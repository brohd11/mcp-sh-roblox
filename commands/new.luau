-- summary: create an instance: new CLASS PARENT [NAME] [Prop=Value...]
-- usage: new CLASS PARENT [NAME] [Prop=Value...]
-- Prints the new instance's path, so it chains:
--   new Part Workspace Crate Size=4,1,4 Anchored=true | tag add Crate
-- Values convert like prop set. The parent is set last, after the properties.
-- One undo step.
local class, parentPath = ARGS[1], ARGS[2]
if not class or not parentPath then
	lib.fail("usage: new CLASS PARENT [NAME] [Prop=Value...]")
end
local parent = lib.resolve(parentPath)
local name
local props = {}
for i = 3, #ARGS do
	local k, v = string.match(ARGS[i], "^([%w_]+)=(.*)$")
	if k then
		table.insert(props, { k, v })
	elseif name == nil then
		name = ARGS[i]
	else
		lib.fail("unexpected argument " .. ARGS[i] .. " (properties are Name=Value)")
	end
end

local inst
lib.record("new " .. class, function()
	local ok, created = pcall(Instance.new, class)
	if not ok then
		lib.fail("cannot create " .. class .. ": " .. tostring(created))
	end
	inst = created
	if name then
		inst.Name = name
	end
	for _, kv in ipairs(props) do
		local value = lib.parse(kv[2], lib.get(inst, kv[1]), kv[1])
		local setOk, err = pcall(function()
			inst[kv[1]] = value
		end)
		if not setOk then
			lib.fail(kv[1] .. ": " .. tostring(err))
		end
	end
	lib.set(inst, "Parent", parent)
end)
print(lib.where(inst))
