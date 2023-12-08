#!/bin/sh

get_file() {
    local DATA_PATH="${PWD}/data/"
    local FILE_NAME="data"
    local FILE_EXT='.txt'
    if ! [ -e $DATA_PATH ]; then
        mkdir $DATA_PATH
    fi
    echo "$DATA_PATH$FILE_NAME$FILE_EXT"
}

add_data() {
    echo "サービス名を入力してください："
    read SERVICE_NAME
    echo "ユーザー名を入力してください："
    read USER_NAME
    echo "パスワードを入力してください："
    read PASSWORD
    if [ $SERVICE_NAME ] && [ $USER_NAME ] && [ $PASSWORD ]; then
        write_file $SERVICE_NAME $USER_NAME $PASSWORD
    else
        local RED='\033[0;31m'
        local NO_COLOR='\033[0m'
        local ERROR_DATA=""
        if [ -z $SERVICE_NAME ]; then
            ERROR_DATA="サービス名"
        fi
        if [ -z $USER_NAME ]; then
            if [ $ERROR_DATA ]; then
                ERROR_DATA=""$ERROR_DATA"とユーザー名"
            else
                ERROR_DATA="ユーザー名"
            fi
        fi
        if [ -z $PASSWORD ]; then
            if [ $ERROR_DATA ]; then
                ERROR_DATA=""$ERROR_DATA"とパスワード"
            else
                ERROR_DATA="パスワード"
            fi
        fi
        echo "パスワードの追加は${RED}失敗${NO_COLOR}しました。"$ERROR_DATA"を入力してください。"
    fi
}

write_file() {
    local SERVICE_NAME=$1
    local CURRENT_USERNAME=$2
    local PASSWORD=$3
    local FILE=$(get_file)
    local FILE_CONTENT=""
    if [ -e $FILE ]; then
        FILE_CONTENT=$(cat $FILE)
    fi
    # encode SERVICE_NAME and CURRENT_USERNAME
    # to pretend that user input colon(:) to introduce bug
    echo "$(encode_base64_string $SERVICE_NAME):$(encode_base64_string $CURRENT_USERNAME):$(encode_password $PASSWORD)\n$FILE_CONTENT\n" >$FILE
    echo "パスワードの追加は成功しました。"
}

read_file() {
    echo "サービス名を入力してください："
    read SERVICE_NAME
    local FILE=$(get_file)
    print_empty_line
    if [ -e $FILE ]; then
        print_data $FILE $SERVICE_NAME
    else
        echo "そのサービスは登録されていません。"
    fi
}

print_data() {
    local FILE=$1
    local SERVICE_NAME="$(encode_base64_string $2):"
    local DATA=$(grep "^$SERVICE_NAME" < $FILE)
    if [ -n $DATA ];then
        local i=0
        echo $DATA | tr ':' '\n' | while ((i++)); read ITEM; do
            local FIELD=""
            local VALUE=$(decode_base64_string $ITEM)
            if [ $i -eq "1" ]; then
                FIELD="サービス名："
                elif [ $i -eq "2" ]; then
                FIELD="ユーザー名："
                elif [ $i -eq "3" ]; then
                FIELD="パスワード："
                VALUE=$(decode_password $ITEM)
            fi
            echo "$FIELD$VALUE"
        done
    else
        echo "そのサービスは登録されていません。"
    fi
}

encode_password() {
    echo $1 | openssl aes-256-cbc -a -salt -pbkdf2 -pass pass:somepassword
}

decode_password() {
    echo $1 | openssl aes-256-cbc -d -a -pbkdf2 -pass pass:somepassword
}

encode_base64_string() {
    echo -n $1 | base64
}

decode_base64_string() {
    echo -n $1 | base64 -d
}

print_thank_you() {
    local RED='\033[0;31m'
    local NO_COLOR='\033[0m'
    echo "Thank you${RED}!${NO_COLOR}"
}

ACTION_ADD="Add Password"
ACTION_GET="Get Password"
ACTION_EXIT="Exit"
ACTION_END="END"

print_actions() {
    echo "次の選択肢から入力してください("$ACTION_ADD"/"$ACTION_GET"/"$ACTION_EXIT")："
}

print_error_message() {
    echo "入力が間違えています。"$ACTION_ADD"/"$ACTION_GET"/"$ACTION_EXIT" から入力してください"
}

print_empty_line() {
    echo ""
}

get_action() {
    read ACTION
    echo $ACTION
}

password_manager() {
    local ACTION=""
    echo "パスワードマネージャーへようこそ！"
    while [ "$ACTION" != "$ACTION_END" ]; do
        print_actions
        ACTION=$(get_action)
        if [ "$ACTION" = "$ACTION_ADD" ]; then
            print_empty_line
            add_data
            print_empty_line
            elif [ "$ACTION" = "$ACTION_GET" ]; then
            print_empty_line
            read_file
            print_empty_line
            elif [ "$ACTION" = "$ACTION_EXIT" ]; then
            print_thank_you
            ACTION=$ACTION_END
        else
            print_error_message
            print_empty_line
        fi
    done
}

password_manager
