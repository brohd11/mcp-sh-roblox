-- summary: find instances by class, name, tag and property values, as JSON lines
-- usage: query [ROOT] [--class C] [--name PATTERN] [--tag T] [--where EXPR]... [--max N]
-- ROOT defaults to Workspace; "game" searches everything. --class uses IsA, so
-- BasePart matches Parts and MeshParts. --name is a Lua pattern. --where compares a
-- property: Name=Value, Name!=Value, and <, >, <=, >= for numbers; Value converts like
-- prop set. All filters must match. Unlike search_game_tree, results are not capped.
-- Output: {"path", "class", "name"} per match, e.g.
--   query --class BasePart --where Anchored=false | prop set Anchored true
local opts, rest = lib.options({ class = true, name = true, tag = true, where = "list", max = true })
local root = lib.resolve(rest[1] or "Workspace")
if rest[2] then
	lib.fail("unexpected argument " .. rest[2])
end
local max = opts.max and (tonumber(opts.max) or lib.fail("--max needs a number"))

local conds = {}
for _, expr in ipairs(opts.where or {}) do
	local prop, op, value = string.match(expr, "^([%w_]+)%s*([!<>=]=?)%s*(.*)$")
	if not prop then
		lib.fail("bad --where " .. expr .. " (use Name=Value, Name!=Value, Name>Value, ...)")
	end
	table.insert(conds, { prop = prop, op = op, text = value })
end

local function matches(inst)
	if opts.class and not inst:IsA(opts.class) then
		return false
	end
	if opts.name and not string.find(inst.Name, opts.name) then
		return false
	end
	if opts.tag and not inst:HasTag(opts.tag) then
		return false
	end
	for _, c in ipairs(conds) do
		local ok, current = pcall(function()
			return inst[c.prop]
		end)
		if not ok then
			return false
		end
		local ordered = c.op ~= "=" and c.op ~= "==" and c.op ~= "!="
		if ordered and type(current) ~= "number" then
			lib.fail("--where " .. c.prop .. c.op .. c.text .. ": " .. c.op .. " only compares numbers, and " .. c.prop .. " is a " .. typeof(current))
		end
		local want = lib.parse(c.text, current, c.prop)
		if c.op == "=" or c.op == "==" then
			if current ~= want then
				return false
			end
		elseif c.op == "!=" then
			if current == want then
				return false
			end
		else
			if (c.op == "<" and not (current < want))
				or (c.op == ">" and not (current > want))
				or (c.op == "<=" and not (current <= want))
				or (c.op == ">=" and not (current >= want)) then
				return false
			end
		end
	end
	return true
end

local count = 0
for _, inst in ipairs(root:GetDescendants()) do
	if matches(inst) then
		lib.emit({ path = lib.where(inst), class = inst.ClassName, name = inst.Name })
		count += 1
		if max and count >= max then
			break
		end
	end
end
