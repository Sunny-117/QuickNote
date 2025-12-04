#!/bin/bash

# QuickNote 发布脚本
# 用法: ./scripts/release.sh v1.0.0

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "❌ 错误: 请提供版本号"
    echo "用法: ./scripts/release.sh v1.0.0"
    exit 1
fi

echo "🚀 开始发布 QuickNote $VERSION"
echo ""

# 检查是否安装了 gh CLI
if ! command -v gh &> /dev/null; then
    echo "❌ 错误: 未安装 GitHub CLI (gh)"
    echo "请运行: brew install gh"
    exit 1
fi

# 检查是否已登录 GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ 错误: 未登录 GitHub"
    echo "请运行: gh auth login"
    exit 1
fi

# 更新版本号
echo "📝 更新版本号..."
sed -i '' "s/\"version\": \".*\"/\"version\": \"${VERSION#v}\"/" src-tauri/tauri.conf.json
sed -i '' "s/^version = \".*\"/version = \"${VERSION#v}\"/" src-tauri/Cargo.toml

# 提交版本更新
echo "💾 提交版本更新..."
git add src-tauri/tauri.conf.json src-tauri/Cargo.toml
git commit -m "chore: bump version to $VERSION" || true

# 构建应用
echo "🔨 构建应用..."
cargo tauri build --target universal-apple-darwin

# 创建压缩包
echo "📦 创建发布包..."
cd src-tauri/target/universal-apple-darwin/release/bundle/macos
tar -czf QuickNote.app.tar.gz QuickNote.app
mv QuickNote.app.tar.gz ../../../../../../
cd ../../../../../../

# 创建 Git 标签
echo "🏷️  创建 Git 标签..."
git tag -a "$VERSION" -m "Release $VERSION"
git push origin main
git push origin "$VERSION"

# 等待 GitHub Actions 完成（可选）
echo ""
echo "⏳ 等待 GitHub Actions 构建..."
echo "你可以访问 https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions 查看进度"
echo ""
echo "或者手动创建 Release:"
echo "gh release create $VERSION QuickNote.app.tar.gz --title \"$VERSION\" --notes \"Release $VERSION\""
echo ""

# 询问是否立即创建 Release（如果 Actions 未配置）
read -p "是否立即创建 GitHub Release? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 创建 GitHub Release..."
    
    # 查找 DMG 文件
    DMG_FILE=$(find src-tauri/target/universal-apple-darwin/release/bundle/dmg -name "*.dmg" | head -n 1)
    
    if [ -n "$DMG_FILE" ]; then
        gh release create "$VERSION" \
            QuickNote.app.tar.gz \
            "$DMG_FILE" \
            --title "$VERSION" \
            --notes "## 安装方法

### macOS (Apple Silicon & Intel)
1. 下载 \`QuickNote.app.tar.gz\` 或 \`.dmg\` 文件
2. 解压或打开 DMG，将应用拖入应用程序文件夹
3. 首次运行可能需要在"系统偏好设置 > 安全性与隐私"中允许

## 更新内容

- 初始版本发布"
    else
        gh release create "$VERSION" \
            QuickNote.app.tar.gz \
            --title "$VERSION" \
            --notes "## 安装方法

### macOS
1. 下载 \`QuickNote.app.tar.gz\` 文件
2. 解压后将应用拖入应用程序文件夹
3. 首次运行可能需要在"系统偏好设置 > 安全性与隐私"中允许

## 更新内容

- 初始版本发布"
    fi
    
    echo ""
    echo "✅ Release 创建成功!"
    echo "🔗 查看: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/releases/tag/$VERSION"
fi

echo ""
echo "🎉 发布完成!"
