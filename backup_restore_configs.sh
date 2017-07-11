#!/bin/bash
#set -x


RESTOREDIR="/tmp/restore"
CONFIGDIR="/tmp/configs"
ARCHIVEDIR="/opt/solr/configarchive"
EXTDIR="$ARCHIVEDIR/tmp/restore"
ARCHIVE="$ARCHIVEDIR/$(date +%m_%d_%Y_%H_%M_%S_$(uname -n)_config.tar)"
LASTARCHIVE=$(ls -rlt $ARCHIVEDIR | tail -1 | awk '{print $9}')
USER=
GROUP=
WHO=$(echo $(whoami))

function usage () {
	echo "USAGE"
	echo "$0 -b -r -t"
	echo "-b - Backup" 
	echo "-r - Restore from last archive"
	echo "-t "archive name" - Restore from the given archive"
}

	if [[ $WHO != "root" ]]
		then
		echo "Run script as root, exiting.."
		exit 1
	fi

case $1 in 

-b)


	if [[ ! -d $ARCHIVEDIR ]]
		then
		mkdir -p $ARCHIVEDIR
		chown $USER:$GROUP $ARCHIVEDIR
	elif [[ -d $ARCHIVEDIR ]]
		then
		tar -cvf $ARCHIVE $RESTOREDIR

	fi

		

	for y in `find $CONFIGDIR -type d | sed  "s:$CONFIGDIR::g"`
	do 
		mkdir -p "$RESTOREDIR"$y
		chown $USER:$GROUP "$RESTOREDIR"$y 
	done

	for y in `find $CONFIGDIR -type f | sed  "s:$CONFIGDIR::g"`
	do
		cp -p $y "$RESTOREDIR""$y"
	done
	tar -cvf $ARCHIVE $RESTOREDIR
	chown $USER:$GROUP $ARCHIVE
	echo "Archive $ARCHIVE have been created."
	;;
-r)

	echo "Restoring"
	cd $ARCHIVEDIR
	tar -xvf $LASTARCHIVE
	service mongod stop
	service solr stop
	for y in `find $EXTDIR -type f | sed  "s:$EXTDIR::g"`
        do
               cp -p "$EXTDIR""$y" $y
        done
	rm -rf tmp
	service mongod start 
	service solr start 
	;;

-t*)
	if [[ $# -eq 2 ]]
		then
		LASTARCHIVE=$2
		if [[ -f $LASTARCHIVE ]]
			then
			service mongod stop
			service solr stop

			echo "Restoring $2"
        		cd $ARCHIVEDIR
        		tar -xvf $LASTARCHIVE
               		for y in `find $EXTDIR -type f | sed  "s:$EXTDIR::g"`
        		do
                		cp -p "$EXTDIR""$y" $y
        		done
			service mongod start
			service solr start
			rm -rf tmp
		else
			echo "$LASTARCHIVE dose not exist"
			exit 1
		fi
	else
		echo $(usage)
	fi

	;;

*) 
	echo "$(usage)"
	echo "No given parameter. Exiting.."
	exit 1
	;;
esac
