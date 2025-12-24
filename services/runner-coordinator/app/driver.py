import docker
from typing import Dict, Any, Optional
import logging
import os

logger = logging.getLogger(__name__)

# Default network name (can be overridden by env var)
DEFAULT_NETWORK = os.environ.get("RUNNER_NETWORK", "autogit-network")

# Docker socket path - for rootless Docker this will be different
# The coordinator sees DOCKER_HOST, but runners need the actual host socket path
DOCKER_SOCKET_PATH = os.environ.get("RUNNER_DOCKER_SOCKET", "/var/run/docker.sock")

class DockerDriver:
    """
    Driver for managing runner containers via the Docker API.
    """

    def __init__(self, base_url: Optional[str] = None):
        try:
            if base_url:
                self.client = docker.DockerClient(base_url=base_url)
            else:
                self.client = docker.from_env()
            self.client.ping()
            # Auto-detect the autogit network on init
            self._detected_network = self._detect_autogit_network()
        except Exception as e:
            logger.error(f"Failed to connect to Docker daemon: {e}")
            raise RuntimeError(f"Docker connection failed: {e}")

    def _detect_autogit_network(self) -> Optional[str]:
        """
        Auto-detect the autogit network by looking for networks containing 'autogit'.
        Handles both 'autogit-network' and 'autogit_autogit-network' (docker-compose prefix).
        """
        try:
            networks = self.client.networks.list()
            # Priority order: exact match, then prefixed match
            for net in networks:
                if net.name == DEFAULT_NETWORK:
                    logger.info(f"Found exact network match: {net.name}")
                    return net.name

            # Look for docker-compose prefixed version
            for net in networks:
                if 'autogit' in net.name.lower() and net.name != 'bridge':
                    logger.info(f"Found autogit network (prefixed): {net.name}")
                    return net.name

            logger.warning(f"No autogit network found, will use default: {DEFAULT_NETWORK}")
            return None
        except Exception as e:
            logger.warning(f"Failed to detect network: {e}")
            return None

    def get_network_name(self) -> str:
        """Get the network name to use for runners."""
        return self._detected_network or DEFAULT_NETWORK

    def spawn_runner(
        self,
        name: str,
        image: str = "gitlab/gitlab-runner:latest",
        cpu_limit: float = 1.0,
        mem_limit: str = "1g",
        network: str = None,
        environment: Optional[Dict[str, str]] = None,
        platform: Optional[str] = None,
        gpu_vendor: Optional[str] = None,
        userns_mode: str = "host" # Default to host, but can be overridden for isolation
    ) -> Dict[str, Any]:
        """
        Spawn a new runner container.
        """
        # Use provided network, auto-detected network, or fall back to default
        network = network or self.get_network_name()
        logger.debug(f"Using network: {network}")

        device_requests = []
        devices = []

        if gpu_vendor == "nvidia":
            device_requests = [docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])]
        elif gpu_vendor == "amd":
            devices = ["/dev/kfd:/dev/kfd", "/dev/dri:/dev/dri"]
        elif gpu_vendor == "intel":
            devices = ["/dev/dri:/dev/dri"]

        try:
            # For rootless Docker, the socket path inside runner needs to match
            # what gitlab-runner expects (/var/run/docker.sock) but bound from host socket
            logger.debug(f"Mounting docker socket from {DOCKER_SOCKET_PATH}")

            container = self.client.containers.run(
                image=image,
                name=name,
                detach=True,
                cpu_period=100000,
                cpu_quota=int(cpu_limit * 100000),
                mem_limit=mem_limit,
                network=network,
                environment=environment or {},
                platform=platform,
                device_requests=device_requests,
                devices=devices,
                userns_mode=userns_mode,
                cap_drop=["ALL"], # Drop all capabilities by default
                cap_add=["CHOWN", "SETGID", "SETUID"], # Add only necessary ones
                security_opt=["no-new-privileges:true"],
                restart_policy={"Name": "unless-stopped"},
                volumes={
                    # Mount host's docker socket into runner container
                    # Use configured path (rootless: /run/user/1000/docker.sock)
                    DOCKER_SOCKET_PATH: {"bind": "/var/run/docker.sock", "mode": "rw"}
                }
            )

            # Reload to get networking info
            container.reload()

            return {
                "id": container.id,
                "short_id": container.short_id,
                "name": container.name,
                "status": container.status,
                "ip_address": container.attrs['NetworkSettings']['Networks'].get(network, {}).get('IPAddress')
            }
        except Exception as e:
            logger.error(f"Failed to spawn runner {name}: {e}")
            raise

    def stop_runner(self, container_id: str, remove: bool = True):
        """
        Stop and optionally remove a runner container.
        """
        try:
            container = self.client.containers.get(container_id)
            container.stop()
            if remove:
                container.remove()
            return True
        except docker.errors.NotFound:
            logger.warning(f"Container {container_id} not found for stopping")
            return False
        except Exception as e:
            logger.error(f"Failed to stop runner {container_id}: {e}")
            raise

    def get_runner_status(self, container_id: str) -> str:
        """
        Get the current status of a runner container.
        """
        try:
            container = self.client.containers.get(container_id)
            return container.status
        except docker.errors.NotFound:
            return "not_found"
        except Exception as e:
            logger.error(f"Failed to get status for {container_id}: {e}")
            return "error"

    def cleanup_orphans(self, label_filter: str = "autogit-runner"):
        """
        Cleanup orphaned runner containers based on labels.
        """
        # TODO: Implement label-based cleanup
        pass

    def register_gitlab_runner(
        self,
        container_id: str,
        gitlab_url: str,
        registration_token: str,
        description: str,
        tags: str,
        executor: str = "docker",
        docker_image: str = "python:3.11-slim",
        clone_url: str = None
    ) -> Dict[str, Any]:
        """
        Register a GitLab runner inside an already running container.

        Args:
            clone_url: Optional URL to use for cloning instead of the GitLab URL.
                       Useful when runners need to use internal network hostnames.
        """
        try:
            container = self.client.containers.get(container_id)

            # Build the registration command
            register_cmd = [
                "gitlab-runner",
                "register",
                "--non-interactive",
                "--url", gitlab_url,
                "--registration-token", registration_token,
                "--executor", executor,
                "--description", description,
                "--tag-list", tags,
                "--docker-image", docker_image,
                "--docker-privileged=false",
                "--docker-volumes", "/var/run/docker.sock:/var/run/docker.sock",
                "--docker-network-mode", self.get_network_name()
            ]

            # Add clone URL if specified (for internal network access)
            if clone_url:
                register_cmd.extend(["--clone-url", clone_url])

            # Execute the registration command
            exit_code, output = container.exec_run(
                cmd=register_cmd,
                detach=False
            )

            if exit_code != 0:
                logger.error(f"Runner registration failed: {output.decode('utf-8')}")
                raise RuntimeError(f"Registration failed with exit code {exit_code}")

            logger.info(f"Runner registered successfully: {description}")
            return {
                "status": "registered",
                "container_id": container.short_id,
                "output": output.decode('utf-8')
            }

        except Exception as e:
            logger.error(f"Failed to register runner in container {container_id}: {e}")
            raise
