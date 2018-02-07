#!/bin/bash
groupadd -g 8000 users2
useradd -m -g 8000 -u 12807 -s /bin/bash pred
apt-get remove -y docker docker-engine docker.io
apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg2 \
	software-properties-common
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y nfs-common docker-ce
usermod -aG docker pred
echo "nfs:/export/home/ehamelin    /home/pred       nfs     rw,nfsvers=3,hard,intr,async,noatime,nodev,nosuid,auto,rsize=32768,wsize=32768  0       0" >> /etc/fstab
