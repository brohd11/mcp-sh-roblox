-- summary: Studio selection: sel | sel set [PATH...] | sel add [PATH...] | sel clear
-- usage: sel               paths of the selected instances
--        sel set PATH...   select exactly these (or paths on stdin)
--        sel add PATH...   add to the selection
--        sel clear
-- Lets an agent act on what the user selected, or show the user what it found:
--   query --where Anchored=false | sel set
local Selection = game:GetService("Selection")
local op = ARGS[1]

if op == nil then
	for _, inst in ipairs(Selection:Get()) do
		print(lib.where(inst))
	end
elseif op == "clear" then
	Selection:Set({})
elseif op == "set" or op == "add" then
	local targets = lib.targets(2)
	if op == "add" then
		local current = Selection:Get()
		for _, inst in ipairs(targets) do
			table.insert(current, inst)
		end
		targets = current
	end
	Selection:Set(targets)
	print(#targets .. " selected")
else
	lib.fail("usage: sel | sel set [PATH...] | sel add [PATH...] | sel clear")
end
