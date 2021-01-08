#!/bin/bash

violet=$'\033[94m'
reset=$'\033[0;39m'

#			print_message(message)
function	print_message {
	echo -e "${violet}$1${reset}"
}

function	anonyme_token {
	TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
}

dpkg -s jq >/dev/null 2>/dev/null
if [ "$?" = "1" ];then
	print_message "jq is not installed"
	echo -n "Would you want install jq ? (Y/N) : "
	read rep
	if [ "$rep" = "Y" -o "$rep" = "y" ];then
		print_message "Enter your password :"
		sudo apt-get install jq
	else
		echo "script stop by user"
		exit 1
	fi
fi

if [ "$1" == "-a" ];then
	anonyme_token
else
	echo -n "Are you anonymous ? (Y/N) : "
	read rep
	if [ "$rep" = "Y" -o "$rep" = "y" ];then
		anonyme_token
	else
		echo -n "Enter your username : "
		read username
		echo -n "Enter your password : "
		read -s password
		TOKEN=$(curl -s --user "$username:$password" "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq -r .token)
	fi
fi
rm -f request.txt
curl -s --head -H "Authorization: Bearer $TOKEN" https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest > request.txt
if [ "$?" == "1" ];then
	echo "Error worng token"
	exit 1
fi
limit=$(cat request.txt | grep RateLimit-Limit | cut -f 2 -d' ' | cut -f 1 -d';')
remaining=$(cat request.txt | grep RateLimit-Remaining | cut -f 2 -d' ' | cut -f 1 -d';')
echo "$remaining pull limit"
echo "$remaining pull remaining"
rm -f request.txt
exit 0