create_user(){
  host=$1
  user_admin=$2
  export PGPASSWORD=$3
  database_admin=$4
  user_to_create=$5

  psql -h ${host} -U $${user_admin} ${database_admin} << EOF
    --create group desenv;
    create user ${user_to_create} with password 'bio123';
    alter group desenv add user ${user_to_create};
EOF
}

main(){
  {user_to_create}=$1

  #copy this command and fill the variables as many time as you want, keeping just the last variable
  create_user ${hostname} ${super_username} ${super_password} ${super_database} ${user_to_create}
}

main $1
