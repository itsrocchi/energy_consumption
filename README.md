# energy_consumption

University project to check energy consumption of different webservers on the same application.

## Overview

This repository contains resources and scripts used to benchmark and analyze the energy consumption of deploying the same Java EE application ("Daytrader EE7") on different webservers, specifically WildFly (versions 25 and 26) and Open Liberty (versions 23 and 25). The results are presented with automatically generated reports and graphs.

## Features

- **Automated benchmarking pipeline (`automation.sh` & `automation_with_sampling.sh`):**
  - Deploys and benchmarks the application on multiple Java EE servers.
  - Uses Apache JMeter for load testing.
  - Collects energy usage statistics from Intel RAPL interface and system RAM usage.
  - Aggregates logs and generates summary reports.
    
## Directory Structure

```
automation.sh                  # Main automation script for running the benchmark
automation_with_sampling.sh    # Extended automation with energy/RAM sampling
plotter.py                     # Script (run within a Python venv) to plot graphs from CSV data
reports/                       # Contains generated reports
LICENSE                        # Apache License 2.0
README.md                      # This file
```

## How It Works

1. **Setup & Dependencies:**
   - Requires Java (for WildFly/Open Liberty and Maven), Apache JMeter, Python 3 (for plotting), and access to Intel RAPL (for energy stats).
   - `automation.sh` handles downloading/unpacking application servers, configuring deployment, running JMeter tests, and collecting energy logs.
   - `automation_with_sampling.sh` launches the benchmark and samples energy and memory at regular intervals, saving results to CSV.
   - To correctly plot the results with the `plotter.py` script, python3 with pandas and matplotlib is required, you can install those libraries by running `pip install matplotlib pandas`

2. **Running the Benchmark:**

   ```sh
   sudo bash automation_with_sampling.sh
   ```

   - You need `sudo` to access energy metrics from `/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj`.
   - When prompted, ensure all paths (JMeter, Java, etc.) are set correctly in the scripts.

3. **Generating Reports:**
   - After the script completes, open the files in `reports/` to explore performance/energy results.
   - Use the generated graphs for analysis and comparison.

## Example Usage

- First you have to clone the repo and access the directory
  ```sh
  git clone https://github.com/itsrocchi/energy_consumption.git
  cd energy_consumption
  ```

- To run a full test and generate plots (ensure dependencies are installed and paths in scripts are correct):

  ```sh
  sudo bash automation_with_sampling.sh
  # Results and plots will be saved in reports/
  ```

- To manually plot results (if you have new CSV data):

  ```sh
  python3 plotter.py
  deactivate
  ```

## Dependencies

- **Java** (OpenJDK 8 recommended)
- **Apache Maven**
- **WildFly** (tested 25 & 26), **Open Liberty** (tested 23 & 25)
- **Apache JMeter** 5.6.3 (path set in the `automation.sh` script)
- **Python 3** (with `matplotlib`, `pandas` for plotting)
- **Intel RAPL** interface enabled on your hardware

## License

This project is licensed under the [Apache License 2.0](LICENSE).

---
**Note:** This project is intended for educational and benchmarking purposes only. Hardware and environment-specific factors can affect results; always interpret energy measurements with care.
