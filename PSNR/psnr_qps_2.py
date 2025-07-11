import os
import pandas as pd
import matplotlib.pyplot as plt
import shutil
from glob import glob

# Parâmetros fixos do vídeo
FPS = 60
TOTAL_FRAMES = 600
DURATION_SEC = TOTAL_FRAMES / FPS

# Diretório onde está o script
current_dir = os.path.dirname(os.path.abspath(__file__))

# Encontra todos os CSVs com 'AllQPs' no nome
csv_files = glob(os.path.join(current_dir, "*.csv"))

# Paleta de cores para QPs
color_palette = ['red', 'green', 'blue', 'purple', 'orange', 'cyan', 'magenta', 'yellow']

for csv_path in csv_files:
    file_name = os.path.basename(csv_path)
    name_no_ext = os.path.splitext(file_name)[0]
    output_folder = os.path.join(current_dir, name_no_ext)
    os.makedirs(output_folder, exist_ok=True)

    # Lê e prepara o DataFrame
    df = pd.read_csv(csv_path)
    df.columns = df.columns.str.strip()

    # Conversões
    df["enhancement_ratio"] = df["enhancement_ratio"].str.replace('%', '').astype(float)
    df["lvc_size_MB"] = df["lvc_size"] / (1024 * 1024)

    # Gera gráfico Bitrate vs PSNR
    plt.figure(figsize=(10, 6))
    qps = sorted(df["qp"].unique())
    colors = {qp: color_palette[i % len(color_palette)] for i, qp in enumerate(qps)}

    # Flags de controle para não duplicar legenda
    avc_plotted = False
    resample_plotted = False
    labels_plotted = set()

    for qp in qps:
        subset = df[df["qp"] == qp]
        for _, row in subset.iterrows():
            is_264 = row["sw2"] == 264
            is_resample = row["sw2"] == 0

            # Escolha do marcador, cor e tamanho
            marker = 'X' if is_264 else ('^' if is_resample else 'o')
            edge_color = 'black'
            face_color = 'none' if is_264 else colors[qp]
            size = 80 if (is_264 or is_resample) else 60

            # Define o texto da legenda
            if is_264 and not avc_plotted:
                label = "AVC Only"
                avc_plotted = True
            elif is_resample and not resample_plotted:
                label = "Resample"
                resample_plotted = True
            elif not is_264 and not is_resample and qp not in labels_plotted:
                label = f"QP {qp}"
                labels_plotted.add(qp)
            else:
                label = None


            plt.scatter(
                row["bitrate_kbps"],
                row["psnr_avg"],
                label=label,
                color=face_color,
                s=size,
                edgecolors=edge_color,
                marker=marker,
                linewidths=1.5
            )

            # Rótulo de texto no ponto
            text_label = ""
            if is_264:
                # text_label = "264"
                text_label += f" QP{row['qp']}" if row["qp"] != 0 else ""
            elif is_resample:
                text_label = "Resample"

            # text_label += f" QP{row['qp']}" if row["qp"] != 0 else ""
            # text_label = ""

            xoffset = -1000
            yoffset = -0.1

            if row["qp"] == 22 and row["sw2"] == 250:
                xoffset = -18000
                yoffset = -0.1

            if is_264:
                xoffset = -3500
            elif is_resample:
                xoffset = 2000

            plt.text(
                row["bitrate_kbps"] + xoffset,
                row["psnr_avg"] + yoffset,
                text_label,
                fontsize=6,
                ha='left',
                va='bottom',
                fontweight='normal'
            )

    # Finaliza e salva o gráfico
    plt.xlabel("Bitrate (kbps)")
    plt.title(f"{name_no_ext} - Bitrate vs PSNR")
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.legend()
    plt.tight_layout()

    graph_path = os.path.join(output_folder, f"{name_no_ext}_bitrate_vs_psnr.png")
    plt.savefig(graph_path, dpi=300)
    plt.close()

print("✨ Todos os gráficos Bitrate × PSNR foram gerados com sucesso! ✨")
