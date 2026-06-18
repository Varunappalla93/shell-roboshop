#!/bin/bash

SG_ID="sg-0f1fe41b89590d9f1"
AMI_ID="ami-0220d79f3f480ecf5"
DOMAIN_NAME="vardevops.online"

for instance in "$@"
do
  INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
       IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
    RECORD_NAME="$DOMAIN_NAME" # daws88s.online
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
         RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.vardevops.online
    fi
        echo "IP Address: $IP"
done
