#!/bin/bash
# Demo script for the Tasker tool
# This demonstrates the key features of the Tasker tool

echo "======================================================================"
echo "                    TASKER TOOL DEMONSTRATION"
echo "======================================================================"
echo ""
echo "The Tasker tool helps identify and execute work items from"
echo "TASK_TRACKER.md, automating common workflows."
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 1: Show next task
echo "📋 DEMO 1: Show the next actionable work item"
echo "Command: python3 -m tools.tasker next"
echo ""
python3 -m tools.tasker next
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 2: List all tasks
echo "📊 DEMO 2: List all milestones and tasks"
echo "Command: python3 -m tools.tasker list"
echo ""
python3 -m tools.tasker list | head -40
echo ""
echo "(output truncated for brevity)"
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 3: Detailed list
echo "📋 DEMO 3: List all tasks with subtask details"
echo "Command: python3 -m tools.tasker list -v"
echo ""
python3 -m tools.tasker list -v | head -50
echo ""
echo "(output truncated for brevity)"
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 4: Status of a milestone
echo "🔍 DEMO 4: Show status of a specific milestone"
echo "Command: python3 -m tools.tasker status milestone-2"
echo ""
python3 -m tools.tasker status milestone-2
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 5: Status of a task
echo "🔍 DEMO 5: Show status of a specific task"
echo "Command: python3 -m tools.tasker status milestone-2-subtask-1"
echo ""
python3 -m tools.tasker status milestone-2-subtask-1
echo ""
echo "----------------------------------------------------------------------"
echo ""

# Demo 6: Execute (dry run)
echo "🚀 DEMO 6: Execute task workflow (no branch, just summary)"
echo "Command: python3 -m tools.tasker execute --no-branch"
echo ""
python3 -m tools.tasker execute --no-branch
echo ""
echo "Generated file: TASK_SUMMARY_milestone-2-subtask-1.md"
echo ""

# Show the generated summary
if [ -f "TASK_SUMMARY_milestone-2-subtask-1.md" ]; then
    echo "Content of generated summary (first 20 lines):"
    echo ""
    head -20 TASK_SUMMARY_milestone-2-subtask-1.md
    echo ""
    echo "(file truncated for brevity)"
    echo ""
    
    # Clean up
    rm -f TASK_SUMMARY_milestone-2-subtask-1.md
    echo "Cleaned up temporary file."
fi

echo ""
echo "----------------------------------------------------------------------"
echo ""
echo "✅ DEMONSTRATION COMPLETE"
echo ""
echo "Key Features Demonstrated:"
echo "  1. ✓ Next task identification"
echo "  2. ✓ Task listing with progress"
echo "  3. ✓ Detailed status views"
echo "  4. ✓ Task workflow execution"
echo "  5. ✓ Automated summary generation"
echo ""
echo "For more information:"
echo "  - Run: python3 -m tools.tasker --help"
echo "  - Read: tools/tasker/README.md"
echo "  - Read: docs/tools/tasker.md"
echo ""
echo "======================================================================"
