#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <backup_timestamp>"
  echo "Example: $0 20251218_033000"
  exit 1
fi

TS=$1
APP=choviet
RESTORE_DIR=/tmp/restore
DB_PATH=/rails/storage/production.sqlite3
STORAGE_PATH=/rails/storage
S3_BUCKET=choviet-backups

mkdir -p $RESTORE_DIR

echo "[$(date)] Starting restore for timestamp: $TS"

# 1. S3에서 다운로드
aws s3 cp s3://${S3_BUCKET}/db/${APP}_db_${TS}.sqlite3 ${RESTORE_DIR}/
aws s3 cp s3://${S3_BUCKET}/storage/${APP}_storage_${TS}.tar.gz ${RESTORE_DIR}/

# 2. 현재 DB 백업 (안전장치)
cp $DB_PATH ${DB_PATH}.before_restore

# 3. DB 복원
cp ${RESTORE_DIR}/${APP}_db_${TS}.sqlite3 $DB_PATH

# 4. Storage 복원
tar -xzf ${RESTORE_DIR}/${APP}_storage_${TS}.tar.gz -C $STORAGE_PATH

echo "[$(date)] Restore completed"