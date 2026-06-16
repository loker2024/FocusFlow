#!/bin/bash

# FocusFlow 构建脚本
# 将 Swift Package Manager 构建的可执行文件打包成 .app

set -e

APP_NAME="FocusFlow"
BUILD_DIR=".build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🔨 构建 ${APP_NAME}..."

# 清理旧的构建
rm -rf "${APP_BUNDLE}"

# 使用 swift build 编译
swift build -c release

# 创建 .app 目录结构
echo "📦 创建应用包..."
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 复制可执行文件
cp "${BUILD_DIR}/release/${APP_NAME}" "${MACOS_DIR}/"

# 复制 Info.plist
cp "FocusFlow/Info.plist" "${CONTENTS_DIR}/"

# 复制 Entitlements（如果存在）
if [ -f "FocusFlow/FocusFlow.entitlements" ]; then
    cp "FocusFlow/FocusFlow.entitlements" "${CONTENTS_DIR}/"
fi

echo "✅ 构建完成！"
echo "📍 应用位置: ${APP_BUNDLE}"
echo ""
echo "运行方式："
echo "  1. 双击 ${APP_BUNDLE} 运行"
echo "  2. 或者执行: open ${APP_BUNDLE}"
