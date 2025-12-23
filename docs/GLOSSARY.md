# Glossary

## A

**ADR (Architecture Decision Record)**
: A document that captures an important architectural decision made along with its context and consequences.

**Agentic Workflow**
: A development approach using specialized AI personas (Project Manager, Software Engineer, DevOps Engineer, Security Engineer, Documentation Engineer, Evaluator) that work together.

**Autoscaling**
: Automatic adjustment of compute resources based on demand, increasing resources during high load and decreasing during low load.

**Architecture**
: The high-level structure of a software system, including components, their relationships, and design principles.

## B

**Buildx**
: Docker CLI plugin for extended build capabilities, including multi-platform builds.

## C

**CI/CD (Continuous Integration/Continuous Deployment)**
: Automated practices for building, testing, and deploying software changes.

**CoreDNS**
: A flexible, extensible DNS server used for service discovery in Kubernetes.

**cert-manager**
: Kubernetes add-on to automate the management and issuance of TLS certificates.

## D

**Deprovision**
: The process of removing or deallocating a resource, such as a runner instance.

**Docker Compose**
: A tool for defining and running multi-container Docker applications using YAML configuration.

**Dynamic Runner**
: A runner that is automatically created and destroyed based on job demand.

## E

**Emulation**
: Running software designed for one architecture on a different architecture (e.g., RISC-V on amd64 via QEMU).

**Executor**
: The backend that runs CI/CD jobs (e.g., Docker executor, Kubernetes executor).

## F

**Fleeting Plugin**
: A GitLab Runner plugin that enables dynamic provisioning and deprovisioning of runner instances.

## G

**GitOps**
: A way of implementing Continuous Deployment where Git is the single source of truth for infrastructure and application code.

**GPU-Aware Scheduling**
: Intelligent allocation of jobs to runners based on GPU requirements and availability.

## H

**Helm**
: A package manager for Kubernetes that simplifies deployment and management of applications.

**High Availability (HA)**
: System design approach that ensures a higher degree of operational continuity through redundancy.

## I

**Idle Timeout**
: The duration a runner can remain inactive before being automatically deprovisioned.

**Ingress Controller**
: Kubernetes component that manages external access to services (e.g., Traefik).

## J

**Job Queue**
: A queue of pending CI/CD jobs waiting for available runners.

## K

**Kubernetes (K8s)**
: An open-source container orchestration platform for automating deployment, scaling, and management.

**kubectl**
: Command-line tool for interacting with Kubernetes clusters.

## L

**Lifecycle Management**
: The complete management of a resource from creation through operation to decommissioning.

## M

**Multi-Architecture**
: Support for running software on different CPU architectures (amd64, arm64, RISC-V).

**MinIO**
: High-performance object storage system compatible with Amazon S3 API.

## N

**Network Policy**
: Kubernetes resource that controls traffic flow between pods.

## O

**Orchestration**
: Automated configuration, coordination, and management of computer systems and software.

## P

**Provision**
: The process of creating and configuring a new resource, such as a runner instance.

**Pod**
: The smallest deployable unit in Kubernetes, containing one or more containers.

## Q

**QEMU**
: Open-source machine emulator and virtualizer used for cross-architecture emulation.

**Queue Depth**
: The number of jobs waiting in the queue for available runners.

## R

**RBAC (Role-Based Access Control)**
: Method of regulating access based on roles assigned to users.

**Runner**
: An agent that executes CI/CD jobs from GitLab.

**Runner Coordinator**
: Service responsible for managing the lifecycle of runner instances.

## S

**SSO (Single Sign-On)**
: Authentication scheme allowing users to log in with a single ID to multiple systems.

**SOLID Principles**
: Five design principles (Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion) for maintainable software.

**Scale-up**
: Increasing resources by adding more instances (horizontal scaling) or capacity (vertical scaling).

**Scale-down**
: Decreasing resources by removing instances or reducing capacity.

## T

**Traefik**
: Modern HTTP reverse proxy and load balancer for microservices.

**TLS (Transport Layer Security)**
: Cryptographic protocol for secure communication over a network.

**Tag**
: A label used in CI/CD to match jobs with specific runners (e.g., `gpu`, `amd64`).

## U

**UV**
: Fast Python package installer and resolver, alternative to pip.

## V

**Vertical Scaling**
: Increasing capacity by adding more resources (CPU, memory) to existing instances.

**Horizontal Scaling**
: Increasing capacity by adding more instances.

## W

**Webhook**
: HTTP callback triggered by specific events, used for event notifications.

**Workload**
: A specific application or job running on a system.

## Y

**YAML (YAML Ain't Markup Language)**
: Human-readable data serialization format commonly used for configuration files.

## Acronyms

| Acronym | Full Form |
|---------|-----------|
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| CD | Continuous Deployment |
| CI | Continuous Integration |
| CLI | Command-Line Interface |
| DNS | Domain Name System |
| GPU | Graphics Processing Unit |
| HA | High Availability |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | HTTP Secure |
| K8s | Kubernetes |
| OIDC | OpenID Connect |
| RBAC | Role-Based Access Control |
| REST | Representational State Transfer |
| RISC-V | Reduced Instruction Set Computer - Five |
| RTO | Recovery Time Objective |
| RPO | Recovery Point Objective |
| SSL | Secure Sockets Layer |
| SSO | Single Sign-On |
| TLS | Transport Layer Security |
| UI | User Interface |
| YAML | YAML Ain't Markup Language |

## Common Commands

### Docker Compose
```bash
docker compose up -d      # Start services
docker compose down       # Stop services
docker compose ps         # List services
docker compose logs -f    # View logs
```

### Kubernetes
```bash
kubectl get pods          # List pods
kubectl describe pod <name> # Pod details
kubectl logs <pod>        # View pod logs
kubectl exec -it <pod> -- bash # Shell into pod
```

### Helm
```bash
helm install <name> <chart>   # Install chart
helm upgrade <name> <chart>   # Upgrade release
helm list                     # List releases
helm rollback <name>          # Rollback release
```

## See Also

- [Documentation Index](docs/INDEX.md) - Complete documentation map
- [Architecture Overview](docs/architecture/README.md) - System architecture
- [FAQ](FAQ.md) - Frequently asked questions
- [Contributing Guide](docs/CONTRIBUTING.md) - How to contribute

---

*Last updated: 2025-12-21*
