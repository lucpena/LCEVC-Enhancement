#!/bin/bash

source ./config.sh

QP="$1"
if [[ -z "$QP" ]]; then
    echo "Erro: QP nao fornecido!"
    exit 1
fi

BaseEnconderUpper=$(echo "$BaseEncoder" | tr '[:lower:]' '[:upper:]') 
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
STATUS_FILE="$SCRIPT_DIR/status-${QP}.log"
ENC_DIR="/mnt/md0/lucpena/output/main/output"

rm -f "$STATUS_FILE"
echo -e "Iniciando o script AVC Only\n\n" >> "$STATUS_FILE"

SizesFileAVC="$SCRIPT_DIR/${VIDEO_NAME}-${BaseEnconderUpper}-only.csv"

# Checa se o CSV ja existe, se nao, cria com o cabecalho
if [ ! -f "$SizesFileAVC" ]; then
    echo "file,sw2,qp,lvc_size,base_size,enhance_size,enhancement_ratio,psnr_avg,bitrate_kbps" > "$SizesFileAVC"
fi

JMEncoder="/home/lucpena/apps/LTM/_build_linux/external_codecs/JM/lencod"
FFMPEG="/home/lucpena/apps/FFMPEG-VMAF/ffmpeg"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OutputFile="$ENC_DIR/${VIDEO_NAME}_${BaseEnconderUpper}-Only_QP${QP}.264"
OutputFileName="${OutputFile##*/}"
OutputYUVFile="${OutputFile%.264}.yuv"
LogFile="$SCRIPT_DIR/${VIDEO_NAME}_${BaseEnconderUpper}-Only_QP${QP}.log"
CONFIG="/mnt/md0/lucpena/output/main/all/avc_only/encoder.cfg"

echo -e "\n=== Codificando somente AVC QP=${QP} ===\n" | tee -a "$STATUS_FILE"
echo "> Codificando com QP=$QP" >> "$STATUS_FILE"

# Codificando para AVC
${JMEncoder} -d "$CONFIG" -p InputFile="$InputFile" -p OutputFile="$OutputFile" -p SourceWidth=$WIDTH -p SourceHeight=$HEIGHT -p FrameRate=$FPS -p FramesToBeEncoded=$NUM_FRAMES -p YUVFormat=1 -p QPISlice=$QP -p QPPSlice=$((QP + 1)) -p QPBSlice=$((QP + 1)) -p IntraPeriod=64 2>&1 | tee "$LogFile"

# Convertendo o arquivo de saida para YUV para o PSNR
$FFMPEG -i "$OutputFile" -pix_fmt "$FORMAT" -f rawvideo "$OutputYUVFile" -y >> "$STATUS_FILE"

# Calculando PSNR
$FFMPEG -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "$FORMAT" -i "$InputFile" \
        -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "$FORMAT" -i "$OutputYUVFile" \
        -lavfi psnr="stats_file=psnr.log" -f null - >> "$STATUS_FILE"

psnr_avg=$(tail -n 1 psnr.log | awk -F'psnr_avg:' '{print $2}' | awk '{print $1}')
rm psnr.log >> "$STATUS_FILE"

output_file_size=$(stat -c%s "$OutputFile")
bitrate_kbps=$(awk "BEGIN { printf \"%.2f\", ($output_file_size * 8 * $FPS) / ($NUM_FRAMES * 1000) }")

[[ -z "$psnr_avg" ]] && psnr_avg="N/A"

# Salva no CSV principal e no local
echo "${OutputFileName},264,${QP},${output_file_size},0,0,0%,${psnr_avg},${bitrate_kbps}" >> "$SizesFileAVC"
echo "${OutputFileName},264,${QP},${output_file_size},0,0,0%,${psnr_avg},${bitrate_kbps}" >> "$SizesFile"

echo "QP=$QP | PSNR=${psnr_avg} dB | Bitrate=${bitrate_kbps} kbps" >> "$STATUS_FILE"


echo -e "\n\n AVC Only finalizado!" | tee -a "$STATUS_FILE"
