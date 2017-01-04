#!/bin/bash

fullPath="/data/dbserver/db-backup/full"
incrPath="/data/dbserver/db-backup/incremental"
bakdate=`date +'%F'`
bakhour=`date +'%H'`

oneHourAgo=`date -d '1 hours ago' +'%F_%H'`

BakBin="/usr/bin/innobackupex --defaults-file=/etc/my.cnf --no-timestamp --user=root --socket=/data/dbserver/mysql/mysql.sock --sleep=100"

# backup function
function hotbackup(){

  baktype=$1
  logfile=$2
  incrpath=$3
  bakpath=$4

  if [ "$baktype" == "full" ];then
    $BakBin  $bakpath   > $logfile 2>&1
  elif [ "$baktype" == "incremental" ];then
    $BakBin --incremental $incrpath --incremental-basedir $bakpath > $logfile 2>&1
  fi
}

# ============= Main =============

if [ "$1" == "full" ];then
   # 全量备份
   hotbackup "full" "${fullPath}/${bakdate}.log" "none" "$fullPath/$bakdate"
   tar zcvf "${fullPath}/${bakdate}.tar.gz" -C "$fullPath" "$bakdate"
   #/usr/bin/scp -P 9922 -rp  ${fullPath}/${bakdate}* db02:${fullPath}

elif [ "$1" == "incremental" ];then
  # 判断是否为第一次增量备份，只有第一次增量备份目录指向全量备份
  # 第二次开始增量备份的上一次目录指向第一次增量目录即可
  if [ "$2" == "first" ];then
     hotbackup "incremental" "${incrPath}/${bakdate}_${bakhour}.log" "$incrPath/${bakdate}_${bakhour}" "$fullPath/$bakdate"
     tar zcvf "$incrPath/${bakdate}_${bakhour}.tar.gz" -C "$incrPath" "${bakdate}_${bakhour}"
     #/usr/bin/scp -P 9922 -rp ${incrPath}/${bakdate}_${bakhour}* db02:${incrPath}
  else
     hotbackup "incremental" "${incrPath}/${bakdate}_${bakhour}.log" "$incrPath/${bakdate}_${bakhour}" "$incrPath/${oneHourAgo}"
     tar zcvf "$incrPath/${bakdate}_${bakhour}.tar.gz" -C "$incrPath" "${bakdate}_${bakhour}"
     #/usr/bin/scp -P 9922 -rp ${incrPath}/${bakdate}_${bakhour}* db02:${incrPath}
  fi
fi
