#!/bin/sh

#Usage copylive $liveuser  $targetuser           
# -m    magento connector cleanup

cd /tmp

function help {
    echo"
    if the username and the database name are the same:
    Options:

    -s   SHH Host to fetch live user
    -m   PERFORM MAGENTO OPERATIONS

    MINIMAL USAGE:

    copylive  source_user  target_user

    will copy from db "source" of user source   to db "target"
    of user "target". (Default DBNAME = USERNAME)
    If the DB does not exist it will create it.

    copylive  source_user  target_user  DB_nameorigin DB_nametarget
    
    Will copy DB_nameorigin of source_user to DB_nametarget of targetuser
    if DB_nametarget doesn't exist will create it.

    Magento extension:

    if the -m switch is specified it will clean up all magneto connector related connections to avoid TARGET from connecting to the production magento.
    " 
}    

function magento {
    echo " magento cleanup functionality still not implemented"
}


ORIGIN_USER=$1
TARGET_USER=$2

if [ -z "$1" ] || [ -z  "$2" ]; then
    help
    echo "====ABORTING , missing minimal arguments==="
    exit
fi

if [ -z "$4" ]; then
    if [ -z "$3" ]; then
        ORIGIN_DB=$1
        TARGET_DB=$2
        echo "USING DEFAULT NAME FOR SOURCE DATABASE: ${ORIGIN_DB}"
        echo "USING DEFAULT NAME FOR TARGET DATABASE: ${TARGET_DB}"
    else    
        ORIGIN_DB=$3
        TARGET_DB=$2
        echo "USING Specified name for SOURCE DATABASE: ${ORIGIN_DB} "
        echo "USING DEFAULT NAME FOR TARGET DATABASE: ${TARGET_DB}" 
    fi
else
    ORIGIN_DB=$3
    TARGET_DB=$4
fi



while getopts ":h:m:s" opt; do
    case $opt in
    s)
        ORIGIN_HOST=$OPTARG
        SSH="ssh $ORIGIN_USER@$ORIGIN_HOST"
        echo "SSH Origin user/Host set on ${SSH}"
        ;;
    h)
        help
        exit
        ;;
    m)  
        magento
        exit
        ;;
    \?)
        help
        echo "UNKNOWN OPTION: ~$OPTARG"
        ;;
    esac
done


#TARGET_USER="openerp"
#DBNAME="${ORIGIN_DB}_$(date +%F)"  #using default name
DBNAME=${TARGET_DB}


#sudo -u $TARGET_USER sh -c "cd ~$TARGET_USER/data/filestore; ln -s attachments $DBNAME || true"
#sudo -u $TARGET_USER rsync --recursive -q $ORIGIN_USER@$ORIGIN_HOST:data/filestore/$ORIGIN_DB/ /home/$TARGET_USER/data/filestore/attachments/ &
#sudo -u $TARGET_USER dropdb ${DBNAME} || true
#sudo -u $TARGET_USER createdb ${DBNAME}
#$SSH "pg_dump --format=custom --no-owner $ORIGIN_DB | gzip --stdout" | gzip --decompress --stdout | sudo -u $TARGET_USER pg_restore --no-owner --dbname=${DBNAME}
#sudo -u $TARGET_USER psql $DBNAME -c "delete from ir_mail_server"
#sudo -u $TARGET_USER psql $DBNAME -c "update fetchmail_server set active=False"
#sudo -u $TARGET_USER psql $DBNAME -c "update ir_cron set active=False"
#sudo -u $TARGET_USER psql $DBNAME -c "update ir_config_parameter set value='http://192.168.11.233' where key='web.base.url'"
#sudo -u $TARGET_USER psql $DBNAME -c "update ir_module_module set state='uninstalled' where name in ('dead_mans_switch_client', 'dead_mans_switch_therp')"
#sudo -u $TARGET_USER psql $DBNAME -c "update res_users set password_crypt=(select password_crypt from res_users where login='admin')"

