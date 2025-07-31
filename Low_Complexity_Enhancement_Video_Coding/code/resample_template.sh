#!/bin/bash

source ./config.sh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
STATUS_FILE="$SCRIPT_DIR/status.log"

ModelEncoder="/home/lucpena/apps/LTM/_build_linux/ModelEncoder"

rm $STATUS_FILE
echo -e "Iniciando Down+Up Sampling...\n" > "$STATUS_FILE"

SizesFileResample="$SCRIPT_DIR/${VIDEO_NAME}-Resample-Only.csv"

# Checa se o CSV ja existe, se nao, cria com o cabecalho
if [ ! -f "$SizesFileResample" ]; then
    echo "file,sw2,qp,lvc_size,base_size,enhance_size,enhancement_ratio,psnr_avg,bitrate_kbps" > "$SizesFileResample"
fi

FFMPEG="/home/lucpena/apps/FFMPEG-VMAF/ffmpeg"

Downsampled="$SCRIPT_DIR/${VIDEO_NAME}_downsampled.yuv"
Upsampled="$SCRIPT_DIR/${VIDEO_NAME}_upsampled.yuv"

echo -e "\nDownsampling...\n" | tee -a "$STATUS_FILE"
${ModelEncoder} --downsample_only=true --format=${FORMAT} -w ${WIDTH} -h ${HEIGHT} \
        -i ${InputFile} -o ${Downsampled} >> "$STATUS_FILE"

echo -e "\nUpsampling...\n" | tee -a "$STATUS_FILE"
${ModelEncoder} --upsample_only=true --format=${FORMAT} -w ${WIDTH} -h ${HEIGHT} \
        -i ${Downsampled} -o ${Upsampled} >> "$STATUS_FILE"

echo -e "\nCalculando PSNR...\n" | tee -a "$STATUS_FILE"
$FFMPEG -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "$FORMAT" -i "$InputFile" \
        -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "$FORMAT" -i "$Upsampled" \
        -lavfi psnr="stats_file=psnr.log" -f null - >> "$STATUS_FILE"

psnr_avg=$(tail -n 1 psnr.log | awk -F'psnr_avg:' '{print $2}' | awk '{print $1}')
rm psnr.log >> "$STATUS_FILE"

output_file_size=$(stat -c%s "$Upsampled")
bitrate_kbps=$(awk "BEGIN { printf \"%.2f\", ($output_file_size * 8 * $FPS) / ($NUM_FRAMES * 1000) }")

# Salva no CSV principal e no local
echo "${VIDEO_NAME}-Resample,0,0,${output_file_size},0,0,0%,${psnr_avg},0" >> "$SizesFile"
echo "${VIDEO_NAME}-Resample,0,0,${output_file_size},0,0,0%,${psnr_avg},0" >> "$SizesFileResample"

[[ -z "$psnr_avg" ]] && psnr_avg="N/A"
echo " Down-Up Sampling → PSNR=${psnr_avg} dB" >> "$STATUS_FILE"

echo -e "\n\n Downsampling + Upsampling finalizado!" | tee -a "$STATUS_FILE"

rm $SCRIPT_DIR/*.yuv