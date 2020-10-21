#!/bin/bash

DELETE_EXPIRED_AUTOMATICALLY="TRUE"

# DELETE EXPIRED BACKUPS THAT ARE MORE THAN
# expire_minutes=$(( 1 * 30 ))	 # 30 minutes old
# expire_minutes=$(( 60 * 24 ))	 # 1 day old
# expire_minutes=$(( 60 * 24 * 7 ))	 # 7 days old
# expire_minutes=$(( 60 * 24 * 7 ))	 # 7 days old
expire_minutes=$(( 60 * 24 * 30 ))	# 30 days old

if [ $expire_minutes -gt 1440 ]; then
    expire_days=$(( $expire_minutes /1440 ))
else
    expire_days=0
fi

function pause(){ 
read -p "$*" 
}

# pause "HIT RETURN, and then enter your sudo password..."
echo "Please enter your sudo password..."
sudo echo

mysql_username="root"
mysql_password="ROOT"

current_dir=`pwd`
echo -n "Current working directory is : "
echo $current_dir
echo "------------------------------------------------------------------------"

TIME_1=`date +%s`
TS=$(date +%Y.%m.%d\-%I.%M)

BASE_DIR=/var/backups/mysql
BACKUP_DIR=${BASE_DIR}/$TS
BACKUP_LOG_NAME=mysql_dump_runtime.log
BACKUP_LOG=${BASE_DIR}/${BACKUP_LOG_NAME}
errorstate=false; 

sudo mkdir -p $BACKUP_DIR
sudo chown mysql:mysql $BACKUP_DIR
sudo chmod 775 $BASE_DIR
sudo chmod -R 777 $BACKUP_DIR

cd $BACKUP_DIR
echo -n "Changed working directory to : "
pwd

echo "Saving the following backups..."
echo "------------------------------------------------------------------------"

DBS="$(mysql -h db --user=${mysql_username} --password=${mysql_password} -Bse 'show databases')"

for db in ${DBS[@]}
do
    normal_output_filename=${db}.sql
    compressed_output_filename=${normal_output_filename}.gz
    echo $compressed_output_filename
    # remember to add the options you need with your backups here.
    
    echo "-- $compressed_output_filename - $TS" > $normal_output_filename
    echo "-- Logname : `logname`" >> $normal_output_filename
    # mysqldump5 --user=${mysql_username} --password=${mysql_password} $db --single-transaction -R | bzip2 -c > $compressed_output_filename
    mysqldump -h db --user=${mysql_username} --password=${mysql_password} --routines $db --single-transaction --max_allowed_packet=256M -R > $normal_output_filename

    if [ -f $normal_output_filename ]; then
        #dump_completed="$(grep -i 'Dump completed' $normal_output_filename | wc -l)"
	dump_completed="$(tail -n 100 $normal_output_filename | grep -i 'Dump completed' | wc -l)"
        if [ ! $dump_completed -eq 1 ]; then
            errorstate=true
            echo ">>> ERROR: Didn't found string 'Dump completed' in dump"; 
        fi
    else 
        errorstate=true
        echo ">>> ERROR: dump-file $normal_output_filename doesn't exist"; 
    fi

    gzip $normal_output_filename
    #bzip2 -c $normal_output_filename > $compressed_output_filename
    #rm $normal_output_filename
done
echo "------------------------------------------------------------------------"

if [ ! -f mysql.sql.gz ]; then
    errorstate=true
    echo ">>> ERROR: file mysql.sql.gz doesn't exist"; 
fi

if $errorstate ; then 
   echo ">>> ERROR - see above -> sending email"; 
   SYS_HOSTNAME=$(</etc/hostname)
fi

TIME_2=`date +%s`

elapsed_seconds=$(( ( $TIME_2 - $TIME_1 ) ))
elapsed_minutes=$(( ( $TIME_2 - $TIME_1 ) / 60 ))

# just a sanity check to make sure i am not running a dump for 4 hours

cd $BASE_DIR
echo -n "Changed working directory to : "
pwd
echo "Making log entries..."

if [ ! -f $BACKUP_LOG ]; then
    echo "------------------------------------------------------------------------" > ${BACKUP_LOG_NAME}
    echo "THIS IS A LOG OF THE MYSQL DUMPS..." >> ${BACKUP_LOG_NAME}
    echo "DATE STARTED : [${TS}]" >> ${BACKUP_LOG_NAME}
    echo "------------------------------------------------------------------------" >> ${BACKUP_LOG_NAME}
    echo "[BACKUP DIRECTORY ] [ELAPSED TIME]" >> ${BACKUP_LOG_NAME}
    echo "------------------------------------------------------------------------" >> ${BACKUP_LOG_NAME}
fi
    echo "[${TS}] This mysql dump ran for a total of $elapsed_seconds seconds." >> ${BACKUP_LOG_NAME}
    echo "------------------------------------------------------------------------" >> ${BACKUP_LOG_NAME}

# delete old databases. I have it setup on a daily cron so anything older than 60 minutes is fine
if [ $DELETE_EXPIRED_AUTOMATICALLY == "TRUE" ]; then
    counter=0
    for del in $(find $BASE_DIR -name '*-[0-9][0-9].[0-9][0-9]' -mmin +${expire_minutes})
    do
        counter=$(( counter + 1 ))
        echo "[${TS}] [Expired Backup - Deleted] $del" >> ${BACKUP_LOG_NAME}
    done
    echo "------------------------------------------------------------------------"
    if [ $counter -lt 1 ]; then
        if [ $expire_days -gt 0 ]; then
            echo There were no backup directories that were more than ${expire_days} days old:
        else
            echo There were no backup directories that were more than ${expire_minutes} minutes old:
        fi	
    else
        echo "------------------------------------------------------------------------" >> ${BACKUP_LOG_NAME}
        if [ $expire_days -gt 0 ]; then
            echo These directories are more than ${expire_days} days old and they are being removed:
        else
            echo These directories are more than ${expire_minutes} minutes old and they are being removed:
        fi
        echo "------------------------------------------------------------------------"
        echo "\${expire_minutes} = ${expire_minutes} minutes"
        counter=0
        for del in $(find $BASE_DIR -name '*-[0-9][0-9].[0-9][0-9]' -mmin +${expire_minutes})
        do
        counter=$(( counter + 1 ))
           echo $del
           rm -R $del
        done
    fi
fi
echo "------------------------------------------------------------------------"
cd `echo $current_dir`
echo -n "Restored working directory to : "
pwd
