#!/bin/sh
# Usage: rsync-time-backup.sh <src> <dst> <label>
# cf.
# https://netfuture.ch/2013/08/simple-versioned-timemachine-like-backup-using-rsync/
# https://github.com/samdoran/rsync-time-machine
# and of course : https://github.com/bit-team/backintime

if [ "$#" -ne 3 ]; then
    echo "$0: Expected 3 arguments, received $#: $@" >&2
    exit 1
fi

APPNAME=$(basename $0 | sed "s/\.sh$//")
DST="$2"
SRC="$1"
NAME="$3"
DATE=$(date "+%Y-%m-%d-%H%M%S")
IN_PROGRESS="__backup_in_progress"
LATEST="__latest_backup"
INPROGRESS_FILE_NAME="backup.inprogress"
INPROGRESS_FILE="$DST/$IN_PROGRESS/$INPROGRESS_FILE_NAME"
MYPID="$$"

# -----------------------------------------------------------------------------
# Make sure everything really stops when CTRL+C is pressed
# -----------------------------------------------------------------------------

fn_terminate_script() {
	echo "SIGINT caught."
	exit 1
}

trap 'fn_terminate_script' SIGINT


fn_run_cmd() {
	if [ -n "$SSH_CMD" ]
	then
		eval "$SSH_CMD '$1'"
	else
		eval $1
	fi
}

fn_find() {
	fn_run_cmd "find '$1'"  2>/dev/null
}

# If the directory for an ongoing backup exists
if [ -d "$DST/$IN_PROGRESS" ]; then
	# we check if we can see a pid file and verify if the backup is still running here
	if [ -n "$(fn_find "$INPROGRESS_FILE")" ]; then
		RUNNINGPID="$(fn_run_cmd "cat $INPROGRESS_FILE")"
		if [ "$RUNNINGPID" = "$(ps -A -o pid,cmd|grep "$APPNAME" | grep -v grep |head -n 1 | awk '{print $SRC}' )" ]; then
			echo "Previous backup task is still active - aborting."
			exit 1
		fi
		echo "$INPROGRESS_FILE already exists - the previous backup failed or was interrupted. Backup will resume from there."
	fi
else
	echo "create the temp directory for the backup"
	fn_run_cmd "mkdir -v -- $DST/$IN_PROGRESS"
fi

# If we are here : the dir IN_PROGRESS is ready and there is not another backup running in it
fn_run_cmd "echo $MYPID > $INPROGRESS_FILE"

echo "Go on for rsync"
if [ -d "$DST/$LATEST" ]; then
	# We rsync the source with IN_PROGRESS hardlinking LATEST unchanged files
	rsync -aPSc --delete --timeout 1600 --link-dest="$DST/$LATEST" "$SRC" "$DST/$IN_PROGRESS"
else
	# We go for a first basic rsync since there is no LATEST directory yet
	rsync -aPSc --timeout 1600 "$SRC" "$DST/$IN_PROGRESS"
fi

# If a dest file already exist with the same name we append a timestamp to the name
if [ -d "$DST/$NAME" ]; then
	NAME="$NAME---$DATE"
fi

# We rename IN_PROGRESS with te choosen name
fn_run_cmd "mv -- $DST/$IN_PROGRESS $DST/$NAME"

# then remove the pid file
fn_run_cmd "rm -fv $DST/$NAME/$INPROGRESS_FILE_NAME"

# The new latest backup is the one we just have done
if [ -d "$DST/$LATEST" ]; then
	fn_run_cmd "rm -fv $DST/$LATEST"
fi
fn_run_cmd "ln -svr $DST/$NAME $DST/$LATEST"

echo "$APPNAME DONE! It began at $DATE. Current is $(date +%Y-%m-%d-%H%M%S)"
exit 1