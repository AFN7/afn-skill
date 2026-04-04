# AFN - Autonomous Full Intelligence

Fully autonomous development agent for Claude Code. Give it a single sentence, it does the rest: research, design, plan, implement, verify.

**No context limits** — persists state to `.afn/` directory, automatically resumes across sessions.

## Install

### As Claude Code Plugin
```bash
claude plugin add github:AFN7/afn-skill
```

### Manual
```bash
# Copy skill to Claude Code skills directory
mkdir -p ~/.claude/skills/afn
cp skills/afn/SKILL.md ~/.claude/skills/afn/

# Copy loop runner and add alias
cp afn-loop.sh ~/.claude/skills/afn/
chmod +x ~/.claude/skills/afn/afn-loop.sh
echo 'alias afn="bash ~/.claude/skills/afn/afn-loop.sh"' >> ~/.bashrc
source ~/.bashrc
```

## Usage

### Inside Claude Code (single context)
```
/afn Build a real-time dashboard with auth and analytics
/afn requirements.md
/afn Fix this bug: login not working
/afn Add dark mode to existing project
/afn                                    # Resume from where you left off
```

### From Terminal (unlimited loop — no context rot)
```bash
afn "Create a full-stack booking system"    # New project — loops until done
afn                                          # Resume from .afn/STATE.md
afn --budget 1 "Portfolio site with CMS"    # $1 per iteration (fresh context each time)
afn --max-iter 10 "REST API with auth"      # Max 10 iterations
```

## How It Works

```
Terminal: afn "Create a full-stack booking system"
            ↓
      afn-loop.sh (bash)
            ↓
      claude --print + SKILL.md as system prompt
            ↓
      Iteration #1: Research → Design → Plan → Implement (5 tasks) → STATE.md
            ↓
      Budget hit or context full → clean exit
            ↓
      Iteration #2: Fresh context → Read STATE.md → Continue (5 more tasks)
            ↓
      ...
            ↓
      Iteration #N: All tasks done → STATE.md = "COMPLETED"
            ↓
      [AFN] PROJECT COMPLETED! (N iterations)
```

### Key Features

- **Fully autonomous** — doesn't ask unnecessary questions, makes smart decisions
- **Any project type** — web, CLI, API, backend, script, bugfix, refactor
- **No context rot** — each iteration starts fresh, state persists in files
- **Parallel research** — dispatches multiple agents for research phase
- **Smart resume** — `.afn/STATE.md` tracks everything, resume anytime
- **Self-completing** — adds things you didn't think of (404 pages, SEO, loading states, favicon, etc.)
- **Realistic content** — no Lorem ipsum, no placeholders, no "coming soon"
- **Professional quality** — doesn't look AI-generated

### State Files

```
.afn/
  STATE.md      # Current progress, task list, decisions
  DESIGN.md     # Design decisions, color palette, architecture
  RESEARCH.md   # Research findings summary
  archive/      # Previous project states
```

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Claude subscription (any plan)

## License

MIT

