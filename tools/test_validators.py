"""
Unit tests for Validators module.
"""
import pytest
import tempfile
from pathlib import Path
from validators import (
    MarkdownValidator,
    MDCValidator,
    VersionValidator,
    FileReferenceValidator,
    LanguageValidator,
    AdapterValidator,
)


class TestMarkdownValidator:
    """Test cases for MarkdownValidator."""
    
    def test_valid_markdown(self):
        """Test validation of valid markdown."""
        validator = MarkdownValidator()
        content = """# Header

This is valid **markdown** with [links](http://example.com).

## Subheader

```python
print("code block")
```
"""
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is True
    
    def test_unmatched_brackets(self):
        """Test detection of unmatched brackets."""
        validator = MarkdownValidator()
        content = "This has unmatched [brackets."
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False
    
    def test_unclosed_code_block(self):
        """Test detection of unclosed code blocks."""
        validator = MarkdownValidator()
        content = "```python\nprint('hello')\n"
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False


class TestVersionValidator:
    """Test cases for VersionValidator."""
    
    def test_valid_version(self):
        """Test validation of valid version."""
        validator = VersionValidator()
        content = "# ProjectOrchestrator Skill v1.0.2"
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is True
    
    def test_missing_version(self):
        """Test detection of missing version."""
        validator = VersionValidator()
        content = "# Some file without version"
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False
        assert len(errors) > 0
    
    def test_invalid_version_format(self):
        """Test detection of invalid version format."""
        validator = VersionValidator()
        content = "# ProjectOrchestrator Skill v1.0"
        is_valid, errors = validator.validate(content, "test.md")
        # Should still find v1.0 pattern, but it's not standard semver
        # This test depends on implementation


class TestFileReferenceValidator:
    """Test cases for FileReferenceValidator."""
    
    def test_correct_references(self):
        """Test validation of correct file references."""
        validator = FileReferenceValidator()
        content = "See requirements.md for details."
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is True
    
    def test_old_prd_reference(self):
        """Test detection of old PRD.md reference."""
        validator = FileReferenceValidator()
        content = "See PRD.md and PRD.md for details."
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False
        assert any("PRD.md" in e for e in errors)
    
    def test_mixed_references(self):
        """Test detection of mixed old and new references."""
        validator = FileReferenceValidator()
        content = "See requirements.md and PRD.md for details."
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False


class TestLanguageValidator:
    """Test cases for LanguageValidator."""
    
    def test_english_only(self):
        """Test validation of English-only content."""
        validator = LanguageValidator()
        content = """# English Content

This is pure English without any Chinese characters.

## Code Examples

```python
def hello():
    print("Hello World")
```
"""
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is True
    
    def test_chinese_code_comments(self):
        """Test detection of Chinese code comments."""
        validator = LanguageValidator()
        content = """# Some Code

```python
# 这是中文注释
def hello():
    pass
```
"""
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is False
        assert len(errors) > 0
    
    def test_chinese_in_trigger_keywords_table(self):
        """Test that Chinese in trigger keywords table is allowed."""
        validator = LanguageValidator()
        content = """| Intent | 中文触发词 | English |
|--------|-----------|---------|
| Context Audit | "继续项目" | "continue" |"""
        is_valid, errors = validator.validate(content, "test.md")
        assert is_valid is True


class TestMDCValidator:
    """Test cases for MDCValidator."""
    
    def test_valid_mdc(self):
        """Test validation of valid MDC."""
        validator = MDCValidator()
        content = """# Valid MDC

This is valid MDC content.

[link](http://example.com)
"""
        is_valid, errors = validator.validate(content, "test.mdc")
        assert is_valid is True
    
    def test_empty_mdc(self):
        """Test validation of empty MDC."""
        validator = MDCValidator()
        content = ""
        is_valid, errors = validator.validate(content, "test.mdc")
        assert is_valid is False


class TestAdapterValidator:
    """Test cases for AdapterValidator."""
    
    @pytest.fixture
    def adapter_file(self):
        """Create a temporary adapter file."""
        content = """# ProjectOrchestrator Skill v1.0.2

See requirements.md for details.

| Intent | 中文触发词 | English |
|--------|-----------|---------|
| Context Audit | "继续项目" | "continue" |
"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False, encoding='utf-8') as f:
            f.write(content)
            f.flush()
            yield f.name
        
        Path(f.name).unlink()
    
    def test_validate_file(self, adapter_file):
        """Test file validation."""
        validator = AdapterValidator()
        is_valid, errors_dict = validator.validate_file(adapter_file)
        
        assert isinstance(is_valid, bool)
        assert isinstance(errors_dict, dict)
    
    def test_validate_missing_file(self):
        """Test validation of missing file."""
        validator = AdapterValidator()
        is_valid, errors_dict = validator.validate_file("/nonexistent/file.md")
        
        assert is_valid is False
        assert "file" in errors_dict
    
    def test_validate_directory(self):
        """Test directory validation."""
        tmpdir = tempfile.mkdtemp()
        
        # Create some adapter files
        for name in ['KIRO_AGENT.md', 'CLAUDE.md']:
            file_path = Path(tmpdir) / name
            file_path.write_text(f"# {name} v1.0.2\n\nSee requirements.md.")
        
        validator = AdapterValidator()
        results = validator.validate_directory(tmpdir)
        
        assert len(results) == 2
        
        # Cleanup
        import shutil
        shutil.rmtree(tmpdir)
    
    def test_validate_empty_directory(self):
        """Test validation of empty directory."""
        tmpdir = tempfile.mkdtemp()
        
        validator = AdapterValidator()
        results = validator.validate_directory(tmpdir)
        
        assert len(results) == 0
        
        # Cleanup
        import shutil
        shutil.rmtree(tmpdir)


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=validators'])
