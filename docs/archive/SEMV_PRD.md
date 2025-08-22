# SEMV_PRD.md (PRD)

**Version**: 2.0.0  
**Date**: 2025-08-15  
**Status**: Development  
**Architecture**: BashFX v1.9 Compliant  

---

## 1. Product Overview

### 1.1 Purpose
SEMV is a semantic versioning automation tool that manages git tags, analyzes commit patterns, and synchronizes versions across multiple project formats. It bridges the gap between git-based version control and package manager version requirements.

### 1.2 Core Value Proposition
- **Automated Versioning**: Analyzes commit messages to determine appropriate version bumps
- **Multi-Language Sync**: Keeps git tags, package files, and build artifacts in sync
- **Developer Workflow**: Integrates seamlessly into existing git workflows
- **BashFX Compliance**: Full integration with BashFX framework standards

### 1.3 Target Users
- **Primary**: Developers working on Rust, JavaScript, Python, and Bash projects
- **Secondary**: DevOps engineers managing version automation in CI/CD pipelines
- **Tertiary**: Project maintainers requiring consistent versioning across repositories

---

## 2. Core Concepts & Conventions

### 2.1 Semantic Versioning Model
SEMV follows semantic versioning (SemVer 2.0.0) with BashFX extensions:

| Format | Example | Use Case |
|--------|---------|----------|
| **Release** | `v1.2.3` | Production releases |
| **Dev Build** | `v1.2.3-dev_5` | Development iterations |
| **Build Number** | `v1.2.3-build_1247` | CI/CD automation |

### 2.2 Commit Message Conventions
Version bumps are determined by commit message prefixes:

| Prefix | Impact | Version Change | Example |
|--------|--------|----------------|---------|
| `brk:` | Breaking Change | Major (x.0.0) | `brk: remove deprecated API` |
| `feat:` | New Feature | Minor (x.y.0) | `feat: add user authentication` |
| `fix:` | Bug Fix | Patch (x.y.z) | `fix: handle null pointer exception` |
| `dev:` | Development Note | Dev Build | `dev: refactor validation logic` |

### 2.3 Project Detection
SEMV auto-detects project types by scanning for:

| Language | Detection File | Version Location |
|----------|----------------|------------------|
| **Rust** | `Cargo.toml` | `version = "1.2.3"` |
| **JavaScript** | `package.json` | `"version": "1.2.3"` |
| **Python** | `pyproject.toml` | `version = "1.2.3"` |
| **Bash** | Script header | `# version: 1.2.3` |

### 2.4 Version Synchronization
**Highest Version Wins**: When conflicts exist, the highest semantic version becomes the source of truth, and all other sources are updated to match.

**Sync Priority**:
1. Manual user input (explicit version)
2. Package file versions (Cargo.toml, package.json, etc.)
3. Git tag history
4. Build cursor (.build file)

---

## 3. Command Surface & Interface

### 3.1 Standard Command Pattern
```bash
semv [command] [arguments] [flags]
```

### 3.2 Core Commands

#### **Version Operations**
| Command | Description | Example |
|---------|-------------|---------|
| `semv` | Show current version (default) | `semv` → `v1.2.3` |
| `semv next` | Calculate next version (dry run) | `semv next` → `v1.2.4` |
| `semv bump` | Create and push new version tag | `semv bump` |
| `semv tag` | Show latest semantic version tag | `semv tag` |

#### **Project Analysis**
| Command | Description | Example |
|---------|-------------|---------|
| `semv info` | Show repository and version status | `semv info` |
| `semv pend` | Show pending changes since last tag | `semv pend` |
| `semv chg` | Count changes by type since tag | `semv chg` |
| `semv since` | Time since last commit | `semv since` |

#### **Synchronization**
| Command | Description | Example |
|---------|-------------|---------|
| `semv sync` | Auto-detect and sync all sources | `semv sync` |
| `semv sync rust` | Sync with Cargo.toml | `semv sync rust` |
| `semv sync js` | Sync with package.json | `semv sync js` |
| `semv sync python` | Sync with pyproject.toml | `semv sync python` |
| `semv sync bash` | Sync with script meta comments | `semv sync bash` |
| `semv validate` | Check all sources are in sync | `semv validate` |
| `semv drift` | Show version mismatches | `semv drift` |

#### **Build & CI Integration**
| Command | Description | Example |
|---------|-------------|---------|
| `semv file` | Generate build info file | `semv file` → `.build` |
| `semv bc` | Show current build count | `semv bc` → `1247` |
| `semv fwd` | Check if version bump available | `semv fwd` |
| `semv upst` | Compare with remote tags | `semv upst` |

#### **Repository Management**
| Command | Description | Example |
|---------|-------------|---------|
| `semv new` | Initialize repo with v0.0.1 | `semv new` |
| `semv can` | Check if repo can use semver | `semv can` |
| `semv fetch` | Fetch remote tags | `semv fetch` |
| `semv snip` | Clean up minor version tags | `semv snip` |

#### **Workflow Automation**
| Command | Description | Example |
|---------|-------------|---------|
| `semv pre-commit` | Validate before commit | `semv pre-commit` |
| `semv release` | Full release workflow | `semv release` |
| `semv audit` | Full version health check | `semv audit` |

#### **Lifecycle Management**
| Command | Description | Example |
|---------|-------------|---------|
| `semv install` | Install to BashFX system | `semv install` |
| `semv uninstall` | Remove from system | `semv uninstall` |
| `semv reset` | Reset configuration | `semv reset` |
| `semv status` | Show installation status | `semv status` |

### 3.3 Standard Flags

#### **Logging & Output**
| Flag | Variable | Description |
|------|----------|-------------|
| `-d` | `opt_debug` | Enable first-level verbose messages |
| `-t` | `opt_trace` | Enable second-level trace messages |
| `-q` | `opt_quiet` | Silence all output except errors |
| `-D` | `opt_dev` | Master developer flag (enables -d, -t) |

#### **Behavior Control**
| Flag | Variable | Description |
|------|----------|-------------|
| `-f` | `opt_force` | Bypass safety guards |
| `-y` | `opt_yes` | Auto-answer yes to prompts |
| `--no-cursor` | `opt_no_cursor` | Disable .build file creation |

#### **Build Options**
| Flag | Variable | Description |
|------|----------|-------------|
| `-N` | `opt_dev_note` | Enable dev note mode |
| `-B` | `opt_build_dir` | Use ./build/ directory |

---

## 4. BashFX Requirements Compliance

### 4.1 Architecture Principles
- ✅ **Self-Contained**: All files in XDG+ compliant paths
- ✅ **Invisible**: No dotfiles in $HOME
- ✅ **Rewindable**: Clean install/uninstall lifecycle
- ✅ **Confidable**: No external dependencies, no phone home
- ✅ **Friendly**: Clear visual feedback with colors/symbols
- ✅ **Self-Reliance**: Built with bash, sed, awk, grep only
- ✅ **Transparency**: Clear, inspectable actions

### 4.2 XDG+ Directory Structure
```
${XDG_HOME}/fx/semv/           # Main installation
├── semv.sh                    # Main script
├── config/                    # Configuration files
├── data/                      # Data and templates
└── .semv.rc                   # Session state file

${XDG_BIN}/semv               # Symlink to main script
```

### 4.3 Function Ordinality Compliance
| Type | Prefix | Responsibility | Example |
|------|--------|----------------|---------|
| **Super-Ordinal** | `main`, `dispatch` | Core orchestration | `main()`, `dispatch()` |
| **High-Order** | `do_*` | User interaction, guards | `do_bump()`, `do_sync()` |
| **Mid-Level** | `_*` | Business logic helpers | `_parse_commits()` |
| **Low-Level** | `__*` | System operations | `__git_tag_create()` |

### 4.4 Standard Interface Requirements
- ✅ **`main()`**: Primary entrypoint and lifecycle orchestrator
- ✅ **`dispatch()`**: Command router to `do_*` functions
- ✅ **`usage()`**: Independent help function
- ✅ **`options()`**: Flag parsing and `opt_*` variable setting
- ✅ **Predictable Variables**: `ret`, `res`, `str`, `path`, `curr`, etc.

### 4.5 Stream Usage Standards
- **stderr**: All human-readable messages (`info`, `warn`, `error`)
- **stdout**: Machine-capturable data for `$(semv tag)` usage
- **Silenceability**: Respect `opt_quiet`, `opt_debug`, `opt_trace` flags

---

## 5. Technical Specifications

### 5.1 Dependencies
**Required**:
- bash 4.0+
- git 2.0+
- Standard POSIX utilities: sed, awk, grep, sort

**Optional**:
- BashFX framework (for enhanced features)
- Terminal with 256-color support (for optimal display)

### 5.2 Version Pattern Matching
```bash
# Standard semantic version regex
^v?([0-9]+)\.([0-9]+)\.([0-9]+)(-.+)?$

# Supported formats
v1.2.3           # Standard release
v1.2.3-dev_5     # Development build
v1.2.3-build_123 # CI build number
1.2.3            # Package manager format
```

### 5.3 Build Cursor Format
```bash
# .build file contents
DEV_VERS=v1.2.3
DEV_BUILD=1247
DEV_BRANCH=main
DEV_DATE=08/15/25
DEV_SEMVER=v1.2.4-dev_2
SYNC_SOURCE=cargo
SYNC_VERSION=1.2.3
SYNC_DATE=2025-08-15T10:30:00Z
```

### 5.4 Performance Requirements
- **Startup Time**: < 100ms for basic commands
- **Analysis Time**: < 500ms for commit analysis (100 commits)
- **Memory Usage**: < 10MB peak memory consumption
- **File Operations**: Atomic writes with backup/restore

---

## 6. Error Handling & Edge Cases

### 6.1 Repository State Validation
- **Missing .git directory**: Graceful error with helpful message
- **No commits**: Guide user through initial setup
- **Detached HEAD**: Warn and suggest checkout
- **Uncommitted changes**: Configurable warnings/blocks

### 6.2 Version Conflict Resolution
- **Invalid semantic versions**: Parse or reject with clear message
- **Future versions**: Handle dates/times in version strings
- **Multiple project types**: Prioritize by detection order
- **Missing package files**: Create with template if requested

### 6.3 Git Operation Safety
- **Network failures**: Graceful degradation for remote operations
- **Permission issues**: Clear error messages for git operations
- **Tag conflicts**: Backup existing tags before force operations
- **Branch protection**: Respect branch protection rules

---

## 7. Success Metrics

### 7.1 Functional Requirements
- ✅ **100% Backward Compatibility**: All existing semv 1.x commands work
- ✅ **Multi-Language Support**: Rust, JavaScript, Python, Bash sync works
- ✅ **BashFX Compliance**: Passes all architecture requirements
- ✅ **Zero Data Loss**: No git history corruption during operations

### 7.2 User Experience Requirements
- ✅ **Intuitive Commands**: New users can accomplish basic tasks
- ✅ **Clear Feedback**: Visual indicators for all operations
- ✅ **Fast Performance**: Sub-second response for common operations
- ✅ **Reliable Automation**: Works consistently in CI/CD environments

### 7.3 Quality Requirements
- ✅ **Test Coverage**: >90% code coverage with integration tests
- ✅ **Documentation**: Complete usage examples and troubleshooting
- ✅ **Error Handling**: Graceful failure with recovery suggestions
- ✅ **Security**: No credential leakage or unsafe operations

---

## 8. Future Roadmap

### 8.1 Phase 2 Enhancements
- Workspace/monorepo support
- Custom version pattern configuration
- Integration with more package managers (Go modules, Maven, etc.)
- Advanced conflict resolution strategies

### 8.2 Integration Opportunities
- IDE plugins and extensions
- GitHub Actions integration
- Docker container versioning
- Release note generation

### 8.3 Advanced Features
- Semantic analysis of code changes
- Automatic changelog generation
- Version deprecation management
- Cross-repository version coordination

---

**Document Status**: ✅ Complete  
**Next Step**: Create SESSION tracking file and begin Phase 1 implementation