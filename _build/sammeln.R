# _build/sammeln.R
#
# Sammelt die aktuellen Arbeitsversionen aller Artefakte aus
# ST_Patientenkommunikation in den Review-Bereich der Prototyp-Site.
# Läuft als Pre-Render-Schritt von Quarto (siehe _quarto.yml), kann aber
# auch von Hand gestartet werden:  Rscript _build/sammeln.R
#
# Liest:    ../../review.yml (die Liste, in Prozessreihenfolge)
# Schreibt: review/*.qmd (generiert, nicht versioniert)
#           index.qmd, nur der Teil zwischen <!-- arbeitsstand:start --> und
#           <!-- arbeitsstand:ende -->; der Rest der Seite bleibt von Hand editierbar
#           ../../Arbeitsstand.md (lokale Übersicht neben der README)

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(stringr)
  library(purrr)
})

# Pfade -----------------------------------------------------------------------

site_dir <- Sys.getenv("QUARTO_PROJECT_DIR", unset = "")
if (site_dir == "") {
  site_dir <- tryCatch(
    path_dir(path_dir(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1])))),
    error = \(e) getwd()
  )
}
site_dir <- path_abs(site_dir)
projekt_dir <- path_dir(path_dir(site_dir)) # ST_Patientenkommunikation
review_dir <- path(site_dir, "review")
manifest_file <- path(projekt_dir, "review.yml")
arbeitsstand_file <- path(projekt_dir, "Arbeitsstand.md")

dir_create(review_dir)
dir_create(path(review_dir, "media"))
# Alte generierte Seiten entfernen, damit gelöschte Artefakte verschwinden,
# auch im Ausgabeordner, den Quarto nicht von sich aus aufräumt
file_delete(dir_ls(review_dir, glob = "*.qmd"))
if (dir_exists(path(site_dir, "_site", "review"))) dir_delete(path(site_dir, "_site", "review"))

manifest <- read_yaml(manifest_file)

# Hilfsfunktionen -------------------------------------------------------------

# Neuste Datei zu einem Glob: höchste Versionsnummer, dann jüngstes Datum
neuste_datei <- function(glob) {
  kandidaten <- Sys.glob(path(projekt_dir, glob))
  if (length(kandidaten) == 0) return(NA_character_)
  version <- as.integer(str_match(path_file(kandidaten), "_v(\\d+)")[, 2])
  datum <- str_extract(path_file(kandidaten), "\\d{4}-\\d{2}-\\d{2}")
  version[is.na(version)] <- 0L
  datum[is.na(datum)] <- "0000-00-00"
  kandidaten[order(version, datum, decreasing = TRUE)][1]
}

# Frontmatter (YAML zwischen ---) vom Text trennen
frontmatter_trennen <- function(zeilen) {
  if (length(zeilen) >= 2 && zeilen[1] == "---") {
    ende <- which(zeilen[-1] == "---")[1] + 1
    if (!is.na(ende)) {
      meta <- tryCatch(yaml.load(paste(zeilen[2:(ende - 1)], collapse = "\n")), error = \(e) list())
      return(list(meta = meta, body = zeilen[(ende + 1):length(zeilen)]))
    }
  }
  list(meta = list(), body = zeilen)
}

versionsinfo <- function(pfad, meta) {
  name <- path_file(pfad)
  v <- str_match(name, "_v(\\d+)")[, 2]
  d <- str_extract(name, "\\d{4}-\\d{2}-\\d{2}")
  stand <- if (!is.null(meta$stand)) as.character(meta$stand) else NULL
  teile <- c(
    if (!is.na(v)) paste0("v", v),
    if (!is.na(d) && (is.null(stand) || !str_detect(stand, fixed(d)))) d
    else if (is.na(d) && !is.null(meta$date)) as.character(meta$date),
    stand
  )
  if (length(teile) == 0) format(file_info(pfad)$modification_time, "geändert %d.%m.%Y") else paste(teile, collapse = ", ")
}

kurz <- function(x, n = 90) {
  x <- as.character(x)
  if (length(x) == 0 || is.na(x) || x == "") return("")
  if (nchar(x) > n) paste0(substr(x, 1, n - 1), "…") else x
}

# Kopf einer Review-Seite: Version, Status, Quelle, Ist
review_kopf <- function(a, info) {
  zeilen <- c(
    "::: {.review-kopf}",
    paste0("**Arbeitsversion:** ", info$version, "  "),
    if (info$status != "") paste0("**Status:** ", info$status, "  "),
    paste0("**Quelle:** `", info$quelle_rel, "`  "),
    if (!is.null(info$ist_link)) paste0("**Ist-Dokument:** [", path_file(info$ist_quelle), "](", info$ist_link, ")  ")
    else if (!is.null(info$ist_quelle)) paste0("**Ist-Dokument:** ", path_file(info$ist_quelle), " (nur lokal)  "),
    if (!is.null(a$hinweis)) paste0("**Hinweis:** ", a$hinweis),
    ":::",
    ""
  )
  zeilen
}

zeilennummern_kopf <- function() {
  c(
    "css: ../review-zeilennummern.css",
    "filters:",
    "  - path: ../review-zeilennummern.lua",
    "    at: pre-ast"
  )
}

zeilennummern_script <- function() {
  c(
    "::: review-technik",
    "```{=html}",
    "<script src=\"../review-zeilennummern.js\" defer></script>",
    "```",
    ":::",
    ""
  )
}

seite_schreiben <- function(datei, titel, order, body, kopf_extra = character(), mit_zeilennummern = TRUE) {
  zeilen <- c(
    "---",
    paste0("title: \"", str_replace_all(titel, "\"", "'"), "\""),
    paste0("order: ", order),
    "toc: false",
    if (mit_zeilennummern) zeilennummern_kopf(),
    "editor:",
    "  markdown:",
    "    wrap: none",
    "---",
    "",
    if (mit_zeilennummern) zeilennummern_script(),
    kopf_extra,
    body
  )
  writeLines(zeilen, path(review_dir, datei))
}

# Ist-Dokument bereitstellen: md als eigene Seite, alles andere als Datei
ist_bereitstellen <- function(a, order) {
  if (is.null(a$ist)) return(NULL)
  ist_pfad <- path(projekt_dir, a$ist)
  if (!file_exists(ist_pfad)) return(list(quelle = a$ist, link = NULL, fehlt = TRUE))
  if (path_ext(ist_pfad) %in% c("md", "txt")) {
    datei <- sprintf("%02d-%s-ist.qmd", order, a$id)
    inhalt <- readLines(ist_pfad, warn = FALSE)
    inhalt <- str_replace_all(inhalt, "\\\\n", "\n")
    seite_schreiben(
      datei, paste0("Ist: ", a$titel), order + 0.5,
      c("::: {.review-kopf}", paste0("**Ist-Dokument, unverändert.** Quelle: `", a$ist, "`"), ":::", "", inhalt)
    )
    return(list(quelle = a$ist, link = path_ext_set(datei, "html"), seite = datei))
  }
  # pdf und docx bleiben lokal: sie können Scans mit echten Namen sein
  list(quelle = a$ist, link = NULL)
}

# Artefakte verarbeiten -------------------------------------------------------

order <- 0
eintraege <- list()

for (g in manifest$gruppen) {
  for (a in g$artefakte) {
    order <- order + 1
    e <- list(gruppe = g$titel, id = a$id, titel = a$titel, typ = a$typ, status = a$status %||% "",
              eingerueckt = isTRUE(a$eingerueckt), pdf = NULL, status_manifest = a$status %||% "",
              hinweis = a$hinweis %||% "", version = "", seite = NULL, quelle_rel = a$quelle %||% "",
              quelle_lokal = NULL, ist_quelle = NULL, ist_link = NULL, ist_lokal = NULL)
    datei <- sprintf("%02d-%s.qmd", order, a$id)

    if (a$typ %in% c("markdown", "docx", "qmd")) {
      quelle <- neuste_datei(a$quelle)
      if (is.na(quelle)) {
        e$typ <- "offen"
        e$version <- "noch kein Entwurf"
      } else {
        e$quelle_rel <- as.character(path_rel(quelle, projekt_dir))
        e$quelle_lokal <- e$quelle_rel
        ist <- ist_bereitstellen(a, order)
        if (!is.null(ist)) {
          e$ist_quelle <- ist$quelle
          e$ist_link <- ist$link
          e$ist_lokal <- ist$quelle
        }

        if (a$typ == "markdown") {
          teile <- frontmatter_trennen(readLines(quelle, warn = FALSE))
          e$version <- versionsinfo(quelle, teile$meta)
          if (e$status == "") e$status <- kurz(teile$meta$status %||% "")
          info <- list(version = e$version, status = e$status, quelle_rel = e$quelle_rel,
                       ist_quelle = e$ist_quelle, ist_link = e$ist_link)
          seite_schreiben(datei, a$titel, order, teile$body, review_kopf(a, info))
        }

        if (a$typ == "docx") {
          media_dir <- path("review", "media", a$id)
          md <- system2(
            "pandoc",
            c(shQuote(quelle), "-t", "markdown-smart-raw_html", "--wrap=none",
              paste0("--extract-media=", media_dir)),
            stdout = TRUE
          )
          md <- str_replace_all(md, fixed(paste0(media_dir, "/")), paste0("media/", a$id, "/"))
          e$version <- versionsinfo(quelle, list())
          info <- list(version = e$version, status = e$status, quelle_rel = e$quelle_rel,
                       ist_quelle = e$ist_quelle, ist_link = e$ist_link)
          seite_schreiben(datei, a$titel, order, md, review_kopf(a, info))
        }

        if (a$typ == "qmd") {
          # Eigenständig rendern (eigenes CSS), als eine Datei einbetten
          ziel_dir <- path(review_dir, a$id)
          dir_create(ziel_dir)
          ziel_html <- path(ziel_dir, "index.html")
          if (!file_exists(ziel_html) || file_info(quelle)$modification_time > file_info(ziel_html)$modification_time) {
            tmp <- path(tempdir(), paste0("review-", a$id))
            dir_create(tmp)
            status_code <- system2("quarto", c("render", shQuote(quelle), "-M", "embed-resources:true",
                                              "--output-dir", shQuote(tmp), "--quiet"))
            html <- dir_ls(tmp, glob = "*.html")
            if (status_code == 0 && length(html) >= 1) {
              file_copy(html[1], ziel_html, overwrite = TRUE)
              # Relativ referenzierte Bilder und Stylesheets mitnehmen
              refs <- str_match_all(paste(readLines(ziel_html, warn = FALSE), collapse = "\n"),
                                    "(?:src|href)=\"([^\":]+\\.(?:jpg|jpeg|png|svg|gif|css|js|woff2?))\"")[[1]][, 2]
              for (r in unique(refs)) {
                von <- path(path_dir(quelle), r)
                if (file_exists(von)) {
                  dir_create(path_dir(path(ziel_dir, r)))
                  file_copy(von, path(ziel_dir, r), overwrite = TRUE)
                }
              }
            } else {
              message("Rendern fehlgeschlagen: ", quelle)
            }
          }
          e$version <- versionsinfo(quelle, list())
          info <- list(version = e$version, status = e$status, quelle_rel = e$quelle_rel,
                       ist_quelle = e$ist_quelle, ist_link = e$ist_link)
          body <- c(
            paste0("[In eigenem Fenster öffnen →](", a$id, "/index.html){target=_blank}"),
            "",
            "```{=html}",
            paste0("<iframe src=\"", a$id, "/index.html\" style=\"width:100%;height:85vh;border:1px solid #ddd;\" title=\"", a$titel, "\"></iframe>"),
            "```"
          )
          seite_schreiben(datei, a$titel, order, body, review_kopf(a, info), mit_zeilennummern = FALSE)
        }
        e$seite <- datei
      }
    }

    if (a$typ == "site") {
      e$seite <- paste0("../", path_ext_set(a$seite, "html"))
      e$quelle_lokal <- path("Webseite/prototyp", a$seite)
      if (!is.null(a$review)) e$review <- paste0("../", path_ext_set(a$review, "html"))
      e$version <- format(file_info(path(site_dir, a$seite))$modification_time, "geändert %d.%m.%Y")
    }
    if (a$typ == "verweis") {
      e$ziel <- a$ziel
    }
    if (!is.null(a$pdf) && file_exists(path(projekt_dir, a$pdf))) {
      dir_create(path(review_dir, "pdf"))
      file_copy(path(projekt_dir, a$pdf), path(review_dir, "pdf", path_file(a$pdf)), overwrite = TRUE)
      e$pdf <- paste0("pdf/", path_file(a$pdf))
    }
    if (a$typ == "extern") {
      e$bei <- a$bei %||% ""
      e$quelle_lokal <- a$quelle
    }
    eintraege[[length(eintraege) + 1]] <- e
  }
}

# Verweise auflösen
seiten_nach_id <- set_names(map(eintraege, "seite"), map_chr(eintraege, "id"))
for (i in seq_along(eintraege)) {
  if (eintraege[[i]]$typ == "verweis") {
    eintraege[[i]]$seite <- seiten_nach_id[[eintraege[[i]]$ziel]]
  }
}

# Übersichten schreiben -------------------------------------------------------

status_text <- function(e) {
  if (e$typ == "offen") return(if (e$status != "") e$status else "offen")
  if (e$typ == "fix") return("fix")
  if (e$typ == "extern") return("extern")
  if (e$status != "") e$status else "Arbeitsversion"
}

# Links in der Site-Übersicht sind relativ zur Wurzel (index.qmd bindet sie ein)
web_pfad <- function(x) {
  if (str_starts(x, "../")) str_remove(x, "^\\.\\./") else paste0("review/", x)
}
link_web <- function(e) {
  if (is.null(e$seite)) return("")
  l <- paste0("[Entwurf →](", web_pfad(e$seite), ")")
  if (!is.null(e$review)) l <- paste0(l, " · [Review mit Zeilennummern →](", web_pfad(e$review), ")")
  l
}

link_lokal <- function(e) {
  if (is.null(e$quelle_lokal)) return("")
  paste0("[", path_file(e$quelle_lokal), "](", str_replace_all(e$quelle_lokal, " ", "%20"), ")")
}

tabelle <- function(eintraege_gruppe, lokal = FALSE) {
  kopf <- if (lokal) {
    c("| Artefakt | Arbeitsversion | Status | Quelle | Ist | Hinweis |", "|---|---|---|---|---|---|")
  } else {
    c("| Artefakt | Arbeitsversion | Status | Seite | Ist | Hinweis |", "|---|---|---|---|---|---|")
  }
  zeilen <- map_chr(eintraege_gruppe, \(e) {
    ist <- if (lokal) {
      if (!is.null(e$ist_lokal)) paste0("[", path_file(e$ist_lokal), "](", str_replace_all(e$ist_lokal, " ", "%20"), ")") else ""
    } else {
      if (!is.null(e$ist_link)) paste0("[Ist →](", web_pfad(e$ist_link), ")") else ""
    }
    titel <- if (e$typ == "extern" && e$bei != "") paste0(e$titel, " (", e$bei, ")") else e$titel
    sprintf("| %s | %s | %s | %s | %s | %s |",
            titel, e$version, status_text(e),
            if (lokal) link_lokal(e) else link_web(e),
            ist, e$hinweis)
  })
  c(kopf, zeilen, "")
}

gruppen <- unique(map_chr(eintraege, "gruppe"))
abschnitte <- map_chr(manifest$gruppen, "titel")[map_lgl(manifest$gruppen, \(g) isTRUE(g$abschnitt))]
heute <- format(Sys.Date(), "%d.%m.%Y")

# Übersicht für die Startseite der Site (index.qmd bindet sie ein):
# trockene Liste, Gruppen als Oberpunkte, in Arbeit befindliche Artefakte fett
in_arbeit <- function(e) {
  !is.null(e$seite) && e$typ %in% c("markdown", "qmd", "docx", "site") && !e$status_manifest %in% c("pending", "Platzhalter")
}
listenpunkt <- function(e, tiefe) {
  text <- e$titel
  if (!is.null(e$seite)) text <- paste0("[", text, "](", web_pfad(e$seite), ")")
  else if (!is.null(e$pdf)) text <- paste0("[", text, " (PDF)](", web_pfad(e$pdf), ")")
  if (in_arbeit(e)) text <- paste0("**", text, "**")
  if (!is.null(e$seite) && !is.null(e$pdf)) text <- paste0(text, " · [PDF](", web_pfad(e$pdf), ")")
  if (e$typ == "extern" && e$bei != "") text <- paste0(text, " (", e$bei, ")")
  else if (e$status_manifest != "") text <- paste0(text, " (", e$status_manifest, ")")
  paste0(strrep("    ", tiefe), "- ", text)
}
uebersicht <- character()
for (g in gruppen) {
  eg <- keep(eintraege, \(e) e$gruppe == g)
  if (g %in% abschnitte) {
    uebersicht <- c(uebersicht, "", paste0("## ", g), "")
    for (e in eg) uebersicht <- c(uebersicht, listenpunkt(e, if (e$eingerueckt) 1 else 0))
  } else if (length(eg) == 1) {
    uebersicht <- c(uebersicht, listenpunkt(eg[[1]], 0))
  } else {
    uebersicht <- c(uebersicht, paste0("- ", g))
    for (e in eg) uebersicht <- c(uebersicht, listenpunkt(e, if (e$eingerueckt) 2 else 1))
  }
}
index_file <- path(site_dir, "index.qmd")
index <- readLines(index_file, warn = FALSE)
start <- which(index == "<!-- arbeitsstand:start -->")[1]
ende <- which(index == "<!-- arbeitsstand:ende -->")[1]
if (is.na(start) || is.na(ende) || ende < start) {
  index <- c(index, "", "<!-- arbeitsstand:start -->", uebersicht, "<!-- arbeitsstand:ende -->")
} else {
  index <- c(index[seq_len(start)], uebersicht, index[ende:length(index)])
}
writeLines(index, index_file)

# Lokaler Arbeitsstand neben der README
stand <- c(
  "# Arbeitsstand Kommunikationspaket",
  "",
  paste0("Generiert von `Webseite/prototyp/_build/sammeln.R` aus `review.yml` am ", heute, ". ",
         "Nicht von Hand bearbeiten; Änderungen in `review.yml` oder in den Quellen."),
  ""
)
for (g in gruppen) {
  stand <- c(stand, paste0("### ", g), "", tabelle(keep(eintraege, \(e) e$gruppe == g), lokal = TRUE))
}
writeLines(stand, arbeitsstand_file)

cat("Review gesammelt:", length(eintraege), "Artefakte,", sum(!map_lgl(map(eintraege, "seite"), is.null)), "mit Seite.\n")
