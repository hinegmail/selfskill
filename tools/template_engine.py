"""
TemplateEngine Module
Manages Jinja2 template loading and rendering for adapters.
"""
from pathlib import Path
from typing import Dict, Optional
from jinja2 import Environment, FileSystemLoader, TemplateNotFound, TemplateSyntaxError


class TemplateEngine:
    """Jinja2 template engine for adapter generation."""
    
    def __init__(self, template_dir: str):
        """
        Initialize the TemplateEngine.
        
        Args:
            template_dir (str): Path to the templates directory.
            
        Raises:
            ValueError: If the template directory does not exist.
        """
        self.template_dir = Path(template_dir)
        
        if not self.template_dir.exists():
            raise ValueError(f"Template directory not found: {template_dir}")
        
        # Initialize Jinja2 environment
        self.env = Environment(
            loader=FileSystemLoader(str(self.template_dir)),
            autoescape=False,
            keep_trailing_newline=True,
        )
    
    def load(self, template_name: str):
        """
        Load a Jinja2 template by name.
        
        Args:
            template_name (str): Name of the template file (e.g., 'base.j2').
            
        Returns:
            jinja2.Template: The loaded template object.
            
        Raises:
            TemplateNotFound: If the template does not exist.
            TemplateSyntaxError: If the template has syntax errors.
        """
        try:
            return self.env.get_template(template_name)
        except TemplateNotFound as e:
            raise TemplateNotFound(
                f"Template not found: {template_name} in {self.template_dir}"
            ) from e
        except TemplateSyntaxError as e:
            raise TemplateSyntaxError(
                f"Template syntax error in {template_name}: {e.message}",
                e.lineno,
            ) from e
    
    def render(self, template_name: str, context: Dict) -> str:
        """
        Render a template with the given context.
        
        Args:
            template_name (str): Name of the template file.
            context (Dict): Context variables for rendering.
            
        Returns:
            str: The rendered template output.
            
        Raises:
            TemplateNotFound: If the template does not exist.
            TemplateSyntaxError: If the template has syntax errors.
            Exception: If rendering fails.
        """
        try:
            template = self.load(template_name)
            return template.render(context)
        except (TemplateNotFound, TemplateSyntaxError) as e:
            raise
        except Exception as e:
            raise RuntimeError(
                f"Template rendering error for {template_name}: {str(e)}"
            ) from e
    
    def render_object(self, template_obj, context: Dict) -> str:
        """
        Render a pre-loaded template object with the given context.
        
        Args:
            template_obj: A Jinja2 template object.
            context (Dict): Context variables for rendering.
            
        Returns:
            str: The rendered template output.
            
        Raises:
            Exception: If rendering fails.
        """
        try:
            return template_obj.render(context)
        except Exception as e:
            raise RuntimeError(
                f"Template rendering error: {str(e)}"
            ) from e
    
    def render_string(self, template_string: str, context: Dict) -> str:
        """
        Render a template from a string.
        
        Args:
            template_string (str): The template content as a string.
            context (Dict): Context variables for rendering.
            
        Returns:
            str: The rendered output.
            
        Raises:
            TemplateSyntaxError: If the template string has syntax errors.
        """
        try:
            template = self.env.from_string(template_string)
            return template.render(context)
        except TemplateSyntaxError as e:
            raise TemplateSyntaxError(
                f"Template syntax error: {e.message}",
                e.lineno,
            ) from e
        except Exception as e:
            raise RuntimeError(
                f"String template rendering error: {str(e)}"
            ) from e
