# roblox-shell

A sandboxed bash shell over Roblox Studio, served over MCP. Built on
[agent-shell](https://github.com/brohd11/agent-shell): it starts Studio's built-in MCP
server (the `StudioMCP` binary in the app, stdio) and adds Luau editing commands.

```sh
roblox-shell run 'query --class BasePart --where Anchored=false | prop set Anchored true'
roblox-shell run 'studio list_roblox_studios'
```

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/brohd11/roblox-shell/main/install.sh | sh
roblox-shell setup        # ~/.agent-shell/roblox/ + `claude mcp add -s user roblox-shell -- <path>`
roblox-shell commands     # check what the shell can reach
```

On Windows: `irm https://raw.githubusercontent.com/brohd11/roblox-shell/main/install.ps1 | iex`.

Keep Roblox Studio open with a place loaded and its built-in MCP server enabled.

## Commands

`studio <tool>` calls Studio's own tools (`help studio`, `studio <tool> --help`).
`studio_id` is filled automatically when exactly one Studio is open, and
`datamodel_type` defaults to `Edit`.

The script commands fill gaps in Studio's own tools, which are strong at reading and
weak at structured edits:

| Command | Does |
|---|---|
| `query [ROOT] --class --name --tag --where Prop=Value…` | find instances, as JSON lines; no 200-result cap |
| `prop get/set NAME [VALUE]` | read or write properties; text converts to the property's type (Vector3, Color3 `#hex`, enums, CFrame position, Instance paths) |
| `new`, `rm`, `mv`, `clone` | create, delete, reparent, duplicate |
| `tag ls/add/rm/find`, `attr ls/get/set/rm` | CollectionService tags, attributes |
| `sel`, `sel set/add/clear` | read or set Studio's selection |
| `scripts [ROOT]` | every script with class, line count, Enabled, RunContext |
| `instances [PATH] [DEPTH]` | children as JSON lines |

Edit commands take paths as arguments, or one per stdin line (JSON lines with a `path`
field work too), and print the paths they changed, so they chain:
`query --class BasePart --where Anchored=false | prop set Anchored true`. Each call is one
undo step in Studio, since `execute_luau` records it. If any target fails, the command
reverts its own changes first: values are converted before anything changes, and a
journal undoes changes made before a later failure.

roblox-shell was verified against Studio 0.741 on macOS. It reads its 28 tools,
fills `studio_id` and `datamodel_type` automatically, and runs `execute_luau` script
commands. On Windows, point it at `StudioMCP.exe`:
`roblox-shell mcp add studio -- "C:\path\to\StudioMCP.exe"`. The script binding
and defaults are kept.

## Your own commands

Keep your own Luau commands in a folder of their own, such as a git repo, and add it:

```sh
roblox-shell commands add ~/code/roblox-tools
```

A `_lib.luau` in that folder is appended to the built-in one, so your scripts can use and
extend `lib`. A script with a built-in's name replaces it, and the listing says so.
Quick one-offs can also go straight into `~/.agent-shell/roblox/commands/`. See the
agent-shell README for the script format and folder order.

## Development

```sh
make           # host build -> build/<os>-<arch>/roblox-shell
make test
make package   # release archives for every platform
```

The makefile body, installers, workflows and `cliff.toml` are rendered from
[sh-templates](https://github.com/brohd11/sh-templates) by the workspace's `render-go.sh`.
Only the config blocks above `# ---- end config ----` are edited here. Pushing a `v*` tag
releases.
