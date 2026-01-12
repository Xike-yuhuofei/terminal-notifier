"""标题工具函数"""
import os
from pathlib import Path
from typing import Optional
from .window_manager import get_window_id, get_persistent_title_path, load_persistent_title, save_persistent_title


def get_ccs_title() -> str:
    """
    获取CCS设置的标题
    优先从环境变量CLAUDE_WINDOW_NAME获取，
    否则从.states/original-title.txt文件中读取
    """
    # 优先使用环境变量
    env_title = os.environ.get('CLAUDE_WINDOW_NAME')
    if env_title:
        return env_title

    try:
        project_root = Path(__file__).parent.parent.parent.parent.parent
        states_dir = project_root / ".states"
        original_title_file = states_dir / "original-title.txt"

        if original_title_file.exists():
            with open(original_title_file, 'r', encoding='utf-8-sig') as f:
                title = f.read().strip()
                if title:
                    if title.startswith('\ufeff'):
                        title = title[1:]
                    return title

        return "Terminal"
    except Exception:
        return "Terminal"


def get_window_info(window_id: Optional[str] = None) -> tuple[str, str]:
    """
    获取窗口信息（支持多窗口）
    返回 (窗口名称, 项目名称)
    """
    # 首先尝试从窗口特定的持久化标题获取
    if window_id is None:
        window_id = get_window_id()
    
    persistent_title = load_persistent_title(window_id)
    if persistent_title:
        window_name = persistent_title
    else:
        # 回退到CCS设置的标题
        window_name = get_ccs_title()
    
    project_name = "Backend_CPP"
    return window_name, project_name


def set_window_title(title: str, window_id: Optional[str] = None) -> None:
    """
    设置窗口标题并持久化
    """
    if window_id is None:
        window_id = get_window_id()
    
    # 保存到窗口特定的持久化标题文件
    save_persistent_title(title, window_id)
    
    # 设置终端标题
    from .terminal import set_terminal_title
    set_terminal_title(title)