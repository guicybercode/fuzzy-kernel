# Contributing to Microkernel IoT Platform

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/microkernel.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit: `git commit -m "Add your feature"`
7. Push: `git push origin feature/your-feature-name`
8. Open a Pull Request

## Development Setup

### Prerequisites
- Zig 0.11+
- Elixir 1.14+ and Erlang/OTP 25+
- Docker and Docker Compose
- Git

### Setup
```bash
make infra-up
make server-setup
make edge-build
```

## Code Style

### Zig
- Follow standard Zig formatting: `zig fmt src/`
- No comments in code (per project requirements)
- Use meaningful variable names

### Elixir
- Follow Elixir style guide
- Format code: `mix format`
- Write documentation for public functions

## Testing

### Zig
```bash
cd edge && zig build test
```

### Elixir
```bash
cd server && mix test
```

## Pull Request Guidelines

1. Update documentation if needed
2. Add tests for new features
3. Ensure all tests pass
4. Keep commits atomic and well-described
5. Reference issues in PR description

## Reporting Issues

- Use GitHub Issues
- Include reproduction steps
- Specify environment (OS, versions)
- Provide logs if applicable

## Feature Requests

- Open an issue with [Feature Request] prefix
- Describe the use case
- Explain expected behavior

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

