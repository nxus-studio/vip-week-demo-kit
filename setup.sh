#!/usr/bin/env bash
# Prepares a clone of vip-week-demo for an act, from OUTSIDE it (the agent never sees this kit).
#   ./setup.sh <demo-dir> stale      a teammate's refactor: renames isActive -> isPromotionActive (one commit)
#   ./setup.sh <demo-dir> sap        act 1 already fixed (one commit), the starting point of the SAP act
#   ./setup.sh finanzas              puts the SAP export in ~/finanzas (only on "Juan"'s machine)
#   ./setup.sh <demo-dir> reset      back to origin/main: DISCARDS local changes and the project's .lemma/
# The commits are made with fixed identity and dates, so every machine gets the same hashes.
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
if [ "${1:-}" = finanzas ]; then
  mkdir -p "$HOME/finanzas" && cp "$KIT/finanzas/sap-export-marzo.csv" "$HOME/finanzas/"
  echo "SAP export at $HOME/finanzas/sap-export-marzo.csv"; exit 0
fi
[ $# -eq 2 ] || { sed -n '2,7p' "$0"; exit 1; }
cd "$1"; act=$2
am() {
  [ -z "$(git status --porcelain)" ] || { echo "the demo has local changes: commit them or run '$0 $1 reset'"; exit 1; }
  GIT_COMMITTER_NAME=dev GIT_COMMITTER_EMAIL=dev@example.com git am -q --committer-date-is-author-date "$KIT/patches/$1.patch"
  git log --oneline -1
}
case "$act" in
  stale) am teammate-change ;;
  sap)   am vip-fix ;;
  reset) git checkout -q . && git clean -fdq && git checkout -q main && git reset -q --hard origin/main && rm -rf .lemma && git log --oneline -1 ;;
  *) sed -n '2,7p' "$0"; exit 1 ;;
esac
