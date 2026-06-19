#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.vardevops.online

if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling nodejs"


dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing nodejs"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user exists, Skipping it"
fi


mkdir -p /app
VALIDATE $? "Creating app directory if not exists"


curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOGS_FILE 
VALIDATE $? "Downloading user code"

cd /app
VALIDATE $? "Going inside App Directory"

rm -rf /app/*
VALIDATE $? "Remove existing code"


unzip /tmp/user.zip
VALIDATE $? "Extracting user code to app directory"

npm install &>>$LOGS_FILE 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Creating user systemctl service"

systemctl daemon-reload
systemctl enable user &>>$LOGS_FILE 
systemctl start user
VALIDATE $? "Enabling and Starting user"
