# Tasker Tool Documentation

## Overview

The Tasker tool is a command-line utility that helps manage and execute work items from the project's task tracker. It parses `TASK_TRACKER.md`, identifies the next actionable work item, and automates common workflows like branch creation and task setup.

## Purpose

In a large project with multiple milestones and subtasks, it can be challenging to:
- Identify what to work on next
- Keep track of task priorities and dependencies
- Follow consistent workflows when starting new tasks
- Maintain visibility into project progress

The Tasker tool solves these problems by:
1. **Parsing** the task tracker into structured data
2. **Identifying** the next actionable work item based on priority and status
3. **Automating** common workflows (branch creation, summary generation)
4. **Providing** clear visibility into project status and progress

## Quick Start

```bash
# Show the next actionable task
python3 -m tools.tasker next

# Execute workflow for the next task
python3 -m tools.tasker execute

# List all tasks
python3 -m tools.tasker list -v
```

## Commands

- **next** - Show the next actionable work item
- **execute** - Execute workflow for a task (create branch, generate summary)
- **list** - List all milestones and tasks
- **status** - Show detailed status of a specific task or milestone

## Documentation

For complete documentation, see [tools/tasker/README.md](../../tools/tasker/README.md)

## Use Cases

### Daily Workflow
1. Check what task is next
2. Execute the task workflow  
3. Begin working on the task

### Project Management
1. Review milestone progress
2. Identify upcoming tasks
3. Track project status

### CI/CD Integration
Automate task identification and setup in CI/CD pipelines

## Examples

```bash
# Show next task
python3 -m tools.tasker next

# Execute next task workflow
python3 -m tools.tasker execute

# Execute specific task
python3 -m tools.tasker execute --task-id milestone-2-subtask-1

# List all tasks with details
python3 -m tools.tasker list -v

# Check milestone status
python3 -m tools.tasker status milestone-2
```
