# 测试指南

## 快速测试数据持久化

### 1. 开发模式测试

```bash
# 启动开发模式
cargo tauri dev
```

测试步骤：
1. 在笔记中输入一些文字，例如："测试数据持久化 123"
2. 等待 1 秒（确保自动保存完成）
3. 查看控制台，应该看到 "Note saved successfully"
4. 关闭应用（Cmd+Q 或右键退出）
5. 重新运行 `cargo tauri dev`
6. 打开面板，验证内容是否还在

### 2. 生产模式测试

```bash
# 构建应用
cargo tauri build

# 安装应用
open src-tauri/target/release/bundle/macos/QuickNote.app
```

测试步骤：
1. 启动应用，点击菜单栏图标
2. 输入测试内容
3. 关闭面板
4. 完全退出应用（右键菜单栏图标 → 退出）
5. 重新启动应用
6. 验证数据是否保留

### 3. 验证数据文件

```bash
# 查看数据文件
cat ~/Library/Application\ Support/com.quick-note.app/note.txt

# 实时监控文件变化
watch -n 1 'ls -la ~/Library/Application\ Support/com.quick-note.app/'
```

### 4. 压力测试

测试大量文本：
1. 复制一段长文本（1000+ 字符）
2. 粘贴到笔记中
3. 关闭并重启应用
4. 验证所有内容是否完整保存

测试频繁编辑：
1. 快速输入和删除文字
2. 观察控制台日志
3. 验证防抖机制是否正常工作（不会每次输入都保存）

## 预期结果

✅ 输入内容后 500ms 自动保存  
✅ 关闭面板时立即保存  
✅ 应用重启后数据完整保留  
✅ 控制台显示保存和加载日志  
✅ 数据文件存在于正确位置  

## 常见问题

### Q: 数据没有保存？
A: 检查控制台是否有错误，确认应用有文件系统权限

### Q: 如何清空所有数据？
A: 删除数据文件：
```bash
rm ~/Library/Application\ Support/com.quick-note.app/note.txt
```

### Q: 如何备份数据？
A: 复制数据文件：
```bash
cp ~/Library/Application\ Support/com.quick-note.app/note.txt ~/Desktop/note-backup.txt
```
