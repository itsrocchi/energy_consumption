#!/bin/bash
umask 000

# === CONFIGURAZIONE ===
RAPL_FILE="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"
SAMPLING_INTERVAL_MS=100  # intervallo in millisecondi
CSV_FILE="/energy_consumption/rapl_sampling.csv"  # esempio di path universale
AUTOMATION_SCRIPT="/energy_consumption/automation_update.sh"
CURRENT_SERVER_FILE="/tmp/current_server.txt"

# === FUNZIONE PER LEGGERE RAM USAGE ===
get_ram_usage_mb() {
    local mem_total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_free_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_used_kb=$((mem_total_kb - mem_free_kb))
    echo $((mem_used_kb / 1024))
}

# === FUNZIONE PER CAMPIONAMENTO ===
sample_rapl() {
    echo "CSV_FILE=$CSV_FILE"
    echo "RAPL_FILE=$RAPL_FILE"
    echo "timestamp_ms,energy_uj,delta_energy_uj,ram_usage_MB,server" > "$CSV_FILE"
    chmod 644 "$CSV_FILE"

    local start_time=$(date +%s%3N)
    local sleep_interval=$(awk -v ms="$SAMPLING_INTERVAL_MS" 'BEGIN {printf "%.3f", ms / 1000}')
    local prev_energy=$(cat "$RAPL_FILE" 2>/dev/null)

    while kill -0 "$1" 2>/dev/null; do
        local current_time=$(date +%s%3N)
        local delta_time=$((current_time - start_time))

        local energy=$(cat "$RAPL_FILE" 2>/dev/null)
        local delta_energy=$((energy - prev_energy))
        prev_energy=$energy

        local ram_usage=$(get_ram_usage_mb)

        local current_server="UNKNOWN"
        if [ -f "$CURRENT_SERVER_FILE" ]; then
            current_server=$(cat "$CURRENT_SERVER_FILE")
        fi

        echo "$delta_time,$energy,$delta_energy,$ram_usage,$current_server" >> "$CSV_FILE"

        sleep "$sleep_interval"
    done

    chmod 644 "$CSV_FILE"
}

# === AVVIO AUTOMATION.SH E CAMPIONAMENTO ===
echo "Starting automation script and RAPL sampling..."

sudo bash "$AUTOMATION_SCRIPT" &
AUTOMATION_PID=$!

# Anche il campionamento ha bisogno dei permessi sudo per leggere RAPL
sudo CSV_FILE="$CSV_FILE" RAPL_FILE="$RAPL_FILE" SAMPLING_INTERVAL_MS="$SAMPLING_INTERVAL_MS" CURRENT_SERVER_FILE="$CURRENT_SERVER_FILE" bash -c "$(declare -f sample_rapl); $(declare -f get_ram_usage_mb); sample_rapl $AUTOMATION_PID"

echo "Sampling completed. Output saved in $CSV_FILE"

# lancia lo script python plotter.py
echo "Running plotter.py to generate graphs..."
python3 /energy_consumption/plotter.py
echo "Graphs generated successfully."