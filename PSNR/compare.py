import os
import re
import pandas as pd
import matplotlib.pyplot as plt

# Lista todas as pastas do diretório atual
all_dirs = [d for d in os.listdir() if os.path.isdir(d)]

# Dicionário para agrupar: { (nome, QP): {AVC: path, VVC: path} }
grouped_dirs = {}

# Agrupa diretórios com base no padrão <nome>-QP<valor>-<codec>
for d in all_dirs:
    match = re.match(r'(\w+)-QP(\d+)-(AVC|VVC)', d)
    if match:
        name, qp, codec = match.groups()
        key = (name, qp)
        if key not in grouped_dirs:
            grouped_dirs[key] = {}
        grouped_dirs[key][codec] = d

# Processa cada grupo com AVC e VVC disponíveis
for (name, qp), codecs in grouped_dirs.items():
    if "AVC" in codecs and "VVC" in codecs:
        data = {}

        for codec in ["AVC", "VVC"]:
            folder = codecs[codec]
            csv_files = [f for f in os.listdir(folder) if f.endswith('.csv')]

            if not csv_files:
                continue

            csv_path = os.path.join(folder, csv_files[0])
            df = pd.read_csv(csv_path, skipinitialspace=True)

            df['psnr_avg'] = pd.to_numeric(df['psnr_avg'], errors='coerce')
            df['enhancement_ratio'] = df['enhancement_ratio'].str.replace('%', '', regex=False).str.replace(',', '.', regex=False).astype(float)
            df = df.sort_values(by='sw2', ascending=False)

            data[codec] = df

        # === Gráfico 1: SW2 vs PSNR ===
        plt.figure(figsize=(10, 6))
        for codec, df in data.items():
            plt.plot(df['sw2'], df['psnr_avg'], marker='o', label=codec)
        plt.xlabel('SW2')
        plt.ylabel('PSNR (dB)')
        plt.title(f'SW2 x PSNR - {name} QP{qp}')
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.savefig(f'{name}_QP{qp}_sw2_vs_psnr.png')
        plt.close()

        # === Gráfico 2: Enhancement Ratio vs PSNR ===
        plt.figure(figsize=(10, 6))
        for codec, df in data.items():
            plt.plot(df['enhancement_ratio'], df['psnr_avg'], marker='s', label=codec)
        plt.xlabel('Enhancement Ratio (%)')
        plt.ylabel('PSNR (dB)')
        plt.title(f'Enhancement Ratio x PSNR - {name} QP{qp}')
        plt.grid(True)
        plt.legend()
        plt.tight_layout()
        plt.savefig(f'{name}_QP{qp}_ratio_vs_psnr.png')
        plt.close()

print("\nFim da execução.\n")
