#!/bin/bash

# QuickNote 图标生成脚本
# 使用 ImageMagick 创建一个简单的图标

set -e

echo "🎨 QuickNote 图标生成器"
echo ""

# 检查是否安装了 ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ 错误: 未安装 ImageMagick"
    echo "请运行: brew install imagemagick"
    exit 1
fi

# 检查是否安装了 Tauri CLI
if ! command -v cargo-tauri &> /dev/null; then
    echo "⚠️  警告: 未安装 Tauri CLI"
    echo "正在安装..."
    cargo install tauri-cli
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo "📁 临时目录: $TEMP_DIR"

# 选择图标类型
echo ""
echo "请选择图标类型:"
echo "1) 📝 Emoji 笔记本"
echo "2) ✏️ Emoji 铅笔"
echo "3) 📄 Emoji 文档"
echo "4) 🎨 紫色渐变圆形"
echo "5) 🔤 字母 N"
echo ""
read -p "请输入选项 (1-5): " choice

case $choice in
    1|2|3)
        # Emoji 图标需要特殊处理，使用 sips 和截图
        echo "⚠️  Emoji 图标需要手动创建"
        echo ""
        echo "请按照以下步骤操作："
        echo "1. 打开预览 (Preview.app)"
        echo "2. 文件 > 新建 > 从剪贴板"
        echo "3. 复制这个 emoji: 📝"
        echo "4. 调整大小到 1024x1024"
        echo "5. 保存为 icon-1024.png"
        echo ""
        echo "或者选择选项 4 或 5 使用纯色图标"
        exit 0
        ;;
    4)
        echo "创建紫色圆形图标..."
        magick -size 1024x1024 xc:none \
            -fill "rgb(102,126,234)" \
            -draw "circle 512,512 512,100" \
            -fill white \
            -pointsize 600 \
            -font "Helvetica-Bold" \
            -gravity center \
            -annotate +0+0 "N" \
            "$TEMP_DIR/icon-1024.png"
        ;;
    5)
        echo "创建字母 N 渐变图标..."
        # 创建渐变背景
        magick -size 1024x1024 \
            gradient:"rgb(102,126,234)-rgb(118,75,162)" \
            -distort SRT 45 \
            "$TEMP_DIR/gradient.png"
        
        # 添加文字
        magick "$TEMP_DIR/gradient.png" \
            -fill white \
            -pointsize 700 \
            -font "Helvetica-Bold" \
            -gravity center \
            -annotate +0+0 "N" \
            "$TEMP_DIR/icon-1024.png"
        ;;
    *)
        echo "❌ 无效选项"
        exit 1
        ;;
esac

# 添加圆角（macOS 风格）
echo "✨ 添加圆角..."
magick "$TEMP_DIR/icon-1024.png" \
    \( +clone -alpha extract \
    -draw 'fill black polygon 0,0 0,150 150,0 fill white circle 150,150 150,0' \
    \( +clone -flip \) -compose Multiply -composite \
    \( +clone -flop \) -compose Multiply -composite \
    \) -alpha off -compose CopyOpacity -composite \
    "$TEMP_DIR/icon-1024-rounded.png"

# 使用 Tauri 生成所有尺寸
echo "🔧 生成所有图标尺寸..."
cargo tauri icon "$TEMP_DIR/icon-1024-rounded.png"

# 清理
rm -rf "$TEMP_DIR"

echo ""
echo "✅ 图标生成完成！"
echo "📁 图标位置: src-tauri/icons/"
echo ""
echo "生成的文件:"
ls -lh src-tauri/icons/
echo ""
echo "💡 提示: 运行 'cargo tauri build' 重新构建应用以应用新图标"
