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

# === PLOT ENERGY ===
plt.figure(figsize=(12, 6))
plt.plot(df['timestamp_ms'], df['energy_uj'], label='Energy (uJ)')
plt.xlabel('Timestamp (ms)')
plt.ylabel('Energy (uJ)')
plt.title('Total Energy Consumption Over Time')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'energy_plot.png'))
plt.close()

# === PLOT DELTA ENERGY ===
plt.figure(figsize=(12, 6))
plt.plot(df['timestamp_ms'], df['delta_energy_uj'], label='Delta Energy (uJ per interval)')
plt.xlabel('Timestamp (ms)')
plt.ylabel('Delta Energy (uJ)')
plt.title('Instantaneous Energy Consumption')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'delta_energy_plot.png'))
plt.close()

# === PLOT RAM USAGE ===
plt.figure(figsize=(12, 6))
plt.plot(df['timestamp_ms'], df['ram_usage_MB'], label='RAM Usage (MB)', color='green')
plt.xlabel('Timestamp (ms)')
plt.ylabel('RAM Usage (MB)')
plt.title('RAM Usage Over Time')
plt.legend()
plt.grid(True)
plt.savefig(os.path.join(RESULTS_DIR, 'ram_usage_plot.png'))
plt.close()

print("Plot salvati come energy_plot.png, delta_energy_plot.png e ram_usage_plot.png nella cartella ./results")
