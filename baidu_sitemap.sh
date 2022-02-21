#!/bin/bash

# 适用于自动给百度提交 文章信息
# 文章 ID 根据数据获取
# 本脚本需要借助 jq 工具，如果没有请安装 yum install jq  或者 apt-get install jq
# 如果需要定期自动提交，请写入 crond 计划任务

# ver 1.0  By anYun	2021.12.20
# https://deyun.fun     https://doc.iquan.fun
# https://www.cyrilstudio.top/  梦溪博客
# QQ群：429296856

# 数据库信息
dbuser='用户名'
dbpasswd='密码'
dbname='数据库名'


# 百度 key
client_id='' #client_id
client_secret='' #client_id
acc_token=$(curl -X GET "https://openapi.baidu.com/oauth/2.0/token?grant_type=client_credentials&client_id=${client_id}&client_secret=${client_secret}&scope=smartapp_snsapi_base" | jq '.access_token' | cut -d'"' -f2)

# 设置推送数量
# 计数从 0 开始，所以如果推送 100 条就要减一 即 99
day_num=100
week_num=1500

# 百度 key
client_id='NDLtYeQeRjWXEfkoxGU'
client_secret='19Ik5haFcVKfedxzoNFfGPYW'
acc_token=$(curl -X GET "https://openapi.baidu.com/oauth/2.0/token?grant_type=client_credentials&client_id=${client_id}&client_secret=${client_secret}&scope=smartapp_snsapi_base" | jq '.access_token' | cut -d'"' -f2)

# 日志文件生成
today=$(date "+%F")
logfile="/www/wwwroot/Shell_Script/logs/${today}.log"
if [ ! -e ${logfile} ];then
	echo -e "${today}	推送日志\n\n" > "${logfile}"
fi

# 天推送
# 获取需要未推送的 ID 
day_arr_cid=($( mysql -u ${dbuser} -p${dbpasswd} -e "select ID from ${dbname}.wp_posts where (post_status='publish' and post_type='post' and day='N')  limit ${day_num};exit;" | awk '{print $1}' | grep -vE 'cid|ID' | tr '\n' ' '))
for (( i=0;i<=${#day_arr_cid[@]};i++ ))
do
	time_now=$(date "+%F %H:%M:%S")
	statusno=$(curl -H "application/x-www-form-urlencoded" -X POST -d "type=1&url_list=pages/detail/detail?id=${day_arr_cid[$i]}" "https://openapi.baidu.com/rest/2.0/smartapp/access/submitsitemap/api?access_token=${acc_token}" | jq '.errno' | cut -d '"' -f2 )
	if [ ${statusno} == '0' ];then
		mysql -u ${dbuser} -p${dbpasswd} -e "update ${dbname}.wp_posts set day='Y' where ID=${day_arr_cid[$i]};exit;"
		echo "天级推送：${time_now} ID ==> ${day_arr_cid[$i]}  推送成功" >> "${logfile}"
	elif [ ${statusno} == '100110007' ];then
		echo "天级推送：${time_now} ID ==> ${day_arr_cid[$i]}  推送失败：数量超限" >> "${logfile}"
		break
	fi
done

# 周推送
week_arr_cid=($( mysql -u ${dbuser} -p${dbpasswd} -e "select ID from ${dbname}.wp_posts where (post_status='publish' and post_type='post' and week='N') limit ${week_num};exit;" | awk '{print $1}' | grep -vE 'cid|ID' | tr '\n' ' '))
for (( i=0;i<${#week_arr_cid[@]};i++ ))
do	
	time_now=$(date "+%F %H:%M:%S")
	statusno=$(curl -H "application/x-www-form-urlencoded" -X POST -d "type=0&url_list=pages/detail/detail?id=${week_arr_cid[$i]}" "https://openapi.baidu.com/rest/2.0/smartapp/access/submitsitemap/api?access_token=${acc_token}" | jq '.errno' | cut -d '"' -f2 )
	# 成功推送就记录相应的 ID 到 week.txt 文件
	if [ ${statusno} == '0' ];then
		mysql -u ${dbuser} -p${dbpasswd} -e "update ${dbname}.wp_posts set week='Y' where ID=${week_arr_cid[$i]};exit;"
		echo "周级推送：${time_now} ID ==> ${week_arr_cid[$i]}  推送成功" >> "${logfile}"
	elif [ ${statusno} == '100110007' ];then
		echo "周级推送：${time_now} ID ==> ${week_arr_cid[$i]}  推送失败：数量超限" >> "${logfile}"
		break
	fi
done

# 日志文件清理
find "${fdir}/logs/" -mtime +3 -name "*.log" -exec -rm -f {} \;

# 历史命令删除
# history -c -w
echo > '/root/.bash_history'
