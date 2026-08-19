#!/usr/bin/env bash
# ════════════════════════════════════════════════════════
# publish — Quarto rendern, committen, pushen.
# Branch wird ermittelt, funktioniert also für master wie für main.
#
# Aufruf:  publish "commit message"
# ════════════════════════════════════════════════════════
set -uo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: publish \"commit message\""
  exit 1
fi

# Ins Projektverzeichnis wechseln, egal von wo aufgerufen wird
cd "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 1

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "✗ Kein git-Repository"; exit 1; }
[ -f _quarto.yml ] || {
  echo "✗ Kein _quarto.yml gefunden"; exit 1; }

branch="$(git symbolic-ref --short HEAD 2>/dev/null)" || {
  echo "✗ Branch nicht ermittelbar (detached HEAD?)"; exit 1; }

echo "→ Rendering Quarto site..."
quarto render || { echo "✗ Quarto render failed"; exit 1; }

echo "→ Staging all changes..."
git add .

echo "→ Committing: $1"
git commit -m "$1" || { echo "✗ Nothing to commit"; exit 1; }

echo "→ Pushing to $branch..."
git push -u origin "$branch" || { echo "✗ Push failed"; exit 1; }

echo "✓ Published ($branch) — Netlify baut jetzt."
