#!/bin/bash

# URL of the script
SCRIPT_URL="https://raw.githubusercontent.com/Salarvand-Education/Areboot/main/Run.sh"

# Function to download and run the script
install_and_run() {
    if curl -s "$SCRIPT_URL" | bash; then
        printf "Installation and execution completed successfully.\n"
    else
        printf "Installation failed.\n" >&2
        return 1
    fi
}

# Main function
main() {
    install_and_run
}

# Start the script
main
