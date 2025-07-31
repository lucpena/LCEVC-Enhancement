#!/bin/bash

source ./config.sh

QP="$1"
if [[ -z "$QP" ]]; then
    ecao "Erro: QP nao fornecido!"
    exit 1
fi

BaseEnconderUpper=$(echo "$BaseEncoder" | tr '[:lower:]' '[:upper:]') 
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
STATUS_FILE="$SCRIPT_DIR/status-${QP}.log"
ENC_DIR="/mnt/md0/lucpena/output/main/output"

rm -f "$STATUS_FILE"
echo -e "Iniciando o script VVC Only\n\n" >> "$STATUS_FILE"

SizesFileVVC="$SCRIPT_DIR/${VIDEO_NAME}-${BaseEnconderUpper}-only.csv"

# Checa se o CSV ja existe, se nao, cria com o cabecalho
if [ ! -f "$SizesFileVVC" ]; then
    echo "file,sw2,qp,lvc_size,base_size,enhance_size,enhancement_ratio,psnr_avg,bitrate_kbps" > "$SizesFileVVC"
fi

VVC_Encoder="/home/lucpena/apps/LTM/_build_linux/external_codecs/VTM/EncoderApp"
FFMPEG="/home/lucpena/apps/FFMPEG-VMAF/ffmpeg"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OutputFile="$ENC_DIR/${VIDEO_NAME}_${BaseEnconderUpper}-Only_QP${QP}.bin"
OutputFileName="${OutputFile##*/}"
OutputYUVFile="${OutputFile%.bin}.yuv"
LogFile="$SCRIPT_DIR/${VIDEO_NAME}_${BaseEnconderUpper}-Only_QP${QP}.log"

CONFIG="/home/lucpena/apps/LTM/_build_linux/external_codecs/VTM/vtm_encoder_randomaccess.cfg"

echo -e "\n=== Codificando somente VVC QP=${QP} ===\n" | tee -a "$STATUS_FILE"
echo "> Codificando com QP=$QP" >> "$STATUS_FILE"

# Codificando para VVC
$VVC_Encoder -c "$CONFIG" --InputFile=${InputFile} ---BitstreamFile=${OutputFile} --ReconFile="recon.yuv" --SourceWidth=${WIDTH} --SourceHeight=${HEIGHT} --InputBitDepth=8 --OutputBitDepth=8 --InternalBitDepth=8 --FrameRate=${FPS} --QP=${QP} --FramesToBeEncoded=${NUM_FRAMES} --ConformanceWindowMode=1 --InputChromaFormat=420


# Decodificando o VVC para YUV
VVC_Decoder="/home/lucpena/apps/LTM/_build_linux/external_codecs/VTM/DecoderApp"
FinalFile="${OutputFile%.bin}-recon.yuv"

${VVC_Decoder} -b ${OutputFile} -o ${OutputYUVFile} >> "$STATUS_FILE"

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
echo "${OutputFileName},265,${QP},${output_file_size},0,0,0%,${psnr_avg},${bitrate_kbps}" >> "$SizesFileVVC"
echo "${OutputFileName},265,${QP},${output_file_size},0,0,0%,${psnr_avg},${bitrate_kbps}" >> "$SizesFile"

echo " QP=$QP | PSNR=${psnr_avg} dB | Bitrate=${bitrate_kbps} kbps" >> "$STATUS_FILE"


echo -e "\n\n VVC Only com QP${QP} finalizado!" | tee -a "$STATUS_FILE"
