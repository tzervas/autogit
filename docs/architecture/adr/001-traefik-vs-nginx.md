
# ADR-001: Traefik vs NGINX Ingress Controller
**Status**: Accepted
**Date**: 2025-12-21
**Deciders**: Project Team
**Technical Story**: Core infrastructure selection
## Context
AutoGit requires an ingress controller to manage external access to services in the Kubernetes cluster. The
ingress controller must:
- Route traffic to multiple services (GitLab, Authelia, DNS)
- Provide SSL/TLS termination
- Support Let's Encrypt automation
- Be MIT-license compatible
- Be lightweight and performant
- Have active community support
## Decision Drivers
- **License Compatibility**: Must be MIT or compatible (Apache 2.0, BSD)
- **Maintenance Status**: Active development and security updates
- **SSL Automation**: Native Let's Encrypt support
- **Resource Usage**: Low memory and CPU footprint
- **Ease of Configuration**: Simple, declarative configuration
- **Community Support**: Active community and good documentation
- **Cloud-Native**: Built for Kubernetes/Docker environments
## Considered Options
1. **Traefik** (MIT License)
2. **NGINX Ingress Controller** (Apache 2.0)
3. **HAProxy Ingress** (Apache 2.0)
4. **Envoy/Contour** (Apache 2.0)
## Decision Outcome
**Chosen option**: **Traefik**
### Rationale
1. **NGINX EOL**: NGINX Ingress Controller will be retired in March 2026 with no further security updates
2. **Native Let's Encrypt**: Traefik has built-in ACME support without additional controllers
3. **Dynamic Configuration**: Automatic service discovery and configuration
4. **MIT License**: Perfect compatibility with project license
5. **Modern Architecture**: Built specifically for cloud-native environments
6. **Better DX**: Simpler configuration than NGINX
7. **Active Development**: Regular releases and security patches
### Positive Consequences
- No need to manage separate cert-manager for basic SSL (though we still use it for advanced features)
- Automatic service discovery reduces configuration overhead
- Built-in dashboard for monitoring
- Native Docker and Kubernetes support
- Lower learning curve for contributors
- Future-proof (no EOL concerns)

### Negative Consequences
- Different from traditional NGINX (team familiarity)
- Smaller ecosystem than NGINX (though growing)
- Different configuration paradigm (labels vs ConfigMaps)
## Pros and Cons of the Options
### Traefik
- **Good**: MIT licensed, active development, native Let's Encrypt, automatic service discovery
- **Good**: Built-in dashboard, Gateway API support
- **Good**: Lower resource usage than NGINX
- **Good**: Simpler configuration model
- **Bad**: Smaller ecosystem than NGINX
- **Bad**: Less mature than NGINX (though stable)
- **Neutral**: Different configuration paradigm
### NGINX Ingress Controller
- **Good**: Very mature, large ecosystem
- **Good**: Familiar to most teams
- **Good**: Extensive documentation
- **Bad**: **Being retired March 2026** - no security updates after
- **Bad**: More complex configuration
- **Bad**: Requires separate cert-manager for SSL
- **Bad**: Manual service configuration
### HAProxy Ingress
- **Good**: Very performant
- **Good**: Mature and stable
- **Bad**: More complex to configure
- **Bad**: Less Kubernetes-native
- **Bad**: Smaller community than Traefik/NGINX
- **Neutral**: Apache 2.0 license
### Envoy/Contour
- **Good**: Very powerful and flexible
- **Good**: Used by Istio/service meshes
- **Bad**: Much more complex than needed
- **Bad**: Higher resource usage
- **Bad**: Steeper learning curve
- **Neutral**: Overkill for this use case
## Implementation Notes
### Traefik Configuration
```yaml
# Traefik deployed via Helm
helm install traefik traefik/traefik \
--namespace traefik \
--set ports.web.redirectTo=websecure \
--set certificatesResolvers.letsencrypt.acme.email=admin@example.com
```
### Service Discovery Example

```yaml
# Services auto-discovered via annotations
apiVersion: v1
kind: Service
metadata:
name: gitlab
annotations:
traefik.ingress.kubernetes.io/router.entrypoints: websecure
traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
ports:
- port: 80
```
## Links
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [NGINX Ingress EOL Announcement](https://github.com/kubernetes/ingress-nginx/issues/10870)
- [Related: ADR-006 SSL/TLS Configuration](006-storage-architecture.md)
- [Traefik GitHub](https://github.com/traefik/traefik)
## Supersedes
None (initial decision)
## Superseded By
None (current)
--**Last Updated**: 2025-12-21
**Status**: Accepted and Implemented

