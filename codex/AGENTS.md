 # Global Instructions

## Superpowers subagent routing

- When following a Superpowers skill, use `agent_type = "luna_worker"` for fresh subagents handling bounded implementation, test fixes, exploration, mechanical work, or routine task reviews.
- Do not pass a model or reasoning-effort override to `luna_worker`; use the model and effort configured in `~/.codex/agents/luna-worker.toml`.
- Use a `default` agent explicitly configured with `model = "gpt-5.6-sol"` for architecture or design judgment, the final whole-branch review, and escalation when a Luna worker is blocked or the task requires broad cross-system reasoning.
- Preserve any Superpowers requirement to resume an existing implementer during a fix loop; apply this routing policy whenever the workflow creates a fresh subagent.
- An explicit user instruction selecting a different agent type or model takes precedence over this routing policy.

## Communication Preferences
- For quick explanatory questions, answer in under 100 words.
- For quick questions, user can say quick, quick question or qq to hint you its a quick question query
- Use bullet points only for these quick answers.
- Keep the reply direct and conversational; avoid long background unless asked.

## Codex Development Process

CAUTION: NEVER USE A PRODUCTION DATABASE OR PRODUCTION ENVIRONMENT FILE WITHOUT EXPLICIT USER PERMISSION.

### Project discovery and overrides

- Treat the active workspace as the project scope.
- Detect whether it contains one Git repository, a monorepo, or multiple sibling or nested Git repositories.
- Identify repositories and runnable applications by their actual names and paths; never assume names such as `client` or `server`.
- Infer application roles, development commands, and likely ports from repository metadata and package scripts.
- Apply the nearest project-level `AGENTS.md` as an override for repository scope, application roles, commands, ports, environment files, and worktree conventions.
- Before multi-repository, worktree, or runtime actions, show the detected project structure and affected scope.

### Development modes or `dm`

When the user says `start`, `let's begin`, `setup pre context`, `development modes`, or `dm`, list these modes:

#### important rules: 
- Do not invoke, read, or follow any superpowers:* skill unless I explicitly request Superpowers in the current task.
- Do not invoke, read, or follow `$sol-advisor:orchestration` unless I explicitly request Sol Advisor in the current task or select development mode 7.
- Do not use subagents, for testing and review the code untill and unless using superpowers plugin mode or requested by the user. also continue development in the same session thread.
- Do not write test cases and test scripts unless and untill using superpowers plugin or requested by the user. just make the changes directly in one shot by default.

1. `superpowers plugin` (Use Superpowers skills only when I explicitly request Superpowers)
2. `quick direct one shot changes` - no need to write test cases for scripts for this - just do tha change/fix/improvements
3. `isolated worktrees and matching branches for selected repositories, with safe local environment files`
4. `same current workspace and worktrees`
5. `subagent-driven development`
6. `inline execution` - never trigger any sub-agents when using this mode
7. `sol-advisor plugin` (GPT-5.6 Sol plans and verifies, Terra implements, and a fresh Sol reviewer must approve completion)

- Accept a mode number, `even`, `odd`, or a combined selection such as `147`.
- When the user says `switch development modes`, list the modes again and update the active selection for the session.
- Don't use superpower skills without my permission. Don't trigger superpower skills automatically

### Worktree status, dev status, `ws`, or `ds`

- Report the current task name in bold.
- For every detected repository, report its name, path, current worktree, branch, and clean or modified state.
- Include a three-column task table: serial number, task name, and status (`not started`, `in progress`, or `done`).

### All worktrees status

- Scan linked worktrees in every detected repository.
- Compare each worktree branch with that repository's current branch.
- Report both unmerged commits and uncommitted changes using actual repository names.
- End with a concise statement covering worktrees that are clean and fully merged.

### Setup worktree or `nw`

- Detect and show the repositories, current worktrees, and current branches.
- Ask for the new shared branch/worktree name.
- Default to all detected repositories while allowing the user to select a subset.
- Before creation, show the source branches, target branches, worktree paths, and environment files that will be copied.
- Create the same requested branch name from each selected repository's current branch.
- Follow an existing repository worktree convention; otherwise use `<repository>/.worktrees/<branch-name>`.
- Copy existing local-development environment files to their corresponding paths in each new worktree, including `.env`, `.env.local`, `.env.development`, and project-configured equivalents.
- Never copy `.env.production`, `prod.env`, production credentials, or ambiguous production-like files. Ask before copying an ambiguous file.
- Copy environment files without reading or exposing their secret values.
- Never overwrite or delete an existing branch or worktree without explicit permission.
- After setup, use the new worktrees as the isolated development workspace.

### Development runtime status, server status, or `ss`

- Detect runnable applications and active development processes from scripts, ports, process metadata, and project overrides.
- Report each application by actual name, URL or port, HTTP status when applicable, repository, worktree, and branch.
- Offer these actions after showing the affected applications:
  1. `start` or `stop`
  2. `restart`
  3. `switch` to applications from another worktree
- Before switching, show the currently running applications and the target worktrees for confirmation.
- Never start a service with production environment files or connect to a production database without explicit permission.


## List down all the new changes, features and fixes:
#### "list down the changes" - user will ask something like this
- compare "abhijay/dev" branch with "main" branch find out the changes and features and fixes that we have new in this "abhijay/dev" branch list them down in bullet points brrifly (easy non-technical language).
- make 2 sections: "New Features" & "fixes and improvements"


## Autopilot Skill V1: For UI and Browser Automation
- dont start browser UI automation, testing and debugging until and unless asked explicitly.
- For UI testing or debugging that the user asks to perform like a human, use `$autopilot-skill-v1`. Trigger it when the user says `use Autopilot skill`, `use Autopilot skill for debugging`, `use Autopilot skill for testing`, or asks to debug or test a web app like a human.
- `$autopilot-skill-v1` uses the globally registered computer use for live browser interaction.
- Do not use the `browser:control-in-app-browser` or `chrome:control-chrome` plugin. This preference applies even when the target page is already open in Chrome or depends on an existing signed-in Chrome session.


## Post-Completion Checklist
After every agent task completion, perform these exact steps:

1. **Type check** – run relevant tests like `npx tsc --noEmit` (for typescript projects) and fix any reported errors before proceeding.
2. **Stage changes** – add each modified file explicitly with `git add <file>`. Do not use `git add -a`.
3. **Commit** – create a commit message using the required format and length, e.g. `git commit -m "feat: describe 6-7 word change"` (replace the prefix with the correct type such as feat/fix/docs/style/refactor/perf/test).
4. **Push** – push the new commit to the current working branch with `git push origin <CURRENT_BRANCH_NAME>`.

These operations must be executed after every agent completion to keep the branch history synchronized with remote and to ensure the shared type-safe workflow remains intact.
