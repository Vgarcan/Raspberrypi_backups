![XEMI Auto Backup - Header](xemi_auto_backup_header.png)

# XEMI Auto Backup – Comprehensive Guide

**XEMI Auto Backup** is a robust, interactive backup and restoration tool designed for Raspberry Pi systems. Leveraging the power of `fsarchiver` and `lftp`, it facilitates versioned backups, secure FTP uploads, and seamless restorations, all through an intuitive terminal-based menu.

---

## 📑 Table of Contents

* [Overview](#overview)
* [Features](#features)
* [System Requirements](#system-requirements)
* [Installation](#installation)
* [Configuration](#configuration)
* [Usage Guide](#usage-guide)

  * [1. Create New Backup](#1-create-new-backup)
  * [2. Restore Backup from FTP](#2-restore-backup-from-ftp)
  * [3. View Logs](#3-view-logs)
  * [4. Delete Backup from FTP](#4-delete-backup-from-ftp)
  * [5. Show Configuration](#5-show-configuration)
  * [6. Edit Configuration](#6-edit-configuration)
* [File Structure](#file-structure)
* [Restoring on a New SD Card](#restoring-on-a-new-sd-card)
* [Quick Command Setup](#quick-command-setup)
* [License](#license)

---

## Overview

**XEMI Auto Backup** automates the process of backing up and restoring Raspberry Pi systems. It creates compressed, versioned backups using `fsarchiver`, uploads them to a specified FTP server via `lftp`, and provides options to restore these backups when needed. The tool ensures data integrity through checksums and maintains detailed logs for each operation.

---

## Features

* **Interactive Menu**: User-friendly terminal interface for all operations.
* **Versioned Backups**: Automatically names backups with date and incremental versioning.
* **FTP Integration**: Securely uploads backups and logs to a remote FTP server.
* **Configurable Settings**: Easily editable configuration file for FTP credentials and paths.
* **Comprehensive Logging**: Generates detailed logs for each backup and restoration process.
* **Automatic Cleanup**: Removes temporary files post-operation to conserve space.
* **Selective Restoration**: Allows users to choose specific backups to restore.
* **Exclusion Paths**: Prevents backup of specified directories to avoid redundancy.

---

## System Requirements

* **Hardware**: Raspberry Pi with sudo access.
* **Software**:

  * `fsarchiver`: For creating and restoring backups.
  * `lftp`: For FTP operations.
* **Remote Server**: FTP server with write access for storing backups.

**Installation of Dependencies**:

```bash
sudo apt update
sudo apt install fsarchiver lftp
```

---

## Installation

1. **Download the Script**:

   Save the `auto_backup.sh` script to your local machine.

2. **Move and Rename the Script**:

   ```bash
   mv auto_backup.sh ~/.local/bin/xemi_auto_backup
   ```

3. **Make the Script Executable**:

   ```bash
   chmod +x ~/.local/bin/xemi_auto_backup
   ```

4. **Ensure the Script Directory is in PATH**:

   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

5. **Run the Script**:

   ```bash
   xemi_auto_backup
   ```

---

## Configuration

Upon the first run, the script initializes a configuration file at `~/.config/xemi_auto_backup/config.conf`. This file contains FTP credentials and paths.

**Default Configuration**:

```ini
# FTP Configuration
FTP_HOST=192.168.1.92
FTP_USER=clouduser
FTP_PASS=cloud842867
FTP_REMOTE_PATH=/volume(sda2)/Recovery/my-backups/raspberrypi
```

**Editing Configuration**:

To modify the configuration, select option **6** from the main menu or manually edit the file:

```bash
nano ~/.config/xemi_auto_backup/config.conf
```

---

## Usage Guide

### 1. Create New Backup

* **Process**:

  * Prompts for a commit message and description.
  * Creates a backup of the specified partition using `fsarchiver`.
  * Generates a `.fsa` backup file and a corresponding `.log` file.
  * Uploads both files to the configured FTP server.
  * Cleans up local temporary files upon successful upload.

* **Backup Naming Convention**:

  ```
  rpi_backup_YYYY-MM-DD_Version.fsa
  ```

  Example:

  ```
  rpi_backup_2025-05-04_001.fsa
  ```

### 2. Restore Backup from FTP

* **Process**:

  * Lists available backups on the FTP server.
  * Displays associated commit messages and descriptions.
  * Allows selection of a specific backup to restore.
  * Downloads the selected `.fsa` file.
  * Prompts for the target device to restore the backup.
  * Restores the backup using `fsarchiver`.

* **Note**: Ensure the target device is correctly identified to prevent data loss.

### 3. View Logs

* **Process**:

  * Retrieves and displays log files from the FTP server.
  * Shows details such as commit messages, descriptions, and operating system information.

### 4. Delete Backup from FTP

* **Process**:

  * Lists available backups on the FTP server.
  * Prompts for selection of a backup to delete.
  * Confirms deletion to prevent accidental data loss.
  * Deletes both the `.fsa` and corresponding `.log` files from the FTP server.

### 5. Show Configuration

* **Process**:

  * Displays the current FTP configuration settings.

### 6. Edit Configuration

* **Process**:

  * Opens the configuration file in `nano` for editing.

---

## File Structure

* **Script**: `~/.local/bin/xemi_auto_backup`
* **Configuration**: `~/.config/xemi_auto_backup/config.conf`
* **Logs**: `~/.local/share/xemi_auto_backup/logs/`
* **Temporary Files**: `/tmp/` (e.g., `.fsa`, `.log`, `.backup_marker`)

---

## Restoring on a New SD Card

1. **Prepare the New SD Card**:

   * Flash a fresh Raspberry Pi OS onto the SD card.

2. **Set Up the Script**:

   * Recreate the script directory:

     ```bash
     mkdir -p ~/.local/bin
     ```

   * Move and make the script executable:

     ```bash
     mv auto_backup.sh ~/.local/bin/xemi_auto_backup
     chmod +x ~/.local/bin/xemi_auto_backup
     ```

3. **Run the Script**:

   * Execute the script:

     ```bash
     xemi_auto_backup
     ```

   * Choose option **2** to restore from the cloud.

---

## Quick Command Setup

To run `xemi_auto_backup` from any location:

1. **Ensure the Script is in the PATH**:

   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Run the Script**:

   ```bash
   xemi_auto_backup
   ```

---

## License

Developed by **Víctor G.C.**

This tool is intended for personal and educational use. Feel free to modify and enhance it to suit your needs.
