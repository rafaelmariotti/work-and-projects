#!/bin/bash

###########################################
# script: Calculate SO params (oracle)    #
# date: 02/10/2015                        #
# version: 1.0                            #
# developed by: Rafael Mariotti           #
###########################################

source ~/.bash_profile

echo ""
echo "FILE: /etc/sysctl.conf"
echo ""
echo "kernel.sem = 250 32000 100 128"
TOTAL_MEM_BYTES=`free -b | grep "Mem:" | awk '{print $2}'`
SHMALL_TOTAL_MEM_PARCIAL=`echo "($TOTAL_MEM_BYTES/100)*90" | bc -l`
PAGE_SIZE=`getconf PAGE_SIZE`
SHMALL=`echo "scale=0; $SHMALL_TOTAL_MEM_PARCIAL/$PAGE_SIZE" | bc -l`
echo "kernel.shmall = $SHMALL"
SHMMAX_TOTAL_MEM_PARCIAL=`echo "scale=0; ($TOTAL_MEM_BYTES/100)*80" | bc -l`
echo "kernel.shmmax = $SHMMAX_TOTAL_MEM_PARCIAL"
echo "kernel.shmmni = 4096"
echo "fs.file-max = 6815744"
echo "fs.aio-max-nr = 6291456"
echo "net.ipv4.ip_local_port_range = 9000 65500"
echo "net.core.rmem_default = 16777216"
echo "net.core.rmem_max = 67108864"
echo "net.core.wmem_default = 16777216"
echo "net.core.wmem_max = 67108864"
echo "vm.swappiness = 10"
echo "vm.min_free_kbytes = 102400"
#Oracle oficial script - HUGE PAGES
KERN=`uname -r | awk -F. '{ printf("%d.%d\n",$1,$2); }'`
# Find out the HugePage size
HPG_SZ=`grep Hugepagesize /proc/meminfo | awk {'print $2'}`
# Start from 1 pages to be on the safe side and guarantee 1 free HugePage
NUM_PG=1
# Cumulative number of pages required to handle the running shared memory segments
for SEG_BYTES in `ipcs -m | awk {'print $5'} | grep "[0-9][0-9]*"`
do
   MIN_PG=`echo "$SEG_BYTES/($HPG_SZ*1024)" | bc -q`
   if [ $MIN_PG -gt 0 ]; then
      NUM_PG=`echo "$NUM_PG+$MIN_PG+1" | bc -q`
   fi
done
# Finish with results
case $KERN in
   '2.4') HUGETLB_POOL=`echo "$NUM_PG*$HPG_SZ/1024" | bc -q`;
          echo "vm.hugetlb_pool = $HUGETLB_POOL" ;;
   '2.6') if [ $NUM_PG -eq 1 ]; then
            red=`tput setaf 1`
            echo "#vm.nr_hugepages = ??? ${red}**Your database is not running. Please, startup and then execute this script again**"
          else
            echo "vm.nr_hugepages = $NUM_PG"
          fi ;;
    *) echo "vm.nr_hugepages = Unrecognized kernel version $KERN." ;;
esac
# End


echo ""
echo "FILE: /etc/security/limits.conf"
echo ""
echo "oracle		soft	nproc		16384"
echo "oracle		hard	nproc		16384"
echo "oracle		soft	nofile		1024"
echo "oracle		hard	nofile		65536"
echo "oracle       	soft	stack		10240"
echo "oracle		hard	stack		32768"
TOTAL_MEM_KBYTES=`free -k | grep "Mem:" | awk '{print $2}'`
MEMLOCK_TOTAL_MEM_PARCIAL=`echo "scale=0; ($TOTAL_MEM_KBYTES/100)*90" | bc -l`
echo "oracle         soft     memlock         $MEMLOCK_TOTAL_MEM_PARCIAL"
echo "oracle         hard     memlock         $MEMLOCK_TOTAL_MEM_PARCIAL"
echo ""
echo "grid		soft	nproc		16384"
echo "grid		hard	nproc		16384"
echo "grid		soft	nofile		1024"
echo "grid		hard	nofile		65536"
echo "grid		soft	stack		10240"
echo "grid		hard	stack		32768"
echo "grid           soft     memlock         $MEMLOCK_TOTAL_MEM_PARCIAL"
echo "grid           hard     memlock         $MEMLOCK_TOTAL_MEM_PARCIAL"
echo ""
