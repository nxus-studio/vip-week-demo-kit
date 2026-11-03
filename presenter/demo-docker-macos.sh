#!/usr/bin/env bash
# The two-laptop demo on one Mac: two Docker containers play "Juan" and "Ana", each with its own
# HOME, Lemma Cloud key and Claude Code login. This script gets them ready and opens one window
# with JUAN on the left and ANA on the right, each running presenter/pane.sh.
#
#   ./demo-docker-macos.sh            prep + open (the usual)
#   ./demo-docker-macos.sh prep       start the boxes, update the kit inside them, clean, check Cloud
#   ./demo-docker-macos.sh open       open the window (Warp; --terminal for Terminal.app)
#   ./demo-docker-macos.sh clean      retract what the boxes shared and reset both (run after a rehearsal)
#
# Assumes boxes named laptop-juan and laptop-ana (user `ana`, demo at ~/vip-week-demo, kit at
# ~/vip-week-demo-kit), already logged into Claude Code (`claude /login`) and Lemma Cloud (`lemma cloud login`).
set -uo pipefail
BOXES=(laptop-juan laptop-ana)
H=/home/ana; DEMO=$H/vip-week-demo; KIT=$H/vip-week-demo-kit
say() { printf '\033[1m▸ %s\033[0m\n' "$*"; }
box() { docker exec -w "$DEMO" "$@"; }

clean() {
  for b in "${BOXES[@]}"; do
    say "$b: retracting what it shared"
    ids=$(box "$b" node -e '
      const fs=require("fs"); const ids=new Set();
      try { for (const k of Object.keys(JSON.parse(fs.readFileSync(".lemma/session/cloud-map.json","utf8")))) ids.add(k) } catch {}
      try { for (const m of fs.readFileSync(process.env.HOME+"/.vip-week-demo-shared","utf8").match(/\{[^{}]*\}/g)||[]) for (const k of Object.keys(JSON.parse(m))) ids.add(k) } catch {}
      console.log([...ids].join(" "))')
    for id in $ids; do box "$b" node "$KIT/presenter/mcp-call.js" forget_memory "{\"id\":\"$id\"}" | head -1; done
    box "$b" bash -c "rm -rf ~/finanzas ~/.finanzas-de-juan ~/.vip-week-demo-shared ~/.lemma-cache/brain ~/.claude/projects/* && $KIT/setup.sh $DEMO reset"
  done
  say "team Brain, seen from ${BOXES[1]}:"
  box "${BOXES[1]}" node "$KIT/presenter/mcp-call.js" search_memory '{"query":"VIP-WEEK SAP descuento redondeo IVA facturas"}' | head -2
}

prep() {
  say "starting the boxes"; docker start "${BOXES[@]}" >/dev/null || exit 1
  for b in "${BOXES[@]}"; do
    say "$b: kit, demo and Claude Code trust"
    box "$b" bash -c "git -C $KIT pull -q --ff-only && git fetch -q origin && chmod +x $KIT/*.sh $KIT/presenter/*.sh" || exit 1
    # first interactive run asks to trust the folder; answer it once here so it never shows on the projector
    box "$b" node -e '
      const f=process.env.HOME+"/.claude.json", fs=require("fs"), c=JSON.parse(fs.readFileSync(f,"utf8"));
      c.projects=c.projects||{}; const p=c.projects[process.argv[1]]=c.projects[process.argv[1]]||{};
      p.hasTrustDialogAccepted=true; p.hasCompletedProjectOnboarding=true; fs.writeFileSync(f, JSON.stringify(c,null,2))' "$DEMO"
  done
  clean
  for b in "${BOXES[@]}"; do printf '%s: ' "$b"; box "$b" lemma cloud status 2>&1 | grep -E 'sharing|reachable' | tr -s ' ' | tr '\n' ' '; echo; done
}

open_window() {
  if [ "${1:-}" = --terminal ] || [ ! -d /Applications/Warp.app ]; then
    osascript <<EOF
tell application "Finder" to set {_x, _y, sw, sh} to bounds of window of desktop
tell application "Terminal"
  activate
  set j to do script "docker exec -it -w $DEMO laptop-juan bash $KIT/presenter/pane.sh juan"
  set custom title of j to "JUAN"
  set bounds of front window to {0, 25, sw / 2, sh}
  set a to do script "docker exec -it -w $DEMO laptop-ana bash $KIT/presenter/pane.sh ana"
  set custom title of a to "ANA"
  set bounds of front window to {sw / 2, 25, sw, sh}
end tell
EOF
    return
  fi
  local dir="$HOME/.warp/launch_configurations"; mkdir -p "$dir"
  cat > "$dir/lemma-demo.yaml" <<EOF
---
name: lemma-demo
windows:
  - tabs:
      - title: JUAN | ANA
        layout:
          split_direction: horizontal
          panes:
            - cwd: $HOME
              commands:
                - exec: docker exec -it -w $DEMO laptop-juan bash $KIT/presenter/pane.sh juan
            - cwd: $HOME
              commands:
                - exec: docker exec -it -w $DEMO laptop-ana bash $KIT/presenter/pane.sh ana
EOF
  open "warp://launch/lemma-demo.yaml"
}

case "${1:-all}" in
  prep) prep ;;
  open) open_window "${2:-}" ;;
  clean) clean ;;
  all) prep && open_window "${2:-}" ;;
  --terminal) prep && open_window --terminal ;;
  *) sed -n '2,13p' "$0"; exit 1 ;;
esac
