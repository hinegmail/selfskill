"""
SkillParser Module
Parses skill definition files and extracts metadata and content.
"""
import re
from typing import Dict, List, Optional


class SkillParser:
    """Parser for skill definition files."""
    
    def __init__(self, file_path: str):
        """
        Initialize the SkillParser.
        
        Args:
            file_path (str): Path to the skill file to parse.
            
        Raises:
            FileNotFoundError: If the skill file does not exist.
        """
        self.file_path = file_path
        self.content = None
        self.metadata = {}
        self._lines: List[str] = []
        self._load_content()
    
    def _load_content(self) -> None:
        """Load and store file content."""
        try:
            with open(self.file_path, 'r', encoding='utf-8') as f:
                self.content = f.read()
            self._lines = self.content.split('\n')
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Skill file not found: {self.file_path}") from e
    
    def extract_version(self) -> str:
        """
        Extract version number from skill file.
        
        Returns:
            str: Version string (e.g., "1.0.2")
            
        Raises:
            ValueError: If version cannot be extracted.
        """
        # Match pattern like "# ProjectOrchestrator Skill v1.0" or "v1.0.2"
        match = re.search(r'v(\d+\.\d+(?:\.\d+)?)', self.content)
        if match:
            return match.group(1)
        raise ValueError("Version not found in skill file")
    
    def extract_section(self, section_name: str) -> str:
        """
        Extract a specific section from the skill file.
        
        Args:
            section_name (str): The section name to extract (e.g., "Core Principles").
            
        Returns:
            str: The section content, or empty string if not found.
        """
        # Find section header - match both "## N. Name" and "## Name" patterns
        pattern = rf'^##\s+(?:\d+\.\s+)?{re.escape(section_name)}\s*$'
        lines = self._lines
        
        section_start = None
        for i, line in enumerate(lines):
            if re.match(pattern, line, re.IGNORECASE):
                section_start = i
                break
        
        if section_start is None:
            return ""
        
        # Find next section or end of file
        section_end = len(lines)
        for i in range(section_start + 1, len(lines)):
            if lines[i].startswith('##') and not lines[i].startswith('###'):
                section_end = i
                break
        
        return '\n'.join(lines[section_start:section_end]).strip()
    
    def extract_modes(self) -> Dict[str, str]:
        """
        Extract all mode definitions (Mode 0-6, including sub-modes like 4.5, 6.5).

        Returns:
            Dict[str, str]: Dictionary mapping mode names to their content.
        """
        modes = {}
        lines = self._lines

        # Match any mode number, integer or decimal (e.g. Mode 0, Mode 4.5, Mode 6.5)
        pattern = re.compile(r'^###\s+Mode\s+(\d+(?:\.\d+)?):', re.IGNORECASE)

        # Find all mode heading positions
        mode_starts: List[tuple] = []  # (line_index, mode_number_str)
        in_code_block = False
        for i, line in enumerate(lines):
            if line.strip().startswith('```'):
                in_code_block = not in_code_block
                continue
            if in_code_block:
                continue
            match = pattern.match(line)
            if match:
                mode_starts.append((i, match.group(1)))

        for idx, (mode_start, mode_num) in enumerate(mode_starts):
            # Find end: next mode heading or next ## section or EOF
            mode_end = len(lines)
            if idx + 1 < len(mode_starts):
                mode_end = mode_starts[idx + 1][0]
            else:
                for i in range(mode_start + 1, len(lines)):
                    if lines[i].startswith('## ') and not lines[i].startswith('### '):
                        mode_end = i
                        break

            header = lines[mode_start]
            mode_name_match = re.search(r'Mode\s+\d+(?:\.\d+)?:\s*(.+?)(?:\(|$)', header)
            mode_name = mode_name_match.group(1).strip() if mode_name_match else f"Mode {mode_num}"

            modes[mode_name] = '\n'.join(lines[mode_start:mode_end]).strip()

        return modes
    
    def extract_keywords(self) -> Dict[str, List[str]]:
        """
        Extract trigger keywords table from the skill file.
        
        Returns:
            Dict[str, List[str]]: Dictionary mapping trigger intents to keywords.
        """
        keywords = {}
        
        # Find the trigger keywords section
        pattern = r'##\s+7\.\s+Trigger\s+Keywords'
        lines = self._lines
        
        table_start = None
        for i, line in enumerate(lines):
            if re.search(pattern, line, re.IGNORECASE):
                table_start = i
                break
        
        if table_start is None:
            return keywords
        
        # Find the table and parse it
        in_table = False
        for i in range(table_start, len(lines)):
            line = lines[i]
            
            # Detect table start
            if '|' in line and not in_table:
                in_table = True
                continue
            
            # Skip separator
            if re.match(r'^\|\s*-+', line):
                continue
            
            # Parse table rows
            if in_table and '|' in line:
                cells = [cell.strip() for cell in line.split('|')[1:-1]]
                if len(cells) >= 2:
                    intent = cells[0]
                    cn_keywords = cells[1]
                    
                    # Split keywords - handle both "keyword1、keyword2" and quoted forms
                    cn_list = []
                    for kw in re.split(r'[、,]', cn_keywords):
                        kw = kw.strip()
                        if kw:
                            # Remove quotes if present
                            kw = kw.strip('"').strip("'")
                            cn_list.append(kw)
                    
                    if cn_list:
                        keywords[intent] = cn_list
            
            # Exit table
            if in_table and not line.strip():
                break
        
        return keywords
    
    def extract_forbidden_behaviors(self) -> List[str]:
        """
        Extract forbidden behaviors list from the skill file.
        
        Returns:
            List[str]: List of forbidden behaviors.
        """
        behaviors = []
        
        # Find the forbidden behaviors section
        pattern = r'##\s+8\.\s+Forbidden\s+Behaviors'
        lines = self._lines
        
        section_start = None
        for i, line in enumerate(lines):
            if re.search(pattern, line, re.IGNORECASE):
                section_start = i
                break
        
        if section_start is None:
            return behaviors
        
        # Parse the list
        section_end = len(lines)
        for i in range(section_start + 1, len(lines)):
            if lines[i].startswith('##') and not lines[i].startswith('###'):
                section_end = i
                break
        
        for i in range(section_start + 1, section_end):
            line = lines[i].strip()
            if re.match(r'^\d+\.\s+', line):
                # Extract behavior description
                behavior = re.sub(r'^\d+\.\s+', '', line)
                behaviors.append(behavior)
        
        return behaviors
    
    def validate_syntax(self) -> bool:
        """
        Validate the syntax of the skill definition.
        
        Returns:
            bool: True if valid, False otherwise.
        """
        if not self.content:
            return False
        
        # Check for required sections
        required_sections = [
            r'##\s+0\.\s+Role Definition',
            r'##\s+1\.\s+Core Principles',
            r'##\s+4\.\s+Seven-Mode Execution Engine',
            r'##\s+7\.\s+Trigger Keywords',
        ]
        
        for pattern in required_sections:
            if not re.search(pattern, self.content):
                return False
        
        return True
    
    def extract_all_sections(self) -> Dict[str, str]:
        """
        Extract all top-level (##) sections from the skill file by scanning
        headings in order. Each section spans from its heading line to the
        line before the next ## heading (or end of file).

        Headings inside fenced code blocks (```) are ignored to prevent
        splitting sections at output-template markers like '## 🚀 Initialization'.

        Returns:
            Dict[str, str]: Ordered dict mapping heading text (without '## ')
                            to the full section content including the heading.
        """
        lines = self._lines
        sections: Dict[str, str] = {}
        boundaries: List[tuple] = []  # (start_line, heading_text)

        in_code_block = False
        for i, line in enumerate(lines):
            if line.strip().startswith('```'):
                in_code_block = not in_code_block
                continue
            if not in_code_block and line.startswith('## ') and not line.startswith('### '):
                heading = line[3:].strip()
                boundaries.append((i, heading))

        for idx, (start, heading) in enumerate(boundaries):
            end = boundaries[idx + 1][0] if idx + 1 < len(boundaries) else len(lines)
            section_content = '\n'.join(lines[start:end]).rstrip()
            sections[heading] = section_content

        return sections

    def parse(self) -> Dict:
        """
        Parse the entire skill file.
        
        Returns:
            dict: Parsed skill data including metadata and content.
            
        Raises:
            ValueError: If the skill file is invalid.
        """
        if not self.validate_syntax():
            raise ValueError("Skill file failed syntax validation")

        all_sections = self.extract_all_sections()

        # Build a filtered dict of numbered top-level sections only
        # (keys matching pattern "N. Title" or "N.N Title"), preserving order.
        numbered_sections: Dict[str, str] = {
            k: v for k, v in all_sections.items()
            if re.match(r'^\d+[\.\s]', k)
        }

        return {
            'version': self.extract_version(),
            'modes': self.extract_modes(),
            'keywords': self.extract_keywords(),
            'forbidden_behaviors': self.extract_forbidden_behaviors(),
            'sections': numbered_sections,
            'all_sections': all_sections,
        }
