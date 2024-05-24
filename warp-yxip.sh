#!/bin/bash
export LANG=en_US.UTF-8

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

# 选择客户端 CPU 架构
archAffix(){
    case "$(uname -m)" in
        i386 | i686 ) echo '386' ;;
        x86_64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        s390x ) echo 's390x' ;;
        * ) red "不支持的CPU架构!" && exit 1 ;;
    esac
}

endpointyx(){    
    # 删除之前的优选结果文件，以避免出错
    rm -f result.csv

    # 下载优选工具软件，感谢 GitHub 项目：https://github.com/peanut996/CloudflareWarpSpeedTest
    wget https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/warp-linux-$(archAffix) -O warp
    
    # 取消 Linux 自带的线程限制，以便生成优选 Endpoint IP
    ulimit -n 102400
    
    # 启动 WARP Endpoint IP 优选工具
    chmod +x warp
    if [[ $1 == 6 ]]; then
        ./warp -ipv6
    else
        ./warp
    fi
    
    # 显示前十个优选 Endpoint IP 及使用方法
    green "当前最优 Endpoint IP 结果如下，并已保存至 result.csv 中："
    cat result.csv | awk -F, '$3!="timeout ms" {print} ' | sort -t, -nk2 -nk3 | uniq | head -11 | awk -F, '{print "端点 "$1" 丢包率 "$2" 平均延迟 "$3}'
    echo ""
    yellow "优选 IP 使用方法如下："
    yellow "1. 将 WARP 的 WireGuard 节点的默认的 Endpoint IP：engage.cloudflareclient.com:2408 替换成本地网络最优的 Endpoint IP"
    yellow "使用教程：https://blog.misaka.rest/2023/01/25/wireguard-warp"

    best_ip=`awk -F, 'NR==2{print $1}' result.csv`
    Organization=`warp-cli settings|grep Organization|wc -l`
    if [ $Organization -eq 1 ];then
       echo "检测到为team账号，使用sudo命令"
       sudo warp-cli tunnel endpoint set $best_ip
       echo "已经成功自动设置为第一个最优IP"
    else
       warp-cli tunnel endpoint set $best_ip
       echo "已经成功自动设置为第一个最优IP"
    fi

    # 删除 WARP Endpoint IP 优选工具及其附属文件
    rm -f warp
}



endpointyx