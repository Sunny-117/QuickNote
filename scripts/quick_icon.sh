#!/bin/bash

# 快速创建 QuickNote 图标（不需要 ImageMagick）

set -e

echo "🎨 快速创建 QuickNote 图标"
echo ""

# 检查是否安装了 sips（macOS 自带）
if ! command -v sips &> /dev/null; then
    echo "❌ 错误: sips 命令不可用"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
ICON_DIR="src-tauri/icons"

mkdir -p "$ICON_DIR"

echo "📝 创建基础图标..."

# 使用 Python 创建一个简单的 PNG 图标
python3 << 'PYTHON_SCRIPT'
from PIL import Image, ImageDraw, ImageFont
import os

# 创建 1024x1024 的图像
size = 1024
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 绘制紫色渐变圆形
for i in range(size):
    for j in range(size):
        dx = i - size/2
        dy = j - size/2
        distance = (dx*dx + dy*dy) ** 0.5
        
        if distance < size/2 - 50:
            # 渐变色
            ratio = distance / (size/2)
            r = int(102 + (118-102) * ratio)
            g = int(126 + (75-126) * ratio)
            b = int(234 + (162-234) * ratio)
            img.putpixel((i, j), (r, g, b, 255))

# 绘制白色字母 N
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 700)
except:
    font = ImageFont.load_default()

text = "N"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
x = (size - text_width) / 2 - bbox[0]
y = (size - text_height) / 2 - bbox[1]

draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

# 保存
img.save('icon-1024.png')
print("✅ 图标创建成功: icon-1024.png")
PYTHON_SCRIPT

if [ ! -f "icon-1024.png" ]; then
    echo "❌ Python 脚本失败，尝试备用方案..."
    
    # 备用方案：创建纯色图标
    cat > "$TEMP_DIR/create_icon.py" << 'EOF'
from PIL import Image, ImageDraw
img = Image.new('RGBA', (1024, 1024), (102, 126, 234, 255))
draw = ImageDraw.Draw(img)
draw.ellipse([100, 100, 924, 924], fill=(118, 75, 162, 255))
img.save('icon-1024.png')
EOF
    python3 "$TEMP_DIR/create_icon.py"
fi

# 使用 sips 生成不同尺寸
echo "🔧 生成不同尺寸..."

sips -z 32 32 icon-1024.png --out "$ICON_DIR/32x32.png" > /dev/null
sips -z 128 128 icon-1024.png --out "$ICON_DIR/128x128.png" > /dev/null
sips -z 256 256 icon-1024.png --out "$ICON_DIR/128x128@2x.png" > /dev/null
sips -z 256 256 icon-1024.png --out "$ICON_DIR/icon.png" > /dev/null

# 创建 .icns 文件（macOS 图标）
echo "🍎 创建 macOS 图标..."
ICONSET_DIR="$TEMP_DIR/icon.iconset"
mkdir -p "$ICONSET_DIR"

sips -z 16 16 icon-1024.png --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -z 32 32 icon-1024.png --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -z 32 32 icon-1024.png --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -z 64 64 icon-1024.png --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -z 128 128 icon-1024.png --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -z 256 256 icon-1024.png --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -z 256 256 icon-1024.png --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -z 512 512 icon-1024.png --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -z 512 512 icon-1024.png --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -z 1024 1024 icon-1024.png --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

iconutil -c icns "$ICONSET_DIR" -o "$ICON_DIR/icon.icns"

# 清理
rm -rf "$TEMP_DIR" icon-1024.png

echo ""
echo "✅ 图标生成完成！"
echo "📁 图标位置: $ICON_DIR/"
echo ""
echo "生成的文件:"
ls -lh "$ICON_DIR/"
echo ""
echo "💡 提示: 运行 'cargo tauri build' 重新构建应用以应用新图标"
