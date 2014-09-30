# Photo Management Utilities

A set of utilities to easily get photos and videos off of all your devices (cameras, photes, etc.), onto your computer, filtered, sorted by date, and backed up.

The idea is that you run import-photos.sh for each of your source devices (or even your Downloads folder!) to consolidate everything in one place for later sorting, then run sort-photos.sh on the whole batch to remove the junk and sort them by date. Finally, backup-photos.sh will back up the photos to another machine via rsync+ssh or to Amazon S3, but that is a work in progress.

## import-photos.sh

Imports photos (and video!) from a given source. All photos will be put in the root of the target-dir regardless of any directory hierarchy in the source-dir. Files with duplicate names will be renamed while preserving the file extension (e.g. photo.jpg photo-1.jpg photo-2.jpg).

### Usage:

	import-photos.sh [-d device -m mount-point [-u true|false]] -s source-directory -t target-directory

### Options

	-d | --device
	(Optional) The device to mount. Use "mtp" to mount an mtp device (e.g. an Android device).

	-m | --mount-point
	(Optional) The mountpoint for the device specified by -d.

	-u | --use-sudo
	(Optional) Whether sudo is required for mounting the device specified by -d. The device will be mounted for the current user with a 0022 umask.

	-s | --source-dir
	(Required) The directory to import photos and videos from. Should include the mount point if -d and -m are used.

	-t | --target-dir
	(Required) The directory to import photos to. Will be created if it doesn't exist.

### Examples

Import media from an Android phone into a temporary staging directory:

	import-photos.sh -d mtp -m /media/android -s /media/android/DCIM -t /tmp/unsorted-photos

Import media from an SD card using sudo:

	import-photos.sh -d /dev/sdc1 -m /media/sd-card -s /media/sd-card/DCIM -t /tmp/unsorted-photos

Import photos downloaded from the web:

	import-photos.sh -s /home/user/Downloads/photos -t /tmp/unsorted-photos

### Testing

Run `test/test-import-photos.sh` to test the import script. View the contents of `test/test-data` to see what happened.

## pick-photos.sh

Uses `feh` to allow the user to select photos to keep. Photos saved with `s` will be moved to the "favorites-dir," if specified. All photos that were not "delete" with `d` will be copied to target-dir.  After photos are reviewed with `feh`, the script plays each video file in `vlc` and prompts the user to keep or discard it. Kept videos are added to the list of files to move to target-dir.  After all selected favorites are copied to favorites-dir and all non-rejected photos are moved to target-dir, source-dir is trashed.

### Usage

	pick-photos.sh -s source-dir -t target-dir -f favorites-dir

### Options

	-s | --source-dir
	(Required) The directory containing photos to be sorted.

	-t | --target-dir
	(Required) The directory to sort photos into.

	-f | --favorites-dir
	(Optional) Photos saved from `feh` using the `s` key are copied to this directory.

### Example

	pick-photos.sh -s /tmp/unsorted-photos -t /home/user/photos -f /home/user/.desktop-slideshow

### Testing

Run `test/test-pick-photos.sh` or `test/test-pick-photos-no-delete.sh` to test picking photos. This test is interactive.

## sort-photos.sh

This script uses `exiftool` to sort all media from source-dir into folders by year and month in target-dir. Folder names are in the format "yyyy-mm". Uses CreateDate metadata, or FileModifyDate if CreateDate is unavailable.

### Usage

	sort-photos.sh -s source-dir -t target-dir

### Options

	-s | --source-dir
	(Required) The directory containing photos to be sorted.

	-t | --target-dir
	(Required) The directory to sort photos into.

### Example

	sort-photos.sh -s /tmp/unsorted-photos -t /home/user/photos

### Testing

Run `test/test-sort-photos.sh` to test sorting photos. View the contents of `test/test-data` to see what happened.

## backup-photos.sh

This is a stub script that doesn't do anything for now. Eventually it will facilitate rsync (over ssh) and s3 backups.
