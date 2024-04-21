#!/bin/bash
NEW_MAIL=/home/pi/mail
RECEIVED_PHOTOS=~/Desktop/Received_Photos
mailbox=/home/pi/mail/mailbox

## Create a place to save photos
if test -d "$RECEIVED_PHOTOS"; then
	echo "$RECEIVED_PHOTOS already exists"
else
	echo "Creating $RECEIVED_PHOTOS"
	mkdir $RECEIVED_PHOTOS
fi

## to include the year:  $(date +"%Y-%m-%dT%H%M%S")
NOW=$(date +"%m-%d_%H%M%S")

##Download new emails since the last check
echo "Checking for new messages at $NOW..."

cd $NEW_MAIL

# Retrieve the email from the server
fetchmail

#Just stop if there is no new mail
if [ $? -eq 1 ]; then
	exit 1
else
	# Extract the messages from the mbox spool
	cat $mailbox | formail -ds sh -c 'cat > "$FILENO.msg"'


	EMAILCOUNT=`ls -1 $NEW_MAIL/*.msg 2>/dev/null | wc -l`
	echo "There are $EMAILCOUNT new messages."

	for message in $NEW_MAIL/*.msg; do

		## Get sender's name and email address, remove weird characters and spaces
		#echo "Get sender's name and email, sanitize filename"
		sender=$(cat $message | formail -x From:| sed 's/[<>]//g' | sed 's/ /_/g' | sed 's/^_\(.*\)/\1/')

		echo "Sanitized sender name is $sender"

#		echo "Processing $file"
		tempdir="temp-$sender-$NOW"

		## Create a temporary dir
		if test -d "$NEW_MAIL/$tempdir"; then
			echo "$tempdir already exists"
		else
			echo "Creating $tempdir"
			mkdir $tempdir
		fi

		## Save atttachments in the temp dir
		ripmime -i $message -d $tempdir

		#Check if there's already a folder for this sender
		if test -d "$RECEIVED_PHOTOS/$sender"; then
			echo "$RECEIVED_PHOTOS/$sender exists"
		else
			# If not, make one
			echo "Making $RECEIVED_PHOTOS/$sender"
			mkdir $RECEIVED_PHOTOS/$sender
		fi


		## Process attachments
		for attachment in $tempdir/*; do

			# Get the filename without the path
			filename=$(basename -- "$attachment")

			# build the new filename
			NEWNAME=${filename%.*}"$sender""_$NOW."${attachment##*.}

			# Check if the file is an image
			file --mime-type $attachment |grep image

			# If is image, rename and copy to $RECEIVED_PHOTOS
			if [ $? -eq 0 ]; then

				# Check if the file already exists
				if test -f "$RECEIVED_PHOTOS/$sender/$NEWNAME"; then
					echo "$NEWNAME already exists in $RECEIVED_PHOTOS/$sender. Skipping."
				else

					# Fix image rotation
					exifautotran $attachment

					#If the file doesn't exist, copy it to $RECEIVED_PHOTOS with its new name
					cp $attachment $RECEIVED_PHOTOS/$sender/$NEWNAME

				fi
			fi

		done

		## Delete the temp folder
#		echo "Deleting $tempdir"
		rm -r $tempdir

		##Delete the email message file
#		echo "Deleting $message"
		rm $message

	done

		## Delete the mailbox (will take up too much space otherwise)
#		echo "Deleting the downloaded mailbox"
		rm $mailbox
		echo "END"
fi
