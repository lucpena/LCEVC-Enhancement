./ffmpeg -i "mnt/md0/lucpena/videos/vc-globo-05.mov" -c:v libx265 -preset slow -crf 18 -pix_fmt yuv422p10le -x265-params "hdr-opt=1:repeat-headers=1" \
-color_primaries bt2020 -colorspace bt2020nc -color_trc smpte2084 \
-master_display "G(17000,79700)B(13100,4600)R(70800,29200)WP(3127,3290)L(10000000,1)" \
-max_cll 1000,400 \
"mnt/md0/lucpena/videos/vc-globo-05-h265.mkv"

./ffmpeg -i "/mnt/md0/lucpena/videos/vc-globo-05.mov" -c:v libx265 -preset slow -crf 18 -pix_fmt yuv422p10le \
-x265-params "hdr-opt=1:repeat-headers=1:master-display=G(17000,79700)B(13100,4600)R(70800,29200)WP(3127,3290)L(10000000,1):max-cll=1000,400" \
-color_primaries bt2020 -colorspace bt2020nc -color_trc smpte2084 \
"/mnt/md0/lucpena/videos/vc-globo-05-h265.mkv" -y

./ffmpeg -i "/mnt/md0/lucpena/videos/vc-globo-05.mov" -c:v libx265 -preset slow -crf 18 -pix_fmt yuv422p10le -x265-params "hdr-opt=1:repeat-headers=1" -color_primaries bt2020 -colorspace bt2020nc -color_trc smpte2084 -master_display "G(17000,79700)B(13100,4600)R(70800,29200)WP(3127,3290)L(10000000,1)" -max_cll 1000,400 "mnt/md0/lucpena/videos/vc-globo-05-h265.mkv"

./ffmpeg -i "/mnt/md0/lucpena/videos/vc-globo-05.mov" -vf "scale=1920:1080" -c:v rawvideo -pix_fmt yuv422p10le -r 59.94 "/mnt/md0/lucpena/videos/test_1080p_output.yuv"

######################################################
# ModelEncoder

./ModelEncoder -i "/mnt/md0/lucpena/videos/vc-globo-05-h265.mkv" -w 3840 -h 2160 -r 60 -f yuv420p10le -b hevc -o "/mnt/md0/lucpena/output/vc-globo-05-h265-output.lvc"

./ModelEncoder --width=3840 --height=2160 --format=yuv420p10 \
 --input_file="/mnt/md0/lucpena/videos/vc-globo-05_422_10bit.yuv" --output_file="/mnt/md0/lucpena/output/vc-globo-05-h265-output.lvc" \
 --output_recon="/mnt/md0/lucpena/output/vc-globo-05-h265-output-recon.yuv" --base_encoder=hevc --encapsulation=nal \
 --base="/mnt/md0/lucpena/videos/vc-globo-05-base.hevc" --base_recon="/mnt/md0/lucpena/videos/vc-globo-05-base-recon.yuv" --limit=500 \
 --cq_step_width_loq_1=32767 --cq_step_width_loq_0=1000

 ./ModelEncoder --width=3840 --height=2160 --format=yuv420p10 --fps=59.94 \
 --input_file="/mnt/md0/lucpena/videos/vc-globo-05_422_10bit.yuv" \
 --output_file="/mnt/md0/lucpena/output/vc-globo-05-h265-output.lvc"

 ./ModelEncoder --width=1920 --height=1080 --format=yuv420p10 --fps=60 \
 --input_file="/mnt/md0/lucpena/videos/test_1080p_output.yuv" \
 --output_file="/mnt/md0/lucpena/output/vc-globo-05-h265-output.lvc" 2>&1 \
 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' \
 | tee "/mnt/md0/lucpena/output/test_1080p_output.log"
 
  ./ModelEncoder --width=1920 --height=1080 --format=yuv420p --fps=120 \
 --input_file="/mnt/md0/lucpena/videos/Bosphorus_1920x1080_120fps_420_8bit_YUV.yuv" \
 --output_file="/mnt/md0/lucpena/output/Bosphorus.lvc" 2>&1 \
 | awk '{ print strftime("[%Y-%m-%d %H:%M:%S]"), $0; fflush(); }' \
 | tee "/mnt/md0/lucpena/docs/Bosphorus_output.log"

 rsync -avhP ~/Videos/videozasso.mp4 unb:/home/lucpena/videos/