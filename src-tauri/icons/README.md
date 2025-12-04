# 图标说明

请将应用图标放置在此目录中。

需要的图标文件：
- 32x32.png
- 128x128.png
- 128x128@2x.png
- icon.icns (macOS)
- icon.ico (Windows)

你可以使用在线工具生成这些图标，例如：
- https://www.appicon.co/
- https://icon.kitchen/

或者使用 Tauri 的图标生成命令：
```bash
cargo tauri icon path/to/your/icon.png
```

这会自动生成所有需要的图标尺寸。
