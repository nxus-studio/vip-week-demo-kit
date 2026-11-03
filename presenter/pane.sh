#!/usr/bin/env bash
# One side of the demo, step by step: shows what comes next, Enter runs it, s skips it, q quits.
# Claude sessions end with /exit, and the pane moves on to the next step.
#   presenter/pane.sh juan [demo-dir]       left side
#   presenter/pane.sh ana  [demo-dir]       right side
# On a single laptop without Cloud, run juan's steps, then ana's, in the same clone (Ana's SAP step hides ~/finanzas).
set -uo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
ROLE=${1:?juan or ana}; DEMO=${2:-$HOME/vip-week-demo}
LEDGER="$HOME/.vip-week-demo-shared"   # local ids of shared memories, so presenter cleanup can retract them later

b=$'\e[1m'; d=$'\e[2m'; c=$'\e[36m'; g=$'\e[32m'; y=$'\e[33m'; r=$'\e[0m'
banner() { clear; printf '%s\n' "${c}${b}━━ $(printf %s "$ROLE" | tr a-z A-Z) · $1 ━━${r}" ""; shift; for l in "$@"; do printf '  %s\n' "$l"; done; printf '\n'; }
run() { printf '%s\n' "${d}\$ $*${r}"; "$@"; }
save_shared() { [ -f "$DEMO/.lemma/session/cloud-map.json" ] && cat "$DEMO/.lemma/session/cloud-map.json" >> "$LEDGER"; return 0; }
reset_demo() { save_shared; run "$KIT/setup.sh" "$DEMO" reset; }
session() { run "$KIT/session.sh" "$DEMO" "$1"; }
pause() { printf '\n%s' "${d}Enter para seguir${r}"; read -r _; }

step() { # title | lines... ; the commands come from the function named after the title id
  local id=$1 title=$2; shift 2
  banner "$title" "$@"
  printf '%s' "${y}Enter: correr   s: saltar   q: salir ${r}"
  read -r k; case "$k" in q) exit 0 ;; s) return ;; esac
  printf '\n'; "$id"
}

# ── Juan ──
j1() { session act1-juan; }
j2() { session correct-juan; }
j3() { reset_demo && run "$KIT/setup.sh" "$DEMO" sap && run "$KIT/setup.sh" finanzas && run head -4 "$HOME/finanzas/sap-export-marzo.csv"; pause; session sap-juan; }

# ── Ana ──
a1() { session act1-ana; }
a2() { run "$KIT/grade.sh" "$DEMO" vip; pause; }
a3() { reset_demo && run "$KIT/setup.sh" "$DEMO" stale; pause; session stale-ana; }
a4() { session correct-ana; }
a5() {
  if [ -d "$HOME/finanzas" ]; then run mv "$HOME/finanzas" "$HOME/.finanzas-de-juan"; printf '%s\n' "${d}(misma máquina: el export de Juan queda fuera del alcance de Ana)${r}"; fi
  reset_demo && run "$KIT/setup.sh" "$DEMO" sap && run ls "$HOME/finanzas"; pause; session sap-ana
}
a6() { run "$KIT/grade.sh" "$DEMO" sap; pause; }

cd "$DEMO" || exit 1
if [ "$ROLE" = juan ]; then
  step j1 "Acto 1 · Juan investiga VIP-WEEK" "Investiga dos síntomas sin cambiar código y guarda lo que encontró." "Mira: el store_memory final y '☁ Shared with your team's Brain'."
  step j2 "Acto 1c · ¿Qué sabe el equipo ahora?" "Después de que Ana corrigió la memoria (paso 4 de Ana)." "Mira: '[team] … (by ana)' y 'Replaces team memory … (by juan)'."
  step j3 "Acto 2 · SAP: Juan tiene el export" "El código con el acto 1 ya arreglado; el export de SAP solo en esta máquina." "Juan deduce la regla de SAP y la comparte. No cambia código."
else
  step a1 "Acto 1 · Ana arregla VIP-WEEK" "Sesión nueva, otra máquina, sin contexto." "Mira: su primera búsqueda → '[team] … (by juan, today, fresh here)'."
  step a2 "Acto 1 · Tests ocultos" "6 tests que el agente nunca vio, en UTC y en hora de Ciudad de México."
  step a3 "Acto 1b · Un compañero renombró una función" "Se descarta el arreglo de Ana; la memoria de Juan sigue en el equipo." "Mira: 'STALE — changed here since: src/promotions.ts::isActive'."
  step a4 "Acto 1c · Ana corrige la memoria de Juan" "update_memory sobre el id [team]: reemplaza la copia del equipo." "Después: paso 2 de Juan."
  step a5 "Acto 2 · SAP: Ana no tiene el export" "Mismo código que Juan; ~/finanzas no existe aquí." "Mira: '[team] … (by juan, today, fresh here)' en su primera búsqueda."
  step a6 "Acto 2 · Tests ocultos de SAP" "4 pedidos nuevos que no están en el export: no se pasa copiando el CSV."
fi
banner "Fin" "${g}Listo.${r}"
