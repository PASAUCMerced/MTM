

#!/bin/sh

timestamp="`date '+%Y%m%d_%H-%M-%S_%s'`"

log="memstat-$timestamp.csv"

echo "" > $log

echo "RAM_GB   PM_GB"
echo "ram_gb,pm_gb" >  $log

while [ 1 = 1 ];do
    check_status=`ps -ax|grep gups |sed '/grep/d'`

    if [ "$check_status" = "" ];then
        echo "detected gups exited."
        break
    fi
   
    ramsize="`numastat -m|grep Used|awk '{print ($2+$3)/1024.00}'`"
    pmsize="`numastat -m|grep Used|awk '{print ($4+$5)/1024.00}'`"

    echo "$ramsize    $pmsize"
    echo "$ramsize,$pmsize" >> $log

    sleep 1
done

