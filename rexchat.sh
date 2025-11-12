#!/bin/bash

# RexChat - Terminal Chat Application for Termux
# Colors: Blue messages, Yellow names

# Configuration
USER_FILE="rexchat_users.txt"
CHAT_FILE="rexchat_messages.txt"
LOG_FILE="rexchat.log"

# Color codes
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Create files if they don't exist
touch "$USER_FILE"
touch "$CHAT_FILE"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Clear screen
clear

# Banner
echo -e "${GREEN}"
echo "  ____  _____ _    _  ____ _    _ _______ _____ "
echo " |  _ \|  __  \ \/ / / __ \ |  | |__   __|  __ \\"
echo " | |_) | |__) |\  / | |  | |  | |  | |  | |__) |"
echo " |  _ <|  _  / /  \ | |  | |  | |  | |  |  _  / "
echo " | |_) | | \ \/ /\ \| |__| |__| |  | |  | | \ \\"
echo " |____/|_|  \_/_/  \_\ ___/\____/   |_|  |_|  \_\\"
echo -e "${NC}"
echo "=================================================="

# User authentication
authenticate_user() {
    while true; do
        echo -e "\n${GREEN}RexChat - Authentication${NC}"
        echo "1. Register"
        echo "2. Login"
        echo "3. Exit"
        read -p "Choose option [1-3]: " choice
        
        case $choice in
            1) register_user ;;
            2) login_user ;;
            3) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid option!${NC}" ;;
        esac
    done
}

# Register new user
register_user() {
    echo -e "\n${YELLOW}=== User Registration ===${NC}"
    read -p "Enter nickname: " nickname
    
    # Check if nickname already exists
    if grep -q "^$nickname:" "$USER_FILE"; then
        echo -e "${RED}Nickname already exists!${NC}"
        return
    fi
    
    read -s -p "Enter password: " password
    echo
    read -s -p "Confirm password: " password_confirm
    echo
    
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}Passwords don't match!${NC}"
        return
    fi
    
    if [ -z "$nickname" ] || [ -z "$password" ]; then
        echo -e "${RED}Nickname and password cannot be empty!${NC}"
        return
    fi
    
    # Hash password (simple base64 for demonstration)
    password_hash=$(echo -n "$password" | base64)
    echo "$nickname:$password_hash" >> "$USER_FILE"
    
    echo -e "${GREEN}Registration successful! You can now login.${NC}"
    log "New user registered: $nickname"
}

# Login user
login_user() {
    echo -e "\n${YELLOW}=== User Login ===${NC}"
    read -p "Enter nickname: " nickname
    read -s -p "Enter password: " password
    echo
    
    if [ -z "$nickname" ] || [ -z "$password" ]; then
        echo -e "${RED}Nickname and password cannot be empty!${NC}"
        return 1
    fi
    
    # Check credentials
    password_hash=$(echo -n "$password" | base64)
    if grep -q "^$nickname:$password_hash$" "$USER_FILE"; then
        echo -e "${GREEN}Login successful! Welcome back, $nickname!${NC}"
        log "User logged in: $nickname"
        return 0
    else
        echo -e "${RED}Invalid nickname or password!${NC}"
        log "Failed login attempt for: $nickname"
        return 1
    fi
}

# Display chat messages
display_chat() {
    clear
    echo -e "${GREEN}=== RexChat - Live Chat ===${NC}"
    echo -e "${YELLOW}Logged in as: $nickname${NC}"
    echo "Type 'exit' to leave chat"
    echo "Type 'clear' to clear chat"
    echo "Type 'users' to show online users"
    echo "----------------------------------------"
    
    # Display last 20 messages
    tail -n 20 "$CHAT_FILE" | while IFS= read -r line; do
        if [[ "$line" =~ ^\[(.*)\]\ (.*):\ (.*)$ ]]; then
            timestamp="${BASH_REMATCH[1]}"
            user="${BASH_REMATCH[2]}"
            message="${BASH_REMATCH[3]}"
            
            if [ "$user" == "$nickname" ]; then
                echo -e "${YELLOW}[$timestamp] $user:${NC} ${BLUE}$message${NC}"
            else
                echo -e "${YELLOW}[$timestamp] $user:${NC} $message"
            fi
        else
            echo "$line"
        fi
    done
    echo "----------------------------------------"
}

# Chat function
chat_loop() {
    local nickname=$1
    
    while true; do
        display_chat
        echo -n ">> "
        read message
        
        case "$message" in
            exit)
                echo -e "${GREEN}Goodbye! Thanks for using RexChat.${NC}"
                log "User left chat: $nickname"
                exit 0
                ;;
            clear)
                > "$CHAT_FILE"
                echo -e "${GREEN}Chat cleared!${NC}"
                sleep 1
                ;;
            users)
                echo -e "\n${YELLOW}=== Registered Users ===${NC}"
                cut -d: -f1 "$USER_FILE" | sort | uniq
                echo -e "Press Enter to continue..."
                read
                ;;
            "")
                continue
                ;;
            *)
                timestamp=$(date '+%H:%M:%S')
                echo "[$timestamp] $nickname: $message" >> "$CHAT_FILE"
                log "Message from $nickname: $message"
                ;;
        esac
    done
}

# Online users monitoring (background process)
monitor_chat() {
    local last_modified=0
    while true; do
        current_modified=$(stat -c %Y "$CHAT_FILE" 2>/dev/null || echo 0)
        if [ "$current_modified" -ne "$last_modified" ]; then
            last_modified=$current_modified
            # This will be handled in the main display
            :
        fi
        sleep 2
    done
}

# Main execution
main() {
    # Try to login
    while true; do
        if login_user; then
            break
        fi
        echo -e "\n${RED}Login failed. Try again or register new account.${NC}"
        read -p "Press Enter to continue..."
        clear
        authenticate_user
    done
    
    # Start chat
    echo -e "\n${GREEN}Connecting to RexChat...${NC}"
    sleep 2
    
    # Add join message
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] SYSTEM: $nickname joined the chat" >> "$CHAT_FILE"
    
    # Start monitoring in background
    monitor_chat &
    monitor_pid=$!
    
    # Start chat loop
    chat_loop "$nickname"
    
    # Cleanup
    kill $monitor_pid 2>/dev/null
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] SYSTEM: $nickname left the chat" >> "$CHAT_FILE"
}

# Handle script interruption
trap 'echo -e "\n${RED}Script interrupted. Goodbye!${NC}"; kill $monitor_pid 2>/dev/null; exit 1' INT TERM

# Start the application
if [ "$1" == "--register" ]; then
    register_user
    exit 0
elif [ "$1" == "--login" ]; then
    login_user
    if [ $? -eq 0 ]; then
        main
    fi
else
    authenticate_user
fi
