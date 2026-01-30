#!/bin/bash
USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="$LOGS_FOLDER/$0.log"
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

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongo repo"

dnf install mongodb-org -y &>>$LOGS_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOGS_FILE
VALIDATE $? "Enable mongodb"

systemctl start mongod &>>$LOGS_FILE
VALIDATE $? "Start mongodb"


# sed streamline editor
# sed "1a hi" users -> adds text after line 1 , this is temporary change only on screen its displayed
# sed -i "1a hi" users -> adds text after line 1 , this is permanent change affects the file
# sed '1i QA' users  -  Before line 1, add QA
# sed '2d' users - delete 2nd line
# sed '/sbin/d' users - delete all sbin lines
# sed 's/sbin/SBIN/g' users - to replace sbin with SBIN in all lines in all occurrences
# sed '3s/sbin/SBIN/g' users - to replace 3rd line sbin with SBIN in all occurrences

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections"

systemctl restart mongod
VALIDATE $? "Restarted mongodb"