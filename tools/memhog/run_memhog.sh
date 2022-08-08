#! /bin/bash

# install tools
if [ -d ./numactl-2.0.13 ]
then
    echo "numactl and mlc have been installed." 
else 
    wget https://github.com/numactl/numactl/archive/refs/tags/v2.0.13.zip 
    unzip v2.0.13.zip
    cd numactl-2.0.13
    ./autogen.sh
    ./configure
    mv ../memhog.c . 
    sudo make && make install 
    cd ..
    
    mkdir mlc ; cd mlc
    wget https://software.intel.com/content/dam/develop/external/us/en/protected/mlc_v3.9.tgz
    tar xzvf mlc_v3.9.tgz
    cd ..
 
fi

# Get the logical cpu index of the numa achitecture

psr1_cpu=( `numactl --hardware | grep "$3 cpus:" | awk -F: '{printf "%s",$2}'` )
psr2_cpu=( `numactl --hardware | grep "$4 cpus:" | awk -F: '{printf "%s",$2}'` )
 

num_threads=$1           # the number of memhog
# cpu_node=$2              # which numa node to launch the memhog
size_mem=$2              # the size of memory that each memhog will consume,
                         # examples: 1M, 1G, 2G
#repeated_time=$5        # control the running time of memehog, however it is decided by many factors. 
# instead of passing this parameter,
# I will change the m mhog source code to let it run utill user manually kills the process
  
psr1=$3                  # Processor 1 to run the memhog
psr2=$4                  # Processor 2 to run the memhog


echo $num_threads
echo $size_mem
n=0
while [ $n -lt $num_threads ]
do
    echo $n
    # -H means disable transparent hugepages, 
    nohup numactl --membind $psr1 --cpunodebind $psr1 --physcpubind ${psr1_cpu[$n]} memhog -r4096 $size_mem -H 1>res.txt  2>err.txt &
    nohup numactl --membind $psr2 --cpunodebind $psr2 --physcpubind ${psr2_cpu[$n]} memhog -r4096 $size_mem -H 1>res.txt 2>err.txt &
    n=$(( $n + 1))
done

sleep 2

cd ./mlc/Linux
sudo ./mlc --latency_matrix
cd ../../
