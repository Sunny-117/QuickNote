// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{Manager, LogicalPosition, Emitter};
use tauri::tray::{TrayIconBuilder, TrayIconEvent, MouseButton};
use tauri::menu::{Menu, MenuItem};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};
use std::fs;
use std::path::PathBuf;

// 获取数据文件路径
fn get_data_file_path(app: &tauri::AppHandle) -> Result<PathBuf, String> {
    let app_data_dir = app.path().app_data_dir()
        .map_err(|e| format!("Failed to get app data dir: {}", e))?;
    
    // 确保目录存在
    fs::create_dir_all(&app_data_dir)
        .map_err(|e| format!("Failed to create app data dir: {}", e))?;
    
    Ok(app_data_dir.join("note.txt"))
}

// 保存笔记
#[tauri::command]
fn save_note(app: tauri::AppHandle, content: String) -> Result<(), String> {
    let file_path = get_data_file_path(&app)?;
    fs::write(&file_path, content)
        .map_err(|e| format!("Failed to save note: {}", e))?;
    println!("Note saved to: {:?}", file_path);
    Ok(())
}

// 加载笔记
#[tauri::command]
fn load_note(app: tauri::AppHandle) -> Result<String, String> {
    println!("load_note command called!");
    let file_path = get_data_file_path(&app)?;
    println!("Data file path: {:?}", file_path);
    
    if !file_path.exists() {
        println!("Note file doesn't exist yet: {:?}", file_path);
        return Ok(String::new());
    }
    
    let content = fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to load note: {}", e))?;
    println!("Note loaded from: {:?}, content length: {}", file_path, content.len());
    println!("Content: {:?}", content);
    Ok(content)
}

#[tauri::command]
fn toggle_panel(app: tauri::AppHandle) -> Result<(), String> {
    println!("toggle_panel called!");
    
    let panel_window = app.get_webview_window("panel-window").ok_or("Panel window not found")?;
    
    println!("Panel window found");
    
    match panel_window.is_visible() {
        Ok(true) => {
            println!("Panel is visible, hiding it");
            panel_window.hide().map_err(|e| e.to_string())?;
        }
        Ok(false) => {
            println!("Panel is hidden, showing it");
            
            // 获取托盘图标的位置（macOS 菜单栏右侧）
            // 将面板定位在屏幕右上角
            if let Ok(monitor) = panel_window.current_monitor() {
                if let Some(monitor) = monitor {
                    let size = monitor.size();
                    // 定位到右上角，菜单栏下方
                    let panel_x = (size.width as i32 / 2) - 340;  // 逻辑像素，靠右
                    let panel_y = 30;  // 菜单栏下方
                    
                    println!("Setting panel position to: x={}, y={}", panel_x, panel_y);
                    let _ = panel_window.set_position(LogicalPosition::new(panel_x, panel_y));
                }
            }
            
            panel_window.show().map_err(|e| e.to_string())?;
            
            // 发送窗口显示事件，触发前端重新加载数据
            let _ = panel_window.emit("panel-shown", ());
            
            // 不要立即设置焦点，让窗口保持打开
            // panel_window.set_focus().map_err(|e| e.to_string())?;
            println!("Panel shown");
        }
        Err(e) => return Err(e.to_string()),
    }
    
    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
fn main() {
    // 防抖：记录上次点击时间
    let last_click = Arc::new(Mutex::new(Instant::now()));
    
    tauri::Builder::default()
        .setup(move |app| {
            // 设置为 Accessory 模式，不显示在 Dock 中
            #[cfg(target_os = "macos")]
            {
                app.set_activation_policy(tauri::ActivationPolicy::Accessory);
            }
            
            // 创建托盘菜单
            let quit_item = MenuItem::with_id(app, "quit", "退出", true, None::<&str>)?;
            let show_item = MenuItem::with_id(app, "show", "显示/隐藏", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&show_item, &quit_item])?;
            
            let last_click_clone = last_click.clone();
            
            // 创建一个简单的托盘图标（32x32 RGBA）
            // 创建一个紫色圆形图标
            let mut rgba = vec![0u8; 32 * 32 * 4];
            for y in 0..32 {
                for x in 0..32 {
                    let dx = x as f32 - 16.0;
                    let dy = y as f32 - 16.0;
                    let distance = (dx * dx + dy * dy).sqrt();
                    
                    let idx = ((y * 32 + x) * 4) as usize;
                    if distance < 14.0 {
                        // 紫色渐变
                        rgba[idx] = 102;     // R
                        rgba[idx + 1] = 126; // G
                        rgba[idx + 2] = 234; // B
                        rgba[idx + 3] = 255; // A
                    } else {
                        // 透明
                        rgba[idx + 3] = 0;
                    }
                }
            }
            
            let icon = tauri::image::Image::new_owned(rgba, 32, 32);
            
            let _tray = TrayIconBuilder::new()
                .icon(icon)
                .menu(&menu)
                .show_menu_on_left_click(false)  // 左键不显示菜单，只切换面板
                .on_menu_event(|app, event| {
                    match event.id.as_ref() {
                        "quit" => {
                            println!("Quit menu item clicked");
                            app.exit(0);
                        }
                        "show" => {
                            println!("Show menu item clicked");
                            let _ = toggle_panel(app.clone());
                        }
                        _ => {}
                    }
                })
                .on_tray_icon_event(move |tray, event| {
                    match event {
                        TrayIconEvent::Click { button, .. } => {
                            // 防抖：如果距离上次点击少于 300ms，忽略
                            let mut last = last_click_clone.lock().unwrap();
                            let now = Instant::now();
                            if now.duration_since(*last) < Duration::from_millis(300) {
                                println!("Click ignored (debounce)");
                                return;
                            }
                            *last = now;
                            
                            println!("Tray icon clicked with button: {:?}", button);
                            if button == MouseButton::Left {
                                let app = tray.app_handle();
                                let _ = toggle_panel(app.clone());
                            }
                        }
                        _ => {}
                    }
                })
                .build(app)?;
            
            println!("System tray icon created!");
            
            Ok(())
        })
        .plugin(tauri_plugin_shell::init())
        .plugin(tauri_plugin_fs::init())
        .invoke_handler(tauri::generate_handler![toggle_panel, save_note, load_note])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
