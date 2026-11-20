# OTDeck: MQTT, Modbus and OPC UA client with an MCP server

Release files for [OTDeck](https://otdeck.com), a desktop workbench for
industrial protocols on Windows, macOS and Linux (amd64 and arm64):

- **MQTT client**: MQTT 5 and 3.1.1 over TCP, TLS, WebSocket; live topic
  tree, JSON/text/hex payloads, publish, **Sparkplug B** decoding.
- **Modbus TCP/RTU client (Modbus master)**: coils and registers, int16 to
  float64 and strings with byte and word order (ABCD, CDAB, BADC, DCBA),
  polling with backoff, writes 05/06/15/16 (Pro).
- **OPC UA client**: endpoint discovery, Basic256Sha256 Sign and
  SignAndEncrypt, address-space browser, monitored items, writes (Pro).
- **Trends** for all three protocols on one panel, recording, replay,
  CSV/Parquet export (Pro).
- **MCP server** `otdeck-mcp` with 10 read-only tools for Claude Desktop,
  Claude Code, Cursor, Codex, VS Code and other AI agents.
- **Built-in simulator**: MQTT broker, Modbus TCP PLC and OPC UA server on
  127.0.0.1.
- Production connections start read-only; offline licence activation for
  air-gapped networks.

## Download

https://otdeck.com/download (all files with SHA-256), or the
[latest release](https://github.com/otdeck/releases/releases/latest).

macOS with Homebrew: `brew install --cask aleksskoz/tap/otdeck`

Windows from Microsoft Store (installs without SmartScreen warnings, updates itself):

[![Get it from Microsoft](https://otdeck.com/badges/microsoft-store.svg)](https://apps.microsoft.com/detail/9PBR65914WKR)

Free forever with one open connection; Pro $99 once, Team $149 per seat a
year: https://otdeck.com/#pricing

The source code is not public. Questions and bug reports: support@otdeck.com
