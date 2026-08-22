# Audit & Observability — Design

**Status:** Agreed with Product Engineer; MVP implementation in `audit/`
**Date:** 2026-08-22
**Scope:** A deterministic, offline observability layer over all three workflows
(product-workflow, Dark Factory / build-workflow, verify). Records which agents and
skills run and in what order, the tokens and model per step, and drives a live local
dashboard of running agents, their projects, context windows, and saturation.

## Principles (agreed)

- **Deterministic, no LLM.** The audit worker never calls a model. It parses Claude's
  native logs only. Fully reproducible.
- **Offline.** No internet access, no external calls, no CDN. Stdlib only; the dashboard
  ships its own assets.
- **Autonomous background service.** Runs continuously while the workflows run, tailing
  logs as they are appended.
- **Project- and stack-agnostic.** Knows nothing about any app; it reads generic
  transcript structure and attributes work to whatever project produced it.

## System requirements

- **Python 3.8+**, standard library only — no third-party packages, no virtualenv.
- **Fully offline** — no network, no API key, and no model at any point.
- **OS** — the audit worker and dashboard are cross-platform (macOS, Linux, Windows).
- **A modern web browser** for the localhost dashboard.
- **Read access to the native logs** — `~/.claude/projects` for the host plane, plus the
  per-plane roots in `config.json` for the Dark Factory and verify planes.
- **Docker** — required only to *run the Dark Factory* so it emits logs; the audit tool
  itself does not need Docker.
- **macOS note** — the automatic Keychain auth path belongs to the Dark Factory *runner*,
  not the audit tool, and is macOS-only; on other OSes authenticate the Dark Factory via
  the `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` environment variable.

## The data source

Claude Code writes one append-only `*.jsonl` transcript per session under
`~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`, with subagent transcripts in
subfolders. Confirmed fields the worker relies on:

- `type` (`user` | `assistant` | …), `timestamp` (ordering), `sessionId`, `uuid` /
  `parentUuid`, `isSidechain` (subagent turn marker), `cwd` + `gitBranch` (project
  attribution).
- `message.model` — the model for that step (e.g. `claude-opus-4-8`).
- `message.usage` — `input_tokens`, `output_tokens`, `cache_creation_input_tokens`,
  `cache_read_input_tokens`.
- `message.content[]` — `tool_use` blocks. A `Task` call = an agent/subagent invocation
  (agent in `subagent_type`); a `Skill` call = a skill invocation; other names = tool
  calls (MCP tools are `mcp__*`).

Everything asked for is derivable from this with no model in the loop:

- **Agent/skill/tool order** — ordered `tool_use` blocks by timestamp; `Task`→agent,
  `Skill`→skill; subagents via `isSidechain` and subfolder transcripts.
- **Tokens per step** — `message.usage`. Reported raw and *effective* (weighting cache
  reads ×0.1, cache writes ×2, output ×5, per the `explain-usage` convention).
- **Model per step** — `message.model`.
- **Context window & saturation** — per assistant turn, context tokens ≈
  `input + cache_read + cache_creation`; saturation = that ÷ the model's context limit.
- **Which agent, which project** — latest active (sub)agent; `cwd`/`gitBranch`.

## The cross-plane problem, and the fix

The three workflows run in different environments and only one currently leaves
collectable logs:

- **product-workflow** — host; logs already at `~/.claude/projects/…`.
- **Dark Factory** — Docker container; the runner mounts only the workspace, so its
  `~/.claude` logs die with the container.
- **verify** — clean-room environment; same problem.

**Fix — persist native logs out of the sealed environments.** The Dark Factory runner
mounts a host audit directory onto the container's Claude projects path so its
transcripts stream to the host live; the verify clean-room does the equivalent. Each
plane's logs land under a per-plane root the worker watches. This does not change what
those workflows *do* — it only exposes their existing native logs.

## Components (in `audit/`)

1. **`config.json`** — the log-source roots per plane, model→context-limit map, poll
   interval, running-threshold, and output paths. The only place environment specifics
   live.
2. **`audit_worker.py`** — the background parser/watcher. Each poll: find changed
   `*.jsonl` under each configured root, (re)parse them, and update:
   - `state/state.json` — live snapshot: every session with plane, project, running
     flag, current model, current agent, context tokens, saturation, and token totals;
     plus the running-agent count. This is what the dashboard reads.
   - `reports/<session>.json` + `<session>.md` — the retrospective per-run trace:
     ordered agents/skills/tools, tokens by model and by step, timeline.
   It also computes **account-wide usage budgets** (see below) and emits warning
   notifications. Plane is assigned by which configured root a file came from. No LLM,
   stdlib only.
3. **`dashboard_server.py`** — a stdlib `http.server` (bound to localhost) serving the
   dashboard and a `/api/state` endpoint that returns `state.json`. Offline.
4. **`dashboard.html`** — dependency-free (inline CSS/JS, inline SVG bars) single page
   that polls `/api/state` every few seconds and shows: running-agent count; a row per
   session with plane, project, current agent, model, a context-window bar with
   saturation %, and token totals; and links to the retrospective reports. It also shows
   a **Usage & limits** panel (per-window consumption bars) and a **warning banner** when a
   budget is approached, projected to be exceeded, or exceeded. No CDN.
5. **`run-audit.sh`** — launches the worker and the server together.

## Definitions

- **Running agent** — a session/subagent whose transcript was appended within
  `running_threshold_seconds`. `current_agent` is the latest active subagent (sidechain),
  else the main session agent.
- **Context window** — tokens presented to the model on the latest assistant turn.
  **Saturation** — that ÷ the configured limit for its model (default 200k; overridable
  per model in config, since limits change).
- **Effective tokens** — cost-weighted totals for honest "where did it go" accounting,
  alongside raw counts.
- **Usage budget** — a configured budget with a token `limit`, `warn_at`/`alert_at`
  thresholds, and a metric (`effective` or `raw`), of one of two kinds:
  - **Rolling window** (`window_hours`, e.g. 5-hour or weekly) — mirrors how plan limits
    actually meter. Projection uses the recent burn rate ("hit the limit in ~N min").
  - **Anchored billing cycle** (`cycle: "monthly"`, `reset_day`) — a self-imposed budget
    tied to a billing renewal day. Usage is summed since the last reset; projection uses
    the *cycle-average pace* (usage-so-far ÷ time-elapsed), not a short burst, and warns if
    on pace to exceed before the reset. **A billing renewal is not a usage reset** — Max
    plan limits reset on rolling windows, so the monthly cycle is a personal budget, not
    the plan's enforcement mechanism.
  The worker sums account-wide consumption and raises a notification at warn/alert/over or
  when projected to exceed.
- **Important caveat — usage is an offline estimate.** The native logs do **not** contain
  plan quotas or remaining allowance, so limits are **user-configured budgets**, and usage
  is reconstructed from local transcripts. It approximates, and does not read, your real
  account/plan meter. (Reading the true remaining quota would require an online API call,
  which conflicts with the offline requirement.)

## Out of scope (MVP)

Historical time-series storage/graphing beyond per-run reports; alerting; auth on the
dashboard (localhost only); parsing non-Claude logs. All additive later.
