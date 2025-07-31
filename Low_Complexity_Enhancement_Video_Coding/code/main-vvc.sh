#!/bin/bash

echo -en "\nInicializando Codificacao em VVC... "
for i in {5..1}; do
    sleep 1
    echo -n "${i} "
done
echo -e "\n"

# === Configuracoes compartilhadas ===
# InputFile="/mnt/md0/lucpena/videos/Bosphorus_1920x1080_120fps_420_8bit.yuv"
# InputFile="/mnt/md0/lucpena/videos/SOCCER_352x288_30_orig_02.yuv"
# InputFile="/mnt/md0/lucpena/videos/RaceNight_3840x2160_50fps_8bit.yuv"
# InputFile="/mnt/md0/lucpena/videos/ReadySteadyGo_1920x1080_120fps_420_8bit.yuv"
# InputFile="/mnt/md0/lucpena/videos/Jockey_1920x1080_120fps_420_8bit.yuv"
# InputFile="/mnt/md0/lucpena/videos/city_704x576_yuv420p_60fps_600frames.yuv"
InputFile="/mnt/md0/lucpena/videos/SBTVD/YUV/vc-globo-05_120frames_420p.yuv"

# VIDEO_NAME="Bosphorus"
# VIDEO_NAME="SOCCER"
# VIDEO_NAME="RaceNight"
# VIDEO_NAME="ReadySteadyGo"
# VIDEO_NAME="Jockey"
# VIDEO_NAME="City"
VIDEO_NAME="vc-globo-05_120frames"

# WIDTH=1920
# HEIGHT=1080
# FPS=60
# NUM_FRAMES=600

## Soocer
# WIDTH=352
# HEIGHT=288
# FPS=30
# NUM_FRAMES=300

## City
# WIDTH=704
# HEIGHT=576
# FPS=60
# NUM_FRAMES=600

## vc-globo-05
WIDTH=3840
HEIGHT=2160
FPS=60
NUM_FRAMES=120

SW2=250
SW2_max=3250
FORMAT="yuv420p"

BaseEncoder="vvc"
Step=500

MAIN_TIME=$(date +"%Y-%m-%d_%H-%M-%S")

QP_list=(22 25 27 30 32 35 37) 

ENCODER_SCRIPT="vvc_template.sh"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

BaseEnconderUpper=$(echo "$BaseEncoder" | tr '[:lower:]' '[:upper:]')
SizesFile="$SCRIPT_DIR/${VIDEO_NAME}-${BaseEnconderUpper}-${WIDTH}x${HEIGHT}-${MAIN_TIME}.csv"

# Loop para LCEVC
for QP in "${QP_list[@]}"; do
    DIR="QP${QP}"
    mkdir -p "$DIR"
    cp "$ENCODER_SCRIPT" "$DIR/run.sh"

    # Cria script com todas as variaveis embutidas
    cat > "$DIR/config.sh" <<EOF
#!/bin/bash
MAIN_TIME="$MAIN_TIME"
InputFile="$InputFile"
VIDEO_NAME="$VIDEO_NAME"
WIDTH=$WIDTH
HEIGHT=$HEIGHT
FORMAT="$FORMAT"
FPS=$FPS
NUM_FRAMES=$NUM_FRAMES
SW2=$SW2
SW2_max=$SW2_max
Step=$Step
BaseEncoder="$BaseEncoder"
QP=$QP
BaseEnconderUpper="$BaseEnconderUpper"
SizesFile="$SizesFile"
EOF

    # Cria o SizesFile se nao existir
    if [ ! -f "$SizesFile" ]; then
        echo "file,sw2,qp,lvc_size,base_size,enhance_size,enhancement_ratio,psnr_avg,bitrate_kbps" > "$SizesFile"
    fi

    chmod +x "$DIR/run.sh"
    chmod +x "$DIR/config.sh"

    # Executa em segundo plano
    (cd "$DIR" && ./run.sh) &
    sleep 2
done

# === Script so com VVC ===
VVC_ONLY_DIR="$SCRIPT_DIR/vvc_only"
VVC_TEMPLATE="$SCRIPT_DIR/vvc_only_template.sh"
mkdir -p "$VVC_ONLY_DIR"

for QP in "${QP_list[@]}"; do
    QPDIR="$VVC_ONLY_DIR/QP${QP}"
    mkdir -p "$QPDIR"

    # Copia template e torna executavel
    cp "$VVC_TEMPLATE" "$QPDIR/run.sh"
    chmod +x "$QPDIR/run.sh"

    # Config file
    cat > "$QPDIR/config.sh" <<EOF
#!/bin/bash
MAIN_TIME="$MAIN_TIME"
InputFile="$InputFile"
VIDEO_NAME="$VIDEO_NAME"
WIDTH=$WIDTH
HEIGHT=$HEIGHT
FORMAT="$FORMAT"
FPS=$FPS
NUM_FRAMES=$NUM_FRAMES
BaseEncoder="$BaseEncoder"
QP=$QP
SizesFile="$SizesFile"
EOF
    chmod +x "$QPDIR/config.sh"

    # Dispara em segundo plano
    (cd "$QPDIR" && ./run.sh "$QP") &
    sleep 2
done

# === Script com Down/Up sampling ===
DIR="resample"
mkdir -p "$DIR"
cp "resample_template.sh" "$DIR/run.sh"

cat > "$DIR/config.sh" <<EOF
#!/bin/bash
MAIN_TIME="$MAIN_TIME"
InputFile="$InputFile"
VIDEO_NAME="$VIDEO_NAME"
WIDTH=$WIDTH
HEIGHT=$HEIGHT
FORMAT="$FORMAT"
FPS=$FPS
NUM_FRAMES=$NUM_FRAMES
SizesFile="$SizesFile"
EOF
chmod +x "$DIR/"*.sh

(cd "$DIR" && ./run.sh) &

wait



echo -e "\n---------------------\n Finish \n---------------------\n"
