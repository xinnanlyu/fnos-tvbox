#!/bin/bash

# Debian 媒体播放系统一键安装脚本
# 支持 Intel/NVIDIA/AMD 多种显卡自动检测
# 实现：Openbox + Chromium + 自动登录 + 硬件加速

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错
set -o pipefail  # 管道中任何命令失败都会导致整个管道失败

# 全局变量
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/fnos-tvbox-install.log"
readonly BACKUP_DIR="/tmp/fnos-tvbox-backup-$(date +%Y%m%d-%H%M%S)"

# 标准化日志函数
log_info() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $msg" | tee -a "$LOG_FILE"
}

log_warn() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $msg" | tee -a "$LOG_FILE" >&2
}

log_error() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $msg" | tee -a "$LOG_FILE" >&2
}

log_success() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $msg" | tee -a "$LOG_FILE"
}

# 错误处理函数
handle_error() {
    local line_no=$1
    local error_code=$2
    log_error "脚本在第 $line_no 行出错，退出码: $error_code"
    log_error "查看详细日志: $LOG_FILE"
    exit $error_code
}

# 设置错误陷阱
trap 'handle_error ${LINENO} $?' ERR

# 清理函数
cleanup_on_exit() {
    log_info "清理临时文件..."
    
    # 清理apt缓存
    apt autoremove -y >/dev/null 2>&1 || true
    apt autoclean >/dev/null 2>&1 || true
    
    # 清理临时安装文件
    rm -rf /tmp/fnos-tvbox-temp-* >/dev/null 2>&1 || true
    
    # 记录安装统计
    log_installation_stats
}

# 记录安装统计信息
log_installation_stats() {
    local end_time=$(date)
    local disk_usage=$(df -h / | awk 'NR==2 {print $3}')
    local memory_usage=$(free -h | awk 'NR==2 {print $3}')
    
    log_info "==============================================="
    log_info "安装统计信息"
    log_info "==============================================="
    log_info "结束时间: $end_time"
    log_info "磁盘使用: $disk_usage"
    log_info "内存使用: $memory_usage"
    log_info "日志文件: $LOG_FILE"
    log_info "备份目录: $BACKUP_DIR"
    log_info "==============================================="
}

# 性能优化函数
optimize_system_performance() {
    log_info "应用系统性能优化..."
    
    # 创建临时文件用于验证操作
    local temp_file="/tmp/fnos-tvbox-temp-$$"
    
    # 优化I/O调度器 (适用于SSD)
    if [[ -f "/sys/block/sda/queue/scheduler" ]]; then
        echo "mq-deadline" > /sys/block/sda/queue/scheduler 2>/dev/null || true
        log_info "已设置I/O调度器为mq-deadline"
    fi
    
    # 设置CPU频率调节器 (适用于桌面使用)
    if command -v cpufreq-set >/dev/null 2>&1; then
        cpufreq-set -g performance >/dev/null 2>&1 || true
        log_info "已设置CPU频率调节器为performance"
    fi
    
    # 清理测试文件
    rm -f "$temp_file" 2>/dev/null || true
    
    log_success "系统性能优化完成"
}

# 资源使用监控
monitor_resources() {
    log_info "当前系统资源状况:"
    
    # CPU负载
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}')
    log_info "CPU负载:$cpu_load"
    
    # 内存使用
    local memory_info=$(free -h | awk 'NR==2 {printf "使用: %s/%s (%.1f%%)", $3, $2, ($3/$2)*100}')
    log_info "内存 $memory_info"
    
    # 磁盘使用
    local disk_info=$(df -h / | awk 'NR==2 {printf "使用: %s/%s (%s)", $3, $2, $5}')
    log_info "磁盘 $disk_info"
}

trap cleanup_on_exit EXIT

# 安全验证函数
verify_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "必需命令不存在: $cmd"
        return 1
    fi
}

# 检查必需命令
check_prerequisites() {
    log_info "检查系统必需命令..."
    local required_commands=("apt" "systemctl" "lspci" "xrandr")
    
    for cmd in "${required_commands[@]}"; do
        verify_command "$cmd"
    done
    
    log_success "系统必需命令检查完成"
}

# 备份重要文件
backup_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file_path" "$BACKUP_DIR/" 2>/dev/null || true
        log_info "已备份文件: $file_path"
    fi
}

# 安全执行命令
safe_execute() {
    local cmd="$*"
    log_info "执行命令: $cmd"
    
    if ! eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log_error "命令执行失败: $cmd"
        return 1
    fi
    
    return 0
}

# 初始化日志
log_info "fnOS电视盒配置脚本开始执行"
log_info "脚本位置: $SCRIPT_DIR"
log_info "日志文件: $LOG_FILE"
log_info "备份目录: $BACKUP_DIR"

# 执行系统检查
check_prerequisites

# 检查并提升权限
check_root_privileges() {
    if [[ "$EUID" -ne 0 ]]; then
        log_warn "检测到非 root 用户运行，正在自动提升权限..."
        exec sudo "$0" "$@"
    fi
    log_success "root 权限验证通过"
}

check_root_privileges "$@"

# 显示安装信息
display_install_info() {
    log_info "Debian 媒体播放系统安装"
    log_info "======================"
    log_info ""
    log_info "此脚本将安装和配置："
    log_info "- 多显卡驱动和硬件加速 (Intel/NVIDIA/AMD)"
    log_info "- Openbox 轻量级桌面环境"
    log_info "- Chromium 浏览器 (硬件加速优化)"
    log_info "- 自动登录和音频配置"
    log_info "- 开机自动启动浏览器全屏播放"
    log_info ""
}

display_install_info

# 配置参数 - 使用只读变量提高安全性
readonly USERNAME="${FNOS_USERNAME:-mediaplayer}"
readonly DEFAULT_URL="${FNOS_DEFAULT_URL:-http://127.0.0.1:5666/v}"
readonly USER_HOME="/home/$USERNAME"

# 验证配置参数
validate_config() {
    log_info "验证配置参数..."
    
    # 检查用户名合法性
    if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "无效的用户名: $USERNAME"
        return 1
    fi
    
    # 检查URL格式
    if [[ ! "$DEFAULT_URL" =~ ^https?:// ]]; then
        log_error "无效的URL格式: $DEFAULT_URL"
        return 1
    fi
    
    log_info "配置用户: $USERNAME"
    log_info "默认URL: $DEFAULT_URL"
    log_info "用户目录: $USER_HOME"
    log_success "配置参数验证通过"
}

validate_config

log_info "开始系统检测和安装..."

# 音频设备检测函数
detect_audio_devices() {
    log_info "🔊 检测音频设备..."
    
    # 获取音频设备信息
    local audio_info
    if audio_info=$(lspci | grep -i audio); then
        log_info "检测到音频设备: $audio_info"
    else
        log_warn "未检测到音频设备信息"
    fi
    
    # 确保音频测试工具可用
    ensure_audio_tools
    
    # 测试HDMI音频输出
    test_hdmi_audio_outputs
}

# 确保音频测试工具可用
ensure_audio_tools() {
    log_info "确保音频测试工具可用..."
    
    if ! command -v speaker-test >/dev/null 2>&1; then
        log_info "安装音频测试工具..."
        safe_execute "apt-get update -qq"
        safe_execute "apt-get install -y alsa-utils"
    fi
    
    log_success "音频测试工具准备完成"
}

# 测试HDMI音频输出
test_hdmi_audio_outputs() {
    log_info "🎵 测试HDMI音频输出..."
    
    # 全局变量初始化
    WORKING_AUDIO_DEVICE=""
    AUDIO_CARD=""
    AUDIO_DEVICE=""
    
    # 寻找测试音频文件
    local test_sound=""
    local test_files=("/usr/share/sounds/alsa/Noise.wav" "/usr/share/sounds/alsa/Front_Right.wav")
    
    for file in "${test_files[@]}"; do
        if [[ -f "$file" ]]; then
            test_sound="$file"
            break
        fi
    done
    
    # 测试所有可能的HDMI音频设备
    local found=false
    for card in {0..2}; do
        for device in {3..9}; do
            local audio_device="hw:$card,$device"
            log_info "测试音频设备 $audio_device ..."
            
            # 使用可用的测试方法
            local test_cmd
            if [[ -n "$test_sound" ]]; then
                test_cmd="timeout 2 aplay -D plughw:$card,$device '$test_sound'"
            else
                test_cmd="timeout 2 speaker-test -D plughw:$card,$device -c 2 -t sine -l 1"
            fi
            
            if eval "$test_cmd" >/dev/null 2>&1; then
                log_success "找到工作的音频设备: $audio_device"
                WORKING_AUDIO_DEVICE="$audio_device"
                AUDIO_CARD="$card"
                AUDIO_DEVICE="$device"
                found=true
                break 2
            fi
        done
    done
    
    # 设置默认音频设备
    if [[ "$found" == "false" ]]; then
        log_warn "未找到工作的HDMI音频设备，将使用默认配置"
        WORKING_AUDIO_DEVICE="hw:0,3"
        AUDIO_CARD="0"  
        AUDIO_DEVICE="3"
    fi
    
    log_info "最终音频设备配置: $WORKING_AUDIO_DEVICE"
}

# 执行音频设备检测
detect_audio_devices

# 显卡硬件检测函数
detect_gpu_hardware() {
    log_info "🔍 检测显卡硬件..."
    
    # 全局变量初始化
    INTEL_GPU=""
    NVIDIA_GPU=""
    AMD_GPU=""
    GPU_TYPE=""
    
    # 获取显卡信息
    local gpu_info
    if gpu_info=$(lspci | grep -i vga); then
        log_info "检测到显卡: $gpu_info"
        analyze_gpu_type "$gpu_info"
    else
        log_warn "未检测到显卡信息"
        prompt_manual_gpu_selection
    fi
    
    # 确定最终GPU类型
    determine_gpu_type
}

# 分析显卡类型
analyze_gpu_type() {
    local gpu_info="$1"
    
    if echo "$gpu_info" | grep -qi intel; then
        INTEL_GPU="yes"
        log_success "检测到 Intel 显卡"
    fi
    
    if echo "$gpu_info" | grep -qi nvidia; then
        NVIDIA_GPU="yes"
        log_success "检测到 NVIDIA 显卡"
    fi
    
    if echo "$gpu_info" | grep -qi -E "(amd|radeon)"; then
        AMD_GPU="yes"
        log_success "检测到 AMD 显卡"
    fi
    
    # 如果没有检测到支持的显卡
    if [[ -z "$INTEL_GPU" && -z "$NVIDIA_GPU" && -z "$AMD_GPU" ]]; then
        log_warn "未能自动识别显卡类型"
        prompt_manual_gpu_selection
    fi
}

# 手动选择显卡类型
prompt_manual_gpu_selection() {
    log_warn "请手动选择显卡类型："
    echo "1) Intel"
    echo "2) NVIDIA"
    echo "3) AMD" 
    echo "4) 其他/未知"
    
    local gpu_choice
    read -p "请选择 (1-4): " gpu_choice
    
    case $gpu_choice in
        1) 
            INTEL_GPU="yes"
            log_info "手动选择了 Intel 显卡"
            ;;
        2) 
            NVIDIA_GPU="yes"
            log_info "手动选择了 NVIDIA 显卡"
            ;;
        3) 
            AMD_GPU="yes"
            log_info "手动选择了 AMD 显卡"
            ;;
        4|*) 
            log_info "将使用通用显卡配置"
            ;;
    esac
}

# 确定GPU类型
determine_gpu_type() {
    if [[ "$INTEL_GPU" == "yes" ]]; then
        GPU_TYPE="intel"
    elif [[ "$NVIDIA_GPU" == "yes" ]]; then
        GPU_TYPE="nvidia"
    elif [[ "$AMD_GPU" == "yes" ]]; then
        GPU_TYPE="amd"
    else
        GPU_TYPE="generic"
    fi
    
    log_success "确定显卡类型: $GPU_TYPE"
}

# 执行显卡硬件检测
detect_gpu_hardware

# 显示安装确认信息
display_installation_summary() {
    log_info "=========================================="
    log_info "🔍 系统检测完成！"
    log_info "=========================================="
    log_info ""
    log_info "检测结果摘要："
    log_info "• 音频设备: $WORKING_AUDIO_DEVICE"
    log_info "• 显卡类型: $GPU_TYPE"
    
    if [[ "$INTEL_GPU" == "yes" ]]; then
        log_info "• 将安装 Intel 显卡支持和硬件加速"
    fi
    if [[ "$NVIDIA_GPU" == "yes" ]]; then
        log_info "• 将安装 NVIDIA 显卡支持和硬件加速"
    fi
    if [[ "$AMD_GPU" == "yes" ]]; then
        log_info "• 将安装 AMD 显卡支持和硬件加速"
    fi
    if [[ -z "$INTEL_GPU" && -z "$NVIDIA_GPU" && -z "$AMD_GPU" ]]; then
        log_info "• 将使用通用显卡配置"
    fi
    
    log_info ""
    log_warn "⚠️  即将开始安装，此过程将："
    log_warn "   • 修改系统配置和软件包"
    log_warn "   • 安装桌面环境和浏览器"
    log_warn "   • 创建专用用户账户 ($USERNAME)"
    log_warn "   • 配置自动启动和登录"
    log_info ""
}

# 确认安装意图
confirm_installation() {
    display_installation_summary
    
    local install_confirm
    read -p "❓ 确定要继续安装吗？(y/N): " install_confirm
    
    case $install_confirm in
        [Yy]|[Yy][Ee][Ss])
            log_success "用户确认开始安装"
            ;;
        *)
            log_info "用户取消安装"
            exit 0
            ;;
    esac
}

# 执行安装确认
confirm_installation

# 系统安装步骤函数
install_system_updates() {
    log_info "================================================"
    log_info "步骤 1: 更新系统包"
    log_info "================================================"
    
    # 备份重要的包管理文件
    backup_file "/etc/apt/sources.list"
    
    log_info "更新软件包列表..."
    safe_execute "apt update"
    
    log_info "升级系统软件包..."
    safe_execute "apt upgrade -y"
    
    log_success "系统更新完成"
}

install_basic_components() {
    log_info "================================================"
    log_info "步骤 2: 安装基础系统组件"
    log_info "================================================"
    
    local basic_packages=(
        "curl"
        "wget" 
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "software-properties-common"
    )
    
    log_info "安装基础组件包: ${basic_packages[*]}"
    safe_execute "apt install -y ${basic_packages[*]}"
    
    # 验证安装结果
    for package in "${basic_packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log_success "$package 安装成功"
        else
            log_error "$package 安装失败"
            return 1
        fi
    done
    
    log_success "基础系统组件安装完成"
}

# 执行系统更新和基础组件安装
install_system_updates
install_basic_components

install_gpu_drivers() {
    log_info "================================================"
    log_info "步骤 3: 安装显卡驱动和硬件加速"
    log_info "================================================"
    
    # 定义显卡驱动包
    local common_packages=(
        "vainfo"
        "mesa-utils"
        "firmware-linux"
    )
    
    local intel_packages=(
        "intel-media-va-driver"
        "i965-va-driver"
        "mesa-va-drivers"
        "mesa-vdpau-drivers"
        "libva2"
        "libva-drm2"
        "libvdpau1"
        "intel-gpu-tools"
        "intel-microcode"
    )
    
    local nvidia_packages=(
        "nvidia-driver"
        "nvidia-vaapi-driver"
        "libnvidia-encode1"
        "nvidia-settings"
    )
    
    local amd_packages=(
        "mesa-va-drivers"
        "mesa-vdpau-drivers"
        "libva2"
        "libva-drm2"
        "libvdpau1"
        "radeontop"
        "firmware-amd-graphics"
    )
    
    # 安装通用显卡组件
    log_info "安装通用显卡组件..."
    safe_execute "apt install -y ${common_packages[*]}"
    
    # 根据检测结果安装对应驱动
    if [[ "$INTEL_GPU" == "yes" ]]; then
        install_intel_drivers "${intel_packages[@]}"
    fi
    
    if [[ "$NVIDIA_GPU" == "yes" ]]; then
        install_nvidia_drivers "${nvidia_packages[@]}"
    fi
    
    if [[ "$AMD_GPU" == "yes" ]]; then
        install_amd_drivers "${amd_packages[@]}"
    fi
    
    # 如果没有特定显卡，使用通用配置
    if [[ -z "$GPU_TYPE" || "$GPU_TYPE" == "generic" ]]; then
        log_info "安装通用显卡驱动..."
        safe_execute "apt install -y mesa-va-drivers mesa-vdpau-drivers libva2 libvdpau1"
        GPU_TYPE="generic"
    fi
    
    log_success "显卡驱动安装完成，类型: $GPU_TYPE"
}

install_intel_drivers() {
    local packages=("$@")
    log_info "安装 Intel 显卡驱动..."
    safe_execute "apt install -y ${packages[*]}"
    log_success "Intel 显卡驱动安装完成"
}

install_nvidia_drivers() {
    local packages=("$@")
    log_info "安装 NVIDIA 显卡驱动..."
    
    # 添加 non-free 仓库
    if ! grep -q "non-free" /etc/apt/sources.list; then
        log_info "添加 non-free 仓库支持..."
        backup_file "/etc/apt/sources.list"
        safe_execute "sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list"
        safe_execute "apt update"
    fi
    
    safe_execute "apt install -y ${packages[*]}"
    log_success "NVIDIA 显卡驱动安装完成"
}

install_amd_drivers() {
    local packages=("$@")
    log_info "安装 AMD 显卡驱动..."
    safe_execute "apt install -y ${packages[*]}"
    log_success "AMD 显卡驱动安装完成"
}

# 执行显卡驱动安装
install_gpu_drivers

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
    alsa-utils \
    pulseaudio-module-bluetooth \
    pavucontrol

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

# 配置用户组 - 完整的音频权限
usermod -aG audio,video,pulse,pulse-access,input,tty "$USERNAME"

# 设置目录权限
chmod 755 /home/"$USERNAME"
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"

# 8.1 配置HDMI音频支持
echo ""
echo "8.1 配置HDMI音频..."
echo "------------------"

# 创建PulseAudio配置目录
mkdir -p /home/"$USERNAME"/.config/pulse

# 配置用户级PulseAudio优先使用HDMI音频
cat > /home/"$USERNAME"/.config/pulse/default.pa <<'EOF'
#!/usr/bin/pulseaudio -nF

# 加载默认配置
.include /etc/pulse/default.pa

# 电视盒专用配置 - HDMI音频优先
# 自动检测并优先切换到HDMI音频输出
load-module module-switch-on-connect

# 音频流救援 - 当设备变更时自动切换音频流
load-module module-rescue-streams

# 设备角色管理 - HDMI设备获得媒体播放优先级
load-module module-intended-roles
EOF

# 创建HDMI优先级启动脚本
cat > /home/"$USERNAME"/.config/pulse/hdmi-priority.sh <<'EOF'
#!/bin/bash
# HDMI音频优先配置脚本

# 等待PulseAudio完全启动
sleep 2

# 查找HDMI音频设备
HDMI_SINK=$(pactl list short sinks | grep -i hdmi | head -1 | cut -f1)

if [ -n "$HDMI_SINK" ]; then
    # 设置HDMI为默认输出
    pactl set-default-sink "$HDMI_SINK"
    # 设置音量为80%
    pactl set-sink-volume "$HDMI_SINK" 80%
    # 确保不是静音
    pactl set-sink-mute "$HDMI_SINK" false
    # 将所有现有音频流切换到HDMI
    for stream in $(pactl list short sink-inputs | cut -f1); do
        pactl move-sink-input "$stream" "$HDMI_SINK" 2>/dev/null || true
    done
    echo "$(date): HDMI音频已设为默认输出: $HDMI_SINK" >> /home/mediaplayer/.local/log/browser.log
else
    echo "$(date): 警告: 未检测到HDMI音频设备" >> /home/mediaplayer/.local/log/browser.log
fi
EOF

chmod +x /home/"$USERNAME"/.config/pulse/hdmi-priority.sh

# 不创建系统级PulseAudio配置 - 避免与用户级配置冲突
# 改用用户级配置和启动脚本处理HDMI优先级

# 创建系统级HDMI音频优先级配置
cat > /etc/pulse/client.conf.d/01-hdmi-priority.conf <<'EOF'
# 电视盒专用配置 - HDMI音频绝对优先
# 确保PulseAudio客户端优先选择HDMI音频设备

# 自动连接到首选设备（HDMI）
auto-connect-localhost = yes

# 默认采样率（适合HDMI音频）
default-sample-rate = 48000
alternate-sample-rate = 44100

# 默认通道配置（立体声）
default-channel-map = front-left,front-right

# 启用设备自动切换
enable-remixing = yes
enable-lfe-remixing = yes

# HDMI音频专用缓冲配置
default-fragment-size-msec = 25
EOF

# 创建ALSA配置以确保HDMI设备优先级
cat > /home/"$USERNAME"/.asoundrc <<'EOF'
# 电视盒专用ALSA配置 - HDMI优先
pcm.!default {
    type pulse
}

ctl.!default {
    type pulse
}

# HDMI设备别名（如果PulseAudio不可用）
pcm.hdmi {
    type hw
    card 0
    device 3
}
EOF

# 设置音频配置文件权限
chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.config/pulse
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.asoundrc
chmod 644 /home/"$USERNAME"/.config/pulse/default.pa
chmod 644 /home/"$USERNAME"/.asoundrc
chmod 644 /etc/pulse/client.conf.d/01-hdmi-priority.conf

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

# 智能显示分辨率配置
# 检测当前显示器支持的最佳分辨率
echo "检测显示器分辨率..." >> /home/$USERNAME/.local/log/browser.log

# 获取主显示器名称和支持的分辨率
PRIMARY_OUTPUT=\$(xrandr | grep " connected primary" | cut -d" " -f1)
if [ -z "\$PRIMARY_OUTPUT" ]; then
    PRIMARY_OUTPUT=\$(xrandr | grep " connected" | head -1 | cut -d" " -f1)
fi

echo "检测到主显示器: \$PRIMARY_OUTPUT" >> /home/$USERNAME/.local/log/browser.log

# 获取最高分辨率
MAX_RESOLUTION=\$(xrandr | grep -A 20 "\$PRIMARY_OUTPUT connected" | grep -E "^\s+[0-9]+x[0-9]+" | head -1 | awk '{print \$1}')
echo "检测到最高分辨率: \$MAX_RESOLUTION" >> /home/$USERNAME/.local/log/browser.log

# 智能分辨率选择策略
# 4K及以上：使用1920x1080以获得更好的字体显示
# 否则使用原生分辨率
if echo "\$MAX_RESOLUTION" | grep -qE "(3840x2160|2560x1440)"; then
    # 4K或2K显示器，为了更好的浏览体验，降低到1920x1080
    CHOSEN_RESOLUTION="1920x1080"
    export DISPLAY_SCALE="1.5"  # 设置缩放因子
    echo "4K/2K显示器检测，使用1920x1080分辨率 + 1.5x缩放" >> /home/$USERNAME/.local/log/browser.log
else
    # 使用原生分辨率
    CHOSEN_RESOLUTION="\$MAX_RESOLUTION"
    export DISPLAY_SCALE="1.0"
    echo "使用原生分辨率: \$CHOSEN_RESOLUTION" >> /home/$USERNAME/.local/log/browser.log
fi

# 应用分辨率设置
if [ -n "\$PRIMARY_OUTPUT" ] && [ -n "\$CHOSEN_RESOLUTION" ]; then
    xrandr --output "\$PRIMARY_OUTPUT" --mode "\$CHOSEN_RESOLUTION" --rate 60 2>/dev/null || true
    echo "已设置分辨率: \$CHOSEN_RESOLUTION" >> /home/$USERNAME/.local/log/browser.log
else
    echo "使用默认分辨率配置" >> /home/$USERNAME/.local/log/browser.log
fi

# 隐藏鼠标指针
unclutter -idle 3 &

# 黑色背景
xsetroot -solid black

# 音频系统初始化 - 用户级PulseAudio服务
echo "初始化音频系统..." >> /home/$USERNAME/.local/log/browser.log

# 确保用户级音频服务正确启动
systemctl --user stop pulseaudio.service 2>/dev/null || true
systemctl --user stop pulseaudio.socket 2>/dev/null || true
pulseaudio --kill 2>/dev/null || true
sleep 2

# 重新加载ALSA配置
alsactl restore 2>/dev/null || true

# 启动用户级PulseAudio服务
echo "启动PulseAudio服务..." >> /home/$USERNAME/.local/log/browser.log
pulseaudio --start --log-target=journal
sleep 3

# 验证PulseAudio运行状态
if pulseaudio --check; then
    echo "✓ PulseAudio启动成功" >> /home/$USERNAME/.local/log/browser.log
    
    # 执行HDMI优先级配置脚本
    echo "执行HDMI优先级配置..." >> /home/$USERNAME/.local/log/browser.log
    /home/$USERNAME/.config/pulse/hdmi-priority.sh
else
    echo "⚠️ PulseAudio启动失败，将回退到ALSA" >> /home/$USERNAME/.local/log/browser.log
    # 设置ALSA回退模式环境变量
    export PULSE_RUNTIME_PATH=/dev/null
    export ALSA_PCM_CARD=$AUDIO_CARD
    export ALSA_PCM_DEVICE=$AUDIO_DEVICE
fi

# 额外验证HDMI音频配置
sleep 2
HDMI_SINK=\$(pactl list short sinks | grep -i hdmi | head -1 | cut -f1)
if [ -n "\$HDMI_SINK" ]; then
    echo "✓ HDMI音频设备已配置: \$HDMI_SINK" >> /home/$USERNAME/.local/log/browser.log
    # 确保HDMI设备是活动状态
    pactl set-sink-volume "\$HDMI_SINK" 80%
    pactl set-sink-mute "\$HDMI_SINK" false
    # 记录当前默认输出设备
    DEFAULT_SINK=\$(pactl get-default-sink 2>/dev/null)
    echo "当前默认音频输出: \$DEFAULT_SINK" >> /home/$USERNAME/.local/log/browser.log
else
    echo "⚠️ 警告: 未检测到HDMI音频设备，请检查连接" >> /home/$USERNAME/.local/log/browser.log
    echo "可用音频设备:" >> /home/$USERNAME/.local/log/browser.log
    pactl list short sinks >> /home/$USERNAME/.local/log/browser.log 2>&1 || true
fi

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

# 智能音频配置检测
echo "\$(date): 检测音频配置..." >> /home/$USERNAME/.local/log/browser.log

# 检查PulseAudio状态
if pulseaudio --check >/dev/null 2>&1; then
    echo "\$(date): PulseAudio运行中，使用PulseAudio音频" >> /home/$USERNAME/.local/log/browser.log
    AUDIO_MODE="pulse"
    
    # 检测并设置HDMI音频设备
    HDMI_DEVICE=\$(pactl list short sinks | grep -i hdmi | head -1 | cut -f2)
    if [ -n "\$HDMI_DEVICE" ]; then
        pactl set-default-sink "\$HDMI_DEVICE" 2>/dev/null || true
        echo "\$(date): 设置HDMI为默认音频输出: \$HDMI_DEVICE" >> /home/$USERNAME/.local/log/browser.log
    fi
else
    echo "\$(date): PulseAudio不可用，回退到ALSA直接输出" >> /home/$USERNAME/.local/log/browser.log
    AUDIO_MODE="alsa"
    export PULSE_RUNTIME_PATH=/dev/null
    export ALSA_PCM_CARD=$AUDIO_CARD
    export ALSA_PCM_DEVICE=$AUDIO_DEVICE
fi

# 智能显示缩放检测
echo "\$(date): 检测显示器配置..." >> /home/$USERNAME/.local/log/browser.log

# 检测当前分辨率
CURRENT_RESOLUTION=\$(xrandr | grep "\\*" | awk '{print \$1}')
echo "\$(date): 当前分辨率: \$CURRENT_RESOLUTION" >> /home/$USERNAME/.local/log/browser.log

# 智能缩放策略
if echo "\$CURRENT_RESOLUTION" | grep -qE "(3840x2160|2560x1440)"; then
    # 4K/2K分辨率 - 使用浏览器缩放
    BROWSER_ZOOM="1.5"
    DPI_SCALE="144"
    echo "\$(date): 高分辨率检测，设置1.5x缩放" >> /home/$USERNAME/.local/log/browser.log
elif echo "\$CURRENT_RESOLUTION" | grep -qE "(1920x1080|1680x1050)"; then
    # 1080p分辨率 - 正常缩放
    BROWSER_ZOOM="1.0" 
    DPI_SCALE="96"
    echo "\$(date): 标准分辨率，使用默认缩放" >> /home/$USERNAME/.local/log/browser.log
else
    # 其他分辨率 - 自适应
    BROWSER_ZOOM="1.2"
    DPI_SCALE="120"
    echo "\$(date): 其他分辨率，使用1.2x缩放" >> /home/$USERNAME/.local/log/browser.log
fi

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

echo "\$(date): 启动 Chromium (智能缩放 + 防撕裂优化)..." >> /home/$USERNAME/.local/log/browser.log
echo "\$(date): 使用缩放级别: \$BROWSER_ZOOM, DPI: \$DPI_SCALE" >> /home/$USERNAME/.local/log/browser.log

# 启动 Chromium - 添加智能缩放和优化参数 + ALSA音频
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
    --force-device-scale-factor=\$BROWSER_ZOOM \\
    --high-dpi-support=1 \\
    --force-color-profile=srgb \\
    --disable-font-subpixel-positioning \\
    \$(if [ "\$AUDIO_MODE" = "alsa" ]; then echo "--alsa-output-device=$WORKING_AUDIO_DEVICE --enable-exclusive-audio --try-supported-channel-layouts"; fi) \\
    --audio-buffer-size=2048 \\
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
echo "显示配置:"
echo "当前分辨率: \$(xrandr | grep "\\*" | awk '{print \$1}')"
echo "主显示器: \$(xrandr | grep " connected" | head -1 | cut -d" " -f1)"
echo ""
echo "音频设备状态:"
echo "PulseAudio状态: \$(systemctl --user is-active pulseaudio 2>/dev/null || echo '未知')"
echo "音频输出设备:"
pactl list short sinks 2>/dev/null || echo "PulseAudio未运行"
echo "当前默认输出:"
pactl get-default-sink 2>/dev/null || echo "无法获取"
echo "HDMI音频检测:"
pactl list short sinks | grep -i hdmi || echo "未检测到HDMI音频"
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

# 电视盒专用HDMI音频修复脚本
cat > /home/"$USERNAME"/.local/bin/fix-hdmi-audio.sh <<'EOF'
#!/bin/bash

echo "电视盒专用HDMI音频修复工具"
echo "=========================="
echo "专为HDMI音视频传输优化"
echo ""

echo "1. 重启PulseAudio服务..."
pulseaudio --kill 2>/dev/null || true
sleep 3
pulseaudio --start &
sleep 5

echo "2. 执行HDMI优先级配置..."
/home/mediaplayer/.config/pulse/hdmi-priority.sh

echo "3. 检测音频设备..."
echo "可用音频输出设备:"
pactl list short sinks

echo ""
echo "4. 强制HDMI音频配置..."
HDMI_SINK=$(pactl list short sinks | grep -i hdmi | head -1 | cut -f1)
if [ -n "$HDMI_SINK" ]; then
    echo "✓ 找到HDMI音频设备: $HDMI_SINK"
    echo "5. 强制设置HDMI为唯一默认输出..."
    pactl set-default-sink "$HDMI_SINK"
    pactl set-sink-volume "$HDMI_SINK" 80%
    pactl set-sink-mute "$HDMI_SINK" false
    
    # 将所有现有音频流强制切换到HDMI
    echo "6. 切换所有音频流到HDMI..."
    for stream in $(pactl list short sink-inputs | cut -f1); do
        pactl move-sink-input "$stream" "$HDMI_SINK" 2>/dev/null || true
    done
    
    echo "✓ HDMI音频已强制设为默认输出"
    echo "✓ 所有音频流已切换到HDMI"
else
    echo "❌ 严重警告: 未找到HDMI音频设备"
    echo ""
    echo "电视盒必须通过HDMI传输音频，请检查："
    echo "- HDMI线缆是否正确连接到电视"
    echo "- 电视音频输入设置是否正确"
    echo "- 显卡驱动是否正确安装"
    echo "- 电视是否支持HDMI音频"
    echo ""
    echo "故障排除建议："
    echo "- 重启电视和设备"
    echo "- 尝试不同的HDMI端口"
    echo "- 检查电视音频设置菜单"
fi

echo ""
echo "7. 当前音频配置验证:"
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
echo "默认输出设备: $DEFAULT_SINK"
if echo "$DEFAULT_SINK" | grep -qi hdmi; then
    echo "✓ 当前默认输出为HDMI - 配置正确"
else
    echo "⚠️ 当前默认输出不是HDMI - 可能需要重启系统"
fi

echo ""
echo "8. HDMI音频测试..."
if [ -n "$HDMI_SINK" ]; then
    echo "正在通过HDMI播放测试音频（3秒）..."
    echo "如果电视有声音说明配置成功"
    speaker-test -t sine -f 1000 -l 3 -D pulse -s 1 &
    SPEAKER_PID=$!
    sleep 3
    kill $SPEAKER_PID 2>/dev/null || true
    echo "测试完成"
else
    echo "跳过音频测试（未找到HDMI设备）"
fi

echo ""
echo "================================================"
echo "修复完成！"
if [ -n "$HDMI_SINK" ]; then
    echo "✓ HDMI音频配置成功，电视应该能听到声音"
    echo "如果仍无声音，请检查电视音频设置"
else
    echo "❌ HDMI音频配置失败，需要检查硬件连接"
fi
echo ""
echo "重启浏览器应用新配置:"
echo "sudo -u mediaplayer /home/mediaplayer/.local/bin/restart-browser.sh"
EOF

chmod +x /home/"$USERNAME"/.local/bin/fix-hdmi-audio.sh

# 音频测试和验证脚本
cat > /home/"$USERNAME"/.local/bin/test-audio.sh <<'EOF'
#!/bin/bash

echo "音频系统测试工具"
echo "================"
echo ""

# 检查PulseAudio状态
echo "1. 检查PulseAudio状态..."
if pulseaudio --check; then
    echo "✓ PulseAudio 运行中"
    
    echo ""
    echo "2. 可用音频输出设备:"
    pactl list short sinks
    
    echo ""
    echo "3. 当前默认音频输出:"
    pactl get-default-sink
    
    echo ""
    echo "4. HDMI音频设备检测:"
    HDMI_SINK=$(pactl list short sinks | grep -i hdmi | head -1)
    if [ -n "$HDMI_SINK" ]; then
        echo "✓ 找到HDMI音频设备: $HDMI_SINK"
        HDMI_ID=$(echo "$HDMI_SINK" | cut -f1)
        
        echo ""
        read -p "是否测试HDMI音频输出？(y/N): " test_hdmi
        if [[ "$test_hdmi" =~ ^[Yy]$ ]]; then
            echo "播放3秒测试音频到HDMI..."
            speaker-test -t sine -f 1000 -l 3 -D pulse -s 1 &
            SPEAKER_PID=$!
            sleep 3
            kill $SPEAKER_PID 2>/dev/null || true
            echo "测试完成"
        fi
    else
        echo "❌ 未找到HDMI音频设备"
    fi
    
else
    echo "❌ PulseAudio 未运行"
    
    echo ""
    echo "2. 检查ALSA设备..."
    aplay -l | grep -E "(card|device)" || echo "❌ 无ALSA设备"
    
    echo ""
    read -p "是否测试ALSA音频输出？(y/N): " test_alsa
    if [[ "$test_alsa" =~ ^[Yy]$ ]]; then
        echo "播放3秒测试音频到ALSA设备..."
        speaker-test -t sine -f 1000 -l 3 -D hw:0,3 &
        SPEAKER_PID=$!
        sleep 3
        kill $SPEAKER_PID 2>/dev/null || true
        echo "测试完成"
    fi
fi

echo ""
echo "5. 系统音频组权限检查:"
groups $USER | grep -q audio && echo "✓ 用户在audio组中" || echo "❌ 用户不在audio组中"
groups $USER | grep -q pulse && echo "✓ 用户在pulse组中" || echo "❌ 用户不在pulse组中"

echo ""
echo "测试完成！"
EOF

chmod +x /home/"$USERNAME"/.local/bin/test-audio.sh

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

apply_final_optimizations() {
    log_info "================================================"
    log_info "步骤 16: 系统优化和GRUB更新"
    log_info "================================================"
    
    # 备份系统配置文件
    backup_file "/etc/sysctl.conf"
    backup_file "/etc/default/grub"
    
    # 应用内核参数优化
    log_info "应用内核参数优化..."
    
    # 减少交换使用
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    log_info "设置vm.swappiness=10（减少swap使用）"
    
    # 优化 I/O
    echo "vm.dirty_ratio=15" >> /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf
    log_info "优化I/O参数（dirty_ratio=15, dirty_background_ratio=5）"
    
    # 更新 GRUB 配置
    log_info "更新 GRUB 配置..."
    safe_execute "update-grub"
    
    # 应用系统性能优化
    optimize_system_performance
    
    # 监控当前资源使用
    monitor_resources
    
    log_success "系统优化完成"
}

# 执行最终优化
apply_final_optimizations

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
echo "✓ 智能分辨率检测和缩放"
echo "✓ HDMI音频优先配置"
echo "✓ 4K/2K显示器智能缩放支持"
echo "✓ 自动登录"
echo "✓ 开机自动启动浏览器"
echo "✓ 全屏媒体播放"
echo "✓ 浏览器自动重启"
echo ""
echo "管理命令:"
echo "- 重启浏览器: sudo -u $USERNAME /home/$USERNAME/.local/bin/restart-browser.sh"
echo "- 检查状态: sudo -u $USERNAME /home/$USERNAME/.local/bin/check-system.sh"
echo "- 测试音频: sudo -u $USERNAME /home/$USERNAME/.local/bin/test-audio.sh"
echo "- 修复HDMI音频: sudo -u $USERNAME /home/$USERNAME/.local/bin/fix-hdmi-audio.sh"
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
echo "配置摘要:"
echo "✓ 音频设备: $WORKING_AUDIO_DEVICE"
if [ "$INTEL_GPU" = "yes" ]; then
    echo "✓ Intel 显卡硬件加速已配置"
fi
if [ "$NVIDIA_GPU" = "yes" ]; then
    echo "✓ NVIDIA 显卡硬件加速已配置"
fi  
if [ "$AMD_GPU" = "yes" ]; then
    echo "✓ AMD 显卡硬件加速已配置"
fi
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
        echo ""
        
        # 询问是否重启浏览器应用新配置
        echo "------------------------------------------"
        read -p "🔄 是否重启浏览器应用新的音频配置？(y/N): " BROWSER_RESTART
        
        case $BROWSER_RESTART in
            [Yy]|[Yy][Ee][Ss])
                echo "✅ 正在重启浏览器服务..."
                
                # 停止浏览器监控进程
                sudo -u $USERNAME pkill -f browser-monitor 2>/dev/null || true
                sudo -u $USERNAME pkill -f chromium 2>/dev/null || true
                sleep 3
                
                # 重新启动浏览器监控
                echo "🚀 启动浏览器监控进程..."
                sudo -u $USERNAME nohup /home/$USERNAME/.local/bin/browser-monitor.sh >/dev/null 2>&1 &
                sleep 2
                
                echo "✅ 浏览器已重启，新的音频配置已生效"
                echo "📺 浏览器应该在几秒内自动启动"
                ;;
            *)
                echo "⏭️  已跳过浏览器重启"
                echo "💡 手动重启浏览器命令:"
                echo "   sudo -u $USERNAME /home/$USERNAME/.local/bin/restart-browser.sh"
                ;;
        esac
        
        echo ""
        echo "💡 手动重启系统命令: sudo reboot"
        echo "🎉 感谢使用飞牛电视盒配置脚本！"
        ;;
esac