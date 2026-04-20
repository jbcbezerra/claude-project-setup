#!/usr/bin/env bash
# Claude Code status line: RGB gradient, dynamic emoji, cost, code velocity

input=$(cat)

# ── Colors ──
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Truecolor helper ──
rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

# ── Parse JSON fields ──
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_h_epoch=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_epoch=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ── Git info ──
branch=""
repo=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  repo=$(basename "$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null)
fi

# ── Context bar: RGB gradient, full blocks only ──
BAR_WIDTH=20

if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")

  # Round to nearest block
  filled=$(( (used_int * BAR_WIDTH + 50) / 100 ))

  bar=""
  for (( i=0; i<BAR_WIDTH; i++ )); do
    pos=$(( i * 100 / (BAR_WIDTH - 1) ))

    if [ "$pos" -le 50 ]; then
      r=$(( 0 + 220 * pos / 50 ))
      g=200
      b=$(( 80 - 80 * pos / 50 ))
    else
      adj=$(( pos - 50 ))
      r=220
      g=$(( 200 - 160 * adj / 50 ))
      b=$(( 0 + 20 * adj / 50 ))
    fi

    if [ "$i" -lt "$filled" ]; then
      bar="${bar}$(rgb $r $g $b)█"
    else
      bar="${bar}\033[38;2;60;60;60m░"
    fi
  done
  bar="${bar}${RESET}"

  if [ "$used_int" -ge 90 ]; then status_emoji="🚨"
  elif [ "$used_int" -ge 70 ]; then status_emoji="🔥"
  elif [ "$used_int" -ge 20 ]; then status_emoji="⚡"
  else status_emoji="🟢"; fi

  if [ "$used_int" -ge 90 ]; then pct_color="$RED"
  elif [ "$used_int" -ge 70 ]; then pct_color="$YELLOW"
  else pct_color="$GREEN"; fi

  ctx_part="${status_emoji} ${bar} ${pct_color}${used_int}%${RESET}"
else
  ctx_part="🟢 \033[38;2;60;60;60m░░░░░░░░░░░░░░░░░░░░${RESET} --%"
fi

# ── Rate limits ──
# Format remaining time until the given epoch.
# mode=hm   -> HH:MM      (for the 5h window)
# mode=dhm  -> DD:HH:MM   (for the 7d window)
format_remaining() {
  local epoch=$1
  local mode=$2
  if [ -z "$epoch" ] || [ "$epoch" = "null" ]; then
    echo "--"
    return
  fi
  local now diff
  now=$(date +%s)
  diff=$(( epoch - now ))
  [ "$diff" -lt 0 ] && diff=0
  local days hours minutes
  if [ "$mode" = "dhm" ]; then
    days=$(( diff / 86400 ))
    hours=$(( (diff % 86400) / 3600 ))
    minutes=$(( (diff % 3600) / 60 ))
    printf "%02d:%02d:%02d" "$days" "$hours" "$minutes"
  else
    hours=$(( diff / 3600 ))
    minutes=$(( (diff % 3600) / 60 ))
    printf "%02d:%02d" "$hours" "$minutes"
  fi
}

format_pct() {
  local p=$1
  if [ -z "$p" ] || [ "$p" = "null" ]; then
    echo "--%"
    return
  fi
  local pi
  pi=$(printf '%.0f' "$p")
  local color
  if [ "$pi" -ge 90 ]; then color="$RED"
  elif [ "$pi" -ge 70 ]; then color="$YELLOW"
  else color="$GREEN"; fi
  printf "%b%d%%%b" "$color" "$pi" "$RESET"
}

five_h_remaining=$(format_remaining "$five_h_epoch" "hm")
seven_d_remaining=$(format_remaining "$seven_d_epoch" "dhm")
five_h_part="5h $(format_pct "$five_h_pct") ${DIM}(↻ ${five_h_remaining})${RESET}"
seven_d_part="7d $(format_pct "$seven_d_pct") ${DIM}(↻ ${seven_d_remaining})${RESET}"

# ── Line 1: project | branch | context | model ──
line1=""
[ -n "$repo" ] && line1="${BOLD}${YELLOW}${repo}${RESET}"
[ -n "$branch" ] && line1="${line1:+$line1 ${DIM}|${RESET} }${BOLD}${CYAN}🌿 (${branch})${RESET}"
line1="${line1:+$line1 ${DIM}|${RESET} }${ctx_part}"
line1="${line1} ${DIM}|${RESET} ${MAGENTA}🤖 ${model}${RESET}"

# ── Line 2: 5h | 7d ──
line2="${five_h_part} ${DIM}|${RESET} ${seven_d_part}"

printf '%b\n%b' "$line1" "$line2"
