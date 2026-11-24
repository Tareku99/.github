"""Write the same Actions summary for each caller."""
import html
import json
import os
import re
import xml.etree.ElementTree as ET
from pathlib import Path


RESULTS = {
    "success": "Passed",
    "failure": "Failed",
    "cancelled": "Cancelled",
    "skipped": "Skipped",
    "": "Did not run",
}


def cell(value):
    """Render caller values as text inside a Markdown table cell."""
    return (
        html.escape(" ".join(value.split()))
        .replace("|", "&#124;")
        .replace("`", "&#96;")
        .replace("[", "&#91;")
        .replace("]", "&#93;")
    )


def junit_rows(path):
    try:
        root = ET.parse(path).getroot()
        suites = [root] if root.tag == "testsuite" else root.findall("testsuite")
        if not suites:
            raise ValueError("Missing test suite")
        total, failed, errors, skipped = (
            sum(int(suite.get(key, "0")) for suite in suites)
            for key in ("tests", "failures", "errors", "skipped")
        )
    except (OSError, ET.ParseError, ValueError):
        return [("JUnit report", "Unavailable")]
    return [
        ("Tests", str(total)),
        ("Passed", str(total - failed - errors - skipped)),
        ("Failures", str(failed)),
        ("Errors", str(errors)),
        ("Skipped", str(skipped)),
    ]


def main():
    env = os.environ
    jobs = json.loads(env["SUMMARY_JOBS"]) if env["SUMMARY_JOBS"] else None
    sha = env["SUMMARY_SHA"]
    rows = [
        ("Event", cell(env["GITHUB_EVENT_NAME"])),
        ("Source ref", cell(env["SUMMARY_REF"] or env.get("GITHUB_HEAD_REF") or env["GITHUB_REF_NAME"])),
    ]
    if re.fullmatch(r"[0-9a-f]{40}", sha):
        url = f"{env['GITHUB_SERVER_URL']}/{env['GITHUB_REPOSITORY']}/commit/{sha}"
        rows.append(("Source commit", f"[`{sha[:12]}`]({url})"))
    if jobs is None:
        title = "Test results"
        rows.append(("Test outcome", RESULTS.get(env["SUMMARY_TEST"], "Unknown")))
        if env["SUMMARY_JUNIT"]:
            rows.extend(junit_rows(env["SUMMARY_JUNIT"]))
    else:
        title = "Workflow report"
        rows.append(("Channel", cell(env["SUMMARY_CHANNEL"])))
        for name, job in jobs.items():
            rows.append((cell(name.capitalize()), RESULTS.get(job.get("result", ""), "Unknown")))
        publish = jobs.get("publish", {})
        if publish.get("result") == "success":
            outputs = publish.get("outputs", {})
            rows.extend([
                ("Image", cell(env["SUMMARY_IMAGE"])),
                ("Tags", cell(", ".join(outputs.get("tags", "").splitlines()))),
                ("Digest", cell(outputs.get("digest", ""))),
            ])
    with Path(env["GITHUB_STEP_SUMMARY"]).open("a", encoding="utf-8") as output:
        output.write(f"## {title}\n\n| Item | Result |\n| --- | --- |\n")
        for label, value in rows:
            output.write(f"| {label} | {value} |\n")


if __name__ == "__main__":
    main()
