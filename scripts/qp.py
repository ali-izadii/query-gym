#!/usr/bin/env python3
"""qp - the query-practice CLI.

Solutions live in solutions/NN_topic.sql as a sequence of blocks:

    -- ===== T05-03 =====
    -- level: intermediate
    -- title: Running revenue per customer
    -- task: Compute the cumulative revenue per customer ordered by placed_at.
    -- hint: SUM(...) OVER (PARTITION BY ... ORDER BY ...)
    -- concepts: window frame, partition by
    -- kind: select            (select | dml | script; default select)
    SELECT ...;

Commands
    qp.py list [topic]            list topics / exercises
    qp.py show <id>               show task text (no answer)
    qp.py answer <id>             print the reference SQL
    qp.py run <id>                execute the reference SQL, print results
    qp.py explain <id>            EXPLAIN (ANALYZE, BUFFERS) the reference SQL
    qp.py check [topic]           execute every reference SQL, report failures
    qp.py diff <id> <file.sql>    compare your query's result to the reference
    qp.py new <id>                scaffold work/<id>.sql
    qp.py gen                     regenerate exercises/*.md from the headers
"""
from __future__ import annotations

import argparse
import collections
import os
import pathlib
import re
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOL_DIR = ROOT / "solutions"
EX_DIR = ROOT / "exercises"
WORK_DIR = ROOT / "work"

BLOCK_RE = re.compile(r"^--\s*=====\s*(?P<id>[A-Za-z0-9\-]+)\s*=====\s*$")
FIELD_RE = re.compile(r"^--\s*(?P<k>level|title|task|hint|concepts|kind|note)\s*:\s*(?P<v>.*)$", re.I)

LEVELS = ["basic", "intermediate", "advanced", "expert"]
BADGE = {"basic": "🟢 basic", "intermediate": "🟡 intermediate",
         "advanced": "🟠 advanced", "expert": "🔴 expert"}


# --------------------------------------------------------------------------- env
def env() -> dict[str, str]:
    cfg = {"POSTGRES_USER": "qp", "POSTGRES_DB": "querypractice"}
    envfile = ROOT / ".env"
    if envfile.exists():
        for line in envfile.read_text().splitlines():
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                cfg[k.strip()] = v.strip()
    cfg.update({k: v for k, v in os.environ.items() if k.startswith("POSTGRES_")})
    return cfg


def psql(sql: str, *, args: list[str] | None = None, check: bool = True) -> subprocess.CompletedProcess:
    cfg = env()
    cmd = ["docker", "compose", "exec", "-T", "db", "psql",
           "-v", "ON_ERROR_STOP=1", "-X",
           "-U", cfg["POSTGRES_USER"], "-d", cfg["POSTGRES_DB"]]
    cmd += args or []
    cmd += ["-f", "-"]
    p = subprocess.run(cmd, input=sql, text=True, capture_output=True, cwd=ROOT)
    if check and p.returncode != 0:
        sys.stderr.write(p.stderr)
        raise SystemExit(p.returncode)
    return p


# ------------------------------------------------------------------------ parsing
class Exercise:
    __slots__ = ("id", "topic", "topic_file", "level", "title", "task",
                 "hint", "concepts", "kind", "note", "sql", "line")

    def __init__(self, **kw):
        for s in self.__slots__:
            setattr(self, s, kw.get(s, ""))

    def __repr__(self):  # pragma: no cover
        return f"<{self.id} {self.title!r}>"


def parse_topic(path: pathlib.Path) -> list[Exercise]:
    out: list[Exercise] = []
    cur: Exercise | None = None
    body: list[str] = []
    last_field: str | None = None
    topic = path.stem

    def flush():
        if cur is not None:
            cur.sql = "\n".join(body).strip()
            out.append(cur)

    for lineno, line in enumerate(path.read_text().splitlines(), 1):
        m = BLOCK_RE.match(line)
        if m:
            flush()
            cur = Exercise(id=m.group("id").upper(), topic=topic,
                           topic_file=str(path.relative_to(ROOT)),
                           kind="select", line=lineno)
            body, last_field = [], None
            continue
        if cur is None:
            continue  # file preamble
        fm = FIELD_RE.match(line)
        if fm and not body:
            last_field = fm.group("k").lower()
            setattr(cur, last_field, fm.group("v").strip())
            continue
        if not body and line.startswith("--") and last_field:
            cont = line.lstrip("-").strip()
            if cont:
                setattr(cur, last_field, (getattr(cur, last_field) + " " + cont).strip())
            continue
        body.append(line)
    flush()

    for ex in out:
        if not ex.title or not ex.task or not ex.level:
            raise SystemExit(f"{path}:{ex.line}: block {ex.id} missing level/title/task")
        if not ex.sql:
            raise SystemExit(f"{path}:{ex.line}: block {ex.id} has no SQL body")
    return out


def load_all() -> list[Exercise]:
    SOL_DIR.mkdir(exist_ok=True)
    items: list[Exercise] = []
    for f in sorted(SOL_DIR.glob("*.sql")):
        items.extend(parse_topic(f))
    ids = [e.id for e in items]
    dupes = [i for i, n in collections.Counter(ids).items() if n > 1]
    if dupes:
        raise SystemExit(f"duplicate exercise ids: {sorted(dupes)}")
    return items


def find(ident: str) -> Exercise:
    items = load_all()
    key = ident.upper().replace("_", "-")
    for e in items:
        if e.id == key:
            return e
    digits = re.sub(r"\D", "", key)
    if len(digits) >= 4:
        want = f"T{digits[:2]}-{digits[2:]}"
        for e in items:
            if e.id == want:
                return e
    cand = [e for e in items if key in e.id]
    if len(cand) == 1:
        return cand[0]
    raise SystemExit(f"no exercise '{ident}'" + (f"; did you mean {[c.id for c in cand][:5]}?" if cand else ""))


# Nicer display names; fall back to a title-cased file name.
TOPIC_TITLES = {
    "01_basics_select_filter":     "Basics: SELECT, WHERE, NULL, ORDER BY",
    "02_joins":                    "Joins: inner, outer, anti, self, LATERAL",
    "03_aggregation":              "Aggregation: GROUP BY, HAVING, FILTER, percentiles",
    "04_subqueries_ctes":          "Subqueries & CTEs",
    "05_window_basics":            "Window functions I: ranking, offsets, frames",
    "06_window_advanced":          "Window functions II: gaps/islands, funnels, cohorts",
    "07_recursive_hierarchies":    "Recursive CTEs & hierarchies",
    "08_grouping_sets_pivot":      "GROUPING SETS, ROLLUP, CUBE, pivot",
    "09_jsonb":                    "JSONB",
    "10_arrays_ranges":            "Arrays, ranges & multiranges",
    "11_text_search":              "Text, regex & full-text search",
    "12_dates_time":               "Dates, time zones & time series",
    "13_set_operations":           "Set operations & reconciliation",
    "14_performance_explain":      "Performance: EXPLAIN, indexes, plans",
    "15_dml_transactions":         "DML, UPSERT, MERGE & transactions",
    "16_data_quality":             "Data quality & validation",
    "17_analytics_reports":        "Capstone analytics reports",
}


def topic_title(stem: str) -> str:
    if stem in TOPIC_TITLES:
        return TOPIC_TITLES[stem]
    _, _, rest = stem.partition("_")
    return rest.replace("_", " ").title()


# ----------------------------------------------------------------------- commands
def cmd_list(a):
    items = load_all()
    if a.topic:
        items = [e for e in items if a.topic.lower() in e.topic.lower()]
        for e in sorted(items, key=lambda x: x.id):
            print(f"{e.id:9} {BADGE[e.level].split()[1]:13} {e.title}")
        print(f"\n{len(items)} exercises")
        return
    by_topic = collections.OrderedDict()
    for e in items:
        by_topic.setdefault(e.topic, []).append(e)
    print(f"{'TOPIC':42} {'N':>3}  {'basic':>5} {'inter':>5} {'adv':>4} {'exp':>4}")
    for t, es in by_topic.items():
        c = collections.Counter(e.level for e in es)
        print(f"{topic_title(t):42} {len(es):>3}  "
              f"{c['basic']:>5} {c['intermediate']:>5} {c['advanced']:>4} {c['expert']:>4}")
    print(f"\n{len(items)} exercises in {len(by_topic)} topics")


def cmd_show(a):
    e = find(a.id)
    print(f"{e.id} — {e.title}   [{e.level}]")
    print(f"topic: {topic_title(e.topic)}")
    if e.concepts:
        print(f"concepts: {e.concepts}")
    print()
    print(e.task)
    if e.hint:
        print(f"\nhint: {e.hint}")
    if e.note:
        print(f"note: {e.note}")


def cmd_answer(a):
    print(find(a.id).sql)


def cmd_run(a):
    e = find(a.id)
    print(f"== {e.id} {e.title}  ({e.kind})")
    sql = e.sql if e.kind != "dml" else f"BEGIN;\n{e.sql}\nROLLBACK;"
    p = psql(sql, args=["-P", "pager=off", "-P", "border=2", "-c", r"\timing on"], check=False)
    sys.stdout.write(p.stdout)
    if p.returncode:
        sys.stderr.write(p.stderr)
        raise SystemExit(p.returncode)


def cmd_explain(a):
    e = find(a.id)
    if e.kind != "select":
        raise SystemExit(f"{e.id} is kind={e.kind}; explain only supports single SELECT blocks")
    body = e.sql.rstrip().rstrip(";")
    opts = "ANALYZE, BUFFERS, VERBOSE, SETTINGS" if not a.no_analyze else "VERBOSE, SETTINGS"
    p = psql(f"EXPLAIN ({opts}) {body};", args=["-P", "pager=off"], check=False)
    sys.stdout.write(p.stdout or p.stderr)
    raise SystemExit(p.returncode)


def _dump_csv(sql: str) -> subprocess.CompletedProcess:
    body = sql.rstrip().rstrip(";")
    copy = f"COPY ({body}) TO STDOUT WITH (FORMAT csv, HEADER true, NULL '<NULL>')"
    return psql(copy, args=["-qtA"], check=False)


def cmd_check(a):
    items = load_all()
    if a.topic:
        items = [e for e in items if a.topic.lower() in e.topic.lower()]
    passed = failed = 0
    slow, bad = [], []
    for e in items:
        t0 = time.time()
        if e.kind == "select":
            p = _dump_csv(e.sql)
        elif e.kind == "dml":
            p = psql(f"BEGIN;\n{e.sql}\nROLLBACK;", args=["-qtA"], check=False)
        else:
            p = psql(e.sql, args=["-qtA"], check=False)
        ms = int((time.time() - t0) * 1000)
        if p.returncode == 0:
            rows = max(0, p.stdout.count("\n") - 1) if e.kind == "select" else 0
            print(f"ok   {e.id:9} {e.kind:6} {ms:6} ms {rows:>8} rows  {e.title[:48]}")
            passed += 1
            if ms > 5000:
                slow.append(f"{e.id}={ms}ms")
        else:
            print(f"FAIL {e.id:9} {e.kind:6} {ms:6} ms  {e.title[:48]}")
            for ln in p.stderr.strip().splitlines()[:4]:
                print(f"       {ln}")
            failed += 1
            bad.append(e.id)
    print(f"\npassed: {passed}   failed: {failed}")
    if slow:
        print("slow (>5s): " + " ".join(slow))
    if bad:
        print("failing: " + " ".join(bad))
        raise SystemExit(1)


def cmd_diff(a):
    e = find(a.id)
    mine = pathlib.Path(a.file)
    if not mine.exists():
        raise SystemExit(f"no such file: {mine}")
    if e.kind != "select":
        raise SystemExit(f"{e.id} is kind={e.kind}; diff only supports SELECT exercises")

    my_sql = "\n".join(l for l in mine.read_text().splitlines()
                       if not l.strip().startswith("--")).strip()
    if not my_sql:
        raise SystemExit(f"{mine} contains no SQL")

    ref = _dump_csv(e.sql)
    if ref.returncode:
        sys.stderr.write("reference solution failed:\n" + ref.stderr)
        raise SystemExit(2)
    got = _dump_csv(my_sql)
    if got.returncode:
        print("YOUR query failed:")
        print(got.stderr.strip())
        raise SystemExit(1)

    ordered = re.search(r"\border\s+by\b", e.sql, re.I) is not None
    rl = ref.stdout.splitlines()
    gl = got.stdout.splitlines()
    rhead, ghead = (rl[0] if rl else ""), (gl[0] if gl else "")
    rbody, gbody = rl[1:], gl[1:]
    if not ordered:
        rbody, gbody = sorted(rbody), sorted(gbody)

    if rbody == gbody:
        print(f"PASS  {e.id}  ({len(gbody)} rows, order-"
              f"{'sensitive' if ordered else 'insensitive'})")
        if rhead != ghead:
            print(f"note: column names differ\n  ref: {rhead}\n  you: {ghead}")
        return

    print(f"FAIL  {e.id}  {e.title}")
    print(f"  rows   ref={len(rbody)}  you={len(gbody)}")
    print(f"  header ref={rhead}")
    print(f"         you={ghead}")
    missing = [r for r in rbody if r not in set(gbody)][:5]
    extra = [r for r in gbody if r not in set(rbody)][:5]
    if missing:
        print("  rows in reference but not yours:")
        for r in missing:
            print(f"    - {r[:160]}")
    if extra:
        print("  rows in yours but not reference:")
        for r in extra:
            print(f"    + {r[:160]}")
    raise SystemExit(1)


def cmd_new(a):
    e = find(a.id)
    WORK_DIR.mkdir(exist_ok=True)
    out = WORK_DIR / f"{e.id}.sql"
    if out.exists():
        print(f"{out.relative_to(ROOT)} already exists")
        return
    txt = [f"-- {e.id} [{e.level}] {e.title}", "--"]
    txt += [f"-- task: {e.task}"]
    if e.concepts:
        txt.append(f"-- concepts: {e.concepts}")
    txt += ["--", f"-- check with: make diff Q={e.id} F=work/{e.id}.sql", "", ""]
    out.write_text("\n".join(txt))
    print(f"created {out.relative_to(ROOT)}")


def cmd_gen(a):
    items = load_all()
    EX_DIR.mkdir(exist_ok=True)
    for old in EX_DIR.glob("*.md"):
        old.unlink()

    by_topic = collections.OrderedDict()
    for e in items:
        by_topic.setdefault(e.topic, []).append(e)

    rows = []
    for topic, es in by_topic.items():
        es = sorted(es, key=lambda x: (LEVELS.index(x.level), x.id))
        counts = collections.Counter(e.level for e in es)
        title = topic_title(topic)
        md = [f"# {topic.split('_')[0]}. {title}", ""]
        md.append(", ".join(f"**{counts[l]}** {l}" for l in LEVELS if counts[l])
                  + f" — {len(es)} exercises")
        md += ["",
               "```bash",
               f"make new Q={es[0].id}                 # scaffold work/{es[0].id}.sql",
               f"make diff Q={es[0].id} F=work/{es[0].id}.sql   # grade your answer",
               f"make run Q={es[0].id}                 # see the reference result",
               f"make explain Q={es[0].id}             # see the plan",
               "```",
               "", "---", ""]
        for e in es:
            md.append(f"### {e.id} — {e.title}")
            md.append("")
            meta = BADGE[e.level]
            if e.concepts:
                meta += f" · `{e.concepts}`"
            md += [meta, "", e.task, ""]
            if e.hint:
                md += [f"<details><summary>hint</summary>\n\n{e.hint}\n\n</details>", ""]
            if e.note:
                md += [f"> {e.note}", ""]
        (EX_DIR / f"{topic}.md").write_text("\n".join(md).rstrip() + "\n")
        rows.append((topic, title, len(es), counts))

    total = sum(r[2] for r in rows)
    idx = ["# Exercises", "",
           f"**{total} exercises, {len(rows)} topics.** Solutions: `solutions/<topic>.sql`.", "",
           "| # | Topic | N | 🟢 | 🟡 | 🟠 | 🔴 |",
           "|---|-------|---|----|----|----|----|"]
    for topic, title, n, c in rows:
        idx.append(f"| {topic.split('_')[0]} | [{title}](./{topic}.md) | {n} | "
                   f"{c['basic']} | {c['intermediate']} | {c['advanced']} | {c['expert']} |")
    idx += ["", f"Totals: 🟢 {sum(c['basic'] for *_, c in rows)} · "
                f"🟡 {sum(c['intermediate'] for *_, c in rows)} · "
                f"🟠 {sum(c['advanced'] for *_, c in rows)} · "
                f"🔴 {sum(c['expert'] for *_, c in rows)}",
            "", "_Generated by `scripts/qp.py gen` — do not edit._", ""]
    (EX_DIR / "README.md").write_text("\n".join(idx))
    print(f"generated {len(rows)} topic files, {total} exercises")


# -------------------------------------------------------------------------- main
def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="qp", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    p = sub.add_parser("list"); p.add_argument("topic", nargs="?"); p.set_defaults(fn=cmd_list)
    p = sub.add_parser("show"); p.add_argument("id"); p.set_defaults(fn=cmd_show)
    p = sub.add_parser("answer"); p.add_argument("id"); p.set_defaults(fn=cmd_answer)
    p = sub.add_parser("run"); p.add_argument("id"); p.set_defaults(fn=cmd_run)
    p = sub.add_parser("explain"); p.add_argument("id")
    p.add_argument("--no-analyze", action="store_true"); p.set_defaults(fn=cmd_explain)
    p = sub.add_parser("check"); p.add_argument("topic", nargs="?"); p.set_defaults(fn=cmd_check)
    p = sub.add_parser("diff"); p.add_argument("id"); p.add_argument("file"); p.set_defaults(fn=cmd_diff)
    p = sub.add_parser("new"); p.add_argument("id"); p.set_defaults(fn=cmd_new)
    p = sub.add_parser("gen"); p.set_defaults(fn=cmd_gen)

    a = ap.parse_args(argv)
    return a.fn(a) or 0


if __name__ == "__main__":
    sys.exit(main())
