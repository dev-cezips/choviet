# Choviet 백업/복구 가이드

## 백업 구성
- 스케줄: 매일 03:30 KST
- 보관: S3에 14일
- 대상: SQLite DB + ActiveStorage 파일

## 수동 백업 실행
```bash
bin/kamal server exec --hosts=3.34.133.227 '/usr/local/bin/choviet_backup.sh'
```

## 복구 절차
1. 백업 목록 확인: `aws s3 ls s3://choviet-backups/db/`
2. 복구 실행: `bin/kamal server exec --hosts=3.34.133.227 '/usr/local/bin/choviet_restore.sh 20251218_033000'`
3. 앱 재시작: `bin/kamal app boot`

## S3 Lifecycle 정책 (14일 보관)
AWS 콘솔에서 설정 또는 aws cli로 설정