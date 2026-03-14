#!/bin/bash
# AFN Loop Runner — Sinirsiz otonom dongu
# Her iterasyonda TAZE context baslatir. Compact/rot YOK.
# STATE.md "TAMAMLANDI" olana kadar durMAZ.
#
# Kullanim:
#   afn "Bana radyo sitesi yap"              # Yeni proje
#   afn                                       # Devam (STATE.md varsa)
#   afn "yeni: E-ticaret sitesi yap"         # Sifirdan basla
#   afn --budget 1 "Radyo sitesi yap"        # Iterasyon basina max $1
#   afn --max-iter 10 "Radyo sitesi yap"     # Max 10 iterasyon

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="$SCRIPT_DIR/SKILL.md"
AFN_DIR=".afn"
STATE_FILE="$AFN_DIR/STATE.md"
MAX_RETRIES=3
RETRY_COUNT=0
BUDGET_PER_ITER=""
MAX_ITERATIONS=0

# Renk kodlari
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

# Skill dosyasi kontrol
if [ ! -f "$SKILL_FILE" ]; then
  error "SKILL.md bulunamadi: $SKILL_FILE"
  exit 1
fi

# Argumanlari isle
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

# Tamamlanma kontrolu
is_done() {
  if [ -f "$STATE_FILE" ]; then
    grep -qi "TAMAMLANDI\|COMPLETED\|DONE" "$STATE_FILE" && return 0
  fi
  return 1
}

# Bekleyen gorev var mi?
has_pending() {
  if [ -f "$STATE_FILE" ]; then
    grep -q "\- \[ \]" "$STATE_FILE" && return 0
  fi
  return 1
}

# Ilerleme goster
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
      echo -e "${CYAN}[AFN]${NC} Ilerleme: ${BOLD}[$bar] $pct%${NC} ($done/$total gorev)"
    fi
  fi
}

# Ctrl+C handler
cleanup() {
  echo ""
  warn "Durduruluyor... (STATE.md korunuyor)"
  show_progress
  exit 130
}
trap cleanup SIGINT SIGTERM

# Prompt olustur
build_prompt() {
  local prompt=""
  if [ -f "$STATE_FILE" ]; then
    prompt="Devam modu: .afn/STATE.md ve .afn/DESIGN.md dosyalarini oku, kaldığın yerden devam et."
    if [ -n "$1" ]; then
      prompt="$1 — Ayrica .afn/STATE.md varsa kontrol et."
    fi
  else
    prompt="$1"
  fi
  echo "$prompt"
}

# Ilk cagri
if [ -z "$TASK" ] && [ -f "$STATE_FILE" ]; then
  log "Mevcut state bulundu. Devam ediliyor..."
  USER_PROMPT=$(build_prompt "")
elif [ -z "$TASK" ] && [ ! -f "$STATE_FILE" ]; then
  error "Ne yapayim? Ornek: afn \"Bana radyo sitesi yap\""
  exit 1
else
  USER_PROMPT=$(build_prompt "$TASK")
fi

echo ""
log "========================================="
log "  ${BOLD}AFN Otonom Dongu Baslatildi${NC}"
log "========================================="
log "Gorev: ${TASK:-devam}"
[ -n "$BUDGET_PER_ITER" ] && log "Budget/iterasyon: \$$BUDGET_PER_ITER"
[ "$MAX_ITERATIONS" -gt 0 ] && log "Max iterasyon: $MAX_ITERATIONS"
log "Durdurmak icin: Ctrl+C"
echo ""

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))

  # Max iterasyon kontrolu
  if [ "$MAX_ITERATIONS" -gt 0 ] && [ "$ITERATION" -gt "$MAX_ITERATIONS" ]; then
    warn "Max iterasyon sayisina ulasildi ($MAX_ITERATIONS). Durduruluyor."
    show_progress
    exit 0
  fi

  log "-----------------------------------------"
  log "Iterasyon ${BOLD}#$ITERATION${NC} basliyor..."
  show_progress
  log "-----------------------------------------"

  # Claude'u TAZE context ile calistir
  # --append-system-prompt: SKILL.md'yi system prompt olarak enjekte eder
  # --print: non-interactive mod, tek seferlik calisir
  # --dangerously-skip-permissions: otonom calisma icin
  CMD=(claude --print --dangerously-skip-permissions)
  CMD+=(--append-system-prompt "$(cat "$SKILL_FILE")")

  if [ -n "$BUDGET_PER_ITER" ]; then
    CMD+=(--max-budget-usd "$BUDGET_PER_ITER")
  fi

  "${CMD[@]}" "$USER_PROMPT" 2>&1

  EXIT_CODE=$?

  # Sonraki iterasyonlar hep devam modu
  USER_PROMPT="Devam modu: .afn/STATE.md ve .afn/DESIGN.md dosyalarini oku, kaldığın yerden devam et. Soru sorma, hemen calis."

  # Tamamlanma kontrolu
  if is_done; then
    echo ""
    success "========================================="
    success "  ${BOLD}PROJE TAMAMLANDI!${NC} ${GREEN}($ITERATION iterasyon)${NC}"
    success "========================================="
    show_progress

    if [ -f "$STATE_FILE" ]; then
      echo ""
      log "Son durum:"
      cat "$STATE_FILE"
    fi
    exit 0
  fi

  # Bekleyen gorev kontrolu
  if ! has_pending && [ -f "$STATE_FILE" ]; then
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      warn "State belirsiz, $MAX_RETRIES deneme yapildi. Durduruluyor."
      show_progress
      exit 1
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    warn "Bekleyen gorev yok ama tamamlanma isaretlenmemis. Tekrar ($RETRY_COUNT/$MAX_RETRIES)..."
  else
    RETRY_COUNT=0
  fi

  # Hata durumu
  if [ $EXIT_CODE -ne 0 ]; then
    warn "Claude exit code: $EXIT_CODE — 5sn bekleyip tekrar..."
    sleep 5
  fi

  log "Yeni taze context aciliyor..."
  sleep 2
done
