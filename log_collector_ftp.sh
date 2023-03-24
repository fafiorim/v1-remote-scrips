#!/bin/bash
#
# This script was created to demonstrate how to collect log files from a Linux host, compress and upload it to a FTP serve.
#
#	created by:Franz Fiorim
#	date: March 9, 2023


#get the paramentes and store them in variables
src_dir="$1"
dst_dir="$2"

host="$3"
user="$4"
passwd="$5"

timestamp=`date +%s`
date=`date +%Y-%m-%d_%H-%M-%S`
hostname=`hostname --fqdn`
os=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2`
instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

if [ -z "$src_dir" ] || [ -z "$dst_dir" ] || [ -z "$host" ] || [ -z "$user" ] || [ -z "$passwd" ]; then
    echo "Usage: sh $0 <source directory> <destination directory> <ftp> <host> <user> <password>"
    echo "e.g.: sh $0 /var/log/ /tmp/ ftp 10.1.1.200 user1 password1"
    exit 1
fi

#compressing the files to GZIP format
function log_compress ()
{   
    # check if source directory exists
    if [ ! -d "${src_dir}" ]; then
    echo "ERROR: no such file or directory '${src_dir}'\n"
    exit 1
    fi

    # check if destination directory exists
    if [ ! -d "${dst_dir}" ]; then
    echo "ERROR: no such file or directory '${dst_dir}'\n"
    exit 1
    fi

    filename="log_collector_${hostname}-${instance_id}-${date}.tar.gz"
    dst_dir="$dst_dir${filename}"

    echo "tar -zcvf $dst_dir $src_dir"
    tar -zcf $dst_dir $src_dir
    compressing=$?
}

# Upload the file to the ftp server
function ftp_upload ()
{
    echo "##############################################################"
    echo "DEBUG: curl -T $dst_dir ftp://$host --user $user:$passwd"
    curl -s -T $dst_dir ftp://$host --user $user:$passwd
    echo "##############################################################"
}

# printing function
function printing_execution_logs {
    echo "##############################################################"
    echo "###################### LOG COLLECTOR #########################"
    echo "##############################################################"
    echo "HOST INFO:"
    echo "Timestamp: $timestamp"
    echo "Date: $date"
    echo "Hostname: $hostname"
    echo "OS: $os"
    echo "Instance ID: $instance_id"
    echo "##############################################################"
    echo "Compressing the files in '$src_dir' to the '$dst_dir...'"
    echo "RESULT:"
    if [ $compressing -eq 0 ]; then
        echo "INFO: Backup created successfully"
        echo "INFO: Backup file: $dst_dir"
    else
        echo "ERROR: Backup failed"
    fi
}

# Main function
function main {
    log_compress
    ftp_upload
    printing_execution_logs
}

main