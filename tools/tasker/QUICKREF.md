# Tasker Quick Reference

## Installation
No installation needed - run directly from repository:
```bash
cd /path/to/autogit
python3 -m tools.tasker --help
```

## Commands

### Show Next Task
```bash
python3 -m tools.tasker next
```
Displays the next actionable work item with full details.

### Execute Task Workflow
```bash
# Execute next task
python3 -m tools.tasker execute

# Execute specific task
python3 -m tools.tasker execute --task-id milestone-2-subtask-1

# Skip branch creation
python3 -m tools.tasker execute --no-branch

# Use different base branch
python3 -m tools.tasker execute --base-branch main
```
Creates branch and generates task summary.

### List Tasks
```bash
# Basic list
python3 -m tools.tasker list

# Detailed with subtasks
python3 -m tools.tasker list -v
```
Shows all milestones and tasks with status.

### Show Status
```bash
# Milestone status
python3 -m tools.tasker status milestone-2

# Task status
python3 -m tools.tasker status milestone-2-subtask-1
```
Detailed view of specific task or milestone.

## Common Workflows

### Daily Workflow
```bash
# 1. Check next task
python3 -m tools.tasker next

# 2. Start working on it
python3 -m tools.tasker execute

# 3. Begin implementation
# (branch is created, summary is generated)
```

### Project Status Check
```bash
# Overview of all milestones
python3 -m tools.tasker list -v

# Check specific milestone
python3 -m tools.tasker status milestone-2
```

### Task Details
```bash
# Get full task details
python3 -m tools.tasker status milestone-2-subtask-1

# Shows:
# - All tasks to complete
# - Deliverables
# - Acceptance criteria
# - Dependencies
# - Estimates
```

## Key Features

✅ **Intelligent Task Identification**
- Priority-based selection
- Status filtering (READY/QUEUED)
- Dependency awareness

✅ **Workflow Automation**
- Branch creation
- Summary generation
- Next steps guidance

✅ **Project Visibility**
- Progress tracking
- Status overview
- Milestone management

## Status Indicators

- ✅ COMPLETE - Task is done
- 🚀 READY - Ready to start now
- 📅 QUEUED - Waiting for dependencies
- 📋 PLANNED - Future work
- 🚧 IN_PROGRESS - Currently being worked on
- 🚫 BLOCKED - Cannot proceed

## Task Identification Logic

1. Filter by status (READY or QUEUED only)
2. Sort by priority (HIGH > MEDIUM > LOW)
3. Select first READY task from highest priority milestone
4. If no READY tasks, select first QUEUED task

## Files Generated

- `TASK_SUMMARY_<task-id>.md` - Task summary (in repo root)
  - Auto-generated when using `execute` command
  - Contains all task details
  - Use as reference while working

## Tips

💡 **Start of day**: Run `next` to see what's coming up
💡 **Before starting work**: Run `execute` to set up properly
💡 **During sprint**: Use `list -v` to track progress
💡 **In standup**: Reference task IDs from `list` output
💡 **CI/CD**: Use `execute --no-branch` to generate summaries

## Help

```bash
# General help
python3 -m tools.tasker --help

# Command-specific help
python3 -m tools.tasker next --help
python3 -m tools.tasker execute --help
python3 -m tools.tasker list --help
python3 -m tools.tasker status --help
```

## Documentation

- **Full Guide**: `tools/tasker/README.md`
- **Documentation**: `docs/tools/tasker.md`
- **Demo Script**: `tools/tasker/demo.sh`

## Examples

```bash
# Quick status check
python3 -m tools.tasker next

# Start new work
python3 -m tools.tasker execute

# Check project progress
python3 -m tools.tasker list

# Review milestone
python3 -m tools.tasker status milestone-2

# See specific task
python3 -m tools.tasker status milestone-2-subtask-1

# Execute specific task
python3 -m tools.tasker execute --task-id milestone-2-subtask-2
```
