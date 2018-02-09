#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
	-t|--topology)
	    TOPOLOGY="$2"	    	    
	    shift # past argument
	    shift # past value
	    ;;
	-s|--storage_per_control)
	    STORAGE="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-b|--backend)
	    BACKEND="$2"
	    shift # past argument
	    shift # past value
	    ;;
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
	    echo "Usage: ./bnchmark.sh -t|--topology simple|edge -s|--storage_per_control number -b|--backend local|swift|ceph -l|--locality g5jlocality -n|--node localitydefaultqueuenode"
	    exit
	    ;;
	*)   # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


rm reservation.yaml

source venv/bin/activate
./make_reservation.sh -b $BACKEND -t $TOPOLOGY -l $LOCALITY -n $NODE -s $STORAGE > reservation.yaml
enos up --force-deploy
enos info --out json > info.json
if [ $BACKEND == "swift" ]
then
   for ((i=0 ; $STORAGE - $i; i++))
   do
       rsync -avz --progress swift.sh root@$(jq ".rsc.storage[$i].address" info.json -r):~/
       ssh root@$(jq ".rsc.storage[$i].address" info.json -r) -C "./swift.sh"
   done
   ./generate_rings.sh
elif [ $BACKEND == "ceph" ]
then
   for ((i=0 ; $STORAGE - $i; i++))
   do
       rsync -avz --progress ceph.sh root@$(jq ".rsc.storage[$i].address" info.json -r):~/
       ssh root@$(jq ".rsc.storage[$i].address" info.json -r) -C "./ceph.sh"
   done
fi
rm info.json
enos os
enos init
enos bench --workload=workload
enos backup
cp current/*rally.tar.gz ../public/$BACKEND"_"$TOPOLOGY"_"$STORAGE"_rally.tar.gz"

#rm reservation.yaml
