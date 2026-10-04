-- summary: duplicate instances: clone [--to DEST] [--name NAME] [PATH...]
-- usage: clone [--to DEST] [--name NAME] PATH...     (or paths on stdin)
-- Each copy goes under DEST, or next to its original. Prints the copies' paths;
-- one undo step. Example: clone --to Workspace.Copies Workspace.Crate
local opts, rest = lib.options({ to = true, name = true })
ARGS = rest
local dest = opts.to and lib.resolve(opts.to)
local targets = lib.targets(1)
lib.record("clone", function()
	for _, inst in ipairs(targets) do
		local copy = inst:Clone()
		if copy == nil then
			lib.fail(lib.where(inst) .. " cannot be cloned (Archivable is false)")
		end
		if opts.name then
			copy.Name = opts.name
		end
		lib.set(copy, "Parent", dest or inst.Parent)
		print(lib.where(copy))
	end
end)
