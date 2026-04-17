#!/bin/bash
# AFN Loop Runner — Unlimited autonomous loop
# Starts a FRESH context each iteration. No compact/rot.
# Keeps running until: Status:SHIPPED | Status:PAUSED | --max-iter | Ctrl+C.
#
# Usage:
#   afn "Create a full-stack booking system"    # New project
#   afn                                          # Resume (if STATE.md exists)
#   afn "new: Real-time chat app"               # Archive old, start fresh
#   afn --budget 1 "Portfolio site with CMS"    # Max $1 per iteration
#   afn --max-iter 10 "Large project"           # Max 10 iterations
#   afn --fresh "Research mode"                 # Ignore existing state (no archive)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/skills/afn/SKILL.md"
# Fallback: check if SKILL.md is next to this script (local install)
if [ ! -f "$SKILL_FILE" ]; then
  SKILL_FILE="$SCRIPT_DIR/SKILL.md"
fi
AFN_DIR=".afn"
STATE_FILE="$AFN_DIR/STATE.md"
LOG_FILE="$AFN_DIR/LOG.md"
MAX_RETRIES=3
RETRY_COUNT=0
BUDGET_PER_ITER=""
MAX_ITERATIONS=0
FRESH=0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${CYAN}[AFN]${NC} $1"; }
success() { echo -e "${GREEN}[AFN]${NC} $1"; }
warn()    { echo -e "${YELLOW}[AFN]${NC} $1"; }
error()   { echo -e "${RED}[AFN]${NC} $1"; }
info()    { echo -e "${MAGENTA}[AFN]${NC} $1"; }

# Check skill file exists
if [ ! -f "$SKILL_FILE" ]; then
  error "SKILL.md not found: $SKILL_FILE"
  exit 1
fi

# Parse arguments
TASK_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --budget)     BUDGET_PER_ITER="$2"; shift 2 ;;
    --max-iter)   MAX_ITERATIONS="$2"; shift 2 ;;
    --fresh)      FRESH=1; shift ;;
    *)            TASK_ARGS+=("$1"); shift ;;
  esac
done
TASK="${TASK_ARGS[*]}"

# --- Status signal checks ---

# SHIPPED: agent declared project complete (success exit)
is_shipped() {
  [ -f "$STATE_FILE" ] && grep -q "^## Status: SHIPPED" "$STATE_FILE"
}

# PAUSED: agent wants user review (clean exit, not failure)
is_paused() {
  [ -f "$STATE_FILE" ] && grep -q "^## Status: PAUSED" "$STATE_FILE"
}

# Any pending `- [ ]` task remains
has_pending() {
  [ -f "$STATE_FILE" ] && grep -q "^- \[ \]" "$STATE_FILE"
}

# --- Observability ---

# Print progress bar
show_progress() {
  if [ -f "$STATE_FILE" ]; then
    local total done pct bar filled i
    total=$(grep -c "^- \[.\]" "$STATE_FILE" 2>/dev/null || echo 0)
    done=$(grep -c "^- \[x\]" "$STATE_FILE" 2>/dev/null || echo 0)
    if [ "$total" -gt 0 ]; then
      pct=$((done * 100 / total))
      bar=""
      filled=$((pct / 5))
      for ((i=0; i<filled; i++)); do bar+="█"; done
      for ((i=filled; i<20; i++)); do bar+="░"; done
      echo -e "${CYAN}[AFN]${NC} Progress: ${BOLD}[$bar] $pct%${NC} ($done/$total tasks)"
    fi
  fi
}

# Print the ## Current single-line status (what the agent is doing NOW)
show_current() {
  if [ -f "$STATE_FILE" ]; then
    # Extract the first non-empty line after "## Current"
    local current
    current=$(awk '/^## Current$/{flag=1; next} /^## /{flag=0} flag && NF' "$STATE_FILE" | head -1)
    if [ -n "$current" ]; then
      echo -e "${CYAN}[AFN]${NC} ${DIM}Current:${NC} $current"
    fi
  fi
}

# Print the last LOG.md block — what happened in the last iteration
show_last_log() {
  if [ -f "$LOG_FILE" ]; then
    # Print the last `## `-prefixed block (iteration entry)
    local last_block
    last_block=$(awk 'BEGIN{block=""} /^## /{block=""} {block=block"\n"$0} END{print block}' "$LOG_FILE" | sed '/^$/d')
    if [ -n "$last_block" ]; then
      echo -e "${DIM}──── Last iteration ────${NC}"
      echo -e "${DIM}$last_block${NC}"
      echo -e "${DIM}────────────────────────${NC}"
    fi
  fi
}

# Print tasks completed since last iteration (diff via git if possible, else diffless)
show_task_snapshot() {
  if [ -f "$STATE_FILE" ]; then
    local done_tasks
    done_tasks=$(grep "^- \[x\]" "$STATE_FILE" 2>/dev/null | tail -3)
    if [ -n "$done_tasks" ]; then
      echo -e "${DIM}Recently completed:${NC}"
      echo "$done_tasks" | sed "s/^- \[x\]/${GREEN}✓${NC}/"
    fi
  fi
}

# --- Ctrl+C handler ---
cleanup() {
  echo ""
  warn "Stopping... (STATE.md preserved)"
  show_progress
  show_current
  exit 130
}
trap cleanup SIGINT SIGTERM

# --- Fresh mode: nuke state if requested ---
if [ "$FRESH" -eq 1 ] && [ -f "$STATE_FILE" ]; then
  warn "--fresh: discarding existing state (not archived)"
  rm -f "$STATE_FILE" "$LOG_FILE"
fi

# --- Build initial prompt based on state ---
build_prompt() {
  local user_task="$1"
  if [ -f "$STATE_FILE" ] && [ -z "$user_task" ]; then
    echo "Resume mode: Read .afn/STATE.md + .afn/DESIGN.md (if exists) + last 3 LOG.md entries. Continue from where you left off. Update ## Current on task start. Append LOG.md on iteration end. If stuck or ambiguous → Status: PAUSED with clear summary (don't silent-abort). IMPORTANT: Keep ≥1 unchecked - [ ] task. When tasks truly run out, follow Ship Decision phase: finite projects → SHIPPED; open-ended → add concrete polish tasks with clear done-criteria."
  elif [ -f "$STATE_FILE" ] && [ -n "$user_task" ]; then
    echo "$user_task — Also check .afn/STATE.md. Update ## Current on task start. IMPORTANT: Keep ≥1 pending task. Use Status: PAUSED for stuck/ambiguous/destructive."
  else
    echo "$user_task"
  fi
}

# --- First invocation handling ---
if [ -z "$TASK" ] && [ -f "$STATE_FILE" ]; then
  # Stale state check (> 7 days)
  if [ -f "$STATE_FILE" ]; then
    # macOS vs Linux stat
    MTIME=$(stat -c %Y "$STATE_FILE" 2>/dev/null || stat -f %m "$STATE_FILE" 2>/dev/null || echo 0)
    NOW=$(date +%s)
    AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
    if [ "$AGE_DAYS" -gt 7 ]; then
      warn "State is ${AGE_DAYS} days old. Agent will surface review prompt before continuing."
    fi
  fi
  log "Existing state found. Resuming..."
  USER_PROMPT=$(build_prompt "")
elif [ -z "$TASK" ] && [ ! -f "$STATE_FILE" ]; then
  error "Nothing to do. Example: afn \"Create a full-stack booking system\""
  exit 1
else
  USER_PROMPT=$(build_prompt "$TASK")
fi

# --- Banner ---
echo ""
log "========================================="
log "  ${BOLD}AFN Autonomous Loop${NC}"
log "========================================="
log "Task: ${TASK:-resume}"
[ -n "$BUDGET_PER_ITER" ] && log "Budget/iteration: \$$BUDGET_PER_ITER"
[ "$MAX_ITERATIONS" -gt 0 ] && log "Max iterations: $MAX_ITERATIONS"
log "Signals: ${GREEN}SHIPPED${NC}=done · ${YELLOW}PAUSED${NC}=review · Ctrl+C=stop"
echo ""

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  # Max iteration check
  if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
    warn "Max iterations reached ($MAX_ITERATIONS). Stopping."
    show_progress
    show_current
    exit 0
  fi

  log "-----------------------------------------"
  log "Iteration ${BOLD}#$ITERATION${NC} starting..."
  show_progress
  show_current
  show_last_log
  log "-----------------------------------------"

  # --- Run Claude with FRESH context ---
  CMD=(claude --print --dangerously-skip-permissions)
  CMD+=(--append-system-prompt "$(cat "$SKILL_FILE")")

  if [ -n "$BUDGET_PER_ITER" ]; then
    CMD+=(--max-budget-usd "$BUDGET_PER_ITER")
  fi

  "${CMD[@]}" "$USER_PROMPT" 2>&1

  EXIT_CODE=$?

  # All subsequent iterations use resume mode (no task arg)
  USER_PROMPT=$(build_prompt "")

  echo ""
  show_task_snapshot

  # --- PAUSED: surface reason and exit cleanly ---
  if is_paused; then
    echo ""
    warn "========================================="
    warn "  ${BOLD}PAUSED for review${NC} (iter #$ITERATION)"
    warn "========================================="
    show_progress
    show_current
    # Print Last Status so user sees what needs decision
    if [ -f "$STATE_FILE" ]; then
      local_status=$(awk '/^## Last Status$/{flag=1; next} /^## /{flag=0} flag' "$STATE_FILE" | sed '/^$/d' | head -10)
      if [ -n "$local_status" ]; then
        echo -e "${YELLOW}Last Status:${NC}"
        echo "$local_status" | sed 's/^/  /'
      fi
    fi
    echo ""
    info "Resume with: afn"
    exit 0
  fi

  # --- SHIPPED: exit with success banner ---
  if is_shipped; then
    echo ""
    success "========================================="
    success "  ${BOLD}PROJECT SHIPPED!${NC} ${GREEN}($ITERATION iterations)${NC}"
    success "========================================="
    show_progress
    exit 0
  fi

  # --- No pending tasks (but not shipped/paused): nudge or pause ---
  if ! has_pending && [ -f "$STATE_FILE" ]; then
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      warn "No pending tasks after $MAX_RETRIES iterations. Auto-pausing for user review."
      # Write PAUSED status — respects the new protocol
      if ! grep -q "^## Status:" "$STATE_FILE"; then
        echo -e "\n## Status: PAUSED" >> "$STATE_FILE"
      else
        sed -i.bak 's/^## Status:.*/## Status: PAUSED/' "$STATE_FILE" && rm -f "$STATE_FILE.bak"
      fi
      warn "Re-run 'afn' after adding tasks or deciding to ship/close."
      exit 0
    else
      warn "No pending tasks. Asking agent to decide: ship or add polish ($RETRY_COUNT/$MAX_RETRIES)"
      USER_PROMPT="Resume mode: All tasks marked done. Follow Ship Decision phase in SKILL.md: if finite project is genuinely complete, write '## Status: SHIPPED'. Otherwise add CONCRETE polish tasks with clear done-criteria (not vague '## Tasks - [ ] Improve'). Prefer '## Status: PAUSED' with a summary if the scope is unclear."
    fi
  else
    RETRY_COUNT=0
  fi

  # --- Claude CLI error handling ---
  if [ $EXIT_CODE -ne 0 ]; then
    warn "Claude exit code: $EXIT_CODE — retrying in 5s..."
    sleep 5
  fi

  log "Opening fresh context..."
  sleep 2
done
