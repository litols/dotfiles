# Claude Development Guide

This document provides context for AI assistants (Claude) working on this dotfiles repository.

## Project Overview

This is a personal dotfiles repository managed with [chezmoi](https://www.chezmoi.io/), migrated from Dotbot. It supports multiple operating systems (macOS and Linux) and includes a work profile feature for separating personal and work configurations.

## Repository Structure

```
.
├── .chezmoi.toml.tmpl          # chezmoi configuration with work profile detection
├── .chezmoiexternal.toml       # External dependencies (tmux tpm)
├── .chezmoiignore              # Files to ignore when applying
├── .github/workflows/test.yml  # CI/CD for testing configurations
├── Brewfile.tmpl               # Homebrew packages
├── dot_*                       # Files/directories to be deployed to home directory
│   ├── dot_zshrc               # Main zsh configuration
│   ├── dot_tmux.conf           # tmux configuration
│   ├── dot_vimrc               # vim configuration
│   ├── dot_gitconfig.tmpl      # Git config with OS detection
│   ├── dot_gitconfig_private   # Private git configuration
│   ├── dot_gitconfig_work.tmpl # Work-specific git config (conditional)
│   ├── dot_config/             # ~/.config directory
│   │   ├── starship.toml       # Starship prompt configuration
│   │   ├── git/ignore          # Global gitignore
│   │   ├── k9s/config.yml      # Kubernetes k9s configuration
│   │   ├── karabiner/          # macOS-only Karabiner config (ignored on non-macOS)
│   │   ├── ghostty/            # macOS-only Ghostty terminal config (ignored on non-macOS)
│   ├── dot_zshrc.d/            # Additional zsh configs
│   │   ├── .keep               # Keep directory in git
│   │   └── work.zsh.tmpl       # Work profile configuration
│   └── dot_hammerspoon/        # macOS-only Hammerspoon config (ignored on non-macOS)
├── mac/                        # Reference configs (not deployed by chezmoi)
│   └── iterm/Default.json      # iTerm2 profile for manual import
```

## chezmoi Naming Conventions

chezmoi uses special prefixes and suffixes to determine file behavior:

### Prefixes

- `dot_` → Creates file/directory starting with `.` (e.g., `dot_zshrc` → `~/.zshrc`)
- `private_` → Sets file permissions to 0600 (owner read/write only)
- `executable_` → Makes file executable (chmod +x)

### Suffixes

- `.tmpl` → Template file, processed with Go templates
- `_darwin` → Only applied on macOS for FILES (e.g., `file_darwin` → `file`)
- `_linux` → Only applied on Linux for FILES (e.g., `file_linux` → `file`)

### Examples

- `dot_zshrc` → `~/.zshrc`
- `dot_config/starship.toml` → `~/.config/starship.toml`
- `private_dot_ssh/config.tmpl` → `~/.ssh/config` (permissions: 0600, templated)
- `dot_gitconfig_darwin.tmpl` → `~/.gitconfig` (macOS only, templated)
- `dot_config/k9s/config.yml` → `~/.config/k9s/config.yml`

**OS-Specific Handling**:

- For **FILES**: Use `_darwin` or `_linux` suffix (e.g., `config_darwin` → `config` on macOS only)
- For **DIRECTORIES**: Use `.chezmoiignore` with template conditions to ignore on other OSes

**Example .chezmoiignore for OS-specific directories**:

```
{{- if ne .chezmoi.os "darwin" }}
# macOS-only configurations
.config/ghostty/
.hammerspoon/
.config/karabiner/
{{- end }}
```

**IMPORTANT**: Do NOT wrap contents of `_darwin`/`_linux` files in OS conditionals - the file suffix already handles OS detection

## Template Variables

Templates have access to:

### Built-in chezmoi variables

- `.chezmoi.os` → Operating system (darwin, linux, etc.)
- `.chezmoi.osRelease.id` → OS distribution (ubuntu, debian, etc.)
- `.chezmoi.arch` → Architecture (amd64, arm64, etc.)
- `.chezmoi.homeDir` → User's home directory
- `.chezmoi.username` → Current username

### Custom data variables (from .chezmoi.toml.tmpl)

- `.workProfile` → Boolean, true if WORK_PROFILE env var is set

### Functions

- `env "VAR_NAME"` → Get environment variable

## Work Profile Feature

The work profile system allows users to maintain separate configurations for work without needing a separate repository.

### How it works

1. User sets `WORK_PROFILE=true` environment variable before running chezmoi
2. `.chezmoi.toml.tmpl` detects this and sets `.workProfile = true`
3. Template files use `{{- if .workProfile }}` to conditionally include work configs
4. Files affected:
   - `dot_zshrc.d/work.zsh.tmpl` → Loads work-specific shell configuration
   - `dot_gitconfig_work.tmpl` → Creates work-specific git config

### Important notes

- Work profile templates must ALWAYS generate valid output, even when disabled
- Use `{{- else }}` clauses to provide comments/documentation when disabled
- Never leave empty files when work profile is disabled

## Development Guidelines

### Making changes

1. **Read before edit**: Always read files before modifying them
2. **Test templates**: Ensure templates work with and without work profile
3. **OS-specific files**: Use `_darwin`/`_linux` suffixes, NOT template conditionals
4. **Don't over-engineer**: Keep solutions simple and focused on the requested change
5. **Preserve existing patterns**: Match the existing code style and structure

### Testing locally

```bash
# Test without work profile
chezmoi init --source=/path/to/dotfiles
chezmoi apply --source=/path/to/dotfiles --dry-run --verbose

# Test with work profile
WORK_PROFILE=true chezmoi init --source=/path/to/dotfiles
WORK_PROFILE=true chezmoi apply --source=/path/to/dotfiles --dry-run --verbose
```

### CI/CD

- GitHub Actions runs on every push and PR
- Tests both Linux (ubuntu-latest) and macOS (macos-latest)
- Tests both with and without work profile enabled
- All tests must pass before merging

## Common Tasks

### Adding a new dotfile

```bash
chezmoi add ~/.newconfig
# This creates the appropriate dot_* file in the source directory
```

### Adding an OS-specific file

- For macOS only: Name it with `_darwin` suffix (e.g., `dot_config/somefile_darwin.conf`)
- For Linux only: Name it with `_linux` suffix (e.g., `dot_config/somefile_linux.conf`)
- Do NOT add OS conditionals inside these files

### Adding an OS-specific directory

- Create the directory with a normal name (e.g., `dot_config/ghostty/`)
- Add it to `.chezmoiignore` with template conditions to ignore on other OSes
- Example: See `.chezmoiignore` for macOS-only directories like `.config/ghostty/`

### Adding a templated file

1. Create file with `.tmpl` extension
2. Use `{{ }}` for variables, `{{- }}` to trim whitespace
3. Test with both work profile enabled and disabled

**Note**: Only use `.tmpl` extension if the file actually uses template variables. Simple static config files should not use `.tmpl`.

## Files Excluded from Deployment

These files are excluded from deployment via `.chezmoiignore`:

- `README.md`, `CLAUDE.md`, `MIGRATION.md` (documentation)
- `.git/`, `.github/` (Git metadata and CI workflows)
- `mac/` (reference configs, not deployed by chezmoi)
- `.config/ghostty/`, `.hammerspoon/`, `.config/karabiner/` (macOS-only, conditionally ignored on non-macOS)

## Troubleshooting

### CI failures

1. Check that templates generate valid output (not empty files)
2. Verify `--source` flag is used with `chezmoi apply` in CI
3. Ensure OS-specific files don't have redundant OS checks inside
4. Test both with and without WORK_PROFILE environment variable

### Empty files on macOS/Linux

- Usually caused by double OS checking (suffix + template conditional)
- Remove the template conditional from `_darwin`/`_linux` files

### Work profile not loading

- Ensure WORK_PROFILE env var is set before running `chezmoi init`
- Check `.chezmoi.toml.tmpl` is correctly detecting the variable
- Verify work profile templates are using `.workProfile` (not `.work_profile`)

## Architecture Decisions

### Why chezmoi over Dotbot?

- Better cross-platform support with built-in OS detection
- Native templating without complex shell scripts
- Active development and better documentation
- No git submodules needed

### Why mise over asdf?

- Faster performance (written in Rust)
- Better UX with simpler configuration
- Backward compatible with asdf `.tool-versions` files
- More actively maintained

### Why work profile instead of separate repo?

- Single source of truth for common configuration
- Easy to switch contexts without cloning multiple repos
- Simpler to maintain and sync changes
- Optional feature that doesn't affect normal usage
