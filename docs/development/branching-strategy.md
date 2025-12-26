# Branching Strategy

## Overview

AutoGit follows a structured branching strategy designed to maintain code quality, enable parallel
development, and ensure smooth integration of features. This document outlines our branching model
and workflow.

## Branch Structure

### Main Branches

#### `main`

- **Purpose**: Production-ready code
- **Protection**: Fully protected, requires PR approval
- **Deployment**: Automatically deployed to production
- **Merge Source**: Only accepts merges from `dev` branch
- **Naming**: `main`

#### `dev`

- **Purpose**: Integration branch for completed features
- **Protection**: Protected, requires PR approval
- **Testing**: All features must pass CI/CD before merging
- **Merge Source**: Accepts merges from feature branches
- **Naming**: `dev`

### Feature Branches

Feature branches are created for major features or tasks from the roadmap.

- **Source**: Created from `dev`
- **Target**: Merge back into `dev`
- **Naming Convention**: `feature/<task-name>`
- **Examples**:
  - `feature/git-server-implementation`
  - `feature/multi-architecture-support`
  - `feature/gpu-scheduling`

#### Feature Branch Workflow

1. Create feature branch from `dev`
1. Break down task into subtasks
1. Create sub-feature branches for each subtask
1. Merge sub-features into feature branch
1. Create PR from feature branch to `dev`

### Sub-Feature Branches

Sub-feature branches handle individual subtasks within a larger feature.

- **Source**: Created from parent feature branch
- **Target**: Merge back into parent feature branch
- **Naming Convention**: `feature/<task-name>/<subtask-name>`
- **Examples**:
  - `feature/git-server-implementation/docker-setup`
  - `feature/git-server-implementation/api-integration`
  - `feature/git-server-implementation/authentication`

### Work Branches

Work branches are for individual work items or bug fixes within a subtask.

- **Source**: Created from sub-feature branch
- **Target**: Merge back into sub-feature branch
- **Naming Convention**: `feature/<task-name>/<subtask-name>/<work-item>`
- **Examples**:
  - `feature/git-server-implementation/docker-setup/dockerfile-optimization`
  - `feature/git-server-implementation/api-integration/endpoint-testing`

### Supporting Branches

#### Hotfix Branches

- **Purpose**: Critical bug fixes for production
- **Source**: Created from `main`
- **Target**: Merge into both `main` and `dev`
- **Naming Convention**: `hotfix/<issue-description>`
- **Lifespan**: Very short-lived

#### Release Branches

- **Purpose**: Prepare release from dev to main
- **Source**: Created from `dev`
- **Target**: Merge into `main` (and back-merge into `dev`)
- **Naming Convention**: `release/<version>`
- **Example**: `release/v1.0.0`

## Workflow Examples

### Standard Feature Development

```
main
  └─ dev
      └─ feature/gpu-scheduling
          ├─ feature/gpu-scheduling/detection-service
          │   ├─ feature/gpu-scheduling/detection-service/nvidia-support
          │   └─ feature/gpu-scheduling/detection-service/amd-support
          └─ feature/gpu-scheduling/scheduler-logic
              └─ feature/gpu-scheduling/scheduler-logic/allocation-algorithm
```

### Workflow Steps

1. **Task Identification**: Identify the next task from `TASK_TRACKER.md`.
1. **Feature Branch Creation**: Create a parent feature branch from `dev`.
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/<task-name>
   ```
1. **Sub-Feature Branching**: For each subtask, create a branch from the parent feature branch.
   ```bash
   git checkout feature/<task-name>
   git checkout -b feature/<task-name>/<subtask-name>
   ```
1. **Development and Local Integration**:
   - Complete work in the sub-feature branch.
   - Merge sub-feature branch back into the parent feature branch.
   - Delete the sub-feature branch locally and remotely.
1. **Final Integration**: Once all subtasks are merged into the parent feature branch and validated,
   create a PR from the parent feature branch to `dev`.

> **Note**: This hierarchical approach ensures that `dev` remains clean and that complex features
> are fully integrated and tested as a unit before being merged into the main development line.

### Dev to Main Release

```bash
# Create release branch from dev
git checkout dev
git pull origin dev
git checkout -b release/v1.1.0

# Finalize release (version bumps, changelog, etc.)
# Create PR: release/v1.1.0 -> main

# After merge to main, back-merge to dev if needed
git checkout dev
git merge main
git push origin dev
```

## Branch Protection Rules

### `main` Branch

- Require pull request reviews (2 approvals)
- Require status checks to pass
- Require branches to be up to date
- No force pushes
- No deletions
- Require signed commits

### `dev` Branch

- Require pull request reviews (1 approval)
- Require status checks to pass
- Require branches to be up to date
- No force pushes
- No deletions

### Feature Branches

- Require pull request reviews (1 approval)
- Require status checks to pass
- Allow force pushes (for rebasing)
- Allow deletions (after merge)

## Pull Request Guidelines

### PR Types and Templates

#### 1. Feature to Dev PR

- **Title**: `feat: [Feature Name] - [Brief Description]`
- **Template**: Feature PR template
- **Requirements**:
  - Complete test coverage
  - Documentation updates
  - CHANGELOG entry
  - All sub-features merged

#### 2. Sub-Feature to Feature PR

- **Title**: `feat(<feature>): [Subtask Name] - [Brief Description]`
- **Template**: Sub-feature PR template
- **Requirements**:
  - Component tests passing
  - Related documentation
  - All work branches merged

#### 3. Work to Sub-Feature PR

- **Title**: `fix/feat(<subtask>): [Work Item Description]`
- **Template**: Work PR template
- **Requirements**:
  - Unit tests passing
  - Code review approval

#### 4. Dev to Main PR

- **Title**: `release: v[X.Y.Z] - [Release Name]`
- **Template**: Release PR template
- **Requirements**:
  - Complete changelog
  - Version bump
  - All features documented
  - Full test suite passing
  - Security scan passed

### PR Description Requirements

All PRs must include:

1. **Summary**: What changes are included
1. **Motivation**: Why these changes are needed
1. **Testing**: How changes were tested
1. **Documentation**: What docs were updated
1. **Breaking Changes**: Any breaking changes
1. **Dependencies**: New dependencies added
1. **Checklist**: Completion checklist

## Commit Message Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Build process or auxiliary tool changes
- `perf`: Performance improvements
- `ci`: CI/CD changes

### Examples

```
feat(gpu): add NVIDIA GPU detection service

Implements GPU detection for NVIDIA cards using nvidia-smi.
Includes support for multiple GPUs and capability detection.

Closes #123
```

```
fix(auth): resolve token expiration issue

Fixes issue where authentication tokens were expiring
prematurely due to incorrect timezone handling.

Fixes #456
```

## Branch Lifecycle

### Creation

1. Ensure base branch is up to date
1. Create branch with proper naming convention
1. Push to remote immediately
1. Create tracking issue/card

### Development

1. Make focused, atomic commits
1. Push regularly to remote
1. Keep branch up to date with base
1. Rebase if needed (not merge)

### Completion

1. Ensure all tests pass
1. Update documentation
1. Create pull request
1. Address review comments
1. Merge when approved
1. Delete branch after merge

## Best Practices

### Do's

✅ Keep branches short-lived (< 2 weeks) ✅ Make small, focused commits ✅ Write descriptive commit
messages ✅ Keep branches up to date with base ✅ Delete branches after merging ✅ Use draft PRs for
work in progress ✅ Tag reviewers appropriately ✅ Update CHANGELOG for features

### Don'ts

❌ Don't commit directly to main or dev ❌ Don't create long-lived feature branches ❌ Don't mix
unrelated changes ❌ Don't force push to shared branches ❌ Don't merge without review ❌ Don't leave
stale branches ❌ Don't merge with failing tests ❌ Don't skip documentation updates

## Automation

### GitHub Actions

We use GitHub Actions to automate:

- Branch protection enforcement
- Automated testing on PRs
- Code quality checks
- Security scanning
- Documentation validation
- Automatic labeling
- Stale branch cleanup

### Scripts

Helper scripts available in `/scripts/`:

- `create-feature-branch.sh` - Create feature branch structure
- `sync-branches.sh` - Keep branches in sync
- `cleanup-merged-branches.sh` - Remove merged branches
- `validate-branch-name.sh` - Validate branch naming

## Troubleshooting

### Merge Conflicts

1. Update your branch from base
1. Resolve conflicts locally
1. Test thoroughly
1. Push resolved changes

### Diverged Branches

1. Fetch latest from remote
1. Rebase onto base branch
1. Force push if needed (careful!)

### Accidental Commits to Wrong Branch

1. Create correct branch from current position
1. Reset original branch to proper state
1. Cherry-pick commits to correct branch

## References

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

## Updates

- **2025-12-21**: Initial branching strategy documented
- **YYYY-MM-DD**: [Future updates]

______________________________________________________________________

*For questions about branching strategy, see [CONTRIBUTING.md](../CONTRIBUTING.md) or open a
discussion.*
