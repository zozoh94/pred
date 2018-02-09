#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
	-s|--storage)
	    STORAGE="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-h|--help)
	    echo "Usage: ./generate_rings.sh -s|--storage number"
	    exit
	    ;;
	*)   # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $STORAGE -lt 1 ]]
then
    echo "The number of storage should be greater or equal than 1"
    exit
fi

STORAGE_NODES=()
for ((i=0 ; $STORAGE - $i; i++))
do
    STORAGE_NODES=("${STORAGE_NODES[@]}" $(host $(jq ".rsc.storage[$i].address" info.json -r) | grep -oP "address\s+\K.*"))
done
KOLLA_SWIFT_BASE_IMAGE="kolla/oraclelinux-source-swift-base:4.0.0"

# Object ring
docker run \
       --rm \
       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
       $KOLLA_SWIFT_BASE_IMAGE \
       swift-ring-builder \
       /etc/kolla/config/swift/object.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
	docker run \
	       --rm \
	       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
	       $KOLLA_SWIFT_BASE_IMAGE \
	       swift-ring-builder \
	       /etc/kolla/config/swift/object.builder add r1z1-${node}:6000/d${i} 1;
    done
done

# Account ring
docker run \
       --rm \
       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
       $KOLLA_SWIFT_BASE_IMAGE \
       swift-ring-builder \
       /etc/kolla/config/swift/account.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
	docker run \
	       --rm \
	       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
	       $KOLLA_SWIFT_BASE_IMAGE \
	       swift-ring-builder \
	       /etc/kolla/config/swift/account.builder add r1z1-${node}:6001/d${i} 1;
    done
done

# Container ring
docker run \
       --rm \
       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
       $KOLLA_SWIFT_BASE_IMAGE \
       swift-ring-builder \
       /etc/kolla/config/swift/container.builder create 10 3 1

for node in ${STORAGE_NODES[@]}; do
    for i in {0..2}; do
	docker run \
	       --rm \
	       -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
	       $KOLLA_SWIFT_BASE_IMAGE \
	       swift-ring-builder \
	       /etc/kolla/config/swift/container.builder add r1z1-${node}:6002/d${i} 1;
    done
done

for ring in object account container; do
    docker run \
	   --rm \
	   -v /etc/kolla/config/swift/:/etc/kolla/config/swift/ \
	   $KOLLA_SWIFT_BASE_IMAGE \
	   swift-ring-builder \
	   /etc/kolla/config/swift/${ring}.builder rebalance;
    done
