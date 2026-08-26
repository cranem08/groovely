#!/usr/bin/env python3
"""
Apply one specification edit, asserting it actually happened.

Exists because a script reporting success without asserting its match wrote two
false completion entries into product-log.md — the artefact the navigator and
package agents read to decide project state.

  apply_resolution.py --file PATH --old TEXT --new TEXT [--expect N]

Exit 0 applied and verified, 1 not applied, 2 usage error.
"""
import argparse, os, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True)
    ap.add_argument("--old", required=True)
    ap.add_argument("--new", required=True)
    ap.add_argument("--expect", type=int, default=1,
                    help="required number of matches (default 1)")
    a = ap.parse_args()

    if not os.path.isfile(a.file):
        print(f"✗ no such file: {a.file}", file=sys.stderr); return 2

    before = open(a.file, encoding="utf-8").read()
    n = before.count(a.old)

    if n != a.expect:
        print(f"✗ NOT APPLIED — {a.file}", file=sys.stderr)
        print(f"    expected {a.expect} match(es), found {n}", file=sys.stderr)
        print(f"    searched for: {a.old[:90]!r}", file=sys.stderr)
        if n == 0:
            print("    the text is not present — it may already have been changed,", file=sys.stderr)
            print("    or the search string may not match the file exactly.", file=sys.stderr)
        else:
            print("    widen the search string until it is unique, or pass --expect.", file=sys.stderr)
        return 1

    open(a.file, "w", encoding="utf-8").write(before.replace(a.old, a.new))

    after = open(a.file, encoding="utf-8").read()
    if after == before:
        print(f"✗ NOT APPLIED — {a.file}: file unchanged after write", file=sys.stderr); return 1
    if a.new and a.new not in after:
        print(f"✗ NOT APPLIED — {a.file}: replacement text absent after write", file=sys.stderr); return 1

    print(f"✓ applied and verified — {a.file} ({a.expect} replacement(s))")
    return 0

if __name__ == "__main__":
    sys.exit(main())
