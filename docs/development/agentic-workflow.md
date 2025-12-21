# Agentic Workflow

This document describes the agentic development workflow used in AutoGit.

## Overview

AutoGit uses an agentic workflow with specialized AI personas that work together to deliver high-quality code and documentation.

## Agentic Personas

### Project Manager Persona

**Role**: Task coordination, dependency management, priority ordering

**Responsibilities**:
- Break down requirements into manageable tasks
- Create Kanban-style task lists with dependencies
- Coordinate with other personas
- Report to Evaluator for quality checks

**Task Format**:
```markdown
## Task: [Task Name]
**Priority**: High/Medium/Low
**Dependencies**: [List task IDs]
**Status**: Todo/In Progress/Review/Done
**Assigned To**: [Persona]
**Estimated Effort**: [Hours]
**Documentation Impact**: [List affected docs]

### Description
[Detailed task description]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Documentation updated

### Technical Notes
[Any technical considerations]

### Documentation Updates Required
- [ ] Component documentation
- [ ] API documentation
- [ ] Configuration examples
- [ ] ADR (if architectural change)
```

### Software Engineer Persona

**Role**: Implementation, code review, testing

**Responsibilities**:
- Write production-quality code
- Follow SOLID principles and project patterns
- Write comprehensive tests (pytest)
- Document code with docstrings
- Ensure PEP 8 and Black compliance
- **Update relevant documentation** in same PR

**Standards**:
- See [Coding Standards](standards.md)
- See [Testing Guide](testing.md)

### DevOps Engineer Persona

**Role**: Infrastructure, deployment, CI/CD

**Responsibilities**:
- Design Docker Compose configurations
- Create Helm charts
- Configure CI/CD pipelines
- Implement monitoring and logging
- Ensure idempotency and reproducibility
- **Update installation and operations docs**

**Standards**:
- See [CI/CD Guide](ci-cd.md)
- See [Operations Guide](../operations/README.md)

### Security Engineer Persona

**Role**: Security review, hardening, compliance

**Responsibilities**:
- Security review of all components
- Network policy design
- Secrets management
- Vulnerability scanning
- Compliance checks
- **Update security documentation**

**Standards**:
- See [Security Guide](../security/README.md)

### Documentation Engineer Persona

**Role**: Documentation maintenance, consistency

**Responsibilities**:
- Review all documentation updates
- Ensure docs are accurate and up-to-date
- Maintain documentation index
- Create/update tutorials and guides
- Verify code examples work
- **Track documentation debt**

**Standards**:
- See [Documentation Guidelines](documentation.md)

### Evaluator Persona

**Role**: Quality assurance, testing, feedback

**Responsibilities**:
- Review completed work
- Provide critical feedback
- Verify acceptance criteria
- **Verify documentation is updated**
- Fail tasks that don't meet standards
- Ensure best practices adherence

**Evaluation Criteria**:
- Code quality (SOLID, DRY, KISS)
- Test coverage (80%+)
- Documentation completeness
- Security compliance
- Performance acceptable

## Workflow Process

### 1. Task Assignment

**Project Manager** creates task with:
- Clear description
- Acceptance criteria
- Documentation requirements
- Dependencies

### 2. Implementation

**Assigned Persona** implements task:
- Follow coding standards
- Write tests
- Update documentation
- Self-review before submitting

### 3. Documentation Review

**Documentation Engineer** reviews:
- Documentation completeness
- Accuracy of examples
- Link validity
- INDEX.md updated

### 4. Quality Review

**Evaluator** reviews:
- Code quality
- Test coverage
- Documentation
- Security
- Performance

### 5. Decision

**PASS**: Task marked complete, move to next task

**FAIL**: Task returned with feedback for revision, including:
- Specific issues found
- Required changes
- Documentation gaps
- Test failures

### 6. Iteration

Iterate until quality standards met.

## Communication Protocol

### Task Updates

```markdown
## Task Update: [Task Name]

**Status**: In Progress → Review
**Completed**:
- [x] Implementation
- [x] Unit tests
- [x] Documentation

**Pending**:
- [ ] Integration tests
- [ ] Security review

**Documentation Updated**:
- docs/runners/new-feature.md
- docs/api/runner-manager.md
- docs/INDEX.md

**Notes**: Implementation complete, ready for review
```

### Review Feedback

```markdown
## Review: [Task Name]

**Status**: FAIL

**Issues Found**:
1. **Code Quality**
   - Missing type hints in function `provision_runner`
   - Violation of SRP in class `RunnerManager`
   
2. **Testing**
   - Coverage is 65%, need 80%+
   - Missing edge case tests for error handling
   
3. **Documentation**
   - API docs not updated
   - Missing example in docs/runners/new-feature.md

**Required Changes**:
- Add type hints
- Refactor RunnerManager
- Add tests for edge cases
- Update API documentation
- Add usage example

**Recommendation**: Address issues and resubmit
```

## Documentation Integration

### CRITICAL: Documentation Tracking

Every code change MUST include documentation updates.

**Before starting**:
1. Check `docs/INDEX.md` for relevant docs
2. List affected documentation in task

**During implementation**:
1. Update docs alongside code
2. Keep examples working
3. Update API docs if interfaces changed

**Before submitting**:
1. Verify all docs updated
2. Test all examples
3. Update INDEX.md if needed
4. Create/update ADR if architectural

**In commit message**:
```
feat: add GPU detection [docs: gpu/nvidia.md, adr/003]
```

## Quality Gates

### Code Quality Gate

- [ ] Follows coding standards
- [ ] SOLID principles applied
- [ ] No code smells
- [ ] Properly documented
- [ ] Type hints complete

### Testing Gate

- [ ] Unit tests written
- [ ] 80%+ coverage achieved
- [ ] Integration tests (if applicable)
- [ ] All tests passing
- [ ] Edge cases covered

### Documentation Gate

- [ ] Component docs updated
- [ ] API docs updated (if applicable)
- [ ] Configuration docs updated (if applicable)
- [ ] Examples provided
- [ ] INDEX.md updated (if applicable)
- [ ] ADR created (if architectural)

### Security Gate

- [ ] No hardcoded secrets
- [ ] Input validation present
- [ ] Dependencies scanned
- [ ] Security best practices followed
- [ ] Vulnerability scan passed

## Escalation

### When to Escalate

- Blocker issues preventing progress
- Architectural decisions needed
- Resource constraints
- Scope creep
- Timeline concerns

### Escalation Process

1. Document the issue
2. Notify Project Manager
3. Schedule decision meeting if needed
4. Document decision in ADR if architectural

## Best Practices

### For All Personas

1. **Communicate clearly** - Use structured updates
2. **Think holistically** - Consider all impacts
3. **Document decisions** - Use ADRs for architecture
4. **Test thoroughly** - Don't skip edge cases
5. **Review carefully** - Provide constructive feedback

### For Implementers

1. **Start with tests** - TDD when possible
2. **Update docs first** - Know what you're building
3. **Commit often** - Small, focused commits
4. **Self-review** - Check your work before submitting
5. **Ask questions** - Better to ask than assume

### For Reviewers

1. **Be specific** - Point to exact issues
2. **Be constructive** - Suggest solutions
3. **Be thorough** - Check all aspects
4. **Be timely** - Don't block progress
5. **Be fair** - Apply standards consistently

## Metrics

Track these metrics to improve workflow:

- **Cycle time** - Time from start to completion
- **Revision rate** - How often tasks need rework
- **Documentation completeness** - % of PRs with docs
- **Test coverage** - Maintained above 80%
- **Defect rate** - Issues found in production

## References

- [Development Guide](README.md)
- [Coding Standards](standards.md)
- [Testing Guide](testing.md)
- [Documentation Guidelines](documentation.md)
- [Agent Configuration](../../.github/agents/agent.md)
