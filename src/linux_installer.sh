#!/bin/bash

# Define configuration and paths
server="${MYSQL_HOST:-localhost}"
port="${MYSQL_PORT:-3306}"
user="${MYSQL_ROOT_USER:-root}"
pass="${MYSQL_ROOT_PASSWORD:-rootPassword}"
wdb="world"
cdb="characters"
ldb="auth"
devpath="./main_db/world"
procpath="./main_db/procs"
uppath="./world_updates"
bkpath="dump"

# Check if the backup folder exists, create if not
if [ ! -d "${bkpath}" ]; then
    mkdir "${bkpath}"
    chmod 0755 "${bkpath}"
fi

# Function to list changesets
list_changesets() {
    echo "Available changesets:"
    for changeset in "${uppath}"/changeset_*.sql; do
        [ -e "$changeset" ] || continue # Skip if no files found
        echo " - ${changeset##*/}"
    done
}

# Function to install clean world database
install_world_db() {
    echo "Installing Clean World Database..."

    mysqldump -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} --add-drop-table --no-data ${wdb} | grep ^DROP | mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${wdb}
    echo

    echo
    echo " [Cleaning World DB] Finished..."

    echo " Adding Stored Procedures"
    max=$(ls -1 "${procpath}"/*.sql | wc -l)
    e=0
    for table in "${procpath}"/*.sql; do
        e=$((${i} + 1))
        echo " [${e}/${max}] import: ${table##*/}"
        mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${wdb} <"${table}"
    done
    echo " Adding Adding Stored Procedures Complete"
    echo " Importing world data"
    max=$(ls -1 "${devpath}"/*.sql | wc -l)
    i=0
    for table in "${devpath}"/*.sql; do
        i=$((${i} + 1))
        echo " [${i}/${max}] import: ${table##*/}"
        mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${wdb} <"${table}"
    done

    echo
    echo " [Importing] Finished..."
}

# Function to update world database with a specific changeset
update_world_db() {
    echo "Updating World Database..."

    # Check if a changeset ID was provided as an argument
    if [ -z "$1" ]; then
        echo "No changeset ID provided."
        echo "Usage: $0 u [changeset_id]"
        exit 1
    fi

    changeset_id=$1
    update="${uppath}/changeset_${changeset_id}.sql"

    if [ ! -f "${update}" ]; then
        echo "Changeset file ${update} does not exist."
        exit 1
    fi

    echo "Importing changeset ${changeset_id}."
    mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${wdb} <"${update}"
    echo "Update to changeset ${changeset_id} completed."
}

# Function to backup database
backup_db() {
    echo "Backing Up Database..."

    echo
    rm -rf "${bkpath}/logon_backup.sql"
    rm -rf "${bkpath}/character_backup.sql"
    echo " [Deleting Old Backups] Finished..."

    echo
    mysqldump -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${ldb} >"${bkpath}/logon_backup.sql"
    echo " [Backing Up Logon Database] Finished..."

    mysqldump -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${cdb} >"${bkpath}/character_backup.sql"
    echo " [Backing Up Char Database] Finished..."

    echo
    echo " [Backing Up] Finished..."
}

# Function to restore database
restore_db() {
    echo "Restoring Database from Backup..."
    echo
    mysqldump -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} --add-drop-table --no-data ${ldb} | grep ^DROP | mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${ldb}
    echo " [Emptying Logon Database] Finished..."

    mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${ldb} <"${bkpath}/logon_backup.sql"
    echo " [Restoring Logon Database From Backup] Finished..."

    echo
    mysqldump -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} --add-drop-table --no-data ${cdb} | grep ^DROP | mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${cdb}
    echo " [Emptying Char Database] Finished..."

    mysql -h ${server} --protocol=TCP --user=${user} --port=${port} --password=${pass} ${cdb} <"${bkpath}/character_backup.sql"
    echo " [Restoring Char Database From Backup] Finished..."

    echo
    echo " [Restoring Backup] Finished..."
}

# Process arguments
case "$1" in
i)
    install_world_db
    ;;
u)
    update_world_db "$2" # Pass the second argument to the function
    ;;
l)
    list_changesets
    ;;
b)
    backup_db
    ;;
r)
    restore_db
    ;;
*)
    echo "Usage:"
    echo "  $0 i                 Install a clean world database."
    echo "  $0 u [changeset_id]  Update the world database with the specified changeset."
    echo "  $0 l                 List available changesets for updates."
    echo "  $0 b                 Backup the world database."
    echo "  $0 r                 Restore the world database from a backup."
    exit 1
    ;;
esac

exit 0
