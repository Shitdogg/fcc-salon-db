#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {
  # ถ้ามีข้อความ error ส่งเข้ามา เอาไว้ใช้งาน ใน กรณีที่ ต้องการ reset message mene ใหม้
  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo "Welcome to My Salon, how can I help you?"
  fi

  # select ข้อมูล services เอาไว้ เลือกในตอนแรก
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")

  # แสดง list โดยการ อ่าน ข้อมูลที่ได้มา แยกโดย | ซึ่ง pipe จะได้ มาหลังจาก select ข้อมูลมาจาก database
  echo "$SERVICES" | while IFS="|" read ID NAME
  do
    echo "$ID) $NAME"
  done

  # รับ input มาจาก ผู้ใช้งาน
  read SERVICE_ID_SELECTED

  # เช็คว่า input ที่เข้ามานั้นมี id อยู่ใน database หรือไม่
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED;")

  
  if [[ -z $SERVICE_NAME ]]
  # -z เพื่อ เช็ค ว่า มี name ใหม่ ถ้าไม่มี id ก้จะเป็น ""
  then
    # service name = "" ก็จะ ใส่ message เข้าไปใน arg1 เพื่อให้ main menu แสดง message error 
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    # ถ้าใส่ input เข้ามา มี id จริง ก็จะ ถามหา phone number
    echo -e "\nWhat's your phone number?"
    # รับ input เบอโทรมาใช้งาน
    read CUSTOMER_PHONE

    # ตรวจสอบว่าลูกค้าเคยมีในระบบไหม โดยใช้งาน หมายเลขโทรศัพท์
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")

    # ถ้ายังไม่มีก็ขอชื่อแล้วเพิ่มเข้าไป
    if [[ -z $CUSTOMER_ID ]]
    then
      echo -e "\nWhat's your name?"
      read CUSTOMER_NAME
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE');")
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE';")
    else
      # ถ้ามี อยู่แล้ว ก็ เอา name มา
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID;")
    fi

    # ขอเวลานัด
    echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
    read SERVICE_TIME

    # recode เวลา 
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME');")

    # แสดงข้อความยืนยัน
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

MAIN_MENU
