# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

这是一个专为飞牛fnOS系统设计的一键电视盒配置脚本，将基于Debian的fnOS服务器自动转换为专用的媒体播放设备。项目实现了智能显卡检测、轻量级桌面环境部署、硬件加速配置和完全自动化的影视播放体验。

## 核心架构

### 主要组件
- `install.sh` - 核心安装脚本，负责系统检测、软件安装和配置
- `README.md` - 完整的用户文档和使用指南

### 系统架构设计
```
fnOS系统 → 显卡检测 → 驱动安装 → 桌面环境 → 浏览器配置 → 自动启动
```

### 技术栈
- **基础系统**: Debian (fnOS)
- **桌面环境**: Openbox (轻量级窗口管理器)
- **显示服务**: X11 + LightDM
- **浏览器**: Chromium (硬件加速优化)
- **音频**: PulseAudio + ALSA
- **显卡支持**: Intel/NVIDIA/AMD 多显卡架构

## 关键功能模块

### 1. 智能显卡检测系统 (install.sh:27-73)
- 自动识别Intel集显、NVIDIA独显、AMD显卡
- 支持手动显卡类型选择
- 针对不同显卡安装相应驱动包

### 2. 硬件加速配置 (install.sh:130-211)
```bash
# 驱动包组织结构
INTEL_PACKAGES=(intel-media-va-driver, i965-va-driver, ...)
NVIDIA_PACKAGES=(nvidia-driver, nvidia-vaapi-driver, ...)
AMD_PACKAGES=(mesa-va-drivers, radeontop, ...)
```

### 3. 防撕裂优化系统 (install.sh:280-310)
- Intel显卡: TearFree + AccelMethod配置
- 内核参数优化: i915.enable_psr=0
- X11配置: 三重缓冲和垂直同步

### 4. 自动启动流程 (install.sh:330-366)
```bash
# 启动顺序
等待X服务器 → 设置显示环境 → 隐藏鼠标 → 启动音频 → 等待系统就绪 → 启动浏览器监控
```

### 5. 浏览器监控系统 (install.sh:494-567)
- 持续监控浏览器进程状态
- 自动重启机制
- 详细日志记录系统

## 常用开发命令

### 脚本执行
```bash
# 安装部署
chmod +x install.sh
./install.sh

# 测试运行 (不执行实际安装)
bash -n install.sh  # 语法检查
```

### 系统管理命令
```bash
# 重启浏览器
sudo -u mediaplayer /home/mediaplayer/.local/bin/restart-browser.sh

# 系统状态检查
sudo -u mediaplayer /home/mediaplayer/.local/bin/check-system.sh

# 查看实时日志
tail -f /home/mediaplayer/.local/log/browser-monitor.log
tail -f /home/mediaplayer/.local/log/browser.log

# 硬件加速验证
vainfo                    # 通用硬件加速信息
sudo intel_gpu_top       # Intel显卡监控
nvidia-smi               # NVIDIA显卡状态
radeontop                # AMD显卡监控
```

### 调试和故障排除
```bash
# 手动测试飞牛影视连接
curl http://127.0.0.1:5666/v

# 检查服务状态
systemctl status lightdm
systemctl status fnnas

# 查看系统日志
journalctl -f
journalctl -u lightdm
```

## 配置文件结构

### 系统配置文件
- `/etc/lightdm/lightdm.conf` - 自动登录配置
- `/etc/X11/xorg.conf.d/20-intel.conf` - Intel显卡防撕裂配置
- `/etc/environment` - 硬件加速环境变量
- `/etc/default/grub` - 内核参数优化

### 用户配置目录
```
/home/mediaplayer/
├── .config/openbox/
│   ├── autostart          # 开机自启动脚本
│   └── rc.xml             # 快捷键和窗口管理
├── .local/bin/
│   ├── start-browser.sh      # 浏览器启动脚本
│   ├── browser-monitor.sh    # 监控和自动重启
│   ├── restart-browser.sh    # 手动重启功能
│   └── check-system.sh       # 系统状态检查
└── .local/log/
    ├── browser.log           # 浏览器运行日志
    └── browser-monitor.log   # 监控系统日志
```

## 显卡特定配置

### Intel显卡优化
- 环境变量: `LIBVA_DRIVER_NAME=iHD`, `VDPAU_DRIVER=va_gl`
- X11配置: TearFree, AccelMethod=sna, DRI=3
- 浏览器参数: `--use-gl=egl`, `--enable-features=VaapiVideoDecoder`

### NVIDIA显卡优化  
- 添加non-free仓库支持
- NVIDIA驱动和VAAPI支持
- 专门的GPU光栅化参数

### AMD显卡优化
- Mesa驱动和固件支持
- VAAPI/VDPAU硬件解码
- Radeon特定的优化配置

## 浏览器启动参数详解

关键的Chromium启动参数 (install.sh:443-464):
```bash
--kiosk                                    # 全屏kiosk模式
--enable-features=VaapiVideoDecoder        # 硬件视频解码
--use-gl=egl                              # EGL图形渲染
--enable-gpu-rasterization               # GPU光栅化
--autoplay-policy=no-user-gesture-required # 自动播放
--disable-features=VizDisplayCompositor   # 禁用软件合成
```

## 自动登录机制

### 登录流程
1. LightDM自动登录到mediaplayer用户
2. 启动Openbox桌面环境  
3. 执行autostart脚本
4. 等待飞牛影视服务就绪
5. 启动全屏浏览器
6. 自动按回车键进入系统

### 服务等待机制 (install.sh:425-438)
```bash
# 30次循环检查飞牛影视服务
for i in {1..30}; do
    if curl -s --connect-timeout 3 http://127.0.0.1:5666/v >/dev/null 2>&1; then
        break
    fi
    sleep 5
done
```

## 系统优化策略

### 性能优化
- 减少swap使用: `vm.swappiness=10`
- I/O优化: `vm.dirty_ratio=15`, `vm.dirty_background_ratio=5`
- 禁用屏保和电源管理
- 4线程光栅化: `--num-raster-threads=4`

### 稳定性保障
- 浏览器进程监控和自动重启
- 异常检测和恢复机制
- 详细的日志记录系统
- 多层级的故障处理

## 默认配置参数

- **用户名**: `mediaplayer`
- **默认URL**: `http://127.0.0.1:5666/v` (飞牛影视地址)
- **检查间隔**: 30秒 (浏览器监控)
- **服务等待**: 最多150秒 (30次×5秒)
- **启动延迟**: 30秒 (等待系统完全就绪)

## 扩展和定制

### 修改默认URL
编辑 `install.sh` 第22行:
```bash
DEFAULT_URL="http://127.0.0.1:YOUR_PORT/v"
```

### 调整启动时序
修改 `autostart` 脚本中的sleep时间以适应不同硬件性能

### 添加自定义功能
在 `/home/mediaplayer/.local/bin/` 目录添加脚本并在autostart中调用

## 故障排除要点

### 常见问题模式
1. **502错误**: 飞牛影视服务未启动，等待或检查服务状态
2. **黑屏问题**: 显卡驱动或X11配置问题，检查日志
3. **无声音**: PulseAudio配置问题，重启音频服务
4. **撕裂现象**: 防撕裂配置未生效，确认重启后配置

### 日志分析技巧
- 监控日志显示进程状态和重启原因
- 浏览器日志包含启动过程和错误信息
- 系统日志提供服务和驱动相关信息

这个项目专注于将通用的fnOS服务器转换为专用的媒体播放设备，通过智能化的硬件检测和自动化配置，实现了真正的"开机即播"体验。