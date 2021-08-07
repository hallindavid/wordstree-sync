#!/bin/bash

WORDSTREE_API=http://dashboard.wordstree.com
CONFIG_PATH="/home/$USER/.wordstree"
ACTION=""
DOCID=""
FILEPATH=""
TOKEN=""

die () {
    echo >&2 "$@"
    echo ""
    help
    exit 1
}

read_var() {
    VAR=$(grep $1 $2 | xargs)
    IFS="=" read -ra VAR <<< "$VAR"
    echo ${VAR[1]}
}

help()
{
   # Display Help
   echo "Syntax: wtsync.sh [action] [document_id] [file]"

   echo "actions are push|pull     tells the script which direction to write"
   echo "document_id               the wordstree document_id"
   echo "file                      a valid path/file name"
   echo
}

setup()
{
  # Check to see if our ~/.wordstree config file exists 
  if [ ! -f "$CONFIG_PATH" ] ; then
    touch "$CONFIG_PATH"
    echo "token=" > "$CONFIG_PATH"
  fi
  
  # If the token is not in the config file, we begin the auth process
  if ! grep -Fq "token=" "$CONFIG_PATH" ; then
    printf "Wordstree Token not found, Initiating Auth process\n"
    auth
    die ""
  fi

  # Retreive the token and assign it to a variable
  TOKEN=$(read_var token "$CONFIG_PATH")  
  
  # Ensure we have 3 parameters
  [ "$#" -ge 3 ] || die "3 argument required, $# provided"
  
  # Ensure that we have a valid action
  [[ $1 == "push" || $1 == "pull" ]] || die "Action must be either 'push' or 'pull'.  $1 provided"
  ACTION="$1"

  # Ensure that Document ID is an integer (other validation occurs during sync)
  echo $2 | grep -E -q '^[0-9]+$' || die "Document ID must be a valid integer.  $2 provided"
  DOCID="$2"

  # Ensure that file path is valid and file exists
  if [ -f "$3" ] ; then
    die "Invalid File Path.  $3 provided"
  fi
  FILEPATH="$3"
}

auth()
{
  read -p "Please enter your wordstree email address: " EMAIL
  read -sp "Please enter your password: " PWD
  
  EMAIL="email=$EMAIL"
  PWD="password=$PWD"
  
  WTRESPONSE=$(curl --location --request POST '${WORDSTREE_API}/api/login' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Accept: application/json' \
--data-urlencode $EMAIL \
--data-urlencode $PWD )
  
  if [ ${#WTRESPONSE} -lt 50 ] ; then
    die "invalid credentials"
  else
    TOKEN=$( echo $WTRESPONSE | jq -r '.token')
    echo "token=$TOKEN" > "$CONFIG_PATH"
  fi
}

checkdoc()
{
  if [[ $2 && $2 == '--markdown' ]]; then
    # get pure markdown
    $(curl -o $1 --location --request GET "$WORDSTREE_API/api/markdown-documents/$DOCID/download" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer $TOKEN" )
    exit 1
  fi

  if [[ $1 == '--show' ]]; then
    # get pure markdown
    echo $(curl -s --location --request GET "$WORDSTREE_API/api/markdown-documents/$DOCID/download" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header "Authorization: Bearer $TOKEN" ) > .temp
    less .temp
    rm .temp
    exit 1
  fi

  # get JSON
  echo $(curl -o $1 --location --request GET "$WORDSTREE_API/api/markdown-documents/$DOCID" \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --header "Authorization: Bearer $TOKEN" )
}

checkdependency()
{
  jqcommand=$(echo $(command -v $1) | wc -c)
  if [[ ${#jqcommand} < 2 ]]; then
    echo $1;
    return 1
  fi

  return 0
}

checkdependencies()
{
  DEPENDENCIES_OUTPUT=""
  DEPENDENCIES_OUTPUT="${DEPENDENCIES_OUTPUT} $(checkdependency jq)"
  DEPENDENCIES_OUTPUT="${DEPENDENCIES_OUTPUT} $(checkdependency curl)"

  if [[ ${#DEPENDENCIES_OUTPUT} > 3 ]]; then
    echo "################################"
    echo "Dependencies missing: ${DEPENDENCIES_OUTPUT}"
    echo "################################"
    exit 1
  fi
}

checkdependencies

# This is really a setup and validate function
setup "$@"

checkdoc $3 $4
