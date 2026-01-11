#!/bin/bash
set -e

# MongoDB Backup Script
# This script backs up MongoDB databases to S3

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/mongodb_backup_${TIMESTAMP}"
BACKUP_NAME="mongodb_backup_${TIMESTAMP}.tar.gz"

# Environment variables (set by cron or environment)
BUCKET="${BUCKET:-mongodb-backups}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Starting MongoDB backup at ${TIMESTAMP}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Run mongodump
echo "Running mongodump..."
mongodump --out="${BACKUP_DIR}" --quiet

# Compress the backup
echo "Compressing backup..."
tar -czf "/tmp/${BACKUP_NAME}" -C /tmp "mongodb_backup_${TIMESTAMP}"

# Upload to S3
echo "Uploading to S3 bucket: ${BUCKET}"
aws s3 cp "/tmp/${BACKUP_NAME}" "s3://${BUCKET}/backups/${BACKUP_NAME}" --region "${AWS_REGION}"

# Clean up local files
echo "Cleaning up local backup files..."
rm -rf "${BACKUP_DIR}"
rm -f "/tmp/${BACKUP_NAME}"

echo "MongoDB backup completed successfully: ${BACKUP_NAME}"
