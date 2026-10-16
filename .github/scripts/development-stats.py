"""Discord statistics from committed Git objects only; never sends or changes anything."""
import argparse
import fnmatch
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE).stdout


def section(text, heading):
    lines = []
    found = False
    for line in text.decode("utf-8-sig").splitlines():
        if line == heading:
            found = True
        elif found and line.startswith("## "):
            break
        elif found and line.strip():
            lines.append(line)
    return lines


def archives(commit):
    """First-parent commits that actually archived Latest, not just matching subjects."""
    for line in git("log", "--first-parent", "--format=%H%x09%s", commit).decode().splitlines():
        sha, _, subject = line.partition("\t")
        match = re.fullmatch(r"Update changelog for (v\S+) \[skip ci\]", subject)
        if not match:
            continue
        try:
            parent = git("rev-parse", "--verify", sha + "^1").decode().strip()
            before = git("show", parent + ":CHANGELOG.md")
            after = git("show", sha + ":CHANGELOG.md")
            latest = section(before, "## Latest")
            if latest and not section(after, "## Latest") and latest == section(after, "## " + match[1]):
                yield sha, parent, match[1]
        except (subprocess.CalledProcessError, UnicodeError):
            continue


def update_range(commit, event, version):
    history = iter(archives(commit))
    if event == "workflow_dispatch":
        for archive, original, archived_version in history:
            if archived_version == version:
                return original, next(archives(original), (None,))[0], True
        return None, None, True
    return commit, next(history, (None,))[0], False


def change_counts(baseline, commit):
    if baseline:
        data = git("diff", "--no-ext-diff", "--no-textconv", "--find-renames", "--numstat", "-z", baseline, commit, "--")
    elif len(git("rev-list", "--parents", "-n", "1", commit).split()) == 1:
        data = git("diff-tree", "--root", "--no-commit-id", "--no-ext-diff", "--no-textconv", "-r", "--find-renames", "--numstat", "-z", commit, "--")
    else:
        return None
    chunks = iter(data.split(b"\0"))
    files = added = removed = 0
    for record in chunks:
        if not record:
            continue
        plus, minus, path = record.split(b"\t", 2)
        if not path:  # -z encodes rename paths in two additional NUL records.
            next(chunks)
            next(chunks)
        files += 1
        if plus != b"-":
            added += int(plus)
            removed += int(minus)
    return files, added, removed


def included(path, rules):
    path = path.lower()
    parts = PurePosixPath(path)
    return (parts.suffix in rules["extensions"]
            and not set(parts.parts).intersection(rules["exclude_path_parts"])
            and not any(fnmatch.fnmatchcase(path, pattern) or
                        (pattern.startswith("**/") and fnmatch.fnmatchcase(path, pattern[3:]))
                        for pattern in rules["exclude_globs"]))


def source_counts(commit, rules):
    blobs = []
    for record in git("ls-tree", "-r", "-z", commit).split(b"\0"):
        if not record:
            continue
        metadata, path = record.split(b"\t", 1)
        mode, kind, oid = metadata.split()
        if mode in (b"100644", b"100755") and kind == b"blob" and included(path.decode("utf-8", "surrogateescape"), rules):
            blobs.append(oid)
    if not blobs:
        return 0, 0
    data = subprocess.run(["git", "cat-file", "--batch"], cwd=ROOT, check=True,
                          input=b"\n".join(blobs) + b"\n", stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
    offset = files = lines = 0
    for _ in blobs:
        end = data.index(b"\n", offset)
        _, kind, size = data[offset:end].split()
        assert kind == b"blob"
        start = end + 1
        content = data[start:start + int(size)]
        offset = start + int(size) + 1
        if b"\0" not in content:
            files += 1
            lines += len(content.splitlines())
    return files, lines


def statistics(commit, event, version, rules):
    commit = git("rev-parse", "--verify", "--end-of-options", commit + "^{commit}").decode().strip()
    snapshot, baseline, repost = update_range(commit, event, version)
    if not snapshot:
        return "Statistics unavailable: no original archive commit was found for this repost."
    result = ["**Changes in this update**"]
    try:
        changes = change_counts(baseline, snapshot)
        if changes:
            files, added, removed = changes
            result += [f"📁 Files changed: **{files:,}**", f"🟢 Lines added: **+{added:,}**", f"🔴 Lines removed: **−{removed:,}**"]
        else:
            result.append("Change totals unavailable: previous update baseline not found.")
    except (subprocess.CalledProcessError, ValueError, StopIteration):
        result.append("Change totals unavailable for this update.")
    result += ["", "**Project size at original update**" if repost else "**Current project size**"]
    try:
        files, lines = source_counts(snapshot, rules)
        result += [f"💻 Source files: **{files:,}**", f"📝 Total source lines: **{lines:,}**"]
    except (subprocess.CalledProcessError, ValueError, AssertionError):
        result.append("Source totals unavailable for this snapshot.")
    return "\n".join(result)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--commit", default="HEAD")
    parser.add_argument("--event", default="push")
    parser.add_argument("--version", default="")
    args = parser.parse_args()
    try:
        rules = json.loads((ROOT / ".github/source-stats.json").read_text(encoding="utf-8"))
        value = statistics(args.commit, args.event, args.version, rules)
    except (OSError, subprocess.CalledProcessError, ValueError, UnicodeError):
        print("Development statistics unavailable; announcement will continue.", file=sys.stderr)
        value = "Statistics unavailable for this update."
    # One compact field, separate from the unchanged changelog description.
    print(json.dumps({"name": "📊 Development Statistics", "value": value[:1024], "inline": False}))


if __name__ == "__main__":
    main()
