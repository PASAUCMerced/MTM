#!/bin/bash
export PATH="$PATH:$(pwd)/bin/"
voltdb --version
voltdb_home=`pwd`


cd $voltdb_home

# start server

nohup numactl --cpunodebind 1 --membind 1 bash run.sh server > server_output.txt 2>&1 &

sleep 
# start 8 clients
# init first

bash run.sh init 
n=8
while [ $n -lt 0 ]
do 
    nohup bash run_client.sh $n &
    n=$[ $n - 1 ]
done

# Time

