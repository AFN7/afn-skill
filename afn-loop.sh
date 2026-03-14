#!/bin/bash
# AFN Loop Runner — Unlimited autonomous loop
# Starts a FRESH context each iteration. No compact/rot.
# Does NOT stop until STATE.md says "COMPLETED".
#
# Usage:
#   afn "Create a full-stack booking system"              # New project
#   afn                                          # Resume (if STATE.md exists)
#   afn "new: Real-time chat app"              # Start fresh
#   afn --budget 1 "Portfolio site with CMS"              # Max $1 per iteration
#   afn --max-iter 10 "Large project"           # Max 10 iterations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/skills/afn/SKILL.md"
# Fallback: check if SKILL.md is next to this script (local install)
if [ ! -f "$SKILL_FILE" ]; then
  SKILL_FILE="$SCRIPT_DIR/SKILL.md"
fi
AFN_DIR=".afn"
STATE_FILE="$AFN_DIR/STATE.md"
MAX_RETRIES=3
RETRY_COUNT=0
BUDGET_PER_ITER=""
MAX_ITERATIONS=0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${CYAN}[AFN]${NC} $1"; }
success() { echo -e "${GREEN}[AFN]${NC} $1"; }
warn() { echo -e "${YELLOW}[AFN]${NC} $1"; }
error() { echo -e "${RED}[AFN]${NC} $1"; }

# Check skill file exists
if [ ! -f "$SKILL_FILE" ]; then
  error "SKILL.md not found: $SKILL_FILE"
  exit 1
fi

# Parse arguments
TASK_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --budget)
      BUDGET_PER_ITER="$2"
      shift 2
      ;;
    --max-iter)
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      TASK_ARGS+=("$1")
      shift
      ;;
  esac
done
TASK="${TASK_ARGS[*]}"

# Check if project is completed
is_done() {
  if [ -f "$STATE_FILE" ]; then
    grep -qi "COMPLETED\|DONE\|TAMAMLANDI" "$STATE_FILE" && return 0
  fi
  return 1
}

# Check for pending tasks
has_pending() {
  if [ -f "$STATE_FILE" ]; then
    grep -q "\- \[ \]" "$STATE_FILE" && return 0
  fi
  return 1
}

# Show progress bar
show_progress() {
  if [ -f "$STATE_FILE" ]; then
    local total=$(grep -c "\- \[.\]" "$STATE_FILE" 2>/dev/null || echo 0)
    local done=$(grep -c "\- \[x\]" "$STATE_FILE" 2>/dev/null || echo 0)
    if [ "$total" -gt 0 ]; then
      local pct=$((done * 100 / total))
      local bar=""
      local filled=$((pct / 5))
      for ((i=0; i<filled; i++)); do bar+="█"; done
      for ((i=filled; i<20; i++)); do bar+="░"; done
      echo -e "${CYAN}[AFN]${NC} Progress: ${BOLD}[$bar] $pct%${NC} ($done/$total tasks)"
    fi
  fi
}

# Ctrl+C handler — clean exit
cleanup() {
  echo ""
  warn "Stopping... (STATE.md preserved)"
  show_progress
  exit 130
}
trap cleanup SIGINT SIGTERM

# Build prompt based on state
build_prompt() {
  local prompt=""
  if [ -f "$STATE_FILE" ]; then
    prompt="Resume mode: Read .afn/STATE.md and .afn/DESIGN.md, continue from where you left off. Do not ask questions, just work."
    if [ -n "$1" ]; then
      prompt="$1 — Also check .afn/STATE.md if it exists."
    fi
  else
    prompt="$1"
  fi
  echo "$prompt"
}

# First invocation
if [ -z "$TASK" ] && [ -f "$STATE_FILE" ]; then
  log "Existing state found. Resuming..."
  USER_PROMPT=$(build_prompt "")
elif [ -z "$TASK" ] && [ ! -f "$STATE_FILE" ]; then
  error "Nothing to do. Example: afn \"Create a full-stack booking system\""
  exit 1
else
  USER_PROMPT=$(build_prompt "$TASK")
fi

echo ""
log "========================================="
log "  ${BOLD}AFN Autonomous Loop Started${NC}"
log "========================================="
log "Task: ${TASK:-resume}"
[ -n "$BUDGET_PER_ITER" ] && log "Budget/iteration: \$$BUDGET_PER_ITER"
[ "$MAX_ITERATIONS" -gt 0 ] && log "Max iterations: $MAX_ITERATIONS"
log "Press Ctrl+C to stop"
echo ""

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  # Max iteration check
  if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
    warn "Max iterations reached ($MAX_ITERATIONS). Stopping."
    show_progress
    exit 0
  fi

  log "-----------------------------------------"
  log "Iteration ${BOLD}#$ITERATION${NC} starting..."
  show_progress
  log "-----------------------------------------"

  # Run Claude with FRESH context
  # --append-system-prompt: injects SKILL.md as system prompt
  # --print: non-interactive mode, single run
  # --dangerously-skip-permissions: autonomous operation
  CMD=(claude --print --dangerously-skip-permissions)
  CMD+=(--append-system-prompt "$(cat "$SKILL_FILE")")

  if [ -n "$BUDGET_PER_ITER" ]; then
    CMD+=(--max-budget-usd "$BUDGET_PER_ITER")
  fi

  "${CMD[@]}" "$USER_PROMPT" 2>&1

  EXIT_CODE=$?

  # All subsequent iterations use resume mode
  USER_PROMPT="Resume mode: Read .afn/STATE.md and .afn/DESIGN.md, continue from where you left off. Do not ask questions, just work."

  # Completion check
  if is_done; then
    echo ""
    success "========================================="
    success "  ${BOLD}PROJECT COMPLETED!${NC} ${GREEN}($ITERATION iterations)${NC}"
    success "========================================="
    show_progress

    if [ -f "$STATE_FILE" ]; then
      echo ""
      log "Final state:"
      cat "$STATE_FILE"
    fi
    exit 0
  fi

  # Pending task check
  if ! has_pending && [ -f "$STATE_FILE" ]; then
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      warn "State unclear after $MAX_RETRIES retries. Stopping."
      show_progress
      exit 1
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    warn "No pending tasks but not marked complete. Retrying ($RETRY_COUNT/$MAX_RETRIES)..."
  else
    RETRY_COUNT=0
  fi

  # Error handling
  if [ $EXIT_CODE -ne 0 ]; then
    warn "Claude exit code: $EXIT_CODE — retrying in 5s..."
    sleep 5
  fi

  log "Opening fresh context..."
  sleep 2
done
