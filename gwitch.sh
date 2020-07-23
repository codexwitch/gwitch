#!/bin/bash

usage="Usage: $0 [ -a | -s | -d ] username

where:
    -a  add new Github username
    -s  switch to existing Github user
    -d  remove Github username from app data"

usage() { echo "$usage"; exit 1; }

checkarg() {
    if [ -z "${OPTARG}" ]; then
        usage
    fi
}

# data is stored in ~/gwitch/users.csv

while getopts "a:s:d:" flag; do
    case "${flag}" in
        # a: add new username
        a)
            checkarg
            user=${OPTARG}
            curdir=$(pwd)
            read -p "Enter email address: " email
            cd ~/.ssh
            ssh-keygen -t rsa -C "$email" -f "github-$user"
            ssh-add -K github-$user.pub
            pbcopy < github-$user.pub
            echo "SSH key copied to clipboard. Login to your Github account using your browser of choice and go to github.com/settings/ssh/new to add your key to your account."
            read -p "Press enter to continue. " muda
            if [ ! -f ./config ]; then
                touch ./config
            fi
            printf "Host github.com-$user\n  HostName github.com\n  User git\n  IdentityFile ~/.ssh/github-$user\n  IdentitiesOnly yes\n\n" >> ./config
            if [ ! -d ~/gwitch ]; then
                mkdir ~/gwitch
            fi
            cd ~/gwitch
            if [ ! -f ./users.csv ]; then
                touch users.csv
            fi
            printf "$user,$email\n" >> ./users.csv
            cd $curdir
            echo  "Github user $user with email address $email successfully added to gwitch."
            read -p "Set this account as the default account? (Y/n)" glob
            if [ "$glob" == "Y" -o "$glob" == "y" ]; then
                git config --global user.name "$user"
                git config --global user.email "$email"
                echo "Default Github user set to $user."
            fi
            exit 0
            ;;
        # s: switch to username
        s)
            if [ ! -d ~/gwitch ]; then
                echo "No app data found. Use $0 -a to add accounts."
                exit 1
            fi
            checkarg
            user=${OPTARG}
            email=$(grep "$user" ~/gwitch/users.csv)
            if [ -z "$email" ]; then
                echo "User not recognized. Use $0 -a to add accounts."
                exit 1
            fi
            email=$(echo "$email" | awk -F, '{print $2}')
            {
                git config user.name "$user"
                git config user.email "$email"
            } || exit 1
            echo "Github user set to $user with email address $email."
            exit 0
            ;;
        # d: remove username
        d)
            if [ ! -d ~/gwitch ]; then
                echo "No app data found. Use $0 -a to add accounts."
                exit 1
            fi
            checkarg
            user=${OPTARG}
            if [ -z $(grep "$user" ~/gwitch/users.csv) ]; then
                echo "User not recognized. Use $0 -a to add acocunts."
                exit 1
            fi
            read -p "OK to remove $user? (Y/n)" cont
            if [ "$cont" != "Y" -a "$cont" == "y" ]; then
                echo "Operation aborted."
                exit 0
            fi
            sed -i '/$user,*\n/d'
            echo "Github user $user removed from app data."
            exit 0
            ;;
    esac
done

# user does not know how to run the program. teach them a lesson!
usage