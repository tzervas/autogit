"""
Data models for tasks and milestones.
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional


class TaskStatus(Enum):
    """Task status enumeration."""
    COMPLETE = "COMPLETE"
    READY = "READY"
    QUEUED = "QUEUED"
    PLANNED = "PLANNED"
    IN_PROGRESS = "IN_PROGRESS"
    BLOCKED = "BLOCKED"


class Priority(Enum):
    """Task priority enumeration."""
    HIGH = "High"
    MEDIUM = "Medium"
    LOW = "Low"


@dataclass
class Task:
    """Represents a task or subtask in the task tracker."""
    id: str
    title: str
    status: TaskStatus
    priority: Priority = Priority.MEDIUM
    branch: Optional[str] = None
    dependencies: List[str] = field(default_factory=list)
    estimated_effort: Optional[str] = None
    assigned_to: Optional[str] = None
    tasks: List[str] = field(default_factory=list)
    deliverables: List[str] = field(default_factory=list)
    acceptance_criteria: List[str] = field(default_factory=list)
    parent_milestone: Optional[str] = None

    def is_actionable(self) -> bool:
        """Check if this task is ready to be worked on."""
        return self.status in [TaskStatus.READY, TaskStatus.QUEUED]

    def is_complete(self) -> bool:
        """Check if this task is complete."""
        return self.status == TaskStatus.COMPLETE


@dataclass
class Milestone:
    """Represents a milestone containing multiple tasks."""
    id: str
    title: str
    status: TaskStatus
    target: Optional[str] = None
    priority: Priority = Priority.MEDIUM
    branch: Optional[str] = None
    overview: Optional[str] = None
    subtasks: List[Task] = field(default_factory=list)

    def get_next_task(self) -> Optional[Task]:
        """Get the next actionable task in this milestone."""
        # First, find ready tasks
        for task in self.subtasks:
            if task.status == TaskStatus.READY:
                return task

        # Then, find queued tasks
        for task in self.subtasks:
            if task.status == TaskStatus.QUEUED:
                return task

        return None

    def is_complete(self) -> bool:
        """Check if this milestone is complete."""
        return self.status == TaskStatus.COMPLETE or all(
            task.is_complete() for task in self.subtasks
        )

    def progress_percentage(self) -> float:
        """Calculate completion percentage."""
        if not self.subtasks:
            return 0.0
        completed = sum(1 for task in self.subtasks if task.is_complete())
        return (completed / len(self.subtasks)) * 100


@dataclass
class TaskTracker:
    """Represents the entire task tracker state."""
    milestones: List[Milestone] = field(default_factory=list)
    last_updated: Optional[str] = None
    current_phase: Optional[str] = None

    def get_next_work_item(self) -> Optional[Task]:
        """
        Identify the next actionable work item across all milestones.

        Returns the highest priority task that is ready to be worked on,
        considering dependencies and status.
        """
        # Find active (incomplete) milestones
        active_milestones = [
            m for m in self.milestones if not m.is_complete()
        ]

        if not active_milestones:
            return None

        # Sort by priority (HIGH > MEDIUM > LOW)
        priority_order = {Priority.HIGH: 0, Priority.MEDIUM: 1, Priority.LOW: 2}
        active_milestones.sort(key=lambda m: priority_order[m.priority])

        # Get the next task from the highest priority milestone
        for milestone in active_milestones:
            next_task = milestone.get_next_task()
            if next_task:
                return next_task

        return None

    def get_milestone_by_id(self, milestone_id: str) -> Optional[Milestone]:
        """Get a milestone by its ID."""
        for milestone in self.milestones:
            if milestone.id == milestone_id:
                return milestone
        return None

    def get_task_by_id(self, task_id: str) -> Optional[Task]:
        """Get a task by its ID."""
        for milestone in self.milestones:
            for task in milestone.subtasks:
                if task.id == task_id:
                    return task
        return None
