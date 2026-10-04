// mcp-sh-roblox: a sandboxed bash shell over Roblox Studio, served over MCP.
// See `mcp-sh-roblox --help` and the README.
package main

import (
	"embed"

	"github.com/brohd11/mcp-sh"
)

// appFS is the built-in config layer. Directory embeds skip files starting with "_",
// so command libraries are listed explicitly.
//
//go:embed config.json commands commands/_lib.*
var appFS embed.FS

// version is set at build time via -ldflags "-X main.version=...". See the Makefile.
var version = "dev"

func main() {
	mcpsh.Main(mcpsh.Config{
		Name:       "mcp-sh-roblox",
		App:        "roblox",
		Version:    version,
		UpdateRepo: "brohd11/mcp-sh-roblox",
		FS:         appFS,
	})
}
