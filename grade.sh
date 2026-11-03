#!/usr/bin/env bash
# Runs the hidden tests of an act inside a clone of vip-week-demo, under TZ=UTC and TZ=America/Mexico_City,
# then removes them. Run it AFTER the agent's session: an agent that can run it can iterate against it.
#   ./grade.sh <demo-dir> vip    act 1, 6 tests (base: 1/6 UTC, 3/6 Mexico City)
#   ./grade.sh <demo-dir> sap    act 2, 4 new orders that are not in the export (base: 0/4)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
[ $# -eq 2 ] && [ -f "$KIT/hidden/$2.test.ts" ] || { sed -n '2,5p' "$0"; exit 1; }
cd "$1"; t="tests/zz-hidden-$2.test.ts"
cp "$KIT/hidden/$2.test.ts" "$t"; trap 'rm -f "$t"' EXIT
for tz in UTC America/Mexico_City; do
  printf '%-22s ' "$tz"; TZ=$tz npx jest "$t" --silent 2>&1 | grep -E '^Tests:' || true
done
