#!/bin/bash
#
# This script was created to demonstrate how interact with Trend Micro Vision One to migrate C1WS agents from one tenant to another using the Vision One Remote Scrips.
#
#	created by:Franz Fiorim
#	date: Marchr 22, 2023


#get the paramentes and store them in variables
dsm="$1"
tenantID="$2"
token="$3"

policyID="$4"
groupID="$5"

#geting system information
timestamp=`date +%s`
date=`date +%Y-%m-%d_%H-%M-%S`
hostname=`hostname --fqdn`
os=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2`
kernel=`uname -r`
agent_version=`cat /opt/ds_agent/version.txt | cut -d ' ' -f7`
uptime_before=`uptime`
uptime_after=""

# creating a temporary directory to store the agent information
mkdir /tmp/agent_migration

function collect_agent_information_old()
{
    #getting the agent information
    /opt/ds_agent/sendCommand --get GetConfiguration | grep hostGUID > /tmp/agent_migration/sendCommand_output_old.txt
    #parse the output - replacing spaces with new lines
    sed -i 's/\s\+/\n/g' /tmp/agent_migration/sendCommand_output_old.txt

    #tenantname
    #e.g.: tenantName='habibidog'
    tenantName_old=`cat /tmp/agent_migration/sendCommand_output_old.txt | grep tenantName | cut -d "'" -f2`

    #dsmUrls
    #e.g.: dsmUrls='https://agents.deepsecurity.trendmicro.com:443/'
    dsmUrls_old=`cat /tmp/agent_migration/sendCommand_output_old.txt | grep dsmUrls | cut -d "'" -f2`

    #hostID
    #e.g.: hostID='2047'
    hostID_old=`cat /tmp/agent_migration/sendCommand_output_old.txt | grep hostID | cut -d "'" -f2`

    # V1 senderGUID / C1 tenantGUID='5BAB243A-4310-4EBE-81C7-E5FDDF6D5292
    tenantGUID_old=`cat /tmp/agent_migration/sendCommand_output_old.txt | grep tenantGUID | cut -d "'" -f2`

    # V1 endpointGUID / hostGUID='3180D8F8-4672-CA1F-F2CE-A42C9EEDD5ED'
    endpointGUID_old=`cat /tmp/agent_migration/sendCommand_output_old.txt | grep hostGUID | cut -d "'" -f2`

}

function collect_agent_information_new()
{
    #getting the agent information
    /opt/ds_agent/sendCommand --get GetConfiguration | grep hostGUID > /tmp/agent_migration/sendCommand_output_new.txt
    #parse the output - replacing spaces with new lines
    sed -i 's/\s\+/\n/g' /tmp/agent_migration/sendCommand_output_new.txt

    #tenantname
    #e.g.: tenantName='habibidog'
    tenantName_new=`cat /tmp/agent_migration/sendCommand_output_new.txt | grep tenantName | cut -d "'" -f2`

    #dsmUrls
    #e.g.: dsmUrls='https://agents.deepsecurity.trendmicro.com:443/'
    dsmUrls_new=`cat /tmp/agent_migration/sendCommand_output_new.txt | grep dsmUrls | cut -d "'" -f2`

    #hostID
    #e.g.: hostID='2047'
    hostID_new=`cat /tmp/agent_migration/sendCommand_output_new.txt | grep hostID | cut -d "'" -f2`

    # V1 senderGUID / C1 tenantGUID='5BAB243A-4310-4EBE-81C7-E5FDDF6D5292
    tenantGUID_new=`cat /tmp/agent_migration/sendCommand_output_new.txt | grep tenantGUID | cut -d "'" -f2`

    # V1 endpointGUID / hostGUID='3180D8F8-4672-CA1F-F2CE-A42C9EEDD5ED'
    endpointGUID_new=`cat /tmp/agent_migration/sendCommand_output_new.txt | grep hostGUID | cut -d "'" -f2`

}

# checking parameters passed to the script validating, if not enough parameters are passed and printing usage example 
if [ -z "$dsm" ] || [ -z "$tenantID" ] || [ -z "$token" ] || [ -z "$policyID" ] || [ -z "$groupID" ]; then
    echo "Usage: sh $0 dsm <tenantID> <token> <policyID> <groupID>"
    echo 'e.g.: sh $0 dsm://agents.deepsecurity.trendmicro.com:443/ "tenantID:5BAB243A-4310-4EBE-81C7-E5FDDF6D5292" "token:EB5C2E13-F676-8979-22C4-21A5F31770D7" "policyid:662" "groupid:529"'
    exit 1
fi

activation_cmd="/opt/ds_agent/dsa_control -a $dsm $tenantID $token $policyID $groupID"

# leveraging the agent CLI to deactivate/reset the agent
function deactivate ()
{   
    echo "###################### DEACTIVATION ##########################"
    echo "INFO: Deactivating the agent..."
    /opt/ds_agent/dsa_control -r
    if [ $? -eq 0 ]; then
        echo "INFO: Agent deactivated successfully"
    else
        echo "ERROR: Agent deactivation failed"
    fi
    echo "##############################################################"
}

# leveraging the agent CLI to activate the agent
function activate ()
{
    echo "###################### ACTIVATION  ###########################"
    echo "INFO: Activating the agent..."

    /opt/ds_agent/dsa_control -a $activation_cmd
    if [ $? -eq 0 ]; then
        echo "INFO: Agent activated successfully"
    else
        echo "ERROR: Agent activation failed"
    fi
    echo "##############################################################"
    echo "                                                              "
    uptime_after=`uptime`
}

###Notes: Add description (old and new one)
### kernel version?
# printing function
function printing_execution_logs {
    echo "##############################################################"
    echo "################### AGENT MIGRATOR SCRIPT ####################"
    echo "##############################################################"
    echo "HOST INFO:"
    echo "Timestamp: $timestamp"
    echo "Date: $date"
    echo "Hostname: $hostname"
    echo "OS: $os"
    echo "Kernel: $kernel"
    echo "Uptime: $uptime_before"
    echo "##############################################################"
    echo "                                                              "
    echo "########################### [OLD] ############################"
    echo "CLOUD ONE/DEEP SECURITY MANAGER INFO [OLD]:"
    echo "Agent version: $agent_version"
    echo "Tenant Name: $tenantName_old"
    echo "DSM URL: $dsmUrls_old"
    echo "HOST ID: $hostID_old"
    echo "TENANT ID: $tenantGUID_old" #tenantID
    echo "ENDPOINT GUID: $endpointGUID_old"
    echo "##############################################################"
    echo "                                                              "
    echo "#################### [WHAT WAS EXECUTED] #####################"
    echo "Activation command used: $activation_cmd"
    echo "New DSM: $tenantID"
    echo "Policy ID: $policyID"
    echo "Group ID: $groupID"
    echo "##############################################################"
    echo "                                                              "
    echo "########################### [NEW] ############################"
    echo "CLOUD ONE INFO [NEW]:"
    echo "Agent version: $agent_version"
    echo "Tenant Name: $tenantName_new"
    echo "DSM URL: $dsmUrls_new"
    echo "HOST ID: $hostID_new"
    echo "TENANT ID: $tenantGUID_new" #tenantID
    echo "ENDPOINT GUID: $endpointGUID_new"
    echo "Uptime: $uptime_after"
    echo "##############################################################"
}

# Main function
function main {
    collect_agent_information_old
    deactivate
    activate
    collect_agent_information_new
    printing_execution_logs
}

main

#./migration_c1ws_agents.sh "dsm://agents.deepsecurity.trendmicro.com:443/" "tenantID:5BAB243A-4310-4EBE-81C7-E5FDDF6D5292" "token:EB5C2E13-F676-8979-22C4-21A5F31770D7" "policyid:662" "groupid:529"
