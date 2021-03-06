#!/bin/sh

VERSION="0.01"

README="""
This is generated system info, generated by the sysinfo script on http://github.com/meghuizen/systeminfo

This helps developers to get complete Linux system information, so they could detect problems.

Just run this script and you get a directory structure and a tarball in a mktemp dir, which you can upload.

it has the following structure:
		/
		| proc/ - /proc dump (not complete dump, but specific parts)
		| sys/ - /sys dump (not complete dump, but specific parts)
		| kernel/ - kernel info
		| harddrivers/ - harddrive info
					 | sdX/ - harddrive info for this specific block device
					 	  | sys-queue/ - /sys/block/sdX/queue data. Used by the IO scheduler
		| README.txt - this explanation
		| SUMMARY.txt - the summary of the system generated on it

License: GPLv2
Website: http://github.com/meghuizen/systeminfo
Version: $VERSION
"""

DEBUG=0

### 1. Function declartions ###

showuser () {
	echo " * $1"
}

debug () {
	if [ "$DEBUG" -gt 0 ]; then
		echo "\t\t* $1"
	fi
}

readdir () {
	local CURRENTDIR="$1"
	local TARGETDIR="$2"
	
	mkdir -p "$TARGETDIR"
	debug "reading dir $CURRENTDIR with target dir $TARGETDIR"
	
	for FILE in `ls -1 "$CURRENTDIR"`; do
		if [ -d "$CURRENTDIR/$FILE" ]; then
			readdir "$CURRENTDIR/$FILE" "$TARGETDIR/$FILE"
		else
			if [ -f "$CURRENTDIR/$FILE" ] && [ -s "$CURRENTDIR/$FILE" ]; then
				#if [ "$FILE" != "kcore" ] && [ "$FILE" != "kmsg" ] && [ "$FILE" != "sysrq-trigger" ] && [ "$FILE" != "events" ]; then
				debug "  reading file $CURRENTDIR/$FILE"
				cat "$CURRENTDIR/$FILE" > "$TARGETDIR/$FILE.txt"
			fi
		fi
	done
}


### 2. Checks if program can be run ###

if [ ! -e `which hdparm` ]; then
    echo "Please install the package hdparm and be sure it's in your PATH"
    exit
fi

if [ "$(id -u)" != "0" ]; then
	echo "Sorry, you are not root."
	exit 1
fi

### 3. Main program ####

TMPDIR=`mktemp -d`
TMPLINDIR="linux-`uname -r`_`uname -m`-sysinfo"
WORKINGDIR="$TMPDIR/$TMPLINDIR"


echo "Using directory $WORKINGDIR as working directory."

showuser "Creating directory structure"
mkdir "$WORKINGDIR"
cd "$WORKINGDIR"

mkdir "$WORKINGDIR/hardwareinfo"
mkdir "$WORKINGDIR/kernel"
mkdir "$WORKINGDIR/proc"
mkdir "$WORKINGDIR/harddrives"

echo "$README" > "$WORKINGDIR/README.txt"

showuser "Getting hardware info"

lshw > "$WORKINGDIR/hardwareinfo/lshw.txt"
lspci > "$WORKINGDIR/hardwareinfo/lspci.txt"
lsusb > "$WORKINGDIR/hardwareinfo/lsusb.txt"
cat /proc/cpuinfo > "$WORKINGDIR/proc/cpuinfo.txt"
cat /proc/meminfo > "$WORKINGDIR/proc/meminfo.txt"


showuser "Getting harddrives info"

#I haven't found a secure way to detect all harddrives
for HDD in "`ls -1 /dev/sd[a-z] 2>/dev/null`"; do
	if [ -n "$HDD" ] && [ -e "$HDD" ]; then
		DRIVE="${HDD#/dev/}"
		debug "Scanning harddrive: $DRIVE [$HDD]"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/hardwareinfo/hdinfo-$DRIVE.txt"
		
		mkdir "$WORKINGDIR/harddrives/$DRIVE"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/info.txt"
		hdparm -tT "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-normal.txt"
		hdparm -tT --direct "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-directio.txt"
		
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/harddrives/$DRIVE/sys-queue"
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/sys/block/$DRIVE/queue"
	fi
done
for HDD in "`ls -1 /dev/hd[a-z] 2>/dev/null`"; do
	if [ -n "$HDD" ] && [ -e "$HDD" ]; then
		DRIVE="${HDD#/dev/}"
		debug "Scanning harddrive: $DRIVE [$HDD]"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/hardwareinfo/hdinfo-$DRIVE.txt"
		
		mkdir "$WORKINGDIR/harddrives/$DRIVE"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/info.txt"
		hdparm -tT "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-normal.txt"
		hdparm -tT --direct "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-directio.txt"
		
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/harddrives/$DRIVE/sys-queue"
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/sys/block/$DRIVE/queue"
	fi
done
for HDD in "`ls -1 /dev/md[a-z] 2>/dev/null`"; do
	if [ -n "$HDD" ] && [ -e "$HDD" ]; then
		DRIVE="${HDD#/dev/}"
		debug "Scanning harddrive: $DRIVE [$HDD]"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/hardwareinfo/hdinfo-$DRIVE.txt"
		
		mkdir "$WORKINGDIR/harddrives/$DRIVE"
		
		hdparm -iI "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/info.txt"
		hdparm -tT "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-normal.txt"
		hdparm -tT --direct "$HDD" > "$WORKINGDIR/harddrives/$DRIVE/hdparm-bench-directio.txt"
		
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/harddrives/$DRIVE/sys-queue"
		readdir "/sys/block/$DRIVE/queue" "$WORKINGDIR/sys/block/$DRIVE/queue"
	fi
done


showuser "Getting kernel info"

echo "uname -a: `uname -a`" > "$WORKINGDIR/kernel/version.txt"
echo "build: `cat /proc/version`" >> "$WORKINGDIR/kernel/version.txt"
cat /proc/cmdline > "$WORKINGDIR/kernel/cmdline.txt"
cat /proc/swaps > "$WORKINGDIR/kernel/swaps.txt"
lsmod > "$WORKINGDIR/kernel/lsmod.txt"
dmesg > "$WORKINGDIR/kernel/dmesg.txt"
sysctl -a > "$WORKINGDIR/kernel/sysctl.txt" 2>/dev/null

if [ -f "/proc/config" ]; then
	cat /proc/config > "$WORKINGDIR/kernel/config.txt"
else
	if [ -f "/proc/config.gz" ]; then
		zcat /proc/config.gz > "$WORKINGDIR/kernel/config.txt"
	else
		cat "/boot/config-`uname -r`" > "$WORKINGDIR/kernel/config.txt"
	fi
fi

showuser "Scanning and dumping specific parts of /proc"
for FILE in `ls -1 /proc`; do
	if [ -f "/proc/$FILE" ] && [ -s "/proc/$FILE" ]; then
		if [ "$FILE" != "kcore" ] && [ "$FILE" != "kmsg" ] && [ "$FILE" != "sysrq-trigger" ]; then
			debug "  reading file /proc/$FILE"
			cat "/proc/$FILE" > "$WORKINGDIR/proc/$FILE.txt"
		fi
	fi
done

readdir /proc/sys "$WORKINGDIR/proc/sys"
readdir /proc/driver "$WORKINGDIR/proc/driver"
readdir /proc/acpi "$WORKINGDIR/proc/acpi"


showuser "Scanning and dumping specific parts of /sys"

readdir /sys/kernel/debug "$WORKINGDIR/sys/kernel/debug"
readdir /sys/kernel/mm "$WORKINGDIR/sys/kernel/mm"

showuser "Generate system summary"

echo ""
echo ""
echo ""

echo "System info of the host `hostname` at `date`:" > "$WORKINGDIR/SUMMARY.txt"
echo "-----------------------------------" >> "$WORKINGDIR/SUMMARY.txt"
echo "Script version: $VERSION" >> "$WORKINGDIR/SUMMARY.txt"
echo "Time: `date`" >> "$WORKINGDIR/SUMMARY.txt"
echo "Hostname: `hostname`" >> "$WORKINGDIR/SUMMARY.txt"
echo "LoadAVG: `cat /proc/loadavg`" >> "$WORKINGDIR/SUMMARY.txt"
echo "Kernel: `uname -a`" >> "$WORKINGDIR/SUMMARY.txt"
echo "Architecture: `uname -m`" >> "$WORKINGDIR/SUMMARY.txt"
echo "CPU info:" >> "$WORKINGDIR/SUMMARY.txt"
cat /proc/cpuinfo | grep -e '\(model name\|bogomips\|MHz\|flags\)' >> "$WORKINGDIR/SUMMARY.txt"
echo "Memory info:" >> "$WORKINGDIR/SUMMARY.txt"
cat /proc/meminfo  | grep -e '\(MemTotal\|SwapTotal\)'  >> "$WORKINGDIR/SUMMARY.txt"
echo "Distro info:" >> "$WORKINGDIR/SUMMARY.txt"
lsb_release -d >> "$WORKINGDIR/SUMMARY.txt"

cat "$WORKINGDIR/SUMMARY.txt"

echo ""
echo ""
echo ""

cd "$TMPDIR"
tar jcf "$TMPLINDIR.tar.bz2" "$TMPLINDIR"

echo "Done with collecting your info. You can get the information from the following location:"
echo "   tmp directory: $TMPDIR"
echo "   tarball: $TMPDIR/$TMPLINDIR.tar.bz2"
echo "   content directory: $WORKINGDIR"
