# SEMV - Semantic Version Manager

**Version**: 2.0.0-dev_1  
**Architecture**: BashFX v1.9 Compliant  
**Languages**: Rust, JavaScript, Python, Bash  

A powerful semantic versioning automation tool that manages git tags, analyzes commit patterns, and synchronizes versions across multiple project formats. SEMV bridges the gap between git-based version control and package manager version requirements.

## 🚀 Features

### Core Capabilities
- **Automated Versioning**: Analyzes commit messages to determine appropriate version bumps
- **Multi-Language Sync**: Keeps git tags, package files, and build artifacts in sync
- **BashFX Compliance**: Full integration with BashFX framework standards
- **Developer Workflow**: Seamlessly integrates into existing git workflows

### Supported Project Types
- **Rust**: `Cargo.toml` version synchronization
- **JavaScript/Node.js**: `package.json` version synchronization  
- **Python**: `pyproject.toml` version synchronization
- **Bash**: Script metadata version synchronization

### Advanced Features
- **Build Cursor**: Automatic `.build` file generation with version metadata
- **Pre-commit Hooks**: Validation and auto-sync before commits
- **Release Automation**: Full release workflow with sync integration
- **Version Drift Detection**: Identify and resolve version mismatches

## 📦 Installation

### BashFX Installation (Recommended)
```bash
# Install to BashFX system
semv install

# Verify installation
semv status
```

### Manual Installation
```bash
# Copy to local bin
cp semv.sh ~/.local/bin/semv
chmod +x ~/.local/bin/semv

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

## 🎯 Quick Start

### Initialize a Repository
```bash
# Initialize semver in a new repository
semv new

# Check if repository can use semver
semv can
```

### Basic Version Management
```bash
# Show current version
semv

# Calculate next version (dry run)
semv next

# Bump version and create tag
semv bump

# Show repository status
semv info
```

### Multi-Language Sync
```bash
# Auto-detect and sync all sources
semv sync

# Sync specific project type
semv sync rust      # Cargo.toml
semv sync js        # package.json  
semv sync python    # pyproject.toml
semv sync bash      # Script metadata

# Check sync status
semv validate

# Show version drift
semv drift
```

## 📝 Commit Message Conventions

SEMV uses commit message prefixes to determine version bumps:

| Prefix | Impact | Version Change | Example |
|--------|--------|----------------|---------|
| `brk:` | Breaking Change | Major (x.0.0) | `brk: remove deprecated API` |
| `feat:` | New Feature | Minor (x.y.0) | `feat: add user authentication` |
| `fix:` | Bug Fix | Patch (x.y.z) | `fix: handle null pointer exception` |
| `dev:` | Development Note | Dev Build | `dev: refactor validation logic` |

### Example Workflow
```bash
# Make changes and commit with proper prefix
git add .
git commit -m "feat: add multi-language sync support"

# Bump version based on commit history
semv bump
# Result: v1.2.0 -> v1.3.0 (minor bump for new feature)
```

## 🔄 Sync Workflow

### The "Highest Version Wins" Model

When conflicts exist between different version sources, SEMV uses the highest semantic version as the source of truth and updates all other sources to match.

**Sync Priority**:
1. Manual user input (explicit version)
2. Package file versions (Cargo.toml, package.json, etc.)
3. Git tag history
4. Build cursor (.build file)

### Example Sync Scenario
```bash
# Current state:
# - Git tags: v1.2.3
# - Cargo.toml: version = "1.2.5"  
# - package.json: "version": "1.2.1"

semv sync
# Result: All sources updated to v1.2.5 (highest version)
# - Git tag: v1.2.5 (created)
# - Cargo.toml: version = "1.2.5" (unchanged)
# - package.json: "version": "1.2.5" (updated)
```

## 🛠️ Configuration

### Environment Variables
```bash
# Disable build cursor generation
export NO_BUILD_CURSOR=1

# Enable quiet mode
export QUIET_MODE=1

# Enable debug mode  
export DEBUG_MODE=1
```

### Configuration File
Located at `~/.local/etc/fx/semv/config`:
```bash
# Commit label configuration
SEMV_MAJ_LABEL="brk"
SEMV_FEAT_LABEL="feat"
SEMV_FIX_LABEL="fix"
SEMV_DEV_LABEL="dev"

# Build configuration
SEMV_MIN_BUILD=1000

# Default options
DEFAULT_DEBUG=1
DEFAULT_NO_CURSOR=1
```

## 🎛️ Command Reference

### Version Operations
```bash
semv                    # Show current version (default)
semv next               # Calculate next version (dry run)
semv bump               # Create and push new version tag
semv tag                # Show latest semantic version tag
```

### Project Analysis
```bash
semv info               # Show repository and version status
semv pend               # Show pending changes since last tag
semv since              # Time since last commit
semv status             # Show working directory status
```

### Synchronization
```bash
semv sync               # Auto-detect and sync all sources
semv sync rust          # Sync with Cargo.toml
semv sync js            # Sync with package.json
semv sync python        # Sync with pyproject.toml
semv sync bash          # Sync with script metadata
semv validate           # Check all sources are in sync
semv drift              # Show version mismatches
```

### Build Operations
```bash
semv file               # Generate build info file
semv bc                 # Show current build count
```

### Repository Management
```bash
semv new                # Initialize repo with v0.0.1
semv can                # Check if repo can use semver
semv fetch              # Fetch remote tags
```

### Workflow Automation
```bash
semv pre-commit         # Pre-commit validation hook
semv release            # Full release workflow
```

### Lifecycle Management
```bash
semv install            # Install to BashFX system
semv uninstall          # Remove from system
semv reset              # Reset configuration
semv status             # Show installation status
```

## 🚩 Flags

### Logging & Output
| Flag | Description |
|------|-------------|
| `-d` | Enable debug messages |
| `-t` | Enable trace messages |
| `-q` | Quiet mode (errors only) |
| `-D` | Master dev flag (enables -d, -t) |

### Behavior Control
| Flag | Description |
|------|-------------|
| `-f` | Force operations |
| `-y` | Auto-answer yes to prompts |
| `--no-cursor` | Disable .build file creation |

## 📁 Project Structure

### XDG+ Compliant Directory Layout
```
~/.local/fx/semv/           # Main installation
├── semv.sh                 # Main script
├── config/                 # Configuration files
├── data/                   # Data and templates
└── .semv.rc               # Session state file

~/.local/bin/semv          # Symlink to main script
```

### Build Cursor Format
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

## 🔧 Development

### Modular Architecture
SEMV is built using a modular architecture with 16 components:

```
semv-template.sh        # Assembly template
semv-config.sh          # Configuration and constants
semv-colors.sh          # BashFX standard colors
semv-printers.sh        # Output functions
semv-options.sh         # Flag parsing
semv-guards.sh          # Validation functions
semv-git-ops.sh         # Git operations
semv-version.sh         # Version parsing/comparison
semv-semver.sh          # Core semver logic
semv-lifecycle.sh       # Installation management
semv-commands.sh        # High-order commands
semv-sync-detect.sh     # Project detection
semv-sync-parsers.sh    # Version parsing/writing
semv-sync-commands.sh   # Sync orchestration
semv-sync-integration.sh # Workflow integration
semv-dispatch.sh        # Command routing
```

### BashFX Compliance
- **Function Ordinality**: `do_*` (high-order), `_*` (helpers), `__*` (literals)
- **Stream Usage**: stderr for messages, stdout for capture
- **XDG+ Paths**: All files in standard locations
- **Predictable Variables**: `ret`, `res`, `path`, `curr`, etc.

## 🐛 Troubleshooting

### Common Issues

**Version Drift Detected**
```bash
# Check what's out of sync
semv drift

# Auto-sync all sources
semv sync
```

**No Semver Tags Found**
```bash
# Initialize repository
semv new

# Or check if in git repository
semv can
```

**Build Cursor Disabled**
```bash
# Enable build cursor
unset NO_BUILD_CURSOR

# Or use flag
semv file --no-cursor=false
```

### Debug Mode
```bash
# Enable verbose output
semv -d info

# Enable trace output  
semv -t bump

# Master debug mode
semv -D sync
```

## 📄 License

This project follows BashFX architecture standards and is part of the BashFX ecosystem.

## 🤝 Contributing

1. Follow BashFX coding standards
2. Maintain function ordinality patterns
3. Use predictable variable naming
4. Include proper error handling
5. Test with multiple project types

## 📚 See Also

- [BashFX Architecture Documentation](BASHFX.v.1.9.md)
- [Command Reference](COMMANDS.md)
- [Development Guide](DEVELOPMENT.md)

---

**SEMV v2.0** - Transforming version management with multi-language synchronization 🚀