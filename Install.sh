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

# Function to create the Salarvand directory and optimization script
create_salarvand_directory_and_scripts() {
    SALARVAND_DIR="/etc/Salarvand/Areboot"
    OPT_SCRIPT="$SALARVAND_DIR/run.sh"

    # Create the Salarvand directory if it doesn't exist
    mkdir -p "$SALARVAND_DIR"
    if [ $? -eq 0 ]; then
        colored_echo green "Directory created: $SALARVAND_DIR"
    else
        colored_echo red "Failed to create directory: $SALARVAND_DIR"
        exit
    fi

    # Create the optimization script (run.sh)
    cat <<EOF > "$OPT_SCRIPT"
#!/bin/bash

# Clear temporary files (excluding important files like crontab)
find /tmp -type f -mtime +1 -exec rm -f {} \; 2>/dev/null
if [ \$? -eq 0 ]; then
    echo "Temporary files cleared (excluding important files)."
else
    echo "Failed to clear temporary files."
fi

# Clear APT cache
apt-get clean -y

# Remove unused packages
apt-get autoremove -y && apt-get autoclean -y

# Clear systemd journal logs
journalctl --vacuum-time=3d 2>/dev/null

# Kill idle or suspicious network connections (except SSH)
ss -tnp | grep ESTAB | grep -v "sshd" | awk '{print \$6}' | cut -d',' -f2 | cut -d'=' -f2 | xargs -r kill -9 2>/dev/null

# Disable unnecessary services (excluding SSH)
systemctl list-unit-files --type=service | grep enabled | awk '{print \$1}' | while read service; do
    case "\$service" in
        *bluetooth*|*cups*|*avahi*|*ModemManager*)
            systemctl disable "\$service" --now 2>/dev/null
            ;;
        *ssh*|*sshd*)
            echo "Skipping SSH service to prevent disconnection."
            ;;
    esac
done

# Clear RAM cache
sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
EOF

    chmod +x "$OPT_SCRIPT"
    colored_echo green "Optimization script created: $OPT_SCRIPT"
}

# Function to install cron automatically
install_cron() {
    colored_echo blue "Checking if Cron is installed..."
    sleep 3
    if dpkg -l | grep -q cron; then
        colored_echo yellow "Cron is already installed."
    else
        colored_echo yellow "Cron is not installed. Installing now..."
        if ! apt-get install cron -y; then
            colored_echo red "Failed to install Cron."
            exit
        fi
        colored_echo green "Crontab installed."
    fi
    systemctl is-active --quiet cron || systemctl start cron
    colored_echo green "Cron service started."
    sleep 3
}

# Function to add a reboot cron job with optimization
add_reboot_cron_job_with_optimization() {
    CRONJOB="$1"
    OPT_SCRIPT="/etc/Salarvand/Areboot/run.sh"

    # Add the optimization script before reboot
    FULL_CRONJOB="$CRONJOB $OPT_SCRIPT && /sbin/reboot"
    (crontab -l 2>/dev/null; echo "$FULL_CRONJOB") | crontab -
    if [ $? -eq 0 ]; then
        colored_echo green "Cron job added with optimization: $FULL_CRONJOB"
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

# Function to display menu using ANSI colors
display_menu() {
    while true; do
        clear
        colored_echo blue "============================================="
        colored_echo blue "|          System Management Menu           |"
        colored_echo blue "============================================="
        colored_echo yellow "1) Add/Remove Reboot Cron Job"
        colored_echo yellow "2) Full System Maintenance (Update, Cleanup, Optimize)"
        colored_echo yellow "3) Exit"
        colored_echo blue "============================================="
        read -p "$(colored_echo yellow 'Choose an option: ')" CHOICE
        case $CHOICE in
            1)
                manage_reboot_cron_job
                ;;
            2)
                full_system_maintenance
                ;;
            3)
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

# Function to manage reboot cron job
manage_reboot_cron_job() {
    while true; do
        clear
        colored_echo blue "============================================="
        colored_echo blue "|         Manage Reboot Cron Job            |"
        colored_echo blue "============================================="
        colored_echo yellow "1) Add Reboot Cron Job (every 6 hours)"
        colored_echo yellow "2) Add Reboot Cron Job (custom time)"
        colored_echo yellow "3) Add Reboot Cron Job (every X days)"
        colored_echo yellow "4) Remove Reboot Cron Job"
        colored_echo yellow "5) Back to Main Menu"
        colored_echo blue "============================================="
        read -p "$(colored_echo yellow 'Choose an action: ')" CHOICE
        case $CHOICE in
            1)
                # Add reboot cron job every 6 hours
                add_reboot_cron_job_with_optimization "0 */6 * * *"
                ;;
            2)
                # Add reboot cron job with custom time
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
                            read -p "$(colored_echo yellow 'Enter interval in days (e.g., 1 for every day, 2 for every 2 days): ')" DAY_INTERVAL
                            if [[ "$DAY_INTERVAL" =~ ^[0-9]+$ && "$DAY_INTERVAL" -ge 1 ]]; then
                                MINUTE="0"
                                HOUR="0"
                                DAY="*/$DAY_INTERVAL"
                                break
                            else
                                colored_echo red "Invalid input. Please enter a number greater than or equal to 1."
                            fi
                            ;;
                        *)
                            colored_echo red "Invalid option. Please choose 1, 2, or 3."
                            ;;
                    esac
                done

                # Build the cron job expression
                CRONJOB="$MINUTE $HOUR $DAY * *"
                add_reboot_cron_job_with_optimization "$CRONJOB"
                ;;
            3)
                # Add reboot cron job every X days
                read -p "$(colored_echo yellow 'Enter interval in days (e.g., 1 for every day, 2 for every 2 days): ')" DAY_INTERVAL
                if [[ "$DAY_INTERVAL" =~ ^[0-9]+$ && "$DAY_INTERVAL" -ge 1 ]]; then
                    MINUTE="0"
                    HOUR="0"
                    DAY="*/$DAY_INTERVAL"
                    CRONJOB="$MINUTE $HOUR $DAY * *"
                    add_reboot_cron_job_with_optimization "$CRONJOB"
                else
                    colored_echo red "Invalid input. Please enter a number greater than or equal to 1."
                fi
                ;;
            4)
                # Remove reboot cron job
                remove_reboot_cron_job
                ;;
            5)
                # Back to main menu
                break
                ;;
            *)
                colored_echo red "Invalid option, please try again."
                sleep 2
                ;;
        esac
    done
}

# Function for full system maintenance
full_system_maintenance() {
    colored_echo blue "Starting full system maintenance..."
    sleep 3

    # 1. Update and upgrade the system
    update_upgrade

    # 2. Cleanup unnecessary files
    cleanup_files

    # 3. Cleanup and optimize the system
    cleanup_and_optimize

    colored_echo green "Full system maintenance completed."
    sleep 3
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

# Function to clean up and optimize the system
cleanup_and_optimize() {
    colored_echo blue "Starting system cleanup and optimization..."
    sleep 3

    # 1. Clear temporary files (excluding important files like crontab)
    colored_echo yellow "Clearing temporary files (excluding important files)..."
    find /tmp -type f -mtime +1 -exec rm -f {} \; 2>/dev/null
    if [ $? -eq 0 ]; then
        colored_echo green "Temporary files cleared (excluding important files)."
    else
        colored_echo red "Failed to clear temporary files."
    fi

    # 2. Clear APT cache
    colored_echo yellow "Clearing APT cache..."
    apt-get clean -y
    if [ $? -eq 0 ]; then
        colored_echo green "APT cache cleared."
    else
        colored_echo red "Failed to clear APT cache."
    fi

    # 3. Remove unused packages
    colored_echo yellow "Removing unused packages..."
    apt-get autoremove -y && apt-get autoclean -y
    if [ $? -eq 0 ]; then
        colored_echo green "Unused packages removed."
    else
        colored_echo red "Failed to remove unused packages."
    fi

    # 4. Clear systemd journal logs
    colored_echo yellow "Clearing systemd journal logs..."
    journalctl --vacuum-time=3d 2>/dev/null
    if [ $? -eq 0 ]; then
        colored_echo green "Systemd journal logs cleared."
    else
        colored_echo red "Failed to clear systemd journal logs."
    fi

    # 5. Kill idle or suspicious network connections (except SSH)
    colored_echo yellow "Killing idle or suspicious network connections (excluding SSH)..."
    ss -tnp | grep ESTAB | grep -v "sshd" | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | xargs -r kill -9 2>/dev/null
    if [ $? -eq 0 ]; then
        colored_echo green "Idle or suspicious connections terminated (SSH excluded)."
    else
        colored_echo red "No idle or suspicious connections found, or failed to terminate connections."
    fi

    # 6. Disable unnecessary services (excluding SSH)
    colored_echo yellow "Disabling unnecessary services (excluding SSH)..."
    systemctl list-unit-files --type=service | grep enabled | awk '{print $1}' | while read service; do
        case "$service" in
            *bluetooth*|*cups*|*avahi*|*ModemManager*)
                systemctl disable "$service" --now 2>/dev/null
                colored_echo green "Disabled service: $service"
                ;;
            *ssh*|*sshd*)
                colored_echo yellow "Skipping SSH service to prevent disconnection."
                ;;
        esac
    done

    # 7. Clear RAM cache
    colored_echo yellow "Clearing RAM cache..."
    sync && echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
    if [ $? -eq 0 ]; then
        colored_echo green "RAM cache cleared."
    else
        colored_echo red "Failed to clear RAM cache."
    fi

    colored_echo green "System cleanup and optimization completed."
    sleep 3
}

# Check for sudo privileges
check_sudo

# Automatically install Cron at the beginning
install_cron

# Create the Salarvand directory and scripts
create_salarvand_directory_and_scripts

# Main loop
display_menu
