#!/bin/bash
# script copyright 2006 Gene Heskett, License=GPLv2
# This script has two names as there is a softlink to it called "flush.sh"
# if it doesn't exist, please do an 
# ln -s backup.sh flush.sh
# This is the script that you run from your user amanda's crontab
# Either as backup.sh, or as flush.sh but that will usually be a hand operation.
# note, this must be run as the backup user, root=illegal
# since I'm always forgetting to su amanda...

if [ `whoami` != 'amanda' ] ; then
        echo
        echo "!!!!!!!!!!!!!!!!!!!! Warning !!!!!!!!!!!!!!!!!!!!!!"
        echo $0" needs to be executed by the user amanda,"
        echo $0" exiting."
        exit 1
fi
Cmdholdit="/opt/trinity/bin/dcop kmail KMailIface pauseBackgroundJobs"
Cmdresume="/opt/trinity/bin/dcop kmail KMailIface resumeBackgroundJobs"
PATH=/usr/local/sbin:/GenesAmandaHelper-0.61/:/bin:/usr/bin
export PATH
echo PATH=$PATH
$Cmdholdit
# a shell wrapper for amdump
echo $0 is being started with argument $1

# a quicker missing config exit
if [[ $# -lt 1 ]] ; then
	echo This script needs a valid config name as an argument, its missing
	exit 1
fi

# source gene.conf
. /GenesAmandaHelper-0.61/gene.conf
echo "35 MYDIR="$MYDIR
echo "36 AM_SBIN_DIR="$AM_SBIN_DIR
echo "37 DUMMY="$DUMMY
echo "38 PERFORM="$PERFORM
echo "39 BASE_CONFPATH="$BASE_CONFPATH
INDICE_PATH=$INDICE_PATH/$1
echo "36 indice_path="$INDICE_PATH
TAPELIST=$BASE_CONFPATH/$1/tapelist
echo "43 TAPELIST="$TAPELIST
echo "44 RUN_AMVERIFY="$RUN_AMVERIFY
echo "45 VTAPES="$VTAPES
echo "46 VTAPE_LOCATION="$VTAPE_LOCATION
echo "47 LOGpath="$LOG
LOG=$LOG"log4gene"
echo "449LOG="$LOG
date=`date +"%d/%m/%y %H:%M:%S"`
echo "51 $0 started on $date with arg $*" > $LOG

# Get the config name from command line arg #1,
# just like all other am* commands. Also handle host & disk
# args and pass to amcheck and amdump

if [ $# -lt 1 ] ; then
	echo "58 The amanda configuration MUST be the first argument to this script"
	exit 1
else
	CONFIGNAME=$1
	CONFPATH=$BASE_CONFPATH/${CONFIGNAME}
	echo "63 CONFPATH="$CONFPATH > $LOG
	HOST=""
	DLE=""
fi

if [ $# -gt 1 ] ; then
	HOST="$2"
fi
echo  "71 HOST="$HOST >> $LOG
if [ $# -gt 2 ] ; then
	DLE="$3"
fi
echo "75 DLE="$DLE >> $LOG
# temp, check data so far

echo "First put the tapelist in order with a run of amcheck" >> $LOG
echo "79 running ${AM_SBIN_DIR}/amcheck $CONFIGNAME $HOST $DLE" >> $LOG
${AM_SBIN_DIR}/amcheck $CONFIGNAME $HOST $DLE >> $LOG
echo "line 81 Back in "$0" - and the lists should be sane" >> $LOG
if [ -f $TAPELIST ] ; then
        read TAPEDATE TAPENAME TAPESTATUS junk < $TAPELIST
	TAPENUM=${TAPENAME##*-}
        echo "line 85 "$0" TAPENUM from TAPELIST = "$TAPENUM >> $LOG
fi

# Now get runtapes and tapecycle from amanda.conf
STRI=""
RUNTAPES=""
while [[ $STRI != "runtapes" ]] ; do
	read STRI FIRSTVAR junk
	if [[ $STRI == "runtapes" ]] ; then
		RUNTAPES=$FIRSTVAR
	fi
	if [[ $STRI == "tapecycle" ]] ; then
        TAPECYCLE=$FIRSTVAR
     fi
done < $CONFPATH/amanda.conf

echo "101 TAPECYCLE="$TAPECYCLE >> $LOG
echo "102 RUNTAPES="$RUNTAPES >> $LOG
# if I ever go back to runtapes > 1, get tapecycle too!  Use the same method.
# Or, modify this one since runtapes is below tapecycle, it would go by

# enable this for tape
#echo amanda's chg-scsi cannot rewind tape so we are using mt
#/bin/mt -f /dev/nst0 rewind

# now, if just testing the script, get out
if [[ $DUMMY == "1" ]] ; then
	echo "112 exiting from dummy check" >> $LOG
	exit 1;
fi

echo "116 This script is being run as "$0 >> $LOG
echo "117 "$0 >>$LOG
# next fails for 2nd check, why
echo "119 "${MYDIR}"backup.sh" >> $LOG 

if [ $0 == "./backup.sh" ] || [ $0 == "${MYDIR}backup.sh" ] || [ $0 == "backup.sh" ] ; then
	echo "122 running "${AM_SBIN_DIR}/"amdump "$CONFIGNAME $HOST $DLE >> $LOG
	${AM_SBIN_DIR}/amdump $CONFIGNAME $HOST $DLE >> $LOG
	SCS=$?
	echo ${AM_SBIN_DIR}"/amdump "$CONFIGNAME $HOST $DLE" returned "$SCS >>$LOG
	if [[ $SCS -ne "0" ]] ; then
# according to the info page, any error is "probably a 2" return.  Dumb, fucking dumb.  Real fucking dumb even.
# so apparently a file that got changed in the users maildir is an error.  Its gonna happen, just ignore it.
		if [[ $SCS -gt "2" ]] ; then
			echo "amdump THINKS it or tar failed for some reason, see the $LOG file." |tee -a $LOG
		fi
# but, a non-zero return should not stop the indices and configs packing and saveing IMNSHO
# so go ahead and just do it, right or wrong, its better than nothing...  Grrrrr.  Did I mention its DUMB ?
	fi
# Now, let everything flush
	sleep 10;

# Now, I've found that the tapelist is NOT updated by amcheck! Only amdump. Cute it is not.  So...
	if [ -f $TAPELIST ] ; then
        	read TAPEDATE TAPENAME TAPESTATUS junk < $TAPELIST
        	TAPENUM=${TAPENAME##*-}
        	echo "142 "$0" TAPENUM from "$TAPELIST" after amdump = "$TAPENUM >> $LOG
	fi

	# then append the indices and configs
	echo "$0 146 running bak-indices-configs "$CONFIGNAME $TAPENUM >> $LOG
	$MYDIR/bak-indices-configs $CONFIGNAME $TAPENUM >> $LOG
	SCS=$?
	echo $MYDIR/bak-indices-configs $CONFIGNAM $TAPENUM returned $SCS >> $LOG

	if [ $SCS -gt 0 ] ; then
		echo "FAILED TO WRITE THE AMANDA CONFIGURATION AND INDEXES TO THE END OF THE BACKUP !" | tee -a $LOG
		echo "Check your amanda status email to see if the backup itself was ok, but it does" | tee -a $LOG
		echo "not have the information to permit a bare metal recovery on the tape." | tee -a $LOG
		echo "Please check $LOG to see why." | tee -a $LOG
		exit 1
	fi

	PERFORM=1
	echo "bak-indices-configs is done and completed successfully." >> $LOG
fi
$Cmdresume
# or are we running as flush.sh

if [ $0 == "./flush.sh" ] || [ $0 == "${MYDIR}flush.sh" ] || [ $0 == "flush.sh" ]; then
	# we don't want amflush to disconnect or ask questions
	if [ "`/bin/ls /usr/dumps`" = "" ] ; then
        	echo "flush-indices-configs is done and completed successfully." | tee -a >> $LOG
		PERFORM=1
	else
		echo "Backup script running amflush -bf $CONFIGNAME " |tee -a >> $LOG

		# below required for real tapes if using chg-scsi
		# echo amanda cannot rewind, so mt to the rescue
		# /bin/mt -f /dev/nst0 rewind;
		# let the drive settle after the rewind
		# sleep 15;
		${AM_SBIN_DIR}/amflush -bf $CONFIGNAME | tee -a >> $LOG
		NUMFILES=$?
		# give the drive time to flush its buffers
		sleep 10;
		echo "flush of ${NUMFILES} files complete, appending index and config files" | tee -a >> $LOG

		# IF VTAPES=1 then chg-disk-slot now points at the tape amdump will try to use.
		# But, amanda's new changers don't use that file anymore!  Find new method
		if [ -f $TAPELIST ] ; then
		        read TAPEDATE TAPENAME TAPESTATUS junk < $TAPELIST
		        TAPENUM=${TAPENAME##*-}
		        echo line 181 $0 TAPENUM from $TAPELIST = $TAPENUM >> $LOG
		fi
		$MYDIR/flush-indices-configs $CONFIGNAME $TAPENUM | tee -a >> $LOG
		if [ $? -gt 0 ] ; then
			echo "FAILED TO WRITE THE AMANDA CONFIGURATION AND INDEXES TO THE END OF THE BACKUP !" | tee -a >> $LOG
			echo "Check your amanda status email to see if the backup itself was ok," | tee -a $LOG
			echo "but it does not have the information to permit a bare metal recovery on the tape." | tee -a >> $LOG
			echo "Please check $LOG to see why." | tee -a $LOG
			exit 1
		fi
	fi
fi

# sleep for disk sync
sleep 6

# now, were we successfull?
if [ $PERFORM == 0 ]; then
	echo "Something went wrong, the backup or flush was not done." | tee -a >> $LOG
	exit 1
fi

# Now, this is why we saved $TAPENUM and $RUNTAPES
# And please note that you will get 2 emails from this piece,
# one from this script while amverify is running, and another,
# seperate one from amverify itself, and I don't know how to
# fix that.
# The calling syntax for amverify is:
# amverify configname [[starting-slot] [num-slots]]

if [ $RUN_AMVERIFY -eq 1 ] ; then
	echo "Now we run amcheckdump starting it on the first tape or vtape used" >> $LOG
	echo "Running ${AM_SBIN_DIR}/amcheckdump $CONFIGNAME $TAPENUM $RUNTAPES" >> $LOG
	${AM_SBIN_DIR}/amcheckdump $CONFIGNAME $TAPENUM $RUNTAPES >> $LOG
	echo "$0 is done, exiting" >> $LOG
else
	echo "amcheckdump run is disabled by gene.conf config." >> $LOG
fi
df |grep /amandatapes >> $LOG
exit 0

