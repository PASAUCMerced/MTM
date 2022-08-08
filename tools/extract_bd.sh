#!/bin/sh

if [ "$#" != 3 ];then
    echo "$0 <iteration-number> <result-dir> <output-dir>"
    exit
fi


rank=0

iteration="$1"
result_dir="$2"
output_dir="$3"

if [ ! -d "$output_dir" ];then
    echo "$output_dir does not exist."
    exit
fi


iteration_dir="`find $result_dir -type d -iname iteration_$iteration`"

if [ "$iteration_dir" = "" ];then
    echo "Incorrect result-dir $result_dir"
    exit
fi

csvfiledir="$output_dir"


echo "result_dir=$result_dir"
echo "csvfiledir=$csvfiledir"

echo "iteration=$iteration" > "$csvfiledir/bandwidth_iteration.txt"

phase_list="GatherFields Push Deposit SolveFields Others"

csvheader="sys_dram_read_mbps,sys_dram_write_mbps,sys_pmm_read_mbps,sys_pmm_write_mbps,sys_read_mbps,sys_write_mbps,sys_total_mbps" 

for phase in $phase_list; do
    membwfile="$iteration_dir/$phase/membw.txt"

    if [ ! -f "$membwfile" ];then
        continue
    fi

    echo "phase=$phase"

    sys_dram_read="`cat $membwfile | grep 'System DRAM Read'|awk '{print $6}'`"
    sys_dram_write="`cat $membwfile | grep 'System DRAM Write'|awk '{print $6}'`"

    sys_pmm_read="`cat $membwfile | grep 'System PMM Read'|awk '{print $6}'`"
    sys_pmm_write="`cat $membwfile | grep 'System PMM Write'|awk '{print $6}'`"
    
    sys_read="`cat $membwfile | grep 'System Read'|awk '{print $5}'`"
    sys_write="`cat $membwfile | grep 'System Write'|awk '{print $5}'`"
    sys_total="`cat $membwfile | grep 'System Memory'|awk '{print $5}'`"

    #echo "n_sys_dram_read:"
    #echo $sys_dram_read | grep -o ' '|wc -l

    #echo "n_sys_dram_write:"
    #echo $sys_dram_write | grep -o ' '|wc -l

    #echo "n_sys_pmm_read:"
    #echo $sys_pmm_read | grep -o ' '|wc -l

    #echo "n_sys_pmm_write:"
    #echo $sys_pmm_write | grep -o ' '|wc -l

    #echo "n_sys_read:"
    #echo $sys_read | grep -o ' '|wc -l

    #echo "n_sys_write:"
    #echo $sys_write | grep -o ' '|wc -l

    #echo "n_sys_total:"
    #echo $sys_total | grep -o ' '|wc -l

    #echo "sys_dram_read:"
    #echo $sys_dram_read

    #exit
    csvfile="$csvfiledir/$phase""_bandwidth.csv"
    csvfiletmp="$csvfiledir/$phase""_bandwidth.tmp"


    #echo "$phase:"
    #echo "$sys_dram_read"
    #echo "$sys_dram_write"
    #echo "$sys_pmm_read"
    #echo "$sys_pmm_write"
    #echo "$sys_read"
    #echo "$sys_write"
    #echo "$sys_total"

    sys_dram_read="`echo $sys_dram_read`"
    sys_dram_write="`echo $sys_dram_write`"

    sys_pmm_read="`echo $sys_pmm_read`"
    sys_pmm_write="`echo $sys_pmm_write`"

    sys_read="`echo $sys_read`"
    sys_write="`echo $sys_write`"
    sys_total="`echo $sys_total`"

    echo "$sys_dram_read" > $csvfiletmp
    echo "$sys_dram_write" >> $csvfiletmp

    echo "$sys_pmm_read" >> $csvfiletmp
    echo "$sys_pmm_write" >> $csvfiletmp

    echo "$sys_read" >> $csvfiletmp
    echo "$sys_write" >> $csvfiletmp
    echo "$sys_total" >> $csvfiletmp

    echo "$csvheader" > $csvfile
    #transpose the csvfile
    awk -F' ' -f "`dirname $0`""/transpose_file.awk"  $csvfiletmp >> $csvfile

    rm $csvfiletmp 2>/dev/zero
done

echo "-- Finished --"
