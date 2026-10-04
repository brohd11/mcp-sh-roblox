-- summary: move instances under a new parent: mv PATH... DEST (or paths on stdin: mv DEST)
-- usage: mv PATH... DEST      or: query --class Part | mv Workspace.Parts
-- Prints each new path; one undo step. To rename, use: prop set Name NEWNAME PATH
if #ARGS == 0 then
	lib.fail("usage: mv PATH... DEST | ... | mv DEST")
end
local dest = lib.resolve(ARGS[#ARGS])
local targets = lib.targets(1, #ARGS - 1)
lib.record("mv", function()
	for _, inst in ipairs(targets) do
		lib.set(inst, "Parent", dest)
		print(lib.where(inst))
	end
end)
