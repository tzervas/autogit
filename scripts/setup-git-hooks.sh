#!/usr/bin/env bash
# Setup script to configure git hooks with auto-fixing behavior

set -e

echo "🔧 Configuring git hooks for auto-fixing..."

# Install pre-commit hooks
if command -v pre-commit &> /dev/null; then
    echo "  📦 Installing pre-commit hooks..."
    pre-commit install --hook-type pre-commit
    pre-commit install --hook-type commit-msg

    # Configure git to be more tolerant of formatter changes
    git config core.hooksPath .git/hooks

    echo "  ✅ Pre-commit hooks installed"
else
    echo "  ⚠️  pre-commit not found. Install with: pip install pre-commit"
    exit 1
fi

# Set up git config for better hook behavior
echo "  ⚙️  Configuring git settings..."

# Allow hooks to modify files during commit
git config --local core.autocrlf input
git config --local core.eol lf

# Configure pre-commit to be less verbose
git config --local pre-commit.verbose false

echo ""
echo "✅ Git hooks configured successfully!"
echo ""
echo "📝 Note: Formatters will now auto-fix files and include them in commits"
echo "   - Trailing whitespace, EOF fixes"
echo "   - YAML/Markdown formatting"
echo "   - Shell script formatting"
echo "   - Python formatting (black, isort)"
echo ""
echo "💡 To run hooks manually: pre-commit run --all-files"
