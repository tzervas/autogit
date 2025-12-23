# Tasker - Task Tracker Work Item Identification and Execution

Tasker is a command-line tool that parses `TASK_TRACKER.md`, identifies the next actionable work item, and automates task execution workflows.

## Features

- **Task Identification**: Automatically identifies the next actionable work item based on priority and dependencies
- **Task Parsing**: Parses TASK_TRACKER.md into structured data models
- **Task Listing**: Lists all milestones and tasks with status and progress
- **Task Status**: Shows detailed information about specific tasks or milestones
- **Task Execution**: Automates workflows including:
  - Creating git branches for tasks
  - Generating task summary documents
  - Setting up work environment

## Installation

The tool is part of the AutoGit repository and requires Python 3.7+.

```bash
# From the repository root
cd /path/to/autogit

# The tool is ready to use
python3 -m tools.tasker --help
```

## Usage

### Show Next Actionable Task

Identify the next task that is ready to be worked on:

```bash
python3 -m tools.tasker next
```

Output:
```
🎯 Next Work Item Identified
============================================================

📋 Task: Docker Setup and Configuration
🆔 ID: milestone-2-subtask-1
📊 Status: READY
⭐ Priority: High
📦 Milestone: Git Server Implementation
🌿 Branch: git-server-implementation-docker-setup
⏱️  Estimated Effort: 4-6 days
👤 Assigned To: DevOps Engineer + Software Engineer

📝 Tasks (10):
   1. Create Dockerfile for GitLab CE (AMD64 native - MVP)
   2. Add multi-arch build files (AMD64, ARM64, RISC-V) for future
   ...
```

### Execute Task Workflow

Execute the complete workflow for starting work on a task:

```bash
# Execute the next actionable task
python3 -m tools.tasker execute

# Execute a specific task by ID
python3 -m tools.tasker execute --task-id milestone-2-subtask-1

# Execute without creating a branch
python3 -m tools.tasker execute --no-branch

# Execute with a different base branch
python3 -m tools.tasker execute --base-branch main
```

This will:
1. Identify the task (next or specified)
2. Create a git branch for the task (unless `--no-branch`)
3. Generate a task summary document (unless `--no-summary`)
4. Provide next steps guidance

### List All Tasks

List all milestones and tasks:

```bash
# Basic list
python3 -m tools.tasker list

# Detailed list with subtasks
python3 -m tools.tasker list -v
```

Output:
```
📊 Task Tracker Overview
============================================================
Last Updated: 2025-12-21
Current Phase: Post-Documentation MVP Implementation

Total Milestones: 6

✅ Documentation Foundation
   ID: milestone-1
   Status: COMPLETE
   Priority: Medium
   Progress: 100% (8/8 subtasks)

📋 Git Server Implementation
   ID: milestone-2
   Status: PLANNED
   Priority: High
   Progress: 0% (0/8 subtasks)
   Subtasks:
      🚀 Docker Setup and Configuration (READY)
      📅 Basic Authentication Setup (QUEUED)
      ...
```

### Show Task Status

Show detailed status of a specific task or milestone:

```bash
# Show milestone status
python3 -m tools.tasker status milestone-2

# Show task status
python3 -m tools.tasker status milestone-2-subtask-1
```

## Commands

### `next`
Show the next actionable work item based on priority and dependencies.

### `execute`
Execute the workflow for starting work on a task.

**Options:**
- `--task-id ID`: Execute a specific task (default: next actionable task)
- `--no-branch`: Don't create a git branch
- `--no-summary`: Don't generate a task summary file
- `--base-branch BRANCH`: Base branch to branch from (default: dev)

### `list`
List all milestones and tasks.

**Options:**
- `-v, --verbose`: Show detailed information including subtasks

### `status`
Show status of a specific task or milestone.

**Arguments:**
- `id`: ID of the milestone or task (e.g., `milestone-2`, `milestone-2-subtask-1`)

## Task Identification Logic

The tool identifies the next actionable work item using the following logic:

1. **Filter by Status**: Only considers tasks with status `READY` or `QUEUED`
2. **Priority Sorting**: Sorts milestones by priority (HIGH > MEDIUM > LOW)
3. **Sequential Selection**: Selects the first ready task from the highest priority milestone
4. **Dependency Awareness**: Considers task dependencies (though dependency resolution is basic)

## Data Models

### Task
Represents a task or subtask with:
- ID, title, status, priority
- Branch name, estimated effort, assigned team
- Dependencies, tasks, deliverables, acceptance criteria

### Milestone
Represents a milestone containing multiple tasks with:
- ID, title, status, priority, target date
- Collection of subtasks
- Progress calculation

### TaskTracker
Root object containing all milestones and providing query methods.

## File Structure

```
tools/tasker/
├── __init__.py          # Package initialization
├── __main__.py          # Module entry point
├── cli.py               # Command-line interface
├── models.py            # Data models (Task, Milestone, TaskTracker)
├── parser.py            # TASK_TRACKER.md parser
├── executor.py          # Task execution automation
└── README.md            # This file
```

## Examples

### Example Workflow

1. Check what task is next:
   ```bash
   python3 -m tools.tasker next
   ```

2. Execute the task workflow:
   ```bash
   python3 -m tools.tasker execute
   ```

3. Start working on the task (branch is created, summary is generated)

4. Check task status later:
   ```bash
   python3 -m tools.tasker status milestone-2-subtask-1
   ```

### Integration with CI/CD

The tool can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Identify next task
  run: |
    python3 -m tools.tasker next

- name: Execute task
  run: |
    python3 -m tools.tasker execute --no-branch
```

## Development

### Adding New Features

To add new features to the tasker tool:

1. Update data models in `models.py` if needed
2. Update parser in `parser.py` to extract new data
3. Add new commands to `cli.py`
4. Add execution logic to `executor.py`

### Testing

```bash
# Test parsing
python3 -m tools.tasker list -v

# Test identification
python3 -m tools.tasker next

# Test status queries
python3 -m tools.tasker status milestone-2

# Test execution (dry run)
python3 -m tools.tasker execute --no-branch --no-summary
```

## Limitations

- **Basic Dependency Resolution**: Dependencies are parsed but not deeply validated
- **Status Updates**: The tool doesn't update task status in TASK_TRACKER.md (manual update required)
- **Markdown Parsing**: Parser assumes specific markdown format; deviations may cause issues
- **Git Operations**: Requires git to be installed and repository to be initialized

## Future Enhancements

- [ ] Automated status updates in TASK_TRACKER.md
- [ ] Advanced dependency resolution and validation
- [ ] Integration with agent system for automated execution
- [ ] Web UI for task management
- [ ] Task time tracking and estimation refinement
- [ ] Automated PR creation
- [ ] Team coordination features

## License

MIT License - See LICENSE file for details.

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.
