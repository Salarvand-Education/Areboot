#!/bin/bash

INTERVAL="12h"  

reboot_server() {
    printf "Rebooting the server...\n"
    sudo reboot
}

main() {
    while true; do
        sleep "$INTERVAL"
        reboot_server
    done
}

echo -e "Script Is Runned Successful"

main
