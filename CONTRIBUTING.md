# Contributing to Universal GitHub Project Installer

We welcome contributions from the community!

## Development Setup

1. Prerequisites:
   - Flutter SDK (>= 3.24.0)
   - Git
   - Native development tools for macOS (Xcode command line tools) or Windows (Visual Studio C++ Desktop workload).

2. Clone repository:
   ```bash
   git clone https://github.com/universal-installer/github-installer.git
   cd github-installer
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run tests:
   ```bash
   flutter test
   ```

5. Run static analysis:
   ```bash
   flutter analyze
   ```

6. Run desktop application:
   ```bash
   # macOS
   flutter run -d macos

   # Windows
   flutter run -d windows
   ```

## Pull Request Guidelines

- Ensure `flutter analyze` passes with zero issues.
- Ensure all tests pass via `flutter test`.
- Add test coverage for new framework detection modules or service features.
