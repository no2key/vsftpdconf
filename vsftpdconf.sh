#!/bin/bash
# Author: <Mark Deng>2010.tpk@gmail.com
# Date: Nov.12.2012
# Purpose: configure vsfptd's virtual users on CentOS
# License: LGPL v3.0 or later

SCRIPT_NAME=`basename $0`
VIRTUAL_USER_FILE=/etc/vsftpd/virtual
FTP_DIR=/home/ftp
VIRTUAL_USER=virtualFTP
VIRTUAL_USER_CONF_DIR=/etc/vsftpd/virtual_ftpuser_conf
VIRTUAL_USER_CONF=$VIRTUAL_USER_CONF_DIR/vconf.tmp
USEAGE="useage: newpwd <user> <passwd>| adduser <passwd>| deluser <user>| disable <user>| enable <user>"



function find_user()
{
	cat $VIRTUAL_USER_FILE | grep "\<$1\>" > /dev/null
	if [ $? = 0 ]
	then
		return 0
	else
		return 1
	fi
}

function find_user_dir()
{
	if [ -d $FTP_DIR/$1 ]
	then
		return 0
	else
		return 1
	fi
}

function change_passwd()
{
	find_user $1
	if [ $? = 0 ]
	then
		sed -i '/\<'$1'\>/{n;d}' $VIRTUAL_USER_FILE > /dev/null
		sed -i '/\<'$1'\>/a\'$2'' $VIRTUAL_USER_FILE > /dev/null
		echo $1 password has been modified.
		make_db
	else
		echo $1 does not exists. Please check again.
		return 1
	fi
}

function add_newuser()
{
	find_user $1
	if [ $? = 0 ]
	then
		echo $1 already exists.
		exit 1
	else
		if [ "$2" != "" ]
		then
			sed -i '$a\'$1'\n'$2'' $VIRTUAL_USER_FILE
			make_db
			make_user_dir $1
			make_user_conf $1
			echo new user $1 is completed yet.
		else
			echo Password can not be empty.
			exit 1
		fi
	fi
}

function del_user()
{
	find_user $1
	if [ $? = 0 ]
	then
		sed -i '/\<'$1'\>/{N;d}' $VIRTUAL_USER_FILE > /dev/null
		make_db

		find_user_dir $1
		if [ $? = 0 ]
		then
			mv $FTP_DIR/$1 $FTP_DIR/deluser_$1_`date +%F:%R`
			echo $1 is deleted.
		else
			echo error: '$FTP_DIR/$1' no directory.
		fi
		
	else
		echo user:$1 does not exists. Please check again.
		exit 1
	fi
}

function make_db()
{
	db_load -T -t hash -f $VIRTUAL_USER_FILE $VIRTUAL_USER_FILE.db
}

function make_user_dir()
{
	find_user_dir $1
	if [ $? = 0 ]
	then
		mv  $FTP_DIR/$1 $FTP_DIR/deluser_$1_`date +%F:%R`
	fi
	mkdir -v $FTP_DIR/$1
	chown $VIRTUAL_USER.$VIRTUAL_USER $FTP_DIR/$1
}

function make_user_conf()
{
	cp $VIRTUAL_USER_CONF $VIRTUAL_USER_CONF_DIR/$1
	sed -i 's/\<username\>/'$1'/' $VIRTUAL_USER_CONF_DIR/$1 > /dev/null
}

function disable_user()
{
	find_user $1
	if [ $? = 0 ]
	then
		find_user_dir $1
		if [ $? = 0 ]
		then
			chmod 400 $FTP_DIR/$1
			echo $1 has disabled.
		else
			echo error: $1 no directory.
			exit 1
		fi
	else
		echo user:$1 dose not exists. Please check again.
		exit 1
	fi
}

function enable_user()
{
	find_user $1
	if [ $? = 0 ]
	then
		find_user_dir $1
		if [ $? = 0 ]
		then
			chmod 755 $FTP_DIR/$1
			echo $1 has enabled.
		else
			echo error: '$FTP_DIR/$1' no directory.
			exit 1
		fi
	else
		echo user:$1 dose not exists. Please check again.
		exit 1
	fi
}

function main()
{
	if [ $# -lt 2 ];
	then
		echo $USEAGE
		exit 1
	fi


	if [ $1 = "newpwd" ];
	then
		change_passwd $2 $3
	elif [ $1 = "adduser" ];
	then
		add_newuser $2 $3
	elif [ $1 = "deluser" ];
	then
		del_user $2
	elif [ $1 = "disable" ];
	then
		disable_user $2
	elif [ $1 = "enable" ];
	then
		enable_user $2
	else
		echo [$1] a bad argument.
	fi
}

main $@
