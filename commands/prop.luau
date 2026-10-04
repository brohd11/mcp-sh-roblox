-- summary: get or set properties: prop get NAME [PATH...] | prop set NAME VALUE [PATH...]
-- usage: prop get NAME [PATH...]          JSON lines {"path", "value"}
--        prop set NAME VALUE [PATH...]    prints each changed path; one undo step
-- PATHs come from arguments or stdin (plain paths, or JSON lines with a path field):
--   query --class Part | prop set Anchored true
-- VALUE converts to the property's type: true/false, numbers, "x, y, z" (Vector3;
-- CFrame position, rotation kept), "r, g, b" (0-1 or 0-255) or #hex (Color3), enum
-- names (Plastic or Enum.Material.Plastic), dotted paths for Instance properties, nil.
local op, name = ARGS[1], ARGS[2]
if op ~= "get" and op ~= "set" then
	lib.fail("usage: prop get NAME [PATH...] | prop set NAME VALUE [PATH...]")
end
if not name then
	lib.fail("missing property NAME")
end

if op == "get" then
	for _, inst in ipairs(lib.targets(3)) do
		lib.emit({ path = lib.where(inst), value = lib.plain(lib.get(inst, name)) })
	end
	return
end

local text = ARGS[3] or lib.fail("missing VALUE")
local targets = lib.targets(4)
-- Convert for every target first, so a bad value or a missing property fails
-- before anything changes; lib.record reverts the rare failure while setting.
local values = {}
for i, inst in ipairs(targets) do
	values[i] = lib.parse(text, lib.get(inst, name), name)
end
lib.record("prop set " .. name, function()
	for i, inst in ipairs(targets) do
		lib.set(inst, name, values[i])
		print(lib.where(inst))
	end
end)
