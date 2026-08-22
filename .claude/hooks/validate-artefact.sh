#!/usr/bin/env bash
# PostToolUse (Write) hook: validate BDD .feature files and ADR templates.
#
# Triggers on every Write tool call and inspects the file path:
#   *.feature files      → structural BDD format check
#   adrs/ADR-*.md files  → ADR template completeness check
#   all other files      → pass through silently
#
# Enforced BDD rules (from standards/bdd.md):
#   - Feature: declaration present
#   - At least one Scenario: block
#   - Each scenario has exactly one Given, one When, one Then
#   - 'And' is prohibited in all scenario steps and Background steps
#   - Background (if present) has exactly one Given step
#
# Exits non-zero on failure so Claude Code surfaces the violation immediately.

set -uo pipefail

# Read JSON payload from stdin
INPUT=$(cat)

# Extract file_path from tool_input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    tool_input = data.get('tool_input', {})
    print(tool_input.get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Nothing to validate if we can't determine the path
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# File must exist on disk (PostToolUse runs after Write completes)
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# ── BDD .feature file validation ─────────────────────────────────────────────

if [[ "$FILE_PATH" == *.feature ]]; then
    ERRORS=()

    # Must have a Feature: declaration
    if ! grep -q "^Feature:" "$FILE_PATH" 2>/dev/null; then
        ERRORS+=("Missing 'Feature:' declaration at the top of the file")
    fi

    # Must have at least one Scenario
    if ! grep -qE "^\s*(Scenario:|Scenario Outline:)" "$FILE_PATH" 2>/dev/null; then
        ERRORS+=("No 'Scenario:' or 'Scenario Outline:' block found")
    fi

    # Enforce one-Given/one-When/one-Then and no And
    STEP_ISSUES=$(python3 - "$FILE_PATH" <<'PYEOF'
import sys, re

try:
    content = open(sys.argv[1]).read()
except Exception:
    sys.exit(0)

issues = []
lines = content.splitlines()

# ── Parse into sections ───────────────────────────────────────────────────────
# Sections: background (optional) and list of scenarios.
# A "step line" starts with Given/When/Then/And/But (ignoring table rows,
# docstrings, comments, and blank lines).

STEP_RE = re.compile(r'^\s*(Given|When|Then|And|But)\s+')
SCENARIO_RE = re.compile(r'^\s*(Scenario:|Scenario Outline:)\s*(.*)')
BACKGROUND_RE = re.compile(r'^\s*Background:')

background_steps = []
scenarios = []          # list of (label, [step_keywords])
current_label = None
current_steps = []
in_background = False
in_scenario = False

for line in lines:
    if BACKGROUND_RE.match(line):
        in_background = True
        in_scenario = False
        current_steps = []
        continue

    m = SCENARIO_RE.match(line)
    if m:
        if in_background:
            background_steps = current_steps[:]
        elif in_scenario and current_label is not None:
            scenarios.append((current_label, current_steps[:]))
        in_background = False
        in_scenario = True
        current_label = m.group(2).strip() or f"Scenario {len(scenarios)+1}"
        current_steps = []
        continue

    if in_background or in_scenario:
        sm = STEP_RE.match(line)
        if sm:
            current_steps.append(sm.group(1))  # just the keyword

if in_background:
    background_steps = current_steps[:]
elif in_scenario and current_label is not None:
    scenarios.append((current_label, current_steps[:]))

# ── Validate Background ───────────────────────────────────────────────────────
if background_steps:
    and_count = background_steps.count('And') + background_steps.count('But')
    given_count = background_steps.count('Given')
    if and_count > 0:
        issues.append(
            "Background: 'And' is prohibited — merge all background steps "
            "into a single Given statement"
        )
    if given_count > 1:
        issues.append(
            f"Background: expected exactly 1 Given step, found {given_count} — "
            "merge into a single Given statement"
        )

# ── Validate each Scenario ────────────────────────────────────────────────────
for idx, (label, steps) in enumerate(scenarios, 1):
    tag = f"Scenario {idx} ('{label}')"

    given_count = steps.count('Given')
    when_count  = steps.count('When')
    then_count  = steps.count('Then')
    and_count   = steps.count('And') + steps.count('But')

    if and_count > 0:
        issues.append(
            f"{tag}: 'And' is prohibited ({and_count} occurrence(s)). "
            "Each scenario must have exactly one Given, one When, one Then. "
            "Split multiple outcomes into separate scenarios."
        )
    if given_count != 1:
        issues.append(
            f"{tag}: expected exactly 1 Given, found {given_count}."
        )
    if when_count != 1:
        issues.append(
            f"{tag}: expected exactly 1 When, found {when_count}."
        )
    if then_count != 1:
        issues.append(
            f"{tag}: expected exactly 1 Then, found {then_count}."
        )

for issue in issues:
    print(issue)
PYEOF
)

    if [ -n "$STEP_ISSUES" ]; then
        while IFS= read -r line; do
            ERRORS+=("$line")
        done <<< "$STEP_ISSUES"
    fi

    if [ ${#ERRORS[@]} -gt 0 ]; then
        echo "BDD validation failed: $FILE_PATH" >&2
        for err in "${ERRORS[@]}"; do
            echo "  ✗ $err" >&2
        done
        exit 1
    fi

    exit 0
fi

# ── ADR template validation ───────────────────────────────────────────────────

if [[ "$FILE_PATH" == */adrs/ADR-*.md ]]; then
    REQUIRED=("Status" "Context" "Decision" "Consequences" "Alternatives Considered")
    MISSING=()

    for section in "${REQUIRED[@]}"; do
        if ! grep -q "^## $section" "$FILE_PATH" 2>/dev/null; then
            MISSING+=("$section")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "ADR template validation failed: $FILE_PATH" >&2
        echo "  Missing required sections:" >&2
        for section in "${MISSING[@]}"; do
            echo "    ✗ ## $section" >&2
        done
        exit 1
    fi

    exit 0
fi

# All other file types — pass through silently
exit 0
