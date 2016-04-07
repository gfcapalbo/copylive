#!/bin/sh

#Usage copylive $liveuser  $targetuser           
# -m    magento connector cleanup

cd /tmp

function help {
    echo"
    if the username and the database name are the same:

    copylive  source_user  target_user

    will copy from db "source" of user source   to db "target"
    of user "target". (Default DBNAME = USERNAME)
    If the DB does not exist it will create it.

    copylive  source_user  target_user  DB_nameorigin DB_nametarget
    
    Will copy DB_nameorigin of source_user to DB_nametarget of targetuser
    if DB_nametarget doesn't exist will create it.

    Magento extension:

    if the -m switch is specified it will clean up all magneto connector related connections to avoid TARGET from connecting to the 

    Before doing that it will fetch the old target options and save them in 
    ~home/magento_options.txt"
}    

function magento {
    echo " magento cleanup functionality still not implemented"
}


function noarguments {
    if [ -z "$1" ] || [ -z  "$2"]; then
    help
    echo " ABORTING , missing minimal arguments"
    }
 
LIVE_USER=$1
TARGET_USER=$2

function no_livedb {
    if [-z "$4" ]; then
        if [-z "$3" ]; then
            LIVE_DB=$1
            TARGET_DB=$2
            echo "USING DEFAULT NAME FOR SOURCE DATABASE: ${LIVE_DB}"
            echo "USING DEFAULT NAME FOR TARGET DATABASE: ${TARGET_DB}"
        else    
            LIVE_DB=$3
            TARGEddT_DB=$2
            echo "USING Specified name for SOURCE DATABASE: ${LIVE_DB} "
            echo "USING DEFAULT NAME FOR TARGET DATABASE: ${TARGET_DB}" 
        fi
    else
        LIVE_DB=$3
        TARGET_DB=$4
    fi
}


while getopts ":h:m" opt; do
    case $opt in
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
    esac
done


TEST_USER="openerp"
DBNAME="${LIVE_DB}_$(date +%F)"
LIVE_HOST=192.168.11.31
SSH="ssh $LIVE_USER@$LIVE_HOST"

sudo -u $TEST_USER sh -c "cd ~$TEST_USER/data/filestore; ln -s attachments $DBNAME || true"
sudo -u $TEST_USER rsync --recursive -q $LIVE_USER@$LIVE_HOST:data/filestore/$LIVE_DB/ /home/$TEST_USER/data/filestore/attachments/ &
sudo -u $TEST_USER dropdb ${DBNAME} || true
sudo -u $TEST_USER createdb ${DBNAME}
$SSH "pg_dump --format=custom --no-owner $LIVE_DB | gzip --stdout" | gzip --decompress --stdout | sudo -u $TEST_USER pg_restore --no-owner --dbname=${DBNAME}
sudo -u $TEST_USER psql $DBNAME -c "delete from ir_mail_server"
sudo -u $TEST_USER psql $DBNAME -c "update fetchmail_server set active=False"
sudo -u $TEST_USER psql $DBNAME -c "update ir_cron set active=False"
sudo -u $TEST_USER psql $DBNAME -c "update ir_config_parameter set value='http://192.168.11.233' where key='web.base.url'"
sudo -u $TEST_USER psql $DBNAME -c "update ir_module_module set state='uninstalled' where name in ('dead_mans_switch_client', 'dead_mans_switch_therp')"
sudo -u $TEST_USER psql $DBNAME -c "update res_users set password_crypt=(select password_crypt from res_users where login='admin')"

