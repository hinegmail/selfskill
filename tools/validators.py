"""
Validators Module
Validates generated adapters and configurations.
"""
import re
from pathlib import Path
from typing import List, Tuple, Dict
from abc import ABC, abstractmethod


class BaseValidator(ABC):
    """Base class for validators."""
    
    @abstractmethod
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate content.
        
        Args:
            content (str): Content to validate.
            file_path (str): Path to the file being validated.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        pass


class MarkdownValidator(BaseValidator):
    """Validates Markdown syntax."""
    
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate Markdown syntax.
        
        Args:
            content (str): Markdown content to validate.
            file_path (str): Path to the file.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # Check for unclosed headers
        header_lines = [line for line in content.split('\n') if line.startswith('#')]
        if not header_lines:
            errors.append("No headers found in markdown file")
        
        # Check for matching brackets
        if content.count('[') != content.count(']'):
            errors.append("Unmatched square brackets in markdown")
        
        # Check for matching braces in code blocks
        code_block_count = content.count('```')
        if code_block_count % 2 != 0:
            errors.append("Unclosed code blocks")
        
        # Check for proper link format
        invalid_links = re.findall(r'\[([^\]]+)\]\s*\((?!https?://|/|\w+\.|\.)', content)
        if invalid_links:
            errors.append(f"Invalid link format found: {invalid_links[:3]}")
        
        return len(errors) == 0, errors


class MDCValidator(BaseValidator):
    """Validates MDC (Markdown Cursor) format."""
    
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate MDC format.
        
        Args:
            content (str): MDC content to validate.
            file_path (str): Path to the file.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # First check basic markdown syntax
        md_validator = MarkdownValidator()
        is_valid, md_errors = md_validator.validate(content, file_path)
        if not is_valid:
            errors.extend(md_errors)
        
        # MDC specific checks - validate against cursor-specific patterns
        # Check for proper frontmatter or comments if needed
        if not content.strip():
            errors.append("MDC file is empty")
        
        return len(errors) == 0, errors


class VersionValidator(BaseValidator):
    """Validates version format."""
    
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate version format.
        
        Args:
            content (str): Content to validate for version.
            file_path (str): Path to the file.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # Look for version pattern (v1.0.2 or similar)
        version_match = re.search(r'v(\d+\.\d+\.\d+)', content)
        if not version_match:
            errors.append("No version found in format v{major}.{minor}.{patch}")
        else:
            version = version_match.group(1)
            # Validate semantic versioning
            parts = version.split('.')
            if len(parts) != 3:
                errors.append(f"Invalid version format: {version}")
        
        return len(errors) == 0, errors


class FileReferenceValidator(BaseValidator):
    """Validates file references (e.g., no PRD.md, correct requirements.md)."""
    
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate file references.
        
        Args:
            content (str): Content to validate.
            file_path (str): Path to the file.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # Check for old PRD.md reference
        if 'PRD.md' in content:
            # Count occurrences
            count = content.count('PRD.md')
            errors.append(f"Found {count} reference(s) to 'PRD.md' (should be 'requirements.md')")
        
        # Check that requirements.md is referenced
        if '.md' in content or '.txt' in content:
            if 'requirements.md' not in content and 'requirements' not in content.lower():
                errors.append("No reference to 'requirements.md' found (expected for file references)")
        
        return len(errors) == 0, errors


class LanguageValidator(BaseValidator):
    """Validates language usage (no Chinese code comments)."""
    
    def validate(self, content: str, file_path: str) -> Tuple[bool, List[str]]:
        """
        Validate that code comments are not in Chinese.
        
        Args:
            content (str): Content to validate.
            file_path (str): Path to the file.
            
        Returns:
            Tuple[bool, List[str]]: (is_valid, error_messages)
        """
        errors = []
        
        # Pattern to detect Chinese characters (excluding trigger keywords table)
        chinese_pattern = re.compile(r'[\u4e00-\u9fff]+')
        
        lines = content.split('\n')
        in_table = False
        chinese_lines = []
        
        for i, line in enumerate(lines, 1):
            # Skip markdown tables
            if '|' in line:
                in_table = True
            elif in_table and not line.strip():
                in_table = False
            
            if in_table:
                continue
            
            # Skip headers starting with ##
            if line.startswith('##'):
                continue
            
            # Check for Chinese in code blocks comments
            if '```' in line:
                continue
            
            # Detect Chinese code comments (e.g., # 中文注释, // 中文注释)
            if re.match(r'^\s*[#/]\s*', line):
                if chinese_pattern.search(line):
                    chinese_lines.append((i, line.strip()))
        
        if chinese_lines:
            errors.append(f"Found Chinese code comments at lines: {[cl[0] for cl in chinese_lines[:5]]}")
        
        return len(errors) == 0, errors


class AdapterValidator:
    """Main validator for adapter files."""
    
    def __init__(self):
        """Initialize validator with all sub-validators."""
        self.validators = [
            MarkdownValidator(),
            VersionValidator(),
            FileReferenceValidator(),
            LanguageValidator(),
        ]
    
    def validate_file(self, file_path: str) -> Tuple[bool, Dict[str, List[str]]]:
        """
        Validate an adapter file.
        
        Args:
            file_path (str): Path to the adapter file.
            
        Returns:
            Tuple[bool, Dict]: (is_valid, errors_by_validator)
        """
        if not Path(file_path).exists():
            return False, {"file": [f"File not found: {file_path}"]}
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except Exception as e:
            return False, {"file": [f"Failed to read file: {str(e)}"]}
        
        all_errors = {}
        all_valid = True
        
        for validator in self.validators:
            validator_name = validator.__class__.__name__
            is_valid, errors = validator.validate(content, file_path)
            
            if not is_valid:
                all_valid = False
                all_errors[validator_name] = errors
        
        return all_valid, all_errors
    
    def validate_directory(self, dir_path: str) -> Dict[str, Tuple[bool, Dict]]:
        """
        Validate all adapter files in a directory.
        
        Args:
            dir_path (str): Path to the directory containing adapters.
            
        Returns:
            Dict: Results for each file.
        """
        results = {}
        dir_obj = Path(dir_path)
        
        # Validate all .md and .mdc files
        for file_path in dir_obj.glob('*.md'):
            results[file_path.name] = self.validate_file(str(file_path))
        
        for file_path in dir_obj.glob('*.mdc'):
            results[file_path.name] = self.validate_file(str(file_path))
        
        return results


# CLI Interface
import click


@click.group()
def cli():
    """Adapter validation tools."""
    pass


@cli.command()
@click.argument('file_path', type=click.Path(exists=True))
def validate_file(file_path):
    """Validate a single adapter file."""
    validator = AdapterValidator()
    is_valid, errors = validator.validate_file(file_path)
    
    if is_valid:
        click.echo(f"✓ {file_path} is valid")
    else:
        click.echo(f"✗ {file_path} has validation errors:")
        for validator_name, error_list in errors.items():
            click.echo(f"  {validator_name}:")
            for error in error_list:
                click.echo(f"    - {error}")
    
    exit(0 if is_valid else 1)


@cli.command()
@click.argument('dir_path', type=click.Path(exists=True))
def validate_dir(dir_path):
    """Validate all adapters in a directory."""
    validator = AdapterValidator()
    results = validator.validate_directory(dir_path)
    
    if not results:
        click.echo(f"No adapter files found in {dir_path}")
        return
    
    all_valid = True
    for file_name, (is_valid, errors) in results.items():
        status = "✓" if is_valid else "✗"
        click.echo(f"{status} {file_name}")
        
        if not is_valid:
            all_valid = False
            for validator_name, error_list in errors.items():
                for error in error_list:
                    click.echo(f"    {validator_name}: {error}")
    
    exit(0 if all_valid else 1)


if __name__ == '__main__':
    cli()
