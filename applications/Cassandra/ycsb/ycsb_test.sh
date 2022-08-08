
#!/bin/bash
 
startTime=`date +%Y%m%d-%H:%M`
 
startTime_s=`date +%s`

nohup ./bin/ycsb.sh load  cassandra-cql -P workloads/workloada -p recordcount=3000000 -p hosts=127.0.0.1 -s  -p fieldlength=10000 -threads 8   -p core_workload_insertion_retry_limit=1000 > ycsb_res_numa_mode.txt &
 
endTime=`date +%Y%m%d-%H:%M`
 
endTime_s=`date +%s`
 
sumTime=$[ $endTime_s - $startTime_s ]
 
echo "$startTime ---> $endTime" "Totl:$sumTime minutes"
