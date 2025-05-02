# XEMI Auto Backup

**XEMI Auto Backup** is a professional, menu-driven backup and restore tool for Raspberry Pi systems. It uses `fsarchiver` and `lftp` to manage versioned backups, upload them to a remote FTP server, and restore them with logs and commit messages.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
  - [1. Create New Backup](#1-create-new-backup)
  - [2. Restore Backup from FTP](#2-restore-backup-from-ftp)
  - [3. View Logs](#3-view-logs)
  - [4. Clear Logs](#4-clear-logs)
  - [5. Show Configuration](#5-show-configuration)
  - [6. Edit Configuration](#6-edit-configuration)
- [File Structure](#file-structure)
- [Restore on New SD Card](#restore-on-new-sd-card)
- [Quick Command Setup (Optional)](#quick-command-setup-optional)
- [License](#license)

---

## Features

- ✅ Easy-to-use interactive terminal menu  
- 📦 Versioned backups with commit messages and descriptions  
- ☁️ Automatic upload of backups and logs to an FTP server  
- 🔐 Configurable settings (FTP host, user, password, path)  
- 📝 Logs matched to each backup (same filename, `.log` extension)  
- ♻️ Automatic local cleanup after upload  
- 🔍 View full logs before restoring a backup  
- ⚠️ Excludes cloud/FTP paths to prevent recursive backups  
- 🧽 Ensures no local backup residue remains  

---

## Requirements

- `fsarchiver`
- `lftp`
- A Raspberry Pi with sudo access
- Remote FTP server with write access

---

## Installation

```bash
mv auto_backup.sh ~/.local/bin/xemi_auto_backup
chmod +x ~/.local/bin/xemi_auto_backup

Ensure ~/.local/bin is in your PATH:

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

Run with:

xemi_auto_backup


---

Usage

1. Create New Backup

Input a commit message and description

Backup will be created with a versioned filename: rpi_backup_YYYY-MM-DD_001.fsa

A matching .log file is generated

Both files are uploaded to the FTP server

Backup is removed locally after successful upload


2. Restore Backup from FTP

Lists all available backups in the cloud with commit summaries

Lets you view the full log before restoring

Once confirmed, downloads the .fsa file and restores it with fsarchiver


3. View Logs

Displays all .log files stored locally


4. Clear Logs

Deletes all local logs


5. Show Configuration

Prints the current FTP configuration


6. Edit Configuration

Opens config.conf in nano for easy editing



---

File Structure


---

Restore on New SD Card

1. Flash a fresh Raspberry Pi OS


2. Recreate the path ~/.local/bin/ and place the script there


3. Make it executable:

chmod +x ~/.local/bin/xemi_auto_backup


4. Run xemi_auto_backup and choose option 2 to restore from cloud




---

Quick Command Setup (Optional)

To run xemi_auto_backup from anywhere using just one command:

1. Move the script

mkdir -p ~/.local/bin
mv auto_backup.sh ~/.local/bin/xemi_auto_backup
chmod +x ~/.local/bin/xemi_auto_backup

2. Add ~/.local/bin to your PATH

If not already set, add this to your ~/.bashrc (or ~/.zshrc if using Zsh):

export PATH="$HOME/.local/bin:$PATH"

Then reload your shell:

source ~/.bashrc

3. Run it!

Now you can just type:

xemi_auto_backup

...from anywhere in your terminal and the menu will launch.


---

License

Developed by Víctor G.C.
For personal and educational use. Modify and improve freely.



