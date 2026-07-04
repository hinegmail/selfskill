"""
Integration tests for the adapter generation workflow.
"""
import tempfile
from pathlib import Path
from adapter_generator import AdapterGenerator
from validators import AdapterValidator


def test_integration_generation_and_validation():
    """End-to-end integration test: generate adapters using real skill.md and templates, then validate."""
    # Resolve real paths
    root_dir = Path(__file__).parent.parent
    skill_file = root_dir / "skill.md"
    template_dir = root_dir / "tools" / "templates" / "adapter"
    
    assert skill_file.exists(), f"Real skill.md not found at {skill_file}"
    assert template_dir.exists(), f"Real templates folder not found at {template_dir}"
    
    # Run E2E generation inside a temporary directory
    with tempfile.TemporaryDirectory() as tmpdir:
        generator = AdapterGenerator(
            skill_file=str(skill_file),
            template_dir=str(template_dir),
            output_dir=tmpdir,
        )
        
        # Generation step
        result = generator.generate(validate=True)
        assert result.success is True, f"E2E Generation failed: {result.errors}"
        assert len(result.generated_files) == 9, f"Expected 9 files (8 adapters + mode_reference), got {len(result.generated_files)}"
        
        # Validation step
        validator = AdapterValidator()
        validation_results = validator.validate_directory(tmpdir)
        
        assert len(validation_results) == 8, f"Expected 8 files to validate, got {len(validation_results)}"
        for file_name, (is_valid, errors) in validation_results.items():
            assert is_valid is True, f"Generated adapter file {file_name} failed validation: {errors}"
