#!/usr/bin/env bash
# dev.kit: Deterministic Engineering Flow (High-Fidelity ASCII Demo)
# Optimized for smoothness, speed, and graceful termination.

set -euo pipefail

# --- Configuration & Assets ---

# ANSI Colors (256-color palette for smoother look)
BLUE='\033[38;5;33m'
CYAN='\033[38;5;51m'
GREEN='\033[38;5;46m'
YELLOW='\033[38;5;226m'
PURPLE='\033[38;5;129m'
RED='\033[38;5;196m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Animation Frames (Braille Spinners)
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
CHECK="✔"
ARROW="▶"

# Hide cursor on start, restore on exit
# Note: We do NOT clear on EXIT so the final state remains in the scrollback/logs.
cleanup() {
    echo -ne "\e[?25h" # Restore cursor
    echo -e "${NC}"    # Reset colors
}
trap cleanup EXIT SIGINT SIGTERM

echo -ne "\e[?25l" # Hide cursor

# --- UI Functions ---

# Reset cursor to top-left of the current "view"
home() {
    echo -ne "\033[H"
}

# Center a string within a given width
center() {
    local text="$1"
    local width="${2:-80}"
    local stripped=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local n=${#stripped}
    local pad=$(( (width - n) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%${pad}s%b%${pad}s" "" "$text" ""
}

# --- Rendering Logic ---

render_frame() {
    local stage="$1"        # Current stage: intent, norm, agent, context, exec, done
    local intent="${2:-}"   # Human intent string
    local progress="${3:-0}" # 0-100 for exec stage
    local spin_idx="${4:-0}" # For the spinner

    home
    local buffer=""

    # 1. Header
    buffer+="${BLUE}${BOLD}$(center "dev.kit DETERMINISTIC ENGINEERING LOOP" 80)${NC}\n"
    buffer+="${DIM}$(center "────────────────────────────────────────────────────────────────────────" 80)${NC}\n\n"

    # 2. Intent Box
    local intent_c="${DIM}"; [[ "$stage" == "intent" ]] && intent_c="${YELLOW}${BOLD}"
    buffer+="$(printf "%22s" "") ${intent_c}╔══════════════════════════════════╗${NC}\n"
    buffer+="$(printf "%22s" "") ${intent_c}║          HUMAN INTENT            ║${NC}\n"
    buffer+="$(printf "%22s" "") ${intent_c}╚══════════════════════════════════╝${NC}\n"
    
    if [[ -n "$intent" ]]; then
        buffer+="$(printf "%22s" "") $(center "${BOLD}\"$intent\"${NC}" 34)\n"
    else
        buffer+="$(printf "%22s" "") $(center "${DIM}(waiting for intent...)${NC}" 34)\n"
    fi
    buffer+="\n"

    # 3. Connection & CLI/NG
    if [[ "$stage" != "intent" ]]; then
        buffer+="$(printf "%39s" "") ${BOLD}║${NC}\n"
        buffer+="$(printf "%39s" "") ${BOLD}▼${NC}\n"
        
        local cli_c="${NC}"; [[ "$stage" == "norm" ]] && cli_c="${PURPLE}${BOLD}"
        buffer+="$(printf "%27s" "") ${cli_c}╔═══════════════════════╗${NC}\n"
        buffer+="$(printf "%27s" "") ${cli_c}║      dev.kit CLI      ║${NC}\n"
        buffer+="$(printf "%27s" "") ${cli_c}╚═══════════════════════╝${NC}\n"
        
        if [[ "$stage" == "norm" || "$stage" == "agent" || "$stage" == "context" || "$stage" == "exec" || "$stage" == "done" ]]; then
            local ng_c="${PURPLE}"; [[ "$stage" == "norm" ]] && ng_c="${RED}${BOLD}"
            buffer+="$(printf "%32s" "") ${ng_c}╔═══════════╗${NC}\n"
            buffer+="$(printf "%32s" "") ${ng_c}║    NG     ║${NC}"
            [[ "$stage" == "norm" ]] && buffer+="  ${RED}${BOLD}← (STOP & ASK)${NC}"
            buffer+="\n$(printf "%32s" "") ${ng_c}╚═══════════╝${NC}\n"
        else
            buffer+="\n\n\n"
        fi
    else
        buffer+="\n\n\n\n\n\n\n"
    fi

    # 4. Agent & Context
    if [[ "$stage" == "agent" || "$stage" == "context" || "$stage" == "exec" || "$stage" == "done" ]]; then
        buffer+="$(printf "%39s" "") ║\n"
        buffer+="$(printf "%39s" "") ╚══════${ARROW} "
        
        local agent_c="${NC}"; [[ "$stage" == "agent" ]] && agent_c="${GREEN}${BOLD}"
        buffer+="${agent_c}╔═══════════════════╗${NC}\n"
        buffer+="$(printf "%50s" "") ${agent_c}║     AI AGENT      ║${NC}"
        [[ "$stage" == "agent" ]] && buffer+="  ${CYAN}${SPINNER[$spin_idx]} reasoning...${NC}"
        buffer+="\n$(printf "%50s" "") ${agent_c}╚═══════════════════╝${NC}\n"
        
        if [[ "$stage" == "context" || "$stage" == "exec" || "$stage" == "done" ]]; then
            buffer+="$(printf "%60s" "") ▲\n"
            buffer+="$(printf "%60s" "") ║\n"
            buffer+="$(printf "%39s" "") ╚════════════════════════╝ "
            
            local ctx_c="${NC}"; [[ "$stage" == "context" ]] && ctx_c="${BLUE}${BOLD}"
            buffer+="${ctx_c}╔═════════════════════╗${NC}\n"
            buffer+="$(printf "%65s" "") ${ctx_c}║    REPO CONTEXT     ║${NC}\n"
            buffer+="$(printf "%65s" "") ${ctx_c}╚═════════════════════╝${NC}\n"
        else
            buffer+="\n\n\n\n\n"
        fi
    else
        buffer+="\n\n\n\n\n\n\n"
    fi

    # 5. Working Status / Result
    buffer+="\n"
    if [[ "$stage" == "exec" ]]; then
        buffer+="$(printf "%20s" "") ${YELLOW}${BOLD}STATUS: Resolving Development Drift...${NC}\n"
        buffer+="$(printf "%20s" "") ${CYAN}${SPINNER[$spin_idx]}${NC} ["
        local filled=$(( progress / 5 ))
        for ((i=0; i<20; i++)); do
            if [ $i -lt $filled ]; then buffer+="${GREEN}█${NC}"; else buffer+="${DIM}░${NC}"; fi
        done
        buffer+="] ${BOLD}${progress}%${NC}\n"
        buffer+="$(printf "%20s" "") ${DIM}> Applying normalization to Workflow.md (DOC-003)${NC}\n"
    elif [[ "$stage" == "done" ]]; then
        buffer+="$(printf "%24s" "") ${GREEN}${BOLD}╔══════════════════════════════╗${NC}\n"
        buffer+="$(printf "%24s" "") ${GREEN}${BOLD}║       ${CHECK} DRIFT RESOLVED         ║${NC}\n"
        buffer+="$(printf "%24s" "") ${GREEN}${BOLD}╚══════════════════════════════╝${NC}\n"
        buffer+="$(printf "%24s" "") ${GREEN}${BOLD}${CHECK} Repository state synchronized.${NC}\n"
        buffer+="$(printf "%24s" "") ${GREEN}${BOLD}${CHECK} High-fidelity engineering verified.${NC}\n"
    else
        buffer+="\n\n\n\n"
    fi

    echo -ne "$buffer"
}

# --- Animation Sequencer ---

# Clear screen once at the very start
clear

# 1. Typing the Intent
intent_text="Optimizing repository for AI scale"
for ((i=1; i<=${#intent_text}; i++)); do
    render_frame "intent" "${intent_text:0:i}"
    sleep 0.03
done
sleep 0.5

# 2. CLI Detection & NG Gate
render_frame "norm" "$intent_text"
sleep 0.8

# 3. Agent Planning (with spinner)
for ((i=0; i<8; i++)); do
    render_frame "agent" "$intent_text" 0 $(( i % 10 ))
    sleep 0.1
done

# 4. Context Hydration
render_frame "context" "$intent_text"
sleep 0.6

# 5. Execution Progress (Smooth & Snappy)
for ((p=0; p<=100; p+=4)); do
    render_frame "exec" "$intent_text" "$p" $(( (p/4) % 10 ))
    sleep 0.05
done
sleep 0.3

# 6. Final Resolution
render_frame "done" "$intent_text"
echo -e "\n"

# Final Status Message (Persistent)
echo -e "$(center "${BOLD}Successfully reached deterministic state.${NC}" 80)"
echo -e "$(center "Run ${CYAN}dev.kit status${NC} to view the engineering report." 80)"
echo ""
