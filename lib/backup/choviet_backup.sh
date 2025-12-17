#!/bin/bash
set -euo pipefail

TS=$(date +%Y%m%d_%H%M%S)
APP=choviet
BACKUP_DIR=/tmp/backups
DB_PATH=/rails/storage/production.sqlite3
STORAGE_PATH=/rails/storage
S3_BUCKET=choviet-backups

mkdir -p $BACKUP_DIR

echo "[$(date)] Starting backup..."

# 1. SQLite DB 백업 (sqlite3 .backup 명령으로 안전하게)
sqlite3 $DB_PATH ".backup '${BACKUP_DIR}/${APP}_db_${TS}.sqlite3'"

# 2. Storage 아카이브 (uploads 등)
tar -czf ${BACKUP_DIR}/${APP}_storage_${TS}.tar.gz -C $STORAGE_PATH .

# 3. S3 업로드
aws s3 cp ${BACKUP_DIR}/${APP}_db_${TS}.sqlite3 s3://${S3_BUCKET}/db/
aws s3 cp ${BACKUP_DIR}/${APP}_storage_${TS}.tar.gz s3://${S3_BUCKET}/storage/

# 4. 로컬 임시파일 정리
rm -f ${BACKUP_DIR}/${APP}_db_${TS}.sqlite3
rm -f ${BACKUP_DIR}/${APP}_storage_${TS}.tar.gz

echo "[$(date)] Backup completed: ${TS}"