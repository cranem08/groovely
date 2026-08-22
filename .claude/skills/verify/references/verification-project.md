# Reference: Clean-Room Verification Project — Scaffold, Ingest, Report

How the `verify` agent structures, feeds, and runs the verification project so its
judgement cannot be influenced by the build. Project-agnostic; concrete commands come from
`commands-map.yaml`.

## Clean-room execution

Verify runs in its **own fresh environment** with its **own trusted toolchain**. It never
executes inside the builder's workspace, never sources the builder's configs
(linters, test runners, `node_modules`, etc.). It ingests exactly two things:

1. the **pristine spec** — copied from the product-workflow plane, never read from the
   build; and
2. the **built artefact as inert input** — the content-addressed bundle (files to read)
   and the deployed URL (to drive).

Because the spec comes from the human plane and the build output is only ever inspected,
there is nothing in the build a tampering builder could alter to change verify's verdict.

## Project scaffold

```
projects/{name}/verification/
├── package.json / <toolchain manifest>   # verify's own, not the build's
├── <runner config>                       # baseURL resolved from deployment.yaml
├── tests/
│   ├── behaviour/        # black-box, one spec per .feature, one test per scenario
│   ├── data/             # data-capture & presentation correctness
│   └── architecture/
│       ├── static/       # dependency-direction, pins, config, forbidden-api, extras
│       └── runtime/      # rules observable only on the running app
├── harness/              # traceability index; mutation & inversion harnesses (teeth)
└── report/verify-report.md
```

The verification project is authored by verify from the spec and is **not** part of the
handoff image; the Dark Factory neither ships nor edits it.

## Artefact identity

The build emits a single immutable, **content-addressed** artefact (a hash of the
bundle). Verify records that hash, certifies exactly those bytes, and the deployment step
promotes the identical bytes — no rebuild between passing and shipping. The hash is
recorded in the report and is the thread tying "what shipped" to "what passed". The
manifest version the build was made against is read from a **neutral-harness-stamped**
record, never from a builder self-report.

## Report format (self-scoping)

```
── Verify Report ────────────────────────────────────────────────
Project:   {name}
Spec:      specification v{X}   (feature files, fitness.md, data model, NFRs)
Artefact:  {content hash}
Date:      {YYYY-MM-DD HH:MM}
Verdict:   PASS — conforms to specification v{X}   |   FAIL

Attests:      conformance of the built artefact to specification v{X}.
Does NOT attest: design quality; soundness or wisdom of the spec; anything the
                 spec does not assert.

Coverage (traceability)
  clauses: {N}   checks: {M}   downward gaps: {0 required}   orphan checks: {0 required}

Teeth
  structural mutants killed: {k}/{k}    behavioural inversions caught: {j}/{j}
  toothless checks: {0 required to pass}

Conformance — everything specified present
  [clause-id] {full human statement} .......... PASS | FAIL {detail}

Conformance — nothing unspecified present
  {surface}: extras found: {0 required to pass} {detail with full context}

Non-gating: build guardrail audit
  weak spots (verify caught, build's own tests missed): {list — informational}
──────────────────────────────────────────────────────────────────
```

Every line names the clause's full human statement, never a bare ID. A FAIL routes a code
defect back to the Dark Factory (fix code) or, if a *rule* is wrong, back to
`design` → `sufficiency-check` (fix spec) — never edited in place.

## product-log sentinel

Append on completion, exact format:
`| {date} | verify | {PASS conforms to spec vX | FAIL: n findings}. Artefact {hash}. See verification/report/verify-report.md. |`
