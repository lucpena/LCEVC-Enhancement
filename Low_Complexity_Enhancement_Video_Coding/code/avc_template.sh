#!/bin/bash
source ./config.sh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

ModelEncoder="/home/lucpena/apps/LTM/_build_linux/ModelEncoder"
ModelDecoder="/home/lucpena/apps/LTM/_build_linux/ModelDecoder"
FFMPEG="/home/lucpena/apps/FFMPEG-VMAF/ffmpeg"

MAIN_DIR="/mnt/md0/lucpena/output/main"
BASES_DIR="$MAIN_DIR/bases"
DEC_DIR="$MAIN_DIR/dec"
LOGS_DIR="$MAIN_DIR/logs"
BIN_DIR="$MAIN_DIR/bin"
RESULTS_DIR="$MAIN_DIR/results"
STATUS_FILE="$SCRIPT_DIR/status.log"

LOCAL_CSV="$SCRIPT_DIR/${VIDEO_NAME}-${BaseEnconderUpper}-QP${QP}.csv"

# Checa se o CSV ja existe, se nao, cria com o cabecalho
if [ ! -f "$LOCAL_CSV" ]; then
    echo "file,sw2,qp,lvc_size,base_size,enhance_size,enhancement_ratio,psnr_avg,bitrate_kbps" > "$LOCAL_CSV"
fi

rm -f "$STATUS_FILE"
echo -e "\n=== Iniciando testes para QP=${QP} ===\n" | tee -a "$STATUS_FILE"

rm -f $SCRIPT_DIR/*.yuv $SCRIPT_DIR/psnr.log 2>> "$STATUS_FILE"

BASE_NAME="${VIDEO_NAME}-QP${QP}-${BaseEnconderUpper}.bin"
if [[ ! -f "${BIN_DIR}/${BASE_NAME}" ]]; then
    echo -e "\nO arquivo ${BASE_NAME} nao existe, criando um novo..." | tee -a "$STATUS_FILE"
    ${ModelEncoder} \
        --width=${WIDTH} --height=${HEIGHT} --format=${FORMAT} --fps=${FPS} --qp=${QP} \
        --input_file="${InputFile}" \
        --output_file="$DEC_DIR/base.lvc" --base_encoder=${BaseEncoder} --encapsulation=nal \
        --cq_step_width_loq_0=${SW2} --keep_base \
        2>&1 | tee -a "$LOGS_DIR/${VIDEO_NAME}_base-gen_QP${QP}_$(date +"%Y-%m-%d_%H-%M-%S").log"

    mv "$SCRIPT_DIR/base.bin" "${BIN_DIR}/${BASE_NAME}"

    echo -e "Base ${BASE_NAME} criada com sucesso." | tee -a "$STATUS_FILE"
else
    echo -e "Base ${BASE_NAME} ja existente, reutilizando." | tee -a "$STATUS_FILE"
fi

for (( current_sw2=SW2; current_sw2<=SW2_max; current_sw2+=Step )); do
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    OutputFile="$DEC_DIR/${VIDEO_NAME}_LCEVC_${BaseEnconderUpper}_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.lvc"
    LogFile="$LOGS_DIR/${VIDEO_NAME}_LCEVC_${BaseEnconderUpper}_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.log"

    echo -e "\n Rodando encode com SW2 = $current_sw2, QP = $QP" | tee -a "$STATUS_FILE"

    ${ModelEncoder} \
        --width=${WIDTH} --height=${HEIGHT} --format=${FORMAT} --fps=${FPS} --qp=${QP} \
        --input_file="${InputFile}" \
        --output_file="${OutputFile}" \
        --base="${BIN_DIR}/${BASE_NAME}" \
        --base_encoder=${BaseEncoder} --encapsulation=nal \
        --cq_step_width_loq_0=${current_sw2} \
        2>&1 | tee -a "${LogFile}"

    DecodedFile="$DEC_DIR/${VIDEO_NAME}_Dec_${BaseEnconderUpper}_LCEVC_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.yuv"
    DecodedLog="$LOGS_DIR/${VIDEO_NAME}_Dec_LCEVC_${BaseEnconderUpper}_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.log"

    ${ModelDecoder} \
        --base_encoder=${BaseEncoder} --fps=${FPS} \
        --input_file="${OutputFile}" \
        --output_file="${DecodedFile}" \
        --keep_base=true \
        2>&1 | tee -a "${DecodedLog}"

    base_file=$(find $SCRIPT_DIR -maxdepth 1 -type f -name "*base.es" | head -n 1)
    enhance_file=$(find $SCRIPT_DIR -maxdepth 1 -type f -name "*enhancement.es" | head -n 1)

    if [[ -f "$base_file" ]]; then
        base_size=$(stat -c%s "$base_file")
        # mv "$base_file" "$BASES_DIR/${VIDEO_NAME}_Base_LCEVC_${BaseEnconderUpper}_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.es"
        rm "$base_file"
    else
        base_size=0
        echo "base.es nao encontrado!" | tee -a "$STATUS_FILE"
    fi

    if [[ -f "$enhance_file" ]]; then
        enhance_size=$(stat -c%s "$enhance_file")
        # mv "$enhance_file" "$BASES_DIR/${VIDEO_NAME}_Enha_LCEVC_${BaseEnconderUpper}_SW2-${current_sw2}_QP${QP}_${TIMESTAMP}.es"
        rm "$enhance_file"
    else
        enhance_size=0
        echo "enhancement.es nao encontrado!" | tee -a "$STATUS_FILE"
    fi

    output_file_size=$(stat -c%s "$OutputFile")
    if (( output_file_size > 0 )); then
        enhancement_ratio=$(awk "BEGIN { printf \"%.4f\", $enhance_size / $output_file_size * 100 }")
        bitrate_kbps=$(awk "BEGIN { printf \"%.2f\", ($output_file_size * 8 * $FPS) / ($NUM_FRAMES * 1000) }")
    else
        enhancement_ratio=0
        bitrate_kbps=0
    fi

    echo -e "\n\t Calculando PSNR..." | tee -a "$STATUS_FILE"
    $FFMPEG \
        -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "${FORMAT}" -i "${InputFile}" \
        -s:v "${WIDTH}x${HEIGHT}" -pix_fmt "${FORMAT}" -i "${DecodedFile}" \
        -lavfi psnr="stats_file=${SCRIPT_DIR}/psnr.log" -f null - 2> /dev/null

    psnr_avg=$(tail -n 1 ${SCRIPT_DIR}/psnr.log | awk -F'psnr_avg:' '{print $2}' | awk '{print $1}')
    rm -f ${SCRIPT_DIR}/psnr.log >> "$STATUS_FILE"

    if [[ -z "$psnr_avg" ]]; then
        psnr_avg="N/A"
    fi

    FileName="${OutputFile##*/}"
    echo "${FileName},${current_sw2},${QP},${output_file_size},${base_size},${enhance_size},${enhancement_ratio}%,${psnr_avg},${bitrate_kbps}" | tee -a "$STATUS_FILE" >> "$SizesFile"
    echo "${FileName},${current_sw2},${QP},${output_file_size},${base_size},${enhance_size},${enhancement_ratio}%,${psnr_avg},${bitrate_kbps}" >> "$LOCAL_CSV"

    echo -e "\n\t SW2=${current_sw2} → enhancement_ratio=${enhancement_ratio}% | psnr_avg=${psnr_avg} dB | bitrate=${bitrate_kbps} kbps\n" | tee -a "$STATUS_FILE"

    rm -f $SCRIPT_DIR/*temp* 2>> "$STATUS_FILE"
done

echo -e "\n Script para QP=${QP} finalizado com sucesso!" | tee -a "$STATUS_FILE"
