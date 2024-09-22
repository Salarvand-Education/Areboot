#!/bin/bash

# آپدیت و آپگرید سیستم
echo "Starting system update and upgrade..."
sleep 3
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Starting Install Crontab..."
sudo apt-get install cron

# پاکسازی فایل‌های بی‌استفاده
echo "Cleaning up unnecessary files..."
sleep 3
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# اضافه کردن کرونجاب برای ریبوت هر 12 ساعت
echo "Adding cron job for reboot every 6 hours..."
sleep 3
cronjob="0 */6 * * * /sbin/reboot"
(crontab -l 2>/dev/null; echo "$cronjob") | crontab -

# ریبوت سیستم
echo "Rebooting system in 3 seconds..."
sleep 3
sudo reboot
