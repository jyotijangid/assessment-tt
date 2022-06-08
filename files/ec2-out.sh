#!/bin/bash

# get all running ec2-instances in a region

echo "<pre>" > /usr/local/nginx/ec2/index.html
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value[],PublicIpAddress,Tags[]]' --output yaml >> /usr/local/nginx/ec2/index.html
echo "</pre>" >> /usr/local/nginx/ec2/index.html

