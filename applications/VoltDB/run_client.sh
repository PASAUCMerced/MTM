#!/bin/bash


start=`date +%s` # %s可以计算的是1970年以来的秒数

numactl --cpunodebind 0 --membind 0 bash run.sh client > ./$1_output.txt 2>&1

end=`date +%s`

time=$((end-start))
echo $time >> ./$1_output.txt