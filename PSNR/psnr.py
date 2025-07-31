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
color_palette = ['green', 'blue', 'purple', 'orange', 'cyan', 'magenta', 'yellow']

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
            is_reference = row["sw2"] in [264, 265]  # AVC (264) ou VVC (265)
            is_resample = row["sw2"] == 0

            # Escolha do marcador, cor e tamanho
            marker = 'X' if is_reference else ('^' if is_resample else 'o')
            edge_color = "black" if is_reference else 'black'
            face_color = 'red' if is_reference else colors[qp]
            size = 80 if (is_reference or is_resample) else 60

            # Define o texto da legenda
            if is_reference:
                codec_name = "AVC" if row["sw2"] == 264 else "VVC"
                label = f"{codec_name} Only" if f"{codec_name} Only" not in labels_plotted else None
                labels_plotted.add(f"{codec_name} Only")
            elif is_resample:
                label = "Resample" if not resample_plotted else None
                resample_plotted = True
            elif qp not in labels_plotted:
                label = f"QP {qp}"
                labels_plotted.add(qp)
            else:
                label = None

            # Scatter point
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
            if is_reference:
                codec_short = "264" if row["sw2"] == 264 else "265"
                text_label = f" QP{row['qp']}" if row["qp"] != 0 else ""
            elif is_resample:
                text_label = ""

            xoffset = 0
            yoffset = 0

            if row["sw2"] != 264 and row["sw2"] != 265:
                if row["qp"] == 37:
                    text_label += f" SW2={row['sw2']}"
                    xoffset = 100
                    yoffset = -0.15
                pass

            if is_reference:
                xoffset = -1400
                yoffset = 0
            elif is_resample:
                xoffset = 0
                yoffset = 0

            # if row["qp"] == 35:
            #     xoffset += -200
            #     yoffset += -0.2
            
            # if row["sw2"] == 1250:
            #     xoffset += 0
            #     yoffset -= 0.15
            
            if row["sw2"] == 3250:
                xoffset -= 0
                yoffset -= 0.35

            if row["sw2"] == 2750:
                xoffset -= 0
                yoffset -= 0.3

            if row["sw2"] == 1750:
                xoffset -= 0
                yoffset -= -0.1

            if row["sw2"] == 2250:
                xoffset -= 0
                yoffset -= 0.2

            # if row["sw2"] == 250:
            #     xoffset -= 0
            #     yoffset -= 0.15

            if row["sw2"] == 750:
                xoffset -= 2600
                yoffset -= 0.4

            plt.text(
                row["bitrate_kbps"] + xoffset,
                row["psnr_avg"] + yoffset,
                text_label,
                fontsize=12,
                ha='left',
                va='bottom',
                fontweight='normal'
            )

    # 🔗 Conecta todos os pontos 'X' (AVC/VVC) em ordem de bitrate
    ref_points = df[df["sw2"].isin([264, 265])].sort_values(by="bitrate_kbps")
    if len(ref_points) > 1:
        plt.plot(
            ref_points["bitrate_kbps"],
            ref_points["psnr_avg"],
            color='red',
            linestyle='-',
            linewidth=2,
            alpha=0.8,
            label=None  # evita duplicar na legenda
        )

    # Finaliza e salva o gráfico
    plt.xlabel("Bitrate (kbps)")
    plt.ylabel("PSNR (dB)")
    plt.title(f"{name_no_ext} - Bitrate vs PSNR")
    plt.grid(True, linestyle='--', alpha=0.5)
    plt.legend()
    plt.tight_layout()

    graph_path = os.path.join(output_folder, f"{name_no_ext}.png")
    plt.savefig(graph_path, dpi=300)
    plt.close()

print("✨ Todos os gráficos Bitrate × PSNR foram gerados com sucesso! ✨")
