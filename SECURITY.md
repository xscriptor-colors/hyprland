# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability in **xhyprland** (e.g., insecure scripts, exposed credentials, or malicious dependencies), please report it responsibly by contacting:

**Email:** `x@xscriptor.com`

### What to Include

When reporting a security issue, please provide:

1. **Description** — A clear explanation of the vulnerability
2. **Type** — What kind of security issue is it? (e.g., arbitrary code execution, permission escalation in scripts, etc.)
3. **Steps to Reproduce** — Detailed steps to trigger the vulnerability
4. **Impact** — How severe is the issue? What could an attacker do?
5. **Affected Scripts/Configs** — Which files in xhyprland are affected?
6. **Proposed Fix** (optional) — If you have a suggestion for how to fix it

### Guidelines

- **Do not** open public GitHub issues for security vulnerabilities
- **Do not** disclose the vulnerability publicly until a fix is released
- **Do** give the maintainers reasonable time to address the issue before public disclosure
- Typically, we aim to respond within **7 days** and release a fix within **30 days** for critical issues

## Security Best Practices for Users

Since xhyprland deals with system configuration, keep these recommendations in mind:

1. **Keep updated** — Always pull the latest version of xhyprland scripts (`git pull`) to receive fixes
2. **Review Scripts Before Running** — `install.sh` and helper scripts run system commands. Always review them if you fork this repository.
3. **Configuration Privacy** — Be careful when sharing your personal configs, as they may contain sensitive paths, tokens, or personal identifiers.
4. **Third-party Tools** — Only install Wayland tools and plugins from trusted package managers (like `pacman` or `yay`).

## Supported Versions

| Version       | Status |
|---------------|--------|
| `main` branch | Active |

## Security Updates

Security fixes will be released as soon as possible. Critical vulnerabilities in the installation scripts will receive priority treatment.

---

**Thank you for helping keep xhyprland secure!**