#!/bin/bash

#################################################
# XEMI AUTO BACKUP TOOL                         #
# Menu-driven interface for Raspberry Pi backup #
# Author: Victor G.C.                           #
# Version: Full version with restore & cleanup  #
#################################################

CONFIG_FILE="$HOME/.config/xemi_auto_backup/config.conf"
LOG_DIR="$HOME/.local/share/xemi_auto_backup/logs"
TMP_DIR="/tmp"
MARKER_FILE=".backup_marker"
PARTITION="/dev/mmcblk0p2"
EXCLUDE_PATH="/home/root/network_backup"

# ----------- DEFAULT CONFIG VALUES -----------
FTP_HOST="192.168.1.92"
FTP_USER="clouduser"
FTP_PASS="cloud842867"
FTP_REMOTE_PATH="/volume(sda2)/Recovery/my-backups/raspberrypi"

# ----------- INIT CONFIG ---------------------
init_config() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname $CONFIG_FILE)"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "FTP_HOST=$FTP_HOST" > "$CONFIG_FILE"
        echo "FTP_USER=$FTP_USER" >> "$CONFIG_FILE"
        echo "FTP_PASS=$FTP_PASS" >> "$CONFIG_FILE"
        echo "FTP_REMOTE_PATH=$FTP_REMOTE_PATH" >> "$CONFIG_FILE"
    fi
    source "$CONFIG_FILE"
}

# ----------- UTILS ---------------------------
log() {
    echo "[$(date '+%F %T')] $1" | tee -a "$LOG_FILE"
}

pause() {
    read -rp $'\nPress [Enter] to continue...'
}

clean_screen() {
    clear
}

# ----------- MENU FUNCTIONS ------------------
run_backup() {
    clean_screen
    TODAY=$(date +%F)
    echo "Enter commit message:"; read COMMIT
    echo "Enter description:"; read DESC

    NEXT_VERSION=$(ls "$TMP_DIR"/rpi_backup_${TODAY}_*.fsa 2>/dev/null | awk -F'_' '{print $NF}' | sed 's/.fsa//' | sort -n | tail -n 1)
    VERSION="001"
    [ -n "$NEXT_VERSION" ] && VERSION=$(printf "%03d" $((10#$NEXT_VERSION + 1)))

    BACKUP_NAME="rpi_backup_${TODAY}_${VERSION}"
    BACKUP_FILE="$TMP_DIR/${BACKUP_NAME}.fsa"
    LOG_FILE="$LOG_DIR/${BACKUP_NAME}.log"
    touch "$LOG_FILE"

    log "User: $(whoami)"
    log "Hostname: $(hostname)"
    log "Commit: $COMMIT"
    log "Description: $DESC"
    log "Starting backup to $BACKUP_FILE"
    log "Excluding path: $EXCLUDE_PATH"

    sudo fsarchiver savefs -v -A -e "$EXCLUDE_PATH" "$BACKUP_FILE" "$PARTITION"
    if [ $? -ne 0 ]; then
        log "Backup failed."
        sudo rm -f "$BACKUP_FILE"
        pause
        return
    fi

    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    BACKUP_HASH=$(sha256sum "$BACKUP_FILE" | awk '{print $1}')

    log "Backup file size: $BACKUP_SIZE"
    log "SHA256 Checksum: $BACKUP_HASH"

    [ -f "$BACKUP_FILE" ] || { log "Backup file missing: $BACKUP_FILE"; pause; return; }
    [ -f "$LOG_FILE" ] || { log "Log file missing: $LOG_FILE"; pause; return; }

    log "Uploading to FTP..."

    lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF
set ftp:ssl-allow no
cd $FTP_REMOTE_PATH
put "$BACKUP_FILE"
put "$LOG_FILE"
echo "Backup on $TODAY [$VERSION]" > "$TMP_DIR/$MARKER_FILE"
put "$TMP_DIR/$MARKER_FILE"
bye
EOF

    if [ $? -eq 0 ]; then
        log "Upload successful. Cleaning up..."
        if sudo rm -f "$BACKUP_FILE"; then
            log "Local backup file removed successfully."
        else
            log "Failed to remove local backup file."
        fi
    else
        log "Upload failed. Backup retained locally."
    fi

    log "Logs available in: $LOG_DIR"
    log "Backup completed successfully."
    pause
}

restore_backup() {
    clean_screen
    echo "Fetching backup list from FTP..."
    BACKUPS=$(lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "cls -1 $FTP_REMOTE_PATH/*.fsa; bye" 2>/dev/null)
    [ -z "$BACKUPS" ] && echo "No backups found on FTP." && pause && return

    PS3=$'\nSelect a backup number to view details: '
    select file in $BACKUPS "Cancel"; do
        [ "$file" == "Cancel" ] && return
        if [ -n "$file" ]; then
            BACKUP_NAME=$(basename "$file")
            LOG_NAME="${BACKUP_NAME/.fsa/.log}"
            clean_screen
            echo "=== Selected Backup: $BACKUP_NAME ==="
            echo -e "\n=== FULL LOG CONTENT ==="
            lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "get $FTP_REMOTE_PATH/$LOG_NAME -o $TMP_DIR/$LOG_NAME; bye"
            if [ -f "$TMP_DIR/$LOG_NAME" ]; then
                cat "$TMP_DIR/$LOG_NAME"
                rm "$TMP_DIR/$LOG_NAME"
            else
                echo "Log not found."
            fi

            echo -e "\nDo you want to restore this backup? (y/n)"
            read -r confirm
            if [ "$confirm" == "y" ]; then
                echo "\nDetecting restore targets (excluding internal system)..."
                TARGETS=($(lsblk -pnlo NAME | grep -v mmcblk0 | grep -E "/dev/sd|/dev/nvme"))
                if [ ${#TARGETS[@]} -eq 0 ]; then
                    echo "No external partitions available for restore."
                    pause
                    return
                fi

                echo "\nAvailable restore targets:"
                for i in "${!TARGETS[@]}"; do
                    echo "$((i+1))) ${TARGETS[$i]}"
                done

                echo -n "\nSelect the device number to restore to: "
                read -r index
                TARGET_DEVICE=${TARGETS[$((index-1))]}

                echo -e "\n⚠️ WARNING: This will OVERWRITE all data on $TARGET_DEVICE. Are you sure? (y/n)"
                read -r confirm2
                if [ "$confirm2" == "y" ]; then
                    echo "Downloading backup..."
                    lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "get $FTP_REMOTE_PATH/$BACKUP_NAME -o $TMP_DIR/$BACKUP_NAME; bye"
                    echo "Restoring backup to $TARGET_DEVICE..."
                    sudo fsarchiver restfs -v "$TMP_DIR/$BACKUP_NAME" id=0,dest=$TARGET_DEVICE
                    sudo rm -f "$TMP_DIR/$BACKUP_NAME"
                    echo "Restore completed."
                else
                    echo "Restore cancelled."
                fi
                pause
                return
            else
                echo "Cancelled."
                pause
                return
            fi
        fi
    done
}

view_logs() {
    clean_screen
    echo -e "\nAvailable logs:\n"
    ls "$LOG_DIR"/*.log 2>/dev/null || echo "No logs found."
    pause
}

clear_logs() {
    clean_screen
    echo "Are you sure you want to delete all logs? (y/n)"
    read -r confirm
    if [ "$confirm" == "y" ]; then
        rm -f "$LOG_DIR"/*.log
        echo "Logs deleted."
    else
        echo "Operation cancelled."
    fi
    pause
}

edit_config() {
    clean_screen
    nano "$CONFIG_FILE"
    pause
}

show_config() {
    clean_screen
    echo "Current Configuration:\n"
    cat "$CONFIG_FILE"
    pause
}

main_menu() {
    while true; do
        clean_screen
        echo "=========== XEMI AUTO BACKUP ==========="
        echo "1) Create New Backup"
        echo "2) Restore Backup from FTP"
        echo "3) View Logs"
        echo "4) Clear Logs"
        echo "5) Show Configuration"
        echo "6) Edit Configuration"
        echo "0) Exit"
        echo "========================================"
        read -rp "Choose an option: " choice
        case $choice in
            1) run_backup ;;
            2) restore_backup ;;
            3) view_logs ;;
            4) clear_logs ;;
            5) show_config ;;
            6) edit_config ;;
            0) exit 0 ;;
            *) echo "Invalid option"; sleep 1 ;;
        esac
    done
}

init_config
main_menu
