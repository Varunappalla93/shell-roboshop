# Day 17:
#!/bin/bash
USERID=$(id -u)
SCRIPT_DIR=$PWD
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"
MONGODB_HOST=mongodb.vardevops.online
# colors
NORMAL='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[33m'


if [ $USERID -ne 0 ]; then
    echo -e "$RED Pls run this script with root user access $NORMAL"
    exit 1
fi

mkdir -p $LOGS_FOLDER

# Validate function
VALIDATE()
{
if [ $1 -ne 0 ]; then
    echo -e "$2... $RED failed $NORMAL" | tee -a $LOGS_FILE
    exit 1
else
    echo -e "$2... $GREEN success $NORMAL" | tee -a $LOGS_FILE
fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "disabling node js default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "enabling node js 20 version"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "installing node js"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user exists, hence $RED skipping $NORMAL"
fi

mkdir -p /app 
VALIDATE $? "Creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Remove existing code"

unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping the catalogue code"

npm install &>>$LOGS_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl catalogue service"

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable catalogue &>>$LOGS_FILE
systemctl start catalogue &>>$LOGS_FILE
VALIDATE $? "enabling and starting catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb client mongosh"

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then    
     mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
     VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $BLUE SKIPPING $NORMAL"
fi

systemctl restart catalogue &>>$LOGS_FILE
VALIDATE $? "Restarting catalogue"