#!/bin/bash
# Directorio donde se guardarán los logs de la app
LOG_DIR="$HOME/logs"
mkdir -p "$LOG_DIR"

echo "Limpiando logs antiguos en $LOG_DIR..."
# Encuentra y elimina archivos .log mayores a 7 días
find "$LOG_DIR" -type f -name "*.log" -mtime +7 -exec rm -f {} \;
echo "Limpieza completada: $(date)" >> "$LOG_DIR/cleanup_history.txt"
