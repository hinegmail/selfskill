"""
Unit tests for utils.py module.
"""
import pytest
import tempfile
import yaml
from pathlib import Path
import utils


def test_load_save_yaml():
    """Test loading and saving YAML files."""
    data = {"name": "test", "version": 1}
    with tempfile.TemporaryDirectory() as tmpdir:
        file_path = Path(tmpdir) / "test.yaml"
        
        # Test save
        assert utils.save_yaml_file(data, str(file_path)) is True
        assert file_path.exists()
        
        # Test load
        loaded = utils.load_yaml_file(str(file_path))
        assert loaded == data
        
        # Test load missing file
        assert utils.load_yaml_file("/nonexistent/file.yaml") == {}
        
        # Test save to invalid path
        assert utils.save_yaml_file(data, "/nonexistent_dir/file.yaml") is False


def test_ensure_directory():
    """Test directory ensuring function."""
    with tempfile.TemporaryDirectory() as tmpdir:
        nested_dir = Path(tmpdir) / "nested" / "dir"
        assert nested_dir.exists() is False
        
        assert utils.ensure_directory(str(nested_dir)) is True
        assert nested_dir.exists() is True
        
        # Test ensuring invalid path
        assert utils.ensure_directory("") is False


def test_read_write_file():
    """Test reading and writing plain files."""
    content = "Hello World\nLine 2"
    with tempfile.TemporaryDirectory() as tmpdir:
        file_path = Path(tmpdir) / "test.txt"
        
        # Test write
        assert utils.write_file(str(file_path), content) is True
        assert file_path.exists()
        
        # Test read
        read_content = utils.read_file(str(file_path))
        assert read_content == content
        
        # Test read missing file
        assert utils.read_file("/nonexistent/file.txt") is None
        
        # Test write to invalid path
        assert utils.write_file("/nonexistent_dir/file.txt", content) is False


def test_list_files():
    """Test listing files in directory."""
    with tempfile.TemporaryDirectory() as tmpdir:
        tmpdir_path = Path(tmpdir)
        
        # Create some files
        (tmpdir_path / "a.md").write_text("a", encoding='utf-8')
        (tmpdir_path / "b.txt").write_text("b", encoding='utf-8')
        (tmpdir_path / "c.md").write_text("c", encoding='utf-8')
        
        # List all
        all_files = utils.list_files(tmpdir)
        assert len(all_files) == 3
        
        # List by extension
        md_files = utils.list_files(tmpdir, extension=".md")
        assert len(md_files) == 2
        assert any("a.md" in f for f in md_files)
        assert any("c.md" in f for f in md_files)
        
        # List non-existent directory
        assert utils.list_files("/nonexistent_dir") == []
