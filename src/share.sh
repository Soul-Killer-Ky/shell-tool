#!/bin/bash
#  


if [ -z $1 ]
then
echo "请使用 sh $0 服务器要共享的目录"
exit 1
fi


if [ ! -d ${SHARE_DIR} ]
then
echo "目录${SHARE_DIR}不存在"
exit 1
fi


SHARE_DIR=$1
PC_IP=`env |awk '/SSH_CONNECTION/{print $1}' |cut -f2 -d"="`
SERV_IP=`env |awk '/SSH_CONNECTION/{print $3}'`






if ! rpm -q samba >/dev/null
then
yum -y install samba
chkconfig --level 3 smb on
fi




/bin/cp /etc/samba/smb.conf /etc/samba/smb.conf.`date "+%Y-%m-%d-%H:%M:%S"`


cat > /etc/samba/smb.conf <<EOF
#修改本配置需重启samba，/etc/init.d/smb restart
[global]


        workgroup = MYGROUP
        server string = My Server




        security = user
        passdb backend = tdbsam


#限制只有自己的pc机才可以访问，可以加其他IP，以空格隔开就可以了
    hosts allow = ${PC_IP}




[share]


    comment = share


    path = ${SHARE_DIR}


    writable = yes


    valid users = root 


    public = no


EOF




#添加共享用户
SHARE_PASS=`tr -dc _A-Z-a-z#$%^*-0-9 </dev/urandom |head -c12`
echo -e "${SHARE_PASS}\n${SHARE_PASS}" | /usr/bin/smbpasswd -a -s root
systemctl restart smb


#修改防火墙规则
#/bin/cp /etc/sysconfig/iptables /etc/sysconfig/iptables.${RANDOM}
#sed -i "/${PC_IP}/d" /etc/sysconfig/iptables
#sed -i "/lo/a \-A RH-Firewall-1-INPUT -s ${PC_IP} -j ACCEPT" /etc/sysconfig/iptables
#service iptables restart
#sysctl -p


echo "请记录以下共享信息"
echo "允许从 ${PC_IP} 访问以下共享信息"
echo "访问地址: \\\\${SERV_IP}\share"
echo "用户名  : root"
echo "密码    : ${SHARE_PASS}"
echo "如果需要映射网络驱动器,请在cmd下执行以下命令"
echo "如果提示"本地设备名已在使用中。"，请使用其他w、z等盘"
echo "net use v: \\\\${SERV_IP}\\share /user:root ${SHARE_PASS}"
