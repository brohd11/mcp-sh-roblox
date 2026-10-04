-- summary: delete instances: rm [PATH...] (or paths on stdin); one undo step
-- usage: rm PATH...      or: query --tag Temp | rm
-- Prints each deleted path. Refuses services and the DataModel itself.
-- Instances are unparented rather than destroyed, so Ctrl+Z in Studio restores them.
local targets = lib.targets(1)
lib.record("rm", function()
	for _, inst in ipairs(targets) do
		if inst == game or inst.Parent == game then
			lib.fail("refusing to delete " .. lib.where(inst) .. ": it is a service")
		end
		local path = lib.where(inst)
		lib.set(inst, "Parent", nil)
		print(path)
	end
end)
