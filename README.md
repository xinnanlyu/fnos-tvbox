# 飞牛fnOS电视盒一键配置脚本

[![GitHub Stars](https://img.shields.io/github/stars/xinnanlyu/fnos-tvbox)](https://github.com/xinnanlyu/fnos-tvbox)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![fnOS Compatible](https://img.shields.io/badge/fnOS-Compatible-green.svg)](https://www.fnnas.com/)

将安装了飞牛fnOS的服务器一键配置为专用电视盒的自动化脚本。支持Intel/NVIDIA/AMD显卡自动检测，通过轻量级桌面环境访问飞牛影视，实现大屏幕视频观看体验。

## ⚡ 快速开始

**⚠️ 重要警告**: 此脚本将修改系统配置，包括显卡驱动、桌面环境和启动设置，请先备份重要数据

### 一键安装

```bash
# 1. SSH连接到fnOS设备
ssh your-username@your-fnos-ip

# 2. 下载并运行脚本
wget https://raw.githubusercontent.com/xinnanlyu/fnos-tvbox/main/install.sh
sudo bash install.sh

# 3. 重启系统
sudo reboot
```

> 安装完成后，系统将自动启动电视盒模式

## 📋 系统要求

### 硬件要求
- **CPU**: Intel/AMD处理器（推荐第8代或更新）
- **显卡**: Intel集显/NVIDIA独显/AMD显卡（自动检测）
- **内存**: 4GB或以上
- **存储**: 至少2GB可用空间（用于桌面环境）
- **显示**: HDMI/DP输出连接到电视/显示器

### 软件要求
- **系统**: 基于Debian的飞牛fnOS
- **网络**: 设备需要联网下载组件
- **飞牛影视**: 已安装并正常运行
- **SSH**: 已启用SSH服务

## 🎯 项目背景

飞牛fnOS是一个优秀的私有云系统，内置了强大的飞牛影视功能。本项目旨在让用户能够：

- 🖥️ **直接在电视/显示器上观看** - 无需额外设备
- 🚀 **一键部署** - 自动配置所有必要组件  
- 📺 **专用电视盒体验** - 开机即播，无人值守
- 🎬 **硬件加速播放** - 流畅的4K视频体验
- 🔄 **自动故障恢复** - 浏览器崩溃自动重启
- 🎯 **零交互体验** - 自动登录，无需手动操作

## ✨ 功能特性

### 核心功能
- 🖥️ **轻量级桌面环境** - 基于Openbox，资源占用极低
- 🎮 **智能显卡检测** - 自动识别Intel/NVIDIA/AMD显卡并安装对应驱动
- 🌐 **优化的Chromium** - 硬件加速配置，专为视频播放优化
- 🚫 **防画面撕裂** - 针对不同显卡的防撕裂配置
- 🎵 **音频支持** - PulseAudio完整配置

### 自动化特性  
- 🚀 **开机自启动** - 系统启动后自动打开飞牛影视
- 🔄 **智能重启机制** - 浏览器异常自动恢复
- 🔒 **自动登录** - 自动按回车进入系统，无需手动干预
- ⏱️ **服务等待机制** - 确保飞牛影视完全启动后再打开浏览器
- 🎮 **智能按键** - 自动处理登录页面，实现真正的零操作

## 📋 前期准备工作

### 必需步骤

#### 1. 安装飞牛fnOS
- 前往 [飞牛fnOS官网](https://www.fnnas.com/) 下载系统镜像
- 按照官方文档安装fnOS到您的设备

#### 2. 配置飞牛影视
- 登录fnOS Web管理界面
- 安装并配置飞牛影视应用，确保正常工作

#### 3. 启用SSH服务

### 建议的额外步骤

#### 4. 修改root密码
```bash
# SSH连接到fnOS设备后：

sudo su
passwd

# 设置一个强密码
```

#### 5. 准备工作目录
```bash
# 切换到root目录
cd

# 准备下载脚本
# （下一步会用到git clone）
```


## 🚀 快速部署

### 方法一：Git克隆（推荐）

```bash
# 1. SSH连接到fnOS设备
ssh your-username@your-fnos-ip

# 2. 切换到root用户和目录
sudo su
cd /root

# 3. 克隆项目
git clone https://github.com/xinnanlyu/fnos-tvbox.git
cd fnos-tvbox

# 4. 运行安装脚本
chmod +x install.sh
./install.sh
```

### 方法二：直接下载

```bash
# SSH连接后执行
sudo su
cd /root
wget https://raw.githubusercontent.com/xinnanlyu/fnos-tvbox/main/install.sh
chmod +x install.sh
./install.sh
```

### 安装过程

脚本将自动：
1. 🔍 **检测显卡硬件** - 自动识别Intel/NVIDIA/AMD显卡
2. 📦 **安装桌面环境** - Openbox + 必要组件
3. 🎮 **配置显卡驱动** - 针对检测到的显卡安装对应驱动
4. 🚫 **防撕裂优化** - 根据显卡类型配置防撕裂
5. 🌐 **优化Chromium** - 显卡特定的硬件加速参数
6. 👤 **创建媒体用户** - 专用的mediaplayer用户
7. 🔧 **配置自启动** - 开机自动打开飞牛影视
8. 🎯 **配置自动登录** - 自动按键进入系统，无需手动操作
9. 📊 **系统优化** - 性能和稳定性调优

### 完成部署

```bash
# 安装完成后重启系统
reboot
```

重启后系统将：
- 自动登录到mediaplayer用户
- 启动轻量级桌面环境
- 等待飞牛影视服务就绪
- 自动打开全屏浏览器访问飞牛影视
- **自动按回车进入系统**（无需手动操作）
- 开始您的观影体验！

## ⚙️ 配置说明

### 默认配置

- **访问地址**: `http://127.0.0.1:5666/v`（飞牛影视默认地址）
- **专用用户**: `mediaplayer`
- **启动模式**: 全屏Kiosk模式
- **自动登录**: 已启用（包含自动按键）
- **自动重启**: 浏览器异常时自动恢复
- **零交互**: 开机后完全无需手动操作

### 自定义飞牛影视地址

如果您的飞牛影视运行在不同端口，修改脚本中的URL：

```bash
# 编辑脚本
nano install.sh

# 找到并修改这行
DEFAULT_URL="http://127.0.0.1:YOUR_PORT/v"
```

## 🎮 使用体验

### 开机体验
1. 🔌 **接通电源** - fnOS设备启动
2. ⏱️ **等待启动** - 约30-45秒系统完全就绪
3. 🌐 **自动打开浏览器** - 全屏访问飞牛影视
4. 🎯 **自动登录** - 系统自动按回车进入
5. 📺 **进入影视界面** - 无需任何手动操作
6. 🎬 **开始观影** - 享受大屏幕观影体验

### 操作方式
- **遥控器/键盘导航** - 在影视界面中浏览内容
- **自动全屏** - 视频播放时自动全屏显示
- **硬件解码** - 流畅播放高清/4K内容
- **故障自愈** - 异常情况自动恢复

### 便捷快捷键
- **Alt + F4**: 关闭当前窗口（系统会自动重启浏览器）
- **Ctrl + Alt + T**: 打开终端（管理维护）
- **F11**: 手动切换全屏模式
- **F5**: 刷新页面

## 📁 系统结构

```
fnOS设备
├── 飞牛影视服务 (端口5666)
├── 桌面环境 (Openbox)
└── /home/mediaplayer/
    ├── .config/openbox/
    │   ├── autostart          # 开机自启脚本
    │   └── rc.xml             # 快捷键配置
    ├── .local/bin/
    │   ├── start-browser.sh      # 浏览器启动
    │   ├── browser-monitor.sh    # 监控脚本  
    │   ├── restart-browser.sh    # 重启功能
    │   └── check-system.sh       # 状态检查
    └── .local/log/
        ├── browser.log           # 浏览器日志
        └── browser-monitor.log   # 监控日志
```

## 🔧 维护管理

### 常用管理命令

```bash
# SSH连接到设备进行管理

# 重启浏览器
sudo -u mediaplayer /home/mediaplayer/.local/bin/restart-browser.sh

# 检查系统状态  
sudo -u mediaplayer /home/mediaplayer/.local/bin/check-system.sh

# 查看实时日志
tail -f /home/mediaplayer/.local/log/browser-monitor.log

# 验证硬件加速
vainfo
```

### 性能监控

```bash
# 查看系统资源使用
htop

# 检查GPU使用情况  
sudo intel_gpu_top

# 查看飞牛影视服务状态
systemctl status fnnas
```

## 🛠️ 故障排除

### 常见问题

#### 🔴 浏览器显示502错误
**原因**: 飞牛影视服务尚未完全启动  
**解决**: 等待1-2分钟，系统会自动重试

### 显卡特定检查

#### 🔴 Intel显卡问题
**检查**:
```bash
# 验证Intel硬件加速
vainfo | grep H264

# Intel GPU使用情况
sudo intel_gpu_top
```

#### 🔴 NVIDIA显卡问题  
**检查**:
```bash
# 验证NVIDIA驱动
nvidia-smi

# 检查CUDA/OpenGL
nvidia-settings
```

#### 🔴 AMD显卡问题
**检查**:
```bash
# 验证Mesa驱动
glxinfo | grep -i amd

# AMD GPU使用情况
radeontop
```

#### 🔴 无声音输出
**解决**:
```bash
# 重启音频服务
pulseaudio --kill && pulseaudio --start

# 检查音频设备
pactl list short sinks
```

#### 🔴 飞牛影视访问异常
**检查**:
```bash
# 测试飞牛影视连接
curl http://127.0.0.1:5666/v

# 检查飞牛服务状态
systemctl status fnnas
```

### 日志分析

```bash
# 查看详细启动日志
tail -50 /home/mediaplayer/.local/log/browser.log

# 查看监控日志
tail -50 /home/mediaplayer/.local/log/browser-monitor.log

# 查看系统日志
journalctl -f
```

## 🚀 高级定制

### 自定义启动页面

```bash
# 编辑启动脚本
sudo nano /home/mediaplayer/.local/bin/start-browser.sh

# 修改DEFAULT_URL为您想要的页面
```

### 调整启动时序

```bash
# 编辑自启动配置
sudo nano /home/mediaplayer/.config/openbox/autostart

# 调整sleep时间以适应您的硬件
```

### 更换显卡驱动

```bash
# 重新运行脚本会自动检测新显卡
sudo ./install.sh
```

### 添加自定义功能

在`/home/mediaplayer/.local/bin/`目录下添加自定义脚本，并在autostart中调用。

## 📈 性能优化

### 已包含的优化
- **多显卡支持**: Intel/NVIDIA/AMD自动检测和优化
- **硬件加速**: VA-API/NVENC/VCE硬件解码
- **防撕裂配置**: 针对不同显卡的防撕裂技术
- **内存优化**: 减少swap使用
- **I/O优化**: 调整缓存策略
- **浏览器优化**: 显卡特定的GPU光栅化参数


## 🤝 社区支持

### 反馈渠道
- 🐛 **Bug报告**: 提交Issue描述问题
- 💡 **功能建议**: 通过Issue提出改进意见  
- 📚 **使用分享**: Discussions分享使用经验
- 🛠️ **代码贡献**: 提交Pull Request

### 贡献指南

我们欢迎所有形式的贡献：

1. **Fork项目** 到您的GitHub账户
2. **创建分支** (`git checkout -b feature/amazing-feature`)
3. **提交更改** (`git commit -m 'Add amazing feature'`)
4. **推送分支** (`git push origin feature/amazing-feature`)
5. **创建Pull Request**

## 📄 许可协议

本项目采用MIT许可证，详见[LICENSE](LICENSE)文件。

## 🙏 致谢

- **飞牛科技** - 提供优秀的fnOS系统和飞牛影视
- **Debian项目** - 稳定可靠的基础系统
- **Openbox** - 轻量级窗口管理器
- **Chromium** - 开源浏览器引擎
- **Intel** - 开源显卡驱动支持

## 🔗 相关链接

- [飞牛fnOS官网](https://www.fnnas.com/)
- [飞牛科技官方论坛](https://www.fnnas.com/forum)
- [项目GitHub仓库](https://github.com/xinnanlyu/fnos-tvbox)
- [Intel Graphics for Linux](https://01.org/linuxgraphics)
- [NVIDIA Linux Driver](https://www.nvidia.com/en-us/drivers/unix/)
- [AMD GPU Linux Driver](https://www.amd.com/en/support/linux-drivers)
- [Openbox官方文档](http://openbox.org/)

## 📊 项目状态

- **支持的显卡**: Intel集显, NVIDIA独显, AMD显卡
- **测试系统**: 飞牛fnOS (基于Debian)
- **维护状态**: 积极维护中
- **许可协议**: MIT开源许可

---

**🎬 享受您的专属电视盒体验！**

> 支持Intel/NVIDIA/AMD多种显卡，将fnOS服务器秒变专业电视盒，在大屏幕上畅享您的私有影音内容。