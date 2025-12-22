# Branching Strategy

## Overview

AutoGit follows a structured branching strategy designed to maintain code quality, enable parallel development, and ensure smooth integration of features. This document outlines our branching model and workflow.

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
2. Break down task into subtasks
3. Create sub-feature branches for each subtask
4. Merge sub-features into feature branch
5. Create PR from feature branch to `dev`

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

1. **Start New Feature**
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/gpu-scheduling
   git push -u origin feature/gpu-scheduling
   ```

2. **Create Sub-Feature**
   ```bash
   git checkout feature/gpu-scheduling
   git checkout -b feature/gpu-scheduling/detection-service
   git push -u origin feature/gpu-scheduling/detection-service
   ```

3. **Create Work Branch**
   ```bash
   git checkout feature/gpu-scheduling/detection-service
   git checkout -b feature/gpu-scheduling/detection-service/nvidia-support
   git push -u origin feature/gpu-scheduling/detection-service/nvidia-support
   ```

4. **Complete Work and Merge Up**
   ```bash
   # After completing work on nvidia-support
   # Create PR: nvidia-support -> detection-service
   # After approval and merge, move to parent
   git checkout feature/gpu-scheduling/detection-service
   git pull origin feature/gpu-scheduling/detection-service
   
   # After all sub-work is done, create PR: detection-service -> gpu-scheduling
   # After approval and merge
   git checkout feature/gpu-scheduling
   git pull origin feature/gpu-scheduling
   
   # After all sub-features done, create PR: gpu-scheduling -> dev
   ```

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
2. **Motivation**: Why these changes are needed
3. **Testing**: How changes were tested
4. **Documentation**: What docs were updated
5. **Breaking Changes**: Any breaking changes
6. **Dependencies**: New dependencies added
7. **Checklist**: Completion checklist

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
2. Create branch with proper naming convention
3. Push to remote immediately
4. Create tracking issue/card

### Development
1. Make focused, atomic commits
2. Push regularly to remote
3. Keep branch up to date with base
4. Rebase if needed (not merge)

### Completion
1. Ensure all tests pass
2. Update documentation
3. Create pull request
4. Address review comments
5. Merge when approved
6. Delete branch after merge

## Best Practices

### Do's
✅ Keep branches short-lived (< 2 weeks)
✅ Make small, focused commits
✅ Write descriptive commit messages
✅ Keep branches up to date with base
✅ Delete branches after merging
✅ Use draft PRs for work in progress
✅ Tag reviewers appropriately
✅ Update CHANGELOG for features

### Don'ts
❌ Don't commit directly to main or dev
❌ Don't create long-lived feature branches
❌ Don't mix unrelated changes
❌ Don't force push to shared branches
❌ Don't merge without review
❌ Don't leave stale branches
❌ Don't merge with failing tests
❌ Don't skip documentation updates

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
2. Resolve conflicts locally
3. Test thoroughly
4. Push resolved changes

### Diverged Branches
1. Fetch latest from remote
2. Rebase onto base branch
3. Force push if needed (careful!)

### Accidental Commits to Wrong Branch
1. Create correct branch from current position
2. Reset original branch to proper state
3. Cherry-pick commits to correct branch

## References

- [Git Flow](https://nvie.com/posts/a-successful-git-branching-model/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

## Updates

- **2024-12-21**: Initial branching strategy documented
- **YYYY-MM-DD**: [Future updates]

---

*For questions about branching strategy, see [CONTRIBUTING.md](../CONTRIBUTING.md) or open a discussion.*
