"""
Parser for TASK_TRACKER.md markdown file.

This module provides functionality to parse the task tracker markdown file
and convert it into structured data models.
"""

import re
from typing import List, Optional, Tuple
from pathlib import Path

from .models import Task, Milestone, TaskTracker, TaskStatus, Priority


class TaskTrackerParser:
    """Parser for TASK_TRACKER.md file."""

    def __init__(self, file_path: str):
        """
        Initialize the parser with a file path.

        Args:
            file_path: Path to TASK_TRACKER.md file
        """
        self.file_path = Path(file_path)
        self.content = ""

    def parse(self) -> TaskTracker:
        """
        Parse the task tracker file and return a TaskTracker object.

        Returns:
            TaskTracker object with all milestones and tasks
        """
        self.content = self.file_path.read_text()
        lines = self.content.split("\n")

        tracker = TaskTracker()

        # Parse metadata from the top of the file
        tracker.last_updated = self._extract_metadata(lines, "Last Updated")
        tracker.current_phase = self._extract_metadata(lines, "Current Phase")

        # Parse milestones
        tracker.milestones = self._parse_milestones(lines)

        return tracker

    def _extract_metadata(self, lines: List[str], key: str) -> Optional[str]:
        """Extract metadata value from the header section."""
        pattern = rf"\*\*{re.escape(key)}\*\*:\s*(.+)"
        for line in lines[:20]:  # Check first 20 lines
            match = re.search(pattern, line)
            if match:
                return match.group(1).strip()
        return None

    def _parse_milestones(self, lines: List[str]) -> List[Milestone]:
        """Parse all milestones from the file."""
        milestones = []

        # Find milestone sections (### Milestone N:)
        milestone_pattern = r"^###\s+Milestone\s+(\d+):\s+(.+?)(\s+[✅📋🚧].*)?$"

        i = 0
        while i < len(lines):
            line = lines[i]
            match = re.match(milestone_pattern, line)

            if match:
                milestone_num = match.group(1)
                milestone_title = match.group(2).strip()

                # Determine status from emoji or text
                status = self._parse_milestone_status(line)

                # Parse milestone details
                milestone_data, next_i = self._parse_milestone_details(
                    lines, i + 1, milestone_num, milestone_title, status
                )
                milestones.append(milestone_data)
                i = next_i
            else:
                i += 1

        return milestones

    def _parse_milestone_status(self, line: str) -> TaskStatus:
        """Parse milestone status from the header line."""
        if "✅" in line or "COMPLETE" in line:
            return TaskStatus.COMPLETE
        elif "🚧" in line or "IN PROGRESS" in line:
            return TaskStatus.IN_PROGRESS
        elif "📋" in line or "PLANNED" in line:
            return TaskStatus.PLANNED
        else:
            return TaskStatus.QUEUED

    def _parse_milestone_details(
        self,
        lines: List[str],
        start_idx: int,
        milestone_num: str,
        milestone_title: str,
        status: TaskStatus
    ) -> Tuple[Milestone, int]:
        """Parse details of a milestone including subtasks."""
        milestone = Milestone(
            id=f"milestone-{milestone_num}",
            title=milestone_title,
            status=status
        )

        i = start_idx
        current_section = None

        # Parse until we hit the next milestone or section
        while i < len(lines):
            line = lines[i]

            # Stop if we hit another milestone
            if re.match(r"^###\s+Milestone", line):
                break

            # Stop if we hit a major section (## heading)
            if re.match(r"^##\s+", line) and "Subtask" not in line:
                break

            # Parse milestone metadata
            if line.startswith("**Target**:"):
                milestone.target = self._extract_value(line, "Target")
            elif line.startswith("**Status**:"):
                pass  # Already parsed from header
            elif line.startswith("**Priority**:"):
                priority_str = self._extract_value(line, "Priority")
                milestone.priority = self._parse_priority(priority_str)
            elif line.startswith("**Branch**:"):
                milestone.branch = self._extract_value(line, "Branch")

            # Parse subtasks (##### heading)
            elif re.match(r"^#####\s+\d+\.", line):
                subtask, next_i = self._parse_subtask(lines, i, milestone.id)
                milestone.subtasks.append(subtask)
                i = next_i
                continue

            i += 1

        return milestone, i

    def _parse_subtask(
        self,
        lines: List[str],
        start_idx: int,
        parent_milestone: str
    ) -> Tuple[Task, int]:
        """Parse a subtask section."""
        line = lines[start_idx]

        # Extract subtask number and title
        match = re.match(r"^#####\s+(\d+)\.\s+(.+?)(\s+[🚀📅🚧✅].*)?$", line)
        if not match:
            return None, start_idx + 1

        subtask_num = match.group(1)
        subtask_title = match.group(2).strip()
        status = self._parse_task_status(line)

        task = Task(
            id=f"{parent_milestone}-subtask-{subtask_num}",
            title=subtask_title,
            status=status,
            parent_milestone=parent_milestone
        )

        i = start_idx + 1
        current_section = None

        # Parse subtask details
        while i < len(lines):
            line = lines[i]

            # Stop at next subtask or milestone
            if re.match(r"^#####\s+\d+\.", line) or re.match(r"^###\s+Milestone", line):
                break

            # Stop at major section
            if re.match(r"^##\s+", line) and "Subtask" not in line:
                break

            # Parse metadata
            if line.startswith("**Branch**:"):
                task.branch = self._extract_value(line, "Branch")
            elif line.startswith("**Priority**:"):
                priority_str = self._extract_value(line, "Priority")
                task.priority = self._parse_priority(priority_str)
            elif line.startswith("**Dependencies**:"):
                task.dependencies = self._parse_dependencies(line)
            elif line.startswith("**Estimated Effort**:"):
                task.estimated_effort = self._extract_value(line, "Estimated Effort")
            elif line.startswith("**Assigned To**:"):
                task.assigned_to = self._extract_value(line, "Assigned To")

            # Parse lists
            elif line.startswith("**Tasks**:"):
                current_section = "tasks"
            elif line.startswith("**Deliverables**:"):
                current_section = "deliverables"
            elif line.startswith("**Acceptance Criteria**:"):
                current_section = "acceptance_criteria"
            elif line.strip().startswith("- [ ]") or line.strip().startswith("- [x]"):
                item = line.strip()[5:].strip()  # Remove checkbox
                if current_section == "tasks":
                    task.tasks.append(item)
                elif current_section == "acceptance_criteria":
                    task.acceptance_criteria.append(item)
            elif line.strip().startswith("-") and current_section == "deliverables":
                item = line.strip()[1:].strip()
                task.deliverables.append(item)
            elif line.strip() == "":
                # Empty line might end current section
                pass
            elif not line.strip().startswith("**") and current_section:
                # Continue current section
                pass
            else:
                current_section = None

            i += 1

        return task, i

    def _parse_task_status(self, line: str) -> TaskStatus:
        """Parse task status from header line."""
        if "✅" in line or "COMPLETE" in line:
            return TaskStatus.COMPLETE
        elif "🚀" in line or "READY" in line:
            return TaskStatus.READY
        elif "📅" in line or "QUEUED" in line:
            return TaskStatus.QUEUED
        elif "🚧" in line or "IN PROGRESS" in line or "IN_PROGRESS" in line:
            return TaskStatus.IN_PROGRESS
        else:
            return TaskStatus.PLANNED

    def _parse_priority(self, priority_str: Optional[str]) -> Priority:
        """Parse priority from string."""
        if not priority_str:
            return Priority.MEDIUM

        priority_str = priority_str.strip().lower()
        if "high" in priority_str:
            return Priority.HIGH
        elif "low" in priority_str:
            return Priority.LOW
        else:
            return Priority.MEDIUM

    def _parse_dependencies(self, line: str) -> List[str]:
        """Parse dependencies from a line."""
        value = self._extract_value(line, "Dependencies")
        if not value or value.lower() == "none":
            return []

        # Parse dependencies like "Subtask 1 (Docker Setup)"
        deps = []
        for dep in value.split(","):
            dep = dep.strip()
            if dep:
                deps.append(dep)
        return deps

    def _extract_value(self, line: str, key: str) -> Optional[str]:
        """Extract value from a key-value line."""
        pattern = rf"\*\*{re.escape(key)}\*\*:\s*(.+)"
        match = re.search(pattern, line)
        if match:
            return match.group(1).strip()
        return None
