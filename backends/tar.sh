function tar_init() {
    # nothing to do for tar?
    log_debug "tar: no tar init..."
}

function tar_remove_old() {
    log_debug "tar: removing older backups..."

	local status

    local retcode=1
    for backup_dir in ${PURGEABLE_DIRS[*]}
    do
        log_info "tar: cleaning up \"$backup_dir\""
        find $backup_dir -name "*.tar.gz" -type f -mtime +7 -delete
		status=$?
        if [ $status -ne 0 ]; then
            log_error "tar: failed cleaning \"$backup_dir\", moving on"
        else
            retcode=0
        fi
     done

    log_debug "tar: backup purge finished"

    return $retcode
}

# TODO: Make default .tar with optional bup
function tar_create_backup() {
    log_debug "tar: backing up..."

	local status

    # save world to a temporary archive
    local archname="/tmp/${BACKUP_NAME}_`date +%F_%H-%M-%S`.tar.gz"
    tar -czf "$archname" "./$WORLD_NAME" "./${WORLD_NAME}_nether" "./${WORLD_NAME}_the_end" "./minecraft-server-tools" "server.properties"
	status=$?
    if [ $status -ne 0 ]; then
        log_error "tar: failed to save the world"
        rm "$archname" #remove (probably faulty) archive
        return 1
    fi
    log_debug "tar: world saved to $archname, pushing it to backup directories..."

	# 0 if could save to at least one backup dir
	# TODO: make more strict?
    local retcode=1
    for backup_dir in ${BACKUP_DIRS[*]}
    do
        log_info "tar: backing up to \"$backup_dir\""
        # scp acts as cp for local destination directories
        scp "$archname" "$backup_dir/"
		status=$?
        if [ $status -ne 0 ]; then
            log_error "tar: failed pushing to \"$backup_dir\", moving on"
        else
            retcode=0
        fi
     done

    rm "$archname"

    log_debug "tar: backup finished"

    return $retcode
}

# server_restore relies on output format of this function
function tar_ls() {
    local backup_dir="$1"

    if [[ "$backup_dir" == *:* ]]; then
        local remote="$(echo "$backup_dir" | cut -d: -f1)"
        local remote_dir="$(echo "$backup_dir" | cut -d: -f2)"
        ssh "$remote" "ls -1 $remote_dir" | grep "tar.gz" | sort -r
	else
        ls -1 "$backup_dir" | grep "tar.gz" | sort -r
	fi
}

function tar_restore() {
    local remote="$1"
    local snapshot="$2"
	local dest="$3"
	local status

    scp "$remote/$snapshot" "/tmp/"
	status=$?
    if [ $status -ne 0 ]; then
        log_error "tar: failed to get archive from \"$remote/$snapshot\""
        return 1
    fi

    tar -xzf "/tmp/$snapshot" -C "$dest"
}
