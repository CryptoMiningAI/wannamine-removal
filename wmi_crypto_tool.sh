#!/bin/bash
WMIEXE_PATH="/home/monitoring"
PYTHON_PATH="/usr/bin"
REMOVED_LOG="/home/monitoring/v2/removed.log"
PINGKO_LOG="/home/monitoring/v2/pingko.log"
#CHECKPING = ping -c 3 $HOST

main()
{
for HOST in $(cat $HOST_LIST)
do
	if ping -c1 $HOST 1>/dev/null 2>/dev/null
	then
	echo "$HOST main"
	#First, we kill all running powershell process
	#/usr/bin/python /home/monitoring/wmiexec.py -debug user:XXXXXX@172.16.12.67 cmd /c "wmic /FAILFAST:OFF process where \"commandline like '%powershell.exe%'\" call terminate"
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py -debug ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /FAILFAST:ON process where \"commandline like '%powershell.exe%'\" call terminate"
	#Now we remove wmi entries
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py -debug ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __FilterToConsumerBinding where Consumer='CommandLineEventConsumer.Name=\"DSM Event Log Consumer\"' delete"
    	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py -debug ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __EventFilter where name=\"DSM Event Log Filter\" delete"
    	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py -debug ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH CommandLineEventConsumer where Name='DSM Event Log Consumer' delete"
    	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py -debug ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\default CLASS Win32_Services delete"
	echo "$HOST WMI REMOVAL ATTEMPTED AT $(date)" >>${REMOVED_LOG}
else 
#echo "$HOST is KO"	
	echo "$HOST is not responding - $(date)" >>${PINGKO_LOG}
fi
done
exit 0
}

check()
{
for HOST in $(cat $HOST_LIST)
do
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __FilterToConsumerBinding where Consumer='CommandLineEventConsumer.Name=\"DSM Event Log Consumer\"'" 
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __EventFilter where name=\"DSM Event Log Filter\""
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH CommandLineEventConsumer where Name='DSM Event Log Consumer'"
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\default CLASS Win32_Services"
done
exit 0
}

check_class()
{
echo
echo
echo "This will most likely generated a lot of output"
echo "Run with the '-c' option for a truncated version, using the filters from ESET"
echo
echo
for HOST in $(cat $HOST_LIST)
do
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __FilterToConsumerBinding"
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __EventFilter"
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH CommandLineEventConsumer"
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\default CLASS Win32_Services"
done
exit 0
}

subscription()
{
echo
echo
echo "This function checks the subscription namespace only - that is where the scheduled jobs reside."
echo "You will not see the payload from this check, as that resides in the default namespace"
echo
echo
for HOST in $(cat $HOST_LIST)
do
	${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __FilterToConsumerBinding"
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH __EventFilter"
        ${PYTHON_PATH}/python ${WMIEXE_PATH}/wmiexec.py ${USER}:${PASSWORD}@$HOST cmd.exe /c "wmic /NAMESPACE:\\\\root\\subscription PATH CommandLineEventConsumer"
done                                                                                                                                 
exit 0
}

usage()
{
	echo "Usage: ./removal_script_france.sh -l [HOST_LIST] -u [USERNAME] -p [PASSWORD] {-r|-c|-C|-S} [REMOVE WMI | CHECK FILTERED CONTENT |CHECK WHOLE CLASS CONTENT | CHECK SUBSCRIPTION NAMESPACE]"
	exit 1
}

while getopts 'l:u:p:rcCS' opt ; do
	case "${opt}" in
		l) HOST_LIST="$OPTARG" ;;
		u) USER="$OPTARG" ;;
		p) PASSWORD="$OPTARG" ;;
		r) GOSW=1 ;;
		c) CHECKSW=1 ;;
		C) CLASSSW=1 ;;
		S) SUBSW=1 ;;
	esac
done

if [ -z $HOST_LIST ] || [ -z $USER ] || [ -z $PASSWORD ]
then
	usage	
fi

if [ ! -z $GOSW ] && [ ! -z $CHECKSW ]
then
	echo "Please only use one of the -r or the -c options"
	usage
fi

if [[ $SUBSW == "1" ]] 
then
	subscription
fi

if [[ $CLASSSW == "1" ]]
then
	check_class
fi

if [[ $GOSW != "1" ]] && [[ $CHECKSW == "1" ]] 
then
	check
elif [[ $GOSW == "1" ]] && [[ $CHECKSW != "1" ]]
then
	main
else
	echo "Error of some sort"
	usage
fi


