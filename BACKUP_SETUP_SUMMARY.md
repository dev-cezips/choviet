# Choviet Backup Setup Summary

## Completed Tasks

### 1. Sentry Error Tracking Integration ✅
- Added sentry-ruby and sentry-rails gems
- Configured with production-only setup and 0.1 traces sample rate
- Successfully deployed with DSN: `https://fbd7e344ae1cb177d6eed15093edbd83@o4510551808671744.ingest.us.sentry.io/4510552033853440`

### 2. SQLite Backup System ✅
- Created backup script using `sqlite3 .backup` command for safe database backups
- Backs up both SQLite database and storage directory to S3
- S3 bucket: `choviet-backups` with `prod/` prefix
- 14-day retention policy configured

### 3. Backup Safety Upgrades ✅
- **Backup Script** (`/usr/local/bin/choviet_backup.sh`): Uses sqlite3 .backup command
- **Wrapper Script** (`/usr/local/bin/choviet_backup_wrapper.sh`): Handles logging and notifications
- **Slack Notifications** (`/usr/local/bin/choviet_notify_slack.sh`): Python3-based for JSON safety
- **Cron Job** (`/etc/cron.d/choviet_backup`): Runs daily at 03:30 KST (18:30 UTC)
- **Logrotate** (`/etc/logrotate.d/choviet_backup`): 14-day log rotation with compression

## Server Configuration Files

### 1. `/etc/choviet/backup.env`
```bash
AWS_ACCESS_KEY_ID=REDACTED
AWS_SECRET_ACCESS_KEY=REDACTED
AWS_DEFAULT_REGION=us-east-1
S3_BUCKET=choviet-backups
S3_PREFIX=prod
SLACK_WEBHOOK_URL=REDACTED
# Slack notification: OK=daily, FAIL=always
```

### 2. `/etc/cron.d/choviet_backup`
```bash
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 03:30 KST = 18:30 UTC
30 18 * * * root /usr/local/bin/choviet_backup_wrapper.sh
```

### 3. `/etc/logrotate.d/choviet_backup`
```
/var/log/choviet_backup.log {
  su root root
  daily
  rotate 14
  missingok
  notifempty
  compress
  delaycompress
  copytruncate
}
```

## Backup Commands

### Manual Backup
```bash
bin/kamal server exec --hosts=3.34.133.227 'sudo /usr/local/bin/choviet_backup_wrapper.sh'
```

### Test Slack Notification
```bash
bin/kamal server exec --hosts=3.34.133.227 'sudo /usr/local/bin/choviet_notify_slack.sh TEST "Test message" /var/log/choviet_backup.log 5'
```

### Check Backup Logs
```bash
bin/kamal server exec --hosts=3.34.133.227 'sudo tail -20 /var/log/choviet_backup.log'
```

### List S3 Backups
```bash
aws s3 ls s3://choviet-backups/prod/db/
aws s3 ls s3://choviet-backups/prod/storage/
```

## Notification Policy
- **Success (OK)**: Notified daily with backup summary
- **Failure (FAIL)**: Notified immediately with error logs

## Security Notes
- All scripts use proper error handling with `set -euo pipefail`
- AWS credentials stored securely in `/etc/choviet/backup.env`
- SQLite backup uses `.backup` command for safe hot backups
- Python3 used for Slack notifications to ensure proper JSON escaping