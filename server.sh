#!/bin/bash

#CONFIG
JRE_JAVA="java"
JVM_ARGS="-Xms512M -Xmx512M" 
JAR="server.jar"
JAR_ARGS="-nogui"
SCREEN_WINDOW="minecraftserverscreen"
WORLD_NAME="world"
LOGFILE="server-screen.log"
PIDFILE="server-screen.pid"
#HOOKS
BACKUP_HOOK='backup_hook_example'

function backup_hook_example {
	echo $ARCHNAME
}

function send_cmd () {
	screen -S $SCREEN_WINDOW -p 0 -X stuff "$1^M"
}

function assert_running() {
	if [ ! -e $PIDFILE ]; then
		return
	fi

	ps -p $(cat $PIDFILE) > /dev/null
	if [ $? -eq 0 ]
	then
		echo "It seems a server is already running. If this is not the case,\
			manually attach to the running screen and close it."
		exit 1
	fi
}

function assert_not_running() {
	if [ ! -e $PIDFILE ]; then
		echo "Server not running"
		exit 1
	fi

	ps -p $(cat $PIDFILE) > /dev/null
	if [ ! $? -eq 0 ]
	then
		echo "Server not running"
		exit 1
	fi
}

function server_start() {
	assert_running

	if [ ! -e "eula.txt" ]
	then
		echo "eula.txt not found. Creating and accepting EULA."
		echo "eula=true" > eula.txt
	fi

	rm -f $LOGFILE
	screen -L -Logfile "$LOGFILE" -S $SCREEN_WINDOW -p 0 -D -m \
		$JRE_JAVA $JVM_ARGS -jar $JAR $JAR_ARGS > /dev/null &
	echo $! > $PIDFILE
	echo Started with PID $!
	exit
}

function server_stop() {
	assert_not_running
	send_cmd "stop"

	local RET=1
	while [ ! $RET -eq 0 ]
	do
		sleep 1
		ps -p $(cat $PIDFILE) > /dev/null
		RET=$?
	done

	echo "stopped the server"

	rm -f $PIDFILE

	exit
}

function server_attach() {
	assert_not_running
	screen -r -p 0 $SCREEN_WINDOW
	exit
}

function server_status() {
	ps -p $(cat $PIDFILE) > /dev/null

	if [ $? -eq 0 ]
	then
		echo "Server is running"
	else
		echo "Server is not running"
	fi
	exit
}

function server_backup_safe() {
	echo "Detected running server. Disabling autosave"
	send_cmd "save-off"
	send_cmd "save-all flush"
	echo "Waiting for save... If froze, run /save-on to re-enable autosave!!"
	
	sleep 1
	while [ $(tail -n 3 "$LOGFILE" | grep -c "Saved the game") -lt 1 ]
	do
		sleep 1
	done
	echo "Done! starting backup..."

	create_backup_archive
	local RET=$?

	echo "Re-enabling auto-save"
	send_cmd "save-on"

	if [ $RET -eq 0 ]
	then
		echo Running backup hook
		$BACKUP_HOOK
	fi
}

function server_backup_unsafe() {
	echo "No running server detected. Running Backup"

	create_backup_archive

	if [ $? -eq 0 ]
	then
		echo Running backup hook
		$BACKUP_HOOK
	fi
}

function create_backup_archive() {
	ARCHNAME="backup/$WORLD_NAME-backup_`date +%d-%m-%y-%T`.tar.gz"
	tar -czf "$ARCHNAME" "./$WORLD_NAME"

	if [ ! $? -eq 0 ]
	then
		echo "TAR failed. No Backup created."
		rm $ARCHNAME #remove (probably faulty) archive
		return 1
	else
		echo $ARCHNAME created.
	fi
}

function server_backup() {
	screen -list $SCREEN_WINDOW > /dev/null
	if [ $? -eq 0 ]
	then #Server is running
		server_backup_safe
	else #Not running
		server_backup_unsafe
	fi

	exit
}

cd $(dirname $0)

case $1 in
	"start")
		server_start
		;;
	"stop")
		server_stop
		;;
	"attach")
		server_attach
		;;
	"backup")
		server_backup
		;;
	"status")
		server_status
		;;
	*)
		echo "Usage: $0 start|stop|attach|status|backup"
		;;
esac
