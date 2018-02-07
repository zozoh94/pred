#!/bin/bash
nowDateH=$(date +%H)
if(($nowDateH >= 23 || $nowDateH < 19)); then
    nowDateS=$(date +%s)
    startDateS=$(date -d "19:00" +%s)
    sleepTime=$(($startDateS-$nowDateS))
    sleep $sleepTime
else
    echo "Trop tard pour préparer une nuit de benchmark"
    exit
fi

# On réserve un operator puis on le prépare
oarsub -I -l nodes=1,walltime=13 -t deploy
kadeploy3 -f $OAR_NODE_FILE -e debian9-x64-base -k
rsync -avz --progress operator.sh root@$(cat $OAR_NODE_FILE | head -n 1):~/
ssh root@$(cat $OAR_NODE_FILE | head -n 1) -C "./operator.sh"
ssh root@$(cat $OAR_NODE_FILE | head -n 1) "su pred -c 'mkdir /home/pred/.ssh'"
ssh root@$(cat $OAR_NODE_FILE | head -n 1) "su pred -c 'touch /home/pred/.ssh/authorized_keys'"
cat ~/.ssh/id_rsa.pub | ssh root@$(cat $OAR_NODE_FILE | head -n 1) "cat - >> /home/pred/.ssh/authorized_keys"

