#!/bin/bash

#   CIDR Calculator
#   Developed by Juan Orts

# Colors
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"

# Exit with Ctrl+C

trap ctrl_c INT

# *************
#   Functions
# *************

# Ctrl+C
function ctrl_c(){
  echo -e "\n\n${redColor}Exiting...${endColor}\n"
  exit 1
}

function calculateAll(){

  # Check if input CIDR is valid
  if [[ $cidr =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])/(3[0-2]|[12]?[0-9]|[0-9])$ ]]; then

    # Extract octets and CIDR value
    firstOctet="$(echo $cidr | cut -d '.' -f 1)"
    secondOctet="$(echo $cidr | cut -d '.' -f 2)"
    thirdOctet="$(echo $cidr | cut -d '.' -f 3)"
    fourthOctet="$(echo $cidr | cut -d '.' -f 4 | cut -d '/' -f 1)"
    cidrValue="$(echo $cidr | cut -d '.' -f 4 | cut -d '/' -f 2)"

    # Obtain subnet mask
    length=32
    difference=$(($length - $cidrValue))
    subnetBinary=""

    for i in $(seq 1 $cidrValue); do
      subnetBinary+="1"
    done

    for i in $(seq 1 $difference); do
      subnetBinary+="0"
    done

    submaskOctet1=$(echo $subnetBinary | head -c 8)
    submaskOctet2=$(echo $subnetBinary | head -c 16 | tail -c 8)
    submaskOctet3=$(echo $subnetBinary | head -c 24 | tail -c 8)
    submaskOctet4=$(echo $subnetBinary | head -c 32 | tail -c 8)

    netmask="$((2#$submaskOctet1))"."$((2#$submaskOctet2))"."$((2#$submaskOctet3))"."$((2#$submaskOctet4))"

    # Obtain wildcard
    wildcardOctet1=$(echo $subnetBinary | sed "s/0/2/g" | sed "s/1/0/g" | sed "s/2/1/g" | head -c 8)
    wildcardOctet2=$(echo $subnetBinary | sed "s/0/2/g" | sed "s/1/0/g" | sed "s/2/1/g" | head -c 16 | tail -c 8)
    wildcardOctet3=$(echo $subnetBinary | sed "s/0/2/g" | sed "s/1/0/g" | sed "s/2/1/g" | head -c 24 | tail -c 8)
    wildcardOctet4=$(echo $subnetBinary | sed "s/0/2/g" | sed "s/1/0/g" | sed "s/2/1/g" | head -c 32 | tail -c 8)

    wildcard="$((2#$wildcardOctet1))"."$((2#$wildcardOctet2))"."$((2#$wildcardOctet3))"."$((2#$wildcardOctet4))"

    # Calculate the number of hosts and total number of addresses
    totalHosts=$((2**$difference - 2))
    addresses=$((2**$difference))

    # Calculate the network address
    if [ $cidrValue -gt 24 ]; then  # Class C 255.255.255.x
      rangeStart=0

      while [ $rangeStart -le $fourthOctet ] && [ "$(($rangeStart + $addresses))" -le $fourthOctet ]; do
        rangeStart=$(($rangeStart + $addresses))
      done

      networkAddress="$firstOctet"."$secondOctet"."$thirdOctet"."$rangeStart"

      # Calculate the first host
      hostStart=$(($rangeStart + 1))

      firstHost="$firstOctet"."$secondOctet"."$thirdOctet"."$hostStart"

      # Calculate the broadcast address and last host
      broadcastOctet=$(($rangeStart + $addresses -1))
      broadcastAddress="$firstOctet"."$secondOctet"."$thirdOctet"."$broadcastOctet"
      lastHost="$firstOctet"."$secondOctet"."$thirdOctet"."$(($broadcastOctet-1))"

    elif [ $cidrValue -gt 16 ] && [ $cidrValue -le 24 ]; then # Class B 255.255.x.0

      gap=$(($addresses / 256))

      rangeStart=0

      while [ $rangeStart -le $thirdOctet ] && [ "$(($rangeStart + $gap))" -le $thirdOctet ]; do
        rangeStart=$(($rangeStart + $gap))
      done

      networkAddress="$firstOctet"."$secondOctet"."$rangeStart"."0"

      # Calculate the first host 
      firstHost="$firstOctet"."$secondOctet"."$rangeStart"."1"

      # Calculate the broadcast address and last host
      broadcastOctet=$(($rangeStart + $gap - 1))
      broadcastAddress="$firstOctet"."$secondOctet"."$broadcastOctet"."255"
      lastHost="$firstOctet"."$secondOctet"."$broadcastOctet"."254"

    elif [ $cidrValue -gt 8 ] && [ $cidrValue -le 16 ]; then  # Class A 225.x.0.0
      gap=$(($addresses / 256 / 256))

      rangeStart=0

      while [ $rangeStart -le $secondOctet ] && [ "$(($rangeStart + $gap))" -le $secondOctet ]; do
        rangeStart=$(($rangeStart + $gap))
      done

      networkAddress="$firstOctet"."$rangeStart"."0"."0"

      # Calculate the first host
      firstHost="$firstOctet"."$rangeStart"."0"."1"

      # Calculate the broadcast address and last host
      broadcastOctet=$(($rangeStart + $gap - 1))
      broadcastAddress="$firstOctet"."$broadcastOctet"."255"."255"
      lastHost="$firstOctet"."$broadcastOctet"."255"."254"
     
    else  # x.0.0.0
      gap=$(($addresses / 256 / 256 / 256))

      rangeStart=0

      while [ $rangeStart -le $firstOctet ] && [ "$(($rangeStart + $gap))" -le $firstOctet ]; do
        rangeStart=$(($rangeStart + $gap))
      done

      networkAddress="$rangeStart"."0"."0"."0"

      # Calculate the first host
      firstHost="$rangeStart"."0"."0"."1"

      # Calculate the broadcast address and last host
      broadcastOctet=$(($rangeStart + $gap - 1))
      broadcastAddress="$broadcastOctet"."255"."255"."255"
      lastHost="$broadcastOctet"."255"."255"."254"
     
    fi
    
    # Show all information
    echo -e "\n${yellowColor}[+]${endColor} ${greenColor}CIDR Range: $cidr${endColor}"
    echo -e "${yellowColor}[+]${endColor} Netmask: ${blueColor}$netmask${endColor}"
    echo -e "${yellowColor}[+]${endColor} Wildcard bits: ${blueColor}$wildcard${endColor}"
    
    if [ $cidrValue -le 30 ]; then
    echo -e "${yellowColor}[+]${endColor} ${turquoiseColor}Network${endColor} address: ${blueColor}$networkAddress${endColor}"
    fi

    if [ $cidrValue -le 30 ]; then
      echo -e "${yellowColor}[+]${endColor} First host: ${blueColor}$firstHost${endColor}"
    elif [ $cidrValue -eq 31 ]; then
      echo -e "${yellowColor}[+]${endColor} First host: ${blueColor}$networkAddress${endColor}"
    else
      echo -e "${yellowColor}[+]${endColor} First host: ${blueColor}$networkAddress${endColor}"
    fi

    if [ $cidrValue -le 30 ]; then
    echo -e "${yellowColor}[+]${endColor} ${purpleColor}Broadcast${endColor} address: ${blueColor}$broadcastAddress${endColor}"
    fi

    if [ $cidrValue -le 30 ]; then
      echo -e "${yellowColor}[+]${endColor} Last host: ${blueColor}$lastHost${endColor}"
    elif [ $cidrValue -eq 31 ]; then
      echo -e "${yellowColor}[+]${endColor} Last host: ${blueColor}$broadcastAddress${endColor}"
    fi

    if [ $cidrValue -le 30 ]; then
      echo -e "${yellowColor}[+]${endColor} Total hosts: ${blueColor}$totalHosts hosts${endColor} + ${turquoiseColor}Network${endColor} and ${purpleColor}Broadcast${endColor} addresses\n"
    elif [ $cidrValue -eq 31 ]; then
      echo -e "${yellowColor}[+]${endColor} Total hosts: 2 hosts\n"
    else
      echo -e "${yellowColor}[+]${endColor} Total hosts: 1 host\n"
    fi
  else
    echo -e "\n${redColor}[!] CIDR notation is not valid${endColor}\n"
    exit 1
  fi

}

# Help panel
function helpPanel(){ 
  echo -e "\n${greenColor}.::  CIDR to IPv4 Conversion Tool  ::.${endColor}\n"
  echo -e "Bash script developed by Juan Orts and inspired by ${blueColor}https://www.ipaddressguide.com/cidr${endColor}\n\n"
  echo -e "${yellowColor}[+]${endColor} Usage: ${yellowColor}$0${yellowColor}\n"
  echo -e "\t${yellowColor}-v ${endColor}<CIDR notation>\t${blueColor}Verbose (detailed output): show all information${endColor}"
  echo -e "\t${yellowColor}-h${endColor}\t\t\t${blueColor}Help: show this menu${endColor}\n"
}

# **************
#   Parameters
# **************
while getopts "v:h" arg; do
  case $arg in
    v) cidr=$OPTARG;;
    h) ;;
  esac
done

if [ $cidr ]; then
  calculateAll
else
  helpPanel
fi
