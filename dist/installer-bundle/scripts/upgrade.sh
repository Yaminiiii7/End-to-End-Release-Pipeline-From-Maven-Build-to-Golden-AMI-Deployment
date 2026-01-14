
        #!/usr/bin/env bash
        set -e

        APP_DIR="/opt/geo-service"
        JAR_NAME="geo-service-1.0.0.jar"
        BACKUP_DIR="/opt/geo-service-backup"

        echo "Starting geo-service upgrade..."

        if [ ! -f "$APP_DIR/$JAR_NAME" ]; then
        echo "No existing installation found."
        exit 1
        fi

        sudo mkdir -p "$BACKUP_DIR"
        sudo cp "$APP_DIR/$JAR_NAME" "$BACKUP_DIR/$JAR_NAME.$(date +%s)"

        sudo systemctl stop geo-service || true
        sudo cp ../bin/$JAR_NAME "$APP_DIR/$JAR_NAME"
        sudo systemctl start geo-service

        echo "Upgrade completed."
        