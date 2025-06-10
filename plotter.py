import os
import pandas as pd
import matplotlib.pyplot as plt

# === CONFIG ===
CSV_FILE = 'rapl_sampling.csv'  # usa path relativo o assoluto
RESULTS_DIR = './results'

# === CREATE RESULTS DIR IF NOT EXISTS ===
os.makedirs(RESULTS_DIR, exist_ok=True)

# === LOAD DATA ===
df = pd.read_csv(CSV_FILE)

# === GET UNIQUE SERVERS, EXCLUDING 'NOT SET' ===
servers = df['server'].unique()
servers = [s for s in servers if s != 'NOT SET']

# === COLORS MAP ===
colors = plt.cm.get_cmap('tab10', len(servers))

# === PLOT ENERGY BY SERVER ===
plt.figure(figsize=(12, 6))
for i, server in enumerate(servers):
    df_server = df[df['server'] == server]
    plt.plot(df_server['timestamp_ms'], df_server['energy_uj'],
             label=f'Energy - {server}',
             color=colors(i))

plt.xlabel('Timestamp (ms)')
plt.ylabel('Energy (uJ)')
plt.title('Total Energy Consumption Over Time by Server')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'energy_plot_by_server.png'))
plt.close()

# === PLOT DELTA ENERGY BY SERVER ===
plt.figure(figsize=(12, 6))
for i, server in enumerate(servers):
    df_server = df[df['server'] == server]
    plt.plot(df_server['timestamp_ms'], df_server['delta_energy_uj'],
             label=f'Delta Energy - {server}',
             color=colors(i))

plt.xlabel('Timestamp (ms)')
plt.ylabel('Delta Energy (uJ)')
plt.title('Instantaneous Energy Consumption by Server')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'delta_energy_plot_by_server.png'))
plt.close()

# === PLOT RAM USAGE BY SERVER ===
plt.figure(figsize=(12, 6))
for i, server in enumerate(servers):
    df_server = df[df['server'] == server]
    plt.plot(df_server['timestamp_ms'], df_server['ram_usage_MB'],
             label=f'RAM Usage - {server}',
             color=colors(i))

plt.xlabel('Timestamp (ms)')
plt.ylabel('RAM Usage (MB)')
plt.title('RAM Usage Over Time by Server')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'ram_usage_plot_by_server.png'))
plt.close()

print("Plot salvati con distinzione per server (escluso 'NOT SET') nella cartella ./results")
