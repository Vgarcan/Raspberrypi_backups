#!/bin/bash

#################################################

XEMI AUTO BACKUP TOOL

Menu-driven interface for Raspberry Pi backup

Author: Victor G.C.

Version: Safe backup with restore & cleanup

#################################################

CONFIG_FILE="$HOME/.config/xemi_auto_backup/config.conf" LOG_DIR="$HOME/.local/share/xemi_auto_backup/logs" TMP_DIR="/tmp" MARKER_FILE=".backup_marker" PARTITION="/dev/mmcblk0p2" EXCLUDE_PATH="/home/root/network_backup"

----------- DEFAULT CONFIG VALUES -----------

FTP_HOST="192.168.1.92" FTP_USER="clouduser" FTP_PASS="cloud842867" FTP_REMOTE_PATH="/volume(sda2)/Recovery/my-backups/raspberrypi"

----------- INIT CONFIG ---------------------

init_config() { mkdir -p "$LOG_DIR" mkdir -p "$(dirname $CONFIG_FILE)" if [ ! -f "$CONFIG_FILE" ]; then echo "FTP_HOST=$FTP_HOST" > "$CONFIG_FILE" echo "FTP_USER=$FTP_USER" >> "$CONFIG_FILE" echo "FTP_PASS=$FTP_PASS" >> "$CONFIG_FILE" echo "FTP_REMOTE_PATH=$FTP_REMOTE_PATH" >> "$CONFIG_FILE" fi source "$CONFIG_FILE" }

----------- UTILS ---------------------------

log() { echo "[$(date '+%F %T')] $1" | tee -a "$LOG_FILE" }

pause() { read -rp $'\nPress [Enter] to continue...' }

clean_screen() { clear }

----------- MENU FUNCTIONS ------------------

run_backup() { clean_screen TODAY=$(date +%F) echo "Enter commit message:"; read COMMIT echo "Enter description:"; read DESC

NEXT_VERSION=$(ls "$TMP_DIR"/rpi_backup_${TODAY}_*.fsa 2>/dev/null | awk -F'_' '{print $NF}' | sed 's/.fsa//' | sort -n | tail -n 1)
VERSION="001"
[ -n "$NEXT_VERSION" ] && VERSION=$(printf "%03d" $((10#$NEXT_VERSION + 1)))

BACKUP_FILE="$TMP_DIR/rpi_backup_${TODAY}_${VERSION}.fsa"
LOG_FILE="$LOG_DIR/rpi_backup_${TODAY}_${VERSION}.log"
touch "$LOG_FILE"

# Safety check: prevent backup file being in the same partition
if [[ "$BACKUP_FILE" == /home/* || "$BACKUP_FILE" == /root/* ]]; then
    echo "[ERROR] Backup file path should not be inside the system partition."
    pause; return
fi

log "Commit: $COMMIT"
log "Description: $DESC"

FREE=$(df "$TMP_DIR" | awk 'NR==2 {print $4}')
FREE_MB=$((FREE / 1024))
if [ "$FREE_MB" -lt 1500 ]; then
    log "Insufficient space in /tmp"
    pause; return
fi

log "Starting backup to $BACKUP_FILE"
sudo fsarchiver savefs -v -A -e "$EXCLUDE_PATH" "$BACKUP_FILE" "$PARTITION"
if [ $? -ne 0 ]; then log "Backup failed."; sudo rm -f "$BACKUP_FILE"; pause; return; fi

log "Uploading to FTP..."
lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" <<EOF

cd $FTP_REMOTE_PATH put "$BACKUP_FILE" put "$LOG_FILE" echo "Backup on $TODAY [$VERSION]" > "$MARKER_FILE" put "$MARKER_FILE" bye EOF

if [ $? -eq 0 ]; then
    log "Upload successful. Cleaning up..."
    sudo rm -f "$BACKUP_FILE"
else
    log "Upload failed. Backup retained locally."
fi
pause

}

restore_backup() { while true; do clean_screen echo "Fetching backup list from FTP..." BACKUPS=$(lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "cls -1 $FTP_REMOTE_PATH/*.fsa; bye" 2>/dev/null) [ -z "$BACKUPS" ] && echo "No backups found on FTP." && pause && return

echo "\nAvailable Backups:\n"
    i=1
    declare -A BACKUP_MAP
    for file in $BACKUPS; do
        base=$(basename "$file")
        logname="${base/.fsa/.log}"
        commit_msg=$(lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "get $FTP_REMOTE_PATH/$logname -o -; bye" 2>/dev/null | grep -m1 'Commit' | cut -d']' -f2- | xargs)
        echo "$i) $base — Commit: $commit_msg"
        BACKUP_MAP[$i]="$base"
        ((i++))
    done
    echo "$i) Cancel"

    read -rp $'\nSelect backup number to view details: ' selection
    [ "$selection" == "$i" ] && return
    SELECTED_BACKUP="${BACKUP_MAP[$selection]}"
    [ -z "$SELECTED_BACKUP" ] && echo "Invalid selection." && pause && continue

    LOG_NAME="${SELECTED_BACKUP/.fsa/.log}"
    clean_screen
    echo "=== Selected Backup: $SELECTED_BACKUP ==="
    echo "\n=== FULL LOG CONTENT ==="
    lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "get $FTP_REMOTE_PATH/$LOG_NAME -o -; bye" || echo "Log not found."

    echo "\nDo you want to restore this backup? (y/n)"
    read -r confirm
    if [ "$confirm" == "y" ]; then
        echo "\nDownloading backup..."
        lftp -u "$FTP_USER","$FTP_PASS" "$FTP_HOST" -e "get $FTP_REMOTE_PATH/$SELECTED_BACKUP -o $TMP_DIR/$SELECTED_BACKUP; bye"
        echo "Restoring backup..."
        sudo fsarchiver restfs -v "$TMP_DIR/$SELECTED_BACKUP"
        sudo rm -f "$TMP_DIR/$SELECTED_BACKUP"
        echo "Restore completed."
        pause
        return
    fi
done

}

view_logs() { clean_screen echo "Available logs:\n" ls "$LOG_DIR"/*.log 2>/dev/null || echo "No logs found." pause }

clear_logs() { clean_screen echo "Are you sure you want to delete all logs? (y/n)" read -r confirm if [ "$confirm" == "y" ]; then rm -f "$LOG_DIR"/*.log echo "Logs deleted." else echo "Operation cancelled." fi pause }

edit_config() { clean_screen nano "$CONFIG_FILE" pause }

show_config() { clean_screen echo "Current Configuration:\n" cat "$CONFIG_FILE" pause }

----------- MAIN MENU ------------------------

main_menu() { while true; do clean_screen echo "=========== XEMI AUTO BACKUP ===========" echo "1) Create New Backup" echo "2) Restore Backup from FTP" echo "3) View Logs" echo "4) Clear Logs" echo "5) Show Configuration" echo "6) Edit Configuration" echo "0) Exit" echo "========================================" read -rp "Choose an option: " choice case $choice in 1) run_backup ;; 2) restore_backup ;; 3) view_logs ;; 4) clear_logs ;; 5) show_config ;; 6) edit_config ;; 0) exit 0 ;; *) echo "Invalid option"; sleep 1 ;; esac done }

----------- INIT AND RUN ---------------------

init_config main_menu

