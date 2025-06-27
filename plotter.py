import os
import pandas as pd
import matplotlib.pyplot as plt
import math

# === CONFIG ===
CSV_FILE = 'rapl_sampling.csv'
RESULTS_DIR = './results'

# === CREATE RESULTS DIR IF NOT EXISTS ===
os.makedirs(RESULTS_DIR, exist_ok=True)

# === LOAD DATA ===
df = pd.read_csv(CSV_FILE)

# === FILTER VALID SERVERS ===
servers = [s for s in df['server'].unique() if s not in ['NOT SET', 'UNKNOWN']]
num_servers = len(servers)

# === NORMALIZED TIMESTAMP PER SERVER ===
df['normalized_timestamp'] = df.groupby('server')['timestamp_ms'].transform(lambda x: x - x.min())

# === LOCAL NORMALIZATION (PER SERVER) ===
for metric in ['delta_energy_uj', 'ram_usage_MB']:
    norm_col = f'normalized_{metric}'
    df[norm_col] = df.groupby('server')[metric].transform(
        lambda x: (x - x.min()) / (x.max() - x.min()) if (x.max() - x.min()) > 0 else 0
    )

# === GLOBAL NORMALIZATION (SAME SCALE FOR ALL SERVERS) ===
df['global_normalized_delta_energy_uj'] = (df['delta_energy_uj'] - df['delta_energy_uj'].min()) / (df['delta_energy_uj'].max() - df['delta_energy_uj'].min())
df['global_normalized_ram_usage_MB'] = (df['ram_usage_MB'] - df['ram_usage_MB'].min()) / (df['ram_usage_MB'].max() - df['ram_usage_MB'].min())

# === COLOR MAP ===
colors = plt.cm.get_cmap('tab10', len(servers))

# === PLOT: TOTAL ENERGY (NON NORMALIZED) ===
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
plt.savefig(os.path.join(RESULTS_DIR, 'energy_by_server.png'))
plt.close()

# === FUNCTION: PLOT LOCAL NORMALIZED METRICS ===
def plot_normalized_metric_grid(metric, ylabel, title, filename):
    rows = 2
    cols = math.ceil(num_servers / 2)
    fig, axs = plt.subplots(rows, cols, figsize=(14, 8), sharex=False)
    axs = axs.flatten()

    for i, server in enumerate(servers):
        df_server = df[df['server'] == server]
        axs[i].plot(df_server['normalized_timestamp'], df_server[f'normalized_{metric}'],
                    color='tab:blue')
        axs[i].set_title(server)
        axs[i].set_ylabel(ylabel)
        axs[i].grid(True)

    for j in range(i + 1, len(axs)):
        axs[j].axis('off')

    fig.suptitle(title)
    for ax in axs:
        ax.set_xlabel('Normalized Timestamp (ms)')
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(os.path.join(RESULTS_DIR, filename))
    plt.close()

# === FUNCTION: PLOT GLOBAL NORMALIZED METRICS ===
def plot_global_normalized_metric_grid(metric, ylabel, title, filename):
    rows = 2
    cols = math.ceil(num_servers / 2)
    fig, axs = plt.subplots(rows, cols, figsize=(14, 8), sharex=False)
    axs = axs.flatten()

    for i, server in enumerate(servers):
        df_server = df[df['server'] == server]
        axs[i].plot(df_server['normalized_timestamp'], df_server[f'global_normalized_{metric}'], color='tab:green')
        axs[i].set_title(server)
        axs[i].set_ylabel(ylabel)
        axs[i].grid(True)
        
    for j in range(i + 1, len(axs)):
        axs[j].axis('off')

    fig.suptitle(title)
    for ax in axs:
        ax.set_xlabel('Normalized Timestamp (ms)')
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(os.path.join(RESULTS_DIR, filename))
    plt.close()

# === FUNCTION: BOXPLOT ===
def boxplot_metric(metric, ylabel, title, filename):
    data = [df[df['server'] == s][metric] for s in servers]
    plt.figure(figsize=(10, 6))
    plt.boxplot(data, labels=servers)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.grid(True)
    plt.savefig(os.path.join(RESULTS_DIR, filename))
    plt.close()

# === GENERATE GRAPHS ===

# 1. LOCAL NORMALIZED ENERGY
plot_normalized_metric_grid(
    metric='delta_energy_uj',
    ylabel='Normalized Delta Energy (0-1)',
    title='Normalized Instantaneous Energy Consumption by Server',
    filename='normalized_delta_energy_by_server_grid.png'
)

# 2. GLOBAL NORMALIZED ENERGY
plot_global_normalized_metric_grid(
    metric='delta_energy_uj',
    ylabel='Global Normalized Delta Energy (0-1)',
    title='Global Normalized Instantaneous Energy Consumption by Server',
    filename='global_normalized_delta_energy_by_server_grid.png'
)

# 3. LOCAL NORMALIZED RAM
plot_normalized_metric_grid(
    metric='ram_usage_MB',
    ylabel='Normalized RAM Usage (0-1)',
    title='Normalized RAM Usage Over Time by Server',
    filename='normalized_ram_usage_by_server_grid.png'
)

# 4. GLOBAL NORMALIZED RAM
plot_global_normalized_metric_grid(
    metric='ram_usage_MB',
    ylabel='Global Normalized RAM Usage (0-1)',
    title='Global Normalized RAM Usage Over Time by Server',
    filename='global_normalized_ram_usage_by_server_grid.png'
)

# 5. BOXPLOT ENERGY (RAW)
boxplot_metric(
    metric='delta_energy_uj',
    ylabel='Delta Energy (uJ)',
    title='Distribution of Instantaneous Energy Consumption by Server',
    filename='boxplot_delta_energy_uj.png'
)

# 6. BOXPLOT RAM USAGE (RAW)
boxplot_metric(
    metric='ram_usage_MB',
    ylabel='RAM Usage (MB)',
    title='Distribution of RAM Usage by Server',
    filename='boxplot_ram_usage_MB.png'
)

print("✅ Grafici generati con normalizzazione locale e globale.")
