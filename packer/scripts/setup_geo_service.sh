#!/usr/bin/env bash
set -e

# Create app directory
sudo mkdir -p /opt/geo-service

# Move jar into place
sudo mv /tmp/geo-service.jar /opt/geo-service/geo-service.jar
sudo chmod 755 /opt/geo-service/geo-service.jar

# Install systemd unit
sudo mv /tmp/geo-service.service /etc/systemd/system/geo-service.service

# Reload + enable + start
sudo systemctl daemon-reload
sudo systemctl enable geo-service
sudo systemctl start geo-service

# Quick check (doesn't fail build if it takes a second)
sudo systemctl status geo-service --no-pager || true
