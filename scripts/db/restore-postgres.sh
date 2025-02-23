#!/bin/bash

# Parse command line arguments
USE_SUDO=false
while [[ $# -gt 0 ]]; do
  case $1 in
  -s | --run-as-sudo)
    USE_SUDO=true
    shift
    ;;
  *)
    BACKUP_FILE="$1"
    shift
    ;;
  esac
done

# Function to run docker compose commands with or without sudo
run_docker_cmd() {
  if [ "$USE_SUDO" = true ]; then
    sudo docker-compose "$@"
  else
    docker-compose "$@"
  fi
}

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | grep -v '#' | xargs)
else
  echo "Error: .env file not found"
  exit 1
fi

# Verify if all necessary env variables are set
if [ -z "$PG_BACKUP_DIR" ]; then
  echo "PG_BACKUP_DIR is not set. Please add it to the .env file."
  exit 1
fi

if [ -z "$PG_USER" ]; then
  echo "PG_USER is not set. Please add it to the .env file."
  exit 1
fi

# Check if backup file was provided
if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 [-s|--run-as-sudo] <backup_file>"
  echo "Example: $0 ${PG_BACKUP_DIR}/tincanner_20240223_020000.sql"
  echo "Options:"
  echo "  -s, --run-as-sudo    Run docker compose commands with sudo"
  exit 1
fi

DB_NAME="${PG_USER}"

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Warning: This will destroy the current database and restore from backup."
echo "Database: ${DB_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo "Are you sure you want to continue? (y/n)"
read -r confirm

if [ "$confirm" != "y" ]; then
  echo "Restore cancelled."
  exit 1
fi

# Drop existing connections
echo "Dropping existing connections..."
run_docker_cmd exec db psql -U ${PG_USER} postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '${DB_NAME}'
AND pid <> pg_backend_pid();"

# Drop and recreate database from template0
echo "Dropping and recreating database..."
run_docker_cmd exec db dropdb -U ${PG_USER} ${DB_NAME}
run_docker_cmd exec db createdb -U ${PG_USER} -T template0 ${DB_NAME}

# Restore from backup
echo "Restoring from backup..."
cat ${BACKUP_FILE} | run_docker_cmd exec -T db psql -U ${PG_USER} ${DB_NAME}

echo "Restore completed successfully!"
