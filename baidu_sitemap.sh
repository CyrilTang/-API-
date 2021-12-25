#!/bin/bash

# 适用于自动给百度提交 文章信息
# 文章 ID 根据数据获取
# 本脚本需要借助 jq 工具，如果没有请安装 yum install jq  或者 apt-get install jq
# 如果需要定期自动提交，请写入 crond 计划任务

# ver 1.0  By anYun	2021.12.20
# https://deyun.fun     https://doc.iquan.fun
# https://www.cyrilstudio.top/  梦溪博客

# 数据库信息
dbuser='用户名'
dbpasswd='密码'
dbname='数据库名'


# 百度 key
client_id='' #client_id
client_secret='' #client_id
acc_token=$(curl -X GET "https://openapi.baidu.com/oauth/2.0/token?grant_type=client_credentials&client_id=${client_id}&client_secret=${client_secret}&scope=smartapp_snsapi_base" | jq '.access_token' | cut -d'"' -f2)

# 天级已推 ID 日志存放路径

baidu_day=$(cat /www/day.txt)
baidu_week=$(cat /www/week.txt)
arr_cid=($( mysql -u ${dbuser} -p${dbpasswd} -e "select ID from ${dbname}.wp_posts where post_status='publish' and post_type='post' and NOT ID IN (${baidu_day}) limit 9;" | awk '{print $1}' | grep -vE 'cid|ID' | tr '\n' ' '))

# echo ${arr_cid[*]}
for (( i=0;i<${#arr_cid[@]};i++ ))
do
    # 天推送
	grep -w ${arr_cid[$i]} '/www/day.txt'
	if [ $? -ne 0 ];then
		time_now=$(date "+%F %H:%M:%S")
		statusno=$(curl -H "application/x-www-form-urlencoded" -X POST -d "type=1&url_list=pages/detail/detail?id=${arr_cid[$i]}" "https://openapi.baidu.com/rest/2.0/smartapp/access/submitsitemap/api?access_token=${acc_token}" | jq '.errno' | cut -d '"' -f2 )
		
		# 成功推送就记录相应的 ID 到 success 文件
		if [ ${statusno} == '0' ];then
			echo -e "${baidu_day},${arr_cid[$i]}\c" > '/www/day.txt'
			echo -e "天级推送：${time_now} ID ==> ${arr_cid[$i]}  推送成功\n" >> '/www/baidu_logs.log'
		elif [ ${statusno} == '100110007' ];then
			echo -e "天级推送：${time_now} ID ==> ${arr_cid[$i]}  推送失败：数量超限\n" >> '/www/baidu_logs.log'
			break
		fi
	fi
	
done

# 周推送
arr_cid=($( mysql -u ${dbuser} -p${dbpasswd} -e "select ID from ${dbname}.wp_posts where post_status='publish' and post_type='post' and NOT ID IN (${baidu_week}) limit 99;" | awk '{print $1}' | grep -vE 'cid|ID' | tr '\n' ' '))
for (( i=0;i<${#arr_cid[@]};i++ ))
do	
	# 周推送
	grep -w ${arr_cid[$i]} '/www/wwwroot/Shell_Script/week.txt'
	if [ $? -ne 0 ];then
		time_now=$(date "+%F %H:%M:%S")
		statusno=$(curl -H "application/x-www-form-urlencoded" -X POST -d "type=0&url_list=pages/detail/detail?id=${arr_cid[$i]}" "https://openapi.baidu.com/rest/2.0/smartapp/access/submitsitemap/api?access_token=${acc_token}" | jq '.errno' | cut -d '"' -f2 )
		# 成功推送就记录相应的 ID 到 success 文件
		if [ ${statusno} == '0' ];then
			echo -e "${baidu_week},${arr_cid[$i]}\c" >> '/www/week.txt'
			echo -e "周级推送：${time_now} ID ==> ${arr_cid[$i]}  推送成功\n" >> '/www/baidu_logs.log'
		elif [ ${statusno} == '100110007' ];then
			echo -e "周级推送：${time_now} ID ==> ${arr_cid[$i]}  推送失败：数量超限\n" >> '/www/baidu_logs.log'
			break
		fi
	fi	
done
history -c -w
