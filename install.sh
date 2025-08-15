#!/bin/bash

# Debian 媒体播放系统一键安装脚本
# 支持 Intel/NVIDIA/AMD 多种显卡自动检测
# 实现：Openbox + Chromium + 自动登录 + 硬件加速

set -e  # 遇到错误立即退出

echo "Debian 媒体播放系统安装"
echo "======================"
echo ""
echo "此脚本将安装和配置："
echo "- Intel 显卡驱动和硬件加速"
echo "- Openbox 轻量级桌面环境"
echo "- Chromium 浏览器"
echo "- 自动登录到媒体播放用户"
echo "- 开机自动启动浏览器全屏播放"
echo ""

# 配置参数
USERNAME="mediaplayer"
DEFAULT_URL="http://127.0.0.1:5666/v"

echo ""
echo "开始系统检测和安装..."

# 检测显卡类型
echo ""
echo "🔍 检测显卡硬件..."
echo "-------------------"

# 获取显卡信息
GPU_INFO=$(lspci | grep -i vga)
echo "检测到显卡: $GPU_INFO"

# 检测显卡厂商
INTEL_GPU=""
NVIDIA_GPU=""
AMD_GPU=""

if echo "$GPU_INFO" | grep -qi intel; then
    INTEL_GPU="yes"
    echo "✓ 检测到 Intel 显卡"
fi

if echo "$GPU_INFO" | grep -qi nvidia; then
    NVIDIA_GPU="yes"
    echo "✓ 检测到 NVIDIA 显卡"
fi

if echo "$GPU_INFO" | grep -qi amd || echo "$GPU_INFO" | grep -qi radeon; then
    AMD_GPU="yes"
    echo "✓ 检测到 AMD 显卡"
fi

# 如果没有检测到支持的显卡，询问用户
if [ -z "$INTEL_GPU" ] && [ -z "$NVIDIA_GPU" ] && [ -z "$AMD_GPU" ]; then
    echo "⚠️  未能自动识别显卡类型"
    echo "请手动选择显卡类型："
    echo "1) Intel"
    echo "2) NVIDIA" 
    echo "3) AMD"
    echo "4) 其他/未知"
    read -p "请选择 (1-4): " GPU_CHOICE
    
    case $GPU_CHOICE in
        1) INTEL_GPU="yes" ;;
        2) NVIDIA_GPU="yes" ;;
        3) AMD_GPU="yes" ;;
        4) echo "将使用通用配置" ;;
        *) echo "无效选择，使用通用配置" ;;
    esac
fi

# 安装确认
echo ""
echo "=========================================="
echo "🔍 显卡检测完成！"
echo "=========================================="
if [ "$INTEL_GPU" = "yes" ]; then
    echo "✓ 将安装 Intel 显卡支持和硬件加速"
fi
if [ "$NVIDIA_GPU" = "yes" ]; then
    echo "✓ 将安装 NVIDIA 显卡支持和硬件加速" 
fi
if [ "$AMD_GPU" = "yes" ]; then
    echo "✓ 将安装 AMD 显卡支持和硬件加速"
fi
if [ -z "$INTEL_GPU" ] && [ -z "$NVIDIA_GPU" ] && [ -z "$AMD_GPU" ]; then
    echo "✓ 将使用通用显卡配置"
fi
echo ""
echo "⚠️  即将开始安装，此过程将："
echo "   • 修改系统配置和软件包"
echo "   • 安装桌面环境和浏览器"
echo "   • 创建专用用户账户"
echo "   • 配置自动启动和登录"
echo ""
read -p "❓ 确定要继续安装吗？(y/N): " INSTALL_CONFIRM

case $INSTALL_CONFIRM in
    [Yy]|[Yy][Ee][Ss])
        echo "✅ 开始安装..."
        ;;
    *)
        echo "❌ 安装已取消"
        exit 0
        ;;
esac

# 1. 更新系统
echo ""
echo "1. 更新系统包..."
echo "----------------"
apt update && apt upgrade -y

# 2. 安装基础系统组件
echo ""
echo "2. 安装基础系统组件..."
echo "----------------------"
apt install -y \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# 3. 安装显卡驱动和硬件加速
echo ""
echo "3. 安装显卡驱动和硬件加速..."
echo "-----------------------------"

# 通用组件（所有显卡都需要）
COMMON_PACKAGES=(
    vainfo
    mesa-utils
    firmware-linux
)

# Intel 显卡驱动
INTEL_PACKAGES=(
    intel-media-va-driver
    i965-va-driver
    mesa-va-drivers
    mesa-vdpau-drivers
    libva2
    libva-drm2
    libvdpau1
    intel-gpu-tools
    intel-microcode
)

# NVIDIA 显卡驱动
NVIDIA_PACKAGES=(
    nvidia-driver
    nvidia-vaapi-driver
    libnvidia-encode1
    nvidia-settings
)

# AMD 显卡驱动  
AMD_PACKAGES=(
    mesa-va-drivers
    mesa-vdpau-drivers
    libva2
    libva-drm2
    libvdpau1
    radeontop
    firmware-amd-graphics
)

# 安装通用组件
echo "安装通用显卡组件..."
apt install -y "${COMMON_PACKAGES[@]}"

# 根据检测结果安装对应驱动
if [ "$INTEL_GPU" = "yes" ]; then
    echo "安装 Intel 显卡驱动..."
    apt install -y "${INTEL_PACKAGES[@]}"
    GPU_TYPE="intel"
fi

if [ "$NVIDIA_GPU" = "yes" ]; then
    echo "安装 NVIDIA 显卡驱动..."
    
    # 添加 non-free 仓库
    if ! grep -q "non-free" /etc/apt/sources.list; then
        sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
        apt update
    fi
    
    apt install -y "${NVIDIA_PACKAGES[@]}"
    GPU_TYPE="nvidia"
fi

if [ "$AMD_GPU" = "yes" ]; then
    echo "安装 AMD 显卡驱动..."
    apt install -y "${AMD_PACKAGES[@]}"
    GPU_TYPE="amd"
fi

# 如果没有特定显卡，使用通用配置
if [ -z "$GPU_TYPE" ]; then
    echo "使用通用显卡配置..."
    apt install -y mesa-va-drivers mesa-vdpau-drivers libva2 libvdpau1
    GPU_TYPE="generic"
fi

echo "显卡驱动安装完成，类型: $GPU_TYPE"

# 4. 安装 X11 和 Openbox
echo ""
echo "4. 安装桌面环境..."
echo "------------------"
apt install -y \
    xorg \
    xserver-xorg-video-intel \
    openbox \
    obconf \
    lightdm \
    lightdm-gtk-greeter \
    pcmanfm \
    lxterminal \
    gmrun \
    nitrogen \
    feh \
    unclutter \
    xdotool \
    wmctrl \
    x11-utils \
    x11-xserver-utils

# 5. 安装 Chromium 浏览器
echo ""
echo "5. 安装 Chromium 浏览器..."
echo "---------------------------"
apt install -y chromium

# 6. 安装音频支持
echo ""
echo "6. 安装音频支持..."
echo "------------------"
apt install -y \
    pulseaudio \
    pulseaudio-utils \
    alsa-utils

# 7. 安装媒体解码器
echo ""
echo "7. 安装媒体解码器..."
echo "--------------------"
apt install -y \
    gstreamer1.0-vaapi \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav

# 8. 创建媒体播放用户
echo ""
echo "8. 创建媒体播放用户..."
echo "----------------------"
if ! id "$USERNAME" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$USERNAME"
    echo "请为用户 $USERNAME 设置密码:"
    passwd "$USERNAME"
else
    echo "用户 $USERNAME 已存在"
fi

# 配置用户组
usermod -aG audio,video,pulse-access,input,tty "$USERNAME"

# 设置目录权限
chmod 755 /home/"$USERNAME"
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

# 9. 配置硬件加速环境变量
echo ""
echo "9. 配置硬件加速和防撕裂..."
echo "---------------------------"
cat >> /etc/environment <<EOF

# Intel 硬件加速环境变量
LIBVA_DRIVER_NAME=iHD
VDPAU_DRIVER=va_gl
EOF

# 创建 Intel 显卡防撕裂配置
mkdir -p /etc/X11/xorg.conf.d
cat > /etc/X11/xorg.conf.d/20-intel.conf <<'EOF'
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
    Option "TearFree" "true"
    Option "AccelMethod" "sna"
    Option "Backlight" "intel_backlight"
    Option "DRI" "3"
    Option "TripleBuffer" "true"
    Option "SwapbuffersWait" "true"
EndSection
EOF

# 优化内核参数防止撕裂
if ! grep -q "i915.enable_psr=0" /etc/default/grub; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="i915.enable_psr=0 /' /etc/default/grub
fi

# 10. 配置自动登录
echo ""
echo "10. 配置自动登录..."
echo "-------------------"
cat > /etc/lightdm/lightdm.conf <<EOF
[Seat:*]
autologin-user=$USERNAME
autologin-user-timeout=0
autologin-session=openbox
user-session=openbox
greeter-hide-users=true
EOF

# 11. 创建 Openbox 配置
echo ""
echo "11. 配置 Openbox..."
echo "-------------------"
mkdir -p /home/"$USERNAME"/.config/openbox

# Openbox 自启动脚本
cat > /home/"$USERNAME"/.config/openbox/autostart <<EOF
#!/bin/bash

# 等待 X 服务器启动
sleep 10

# 设置显示环境
export DISPLAY=:0

# 禁用屏幕保护和电源管理
xset s off
xset -dpms
xset s noblank

# 设置显示优化防止撕裂
xrandr --output eDP-1 --mode 1920x1080 --rate 60 2>/dev/null || true
xrandr --output eDP1 --mode 1920x1080 --rate 60 2>/dev/null || true

# 隐藏鼠标指针
unclutter -idle 3 &

# 黑色背景
xsetroot -solid black

# 启动音频
pulseaudio --start &

# 允许本地 X 连接
xhost +local: 2>/dev/null || true

# 等待系统就绪
sleep 20

# 启动浏览器
/home/$USERNAME/.local/bin/browser-monitor.sh &
EOF

chmod +x /home/"$USERNAME"/.config/openbox/autostart

# Openbox 快捷键配置
cat > /home/"$USERNAME"/.config/openbox/rc.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <keyboard>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="C-A-t">
      <action name="Execute">
        <command>lxterminal</command>
      </action>
    </keybind>
    <keybind key="F11">
      <action name="ToggleFullscreen"/>
    </keybind>
    <keybind key="F5">
      <action name="Execute">
        <command>xdotool key ctrl+F5</command>
      </action>
    </keybind>
  </keyboard>
  <theme>
    <n>Clearlooks</n>
  </theme>
  <desktops>
    <number>1</number>
  </desktops>
</openbox_config>
EOF

# 12. 创建浏览器启动脚本
echo ""
echo "12. 配置浏览器启动..."
echo "---------------------"
mkdir -p /home/"$USERNAME"/.local/bin
mkdir -p /home/"$USERNAME"/.local/log

cat > /home/"$USERNAME"/.local/bin/start-browser.sh <<EOF
#!/bin/bash

# 设置环境变量
export DISPLAY=:0
export LIBVA_DRIVER_NAME=iHD
export VDPAU_DRIVER=va_gl

echo "\$(date): 等待后台服务启动..." >> /home/$USERNAME/.local/log/browser.log

# 等待后台服务启动 - 增加等待时间
sleep 30

# 检查目标服务是否可用
echo "\$(date): 检查服务可用性..." >> /home/$USERNAME/.local/log/browser.log

# 等待服务启动的循环检查
for i in {1..30}; do
    if curl -s --connect-timeout 3 http://127.0.0.1:5666/v >/dev/null 2>&1; then
        echo "\$(date): 服务已就绪 (尝试 \$i 次)" >> /home/$USERNAME/.local/log/browser.log
        break
    else
        echo "\$(date): 等待服务启动... (尝试 \$i/30)" >> /home/$USERNAME/.local/log/browser.log
        sleep 5
    fi
    
    # 如果30次都失败，记录并继续启动浏览器
    if [ \$i -eq 30 ]; then
        echo "\$(date): 服务检查超时，仍然启动浏览器" >> /home/$USERNAME/.local/log/browser.log
    fi
done

echo "\$(date): 启动 Chromium (防撕裂优化)..." >> /home/$USERNAME/.local/log/browser.log

# 启动 Chromium - 添加防撕裂和GPU优化参数
chromium \\
    --kiosk \\
    --no-first-run \\
    --disable-infobars \\
    --disable-session-crashed-bubble \\
    --no-sandbox \\
    --disable-gpu-sandbox \\
    --autoplay-policy=no-user-gesture-required \\
    --enable-features=VaapiVideoDecoder \\
    --use-gl=egl \\
    --enable-gpu-rasterization \\
    --enable-zero-copy \\
    --enable-hardware-overlays \\
    --disable-gpu-driver-bug-workarounds \\
    --enable-oop-rasterization \\
    --disable-software-rasterizer \\
    --force-gpu-rasterization \\
    --enable-gpu-memory-buffer-video-frames \\
    --disable-features=VizDisplayCompositor \\
    --enable-smooth-scrolling \\
    --num-raster-threads=4 \\
    "$DEFAULT_URL" \\
    >> /home/$USERNAME/.local/log/browser.log 2>&1 &

# 等待启动
sleep 8

# 确保全屏
wmctrl -r "Chromium" -b add,above 2>/dev/null || true
xdotool search --name "Chromium" windowactivate 2>/dev/null || true

# 等待页面完全加载
sleep 5

# 自动按回车键进行登录（如果需要）
echo "\$(date): 尝试自动登录..." >> /home/$USERNAME/.local/log/browser.log
xdotool search --name "Chromium" windowactivate 2>/dev/null || true
sleep 1
xdotool key Return 2>/dev/null || true

echo "\$(date): Chromium 启动完成，已尝试自动登录" >> /home/$USERNAME/.local/log/browser.log
EOF

chmod +x /home/"$USERNAME"/.local/bin/start-browser.sh

# 13. 创建管理脚本
echo ""
echo "13. 创建管理脚本..."
echo "------------------"

# 浏览器监控和自动重启脚本
cat > /home/"$USERNAME"/.local/bin/browser-monitor.sh <<'EOF'
#!/bin/bash

# 浏览器监控和自动重启脚本
LOGFILE="/home/mediaplayer/.local/log/browser-monitor.log"
mkdir -p "/home/mediaplayer/.local/log"

# 记录日志函数
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

log_message "浏览器监控启动"

# 启动浏览器函数
start_browser() {
    log_message "启动浏览器..."
    
    # 清理现有进程
    pkill chromium 2>/dev/null || true
    sleep 3
    
    # 启动浏览器
    /home/mediaplayer/.local/bin/start-browser.sh &
    
    sleep 10
    
    local browser_pid=$(pgrep -f "chromium.*127.0.0.1:5666" | head -1)
    log_message "浏览器启动完成 (PID: ${browser_pid:-未找到})"
}

# 检查浏览器是否运行
is_browser_running() {
    pgrep -f "chromium.*127.0.0.1:5666" > /dev/null
    return $?
}

# 首次启动浏览器
start_browser

# 监控循环
while true; do
    sleep 30  # 每30秒检查一次
    
    if ! is_browser_running; then
        log_message "检测到浏览器已关闭，准备重启..."
        start_browser
        log_message "浏览器已重新启动"
    fi
done
EOF

chmod +x /home/"$USERNAME"/.local/bin/browser-monitor.sh

# 重启浏览器脚本
cat > /home/"$USERNAME"/.local/bin/restart-browser.sh <<'EOF'
#!/bin/bash
echo "重启浏览器..."

# 停止监控脚本
pkill -f browser-monitor.sh 2>/dev/null || true

# 停止浏览器
pkill chromium 2>/dev/null || true

sleep 3

# 重新启动监控脚本
/home/mediaplayer/.local/bin/browser-monitor.sh &

echo "浏览器监控已重启"
EOF

chmod +x /home/"$USERNAME"/.local/bin/restart-browser.sh

# 系统状态检查脚本
cat > /home/"$USERNAME"/.local/bin/check-system.sh <<EOF
#!/bin/bash
echo "系统状态检查"
echo "============"
echo ""
echo "显卡类型: $GPU_TYPE"
echo ""
echo "硬件加速支持:"
vainfo | grep -E "(Driver|VAProfile.*H264)" | head -5
echo ""
echo "显卡设备信息:"
lspci | grep -i vga
echo ""
echo "浏览器进程:"
ps aux | grep chromium | grep -v grep || echo "未运行"
echo ""
echo "系统负载:"
uptime
echo ""
echo "内存使用:"
free -h
echo ""
echo "GPU监控 (如可用):"
if [ "$GPU_TYPE" = "intel" ] && command -v intel_gpu_top >/dev/null; then
    echo "运行: sudo intel_gpu_top"
elif [ "$GPU_TYPE" = "nvidia" ] && command -v nvidia-smi >/dev/null; then
    nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits
elif [ "$GPU_TYPE" = "amd" ] && command -v radeontop >/dev/null; then
    echo "运行: radeontop"
else
    echo "无可用的GPU监控工具"
fi
echo ""
echo "最近日志:"
tail -5 /home/$USERNAME/.local/log/browser.log 2>/dev/null || echo "无日志"
EOF

chmod +x /home/"$USERNAME"/.local/bin/check-system.sh

# 14. 设置文件权限
echo ""
echo "14. 设置权限..."
echo "---------------"
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.config
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.local

# 15. 启用服务
echo ""
echo "15. 启用服务..."
echo "---------------"
systemctl enable lightdm
systemctl set-default graphical.target

# 16. 系统优化和GRUB更新
echo ""
echo "16. 系统优化..."
echo "---------------"

# 减少交换使用
echo "vm.swappiness=10" >> /etc/sysctl.conf

# 优化 I/O
echo "vm.dirty_ratio=15" >> /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf

# 更新 GRUB 配置
echo "更新 GRUB 配置..."
update-grub

echo ""
echo "============================================"
echo "安装完成！"
echo "============================================"
echo ""
echo "系统配置摘要:"
echo "- 用户: $USERNAME"
echo "- 默认页面: $DEFAULT_URL"
echo "- 浏览器: Chromium (硬件加速)"
echo "- 桌面: Openbox"
echo ""
echo "功能特性:"
echo "✓ 自动显卡检测和驱动安装"
echo "✓ 多显卡硬件加速支持 (Intel/NVIDIA/AMD)"
echo "✓ 防撕裂配置"
echo "✓ 自动登录"
echo "✓ 开机自动启动浏览器"
echo "✓ 全屏媒体播放"
echo "✓ 音频支持"
echo "✓ 浏览器自动重启"
echo ""
echo "管理命令:"
echo "- 重启浏览器: sudo -u $USERNAME /home/$USERNAME/.local/bin/restart-browser.sh"
echo "- 检查状态: sudo -u $USERNAME /home/$USERNAME/.local/bin/check-system.sh"
echo "- 查看监控日志: tail -f /home/$USERNAME/.local/log/browser-monitor.log"
echo "- 查看浏览器日志: tail -f /home/$USERNAME/.local/log/browser.log"
echo ""
echo "快捷键:"
echo "- Alt+F4: 关闭窗口"
echo "- Ctrl+Alt+T: 打开终端"
echo "- F11: 切换全屏"
echo "- F5: 刷新页面"
echo ""
echo "重要提示:"
echo "✓ 安装已完成，需要重启生效"
echo "✓ 重启后将自动登录并启动浏览器"
echo "✓ 防撕裂配置需要重启后生效"
echo "✓ 如有问题，按 Ctrl+Alt+T 打开终端进行调试"
echo ""
echo "硬件加速验证:"
echo "- 重启后运行: vainfo"
echo "- 在 Chromium 中访问: chrome://gpu"
echo "- Intel GPU: sudo intel_gpu_top"
echo "- NVIDIA GPU: nvidia-smi"
echo "- AMD GPU: radeontop"
echo ""

# 重启确认
echo "=========================================="
read -p "🔄 是否立即重启系统使配置生效？(y/N): " REBOOT_CONFIRM

case $REBOOT_CONFIRM in
    [Yy]|[Yy][Ee][Ss])
        echo "✅ 正在重启系统..."
        sleep 2
        reboot
        ;;
    *)
        echo "⏭️  已跳过重启"
        echo "💡 手动重启命令: sudo reboot"
        echo "🎉 感谢使用飞牛电视盒配置脚本！"
        ;;
esac