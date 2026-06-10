"""
Utils Module
Utility functions for the adapter generation tools.
"""

import os
import yaml
from pathlib import Path


def load_yaml_file(file_path):
    """
    Load YAML configuration file.
    
    Args:
        file_path (str): Path to YAML file.
    
    Returns:
        dict: Parsed YAML content.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading YAML file {file_path}: {e}")
        return {}


def save_yaml_file(data, file_path):
    """
    Save data to YAML file.
    
    Args:
        data (dict): Data to save.
        file_path (str): Path to output file.
    
    Returns:
        bool: True if successful, False otherwise.
    """
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
        return True
    except Exception as e:
        print(f"Error saving YAML file {file_path}: {e}")
        return False


def ensure_directory(dir_path):
    """
    Ensure a directory exists, create if necessary.
    
    Args:
        dir_path (str): Directory path.
    
    Returns:
        bool: True if directory exists or was created successfully.
    """
    try:
        Path(dir_path).mkdir(parents=True, exist_ok=True)
        return True
    except Exception as e:
        print(f"Error creating directory {dir_path}: {e}")
        return False


def read_file(file_path, encoding='utf-8'):
    """
    Read file content.
    
    Args:
        file_path (str): Path to file.
        encoding (str): File encoding.
    
    Returns:
        str: File content or None if error.
    """
    try:
        with open(file_path, 'r', encoding=encoding) as f:
            return f.read()
    except Exception as e:
        print(f"Error reading file {file_path}: {e}")
        return None


def write_file(file_path, content, encoding='utf-8'):
    """
    Write content to file.
    
    Args:
        file_path (str): Path to file.
        content (str): Content to write.
        encoding (str): File encoding.
    
    Returns:
        bool: True if successful, False otherwise.
    """
    try:
        with open(file_path, 'w', encoding=encoding) as f:
            f.write(content)
        return True
    except Exception as e:
        print(f"Error writing file {file_path}: {e}")
        return False


def list_files(dir_path, extension=None):
    """
    List files in a directory.
    
    Args:
        dir_path (str): Directory path.
        extension (str): Filter by file extension (e.g., '.md').
    
    Returns:
        list: List of file paths.
    """
    try:
        files = []
        for item in Path(dir_path).iterdir():
            if item.is_file():
                if extension is None or item.suffix == extension:
                    files.append(str(item))
        return files
    except Exception as e:
        print(f"Error listing files in {dir_path}: {e}")
        return []
