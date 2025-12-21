# Multi-Agent Coordination Testing Guide

**Purpose**: Verify that the AutoGit multiagent workflow functions correctly in GitHub Copilot web UI

**Last Updated**: 2024-12-21

## Critical Multi-Agent Considerations

### Understanding Copilot's Agent Model

GitHub Copilot web UI has specific behaviors when working with multiple agent files:

1. **Single Session Context**: Copilot maintains one conversation context at a time
2. **Agent File Loading**: All `.md` files in `.github/agents/` are loaded as context
3. **No True Multi-Threading**: Agents don't run in parallel - they execute sequentially
4. **Context Window Limits**: Too many agent files may exceed context limits
5. **Agent Switching**: Copilot must explicitly switch between agent contexts

## Multi-Agent Workflow Patterns

### Pattern 1: Sequential Coordination (Recommended)

**How it works**: Root agent acts as orchestrator, explicitly invoking each agent in sequence

```markdown
USER REQUEST:
"Add GPU detection for AMD GPUs"

ROOT AGENT RESPONSE:
"I'll coordinate this across multiple agents:

Step 1 - Planning:
[Switches to Project Manager context]
[Project Manager creates task breakdown]

Step 2 - Implementation:
[Switches to Software Engineer context]
[Software Engineer writes code]

Step 3 - Infrastructure:
[Switches to DevOps Engineer context]
[DevOps updates Docker configs]

Step 4 - Security Review:
[Switches to Security Engineer context]
[Security reviews implementation]

Step 5 - Documentation:
[Switches to Documentation Engineer context]
[Docs updated]

Step 6 - Quality Gate:
[Switches to Evaluator context]
[Evaluator approves or rejects]"
```

**Pros**:
- ✅ Clear workflow progression
- ✅ Each agent has full context
- ✅ Easy to debug and understand
- ✅ Works within Copilot's single-session model

**Cons**:
- ⚠️ Takes longer (not truly parallel)
- ⚠️ User must wait for full sequence

### Pattern 2: Task Decomposition (Alternative)

**How it works**: User works with one agent at a time per request

```markdown
REQUEST 1:
"@project-manager: Create task breakdown for AMD GPU support"
[Project Manager responds with tasks]

REQUEST 2:
"@software-engineer: Implement task #1 - AMD GPU detection class"
[Software Engineer implements]

REQUEST 3:
"@evaluator: Review the GPU detection implementation"
[Evaluator reviews]
```

**Pros**:
- ✅ User controls pace
- ✅ Can review each step
- ✅ Easy to course-correct
- ✅ Clear which agent is active

**Cons**:
- ⚠️ More manual coordination required
- ⚠️ Risk of losing context between requests

### Pattern 3: Hybrid Orchestration (Best Practice)

**How it works**: Root agent delegates but user can intervene

```markdown
REQUEST:
"Add AMD GPU support. @root-agent please coordinate, but pause for my review after planning"

ROOT AGENT:
"I'll coordinate the agents. Starting with planning...

@project-manager output:
[Task breakdown appears]

⏸️ PAUSED for your review. Reply 'continue' to proceed with implementation."

USER: "continue"

ROOT AGENT:
"Proceeding with implementation...

@software-engineer output:
[Code implementation]
[Tests written]

⏸️ PAUSED. Review the code? Reply 'continue' or 'revise with feedback: ...'"
```

**Pros**:
- ✅ Automated coordination
- ✅ User maintains control
- ✅ Can review at checkpoints
- ✅ Balance of automation and oversight

## Testing Multi-Agent Workflow

### Test 1: Simple Agent Delegation

**Objective**: Verify root agent correctly delegates to specialized agents

**Test Steps**:
```markdown
1. User: "What coding standards should I follow for Python?"
   Expected: Root agent delegates to Software Engineer
   Verify: Response includes PEP 8, Black, type hints from software-engineer.md

2. User: "How do I deploy to Kubernetes?"
   Expected: Root agent delegates to DevOps Engineer
   Verify: Response includes Helm chart info from devops-engineer.md

3. User: "How do I handle secrets securely?"
   Expected: Root agent delegates to Security Engineer
   Verify: Response includes secrets management from security-engineer.md
```

**Success Criteria**: Root agent correctly identifies and delegates to appropriate specialized agent

### Test 2: Multi-Agent Coordination

**Objective**: Verify multiple agents can work together on a feature

**Test Steps**:
```markdown
User: "I need to add a new configuration option for runner timeout. 
Please coordinate across all relevant agents to implement this fully."

Expected Workflow:
1. Root agent delegates to Project Manager
2. Project Manager creates task list
3. Software Engineer implements code changes
4. DevOps Engineer updates configuration templates
5. Documentation Engineer updates config docs
6. Security Engineer reviews for security implications
7. Evaluator provides final approval

Verify:
- Each agent is mentioned explicitly in the response
- Each agent's output is distinct and follows their configuration
- No agent is skipped
- Work builds on previous agent's output
```

**Success Criteria**: All relevant agents participate, outputs are coordinated

### Test 3: Agent Context Retention

**Objective**: Verify agents maintain context across conversation

**Test Steps**:
```markdown
Request 1: "@project-manager: Create a task plan for adding Intel GPU support"
[Note the task IDs and structure]

Request 2: "@software-engineer: Implement task #2 from the project manager's plan"
Expected: Software Engineer references the specific task from Request 1
Verify: Agent has context from previous Project Manager output

Request 3: "@evaluator: Review the software engineer's implementation"
Expected: Evaluator has context of what was implemented
Verify: Review references the actual code/changes made
```

**Success Criteria**: Agents maintain conversation context and reference previous outputs

### Test 4: Shared Context Usage

**Objective**: Verify all agents use shared-context.md correctly

**Test Steps**:
```markdown
1. User: "@software-engineer: What architecture principles do we follow?"
   Expected: References SOLID, DRY, KISS from shared-context.md

2. User: "@devops-engineer: What architecture principles do we follow?"
   Expected: Same principles (from shared-context.md)

3. User: "@security-engineer: What are our license requirements?"
   Expected: References MIT compatibility from shared-context.md

Verify: All agents give consistent answers based on shared context
```

**Success Criteria**: Consistent responses across agents from shared context

### Test 5: Complex Multi-Agent Feature

**Objective**: Full integration test with a realistic feature request

**Test Steps**:
```markdown
User: "We need to implement runner autoscaling based on job queue depth. 
The system should:
- Monitor GitLab job queue
- Provision runners when queue > 10
- Deprovision idle runners after 5 minutes
- Support amd64 and arm64 architectures
- Include monitoring dashboards
- Have full documentation

Please coordinate this across all agents."

Expected Complete Workflow:
1. Project Manager: Breaks into ~8-10 tasks with dependencies
2. Software Engineer: Implements queue monitor and autoscaler logic
3. DevOps Engineer: Sets up monitoring, creates dashboards, updates Helm
4. Security Engineer: Reviews resource limits, isolation, permissions
5. Documentation Engineer: Creates operational guide, API docs, examples
6. Evaluator: Reviews all work, runs integration tests, approves

Verify:
- All 6 agents participate
- Work flows logically from planning → implementation → validation
- Each agent follows their specialized configuration
- Documentation is updated
- Security is considered
- Final output is production-ready
```

**Success Criteria**: Complete feature delivered with all aspects covered by appropriate agents

## Known Limitations & Workarounds

### Limitation 1: Context Window Size

**Problem**: With 9 agent files (including shared context and guide), context window may be exceeded

**Workaround Options**:

1. **Lazy Loading** (Recommended):
   - Only load agent.md (root) by default
   - Root agent explicitly loads specialized agents as needed
   - Example: "Loading software-engineer.md for this task..."

2. **Agent Grouping**:
   - Combine related agents (e.g., software-engineer + evaluator)
   - Create composite agents for common workflows

3. **Context Prioritization**:
   - Always load: agent.md, shared-context.md
   - Load on demand: specialized agents based on task type

**Implementation**: Add to agent.md:
```markdown
## Context Loading Strategy

To optimize context window usage:
1. Root agent (this file) is always loaded
2. Shared context is loaded when needed
3. Specialized agents loaded only when required for the task
4. Use @agent-name to explicitly load a specific agent
```

### Limitation 2: Sequential Execution Only

**Problem**: Agents cannot truly work in parallel

**Workaround**:
- Accept sequential execution
- Optimize by skipping unnecessary agents
- Use checkpoint pattern to make progress visible

**Implementation**: Document expected timing:
```markdown
## Expected Execution Times

Simple task (1 agent): ~1-2 minutes
Medium task (3 agents): ~5-10 minutes
Complex task (all 6 agents): ~15-30 minutes

User can interrupt and resume at any checkpoint.
```

### Limitation 3: Agent State Persistence

**Problem**: Agent state doesn't persist between Copilot sessions

**Workaround**:
- Store state in files (e.g., TASKS.md, PROGRESS.md)
- Use git commits as checkpoints
- Reference previous work explicitly

**Implementation**: Add state management pattern:
```markdown
## State Management

Agents should:
1. Create CURRENT_TASK.md for active work
2. Update PROGRESS.md after each agent completes
3. Commit after each major milestone
4. Reference commit SHAs in handoffs
```

### Limitation 4: No Agent-to-Agent Communication

**Problem**: Agents can't directly communicate; must go through user or root agent

**Workaround**:
- Root agent acts as message bus
- Use structured handoff format
- Document outputs for next agent

**Implementation**: Handoff template:
```markdown
## Agent Handoff Template

From: @software-engineer
To: @evaluator
Task: Review AMD GPU implementation
Context:
- Implementation in: src/gpu/amd_detector.py
- Tests in: tests/test_amd_detector.py
- Coverage: 87%
- Lint: Clean
Status: Ready for review
Next Steps: Evaluator to verify and approve
```

## Recommended Multi-Agent Workflow Structure

Based on limitations, here's the recommended approach:

### Structure 1: Root Agent as Orchestrator (Keep Current)

```
.github/agents/
├── agent.md                      # Main orchestrator (ALWAYS LOADED)
├── shared-context.md             # Common context (LOADED ON DEMAND)
├── project-manager.md            # Load when: planning, task breakdown
├── software-engineer.md          # Load when: coding, implementation
├── devops-engineer.md            # Load when: infrastructure, deployment
├── security-engineer.md          # Load when: security review needed
├── documentation-engineer.md     # Load when: docs need update
├── evaluator.md                  # Load when: review, quality gate
├── COPILOT-WEB-UI-GUIDE.md      # Reference guide (not loaded in context)
└── TESTING-GUIDE.md             # This file (not loaded in context)
```

### Structure 2: Add Agent Loading Hints

Update agent.md to include:

```markdown
## When to Load Each Agent

Based on keywords in user request:

| Keywords | Load Agent |
|----------|------------|
| "plan", "tasks", "breakdown", "coordinate" | project-manager.md |
| "implement", "code", "function", "class", "test" | software-engineer.md |
| "deploy", "docker", "kubernetes", "helm", "ci/cd" | devops-engineer.md |
| "security", "vulnerability", "auth", "encrypt" | security-engineer.md |
| "document", "docs", "guide", "readme", "adr" | documentation-engineer.md |
| "review", "approve", "quality", "test coverage" | evaluator.md |
```

## Verification Checklist

Before finalizing multiagent structure, verify:

### Basic Functionality
- [ ] Root agent file is valid markdown
- [ ] All specialized agent files are valid markdown
- [ ] Shared context file is complete
- [ ] All agents reference shared-context.md
- [ ] File sizes are reasonable (< 20KB each)

### Agent Coordination
- [ ] Test 1: Simple delegation works
- [ ] Test 2: Multi-agent coordination works
- [ ] Test 3: Context retained across requests
- [ ] Test 4: Shared context used consistently
- [ ] Test 5: Complex feature implemented correctly

### Context Management
- [ ] Total context size < 100KB when all loaded
- [ ] Root agent can function alone
- [ ] Specialized agents load on demand
- [ ] No circular dependencies between agents

### Documentation
- [ ] Each agent has clear responsibilities
- [ ] Workflow patterns are documented
- [ ] Limitations are documented
- [ ] Workarounds are provided
- [ ] Examples are complete

### User Experience
- [ ] Clear how to invoke agents
- [ ] Feedback at each step
- [ ] Progress is visible
- [ ] Can pause/resume workflows
- [ ] Error messages are helpful

## Next Steps

1. **Test in Real Copilot Environment**:
   - Try Test 1-5 above in actual Copilot web UI
   - Document what works and what doesn't
   - Adjust agent configurations based on results

2. **Optimize Context Loading**:
   - Implement lazy loading if context issues occur
   - Add loading hints to agent.md
   - Document optimal patterns

3. **Create Examples**:
   - Document successful multi-agent workflows
   - Share common patterns that work well
   - Build a cookbook of proven approaches

4. **Monitor and Improve**:
   - Track which patterns work best
   - Collect feedback from usage
   - Iterate on agent configurations
   - Update this guide with learnings

## References

- [Root Agent Configuration](agent.md)
- [Copilot Web UI Guide](COPILOT-WEB-UI-GUIDE.md)
- [Shared Context](shared-context.md)
- [Agentic Workflow Documentation](../../docs/development/agentic-workflow.md)

---

**Status**: Ready for real-world testing in Copilot web UI environment.
**Action Required**: Execute Test 1-5 in actual Copilot sessions and document results.
