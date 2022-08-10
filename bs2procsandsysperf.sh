#!/bin/bash

#Richard Deodutt
#08/06/2022
#This script is meant to monitor processes and system performance. It will be able to show processes using over a certain ammount of system memory and allow the user to terminate them. 
#Script issues go here



#Units
BinaryKilo=$((1024))

#Color output
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
#No color output
NC='\033[0m'


#Total memory for the system in kB
TotalSystemMemorykB=$(echo $(grep MemTotal /proc/meminfo | sed 's/[^0-9]*//g'))

#Total available memory for the system in kB
TotalAvailableSystemMemorykB=$(echo $(grep MemAvailable: /proc/meminfo | sed 's/[^0-9]*//g'))

#Percentage of total available memory for the system
PercentageTotalAvailableSystemMemory=$(printf '%.*f\n' 1 $(echo "$TotalAvailableSystemMemorykB / $TotalSystemMemorykB * 100" | bc -l))

#Percentage of total used memory for the system
PercentageTotalUsedSystemMemory=$(printf '%.*f\n' 1 $(echo "100 - $PercentageTotalAvailableSystemMemory" | bc -l))

KBtohumanreadable(){
    Kilobytes=$1
    Bytes=$(echo "$Kilobytes * $BinaryKilo" | bc -l)
    if [ $Kilobytes -ge $BinaryKilo ]; then
        Megabytes=$(echo "$Bytes / ($BinaryKilo ^ 2)" | bc -l)
        if [ $(printf '%.*f\n' 0 $Megabytes) -ge $BinaryKilo ]; then
            Gigabytes=$(echo "$Bytes / ($BinaryKilo ^ 3)" | bc -l)
            printf '%.*f GB\n' 2 $Gigabytes
        else
            printf '%.*f MB\n' 2 $Megabytes
        fi
    else
        printf '%.*f KB\n' 2 $Kilobytes
    fi
}

echo "Total System Memory: "$(KBtohumanreadable $TotalSystemMemorykB)

echo "Total Available System Memory: "$(KBtohumanreadable $TotalAvailableSystemMemorykB)

echo "Percent of Available Memory: $PercentageTotalAvailableSystemMemory %"

echo "Percent of Used Memory: $PercentageTotalUsedSystemMemory %"



#Show the system memory situation
free -h

#Check the system processes


