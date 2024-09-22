#!/bin/bash

echo "Starting system update and upgrade..."
sleep 3
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Starting Install Crontab..."
sleep 3
sudo apt-get install cron -y

echo "Cleaning up unnecessary files..."
sleep 3
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "Adding cron job for reboot every 6 hours..."
sleep 3
cronjob="0 */6 * * * /sbin/reboot"
(crontab -l 2>/dev/null; echo "$cronjob") | crontab -

echo "Rebooting system in 3 seconds..."
sleep 3
sudo reboot
