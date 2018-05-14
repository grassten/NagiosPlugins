#!/bin/bash

# Author: Steven Asten
# Returns toner level for a single color based on the color choice passed into the colorchoice variable


hostaddress=$1
colorchoice=$2
stringchoice=$3

#query printer for OIDs where colors are stored to see which colors printer supports and in what order they are in
color1=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o SNMPv2-SMI::mib-2.43.12.1.1.4.1.1 | awk '{print $4}' | sed 's/"//g' | sed 's/\b\(.\)/\u\1/g'`
color2=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o SNMPv2-SMI::mib-2.43.12.1.1.4.1.2 | awk '{print $4}' | sed 's/"//g' | sed 's/\b\(.\)/\u\1/g'`
color3=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o SNMPv2-SMI::mib-2.43.12.1.1.4.1.3 | awk '{print $4}' | sed 's/"//g' | sed 's/\b\(.\)/\u\1/g'`
color4=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o SNMPv2-SMI::mib-2.43.12.1.1.4.1.4 | awk '{print $4}' | sed 's/"//g' | sed 's/\b\(.\)/\u\1/g'`
other=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o SNMPv2-SMI::mib-2.43.11.1.1.6.1.1 | awk '{print $4}' | sed 's/"//g'`


#for old printers that say "Toner" instead of "Black"
if [ $other = "Toner" ]
then
	#get current toner integer, store in color1toner
        color1toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.9.1.1 | awk '{print $4}'`
	#get max toner integer, store in max1toner
        max1toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.8.1.1 | awk '{print $4}'`
	#if max toner is showing as 0, there is an error, or the printer does not support SNMP
	if [ $max1toner = "0" ]
	then
		echo "Error"
		exit 1
	fi

	#divide max toner from current to get a percentage
        toner1level=$((100 * $color1toner / $max1toner))

	#if current toner is less than zero, the printer does not support SNMP toner checks.
	if [ "$color1toner" -lt "0" ]
	then
		echo "Not Supported"
		exit 0
       	else
		#case statement to return proper status based on toner level (below 10 returns critical status)
               	case $toner1level in
                [1][0][0=]*)
                echo "Black Toner Level: $toner1level%."
                exit 0
                ;;
                [2-9][0-9]*)
                echo "Black Toner Level: $toner1level%."
                exit 0
                ;;
                [1][0-9]*)
                echo "Black Toner Level: $toner1level%."
                exit 0
                ;;
                [0-9]*)
                echo "Black Toner Level: $toner1level%."
                exit 2
                ;;
                *)
                echo "Black Toner Level: $toner1level%."
                exit 3
                ;;
                esac
        fi

elif [ $color1 = $colorchoice ]
then
        color1toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.9.1.1 | awk '{print $4}' | tr '[:upper:]' '[:lower:]'`
	if [[ $color1toner == *"error"* ]]
	then
		echo "Error"
		exit 1
        elif [ "$max1toner" = "0" ]
        then
                echo "Error"
                exit 1
	else
	       	max1toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.8.1.1 | awk '{print $4}'`
       		toner1level=$((100 * $color1toner / $max1toner))
	
		if [ "$color1toner" -lt "0" ]
	        then
	                echo "Not Supported"
	                exit 0
	        else
	                case $toner1level in
	                [1][0][0=]*)
	                echo "$color1 Toner Level: $toner1level%."
	                exit 0
	                ;;
	                [2-9][0-9]*)
	                echo "$color1 Toner Level: $toner1level%."
	                exit 0
	                ;;
	                [1][0-9]*)
	                echo "$color1 Toner Level: $toner1level%."
	                exit 0
	                ;;
	                [0-9]*)
	                echo "$color1 Toner Level: $toner1level%."
	                exit 2
	                ;;
	                *)
	                echo "$color1 Toner Level: $toner1level%."
	                exit 3
	                ;;
	                esac
	        fi
	fi

elif [ $color2 = $colorchoice ]
then
        color2toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.9.1.2 | awk '{print $4}' | tr '[:upper:]' '[:lower:]'`
	if [[ $color2toner == *"error"* ]]
        then
                echo "Error"
                exit 1
        else
	       	max2toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.8.1.2 | awk '{print $4}'`
	        toner2level=$((100 * $color2toner / $max2toner))
	        
		case $toner2level in
	        [1][0][0=]*)
	        echo "$color2 Toner Level: $toner2level%."
	        exit 0
	        ;;
	        [2-9][0-9]*)
	        echo "$color2 Toner Level: $toner2level%."
	        exit 0
	        ;;
	        [1][0-9]*)
	        echo "$color2 Toner Level: $toner2level%."
	        exit 0
	        ;;
	        [0-9]*)
	        echo "$color2 Toner Level: $toner2level%."
	        exit 2
	        ;;
	        *)
	        echo "$color2 Toner Level: $toner2level%."
	        exit 3
	        ;;
	        esac
	fi

elif [ $color3 = $colorchoice ]
then
        color3toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.9.1.3 | awk '{print $4}' | tr '[:upper:]' '[:lower:]'`
	if [[ $color1toner == *"error"* ]]
        then
                echo "Error"
                exit 1
        else
	        max3toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.8.1.3 | awk '{print $4}'`
	        toner3level=$((100 * $color3toner / $max3toner))
	
		case $toner3level in
	        [1][0][0=]*)
	        echo "$color3 Toner Level: $toner3level%."
	        exit 0
	        ;;
	        [2-9][0-9]*)
	        echo "$color3 Toner Level: $toner3level%."
	        exit 0
	        ;;
	        [1][0-9]*)
	        echo "$color3 Toner Level: $toner3level%."
	        exit 0
	        ;;
	        [0-9]*)
	        echo "$color3 Toner Level: $toner3level%."
	        exit 2
	        ;;
	        *)
	        echo "$color3 Toner Level: $toner3level%."
	        exit 3
	        ;;
	        esac
	fi

elif [ $color4 = $colorchoice ]
then
        color4toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.9.1.4 | awk '{print $4}' | tr '[:upper:]' '[:lower:]'`
	if [[ $color1toner == *"error"* ]]
        then
                echo "Error"
                exit 1
        else
	        max4toner=`/usr/local/nagios/libexec/check_snmp -C $stringchoice -H $hostaddress -o 1.3.6.1.2.1.43.11.1.1.8.1.4 | awk '{print $4}'`
	        toner4level=$((100 * $color4toner / $max4toner))
	
		case $toner4level in
	        [1][0][0=]*)
	        echo "$color4 Toner Level: $toner4level%."
	        exit 0
	        ;;
	        [2-9][0-9]*)
	        echo "$color4 Toner Level: $toner4level%."
	        exit 0
	        ;;
	        [1][0-9]*)
	        echo "$color4 Toner Level: $toner4level%."
	        exit 0
	        ;;
	        [0-9]*)
	        echo "$color4 Toner Level: $toner4level%."
	        exit 2
	        ;;
	        *)
	        echo "$color4 Toner Level: $toner4level%."
	        exit 3
	        ;;
	        esac
	fi
else
        echo "No Response"
        exit 1

fi


