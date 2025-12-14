# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Quick Start

### Install

#### Using HTTPS (simpler, no SSH key required)

```shell
# Install chezmoi and apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply litols
```

#### Using SSH (recommended if you have SSH keys set up)

```shell
# Install chezmoi and apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:litols/dotfiles.git
```

#### Step-by-step installation

Or if you want to review changes before applying:

```shell
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize from GitHub repository (HTTPS)
chezmoi init litols

# Or initialize using SSH
chezmoi init git@github.com:litols/dotfiles.git

# Review what would be changed
chezmoi diff

# Apply the changes
chezmoi apply
```

## Work Profile

To enable work-specific configuration, set the `WORK_PROFILE` environment variable before running chezmoi:

```shell
# Using HTTPS
export WORK_PROFILE=true
chezmoi init --apply litols

# Or using SSH
export WORK_PROFILE=true
chezmoi init --apply git@github.com:litols/dotfiles.git
```

This will:

- Load work-specific zsh configuration from `~/.zshrc.d/work.zsh`
- Create `~/.gitconfig_work` for work-specific git settings

You can customize these files by editing:

- `~/.local/share/chezmoi/dot_zshrc.d/work.zsh.tmpl`
- `~/.local/share/chezmoi/dot_gitconfig_work.tmpl`

## Daily Usage

```shell
# Pull latest changes from the repository and apply them
chezmoi update

# Edit a dotfile (opens in $EDITOR)
chezmoi edit ~/.zshrc

# See what would change
chezmoi diff

# Apply pending changes
chezmoi apply

# Add a new dotfile to chezmoi
chezmoi add ~/.newfile
```

## Manual Setup

### Homebrew

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installing Homebrew, you can install packages from the Brewfile:

```shell
# macOS
brew bundle --file ~/Brewfile

# Linux
brew bundle --file ~/Brewfile
```

### JetBrains Mono Nerd Font

- Mac: `brew install font-jetbrains-mono-nerd-font`
- Linux: `brew install font-jetbrains-mono-nerd-font`
- Windows: Install via Chocolatey

### Language Pack (Linux)

```shell
sudo apt install -y language-pack-ja
```

## What's Included

- **Shell**: zsh with zinit plugin manager, starship prompt
- **Terminal**: tmux configuration with tpm plugins
- **Editor**: vim configuration
- **Git**: Global gitconfig and gitignore
- **Tools**: mise, fzf, bat, tig, gh
- **macOS**: Karabiner-Elements, Hammerspoon, Ghostty terminal
- **Kubernetes**: k9s configuration

## CI/CD

This repository includes GitHub Actions workflows to test chezmoi configuration on both Linux and macOS, with and without work profile enabled.

## Migration from Dotbot

This repository has been migrated from Dotbot to chezmoi. Old configuration files have been removed.
