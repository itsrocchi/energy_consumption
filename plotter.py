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

# === GET UNIQUE SERVERS, EXCLUDING 'NOT SET' AND 'UNKNOWN' ===
servers = [s for s in df['server'].unique() if s not in ['NOT SET', 'UNKNOWN']]
num_servers = len(servers)

# === Normalize timestamps per server ===
# === Normalize timestamps per server (tempo relativo)
df['normalized_timestamp'] = df.groupby('server')['timestamp_ms'].transform(lambda x: x - x.min())

# === Global normalization: all values compared on the same scale
df['normalized_delta_energy_uj'] = df['delta_energy_uj'] / df['delta_energy_uj'].max()
df['normalized_ram_usage_MB'] = df['ram_usage_MB'] / df['ram_usage_MB'].max()


# === Normalize delta_energy_uj and ram_usage_MB values per server ===
for metric in ['delta_energy_uj', 'ram_usage_MB']:
    norm_col = f'normalized_{metric}'
    df[norm_col] = df.groupby('server')[metric].transform(
        lambda x: (x - x.min()) / (x.max() - x.min()) if (x.max() - x.min()) > 0 else 0
    )

# === COLORS MAP ===
colors = plt.cm.get_cmap('tab10', len(servers))

# === PLOT TOTAL ENERGY (non normalizzato, grafico unico) ===
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

# === FUNCTION TO PLOT METRIC IN GRID (normalizzato) ===
def plot_normalized_metric_grid(metric, ylabel, title, filename):
    rows = 2
    cols = math.ceil(num_servers / 2)
    fig, axs = plt.subplots(rows, cols, figsize=(14, 8), sharex=False)
    axs = axs.flatten()

    for i, server in enumerate(servers):
        df_server = df[df['server'] == server]
        axs[i].plot(df_server['normalized_timestamp'], df_server[f'normalized_{metric}'],
                    label=server, color='tab:blue')
        axs[i].set_title(server)
        axs[i].set_ylabel(ylabel)
        axs[i].grid(True)
        axs[i].legend()

    for j in range(i + 1, len(axs)):
        axs[j].axis('off')

    fig.suptitle(title)
    for ax in axs:
        ax.set_xlabel('Normalized Timestamp (ms)')
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(os.path.join(RESULTS_DIR, filename))
    plt.close()

# === FUNCTION TO CREATE BOXPLOT (non normalizzato) ===
def boxplot_metric(metric, ylabel, title, filename):
    data = [df[df['server'] == s][metric] for s in servers]
    plt.figure(figsize=(10, 6))
    plt.boxplot(data, labels=servers)
    plt.ylabel(ylabel)
    plt.title(title)
    plt.grid(True)
    plt.savefig(os.path.join(RESULTS_DIR, filename))
    plt.close()

# === PLOT NORMALIZED DELTA ENERGY ===
plot_normalized_metric_grid(
    metric='delta_energy_uj',
    ylabel='Normalized Delta Energy (0-1)',
    title='Normalized Instantaneous Energy Consumption by Server',
    filename='normalized_delta_energy_by_server_grid.png'
)

boxplot_metric(
    metric='delta_energy_uj',
    ylabel='Delta Energy (uJ)',
    title='Distribution of Instantaneous Energy Consumption by Server',
    filename='boxplot_delta_energy_uj.png'
)

# === PLOT NORMALIZED RAM USAGE ===
plot_normalized_metric_grid(
    metric='ram_usage_MB',
    ylabel='Normalized RAM Usage (0-1)',
    title='Normalized RAM Usage Over Time by Server',
    filename='normalized_ram_usage_by_server_grid.png'
)

boxplot_metric(
    metric='ram_usage_MB',
    ylabel='RAM Usage (MB)',
    title='Distribution of RAM Usage by Server',
    filename='boxplot_ram_usage_MB.png'
)

print("Grafici aggiornati con normalizzazione del tempo e dei valori per confronto visivo.")
