import pandas as pd
import matplotlib.pyplot as plt
import os
import glob
import shutil

# Pega todos os arquivos .csv no diretório atual
csv_files = glob.glob("*.csv")

# Processa cada CSV individualmente
for csv_file in csv_files:

    # Nome base da pasta (sem .csv)
    base_name = os.path.splitext(csv_file)[0]
    output_dir = os.path.join(os.getcwd(), base_name)

    # Cria a pasta se não existir
    os.makedirs(output_dir, exist_ok=True)

    # Lê os dados do CSV
    df = pd.read_csv(csv_file)

    # Converte colunas necessárias
    df['psnr_avg'] = pd.to_numeric(df['psnr_avg'], errors='coerce')
    df['enhancement_ratio'] = df['enhancement_ratio'].str.replace('%', '').astype(float)
    df = df.sort_values(by='SW2', ascending=False)

    # === Gráfico 1: SW2 vs PSNR ===
    plt.figure(figsize=(10, 6))
    plt.plot(df['SW2'], df['psnr_avg'], marker='o', color='blue')
    plt.xlabel('SW2')
    plt.ylabel('PSNR (dB)')
    plt.title(f'SW2 x PSNR - {base_name}')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'sw2_vs_psnr.png'))
    plt.close()

    # === Gráfico 2: Enhancement Ratio vs PSNR ===
    plt.figure(figsize=(10, 6))
    plt.plot(df['enhancement_ratio'], df['psnr_avg'], marker='s', color='green')
    plt.xlabel('Enhancement Ratio (%)')
    plt.ylabel('PSNR (dB)')
    plt.title(f'Enhancement Ratio x PSNR - {base_name}')
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'ratio_vs_psnr.png'))
    plt.close()

    # Move o CSV para a pasta criada
    shutil.move(csv_file, os.path.join(output_dir, csv_file))

print("✨ Terminei! Todos os gráficos foram salvos nas suas pastinhas fofinhas! 💾📊")
