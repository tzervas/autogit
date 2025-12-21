# Contributing to Autogit

## Getting Started

1. Fork the repository
2. Clone your fork
3. Run `./scripts/setup.sh`
4. Make your changes
5. Test with `docker-compose up`
6. Submit a pull request

## Development Guidelines

- Follow Docker best practices
- Keep services loosely coupled
- Document all APIs
- Add tests where appropriate
- Update documentation

## Service Development

Each service should:
- Have its own Dockerfile
- Include a README in its directory
- Expose health check endpoints
- Handle graceful shutdown
- Log to stdout/stderr

## Testing

```bash
# Build and test locally
docker-compose build
docker-compose up
```

## Questions?

Open an issue for discussion.
