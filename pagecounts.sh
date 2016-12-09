#!/bin/bash

# Author: Steven Asten
# This script gets color pages and mono pages printed for all printers, and sends a monthly report to Loren Brewster. Used for billing purposes.
# The billing cycle is from the 22nd - 21st. An email report should be send on the 22nd of every month.

# The script gets the page counts of all printers daily
# On the 22nd, it takes the last recorded page count minus the first recorded page count to get monthly total








# Create arrays for various types of printers                
# This is done because different manufacturers use different 
# SNMP OIDs for color pages printed                          
# There are also arrays created for mono-only printers       
# and one array created which is simply a combination of all 
# used arrays, which is used in making the monthly report    


xeroxarr=(`grep address /usr/local/nagios/etc/objects/printers/xeroxcolor.cfg | awk '{print $2}' | sort -V`)
lexmarkarr=(`grep address /usr/local/nagios/etc/objects/printers/lexmarkcolor.cfg | awk '{print $2}' | sort -V`)
hparr=(`grep address /usr/local/nagios/etc/objects/printers/hpcolor.cfg | awk '{print $2}' | sort -V`)
monoarr=(`grep address /usr/local/nagios/etc/objects/printers/monoprinter.cfg | awk '{print $2}' | sort -V`)
monoarrpublic=(`grep address /usr/local/nagios/etc/objects/printers/publicmonoprinter.cfg | awk '{print $2}' | sort -V`)
allips=("${xeroxarr[@]}" "${lexmarkarr[@]}" "${hparr[@]}" "${monoarr[@]}" "${monoarrpublic[@]}") 


# Date variable only contains the day number of the month
# If the date is the 22nd, the script will first print the IP address
# If it is any other day of the month, the script will instead search for the IP address

date=`date +%d` 
#date="23"

# Filename variable is used for page count text files
# Files are named by the date which the billing period ends
# Since today is July 30th, data should be sent to 22Aug2016 file, hence +1 month
# lastfilename variable is used in monthly reports; this is only needed on the 22nd of the month

if [ "$date" -lt "22" ]
then
	filename=`date -d "$(date +%Y-%m-22)" +%d%b%Y`
else
	filename=`date -d "$(date +%Y-%m-22) +1 month" +%d%b%Y`
	lastfilename=`date -d "$(date +%Y-%m-22)" +%d%b%Y`
fi


# This section uses the xeroxarr array, which contains IP addresses of all Xerox color printers
# First it pings the printer to make sure it is online; if it's not, and the date is the 22nd, it simply outputs the IP address
# Then it snmpwalks the printers with color and mono pages OIDs, storing them in monocount and colorcount variables
# If the day is the 22nd, it will output the IP address, followed by the mono and color page counts
# Else, it will search the file for the IP address followed by "m:" for mono, or "c:" for color, and append page count to the end of the line

#edit: this also includes Dell printers now because they share the same SNMP OID for color pages printed.

for (( i=0; i<${#xeroxarr[@]}; i++ ));
do

	alpsline=`grep -n ${xeroxarr[$i]} /usr/local/nagios/etc/objects/printers/xeroxcolor.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/xeroxcolor.cfg`
		
	monocount=$((snmpwalk -v1 -c readPSU ${xeroxarr[$i]} 1.3.6.1.4.1.253.8.53.13.2.1.6.1.20.34 | awk '{print $4}') 2>&1)
	colorcount=$((snmpwalk -v1 -c readPSU ${xeroxarr[$i]} 1.3.6.1.4.1.253.8.53.13.2.1.6.1.20.33 | awk '{print $4}') 2>&1)
	
	if [[ $monocount != *"Timeout:"* ]]
	then		
		if [ "$date" -eq "22" ]
		then
			echo ${xeroxarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			echo ${xeroxarr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
		else
			findIPAddr=`grep "${xeroxarr[$i]}" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt`
			if [[ $findIPAddr == *"${xeroxarr[$i]}"* ]]
			then
				line=`grep -n "${xeroxarr[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        	linecolor=`grep -n "${xeroxarr[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${linecolor}s/$/:$colorcount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			else
			        echo ${xeroxarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        	echo ${xeroxarr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			fi
		fi
	else
                if [ "$date" -eq "22" ]
                then
                        echo ${xeroxarr[$i]}"m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        echo ${xeroxarr[$i]}"c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        
		fi
	fi
done


# Lexmark color printers

for (( i=0; i<${#lexmarkarr[@]}; i++ )); 
do
	alpsline=`grep -n ${xeroxarr[$i]} /usr/local/nagios/etc/objects/printers/lexmarkcolor.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/lexmarkcolor.cfg`
        
	monocount=$((snmpwalk -v1 -c readPSU ${lexmarkarr[$i]} 1.3.6.1.4.1.641.2.1.5.2 | awk '{print $4}') 2>&1)
	colorcount=$((snmpwalk -v1 -c readPSU ${lexmarkarr[$i]} 1.3.6.1.4.1.641.2.1.5.3 | awk '{print $4}') 2>&1)
	
	if [[ $monocount != *"Timeout:"* ]]
        then
	        
		if [ "$date" -eq "22" ]
	        then
			echo ${lexmarkarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			echo ${lexmarkarr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
	        else
			findIPAddr=`grep "${xeroxarr[$i]}" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt`
			if [[ $findIPAddr == *"${lexmarkarr[$i]}"* ]]
			then
	                	line=`grep -n "${lexmarkarr[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	                	sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				linecolor=`grep -n "${lexmarkarr[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${linecolor}s/$/:$colorcount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			else
				echo ${lexmarkarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				echo ${lexmarkarr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			fi
	        fi
        else
                if [ "$date" -eq "22" ]
                then
                        echo ${lexmarkarr[$i]}"m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        echo ${lexmarkarr[$i]}"c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                fi
        fi

done


# HP Color printers

for (( i=0; i<${#hparr[@]}; i++ ));
do
	alpsline=`grep -n ${hparr[$i]} /usr/local/nagios/etc/objects/printers/hpcolor.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/hpcolor.cfg`
        
	monocount=$((snmpwalk -v1 -c readPSU ${hparr[$i]} 1.3.6.1.4.1.11.2.3.9.4.2.1.4.1.2.6 | awk '{print $4}') 2>&1)
	colorcount=$((snmpwalk -v1 -c readPSU ${hparr[$i]} 1.3.6.1.4.1.11.2.3.9.4.2.1.4.1.2.7 | awk '{print $4}') 2>&1)
	
	if [[ $monocount != *"Timeout:"* ]]
        then	
		if [ "$date" -eq "22" ]
		then
			echo ${hparr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			echo ${hparr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
	        else
			findIPAddr=`grep "${xeroxarr[$i]}" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt`
			if [[ $findIPAddr == *"${xeroxarr[$i]}"* ]]
			then
	                	line=`grep -n "${hparr[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	                	sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				linecolor=`grep -n "${hparr[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${linecolor}s/$/:$colorcount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			else
				echo ${hparr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				echo ${hparr[$i]}"c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			fi
		fi
        else
                if [ "$date" -eq "22" ]
                then
                        echo ${hparr[$i]}"m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        echo ${hparr[$i]}"c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                fi
        fi

done



# This section is for Lorens old/difficult printer, which does not have an OID for mono pages printed.
# It gets the color page count and total page count and subtracts to get the mono page count.	       	
# edit: This printer is now located in the ID room, but the note still applies


colorcount=`snmpwalk -v1 -c readPSU 172.29.164.2 1.3.6.1.4.1.11.2.3.9.4.2.1.4.1.2.7 | awk '{print $4}' 2> /dev/null`
totalcount=$((snmpwalk -v1 -c readPSU 172.29.164.2 1.3.6.1.2.1.43.10.2.1.4.1.1 | awk '{print $4}') 2>&1)

if [[ $totalcount != *"Timeout:"* ]]
then
	monocount=$((totalcount - colorcount))
	alpsline=`grep -n "172.29.164.2" /usr/local/nagios/etc/objects/printers/incompat.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/incompat.cfg`

	if [ "$date" -eq "22" ]
	then
		echo "172.29.164.2m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
		echo "172.29.164.2c:"$alpsnumber":"$colorcount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
	else
	        line=`grep -n "172.29.164.2m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	        sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
		linecolor=`grep -n "172.29.164.2c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                sed -i -e "${linecolor}s/$/:$colorcount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt	
	fi
else
        if [ "$date" -eq "22" ]
        then
        	echo "172.29.164.2m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
        	echo "172.29.164.2c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
        fi
fi


# Mono-only printers

for (( i=0; i<${#monoarr[@]}; i++ ));
do
	alpsline=`grep -n ${monoarr[$i]} /usr/local/nagios/etc/objects/printers/monoprinter.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/monoprinter.cfg`
        
        monocount=$((snmpwalk -v1 -c readPSU ${monoarr[$i]} 1.3.6.1.2.1.43.10.2.1.4.1.1 | awk '{print $4}') 2>&1)
	
	if [[ $monocount != *"Timeout:"* ]]
        then

                if [ "$date" -eq "22" ]
                then
                        echo ${monoarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			echo ${monoarr[$i]}"c:"$alpsnumber":0" >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
		else
			findIPAddr=`grep "${monoarr[$i]}" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt`
			if [[ $findIPAddr == *"${monoarr[$i]}"* ]]
			then
                        	line=`grep -n "${monoarr[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        	linecolor=`grep -n "${monoarr[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${linecolor}s/$/:0/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			else
                        	echo ${monoarr[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				echo ${monoarr[$i]}"c:"$alpsnumber":0" >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			fi		
                fi
        else
                if [ "$date" -eq "22" ]
                then
                        echo ${monoarr[$i]}"m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        echo ${monoarr[$i]}"c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                fi
        fi

done


# Mono-only printers which are set to Public SNMP identifier (and cannot be changed)

for (( i=0; i<${#monoarrpublic[@]}; i++ ));
do

	alpsline=`grep -n ${monoarrpublic[$i]} /usr/local/nagios/etc/objects/printers/publicmonoprinter.cfg | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	alpsnumber=`awk -v var=$alpsline 'NR>var && /AP/ {print $NF; exit}' /usr/local/nagios/etc/objects/printers/publicmonoprinter.cfg`
        
        monocount=$((snmpwalk -v1 -c public ${monoarrpublic[$i]} 1.3.6.1.2.1.43.10.2.1.4.1.1 | awk '{print $4}') 2>&1)

	if [[ $monocount != *"Timeout:"* ]]
        then
                if [ "$date" -eq "22" ]
                then
                       	echo ${monoarrpublic[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			echo ${monoarrpublic[$i]}"c:"$alpsnumber":0" >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				
                else
			findIPAddr=`grep "${monoarr[$i]}" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt`
			if [[ $findIPAddr == *"${monoarr[$i]}"* ]]
			then
                        	line=`grep -n "${monoarrpublic[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${line}s/$/:$monocount/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        	linecolor=`grep -n "${monoarrpublic[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
                        	sed -i -e "${linecolor}s/$/:0/" /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			else
                       		echo ${monoarrpublic[$i]}"m:"$alpsnumber":"$monocount >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
				echo ${monoarrpublic[$i]}"c:"$alpsnumber":0" >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
			fi
                fi	
        
	else
                if [ "$date" -eq "22" ]
                then
                        echo ${monoarrpublic[$i]}"m:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                        echo ${monoarrpublic[$i]}"c:"$alpsnumber >> /usr/local/nagios/libexec/pagecountdocs/"$filename".txt
                fi
        fi
done




# This section creates the monthly page count reports and sends them to loren

if [[ $date == "22" ]]
then
	echo "IP ADDRESS,ALPS#,MONO,COLOR" >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv #Headings for report	
	
	for (( i=0; i<${#allips[@]}; i++ )); #Runs through all printers (allips array created above)
	do

		# Color page count and mono page count are stored on two separate
		# lines for each printer; this looks for the printer ip followed by
		# either m for mono or c for color, and outputs ONLY the line number

	        linemono=`grep -n "${allips[$i]}m" /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`
	        linecolor=`grep -n "${allips[$i]}c" /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt | sed -n 's/^\([0-9]*\)[:].*/\1/p'`



		# Print the ip address of each printer followed by a comma

	        awk -F ":" -v var="$linemono" -v ORS="" 'FNR == var { print $1 }' /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt | sed 's/m//' >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		echo -n "," >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv


		# Prints the ALPS number I think hopefully probably
		
		awk -F ":" -v var="$linemono" -v ORS="" 'FNR == var { print $2 }' /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		echo -n "," >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv


		# Print mono page count of printer, followed by comma
		
		monocontent=`sed -n "$linemono p" /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt`
		if [[ $monocontent == *":"* ]]
		then
	        	awk -F ":" -v var="$linemono" -v ORS="" 'FNR == var { print ($NF - $3) }' /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		else
			echo -n "0" >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		fi

		echo -n "," >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv


		# Print color page count of printer

		colorcontent=`sed -n "$linecolor p" /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt`
		if [[ $colorcontent == *":"* ]]
		then
	        	awk -F ":" -v var="$linecolor" 'FNR == var { print ($NF - $3) }' /usr/local/nagios/libexec/pagecountdocs/"$lastfilename".txt >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		else	
			echo "0" >> /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
		fi
	done
	

	# Send email with page count CSV that was created above attached

	/usr/local/bin/sendEmail -s smtp.psu.edu -t sca5129@psu.edu -f ykitmaint@psu.edu -l /var/log/sendEmail -u "$lastfilename Printer Page Counts" -m "See attached." -a /usr/local/nagios/libexec/pagecountdocs/pagecountreports/"$lastfilename".csv
fi



