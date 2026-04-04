# AFN Skill — Autonomous Full Intelligence

Fully autonomous development agent for Claude Code. Give it a task, it handles everything: research, design, planning, implementation, verification. No context limits — state persists to files, resumes seamlessly across sessions.

## Installation

```bash
# Clone into Claude Code skills directory
git clone https://github.com/AFN7/afn-skill.git ~/.claude/skills/afn
```

That's it. Claude Code auto-discovers skills from `~/.claude/skills/`.

## Usage

### Inside Claude Code (single session)
```
/afn Create a full-stack booking system
/afn Fix this bug: login not working
/afn                                    # Resume from .afn/STATE.md
/afn new: Real-time chat app            # Archive old, start fresh
```

### Terminal Loop (unlimited — recommended for big projects)
```bash
cd /your/project
bash ~/.claude/skills/afn/afn-loop.sh "Create a full-stack booking system"
bash ~/.claude/skills/afn/afn-loop.sh                    # Resume
bash ~/.claude/skills/afn/afn-loop.sh --budget 1 "task"  # Max $1/iteration
bash ~/.claude/skills/afn/afn-loop.sh --max-iter 10 "task"
```

The loop:
- Opens a **fresh context** each iteration (no context rot)
- Reads `.afn/STATE.md` to resume where it left off
- Tracks progress via checkbox tasks `- [ ]` / `- [x]`
- Stops when all tasks are done or you press `Ctrl+C`

## How It Works

1. **Gather Context** — detects project type, existing code, user preferences
2. **Research** — parallel agents research domain, tech, UX, infra
3. **Design** — writes `.afn/DESIGN.md` with architecture decisions
4. **Plan** — creates task list in `.afn/STATE.md`
5. **Implement** — builds each task, verifies, marks complete
6. **Final Review** — checks for gaps, fixes, delivers

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition (loaded by Claude Code) |
| `afn-loop.sh` | Terminal loop runner |
| `.afn/STATE.md` | Project state (created in your project dir) |
| `.afn/DESIGN.md` | Design decisions (created in your project dir) |

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed
- `claude` command available in PATH
