# Specialist Feedback: Runner Coordinator Research

## 1. Software Engineer Feedback (Architecture & API)
**Proposed Solution**:
- **Standalone Service**: The Runner Coordinator should be a standalone Python service using FastAPI. This allows it to scale independently of the Git Server.
- **State Management**: Use a lightweight SQLite database (or Redis if we need high concurrency later) to track runner states and job assignments.
- **Lifecycle**: Implement a state machine: `PENDING` -> `PROVISIONING` -> `IDLE` -> `BUSY` -> `TEARDOWN`.
- **API**: Use REST for status/management and Webhooks for receiving job notifications from GitLab.

## 2. DevOps Engineer Feedback (Infrastructure & GPU)
**Proposed Solution**:
- **Docker Socket**: Mount `/var/run/docker.sock` into the Coordinator. This is more efficient than DinD for a management service.
- **Multi-Arch**: Use `docker run --platform` and ensure `binfmt_misc` is configured on the host for RISC-V/ARM64 emulation.
- **GPU**: Use the `nvidia-container-toolkit` for NVIDIA. For AMD/Intel, we need to mount specific device nodes (`/dev/dri`, `/dev/kfd`).
- **Resource Limits**: Use Docker's `--cpus` and `--memory` flags dynamically based on the job requirements.

## 3. Security Engineer Feedback (Isolation & Secrets)
**Proposed Solution**:
- **User Namespaces**: Enable user namespace remapping to ensure `root` in the runner container is not `root` on the host.
- **Network Isolation**: Each runner should be on a dedicated, isolated Docker network with no access to the `autogit-network` except via the Coordinator's proxy.
- **Secrets**: Use environment variables passed at runtime, but ensure they are never logged. Use a dedicated secrets volume that is wiped after the job.
- **No-Privileged**: Strictly forbid `--privileged` mode for runners.

## 4. Hybrid/Alternative Considerations
- **Fleeting Plugin**: We should explore if we can implement a custom "Fleeting" plugin for GitLab Runner, which is their native way of handling autoscaling. This might simplify the integration.
- **K3s/K8s**: While the MVP is Docker Compose, we should design the Coordinator's "Driver" to be pluggable, so we can swap the Docker driver for a Kubernetes driver in Milestone 6.
