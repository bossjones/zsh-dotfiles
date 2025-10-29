#!/usr/bin/env python3
"""
Development Environment Checker
Verifies that all required packages and tools are properly installed.
"""

import subprocess
import sys
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import re


class Colors:
    """ANSI color codes for terminal output"""
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


class EnvironmentChecker:
    def __init__(self):
        self.results = {
            'brew_packages': [],
            'sheldon': None,
            'chezmoi': None,
            'asdf_tools': []
        }
        self.failed_checks = []
        
    def print_header(self, text: str):
        """Print a formatted section header"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.BLUE}{text}{Colors.ENDC}")
        print(f"{Colors.BOLD}{Colors.BLUE}{'=' * 70}{Colors.ENDC}\n")
    
    def print_success(self, text: str):
        """Print success message"""
        print(f"{Colors.GREEN}✓{Colors.ENDC} {text}")
    
    def print_failure(self, text: str):
        """Print failure message"""
        print(f"{Colors.RED}✗{Colors.ENDC} {text}")
        self.failed_checks.append(text)
    
    def print_warning(self, text: str):
        """Print warning message"""
        print(f"{Colors.YELLOW}⚠{Colors.ENDC} {text}")
    
    def run_command(self, cmd: List[str]) -> Tuple[bool, str, str]:
        """Run a shell command and return success status, stdout, stderr"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)
    
    def check_brew_package(self, package: str) -> bool:
        """Check if a brew package is installed"""
        success, stdout, _ = self.run_command(['brew', 'list', '--formula'])
        if not success:
            return False
        
        # Handle cask packages separately
        if 'font-' in package:
            success, stdout, _ = self.run_command(['brew', 'list', '--cask'])
            if not success:
                return False
        
        installed_packages = stdout.strip().split('\n')
        return package in installed_packages
    
    def check_sheldon(self) -> Dict:
        """Check sheldon installation, version, and location"""
        expected_version = "0.6.6"
        expected_location = Path.home() / ".local" / "bin" / "sheldon"
        
        result = {
            'installed': False,
            'location': None,
            'version': None,
            'location_correct': False,
            'version_correct': False
        }
        
        # Check if sheldon exists at expected location
        if expected_location.exists():
            result['installed'] = True
            result['location'] = str(expected_location)
            result['location_correct'] = True
            
            # Get version
            success, stdout, _ = self.run_command([str(expected_location), '--version'])
            if success:
                # Parse version from output like "sheldon 0.6.6"
                match = re.search(r'(\d+\.\d+\.\d+)', stdout)
                if match:
                    result['version'] = match.group(1)
                    result['version_correct'] = result['version'] == expected_version
        else:
            # Check if sheldon is in PATH
            success, stdout, _ = self.run_command(['which', 'sheldon'])
            if success:
                result['installed'] = True
                result['location'] = stdout.strip()
                
                # Get version
                success, stdout, _ = self.run_command(['sheldon', '--version'])
                if success:
                    match = re.search(r'(\d+\.\d+\.\d+)', stdout)
                    if match:
                        result['version'] = match.group(1)
                        result['version_correct'] = result['version'] == expected_version
        
        return result
    
    def check_chezmoi(self) -> Dict:
        """Check chezmoi installation"""
        result = {
            'installed': False,
            'location': None,
            'version': None
        }
        
        # Check if chezmoi is in PATH
        success, stdout, _ = self.run_command(['which', 'chezmoi'])
        if success:
            result['installed'] = True
            result['location'] = stdout.strip()
            
            # Get version
            success, stdout, _ = self.run_command(['chezmoi', '--version'])
            if success:
                # Parse version from output
                match = re.search(r'(\d+\.\d+\.\d+)', stdout)
                if match:
                    result['version'] = match.group(1)
        
        return result
    
    def check_asdf_tool(self, tool: str, expected_version: str) -> Dict:
        """Check if an asdf-managed tool is installed with correct version"""
        result = {
            'tool': tool,
            'expected_version': expected_version,
            'installed': False,
            'current_version': None,
            'version_correct': False
        }
        
        # Check asdf current for this tool
        success, stdout, _ = self.run_command(['asdf', 'current', tool])
        if success:
            # Parse output like "golang          1.20.5          /Users/bossjones/.tool-versions"
            parts = stdout.strip().split()
            if len(parts) >= 2:
                result['installed'] = True
                result['current_version'] = parts[1]
                result['version_correct'] = result['current_version'] == expected_version
        
        return result
    
    def check_all_brew_packages(self):
        """Check all brew packages from the requirements"""
        self.print_header("Checking Homebrew Packages")
        
        # Core packages from history
        packages = [
            # Basic utilities
            'duf', 'dust', 'dua-cli', 'ncdu', 'peco', 'pdfgrep', 'git-delta',
            'broot', 'bat', 'pv', 'tree', 'figlet', 'graphviz',
            
            # System libraries
            'atomicparsley', 'cmake', 'coreutils', 'doxygen', 'eigen',
            'ffmpeg', 'tesseract', 'findutils',
            
            # Fonts (cask)
            'font-fira-code', 'font-fira-code-nerd-font', 'font-fira-mono-nerd-font',
            'font-droid-sans-mono-nerd-font', 'font-fontawesome', 'font-hack-nerd-font',
            'font-inconsolata-nerd-font', 'font-jetbrains-mono-nerd-font',
            'font-liberation', 'font-liberation-nerd-font', 'font-meslo-lg-nerd-font',
            'font-mononoki-nerd-font', 'font-noto-color-emoji', 'font-noto-emoji',
            'font-noto-nerd-font', 'font-sauce-code-pro-nerd-font',
            'font-symbols-only-nerd-font', 'font-ubuntu-mono-nerd-font',
            'font-ubuntu-nerd-font', 'font-victor-mono-nerd-font',
            
            # More libraries
            'gawk', 'gnu-getopt', 'gnu-sed', 'gnu-tar', 'gnutls',
            'graphicsmagick', 'hdf5', 'jpeg', 'libffi', 'libmagic',
            'libomp', 'libpng', 'libtiff', 'openblas', 'openexr',
            'openmpi', 'openssl', 'pkg-config', 'readline',
            
            # Additional utilities
            'repomix', 'pstree', 'imagemagick', 'uv', 'fdupes',
            'sqlite3', 'tbb', 'tcl-tk', 'wget', 'xz', 'zlib',
            'libmediainfo', 'bc',
            
            # Development tools
            'autogen', 'bash', 'bzip2', 'cheat', 'python@3.10',
            'curl', 'diff-so-fancy', 'direnv', 'fd', 'fnm', 'fpp', 'fzf',
            'gcc', 'gh', 'git', 'gnu-indent', 'grep', 'gzip',
            'hub', 'jq', 'less', 'lesspipe', 'libxml2', 'lsof',
            'luarocks', 'luv', 'moreutils', 'neofetch', 'neovim', 'nnn', 'node',
            'pyenv', 'pyenv-virtualenv', 'pyenv-virtualenvwrapper',
            'ruby-build', 'rbenv', 'reattach-to-user-namespace',
            'ripgrep', 'rsync', 'screen', 'screenfetch', 'shellcheck',
            'shfmt', 'unzip', 'urlview', 'vim', 'watch', 'zsh', 'openssl@1.1'
        ]
        
        # Remove duplicates while preserving order
        packages = list(dict.fromkeys(packages))
        
        installed_count = 0
        missing_count = 0
        
        for package in packages:
            is_installed = self.check_brew_package(package)
            self.results['brew_packages'].append({
                'package': package,
                'installed': is_installed
            })
            
            if is_installed:
                self.print_success(f"{package}")
                installed_count += 1
            else:
                self.print_failure(f"{package} - NOT INSTALLED")
                missing_count += 1
        
        print(f"\n{Colors.BOLD}Summary:{Colors.ENDC} {installed_count}/{len(packages)} packages installed")
        if missing_count > 0:
            print(f"{Colors.RED}{missing_count} packages missing{Colors.ENDC}")
    
    def check_all_sheldon(self):
        """Check sheldon installation"""
        self.print_header("Checking Sheldon")
        
        result = self.check_sheldon()
        self.results['sheldon'] = result
        
        if result['installed']:
            self.print_success(f"Sheldon is installed")
            print(f"  Location: {result['location']}")
            print(f"  Version: {result['version']}")
            
            if result['location_correct']:
                self.print_success(f"Location is correct (~/.local/bin/sheldon)")
            else:
                self.print_warning(f"Location is not ~/.local/bin/sheldon")
            
            if result['version_correct']:
                self.print_success(f"Version is correct (0.6.6)")
            else:
                self.print_warning(f"Version is not 0.6.6 (found: {result['version']})")
        else:
            self.print_failure("Sheldon is NOT installed")
            print(f"\n  Install with:")
            print(f"  curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | \\")
            print(f"    bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin --tag 0.6.6")
    
    def check_all_chezmoi(self):
        """Check chezmoi installation"""
        self.print_header("Checking Chezmoi")
        
        result = self.check_chezmoi()
        self.results['chezmoi'] = result
        
        if result['installed']:
            self.print_success(f"Chezmoi is installed")
            print(f"  Location: {result['location']}")
            print(f"  Version: {result['version']}")
        else:
            self.print_failure("Chezmoi is NOT installed")
            print(f"\n  Install with:")
            print(f"  sh -c \"$(curl -fsLS chezmoi.io/get)\" -- init -R --debug -v --apply https://github.com/bossjones/zsh-dotfiles.git")
    
    def check_all_asdf_tools(self):
        """Check all asdf-managed tools"""
        self.print_header("Checking ASDF-Managed Tools")
        
        # Expected tools and versions from asdf current output
        tools = {
            'github-cli': '2.35.0',
            'golang': '1.20.5',
            'helm-docs': '1.13.1',
            'helm': '3.14.2',
            'helmfile': '0.162.0',
            'k9s': '0.32.4',
            'kubectl': '1.26.12',
            'kubectx': '0.9.5',
            'kubetail': '1.6.20',
            'mkcert': '1.4.4',
            'neovim': '0.11.3',
            'opa': '0.62.1',
            'ruby': '3.2.1',
            'rye': '0.33.0',
            'shellcheck': '0.10.0',
            'shfmt': '3.7.0',
            'tmux': '3.5a',
            'yq': '4.34.1'
        }
        
        installed_count = 0
        correct_version_count = 0
        
        for tool, expected_version in tools.items():
            result = self.check_asdf_tool(tool, expected_version)
            self.results['asdf_tools'].append(result)
            
            if result['installed']:
                if result['version_correct']:
                    self.print_success(f"{tool} @ {result['current_version']}")
                    installed_count += 1
                    correct_version_count += 1
                else:
                    self.print_warning(f"{tool} @ {result['current_version']} (expected: {expected_version})")
                    installed_count += 1
            else:
                self.print_failure(f"{tool} - NOT INSTALLED (expected: {expected_version})")
        
        print(f"\n{Colors.BOLD}Summary:{Colors.ENDC} {installed_count}/{len(tools)} tools installed")
        print(f"{Colors.BOLD}Correct versions:{Colors.ENDC} {correct_version_count}/{len(tools)}")
    
    def generate_report(self):
        """Generate a summary report"""
        self.print_header("Final Report")
        
        # Count statistics
        brew_installed = sum(1 for pkg in self.results['brew_packages'] if pkg['installed'])
        brew_total = len(self.results['brew_packages'])
        
        asdf_installed = sum(1 for tool in self.results['asdf_tools'] if tool['installed'])
        asdf_correct = sum(1 for tool in self.results['asdf_tools'] if tool['version_correct'])
        asdf_total = len(self.results['asdf_tools'])
        
        print(f"Brew Packages: {brew_installed}/{brew_total} installed")
        print(f"ASDF Tools: {asdf_installed}/{asdf_total} installed ({asdf_correct} correct versions)")
        print(f"Sheldon: {'✓' if self.results['sheldon'].get('installed') else '✗'}")
        print(f"Chezmoi: {'✓' if self.results['chezmoi'].get('installed') else '✗'}")
        
        if self.failed_checks:
            print(f"\n{Colors.RED}{Colors.BOLD}Issues Found: {len(self.failed_checks)}{Colors.ENDC}")
            return 1
        else:
            print(f"\n{Colors.GREEN}{Colors.BOLD}All checks passed!{Colors.ENDC}")
            return 0
    
    def run_all_checks(self):
        """Run all environment checks"""
        print(f"{Colors.BOLD}Development Environment Checker{Colors.ENDC}")
        print(f"Checking installation status of packages and tools...\n")
        
        self.check_all_brew_packages()
        self.check_all_sheldon()
        self.check_all_chezmoi()
        self.check_all_asdf_tools()
        
        return self.generate_report()


def main():
    """Main entry point"""
    checker = EnvironmentChecker()
    exit_code = checker.run_all_checks()
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
