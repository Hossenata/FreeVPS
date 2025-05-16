#!/bin/bash

# متغيرات مهمة
if [[ -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Please set 'NGROK_AUTH_TOKEN'"
  exit 2
fi

if [[ -z "$LINUX_USER_PASSWORD" ]]; then
  echo "Please set 'LINUX_USER_PASSWORD'"
  exit 3
fi

if [[ -z "$LINUX_USERNAME" ]]; then
  echo "Please set 'LINUX_USERNAME'"
  exit 4
fi

if [[ -z "$LINUX_MACHINE_NAME" ]]; then
  LINUX_MACHINE_NAME="ubuntu-vps"
fi

echo "### إعداد المستخدم الجديد ###"
sudo useradd -m "$LINUX_USERNAME"
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo "$LINUX_USERNAME"
sudo hostnamectl set-hostname "$LINUX_MACHINE_NAME"

echo "### تنزيل ngrok (إصدار حديث) ###"
wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip
unzip ngrok.zip
chmod +x ngrok
sudo mv ngrok /usr/local/bin/ngrok

echo "### تسجيل توكن ngrok ###"
ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

echo "### تشغيل ngrok على المنفذ 22 ###"
ngrok tcp 22 > ngrok.log &
sleep 10

HAS_ERRORS=$(grep "ERR_" ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  echo ""
  echo "=========================================="
  echo "تم تشغيل السيرفر!"
  echo "اتصل باستخدام الأمر التالي:"
  echo "$(grep -o -E "tcp://(.+)" < ngrok.log | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /")"
  echo "=========================================="
else
  echo "$HAS_ERRORS"
  exit 5
fi
