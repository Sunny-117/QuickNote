# 数据持久化说明

## 概述

QuickNote 使用文件系统持久化存储笔记数据，确保数据在应用重启后不会丢失。

## 存储位置

笔记数据保存在用户的应用数据目录：

```
~/Library/Application\ Support/com.quicknote.desktop/note.txt
```

## 保存机制

### 自动保存

- **输入时保存**：输入内容后 500ms 自动保存（防抖）
- **关闭面板时保存**：点击关闭按钮或失去焦点时立即保存
- **应用退出前保存**：确保数据不丢失

### 加载机制

- 应用启动时自动从文件加载上次保存的内容
- 如果文件不存在，显示空白笔记

## 测试数据持久化

### 方法 1：重启应用测试

1. 打开 QuickNote，输入一些文字
2. 关闭面板（点击外部或关闭按钮）
3. 完全退出应用（右键菜单栏图标 → 退出）
4. 重新启动应用
5. 打开面板，验证之前的内容是否还在

### 方法 2：查看数据文件

```bash
# 查看数据文件内容
cat ~/Library/Application\ Support/com.quick-note.app/note.txt

# 查看文件修改时间
ls -la ~/Library/Application\ Support/com.quick-note.app/
```

### 方法 3：开发模式测试

```bash
# 运行开发模式
cargo tauri dev

# 在应用中输入内容
# 查看控制台日志，应该看到：
# - "Note saved successfully"
# - "Note loaded successfully"
```

## 技术实现

### 后端 (Rust)

```rust
// 保存笔记到文件
#[tauri::command]
fn save_note(app: tauri::AppHandle, content: String) -> Result<(), String>

// 从文件加载笔记
#[tauri::command]
fn load_note(app: tauri::AppHandle) -> Result<String, String>
```

### 前端 (JavaScript)

```javascript
// 保存（带防抖）
await invoke('save_note', { content: textarea.value });

// 加载
const savedNote = await invoke('load_note');
```

## 数据安全

- ✅ 数据保存在用户本地，不上传到任何服务器
- ✅ 使用标准的应用数据目录，符合 macOS 规范
- ✅ 自动创建目录，无需手动配置
- ✅ 防抖机制避免频繁写入，提升性能

## 故障排查

### 数据没有保存？

1. 检查控制台是否有错误日志
2. 确认应用有文件系统写入权限
3. 检查数据目录是否存在：
   ```bash
   ls -la ~/Library/Application\ Support/com.quick-note.app/
   ```

### 数据文件损坏？

如果数据文件损坏，可以手动删除：

```bash
rm ~/Library/Application\ Support/com.quick-note.app/note.txt
```

重启应用后会创建新的空白文件。

## 未来改进

- [ ] 支持多个笔记本
- [ ] 自动备份功能
- [ ] 导出/导入功能
- [ ] 加密存储选项
