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

#State of the system's memory
TotalSystemMemoryKB=0
TotalAvailableSystemMemoryKB=0
PercentageTotalAvailableSystemMemory=0
PercentageTotalUsedSystemMemory=0



#Function to convert KB to a human readable format
KBtoHumanReadable(){
    #Takes in Kilobytes as the first arugment
    Kilobytes=$1
    #Convert the Kilobytes to Bytes by multiplying them by BinaryKilo(1024)
    Bytes=$(echo "$Kilobytes * $BinaryKilo" | bc -l)
    if [ $Kilobytes -ge $BinaryKilo ]; then
        #If the number of Kilobytes is over BinaryKilo(1024) convert to Megabytes
        Megabytes=$(echo "$Bytes / ($BinaryKilo ^ 2)" | bc -l)
        if [ $(printf '%.*f\n' 0 $Megabytes) -ge $BinaryKilo ]; then
            #If the number of Megabytes is over BinaryKilo(1024) convert to Gigabytes
            Gigabytes=$(echo "$Bytes / ($BinaryKilo ^ 3)" | bc -l)
            #Print as Gigabytes due to the number of Megabytes being at or over BinaryKilo(1024)
            printf '%.*f GB\n' 2 $Gigabytes
        else
            #Print as Megabytes due to the number of Kilobytes being at or over BinaryKilo(1024) and the number of Megabytes being under BinaryKilo or 1024
            printf '%.*f MB\n' 2 $Megabytes
        fi
    else
        #Print as Kilobytes due to the number of Kilobytes being under BinaryKilo or 1024
        printf '%.*f KB\n' 2 $Kilobytes
    fi
}

#Function to update the state of the systems memory and store it
UpdateSystemMemoryState(){
    #Total memory for the system in KB numbers only
    TotalSystemMemoryKB=$(echo $(grep MemTotal /proc/meminfo | sed 's/[^0-9]*//g'))
    #Total available memory for the system in KB numbers only
    TotalAvailableSystemMemoryKB=$(echo $(grep MemAvailable: /proc/meminfo | sed 's/[^0-9]*//g'))
    #Percentage of total available memory for the system rounded
    PercentageTotalAvailableSystemMemory=$(printf '%.*f\n' 1 $(echo "$TotalAvailableSystemMemoryKB / $TotalSystemMemoryKB * 100" | bc -l))
    #Percentage of total used memory for the system rounded
    PercentageTotalUsedSystemMemory=$(printf '%.*f\n' 1 $(echo "100 - $PercentageTotalAvailableSystemMemory" | bc -l))
}

#Function to print/echo the last state of the systems memory stored
PrintSystemMemoryStatus(){
    #Total memory for the system in a human readable format
    echo "Total System Memory: "$(KBtoHumanReadable $TotalSystemMemoryKB)
    #Total available memory for the system in a human readable format
    echo "Total Available System Memory: "$(KBtoHumanReadable $TotalAvailableSystemMemoryKB)
    #Percentage of total available memory for the system rounded
    echo "Percent of Available Memory: $PercentageTotalAvailableSystemMemory %"
    #Percentage of total used memory for the system rounded
    echo "Percent of Used Memory: $PercentageTotalUsedSystemMemory %"
}

#Check the system memory situation

#Update the system memory state
UpdateSystemMemoryState

#Print the system memory state
PrintSystemMemoryStatus

#Check how much memory is free and assign a code- code green means free memory is high, code yellow means free memory is mid and code red means free memory is low. depending on code it will change the threshold for showing processes to be selected for termination.



#Check the system processes


