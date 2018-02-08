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

./make_reservation.sh -b $BACKEND -t $TOPOLOGY -l $LOCALITY -n $NODE -s $STORAGE > reservation.yaml
enos up
if [ $BACKEND == "swift" ]
   ./generate_rings.sh

rm reservation.yaml
