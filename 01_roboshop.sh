# Day 17:
#!/bin/bash

# create an IAM user(Script user not real user) to interact with AWS console.

# config and creds are displayed in cd .aws/ and ls -la.
# aws s3 ls  - to check if s3 buckets are connected.

# give aws configure in respective ec2 instance, eg:shell and give access key and secret key and 
# need to run using sh 01_roboshop.sh mongodb catalogue etc script to create multiple instances such as mongodb
# catalogue, cart, redis etc and respective multiple route 53 A records.

SG_ID="sg-027080a66d5d9f364"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z07749522UFFTP3DDWVZQ"
DOMAIN_NAME="vardevops.online"

for instance in $@   # sh 01_roboshop.sh mongodb catalogue etc.
do
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text )

    if [ $instance == "frontend" ]; then
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PublicIpAddress' \
            --output text
        )
        RECORD_NAME="$DOMAIN_NAME" # vardevops.online
    else
        IP=$(
            aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
        )
        RECORD_NAME="$instance.$DOMAIN_NAME" # eg: mongodb.vardevops.online
    fi
    echo "IP Address is $IP"

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
    }
    '

    echo "Record is updated for $instance"
done