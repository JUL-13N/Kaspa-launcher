#!/bin/bash

# Kaspa Launcher Script - Enhanced Version (Mac/Linux)
# Allows you to run Kaspa executables with custom saved arguments

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/kaspa-config.conf"

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating default config file..."
    cat > "$CONFIG_FILE" << EOF
kaspad=--retention-period-days=2
kaspa-wallet=
rothschild=
stratum-bridge=
EOF
    echo "Config file created at: $CONFIG_FILE"
    echo
    sleep 2
fi

# Function to load and normalize raw args (converts old space-separated to == format)
load_args_raw() {
    local exe="$1"
    local raw
    raw=$(grep "^$exe=" "$CONFIG_FILE" | cut -d'=' -f2-)
    # Normalize: convert " --" boundaries to "==--"
    local normalized
    normalized=$(echo "$raw" | sed 's/ --/==--/g')
    # Save back if changed
    if [ "$normalized" != "$raw" ]; then
        update_config "$exe" "$normalized"
    fi
    echo "$normalized"
}

# Function to load args converted to spaces for execution
load_args() {
    local exe="$1"
    local raw
    raw=$(load_args_raw "$exe")
    echo "${raw//==/ }"
}

# Function to update config
update_config() {
    local exe="$1"
    local new_args="$2"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^$exe=.*|$exe=$new_args|" "$CONFIG_FILE"
    else
        # Linux
        sed -i "s|^$exe=.*|$exe=$new_args|" "$CONFIG_FILE"
    fi
}

# Function to display main menu
show_main_menu() {
    clear
    echo "================================"
    echo "    KASPA LAUNCHER"
    echo "================================"
    echo
    echo "Select Kaspa executable to run:"
    echo
    echo "1. kaspad (Node) [DEFAULT - Press Enter]"
    echo "2. kaspa-wallet (Wallet)"
    echo "3. rothschild (Stress Test)"
    echo "4. stratum-bridge (Mine to Node)"
    echo "5. Manage arguments"
    echo "6. Exit"
    echo
}

# Function to run executable
run_executable() {
    local exe="$1"
    local args=$(load_args "$exe")
    
    # Check if executable exists
    if [ ! -f "$SCRIPT_DIR/$exe" ]; then
        echo "Error: $exe not found in $SCRIPT_DIR"
        echo "Make sure the executable is in the same directory as this script."
        echo
        read -p "Press Enter to continue..."
        return
    fi
    
    # Make sure it's executable
    chmod +x "$SCRIPT_DIR/$exe"
    
    echo
    echo "Running: $exe $args"
    echo
    echo "Press Ctrl+C to stop the process"
    echo "================================"
    echo
    
    # Run the executable with saved arguments
    cd "$SCRIPT_DIR"
    ./"$exe" $args
    
    echo
    echo "Process ended."
    read -p "Press Enter to continue..."
}

# Function to manage arguments menu
manage_args_menu() {
    while true; do
        clear
        echo "================================"
        echo "    MANAGE SAVED ARGUMENTS"
        echo "================================"
        echo
        echo "Current saved arguments:"
        echo
        cat "$CONFIG_FILE"
        echo
        echo
        echo "Which executable's arguments do you want to manage?"
        echo
        echo "1. kaspad"
        echo "2. kaspa-wallet"
        echo "3. rothschild"
        echo "4. stratum-bridge"
        echo "5. Back to main menu"
        echo
        read -p "Enter your choice (1-5): " manage_choice
        
        case $manage_choice in
            1) manage_exe="kaspad" ;;
            2) manage_exe="kaspa-wallet" ;;
            3) manage_exe="rothschild" ;;
            4) manage_exe="stratum-bridge" ;;
            5) return ;;
            *) echo "Invalid choice."; sleep 1; continue ;;
        esac
        
        manage_args_for_exe "$manage_exe"
    done
}

# Function to manage arguments for specific executable
manage_args_for_exe() {
    local exe="$1"
    
    while true; do
        clear
        current_args=$(load_args_raw "$exe")
        
        echo "================================"
        echo "    MANAGE ARGUMENTS FOR $exe"
        echo "================================"
        echo
        if [ -z "$current_args" ]; then
            echo "Current arguments: (none)"
        else
            echo "Current arguments:"
            echo
            local i=1
            # Split by == delimiter and display each argument
            echo "$current_args" | sed 's/==/\n/g' | while IFS= read -r arg; do
                if [ -n "$arg" ]; then
                    echo "  $i. $arg"
                    ((i++))
                fi
            done
        fi
        echo
        echo "================================"
        echo
        echo "OPTIONS:"
        echo "1. Add new argument"
        echo "2. Remove existing argument"
        echo "3. Clear all arguments"
        echo "4. View available arguments (help -h)"
        echo "5. Back to manage menu"
        echo
        read -p "Enter your choice (1-5): " arg_action
        
        case $arg_action in
            1) add_argument "$exe" ;;
            2) remove_argument "$exe" ;;
            3) clear_arguments "$exe" ;;
            4) show_help_for_exe "$exe" ;;
            5) return ;;
            *) echo "Invalid choice."; sleep 1 ;;
        esac
    done
}

# Function to show help for specific executable
show_help_for_exe() {
    local exe="$1"
    
    clear
    echo "================================"
    echo "    AVAILABLE ARGUMENTS FOR $exe"
    echo "================================"
    echo
    echo "Running: $exe -h"
    echo
    echo "================================"
    echo
    
    # Check if executable exists
    if [ ! -f "$SCRIPT_DIR/$exe" ]; then
        echo "Error: $exe not found in current directory."
        echo
        read -p "Press Enter to continue..."
        return
    fi
    
    chmod +x "$SCRIPT_DIR/$exe"
    cd "$SCRIPT_DIR"
    ./"$exe" -h
    
    echo
    echo "================================"
    echo
    read -p "Press Enter to continue..."
}

# Function to add argument
add_argument() {
    local exe="$1"
    local current_args=$(load_args_raw "$exe")
    
    echo
    echo "Enter argument to add, or pick a number:"
    echo
    echo "  1. --retention-period-days=2"
    echo "  2. --ram-scale=0.5"
    echo "  3. --disable-upnp"
    echo "  4. --utxoindex"
    echo "  5. --appdir (custom path)"
    echo
    echo "(Or type any argument directly)"
    echo
    read -p "> " new_arg
    
    if [ -z "$new_arg" ]; then
        echo "No argument entered."
        sleep 1
        return
    fi

    # Map number shortcuts to actual arguments
    case "$new_arg" in
        1) new_arg="--retention-period-days=2" ;;
        2) new_arg="--ram-scale=0.5" ;;
        3) new_arg="--disable-upnp" ;;
        4) new_arg="--utxoindex" ;;
        5) 
            echo
            echo "Enter custom path for --appdir:"
            echo
            echo "Examples:"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "  /Volumes/MySSD/kaspa-data"
                echo "  ~/Library/Application Support/kaspa"
            else
                echo "  /mnt/ssd/kaspa-data"
                echo "  ~/kaspa-data"
            fi
            echo
            echo "Default location if not specified:"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                echo "  ~/.kaspa"
            else
                echo "  ~/.kaspa"
            fi
            echo
            read -p "Path: " custom_path
            
            if [ -z "$custom_path" ]; then
                echo "No path entered. Cancelled."
                sleep 1
                return
            fi
            
            new_arg="--appdir=$custom_path"
            ;;
    esac
    
    # Check duplicate by splitting on ==
    if echo "$current_args" | sed 's/==/\n/g' | grep -qxF -- "$new_arg"; then
        echo
        echo "Argument already exists: $new_arg"
        sleep 2
        return
    fi
    
    if [ -z "$current_args" ]; then
        updated_args="$new_arg"
    else
        updated_args="$current_args==$new_arg"
    fi
    
    update_config "$exe" "$updated_args"
    
    echo
    echo "Argument added successfully."
    echo
    sleep 2
}

# Function to remove argument
remove_argument() {
    local exe="$1"
    local current_args=$(load_args_raw "$exe")

    if [ -z "$current_args" ]; then
        echo
        echo "No arguments to remove."
        sleep 2
        return
    fi

    echo
    echo "Current arguments:"
    echo

    # Build array by splitting on ==
    local arg_array=()
    while IFS= read -r arg; do
        [ -n "$arg" ] && arg_array+=("$arg")
    done < <(echo "$current_args" | sed 's/==/\n/g')

    local i=1
    for arg in "${arg_array[@]}"; do
        echo "  $i. $arg"
        ((i++))
    done
    local arg_count=${#arg_array[@]}

    echo
    read -p "Enter number to remove (1-$arg_count): " remove_num

    if [ -z "$remove_num" ]; then
        echo "Nothing entered."
        sleep 1
        return
    fi

    if ! [[ "$remove_num" =~ ^[0-9]+$ ]] || [ "$remove_num" -lt 1 ] || [ "$remove_num" -gt "$arg_count" ]; then
        echo
        echo "Invalid — enter a number between 1 and $arg_count."
        sleep 2
        return
    fi

    local remove_arg="${arg_array[$((remove_num - 1))]}"

    echo
    echo "Remove: $remove_arg"
    read -p "Press Enter to confirm, or type n to cancel: " confirm

    if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
        echo "Cancelled."
        sleep 1
        return
    fi

    # Rebuild with == joining, skipping removed index
    local updated_args=""
    local j=1
    for arg in "${arg_array[@]}"; do
        if [ "$j" -ne "$remove_num" ]; then
            if [ -z "$updated_args" ]; then
                updated_args="$arg"
            else
                updated_args="$updated_args==$arg"
            fi
        fi
        ((j++))
    done

    update_config "$exe" "$updated_args"

    echo
    echo "Removed successfully."
    if [ -z "$updated_args" ]; then
        echo "$exe now has no arguments."
    else
        echo "$exe will now run with the remaining arguments."
    fi
    echo
    sleep 2
}

# Function to clear all arguments
clear_arguments() {
    local exe="$1"
    
    echo
    echo "Are you sure you want to clear ALL arguments for $exe?"
    echo
    read -p "Press Enter to confirm, or type 'n' to cancel: " confirm_clear
    
    if [ "$confirm_clear" = "n" ] || [ "$confirm_clear" = "N" ]; then
        echo "Cancelled."
        sleep 1
        return
    fi
    
    update_config "$exe" ""
    
    echo
    echo "All arguments cleared for $exe"
    echo
    sleep 2
}

# Main loop
while true; do
    show_main_menu
    read -p "Enter your choice (1-6, or press Enter for option 1): " choice
    
    # Default to option 1 if Enter is pressed (empty input)
    if [ -z "$choice" ]; then
        choice="1"
    fi
    
    case $choice in
        1) run_executable "kaspad" ;;
        2) run_executable "kaspa-wallet" ;;
        3) run_executable "rothschild" ;;
        4) run_executable "stratum-bridge" ;;
        5) manage_args_menu ;;
        6) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice. Please try again."; sleep 1 ;;
    esac
done
