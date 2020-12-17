#!/bin/bash
# this script is called by backup.sh (flush.sh too) to append the
# current indices and configs in effect at the time amdump was last run
# affording a good chance of being able to do a bare metal recovery
# somewhat less painfully than they normally are.
# script Copyright 2006 Gene Heskett, license=GPLv2

# Read config 
. /GenesAmandaHelper-0.61/gene.conf

PATH=/bin:/usr/local/sbin:/usr/bin
#INDICE_PATH=$INDICE_PATH/$1
echo INDICE_PATH in bak-indice-configs now=$INDICE_PATH
# 2010/09 recently amanda has stopped using the 'data' link as a pointer to the right 'tape', so...
#if [ $# -ne 1 ] ; then
if [ $# -ne 2 ] ; then
	echo "The amanda configuration MUST be the first argument to this script"
	echo "And the TAPENUM must be the 2nd argument to this script"
	exit 1
else
	CONFIGNAME=$1
	CONFPATH=$BASE_CONFPATH/${CONFIGNAME}
	TAPENUM=$2
	DATALOC="slot"$TAPENUM
	echo "Line 24 DATALOC="$DATALOC
fi


# this is an attempt to derive the tape number for a rewrite of the archiving now done
# Change this hard coded path to whatever you are using for this particular cache, it does NOT
# go into your disklist!

#temp stuff these two
if [ $DUMMY -eq 1 ] ; then
	echo "$0 started, mydir=$MYDIR config=$1 CONFPATH=${CONFPATH}" 
fi

if [[ -d $MYDIR'/config-bak' ]] ; then
	cd $MYDIR/config-bak
else
	echo "ERROR: the data dir $MYDIR/config-bak does not exist"
	exit 2
fi

# now get the final tape from the tapelist
# likewise, change this to your real path
TAPELIST=$CONFPATH/tapelist

#temp stuff
echo "Tapelist file to be used TAPELIST=${TAPELIST}"

# strip the tapename and tapenumber out of the string
if [ -f $TAPELIST ] ; then
	read TAPEDATE TAPENAME TAPESTATUS junk < $TAPELIST
	TAPENUM=${TAPENAME##*-}
	echo "tapename=$TAPENAME, tapenum=$TAPENUM"
fi

# keep track of the passes on the tapes, sort of.
# first, check to see if old style name exists and use it if it does
#if [ -f dd.report.$TAPENUM ] ; then
#        read TAPEUSECOUNT < dd.report.$TAPENUM
#	echo "Line 57 Tape use count obtained from dd.report.$TAPENUM = $TAPEUSECOUNT"
#fi

# now, if that bombed
#if [[ $TAPEUSECOUNT -eq "" ]] ; then
echo "getting tape usage count from dd.report.$TAPENAME"
if [ -f dd.report.$TAPENAME ]  ; then
	read TAPEUSECOUNT < dd.report.$TAPENAME
        echo "Line 71 Tape use count from dd.report.$TAPENAME = $TAPEUSECOUNT"
fi

echo "line 74 Tapeusecount is now="$TAPEUSECOUNT
# and if it still bombed out, reset the friggin count
if [[ $TAPEUSECOUNT -eq "" ]] ; then
	TAPEUSECOUNT=0
fi

# increment it
TAPEUSECOUNT=$(( TAPEUSECOUNT + 1 ))

#some troubelshooting echo's
echo "This tape "$TAPENAME" has now been used $TAPEUSECOUNT times" 

echo "INDICE_PATH=$INDICE_PATH, CONFPATH=$CONFPATH DATALOC=$DATALOC"

# now get rid of the data that was generated the last time this tape was used.
rm -f configuration.tar.$TAPENAME indices.tar.$TAPENAME dd.report.$TAPENAME
# this line can leave once all the stuff has been renamed else the tapenums are stuck in place!
rm -f configuration.tar.$TAPENUM indices.tar.$TAPENUM dd.report.$TAPENUM

# Lets see if its safe to write to the tape by generating a new dd.report.$TAPENAME
# and, so it gets into the email
touch dd.report.$TAPENAME

# Now set the tape use count as the first line of this refreshed file
echo "$TAPEUSECOUNT" >  dd.report.$TAPENAME

# and report the invocation name used to line 2 (wrong slot# passed)
echo "This script is being run as " $0 $* | tee -a dd.report.$TAPENAME

# and report the tapename being used this time on line 3
echo "using tape $TAPENAME" | tee -a dd.report.$TAPENAME

# if using real tapes AND chg-scsi, enable this next line
# Is this needed ?
# mt -f /dev/nst0 tell | tee -a dd.report.$TAPENAME

# if that worked, we should have a current one
if [ ! -s "dd.report."$TAPENAME ] ; then # -s for exists AND is non-zero length
	echo "dd.report."$TAPENAME" was not created or written to"
	exit 3
fi

echo "tar up the indices and configs directories as they exist now." >> dd.report.$TAPENAME 
echo "In bak-indices-configs DUMMY="$DUMMY >> dd.report.$TAPENAME
if [[ $DUMMY -ne 1 ]] ; then
#	tar -cpsf indices.tar.${TAPENAME} $INDICE_PATH  2>&1 >> dd.report.$TAPENAME
	tar -cpf indices.tar.${TAPENAME} $INDICE_PATH  2>&1 >> dd.report.$TAPENAME
#	tar -cpsf configuration.tar.${TAPENAME} $CONFPATH  2>&1 >> dd.report.$TAPENAME
	tar -cpf configuration.tar.${TAPENAME} $CONFPATH  2>&1 >> dd.report.$TAPENAME
else
	tar -cpsf indices.tar.${TAPENAME} $INDICE_PATH 
	tar -cpsf configuration.tar.${TAPENAME} $CONFPATH 
fi

# We've now generated the up2date indices & configs
# Figure out if the tape was written to using amstatus

PARTS_WRITTEN=`${AM_SBIN_DIR}/amstatus $CONFIGNAME | grep taped | awk -F: '{print $2}' | awk '{print $1}'`
# Ok, then lets make it part of the dd.report record
echo "Parts written = $PARTS_WRITTEN >> dd.report.$TAPENAME"

if [ $PARTS_WRITTEN -gt 0 ]; then
	if [ $DUMMY -eq 1 ] ; then
		echo "DUMMY="$DUMMY" indices.tar."$TAPENAME" not written"
		echo "DUMMY="$DUMMY" configuration.tar."$TAPENAME" not written" 
		exit 7 # we ought to replace this with a defined error code just to be neat.
	else 
		if [ $VTAPES -eq 1 ] ; then
			echo "Using a vtape, so copying the indices & configuration to the vtape data dir."
# Amanda has stopped using the link 'data' to point to the correct tape, breaking this script
#			rm -f ${VTAPE_LOCATION}/data/indices.tar # replace outdated file
			rm -f ${VTAPE_LOCATION}/$DATALOC/indices.tar # replace outdated file

#			cp indices.tar.$TAPENAME ${VTAPE_LOCATION}/data/indices.tar
			cp indices.tar.$TAPENAME ${VTAPE_LOCATION}/$DATALOC/indices.tar

			echo "Here are the contents of indices.tar" >> dd.report.$TAPENAME
#			tar tf ${VTAPE_LOCATION}/data/indices.tar >> dd.report.$TAPENAME
			tar tf ${VTAPE_LOCATION}/$DATALOC/indices.tar >> dd.report.$TAPENAME

#			rm -f ${VTAPE_LOCATION}/data/configuration.tar # replace outdated file
			rm -f ${VTAPE_LOCATION}/$DATALOC/configuration.tar # replace outdated file

#			cp configuration.tar.$TAPENAME ${VTAPE_LOCATION}/data/configuration.tar
			cp configuration.tar.$TAPENAME ${VTAPE_LOCATION}/$DATALOC/configuration.tar

			echo "And here is the contents of configuration.tar" >> dd.report.$TAPENAME
#			tar tf ${VTAPE_LOCATION}/data/configuration.tar >> dd.report.$TAPENAME
			tar tf ${VTAPE_LOCATION}/$DATALOC/configuration.tar >> dd.report.$TAPENAME
		else
			#Real tape
			echo "Using a real tape, so writing the indices & configuration using dd"

			# once for the file & once for value
			# due to the possibility of a double eof being written by amanda
			mt -f /dev/nst0 seod

			dd if=indices.tar.$TAPENAME of=/dev/nst0 bs=32768 conv=sync 2>&1 >> dd.report.$TAPENAME
			if [ $? -ne 0 ] ; then
				echo "dd command failed. Amanda configuration & indices not written to tape ! (tape 
full?)"
				exit 4
			fi
			echo "Here is the contents of indices.tar.$TAPENAME"
                        tar tf indices.tar.$TAPENAME >> dd.report.$TAPENAME

			dd if=configuration.tar.$TAPENAME of=/dev/nst0 bs=32768 conv=sync 2>&1 >> dd.report.$TAPENAME
			if [ $? -ne 0 ] ; then
				echo "dd command failed. Amanda configuration not written to tape ! (tape full?)"
				exit 5
			fi
			echo "And here is the contents of configuration.tar.$TAPENAME"
			tar tf configuration.tar.$TAPENAME >> dd.report.$TAPENAME
			mt -f /dev/nst0 weof 1
			echo "Rewinding tape"
			mt -f /dev/nst0 rewind
		fi
	fi

else
	echo $TAPENAME" was not written to as amstatus $CONFIGNAME reported it had not written any partitions to tape." | 
tee -a dd.report.$TAPENAME
	exit 6
fi

# with the above data, we can try to troubleshoot if it fubars.

echo "The script "$0" is finished." | tee -a dd.report.$TAPENAME
echo "Amandatapes usage="`df /amandatapes` |tee -a dd.report.$TAPENAME

# The file /amanda/bak-configs/dd.report.$TAPENAME might have enough info
# to allow troubleshooting if the proceedure blows up someplace.  One can
# always add more data outputs in the problem area... :-)
