package main

import (
	"io/fs"
	"strings"
	"testing"

	"github.com/brohd11/mcp-sh/profile"
)

func load(t *testing.T) *profile.Loaded {
	t.Helper()
	l, err := profile.Load(profile.App{Name: "roblox", FS: appFS}, profile.Options{ConfigDir: t.TempDir(), ProjectDir: t.TempDir()})
	if err != nil {
		t.Fatal(err)
	}
	return l
}

func TestConfigLoads(t *testing.T) {
	l := load(t)
	if l.Profile.Title == "" || l.Profile.Setup == "" {
		t.Error("missing title or setup")
	}
	if _, err := l.Sources("test"); err != nil {
		t.Errorf("sources: %v", err)
	}
}

func TestEmbeddedLibrary(t *testing.T) {
	b, err := fs.ReadFile(load(t).CommandDirs[0].FS, "_lib.luau")
	if err != nil || !strings.Contains(string(b), "function lib.resolve") {
		t.Fatalf("_lib.luau not embedded: %v", err)
	}
}
