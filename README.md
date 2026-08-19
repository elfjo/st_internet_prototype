# Pfad-Skelett: Prototyp Patientenseiten elektiver Aufenthalt

Klickbarer Struktur-Prototyp zur Benchmark-Recherche
[[Patientenwebsite-Benchmark-elektiver-Pfad]]. Kein Design-Entwurf,
sondern ein Informationsarchitektur-Modell: Er zeigt, wo welcher Inhalt
liegt, wie die Phasen benannt sind und welche Muster aus der Recherche
umgesetzt sind.

## Was der Prototyp zeigt

- `index.html` — Einstiegsseite mit Phasennavigation (Ich-Form nach dem
  Grazer Muster), Trennung Informationszone / Kontaktzone
- `phasen/vorbereitung.html` — eine generische Phasenseite
  («Wissenswertes vorab», UKE-Benennung) mit Pfad-Stepper,
  Task-Liste nach NHS-Muster und Austrittsplanung in der
  Vorbereitungsphase (LUKS-Muster)
- `behandlungen/hueftprothese.html` — der Content-Type «Behandlung»
  nach norwegischem Muster: feste Pflichtabschnitte, Progressive
  Disclosure, RCoA-Risikodarstellung, Warnzeichen als Care Card,
  Praxisblock getrennt vom klinischen Pfad, Governance-Fusszeile

## Was der Prototyp nicht ist

Die klinischen Zahlen auf der Hüftprothesen-Seite sind
**illustrative Platzhalter** und als solche markiert. Vor jeder echten
Verwendung: klinische Freigabe, Quellenprüfung, Nutzertest.

## Deployment

Kein Build-Schritt, keine Abhängigkeiten.

- **Lokal:** `index.html` im Browser öffnen.
- **Netlify:** Ordner per Drag-and-drop auf app.netlify.com ziehen,
  oder als Git-Repo verbinden (Publish directory: `/`, kein Build
  command).
- **GitHub Pages:** Repo anlegen, Ordnerinhalt pushen, in den
  Repo-Settings Pages auf Branch `main`, Ordner `/ (root)` stellen.

## Umgesetzte Muster aus der Recherche

| Muster | Quelle | Wo im Prototyp |
|---|---|---|
| Phasen als Systemvorlage | Norwegen (helsenorge) | hueftprothese.html, Abschnittsstruktur |
| Vollständiger Zyklus auf einer Seite | Radboudumc | hueftprothese.html |
| Ich-Form in Navigationslabels | LKH Graz | index.html |
| «Wissenswertes vorab» | UKE Hamburg | phasen/vorbereitung.html |
| Wartezeit als eigene Phase | My Planned Care NHS | index.html, Phase 2 |
| Austrittsplanung in der Vorbereitung | LUKS, Sahlgrenska | vorbereitung.html |
| Task-Liste mit Status «Noch nicht möglich» | NHS Design System | vorbereitung.html |
| Max. 2 Warnhinweise, inhaltliche Überschrift | NHS Design System | beide Inhaltsseiten |
| Konsequenzrahmung statt Instruktion | Sahlgrenska | vorbereitung.html, Nüchternheit |
| Sonderpfade Diabetes / Blutverdünner ohne Login | Sahlgrenska | vorbereitung.html |
| Risikotabelle: Ereignis, Dauer, X von 100 | RCoA | hueftprothese.html |
| Narkose- und Eingriffsrisiko getrennt | RCoA | hueftprothese.html |
| Vier Fragen (Nutzen/Risiken/Alternativen/Nichtstun) | NICE NG197, BRAN | hueftprothese.html, druckbar |
| «Sofort melden bei» als Care Card | NHS Design System | hueftprothese.html |
| Praxisblock getrennt vom klinischen Pfad | Norwegen | hueftprothese.html |
| Feedback «Ich finde die Seite zu schwierig» | MUMC+ | alle Seiten |
| Geprüft am / Nächste Prüfung / Freigabe | NHS, 1177.se | alle Seiten, Fusszeile |
| Info- und Kontaktzone getrennt | GPGI 2.0 | alle Seiten |
| Hinweis: ersetzt nicht das Aufklärungsgespräch | § 630e-Systematik | hueftprothese.html |
