#!/bin/bash

# Get IPs of hosts created by ASG where Ansible will configure
region="${1}"
asgName="${2}"

IP=$(aws autoscaling describe-auto-scaling-instances --region $region --output text --query "AutoScalingInstances[?AutoScalingGroupName=='$asgName'].InstanceId" | aws ec2 describe-instances --filters "Name=tag:Name,Values=$asgName" --instance-ids $ID --region $region --query "Reservations[].Instances[].PublicIpAddress" --output text | awk -v OFS="\n" '$1=$1')

sudo echo "[servers]" > /etc/ansible/hosts
sudo echo "${IP}" >> /etc/ansible/hosts

