# Contributing to xhyprland

First off, thank you for considering contributing to **xhyprland**! It's people like you that make xhyprland such a powerful and beautiful environment.

## How Can I Contribute?

### 1. Reporting Bugs
If you find an issue with a script, a broken visual element in Waybar, or a Hyprland crash related to our configs, please report it!
- Check if the issue has already been reported.
- Open a new issue with a clear title and description.
- Include your Distro, Hyprland version, and steps to reproduce.

### 2. Suggesting Enhancements
Have an idea for a new feature, a new Waybar widget, or a better script?
- Open an issue describing your idea.
- Explain how it benefits the project.

### 3. Submitting Pull Requests (PRs)
We welcome code contributions! To submit a change:

1. **Fork the repository** to your own GitHub account.
2. **Create a branch** for your feature or bug fix (`git checkout -b feature/amazing-feature`).
3. **Make your changes**. Please keep your code clean and document complex scripts.
4. **Test your changes** thoroughly in your own environment.
5. **Commit your changes** with a clear and descriptive commit message.
6. **Push to your fork** (`git push origin feature/amazing-feature`).
7. **Open a Pull Request** against the `main` branch of xhyprland.

## Development Guidelines

### Scripts (Bash)
- Ensure all scripts in `scripts/` are executable (`chmod +x`).
- Keep scripts POSIX compliant where possible, or clearly require `bash`.
- Add comments explaining complex commands or `jq`/`awk` operations.

### Themes (CSS & JSONC)
- When contributing a new Waybar theme, ensure both `.css` and `.jsonc` files are provided and organized correctly.
- Test your theme on different screen resolutions to ensure responsiveness.

### Hyprland Config
- Avoid hardcoding system-specific paths (like `/home/yourusername/`). Use `~` or environment variables instead.

---

**Thank you for your contributions!**
