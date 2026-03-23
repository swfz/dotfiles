#!/bin/bash
# Claude Code status line - Fine Bar + Gradient pattern

input=$(cat)

# --- Extract all fields from JSON input in a single jq call ---
eval "$(echo "$input" | jq -r '
  @sh "cwd=\(.workspace.current_dir // .cwd // "")",
  @sh "model=\(.model.display_name // "")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "session_cost=\(.cost.total_cost_usd // "")",
  @sh "cache_read=\(.context_window.current_usage.cache_read_input_tokens // "")",
  @sh "cache_create=\(.context_window.current_usage.cache_creation_input_tokens // "")",
  @sh "input_tokens=\(.context_window.current_usage.input_tokens // "")",
  @sh "output_tokens=\(.context_window.current_usage.output_tokens // "")",
  @sh "rate_5h_pct=\(.rate_limits.five_hour.used_percentage // "")",
  @sh "rate_7d_pct=\(.rate_limits.seven_day.used_percentage // "")",
  @sh "resets_at_5h=\(.rate_limits.five_hour.resets_at // "")",
  @sh "resets_at_7d=\(.rate_limits.seven_day.resets_at // "")"
')"

# --- ANSI colors ---
R=$'\033[0m'
DIM=$'\033[2m'
GIT_FG=$'\033[97m'
WT_FG=$'\033[93m'
COMMIT_FG=$'\033[97m'
STAT_ADD=$'\033[32m'
STAT_DEL=$'\033[31m'
TIME_FG=$'\033[35m'
COST_FG=$'\033[32m'
CACHE_FG=$'\033[96m'
MODEL_FG=$'\033[36m'
RESET_FG=$'\033[37m'
SEP="${DIM} | ${R}"

# --- TrueColor gradient (green -> yellow -> red) ---
_gradient() {
  local pct="$1"
  if [ "$pct" -lt 50 ]; then
    local r=$(( pct * 51 / 10 ))
    printf '\033[38;2;%d;200;80m' "$r"
  else
    local g=$(( 200 - (pct - 50) * 4 ))
    [ "$g" -lt 0 ] && g=0
    printf '\033[38;2;255;%d;60m' "$g"
  fi
}

# --- Fine bar with ░▒▓█ shades ---
# Usage: _fine_bar <pct>
_fine_bar() {
  local pct="$1" width=10
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  local filled=$(( pct * width ))
  local full=$(( filled / 100 ))
  local remainder=$(( filled % 100 ))
  local frac=$(( remainder * 4 / 100 ))
  local bar=""
  local i
  for (( i=0; i<full; i++ )); do bar+="█"; done
  local empty_count=$(( width - full ))
  if [ "$empty_count" -gt 0 ]; then
    case "$frac" in
      1) bar+="░"; empty_count=$(( empty_count - 1 )) ;;
      2) bar+="▒"; empty_count=$(( empty_count - 1 )) ;;
      3) bar+="▓"; empty_count=$(( empty_count - 1 )) ;;
    esac
    for (( i=0; i<empty_count; i++ )); do bar+="░"; done
  fi
  printf '%s' "$bar"
}

# --- Format: label + gradient bar + pct ---
# Usage: _fmt <label> <pct>
_fmt() {
  local label="$1" pct="$2"
  local pct_int=$(printf '%.0f' "$pct" 2>/dev/null)
  local color; color=$(_gradient "$pct_int")
  local bar; bar=$(_fine_bar "$pct_int")
  printf '%s %s%s %d%%%s' "$label" "$color" "$bar" "$pct_int" "$R"
}

# --- Git info ---
git_branch=""
is_worktree=0
git_stats_add=0
git_stats_del=0
commits_ahead=""

if git -C "$cwd" rev-parse --is-inside-work-tree --no-optional-locks >/dev/null 2>&1; then
  # Branch
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  # Worktree detection
  main_worktree=$(git -C "$cwd" --no-optional-locks worktree list --porcelain 2>/dev/null \
    | awk '/^worktree /{print $2; exit}')
  resolved_cwd=$(cd "$cwd" 2>/dev/null && pwd -P)
  if [ -n "$main_worktree" ] && [ "$resolved_cwd" != "$(cd "$main_worktree" 2>/dev/null && pwd -P)" ]; then
    is_worktree=1
  fi

  # Diff stats
  stat_line=$(git -C "$cwd" --no-optional-locks diff --stat HEAD 2>/dev/null | tail -1)
  if [ -n "$stat_line" ]; then
    added=$(echo "$stat_line" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' | head -1)
    deleted=$(echo "$stat_line" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' | head -1)
    git_stats_add=${added:-0}
    git_stats_del=${deleted:-0}
  fi

  # Commits ahead of default branch
  if [ -n "$git_branch" ]; then
    default_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
      | sed 's|refs/remotes/origin/||')
    if [ -z "$default_branch" ]; then
      for b in main master develop; do
        if git -C "$cwd" --no-optional-locks show-ref --verify --quiet "refs/remotes/origin/${b}" 2>/dev/null; then
          default_branch="$b"
          break
        fi
      done
    fi
    if [ -n "$default_branch" ] && [ "$git_branch" != "$default_branch" ]; then
      ahead=$(git -C "$cwd" --no-optional-locks rev-list --count "origin/${default_branch}..HEAD" 2>/dev/null)
      [ -n "$ahead" ] && [ "$ahead" -gt 0 ] && commits_ahead="${ahead}"
    fi
  fi
fi

# --- Session elapsed time ---
session_time=""
if [ -n "$PPID" ] && [ "$PPID" -gt 0 ] 2>/dev/null; then
  etime=$(ps -o etime= -p "$PPID" 2>/dev/null | tr -d ' ')
  if [ -n "$etime" ]; then
    days=0; hours=0; mins=0
    if [[ "$etime" == *-* ]]; then
      days=${etime%%-*}
      etime=${etime##*-}
    fi
    IFS=':' read -ra parts <<< "$etime"
    count=${#parts[@]}
    if [ "$count" -eq 3 ]; then
      hours=${parts[0]}; mins=${parts[1]}
    elif [ "$count" -eq 2 ]; then
      mins=${parts[0]}
    fi
    total_mins=$(( days * 1440 + hours * 60 + mins ))
    if [ "$total_mins" -ge 60 ]; then
      h=$(( total_mins / 60 )); m=$(( total_mins % 60 ))
      session_time="${h}h${m}m"
    else
      session_time="${total_mins}m"
    fi
  fi
fi

# --- Parse reset time ---
now_epoch=$(date +%s)

_parse_reset() {
  local epoch="$1" show_time="${2:-1}"
  [ -z "$epoch" ] && return
  local remaining=$(( epoch - now_epoch ))
  local rtime
  rtime=$(date -d @"$epoch" "+%H:%M" 2>/dev/null || date -r "$epoch" "+%H:%M" 2>/dev/null)
  if [ "$remaining" -gt 0 ]; then
    local rm_total=$(( remaining / 60 ))
    local rh=$(( rm_total / 60 )) rmm=$(( rm_total % 60 ))
    local dur
    if [ "$rh" -ge 24 ]; then
      local rd=$(( rh / 24 )); rh=$(( rh % 24 ))
      dur="${rd}d${rh}h${rmm}m"
    elif [ "$rh" -gt 0 ]; then
      dur="${rh}h${rmm}m"
    else
      dur="${rmm}m"
    fi
    if [ "$show_time" -eq 1 ]; then
      printf '%s (%s)' "$rtime" "$dur"
    else
      printf '(%s)' "$dur"
    fi
  else
    if [ "$show_time" -eq 1 ]; then
      printf '%s (now)' "$rtime"
    else
      printf '(now)'
    fi
  fi
}

reset_label=$(_parse_reset "$resets_at_5h" 1)
reset_label_7d=$(_parse_reset "$resets_at_7d" 0)

# --- Session cost ---
cost_label=""
if [ -n "$session_cost" ]; then
  cost_label=$(echo "$session_cost" | awk '{printf "$%.4f", $1}')
fi

# --- Cache efficiency ---
cache_label=""
if [ -n "$cache_read" ] && [ -n "$cache_create" ]; then
  total_cache=$(( cache_read + cache_create ))
  if [ "$total_cache" -gt 0 ]; then
    cache_pct=$(echo "$cache_read $total_cache" | awk '{printf "%.0f", $1/$2*100}')
    cache_read_k=$(echo "$cache_read" | awk '{if($1>=1000) printf "%.0fK",$1/1000; else printf "%d",$1}')
    cache_label="cache: ${cache_pct}% (${cache_read_k} hit)"
  fi
fi

# --- Token usage (in/out) ---
_fmt_tokens() {
  echo "$1" | awk '{if($1>=1000000) printf "%.1fM",$1/1000000; else if($1>=1000) printf "%.0fK",$1/1000; else printf "%d",$1}'
}
token_label=""
if [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
  in_fmt=$(_fmt_tokens "$input_tokens")
  out_fmt=$(_fmt_tokens "$output_tokens")
  token_label="in:${in_fmt} out:${out_fmt}"
fi

# --- Build line 1 ---
out=""

# Git branch / worktree
if [ -n "$git_branch" ]; then
  if [ "$is_worktree" -eq 1 ]; then
    out+="${GIT_FG}${git_branch}${R} ${WT_FG}(worktree)${R}"
  else
    out+="${GIT_FG}${git_branch}${R}"
  fi
  if [ -n "$commits_ahead" ]; then
    out+=" ${COMMIT_FG}+${commits_ahead}${R}"
  fi
  if [ "$git_stats_add" -gt 0 ] || [ "$git_stats_del" -gt 0 ]; then
    out+=" ${STAT_ADD}+${git_stats_add}${R} ${STAT_DEL}-${git_stats_del}${R}"
  fi
fi

# Session time
if [ -n "$session_time" ]; then
  [ -n "$out" ] && out+="$SEP"
  out+="${TIME_FG}${session_time}${R}"
fi

# Session cost
if [ -n "$cost_label" ]; then
  [ -n "$out" ] && out+="$SEP"
  out+="${COST_FG}${cost_label}${R}"
fi

# Cache efficiency
if [ -n "$cache_label" ]; then
  [ -n "$out" ] && out+="$SEP"
  out+="${CACHE_FG}${cache_label}${R}"
fi

# Token usage
TOKEN_FG=$'\033[33m'
if [ -n "$token_label" ]; then
  [ -n "$out" ] && out+="$SEP"
  out+="${TOKEN_FG}${token_label}${R}"
fi

# Model
if [ -n "$model" ]; then
  [ -n "$out" ] && out+="$SEP"
  out+="${MODEL_FG}${model}${R}"
fi

# --- Build line 2 (context + rate limits) ---
line2=""

# Context window
if [ -n "$used_pct" ]; then
  line2+=$(_fmt "ctx" "$used_pct")
fi

# 5h rate limit
if [ -n "$rate_5h_pct" ]; then
  [ -n "$line2" ] && line2+="$SEP"
  line2+=$(_fmt "5h" "$rate_5h_pct")
  if [ -n "$reset_label" ]; then
    line2+=" ${RESET_FG}${reset_label}${R}"
  fi
fi

# 7d rate limit
if [ -n "$rate_7d_pct" ]; then
  [ -n "$line2" ] && line2+="$SEP"
  line2+=$(_fmt "7d" "$rate_7d_pct")
  if [ -n "$reset_label_7d" ]; then
    line2+=" ${RESET_FG}${reset_label_7d}${R}"
  fi
fi

# --- Output ---
if [ -n "$line2" ]; then
  printf '%s\n%s' "$out" "$line2"
else
  printf '%s' "$out"
fi
