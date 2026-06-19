#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD

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

dnf install python3 gcc python3-devel -y
VALIDATE $? "Installing python"


id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user exists, Skipping it"
fi

mkdir -p /app
VALIDATE $? "Creating app directory if not exists"


curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOGS_FILE 
VALIDATE $? "Downloading payment code"


cd /app
VALIDATE $? "Going inside App Directory"

rm -rf /app/*
VALIDATE $? "Remove existing code"

unzip /tmp/payment.zip
VALIDATE $? "Extracting payment code to app directory"


pip3 install -r requirements.txt &>>$LOGS_FILE 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/payment.service
VALIDATE $? "Creating payment systemctl service"


systemctl daemon-reload
systemctl enable payment &>>$LOGS_FILE 
systemctl start payment
VALIDATE $? "Enabling and Starting payment"
