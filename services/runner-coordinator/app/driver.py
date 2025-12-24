import docker
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

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
        except Exception as e:
            logger.error(f"Failed to connect to Docker daemon: {e}")
            raise RuntimeError(f"Docker connection failed: {e}")

    def spawn_runner(
        self,
        name: str,
        image: str = "gitlab/gitlab-runner:latest",
        cpu_limit: float = 1.0,
        mem_limit: str = "1g",
        network: str = "autogit-network",
        environment: Optional[Dict[str, str]] = None,
        platform: Optional[str] = None,
        gpu_vendor: Optional[str] = None,
        userns_mode: str = "host" # Default to host, but can be overridden for isolation
    ) -> Dict[str, Any]:
        """
        Spawn a new runner container.
        """
        device_requests = []
        devices = []

        if gpu_vendor == "nvidia":
            device_requests = [docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])]
        elif gpu_vendor == "amd":
            devices = ["/dev/kfd:/dev/kfd", "/dev/dri:/dev/dri"]
        elif gpu_vendor == "intel":
            devices = ["/dev/dri:/dev/dri"]

        try:
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
                    "/var/run/docker.sock": {"bind": "/var/run/docker.sock", "mode": "rw"}
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
        docker_image: str = "python:3.11-slim"
    ) -> Dict[str, Any]:
        """
        Register a GitLab runner inside an already running container.
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
                "--docker-volumes", "/var/run/docker.sock:/var/run/docker.sock"
            ]

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
