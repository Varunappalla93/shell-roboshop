# Day 17:
#!/bin/bash

# create an IAM user(Script user not real user) in AWS and we get access key and secrey key to interact with AWS console. 
# IAM user is used to execute shell commands.

# give aws configure in respective EC2 instance, eg:shell and give its access key, secret key and EC2 instance region to connect 
# that IAM user to EC2 instance. 

# config and creds are displayed in cd .aws/ and ls -la.

# give aws s3 ls to check if that IAM user is connected to EC2 instance.

# we need to run using sh 01_roboshop.sh mongodb catalogue etc, script to create multiple EC2 instances such as mongodb
# catalogue, cart, redis etc and its respective multiple route 53 A records.

# we push the shell scripts code which we created in our local machine, for eg, in VS code to github specific repo, 
# and from github, we clone the repo if its first time / pull the latest code the its specific EC2 instances, eg: mongodb EC2 instance
# and execute the specific script, eg: sudo sh mongodb.sh.

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