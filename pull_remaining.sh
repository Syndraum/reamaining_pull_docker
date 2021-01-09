#!/bin/bash

violet=$'\033[94m'
reset=$'\033[0;39m'

#			print_message(message)
function	print_message {
	echo -e "${violet}$1${reset}"
}

#			anonymous_token()
function	anonymous_token {
	TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
}
#			user_token(username, password)
function	user_token {
	TOKEN=$(curl -s --user "$1:$2" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
}

dpkg -s jq >/dev/null 2>/dev/null
if [ "$?" = "1" ];then
	print_message "jq is not installed"
	echo -n "Would you like to install jq ? (Y/N) : "
	read rep
	if [ "$rep" = "Y" -o "$rep" = "y" ];then
		print_message "Enter your password :"
		sudo apt-get install jq
	else
		echo "Script stopped by user"
		exit 1
	fi
fi

if [ "$1" == "-a" ];then
	anonymous_token
elif [ "$1" == "-u" ];then
	if [ -z "$2" ];then
		echo -n "Enter your username : "
		read username
	else
		username=$2
	fi
	echo -n "Enter your password : "
	read -s password
	echo ""
	user_token $username $password
else
	echo -n "Are you anonymous ? (Y/N) : "
	read rep
	if [ "$rep" = "Y" -o "$rep" = "y" ];then
		anonymous_token
	else
		echo -n "Enter your username : "
		read username
		echo -n "Enter your password : "
		read -s password
		echo ""
		user_token $username $password
	fi
fi
rm -f request.txt
curl -s --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest > request.txt
$(cat request.txt | grep RateLimit-Limit >/dev/null 2>/dev/null)
if [ "$?" == "1" ];then
	echo "Error: wrong token"
	exit 1
fi
limit=$(cat request.txt | grep RateLimit-Limit | cut -f 2 -d' ' | cut -f 1 -d';')
remaining=$(cat request.txt | grep RateLimit-Remaining | cut -f 2 -d' ' | cut -f 1 -d';')
printf "%*d pull limit\n" ${#limit} $limit
printf "%*d pull remaining\n" ${#limit} $remaining
rm -f request.txt
exit 0
