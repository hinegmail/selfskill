"""
AdapterGenerator Module
Main orchestration tool for generating adapters from skill definitions.
"""
import json
import re
import time
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
import yaml
import click

from skill_parser import SkillParser
from template_engine import TemplateEngine
from validators import AdapterValidator


@dataclass
class GenerationResult:
    """Result of adapter generation."""
    version: str
    generated_files: Dict[str, str]  # platform -> file path
    generation_timestamp: str
    duration_seconds: float
    success: bool
    errors: List[str]
    validation_warnings: List[str]  # post-generation adapter validation warnings


class AdapterGenerator:
    """Main orchestration for adapter generation."""
    
    # Supported platforms
    PLATFORMS = [
        'kiro',
        'antigravity',
        'claude',
        'cursor',
        'clinerules',
        'windsurfer',
        'gemini',
        'agents',
    ]
    
    def __init__(
        self,
        skill_file: str,
        template_dir: str,
        output_dir: str,
        config_file: Optional[str] = None,
    ):
        """
        Initialize the AdapterGenerator.
        
        Args:
            skill_file (str): Path to the skill.md file.
            template_dir (str): Path to the templates directory.
            output_dir (str): Path to the output directory.
            config_file (str, optional): Path to a YAML configuration file.
            
        Raises:
            ValueError: If required files/directories don't exist.
        """
        self.skill_file = Path(skill_file)
        self.template_dir = Path(template_dir)
        self.output_dir = Path(output_dir)
        
        if not self.skill_file.exists():
            raise ValueError(f"Skill file not found: {skill_file}")
        if not self.template_dir.exists():
            raise ValueError(f"Template directory not found: {template_dir}")
        
        # Create output directory if needed
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Load configuration if provided
        self.config = self._load_config(config_file) if config_file else {}
        
        # Initialize parsers
        self.skill_parser = SkillParser(str(self.skill_file))
        self.template_engine = TemplateEngine(str(self.template_dir))
    
    def _load_config(self, config_file: str) -> Dict:
        """Load configuration from YAML file."""
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f) or {}
        except Exception as e:
            raise ValueError(f"Failed to load config file {config_file}: {str(e)}")
    
    def generate(
        self,
        platforms: Optional[List[str]] = None,
        dry_run: bool = False,
        validate: bool = True,
    ) -> GenerationResult:
        """
        Generate adapters for specified platforms.
        
        Args:
            platforms (List[str], optional): List of platforms to generate.
                If None, generates all platforms.
            dry_run (bool): If True, don't write files.
            validate (bool): If True, validate input before generation.
            
        Returns:
            GenerationResult: Result of generation.
        """
        start_time = time.time()
        errors = []
        generated_files = {}
        
        try:
            # Parse skill file
            try:
                skill_data = self.skill_parser.parse()
                version = skill_data['version']
            except Exception as e:
                return GenerationResult(
                    version="unknown",
                    generated_files={},
                    generation_timestamp="",
                    duration_seconds=time.time() - start_time,
                    success=False,
                    errors=[f"Failed to parse skill.md: {str(e)}"],
                    validation_warnings=[],
                )
            
            # Validate if requested
            if validate and not self.skill_parser.validate_syntax():
                return GenerationResult(
                    version=version,
                    generated_files={},
                    generation_timestamp="",
                    duration_seconds=time.time() - start_time,
                    success=False,
                    errors=["Skill file failed syntax validation"],
                    validation_warnings=[],
                )
            
            # Determine which platforms to generate
            target_platforms = platforms if platforms else self.PLATFORMS
            
            # Validate platform names
            invalid_platforms = [p for p in target_platforms if p not in self.PLATFORMS]
            if invalid_platforms:
                errors.append(f"Unknown platforms: {invalid_platforms}")
                return GenerationResult(
                    version=version,
                    generated_files={},
                    generation_timestamp="",
                    duration_seconds=time.time() - start_time,
                    success=False,
                    errors=errors,
                )
            
            # Generate each adapter
            context = {
                'version': version,
                'skill_data': skill_data,
                'config': self.config,
            }
            
            for platform in target_platforms:
                try:
                    output_file = self._generate_adapter(
                        platform,
                        context,
                        dry_run,
                    )
                    generated_files[platform] = str(output_file)
                except Exception as e:
                    errors.append(f"Failed to generate {platform}: {str(e)}")
            
            success = len(errors) == 0

            # Post-generation: validate each generated adapter
            validation_warnings = []
            if success and not dry_run:
                adapter_validator = AdapterValidator()
                for platform, file_path in generated_files.items():
                    is_valid, validator_errors = adapter_validator.validate_file(file_path)
                    if not is_valid:
                        for vname, verrors in validator_errors.items():
                            for msg in verrors:
                                validation_warnings.append(
                                    f"{platform}/{vname}: {msg}"
                                )

            # Post-generation: auto-update SKILL_VERSION.md if it exists
            if success and not dry_run:
                self._update_skill_version(version, generated_files)

        except Exception as e:
            errors.append(f"Generation failed: {str(e)}")
            success = False
            validation_warnings = []
        
        duration = time.time() - start_time
        
        return GenerationResult(
            version=version if 'version' in locals() else "unknown",
            generated_files=generated_files,
            generation_timestamp=self._get_timestamp(),
            duration_seconds=duration,
            success=success,
            errors=errors,
            validation_warnings=validation_warnings,
        )
    
    def _generate_adapter(
        self,
        platform: str,
        context: Dict,
        dry_run: bool,
    ) -> Path:
        """Generate a single adapter."""
        # Determine template name
        template_name = f"platforms/{platform}.j2"
        
        # Render template
        output_content = self.template_engine.render(template_name, context)
        
        # Determine output file
        file_extensions = {
            'cursor': '.mdc',
            'clinerules': '.md',
            'windsurfer': '.md',
        }
        ext = file_extensions.get(platform, '.md')
        
        platform_name_map = {
            'kiro': 'KIRO_AGENT.md',
            'antigravity': 'ANTIGRAVITY.md',
            'claude': 'CLAUDE.md',
            'cursor': 'cursor.mdc',
            'clinerules': 'clinerules.md',
            'windsurfer': 'windsurfrules.md',
            'gemini': 'gemini_styleguide.md',
            'agents': 'AGENTS.md',
        }
        
        output_file = self.output_dir / platform_name_map.get(platform, f"{platform}{ext}")
        
        # Write file if not dry run
        if not dry_run:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(output_content)
        
        return output_file
    
    def validate(self) -> Tuple[bool, List[str]]:
        """
        Validate the generation setup.
        
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # Check skill file
        if not self.skill_file.exists():
            errors.append(f"Skill file not found: {self.skill_file}")
        else:
            try:
                if not self.skill_parser.validate_syntax():
                    errors.append("Skill file failed syntax validation")
            except Exception as e:
                errors.append(f"Failed to validate skill file: {str(e)}")
        
        # Check templates
        for platform in self.PLATFORMS:
            template_name = f"platforms/{platform}.j2"
            try:
                self.template_engine.load(template_name)
            except Exception as e:
                errors.append(f"Template not found for {platform}: {str(e)}")
        
        return len(errors) == 0, errors
    
    def _update_skill_version(self, version: str, generated_files: Dict[str, str]) -> None:
        """
        Auto-update SKILL_VERSION.md with current version and timestamp.
        Looks for the file relative to skill.md's parent directory.
        Silently skips if the file does not exist.
        """
        skill_dir = self.skill_file.parent
        version_file = skill_dir / '.ai' / 'SKILL_VERSION.md'
        if not version_file.exists():
            return

        today = datetime.utcnow().strftime('%Y-%m-%d')
        content = version_file.read_text(encoding='utf-8')

        # Update version table rows: replace any v\d+\.\d+[\.\d]* cell values
        # in the three component rows (skill.md, adapters, templates)
        content = re.sub(
            r'(\|\s*\*\*skill\.md\*\*\s*\|\s*)v[\d.]+(\s*\|)',
            rf'\g<1>v{version}\g<2>',
            content,
        )
        content = re.sub(
            r'(\|\s*\*\*适配器\*\*\s*\|\s*)v[\d.]+(\s*\|)',
            rf'\g<1>v{version}\g<2>',
            content,
        )
        content = re.sub(
            r'(\|\s*\*\*模板\*\*\s*\|\s*)v[\d.]+(\s*\|)',
            rf'\g<1>v{version}\g<2>',
            content,
        )

        # Update all date cells in the version table (| YYYY-MM-DD |)
        content = re.sub(
            r'(\|\s*✅[^\|]*\|\s*)\d{4}-\d{2}-\d{2}(\s*\|)',
            rf'\g<1>{today}\g<2>',
            content,
        )

        # Update "最后更新" standalone line if present
        content = re.sub(
            r'(\*\*最后更新\*\*：)\d{4}-\d{2}-\d{2}',
            rf'\g<1>{today}',
            content,
        )

        version_file.write_text(content, encoding='utf-8')

    @staticmethod
    def _get_timestamp() -> str:
        """Get current timestamp in ISO format."""
        from datetime import datetime
        return datetime.utcnow().isoformat() + 'Z'


@click.command()
@click.option(
    '--input',
    type=click.Path(exists=True),
    default='skill.md',
    help='Path to skill.md file'
)
@click.option(
    '--templates',
    type=click.Path(exists=True),
    default='tools/templates/adapter',
    help='Path to templates directory'
)
@click.option(
    '--output',
    type=click.Path(),
    default='adapters',
    help='Output directory for adapters'
)
@click.option(
    '--platforms',
    type=str,
    default=None,
    help='Comma-separated list of platforms (default: all)'
)
@click.option(
    '--config',
    type=click.Path(exists=True),
    default=None,
    help='Path to YAML configuration file'
)
@click.option(
    '--version',
    type=str,
    default=None,
    help='Force version number'
)
@click.option(
    '--dry-run',
    is_flag=True,
    help='Preview generation without writing files'
)
@click.option(
    '--validate',
    is_flag=True,
    default=True,
    help='Validate input before generation'
)
def main(input, templates, output, platforms, config, version, dry_run, validate):
    """Generate adapters from skill definition."""
    try:
        generator = AdapterGenerator(
            skill_file=input,
            template_dir=templates,
            output_dir=output,
            config_file=config,
        )
        
        # Parse platform list
        target_platforms = None
        if platforms:
            target_platforms = [p.strip() for p in platforms.split(',')]
        
        # Generate adapters
        result = generator.generate(
            platforms=target_platforms,
            dry_run=dry_run,
            validate=validate,
        )
        
        # Output results
        if result.success:
            click.echo(f"✓ Generation completed in {result.duration_seconds:.2f}s")
            click.echo(f"  Version: {result.version}")
            click.echo(f"  Generated files: {len(result.generated_files)}")
            for platform, path in result.generated_files.items():
                click.echo(f"    - {platform}: {path}")
            if result.validation_warnings:
                click.echo(f"\n⚠ Adapter validation warnings ({len(result.validation_warnings)}):")
                for w in result.validation_warnings:
                    click.echo(f"    {w}")
        else:
            click.echo("✗ Generation failed")
            for error in result.errors:
                click.echo(f"  ERROR: {error}")
            exit(1)
    
    except Exception as e:
        click.echo(f"✗ Error: {str(e)}", err=True)
        exit(1)


if __name__ == '__main__':
    import sys
    import io
    import logging
    from datetime import datetime
    from pathlib import Path

    # Determine log directory: tools/logs
    log_dir = Path(__file__).parent / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Generate timestamped log file path
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = log_dir / f"project_orchestrator_{timestamp}.log"

    # Set up basic logging to both stdout and a file
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(str(log_file), encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    # Force UTF-8 encoding for standard output on Windows to prevent UnicodeEncodeError
    if sys.platform.startswith('win'):
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
    main()
