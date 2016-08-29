#!/sbin/sh
#
# /system/addon.d/99-supersu.sh (root:root 755)
# During an upgrade, this script backs up SuperSU-related files,
# /system is formatted and reinstalled, then the files are restored.
#

. /tmp/backuptool.functions

list_files() {
cat <<EOF
app/Superuser.apk
app/SuperSU/SuperSU.apk
xbin/su
xbin/sugote
xbin/sugote-mksh
xbin/daemonsu
xbin/supolicy
xbin/otasurvival.sh
lib/libsupol.so
lib64/libsupol.so
bin/log
bin/.ext/.su
etc/init.d/99SuperSUDaemon
etc/install-recovery.sh
etc/.installed_su_daemon
.pin
EOF
}

SYSTEMLIB=/system/lib
API=$(cat /system/build.prop | grep "ro.build.version.sdk=" | dd bs=1 skip=21 count=2)
APPPROCESS=false
APPPROCESS64=false
if [ "$API" -ge "21" ]; then
	APPPROCESS=true
	if [ -f "/system/bin/app_process64" ]; then
		APPPROCESS64=true
		SYSTEMLIB=/system/lib64
	fi
fi

ch_con() {
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toybox chcon -h u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toybox chcon -h u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toolbox chcon -h u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toolbox chcon -h u:object_r:system_file:s0 $1
  chcon -h u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toybox chcon u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toybox chcon u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toolbox chcon u:object_r:system_file:s0 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toolbox chcon u:object_r:system_file:s0 $1
  chcon u:object_r:system_file:s0 $1
}

ch_con_ext() {
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toybox chcon $2 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toybox chcon $2 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toolbox chcon $2 $1
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toolbox chcon $2 $1
  chcon $2 $1
}

ln_con() {
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toybox ln -s $1 $2
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toybox ln -s $1 $2
  LD_LIBRARY_PATH=$SYSTEMLIB /system/toolbox ln -s $1 $2
  LD_LIBRARY_PATH=$SYSTEMLIB /system/bin/toolbox ln -s $1 $2
  ln -s $1 $2
  ch_con $2
}

set_perm() {
  chown $1.$2 $4
  chown $1:$2 $4
  chmod $3 $4
  ch_con $4
  ch_con_ext $4 $5
}

cp_perm() {
  rm $5
  cat $4 > $5
  set_perm $1 $2 $3 $5 $6
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      [ ! -L $S/"$FILE" ] && backup_file $S/"$FILE"
    done
    if [ -d "$S/su.d" ]; then
      mkdir -p $C/su.d
      cp -a $S/su.d/* $C/su.d/
    fi
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
    if [ -d "$C/su.d" ]; then
      mkdir -p $S/su.d
      chmod 0700 $S/su.d
      cp -a $C/su.d/* $S/su.d/
      rm -rf $C/su.d      
    fi
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
  	[ -f "/system/xbin/su"] && rm /system/xbin/su
  	[ -f "/system/app/Superuser.apk"] && rm /system/app/Superuser.apk
  ;;
  post-restore)
    # app_process hijack, copy-pasted from the SuperSU install script
	if ($APPPROCESS); then
		rm /system/bin/app_process
		ln_con /system/xbin/daemonsu /system/bin/app_process
		if ($APPPROCESS64); then
			if [ ! -f "/system/bin/app_process64_original" ]; then
				mv /system/bin/app_process64 /system/bin/app_process64_original
			else
				rm /system/bin/app_process64
			fi
			ln_con /system/xbin/daemonsu /system/bin/app_process64
			if [ ! -f "/system/bin/app_process_init" ]; then
				cp_perm 0 2000 0755 /system/bin/app_process64_original /system/bin/app_process_init
			fi
		else
			if [ ! -f "/system/bin/app_process32_original" ]; then
				mv /system/bin/app_process32 /system/bin/app_process32_original
			else
				rm /system/bin/app_process32
			fi
			ln_con /system/xbin/daemonsu /system/bin/app_process32
			if [ ! -f "/system/bin/app_process_init" ]; then
				cp_perm 0 2000 0755 /system/bin/app_process32_original /system/bin/app_process_init
			fi
		fi
	fi

	# these could be reset	
	chmod 0755 /system/app/SuperSU
	chmod 0700 /system/su.d	    
  ;;
esac