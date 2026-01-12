"""Toast通知工具模块"""
import subprocess
import json
import os
from typing import Optional, Dict, Any


def send_toast_notification(title: str, message: str = "") -> bool:
    """
    发送Windows Toast通知

    Args:
        title: 通知标题
        message: 通知内容

    Returns:
        bool: 通知发送是否成功
    """
    try:
        title_escaped = title.replace("'", "''")
        message_escaped = message.replace("'", "''")

        powershell_script = f'''
        $Title = '{title_escaped}'
        $Message = '{message_escaped}'

        try {{
            if (Get-Module -ListAvailable -Name BurntToast) {{
                Import-Module BurntToast -ErrorAction SilentlyContinue
                New-BurntToastNotification -Text $Title, $Message
                $true
            }} else {{
                $false
            }}
        }} catch {{
            $false
        }}
        '''

        result = subprocess.run(
            ['powershell.exe', '-ExecutionPolicy', 'Bypass', '-Command', powershell_script],
            capture_output=True,
            text=True,
            timeout=10
        )

        return result.returncode == 0 and "True" in result.stdout.strip()

    except Exception:
        return False


def send_stop_toast(window_name: str, project_name: str) -> bool:
    """
    发送停止通知

    Args:
        window_name: CCS启动时设置的自定义标题
        project_name: 项目名称（未使用）

    Returns:
        bool: 通知发送是否成功
    """
    title = f"[⚠️] {window_name}"
    message = "Stop Hook"
    return send_toast_notification(title, message)


def send_notification_toast(window_name: str, project_name: str) -> bool:
    """
    发送普通通知

    Args:
        window_name: CCS启动时设置的自定义标题
        project_name: 项目名称（未使用）

    Returns:
        bool: 通知发送是否成功
    """
    title = f"[📢] {window_name}"
    message = "Notification Hook"
    return send_toast_notification(title, message)


def invoke_toast_with_fallback(toast_function: str, window_name: str, project_name: str) -> bool:
    """
    调用Toast通知并处理错误（兼容原始Invoke-ToastWithFallback函数）
    
    Args:
        toast_function: Toast函数名称（Send-StopToast或Send-NotificationToast）
        window_name: 窗口名称
        project_name: 项目名称
        
    Returns:
        bool: 通知发送是否成功
    """
    try:
        if toast_function == "Send-StopToast":
            return send_stop_toast(window_name, project_name)
        elif toast_function == "Send-NotificationToast":
            return send_notification_toast(window_name, project_name)
        else:
            return False
    except Exception:
        # Toast失败不应阻塞主程序
        return False
