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
            'asdf_tools': [],
            'env_vars': []
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

    def parse_shell_config_for_var(self, var_name: str) -> Dict[str, str]:
        """Parse shell configuration files to find where a variable is defined

        Checks common shell configuration files for export statements or variable
        assignments. Returns a dictionary mapping file paths to the defined values.
        """
        import os
        import re

        # Common shell configuration files to check
        config_files = [
            Path.home() / '.zshrc',
            Path.home() / '.zprofile',
            Path.home() / '.bashrc',
            Path.home() / '.profile',
            Path.home() / '.bash_profile',
        ]

        found_in_files = {}

        # Regex patterns to match variable definitions
        # Matches: export VAR=value, export VAR="value", VAR=value
        patterns = [
            re.compile(rf'^\s*export\s+{var_name}=(["\']?)(.+?)\1\s*$', re.MULTILINE),
            re.compile(rf'^\s*{var_name}=(["\']?)(.+?)\1\s*$', re.MULTILINE),
        ]

        for config_file in config_files:
            if not config_file.exists():
                continue

            try:
                content = config_file.read_text()

                for pattern in patterns:
                    matches = pattern.findall(content)
                    if matches:
                        # Get the last match (in case variable is set multiple times)
                        value = matches[-1][1] if isinstance(matches[-1], tuple) else matches[-1]
                        found_in_files[str(config_file)] = value
                        break  # Found in this file, move to next file

            except (IOError, PermissionError):
                # Skip files we can't read
                continue

        return found_in_files

    def check_env_var(self, var_name: str, expected_value: Optional[str] = None) -> Dict:
        """Check if an environment variable is set and optionally verify its value

        This method checks both:
        1. The current live environment (os.environ) - what's actually active
        2. Shell configuration files - where the variable should be defined

        Returns a comprehensive result showing both the current state and config state.
        """
        import os

        result = {
            'var_name': var_name,
            'expected_value': expected_value,
            'is_set': False,
            'current_value': None,
            'value_correct': False,
            'defined_in_configs': {},  # Maps file path to defined value
            'in_config_files': False,
            'config_value_correct': False
        }

        # Check current live environment
        current_value = os.environ.get(var_name)

        if current_value is not None:
            result['is_set'] = True
            result['current_value'] = current_value

            if expected_value is not None:
                # Handle $HOME expansion in expected value
                if '$HOME' in expected_value or '~' in expected_value:
                    home = os.path.expanduser('~')
                    expanded_expected = expected_value.replace('$HOME', home).replace('~', home)
                    result['value_correct'] = current_value == expanded_expected
                else:
                    result['value_correct'] = current_value == expected_value
            else:
                # If no expected value specified, just being set is correct
                result['value_correct'] = True

        # Check shell configuration files
        config_definitions = self.parse_shell_config_for_var(var_name)
        result['defined_in_configs'] = config_definitions
        result['in_config_files'] = len(config_definitions) > 0

        # Check if any config file has the correct value
        if expected_value is not None and config_definitions:
            for file_path, config_value in config_definitions.items():
                # Handle $HOME expansion for comparison
                if '$HOME' in expected_value or '~' in expected_value:
                    home = os.path.expanduser('~')
                    expanded_expected = expected_value.replace('$HOME', home).replace('~', home)
                    # Also check if config file has unexpanded version
                    if config_value == expected_value or config_value == expanded_expected:
                        result['config_value_correct'] = True
                        break
                else:
                    if config_value == expected_value:
                        result['config_value_correct'] = True
                        break

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
            'open-mpi', 'openssl@3', 'pkgconf', 'readline',

            # Additional utilities
            'repomix', 'pstree', 'imagemagick', 'uv', 'fdupes',
            'sqlite', 'tbb', 'tcl-tk', 'wget', 'xz', 'zlib',
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

    def check_all_envs(self):
        """Check all required environment variables

        This function verifies that all necessary environment variables for the
        zsh-dotfiles development environment are properly set with correct values.
        It checks each variable in TWO places:
        1. Current live environment (what's actively loaded in this shell session)
        2. Shell configuration files (~/.zshrc, ~/.zprofile, ~/.bashrc, ~/.profile)

        This dual-check ensures variables are both currently active AND persisted
        in config files for future shell sessions.
        """
        # Print a formatted header to clearly identify this section of checks
        self.print_header("Checking Environment Variables")

        # Define required environment variables with their expected values
        # These variables control various aspects of the zsh-dotfiles environment:
        # - ZSH_DOTFILES_PREP_CI: Enables CI mode for automated testing
        # - ZSH_DOTFILES_PREP_DEBUG: Enables debug output for troubleshooting
        # - ZSH_DOTFILES_PREP_GITHUB_USER: Sets the GitHub username for repo operations
        # - ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE: Skips brew bundle installation (for speed)
        # - SHELDON_CONFIG_DIR: Directory where Sheldon plugin manager stores configs
        # - SHELDON_DATA_DIR: Directory where Sheldon plugin manager stores data
        env_vars = {
            'ZSH_DOTFILES_PREP_CI': '1',
            'ZSH_DOTFILES_PREP_DEBUG': '1',
            'ZSH_DOTFILES_PREP_GITHUB_USER': 'bossjones',
            'ZSH_DOTFILES_PREP_SKIP_BREW_BUNDLE': '1',
            'SHELDON_CONFIG_DIR': '$HOME/.sheldon',
            'SHELDON_DATA_DIR': '$HOME/.sheldon'
        }

        # Initialize the results storage for environment variables if not already present
        # This ensures we have a place to store the check results for later use
        if 'env_vars' not in self.results:
            self.results['env_vars'] = []

        # Initialize counters to track the status of environment variables
        # live_set_count: How many variables are set in current environment
        # live_correct_count: How many have correct values in current environment
        # config_count: How many are defined in shell config files
        # config_correct_count: How many have correct values in config files
        live_set_count = 0
        live_correct_count = 0
        config_count = 0
        config_correct_count = 0

        # Iterate through each environment variable and check its status
        for var_name, expected_value in env_vars.items():
            # Check the individual environment variable and get detailed result
            # This checks BOTH live environment AND config files
            result = self.check_env_var(var_name, expected_value)

            # Store the result for later reference and reporting
            self.results['env_vars'].append(result)

            # Display live environment status
            if result['is_set']:
                # Variable is set in live environment
                live_set_count += 1

                if result['value_correct']:
                    # Variable has the correct value in live environment
                    self.print_success(f"{var_name} = {result['current_value']} (live)")
                    live_correct_count += 1
                else:
                    # Variable is set but has wrong value in live environment
                    self.print_warning(f"{var_name} = {result['current_value']} (live, expected: {expected_value})")
            else:
                # Variable is not set in live environment
                self.print_failure(f"{var_name} - NOT SET in live environment (expected: {expected_value})")

            # Display config file status
            if result['in_config_files']:
                config_count += 1
                # Show where the variable is defined in config files
                for config_file, config_value in result['defined_in_configs'].items():
                    short_path = config_file.replace(str(Path.home()), '~')

                    if result['config_value_correct']:
                        print(f"  {Colors.GREEN}↳{Colors.ENDC} Defined in {short_path}: {config_value}")
                        if var_name not in [r['var_name'] for r in self.results['env_vars'][:-1]]:
                            config_correct_count += 1
                    else:
                        print(f"  {Colors.YELLOW}↳{Colors.ENDC} Defined in {short_path}: {config_value} (expected: {expected_value})")
            else:
                # Variable not found in any config file
                print(f"  {Colors.RED}↳{Colors.ENDC} NOT defined in shell config files")

            print()  # Add blank line between variables for readability

        # Properly count config correct values
        config_correct_count = sum(1 for var in self.results['env_vars'] if var['config_value_correct'])

        # Print summary statistics showing status in both live and config
        print(f"{Colors.BOLD}Live Environment Summary:{Colors.ENDC}")
        print(f"  Variables set: {live_set_count}/{len(env_vars)}")
        print(f"  Correct values: {live_correct_count}/{len(env_vars)}")

        print(f"\n{Colors.BOLD}Config Files Summary:{Colors.ENDC}")
        print(f"  Variables defined: {config_count}/{len(env_vars)}")
        print(f"  Correct values: {config_correct_count}/{len(env_vars)}")

        # If any variables are missing or incorrect, provide helpful export commands
        # This gives the user ready-to-use commands to fix their environment
        if live_correct_count < len(env_vars) or config_correct_count < len(env_vars):
            print(f"\n{Colors.YELLOW}{Colors.BOLD}Recommendations:{Colors.ENDC}")

            # Show which variables need attention
            needs_live_fix = []
            needs_config_fix = []

            for result in self.results['env_vars']:
                if not result['value_correct']:
                    needs_live_fix.append(result)
                if not result['config_value_correct']:
                    needs_config_fix.append(result)

            # If variables are missing from config files, show how to add them permanently
            if needs_config_fix:
                print(f"\n{Colors.YELLOW}Add these to your ~/.zshrc or ~/.bashrc for persistence:{Colors.ENDC}")
                print()

                for result in needs_config_fix:
                    expected = result['expected_value']
                    # Add quotes around values containing $HOME to preserve the variable reference
                    if '$HOME' in expected:
                        print(f'export {result["var_name"]}="{expected}"')
                    else:
                        print(f'export {result["var_name"]}={expected}')

            # If variables are missing from live environment, show how to set them temporarily
            if needs_live_fix:
                print(f"\n{Colors.YELLOW}Set these temporarily in your current shell (until next shell restart):{Colors.ENDC}")
                print()

                for result in needs_live_fix:
                    expected = result['expected_value']
                    # Add quotes around values containing $HOME to preserve the variable reference
                    if '$HOME' in expected:
                        print(f'export {result["var_name"]}="{expected}"')
                    else:
                        print(f'export {result["var_name"]}={expected}')

                print(f"\n{Colors.YELLOW}Then reload your shell or run: source ~/.zshrc{Colors.ENDC}")


    def generate_report(self):
        """Generate a summary report"""
        self.print_header("Final Report")

        # Count statistics
        brew_installed = sum(1 for pkg in self.results['brew_packages'] if pkg['installed'])
        brew_total = len(self.results['brew_packages'])

        asdf_installed = sum(1 for tool in self.results['asdf_tools'] if tool['installed'])
        asdf_correct = sum(1 for tool in self.results['asdf_tools'] if tool['version_correct'])
        asdf_total = len(self.results['asdf_tools'])

        # Environment variables statistics
        env_set = 0
        env_correct = 0
        env_total = 0
        if 'env_vars' in self.results:
            env_set = sum(1 for var in self.results['env_vars'] if var['is_set'])
            env_correct = sum(1 for var in self.results['env_vars'] if var['value_correct'])
            env_total = len(self.results['env_vars'])

        print(f"Brew Packages: {brew_installed}/{brew_total} installed")
        print(f"ASDF Tools: {asdf_installed}/{asdf_total} installed ({asdf_correct} correct versions)")
        print(f"Environment Variables: {env_set}/{env_total} set ({env_correct} correct values)")
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
        # self.check_all_asdf_tools()
        self.check_all_envs()

        return self.generate_report()


def main():
    """Main entry point"""
    checker = EnvironmentChecker()
    exit_code = checker.run_all_checks()
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
