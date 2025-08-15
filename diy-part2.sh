#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "搜索目录: $NAME"
		# 先删除可能存在的旧目录
	    rm -rf ./package/lean/$PKG_NAME
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "删除目录: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "没有找到目录: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"
	# 先删除可能存在的旧目录
	#rm -rf ./package/lean/$PKG_NAME
	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package/lean/ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME ./package/lean/
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
#UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "master"
#UPDATE_PACKAGE "luci-app-argon-config" "sbwml/luci-theme-argon" "main" "pkg"
#UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "js"

UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main" "name"
#UPDATE_PACKAGE "passwall-packages" "xiaorouji/openwrt-passwall-packages" "main"
#UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
#UPDATE_PACKAGE "passwall2" "xiaorouji/openwrt-passwall2" "main" "pkg"

#UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
#UPDATE_PACKAGE "vnt" "lazyoop/networking-artifact" "main" "pkg"
#UPDATE_PACKAGE "easytier" "lazyoop/networking-artifact" "main" "pkg"

#UPDATE_PACKAGE "luci-app-gecoosac" "lwb1978/openwrt-gecoosac" "main"
UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main" "name"

# UPDATE_PACKAGE "luci-app-ddns-go" "sirpdboy/luci-app-ddns-go" "main"
# UPDATE_PACKAGE "luci-app-msd_lite" "ximiTech/luci-app-msd_lite" "main"
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master" "name"
#UPDATE_PACKAGE "sing-box" "kenzok8/small-package" "main" "pkg"

#quickstart
UPDATE_PACKAGE "taskd" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-lib-xterm" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-lib-taskd" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-app-store" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "quickstart" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-app-quickstart" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-app-istorex" "kenzok8/small-package" "main" "pkg"

#unishare
UPDATE_PACKAGE "webdav2" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "unishare" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "luci-app-unishare" "kenzok8/small-package" "main" "pkg"

PKG_PATH="./package/"

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	HP_RULE="surge"
	HP_PATH="./feeds/luci/applications/luci-app-homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ./$HP_PATH/resources/

	cd . && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy数据已更新!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ./feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
    echo " "
	
	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale修复成功!"
fi

#修复Rust编译失败
RUST_FILE=$(find ./feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust修复成功!"
fi

#修复DiskMan编译失败
DM_FILE="./package/lean/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
	echo " "
 
	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
	sed -i '/ntfs-3g-utils /d' $DM_FILE

	cd $PKG_PATH && echo "diskman修复成功!"
fi

#修复状态灯
LED_FILE="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6000-re-ss-01.dts"
if [ -f "$LED_FILE" ]; then
	echo " "
 
	sed -i 's/led-boot = &led_status_green;/led-boot = &led_status_blue;/g' $LED_FILE
 	sed -i 's/led-running = &led_status_blue;/led-running = &led_status_green;/g' $LED_FILE

	cd $PKG_PATH && echo "状态灯修复完成!"
fi

#修复5G不支持160
WIRELESS_FILE="./feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/wireless.js"

# 检查文件是否存在
if [ -f "$WIRELESS_FILE" ]; then
    echo "正在修复 wireless.js 文件.."

    # 删除 'VHT160', '160 MHz', htmodelist.VHT160
    sed -i "/'VHT160', '160 MHz', htmodelist.VHT160/d" $WIRELESS_FILE

    # 删除 'HE160', '160 MHz', htmodelist.HE160
    sed -i "/'HE160', '160 MHz', htmodelist.HE160/d" $WIRELESS_FILE

    # 删除 if (/HE20|HE40|HE80|HE160/.test(htval)) 中的 |HE160
    # 注意：这里需要更精确的匹配，以避免删除其他地方的 HE160
    sed -i "s/|HE160\(\/.test(htval))\)/\1/g" $WIRELESS_FILE

    # 删除 else if (/VHT20|VHT40|VHT80|VHT160/.test(htval)) 中的 |VHT160
    # 注意：这里需要更精确的匹配，以避免删除其他地方的 VHT160
    sed -i "s/|VHT160\(\/.test(htval))\)//g" $WIRELESS_FILE

    cd $PKG_PATH && echo "wireless.js 文件修复完成！"
else
    echo "错误：文件 wireless.js 未找到。"
fi

# 自定义v2ray-geodata下载
V2RAY_FILE="./feeds/packages/net/v2ray-geodata"
MF_FILE="./package/lean/v2ray-geodata/Makefile"
SH_FILE="./package/lean/v2ray-geodata/init.sh"
UP_FILE="./package/lean/v2ray-geodata/v2ray-geodata-updater"
if [ -d "$V2RAY_FILE" ]; then
	echo " "

	cp -f "$MF_FILE" "$V2RAY_FILE/Makefile"
	cp -f "$SH_FILE" "$V2RAY_FILE/init.sh"
	cp -f "$UP_FILE" "$V2RAY_FILE/v2ray-geodata-updater"

	cd $PKG_PATH && echo "v2ray-geodata替换完成!"
fi

#设置nginx默认配置和修复quickstart温度显示
wget "https://gist.githubusercontent.com/huanchenshang/df9dc4e13c6b2cd74e05227051dca0a9/raw/nginx.default.config" -O ./feeds/packages/net/nginx-util/files/nginx.config
wget "https://gist.githubusercontent.com/puteulanus/1c180fae6bccd25e57eb6d30b7aa28aa/raw/istore_backend.lua" -O ./package/lean/luci-app-quickstart/luasrc/controller/istore_backend.lua

# 修改软件源为immortalwrt
lean_def_dir="./package/lean/default-settings"
zzz_default_settings="$lean_def_dir/files/zzz-default-settings"

# 检查是否存在 lean_def_dir 和 zzz_default_settings
if [ -d "$lean_def_dir" ] && [ -f "$zzz_default_settings" ]; then

    # 使用更简单的模式删除包含特定内容的行
    sed -i '/openwrt_luci/d' "$zzz_default_settings"
    sed -i '/mirrors.tencent.com/d' "$zzz_default_settings"

    # 使用 cat 命令将新的软件源配置追加到文件末尾
    cat << 'NEW_END' >> "$zzz_default_settings"

cat << EOF > /etc/opkg/distfeeds.conf
src/gz openwrt_base https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/base/
src/gz openwrt_luci https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/luci/
src/gz openwrt_packages https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/packages/
src/gz openwrt_routing https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/routing/
src/gz openwrt_telephony https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/packages/aarch64_cortex-a53/telephony/
EOF
NEW_END
    cd $PKG_PATH && echo "替换软件源完成！"
fi

#修改CPU 性能优化调节名称显示
path="./feeds/luci/applications/luci-app-cpufreq"
po_file="$path/po/zh_Hans/cpufreq.po"

if [ -d "$path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "CPU 性能优化调节"/msgstr "性能调节"/g' "$po_file"
    cd $PKG_PATH && echo "cpu调节更名完成"
else
    echo "cpufreq.po文件未找到"
    return 1
fi

#添加quickfile文件管理
repo_url="https://github.com/sbwml/luci-app-quickfile.git"
target_dir="./package/lean/quickfile"
if [ -d "$target_dir" ]; then
    rm -rf "$target_dir"
fi
git clone --depth 1 "$repo_url" "$target_dir"

makefile_path="$target_dir/quickfile/Makefile"
if [ -f "$makefile_path" ]; then
    sed -i '/\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-\$(ARCH_PACKAGES)/c\
\tif [ "\$(ARCH_PACKAGES)" = "x86_64" ]; then \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-x86_64 \$(1)\/usr\/bin\/quickfile; \\\
\telse \\\
\t\t\$(INSTALL_BIN) \$(PKG_BUILD_DIR)\/quickfile-aarch64_generic \$(1)\/usr\/bin\/quickfile; \\\
\tfi' "$makefile_path"
	cd $PKG_PATH && echo "添加quickfile成功"
fi

#修改argon背景图片
theme_path="./feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background"
source_path="./images"
source_file="$source_path/bg1.jpg"
target_file="$theme_path/bg1.jpg"

if [ -f "$source_file" ]; then
    cp -f "$source_file" "$target_file"
    cd $PKG_PATH && echo "背景图片更新成功"
else
    echo "错误：未找到源图片文件"
fi

#turboacc设置名称显示
tb_path="./feeds/luci/applications/luci-app-turboacc"
po_file="$tb_path/po/zh_Hans/turboacc.po"

if [ -d "$tb_path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "Turbo ACC 网络加速"/msgstr "网络加速"/g' "$po_file"
    cd $PKG_PATH && echo "turboacc名称更改完成"
else
    echo "turboacc文件或目录不存在，跳过更改"
fi

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

#修改访问ip和主机名称
LAN_ADDR="192.168.10.1"
HOST_NAME="iStoreOS"
CFG_PATH="$PKG_PATH/base-files/files/bin/config_generate"
CFG2_PATH="$PKG_PATH/base-files/luci2/bin/config_generate"
if [ -f $CFG_PATH ] && [ -f $CFG2_PATH ]; then
    echo " "
	
    sed -i 's/192\.168\.[0-9]*\.[0-9]*/'$LAN_ADDR'/g' $CFG_PATH $CFG2_PATH
 	  sed -i 's/LEDE/'$HOST_NAME'/g' $CFG_PATH $CFG2_PATH
	  #修改immortalwrt.lan关联IP
	  sed -i "s/192\.168\.[0-9]*\.[0-9]*/$LAN_ADDR/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
    cd $PKG_PATH && echo "访问ip修改完成!"
fi

# 修改wifi参数
WRT_SSID_2G="iStoreOS-2.4G"
WRT_SSID_5G="iStoreOS-5G"
WRT_WORD="ai.ni520"
WIFI_UC="$PKG_PATH/kernel/mac80211/files/lib/wifi/mac80211.sh"

if [ -f "$WIFI_UC" ]; then
    echo "--- 正在修改 mac80211.sh 中的 Wi-Fi 参数 ---"

    # 使用sed命令将默认的ssid设置替换为case语句，以区分2.4G和5G
    sed -i "/set wireless.default_radio\${devidx}.ssid=LEDE/c \\
            case \"\${mode_band}\" in\\
            2g) set wireless.default_radio\${devidx}.ssid='$WRT_SSID_2G' ;;\
            5g) set wireless.default_radio\${devidx}.ssid='$WRT_SSID_5G' ;;\
            esac" "$WIFI_UC"

    # 修改WIFI加密：将encryption=none替换为psk2+ccmp
    sed -i "s/encryption=none/encryption='psk2+ccmp'/g" "$WIFI_UC"

    # 修改WIFI地区：将country=US替换为CN
    sed -i "s/country=US/country='CN'/g" "$WIFI_UC"

    # 在 uci batch 中添加 mu_beamformer 和 txpower
    # 在 'set wireless.radio${devidx}.country='CN'' 行之后插入
    sed -i "/country='CN'/a \
            set wireless.radio\${devidx}.mu_beamformer='1'\n\
            set wireless.radio\${devidx}.txpower='20'" "$WIFI_UC"

    # 在 uci batch 中添加 key
    # 在 'set wireless.default_radio${devidx}.encryption='psk2+ccmp'' 行之后插入
    sed -i "/encryption='psk2+ccmp'/a \
            set wireless.default_radio\${devidx}.key='$WRT_WORD'" "$WIFI_UC"

    echo "Wi-Fi 参数修改和添加完成！"
else
    echo "Error: mac80211.sh 文件未找到，路径为：$WIFI_UC"
    exit 1
fi


