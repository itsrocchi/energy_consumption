#!/bin/bash
umask 000


# === CONFIG ===
export CURRENT_SERVER="NOT SET"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

WILDFLY_URL="https://github.com/wildfly/wildfly/releases/download/25.0.1.Final/wildfly-25.0.1.Final.zip"
WILDFLY_ZIP="wildfly-25.0.1.Final.zip"
WILDFLY_DIR="wildfly-25.0.1.Final"

WILDFLY_URL_2="https://github.com/wildfly/wildfly/releases/download/26.0.1.Final/wildfly-26.0.1.Final.zip"
WILDFLY_ZIP_2="wildfly-26.0.1.Final.zip"
WILDFLY_DIR_2="wildfly-26.0.1.Final"

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

# === STEP 1. WildFly 25 ===

if [ ! -d "$WILDFLY_DIR" ]; then
    wget "$WILDFLY_URL"
    unzip "$WILDFLY_ZIP"
    rm "$WILDFLY_ZIP"
fi
chmod 777 "$WILDFLY_DIR"

echo "Replacing standalone.xml for WildFly 25..."
cp "$STANDALONE_XML" "$WILDFLY_DIR/standalone/configuration/standalone.xml"

echo "Copying EAR for WildFly 25..."
cp "$EAR_FILE" "$WILDFLY_DIR/standalone/deployments/"

cp -r modules/com "$WILDFLY_DIR/modules/"

# Avvia MySQL
sudo systemctl start mysql
if ! systemctl is-active --quiet mysql; then
    echo "MySQL failed to start."
    exit 1
fi

# Avvia WildFly 25
export CURRENT_SERVER="WildFly 25"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

"$WILDFLY_DIR/bin/standalone.sh" &

echo "Waiting for WildFly 25 to start..."
sleep 30

# JMeter WildFly 25
energyBefore=$(cat "$RAPL_FILE")
echo "Inizio test WILDFLY 25 - energy_uj: $energyBefore" > "$ENERGY_LOG_WF"

rm -f jmeter_output_WF.jtl
touch jmeter_output_WF.jtl

"$JMETER_BIN" -n -t "$JMETER_WF" -l jmeter_output_WF.jtl

energyAfter=$(cat "$RAPL_FILE")
echo "Fine test WILDFLY 25 - energy_uj: $energyAfter" >> "$ENERGY_LOG_WF"
delta=$((energyAfter - energyBefore))
echo "Delta energy_uj: $delta" >> "$ENERGY_LOG_WF"

pkill -f standalone
rm -rf "$WILDFLY_DIR"

# === STEP 2. WildFly 26 ===

if [ ! -d "$WILDFLY_DIR_2" ]; then
    wget "$WILDFLY_URL_2"
    unzip "$WILDFLY_ZIP_2"
    rm "$WILDFLY_ZIP_2"
fi
chmod 777 "$WILDFLY_DIR_2"

echo "Replacing standalone.xml for WildFly 26..."
cp "$STANDALONE_XML" "$WILDFLY_DIR_2/standalone/configuration/standalone.xml"

echo "Copying EAR for WildFly 26..."
cp "$EAR_FILE" "$WILDFLY_DIR_2/standalone/deployments/"

cp -r modules/com "$WILDFLY_DIR_2/modules/"

export CURRENT_SERVER="WildFly 26"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

"$WILDFLY_DIR_2/bin/standalone.sh" &

echo "Waiting for WildFly 26 to start..."
sleep 30

energyBefore=$(cat "$RAPL_FILE")
echo "Inizio test WILDFLY 26 - energy_uj: $energyBefore" > "$ENERGY_LOG_WF26"

rm -f jmeter_output_WF_26.jtl
touch jmeter_output_WF_26.jtl

"$JMETER_BIN" -n -t "$JMETER_WF" -l jmeter_output_WF_26.jtl

energyAfter=$(cat "$RAPL_FILE")
echo "Fine test WILDFLY 26 - energy_uj: $energyAfter" >> "$ENERGY_LOG_WF26"
delta=$((energyAfter - energyBefore))
echo "Delta energy_uj: $delta" >> "$ENERGY_LOG_WF26"

pkill -f standalone
rm -rf "$WILDFLY_DIR_2"

# === STEP 3. Open Liberty v1 ===

if [ ! -d "$PROJECT_ROOT" ]; then
    git clone "$DAYTRADER_EE7_URL" "$PROJECT_ROOT"
fi

echo "Copying pom_original.xml..."
cp "$POM_25" "$DAYTRADER_EE7/pom.xml"

cd "$PROJECT_ROOT"
mvn clean install -DskipTests

cd "$DAYTRADER_EE7"
export CURRENT_SERVER="OpenLiberty 25"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

mvn liberty:run &

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

pkill -f 'org.codehaus.plexus.classworlds.launcher.Launcher'

# === STEP 4. Open Liberty v2 ===

echo "Copying pom_v2.xml..."
cp "$POM_23" "$DAYTRADER_EE7/pom.xml"

cd "$PROJECT_ROOT"
mvn clean install -DskipTests

cd "$DAYTRADER_EE7"
export CURRENT_SERVER="OpenLiberty 23"
echo "$CURRENT_SERVER" > "$CURRENT_SERVER_FILE"

mvn liberty:run &

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
rm -rf "$PROJECT_ROOT"