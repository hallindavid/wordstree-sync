#!/bin/bash

CONFIG_PATH="/home/$USER/.wordstree"
ACTION=""
DOCID=""
FILEPATH=""
TOKEN=""

die () {
    echo >&2 "$@"
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
  if ! grep -Fq "token=" "$CONFIG_PATH" 
  then
    printf "Wordstree Token not found, Initiating Auth process\n"
    auth
  fi

  # Retreive the token and assign it to a variable
  TOKEN=$(read_var token "$CONFIG_PATH")  
  
  # Ensure we have 3 parameters
  [ "$#" -eq 3 ] || die "3 argument required, $# provided"
  
  # Ensure that we have a valid action
  [[ $1 == "push" || $1 == "pull" ]] || die "Action must be either 'push' or 'pull'.  $1 provided"
  ACTION="$1"
  # Ensure that Document ID is an integer (other validation occurs during sync)
  echo $2 | grep -E -q '^[0-9]+$' || die "Document ID must be a valid integer.  $2 provided"
  DOCID="$2"
  # Ensure that file path is valid and file exists
  if [ ! -f "$3" ] ; then
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
  
  WTRESPONSE=$(curl --location --request POST 'https://dashboard.wordstree.com/api/login' \
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

	
 $(curl --location --request GET 'https://dashboard.wordstree.com/api/markdown-documents/${DOCID}' \
	--header 'Content-Type: application/json' \
	--header 'Accept: application/json' \
	--header 'Authroization: Bearer ${TOKEN}' )
#	echo "$WTRESP"

}

# This is really a setup and validate function
setup "$@"


checkdoc



