#!/bin/sh

#Usage copylive $liveuser  $targetuser           
# -m    magento connector cleanup

cd /tmp

LIVE_DB=$1
LIVE_USER=$1
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

