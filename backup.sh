#!/bin/bash

function HelpInfo {
   	echo -e "Usage: $0 [OPTINS] [HINTS]\n"
   	echo -e "\x1b[1mINFO\e[0m"
   	echo -e "	This is an automatic backup system!"
   	echo -e "	\x1b[4mbackup name:\e[0m   backup-[y]-[m]-[d]--[h]-[m]-[s].tar.gz"
   	echo -e "	\x1b[4mchecksum name:\e[0m backup-[y]-[m]-[d]--[h]-[m]-[s].checksum\n"
   	echo -e "\x1b[1mOPTIONS\e[0m"
   	echo -e "	-h/--help  Output a usage message and exit."
   	echo -e "	-info      Output an info about developer.\n"
   	echo -e "\x1b[1mCHANGE SETTINGS\e[0m"
   	echo -e "	-c  \x1b[4mHINT\e[0m"
   	echo -e "		Use \x1b[4mHINT\e[0m to change following params."
   	echo -e "		Notice, \x1b[4mdon't forget\e[0m to use '\x1b[1m/\e[0m' at the"
   	echo -e "		end of directory name!"
   	echo -e "		  \x1b[33mbnum\e[0m - amount of valid backups"
   	echo -e "		  \x1b[33mext\e[0m  - file extension"
   	echo -e "		  \x1b[33min\e[0m   - input directory"
   	echo -e "		  \x1b[33mout\e[0m  - output directory"
   	echo -e "		  \x1b[33mall\e[0m    - all hints\n"   
   	echo -e "	-f  \x1b[4mHINT\e[0m"
   	echo -e "		Use \x1b[33mdel\e[0m to stop making backups frequently"
   	echo -e "		or use empty string to change timetable.\n"
}
function Description {
	echo -e "Th15 sh3ll cod3 m@d3 by \x1b[45mKirill Poltoradnev\e[0m\n"
}
function HelloProg {
	echo -e "Current backupmaster settings: \n"
	echo -e "	\x1b[4mBackup amount:\e[0m		$1"
	echo -e "	\x1b[4mInput:\e[0m			$2"
	echo -e "	\x1b[4mFile extension:\e[0m		$3"
	echo -e "	\x1b[4mOutput:\e[0m			$4 \n"
}

function MainEnterPoint {
	BACKUP_CONFIG="backup.config"

	AMOUNT_OF_BACKUPS=`cat $BACKUP_CONFIG | grep "AMOUNT_OF_BACKUPS" | cut -d '=' -f 2`
	BACKUP_PATH_INPUT=`cat $BACKUP_CONFIG | grep "BACKUP_PATH_INPUT" | cut -d '=' -f 2`
	FILE_EXTENSION=`cat $BACKUP_CONFIG | grep "FILE_EXTENSION" | cut -d '=' -f 2`
	BACKUP_PATH_OUTPUT=`cat $BACKUP_CONFIG | grep "BACKUP_PATH_OUTPUT" | cut -d '=' -f 2`

	if [[ $AMOUNT_OF_BACKUPS == "" || $BACKUP_PATH_INPUT == "" || $BACKUP_PATH_OUTPUT == "" || $FILE_EXTENSION == "" ]]; then
		echo -e "Error while read variables: Incorrect backup.config file"
		exit 0
	fi

	HelloProg $AMOUNT_OF_BACKUPS $BACKUP_PATH_INPUT $FILE_EXTENSION $BACKUP_PATH_OUTPUT

	MakeBackup $BACKUP_PATH_OUTPUT $BACKUP_PATH_INPUT $AMOUNT_OF_BACKUPS $FILE_EXTENSION

}
#============================================================================
# Make crontab job 
#============================================================================
function MakeTimeTable {
	echo -e "Time has to follow the structure:\n" 
	echo -e "	\x1b[1mminute\e[0m[0-59] \x1b[1mhour\e[0m[0-23] \x1b[1mday\e[0m[1-31] \x1b[1mmonth\e[0m[1-12]\n"
	read -p "Enter: " BACKUP_CRON_SET
	if [ "$1" == "del"];
		then crontab -r
		else echo "$BACKUP_CRON_SET bash backup.sh" | crontab -
	fi
}
#============================================================================
# Build backup and count checksum via sha256 
#============================================================================
function MakeBackup {
	CheckBackupNum $1 $3 $2
	OF="backup-$(date +%F--%H-%M-%S)"
	TDGT=$1
	if [ "$4" != "*" ];
		then BACKUPING_FILES=`ls | grep $4$`
		else BACKUPING_FILES=`ls`
	fi
	tar -czf $TDGT$OF".tar.gz" $BACKUPING_FILES
	cd $TDGT
	sha256sum $OF".tar.gz" | cut -d " " -f 1 > $OF".checksum"
	echo -e "\n	\x1b[4mBackup checksum:\e[0m	`cat $OF.checksum` \n"
}
#============================================================================
# Controle number of possible dumps
#============================================================================
function CheckBackupNum {
	cd $1
	FILE_COUNTER=0
	for f in `ls | grep ^backup- | grep .tar.gz$ | cut -d " " -f 9`; do 
		if [ $FILE_COUNTER == 0 ]; then 
			DUMP_FOR_REMOVE=$f
		fi
		((FILE_COUNTER++));
	done
	if (($FILE_COUNTER > $2-1)); then
		rm $DUMP_FOR_REMOVE
		rm `echo $DUMP_FOR_REMOVE | cut -f1 -d'.'`".checksum"
	fi
	cd $3
}
#============================================================================
#							Help [-h/--help]
#============================================================================
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
	HelpInfo
	exit 0
fi
#============================================================================
#							Info [-info]
#============================================================================
if [ "$1" == "-info" ]; then
	Description
	exit 0
fi
#============================================================================
#						StartMainScript  [ ]
#============================================================================
if [ "$1" == "" ]; then
	MainEnterPoint
	exit 0
fi
#============================================================================
#						Backup frequency  [-f]
#============================================================================
if [ "$1" == "-f" ]; then
	MakeTimeTable
	exit 0
fi
#============================================================================
#					Change settings  [-c] [HINTS]
#============================================================================
if [ "$1" == "-c" ]; then
	# Change all hints
	if [ "$2" == "all" ]; then
		read -p "Amount of backups:	" AMOUNT_OF_BACKUPS
		read -p "File extension:		" FILE_EXTENSION
		read -p "Input directory:	" BACKUP_PATH_INPUT
		read -p "Output directory:	" BACKUP_PATH_OUTPUT
	fi
	# Change amount of backup
	if [ "$2" == "bnum" ]; then
		read -p "Amount of backups:	" AMOUNT_OF_BACKUPS
	fi
	# Change file extensions
	if [ "$2" == "ext" ]; then
		read -p "File extension:		" FILE_EXTENSION
	fi
	# Change input dir
	if [ "$2" == "in" ]; then
		read -p "Input directory:	" BACKUP_PATH_INPUT
	fi
	# Change output dir
	if [ "$2" == "out" ]; then
		read -p "Output directory:	" BACKUP_PATH_OUTPUT
	fi
	echo -e "AMOUNT_OF_BACKUPS=$AMOUNT_OF_BACKUPS\nBACKUP_PATH_INPUT=$BACKUP_PATH_INPUT\nFILE_EXTENSION=$FILE_EXTENSION\nBACKUP_PATH_OUTPUT=$BACKUP_PATH_OUTPUT" > "backup.config"
	echo "Changes done! Restart scripy with no OPTIONS"
	exit 0
fi
#============================================================================
echo "No such command: $1"
exit 0

