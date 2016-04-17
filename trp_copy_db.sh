OPIES DB from ORIGIN TO TARGET, CLEANS AND ADJUSTS DATA

function help {
    echo"
    Copy live copies a Odoo Database from one 
    instance source to another, It cleans up 
    email servers and sanitizes data. 
    If there is a magento instance on the source 
    instance it will also change the magento 
    connection data.

    The only parameter it takes is the Variable file , 
    where all the vars are specified. 
   
    ====USAGE====
    trp_copy_db  <varfilename>

    varfilename is the file where all variables are stored.
    If no varfilename is specified thes script will use default location 
    copylive/copylive_variables.sh
    

    ====ACCEPTED VARIABLES in varfilename ====

    ORIGIN_DATABASE =  name of DB FROM WICH I AM COPYING 
    TARGET_DATABASE = name of DB TO WICH I AM COPYING
    TARGET_USER = name of USER of target instance
    MAGENTO = Does this database have a magento instance? YES/NO 
    TARGET_MAGENTO_API_LOCATION = Where to connect the TARGET MAGENTO. 
    ORIGIN_HOST= Location of origin DB (if there is no need to access the origin via SSH just leave empty.) 
    " 
}

#No arguments, use default

if [ -z "$1" ]
    then
      VARIABLE_FILE="./copylive/copylive_settings.sh"
else
      VARIABLE_FILE=$1
fi

#just in case someone puts dangerous commands in the variable file.
echo "==== VARIABLES TO BE USED FOR COPY ===="
cat ${VARIABLE_FILE}
read -p  "Before Continuing Please verify the content and settings of ${VARIABLE_FILE} , press enter to continue, CTRL+C to interrupt" -n 1 -r

. $VARIABLE_FILE
echo $GET_MAGENTO_API_LOCATION


if [ -z "${ORIGIN_HOST}" ] 
    then
        help
        SSH="ssh $ORIGIN_USER@$ORIGIN_HOST"
        echo "SSH Origin user/Host set on ${SSH}"
fi

#DBNAME="${ORIGIN_DB}_$(date +%F)"  #using default name
DBNAME=${TARGET_DB}




sudo -u $TARGET_USER sh -c "cd ~$TARGET_USER/data/filestore; ln -s attachments $DBNAME || true"
sudo -u $TARGET_USER rsync --recursive -q $ORIGIN_USER@$ORIGIN_HOST:data/filestore/$ORIGIN_DB/ /home/$TARGET_USER/data/filestore/attachments/ &
# Fetch the Magneto Connection data and save it
CONNECT = sudo -u $TARGET_USER psql $DBNAME -c "SELECT FROM CONNECTOR_BACKEND
sudo -u $TARGET_USER dropdb ${DBNAME} || true
sudo -u $TARGET_USER createdb ${DBNAME}
$SSH "pg_dump --format=custom --no-owner $ORIGIN_DB | gzip --stdout" | gzip --decompress --stdout | sudo -u $TARGET_USER pg_restore --no-owner --dbname=${DBNAME}
sudo -u $TARGET_USER psql $DBNAME -c "delete from ir_mail_server"
sudo -u $TARGET_USER psql $DBNAME -c "update fetchmail_server set active=False"
sudo -u $TARGET_USER psql $DBNAME -c "update ir_cron set active=False"
sudo -u $TARGET_USER psql $DBNAME -c "update ir_config_parameter set value='http://192.168.11.233' where key='web.base.url'"
sudo -u $TARGET_USER psql $DBNAME -c "update ir_module_module set state='uninstalled' where name in ('dead_mans_switch_client', 'dead_mans_switch_therp')"
sudo -u $TARGET_USER psql $DBNAME -c "update res_users set password_crypt=(select password_crypt from res_users where login='admin')"

sudo -u $TARGET_USER psql $DBNAME -c "update res_users set password_crypt=(select password_crypt from res_users where login='admin')"
# Restore Magento connection data 
sudo -u $TARGET_USER psql $DBNAME -c "update ir_module_module set state='uninstalled' where name in ('dead_mans_switch_client', 'dead_mans_switch_therp')"
