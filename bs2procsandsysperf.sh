#!/bin/bash

#Richard Deodutt
#08/06/2022
#This script is meant to monitor processes and system performance. It will be able to show processes using over a certain ammount of system memory and allow the user to terminate them. 
#Script issues go here


#Color Output
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
#No Color Output
NC='\033[0m'


#Total memory for the system in kB
TotalSystemMemorykB=$(echo $(grep MemTotal /proc/meminfo | sed 's/[^0-9]*//g'))

#Total available memory for the system in kB
TotalAvailableSystemMemorykB=$(echo $(grep MemAvailable: /proc/meminfo | sed 's/[^0-9]*//g'))

#Percentage of total available memory for the system
PercentageTotalAvailableSystemMemory=$(echo "$TotalAvailableSystemMemorykB / $TotalSystemMemorykB * 100" | bc -l | cut -c "1-4")



#Show the system memory situation
free -h

echo "Available Memory: $PercentageTotalAvailableSystemMemory%"

#Check the system processes


