# OTDeck: Modbus, OPC UA, MQTT and BACnet client with an MCP server

Release files for [OTDeck](https://otdeck.com), a desktop workbench for the
protocols of factories and buildings, on Windows, macOS and Linux (x64 and Arm64):

- **Modbus TCP/RTU client (Modbus master)**: TCP, RTU, RTU over TCP and UDP
  gateways; coils and registers with register maps, int16 to float64 and
  strings with byte and word order (ABCD, CDAB, BADC, DCBA), writes (Pro).
- **OPC UA client**: endpoint discovery, security policies and certificate
  trust, address-space browser, monitored items, history, methods, writes (Pro).
- **MQTT client**: MQTT 5 and 3.1.1 over TCP, TLS and WebSocket; live topic
  tree, retained messages, publish, **Sparkplug B** decoding.
- **BACnet/IP and BACnet/SC client**: device discovery, objects, priority
  arrays, commanding with relinquish, alarms and event notifications with
  delivery diagnostics, EDE export.
- **Commissioning**: a point checkout sheet walks an IO list point by point,
  with alarm tests and a commissioning report (Pro).
- **Trends, watch rules and snapshots**: live trends for all protocols,
  warnings when a value leaves its range, compare a device with yesterday.
- **MCP server** `otdeck-mcp` with 17 tools for Claude Desktop, Claude Code,
  Cursor, Codex, VS Code and other AI agents. Agents never see your
  passwords; every write they ask for waits for your Allow in OTDeck (Pro).
- **Built-in simulator**: MQTT broker, Modbus TCP PLC, OPC UA server and
  BACnet device on 127.0.0.1.
- Production connections start read-only; works offline with no account and
  no analytics; offline licence activation for air-gapped networks.

## Download

https://otdeck.com/download (all files with SHA-256), or the
[latest release](https://github.com/otdeck/releases/releases/latest).

macOS with Homebrew: `brew install --cask aleksskoz/tap/otdeck`

Windows from Microsoft Store (installs without SmartScreen warnings, updates itself):

[![Get it from Microsoft](https://otdeck.com/badges/microsoft-store.svg)](https://apps.microsoft.com/detail/9PBR65914WKR)

MCP server in the [MCP Registry](https://registry.modelcontextprotocol.io) as
`com.otdeck/otdeck-mcp`.

Free forever with one open connection; Pro $99 once, Team $149 per seat a
year: https://otdeck.com/#pricing

The source code is not public. Questions and bug reports: support@otdeck.com
