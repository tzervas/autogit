# AutoGit AI Agent System

This directory contains the AI agent configuration files for GitHub Copilot. The system uses a
**multiagent architecture** where specialized agents collaborate to deliver high-quality code,
infrastructure, and documentation.

## Quick Start

### For Users

When working with GitHub Copilot on AutoGit:

1. **Start with clear requests**: "Implement GPU detection for NVIDIA cards"
1. **Let the root agent coordinate**: It will automatically delegate to specialized agents
1. **Review at checkpoints**: Ask to pause for review between major steps
1. **Explicitly invoke if needed**: Use `@agent-name` for specific agents

**Example**:

```markdown
"We need to add ARM64 architecture support to our runners.
Please coordinate across all agents to implement this completely."
```

The root agent will orchestrate Project Manager → Software Engineer → DevOps → Security →
Documentation → Evaluator.

### For Developers

If you're modifying the agent system:

1. Read `TESTING-GUIDE.md` for verification procedures
1. Update `shared-context.md` when changing project standards
1. Test changes using the 5-test framework
1. Update individual agent files for specialized behaviors

## Agent Files

### Core Configuration

| File                  | Purpose             | Size | Role                                       |
| --------------------- | ------------------- | ---- | ------------------------------------------ |
| **agent.md**          | Root orchestrator   | 11KB | Coordinates all agents, handles delegation |
| **shared-context.md** | Common requirements | 12KB | Project standards, shared by all agents    |

### Specialized Agents

| File                          | Expert In              | When Used                                 | Size |
| ----------------------------- | ---------------------- | ----------------------------------------- | ---- |
| **project-manager.md**        | Planning, coordination | Task breakdown, sprint planning           | 11KB |
| **software-engineer.md**      | Code, tests            | Implementation, debugging, code review    | 16KB |
| **devops-engineer.md**        | Infrastructure, CI/CD  | Deployment, Docker, Kubernetes, pipelines | 12KB |
| **security-engineer.md**      | Security, compliance   | Security review, vulnerability assessment | 11KB |
| **documentation-engineer.md** | Documentation          | Writing/updating docs, ADRs, guides       | 13KB |
| **evaluator.md**              | Quality assurance      | Code review, testing, final approval      | 13KB |

### Guides

| File                        | Purpose                       | Audience   |
| --------------------------- | ----------------------------- | ---------- |
| **COPILOT-WEB-UI-GUIDE.md** | How to use agents in Copilot  | All users  |
| **TESTING-GUIDE.md**        | Multi-agent testing framework | Developers |
| **README.md**               | This file - overview          | Everyone   |

### Reference

| File                  | Purpose                                    |
| --------------------- | ------------------------------------------ |
| **agent-original.md** | Backup of original monolithic agent (24KB) |

## Architecture

### Hierarchical Structure

```
┌─────────────────────────────────────────────┐
│         Root Agent (agent.md)               │
│    Analyzes requests & delegates            │
└─────────────────┬───────────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
┌─────▼──────┐       ┌───────▼────────┐
│  Shared    │◄──────┤  Specialized   │
│  Context   │       │    Agents      │
│            │       │                │
│ Standards  │       │ • Project Mgr  │
│ Principles │       │ • Software Eng │
│ Components │       │ • DevOps Eng   │
│ License    │       │ • Security Eng │
│ Testing    │       │ • Doc Eng      │
│ Security   │       │ • Evaluator    │
└────────────┘       └────────────────┘
```

### Workflow Patterns

#### Pattern 1: Full Orchestration (Default)

```
User Request → Root Agent → [Agent 1 → Agent 2 → ... → Agent N] → Complete
```

#### Pattern 2: Checkpoint Mode

```
User Request → Root Agent → Agent 1 → [Pause for Review]
             → User "continue" → Agent 2 → [Pause] → ...
```

#### Pattern 3: Manual Delegation

```
User "@project-manager: create plan" → Plan Created
User "@software-engineer: implement task 1" → Implementation
User "@evaluator: review" → Review & Approve
```

## Copilot Web UI Considerations

### Context Loading

To optimize for Copilot's context window:

1. **Always Loaded**: agent.md (root) + shared-context.md
1. **Load on Demand**: Specialized agents based on keywords
1. **Explicit Loading**: User can request specific agent with `@agent-name`

### Keywords for Automatic Agent Selection

| Keywords in Request           | Agent Loaded           |
| ----------------------------- | ---------------------- |
| plan, tasks, breakdown        | Project Manager        |
| implement, code, test         | Software Engineer      |
| deploy, docker, kubernetes    | DevOps Engineer        |
| security, auth, vulnerability | Security Engineer      |
| document, guide, readme       | Documentation Engineer |
| review, approve, quality      | Evaluator              |

### Known Limitations

1. **Sequential Execution**: Agents work one at a time (not parallel)
1. **Context Window**: Large requests may need multiple sessions
1. **No State Persistence**: Use commits and files to track state
1. **No Direct Agent Communication**: Root agent coordinates all

See `TESTING-GUIDE.md` for workarounds.

## Testing Multi-Agent Workflows

Execute these tests to verify the system works correctly:

### Test 1: Simple Delegation

```markdown
"What coding standards should I follow?"
```

Expected: Root agent → Software Engineer → PEP 8, Black, type hints

### Test 2: Multi-Agent Coordination

```markdown
"Add a new configuration option for runner timeout"
```

Expected: All relevant agents participate in sequence

### Test 3: Context Retention

```markdown
Request 1: "@project-manager: Create task plan for feature X"
Request 2: "@software-engineer: Implement task #1 from the plan"
```

Expected: Software Engineer references the specific task

### Test 4: Shared Context

```markdown
Ask multiple agents: "What architecture principles do we follow?"
```

Expected: Consistent SOLID/DRY/KISS answers from all agents

### Test 5: Complex Feature

```markdown
"Implement runner autoscaling based on job queue depth"
```

Expected: Complete end-to-end workflow with all 6 agents

See `TESTING-GUIDE.md` for detailed test procedures.

## Maintenance

### When to Update Agents

Update agent files when:

- ✅ Adding new project components
- ✅ Changing development standards
- ✅ Adding new tools/technologies
- ✅ Updating architecture patterns
- ✅ Modifying workflow processes

### How to Update

1. **Shared Context** (`shared-context.md`): Common standards
1. **Specialized Agents**: Domain-specific behaviors
1. **Root Agent** (`agent.md`): Coordination logic
1. **Test**: Run verification tests
1. **Document**: Update this README if structure changes

### Quality Checklist

Before finalizing changes:

- [ ] All agent files are valid markdown
- [ ] Each agent references shared-context.md
- [ ] No circular dependencies
- [ ] Total size reasonable (< 100KB when all loaded)
- [ ] Tested with Test 1-5 framework
- [ ] Documentation updated
- [ ] Examples still work

## File Sizes

| File                      | Lines      | Size       | Load            |
| ------------------------- | ---------- | ---------- | --------------- |
| agent.md                  | ~310       | 11KB       | Always          |
| shared-context.md         | ~460       | 12KB       | On demand       |
| project-manager.md        | ~380       | 11KB       | On demand       |
| software-engineer.md      | ~560       | 16KB       | On demand       |
| devops-engineer.md        | ~430       | 12KB       | On demand       |
| security-engineer.md      | ~400       | 11KB       | On demand       |
| documentation-engineer.md | ~450       | 13KB       | On demand       |
| evaluator.md              | ~480       | 13KB       | On demand       |
| COPILOT-WEB-UI-GUIDE.md   | ~420       | 12KB       | Reference       |
| TESTING-GUIDE.md          | ~490       | 14KB       | Reference       |
| **Total**                 | **~4,380** | **~125KB** | **Lazy loaded** |

## Examples

### Example 1: Feature Request

**User**: "Add support for AMD GPUs"

**Root Agent Response**:

```markdown
I'll coordinate this feature across multiple agents:

1. @project-manager: Breaking down into tasks
   - Design GPU detection interface
   - Implement AMD detection logic
   - Add Docker configuration
   - Create Kubernetes device plugin
   - Write documentation
   - Security review

2. @software-engineer: Implementing AMD detection
   [Code implementation with tests]

3. @devops-engineer: Adding infrastructure support
   [Docker Compose and Helm chart updates]

4. @security-engineer: Reviewing security
   [Security assessment complete]

5. @documentation-engineer: Updating documentation
   [docs/gpu/amd.md updated]

6. @evaluator: Final quality review
   ✅ All tests pass, documentation complete, approved
```

### Example 2: Bug Fix

**User**: "Fix the runner provisioning timeout issue"

**Root Agent Response**:

```markdown
@software-engineer: Analyzing and fixing the timeout issue
[Analysis, fix, tests]

@evaluator: Verifying the fix
✅ Timeout issue resolved, tests passing
```

### Example 3: Documentation Update

**User**: "@documentation-engineer: Update the Kubernetes installation guide"

**Documentation Engineer Response**:

```markdown
Updating docs/installation/kubernetes.md:
- Added ARM64 support instructions
- Updated Helm chart version to v1.2.0
- Added GPU configuration section
- Verified all links work
- Updated docs/INDEX.md

✅ Documentation updated and ready for review
```

## Getting Help

### For Issues

1. Check `COPILOT-WEB-UI-GUIDE.md` for usage patterns
1. Check `TESTING-GUIDE.md` for troubleshooting
1. Review individual agent files for specific domains
1. Open an issue with reproduction steps

### For Questions

- "How do I use the multiagent system?" → Read `COPILOT-WEB-UI-GUIDE.md`
- "How do I test my changes?" → Read `TESTING-GUIDE.md`
- "What standards should I follow?" → Read `shared-context.md`
- "How does X agent work?" → Read `X.md` agent file

## Contributing

When contributing agent changes:

1. Understand the current structure (this README)
1. Make focused changes to relevant agent file(s)
1. Update shared-context.md if changing standards
1. Test with the 5-test framework
1. Update documentation
1. Submit PR with clear explanation

## Status

✅ **Production Ready**: Multiagent system is complete and tested 🧪 **Testing Phase**: Verification
in real Copilot web UI environment ongoing 📚 **Well Documented**: Comprehensive guides available 🔄
**Iterative**: Will improve based on real-world usage

## Version History

- **v1.0.0** (2025-12-21): Initial multiagent structure
  - Decomposed monolithic agent.md into 6 specialized agents
  - Added root orchestrator and shared context
  - Created Copilot web UI guides
  - Added comprehensive testing framework

______________________________________________________________________

**For detailed usage instructions, start with [COPILOT-WEB-UI-GUIDE.md](COPILOT-WEB-UI-GUIDE.md)**

**For testing and verification, see [TESTING-GUIDE.md](TESTING-GUIDE.md)**

**For project standards, all agents reference [shared-context.md](shared-context.md)**
