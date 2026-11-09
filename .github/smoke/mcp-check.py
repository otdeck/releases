"""Talks MCP over stdio to otdeck-mcp: initialize, then tools/list.

Usage: python mcp-check.py <path to otdeck-mcp> <empty app dir> [tool count]
Exits non-zero unless the server answers both, with exactly <tool count>
tools when given. No licence in the app dir: the Free plan must answer.
"""
import json
import subprocess
import sys
import time

exe, appdir = sys.argv[1], sys.argv[2]
want = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3] else 0
msgs = [
    {"jsonrpc": "2.0", "id": 1, "method": "initialize",
     "params": {"protocolVersion": "2025-06-18", "capabilities": {},
                "clientInfo": {"name": "install-smoke", "version": "1"}}},
    {"jsonrpc": "2.0", "method": "notifications/initialized"},
    {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
]
p = subprocess.Popen([exe, "-dir", appdir], stdin=subprocess.PIPE,
                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                     text=True, encoding="utf-8")
for m in msgs:
    p.stdin.write(json.dumps(m) + "\n")
    p.stdin.flush()
time.sleep(5)  # the server stops at EOF; give it time to answer first
try:  # communicate() closes stdin, the server then exits
    out, err = p.communicate(timeout=20)
except subprocess.TimeoutExpired:
    p.kill()
    out, err = p.communicate()
print("stderr:", err.strip()[:2000])
replies = {}
for line in out.splitlines():
    try:
        d = json.loads(line)
    except ValueError:
        continue
    if "id" in d:
        replies[d["id"]] = d
info = replies.get(1, {}).get("result", {}).get("serverInfo")
tools = [t["name"] for t in replies.get(2, {}).get("result", {}).get("tools", [])]
print("serverInfo:", info)
print("tools:", len(tools), ", ".join(tools))
if not info or not tools:
    sys.exit("otdeck-mcp did not answer initialize and tools/list")
if want and len(tools) != want:
    sys.exit(f"otdeck-mcp lists {len(tools)} tools, expected {want}")
