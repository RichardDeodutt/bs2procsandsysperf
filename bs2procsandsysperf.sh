#!/bin/bash

#Richard Deodutt
#08/06/2022
#This script is meant to monitor processes and system performance. It will be able to show the system's state and processes using over a certain ammount of system memory and allow the user to terminate them. 
#The Base Threshold Percent which is the ThresholdPercent variable can be changed in the script if you want to raise or lower the memory usage threshold that needs to be passed by a process to be listed. If you lower it all the way to 0 it would list all the processes that use more than 0 percent memory which includes this script itself, and the bash terminal running this script. This means it is possible to break the script by selecting this script from the processes list to terminate or kill. You can also kill the bash terminal running this script. It also has the issue of listing processes that only existed when it was checked but may not be running anymore such as the ps command this script uses itself, this can also happen outside of running at the 0 threshold percent depending on your circumstances because it only runs the ps command once and uses that information until refreshed or restarted but the information may change the next second so it may fail to terminate or kill a processes due to the process ending another way already. The last issue shouldn't break the script as those processes are not running which is what we want, it would just print a error message that terminating or kill the process didn't work. 



#Units, don't change
BinaryKilo=$((1024))

#Color output, don't change
Red='\033[0;31m'
Green='\033[0;32m'
Yellow='\033[0;33m'
#No color output, don't change
NC='\033[0m'

#Color code thresholds
#100% and below, should not change
CodeGreen=$((100))
#50% and below, can change but must be less than Geen and more than Red
CodeYellow=$((50))
#25% and below, can change but must be less than Yellow
CodeRed=$((25))

#Threshold percent, can change to directly change the base threshold for selection, running it at 0 causes issues
ThresholdPercent=$((20))
#Adjusted threshold percent, don't change as it self calculates it's own value
AdjustedThresholdPercent=$((20))

#State of the system's memory, don't change
TotalSystemMemoryKB=0
TotalAvailableSystemMemoryKB=0
PercentageTotalAvailableSystemMemory=0
PercentageTotalUsedSystemMemory=0
Code="No Color"
ColorCode=$NC
Multiplier=$((1))

#Print to the console in colored text
ColorPrint(){
    Text=$1
    Color=$2
    printf "${Color}$Text${NC}\n"
}

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
    #Sets color code and multiplier based on set thresholds
    #Depending on the color code it will change the threshold for showing processes to be selected for termination.
    if [ $(echo $PercentageTotalAvailableSystemMemory | cut -d"." -f 1) -le $CodeRed ]; then
        #Code red low ammount of memory free
        ColorCode=$Red
        Code="Red"
        #Multiplier as a decimal of code red
        Multiplier=$(printf '%.*f\n' 2 $(echo "$CodeRed / 100" | bc -l))
    elif [ $(echo $PercentageTotalAvailableSystemMemory | cut -d"." -f 1) -le $CodeYellow ]; then
        #Code yellow mid ammount of memory free
        ColorCode=$Yellow
        Code="Yellow"
        #Multiplier as a decimal of code yellow
        Multiplier=$(printf '%.*f\n' 2 $(echo "$CodeYellow / 100" | bc -l))
    elif [ $(echo $PercentageTotalAvailableSystemMemory | cut -d"." -f 1) -le $CodeGreen ]; then
        #Code green high ammount of memory free
        ColorCode=$Green
        Code="Green"
        #Multiplier as a decimal of code green
        Multiplier=$(printf '%.*f\n' 2 $(echo "$CodeGreen / 100" | bc -l))
    else
        #Code error something is wrong so use defaults
        ColorCode=$NC
        Code="No-Color"
        #Multiplier as a decimal 100%
        Multiplier=$((1))
    fi
    #Adjust the threshold percent based on the state of the system
    AdjustedThresholdPercent=$(printf '%.*f\n' 1 $(echo "$ThresholdPercent * $Multiplier" | bc -l))
}

#Function to print/echo the last state of the systems memory stored
PrintSystemMemoryStatus(){
    #Total memory for the system in a human readable format
    echo "Total System Memory: $(KBtoHumanReadable $TotalSystemMemoryKB)"
    #Total available memory for the system in a human readable format
    echo "Total Available System Memory: $(KBtoHumanReadable $TotalAvailableSystemMemoryKB)"
    #Percentage of total available memory for the system rounded and color coded
    echo "Percent of Available Memory: $(ColorPrint $PercentageTotalAvailableSystemMemory $ColorCode) %"
    #Percentage of total used memory for the system rounded and color coded
    echo "Percent of Used Memory: $(ColorPrint $PercentageTotalUsedSystemMemory $ColorCode) %"
    #The state of the system explained in a color code, the multiplier used, the original threshold percent and adjusted threshold percent used to select which processes are using too much memory
    echo "Code Color: $(ColorPrint $Code $ColorCode) | Multiplier: $Multiplier | Threshold Percent: $ThresholdPercent % | Adjusted Threshold Percent: $AdjustedThresholdPercent %"
}

#Kill a process using the process id
KillbyPID(){
    #Takes in the process id as the first argument
    PID=$1
    #Kill command with no output
    kill -9 $PID > /dev/null 2>&1
    #Check if the command has a error
    if [ $? -eq 0 ]; then
        #Command worked
        echo $(ColorPrint "Killed" $Green)
        return 0
    else
        #Command did not work
        echo $(ColorPrint "Something went wrong with killing the process" $Red)
        return 1
    fi
}

#Terminate a process using the process id
TerminatebyPID(){
    #Takes in the process id as the first argument
    PID=$1
    #Terminate command with no output
    kill $PID > /dev/null 2>&1
    #Check if the command has a error
    if [ $? -eq 0 ]; then
        #Command worked
        echo $(ColorPrint "Terminated" $Green)
        return 0
    else
        #Command did not work, try to kill instead as it might be unresponsive
        echo $(ColorPrint "Something went wrong with terminating the process, attempting to kill" $Red)
        KillbyPID $PID
        return $?
    fi
}

#Echos the status or options and instructions
StatusOptions(){
    #Takes in the options as the first argument
    Options="$1"
    #Echo status or options
    echo $(ColorPrint "Can terminate from the following process list below: " $Red)
    echo
    #echo all the options
    echo "$Options"
    echo
    #echo instuctions or helpful info on what to enter
    echo $(ColorPrint "Select a process using the number on the # column on the leftmost side to terminate it" $Red)
    echo $(ColorPrint "If the first character of the input is: " $Red)
    echo $(ColorPrint "'t' change the mode to terminate, 'k' change the mode to kill or 'r' to refresh/restart everything" $Red)
    echo $(ColorPrint "'a' terminate or kill all processes, 's' for remaining status/options or 'q' to quit selection" $Red)
    echo
}

#Select interactive options to terminate or kill a process
SelectInteractiveOptions(){
    #Options of processes that are over the threshold and can be terminated or killed
    Options=$(ps -eo user,pid,%mem,rss,stat,start,time,command --sort=-%mem | (sed -u 1q; awk -v TP=$AdjustedThresholdPercent '$3 > TP') | nl -v 0 | sed -e '0,/0/ s/0/#/')
    #Mode of t is terminate and k is kill
    Mode='t'
    #The total number of options not counting the header
    OptionsCount=$(($(echo "$Options" | wc -l) - 1))
    #Check if there are any options and if there is not then stop
    if [ $OptionsCount -eq $((0)) ]; then
        echo $(ColorPrint "Nothing meets the threshold to terminate" $Green)
        return 0
    fi
    #Echo status of options list and instuctions
    StatusOptions "$Options"
    #infinite loop for input and output with the user
    while :
    do
        #Check if there are any more options and if there is not then stop
        if [ $OptionsCount -eq $((0)) ]; then
            echo $(ColorPrint "Nothing else meets the threshold to terminate" $Green)
            return 0
        fi
        #get the user input and show mode
        if [ $Mode == 't' ]; then
            #Terminate mode
            read -p "Term #> " Selection
        elif [ $Mode == 'k' ]; then
            #Kill mode
            read -p "Kill #> " Selection
        else
            #Default terminate mode
            Mode='t'
            read -p "Term #> " Selection
        fi
        #lower case the input
        Selection=$(echo $Selection | tr [:upper:] [:lower:])
        #get the first character of the user input
        SelectionFirstCharacter=$(echo $Selection | cut -c 1)
        #option to change mode to terminate
        if [[ $SelectionFirstCharacter == "t" ]]; then
            #Change to terminate mode
            echo $(ColorPrint "Terminate Mode" $Green)
            Mode='t'
            continue
        fi
        if [[ $SelectionFirstCharacter == "k" ]]; then
            #Change to kill mode
            echo $(ColorPrint "Kill Mode" $Green)
            Mode='k'
            continue
        fi
        #option q to quit
        if [[ $SelectionFirstCharacter == "q" ]]; then
            echo $(ColorPrint "Quiting" $Green)
            return 0
        fi
        if [[ $SelectionFirstCharacter == "r" ]]; then
            #Refresh or restart everything
            #Update the system memory state
            UpdateSystemMemoryState
            #Print the system memory state
            PrintSystemMemoryStatus
            #Options of processes that are over the threshold and can be terminated or killed
            Options=$(ps -eo user,pid,%mem,rss,stat,start,time,command --sort=-%mem | (sed -u 1q; awk -v TP=$AdjustedThresholdPercent '$3 > TP') | nl -v 0 | sed -e '0,/0/ s/0/#/')
            #Mode of t is terminate and k is kill
            Mode='t'
            #The total number of options not counting the header
            OptionsCount=$(($(echo "$Options" | wc -l) - 1))
            #Check if there are any options and if there is not then stop
            if [ $OptionsCount -eq $((0)) ]; then
                echo $(ColorPrint "Nothing meets the threshold to terminate" $Green)
                return 0
            fi
            #Echo status of options list and instuctions
            StatusOptions "$Options"
            continue
        fi
        #option a to kill or terminate all listed processes
        if [[ $SelectionFirstCharacter == "a" ]]; then
            if [ $Mode == 't' ]; then
                #Terminate all processes
                echo $(ColorPrint "Terminating All Processes" $Green)
                #Go through the whole process list
                for ((i=1;i<=OptionsCount;i++)); do
                    #Selected PID to terminate
                    ProcessID=$(echo "$Options" | awk -v S=$i '$1 == S {print $3}')
                    #Selected CMD to terminate
                    ProcessCMD=$(echo "$Options" | awk -v S=$i '$1 == S {print $9}')
                    #Telling user what is about to be terminated
                    echo $(ColorPrint "Terminating process #$i '$ProcessCMD' with PID: '$ProcessID'" $Green)
                    #Terminate process by ID
                    TerminatebyPID $ProcessID
                done
            elif [ $Mode == 'k' ]; then
                #Kill all processes
                echo $(ColorPrint "Killing All Processes" $Green)
                #Go through the whole process list
                for ((i=1;i<=OptionsCount;i++)); do
                    #Selected PID to kill
                    ProcessID=$(echo "$Options" | awk -v S=$i '$1 == S {print $3}')
                    #Selected CMD to kill
                    ProcessCMD=$(echo "$Options" | awk -v S=$i '$1 == S {print $9}')
                    #Telling user what is about to be killed
                    echo $(ColorPrint "Killing process #$i '$ProcessCMD' with PID: '$ProcessID'" $Green)
                    #Kill process by ID
                    KillbyPID $ProcessID
                done
            else
                #Default terminate all processes
                Mode='t'
                echo $(ColorPrint "Terminating All Processes" $Green)
                #Go through the whole process list
                for ((i=1;i<=OptionsCount;i++)); do
                    #Selected PID to terminate
                    ProcessID=$(echo "$Options" | awk -v S=$i '$1 == S {print $3}')
                    #Selected CMD to terminate
                    ProcessCMD=$(echo "$Options" | awk -v S=$i '$1 == S {print $9}')
                    #Telling user what is about to be terminated
                    echo $(ColorPrint "Terminating process #$i '$ProcessCMD' with PID: '$ProcessID'" $Green)
                    #Terminate process by ID
                    TerminatebyPID $ProcessID
                done
            fi
            return 0
        fi
        if [[ $SelectionFirstCharacter == "s" ]]; then
            #Echo status of options list and instuctions
            StatusOptions "$Options"
            continue
        fi
        #check if input is not empty and if it's found in the list of processes
        if [ -n "$Selection" ] && [ $(echo "$Options" | awk -v S=$Selection '$1 == S {print "Found"}' | grep -c "Found" > /dev/null 2>&1 ; echo $?) -eq "$((0))" ] 2>/dev/null ; then
            #Selected PID to terminate or kill
            ProcessID=$(echo "$Options" | awk -v S=$Selection '$1 == S {print $3}')
            #Selected CMD to terminate or kill
            ProcessCMD=$(echo "$Options" | awk -v S=$Selection '$1 == S {print $9}')
            #Terminate or kill selected process
            if [ $Mode == 't' ]; then
                #Telling user what is about to be terminated
                echo $(ColorPrint "Terminating process #$Selection '$ProcessCMD' with PID: '$ProcessID'" $Green)
                #Terminate process by ID
                TerminatebyPID $ProcessID
            elif [ $Mode == 'k' ]; then
                #Telling user what is about to be killed
                echo $(ColorPrint "Killing process #$Selection '$ProcessCMD' with PID: '$ProcessID'" $Green)
                #Kill process by ID
                KillbyPID $ProcessID
            else
                #Default terminate selected process
                Mode='t'
                #Telling user what is about to be terminated
                echo $(ColorPrint "Terminating process #$Selection '$ProcessCMD' with PID: '$ProcessID'" $Green)
                #Terminate process by ID
                TerminatebyPID $ProcessID
            fi
            #Remove terminated or killed option from list
            Options=$(echo "$Options" | awk -v S=$Selection '$1 != S {print}')
            #Update the total number of options not counting the header
            OptionsCount=$(($(echo "$Options" | wc -l) - 1))
        else
            #everything else is invalid input and warn the user
            echo $(ColorPrint "Input was invalid try again or enter q to quit" $Yellow)
        fi
    done
}



#main part of the script



#Update the system memory state
UpdateSystemMemoryState

#Print the system memory state
PrintSystemMemoryStatus

#Select the system processes to termination or kill
SelectInteractiveOptions

#Script exiting
echo $(ColorPrint "Script Successfully ran" $Green)
exit 0