# Copilot Web UI Agent Workflow Implementation Guide

**Last Updated**: 2025-12-21
**Status**: Active

## Overview

This document describes how to implement and use the AutoGit multiagent workflow in the GitHub Copilot web UI environment.

## Agent Discovery in Copilot Web UI

GitHub Copilot web UI automatically discovers agent configuration files in the `.github/agents/` directory. The system follows this hierarchy:

1. **Primary Agent File**: `.github/agents/agent.md` (root orchestrator)
2. **Specialized Agent Files**: Other `.md` files in `.github/agents/`
3. **Shared Context**: `.github/agents/shared-context.md` (referenced by all agents)

## How Copilot Web UI Uses Agents

### Agent File Detection

Copilot web UI reads all markdown files in `.github/agents/` and uses them as context for AI-assisted development. The files are read in this priority:

1. **agent.md** - Primary agent configuration (always loaded)
2. **Other agent files** - Loaded based on task context
3. **shared-context.md** - Common context (loaded when referenced)

### Agent Invocation

There are several ways agents can be invoked in Copilot web UI:

#### 1. Implicit Invocation (Recommended)

The root agent automatically delegates based on task type:

```markdown
# User request to Copilot
"Implement GPU detection for NVIDIA cards"

# Copilot reads agent.md which instructs:
# 1. Root agent analyzes request
# 2. Delegates to Project Manager to break down task
# 3. Project Manager creates subtasks
# 4. Software Engineer implements code
# 5. DevOps Engineer updates Docker configs
# 6. Security Engineer reviews
# 7. Documentation Engineer updates docs
# 8. Evaluator does final review
```

#### 2. Explicit Agent Mention (Optional)

You can explicitly mention an agent in your request:

```markdown
# Direct invocation
"@software-engineer: Please implement the GPU detection class"
"@documentation-engineer: Update the GPU documentation"
"@evaluator: Review this PR for code quality"
```

#### 3. Context-Based Selection (Automatic)

Copilot automatically selects relevant agents based on:
- File type being edited (`.py` → Software Engineer)
- Directory location (`docs/` → Documentation Engineer)
- Task keywords ("deploy", "docker" → DevOps Engineer)
- Security keywords ("vulnerability", "auth" → Security Engineer)

## Workflow Patterns in Copilot Web UI

### Pattern 1: Feature Implementation

**User Request**: "Add support for AMD GPUs"

**Agent Workflow**:
1. **Root Agent** reads request, delegates to Project Manager
2. **Project Manager** creates task breakdown:
   ```markdown
   ## Task 1: Design GPU Detection Interface
   Assigned: Software Engineer

   ## Task 2: Implement AMD Detection
   Assigned: Software Engineer

   ## Task 3: Add Docker Configuration
   Assigned: DevOps Engineer

   ## Task 4: Security Review
   Assigned: Security Engineer

   ## Task 5: Update Documentation
   Assigned: Documentation Engineer
   ```
3. Each agent executes their task in sequence
4. **Evaluator** reviews final work

### Pattern 2: Bug Fix

**User Request**: "Fix the runner provisioning timeout"

**Agent Workflow**:
1. **Root Agent** → **Software Engineer** (primary)
2. **Software Engineer**:
   - Analyzes code
   - Identifies issue
   - Implements fix
   - Writes tests
3. **Evaluator** verifies fix works
4. **Documentation Engineer** updates troubleshooting docs if needed

### Pattern 3: Documentation Update

**User Request**: "Update the installation guide for Kubernetes"

**Agent Workflow**:
1. **Root Agent** → **Documentation Engineer** (primary)
2. **Documentation Engineer**:
   - Reviews current docs
   - Updates content
   - Checks links
   - Updates INDEX.md
3. **DevOps Engineer** reviews for technical accuracy
4. **Evaluator** approves changes

### Pattern 4: Infrastructure Change

**User Request**: "Update the Helm chart to support GPU workloads"

**Agent Workflow**:
1. **Root Agent** → **DevOps Engineer** (primary)
2. **DevOps Engineer**:
   - Updates Helm templates
   - Adds GPU device plugin config
   - Tests in staging
3. **Security Engineer** reviews security implications
4. **Documentation Engineer** updates installation docs
5. **Evaluator** verifies deployment works

## Best Practices for Copilot Web UI

### 1. Clear Task Descriptions

✅ **Good**:
```markdown
"Implement GPU detection for NVIDIA GPUs with the following requirements:
- Detect using nvidia-smi
- Return GPU model and memory
- Handle cases where nvidia-smi is not available
- Write tests with 80%+ coverage"
```

❌ **Bad**:
```markdown
"Add GPU stuff"
```

### 2. Reference Relevant Agents

When you know which agent should handle the task:

```markdown
"@project-manager: Please create a task breakdown for implementing SSO with Authelia"
"@security-engineer: Review this authentication implementation for vulnerabilities"
```

### 3. Provide Context

Help agents understand the bigger picture:

```markdown
"We need to add ARM64 support to our Docker images.
This is part of the multi-architecture support feature in v1.1.
Current implementation only supports AMD64.
See docs/architecture/adr/003-multi-architecture.md for context."
```

### 4. Request Specific Outputs

Be explicit about what you want:

```markdown
"@software-engineer: Implement the GPU detection class and provide:
- Working code with type hints
- Unit tests with 80%+ coverage
- Docstrings with examples
- Update docs/api/gpu-detector.md"
```

### 5. Use Checkpoints

For large tasks, work through agents sequentially:

```markdown
# First request
"@project-manager: Create a detailed task breakdown for adding Kubernetes support"

# Review output, then next request
"@devops-engineer: Implement task 1 from the plan - create base Helm chart structure"

# Continue through tasks
"@security-engineer: Review the Helm chart for security issues"
```

## Agent Interaction Examples

### Example 1: New Feature Development

```markdown
# Step 1: Planning
User: "We need to add support for Intel GPUs. Can you help plan this?"

Root Agent → Project Manager:
"I'll break this down into tasks:

1. Research Intel GPU detection (oneAPI)
2. Implement detection code
3. Add to Docker Compose
4. Create Kubernetes device plugin
5. Write tests
6. Update documentation
7. Security review"

# Step 2: Implementation
User: "@software-engineer: Implement task 2 - Intel GPU detection"

Software Engineer:
"I'll create the Intel GPU detector:
- Class: IntelGPUDetector
- Method: detect() -> List[GPUInfo]
- Detection: Check /dev/dri/card* devices
- Tests included"

# Step 3: Review
User: "@evaluator: Review the Intel GPU implementation"

Evaluator:
"Code review complete:
✅ Implements requirements
✅ Tests pass (85% coverage)
✅ Follows coding standards
⚠️  Documentation needs example
Status: APPROVED with minor fix"
```

### Example 2: Multi-Agent Collaboration

```markdown
User: "Implement runner autoscaling with the following flow:
1. Monitor job queue
2. Provision runners when queue > threshold
3. Deprovision idle runners
Please coordinate across teams."

Root Agent:
"This requires multiple agents. I'll coordinate:

@project-manager: Create detailed task breakdown
@software-engineer: Implement autoscaling logic
@devops-engineer: Configure monitoring and alerts
@security-engineer: Review resource limits and isolation
@documentation-engineer: Create operations guide
@evaluator: Final review and integration testing"

[Each agent then executes their part with full context]
```

## Troubleshooting

### Issue: Agent Not Following Instructions

**Problem**: Agent ignores specialized configuration

**Solution**:
1. Verify `.github/agents/agent.md` exists and is valid markdown
2. Check agent file references shared-context.md correctly
3. Explicitly mention agent: `@software-engineer: ...`
4. Ensure task description is clear and specific

### Issue: Agents Not Coordinating

**Problem**: Multiple agents working on same task, duplicating work

**Solution**:
1. Use root agent to delegate: Let `agent.md` coordinate
2. Be explicit about which agent should be primary
3. Use checkpoints - complete one agent's work before next

### Issue: Agent Missing Context

**Problem**: Agent doesn't have necessary project context

**Solution**:
1. Ensure `shared-context.md` is complete and up-to-date
2. Reference relevant documentation in request
3. Point to ADRs for architectural context
4. Include links to related code/docs

## Maintaining Agent Configuration

### When to Update Agent Files

Update agent configurations when:

- ✅ Adding new project components
- ✅ Changing development standards
- ✅ Adding new tools or technologies
- ✅ Updating architecture patterns
- ✅ Modifying workflow processes

### How to Test Agent Changes

1. **Small change testing**:
   ```markdown
   "Test: @software-engineer, what coding standards do you follow?"
   [Verify response matches updated standards]
   ```

2. **Full workflow testing**:
   ```markdown
   "Please implement a small test feature end-to-end"
   [Verify all agents participate correctly]
   ```

3. **Documentation sync**:
   ```markdown
   "@documentation-engineer: Verify all docs match current code"
   [Check that agent catches discrepancies]
   ```

## Advanced Usage

### Custom Agent Workflows

You can create custom workflows by combining agents:

```markdown
# Custom workflow for critical security fix
User: "Critical security fix needed - SQL injection in user input"

Root Agent workflow:
1. @security-engineer: Assess vulnerability impact (IMMEDIATE)
2. @software-engineer: Implement fix + tests (PARALLEL)
3. @evaluator: Verify fix works (BLOCKING)
4. @documentation-engineer: Update security docs (PARALLEL)
5. @devops-engineer: Prepare hotfix deployment (AFTER EVAL)
```

### Parallel Agent Execution

Some tasks can be done in parallel:

```markdown
User: "We need to prepare the v1.1 release"

Root Agent: "I'll coordinate parallel work:

GROUP 1 (Parallel):
- @software-engineer: Finalize code changes
- @documentation-engineer: Update CHANGELOG and docs
- @devops-engineer: Prepare release Helm chart

GROUP 2 (After Group 1):
- @security-engineer: Final security scan
- @evaluator: Release candidate testing

GROUP 3 (After Group 2):
- @devops-engineer: Tag and publish release"
```

## Measuring Effectiveness

Track these metrics to measure multiagent workflow effectiveness:

- **Task completion time**: From request to merge
- **Review cycles**: Number of revisions needed
- **Documentation completeness**: % of changes with doc updates
- **Code quality**: Test coverage, linting results
- **Agent utilization**: Which agents are most/least used
- **Handoff efficiency**: Time between agent transitions

## References

- [Root Agent Configuration](agent.md)
- [Shared Agent Context](shared-context.md)
- [Agentic Workflow Guide](../../docs/development/agentic-workflow.md)
- Individual Agent Files:
  - [Project Manager](project-manager.md)
  - [Software Engineer](software-engineer.md)
  - [DevOps Engineer](devops-engineer.md)
  - [Security Engineer](security-engineer.md)
  - [Documentation Engineer](documentation-engineer.md)
  - [Evaluator](evaluator.md)

## Getting Help

If you're having issues with the multiagent workflow:

1. Check this guide first
2. Review individual agent configuration files
3. Test with simple tasks before complex ones
4. Ask for clarification: "How should I structure this request for the agents?"
5. Open an issue with details about the problem

---

**Remember**: The multiagent system works best when you provide clear, specific requests and allow the root agent to coordinate the workflow!
