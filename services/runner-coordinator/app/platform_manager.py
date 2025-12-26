import logging
import platform
import subprocess
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


class PlatformManager:
    """
    Handles architecture detection and GPU capability discovery.
    """

    @staticmethod
    def get_host_architecture() -> str:
        """
        Detect the host's CPU architecture.
        Returns: 'amd64', 'arm64', or 'riscv'
        """
        arch = platform.machine().lower()
        if arch in ["x86_64", "amd64"]:
            return "amd64"
        elif arch in ["aarch64", "arm64"]:
            return "arm64"
        elif arch in ["riscv64"]:
            return "riscv"
        return arch

    @staticmethod
    def detect_gpu_capabilities() -> Dict[str, Any]:
        """
        Detect available GPU hardware and vendors.
        """
        capabilities = {"nvidia": False, "amd": False, "intel": False, "devices": []}

        # 1. Check for NVIDIA (nvidia-smi)
        try:
            subprocess.run(
                ["nvidia-smi"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True
            )
            capabilities["nvidia"] = True
            logger.info("NVIDIA GPU detected via nvidia-smi")
        except (subprocess.CalledProcessError, FileNotFoundError):
            pass

        # 2. Check for AMD (rocm-smi or /dev/kfd)
        try:
            import os

            if os.path.exists("/dev/kfd"):
                capabilities["amd"] = True
                logger.info("AMD GPU detected via /dev/kfd")
        except Exception:
            pass

        # 3. Check for Intel (look for render nodes)
        try:
            import os

            if any(
                f.startswith("renderD") for f in os.listdir("/dev/dri") if os.path.isdir("/dev/dri")
            ):
                # This is a broad check, might need refinement for specific Intel GPUs
                capabilities["intel"] = True
                logger.info("Intel GPU/Render node detected via /dev/dri")
        except (FileNotFoundError, Exception):
            pass

        return capabilities

    @staticmethod
    def get_docker_platform(target_arch: str) -> str:
        """
        Map internal architecture names to Docker platform strings.
        """
        mapping = {"amd64": "linux/amd64", "arm64": "linux/arm64", "riscv": "linux/riscv64"}
        return mapping.get(target_arch, f"linux/{target_arch}")

    @staticmethod
    def get_gpu_device_requests(vendor: str) -> Optional[list]:
        """
        Generate Docker device requests/mounts for specific GPU vendors.
        """
        if vendor == "nvidia":
            # For NVIDIA, we use the DeviceRequest API (requires nvidia-container-runtime)
            import docker

            return [docker.types.DeviceRequest(count=-1, capabilities=[["gpu"]])]

        # For AMD/Intel, we typically mount device nodes directly
        # This is handled in the driver's volume/device mapping logic
        return None
