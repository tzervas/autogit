#!/usr/bin/env python3
"""
Tasker CLI - Command-line interface for task management.

This tool helps identify and manage work items from TASK_TRACKER.md.
"""

import argparse
import sys
from pathlib import Path
from typing import Optional

from .parser import TaskTrackerParser
from .models import TaskTracker, Task, Milestone, TaskStatus
from .executor import TaskExecutor


class TaskerCLI:
    """Command-line interface for the Tasker tool."""
    
    def __init__(self, tracker_path: Optional[str] = None):
        """
        Initialize the CLI.
        
        Args:
            tracker_path: Path to TASK_TRACKER.md file
        """
        if tracker_path:
            self.tracker_path = Path(tracker_path)
        else:
            # Default to repository root
            self.tracker_path = Path(__file__).parent.parent.parent / "TASK_TRACKER.md"
        
        if not self.tracker_path.exists():
            print(f"Error: Task tracker file not found at {self.tracker_path}")
            sys.exit(1)
        
        self.tracker: Optional[TaskTracker] = None
    
    def load_tracker(self) -> TaskTracker:
        """Load and parse the task tracker file."""
        if self.tracker is None:
            parser = TaskTrackerParser(str(self.tracker_path))
            self.tracker = parser.parse()
        return self.tracker
    
    def cmd_next(self, args):
        """Show the next actionable work item."""
        tracker = self.load_tracker()
        next_task = tracker.get_next_work_item()
        
        if not next_task:
            print("✅ No actionable tasks found. All work is complete or blocked!")
            return 0
        
        # Find parent milestone
        milestone = None
        for m in tracker.milestones:
            if m.id == next_task.parent_milestone:
                milestone = m
                break
        
        print("🎯 Next Work Item Identified")
        print("=" * 60)
        print(f"\n📋 Task: {next_task.title}")
        print(f"🆔 ID: {next_task.id}")
        print(f"📊 Status: {next_task.status.value}")
        print(f"⭐ Priority: {next_task.priority.value}")
        
        if milestone:
            print(f"📦 Milestone: {milestone.title}")
        
        if next_task.branch:
            print(f"🌿 Branch: {next_task.branch}")
        
        if next_task.estimated_effort:
            print(f"⏱️  Estimated Effort: {next_task.estimated_effort}")
        
        if next_task.assigned_to:
            print(f"👤 Assigned To: {next_task.assigned_to}")
        
        if next_task.dependencies:
            print(f"🔗 Dependencies: {', '.join(next_task.dependencies)}")
        
        if next_task.tasks:
            print(f"\n📝 Tasks ({len(next_task.tasks)}):")
            for i, task in enumerate(next_task.tasks[:5], 1):
                print(f"   {i}. {task}")
            if len(next_task.tasks) > 5:
                print(f"   ... and {len(next_task.tasks) - 5} more")
        
        if next_task.deliverables:
            print(f"\n📦 Deliverables ({len(next_task.deliverables)}):")
            for i, deliverable in enumerate(next_task.deliverables[:5], 1):
                print(f"   {i}. {deliverable}")
            if len(next_task.deliverables) > 5:
                print(f"   ... and {len(next_task.deliverables) - 5} more")
        
        if next_task.acceptance_criteria:
            print(f"\n✅ Acceptance Criteria ({len(next_task.acceptance_criteria)}):")
            for i, criteria in enumerate(next_task.acceptance_criteria[:5], 1):
                print(f"   {i}. {criteria}")
            if len(next_task.acceptance_criteria) > 5:
                print(f"   ... and {len(next_task.acceptance_criteria) - 5} more")
        
        print("\n" + "=" * 60)
        
        return 0
    
    def cmd_list(self, args):
        """List all milestones and tasks."""
        tracker = self.load_tracker()
        
        print("📊 Task Tracker Overview")
        print("=" * 60)
        
        if tracker.last_updated:
            print(f"Last Updated: {tracker.last_updated}")
        if tracker.current_phase:
            print(f"Current Phase: {tracker.current_phase}")
        
        print(f"\nTotal Milestones: {len(tracker.milestones)}")
        print()
        
        for milestone in tracker.milestones:
            status_emoji = self._get_status_emoji(milestone.status)
            progress = milestone.progress_percentage()
            
            print(f"{status_emoji} {milestone.title}")
            print(f"   ID: {milestone.id}")
            print(f"   Status: {milestone.status.value}")
            print(f"   Priority: {milestone.priority.value}")
            if milestone.target:
                print(f"   Target: {milestone.target}")
            print(f"   Progress: {progress:.0f}% ({sum(1 for t in milestone.subtasks if t.is_complete())}/{len(milestone.subtasks)} subtasks)")
            
            if args.verbose and milestone.subtasks:
                print(f"   Subtasks:")
                for task in milestone.subtasks:
                    task_emoji = self._get_status_emoji(task.status)
                    print(f"      {task_emoji} {task.title} ({task.status.value})")
            
            print()
        
        return 0
    
    def cmd_status(self, args):
        """Show status of a specific task or milestone."""
        tracker = self.load_tracker()
        
        # Try to find as milestone first
        milestone = tracker.get_milestone_by_id(args.id)
        if milestone:
            self._show_milestone_status(milestone)
            return 0
        
        # Try as task
        task = tracker.get_task_by_id(args.id)
        if task:
            self._show_task_status(task, tracker)
            return 0
        
        print(f"❌ Error: No milestone or task found with ID '{args.id}'")
        return 1
    
    def _show_milestone_status(self, milestone: Milestone):
        """Display detailed status of a milestone."""
        status_emoji = self._get_status_emoji(milestone.status)
        progress = milestone.progress_percentage()
        
        print(f"{status_emoji} Milestone: {milestone.title}")
        print("=" * 60)
        print(f"ID: {milestone.id}")
        print(f"Status: {milestone.status.value}")
        print(f"Priority: {milestone.priority.value}")
        if milestone.target:
            print(f"Target: {milestone.target}")
        if milestone.branch:
            print(f"Branch: {milestone.branch}")
        print(f"Progress: {progress:.0f}%")
        
        if milestone.subtasks:
            print(f"\nSubtasks ({len(milestone.subtasks)}):")
            for i, task in enumerate(milestone.subtasks, 1):
                task_emoji = self._get_status_emoji(task.status)
                print(f"  {i}. {task_emoji} {task.title}")
                print(f"     Status: {task.status.value} | Priority: {task.priority.value}")
                if task.branch:
                    print(f"     Branch: {task.branch}")
        
        print()
    
    def _show_task_status(self, task: Task, tracker: TaskTracker):
        """Display detailed status of a task."""
        status_emoji = self._get_status_emoji(task.status)
        
        print(f"{status_emoji} Task: {task.title}")
        print("=" * 60)
        print(f"ID: {task.id}")
        print(f"Status: {task.status.value}")
        print(f"Priority: {task.priority.value}")
        
        # Find parent milestone
        milestone = None
        for m in tracker.milestones:
            if m.id == task.parent_milestone:
                milestone = m
                break
        
        if milestone:
            print(f"Milestone: {milestone.title}")
        
        if task.branch:
            print(f"Branch: {task.branch}")
        if task.estimated_effort:
            print(f"Estimated Effort: {task.estimated_effort}")
        if task.assigned_to:
            print(f"Assigned To: {task.assigned_to}")
        if task.dependencies:
            print(f"Dependencies: {', '.join(task.dependencies)}")
        
        if task.tasks:
            print(f"\nTasks ({len(task.tasks)}):")
            for i, t in enumerate(task.tasks, 1):
                print(f"  {i}. {t}")
        
        if task.deliverables:
            print(f"\nDeliverables ({len(task.deliverables)}):")
            for i, d in enumerate(task.deliverables, 1):
                print(f"  {i}. {d}")
        
        if task.acceptance_criteria:
            print(f"\nAcceptance Criteria ({len(task.acceptance_criteria)}):")
            for i, ac in enumerate(task.acceptance_criteria, 1):
                print(f"  {i}. {ac}")
        
        print()
    
    def cmd_execute(self, args):
        """Execute the workflow for a task."""
        tracker = self.load_tracker()
        
        # Get the task to execute
        if args.task_id:
            task = tracker.get_task_by_id(args.task_id)
            if not task:
                print(f"❌ Error: No task found with ID '{args.task_id}'")
                return 1
        else:
            # Execute the next task
            task = tracker.get_next_work_item()
            if not task:
                print("✅ No actionable tasks found. All work is complete or blocked!")
                return 0
        
        print(f"🚀 Preparing to execute: {task.title}")
        print()
        
        # Get repository path
        repo_path = self.tracker_path.parent
        executor = TaskExecutor(str(repo_path))
        
        # Execute the workflow
        success = executor.execute_task(
            task,
            create_branch=not args.no_branch,
            generate_summary=not args.no_summary,
            base_branch=args.base_branch
        )
        
        return 0 if success else 1
    
    def _get_status_emoji(self, status: TaskStatus) -> str:
        """Get emoji for task status."""
        emoji_map = {
            TaskStatus.COMPLETE: "✅",
            TaskStatus.READY: "🚀",
            TaskStatus.QUEUED: "📅",
            TaskStatus.PLANNED: "📋",
            TaskStatus.IN_PROGRESS: "🚧",
            TaskStatus.BLOCKED: "🚫",
        }
        return emoji_map.get(status, "❓")
    
    def run(self):
        """Run the CLI application."""
        parser = argparse.ArgumentParser(
            description="Tasker - Identify and manage work items from TASK_TRACKER.md",
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
Examples:
  %(prog)s next              # Show the next actionable work item
  %(prog)s execute           # Execute workflow for next actionable task
  %(prog)s execute --task-id milestone-2-subtask-1  # Execute specific task
  %(prog)s list              # List all milestones and tasks
  %(prog)s list -v           # List with detailed subtask information
  %(prog)s status milestone-2  # Show status of a specific milestone
  %(prog)s status milestone-2-subtask-1  # Show status of a specific task
            """
        )
        
        parser.add_argument(
            "--tracker",
            help="Path to TASK_TRACKER.md file (default: auto-detect)"
        )
        
        subparsers = parser.add_subparsers(dest="command", help="Command to execute")
        
        # next command
        next_parser = subparsers.add_parser(
            "next",
            help="Show the next actionable work item"
        )
        
        # list command
        list_parser = subparsers.add_parser(
            "list",
            help="List all milestones and tasks"
        )
        list_parser.add_argument(
            "-v", "--verbose",
            action="store_true",
            help="Show detailed information including subtasks"
        )
        
        # status command
        status_parser = subparsers.add_parser(
            "status",
            help="Show status of a specific task or milestone"
        )
        status_parser.add_argument(
            "id",
            help="ID of the milestone or task"
        )
        
        # execute command
        execute_parser = subparsers.add_parser(
            "execute",
            help="Execute the workflow for a task (create branch, generate summary)"
        )
        execute_parser.add_argument(
            "--task-id",
            help="ID of the task to execute (default: next actionable task)"
        )
        execute_parser.add_argument(
            "--no-branch",
            action="store_true",
            help="Don't create a git branch"
        )
        execute_parser.add_argument(
            "--no-summary",
            action="store_true",
            help="Don't generate a task summary file"
        )
        execute_parser.add_argument(
            "--base-branch",
            default="dev",
            help="Base branch to branch from (default: dev)"
        )
        
        args = parser.parse_args()
        
        # Update tracker path if provided
        if args.tracker:
            self.tracker_path = Path(args.tracker)
        
        # Default to 'next' command if none specified
        if not args.command:
            args.command = "next"
        
        # Execute command
        if args.command == "next":
            return self.cmd_next(args)
        elif args.command == "list":
            return self.cmd_list(args)
        elif args.command == "status":
            return self.cmd_status(args)
        elif args.command == "execute":
            return self.cmd_execute(args)
        else:
            parser.print_help()
            return 1


def main():
    """Main entry point."""
    cli = TaskerCLI()
    sys.exit(cli.run())


if __name__ == "__main__":
    main()
