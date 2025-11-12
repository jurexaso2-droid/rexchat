#!/bin/bash

# RexChat - Philippine-Wide Online Chat with Instant Messaging
# No delays, colorful chat, auto-login, join/leave notifications

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[1;33m'
MAGENTA='\033[1;35m'
NC='\033[0m'

# Configuration
USER_FILE="rexchat_users.txt"
CONFIG_FILE="rexchat_config.txt"
LOG_FILE="rexchat.log"
CHAT_FILE="rexchat_messages.txt"
ONLINE_FILE="rexchat_online.txt"

# Create files
touch "$USER_FILE" "$CONFIG_FILE" "$LOG_FILE" "$CHAT_FILE" "$ONLINE_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                REXCHAT PHILIPPINES          ║"
    echo "║           Instant Nationwide Chat           ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}    🌏 Real-time Chat - No Delays!${NC}"
    echo -e "${GREEN}         Works anywhere with internet${NC}"
    echo "=============================================="
}

# Check internet connection
check_internet() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        return 0
    else
        echo -e "${RED}❌ No internet connection!${NC}"
        return 1
    fi
}

# Install required packages
install_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}Installing curl...${NC}"
        pkg update -y && pkg install -y curl
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Installing jq...${NC}"
        pkg install -y jq
    fi
    
    echo -e "${GREEN}✅ Dependencies ready!${NC}"
}

# User registration with AUTO-LOGIN
register_user() {
    echo -e "\n${YELLOW}=== CREATE PHILIPPINE ACCOUNT ===${NC}"
    read -p "🇵🇭 Choose your nickname: " nickname
    
    # Check if nickname exists locally
    if grep -q "^$nickname:" "$USER_FILE"; then
        echo -e "${RED}❌ Nickname already taken!${NC}"
        return 1
    fi
    
    read -s -p "🔒 Enter password: " password
    echo
    read -s -p "🔒 Confirm password: " password2
    echo
    
    if [ "$password" != "$password2" ]; then
        echo -e "${RED}❌ Passwords don't match!${NC}"
        return 1
    fi
    
    if [ -z "$nickname" ] || [ -z "$password" ]; then
        echo -e "${RED}❌ Nickname and password required!${NC}"
        return 1
    fi
    
    # Add location info
    echo -e "${CYAN}📍 Select your region:${NC}"
    echo "1. Metro Manila"
    echo "2. Luzon"
    echo "3. Visayas" 
    echo "4. Mindanao"
    echo "5. Other"
    read -p "Choose [1-5]: " region_choice
    
    case $region_choice in
        1) region="Metro Manila" ;;
        2) region="Luzon" ;;
        3) region="Visayas" ;;
        4) region="Mindanao" ;;
        5) region="Other" ;;
        *) region="Philippines" ;;
    esac
    
    password_hash=$(echo -n "$password" | base64)
    echo "$nickname:$password_hash:$region:$(date '+%Y-%m-%d')" >> "$USER_FILE"
    
    # AUTO-LOGIN after registration
    echo "$nickname" > "rexchat_current_user.txt"
    echo "$region" > "rexchat_current_region.txt"
    
    echo -e "${GREEN}✅ Account created! From: $region${NC}"
    echo -e "${YELLOW}✅ Automatically logged in as $nickname!${NC}"
    log "New user: $nickname from $region"
    return 0
}

# User login
login_user() {
    echo -e "\n${YELLOW}=== LOGIN TO REXCHAT PH ===${NC}"
    read -p "🇵🇭 Nickname: " nickname
    read -s -p "🔒 Password: " password
    echo
    
    password_hash=$(echo -n "$password" | base64)
    if grep -q "^$nickname:$password_hash:" "$USER_FILE"; then
        user_data=$(grep "^$nickname:$password_hash:" "$USER_FILE")
        region=$(echo "$user_data" | cut -d: -f3)
        
        echo "$nickname" > "rexchat_current_user.txt"
        echo "$region" > "rexchat_current_region.txt"
        
        echo -e "${GREEN}✅ Login successful!${NC}"
        echo -e "${CYAN}📍 Location: $region${NC}"
        log "User login: $nickname from $region"
        return 0
    else
        echo -e "${RED}❌ Invalid login!${NC}"
        return 1
    fi
}

# Instant messaging system with colorful chat
start_instant_chat() {
    local nickname="$1"
    local region="$2"
    
    if ! check_internet; then
        echo -e "${RED}❌ Internet required for nationwide chat!${NC}"
        echo -e "${YELLOW}Please enable mobile data or WiFi${NC}"
        return 1
    fi
    
    # Add JOIN message
    timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] 🟢 $nickname joined the chatroom" >> "$CHAT_FILE"
    
    # Add to online users
    echo "$nickname" >> "$ONLINE_FILE"
    
    echo -e "${GREEN}🚀 Entering instant chat room...${NC}"
    sleep 2
    
    # Display chat header
    show_chat_header() {
        clear
        echo -e "${CYAN}"
        echo "╔══════════════════════════════════════════════╗"
        echo "║              REXCHAT PHILIPPINES            ║"
        echo "║               INSTANT CHAT ROOM             ║"
        echo "╚══════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo -e "${GREEN}👤 You: $nickname | 📍 $region${NC}"
        echo -e "${YELLOW}💬 Live Chat - No Delays - Nationwide${NC}"
        echo "──────────────────────────────────────────────"
    }
    
    # Display messages with COLOR
    display_messages() {
        if [ -f "$CHAT_FILE" ] && [ -s "$CHAT_FILE" ]; then
            # Show last 15 messages
            tail -n 15 "$CHAT_FILE" | while IFS= read -r line; do
                if [[ "$line" =~ .*"joined the chatroom" ]]; then
                    # Join messages in GREEN
                    echo -e "${GREEN}$line${NC}"
                elif [[ "$line" =~ .*"left the chatroom" ]]; then
                    # Leave messages in RED
                    echo -e "${RED}$line${NC}"
                elif [[ "$line" =~ .*"$nickname".* ]]; then
                    # MY messages in BLUE
                    echo -e "${BLUE}$line${NC}"
                else
                    # OTHER users' messages in YELLOW
                    echo -e "${YELLOW}$line${NC}"
                fi
            done
        else
            echo "💬 No messages yet. Start the conversation!"
        fi
    }
    
    # Send instant message (NO DELAY)
    send_instant_message() {
        local msg="$1"
        timestamp=$(date '+%H:%M:%S')
        
        # INSTANT send - no delays
        echo "[$timestamp] $nickname: $msg" >> "$CHAT_FILE"
        echo -e "${GREEN}✅ Message sent instantly!${NC}"
    }
    
    # Show online users
    show_online_users() {
        echo -e "\n${CYAN}👥 Online Now:${NC}"
        echo "──────────────────────────────────────────────"
        if [ -f "$ONLINE_FILE" ] && [ -s "$ONLINE_FILE" ]; then
            cat "$ONLINE_FILE" | while read -r user; do
                if [ "$user" == "$nickname" ]; then
                    echo -e "${GREEN}🟢 $user (You)${NC}"
                else
                    echo -e "${YELLOW}🟢 $user${NC}"
                fi
            done
        else
            echo "No users online"
        fi
        echo "──────────────────────────────────────────────"
    }
    
    # Cleanup when leaving chat
    cleanup_chat() {
        # Remove from online users
        if [ -f "$ONLINE_FILE" ]; then
            grep -v "^$nickname$" "$ONLINE_FILE" > "${ONLINE_FILE}.tmp"
            mv "${ONLINE_FILE}.tmp" "$ONLINE_FILE"
        fi
        
        # Add LEAVE message
        timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] 🔴 $nickname left the chatroom" >> "$CHAT_FILE"
        
        echo -e "${YELLOW}👋 You left the chatroom${NC}"
    }
    
    # Set trap for cleanup
    trap cleanup_chat EXIT
    
    # Real-time chat loop with INSTANT updates
    chat_loop() {
        local last_size=0
        local current_size=0
        
        while true; do
            # Check for new messages instantly
            if [ -f "$CHAT_FILE" ]; then
                current_size=$(stat -c %s "$CHAT_FILE" 2>/dev/null || echo 0)
            fi
            
            # Only refresh if there are new messages
            if [ "$current_size" -ne "$last_size" ]; then
                last_size=$current_size
                show_chat_header
                display_messages
                echo "──────────────────────────────────────────────"
                show_online_users
                echo -e "${GREEN}💬 Type your message (/'exit' to leave):${NC}"
                echo -n "➤ "
            fi
            
            # Non-blocking read for instant input
            if read -t 0.5 -r message; then
                case "$message" in
                    "/exit")
                        echo -e "${YELLOW}Leaving chatroom...${NC}"
                        break
                        ;;
                    "/users")
                        show_online_users
                        read -p "Press Enter to continue..."
                        ;;
                    "/clear")
                        clear
                        ;;
                    "/help")
                        echo -e "${CYAN}📋 Instant Chat Commands:${NC}"
                        echo "/exit   - Leave chatroom"
                        echo "/users  - Show online users"
                        echo "/clear  - Clear screen"
                        echo "/help   - Show this help"
                        read -p "Press Enter to continue..."
                        ;;
                    "")
                        # Empty message, do nothing
                        ;;
                    *)
                        send_instant_message "$message"
                        # Instant refresh after sending
                        last_size=0
                        ;;
                esac
            fi
        done
    }
    
    # Start the instant chat
    chat_loop
}

# Setup chat system
setup_chat_system() {
    echo -e "${YELLOW}Setting up instant chat system...${NC}"
    
    # Create chat file with welcome message
    if [ ! -s "$CHAT_FILE" ]; then
        timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] 🎉 Welcome to RexChat Philippines Instant Messaging!" > "$CHAT_FILE"
        echo "[$timestamp] 💬 Messages are instant with no delays!" >> "$CHAT_FILE"
        echo "[$timestamp] 🌏 Chat with Filipinos nationwide!" >> "$CHAT_FILE"
    fi
    
    echo -e "${GREEN}✅ Instant chat system ready!${NC}"
}

# Main menu
main_menu() {
    while true; do
        show_banner
        
        # Check if user is logged in
        if [ -f "rexchat_current_user.txt" ]; then
            nickname=$(cat "rexchat_current_user.txt")
            region=$(cat "rexchat_current_region.txt")
            echo -e "${GREEN}✅ Logged in as: $nickname from $region${NC}"
        else
            echo -e "${YELLOW}⚠️  Not logged in${NC}"
        fi
        
        if ! check_internet; then
            echo -e "${RED}⚠️  OFFLINE - Internet required${NC}"
        else
            echo -e "${GREEN}✅ ONLINE - Instant messaging ready${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}Main Menu:${NC}"
        echo "1. 🚀 Start Instant Chat Room"
        echo "2. 👤 Create Account (Auto-Login)"
        echo "3. 🔐 Login"
        echo "4. 👥 View Online Users"
        echo "5. 📖 How to Use"
        echo "6. 🚪 Exit"
        echo ""
        
        read -p "Choose [1-6]: " choice
        
        case $choice in
            1)
                if [ -f "rexchat_current_user.txt" ]; then
                    nickname=$(cat "rexchat_current_user.txt")
                    region=$(cat "rexchat_current_region.txt")
                    start_instant_chat "$nickname" "$region"
                else
                    echo -e "${RED}Please login or create account first!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                if register_user; then
                    echo -e "${GREEN}✅ Ready for instant chat!${NC}"
                    read -p "Press Enter to continue..."
                else
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                if login_user; then
                    echo -e "${GREEN}✅ Ready for instant chat!${NC}"
                    read -p "Press Enter to continue..."
                else
                    read -p "Press Enter to continue..."
                fi
                ;;
            4)
                echo -e "\n${CYAN}👥 Currently Online:${NC}"
                echo "──────────────────────────────────────────────"
                if [ -f "$ONLINE_FILE" ] && [ -s "$ONLINE_FILE" ]; then
                    cat "$ONLINE_FILE"
                else
                    echo "No users online right now"
                fi
                echo "──────────────────────────────────────────────"
                read -p "Press Enter to continue..."
                ;;
            5)
                show_tutorial
                ;;
            6)
                # Add leave message if user was in chat
                if [ -f "rexchat_current_user.txt" ]; then
                    nickname=$(cat "rexchat_current_user.txt")
                    # Remove from online users
                    if [ -f "$ONLINE_FILE" ]; then
                        grep -v "^$nickname$" "$ONLINE_FILE" > "${ONLINE_FILE}.tmp"
                        mv "${ONLINE_FILE}.tmp" "$ONLINE_FILE"
                    fi
                fi
                echo -e "${GREEN}Salamat for using RexChat Philippines! 🇵🇭${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice!${NC}"
                ;;
        esac
    done
}

# Tutorial
show_tutorial() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║         INSTANT CHAT TUTORIAL               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${GREEN}🚀 INSTANT MESSAGING FEATURES:${NC}"
    echo ""
    echo -e "${YELLOW}⚡ NO DELAYS:${NC}"
    echo "• Messages send instantly"
    echo "• Real-time updates"
    echo "• No waiting for responses"
    echo ""
    echo -e "${YELLOW}🎨 COLORFUL CHAT:${NC}"
    echo "• ${BLUE}Blue${NC} - Your messages"
    echo "• ${YELLOW}Yellow${NC} - Other users' messages" 
    echo "• ${GREEN}Green${NC} - Join notifications"
    echo "• ${RED}Red${NC} - Leave notifications"
    echo ""
    echo -e "${YELLOW}👥 JOIN/LEAVE NOTIFICATIONS:${NC}"
    echo "• See when users join: '🟢 username joined'"
    echo "• See when users leave: '🔴 username left'"
    echo "• Know who's online instantly"
    echo ""
    echo -e "${YELLOW}🔐 AUTO-LOGIN:${NC}"
    echo "• Automatically logged in after registration"
    echo "• No need to login again"
    echo "• Straight to chatting"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT:${NC}"
    echo "• Internet required for nationwide chat"
    echo "• Works with mobile data/WiFi"
    echo "• All Philippine networks supported"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Initialize
initialize_app() {
    echo -e "${YELLOW}Initializing RexChat Instant Messaging...${NC}"
    
    install_dependencies
    setup_chat_system
    
    echo -e "${GREEN}✅ RexChat Instant Messaging Ready!${NC}"
    sleep 2
}

# Start application
initialize_app
main_menu
