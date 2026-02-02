# Day 18:
#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"

# colors
NORMAL='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
BLUE='\e[33m'

# SCRIPT_DIR=$PWD # not recommended.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)  # Where the script file lives
MYSQL_HOST=mysql.vardevops.online


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

dnf install maven -y &>>$LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "Roboshop user exists, hence $RED skipping $NORMAL"
fi

mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading shipping code"


cd /app
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOGS_FILE
VALIDATE $? "Uzip shipping code"

cd /app 
mvn clean package &>>$LOGS_FILE
VALIDATE $? "Installing and Building shipping"


mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and Renaming shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y  &>>$LOGS_FILE
VALIDATE $? "Installing MySQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "status" &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo -e "$RED Error: Cannot connect to MySQL. Check credentials/permissions. $NORMAL"
    exit 1
fi

# Check if DB exists
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    echo "Loading Schema..."
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
    VALIDATE $? "Loading MySQL Data"
else
    echo -e "Data already exists... $BLUE SKIPPING $NORMAL"
fi

systemctl enable shipping &>>$LOGS_FILE
systemctl restart shipping
VALIDATE $? "Enabled and restarted shipping"