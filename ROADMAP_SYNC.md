# Roadmap Sync — Usage Guide

A system that keeps your `ROADMAP.md` in sync with GitHub Issues automatically.

## How It Works

Your `ROADMAP.md` is the **single source of truth**. Edit checkboxes, push to `main`,
and the GitHub Action handles the rest:

| Checkbox | Effect on GitHub Issue |
|----------|----------------------|
| `- [ ]`  | Open |
| `- [/]`  | Open + `in-progress` label |
| `- [x]`  | Closed |
| No `(#N)` | **Auto-creates** the issue and writes the number back |

## ROADMAP.md Format

```markdown
## Phase Name <!-- phase:label-name -->

- [ ] Task that already has an issue (#1)
- [ ] New task that needs an issue
- [/] Task currently in progress (#2)
- [x] Completed task (#3)
```

**Rules:**
- Each phase heading **must** have `<!-- phase:label-name -->` — this becomes the issue label
- Tasks with `(#N)` sync state with that issue
- Tasks **without** `(#N)` get a new issue created automatically

## Setup in a New Repo

Copy these two files into your repository:

```
your-repo/
├── .github/
│   ├── scripts/
│   │   └── sync_roadmap.py    ← the sync engine
│   └── workflows/
│       └── roadmap-sync.yml   ← the GitHub Action trigger
└── ROADMAP.md                 ← your roadmap (create with the format above)
```

That's it. No configuration needed — it auto-detects the repo from `gh`.

## Manual Usage (Local)

```bash
# Preview what would change (no side effects)
python3 .github/scripts/sync_roadmap.py --dry-run

# Apply changes
python3 .github/scripts/sync_roadmap.py

# Use a different roadmap file
python3 .github/scripts/sync_roadmap.py --roadmap docs/ROADMAP.md

# Target a specific repo
python3 .github/scripts/sync_roadmap.py --repo owner/repo
```

Requires `gh` CLI authenticated (`gh auth login`).

## Workflow Trigger

The Action runs on:
- **Push to `main`** that modifies `ROADMAP.md`
- **Manual dispatch** from the Actions tab on GitHub

It includes an infinite-loop guard to prevent re-triggers from its own commits.

## Example Workflow

1. Add a new task to `ROADMAP.md`:
   ```markdown
   - [ ] Add retry logic to download manager
   ```

2. Push to `main`

3. The Action auto-creates issue `#46` and updates your file to:
   ```markdown
   - [ ] Add retry logic to download manager (#46)
   ```

4. Later, mark it in progress:
   ```diff
   -- [ ] Add retry logic to download manager (#46)
   +- [/] Add retry logic to download manager (#46)
   ```

5. Push → issue `#46` gets the `in-progress` label

6. When done:
   ```diff
   -- [/] Add retry logic to download manager (#46)
   +- [x] Add retry logic to download manager (#46)
   ```

7. Push → issue `#46` is closed
