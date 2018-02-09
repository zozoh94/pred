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
	-m|--latency_mult)
	    MULT_LATENCY="$2"
	    shift # past argument
	    shift # past value
	    ;;
	-h|--help)
	    echo "Usage: ./make_reservation.sh -t|--topology simple|edge -m|--latency_mult number -b|--backend local|swift|ceph -l|--locality g5jlocality -n|--node localitydefaultqueuenode"
	    exit
	    ;;
	*)   # unknown option
	    POSITIONAL+=("$1") # save it in an array for later
	    shift # past argument
	    ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo "# Topology : "$TOPOLOGY
echo "# Latency mult : "$MULT_LATENCY
echo "# Backend for Glance : "$BACKEND
echo "# Locality : "$LOCALITY
echo "# Type of node : "$NODE

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

if [[ $MULT_LATENCY -lt 0 ]]
then
    echo "The latency multiplicator should be greater or equal than 0"
    exit
fi

echo "
---
# ############################################### #
# Grid'5000 reservation parameters                #
# ############################################### #
provider:
  type: g5k
  name: 'Enos'
  walltime: '8:00:00'
  # reservation: '2018-01-26 23:16:00'
  # mandatory : you need to have exacly one vlan
  vlans:
     "$LOCALITY": \"{type='kavlan'}/vlan=1\"
  # Be less strict on node distribution especially
  # when nodes are missing in the reservation
  # or not deployed
  role_distribution: debug
"

case $TOPOLOGY in
    "simple")
	echo "
topology:
  grp1:
    "$NODE":
      control: 1
      network: 1"
	if [ "$BACKEND" != "local" ]
	then
	   echo "
      storage: 1"
	fi
	echo "
  grp2:
    "$NODE":
      compute: 1

network_constraints:
  enable: true
  constraints:
    -
      src: grp1
      dst: grp2
      delay: "$((10*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
"
	;;
    "edge")
	echo "
topology:
  grp1:
    "$NODE":
      control: 1
      network: 1"
	if [ "$BACKEND" != "local" ]
	then
	    echo "
      storage: 1"
	fi
	echo "
  grp2:
    "$NODE":
      storage: 1
  grp3:
    "$NODE":
      storage: 1
  grp4:
    "$NODE":
      storage: 1
  grp5:
    "$NODE":
      compute: 1

network_constraints:
  enable: true
  constraints:
    -
      src: grp1
      dst: grp5
      delay: "$((10*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp1
      dst: grp2
      delay: "$((5*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp2
      dst: grp5
      delay: "$((10*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp3
      dst: grp5
      delay: "$((12*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp4
      dst: grp5
      delay: "$((15*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp3
      dst: grp4
      delay: "$((12*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp1
      dst: grp3
      delay: "$((27*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp1
      dst: grp4
      delay: "$((30*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp1
      dst: grp3
      delay: "$((27*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp1
      dst: grp4
      delay: "$((30*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp2
      dst: grp3
      delay: "$((27*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
    -
      src: grp2
      dst: grp4
      delay: "$((30*$MULT_LATENCY))"ms
      rate: 1gbit
      loss: 0%
      symetric: true
"
	;;
esac

echo "
# ############################################### #
# Inventory to use                                #
# ############################################### #

# This will describe the topology of your services
inventory: inventories/inventory.sample

# ############################################### #
# docker registry parameters
# ############################################### #

# A registry will be deployed and used during the deployment
registry:
  type: internal

# ############################################### #
# Enos Customizations                             #
# ############################################### #
enable_monitoring: no


# ############################################### #
# Kolla parameters                                #
# ############################################### #
# Repository
kolla_repo: \"https://git.openstack.org/openstack/kolla-ansible\"
kolla_ref: \"stable/pike\"

# Vars : globals.yml
kolla:
  kolla_base_distro: \"centos\"
  kolla_install_type: \"source\"
  docker_namespace: \"beyondtheclouds\"
  openstack_release: \"5.0.1\"
  neutron_plugin_agent: \"linuxbridge\"
  enable_openvswitch: \"no\"
  enable_trove: \"no\"
  enable_designate: \"no\"
  enable_octavia: \"no\"
  enable_heat: \"no\"
  enable_horizon: \"yes\"
"
if [ "$BACKEND" == "swift" ]
then
    echo "
  enable_swift: \"yes\"
  glance_backend_swift: \"yes\"
"
elif [ "$BACKEND" == "ceph" ]
then
  echo "
  enable_ceph: \"yes\"
"  
fi
