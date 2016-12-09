#!/bin/bash

# Author: Steven Asten
# Returns the status of paper for the printer; can be OK, Out of paper, Jammed, or offline (no response)

HOSTADDRESS=$1
STRING=$2

#get the status of the printer
status=`snmpwalk -v1 -c $STRING $HOSTADDRESS SNMPv2-SMI::mib-2.43.18.1.1.8.1 | tr '[:upper:]' '[:lower:]'`

#ping the printer to check if it's online
pingres=`ping -c 2 $HOSTADDRESS`

#check status of printer for paper jams
if [[ $status == *"jam"* ]]
then
	echo -n "Paper jam"
	exit 2
#check ping variable
elif [[ $pingres == *"100% packet loss"* ]]
then
	echo -n "No Response"
	exit 1
else
	#create array with available printer trays
	mapfile -t trays < <(snmpwalk -v1 -c $STRING $HOSTADDRESS 1.3.6.1.2.1.43.8.2.1.18 | grep -i "tray")
	
	if [[ ${#trays[@]} == 0 ]]
	then
		echo -n "No Response"
		exit 1
	else
		
		#create increment variable, set to zero
		count=0
		
		#for the number of trays in the tray array, check each for paper level corresponding paper level oid
		for (( i=0; i<${#trays[@]}; i++ ))
		do
			oid=$(echo ${trays[i]} | awk '{print $1}')
			paperlevel=`snmpwalk -v1 -c $STRING $HOSTADDRESS ${oid/18/10} | awk '{print $4}'`
			
			#if the paperlevel variable is greater than zero, increment count by 1
			if [[ $paperlevel != "0" ]]
		        then
		                count=`expr $count + 1`
			fi
		done
		
		#if count incrementor is zero, the printer is out of paper. if not, there is paper (or should be anyways ha)
		if [[ $count == 0 ]]
		then		
	        	echo -n "Out of paper."
			exit 2
		else
			echo -n "Paper ok."
			exit 0
		fi
	fi
fi


