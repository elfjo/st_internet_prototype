# Pfad-Skelett: Prototyp Patientenseiten elektiver Aufenthalt

Klickbarer Struktur-Prototyp zur Benchmark-Recherche
[[Patientenwebsite-Benchmark-elektiver-Pfad]]. Kein Design-Entwurf,
sondern ein Informationsarchitektur-Modell: Er zeigt, wo welcher Inhalt
liegt, wie die Phasen benannt sind und welche Muster aus der Recherche
umgesetzt sind.

## Workflow (identisch mit Perspektivenwerkstatt/Webpage)

Quarto-Website. Inhalte sind `.qmd`-Dateien, editierbar wie Markdown.

```
quarto preview      # lokale Vorschau mit Live-Reload
quarto render       # baut die Site nach _site/
git add -A && git commit && git push
```

Netlify publiziert das committete `_site/` ohne eigenen Build
(`netlify.toml`: publish = "_site"). Zum Aufschalten: Repo auf GitHub
anlegen, pushen, in Netlify «Import from Git» wählen — Build command
leer lassen.

## Struktur

- `index.qmd` — Einstiegsseite mit Phasennavigation (Ich-Form nach dem
  Grazer Muster), Kontaktzone getrennt von der Information
- `phasen/vorbereitung.qmd` — generische Phasenseite («Ich bereite
  mich vor») mit Stepper, Task-Tabelle nach NHS-Muster und
  Austrittsplanung in der Vorbereitungsphase (LUKS-Muster)
- `behandlungen/hueftprothese.qmd` — Content-Type «Behandlung» nach
  norwegischem Muster: feste Pflichtabschnitte, Progressive Disclosure
  (Quarto-Callouts), RCoA-Risikodarstellung, Warnzeichen als Care
  Card, Praxisblock getrennt, Governance-Fusszeile
- `_feedback.qmd`, `_governance.qmd` — geteilte Bausteine, einmal
  gepflegt, per `{{< include >}}` eingebunden (das Ein-Asset-Prinzip
  aus der Recherche, im Kleinen)
- `pfad-custom.scss` — Gestaltung; bewusst zurückhaltend
- `_quarto.yml` — Navigation, TOC, Feedback-Script

## Redaktionskonventionen im Prototyp

- Platzhalter für klinische Angaben: `[Text]{.ph}` — rendert violett
  in ⟨Klammern⟩. Nichts davon ist geprüfte medizinische Information.
- Warnhinweise: `::: {.warnung}` mit inhaltlicher `###`-Überschrift,
  maximal zwei pro Seite (NHS-Regel)
- «Sofort melden»: `::: {.care}` — getrennt vom Warnhinweis
- Aufklappbares: `::: {.callout-note collapse="true" icon="false"}`
- Status in Task-Tabellen: `[Offen]{.st .st-offen}`,
  `[Noch nicht möglich]{.st .st-gesperrt}`, `[Erledigt]{.st .st-erledigt}`

## Umgesetzte Muster aus der Recherche

| Muster | Quelle | Wo im Prototyp |
|---|---|---|
| Phasen als Systemvorlage | Norwegen (helsenorge) | hueftprothese.qmd, Abschnittsstruktur |
| Vollständiger Zyklus auf einer Seite | Radboudumc | hueftprothese.qmd |
| Ich-Form in Navigationslabels | LKH Graz | index.qmd |
| Wartezeit als eigene Phase | My Planned Care NHS | index.qmd, Phase 2 |
| Austrittsplanung in der Vorbereitung | LUKS, Sahlgrenska | vorbereitung.qmd |
| Task-Liste mit Status «Noch nicht möglich» | NHS Design System | vorbereitung.qmd |
| Max. 2 Warnhinweise, inhaltliche Überschrift | NHS Design System | beide Inhaltsseiten |
| Konsequenzrahmung statt Instruktion | Sahlgrenska | vorbereitung.qmd, Nüchternheit |
| Sonderpfade Diabetes / Blutverdünner ohne Login | Sahlgrenska | vorbereitung.qmd |
| Risikotabelle: Ereignis, Dauer, X von 100 | RCoA | hueftprothese.qmd |
| Narkose- und Eingriffsrisiko getrennt | RCoA | hueftprothese.qmd |
| Vier Fragen (Nutzen/Risiken/Alternativen/Nichtstun) | NICE NG197, BRAN | hueftprothese.qmd, druckbar |
| «Sofort melden bei» als Care Card | NHS Design System | hueftprothese.qmd |
| Praxisblock getrennt vom klinischen Pfad | Norwegen | hueftprothese.qmd |
| Feedback «Ich finde die Seite zu schwierig» | MUMC+ | alle Seiten |
| Geprüft am / Nächste Prüfung / Freigabe | NHS, 1177.se | alle Seiten, Fusszeile |
| Geteilte Bausteine statt Dubletten | Schön Klinik, 1177.se | _feedback.qmd, _governance.qmd |
| Info- und Kontaktzone getrennt | GPGI 2.0 | index.qmd |
| Hinweis: ersetzt nicht das Aufklärungsgespräch | § 630e-Systematik | hueftprothese.qmd |
