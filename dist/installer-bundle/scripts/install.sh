
#!/usr/bin/env bash
set -e
echo "Installing geo-service..."
sudo mkdir -p /opt/geo-service
sudo cp ../bin/geo-service-1.0.0.jar /opt/geo-service/geo-service.jar
echo "Done. (systemd setup can be added here)"
        