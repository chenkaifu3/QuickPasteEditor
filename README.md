# QuickPasteEditor - macOS Clipboard Manager & Text Editor

A lightweight macOS native clipboard manager and text editor with clipboard history, rich text preview, and quick editing capabilities.

## Features

- 🚀 **Fast & Responsive**: Clean interface with smooth performance
- 📋 **Clipboard History**: Automatically tracks up to 200 clipboard entries
- 📝 **Text Editing**: Full-featured text editor with live word/line count
- 📊 **Rich Content Support**: Plain text, RTF/RTFD, and images (PNG/TIFF)
- 🎛️ **Customizable**: Adjustable font size (10-36pt) and preview height
- 🔄 **Smart Filtering**: Prevents internal copy operations from duplicating history
- 🎨 **Interactive Feedback**: Animated toolbar buttons with bounce effects
- ⌨️ **Keyboard Shortcuts**: Standard Cmd+C/V/X/A support
- 🗂️ **Multi-Select**: Select multiple history entries for batch deletion
- 💾 **Persistent Storage**: History auto-saves and restores on restart

## System Requirements

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools or Xcode 15.0+

## Quick Start

### Building from Source

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Build using Swift Package Manager
swift build -c release

# Run the app
./.build/release/QuickPasteEditor
```

### Creating an App Bundle

The included Python script helps create a macOS app bundle:

```bash
# Build and package the app
swift build -c release
python3 make_icon_transparent.py  # Optional: customize icon
# Manually create app bundle or use packaging tools
```

## Usage

### Toolbar Buttons

- **Copy Text**: Copy editor content to clipboard (won't re-capture to history)
- **Copy Selected**: Restore selected history entry (with RTF/images) to clipboard
- **Delete**: Delete selected history entries (supports multi-select)
- **Clear History**: Remove all clipboard history
- **Font Size**: Adjust editor font size (10-36pt)

### Keyboard Shortcuts

- **Cmd+C**: Copy from editor (won't trigger history capture)
- **Cmd+V**: Paste into editor
- **Cmd+X**: Cut from editor
- **Cmd+A**: Select all in editor
- **Delete**: Remove selected history entries
- **Cmd/Shift+Click**: Multi-select history entries
- **Arrow Keys**: Navigate history list

### How It Works

1. **Auto-Capture**: Monitors system clipboard every 0.8s
2. **Smart Filtering**: Ignores internal copies, files/folders, and duplicates
3. **Rich Preview**: Displays formatted text and images
4. **Quick Edit**: Click any history entry to load into editor
5. **Persistent**: History saves to `~/Library/Application Support/QuickPasteEditor/`

## Project Structure

```
QuickPasteEditor/
├── Package.swift                    # Swift package configuration
├── Sources/
│   ├── QuickPasteEditorApp.swift   # App entry point
│   ├── ContentView.swift            # Main UI view
│   └── Resources/
│       ├── Info.plist              # App metadata
│       ├── AppIcon.icns            # App icon
│       └── AppIcon.iconset/        # Icon source files
├── make_icon_transparent.py        # Icon generation script
└── README.md                       # This file
```

## Technical Details

### Core Technologies

- **SwiftUI**: Modern declarative UI framework
- **NSPasteboard**: System clipboard access
- **Combine**: Reactive programming for clipboard monitoring
- **JSONEncoder/Decoder**: History persistence

### Key Features Implementation

- **Multi-Select**: Uses `Set<ClipboardEntry.ID>` for selection state
- **Smart Capture**: Notification-based suppression for internal copies
- **History Loading**: Automatically selects newest file among multiple candidates
- **Animated Buttons**: Custom `ToolbarButton` view with spring animations
- **Preview**: Dual-mode display for text/RTF content and images

## Troubleshooting

### Swift Compiler Version Mismatch

If you see errors like:
```
failed to build module 'Foundation'; this SDK is not supported by the compiler
```

**Solutions**:
1. Update Command Line Tools:
   ```bash
   sudo rm -rf /Library/Developer/CommandLineTools
   xcode-select --install
   ```

2. Or use full Xcode:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

### Clipboard Access Permissions

First run may request clipboard access. Grant permission in:
1. System Settings → Privacy & Security → Accessibility
2. Add QuickPasteEditor to the allow list

### History Not Loading

- Check file permissions in `~/Library/Application Support/QuickPasteEditor/`
- Verify JSON file integrity
- App automatically selects newest history file if multiple exist

## Documentation

For detailed usage instructions in Chinese, see [使用说明.md](使用说明.md).

## License

Free to use without authorization.

## Support

For issues or suggestions, please submit an Issue on GitHub.