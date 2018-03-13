# uml_ss

基于uml linux的bbr支持的shadowsocks模板，简单配置几个参数就可以启动纯绿色

## 用法

vps需要打开tun/tap

先克隆

> git clone git@github.com:sinoyster/uml_ss.git

进入目录修改配置init_uml.sh：

```shell
cd uml_ss
vi init_uml.sh
```

建议只修改加密码，默认的chacha20也足够安全

```shell

ROUTER_DEV="venet0" #需要路由的网卡接口openvz默认是venet0 kvm是eth0

#tap接口不能重复
TAP_DEV="tap0"
#tap接口ip
export HOST_TAP_IP="10.0.0.1"
#接口转发端口
export HOST_PORT=40401

UML_ID="ss${HOST_PORT}"

# same LAN with HOST_TAP_IP
export UML_IP="10.0.0.2"     # uml linux的ip 应和HOST_TAP_IP在同一网络
export UML_SS_PORT=40401     # uml linux的shadowsocks端口
export UML_SS_METHOD="chacha20" # uml linux的加密方式，默认chacha20
export UML_SS_PASSWD="ss123456" # uml linux的shadowsocks密码
export UML_MEM="16M"            # uml linux内存 最低16M

#root password: root1234 # 登录密码
#ssh -p 30022 ${UML_IP} # 如何登录uml linux: ssh -p 30022 10.0.0.2 

```

默认配置可以不修改，运行生成uml虚拟机启动脚本 start_uml.sh

> ./init_uml.sh 

在运行并nohup

> nohup ./start_uml.sh &

enjoy!
