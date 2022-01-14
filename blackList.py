import re
import os
import threading
import time

ips = list()

def readLogs(path):
    f = open(path,"r")
    logs = f.readlines()
    f.close()
    return logs

def checklogs(logs):
    fails = list()
    for i in logs:
        if (i[-9:-2]=="preauth"):
            fails.append(i)
    return fails

def getIP(fails):
    for i in fails:
        ip = re.search('[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*',i)
        if ip != None:
            if ip not in ips:
                ips.append(ip.group())

def ufw(ip):
    os.system("sudo ufw insert 1 deny from " + ip + " to any comment blackList.py > /dev/null 2>&1")

def changeLog():
    os.system("cat /var/log/sshd/sshd.log >> /var/log/sshd/sshdR.log")
    os.system("echo '' > /var/log/sshd/sshd.log")

def ban():
    threads = list()
    path ="/var/log/sshd/banedIP.txt"
    f = open(path,"a")
    for ip in ips:
        threads.append(threading.Thread(target=ufw, args=(ip,)))
        f.write(ip+"\n")
    f.close()
    for i in threads:
        i.start()
        time.sleep(0.01)
    f.close()

if __name__ == "__main__":
    file = "/var/log/sshd/sshd.log"
    logs = readLogs(file)

    fails = checklogs(logs)
    getIP(fails)
    
    if len(ips) >0:
        ban()
        changeLog()
