#!/bin/bash
NEW_MAIL=/home/dave/.getmail/Mailbox/new
RECEIVED_PHOTOS=/home/dave/Desktop/RECEIVED_PHOTOS

echo "START"
## to include the year:  $(date +"%Y-%m-%dT%H%M%S")
NOW=$(date +"%m-%dT%H%M%S")
		
##Download new emails since the last check
echo "Checking for new messages at $NOW..."

cd $NEW_MAIL

getmail
EMAILCOUNT=`ls -1 $NEW_MAIL/*.pi 2>/dev/null | wc -l`

if [ $EMAILCOUNT == 0 ]
then
	echo "There are no new emails."
	echo "END"
	exit 0

else
	echo "There are $EMAILCOUNT new messages."
	echo "Processing new emails..."
		
	for message in $NEW_MAIL/*.pi; do
		echo "Processing $file"
		tempdir=temp-$NOW

		## Get sender's name and email address, remove weird characters and spaces
		sender=$(cat $message | formail -x From:| sed 's/[<>]//g' | sed 's/ /_/g') 

		## Create a temporary dir
		echo "Creating $tempdir"
		mkdir $tempdir

		## Save atttachments in the temp dir
		ripmime -i $message -d $tempdir

		## Process attachments
		for attachment in $tempdir/*; do

			# Get the filename without the path
			filename=$(basename -- "$attachment")
			
			# Check if the file is an image
			file --mime-type $attachment |grep image

			# If is image, rename and copy to $RECEIVED_PHOTOS
			if [ $? -eq 0 ]
			then
				cp $attachment $RECEIVED_PHOTOS/${filename%.*}"$sender""_$now."${attachment##*.};
			fi

		done

		## Delete the temp folder
		echo "Deleting $tempdir"
		rm -r $tempdir
	
		##Delete the email message file
		echo "Deleting $message"
		rm $message
		echo "END"
	done
fi
