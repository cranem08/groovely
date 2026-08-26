#!/usr/bin/env python3
"""
Audit worker for the product-workflow observability layer.

Deterministic, offline, no LLM. Parses Claude Code's native *.jsonl transcripts
across all configured workflow planes and emits:
  - state/state.json : a live snapshot the dashboard reads
  - reports/<session>.json + .md : per-run retrospective traces

Runs as an autonomous background loop (or a single pass with --once). Standard
library only; never makes a network call.
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(HERE)


# ── config / paths ────────────────────────────────────────────────────────────

def expand(path):
    return os.path.expanduser(os.path.expandvars(path))


def load_config(path):
    with open(path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    # Resolve output paths relative to the repo root when not absolute.
    for key in ("state_path", "reports_dir", "offsets_path"):
        p = cfg[key]
        cfg[key] = p if os.path.isabs(p) else os.path.join(REPO_ROOT, p)
    return cfg


# ── time helpers ──────────────────────────────────────────────────────────────

def parse_ts(value):
    """ISO-8601 (with optional trailing Z) -> epoch seconds, or None."""
    if not value or not isinstance(value, str):
        return None
    try:
        v = value.replace("Z", "+00:00")
        return datetime.fromisoformat(v).timestamp()
    except Exception:
        return None


def now_epoch():
    return datetime.now(timezone.utc).timestamp()


# ── transcript parsing ────────────────────────────────────────────────────────

def _classify_tool_use(name, inp):
    """Return (kind, display_name, detail) for a tool_use block."""
    inp = inp if isinstance(inp, dict) else {}
    # Subagent launch tool is "Task" in stock Claude Code and "Agent" in Cowork.
    if name in ("Task", "Agent"):
        return "agent", inp.get("subagent_type") or inp.get("description") or "agent", inp.get("description") or ""
    if name == "Skill":
        return "skill", inp.get("skill") or inp.get("command") or inp.get("name") or "skill", ""
    return "tool", name or "tool", ""


def _match_label(value, labels):
    """Return the configured label whose path equals or is a parent of value, else None."""
    if not isinstance(value, str):
        return None
    for p, l in labels:
        if value == p or value.startswith(p + os.sep):
            return l
    return None


def parse_transcript(path, plane, weights, project_labels=()):
    """Parse one *.jsonl transcript into a session summary + ordered trace."""
    session_id = os.path.splitext(os.path.basename(path))[0]
    cwd = None
    git_branch = None
    events = []          # ordered {ts, kind, name, detail, sidechain}
    turns = []           # per assistant message with usage
    by_model = {}        # model -> aggregate
    last_ts = None
    last_sidechain_agent = None
    matched_label = None  # explicit project label from config (deterministic)

    def agg(model):
        return by_model.setdefault(model or "unknown", {
            "input": 0, "output": 0, "cache_read": 0, "cache_creation": 0,
            "raw_total": 0, "effective_total": 0.0, "turns": 0,
        })

    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    o = json.loads(line)
                except Exception:
                    continue

                ts = parse_ts(o.get("timestamp"))
                if ts is not None:
                    last_ts = ts if last_ts is None else max(last_ts, ts)
                if o.get("cwd"):
                    cwd = o["cwd"]
                    if matched_label is None:
                        matched_label = _match_label(cwd, project_labels)
                if o.get("gitBranch"):
                    git_branch = o["gitBranch"]
                sidechain = bool(o.get("isSidechain"))

                msg = o.get("message")
                if o.get("type") != "assistant" or not isinstance(msg, dict):
                    continue

                model = msg.get("model") or "unknown"
                usage = msg.get("usage") if isinstance(msg.get("usage"), dict) else {}
                inp_t = int(usage.get("input_tokens") or 0)
                out_t = int(usage.get("output_tokens") or 0)
                cr_t = int(usage.get("cache_read_input_tokens") or 0)
                cc_t = int(usage.get("cache_creation_input_tokens") or 0)
                context_tokens = inp_t + cr_t + cc_t
                effective = (inp_t * weights["input"] + cr_t * weights["cache_read"]
                             + cc_t * weights["cache_creation"] + out_t * weights["output"])

                if any((inp_t, out_t, cr_t, cc_t)):
                    a = agg(model)
                    a["input"] += inp_t
                    a["output"] += out_t
                    a["cache_read"] += cr_t
                    a["cache_creation"] += cc_t
                    a["raw_total"] += inp_t + out_t + cr_t + cc_t
                    a["effective_total"] += effective
                    a["turns"] += 1
                    turns.append({
                        "ts": ts, "model": model, "sidechain": sidechain,
                        "input": inp_t, "output": out_t, "cache_read": cr_t,
                        "cache_creation": cc_t, "context_tokens": context_tokens,
                        "effective": round(effective, 1),
                    })

                content = msg.get("content")
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            kind, disp, detail = _classify_tool_use(block.get("name"), block.get("input"))
                            events.append({"ts": ts, "kind": kind, "name": disp,
                                           "detail": detail, "sidechain": sidechain})
                            if kind == "agent":
                                last_sidechain_agent = disp
                            if matched_label is None and project_labels:
                                inp = block.get("input")
                                if isinstance(inp, dict):
                                    for v in inp.values():
                                        lab = _match_label(v, project_labels)
                                        if lab:
                                            matched_label = lab
                                            break
    except FileNotFoundError:
        return None

    # counts
    def count(kind):
        c = {}
        for e in events:
            if e["kind"] == kind:
                c[e["name"]] = c.get(e["name"], 0) + 1
        return c

    current_model = turns[-1]["model"] if turns else "unknown"
    context_tokens = turns[-1]["context_tokens"] if turns else 0
    raw_total = sum(a["raw_total"] for a in by_model.values())
    effective_total = round(sum(a["effective_total"] for a in by_model.values()), 1)

    project = matched_label
    if project is None and cwd:
        project = os.path.basename(os.path.normpath(cwd))

    return {
        "session_id": session_id,
        "plane": plane,
        "file": path,
        "project": project,
        "cwd": cwd,
        "git_branch": git_branch,
        "last_ts": last_ts,
        "current_model": current_model,
        "current_context_tokens": context_tokens,
        "current_agent": last_sidechain_agent,  # None => main loop
        "raw_total_tokens": raw_total,
        "effective_total_tokens": effective_total,
        "by_model": by_model,
        "agents": count("agent"),
        "skills": count("skill"),
        "tools": count("tool"),
        "event_count": len(events),
        "turn_count": len(turns),
        "_events": events,   # kept for report writing; stripped from state
        "_turns": turns,
    }


# ── discovery ─────────────────────────────────────────────────────────────────

def find_transcripts(root):
    """All *.jsonl session transcripts under root. Only files inside a `projects/`
    directory are treated as transcripts, so stray logs (e.g. Cowork's audit.jsonl) are
    ignored."""
    out = []
    root = expand(root)
    if not os.path.isdir(root):
        return out
    for dirpath, _dirs, files in os.walk(root):
        if "projects" not in os.path.normpath(dirpath).split(os.sep):
            continue
        for fn in files:
            if fn.endswith(".jsonl"):
                out.append(os.path.join(dirpath, fn))
    return out


# ── state + reports ───────────────────────────────────────────────────────────

def build_state(sessions, cfg):
    limits = cfg["model_context_limits"]
    threshold = cfg["running_threshold_seconds"]
    now = now_epoch()
    out_sessions = []
    running = 0
    for s in sessions:
        limit = limits.get(s["current_model"], limits.get("default", 200000))
        sat = (s["current_context_tokens"] / limit) if limit else 0.0
        is_running = s["last_ts"] is not None and (now - s["last_ts"]) <= threshold
        if is_running:
            running += 1
        out_sessions.append({
            "session_id": s["session_id"],
            "plane": s["plane"],
            "project": s["project"],
            "git_branch": s["git_branch"],
            "running": is_running,
            "last_ts": s["last_ts"],
            "last_activity_iso": (datetime.fromtimestamp(s["last_ts"], timezone.utc).isoformat()
                                  if s["last_ts"] else None),
            "current_model": s["current_model"],
            "current_agent": s["current_agent"] or "main",
            "context_tokens": s["current_context_tokens"],
            "context_limit": limit,
            "saturation": round(sat, 4),
            "raw_total_tokens": s["raw_total_tokens"],
            "effective_total_tokens": s["effective_total_tokens"],
            "agents_invoked": s["agents"],
            "skills_invoked": s["skills"],
            "tool_calls": sum(s["tools"].values()),
            "report": f"{s['session_id']}.md",
        })
    out_sessions.sort(key=lambda x: (not x["running"], -(x["last_ts"] or 0)))
    return {
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "agents_running": running,
        "sessions_total": len(out_sessions),
        "planes": sorted({s["plane"] for s in out_sessions}),
        "sessions": out_sessions,
    }


def write_reports(sessions, cfg):
    rdir = cfg["reports_dir"]
    os.makedirs(rdir, exist_ok=True)
    for s in sessions:
        base = os.path.join(rdir, s["session_id"])
        report = {k: v for k, v in s.items() if not k.startswith("_")}
        report["trace"] = s["_events"]
        with open(base + ".json", "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
        with open(base + ".md", "w", encoding="utf-8") as f:
            _write_md(f, s, cfg)


def _write_md(f, s, cfg):
    limits = cfg["model_context_limits"]
    f.write(f"# Audit trace — {s['session_id']}\n\n")
    f.write(f"- Plane: **{s['plane']}**\n")
    f.write(f"- Project: **{s['project'] or '(unknown)'}**"
            + (f" (branch `{s['git_branch']}`)" if s['git_branch'] else "") + "\n")
    f.write(f"- Turns: {s['turn_count']}  |  Events: {s['event_count']}\n")
    f.write(f"- Tokens: raw {s['raw_total_tokens']:,} / effective {s['effective_total_tokens']:,.0f}\n\n")

    f.write("## Tokens by model\n\n")
    f.write("| Model | Turns | Input | Output | Cache read | Cache write | Raw | Effective |\n")
    f.write("|---|--:|--:|--:|--:|--:|--:|--:|\n")
    for model, a in sorted(s["by_model"].items()):
        f.write(f"| {model} | {a['turns']} | {a['input']:,} | {a['output']:,} | "
                f"{a['cache_read']:,} | {a['cache_creation']:,} | {a['raw_total']:,} | "
                f"{a['effective_total']:,.0f} |\n")
    f.write("\n")

    if s["agents"]:
        f.write("## Agents invoked\n\n")
        for name, c in sorted(s["agents"].items(), key=lambda x: -x[1]):
            f.write(f"- `{name}` ×{c}\n")
        f.write("\n")
    if s["skills"]:
        f.write("## Skills invoked\n\n")
        for name, c in sorted(s["skills"].items(), key=lambda x: -x[1]):
            f.write(f"- `{name}` ×{c}\n")
        f.write("\n")

    f.write("## Ordered trace (agents / skills / tools)\n\n")
    for e in s["_events"]:
        tstr = ""
        if e["ts"]:
            tstr = datetime.fromtimestamp(e["ts"], timezone.utc).strftime("%H:%M:%S")
        marker = {"agent": "AGENT", "skill": "SKILL", "tool": "tool "}[e["kind"]]
        side = " (subagent)" if e["sidechain"] else ""
        detail = f" — {e['detail']}" if e["detail"] else ""
        f.write(f"- `{tstr}` {marker} **{e['name']}**{side}{detail}\n")


# ── usage budgets (rolling-window consumption vs configured limits) ────────────

def _monthly_cycle_bounds(now_dt, reset_day):
    """(start_epoch, end_epoch) for the billing cycle containing now_dt, anchored to
    reset_day (UTC). Clamps reset_day to the last day of short months."""
    def clamp(y, m, d):
        nxt = datetime(y + 1, 1, 1, tzinfo=timezone.utc) if m == 12 \
            else datetime(y, m + 1, 1, tzinfo=timezone.utc)
        last = (nxt - timedelta(days=1)).day
        return min(d, last)
    y, m = now_dt.year, now_dt.month
    this_start = datetime(y, m, clamp(y, m, reset_day), tzinfo=timezone.utc)
    if now_dt >= this_start:
        start = this_start
        ny, nm = (y + 1, 1) if m == 12 else (y, m + 1)
        end = datetime(ny, nm, clamp(ny, nm, reset_day), tzinfo=timezone.utc)
    else:
        py, pm = (y - 1, 12) if m == 1 else (y, m - 1)
        start = datetime(py, pm, clamp(py, pm, reset_day), tzinfo=timezone.utc)
        end = this_start
    return start.timestamp(), end.timestamp()


def compute_usage(sessions, cfg):
    """Account-wide usage vs configured budgets (rolling windows and/or anchored billing
    cycles). Offline estimate from local logs — the native logs do not carry plan quotas,
    so limits are user-set and this approximates, never reads, the real account meter."""
    budgets_cfg = cfg.get("usage_budgets", [])
    look_h = float(cfg.get("usage_burn_lookback_hours", 1.0)) or 1.0

    turns = []
    for s in sessions:
        for t in s["_turns"]:
            if t["ts"] is None:
                continue
            raw = t["input"] + t["output"] + t["cache_read"] + t["cache_creation"]
            turns.append((t["ts"], raw, t["effective"]))

    now = now_epoch()
    now_dt = datetime.now(timezone.utc)
    # burn rate over the recent lookback (independent of window)
    r_start = now - look_h * 3600
    recent_eff = sum(e for (ts, r, e) in turns if ts >= r_start)
    recent_raw = sum(r for (ts, r, e) in turns if ts >= r_start)

    budgets = []
    notifications = []
    for b in budgets_cfg:
        metric = b.get("metric", "effective")
        limit = float(b.get("limit_tokens", 0) or 0)
        warn_at = float(b.get("warn_at", 0.8))
        alert_at = float(b.get("alert_at", 0.95))

        if b.get("cycle") == "monthly":
            reset_day = int(b.get("reset_day", 1))
            w_start, w_end = _monthly_cycle_bounds(now_dt, reset_day)
            window_label = f"resets day {reset_day}"
            hours_remaining = max(0.0, (w_end - now) / 3600)
            is_cycle = True
        else:
            wh = float(b.get("window_hours", 5)) or 5.0
            w_start, w_end = now - wh * 3600, None
            window_label = f"{wh:g}h window"
            hours_remaining = None
            is_cycle = False

        used_raw = sum(r for (ts, r, e) in turns if ts >= w_start)
        used_eff = sum(e for (ts, r, e) in turns if ts >= w_start)
        used = used_eff if metric == "effective" else used_raw

        # Projection pace: for a long anchored cycle, use the cycle-average pace
        # (usage so far / time elapsed this cycle) — extrapolating a 1-hour burst over
        # weeks is meaningless. For a short rolling window, use the recent burn rate.
        recent_burn = (recent_eff if metric == "effective" else recent_raw) / look_h if look_h else 0.0
        if is_cycle:
            elapsed_h = max((now - w_start) / 3600, 1e-6)
            pace = used / elapsed_h
        else:
            pace = recent_burn

        status, pct, hours_to_limit, projected, projected_total = "unset", None, None, False, None
        if limit > 0:
            pct = used / limit
            status = "over" if pct >= 1.0 else ("alert" if pct >= alert_at
                     else ("warn" if pct >= warn_at else "ok"))
            if used < limit and pace > 0:
                hours_to_limit = (limit - used) / pace
            if is_cycle:
                projected_total = used + pace * hours_remaining
                if used < limit and projected_total >= limit:
                    projected = True
            else:
                if hours_to_limit is not None and hours_to_limit <= 1.0:
                    projected = True

            if status in ("warn", "alert", "over"):
                notifications.append({
                    "budget": b.get("name", "budget"), "level": status,
                    "message": f"{b.get('name','budget')} at {pct*100:.0f}% of limit "
                               f"({int(used):,}/{int(limit):,} {metric} tokens)."})
            elif projected and is_cycle:
                notifications.append({
                    "budget": b.get("name", "budget"), "level": "warn",
                    "message": f"{b.get('name','budget')} projected to exceed before reset "
                               f"(est ~{int(projected_total):,} vs {int(limit):,} {metric} tokens)."})
            elif projected:
                notifications.append({
                    "budget": b.get("name", "budget"), "level": "warn",
                    "message": f"{b.get('name','budget')} projected to exceed in "
                               f"~{int(hours_to_limit*60)} min at current burn rate."})

        budgets.append({
            "name": b.get("name", "budget"),
            "type": "monthly" if is_cycle else "rolling",
            "window_label": window_label,
            "reset_day": (int(b.get("reset_day", 1)) if is_cycle else None),
            "cycle_end_iso": (datetime.fromtimestamp(w_end, timezone.utc).isoformat() if w_end else None),
            "days_to_reset": (round(hours_remaining / 24, 2) if hours_remaining is not None else None),
            "metric": metric, "used_tokens": int(used), "used_raw": int(used_raw),
            "used_effective": int(used_eff), "limit_tokens": int(limit),
            "pct": (round(pct, 4) if pct is not None else None), "status": status,
            "burn_per_hour": int(pace), "pace_basis": ("cycle-average" if is_cycle else "recent"),
            "hours_to_limit": (round(hours_to_limit, 2) if hours_to_limit is not None else None),
            "projected_total": (int(projected_total) if projected_total is not None else None),
            "projected_exceed": projected,
        })

    return {"budgets": budgets, "notifications": notifications}


# ── main pass / loop ──────────────────────────────────────────────────────────

def collect_sessions(cfg):
    labels = [(expand(e["path"]).rstrip("/"), e["label"])
              for e in cfg.get("project_labels", [])
              if e.get("path") and e.get("label")]
    sessions = []
    for src in cfg["log_sources"]:
        root = expand(src["root"])
        for path in find_transcripts(root):
            s = parse_transcript(path, src["plane"], cfg["effective_token_weights"], labels)
            if s and (s["turn_count"] or s["event_count"]):
                sessions.append(s)
    return sessions


def calibrate(cfg, specs):
    """Suggest limit_tokens for budgets from account percentages you read off your Claude
    usage page, e.g. --calibrate "5-hour window=22". Non-destructive: prints suggestions
    for you to paste into config.json. Calibrated to LOCAL usage only, so run this on the
    host where your real Claude usage lives."""
    usage = compute_usage(collect_sessions(cfg), cfg)
    by_name = {b["name"]: b for b in usage["budgets"]}
    print("Calibration (limit = measured local usage / account%). Local-share estimate.\n")
    for spec in specs:
        name, _, pct_s = spec.partition("=")
        name = name.strip()
        try:
            pct = float(pct_s)
        except ValueError:
            print(f"  '{spec}': expected NAME=PERCENT"); continue
        b = by_name.get(name) or next(
            (v for k, v in by_name.items() if name.lower() in k.lower()), None)
        if b is None:
            print(f"  no budget matching '{name}'. Known: {', '.join(by_name)}"); continue
        if pct <= 0:
            print(f"  [{b['name']}] account at {pct}% — too low to calibrate; usage so far "
                  f"= {b['used_tokens']:,} {b['metric']} tokens"); continue
        suggested = int(b["used_tokens"] / (pct / 100.0))
        print(f"  [{b['name']}] measured used = {b['used_tokens']:,} {b['metric']} tokens; "
              f"account = {pct}%  ->  suggested limit_tokens = {suggested:,}")
    print("\nPaste the suggested value(s) into audit/config.json (usage_budgets[].limit_tokens).")


def one_pass(cfg):
    sessions = collect_sessions(cfg)
    state = build_state(sessions, cfg)
    usage = compute_usage(sessions, cfg)
    state["usage"] = usage["budgets"]
    state["notifications"] = usage["notifications"]
    os.makedirs(os.path.dirname(cfg["state_path"]), exist_ok=True)
    with open(cfg["state_path"], "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
    write_reports(sessions, cfg)
    return state


def main():
    ap = argparse.ArgumentParser(description="Offline audit worker for Claude native logs.")
    ap.add_argument("--config", default=os.path.join(HERE, "config.json"))
    ap.add_argument("--once", action="store_true", help="Run a single pass and exit.")
    ap.add_argument("--calibrate", action="append", default=[], metavar='"NAME=PCT"',
                    help='Suggest limit_tokens for a budget from an account percentage, '
                         'e.g. --calibrate "5-hour window=22". Repeatable. Prints only.')
    args = ap.parse_args()

    cfg = load_config(args.config)
    if args.calibrate:
        calibrate(cfg, args.calibrate)
        return
    if args.once:
        state = one_pass(cfg)
        print(f"[audit] {state['sessions_total']} sessions, "
              f"{state['agents_running']} running -> {cfg['state_path']}")
        return

    print(f"[audit] watching {len(cfg['log_sources'])} plane(s), "
          f"poll={cfg['poll_seconds']}s. Ctrl-C to stop.")
    while True:
        try:
            state = one_pass(cfg)
            print(f"[audit] {datetime.now().strftime('%H:%M:%S')} "
                  f"{state['sessions_total']} sessions, {state['agents_running']} running")
        except Exception as e:  # never die on a transient parse/IO error
            print(f"[audit] pass error: {e}", file=sys.stderr)
        time.sleep(cfg["poll_seconds"])


if __name__ == "__main__":
    main()
