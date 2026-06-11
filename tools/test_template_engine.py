"""
Unit tests for TemplateEngine module.
"""
import pytest
import tempfile
from pathlib import Path
from template_engine import TemplateEngine
from jinja2 import TemplateNotFound, TemplateSyntaxError


class TestTemplateEngine:
    """Test cases for TemplateEngine class."""
    
    @pytest.fixture
    def template_dir(self):
        """Create a temporary template directory with sample templates."""
        tmpdir = tempfile.mkdtemp()
        
        # Create a simple template
        simple_template = Path(tmpdir) / "simple.j2"
        simple_template.write_text("Hello {{ name }}!")
        
        # Create a nested template
        nested_dir = Path(tmpdir) / "nested"
        nested_dir.mkdir()
        nested_template = nested_dir / "nested.j2"
        nested_template.write_text("Nested: {{ value }}")
        
        # Create a template with syntax error
        error_template = Path(tmpdir) / "error.j2"
        error_template.write_text("{% if unclosed %}")
        
        # Create a template with includes
        base_template = Path(tmpdir) / "base.j2"
        base_template.write_text("Base: {{ base_content }}")
        
        included_template = Path(tmpdir) / "include.j2"
        included_template.write_text("{%- include 'base.j2' -%}")
        
        yield tmpdir
        
        # Cleanup
        import shutil
        shutil.rmtree(tmpdir)
    
    def test_init_with_valid_dir(self, template_dir):
        """Test initialization with a valid template directory."""
        engine = TemplateEngine(template_dir)
        assert engine.template_dir.exists()
    
    def test_init_with_invalid_dir(self):
        """Test initialization with an invalid directory."""
        with pytest.raises(ValueError):
            TemplateEngine("/nonexistent/directory")
    
    def test_load_template(self, template_dir):
        """Test loading a template."""
        engine = TemplateEngine(template_dir)
        template = engine.load("simple.j2")
        
        assert template is not None
        # Verify it can be rendered
        result = template.render(name="World")
        assert "Hello World!" in result
    
    def test_load_nested_template(self, template_dir):
        """Test loading a nested template."""
        engine = TemplateEngine(template_dir)
        template = engine.load("nested/nested.j2")
        
        assert template is not None
        result = template.render(value="test")
        assert "Nested: test" in result
    
    def test_load_missing_template(self, template_dir):
        """Test loading a template that doesn't exist."""
        engine = TemplateEngine(template_dir)
        
        with pytest.raises(TemplateNotFound):
            engine.load("missing.j2")
    
    def test_render(self, template_dir):
        """Test rendering a template with context."""
        engine = TemplateEngine(template_dir)
        result = engine.render("simple.j2", {"name": "Alice"})
        
        assert "Hello Alice!" in result
    
    def test_render_with_multiple_variables(self, template_dir):
        """Test rendering with multiple context variables."""
        # Create a template with multiple variables
        tmpl_path = Path(template_dir) / "multi.j2"
        tmpl_path.write_text("{{ first }} and {{ second }}")
        
        engine = TemplateEngine(template_dir)
        result = engine.render("multi.j2", {"first": "foo", "second": "bar"})
        
        assert "foo and bar" in result
    
    def test_render_missing_template(self, template_dir):
        """Test rendering a missing template."""
        engine = TemplateEngine(template_dir)
        
        with pytest.raises(TemplateNotFound):
            engine.render("missing.j2", {})
    
    def test_render_string(self, template_dir):
        """Test rendering a template from a string."""
        engine = TemplateEngine(template_dir)
        result = engine.render_string("Hello {{ name }}!", {"name": "Bob"})
        
        assert "Hello Bob!" in result
    
    def test_render_string_with_loops(self, template_dir):
        """Test rendering a string template with loops."""
        engine = TemplateEngine(template_dir)
        template_str = "{% for item in items %}{{ item }},{% endfor %}"
        result = engine.render_string(template_str, {"items": ["a", "b", "c"]})
        
        assert "a,b,c," in result
    
    def test_render_object(self, template_dir):
        """Test rendering a pre-loaded template object."""
        engine = TemplateEngine(template_dir)
        template = engine.load("simple.j2")
        
        result = engine.render_object(template, {"name": "Charlie"})
        assert "Hello Charlie!" in result
    
    def test_template_with_includes(self, template_dir):
        """Test template inheritance/includes."""
        engine = TemplateEngine(template_dir)
        result = engine.render("include.j2", {"base_content": "included content"})
        
        assert "Base: included content" in result
    
    def test_template_caching(self, template_dir):
        """Test that templates are cached."""
        engine = TemplateEngine(template_dir)
        template1 = engine.load("simple.j2")
        template2 = engine.load("simple.j2")
        
        # Both should be the same cached instance
        assert template1 is template2
    
    def test_autoescape_disabled(self, template_dir):
        """Test that autoescape is disabled."""
        # Create a template with HTML
        tmpl_path = Path(template_dir) / "html.j2"
        tmpl_path.write_text("{{ content }}")
        
        engine = TemplateEngine(template_dir)
        result = engine.render("html.j2", {"content": "<h1>Test</h1>"})
        
        # Should not be escaped
        assert "<h1>Test</h1>" in result
        assert "&lt;" not in result

    def test_load_syntax_error(self, template_dir):
        """Test loading a template with syntax errors."""
        engine = TemplateEngine(template_dir)
        with pytest.raises(TemplateSyntaxError):
            engine.load("error.j2")

    def test_render_runtime_error(self, template_dir):
        """Test rendering error triggers RuntimeError."""
        engine = TemplateEngine(template_dir)
        tmpl_path = Path(template_dir) / "render_err.j2"
        tmpl_path.write_text("{{ value() }}")
        with pytest.raises(RuntimeError):
            engine.render("render_err.j2", {"value": 1})

    def test_render_object_runtime_error(self, template_dir):
        """Test render_object error triggers RuntimeError."""
        engine = TemplateEngine(template_dir)
        tmpl_path = Path(template_dir) / "render_err.j2"
        tmpl_path.write_text("{{ value() }}")
        template = engine.load("render_err.j2")
        with pytest.raises(RuntimeError):
            engine.render_object(template, {"value": 1})

    def test_render_string_syntax_error(self, template_dir):
        """Test render_string syntax error."""
        engine = TemplateEngine(template_dir)
        with pytest.raises(TemplateSyntaxError):
            engine.render_string("{% if unclosed %}", {})

    def test_render_string_runtime_error(self, template_dir):
        """Test render_string runtime error triggers RuntimeError."""
        engine = TemplateEngine(template_dir)
        with pytest.raises(RuntimeError):
            engine.render_string("{{ value() }}", {"value": 1})


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--cov=template_engine'])
