import docker
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class DockerDriver:
    """
    Driver for managing runner containers via the Docker API.
    """

    def __init__(self, base_url: str = "unix://var/run/docker.sock"):
        try:
            self.client = docker.DockerClient(base_url=base_url)
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
        gpu_vendor: Optional[str] = None
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
