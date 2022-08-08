#!/bin/bash

cd /path/to/Cassandra/apache-cassandra-4.0-rc1
./start_cassandra.sh

sleep 5

cd /path/to/Cassandra/ycsb
./ycsb_test.sh
