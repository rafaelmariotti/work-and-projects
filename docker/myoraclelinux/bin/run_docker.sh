#!/bin/bash
source ~/.bash_profile
docker_home=/opt/docker/oracle_conf

static_variables(){
  #DO NOT change this values!
  total_mem_bytes=`free -b | grep "Mem:" | awk '{print $2}'`
  shmall_total_mem_parcial=`echo "(${total_mem_bytes}/100)*90" | bc -l`
  page_size=`getconf PAGE_SIZE`
  shmall_value=`echo "scale=0; ${shmall_total_mem_parcial}/${page_size}" | bc -l`

  total_mem_kbytes=`free -k | grep "Mem:" | awk '{print $2}'`
  memlock_value=`echo "scale=0; (${total_mem_kbytes}/100)*90" | bc -l`

}

dynamic_variables(){
  oracle_user_pass_value="mariotti123*"
}


main(){
  static_variables
  dynamic_variables

  docker kill `docker ps -a | grep -v "CONTAINER ID" | grep -v "oraclelinux:6\.7.*oracle_template" | awk '{print $1}'`
  docker rm `docker ps -a | grep -v "CONTAINER ID" | grep -v "oraclelinux:6\.7.*oracle_template" | awk '{print $1}'`
  docker rmi `docker images | grep -e "<none>" -e latest | awk '{print $3}'`

  cp $docker_home/conf/Dockerfile.template $docker_home/conf/Dockerfile
  sed -i "s|\${shmall_env}|${shmall_value}|g" $docker_home/conf/Dockerfile
  sed -i "s|\${memlock_env}|${memlock_value}|g" $docker_home/conf/Dockerfile
  sed -i "s|\${oracle_user_pass_env}|${oracle_user_pass_value}|g" $docker_home/conf/Dockerfile
  sed -i "s|\${docker_home_env}|${docker_home}|g" $docker_home/conf/Dockerfile

  docker build -t teste:latest --memory="2g" --memory-swap="4g" $docker_home/conf
  docker run -ti --privileged=true --memory="2g" --memory-swap="4g" -h oracle-docker --net=host --name oracle_template_teste teste:latest /bin/bash
  #rm -f $docker_home/Dockerfile
}

main
