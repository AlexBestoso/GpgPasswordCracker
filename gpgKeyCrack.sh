#!/bin/bash 
# This script is used to help recover passwords used in gpg encrypted files.
# This script may require sudo privileges to utilize the required key pairs, though it can be modified to allow manual key entry.
# 
# To increase performance of processing large word lists. a temporary batch file is created. This is used to take a slice out of the main wordlist
# file so that the other commands used don't get hung when trying to read out single passwords.
#
# WARNING: This program WILL delete your wordlist file. So if it's important to you, ensure that you use a copy of your wordlist and not the actual one.
#

TARGET=$1
WORDLIST=$2
PASSWORD_BATCH=$3

if [ ${#TARGET} -ne 0 ]; then
	if test -f $TARGET; then
		echo "Target file found : '$TARGET'"
	else
		echo -en "No target selected\nUsage : $0 <encypted.gpg> <wordlist> [temporatyPasswordFile]\n"
		exit
	fi
else
	echo -en "No target selected\nUsage : $0 <encypted.gpg> <wordlist> [optional: wordlist.batch]\n"
        exit
fi

if [ ${#PASSWORD_BATCH} == 0 ]; then
	PASSWORD_BATCH="$WORDLIST.batch"
	echo "Automatic batch file selection : '$PASSWORD_BATCH'"
fi

if test -f $PASSWORD_BATCH; then
	Prep=$(wc -l < $PASSWORD_BATCH)
	if [ $Prep -gt 0 ]; then
		cat $PASSWORD_BATCH >> $WORDLIST
		rm $PASSWORD_BATCH
		echo "Restored unprocessed password batch."
	else 
		echo "Fresh run, password batch not restored."
	fi
fi

STR=$(head -n 1 $WORDLIST)
SIZE=${#STR}
MAX=100000
MAXDEL="1,${MAX}d"

while [ "$SIZE" != "0" ]
do
	echo "Gathering batch of passwords..."
	head -n $MAX $WORDLIST > $PASSWORD_BATCH
	PASSES=$(cat $PASSWORD_BATCH)
	THING="/"

	echo -en "\rRemoving batch from rainbow table...this may take a while\n"
	
	sed -i $MAXDEL $WORDLIST

	echo "cracking..."
	ITR=1
	OTHERITR=$(wc -l < $PASSWORD_BATCH)
	for PASS in $PASSES
	do
	
		sudo gpg --no-verbose --pinentry-mode loopback --batch --passphrase $PASS -d $TARGET 2>/dev/null
		if [ "$?" != "2" ];then
			echo Valid Password : $PASS
			exit
		elif [ "$THING" == "/" ];then
			echo -en "\r$THING $ITR / $OTHERITR                       "
			THING="-"
		elif [ "$THING" == "-" ];then
	                echo -en "\r$THING $ITR / $OTHERITR                       "
	                THING="\\"
		elif [ "$THING" == "\\" ];then
	                echo -en "\r$THING $ITR / $OTHERITR                       "
	                THING="|"
		else
			echo -en "\r$THING $ITR / $OTHERITR                       "
			THING="/"
		fi
		#if [ `echo "$ITR % 10" | bc ` -eq 9 ];then
		sed -i "1,1d" $PASSWORD_BATCH
		#fi
		ITR=$(($ITR+1))
		if [ $ITR -gt $OTHERITR ]; then
			break
		fi
	done

 	echo -en "\nRemaining $(wc -l $WORDLIST)"

	STR=$(head -n 1 $WORDLIST)
	SIZE=${#STR}
done
echo -en "\ndone\n"
rm $WORDLIST
rm $PASSWORD_BATCH
