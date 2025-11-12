#!/bin/bash

# RexChat - Complete All-in-One Real-Time Chat System
# Colors for beautiful interface
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

# Configuration files
USER_FILE="rexchat_users.txt"
CHAT_FILE="rexchat_messages.txt"
ONLINE_FILE="rexchat_online.txt"
CURRENT_USER_FILE="rexchat_current_user.txt"
THEME_FILE="rexchat_theme.txt"
LOG_FILE="rexchat.log"

# Create files if they don't exist
touch "$USER_FILE"
touch "$CHAT_FILE"
touch "$ONLINE_FILE"
touch "$CURRENT_USER_FILE"
touch "$THEME_FILE"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║ ██████╗ ███████╗██╗  ██╗ ██████╗██╗  ██╗ █████╗ ████████╗ ║"
    echo "║ ██╔══██╗██╔════╝╚██╗██╔╝██╔════╝██║  ██║██╔══██╗╚══██╔══╝ ║"
    echo "║ ██████╔╝█████╗   ╚███╔╝ ██║     ███████║███████║   ██║    ║"
    echo "║ ██╔══██╗██╔══╝   ██╔██╗ ██║     ██╔══██║██╔══██║   ██║    ║"
    echo "║ ██║  ██║███████╗██╔╝ ██╗╚██████╗██║  ██║██║  ██║   ██║    ║"
    echo "║ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}           Real-Time Chat System for Termux${NC}"
    echo -e "${GREEN}             Beginner Friendly - All in One${NC}"
    echo "=================================================="
}

# User registration
register_user() {
    echo -e "\n${YELLOW}=== CREATE NEW ACCOUNT ===${NC}"
    read -p "Enter your nickname: " nickname
    
    # Check if nickname already exists
    if grep -q "^$nickname:" "$USER_FILE"; then
        echo -e "${RED}❌ Nickname already exists! Please choose another one.${NC}"
        return 1
    fi
    
    read -s -p "Enter password: " password
    echo
    read -s -p "Confirm password: " password_confirm
    echo
    
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}❌ Passwords don't match!${NC}"
        return 1
    fi
    
    if [ -z "$nickname" ] || [ -z "$password" ]; then
        echo -e "${RED}❌ Nickname and password cannot be empty!${NC}"
        return 1
    fi
    
    # Simple password hash
    password_hash=$(echo -n "$password" | base64)
    echo "$nickname:$password_hash" >> "$USER_FILE"
    
    echo -e "${GREEN}✅ Registration successful! You can now login.${NC}"
    log "New user registered: $nickname"
    return 0
}

# User login
login_user() {
    echo -e "\n${YELLOW}=== LOGIN TO CHAT ===${NC}"
    read -p "Enter your nickname: " nickname
    read -s -p "Enter password: " password
    echo
    
    if [ -z "$nickname" ] || [ -z "$password" ]; then
        echo -e "${RED}❌ Nickname and password cannot be empty!${NC}"
        return 1
    fi
    
    # Check credentials
    password_hash=$(echo -n "$password" | base64)
    if grep -q "^$nickname:$password_hash$" "$USER_FILE"; then
        echo -e "${GREEN}✅ Login successful! Welcome back, $nickname!${NC}"
        log "User logged in: $nickname"
        
        # Set current user
        echo "$nickname" > "$CURRENT_USER_FILE"
        return 0
    else
        echo -e "${RED}❌ Invalid nickname or password!${NC}"
        log "Failed login attempt for: $nickname"
        return 1
    fi
}

# Set chat theme
set_theme() {
    case $1 in
        "CHATROOM")
            theme_name="CHATROOM"
            border_color=$CYAN
            header_color=$GREEN
            system_color=$YELLOW
            ;;
        "OCEAN")
            theme_name="OCEAN"
            border_color=$BLUE
            header_color=$CYAN
            system_color=$GREEN
            ;;
        "FOREST")
            theme_name="FOREST"
            border_color=$GREEN
            header_color=$YELLOW
            system_color=$ORANGE
            ;;
        "ROYAL")
            theme_name="ROYAL"
            border_color=$PURPLE
            header_color=$YELLOW
            system_color=$CYAN
            ;;
        *)
            theme_name="CHATROOM"
            border_color=$CYAN
            header_color=$GREEN
            system_color=$YELLOW
            ;;
    esac
    echo "$theme_name" > "$THEME_FILE"
}

# Display chat header
display_header() {
    clear
    echo -e "${border_color}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${border_color}║${header_color}                    🏠 REXCHAT CHATROOM                     ${border_color}║${NC}"
    echo -e "${border_color}║${header_color}                     Theme: $theme_name                      ${border_color}║${NC}"
    echo -e "${border_color}║${YELLOW}                 User: $nickname                               ${border_color}║${NC}"
    echo -e "${border_color}╠════════════════════════════════════════════════════════════╣${NC}"
}

# Display messages with colors
display_messages() {
    local last_lines=${1:-15}
    
    # Get last messages and format them
    tail -n "$last_lines" "$CHAT_FILE" | while IFS= read -r line; do
        if [[ "$line" =~ ^\[(.*)\]\ (.*):\ (.*)$ ]]; then
            timestamp="${BASH_REMATCH[1]}"
            user="${BASH_REMATCH[2]}"
            message="${BASH_REMATCH[3]}"
            
            if [ "$user" == "SYSTEM" ]; then
                echo -e "${border_color}║${system_color}[$timestamp] $user: $message${NC}"
            elif [ "$user" == "$nickname" ]; then
                echo -e "${border_color}║${YELLOW}[$timestamp] $user:${NC} ${BLUE}$message${NC}"
            else
                echo -e "${border_color}║${YELLOW}[$timestamp] $user:${NC} $message"
            fi
        else
            echo -e "${border_color}║$line${NC}"
        fi
    done | tail -n "$last_lines"
}

# Real-time chat function
start_chat() {
    local nickname=$1
    
    # Load theme
    current_theme=$(cat "$THEME_FILE")
    set_theme "$current_theme"
    
    # Add user to online list
    echo "$nickname" >> "$ONLINE_FILE"
    
    # Add join message
    timestamp=$(date '+%H:%M:%S')
    echo -e "[$timestamp] SYSTEM: $nickname joined the chatroom" >> "$CHAT_FILE"
    
    # Cleanup function
    cleanup() {
        # Remove user from online list
        if [ -f "$ONLINE_FILE" ]; then
            grep -v "^$nickname$" "$ONLINE_FILE" > "${ONLINE_FILE}.tmp" && mv "${ONLINE_FILE}.tmp" "$ONLINE_FILE"
        fi
        
        # Add leave message
        timestamp=$(date '+%H:%M:%S')
        echo -e "[$timestamp] SYSTEM: $nickname left the chatroom" >> "$CHAT_FILE"
        
        echo -e "\n${GREEN}Disconnected from chatroom. Goodbye!${NC}"
    }
    
    trap cleanup EXIT INT TERM
    
    # Real-time chat loop
    local refresh_rate=2
    local last_modified=0
    
    while true; do
        # Check if chat file was modified
        current_modified=$(stat -c %Y "$CHAT_FILE" 2>/dev/null || echo 0)
        
        # Only refresh display if there are changes
        if [ "$current_modified" -ne "$last_modified" ]; then
            last_modified=$current_modified
            
            display_header
            display_messages 15
            echo -e "${border_color}╠════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${border_color}║${GREEN} Commands: /exit /clear /theme /users /help                  ${border_color}║${NC}"
            echo -e "${border_color}╚════════════════════════════════════════════════════════════╝${NC}"
            echo -n -e "${GREEN}Type your message: ${NC}"
        fi
        
        # Non-blocking read for user input
        if read -t 0.5 -r message; then
            case "$message" in
                "/exit")
                    break
                    ;;
                "/clear")
                    > "$CHAT_FILE"
                    echo -e "${border_color}║${system_color}SYSTEM: Chat cleared by $nickname${NC}" >> "$CHAT_FILE"
                    ;;
                "/theme")
                    echo -e "\n${header_color}Available Themes:${NC}"
                    echo "1. CHATROOM (Default) - Cyan/Green"
                    echo "2. OCEAN - Blue/Cyan"
                    echo "3. FOREST - Green/Yellow" 
                    echo "4. ROYAL - Purple/Yellow"
                    read -p "Select theme [1-4]: " theme_choice
                    
                    case $theme_choice in
                        1) set_theme "CHATROOM" ;;
                        2) set_theme "OCEAN" ;;
                        3) set_theme "FOREST" ;;
                        4) set_theme "ROYAL" ;;
                        *) echo -e "${RED}Invalid theme!${NC}" ;;
                    esac
                    ;;
                "/users")
                    echo -e "\n${YELLOW}=== Online Users ===${NC}"
                    if [ -f "$ONLINE_FILE" ] && [ -s "$ONLINE_FILE" ]; then
                        cat "$ONLINE_FILE"
                    else
                        echo "No users online"
                    fi
                    echo -e "${YELLOW}===================${NC}"
                    read -p "Press Enter to continue..."
                    ;;
                "/help")
                    echo -e "\n${GREEN}=== Chat Commands ===${NC}"
                    echo "/exit   - Leave chatroom"
                    echo "/clear  - Clear chat history"
                    echo "/theme  - Change chat theme"
                    echo "/users  - Show online users"
                    echo "/help   - Show this help"
                    echo -e "${GREEN}=====================${NC}"
                    read -p "Press Enter to continue..."
                    ;;
                "")
                    # Empty message, do nothing
                    ;;
                *)
                    timestamp=$(date '+%H:%M:%S')
                    echo -e "[$timestamp] $nickname: $message" >> "$CHAT_FILE"
                    ;;
            esac
        fi
    done
}

# Authentication menu
auth_menu() {
    while true; do
        echo -e "\n${GREEN}=== REXCHAT MAIN MENU ===${NC}"
        echo "1. Login to Chatroom"
        echo "2. Create New Account"
        echo "3. View Online Users"
        echo "4. How to Use Tutorial"
        echo "5. Exit"
        read -p "Choose option [1-5]: " choice
        
        case $choice in
            1)
                if login_user; then
                    nickname=$(cat "$CURRENT_USER_FILE")
                    echo -e "\n${GREEN}Entering chatroom...${NC}"
                    sleep 2
                    start_chat "$nickname"
                else
                    echo -e "\n${RED}Login failed. Please try again.${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                register_user
                if [ $? -eq 0 ]; then
                    read -p "Press Enter to continue..."
                else
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                echo -e "\n${YELLOW}=== Online Users ===${NC}"
                if [ -f "$ONLINE_FILE" ] && [ -s "$ONLINE_FILE" ]; then
                    cat "$ONLINE_FILE"
                else
                    echo "No users online"
                fi
                echo -e "${YELLOW}===================${NC}"
                read -p "Press Enter to continue..."
                ;;
            4)
                show_tutorial
                ;;
            5)
                echo -e "${GREEN}Goodbye! Thanks for using RexChat.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option! Please choose 1-5.${NC}"
                ;;
        esac
    done
}

# Tutorial function
show_tutorial() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║              REXCHAT TUTORIAL               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${YELLOW}📖 HOW TO USE REXCHAT:${NC}"
    echo ""
    echo -e "${GREEN}🚀 GETTING STARTED:${NC}"
    echo "1. First, choose 'Create New Account' to make your account"
    echo "2. Then 'Login to Chatroom' to start chatting"
    echo ""
    echo -e "${GREEN}💬 IN THE CHATROOM:${NC}"
    echo "• Type your message and press Enter to send"
    echo "• Messages appear in ${BLUE}blue${NC} for you, ${YELLOW}yellow${NC} for others"
    echo "• System messages appear in different colors"
    echo ""
    echo -e "${GREEN}⚡ CHAT COMMANDS:${NC}"
    echo "/exit   - Leave the chatroom"
    echo "/clear  - Clear all messages"
    echo "/theme  - Change the chat colors"
    echo "/users  - See who's online"
    echo "/help   - Show this help"
    echo ""
    echo -e "${GREEN}👥 MULTI-USER CHAT:${NC}"
    echo "• Multiple users can chat on the same device"
    echo "• Each user needs their own account"
    echo "• All messages are saved in real-time"
    echo ""
    echo -e "${GREEN}🎨 THEMES:${NC}"
    echo "• CHATROOM: Default cyan/green theme"
    echo "• OCEAN: Beautiful blue colors"
    echo "• FOREST: Green nature theme"
    echo "• ROYAL: Purple royal theme"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT:${NC}"
    echo "• Don't delete the .txt files - they store your data!"
    echo "• All users must be in the same folder to chat together"
    echo "• Messages are saved even after closing the app"
    echo ""
    
    read -p "Press Enter to return to main menu..."
}

# Installation check
check_installation() {
    echo -e "${YELLOW}Checking installation...${NC}"
    
    # Check if all required files are created
    required_files=("$USER_FILE" "$CHAT_FILE" "$ONLINE_FILE" "$CURRENT_USER_FILE" "$THEME_FILE" "$LOG_FILE")
    
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✅ $file - OK${NC}"
        else
            echo -e "${RED}❌ $file - Missing${NC}"
            touch "$file"
        fi
    done
    
    # Set default theme if not set
    if [ ! -s "$THEME_FILE" ]; then
        echo "CHATROOM" > "$THEME_FILE"
    fi
    
    echo -e "${GREEN}✅ Installation check complete!${NC}"
    sleep 2
}

# Main function
main() {
    show_banner
    check_installation
    auth_menu
}

# Start the application
main
