# Security Policy

## Security Model

The Universal GitHub Project Installer runs third-party code from GitHub repositories locally. As a result, the application enforces the following security boundaries:

1. **Explicit Command Authorization**: Destructive commands, database migrations, and arbitrary repo scripts require interactive user authorization before execution.
2. **Secret & Key Masking**: Sensitive tokens (GitHub PATs, OpenAI keys, Gemini keys) are stored encrypted using local vault storage and masked in logs.
3. **Automated Secret Scanner**: Analyzes cloned repositories for inadvertently committed private keys, AWS tokens, and dangerous scripts prior to execution.
4. **Isolated Environments**: Supports Python virtual environments (`.venv`), isolated project directories, and dedicated database files (`database.sqlite`).
5. **No Blind Code Transmission**: The AI Assistant never transmits repository source code externally without explicit project context selection and user prompting.

## Reporting a Vulnerability

If you discover a security vulnerability, please do not open a public issue. Email the core team or report via GitHub Security Advisories.
