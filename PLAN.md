# CentOS Script Migration Plan

## Overview
This plan outlines the step-by-step process to create CentOS equivalents of the existing Ubuntu chezmoi installation scripts. The goal is to maintain the same functionality while adapting package management and system-specific configurations for CentOS/RHEL environments.

## Phase 1: Analysis of Ubuntu Scripts
### Core Installation Scripts (High Priority)
1. **run_onchange_before_01-ubuntu-install-packages.sh.tmpl**
   - Purpose: Install essential system packages via apt
   - CentOS equivalent: Use dnf/yum package manager
   - Key changes: Package name mapping (apt → dnf), repository setup

2. **run_before-00-prereq-ubuntu.sh.tmpl**
   - Purpose: System prerequisites and initial setup
   - CentOS equivalent: Adapt for RHEL/CentOS system initialization
   - Key changes: Package manager commands, system paths

3. **run_before-00-prereq-ubuntu-pyenv.sh.tmpl**
   - Purpose: Python environment prerequisites
   - CentOS equivalent: Install Python development dependencies
   - Key changes: Development library package names

### Tool Installation Scripts (Medium Priority)
4. **run_onchange_before_02-ubuntu-install-asdf.sh.tmpl**
   - Purpose: Install asdf version manager
   - CentOS equivalent: Same installation method (git clone)
   - Key changes: Dependency packages via dnf

5. **run_onchange_before_02-ubuntu-install-fd.sh.tmpl**
   - Purpose: Install fd file finder tool
   - CentOS equivalent: Use EPEL repository or binary installation
   - Key changes: Repository setup, package names

6. **run_onchange_before_02-ubuntu-install-fnm.sh.tmpl**
   - Purpose: Install Fast Node Manager
   - CentOS equivalent: Same curl installation method
   - Key changes: Minimal (tool installs via curl)

7. **run_onchange_before_02-ubuntu-install-opencv-deps.sh.tmpl**
   - Purpose: Install OpenCV development dependencies
   - CentOS equivalent: Map multimedia/CV packages to CentOS
   - Key changes: Extensive package name mapping

8. **run_onchange_before_02-ubuntu-install-sheldon.sh.tmpl**
   - Purpose: Install Sheldon ZSH plugin manager
   - CentOS equivalent: Rust compilation or binary installation
   - Key changes: Rust toolchain setup if needed

9. **run_onchange_before_03-ubuntu-install-krew.sh.tmpl**
   - Purpose: Install kubectl krew plugin manager
   - CentOS equivalent: Same installation method
   - Key changes: Minimal (tool installs via script)

### Configuration Scripts (Medium Priority)
10. **run_onchange_after_50-ubuntu-install-asdf-plugins.sh.tmpl**
    - Purpose: Install asdf plugins and tools
    - CentOS equivalent: Same asdf commands
    - Key changes: None (asdf is cross-platform)

11. **run_after-00-adhoc-ubuntu.sh.tmpl**
    - Purpose: Post-installation adhoc tasks
    - CentOS equivalent: Adapt system-specific tasks
    - Key changes: System service management, paths

### Completion Scripts (Low Priority)
12. **run_onchange_before_99-ubuntu-write-completions.sh.tmpl**
    - Purpose: Generate shell completions
    - CentOS equivalent: Same completion generation
    - Key changes: Minimal (completions are universal)

## Phase 2: Package Mapping Strategy
### Core Package Manager Translation
- `apt update` → `dnf check-update` or `yum check-update`
- `apt install` → `dnf install` or `yum install`
- `apt-get` → `dnf` or `yum`

### Repository Management
- **EPEL Repository**: Essential for additional packages
- **PowerTools/CRB**: For development packages
- **RPM Fusion**: For multimedia packages

### Common Package Name Mappings
| Ubuntu Package | CentOS Package | Notes |
|---------------|----------------|-------|
| `build-essential` | `groupinstall "Development Tools"` | Meta package |
| `python3-dev` | `python3-devel` | Header files |
| `libssl-dev` | `openssl-devel` | SSL development |
| `pkg-config` | `pkgconf-pkg-config` | Build tool |
| `libbz2-dev` | `bzip2-devel` | Compression |
| `libffi-dev` | `libffi-devel` | Foreign function interface |

## Phase 3: Implementation Order (COMPLETED)
### Step 1: High Priority Scripts ✓
1. [x] Create `run_before-00-prereq-centos.sh.tmpl`
2. [x] Create `run_before-00-prereq-centos-pyenv.sh.tmpl`  
3. [x] Create `run_onchange_before_01-centos-install-packages.sh.tmpl`

### Step 2: Medium Priority Tool Installation ✓
4. [x] Create `run_onchange_before_02-centos-install-asdf.sh.tmpl`
5. [x] Create `run_onchange_before_02-centos-install-fd.sh.tmpl`
6. [x] Create `run_onchange_before_02-centos-install-fnm.sh.tmpl`
7. [x] Create `run_onchange_before_02-centos-install-opencv-deps.sh.tmpl`
8. [x] Create `run_onchange_before_02-centos-install-sheldon.sh.tmpl`
9. [x] Create `run_onchange_before_03-centos-install-krew.sh.tmpl`

### Step 3: Configuration and Completion Scripts ✓
10. [x] Create `run_onchange_after_50-centos-install-asdf-plugins.sh.tmpl`
11. [x] Create `run_after-00-adhoc-centos.sh.tmpl`
12. [x] Create `run_onchange_before_99-centos-write-completions.sh.tmpl`

## Phase 4: Template Integration
### Chezmoi Template Variables
- Use `{{ if eq .chezmoi.osRelease.id "centos" }}` conditions
- Support both CentOS 8/9 and RHEL 8/9
- Version detection: `{{ .chezmoi.osRelease.versionID }}`

### Cross-Platform Compatibility
- Maintain existing Ubuntu support
- Add CentOS-specific blocks in templates
- Test template rendering with `chezmoi execute-template`

## Phase 5: Testing Strategy
### Local Testing
- Use CentOS 9 container/VM for testing
- Verify package installations work correctly
- Test template rendering and execution

### Validation Steps
1. Template syntax validation: `chezmoi doctor`
2. Dry run: `chezmoi apply --dry-run`
3. Full installation test on clean CentOS system
4. Verify all tools are properly installed and functional

## Key Considerations
### CentOS Version Support
- **CentOS 9 Stream**: Primary target (latest)
- **CentOS 8 Stream**: Legacy support if needed
- **RHEL 8/9**: Commercial equivalent support

### Repository Requirements
- **EPEL**: Extra Packages for Enterprise Linux
- **PowerTools** (CentOS 8) / **CRB** (CentOS 9): Code Ready Builder
- **RPM Fusion**: Multimedia packages

### Potential Challenges
1. **Package availability**: Some packages may not exist in CentOS repos
2. **Compilation requirements**: May need to compile from source
3. **Repository setup**: Proper repo enablement crucial
4. **SELinux considerations**: May affect some installations
5. **Firewall settings**: Different from Ubuntu's ufw

## Success Criteria
- [x] All 12 CentOS scripts created and functional
- [ ] Template conditions properly isolate Ubuntu vs CentOS logic
- [ ] All tools install successfully on CentOS 9
- [ ] No conflicts with existing Ubuntu functionality
- [ ] Proper error handling and logging maintained

## Phase 6: Oracle Linux Support (COMPLETED)
### Template Configuration Updates
- [x] **Updated Sheldon Plugin Configuration**: Modified both `home/dot_sheldon/plugins.toml.tmpl` and `home/private_dot_config/sheldon/plugins.toml.tmpl`
  - Added Oracle Linux Server support alongside CentOS Linux for Red Hat-based plugins (salt, saltstack, docker, docker-compose, rust)
  - Extended CUDA plugin support to Oracle Linux Server (based on chezmoi data showing CUDA availability)
  - Added FZF shell integration support for Oracle Linux Server
  - Used `or` conditions to group Oracle Linux Server with appropriate distributions for plugin loading

### Oracle Linux Integration Notes
- Oracle Linux Server uses the same Red Hat-based ecosystem as CentOS
- CUDA support enabled based on system capabilities (`"cuda": true` in chezmoi data)  
- Plugin configuration now supports three major Linux distributions: Ubuntu, CentOS Linux, and Oracle Linux Server
- Template conditions use `{{ if (or (eq .chezmoi.osRelease.name "CentOS Linux") (eq .chezmoi.osRelease.name "Oracle Linux Server")) -}}` pattern