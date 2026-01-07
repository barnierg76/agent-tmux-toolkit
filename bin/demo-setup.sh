#!/bin/bash
# demo-setup.sh - Set up demo environment for screenshots
# Creates agent session with realistic content in each pane
set -e

# Source shared utilities
source "$(dirname "$0")/agent-common.sh"

SESSION_NAME="${1:-demo-agents}"
DEMO_MODE="${2:-screenshot}"  # screenshot or interactive

# Kill existing demo session if exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo -e "${YELLOW}Killing existing session '$SESSION_NAME'...${NC}"
    tmux kill-session -t "$SESSION_NAME"
fi

echo -e "${BLUE}Creating demo session '$SESSION_NAME'...${NC}"

# Create new session with first pane (Plan)
tmux new-session -d -s "$SESSION_NAME" -n "agents" -c "$(pwd)"

# Split horizontally for Work pane (middle)
tmux split-window -h -t "$SESSION_NAME:agents" -c "$(pwd)"

# Split horizontally again for Review pane (right)
tmux split-window -h -t "$SESSION_NAME:agents" -c "$(pwd)"

# Even out the three panes (33% each)
tmux select-layout -t "$SESSION_NAME:agents" even-horizontal

# Get actual pane IDs
PANE_IDS=($(tmux list-panes -t "$SESSION_NAME:agents" -F "#{pane_id}"))

# Set roles
tmux set-option -p -t "${PANE_IDS[0]}" @role "PLAN"
tmux set-option -p -t "${PANE_IDS[1]}" @role "WORK"
tmux set-option -p -t "${PANE_IDS[2]}" @role "REVIEW"

# Set pane titles
tmux select-pane -t "${PANE_IDS[0]}" -T "auth-feature"
tmux select-pane -t "${PANE_IDS[1]}" -T "auth-feature"
tmux select-pane -t "${PANE_IDS[2]}" -T "auth-feature"

# Function to send content to pane using printf for reliable output
send_plan_content() {
    local pane_id="$1"
    tmux send-keys -t "$pane_id" "clear" Enter
    sleep 0.3
    # Use printf with echo for clean multi-line output
    tmux send-keys -t "$pane_id" -l 'printf "%s\n" "$ claude" "" "> Planning authentication feature..." "" "Research complete. Here is the plan:" "" "## Implementation Tasks" "" "- [x] Research OAuth2 best practices" "- [x] Design token refresh flow" "- [ ] Create auth middleware" "- [ ] Add session management" "- [ ] Write integration tests" "" "Ready for implementation phase."'
    tmux send-keys -t "$pane_id" Enter
}

send_work_content() {
    local pane_id="$1"
    tmux send-keys -t "$pane_id" "clear" Enter
    sleep 0.3
    tmux send-keys -t "$pane_id" -l 'printf "%s\n" "$ claude" "" "> Implementing auth middleware..." "" "Created: src/middleware/auth.ts" "" "export const authMiddleware = async (" "  req: Request," "  res: Response," "  next: NextFunction" ") => {" "  const token = req.headers.authorization;" "  if (!token) return res.status(401);" "  const user = await verifyToken(token);" "  req.user = user;" "  next();" "};"'
    tmux send-keys -t "$pane_id" Enter
}

send_review_content() {
    local pane_id="$1"
    tmux send-keys -t "$pane_id" "clear" Enter
    sleep 0.3
    tmux send-keys -t "$pane_id" -l 'printf "%s\n" "$ claude" "" "> Running tests and code review..." "" "## Test Results" "v auth.middleware.test.ts (12 tests)" "v session.test.ts (8 tests)" "v integration/auth.test.ts (5 tests)" "" "All 25 tests passed" "" "## Lint Check" "v No ESLint errors" "v TypeScript compilation successful" "" "Ready for PR creation."'
    tmux send-keys -t "$pane_id" Enter
}

echo -e "${CYAN}Populating panes with demo content...${NC}"

# Send content to each pane
send_plan_content "${PANE_IDS[0]}"
send_work_content "${PANE_IDS[1]}"
send_review_content "${PANE_IDS[2]}"

# Wait for content to render
sleep 1

# Focus on the middle (WORK) pane for screenshot
tmux select-pane -t "${PANE_IDS[1]}"

echo -e "${GREEN}Demo session ready!${NC}"
echo ""
echo -e "${CYAN}To capture screenshot:${NC}"
echo "  1. Attach to session: tmux attach -t $SESSION_NAME"
echo "  2. Press Option+F to open agent-flow menu"
echo "  3. Take screenshot (Cmd+Shift+4 on macOS)"
echo ""
echo -e "${CYAN}Or attach now:${NC}"

if [[ "$DEMO_MODE" == "interactive" ]]; then
    tmux attach -t "$SESSION_NAME"
else
    echo "  tmux attach -t $SESSION_NAME"
fi
