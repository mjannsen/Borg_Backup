# Borg_Backup
This is a set of useful scripts for setting up a borg backup to a (remote) repository. 
Features:
* Defining variables, exclude and include patterns via config / env files
* Backup script for creating / updating backups as well as pruning
* Automated mounting of repository to a local folder for easy browsing and restoring from the archive

### Running Backups
* run `borg_backup.sh` to create initial backup
* add entry to crontab for daily backups: 
```
0 3 * * * /MY_PATH_TO/borg-backup/borg-backup.sh > /dev/null 2>&1
```
* check logfile for results or errors

## Disclaimer

The Repo is primarily designed for personal use, so it is subject to frequent modifications and glitches. Use it at your own risk and do not anticipate guidance for its installation on your device.
