#!/bin/bash

# Function to check if user has sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "\e[31mPlease run as root\e[0m"
        exit
    fi
}

# Function to display colored text
colored_echo() {
    COLOR=$1
    MESSAGE=$2
    case $COLOR in
        red)
            echo -e "\e[31m$MESSAGE\e[0m"
            ;;
        green)
            echo -e "\e[32m$MESSAGE\e[0m"
            ;;
        yellow)
            echo -e "\e[33m$MESSAGE\e[0m"
            ;;
        blue)
            echo -e "\e[34m$MESSAGE\e[0m"
            ;;
        *)
            echo "$MESSAGE"
            ;;
    esac
}

# Function to display menu using ANSI colors
display_menu() {
    while true; do
        clear
        colored_echo blue "============================================="
        colored_echo blue "|          System Management Menu           |"
        colored_echo blue "============================================="
        colored_echo yellow "1) Update and Upgrade System"
        colored_echo yellow "2) Install Cron"
        colored_echo yellow "3) Cleanup Unnecessary Files"
        colored_echo yellow "4) Add/Remove Reboot Cron Job"
        colored_echo yellow "5) Exit"
        colored_echo blue "============================================="
        read -p "$(colored_echo yellow 'Choose an option: ')" CHOICE
        case $CHOICE in
            1)
                update_upgrade
                ;;
            2)
                install_cron
                ;;
            3)
                cleanup_files
                ;;
            4)
                manage_reboot_cron_job
                ;;
            5)
                colored_echo green "Exiting..."
                exit
                ;;
            *)
                colored_echo red "Invalid option, please try again."
                sleep 2
                ;;
        esac
    done
}

# Function to update and upgrade the system
update_upgrade() {
    colored_echo blue "Starting system update and upgrade..."
    sleep 3
    if ! apt-get update -y; then
        colored_echo red "Failed to update package lists."
        return
    fi
    if ! apt-get upgrade -y; then
        colored_echo red "Failed to upgrade packages."
        return
    fi
    colored_echo green "System update and upgrade completed."
    sleep 3
}

# Function to install cron
install_cron() {
    colored_echo blue "Starting Install Crontab..."
    sleep 3
    if dpkg -l | grep -q cron; then
        colored_echo yellow "Cron is already installed."
    else
        if ! apt-get install cron -y; then
            colored_echo red "Failed to install Cron."
            return
        fi
        colored_echo green "Crontab installed."
    fi
    systemctl is-active --quiet cron || systemctl start cron
    colored_echo green "Cron service started."
    sleep 3
}

# Function to clean up unnecessary files
cleanup_files() {
    colored_echo blue "Cleaning up unnecessary files..."
    sleep 3
    if ! apt-get autoremove -y && apt-get autoclean -y; then
        colored_echo red "Failed to clean up unnecessary files."
        return
    fi
    colored_echo green "Cleanup completed."
    sleep 3
}

# Function to add/remove reboot cron job
manage_reboot_cron_job() {
    while true; do
        clear
        colored_echo blue "============================================="
        colored_echo blue "|         Manage Reboot Cron Job            |"
        colored_echo blue "============================================="
        colored_echo yellow "1) Add Reboot Cron Job (every 6 hours)"
        colored_echo yellow "2) Add Reboot Cron Job (custom time)"
        colored_echo yellow "3) Remove Reboot Cron Job"
        colored_echo yellow "4) Back"
        colored_echo blue "============================================="
        read -p "$(colored_echo yellow 'Choose an action: ')" CHOICE
        case $CHOICE in
            1)
                add_reboot_cron_job "0 */6 * * * /sbin/reboot"
                ;;
            2)
                # Get custom time inputs
                while true; do
                    read -p "$(colored_echo yellow 'How often should the system reboot? (1=Every X minutes, 2=Every Y hours, 3=Every day): ')" REBOOT_FREQUENCY
                    case $REBOOT_FREQUENCY in
                        1)
                            read -p "$(colored_echo yellow 'Enter interval in minutes (e.g., 10 for every 10 minutes): ')" MINUTE_INTERVAL
                            if [[ "$MINUTE_INTERVAL" =~ ^[0-9]+$ && "$MINUTE_INTERVAL" -ge 1 && "$MINUTE_INTERVAL" -le 59 ]]; then
                                MINUTE="*/$MINUTE_INTERVAL"
                                HOUR="*"
                                DAY="*"
                                break
                            else
                                colored_echo red "Invalid input. Please enter a number between 1 and 59."
                            fi
                            ;;
                        2)
                            read -p "$(colored_echo yellow 'Enter interval in hours (e.g., 3 for every 3 hours): ')" HOUR_INTERVAL
                            if [[ "$HOUR_INTERVAL" =~ ^[0-9]+$ && "$HOUR_INTERVAL" -ge 1 && "$HOUR_INTERVAL" -le 23 ]]; then
                                MINUTE="0"
                                HOUR="*/$HOUR_INTERVAL"
                                DAY="*"
                                break
                            else
                                colored_echo red "Invalid input. Please enter a number between 1 and 23."
                            fi
                            ;;
                        3)
                            MINUTE="0"
                            HOUR="0"
                            DAY="*"
                            break
                            ;;
                        *)
                            colored_echo red "Invalid option. Please choose 1, 2, or 3."
                            ;;
                    esac
                done

                # Build the cron job expression
                CRONJOB="$MINUTE $HOUR $DAY * * /sbin/reboot"
                colored_echo green "Cron job expression: $CRONJOB"
                read -p "$(colored_echo yellow 'Do you want to add this cron job? (y/n): ')" CONFIRM
                if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]]; then
                    add_reboot_cron_job "$CRONJOB"
                else
                    colored_echo yellow "Operation canceled."
                fi
                ;;
            3)
                remove_reboot_cron_job
                ;;
            4)
                break
                ;;
            *)
                colored_echo red "Invalid option, please try again."
                sleep 2
                ;;
        esac
    done
}

# Function to add a reboot cron job
add_reboot_cron_job() {
    CRONJOB="$1"
    (crontab -l 2>/dev/null; echo "$CRONJOB") | crontab -
    if [ $? -eq 0 ]; then
        colored_echo green "Cron job added: $CRONJOB"
    else
        colored_echo red "Failed to add cron job."
    fi
    sleep 3
}

# Function to remove a reboot cron job
remove_reboot_cron_job() {
    TEMP_CRONTAB=$(mktemp)
    crontab -l | grep -v '/sbin/reboot' > "$TEMP_CRONTAB"
    crontab "$TEMP_CRONTAB"
    rm "$TEMP_CRONTAB"
    if [ $? -eq 0 ]; then
        colored_echo green "Reboot cron job removed."
    else
        colored_echo red "Failed to remove cron job."
    fi
    sleep 3
}

# Check for sudo privileges
check_sudo

# Main loop
display_menu
