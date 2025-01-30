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
    apt-get update -y && apt-get upgrade -y
    colored_echo green "System update and upgrade completed."
    sleep 3
}

# Function to install cron
install_cron() {
    colored_echo blue "Starting Install Crontab..."
    sleep 3
    apt-get install cron -y
    colored_echo green "Crontab installed."
    sleep 3
}

# Function to clean up unnecessary files
cleanup_files() {
    colored_echo blue "Cleaning up unnecessary files..."
    sleep 3
    apt-get autoremove -y && apt-get autoclean -y
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
                read -p "$(colored_echo yellow 'Enter minute (0-59): ')" MINUTE
                read -p "$(colored_echo yellow 'Enter hour (0-23): ')" HOUR
                read -p "$(colored_echo yellow 'Enter day of month (1-31): ')" DAY
                read -p "$(colored_echo yellow 'Enter month (1-12): ')" MONTH
                read -p "$(colored_echo yellow 'Enter day of week (0-7): ')" WEEKDAY
                CRONJOB="$MINUTE $HOUR $DAY $MONTH $WEEKDAY /sbin/reboot"
                add_reboot_cron_job "$CRONJOB"
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
    colored_echo green "Cron job added: $CRONJOB"
    sleep 3
}

# Function to remove a reboot cron job
remove_reboot_cron_job() {
    TEMP_CRONTAB=$(mktemp)
    crontab -l | grep -v '/sbin/reboot' > "$TEMP_CRONTAB"
    crontab "$TEMP_CRONTAB"
    rm "$TEMP_CRONTAB"
    colored_echo green "Reboot cron job removed."
    sleep 3
}

# Check for sudo privileges
check_sudo

# Main loop
display_menu
