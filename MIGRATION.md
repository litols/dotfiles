# Migration Guide: Dotbot to chezmoi

This guide provides step-by-step instructions for migrating from Dotbot to chezmoi on existing machines.

## Overview

This migration is **safe and reversible**. Your existing dotfiles will not be modified until you explicitly apply the new configuration.

## Prerequisites

- Existing dotfiles managed by Dotbot
- Git installed
- Homebrew installed (macOS/Linux)
- Terminal access

## Migration Steps

### Step 1: Backup Current Configuration

Before starting, create a backup of your current dotfiles:

```bash
# Backup your home directory dotfiles
tar czf ~/dotfiles-backup-$(date +%Y%m%d).tar.gz \
    ~/.zshrc \
    ~/.tmux.conf \
    ~/.vimrc \
    ~/.gitconfig \
    ~/.gitconfig_private \
    ~/.config/starship.toml \
    ~/.config/git \
    ~/.config/k9s \
    2>/dev/null

# Backup macOS-specific configs (if on macOS)
tar czf ~/dotfiles-macos-backup-$(date +%Y%m%d).tar.gz \
    ~/.config/karabiner \
    ~/.hammerspoon \
    ~/.config/ghostty \
    2>/dev/null

echo "Backup created in home directory"
```

### Step 2: Install chezmoi

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Verify installation
chezmoi --version
```

### Step 3: Initialize with New Repository

**Option A: Fresh start (recommended)**

```bash
# Remove old dotfiles repository (don't worry, your dotfiles are still in ~/)
cd ~
rm -rf ~/dotfiles  # or wherever your old dotfiles repo is

# Initialize chezmoi with the new repository
chezmoi init --apply litols
```

**Option B: Keep old repository for reference**

```bash
# Rename old repository
mv ~/dotfiles ~/dotfiles-old

# Initialize chezmoi with the new repository
chezmoi init --apply litols
```

### Step 4: Review Changes (Before Applying)

If you want to review what will change before applying:

```bash
# Initialize without applying
chezmoi init litols

# See what would change
chezmoi diff

# Review specific files
chezmoi cat ~/.zshrc
chezmoi cat ~/.gitconfig

# When ready, apply changes
chezmoi apply
```

### Step 5: Verify Critical Configurations

After applying, verify that your configurations are working:

```bash
# Test shell
zsh -c 'echo "Shell works: $SHELL"'

# Test git config
git config --global user.name
git config --global user.email

# Test starship (if installed)
starship --version

# Test mise (replacing asdf)
mise --version
```

### Step 6: Handle asdf → mise Migration

If you were using asdf, your `.tool-versions` files will continue to work with mise:

```bash
# Install mise (will be installed via Brewfile automatically, or manually:)
brew install mise

# Activate mise (already in new .zshrc)
mise activate zsh

# Verify your existing .tool-versions work
cd ~/your-project
mise install  # Installs versions from .tool-versions
```

**Note**: You can keep both asdf and mise temporarily, then remove asdf when confident:

```bash
# After confirming mise works
brew uninstall asdf
rm -rf ~/.asdf
```

### Step 7: Set Up Work Profile (If Needed)

If you maintain separate work configurations:

```bash
# Set work profile environment variable
export WORK_PROFILE=true

# Re-initialize and apply
chezmoi init --apply litols

# Edit work-specific configs
chezmoi edit ~/.zshrc.d/work.zsh
chezmoi edit ~/.gitconfig_work

# Apply changes
chezmoi apply
```

Add to your `.zshrc` or `.bash_profile` on work machine:

```bash
# Add to ~/.zshrc (outside of chezmoi management)
export WORK_PROFILE=true
```

### Step 8: Install Homebrew Packages

The Brewfile will be automatically applied, but you can also run manually:

```bash
# Run brew bundle (automatically triggered by chezmoi)
# Or manually:
brew bundle --file ~/Brewfile
```

### Step 9: macOS-Specific Setup (macOS only)

**Karabiner-Elements**
```bash
# Karabiner config is automatically applied
# Launch Karabiner-Elements to activate
open -a "Karabiner-Elements"
```

**Hammerspoon**
```bash
# Hammerspoon config is automatically applied
# Launch Hammerspoon to activate
open -a "Hammerspoon"
```

**Ghostty Terminal**
```bash
# Config is at ~/.config/ghostty/config
# Launch Ghostty to use new config
open -a "Ghostty"
```

### Step 10: Clean Up Old Dotbot Installation

Once you've verified everything works:

```bash
# Remove old dotfiles repository (if you renamed it)
rm -rf ~/dotfiles-old

# Remove any remaining Dotbot-related files
rm -rf ~/.dotbot  # if it exists

# Remove old backups (after confirming everything works)
rm ~/dotfiles-backup-*.tar.gz
rm ~/dotfiles-macos-backup-*.tar.gz
```

## Work Profile Migration

If you previously maintained a separate work dotfiles repository:

### Before Migration

1. Note your work-specific configurations:
   - Git user.name and user.email
   - Work-specific aliases
   - Work-specific environment variables
   - SSH configs
   - AWS configs

### During Migration

```bash
# Initialize with work profile
export WORK_PROFILE=true
chezmoi init litols

# Edit work configurations
chezmoi edit ~/.zshrc.d/work.zsh
# Add your work-specific aliases and env vars here

chezmoi edit ~/.gitconfig_work
# Add your work git config here, example:
# [user]
#     name = Your Work Name
#     email = you@company.com

# Apply changes
chezmoi apply
```

### Example Work Configurations

**~/.zshrc.d/work.zsh**:
```bash
# Work-specific environment
export WORK_PROJECT_DIR=~/work
export AWS_PROFILE=work

# Work-specific aliases
alias work-ssh='ssh bastion.company.com'
alias work-vpn='sudo openconnect vpn.company.com'

# Work-specific PATH
export PATH="/opt/company/bin:$PATH"
```

**~/.gitconfig_work**:
```ini
[user]
    name = Your Name
    email = your.name@company.com

[url "git@github-work:"]
    insteadOf = git@github.com:
```

## Rollback Procedure

If you need to rollback to Dotbot:

### Option 1: Restore from Backup

```bash
# Restore from backup
cd ~
tar xzf dotfiles-backup-YYYYMMDD.tar.gz
tar xzf dotfiles-macos-backup-YYYYMMDD.tar.gz

# Remove chezmoi
rm -rf ~/.local/share/chezmoi
brew uninstall chezmoi
```

### Option 2: Reinstall Old Dotfiles

```bash
# Clone old dotfiles repository
cd ~
git clone https://github.com/litols/dotfiles ~/dotfiles-old
cd ~/dotfiles-old
git checkout <old-commit-before-migration>

# Run Dotbot install
./install

# Remove chezmoi
rm -rf ~/.local/share/chezmoi
brew uninstall chezmoi
```

## Troubleshooting

### Issue: Shell not loading correctly

**Symptoms**: Missing aliases, PATH incorrect, commands not found

**Solution**:
```bash
# Check if .zshrc was applied
ls -la ~/.zshrc

# Verify chezmoi applied correctly
chezmoi verify

# Re-apply
chezmoi apply -v

# Check for errors
cat ~/.zshrc | head -20
```

### Issue: Git config not working

**Symptoms**: Git asking for username/email, wrong credentials

**Solution**:
```bash
# Check git config
git config --global --list

# Verify files exist
ls -la ~/.gitconfig
ls -la ~/.gitconfig_private

# Re-apply git configs
chezmoi apply ~/.gitconfig
chezmoi apply ~/.gitconfig_private
```

### Issue: Work profile not loading

**Symptoms**: Work-specific settings not active

**Solution**:
```bash
# Ensure WORK_PROFILE is set
echo $WORK_PROFILE  # Should output: true

# Check if work files exist
ls -la ~/.zshrc.d/work.zsh
ls -la ~/.gitconfig_work

# Re-initialize with work profile
export WORK_PROFILE=true
chezmoi init --apply litols
```

### Issue: tmux plugins not working

**Symptoms**: tmux plugins missing or not loading

**Solution**:
```bash
# Check tpm installation
ls -la ~/.tmux/plugins/tpm

# If missing, re-run chezmoi
chezmoi apply

# Install tmux plugins
tmux source ~/.tmux.conf
# Press prefix + I (capital i) in tmux to install plugins
```

### Issue: mise not recognizing .tool-versions

**Symptoms**: `mise: command not found` or versions not loading

**Solution**:
```bash
# Ensure mise is installed
brew install mise

# Check mise activation in .zshrc
grep "mise activate" ~/.zshrc

# Restart shell
exec zsh

# Verify mise works
mise --version
mise list

# Install versions
cd ~/your-project
mise install
```

## Comparison: Dotbot vs chezmoi

### What Changed

| Aspect | Dotbot | chezmoi |
|--------|--------|---------|
| File management | Symlinks | File copies |
| Templating | None (shell scripts) | Go templates |
| OS-specific configs | Shell conditionals | File suffixes (`_darwin`, `_linux`) |
| External deps | Git submodules | `.chezmoiexternal.toml` |
| Work/Personal | Separate repos | Single repo with profiles |
| Updates | `git pull && ./install` | `chezmoi update` |

### What Stayed the Same

- All your configurations (zsh, tmux, vim, git)
- Homebrew package list
- Shell aliases and functions
- Key bindings and shortcuts
- Tool versions (now managed by mise instead of asdf)

### What's Better

- **Single command updates**: `chezmoi update` pulls and applies in one step
- **Work profile**: Switch contexts without switching repos
- **Better templating**: OS detection, environment variables, conditionals
- **Dry run**: Preview changes before applying
- **Encrypted secrets**: Built-in secret management (not used yet, but available)

## Daily Usage After Migration

### Update dotfiles

```bash
# Old way (Dotbot)
cd ~/dotfiles && git pull && ./install

# New way (chezmoi)
chezmoi update
```

### Edit dotfiles

```bash
# Old way (Dotbot)
vim ~/dotfiles/zsh/.zshrc
cd ~/dotfiles && ./install

# New way (chezmoi)
chezmoi edit ~/.zshrc  # Opens in $EDITOR, auto-applies on save
# Or manually:
chezmoi apply
```

### Add new dotfile

```bash
# Old way (Dotbot)
# Edit install.conf.yaml, add symlink, commit

# New way (chezmoi)
chezmoi add ~/.newconfig
cd $(chezmoi source-path)
git add .
git commit -m "Add newconfig"
git push
```

## Getting Help

- **chezmoi docs**: https://www.chezmoi.io/
- **Repository issues**: https://github.com/litols/dotfiles/issues
- **Quick reference**: `chezmoi help`
- **See what will change**: `chezmoi diff`
- **Verify current state**: `chezmoi verify`

## Summary

The migration process:

1. ✅ Backup current configs
2. ✅ Install chezmoi
3. ✅ Initialize new repository
4. ✅ Review changes (optional)
5. ✅ Apply configuration
6. ✅ Verify everything works
7. ✅ Set up work profile (if needed)
8. ✅ Clean up old Dotbot files

**Estimated time**: 15-30 minutes

**Risk level**: Low (fully reversible)

**Recommended approach**: Try on a non-critical machine first, then migrate your main machines.
