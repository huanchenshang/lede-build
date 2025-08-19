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

#修复TailScale配置文件冲突
TS_FILE=$(find ./feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
    echo " "
	
	sed -i '/\/files/d' $TS_FILE

	echo "tailscale修复成功!"
else
    echo "tailsclae修复失败"
fi

#修复Rust编译失败
RUST_FILE=$(find ./feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	echo "rust修复成功!"
else
    echo "rust修复失败" 
fi

#修复DiskMan编译失败
DM_FILE="./package/lean/luci-app-diskman/applications/luci-app-diskman/Makefile"
if [ -f "$DM_FILE" ]; then
	echo " "
 
	sed -i 's/fs-ntfs/fs-ntfs3/g' $DM_FILE
	sed -i '/ntfs-3g-utils /d' $DM_FILE
	sed -i '/config PACKAGE_$(PKG_NAME)_INCLUDE_ntfs_3g_utils/,/default y/d' "$DM_FILE"
	echo "diskman修复成功!"
else
    echo "diskman修复失败" 
fi

#修复状态灯
LED_FILE="./target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6000-re-ss-01.dts"
DTS_FILE="./files/ipq6000-re-ss-01.dts"
if [ -f "$LED_FILE" ]; then
	echo " "
 
    cp -f "$DTS_FILE" "$LED_FILE"

	echo "状态灯修复完成!"
else
    echo "状态灯修复失败" 
fi

#修复补丁编译失败
QCA_FILE="./target/linux/qualcommax/patches-6.12/0600-2-qca-nss-ecm-support-PPPOE-offload.patch"
QFIX_FILE="./files/0600-2-qca-nss-ecm-support-PPPOE-offload.patch"
if [ -f "$QCA_FILE" ]; then
	echo " "
 
    cp -f "$QFIX_FILE" "$QCA_FILE"

	echo "编译失败修复完成!"
else
    echo "编译失败修复失败" 
fi

#修复5G不支持160
#WIRELESS_FILE="./feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/wireless.js"
# 检查文件是否存在
#if [ -f "$WIRELESS_FILE" ]; then
#    echo "正在修复 wireless.js 文件.."
#
#    # 删除 'VHT160', '160 MHz', htmodelist.VHT160
#    sed -i "/'VHT160', '160 MHz', htmodelist.VHT160/d" $WIRELESS_FILE
#
#    # 删除 'HE160', '160 MHz', htmodelist.HE160
#    sed -i "/'HE160', '160 MHz', htmodelist.HE160/d" $WIRELESS_FILE
#
#    # 删除 if (/HE20|HE40|HE80|HE160/.test(htval)) 中的 |HE160
#    # 注意：这里需要更精确的匹配，以避免删除其他地方的 HE160
#    sed -i "s/|HE160\(\/.test(htval))\)/\1/g" $WIRELESS_FILE
#
#    # 删除 else if (/VHT20|VHT40|VHT80|VHT160/.test(htval)) 中的 |VHT160
#    # 注意：这里需要更精确的匹配，以避免删除其他地方的 VHT160
#    sed -i "s/|VHT160\(\/.test(htval))\)//g" $WIRELESS_FILE
#
#    echo "wireless.js 文件修复完成！"
#else
#    echo "错误：文件 wireless.js 未找到。"
#fi

# 自定义v2ray-geodata下载
V2RAY_FILE="./feeds/packages/net/v2ray-geodata"
MF_FILE="./files/package/v2ray-geodata/Makefile"
SH_FILE="./files/package/v2ray-geodata/init.sh"
UP_FILE="./files/package/v2ray-geodata/v2ray-geodata-updater"
if [ -d "$V2RAY_FILE" ]; then
	echo " "

	cp -f "$MF_FILE" "$V2RAY_FILE/Makefile"
	cp -f "$SH_FILE" "$V2RAY_FILE/init.sh"
	cp -f "$UP_FILE" "$V2RAY_FILE/v2ray-geodata-updater"

	echo "v2ray-geodata替换完成!"
else
    echo "v2ray-geodata替换失败" 
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
    echo "替换软件源完成！"
else
    echo "替换软件源失败！" 
fi

#修改CPU 性能优化调节名称显示
path="./feeds/luci/applications/luci-app-cpufreq"
po_file="$path/po/zh_Hans/cpufreq.po"

if [ -d "$path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "CPU 性能优化调节"/msgstr "性能调节"/g' "$po_file"
    echo "cpu调节更名完成"
else
    echo "cpufreq.po文件未找到"
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
	echo "添加quickfile成功"
else
    echo "添加quickfile失败！" 
fi

#修改argon背景图片
theme_path="./feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background"
source_path="./files/images"
source_file="$source_path/bg1.jpg"
target_file="$theme_path/bg1.jpg"

if [ -f "$source_file" ]; then
    cp -f "$source_file" "$target_file"
    echo "背景图片更新成功"
else
    echo "错误：未找到源图片文件"
fi

#turboacc设置名称显示
tb_path="./feeds/luci/applications/luci-app-turboacc"
po_file="$tb_path/po/zh_Hans/turboacc.po"

if [ -d "$tb_path" ] && [ -f "$po_file" ]; then
    sed -i 's/msgstr "Turbo ACC 网络加速"/msgstr "网络加速"/g' "$po_file"
    echo "turboacc名称更改完成"
else
    echo "turboacc文件或目录不存在，跳过更改"
fi

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-argon/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

#修改访问ip和主机名称
#LAN_ADDR="192.168.10.1"
#HOST_NAME="iStoreOS"
#CFG_PATH="$PKG_PATH/base-files/files/bin/config_generate"
#CFG2_PATH="$PKG_PATH/base-files/luci2/bin/config_generate"
#if [ -f $CFG_PATH ] && [ -f $CFG2_PATH ]; then
#    echo " "
#	
#   sed -i 's/192\.168\.[0-9]*\.[0-9]*/'$LAN_ADDR'/g' $CFG_PATH $CFG2_PATH
# 	  sed -i 's/LEDE/'$HOST_NAME'/g' $CFG_PATH $CFG2_PATH
#	  #修改immortalwrt.lan关联IP
#	  sed -i "s/192\.168\.[0-9]*\.[0-9]*/$LAN_ADDR/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#    echo "访问ip修改完成!"
#else
#    echo "访问ip修改失败！" 
#fi

# 修改wifi参数
#WRT_SSID="iStoreOS"
#WRT_WORD="ai.ni520"
#WIFI_UC="$PKG_PATH/kernel/mac80211/files/lib/wifi/mac80211.sh"

#if [ -f "$WIFI_UC" ]; then
#    echo "--- 正在修改 mac80211.sh 中的 Wi-Fi 参数 ---"
#
#    # 使用双引号来确保变量被正确扩展
#    sed -i "s/ssid=LEDE/ssid='$WRT_SSID'/g" "$WIFI_UC"
#    sed -i "s/encryption=none/encryption='psk2+ccmp'/g" "$WIFI_UC"
#   sed -i "s/country=US/country='CN'/g" "$WIFI_UC"

#    # 在 'set wireless.radio${devidx}.country='CN'' 行之后插入
#   sed -i "/country='CN'/a \n\
#        set wireless.radio\${devidx}.mu_beamformer='1'\n\
#        set wireless.radio\${devidx}.txpower='20'" "$WIFI_UC"
#
#    # 在 'set wireless.default_radio${devidx}.encryption='psk2+ccmp'' 行之后插入
#    sed -i "/encryption='psk2+ccmp'/a \n\
#        set wireless.default_radio\${devidx}.key='$WRT_WORD'" "$WIFI_UC"
#
#    echo "Wi-Fi 参数修改和添加完成！"
#else
#    echo "Error: mac80211.sh 文件未找到，路径为：$WIFI_UC"
#fi


