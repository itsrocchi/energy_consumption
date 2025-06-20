#!/bin/bash
umask 000


# === CONFIG ===
export CURRENT_SERVER="NOT SET"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# === WILDFLY CONFIGURATION ===

# Mappa di versioni -> nome zip
declare -A WILDFLY_VERSIONS=(
    ["WF25"]="25.0.1.Final"
    ["WF26"]="26.0.1.Final"
)

# Funzione per costruire lo URL
get_wildfly_url() {
    local version=$1
    echo "https://github.com/wildfly/wildfly/releases/download/$version/wildfly-$version.zip"
}


DAYTRADER_EE7_URL="https://github.com/WASdev/sample.daytrader7"
PROJECT_ROOT="$BASE_DIR/sample.daytrader7"
DAYTRADER_EE7="$PROJECT_ROOT/daytrader-ee7"

STANDALONE_XML="$BASE_DIR/standalone.xml"
EAR_FILE="$BASE_DIR/daytrader-ear-3.0-SNAPSHOT.ear"

JMETER_WF="$BASE_DIR/jmx_files/daytrader7_WF.jmx"
JMETER_OL="$BASE_DIR/jmx_files/daytrader7_OL.jmx"
JMETER_BIN="/home/lorenzo/development/apache-jmeter-5.6.3/bin/jmeter" #check qua 

RAPL_FILE="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"
CURRENT_SERVER_FILE="/tmp/current_server.txt"

REPORT_DIR="$BASE_DIR/reports"

ENERGY_LOG_WF="$BASE_DIR/energy_log_WF.txt"
ENERGY_LOG_OL="$BASE_DIR/energy_log_OL.txt"
ENERGY_LOG_WF26="$BASE_DIR/energy_log_WF_26.txt"
ENERGY_LOG_WF27="$BASE_DIR/energy_log_WF_27.txt"

FINAL_LOG="$BASE_DIR/energy_log_final.txt"

POM_25="$BASE_DIR/poms_openliberty/pom_original.xml"
POM_23="$BASE_DIR/poms_openliberty/pom_v2.xml"

run_wildfly_test() {
    local key=$1
    local version="${WILDFLY_VERSIONS[$key]}"
    local zip_file="wildfly-$version.zip"
    local dir_name="wildfly-$version"
    local url
    url=$(get_wildfly_url "$version")
    local log_file="$BASE_DIR/energy_log_WF${key}.txt"
    local jmeter_output="jmeter_output_WF_${key}.jtl"

    if [ ! -d "$dir_name" ]; then
        echo "Scarico WildFly $version..."
        wget "$url" -O "$zip_file"
        unzip "$zip_file"
        rm "$zip_file"
    fi
    chmod -R 777 "$dir_name"

    echo "Replacing standalone.xml for WildFly $version..."
    cp "$STANDALONE_XML" "$dir_name/standalone/configuration/standalone.xml"

    echo "Copying EAR for WildFly $version..."
    cp "$EAR_FILE" "$dir_name/standalone/deployments/"

    cp -r modules/com "$dir_name/modules/"

    export CURRENT_SERVER="WildFly $version"
    echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

    "$dir_name/bin/standalone.sh" &

    echo "Waiting for WildFly $version to start..."
    sleep 30

    energyBefore=$(cat "$RAPL_FILE")
    echo "Inizio test WildFly $version - energy_uj: $energyBefore" > "$log_file"

    rm -f "$jmeter_output"
    touch "$jmeter_output"

    "$JMETER_BIN" -n -t "$JMETER_WF" -l "$jmeter_output"

    energyAfter=$(cat "$RAPL_FILE")
    echo "Fine test WildFly $version - energy_uj: $energyAfter" >> "$log_file"
    delta=$((energyAfter - energyBefore))
    echo "Delta energy_uj: $delta" >> "$log_file"

    export CURRENT_SERVER="NOT SET"
    echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

    pkill -f standalone
    rm -rf "$dir_name"
}


# Avvia MySQL
sudo systemctl start mysql
if ! systemctl is-active --quiet mysql; then
    echo "MySQL failed to start."
    exit 1
fi

# === ESECUZIONE TEST WILDFLY MULTIVERSIONE ===

# Avvia MySQL prima dei test WildFly
sudo systemctl start mysql
if ! systemctl is-active --quiet mysql; then
    echo "MySQL failed to start."
    exit 1
fi

# Esegui test per ogni versione
run_wildfly_test "WF25"
run_wildfly_test "WF26"


# === STEP 3. Open Liberty v1 ===

if [ ! -d "$PROJECT_ROOT" ]; then
    git clone "$DAYTRADER_EE7_URL" "$PROJECT_ROOT"
fi

echo "Copying pom_original.xml..."
cp "$POM_23" "$DAYTRADER_EE7/pom.xml"

cd "$PROJECT_ROOT"
mvn clean install -DskipTests

cd "$DAYTRADER_EE7"
export CURRENT_SERVER="OpenLiberty 25"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

mvn liberty:run -Dopenliberty.runtime.version=25.0.0.5 &

sleep 30

energyBefore=$(cat "$RAPL_FILE")
echo "Inizio test OPENLIBERTY 25 - energy_uj: $energyBefore" > "$ENERGY_LOG_OL"

rm -f jmeter_output_OL.jtl
touch jmeter_output_OL.jtl

"$JMETER_BIN" -n -t "$JMETER_OL" -l "$BASE_DIR/jmeter_output_OL.jtl"

energyAfter=$(cat "$RAPL_FILE")
echo "Fine test OPENLIBERTY 25 - energy_uj: $energyAfter" >> "$ENERGY_LOG_OL"
delta=$((energyAfter - energyBefore))
echo "Delta energy_uj: $delta" >> "$ENERGY_LOG_OL"

# === CONFIG ===
export CURRENT_SERVER="NOT SET"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

pkill -f 'org.codehaus.plexus.classworlds.launcher.Launcher'
rm -rf "$DAYTRADER_EE7/target/liberty/wlp"


# === STEP 4. Open Liberty v2 ===

echo "Copying pom_v2.xml..."
cp "$POM_23" "$DAYTRADER_EE7/pom.xml"

cd "$PROJECT_ROOT"
mvn clean install -DskipTests

cd "$DAYTRADER_EE7"
export CURRENT_SERVER="OpenLiberty 23"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

mvn liberty:run -Dopenliberty.runtime.version=23.0.0.10 &

sleep 30

energyBefore=$(cat "$RAPL_FILE")
echo "Inizio test OPENLIBERTY 23 - energy_uj: $energyBefore" > "$ENERGY_LOG_WF27"

rm -f jmeter_output_OL_2.jtl
touch jmeter_output_OL_2.jtl

"$JMETER_BIN" -n -t "$JMETER_OL" -l "$BASE_DIR/jmeter_output_OL_2.jtl"

energyAfter=$(cat "$RAPL_FILE")
echo "Fine test OPENLIBERTY 23 - energy_uj: $energyAfter" >> "$ENERGY_LOG_WF27"
delta=$((energyAfter - energyBefore))
echo "Delta energy_uj: $delta" >> "$ENERGY_LOG_WF27"

pkill -f 'org.codehaus.plexus.classworlds.launcher.Launcher'

# === Merge Log ===

echo "Merging energy logs..."
cat "$ENERGY_LOG_WF" "$ENERGY_LOG_OL" "$ENERGY_LOG_WF26" "$ENERGY_LOG_WF27" > "$FINAL_LOG"

echo "Automation script completed."

export CURRENT_SERVER="NOT SET"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

#remove the git repository
echo "Rimozione di: $PROJECT_ROOT"
if [ -d "$PROJECT_ROOT" ]; then
    sudo rm -rf "$PROJECT_ROOT"
    echo "Rimosso con successo"
else
    echo "Directory non trovata: $PROJECT_ROOT"
fi

