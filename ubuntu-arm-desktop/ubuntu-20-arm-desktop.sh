#/bin/bash
# Ubuntu20 桌面环境配置(arm兼容)
# 2021 flyqie

# 遇到错误马上退出,避免出现其他问题
set -e
# ...
set -x

# Xrdp
function install_xrdp() {
	apt-get install -y xrdp
} 

# 桌面环境
function install_desktop_env() {
	DEBIAN_FRONTEND=noninteractive apt-get install xfce4 xfce4-goodies xorg dbus-x11 x11-xserver-utils xrdp -y
}
echo "exec startxfce4 "  >> /etc/xrdp/xrdp.ini

# Xrdp PulseAudio
function install_xrdp_pa() {
	apt-get install -y git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile1-dev libspeexdsp-dev libudev-dev pulseaudio
	cp /etc/apt/sources.list /etc/apt/sources.list.u2ad
	sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
	apt-get update -y
	apt build-dep pulseaudio -y
	cd /tmp
	apt source pulseaudio
	pulsever=$(pulseaudio --version | awk '{print $2}')
	cd /tmp/pulseaudio-$pulsever
	# ./configure --without-caps
	./configure
	git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
	cd pulseaudio-module-xrdp
	./bootstrap
	./configure PULSE_DIR="/tmp/pulseaudio-$pulsever"
	make
	cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
	install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
	# systemctl restart dbus
	# systemctl restart pulseaudio
	systemctl restart xrdp
	# 解决PA无声音问题,这似乎只在Ubuntu20出现,令人绝望...
	# Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
	fix_pa_systemd_issue
}

# 解决PA无声音问题,这似乎只在Ubuntu20出现,令人绝望...
# Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
function fix_pa_systemd_issue() {
mkdir -p /home/whooc/.config/systemd/user/
ln -s /dev/null /home/whooc/.config/systemd/user/pulseaudio.service
mkdir -p /home/whooc/.config/autostart/
cat <<EOF | \
  sudo tee /home/whooc/.config/autostart/pulseaudio.desktop
[Desktop Entry]
Type=Application
Exec=pulseaudio
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=pulseaudio
Name=pulseaudio
Comment[en_US]=pulseaudio
Comment=pulseaudio
EOF
chown -R whooc /home/whooc/.config/
chmod -R 755 /home/whooc/.config/
}

# 创建桌面用户
function create_desktop_user() {
useradd -s /bin/bash -m whooc
usermod -a -G sudo whooc
echo "whooc ALL=(ALL) ALL" >> /etc/sudoers
echo "123456789
123456789
" | passwd whooc
}

# Xrdp环境配置
function xrdp_conf() {
touch /home/whooc/.Xclients
echo "lxsession" > /home/whooc/.Xclients
chmod a+x /home/whooc/.Xclients
# sudo sed -e 's/^new_cursors=true/new_cursors=false/g' -i /etc/xrdp/xrdp.ini
cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.backup.u2ad
echo "$xrdp_config_base64" | base64 -d > /etc/xrdp/xrdp.ini
cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-color-manager.pkla
[Netowrkmanager]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF
systemctl restart xrdp
systemctl restart polkit
}

# 桌面环境配置
function desktop_env_conf() {
	# 移除掉网络图标
	apt-get remove -y network-manager-gnome
	# chrome疑似没有arm64,安装chromium
	apt-get install -y chromium-browser
}

# 设置简体中文
function set_chinese_lang() {
apt-get install -y locales
echo '# This file lists locales that you wish to have built. You can find a list
# of valid supported locales at /usr/share/i18n/SUPPORTED, and you can add
# user defined locales to /usr/local/share/i18n/SUPPORTED. If you change
# this file, you need to rerun locale-gen.
# aa_DJ ISO-8859-1
# aa_DJ.UTF-8 UTF-8
# aa_ER UTF-8
# aa_ER@saaho UTF-8
# aa_ET UTF-8
# af_ZA ISO-8859-1
# af_ZA.UTF-8 UTF-8
# ak_GH UTF-8
# am_ET UTF-8
# an_ES ISO-8859-15
# an_ES.UTF-8 UTF-8
# anp_IN UTF-8
# ar_AE ISO-8859-6
# ar_AE.UTF-8 UTF-8
# ar_BH ISO-8859-6
# ar_BH.UTF-8 UTF-8
# ar_DZ ISO-8859-6
# ar_DZ.UTF-8 UTF-8
# ar_EG ISO-8859-6
# ar_EG.UTF-8 UTF-8
# ar_IN UTF-8
# ar_IQ ISO-8859-6
# ar_IQ.UTF-8 UTF-8
# ar_JO ISO-8859-6
# ar_JO.UTF-8 UTF-8
# ar_KW ISO-8859-6
# ar_KW.UTF-8 UTF-8
# ar_LB ISO-8859-6
# ar_LB.UTF-8 UTF-8
# ar_LY ISO-8859-6
# ar_LY.UTF-8 UTF-8
# ar_MA ISO-8859-6
# ar_MA.UTF-8 UTF-8
# ar_OM ISO-8859-6
# ar_OM.UTF-8 UTF-8
# ar_QA ISO-8859-6
# ar_QA.UTF-8 UTF-8
# ar_SA ISO-8859-6
# ar_SA.UTF-8 UTF-8
# ar_SD ISO-8859-6
# ar_SD.UTF-8 UTF-8
# ar_SS UTF-8
# ar_SY ISO-8859-6
# ar_SY.UTF-8 UTF-8
# ar_TN ISO-8859-6
# ar_TN.UTF-8 UTF-8
# ar_YE ISO-8859-6
# ar_YE.UTF-8 UTF-8
# as_IN UTF-8
# ast_ES ISO-8859-15
# ast_ES.UTF-8 UTF-8
# ayc_PE UTF-8
# az_AZ UTF-8
# be_BY CP1251
# be_BY.UTF-8 UTF-8
# be_BY@latin UTF-8
# bem_ZM UTF-8
# ber_DZ UTF-8
# ber_MA UTF-8
# bg_BG CP1251
# bg_BG.UTF-8 UTF-8
# bhb_IN.UTF-8 UTF-8
# bho_IN UTF-8
# bn_BD UTF-8
# bn_IN UTF-8
# bo_CN UTF-8
# bo_IN UTF-8
# br_FR ISO-8859-1
# br_FR.UTF-8 UTF-8
# br_FR@euro ISO-8859-15
# brx_IN UTF-8
# bs_BA ISO-8859-2
# bs_BA.UTF-8 UTF-8
# byn_ER UTF-8
# ca_AD ISO-8859-15
# ca_AD.UTF-8 UTF-8
# ca_ES ISO-8859-1
# ca_ES.UTF-8 UTF-8
# ca_ES.UTF-8@valencia UTF-8
# ca_ES@euro ISO-8859-15
# ca_ES@valencia ISO-8859-15
# ca_FR ISO-8859-15
# ca_FR.UTF-8 UTF-8
# ca_IT ISO-8859-15
# ca_IT.UTF-8 UTF-8
# ce_RU UTF-8
# chr_US UTF-8
# cmn_TW UTF-8
# crh_UA UTF-8
# cs_CZ ISO-8859-2
# cs_CZ.UTF-8 UTF-8
# csb_PL UTF-8
# cv_RU UTF-8
# cy_GB ISO-8859-14
# cy_GB.UTF-8 UTF-8
# da_DK ISO-8859-1
# da_DK.UTF-8 UTF-8
# de_AT ISO-8859-1
# de_AT.UTF-8 UTF-8
# de_AT@euro ISO-8859-15
# de_BE ISO-8859-1
# de_BE.UTF-8 UTF-8
# de_BE@euro ISO-8859-15
# de_CH ISO-8859-1
# de_CH.UTF-8 UTF-8
# de_DE ISO-8859-1
# de_DE.UTF-8 UTF-8
# de_DE@euro ISO-8859-15
# de_IT ISO-8859-1
# de_IT.UTF-8 UTF-8
# de_LI.UTF-8 UTF-8
# de_LU ISO-8859-1
# de_LU.UTF-8 UTF-8
# de_LU@euro ISO-8859-15
# doi_IN UTF-8
# dv_MV UTF-8
# dz_BT UTF-8
# el_CY ISO-8859-7
# el_CY.UTF-8 UTF-8
# el_GR ISO-8859-7
# el_GR.UTF-8 UTF-8
# en_AG UTF-8
# en_AU ISO-8859-1
# en_AU.UTF-8 UTF-8
# en_BW ISO-8859-1
# en_BW.UTF-8 UTF-8
# en_CA ISO-8859-1
# en_CA.UTF-8 UTF-8
# en_DK ISO-8859-1
# en_DK.ISO-8859-15 ISO-8859-15
# en_DK.UTF-8 UTF-8
# en_GB ISO-8859-1
# en_GB.ISO-8859-15 ISO-8859-15
# en_GB.UTF-8 UTF-8
# en_HK ISO-8859-1
# en_HK.UTF-8 UTF-8
# en_IE ISO-8859-1
# en_IE.UTF-8 UTF-8
# en_IE@euro ISO-8859-15
# en_IL UTF-8
# en_IN UTF-8
# en_NG UTF-8
# en_NZ ISO-8859-1
# en_NZ.UTF-8 UTF-8
# en_PH ISO-8859-1
# en_PH.UTF-8 UTF-8
# en_SG ISO-8859-1
# en_SG.UTF-8 UTF-8
# en_US ISO-8859-1
# en_US.ISO-8859-15 ISO-8859-15
en_US.UTF-8 UTF-8
# en_ZA ISO-8859-1
# en_ZA.UTF-8 UTF-8
# en_ZM UTF-8
# en_ZW ISO-8859-1
# en_ZW.UTF-8 UTF-8
# eo UTF-8
# es_AR ISO-8859-1
# es_AR.UTF-8 UTF-8
# es_BO ISO-8859-1
# es_BO.UTF-8 UTF-8
# es_CL ISO-8859-1
# es_CL.UTF-8 UTF-8
# es_CO ISO-8859-1
# es_CO.UTF-8 UTF-8
# es_CR ISO-8859-1
# es_CR.UTF-8 UTF-8
# es_CU UTF-8
# es_DO ISO-8859-1
# es_DO.UTF-8 UTF-8
# es_EC ISO-8859-1
# es_EC.UTF-8 UTF-8
# es_ES ISO-8859-1
# es_ES.UTF-8 UTF-8
# es_ES@euro ISO-8859-15
# es_GT ISO-8859-1
# es_GT.UTF-8 UTF-8
# es_HN ISO-8859-1
# es_HN.UTF-8 UTF-8
# es_MX ISO-8859-1
# es_MX.UTF-8 UTF-8
# es_NI ISO-8859-1
# es_NI.UTF-8 UTF-8
# es_PA ISO-8859-1
# es_PA.UTF-8 UTF-8
# es_PE ISO-8859-1
# es_PE.UTF-8 UTF-8
# es_PR ISO-8859-1
# es_PR.UTF-8 UTF-8
# es_PY ISO-8859-1
# es_PY.UTF-8 UTF-8
# es_SV ISO-8859-1
# es_SV.UTF-8 UTF-8
# es_US ISO-8859-1
# es_US.UTF-8 UTF-8
# es_UY ISO-8859-1
# es_UY.UTF-8 UTF-8
# es_VE ISO-8859-1
# es_VE.UTF-8 UTF-8
# et_EE ISO-8859-1
# et_EE.ISO-8859-15 ISO-8859-15
# et_EE.UTF-8 UTF-8
# eu_ES ISO-8859-1
# eu_ES.UTF-8 UTF-8
# eu_ES@euro ISO-8859-15
# eu_FR ISO-8859-1
# eu_FR.UTF-8 UTF-8
# eu_FR@euro ISO-8859-15
# fa_IR UTF-8
# ff_SN UTF-8
# fi_FI ISO-8859-1
# fi_FI.UTF-8 UTF-8
# fi_FI@euro ISO-8859-15
# fil_PH UTF-8
# fo_FO ISO-8859-1
# fo_FO.UTF-8 UTF-8
# fr_BE ISO-8859-1
# fr_BE.UTF-8 UTF-8
# fr_BE@euro ISO-8859-15
# fr_CA ISO-8859-1
# fr_CA.UTF-8 UTF-8
# fr_CH ISO-8859-1
# fr_CH.UTF-8 UTF-8
# fr_FR ISO-8859-1
# fr_FR.UTF-8 UTF-8
# fr_FR@euro ISO-8859-15
# fr_LU ISO-8859-1
# fr_LU.UTF-8 UTF-8
# fr_LU@euro ISO-8859-15
# fur_IT UTF-8
# fy_DE UTF-8
# fy_NL UTF-8
# ga_IE ISO-8859-1
# ga_IE.UTF-8 UTF-8
# ga_IE@euro ISO-8859-15
# gd_GB ISO-8859-15
# gd_GB.UTF-8 UTF-8
# gez_ER UTF-8
# gez_ER@abegede UTF-8
# gez_ET UTF-8
# gez_ET@abegede UTF-8
# gl_ES ISO-8859-1
# gl_ES.UTF-8 UTF-8
# gl_ES@euro ISO-8859-15
# gu_IN UTF-8
# gv_GB ISO-8859-1
# gv_GB.UTF-8 UTF-8
# ha_NG UTF-8
# hak_TW UTF-8
# he_IL ISO-8859-8
# he_IL.UTF-8 UTF-8
# hi_IN UTF-8
# hne_IN UTF-8
# hr_HR ISO-8859-2
# hr_HR.UTF-8 UTF-8
# hsb_DE ISO-8859-2
# hsb_DE.UTF-8 UTF-8
# ht_HT UTF-8
# hu_HU ISO-8859-2
# hu_HU.UTF-8 UTF-8
# hy_AM UTF-8
# hy_AM.ARMSCII-8 ARMSCII-8
# ia_FR UTF-8
# id_ID ISO-8859-1
# id_ID.UTF-8 UTF-8
# ig_NG UTF-8
# ik_CA UTF-8
# is_IS ISO-8859-1
# is_IS.UTF-8 UTF-8
# it_CH ISO-8859-1
# it_CH.UTF-8 UTF-8
# it_IT ISO-8859-1
# it_IT.UTF-8 UTF-8
# it_IT@euro ISO-8859-15
# iu_CA UTF-8
# ja_JP.EUC-JP EUC-JP
# ja_JP.UTF-8 UTF-8
# ka_GE GEORGIAN-PS
# ka_GE.UTF-8 UTF-8
# kk_KZ PT154
# kk_KZ.RK1048 RK1048
# kk_KZ.UTF-8 UTF-8
# kl_GL ISO-8859-1
# kl_GL.UTF-8 UTF-8
# km_KH UTF-8
# kn_IN UTF-8
# ko_KR.EUC-KR EUC-KR
# ko_KR.UTF-8 UTF-8
# kok_IN UTF-8
# ks_IN UTF-8
# ks_IN@devanagari UTF-8
# ku_TR ISO-8859-9
# ku_TR.UTF-8 UTF-8
# kw_GB ISO-8859-1
# kw_GB.UTF-8 UTF-8
# ky_KG UTF-8
# lb_LU UTF-8
# lg_UG ISO-8859-10
# lg_UG.UTF-8 UTF-8
# li_BE UTF-8
# li_NL UTF-8
# lij_IT UTF-8
# ln_CD UTF-8
# lo_LA UTF-8
# lt_LT ISO-8859-13
# lt_LT.UTF-8 UTF-8
# lv_LV ISO-8859-13
# lv_LV.UTF-8 UTF-8
# lzh_TW UTF-8
# mag_IN UTF-8
# mai_IN UTF-8
# mg_MG ISO-8859-15
# mg_MG.UTF-8 UTF-8
# mhr_RU UTF-8
# mi_NZ ISO-8859-13
# mi_NZ.UTF-8 UTF-8
# mk_MK ISO-8859-5
# mk_MK.UTF-8 UTF-8
# ml_IN UTF-8
# mn_MN UTF-8
# mni_IN UTF-8
# mr_IN UTF-8
# ms_MY ISO-8859-1
# ms_MY.UTF-8 UTF-8
# mt_MT ISO-8859-3
# mt_MT.UTF-8 UTF-8
# my_MM UTF-8
# nan_TW UTF-8
# nan_TW@latin UTF-8
# nb_NO ISO-8859-1
# nb_NO.UTF-8 UTF-8
# nds_DE UTF-8
# nds_NL UTF-8
# ne_NP UTF-8
# nhn_MX UTF-8
# niu_NU UTF-8
# niu_NZ UTF-8
# nl_AW UTF-8
# nl_BE ISO-8859-1
# nl_BE.UTF-8 UTF-8
# nl_BE@euro ISO-8859-15
# nl_NL ISO-8859-1
# nl_NL.UTF-8 UTF-8
# nl_NL@euro ISO-8859-15
# nn_NO ISO-8859-1
# nn_NO.UTF-8 UTF-8
# nr_ZA UTF-8
# nso_ZA UTF-8
# oc_FR ISO-8859-1
# oc_FR.UTF-8 UTF-8
# om_ET UTF-8
# om_KE ISO-8859-1
# om_KE.UTF-8 UTF-8
# or_IN UTF-8
# os_RU UTF-8
# pa_IN UTF-8
# pa_PK UTF-8
# pap_AW UTF-8
# pap_CW UTF-8
# pl_PL ISO-8859-2
# pl_PL.UTF-8 UTF-8
# ps_AF UTF-8
# pt_BR ISO-8859-1
# pt_BR.UTF-8 UTF-8
# pt_PT ISO-8859-1
# pt_PT.UTF-8 UTF-8
# pt_PT@euro ISO-8859-15
# quz_PE UTF-8
# raj_IN UTF-8
# ro_RO ISO-8859-2
# ro_RO.UTF-8 UTF-8
# ru_RU ISO-8859-5
# ru_RU.CP1251 CP1251
# ru_RU.KOI8-R KOI8-R
# ru_RU.UTF-8 UTF-8
# ru_UA KOI8-U
# ru_UA.UTF-8 UTF-8
# rw_RW UTF-8
# sa_IN UTF-8
# sat_IN UTF-8
# sc_IT UTF-8
# sd_IN UTF-8
# sd_IN@devanagari UTF-8
# se_NO UTF-8
# sgs_LT UTF-8
# shs_CA UTF-8
# si_LK UTF-8
# sid_ET UTF-8
# sk_SK ISO-8859-2
# sk_SK.UTF-8 UTF-8
# sl_SI ISO-8859-2
# sl_SI.UTF-8 UTF-8
# so_DJ ISO-8859-1
# so_DJ.UTF-8 UTF-8
# so_ET UTF-8
# so_KE ISO-8859-1
# so_KE.UTF-8 UTF-8
# so_SO ISO-8859-1
# so_SO.UTF-8 UTF-8
# sq_AL ISO-8859-1
# sq_AL.UTF-8 UTF-8
# sq_MK UTF-8
# sr_ME UTF-8
# sr_RS UTF-8
# sr_RS@latin UTF-8
# ss_ZA UTF-8
# st_ZA ISO-8859-1
# st_ZA.UTF-8 UTF-8
# sv_FI ISO-8859-1
# sv_FI.UTF-8 UTF-8
# sv_FI@euro ISO-8859-15
# sv_SE ISO-8859-1
# sv_SE.ISO-8859-15 ISO-8859-15
# sv_SE.UTF-8 UTF-8
# sw_KE UTF-8
# sw_TZ UTF-8
# szl_PL UTF-8
# ta_IN UTF-8
# ta_LK UTF-8
# tcy_IN.UTF-8 UTF-8
# te_IN UTF-8
# tg_TJ KOI8-T
# tg_TJ.UTF-8 UTF-8
# th_TH TIS-620
# th_TH.UTF-8 UTF-8
# the_NP UTF-8
# ti_ER UTF-8
# ti_ET UTF-8
# tig_ER UTF-8
# tk_TM UTF-8
# tl_PH ISO-8859-1
# tl_PH.UTF-8 UTF-8
# tn_ZA UTF-8
# tr_CY ISO-8859-9
# tr_CY.UTF-8 UTF-8
# tr_TR ISO-8859-9
# tr_TR.UTF-8 UTF-8
# ts_ZA UTF-8
# tt_RU UTF-8
# tt_RU@iqtelif UTF-8
# ug_CN UTF-8
# uk_UA KOI8-U
# uk_UA.UTF-8 UTF-8
# unm_US UTF-8
# ur_IN UTF-8
# ur_PK UTF-8
# uz_UZ ISO-8859-1
# uz_UZ.UTF-8 UTF-8
# uz_UZ@cyrillic UTF-8
# ve_ZA UTF-8
# vi_VN UTF-8
# wa_BE ISO-8859-1
# wa_BE.UTF-8 UTF-8
# wa_BE@euro ISO-8859-15
# wae_CH UTF-8
# wal_ET UTF-8
# wo_SN UTF-8
# xh_ZA ISO-8859-1
# xh_ZA.UTF-8 UTF-8
# yi_US CP1255
# yi_US.UTF-8 UTF-8
# yo_NG UTF-8
# yue_HK UTF-8
zh_CN GB2312
zh_CN.GB18030 GB18030
zh_CN.GBK GBK
zh_CN.UTF-8 UTF-8
# zh_HK BIG5-HKSCS
# zh_HK.UTF-8 UTF-8
# zh_SG GB2312
# zh_SG.GBK GBK
# zh_SG.UTF-8 UTF-8
# zh_TW BIG5
# zh_TW.EUC-TW EUC-TW
# zh_TW.UTF-8 UTF-8
# zu_ZA ISO-8859-1
# zu_ZA.UTF-8 UTF-8
# en_US.UTF-8 UTF-8'>/etc/locale.gen
locale-gen
update-locale "LANG=zh_CN.UTF-8"
locale-gen --purge "zh_CN.UTF-8"
dpkg-reconfigure --frontend noninteractive locales
localectl set-locale LANG=zh_CN.UTF-8
apt-get install -y xfonts-intl-chinese xfonts-wqy fontforge ttf-wqy-microhei ttf-wqy-zenhei xfonts-wqy fonts-wqy-microhei
apt-get install -y ibus-libpinyin
}

apt-get update -y
apt-get install -y sudo screen

# 创建用户
create_desktop_user

# 安装桌面环境
install_desktop_env

# 安装XRDP
install_xrdp

# 安装XRDP PA
install_xrdp_pa

# XRDP环境配置
xrdp_config_base64="W0dsb2JhbHNdDQo7IHhyZHAuaW5pIGZpbGUgdmVyc2lvbiBudW1iZXINCmluaV92ZXJzaW9uPTENCg0KOyBmb3JrIGEgbmV3IHByb2Nlc3MgZm9yIGVhY2ggaW5jb21pbmcgY29ubmVjdGlvbg0KZm9yaz10cnVlDQoNCjsgcG9ydHMgdG8gbGlzdGVuIG9uLCBudW1iZXIgYWxvbmUgbWVhbnMgbGlzdGVuIG9uIGFsbCBpbnRlcmZhY2VzDQo7IDAuMC4wLjAgb3IgOjogaWYgaXB2NiBpcyBjb25maWd1cmVkDQo7IHNwYWNlIGJldHdlZW4gbXVsdGlwbGUgb2NjdXJyZW5jZXMNCjsNCjsgRXhhbXBsZXM6DQo7ICAgcG9ydD0zMzg5DQo7ICAgcG9ydD11bml4Oi8vLi90bXAveHJkcC5zb2NrZXQNCjsgICBwb3J0PXRjcDovLy46MzM4OSAgICAgICAgICAgICAgICAgICAgICAgICAgIDEyNy4wLjAuMTozMzg5DQo7ICAgcG9ydD10Y3A6Ly86MzM4OSAgICAgICAgICAgICAgICAgICAgICAgICAgICAqOjMzODkNCjsgICBwb3J0PXRjcDovLzxhbnkgaXB2NCBmb3JtYXQgYWRkcj46MzM4OSAgICAgIDE5Mi4xNjguMS4xOjMzODkNCjsgICBwb3J0PXRjcDY6Ly8uOjMzODkgICAgICAgICAgICAgICAgICAgICAgICAgIDo6MTozMzg5DQo7ICAgcG9ydD10Y3A2Oi8vOjMzODkgICAgICAgICAgICAgICAgICAgICAgICAgICAqOjMzODkNCjsgICBwb3J0PXRjcDY6Ly97PGFueSBpcHY2IGZvcm1hdCBhZGRyPn06MzM4OSAgIHtGQzAwOjA6MDowOjA6MDowOjF9OjMzODkNCjsgICBwb3J0PXZzb2NrOi8vPGNpZD46PHBvcnQ+DQpwb3J0PTMzODkNCg0KOyAncG9ydCcgYWJvdmUgc2hvdWxkIGJlIGNvbm5lY3RlZCB0byB3aXRoIHZzb2NrIGluc3RlYWQgb2YgdGNwDQo7IHVzZSB0aGlzIG9ubHkgd2l0aCBudW1iZXIgYWxvbmUgaW4gcG9ydCBhYm92ZQ0KOyBwcmVmZXIgdXNlIHZzb2NrOi8vPGNpZD46PHBvcnQ+IGFib3ZlDQp1c2VfdnNvY2s9ZmFsc2UNCg0KOyByZWd1bGF0ZSBpZiB0aGUgbGlzdGVuaW5nIHNvY2tldCB1c2Ugc29ja2V0IG9wdGlvbiB0Y3Bfbm9kZWxheQ0KOyBubyBidWZmZXJpbmcgd2lsbCBiZSBwZXJmb3JtZWQgaW4gdGhlIFRDUCBzdGFjaw0KdGNwX25vZGVsYXk9dHJ1ZQ0KDQo7IHJlZ3VsYXRlIGlmIHRoZSBsaXN0ZW5pbmcgc29ja2V0IHVzZSBzb2NrZXQgb3B0aW9uIGtlZXBhbGl2ZQ0KOyBpZiB0aGUgbmV0d29yayBjb25uZWN0aW9uIGRpc2FwcGVhciB3aXRob3V0IGNsb3NlIG1lc3NhZ2VzIHRoZSBjb25uZWN0aW9uIHdpbGwgYmUgY2xvc2VkDQp0Y3Bfa2VlcGFsaXZlPXRydWUNCg0KOyBzZXQgdGNwIHNlbmQvcmVjdiBidWZmZXIgKGZvciBleHBlcnRzKQ0KI3RjcF9zZW5kX2J1ZmZlcl9ieXRlcz0zMjc2OA0KI3RjcF9yZWN2X2J1ZmZlcl9ieXRlcz0zMjc2OA0KDQo7IHNlY3VyaXR5IGxheWVyIGNhbiBiZSAndGxzJywgJ3JkcCcgb3IgJ25lZ290aWF0ZScNCjsgZm9yIGNsaWVudCBjb21wYXRpYmxlIGxheWVyDQpzZWN1cml0eV9sYXllcj1uZWdvdGlhdGUNCg0KOyBtaW5pbXVtIHNlY3VyaXR5IGxldmVsIGFsbG93ZWQgZm9yIGNsaWVudCBmb3IgY2xhc3NpYyBSRFAgZW5jcnlwdGlvbg0KOyB1c2UgdGxzX2NpcGhlcnMgdG8gY29uZmlndXJlIFRMUyBlbmNyeXB0aW9uDQo7IGNhbiBiZSAnbm9uZScsICdsb3cnLCAnbWVkaXVtJywgJ2hpZ2gnLCAnZmlwcycNCmNyeXB0X2xldmVsPWhpZ2gNCg0KOyBYLjUwOSBjZXJ0aWZpY2F0ZSBhbmQgcHJpdmF0ZSBrZXkNCjsgb3BlbnNzbCByZXEgLXg1MDkgLW5ld2tleSByc2E6MjA0OCAtbm9kZXMgLWtleW91dCBrZXkucGVtIC1vdXQgY2VydC5wZW0gLWRheXMgMzY1DQo7IG5vdGUgdGhpcyBuZWVkcyB0aGUgdXNlciB4cmRwIHRvIGJlIGEgbWVtYmVyIG9mIHRoZSBzc2wtY2VydCBncm91cCwgZG8gd2l0aCBlLmcuDQo7JCBzdWRvIGFkZHVzZXIgeHJkcCBzc2wtY2VydA0KY2VydGlmaWNhdGU9DQprZXlfZmlsZT0NCg0KOyBzZXQgU1NMIHByb3RvY29scw0KOyBjYW4gYmUgY29tbWEgc2VwYXJhdGVkIGxpc3Qgb2YgJ1NTTHYzJywgJ1RMU3YxJywgJ1RMU3YxLjEnLCAnVExTdjEuMicsICdUTFN2MS4zJw0Kc3NsX3Byb3RvY29scz1UTFN2MS4yLCBUTFN2MS4zDQo7IHNldCBUTFMgY2lwaGVyIHN1aXRlcw0KI3Rsc19jaXBoZXJzPUhJR0gNCg0KOyBTZWN0aW9uIG5hbWUgdG8gdXNlIGZvciBhdXRvbWF0aWMgbG9naW4gaWYgdGhlIGNsaWVudCBzZW5kcyB1c2VybmFtZQ0KOyBhbmQgcGFzc3dvcmQuIElmIGVtcHR5LCB0aGUgZG9tYWluIG5hbWUgc2VudCBieSB0aGUgY2xpZW50IGlzIHVzZWQuDQo7IElmIGVtcHR5IGFuZCBubyBkb21haW4gbmFtZSBpcyBnaXZlbiwgdGhlIGZpcnN0IHN1aXRhYmxlIHNlY3Rpb24gaW4NCjsgdGhpcyBmaWxlIHdpbGwgYmUgdXNlZC4NCmF1dG9ydW49DQoNCmFsbG93X2NoYW5uZWxzPXRydWUNCmFsbG93X211bHRpbW9uPXRydWUNCmJpdG1hcF9jYWNoZT10cnVlDQpiaXRtYXBfY29tcHJlc3Npb249dHJ1ZQ0KYnVsa19jb21wcmVzc2lvbj10cnVlDQojaGlkZWxvZ3dpbmRvdz10cnVlDQptYXhfYnBwPTMyDQpuZXdfY3Vyc29ycz1mYWxzZQ0KOyBmYXN0cGF0aCAtIGNhbiBiZSAnaW5wdXQnLCAnb3V0cHV0JywgJ2JvdGgnLCAnbm9uZScNCnVzZV9mYXN0cGF0aD1ib3RoDQo7IHdoZW4gdHJ1ZSwgdXNlcmlkL3Bhc3N3b3JkICptdXN0KiBiZSBwYXNzZWQgb24gY21kIGxpbmUNCiNyZXF1aXJlX2NyZWRlbnRpYWxzPXRydWUNCjsgWW91IGNhbiBzZXQgdGhlIFBBTSBlcnJvciB0ZXh0IGluIGEgZ2F0ZXdheSBzZXR1cCAoTUFYIDI1NiBjaGFycykNCiNwYW1lcnJvcnR4dD1jaGFuZ2UgeW91ciBwYXNzd29yZCBhY2NvcmRpbmcgdG8gcG9saWN5IGF0IGh0dHA6Ly91cmwNCg0KOw0KOyBjb2xvcnMgdXNlZCBieSB3aW5kb3dzIGluIFJHQiBmb3JtYXQNCjsNCmJsdWU9MDA5Y2I1DQpncmV5PWRlZGVkZQ0KI2JsYWNrPTAwMDAwMA0KI2RhcmtfZ3JleT04MDgwODANCiNibHVlPTA4MjQ2Yg0KI2RhcmtfYmx1ZT0wODI0NmINCiN3aGl0ZT1mZmZmZmYNCiNyZWQ9ZmYwMDAwDQojZ3JlZW49MDBmZjAwDQojYmFja2dyb3VuZD02MjZjNzINCg0KOw0KOyBjb25maWd1cmUgbG9naW4gc2NyZWVuDQo7DQoNCjsgTG9naW4gU2NyZWVuIFdpbmRvdyBUaXRsZQ0KI2xzX3RpdGxlPU15IExvZ2luIFRpdGxlDQoNCjsgdG9wIGxldmVsIHdpbmRvdyBiYWNrZ3JvdW5kIGNvbG9yIGluIFJHQiBmb3JtYXQNCmxzX3RvcF93aW5kb3dfYmdfY29sb3I9MDA5Y2I1DQoNCjsgd2lkdGggYW5kIGhlaWdodCBvZiBsb2dpbiBzY3JlZW4NCmxzX3dpZHRoPTM1MA0KbHNfaGVpZ2h0PTQzMA0KDQo7IGxvZ2luIHNjcmVlbiBiYWNrZ3JvdW5kIGNvbG9yIGluIFJHQiBmb3JtYXQNCmxzX2JnX2NvbG9yPWRlZGVkZQ0KDQo7IG9wdGlvbmFsIGJhY2tncm91bmQgaW1hZ2UgZmlsZW5hbWUgKGJtcCBmb3JtYXQpLg0KI2xzX2JhY2tncm91bmRfaW1hZ2U9DQoNCjsgbG9nbw0KOyBmdWxsIHBhdGggdG8gYm1wLWZpbGUgb3IgZmlsZSBpbiBzaGFyZWQgZm9sZGVyDQpsc19sb2dvX2ZpbGVuYW1lPQ0KbHNfbG9nb194X3Bvcz01NQ0KbHNfbG9nb195X3Bvcz01MA0KDQo7IGZvciBwb3NpdGlvbmluZyBsYWJlbHMgc3VjaCBhcyB1c2VybmFtZSwgcGFzc3dvcmQgZXRjDQpsc19sYWJlbF94X3Bvcz0zMA0KbHNfbGFiZWxfd2lkdGg9NjUNCg0KOyBmb3IgcG9zaXRpb25pbmcgdGV4dCBhbmQgY29tYm8gYm94ZXMgbmV4dCB0byBhYm92ZSBsYWJlbHMNCmxzX2lucHV0X3hfcG9zPTExMA0KbHNfaW5wdXRfd2lkdGg9MjEwDQoNCjsgeSBwb3MgZm9yIGZpcnN0IGxhYmVsIGFuZCBjb21ibyBib3gNCmxzX2lucHV0X3lfcG9zPTIyMA0KDQo7IE9LIGJ1dHRvbg0KbHNfYnRuX29rX3hfcG9zPTE0Mg0KbHNfYnRuX29rX3lfcG9zPTM3MA0KbHNfYnRuX29rX3dpZHRoPTg1DQpsc19idG5fb2tfaGVpZ2h0PTMwDQoNCjsgQ2FuY2VsIGJ1dHRvbg0KbHNfYnRuX2NhbmNlbF94X3Bvcz0yMzcNCmxzX2J0bl9jYW5jZWxfeV9wb3M9MzcwDQpsc19idG5fY2FuY2VsX3dpZHRoPTg1DQpsc19idG5fY2FuY2VsX2hlaWdodD0zMA0KDQpbTG9nZ2luZ10NCkxvZ0ZpbGU9eHJkcC5sb2cNCkxvZ0xldmVsPURFQlVHDQpFbmFibGVTeXNsb2c9dHJ1ZQ0KU3lzbG9nTGV2ZWw9REVCVUcNCjsgTG9nTGV2ZWwgYW5kIFN5c0xvZ0xldmVsIGNvdWxkIGJ5IGFueSBvZjogY29yZSwgZXJyb3IsIHdhcm5pbmcsIGluZm8gb3IgZGVidWcNCg0KW0NoYW5uZWxzXQ0KOyBDaGFubmVsIG5hbWVzIG5vdCBsaXN0ZWQgaGVyZSB3aWxsIGJlIGJsb2NrZWQgYnkgWFJEUC4NCjsgWW91IGNhbiBibG9jayBhbnkgY2hhbm5lbCBieSBzZXR0aW5nIGl0cyB2YWx1ZSB0byBmYWxzZS4NCjsgSU1QT1JUQU5UISBBbGwgY2hhbm5lbHMgYXJlIG5vdCBzdXBwb3J0ZWQgaW4gYWxsIHVzZQ0KOyBjYXNlcyBldmVuIGlmIHlvdSBzZXQgYWxsIHZhbHVlcyB0byB0cnVlLg0KOyBZb3UgY2FuIG92ZXJyaWRlIHRoZXNlIHNldHRpbmdzIG9uIGVhY2ggc2Vzc2lvbiB0eXBlDQo7IFRoZXNlIHNldHRpbmdzIGFyZSBvbmx5IHVzZWQgaWYgYWxsb3dfY2hhbm5lbHM9dHJ1ZQ0KcmRwZHI9dHJ1ZQ0KcmRwc25kPXRydWUNCmRyZHludmM9dHJ1ZQ0KY2xpcHJkcj10cnVlDQpyYWlsPXRydWUNCnhyZHB2cj10cnVlDQp0Y3V0aWxzPXRydWUNCg0KOyBmb3IgZGVidWdnaW5nIHhyZHAsIGluIHNlY3Rpb24geHJkcDEsIGNoYW5nZSBwb3J0PS0xIHRvIHRoaXM6DQojcG9ydD0vdG1wLy54cmRwL3hyZHBfZGlzcGxheV8xMA0KDQo7IGZvciBkZWJ1Z2dpbmcgeHJkcCwgYWRkIGZvbGxvd2luZyBsaW5lIHRvIHNlY3Rpb24geHJkcDENCiNjaGFuc3J2cG9ydD0vdG1wLy54cmRwL3hyZHBfY2hhbnNydl9zb2NrZXRfNzIxMA0KDQoNCjsNCjsgU2Vzc2lvbiB0eXBlcw0KOw0KDQo7IFNvbWUgc2Vzc2lvbiB0eXBlcyBzdWNoIGFzIFhvcmcsIFgxMXJkcCBhbmQgWHZuYyBzdGFydCBhIGRpc3BsYXkgc2VydmVyLg0KOyBTdGFydHVwIGNvbW1hbmQtbGluZSBwYXJhbWV0ZXJzIGZvciB0aGUgZGlzcGxheSBzZXJ2ZXIgYXJlIGNvbmZpZ3VyZWQNCjsgaW4gc2VzbWFuLmluaS4gU2VlIGFuZCBjb25maWd1cmUgYWxzbyBzZXNtYW4uaW5pLg0KW1hvcmddDQpuYW1lPVhvcmcNCmxpYj1saWJ4dXAuc28NCnVzZXJuYW1lPWFzaw0KcGFzc3dvcmQ9YXNrDQppcD0xMjcuMC4wLjENCnBvcnQ9LTENCmNvZGU9MjANCg0KIyBbWHZuY10NCiMgbmFtZT1Ydm5jDQojIGxpYj1saWJ2bmMuc28NCiMgdXNlcm5hbWU9YXNrDQojIHBhc3N3b3JkPWFzaw0KIyBpcD0xMjcuMC4wLjENCiMgcG9ydD0tMQ0KI3hzZXJ2ZXJicHA9MjQNCiNkZWxheV9tcz0yMDAwDQoNCiMgW3ZuYy1hbnldDQojIG5hbWU9dm5jLWFueQ0KIyBsaWI9bGlidm5jLnNvDQojIGlwPWFzaw0KIyBwb3J0PWFzazU5MDANCiMgdXNlcm5hbWU9bmENCiMgcGFzc3dvcmQ9YXNrDQojcGFtdXNlcm5hbWU9YXNrc2FtZQ0KI3BhbXBhc3N3b3JkPWFza3NhbWUNCiNwYW1zZXNzaW9ubW5nPTEyNy4wLjAuMQ0KI2RlbGF5X21zPTIwMDANCg0KIyBbbmV1dHJpbm9yZHAtYW55XQ0KIyBuYW1lPW5ldXRyaW5vcmRwLWFueQ0KIyBsaWI9bGlieHJkcG5ldXRyaW5vcmRwLnNvDQojIGlwPWFzaw0KIyBwb3J0PWFzazMzODkNCiMgdXNlcm5hbWU9YXNrDQojIHBhc3N3b3JkPWFzaw0KDQo7IFlvdSBjYW4gb3ZlcnJpZGUgdGhlIGNvbW1vbiBjaGFubmVsIHNldHRpbmdzIGZvciBlYWNoIHNlc3Npb24gdHlwZQ0KI2NoYW5uZWwucmRwZHI9dHJ1ZQ0KI2NoYW5uZWwucmRwc25kPXRydWUNCiNjaGFubmVsLmRyZHludmM9dHJ1ZQ0KI2NoYW5uZWwuY2xpcHJkcj10cnVlDQojY2hhbm5lbC5yYWlsPXRydWUNCiNjaGFubmVsLnhyZHB2cj10cnVlDQo="
xrdp_conf

# 桌面环境配置
desktop_env_conf

# 中文配置
set_chinese_lang

apt-get autoremove -y

echo "Install Done!"
echo "Now you can reboot and connect port 3389 with rdp client"
echo "Note: chromium-browser is not displayed on the desktop, please start it manually if necessary"
echo "Default Username: whooc"
echo "Default Password: 123456789"