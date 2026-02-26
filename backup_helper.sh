#!/bin/bash
# === backup_helper.sh
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
echo "Использование: $0 <директория> [место_сохранения]"
exit 0
fi
if [ $# -eq 0 ]; then
echo -e "${RED}Ошибка: Укажите директорию${NC}"
exit 1
fi
SOURCE_DIR="$1"
# === ДОБАВЛЕНИЕ 2: ВТОРОЙ АРГУМЕНТ ===
if [ $# -ge 2 ]; then
    BACKUP_DIR="$2"
else
    BACKUP_DIR="$HOME/backups"
fi
LOG_FILE="$BACKUP_DIR/backup.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Ошибка: Директория не существует${NC}"
    exit 1
fi
mkdir -p "$BACKUP_DIR"
log_message() {
    echo "[$(date +%Y-%m-%d\ %H:%M:%S)] - $1" >> "$LOG_FILE"
    echo -e "${GREEN}[LOG]${NC} $1"
}
log_message "=== Запуск резервного копирования ==="
log_message "Источник: $SOURCE_DIR"

MIN_SPACE_MB=100
AVAILABLE_SPACE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_MB=$((AVAILABLE_SPACE / 1024))
if [ "$AVAILABLE_SPACE_MB" -lt "$MIN_SPACE_MB" ]; then
    log_message "${YELLOW}Внимание: Мало места (${AVAILABLE_SPACE_MB} МБ)${NC}"
    read -p "Продолжить? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
BASENAME=$(basename "$SOURCE_DIR")
BACKUP_FILE="$BACKUP_DIR/${BASENAME}_backup_${TIMESTAMP}.tar.gz"
log_message "Создание архива: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_message "Архив создан: $BACKUP_FILE ($FILE_SIZE)"
else
    log_message "${RED}Ошибка при создании архива${NC}"
    exit 1
fi
# === ДОБАВЛЕНИЕ 3: УДАЛЕНИЕ СТАРЫХ (>7 ДНЕЙ) ===
find "$BACKUP_DIR" -name "${BASENAME}_backup_*.tar.gz" -type f -mtime +7 -delete 2>/dev/null
log_message "Информация об архиве:"
echo "Размер: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Файлов: $(tar -tzf "$BACKUP_FILE" | wc -l)"
echo "MD5: $(md5sum "$BACKUP_FILE" | cut -d' ' -f1)"
echo "=== УВЕДОМЛЕНИЕ ===" > "$BACKUP_DIR/last_notification.txt"
echo "Копия $BASENAME создана" >> "$BACKUP_DIR/last_notification.txt"
echo "Время: $(date)" >> "$BACKUP_DIR/last_notification.txt"
echo "Файл: $BACKUP_FILE" >> "$BACKUP_DIR/last_notification.txt"

og_message "Копирование завершено!"
echo -e "\n${YELLOW}Последние записи в логе:${NC}"
tail -5 "$LOG_FILE"


