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
	-m|--latencymult)
	    MULTLATENCY="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-h|--help)
	    echo "Usage: ./benchmark.sh -t|--topology simple|edge -m|--latencymult number -b|--backend local|swift|ceph -l|--locality g5jlocality -n|--node localitydefaultqueuenode"
	    exit
	    ;;
	*)   # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

case $TOPOLOGY in
    "simple"|"edge")
	;;
    *)
	echo "Topology should be either simple or edge"
	exit
esac

case $BACKEND in
    "local"|"swift"|"ceph")
	;;
    *)
	echo "Backend should be either local, Swift or Ceph"
	exit
esac

if [[ $MULTLATENCY -le 0 ]]
then
    echo "The latency multiplicator should be greater than 0"
    exit
fi

rm reservation.yaml

source venv/bin/activate
./make_reservation.sh -b $BACKEND -t $TOPOLOGY -l $LOCALITY -n $NODE -m $MULTLATENCY > reservation.yaml
enos up --force-deploy
enos info --out json > info.json
if [ $TOPOLOGY == "simple" ]
then
    $SOTRAGE=1
elif [ $TOPOLOGY == "edge" ]
then
     $STORAGE=4
fi
if [ $BACKEND == "swift" ]
then
   for ((i=0 ; $STORAGE - $i; i++))
   do
       rsync -avz --progress swift.sh root@$(jq ".rsc.storage[$i].address" info.json -r):~/
       ssh root@$(jq ".rsc.storage[$i].address" info.json -r) -C "./swift.sh"
   done
   ./generate_rings.sh -s $STORAGE
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
enos tc
enos bench --workload=workload
enos backup
cp current/*rally.tar.gz ../public/$BACKEND"_"$TOPOLOGY"_"$MULTLATENCY"_rally_"$(date +%Y-%m-%d_%H:%M:%S)".tar.gz"
