# boxy 📦

A fast command-line utility that draws Unicode boxes around text with proper emoji/Unicode width handling.

## Features

- ✨ Accurate Unicode/emoji width calculation
- 🎨 Multiple box styles (normal, rounded, double, heavy, ascii)
- 🌈 Colored borders and text with predefined color schemes
- 🎨 Text color control with auto-matching and explicit colors
- 🎭 Theme system with predefined visual styles
- 📋 Title and footer support with emoji/variable expansion
- 🎯 Icon decorations for content
- 📏 Fixed width boxes with smart content truncation
- 🔄 Pipeline integration with box stripping modes
- 🚀 Written in Rust for speed
- 📝 Handles multi-line text and ANSI color codes

## Installation

```bash
# Build from source
cargo build --release

# Deploy to local bin
./deploy.sh
```

## Usage

```bash
# Basic usage
echo "Hello World" | boxy

# With style and color
echo "Hello World" | boxy --style rounded --color blue
echo "Hello World" | boxy -s double -c red

# With title and footer
echo "Hello World" | boxy --title "🚀 My App" --footer "v1.0"
echo "Content" | boxy --title "Header" --footer "✅ Done"

# With icon decoration and text colors
echo "Important message" | boxy --icon "⚠️" --color yellow --text red
echo "Success!" | boxy --icon "✅" --color green --text auto  # Text matches box color

# Using themes (includes icon, color, and styling)
echo "Something went wrong" | boxy --theme error
echo "Build successful" | boxy --theme success --text auto

# Fixed width boxes
echo "This is a long message that will be truncated" | boxy --width 20

# Variable expansion in titles
export VERSION="v1.2.3"
echo "Build complete" | boxy --title "🏗️ Build $VERSION" --color green

# Multi-line text
echo -e "Line 1\nLine 2\nLine 3" | boxy

# Pipeline integration - strip box decoration
echo "Content" | boxy | boxy --no-boxy          # Preserves colors
echo "Content" | boxy | boxy --no-boxy=strict   # Pure ASCII output

# With emojis (handles width correctly!)
echo -e "🎉 Party Time\n🚀 Launch\n🔥 Fire" | boxy -s rounded -c orange
```

## Box Styles

- `normal` - Standard box drawing characters `┌─┐│└┘`
- `rounded` - Rounded corners `╭─╮│╰╯`
- `double` - Double lines `╔═╗║╚╝`
- `heavy` - Heavy lines `┏━┓┃┗┛`
- `ascii` - ASCII compatible `+-+|++`

## Colors & Text Styling

### Available Colors
- Basic: `red`, `green`, `blue`, `cyan`, `yellow`, `magenta`
- Extended: `red2`, `green2`, `blue2`, `purple`, `purple2`
- Special: `orange`, `deep`, `deep_green`
- Grays: `white`, `white2`, `grey`, `grey2`, `grey3`

### Text Colors (`--text`)
- Use any color from the list above: `--text red`, `--text blue2`
- Use `auto` to match box color: `--text auto`
- Omit flag for default terminal text color

### Themes
Predefined combinations of icon, color, and styling:
```bash
--theme error      # ❌ with red styling
--theme success    # ✅ with green styling  
--theme warn       # ⚠️ with orange styling
--theme info       # ℹ️ with blue styling
--theme debug      # 🐛 with dark green styling
# ... and many more
```

## Examples

```bash
# System info box with title  
echo -e "🦀 Rust powered\n⚡ Lightning fast\n🔒 Memory safe" | boxy --title "📦 boxy v0.5.0" -s rounded -c blue

# Error alert with themed styling and auto text color
echo "File not found: config.json" | boxy --theme error --text auto --title "🚨 Error"

# Status dashboard with custom text colors
echo -e "✅ Tests passing\n🔧 Build complete\n📦 Ready to deploy" | boxy --title "🎯 CI/CD Status" --footer "✅ All systems go" -c green --text white

# Mixed styling approach
echo "Deploy to production?" | boxy --theme warn --text auto --width 25

# Interactive menu
echo -e "1. Deploy to staging\n2. Deploy to production\n3. Rollback\n4. Exit" | boxy --title "🚀 Deployment Menu" -s rounded

# Pipeline processing
command_output | boxy --title "📋 Results" | tee results.txt
cat results.txt | boxy --no-boxy | grep "ERROR"
```

## Integration with Bash

Add to your `.bashrc` or script:

```bash
box() {
    echo "$1" | $HOME/.local/bin/odx/boxy "$@"
}

# Usage examples  
box "Hello World" -s rounded -c blue --text auto
box "Deploy complete" --theme success --text auto
box "Error occurred" --theme error --width 30
```

## Advanced Features

### Title and Footer
- Support emoji and environment variable expansion
- Auto-truncation with `...` when too long
- Centered alignment within box

### Icon Decoration
- Adds visual flair to first content line
- Supports emoji and colored characters

### Pipeline Integration
- `--no-boxy`: Strip box while preserving colors/formatting
- `--no-boxy=strict`: Pure ASCII output for script processing
- Perfect for command chains and text processing

## Why boxy?

Unlike bash-based box drawing tools, boxy correctly handles:
- Emoji width (🚀 = 2 columns)
- Unicode variation selectors
- Zero-width joiners
- CJK characters
- Mixed ASCII and Unicode content
- ANSI color preservation in pipeline modes

## License

MIT