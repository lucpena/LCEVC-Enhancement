import os
import pandas as pd
import matplotlib.pyplot as plt
import shutil
from glob import glob

# Diretório atual (onde o script está)
current_dir = os.path.dirname(os.path.abspath(__file__))

# Procura todos os arquivos CSV com 'AllQPs' no nome
csv_files = glob(os.path.join(current_dir, "*AllQPs*.csv"))

# Paleta de cores para QPs
color_palette = ['red', 'green', 'blue', 'purple', 'orange', 'cyan', 'magenta']

for csv_path in csv_files:
    # Nome do arquivo sem extensão
    file_name = os.path.basename(csv_path)
    name_no_ext = os.path.splitext(file_name)[0]
    
    # Cria pasta com nome do arquivo
    output_folder = os.path.join(current_dir, name_no_ext)
    os.makedirs(output_folder, exist_ok=True)
    
    # Lê o CSV
    df = pd.read_csv(csv_path)
    df.columns = df.columns.str.strip()
    df["enhancement_ratio"] = df["enhancement_ratio"].str.replace('%', '').astype(float)
    df["lvc_size_MB"] = df["lvc_size"] / (1024 * 1024)

    # Gera o gráfico
    plt.figure(figsize=(10, 6))
    qps = sorted(df["qp"].unique())
    colors = {qp: color_palette[i % len(color_palette)] for i, qp in enumerate(qps)}

    for qp in qps:
        subset = df[df["qp"] == qp]
        plt.scatter(
            subset["enhancement_ratio"],
            subset["psnr_avg"],
            label=f"QP {qp}",
            color=colors[qp],
            s=60,
            edgecolors="black"
        )

        flag=1
        for _, row in subset.iterrows():
            label = f"SW2: {row['sw2']} | {row['lvc_size_MB']:.1f}MB"
            xoffset = 1.0
            yoffset = 0.0

            if row["qp"] == 22 and row["sw2"] == 3250:
                xoffset = 0.0
                yoffset = 0.3
            if row["qp"] == 22 and row["sw2"] == 2750:
                xoffset = 0.0
                yoffset = -0.3

            if row["qp"] == 27 and row["sw2"] == 3250:
                xoffset = 0.0
                yoffset = 0.3

            if row["qp"] == 32 and row["sw2"] == 250:
                xoffset = 0.6
                yoffset = 0.15
            if row["qp"] == 32 and row["sw2"] == 750:
                xoffset = 0.8
                yoffset = -0.1
            if row["qp"] == 32 and row["sw2"] == 2250:
                xoffset = -2.2
                yoffset = 0.3

            if row["qp"] == 37 and row["sw2"] == 250:
                xoffset = 0.5
                yoffset = 0.1
            if row["qp"] == 37 and row["sw2"] == 750:
                xoffset = 1.0
                yoffset = -0.1
            if row["qp"] == 37 and row["sw2"] == 1250:
                xoffset = 1.0
                yoffset = -0.2

            plt.text(row["enhancement_ratio"] + xoffset, row["psnr_avg"] + yoffset, label, fontsize=10, va='center', ha='left')

    plt.xlabel("Enhancement Ratio (%)")
    plt.ylabel("PSNR (dB)")
    plt.title(f"{name_no_ext} - Enhancement Ratio vs PSNR")
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.legend()
    plt.tight_layout()

    # Salva o gráfico
    plot_path = os.path.join(output_folder, f"{name_no_ext}_graph.png")
    plt.savefig(plot_path)
    plt.close()

    # Move o CSV para a pasta criada
    # shutil.move(csv_path, os.path.join(output_folder, file_name))

print("\n> Fim da execução.\n")