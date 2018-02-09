#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
	-l|--locality)
	    LOCALITY="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-n|--node)
	    NODE="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-h|--help)
	    echo "Usage: ./pred.sh -l|--locality g5jlocality -n|--node localitydefaultqueuenode"
	    exit
	    ;;
	*)   # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# On réserve un operator puis on le prépare
kadeploy3 -f $OAR_NODE_FILE -e debian9-x64-base -k
echo "
#!/bin/bash
groupadd -g 8000 users2
useradd -m -g 8000 -u "$(id -u)" -s /bin/bash "$USER"
apt-get remove -y docker docker-engine docker.io
apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
	gnupg2 \
	software-properties-common
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo \"$ID\")/gpg | sudo apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository \
   \"deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo \"$ID\") \
   \$(lsb_release -cs) \
   stable\"
apt-get update
apt-get install -y nfs-common docker-ce virtualenv python-dev jq
usermod -aG docker "$USER"
echo \"nfs:/export/home/"$USER"    /home/"$USER"       nfs     rw,nfsvers=3,hard,intr,async,noatime,nodev,nosuid,auto,rsize=32768,wsize=32768  0       0\" >> /etc/fstab
mount -a
" > operator.sh
chmod +x operator.sh
rsync -avz --progress operator.sh root@$(cat $OAR_NODE_FILE | head -n 1):~/
ssh root@$(cat $OAR_NODE_FILE | head -n 1) -C "./operator.sh"
rm -rf venv
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && virtualenv venv && source venv/bin/activate && pip install -U pip && pip install enos"

# On lance les benchmarks

## Topology simple

### Backend local
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && ./benchmark.sh -b local -t simple -l $LOCALITY -n $NODE -m 1"

## Swift
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && ./benchmark.sh -b swift -t simple -l $LOCALITY -n $NODE -m 1"

## Topology edge

### Backend local
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && ./benchmark.sh -b local -t edge -l $LOCALITY -n $NODE -m 1"

## Swift
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && ./benchmark.sh -b swift -t edge -l $LOCALITY -n $NODE -m 1"

## Ceph
ssh $USER@$(cat $OAR_NODE_FILE | head -n 1) -C "cd pred && ./benchmark.sh -b ceph -t edge -l $LOCALITY -n $NODE -m 1"
