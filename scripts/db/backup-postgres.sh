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

BACKUP_DIR=${PG_BACKUP_DIR}
DB_NAME="${PG_USER}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${PG_BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

# Ensure backup directory exists
mkdir -p ${PG_BACKUP_DIR}

# Create the backup using pg_dump
echo "Creating backup of ${DB_NAME} database..."
run_docker_cmd exec db pg_dump -U ${PG_USER} ${DB_NAME} >${BACKUP_FILE}

# Keep only last 2 days of backups
find ${BACKUP_DIR} -name "${DB_NAME}_*.sql" -type f -mtime +2 -delete

echo "Backup completed: ${BACKUP_FILE}"
