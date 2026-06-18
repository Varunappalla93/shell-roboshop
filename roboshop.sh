#!/bin/bash

SG_ID="sg-0f1fe41b89590d9f1"
AMI_ID="ami-0220d79f3f480ecf5"
DOMAIN_NAME="vardevops.online"
ZONE_ID="Z0250438Z6CI85HTN7SE"

# All this will be in a loop until all our given name instances will be created and route 53 domain names and A record respective values are 
# updated with instance IPs.

# create ec2 instances using sh roboshop.sh mongodb catalogue redis etc.
for instance in "$@"
do
  INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    # if frontend is instance name, get its public ip
    if [ $instance == "frontend" ]; then
       IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        # and update route 53 record domain name
    RECORD_NAME="$DOMAIN_NAME" # daws88s.online
    #  if anything other than frontend is instance name, get its private ip
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        # and update route 53 record domain name
         RECORD_NAME="$instance.$DOMAIN_NAME" # mongodb.vardevops.online
    fi
        echo "IP Address: $IP"

    # update route 53 domain names and A record respective values with instance IPs.
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record",
        "Changes": [
            {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
    }'
        echo "record updated for $instance"
done
