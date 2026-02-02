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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Added RabbitMQ repo"

dnf install rabbitmq-server -y &>>$LOGS_FILE
VALIDATE $? "Installing RabbitMQ server"

systemctl enable rabbitmq-server &>>$LOGS_FILE
systemctl start rabbitmq-server
VALIDATE $? "Enabled and started rabbitmq"

rabbitmqctl add_user roboshop roboshop123 &>>$LOGS_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGS_FILE
VALIDATE $? "created user and give permissions"