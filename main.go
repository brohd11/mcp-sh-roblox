// roblox-shell: a sandboxed bash shell over Roblox Studio, served over MCP.
// See `roblox-shell --help` and the README.
package main

import (
	"embed"

	"github.com/brohd11/agent-shell"
)

// appFS is the built-in config layer. Directory embeds skip files starting with "_",
// so command libraries are listed explicitly.
//
//go:embed config.json commands commands/_lib.*
var appFS embed.FS

// version is set at build time via -ldflags "-X main.version=...". See the Makefile.
var version = "dev"

func main() {
	agentshell.Main(agentshell.Config{
		Name:       "roblox-shell",
		App:        "roblox",
		Version:    version,
		UpdateRepo: "brohd11/roblox-shell",
		FS:         appFS,
	})
}
