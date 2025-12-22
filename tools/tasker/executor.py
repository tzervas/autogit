"""
Executor module for automating task execution workflows.

This module provides functionality to:
- Create branches for identified tasks
- Update task status in TASK_TRACKER.md
- Generate task context and summaries
- Coordinate with the agent system
"""

import subprocess
from pathlib import Path
from typing import Optional
from datetime import datetime

from .models import Task, TaskStatus


class TaskExecutor:
    """Executor for automating task workflows."""
    
    def __init__(self, repo_path: str):
        """
        Initialize the executor.
        
        Args:
            repo_path: Path to the git repository root
        """
        self.repo_path = Path(repo_path)
    
    def create_branch_for_task(self, task: Task, base_branch: str = "dev", 
                              interactive: bool = True) -> bool:
        """
        Create a git branch for the given task.
        
        Args:
            task: The task to create a branch for
            base_branch: The base branch to branch from (default: dev)
            interactive: Whether to prompt user for input (default: True)
        
        Returns:
            True if successful, False otherwise
        """
        if not task.branch:
            print(f"⚠️  No branch name defined for task: {task.title}")
            return False
        
        # Clean up branch name (remove backticks if present)
        branch_name = task.branch.strip("`")
        
        try:
            # Check if we're in a git repo
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode != 0:
                print(f"❌ Not a git repository: {self.repo_path}")
                return False
            
            # Check if branch already exists
            result = subprocess.run(
                ["git", "rev-parse", "--verify", branch_name],
                cwd=self.repo_path,
                capture_output=True,
                text=True,
                check=False
            )
            
            if result.returncode == 0:
                print(f"ℹ️  Branch '{branch_name}' already exists")
                
                # Ask if user wants to checkout (only in interactive mode)
                if interactive:
                    response = input(f"Checkout existing branch '{branch_name}'? (y/n): ")
                    if response.lower() == 'y':
                        subprocess.run(
                            ["git", "checkout", branch_name],
                            cwd=self.repo_path,
                            check=True
                        )
                        print(f"✅ Checked out branch: {branch_name}")
                else:
                    # Non-interactive: just checkout the existing branch
                    subprocess.run(
                        ["git", "checkout", branch_name],
                        cwd=self.repo_path,
                        check=True
                    )
                    print(f"✅ Checked out existing branch: {branch_name}")
                return True
            
            # Fetch latest changes
            print(f"📥 Fetching latest changes from origin...")
            subprocess.run(
                ["git", "fetch", "origin"],
                cwd=self.repo_path,
                check=True
            )
            
            # Checkout base branch
            print(f"🔄 Checking out base branch: {base_branch}")
            subprocess.run(
                ["git", "checkout", base_branch],
                cwd=self.repo_path,
                check=True
            )
            
            # Pull latest changes
            print(f"📥 Pulling latest changes...")
            subprocess.run(
                ["git", "pull", "origin", base_branch],
                cwd=self.repo_path,
                check=True
            )
            
            # Create new branch
            print(f"🌿 Creating new branch: {branch_name}")
            subprocess.run(
                ["git", "checkout", "-b", branch_name],
                cwd=self.repo_path,
                check=True
            )
            
            print(f"✅ Successfully created and checked out branch: {branch_name}")
            print(f"🚀 Ready to start work on: {task.title}")
            
            return True
            
        except subprocess.CalledProcessError as e:
            print(f"❌ Git operation failed: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False
    
    def generate_task_summary(self, task: Task, output_path: Optional[str] = None) -> str:
        """
        Generate a detailed summary of the task for documentation.
        
        Args:
            task: The task to generate summary for
            output_path: Optional path to write summary to
        
        Returns:
            The generated summary as a string
        """
        summary = []
        summary.append(f"# Task Summary: {task.title}")
        summary.append("")
        summary.append(f"**Task ID**: {task.id}")
        summary.append(f"**Status**: {task.status.value}")
        summary.append(f"**Priority**: {task.priority.value}")
        summary.append(f"**Date Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        summary.append("")
        
        if task.branch:
            summary.append(f"**Branch**: `{task.branch.strip('`')}`")
            summary.append("")
        
        if task.estimated_effort:
            summary.append(f"**Estimated Effort**: {task.estimated_effort}")
            summary.append("")
        
        if task.assigned_to:
            summary.append(f"**Assigned To**: {task.assigned_to}")
            summary.append("")
        
        if task.dependencies:
            summary.append("## Dependencies")
            summary.append("")
            for dep in task.dependencies:
                summary.append(f"- {dep}")
            summary.append("")
        
        if task.tasks:
            summary.append("## Tasks")
            summary.append("")
            for i, t in enumerate(task.tasks, 1):
                summary.append(f"{i}. {t}")
            summary.append("")
        
        if task.deliverables:
            summary.append("## Deliverables")
            summary.append("")
            for deliverable in task.deliverables:
                summary.append(f"- {deliverable}")
            summary.append("")
        
        if task.acceptance_criteria:
            summary.append("## Acceptance Criteria")
            summary.append("")
            for criteria in task.acceptance_criteria:
                summary.append(f"- [ ] {criteria}")
            summary.append("")
        
        summary.append("## Getting Started")
        summary.append("")
        summary.append("1. Review the tasks and deliverables above")
        summary.append("2. Check dependencies are met")
        summary.append("3. Create work items as needed")
        summary.append("4. Begin implementation")
        summary.append("5. Test thoroughly")
        summary.append("6. Update documentation")
        summary.append("7. Mark acceptance criteria as complete")
        summary.append("")
        
        summary_text = "\n".join(summary)
        
        if output_path:
            output_file = Path(output_path)
            output_file.write_text(summary_text)
            print(f"✅ Task summary written to: {output_path}")
        
        return summary_text
    
    def execute_task(self, task: Task, create_branch: bool = True, 
                    generate_summary: bool = True, base_branch: str = "dev",
                    interactive: bool = True) -> bool:
        """
        Execute the complete workflow for starting work on a task.
        
        Args:
            task: The task to execute
            create_branch: Whether to create a git branch
            generate_summary: Whether to generate a task summary file
            base_branch: The base branch to branch from
            interactive: Whether to allow interactive prompts (default: True)
        
        Returns:
            True if successful, False otherwise
        """
        print(f"🚀 Executing workflow for task: {task.title}")
        print("=" * 60)
        
        success = True
        
        # Create branch
        if create_branch:
            if not self.create_branch_for_task(task, base_branch, interactive):
                success = False
                print("⚠️  Branch creation failed, but continuing...")
        
        # Generate summary
        if generate_summary:
            summary_filename = f"TASK_SUMMARY_{task.id}.md"
            summary_path = self.repo_path / summary_filename
            self.generate_task_summary(task, str(summary_path))
        
        print()
        print("=" * 60)
        print("✅ Task execution workflow complete!")
        print()
        print("Next steps:")
        print("1. Review the task summary")
        print("2. Begin implementing the deliverables")
        print("3. Follow the acceptance criteria")
        print("4. Create PRs as work is completed")
        
        return success
