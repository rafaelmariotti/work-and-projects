#!/bin/bash

############################################
# script: atualiza versionamento no banco  #
# date: 23/12/2015                         #
# version: 1.1                             #
# developed by: rmariotti                  #
############################################

source ~/.bash_profile
username_db="user"
password_db="pass"

get_info(){

  while [ true ]; do
    echo ""
    echo "Does your deploy has database scripts? (y/n)"
    read db_deploy
    db_deploy=`echo "${db_deploy}" | awk '{print tolower($0)}'`

    if [[ "${db_deploy}" != @("y"|"n"|"yes"|"no") ]] ; then
      echo "  [ERROR] wrong answer. Try again."
      continue
    fi
    break
  done

  while [ true ]; do
    echo ""
    echo "Does your deploy has application changes? (y/n)"
    read app_deploy
    app_deploy=`echo "${app_deploy}" | awk '{print tolower($0)}'`

    if [[ "${app_deploy}" != @("y"|"n"|"yes"|"no") ]] ; then
      echo "  [ERROR] wrong answer. Try again."
      continue
    fi
    break
  done
}

check_options(){
  if [[ "${db_deploy}" == @("y"|"yes") ]] && [[ "${app_deploy}" == @("n"|"no") ]]; then
    only_database
  elif [[ "${app_deploy}" = @("y"|"yes") ]] && [[ "${db_deploy}" = @("n"|"no") ]]; then
    only_application
  elif [[ "${db_deploy}" = @("y"|"yes") ]] && [[ "${app_deploy}" = @("y"|"yes") ]]; then
    database_with_application
  else
    echo "So, why did you execute me?! stupid devops..."
  fi

}

only_database(){
  sqlplus -S $username_db/$password_db > /dev/null << EOF
set head off;
spool '/tmp/db_info.log';
SELECT db_version
  || '|'
  || TO_CHAR(deployed_at, 'dd/mm/yyyy hh24:mi')
  || '|'
  || developed_by AS db_version_info
FROM db_version
WHERE id_version =
  (SELECT MAX(id_version) FROM db_version
  );
spool off;
EOF

  db_version=`cat /tmp/db_info.log | grep -v "^$" | awk -F\| '{print $1}'`
  db_deployed_at=`cat /tmp/db_info.log | grep -v "^$" | awk -F\| '{print $2}'`
  db_developed_by=`cat /tmp/db_info.log | grep -v "^$" | awk -F\| '{print $3}'`

  red=`tput setaf 1`
  green=`tput setaf 2`
  yellow=`tput setaf 3`
  red=`tput setaf 9`
  reset=`tput sgr0`

  echo ""
  clear
  echo "Your current database version is $green${db_version}$reset deployed at $red${db_deployed_at}$reset by $yellow${db_developed_by}$reset "
  echo ""

  while [ true ]; do
    echo "  Please, type your new database version"
    read new_db_version

    test_db_version=`printf %02d.%02d.%02d $(echo $db_version | sed 's/\./ /g')`
    test_new_db_version=`printf %02d.%02d.%02d $(echo $new_db_version | sed 's/\./ /g')`

    if [ -n ${new_db_version} ] && [ -z `echo "${new_db_version}" | egrep "[1-9][0-9]{0,1}\.([0-9]|[1-9][0-9]{0,1})\.([0-9]|[1-9][0-9]{0,1})$"` ]; then
      echo "    [ ERROR ] new database version not compatible. Mask: {number}.{number}.{number}"
      continue
    elif [ $(expr ${test_new_db_version} \<= ${test_db_version}) -eq 1 ]; then
      echo "    [ ERROR ] type a version that is higher than current database version"
      continue
    fi
    break
  done

  while [ true ]; do
    echo "  Please, provide who is responsible for the new database changes (developer username)"
    read new_developed_by
    if [ -z "${new_developed_by}" ]; then
      echo "    [ ERROR ] developer name is empty. Please provide a valid developer username"
      continue
    fi
    break
  done

  echo "  If you want, you can type a comment about the new version (or just type enter to skip)"
  read new_db_note_from_developer

  if [ -z "${new_db_note_from_developer}" ]; then
    new_db_note_from_developer="null"
  else
    new_db_note_from_developer="'${new_db_note_from_developer}'"
  fi

  while [ true ]; do
    echo ""
    echo "Your new database version is $green${new_db_version}$reset developed by $yellow${new_developed_by}$reset. Are you sure? (y/n)"
    read answer
    answer=`echo "${answer}" | awk '{print tolower($0)}'`

    if [[ "${answer}" != @("y"|"n"|"yes"|"no") ]] ; then
      echo "  [ ERROR ] wrong answer. Try again"
      continue
    fi
    break
  done

  if [[ "${answer}" == @("y"|"yes") ]]; then
    sqlplus -S $username_db/$password_db > /tmp/result.log << EOF

  INSERT INTO db_version
  ( id_version, db_version, deployed_by, developed_by,note_from_developer )
  VALUES
  ( seq_db_version.nextval, '${new_db_version}', 'infra', '${new_developed_by}', ${new_db_note_from_developer} );
  commit;

EOF

    if [ `cat /tmp/result.log | grep -e "row" -e "Commit" | wc -l` -eq 2 ]; then
      echo ""
      echo "[ SUCCESS ] database version updated. Thank you!"
      echo ""
      rm -f /tmp/result.log
      rm -f /tmp/db_info.log

    else
      echo ""
      echo "[ ERROR ] error executing insert. Please, check log file $red/tmp/result.log$reset for more details"
      echo ""
      exit
    fi

  else
    echo "Process canceled"
    echo ""
    exit
  fi
}

only_application(){
  sqlplus -S $username_db/$password_db > /dev/null << EOF
  set head off;
  set pages 500;
  spool '/tmp/app_info.log';
  SELECT lower(app_r.app_name)
  || ' '
  || app_r.id_app
  || ' '
  || app_v.app_version
  || ' '
  || app_v.app_release
  || ' '
  || app_v.app_build
  result_
FROM app_registry app_r
JOIN app_version app_v
ON app_r.id_app   = app_v.id_app
WHERE deployed_at =
  (SELECT MAX(deployed_at)
  FROM app_version app_v2
  WHERE app_v2.id_app = app_v.id_app
  )
ORDER BY app_r.app_name;
  spool off;
EOF

  red=`tput setaf 1`
  green=`tput setaf 2`
  yellow=`tput setaf 3`
  red=`tput setaf 9`
  reset=`tput sgr0`

  echo ""
  clear
  echo "  Applications registered with this database"
  echo ""
  cat /tmp/app_info.log | grep -v "rows" | awk '{print $1}' | grep -v "^$" | sort -n
  echo "${red}end${reset}"


  while [ true ]; do
    echo ""
    echo "  Please, type what application you are deploying"

    read option
    option=`echo "${option}" | awk '{print tolower($0)}'`
    if [ "${option}" == "end" ]; then
      echo ""
      echo "Good Bye!"
      exit
    fi

    if [ -z "`cat /tmp/app_info.log | awk '{if ($1 == "'${option}'") print $0;}'`" ]; then
      echo "  [ ERROR ] application $red${option}$reset does not exists on the list. Please, type a valid application listed above"
      continue
    fi
    break
  done

  app_version=`cat /tmp/app_info.log | awk '{if ($1 == "'${option}'") print $0;}' | awk '{print $3}'`
  while [ true ]; do
    echo ""
    echo "  Application $yellow${option}$reset selected"
    echo "  Please, type your new application version (current version is $green${app_version}$reset)"
    read new_app_version

    test_app_version=`printf %02d.%02d.%02d $(echo $app_version | sed 's/\./ /g')`
    test_new_app_version=`printf %02d.%02d.%02d $(echo $new_app_version | sed 's/\./ /g')`

    if [ -n ${new_app_version} ] && [ -z `echo "${new_app_version}" | egrep "[1-9][0-9]{0,1}\.([0-9]|[1-9][0-9]{0,1})\.([0-9]|[1-9][0-9]{0,1})$"` ]; then
      echo "[ ERROR ] new application version not compatible"
      continue
    elif [ $(expr ${test_new_app_version} \<= ${test_app_version}) -eq 1 ]; then
      echo "[ ERORR ] type a version that is higher then current application version"
      continue
    fi
    break
  done

  app_release=`cat /tmp/app_info.log | awk '{if ($1 == "'${option}'") print $0;}' | awk '{print $4}'`
  while [ true ]; do
    echo ""
    echo "  Please, type your new application release (current release is $green${app_release}$reset)"
    read new_app_release

    if [ -z ${new_app_release} ]; then
      echo "[ ERROR ] application release is empty. Please provide a valid application release"
      continue
    fi
    break
  done

  app_build=`cat /tmp/app_info.log | awk '{if ($1 == "'${option}'") print $0;}' | awk '{print $5}'`
  while [ true ]; do
    echo ""
    echo "  Please, type your new application build (current build is $green${app_build}$reset)"
    read new_app_build

    test_app_build=`printf %02d.%02d $(echo $new_app_build | sed 's/./ /g')`
    test_new_app_build=`printf %02d.%02d.%02d $(echo $app_build | sed 's/\./ /g')`

    if [ -z ${new_app_build} ]; then
      echo "[ ERROR ] application build is empty. Please provide a valid application build"
      continue
    elif [ -z `echo "${new_app_build}" | egrep "[1-9][0-9]{0,4}$"` ]; then
      echo "[ ERROR ] new application build not compatible"
      continue
    elif [ ${new_app_build} -le ${app_build} ]; then
      echo "[ ERORR ] type a build that is higher then current application build"
      continue
    fi
    break
  done

  while [ true ]; do
    echo ""
    echo "  Please, provide who is responsible for the new application changes (developer username)"
    read new_app_developed_by

    if [ -z "${new_app_developed_by}" ]; then
      echo "[ ERROR ] developer name is empty. Please provide a valid developer username"
      continue
    fi
    break
  done

  echo ""
  echo "  If you want, you can type a comment about the new application (or just type enter to skip)"
  read new_app_note_from_developer

  if [ -z "${new_app_note_from_developer}" ]; then
    new_app_note_from_developer="null"
  else
    new_app_note_from_developer="'${new_app_note_from_developer}'"
  fi

  while [ true ]; do
    echo ""
    echo "Your application $yellow${option}$reset will be modified to version $green${new_app_version}$reset release $green${new_app_release}$reset build $green${new_app_build}$reset developed by $blue${new_app_developed_by}$reset. Are you sure? (y/n)"
    read answer
    answer=`echo "${answer}" | awk '{print tolower($0)}'`

    if [[ "${answer}" != @("y"|"n"|"yes"|"no") ]] ; then
      echo "  [ ERROR ] wrong answer. Try again"
      continue
    fi
    break
 done

  if [[ "${answer}" == @("y"|"yes") ]]; then
    app_id=`cat /tmp/app_info.log | awk '{if ($1 == "'${option}'") print $0;}' | awk '{print $2}'`
    sqlplus -S $username_db/$password_db > /tmp/result.log << EOF
    var last_db_version_id number

    begin
      select max(id_version) into :last_db_version_id from db_version;
    end;
    /

    INSERT INTO app_version
    ( id_deploy, id_app, app_version, app_release, app_build, id_db_version, deployed_by, developed_by, note_from_developer, note_from_infra )
    VALUES
    ( seq_app_version.nextval, ${app_id}, '${new_app_version}', '${new_app_release}', '${new_app_build}', :last_db_version_id, 'infra', '${new_app_developed_by}', ${new_app_note_from_developer}, null );
    commit;
EOF

    if [ `cat /tmp/result.log | grep -e "row" -e "Commit" | wc -l` -eq 2 ]; then
      echo ""
      echo "[ SUCCESS ] application version updated"
      rm -f /tmp/result.log
      rm -f /tmp/app_info.log

    else
      echo ""
      echo "[ ERROR ] Error executing insert. Please, check log file $red/tmp/result.log$reset for more details"
      echo ""
      exit
    fi

  else
    echo "Process canceled"
    echo ""
  fi

  while [ true ]; do
    echo ""
    echo "Do you want to change another application? (y/n)"
    read answer
    answer=`echo "${answer}" | awk '{print tolower($0)}'`

    if [[ "${answer}" != @("y"|"n"|"yes"|"no") ]] ; then
      echo "  [ERROR] wrong answer. Try again."
      continue
    fi
    break
  done

  if [[ "${answer}" == @("y"|"yes") ]]; then
    only_application
  elif [[ "${answer}" = @("n"|"no") ]]; then
    echo ""
    echo "Good Bye!"
    exit
  fi

}

database_with_application(){
only_database
only_application
}

main(){
get_info
check_options
}

main
