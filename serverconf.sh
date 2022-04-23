# serverconf.sh
# configuration file for server.sh minecraft server
# management script

VERBOSE=0

#CONFIG
JRE_JAVA="java"
JVM_ARGS="-Xms10G -Xmx10G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
JAR="paper.jar"
JAR_ARGS="-nogui"

TMUX_WINDOW="minecraft"
TMUX_SOCKET="mc_tmux_socket"

WORLD_NAME="paoworld"
if [ -f "server.properties" ]; then
    WORLD_NAME=$(grep level-name server.properties | cut -d= -f2)
    echo "Getting world name from server.properties: $WORLD_NAME"
fi

BACKUP_NAME="${WORLD_NAME}_backup"
LOGFILE="logs/latest.log"
PIDFILE="server-screen.pid"
# if not bup or borg, uses tar by default
BACKUP_BACKEND="tar"
#BACKUP_BACKEND="bup"
#BACKUP_BACKEND="borg"

#Constants
CUR_YEAR=`date +"%Y"`

# IMPORTANT: local paths must be absolute!
# BACKUP_DIRS=( "$PWD/.bak/$CUR_YEAR" "user@backupserver:/path/to/backup/$CUR_YEAR" )
BACKUP_DIRS=("$PWD/.bak/$CUR_YEAR")
PURGEABLE_DIRS=("$PWD/.bak/$CUR_YEAR")

# borg repository could be pasword-protected
# to avoid having to manually type password, borg can run a command that should echo a password
#BACKUP_PASSCOMMAND="echo superstrongpassword"
#BACKUP_PASSCOMMAND="pass passwordname"

# 0 - don't check backups after creation
# 1 - check only local backups
# 2 - check local and remote backups (may take a while if world is large and connection is slow)
BACKUP_CHECK_MODE=1
