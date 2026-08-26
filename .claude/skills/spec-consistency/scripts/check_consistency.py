#!/usr/bin/env python3
"""
Cross-artefact consistency checks for a product-workflow project.

Applied by the sufficiency-check agent (full sweep) and by
.claude/hooks/validate-artefact.sh (single file, blocking on write).

Checks
  RETIRED   a term the project has abandoned appears in a live artefact
  CONSTANT  an artefact states a value that disagrees with constants.md
  GLOSSARY  a term defined in the glossary is used nowhere (reverse closure)

Deliberate limits, stated rather than implied:
  - Forward glossary closure (every scenario term is defined) is not
    mechanically decidable and is not attempted.
  - CONSTANT uses keyword proximity over a curated probe set, not every
    registered constant. A precise check over the high-risk constants is
    worth more than a noisy one over all of them.

Usage
  check_consistency.py --project DIR [--file PATH]
Exit
  0 clean, 1 findings, 2 configuration error
"""
import argparse, os, re, sys

# Artefacts permitted to name a retired term: the registries and the
# historical record. Findings and logs must be able to say what was cut.
RETIRED_EXEMPT_FILES = {
    "docs/specs/retired-terms.md",
    "docs/specs/out-of-scope.md",
    "product-log.md",
    "workflow-findings.md",
    "UPSTREAM.md",
}
RETIRED_EXEMPT_DIRS = ("docs/build/",)

# A line that is itself a record of the retirement may name the term.
# A pragma block runs until the next heading.
PRAGMA_END = re.compile(r"^#{1,6}\s")
CUT_RECORD = re.compile(
    r"(—\s*\*\*cut\*\*|—\s*cut\b|\*\*cut\*\*|\bwas cut\b|\bwere cut\b|\bcut under\b|"
    r"\bcut on review\b|\bretired\b|\bremoved under\b|\bspecified and then (cut|removed)\b|"
    r"\bno longer\b|\bRejected\b)", re.I)

# The CONSTANT check runs ONLY over specification artefacts. Logs, findings
# and reports legitimately quote superseded values while recounting history;
# scanning them produces noise, and a check that cries wolf is worth less
# than no check at all.
SPEC_DIRS = ("docs/specs/", "docs/designs/", "docs/features/")
SPEC_EXEMPT = {"docs/specs/constants.md", "docs/specs/retired-terms.md"}

# Each probe fires only when the line ALSO carries a unit. Requiring the unit
# is what stops a finding number, a section number or a date from being read
# as a value.
UNITS = r"(day|minute|second|hour|character|record|digit|photograph|code|attempt|MiB|GiB|MB|ms|px|pixel)"
PROBES = {
    "page size":            {"10", "12", "ten", "twelve"},
    # "twenty" is two list pages of ten — a DERIVED value, legitimate.
    "records rather than":  {"10", "12", "20", "200", "ten", "twelve", "twenty", "two hundred"},
    "consecutive failed":   {"5", "4", "four", "five", "fifth"},
    "lock an account":      {"5", "15", "four", "five", "fifth", "fifteen"},
    "locks the account":    {"5", "15", "four", "five", "fifth", "fifteen"},
    "consecutive failed password attempts": {"5", "15", "four", "five", "fifth", "fifteen"},
    "temporarily locked":   {"15", "fifteen"},
    "password must be":     {"12", "twelve"},
    "password may be":      {"128", "one hundred and twenty eight"},
    "rolling":              {"30", "thirty"},
    "idle expiry":          {"30", "29", "thirty", "twenty nine"},
    "absolute cap":          {"90", "ninety"},
    "trusted device":       {"30", "29", "thirty", "twenty nine"},
    "expires absolutely":   {"30", "thirty"},
    "trust this device":    {"30", "thirty"},
    "verification link":    {"24", "twenty four"},
    "reset link":           {"60", "sixty"},
    "tombstone":            {"90", "ninety"},
    "soft-deleted":         {"90", "ninety"},
    "photographs per record": {"2", "two"},
    "hard timeout":         {"10", "ten"},
    "size cap":             {"2", "two"},
    # C-040. Deliberately probed on "longest edge" rather than on "pixels":
    # feature scenarios state many legitimate pixel values (an oversized upload,
    # a shape to preserve), and a probe on the unit would fire on all of them.
    # "Longest edge" is the phrase that means the constant.
    "longest edge":         {"1000", "one thousand", "one thousand and one"},
    "recovery code":        {"3", "10", "ten"},  # "3." is a numbered scope item
}
NUMWORDS = ("one thousand and one|one thousand|one hundred and twenty eight|two hundred|"
            "twenty nine|twenty four|ten|twelve|four|five|fifth|fifteen|thirty|ninety|"
            "eighty|sixty|twenty|two")
NUM_RE = re.compile(r"\b(\d{1,4})\b|\b(" + NUMWORDS + r")\b", re.I)
DATE_RE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}:\d{2}\b")
# A CONSTANT REFERENCE IS NOT A VALUE. "C-043" carries the digits 043, and a
# reference sitting next to a unit — "C-043 of photographs per record" — was read
# as the value 43 and reported as contradicting the constant. That punishes
# exactly the behaviour the registry exists to encourage: citing the ID instead
# of restating the number. References are stripped before any number is read.
CONSTREF_RE = re.compile(r"\bC-\d{3}\b")
UNIT_RE = re.compile(UNITS, re.I)
def hit_term(term, text):
    """Whole-term match: not part of a longer word or hyphenated compound."""
    return re.search(r"(?<![\w-])" + re.escape(term.lower()) + r"(?![\w-])", text) is not None

def probe_hit(probe, line):
    return re.search(r"(?<![\w-])" + re.escape(probe) + r"(?![\w-])", line, re.I) is not None
def near_unit(line, end):
    return UNIT_RE.search(line[end:end + 24]) is not None

def rel(project, path):
    return os.path.relpath(path, project).replace(os.sep, "/")

def artefacts(project):
    out = []
    for base in ("docs", ""):
        root = os.path.join(project, base) if base else project
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [d for d in dirnames if d not in (".git", "_to_delete", "build")]
            for fn in filenames:
                if fn.endswith((".md", ".feature")):
                    p = os.path.join(dirpath, fn)
                    if p not in out and "_bundle" not in fn:
                        out.append(p)
        if not base:
            break
    return sorted(set(out))

def parse_retired(project):
    """Terms from the 'Retired' table only — 'Awaiting a ruling' is excluded."""
    path = os.path.join(project, "docs/specs/retired-terms.md")
    if not os.path.exists(path):
        return []
    terms, in_retired = [], False
    for line in open(path):
        if line.strip().startswith("## Retired"):
            in_retired = True; continue
        if line.startswith("## ") and in_retired:
            break
        if in_retired and line.startswith("|") and not line.startswith("|---"):
            cell = line.split("|")[1].strip()
            if not cell or cell.lower().startswith("term"):
                continue
            # Backticked terms ONLY. A retired term must be registered in a
            # form specific enough to be unambiguous — a bare common word
            # such as "gallery" or "everything" collides with ordinary prose
            # and makes the check worthless.
            for t in re.findall(r"`([^`]+)`", cell):
                t = t.strip()
                if len(t) >= 4:
                    terms.append(t)
    return sorted({t for t in terms if t})

def parse_glossary(project):
    path = os.path.join(project, "docs/specs/glossary.md")
    if not os.path.exists(path):
        return []
    return sorted(set(re.findall(r"\|\s*\*\*([^*]+)\*\*\s*\|", open(path).read())))

def check(project, only=None):
    findings = []
    files = artefacts(project)
    retired = parse_retired(project)

    for path in files:
        r = rel(project, path)
        if only and os.path.abspath(path) != os.path.abspath(only):
            continue
        try:
            lines = open(path, encoding="utf-8").read().splitlines()
        except Exception:
            continue

        exempt = r in RETIRED_EXEMPT_FILES or any(r.startswith(d) for d in RETIRED_EXEMPT_DIRS)
        in_cut_section = False
        in_pragma_block = False

        for n, line in enumerate(lines, 1):
            low = line.lower()

            # A heading that marks a retirement makes its whole section a cut
            # record. "## 6. Wantlist — cut" must be free to explain itself.
            if line.startswith("#"):
                in_cut_section = bool(CUT_RECORD.search(line))
            if re.match(r"^#{1,3}\s", line) and not CUT_RECORD.search(line):
                in_cut_section = False

            # Explicit pragma. Some prose legitimately names a retired concept —
            # explaining why it went, or listing what the product is not. Declaring
            # that is honest; widening the heuristic until it guesses correctly is
            # an arms race with English.
            if "consistency:retired-ok" in low:
                in_pragma_block = True
            if PRAGMA_END.match(line):
                in_pragma_block = False

            if (not exempt and not in_cut_section and not in_pragma_block
                    and "consistency:retired-ok" not in low
                    and not CUT_RECORD.search(line)):
                for term in retired:
                    if hit_term(term, low):
                        findings.append(("RETIRED", r, n,
                            f"retired term {term!r} appears in a live artefact", line.strip()[:110]))
                        break
                else:
                    # A multi-word retired term WRAPPED ACROSS A LINE BREAK is
                    # the same term, and a line-scoped check lets it through a
                    # gate whose whole purpose is to block it.
                    #
                    # Two conditions keep this from crying wolf. The next line
                    # must carry no exemption of its own — a blank line
                    # followed by "Purchase price ... was cut on review" is a
                    # cut record, not residue, and the blank line must not
                    # launder it into a finding. And the term must appear in
                    # the JOINED text while appearing in NEITHER line alone —
                    # a match contained in one line is that line's to report,
                    # on its own iteration, under its own exemptions.
                    nxt = lines[n] if n < len(lines) else ""
                    if (nxt and not CUT_RECORD.search(nxt)
                            and "consistency:retired-ok" not in nxt.lower()):
                        joined = re.sub(r"\s+", " ", low + " " + nxt.lower())
                        for term in retired:
                            if (hit_term(term, joined)
                                    and not hit_term(term, low)
                                    and not hit_term(term, nxt.lower())):
                                findings.append(("RETIRED", r, n,
                                    f"retired term {term!r} appears in a live artefact, "
                                    "wrapped across this line and the next",
                                    line.strip()[:110]))
                                break

            spec_scope = any(r.startswith(d) for d in SPEC_DIRS) and r not in SPEC_EXEMPT
            scrubbed = CONSTREF_RE.sub(" ", DATE_RE.sub(" ", line))
            # A line may legitimately state several constants ("5 attempts
            # locks the account for 15 minutes"). Pool the permitted values of
            # every probe the line matches, or each rejects the other's value.
            if spec_scope and UNIT_RE.search(scrubbed):
                hit = [p for p in PROBES if probe_hit(p, low)]
                if hit:
                    allowed = {a.lower() for p in hit for a in PROBES[p]}
                    for m in NUM_RE.finditer(scrubbed):
                        tok = (m.group(1) or m.group(2)).lower()
                        # a number only counts as a value if a unit follows it;
                        # "The two counters" is English, not a quantity
                        if not near_unit(scrubbed, m.end()):
                            continue
                        if tok not in allowed:
                            findings.append(("CONSTANT", r, n,
                                f"value {tok!r} on a line about {', '.join(hit)!r}; "
                                "constants.md permits " + ", ".join(sorted(allowed)),
                                line.strip()[:110]))

    if not only:
        # Whitespace is normalised before matching: a multi-word glossary term
        # wrapped across a line ("the **display\n        # image** is chosen") is the
        # same term, and a check that misses it reports a live term as unused.
        blob = re.sub(r"\s+", " ", "\n".join(
            open(p, encoding="utf-8", errors="ignore").read()
            for p in files if not p.endswith("glossary.md")))
        for term in parse_glossary(project):
            if not re.search(r"(?<![\w-])" + re.escape(term.lower()) + r"(?![\w-])", blob.lower()):
                findings.append(("GLOSSARY", "docs/specs/glossary.md", 0,
                    f"defined term {term!r} is used in no other artefact", ""))
    return findings

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--project", required=True)
    ap.add_argument("--file")
    a = ap.parse_args()
    if not os.path.isdir(a.project):
        print(f"not a directory: {a.project}", file=sys.stderr); return 2
    fs = check(a.project, a.file)
    if not fs:
        print("consistency: clean"); return 0
    by = {}
    for kind, f, n, msg, ctx in fs:
        by.setdefault(kind, []).append((f, n, msg, ctx))
    for kind in ("RETIRED", "CONSTANT", "GLOSSARY"):
        if kind not in by: continue
        print(f"\n{kind} — {len(by[kind])} finding(s)", file=sys.stderr)
        for f, n, msg, ctx in by[kind]:
            loc = f"{f}:{n}" if n else f
            print(f"  ✗ {loc}\n      {msg}", file=sys.stderr)
            if ctx: print(f"      | {ctx}", file=sys.stderr)
    print(f"\nconsistency: {len(fs)} finding(s)", file=sys.stderr)
    return 1

if __name__ == "__main__":
    sys.exit(main())
