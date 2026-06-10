"""
Unit tests for SkillParser module.
"""
import pytest
import tempfile
from pathlib import Path
from skill_parser import SkillParser


class TestSkillParser:
    """Test cases for SkillParser class."""
    
    @pytest.fixture
    def skill_file(self):
        """Create a temporary skill.md file for testing."""
        content = """# ProjectOrchestrator Skill v1.0.2

## 0. Role Definition

You are **ProjectOrchestrator**.

---

## 1. Core Principles

1. **File-based memory, not chat-based memory.**
2. **`.ai/` is the Single Source of Truth.**
3. **`NEXT.md` is the only execution gate.**

---

## 4. Seven-Mode Execution Engine

### Mode 0: Initialization

**Trigger**: `.ai/STATUS.md` or `.ai/NEXT.md` is missing.

### Mode 1: Context Audit

**Trigger**: Every conversation start.

### Mode 2: Task Planning

**Trigger**: Context Audit completed.

### Mode 3: Task Implementation

**Trigger**: User confirms the Task Plan.

### Mode 4: Validation & Test Repair

**Trigger**: Implementation completed.

### Mode 5: Phase Closeout

**Trigger**: Validation passes.

### Mode 6: Skill Evolution Proposal

**Trigger**: Repeated process issues observed.

---

## 7. Trigger Keywords (中英双语)

| Intent | 中文触发词 | English Triggers |
|--------|-----------|-----------------|
| Context Audit | "继续项目"、"继续开发" | "continue project", "continue" |
| Task Planning | "开始阶段 X" | "plan", "start task" |
| Implementation | "确认"、"批准" | "approved", "implement" |

---

## 8. Forbidden Behaviors

You must not:

1. Continue development based only on chat memory.
2. Start implementation before reading `.ai/` documents.
3. Skip Context Audit mode.
"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False, encoding='utf-8') as f:
            f.write(content)
            f.flush()
            yield f.name
        
        # Cleanup
        Path(f.name).unlink()
    
    def test_init_with_valid_file(self, skill_file):
        """Test initialization with a valid skill file."""
        parser = SkillParser(skill_file)
        assert parser.file_path == skill_file
        assert parser.content is not None
        assert len(parser.content) > 0
    
    def test_init_with_missing_file(self):
        """Test initialization with a missing file."""
        with pytest.raises(FileNotFoundError):
            SkillParser("/nonexistent/path/skill.md")
    
    def test_extract_version(self, skill_file):
        """Test version extraction."""
        parser = SkillParser(skill_file)
        version = parser.extract_version()
        assert version == "1.0.2"
    
    def test_extract_version_not_found(self):
        """Test version extraction when version is missing."""
        content = "# Some file\n\nNo version here"
        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False, encoding='utf-8') as f:
            f.write(content)
            f.flush()
            temp_file = f.name
        
        try:
            parser = SkillParser(temp_file)
            with pytest.raises(ValueError):
                parser.extract_version()
        finally:
            Path(temp_file).unlink(missing_ok=True)
    
    def test_extract_section(self, skill_file):
        """Test section extraction."""
        parser = SkillParser(skill_file)
        section = parser.extract_section("Core Principles")
        
        assert "Core Principles" in section
        assert "File-based memory" in section
        assert "Single Source of Truth" in section
    
    def test_extract_section_not_found(self, skill_file):
        """Test section extraction when section doesn't exist."""
        parser = SkillParser(skill_file)
        section = parser.extract_section("Nonexistent Section")
        
        assert section == ""
    
    def test_extract_modes(self, skill_file):
        """Test modes extraction."""
        parser = SkillParser(skill_file)
        modes = parser.extract_modes()
        
        assert isinstance(modes, dict)
        assert len(modes) > 0
        # Should have modes 0-6
        mode_keys = list(modes.keys())
        assert any("Initialization" in key for key in mode_keys)
        assert any("Context Audit" in key for key in mode_keys)
    
    def test_extract_keywords(self, skill_file):
        """Test keywords extraction."""
        parser = SkillParser(skill_file)
        keywords = parser.extract_keywords()
        
        assert isinstance(keywords, dict)
        assert "Context Audit" in keywords
        assert "继续项目" in keywords["Context Audit"] or any("继续项目" in kw for kw in keywords["Context Audit"])
    
    def test_extract_forbidden_behaviors(self, skill_file):
        """Test forbidden behaviors extraction."""
        parser = SkillParser(skill_file)
        behaviors = parser.extract_forbidden_behaviors()
        
        assert isinstance(behaviors, list)
        assert len(behaviors) > 0
        assert any("chat memory" in b for b in behaviors)
    
    def test_validate_syntax_valid(self, skill_file):
        """Test syntax validation with a valid file."""
        parser = SkillParser(skill_file)
        assert parser.validate_syntax() is True
    
    def test_validate_syntax_invalid(self):
        """Test syntax validation with an invalid file."""
        content = "# Some Random File\n\nNo required sections"
        with tempfile.NamedTemporaryFile(mode='w', suffix='.md', delete=False, encoding='utf-8') as f:
            f.write(content)
            f.flush()
            temp_file = f.name
        
        try:
            parser = SkillParser(temp_file)
            assert parser.validate_syntax() is False
        finally:
            Path(temp_file).unlink(missing_ok=True)
    
    def test_parse(self, skill_file):
        """Test complete parsing."""
        parser = SkillParser(skill_file)
        result = parser.parse()
        
        assert isinstance(result, dict)
        assert "version" in result
        assert "modes" in result
        assert "keywords" in result
        assert "forbidden_behaviors" in result
        
        assert result["version"] == "1.0.2"
        assert len(result["modes"]) > 0
        assert len(result["keywords"]) > 0
        assert len(result["forbidden_behaviors"]) > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=skill_parser'])
