-- summary: attributes: attr ls | get NAME | set NAME VALUE [--type T] | rm NAME, on [PATH...]
-- usage: attr ls [PATH...]                       JSON lines {"path", "attributes"}
--        attr get NAME [PATH...]                 JSON lines {"path", "value"}
--        attr set NAME VALUE [--type T] [PATH...]  prints each path; one undo step
--        attr rm NAME [PATH...]                  prints each path; one undo step
-- set converts VALUE to the attribute's existing type, or to --type (string, number,
-- boolean, Vector3, Vector2, Color3, UDim2, UDim, NumberRange, CFrame, BrickColor);
-- a new attribute without --type is true/false, a number, or else a string.
local opts, rest = lib.options({ type = true })
ARGS = rest
local op, name = ARGS[1], ARGS[2]

if op == "ls" then
	for _, inst in ipairs(lib.targets(2)) do
		local attrs = {}
		for k, v in pairs(inst:GetAttributes()) do
			attrs[k] = lib.plain(v)
		end
		lib.emit({ path = lib.where(inst), attributes = attrs })
	end
	return
end
if op ~= "get" and op ~= "set" and op ~= "rm" then
	lib.fail("usage: attr ls [PATH...] | attr get NAME [PATH...] | attr set NAME VALUE [--type T] [PATH...] | attr rm NAME [PATH...]")
end
if not name then
	lib.fail("missing attribute NAME")
end

if op == "get" then
	for _, inst in ipairs(lib.targets(3)) do
		lib.emit({ path = lib.where(inst), value = lib.plain(inst:GetAttribute(name)) })
	end
	return
end

local text
local first = 3
if op == "set" then
	text = ARGS[3] or lib.fail("missing VALUE")
	first = 4
end
local targets = lib.targets(first)
lib.record("attr " .. op .. " " .. name, function()
	for _, inst in ipairs(targets) do
		if op == "set" then
			lib.setAttr(inst, name, lib.attrValue(text, inst:GetAttribute(name), opts.type))
		else
			lib.setAttr(inst, name, nil)
		end
		print(lib.where(inst))
	end
end)
