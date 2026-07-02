"""
Unit tests for AdapterGenerator module.
"""
import pytest
import tempfile
from pathlib import Path
from adapter_generator import AdapterGenerator, GenerationResult


class TestAdapterGenerator:
    """Test cases for AdapterGenerator class."""
    
    @pytest.fixture
    def test_environment(self):
        """Create a test environment with skill file, templates, and output dir."""
        import tempfile
        
        # 使用 TemporaryDirectory 确保整个测试环境在此作用域结束后自动级联清除
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir_path = Path(tmpdir)
            
            # Create skill file
            skill_content = """# ProjectOrchestrator Skill v1.0.2

## 0. Role Definition

You are **ProjectOrchestrator**.

---

## 1. Core Principles

1. **File-based memory, not chat-based memory.**

---

## 4. Seven-Mode Execution Engine

### Mode 0: Initialization

**Trigger**: Initial setup.

### Mode 1: Context Audit

**Trigger**: Every conversation start.

### Mode 2: Task Planning

**Trigger**: Audit completed.

### Mode 3: Task Implementation

**Trigger**: Plan confirmed.

### Mode 4: Validation & Test Repair

**Trigger**: Implementation done.

### Mode 5: Phase Closeout

**Trigger**: Tests pass.

### Mode 6: Skill Evolution Proposal

**Trigger**: Issues observed.

---

## 7. Trigger Keywords

| Intent | 中文触发词 | English |
|--------|-----------|---------|
| Context Audit | "继续项目" | "continue" |

---

## 8. Forbidden Behaviors

You must not:

1. Continue based on chat memory.
2. Skip audit mode.
"""
            
            skill_file = tmpdir_path / "test_skill.md"
            skill_file.write_text(skill_content, encoding='utf-8')
            
            # Create template directory
            template_dir = tmpdir_path / "test_templates"
            template_dir.mkdir(exist_ok=True)
            
            # Create base templates
            (template_dir / "base.j2").write_text("Base content: {{ version }}")
            (template_dir / "modes.j2").write_text("Modes content")
            (template_dir / "rules.j2").write_text("Rules content")
            (template_dir / "footer.j2").write_text("Footer: {{ version }}")
            
            # Create platforms directory
            platforms_dir = template_dir / "platforms"
            platforms_dir.mkdir(exist_ok=True)
            
            # Create platform templates
            for platform in ['kiro', 'antigravity', 'claude', 'cursor', 'clinerules', 'windsurfer', 'gemini', 'agents']:
                platform_file = platforms_dir / f"{platform}.j2"
                platform_file.write_text(
                    "{%- include 'base.j2' -%}\n---\n"
                    "{%- include 'modes.j2' -%}\n---\n"
                    "{%- include 'rules.j2' -%}\n---\n"
                    "{%- include 'footer.j2' -%}"
                )
            
            # Create output directory
            output_dir = tmpdir_path / "test_output"
            output_dir.mkdir(exist_ok=True)
            
            env_dict = {
                'skill_file': str(skill_file),
                'template_dir': str(template_dir),
                'output_dir': str(output_dir),
            }
            
            yield env_dict
    
    def test_init_with_valid_paths(self, test_environment):
        """Test initialization with valid paths."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        assert generator.skill_file.exists()
        assert generator.template_dir.exists()
        assert generator.output_dir.exists()
    
    def test_init_with_invalid_skill_file(self, test_environment):
        """Test initialization with invalid skill file."""
        with pytest.raises(ValueError):
            AdapterGenerator(
                skill_file="/nonexistent/skill.md",
                template_dir=test_environment['template_dir'],
                output_dir=test_environment['output_dir'],
            )
    
    def test_init_with_invalid_template_dir(self, test_environment):
        """Test initialization with invalid template directory."""
        with pytest.raises(ValueError):
            AdapterGenerator(
                skill_file=test_environment['skill_file'],
                template_dir="/nonexistent/templates",
                output_dir=test_environment['output_dir'],
            )
    
    def test_generate_all_platforms(self, test_environment):
        """Test generating all platforms."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate()
        
        assert result.success is True
        assert result.version == "1.0.2"
        assert len(result.generated_files) > 0
        assert len(result.errors) == 0
    
    def test_generate_specific_platforms(self, test_environment):
        """Test generating specific platforms."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate(platforms=['kiro', 'claude'])
        
        assert result.success is True
        assert len(result.generated_files) == 2
        assert 'kiro' in result.generated_files
        assert 'claude' in result.generated_files
    
    def test_generate_invalid_platform(self, test_environment):
        """Test generating with invalid platform name."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate(platforms=['kiro', 'invalid_platform'])
        
        assert result.success is False
        assert len(result.errors) > 0
    
    def test_generate_dry_run(self, test_environment):
        """Test dry run generation."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate(platforms=['kiro'], dry_run=True)
        
        assert result.success is True
        # File should not actually be written
        output_file = Path(test_environment['output_dir']) / "KIRO_AGENT.md"
        assert not output_file.exists()
    
    def test_generate_writes_files(self, test_environment):
        """Test that generate actually writes files."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate(platforms=['kiro'], dry_run=False)
        
        assert result.success is True
        output_file = Path(test_environment['output_dir']) / "KIRO_AGENT.md"
        assert output_file.exists()
        
        content = output_file.read_text(encoding='utf-8')
        assert "1.0.2" in content
        assert len(content) > 50
    
    def test_validate_setup(self, test_environment):
        """Test validation of setup."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        is_valid, errors = generator.validate()
        
        assert is_valid is True
        assert len(errors) == 0
    
    def test_validate_missing_skill_file(self, test_environment):
        """Test validation with missing skill file."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        # Remove the skill file
        Path(test_environment['skill_file']).unlink()
        
        is_valid, errors = generator.validate()
        
        assert is_valid is False
        assert len(errors) > 0
    
    def test_result_dataclass(self):
        """Test GenerationResult dataclass."""
        result = GenerationResult(
            version="1.0.2",
            generated_files={"kiro": "/path/to/kiro.md"},
            generation_timestamp="2024-06-09T10:30:00Z",
            duration_seconds=2.5,
            success=True,
            errors=[],
            validation_warnings=[],
        )
        
        assert result.version == "1.0.2"
        assert len(result.generated_files) == 1
        assert result.success is True
        assert result.validation_warnings == []

    def test_load_config_invalid_yaml(self, test_environment):
        """Test loading configuration with invalid YAML content."""
        invalid_yaml = Path(test_environment['output_dir']) / "invalid.yaml"
        invalid_yaml.write_text("invalid:\n\t- config", encoding='utf-8')
        
        with pytest.raises(ValueError):
            AdapterGenerator(
                skill_file=test_environment['skill_file'],
                template_dir=test_environment['template_dir'],
                output_dir=test_environment['output_dir'],
                config_file=str(invalid_yaml)
            )

    def test_generate_parse_error(self, test_environment):
        """Test generation failure due to parsing errors of skill file."""
        bad_skill = Path(test_environment['output_dir']) / "bad_skill.md"
        bad_skill.write_text("# ProjectOrchestrator Skill NoVersion\n\nSome invalid content", encoding='utf-8')
        
        generator = AdapterGenerator(
            skill_file=str(bad_skill),
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate()
        assert result.success is False
        # parse() raises ValueError("Skill file failed syntax validation") for syntax-invalid files
        assert any(
            "Failed to parse skill.md" in err or "Skill file failed syntax validation" in err
            for err in result.errors
        )

    def test_generate_validate_syntax_error(self, test_environment):
        """Test generation validation failure with syntax invalid skill file."""
        bad_skill = Path(test_environment['output_dir']) / "bad_skill.md"
        bad_skill.write_text("# ProjectOrchestrator Skill v1.0.2\n\nNo required sections here.", encoding='utf-8')
        
        generator = AdapterGenerator(
            skill_file=str(bad_skill),
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        result = generator.generate(validate=True)
        assert result.success is False
        assert any("Skill file failed syntax validation" in err for err in result.errors)

    def test_validate_setup_missing_template(self, test_environment):
        """Test validate method when some adapter templates are missing."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        Path(test_environment['template_dir'], 'platforms', 'kiro.j2').unlink()
        
        is_valid, errors = generator.validate()
        assert is_valid is False
        assert any("Template not found" in err for err in errors)

    def test_generate_template_render_error(self, test_environment):
        """Test generation error when template rendering fails."""
        generator = AdapterGenerator(
            skill_file=test_environment['skill_file'],
            template_dir=test_environment['template_dir'],
            output_dir=test_environment['output_dir'],
        )
        
        Path(test_environment['template_dir'], 'platforms', 'kiro.j2').write_text("{{ skill_data.undefined_var.attr }}", encoding='utf-8')
        
        result = generator.generate()
        assert result.success is False
        assert any("Failed to generate kiro" in err for err in result.errors)

    def test_main_cli_success(self, test_environment):
        """Test main CLI entry point execution success."""
        from click.testing import CliRunner
        from adapter_generator import main
        
        runner = CliRunner()
        result = runner.invoke(main, [
            '--input', test_environment['skill_file'],
            '--templates', test_environment['template_dir'],
            '--output', test_environment['output_dir'],
            '--dry-run'
        ])
        
        assert result.exit_code == 0
        assert "Generation completed" in result.output

    def test_main_cli_failure(self, test_environment):
        """Test main CLI entry point execution failure."""
        from click.testing import CliRunner
        from adapter_generator import main
        
        runner = CliRunner()
        result = runner.invoke(main, [
            '--input', '/nonexistent/skill.md',
            '--templates', test_environment['template_dir'],
            '--output', test_environment['output_dir']
        ])
        
        assert result.exit_code != 0


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=adapter_generator'])
