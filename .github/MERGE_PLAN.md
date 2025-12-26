# PR Merge Plan: Critical Agent Work

**Order**: Must merge in this sequence to maintain dependency tree

## Phase 1: Agent Documentation (MERGE FIRST)

### Why First?
The agent workflow documentation provides context for reviewing all other PRs. Reviewers need to understand HOW this code was created to properly evaluate it.

### PR #1: Agentic Workflow Documentation
- **Branch**: `dev` (already merged)
- **Files**: `.github/AGENTIC_WORKFLOW.md`
- **Status**: ✅ Already in dev
- **Action**: None needed - propagate to other branches

---

## Phase 2: Core CLI Implementation (HIGHEST PRIORITY)

### PR #2: autogit-core v0.1.0
- **Branch**: `feature/autogit-core-cli-v0.1.0` → `dev`
- **Files**: 32 files in `autogit-core/`
- **LOC**: ~5,300 lines
- **Status**: ✅ Ready for review
- **Session Summary**: `autogit-core/SESSION_SUMMARY.md`

**Why This Is Critical**:
- All other work depends on having a working GitLab API client
- Runner automation needs `autogit runner` commands
- Mirror sync needs `autogit mirror` commands
- This is the foundation for all future automation

**Review Checklist**:
- [ ] Rust builds cleanly
- [ ] All commands work with live GitLab
- [ ] Shell completions generate for all 6 shells
- [ ] Starship integration tested
- [ ] Documentation complete (README, CHANGELOG, SESSION_SUMMARY)
- [ ] No security issues (secrets handled with secrecy crate)

**Merge Command**:
```bash
# On GitHub, create PR: feature/autogit-core-cli-v0.1.0 → dev
# Title: "feat(autogit-core): Complete CLI v0.1.0 with GitLab API integration"
# Link to: autogit-core/SESSION_SUMMARY.md
# After approval and CI passes:
git checkout dev
git merge --no-ff feature/autogit-core-cli-v0.1.0
git push origin dev
```

---

## Phase 3: Infrastructure Support (PARALLEL - After Core)

These can be reviewed in parallel after autogit-core merges.

### PR #3: Homelab GitLab Deployment
- **Branch**: `feature/homelab-gitlab-deployment` → `dev`
- **Files**: 14 files (compose, scripts, docs)
- **Status**: ✅ Ready for review
- **Depends**: None (deployment scripts)

### PR #4: Observability Stack
- **Branch**: `feature/observability-stack` → `dev`
- **Files**: 9 files (Prometheus, Grafana, Loki, Tempo)
- **Status**: ✅ Ready for review
- **Depends**: None (config files)

### PR #5: Architecture Documentation
- **Branch**: `feature/docs-architecture` → `dev`
- **Files**: 4 docs files
- **Status**: ✅ Ready for review
- **Depends**: None (docs only)

### PR #6: Development Tooling
- **Branch**: `feature/dev-tooling` → `dev`
- **Files**: 7 files (Makefile, .editorconfig, scripts)
- **Status**: ✅ Ready for review
- **Depends**: None (tooling)

### PR #7: GitHub Workflows Organization
- **Branch**: `feature/github-workflows` → `dev`
- **Files**: 2 files (chat mode, archived workflows)
- **Status**: ✅ Ready for review
- **Depends**: None (CI organization)
- **Note**: Contains autogit-specialist.chatmode.md!

---

## Phase 4: Propagate to Feature Branches

After all PRs merge to dev, propagate changes to active feature branches:

```bash
# Merge dev into all review-worthy branches
for branch in \
  feature/homelab-deployment \
  feature/homelab-deployment-terraform-config \
  feature/multi-arch-support \
  feature/multi-arch-support-arm64-native; do
    git checkout $branch
    git merge dev
    git push origin $branch
done
```

---

## Phase 5: Cleanup Stale Branches

After propagation, delete stale branches (as documented in BRANCH_INDEX.md):

```bash
# Local cleanup
git branch -D \
  feature/homelab-migration-recovery \
  copilot/fix-workflow-trigger-issues \
  feature/homelab-deployment-deployment-verification \
  feature/homelab-deployment-docker-compose-sync \
  feature/homelab-deployment-runner-registration \
  feature/multi-arch-support-multi-arch-images \
  feature/multi-arch-support-qemu-fallback \
  feature/multi-arch-support-riscv-support \
  work/multi-arch-support-arm64-native-init

# Remote cleanup
git push origin --delete \
  feature/homelab-migration-recovery \
  copilot/fix-workflow-trigger-issues \
  copilot/review-dev-branch-merge \
  copilot/sub-pr-37 \
  copilot/sub-pr-37-again \
  copilot/update-ci-release-process \
  feature/homelab-deployment-deployment-verification \
  feature/homelab-deployment-docker-compose-sync \
  feature/homelab-deployment-runner-registration \
  feature/multi-arch-support-multi-arch-images \
  feature/multi-arch-support-qemu-fallback \
  feature/multi-arch-support-riscv-support \
  work/homelab-deployment-terraform-config-init
```

---

## Timeline

| Phase | Action | Duration | Blocker |
|-------|--------|----------|---------|
| 1 | Agent docs | ✅ Done | None |
| 2 | Review autogit-core | 1-2 days | Code review |
| 2 | Merge autogit-core | 5 min | Approval |
| 3 | Review infra PRs (parallel) | 1 day | Code review |
| 3 | Merge infra PRs | 15 min | Approvals |
| 4 | Propagate to branches | 30 min | Phase 3 complete |
| 5 | Cleanup stale | 15 min | Phase 4 complete |

**Total**: 2-3 days if reviews happen promptly

---

## Critical Path

```
AGENTIC_WORKFLOW.md (done)
    ↓
autogit-core PR #2 (CRITICAL - blocks nothing but enables everything)
    ↓
├─→ Homelab deployment PR #3
├─→ Observability PR #4
├─→ Architecture docs PR #5
├─→ Dev tooling PR #6
└─→ GitHub workflows PR #7
    ↓
Propagate to active branches
    ↓
Cleanup stale branches
    ↓
✅ Clean, organized repository ready for next 10 work items
```

---

## Next Work Items (After Merges)

From NEXT_10_ITEMS.md:

1. ✅ autogit-core PR (this phase)
2. ✅ Infrastructure PRs (this phase)
3. Integration tests for CLI (new branch)
4. CLI release pipeline (new branch)
5. Runner automation using autogit CLI
6. Mirror sync automation
7. Terraform review and updates

---

## Communication

When creating PRs on GitHub:

**PR Template**:
```markdown
## Summary
[One-line description]

## Documentation
- Session Summary: `path/to/SESSION_SUMMARY.md` (if applicable)
- Related Docs: `BRANCH_INDEX.md`, `NEXT_10_ITEMS.md`

## Testing
- [ ] Manual testing completed
- [ ] Works with live GitLab instance (for autogit-core)
- [ ] No regressions

## Dependencies
- Depends on: [None | PR #X]
- Blocks: [None | PR #Y]

## Review Checklist
- [ ] Code quality
- [ ] Documentation complete
- [ ] No security issues
- [ ] Tests pass (when applicable)

## Agent Notes
This work was completed by AI agent in autonomous mode.
See `.github/AGENTIC_WORKFLOW.md` for context on development process.
```

---

**Execute Phase 2 (autogit-core PR) immediately after reading this document.**
