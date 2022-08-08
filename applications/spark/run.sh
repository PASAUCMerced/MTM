#!/bin/bash

nohup numactl --membind 0,1,2,3  /path/to/spark/spark-2.4.7-bin-hadoop2.7/bin/spark-submit --master local[8]  --class com.github.ehiggs.spark.terasort.TeraSort --conf spark.driver.memory=1000g  --conf spark.memory.fraction=0.6 --conf spark.memory.storageFraction=0.6   --conf spark.default.parallelism=1000 --conf spark.local.dir=/storage2/tmp  /path/to/spark/spark-terasort/target/spark-terasort-1.2-SNAPSHOT-jar-with-dependencies.jar /storage/350g  /storage/output/t_output_350g > results.txt 2>&1 &
