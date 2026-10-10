#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 IP.Check.Place（= xykt/IPQuality）原脚本中抽取指定区段，生成精简版 ipcheck-trimmed.sh。

用法：
    curl -sL https://IP.Check.Place -o ipcheck.sh     # 先下载原脚本
    python3 build_trimmed.py ipcheck.sh               # 生成 ipcheck-trimmed.sh
    # 也可用环境变量覆盖：SRC=... DST=... python3 build_trimmed.py
"""
import os
import re
import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("SRC", "ipcheck.sh")
DST = sys.argv[2] if len(sys.argv) > 2 else os.environ.get("DST", "ipcheck-trimmed.sh")

lines = open(SRC, encoding="utf-8").read().replace("\r\n", "\n").replace("\r", "\n").split("\n")

# 1) 切出所有顶层函数
funcs = {}
order = []
cur = None
start = 0
for i, ln in enumerate(lines, 1):
    m = re.match(r"^(?:function\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", ln)
    if m:
        if cur:
            funcs[cur] = (start, i - 1)
        cur = m.group(1)
        start = i
        order.append(cur)
if cur:
    funcs[cur] = (start, len(lines))


def grab(name):
    a, b = funcs[name]
    return "\n".join(lines[a - 1:b])


# 2) 语言块：只保留 cn / en 两套（原 set_language 里 cn 在 250-374）
lang_cn = "\n".join(lines[249:374])   # "cn") ... ;;
lang_en = "\n".join(lines[124:249])   # "en"|"jp"... ;;
# cn 块的正文（去掉开头的 "cn") 那一行，用于 *) 兜底复用）
lang_cn_body = "\n".join(lines[250:374])   # 从 swarn[1]= 到 ;;

# 3) 保留的函数清单（按原脚本顺序）
KEEP = [
    # 工具
    "show_progress_bar", "show_progress_bar_", "kill_progress_bar",
    "install_dependencies", "install_packages",
    "generate_random_user_agent", "adapt_locale", "check_connectivity",
    "get_ipv4", "is_valid_ipv4", "hide_ipv4",
    "get_ipv6", "is_valid_ipv6", "hide_ipv6",
    "calculate_display_width", "calc_padding",
    "generate_dms", "convert_single", "generate_googlemap_url",
    # 一、基础信息
    "db_maxmind",
    # 二、IP类型属性
    "db_ipinfo", "db_ipregistry", "db_ipapi",
    # 三、风险评分
    "db_scamalytics", "db_abuseipdb", "db_ip2location", "db_dbip", "db_ipqs",
    # 五、流媒体/AI 依赖的 DNS 判定
    "check_ip_valide", "calc_ip_net",
    "Check_DNS_IP", "Check_DNS_1", "Check_DNS_2", "Check_DNS_3",
    "Get_Unlock_Type",
    "MediaUnlockTest_TikTok", "MediaUnlockTest_DisneyPlus",
    "MediaUnlockTest_Netflix", "MediaUnlockTest_YouTube_Premium",
    "MediaUnlockTest_PrimeVideo_Region", "MediaUnlockTest_Reddit",
    "OpenAITest",
    # 输出
    "sscore_text",
    "show_head", "show_basic", "show_basic_lite", "show_type", "show_type_lite",
    "show_score", "show_media", "show_tail",
    "read_ref", "clean_ansi", "get_opts", "show_help",
    "check_IP",
]

out = []
out.append("#!/bin/bash")
out.append("# ============================================================")
out.append("# IP 质量体检（精简版）")
out.append("# 仅保留：一、基础信息 / 二、IP类型属性 / 三、风险评分 / 五、流媒体及AI解锁")
out.append("# 去掉：四、风险因子 / 六、邮局连通性及黑名单 / JSON输出 / 报告上传 / 广告")
out.append("#")
out.append("# 源自 xykt/IPQuality，原脚本：bash <(curl -Ls https://IP.Check.Place)")
out.append("# 本文件由 build_trimmed.py 从原脚本自动抽取生成（保留区段未作改写）")
out.append("# 仓库：https://github.com/whooc/whooc-script")
out.append("#")
out.append("# 快速运行：")
out.append("#   bash <(curl -Ls https://raw.githubusercontent.com/whooc/whooc-script/main/ipcheck-trimmed.sh)")
out.append("#   bash <(curl -Ls https://gh-proxy.com/https://raw.githubusercontent.com/whooc/whooc-script/main/ipcheck-trimmed.sh)   # 国内加速")
out.append("# 参数：-4/-6 指定协议 · -f 显示完整IP · -n 跳过依赖安装 · -p 不生成报告链接")
out.append("# ============================================================")
out.append('script_version="v2026-09-16"')

# 变量声明区（从原脚本 11-97 行抽取，去掉用不到的声明）
out.append(grab("__DECL__") if "__DECL__" in funcs else "")
out.pop()  # 占位去掉
decl_block = "\n".join(lines[12:97])  # Font_* 到 shelp_lines 之前
# 清理：去掉已删除功能的声明
for dead in ["declare -A ipdata\n", "declare -A sfactor\n", "declare -A smail\n",
             "declare -A smailstatus\n", "declare mode_json=0\n", "declare ipjson\n",
             "declare -A aad\n", "declare ADLines\n", "declare bar_pid\n",
             "declare ldatabase\n"]:
    decl_block = decl_block.replace(dead, "")
decl_block = decl_block.replace("declare ADLines\n", "")
out.append(decl_block)
out.append('declare ADLines=0')
out.append('declare -A sfactor smail smailstatus ipdata')

# set_language（cn/en）
lang = []
lang.append("set_language(){")
lang.append('case "$YY" in')
lang.append(lang_en)
lang.append(lang_cn)          # 已以 ;; 结尾
lang.append("*)")             # 兜底：未知语言回落到中文
lang.append(lang_cn_body)
lang.append("esac")
lang.append("}")
out.append("\n".join(lang))

# 其余保留函数
for name in KEEP:
    out.append(grab(name))

# 入口
out.append('''# ============================ 入口 ============================
generate_random_user_agent
adapt_locale
check_connectivity
read_ref
get_ipv4
get_ipv6
is_valid_ipv4 $IPV4
is_valid_ipv6 $IPV6
get_opts "$@"
[[ mode_no -eq 0 ]] && install_dependencies 1>&2
set_language
if [[ $ERRORcode -ne 0 ]]; then
  echo -ne "\\r$Font_B$Font_Red${swarn[$ERRORcode]}$Font_Suffix\\n"
  exit $ERRORcode
fi
clear
[[ $IPV4work -ne 0 && $IPV4check -ne 0 ]] && check_IP "$IPV4" 4
[[ $IPV6work -ne 0 && $IPV6check -ne 0 ]] && check_IP "$IPV6" 6
''')

# 4) 改造 check_IP：只跑需要的库，输出只保留需要的区段
check_ip_new = '''check_IP(){
IP=$1
ibar_step=0
[[ $2 -eq 4 ]] && hide_ipv4 $IP
[[ $2 -eq 6 ]] && hide_ipv6 $IP
db_maxmind $2
db_ipinfo
[[ $mode_lite -eq 0 ]] && db_scamalytics $2 || scamalytics=()
db_ipregistry $2
db_ipapi $2
[[ $mode_lite -eq 0 ]] && db_abuseipdb $2 || abuseipdb=()
[[ $mode_lite -eq 0 ]] && db_ip2location $2 || ip2location=()
db_dbip
[[ $mode_lite -eq 0 ]] && db_ipqs $2 || ipqs=()
MediaUnlockTest_TikTok $2
MediaUnlockTest_DisneyPlus $2
MediaUnlockTest_Netflix $2
MediaUnlockTest_YouTube_Premium $2
MediaUnlockTest_PrimeVideo_Region $2
MediaUnlockTest_Reddit $2
OpenAITest $2
echo -ne "$Font_LineClear" 1>&2
if [ $2 -eq 4 ] || [[ $IPV4work -eq 0 || $IPV4check -eq 0 ]]; then
  for ((i=0; i<ADLines; i++)); do
    echo -ne "$Font_LineUp" 1>&2
    echo -ne "$Font_LineClear" 1>&2
  done
fi
if [[ $mode_lite -eq 0 ]]; then
  local ip_report=$(show_head
show_basic
show_type
show_score
show_media
show_tail)
else
  local ip_report=$(show_head
show_basic_lite
show_type_lite
show_score
show_media
show_tail)
fi
echo -ne "\\r$ip_report\\n"
if [[ mode_output -eq 1 ]]; then
  case "$outputfile" in
  *.[aA][nN][sS][iI]) echo "$ip_report" >>"$outputfile" 2>/dev/null ;;
  *) echo -e "$ip_report" | sed 's/\\x1b\\[[0-9;]*[mGKHF]//g' >>"$outputfile" 2>/dev/null ;;
  esac
fi
echo -ne "\\r\\n"
}
'''
# 删除原 check_IP（在 out 里已包含），重建 out：把 KEEP 中 check_IP 去掉后追加新版本
out_txt = "\n".join(out)
# KEEP 里 check_IP 已被 grab 进去了，替换掉
orig_check = grab("check_IP")
out_txt = out_txt.replace(orig_check, "")
out_txt = out_txt.replace("# ============================ 入口 ============================",
                          check_ip_new + "\n# ============================ 入口 ============================")

# 去掉入口重复的 show_ad 前 clear（保留）
open(DST, "w", encoding="utf-8", newline="\n").write(out_txt)
print("written", DST, len(out_txt.split("\n")), "lines")
