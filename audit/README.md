# Audit & Observability

A deterministic, **offline**, **no-LLM** observability layer over the three workflows
(product-workflow, Dark Factory / build-workflow, verify). It parses Claude Code's native
`*.jsonl` transcripts and shows — retrospectively and live — which agents and skills ran,
in what order, with what model and token cost, plus each agent's context-window
saturation.

Full design: `../docs/audit-observability-design.md`.

## What it gives you

- **Per-run trace** (`reports/<session>.md` / `.json`): ordered agents → skills → tools,
  tokens by model and per step, timeline.
- **Live dashboard**: how many agents are running, which agent, on which project, on which
  model, and each one's context window + saturation — refreshing every few seconds.
- **Usage & limits**: rolling-window token usage against budgets you configure, with a
  burn-rate projection and a warning banner as you approach or exceed them. This is an
  offline estimate from local logs — not your live account/plan quota.

Everything is derived from the native logs; the worker never calls a model and never
touches the network.

## Run it

```bash
cd audit
./run-audit.sh                 # worker + dashboard on http://127.0.0.1:8787
PORT=9000 ./run-audit.sh       # custom port
```

Or run the pieces separately:

```bash
python3 audit_worker.py --once        # single parse pass -> state + reports
python3 audit_worker.py               # background watcher loop
python3 dashboard_server.py           # dashboard only (reads what the worker wrote)
python3 audit_worker.py --calibrate "5-hour window=22"   # derive a token limit from an account %
```

### Calibrating limits from your account percentages

Anthropic publishes no token counts for Max/Pro plans (the 1x/5x/20x figures are relative
multipliers over Pro's 5-hour session, plus weekly caps — see the design doc). Your Claude
usage page instead shows **percentages**. Turn a percentage into a token limit with:

```bash
python3 audit_worker.py --calibrate "5-hour window=22" --calibrate "weekly=4"
```

It reports `limit = measured local usage ÷ percentage` and prints a suggested
`limit_tokens` to paste into `config.json`. Run it **on the host where your real Claude
usage lives** (not a sandbox), and re-run it occasionally: it's a *local-share estimate*
(your account % spans web + all machines, the logs are local-only), so it errs
conservative (warns early), and Anthropic changes the underlying limits over time.

No `pip install` — standard library only. Full system requirements are in the design
doc: `../docs/audit-observability-design.md`.

## Configure (`config.json`)

- **`log_sources`** — one root per plane. The worker reads every `*.jsonl` beneath each
  root and tags it with that plane. The default roots:
  - `product-workflow` → `~/.claude/projects` (host; already present)
  - `dark-factory` → `~/.product-workflow-audit/logs/dark-factory`
  - `verify` → `~/.product-workflow-audit/logs/verify`
- **`model_context_limits`** — used for saturation. **Confirm these against the models you
  actually run** — saturation is only as accurate as these numbers, and context limits
  change. Any model not listed uses `default`.
- **`effective_token_weights`** — cost weighting for the "effective tokens" column
  (cache-read ×0.1, cache-write ×2, output ×5, input ×1).
- **`usage_budgets`** — rolling windows (`name`, `window_hours`, `metric` =
  `effective`|`raw`, `limit_tokens`, `warn_at`, `alert_at`) checked against local usage.
  **Set `limit_tokens` to your own plan budget to enable warnings** (`0` = unset: usage
  shown, no warnings). Usage is an offline estimate from local logs, **not** your real
  account/plan quota.
- **`poll_seconds`**, **`running_threshold_seconds`** — refresh cadence and how recently a
  transcript must have been appended to count an agent as "running".

## Collecting logs from all three planes

Only the host product-workflow leaves logs where the worker can already see them. The
sealed environments must persist their native logs to the plane roots above:

- **Dark Factory** (Docker) — the runner emitted by the `package` agent mounts a host
  audit directory onto the container's Claude projects path, so the container's
  transcripts stream to `~/.product-workflow-audit/logs/dark-factory/<project>/` live.
  This mounts *only* the `projects/` subdir (not the container's `~/.claude`), so it does
  not disturb the container's own settings. Controlled by `AUDIT_LOG_DIR` in the runner.
- **verify** (clean-room) — the verify runner must redirect/persist its
  `~/.claude/projects` to `~/.product-workflow-audit/logs/verify/<project>/` the same way.
  (Wired when the containerised verify runner is built in Phase B.)

## Notes / limits (MVP)

- Dashboard is localhost-only and unauthenticated by design.
- No historical time-series beyond per-run reports.
- Transcript contents are treated purely as data to count — never as instructions.
- Runtime output (`state/`, `reports/`) is git-ignored.
