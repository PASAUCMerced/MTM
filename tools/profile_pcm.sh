#!/bin/sh

rm -rf diags 2>/dev/zero

killall gups 2>/dev/zero
killall pcm-memory 2>/dev/zero


if [ "$#" -ne "2" ];then
    echo "$0 <ram|pm> <problem>"
    exit
fi

if [ "`id|grep root`" = "" ];then
    echo "$0 is needed to run with root privileges"
    exit
fi

memtype="$1"
problem="$2"

export OMP_NUM_THREADS="24"

if [ "$TEST_RESULT_DIR" = "" ];then
    result_dir="results_""$memtype""_""$problem"
else
    result_dir="$TEST_RESULT_DIR"
fi

echo "memtype=$memtype"
echo "problem=$problem"
echo "result_dir=$result_dir"


rm -rf $result_dir 2>/dev/zero
mkdir -p $result_dir 2>/dev/zero



#PM_BIND="2-3"
#RAM_BIND="0-1"
if [ "$TEST_ITER_START" = "" ]; then
    ITER_START=1
else
    ITER_START="$TEST_ITER_START"
fi

if [ "$TEST_ITER_END" = "" ];then
    ITER_END=1
else
    ITER_END="$TEST_ITER_END"
fi

if [ "$memtype" = "ram" ];then
    memnodes="0-1"
else
    memnodes="2-3"
fi

appoutput_log=$result_dir/appout.txt

killall gups 2>/dev/zero
killall stdbuf 2>/dev/zero
killall pcm-memory 2>/dev/zero
killall perf 2>/dev/zero

sleep 3

killall -9 gups 2>/dev/zero
killall -9 stdbuf 2>/dev/zero
killall -9 pcm-memory 2>/dev/zero
killall -9 perf 2>/dev/zero



sudo ./gups 24 1000000 $problem 8 0 20 80

sleep 3

while [ 1 = 1 ];do
    sleep 1
    #echo "..."
    check_status=`ps -ax|grep gups |sed '/grep/d'|sed '/launch/d'`

    if [ "$check_status" = "" ];then
        echo "detected gups exited."
        break
    fi

done

killall gups 2>/dev/zero
killall stdbuf 2>/dev/zero
killall pcm-memory 2>/dev/zero
killall perf 2>/dev/zero

sleep 3

killall -9 gups 2>/dev/zero
killall -9 stdbuf 2>/dev/zero
killall -9 pcm-memory 2>/dev/zero
killall -9 perf 2>/dev/zero




echo "-- Finished ---"
