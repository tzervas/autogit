"""
Unit tests for the tasker tool.
"""

import unittest
from pathlib import Path

from tools.tasker.parser import TaskTrackerParser
from tools.tasker.models import TaskStatus, Priority


class TestTaskTrackerParser(unittest.TestCase):
    """Test the task tracker parser."""

    def setUp(self):
        """Set up test fixtures."""
        self.tracker_path = Path(__file__).parent.parent.parent.parent / "TASK_TRACKER.md"
        self.parser = TaskTrackerParser(str(self.tracker_path))

    def test_parser_initialization(self):
        """Test parser can be initialized."""
        self.assertIsNotNone(self.parser)
        self.assertTrue(self.tracker_path.exists())

    def test_parse_tracker(self):
        """Test parsing the task tracker file."""
        tracker = self.parser.parse()

        # Should have milestones
        self.assertGreater(len(tracker.milestones), 0)

        # Should have metadata
        self.assertIsNotNone(tracker.last_updated)
        self.assertIsNotNone(tracker.current_phase)

    def test_parse_milestones(self):
        """Test parsing milestones."""
        tracker = self.parser.parse()

        # Check we have expected milestones
        milestone_titles = [m.title for m in tracker.milestones]
        self.assertIn("Documentation Foundation", milestone_titles)
        self.assertIn("Git Server Implementation", milestone_titles)

    def test_parse_milestone_status(self):
        """Test parsing milestone status."""
        tracker = self.parser.parse()

        # Find the documentation milestone
        doc_milestone = None
        for m in tracker.milestones:
            if "Documentation" in m.title:
                doc_milestone = m
                break

        self.assertIsNotNone(doc_milestone)
        self.assertEqual(doc_milestone.status, TaskStatus.COMPLETE)

    def test_parse_subtasks(self):
        """Test parsing subtasks."""
        tracker = self.parser.parse()

        # Find git server milestone
        git_server_milestone = None
        for m in tracker.milestones:
            if "Git Server" in m.title:
                git_server_milestone = m
                break

        self.assertIsNotNone(git_server_milestone)
        self.assertGreater(len(git_server_milestone.subtasks), 0)

        # Check first subtask
        first_task = git_server_milestone.subtasks[0]
        self.assertIn("Docker", first_task.title)
        self.assertIsNotNone(first_task.branch)
        self.assertIsNotNone(first_task.priority)

    def test_get_next_work_item(self):
        """Test getting next actionable work item."""
        tracker = self.parser.parse()
        next_task = tracker.get_next_work_item()

        # Should find a task
        self.assertIsNotNone(next_task)

        # Should be actionable (READY or QUEUED)
        self.assertIn(next_task.status, [TaskStatus.READY, TaskStatus.QUEUED])

    def test_milestone_progress(self):
        """Test milestone progress calculation."""
        tracker = self.parser.parse()

        # Find a milestone with subtasks
        for milestone in tracker.milestones:
            if len(milestone.subtasks) > 0:
                progress = milestone.progress_percentage()
                self.assertGreaterEqual(progress, 0.0)
                self.assertLessEqual(progress, 100.0)
                break


class TestTaskModels(unittest.TestCase):
    """Test the task data models."""

    def test_task_is_actionable(self):
        """Test task actionable check."""
        from tools.tasker.models import Task

        ready_task = Task(id="test-1", title="Test", status=TaskStatus.READY)
        self.assertTrue(ready_task.is_actionable())

        queued_task = Task(id="test-2", title="Test", status=TaskStatus.QUEUED)
        self.assertTrue(queued_task.is_actionable())

        complete_task = Task(id="test-3", title="Test", status=TaskStatus.COMPLETE)
        self.assertFalse(complete_task.is_actionable())

    def test_task_is_complete(self):
        """Test task complete check."""
        from tools.tasker.models import Task

        complete_task = Task(id="test-1", title="Test", status=TaskStatus.COMPLETE)
        self.assertTrue(complete_task.is_complete())

        ready_task = Task(id="test-2", title="Test", status=TaskStatus.READY)
        self.assertFalse(ready_task.is_complete())

    def test_milestone_get_next_task(self):
        """Test milestone get next task."""
        from tools.tasker.models import Milestone, Task

        milestone = Milestone(
            id="test-milestone",
            title="Test Milestone",
            status=TaskStatus.PLANNED
        )

        # Add tasks
        milestone.subtasks = [
            Task(id="t1", title="Task 1", status=TaskStatus.COMPLETE),
            Task(id="t2", title="Task 2", status=TaskStatus.READY),
            Task(id="t3", title="Task 3", status=TaskStatus.QUEUED),
        ]

        next_task = milestone.get_next_task()
        self.assertIsNotNone(next_task)
        self.assertEqual(next_task.id, "t2")  # Should get READY before QUEUED


if __name__ == "__main__":
    unittest.main()
