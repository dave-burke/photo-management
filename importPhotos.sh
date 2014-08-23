#!/bin/bash

tmpPhotoDir=/tmp/photos
targetPhotoDir=~/photos
if [ $# -eq 0 ]; then
	echo You must specify either "dave" "suz" or "cam"
	exit 1
elif [ $1 == "dave" -o $1 == "-d" ]; then
	echo "Backing up Dave's cell"
	device=mtp
	mountPoint=/media/android
	srcPhotoDir=${mountPoint}/Card/DCIM
#	backupDir=/sharedisk/backups/daveCell
elif [ $1 == "suz" -o $1 == "-s" ]; then
	echo "Backing up Suz's cell"
	device=mtp
	mountPoint=/media/android
	srcPhotoDir=${mountPoint}/DCIM
#	backupDir=/sharedisk/backups/suzCell
elif [ $1 == "cam" -o $1 == "-c" ]; then
	echo "Backing up camera"
	device=/dev/disk/by-label/CAMERA
	mountPoint=/media/cam
	srcPhotoDir=${mountPoint}/DCIM
fi

#********************MOUNT THE DEVICE********************
if [ ! -d "${srcPhotoDir}" ]; then #only mount if it's not already done
	if [ ${device} == "mtp" ]; then
		simple-mtpfs ${mountPoint}
	else
		if [ ! -b ${device} ]; then
			echo "Can't find a device at ${device}"
			exit 1
		fi
		mount -v "${device}"
	fi
fi

#********************VERIFY THE PHOTO SOURCE DIRECTORY********************
if [ ! -d "${srcPhotoDir}" ]; then
	echo "Couldn't find source photo directory on device: ${srcPhotoDir}"
	exit 1
fi

#********************CREATE PHOTO DIRECTORY********************
if [ ! -d "${tmpPhotoDir}" ]; then
	mkdir -v "${tmpPhotoDir}"
	if [ ! -d "${tmpPhotoDir}" ]; then
		echo "Couldn't make directory at ${tmpPhotoDir}"
		exit 1
	fi
else
	echo ${tmpPhotoDir} already exists.
fi

#********************COPY AND VERIFY THE PHOTOS********************
echo Copying photos...
rsync -av -h --progress --exclude="cache" "${srcPhotoDir}/" "${tmpPhotoDir}"
if [ $? -eq 0 ]; then
	echo "Success!"
	if hash kioclient >/dev/null; then
		echo "Trashing files"
		kioclient move "${srcPhotoDir}" trash:/
	else
		echo Okay to delete source?
		read isOk
		if [ $isOk == "yes" ]; then
			rm -rfv "${srcPhotoDir}"
		else
			echo "Did not delete source directory ${srcPhotoDir}"
		fi
	fi
else
	echo "Failed to sync photos!"
	exit 1
fi

#********************Organize photos*********************
echo Sorting photos...
exiftool -ext '*' --ext CTG '-Directory<CreateDate' -d ${targetPhotoDir}/%Y-%m -r ${tmpPhotoDir}
if [ $? -eq 0 ]; then
	echo "Success!"
	if hash kioclient >/dev/null; then
		echo "Trashing files"
		kioclient move "${tmpPhotoDir}" trash:/
	else
		echo Okay to delete tmp dir?
		read isOk
		if [ $isOk == "yes" ]; then
			rm -rfv "${tmpPhotoDir}"
		else
			echo "Did not delete source directory ${tmpPhotoDir}"
		fi
	fi
else
	echo "Failed to sort photos!"
	exit 1
fi

#********************BACKUP THE DEVICE********************
if [ "${backupDir}" == "" ]; then
	echo "No backupDir specified"
else
	if [ ! -d ${backupDir} ]; then
		echo "Can't find a backup dir at ${backupDir}"
		exit 1
	else
		echo "Backing up device..."
		rdiff-backup -v4 --exclude "${mountPoint}/Movies" --exclude "${mountPoint}/Music" "${mountPoint}" "${backupDir}"
	fi
fi

#********************UNMOUNT THE DEVICE********************
sync ; sleep 2
if [ ${device} == "mtp" ]; then
	fusermount -u "${mountPoint}"
else
	umount -v "${mountPoint}"
fi

echo Done!
