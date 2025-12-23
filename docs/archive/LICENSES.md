# Dependency Licenses

This document tracks all dependencies and their licenses to ensure MIT compatibility.

## License Compatibility

AutoGit is licensed under the MIT License. All dependencies must have compatible licenses:

✅ **Compatible Licenses**:
- MIT
- BSD (2-Clause, 3-Clause)
- Apache 2.0
- ISC
- Python Software Foundation License

❌ **Incompatible Licenses**:
- GPL (any version) - copyleft
- AGPL - copyleft
- Proprietary/Commercial licenses

## Core Dependencies

### Runtime Dependencies

#### Python Packages

| Package | Version | License | Use |
|---------|---------|---------|-----|
| To be added | - | - | - |

#### Container Images

| Image | Version | License | Use |
|-------|---------|---------|-----|
| Docker | 24.0+ | Apache 2.0 | Container runtime |
| Python | 3.11+ | PSF | Runtime environment |

### Build Dependencies

| Package | Version | License | Use |
|---------|---------|---------|-----|
| To be added | - | - | - |

### Development Dependencies

| Package | Version | License | Use |
|---------|---------|---------|-----|
| pytest | Latest | MIT | Testing framework |
| black | Latest | MIT | Code formatter |
| flake8 | Latest | MIT | Linter |
| mypy | Latest | MIT | Type checker |

## Infrastructure Components

### Kubernetes Components

| Component | License | Use |
|-----------|---------|-----|
| Traefik | MIT | Ingress controller |
| Authelia | Apache 2.0 | SSO authentication |
| CoreDNS | Apache 2.0 | DNS management |
| cert-manager | Apache 2.0 | TLS certificate management |

### GitLab Components

| Component | License | Use |
|-----------|---------|-----|
| GitLab CE | MIT | Git server |
| GitLab Runner | MIT | CI/CD runner |
| PostgreSQL | PostgreSQL License | Database |
| Redis | BSD 3-Clause | Cache |
| MinIO | AGPLv3* | Object storage |

*Note: MinIO changed to AGPLv3 after certain versions. Use AGPL-compatible version or alternative.

## License Verification Process

When adding new dependencies:

1. **Check License**
   ```bash
   pip-licenses --from=mixed --format=markdown
   ```

2. **Verify Compatibility**
   - Ensure license is in compatible list
   - Check for any license changes in recent versions
   - Document any special considerations

3. **Update This Document**
   - Add to appropriate section
   - Include version, license, and use
   - Note any license caveats

4. **Review in PR**
   - All dependency additions must update this file
   - Maintainers will verify license compatibility

## License Notices

### MIT License Template

```
MIT License

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Third-Party Notices

Copies of third-party licenses can be found in the `licenses/` directory.

## Compliance

This project maintains MIT license compatibility for all dependencies. Any dependency with an incompatible license must be:

1. Replaced with a compatible alternative
2. Isolated as an optional component
3. Documented with clear usage restrictions

## Updates

This document should be updated whenever:
- New dependencies are added
- Dependencies are updated to new major versions
- License terms change for existing dependencies

## Resources

- [Choose a License](https://choosealicense.com/)
- [Open Source Initiative](https://opensource.org/licenses)
- [SPDX License List](https://spdx.org/licenses/)

## Maintainer Notes

Run license check before releases:

```bash
# Check Python packages
pip-licenses --format=markdown > licenses/python-licenses.md

# Check for incompatible licenses
pip-licenses | grep -E "GPL|AGPL"
```

Last updated: YYYY-MM-DD
