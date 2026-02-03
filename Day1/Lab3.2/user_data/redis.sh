#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y redis-server

# Make Redis listen on all interfaces (safe here because SG restricts access)
sed -i 's/^bind .*/bind 0.0.0.0 ::1/' /etc/redis/redis.conf
sed -i 's/^protected-mode .*/protected-mode no/' /etc/redis/redis.conf

systemctl enable redis-server
systemctl restart redis-server
