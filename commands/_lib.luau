-- Shared helpers for roblox-shell's script commands, available to every
-- command as `lib`. A user commands/_lib.luau is appended after this one and can add
-- or replace helpers.
local HttpService = game:GetService("HttpService")

-- Fail with a plain message (no Luau location prefix).
function lib.fail(msg)
	error(msg, 0)
end

local function where(inst)
	return inst == game and "game" or inst:GetFullName()
end
lib.where = where

-- Resolve a dotted path ("Workspace.Model.Part"; a "game." prefix is optional).
function lib.resolve(path)
	path = string.match(path, "^%s*(.-)%s*$")
	if path == "" or path == "game" then
		return game
	end
	local cur = game
	local first = true
	for seg in string.gmatch(path, "[^%.]+") do
		if not (first and seg == "game") then
			local nxt = cur:FindFirstChild(seg)
			if nxt == nil and cur == game then
				local ok, svc = pcall(function()
					return game:GetService(seg)
				end)
				if ok then
					nxt = svc
				end
			end
			if nxt == nil then
				lib.fail("not found: " .. path .. " (no '" .. seg .. "' in " .. where(cur) .. ")")
			end
			cur = nxt
		end
		first = false
	end
	return cur
end

-- Instances named by ARGS[first..last], or by STDIN lines when that range is empty.
-- STDIN lines are plain paths, or JSON objects with a "path" or "fullPath" field.
function lib.targets(first, last, allowEmpty)
	last = last or #ARGS
	local paths = {}
	for i = first, last do
		table.insert(paths, ARGS[i])
	end
	if #paths == 0 then
		for line in string.gmatch(STDIN, "[^\n]+") do
			line = string.match(line, "^%s*(.-)%s*$")
			if line ~= "" then
				if string.sub(line, 1, 1) == "{" then
					local ok, obj = pcall(function()
						return HttpService:JSONDecode(line)
					end)
					if not ok or type(obj) ~= "table" then
						lib.fail("stdin: not a JSON object: " .. line)
					end
					line = obj.path or obj.fullPath or lib.fail("stdin: JSON line has no path field: " .. line)
				end
				table.insert(paths, line)
			end
		end
	end
	if #paths == 0 and not allowEmpty then
		lib.fail("no targets: pass paths as arguments, or one per stdin line")
	end
	local out = {}
	for _, p in ipairs(paths) do
		table.insert(out, lib.resolve(p))
	end
	return out
end

-- Read a property, failing with a clear message when the instance has none.
function lib.get(inst, name)
	local ok, v = pcall(function()
		return inst[name]
	end)
	if not ok then
		lib.fail(where(inst) .. " (" .. inst.ClassName .. ") has no property " .. name)
	end
	return v
end

local function numbers(text, n, typeName)
	local out = {}
	for part in string.gmatch(text, "[^,%s{}%(%)]+") do
		local v = tonumber(part)
		if v == nil then
			lib.fail(string.format("%q is not a %s", text, typeName))
		end
		table.insert(out, v)
	end
	if n and #out ~= n then
		lib.fail(string.format("%q is not a %s (want %d numbers)", text, typeName, n))
	end
	return out
end

-- Convert text to the type of `current`, the property's current value.
function lib.parse(text, current, what)
	local t = typeof(current)
	what = what or "value"
	if t == "string" then
		return text
	elseif t == "boolean" then
		if text == "true" then
			return true
		elseif text == "false" then
			return false
		end
		lib.fail(what .. ": expected true or false, got " .. text)
	elseif t == "number" then
		return tonumber(text) or lib.fail(what .. ": expected a number, got " .. text)
	elseif t == "EnumItem" then
		local name = string.match(text, "([%w_]+)$") or text
		local ok, item = pcall(function()
			return current.EnumType[name]
		end)
		if ok and item then
			return item
		end
		local names = {}
		for _, it in ipairs(current.EnumType:GetEnumItems()) do
			table.insert(names, it.Name)
		end
		lib.fail(what .. ": " .. text .. " is not a " .. tostring(current.EnumType) .. " (" .. table.concat(names, ", ") .. ")")
	elseif t == "Instance" or t == "nil" then
		if text == "nil" or text == "" then
			return nil
		end
		return lib.resolve(text)
	end
	local stripped = string.gsub(text, "^[%a%.]+%(", "(")
	if t == "Vector3" then
		local n = numbers(stripped, 3, "Vector3")
		return Vector3.new(n[1], n[2], n[3])
	elseif t == "Vector2" then
		local n = numbers(stripped, 2, "Vector2")
		return Vector2.new(n[1], n[2])
	elseif t == "Color3" then
		if string.sub(text, 1, 1) == "#" then
			return Color3.fromHex(text)
		end
		local n = numbers(stripped, 3, "Color3")
		if n[1] > 1 or n[2] > 1 or n[3] > 1 then
			return Color3.fromRGB(n[1], n[2], n[3])
		end
		return Color3.new(n[1], n[2], n[3])
	elseif t == "BrickColor" then
		return BrickColor.new(text)
	elseif t == "UDim2" then
		local n = numbers(stripped, 4, "UDim2")
		return UDim2.new(n[1], n[2], n[3], n[4])
	elseif t == "UDim" then
		local n = numbers(stripped, 2, "UDim")
		return UDim.new(n[1], n[2])
	elseif t == "NumberRange" then
		local n = numbers(stripped, nil, "NumberRange")
		return NumberRange.new(n[1], n[2] or n[1])
	elseif t == "CFrame" then
		local n = numbers(stripped, nil, "CFrame")
		if #n == 3 then
			return CFrame.new(n[1], n[2], n[3]) * current.Rotation
		elseif #n == 12 then
			return CFrame.new(table.unpack(n))
		end
		lib.fail(what .. ": a CFrame takes 3 numbers (position; rotation is kept) or 12")
	end
	lib.fail(what .. ": cannot set a " .. t .. " from text")
end

local samples = {
	string = "",
	number = 0,
	boolean = false,
	Vector3 = Vector3.zero,
	Vector2 = Vector2.zero,
	Color3 = Color3.new(),
	UDim2 = UDim2.new(),
	UDim = UDim.new(),
	NumberRange = NumberRange.new(0),
	CFrame = CFrame.new(),
	BrickColor = BrickColor.new("White"),
}

-- Value for an attribute: converted to typeName, else to the existing attribute's
-- type, else inferred (true/false, number, otherwise string).
function lib.attrValue(text, existing, typeName)
	if typeName then
		local sample = samples[typeName]
		if sample == nil then
			local names = {}
			for k in pairs(samples) do
				table.insert(names, k)
			end
			table.sort(names)
			lib.fail("unknown attribute type " .. typeName .. " (" .. table.concat(names, ", ") .. ")")
		end
		return lib.parse(text, sample, "value")
	end
	if existing ~= nil then
		return lib.parse(text, existing, "value")
	end
	if text == "true" then
		return true
	elseif text == "false" then
		return false
	end
	return tonumber(text) or text
end

-- A JSON-friendly form of a value.
function lib.plain(v)
	local t = typeof(v)
	if v == nil or t == "string" or t == "number" or t == "boolean" then
		return v
	elseif t == "Instance" then
		return where(v)
	end
	return tostring(v)
end

-- Print one JSON object per line.
function lib.emit(obj)
	print(HttpService:JSONEncode(obj))
end

-- Changes made through lib.set/setAttr/addTag/removeTag inside lib.record are
-- journaled. Studio's execute_luau already makes each call one undo step (it runs
-- inside its own ChangeHistoryService recording, so a nested one cannot be started);
-- the journal makes a failing command all-or-nothing on top of that.
local journal = nil

local function remember(undo)
	if journal then
		table.insert(journal, undo)
	end
end

-- Run fn; if it fails, undo every journaled change it made, newest first.
function lib.record(name, fn)
	journal = {}
	local ok, err = pcall(fn)
	local log = journal
	journal = nil
	if not ok then
		for i = #log, 1, -1 do
			pcall(log[i])
		end
		error(err, 0)
	end
end

-- Set a property, journaling the old value.
function lib.set(inst, prop, value)
	local old = lib.get(inst, prop)
	local ok, err = pcall(function()
		inst[prop] = value
	end)
	if not ok then
		lib.fail(where(inst) .. "." .. prop .. ": " .. tostring(err))
	end
	remember(function()
		inst[prop] = old
	end)
end

function lib.setAttr(inst, name, value)
	local old = inst:GetAttribute(name)
	inst:SetAttribute(name, value)
	remember(function()
		inst:SetAttribute(name, old)
	end)
end

function lib.addTag(inst, tag)
	if not inst:HasTag(tag) then
		inst:AddTag(tag)
		remember(function()
			inst:RemoveTag(tag)
		end)
	end
end

function lib.removeTag(inst, tag)
	if inst:HasTag(tag) then
		inst:RemoveTag(tag)
		remember(function()
			inst:AddTag(tag)
		end)
	end
end

-- Split "--flag value" options out of ARGS. Returns the options and the remaining
-- arguments; names lists the options that take a value.
function lib.options(names)
	local opts, rest = {}, {}
	local i = 1
	while i <= #ARGS do
		local a = ARGS[i]
		local name = string.match(a, "^%-%-([%w_-]+)$")
		if name and names[name] then
			if ARGS[i + 1] == nil then
				lib.fail("--" .. name .. " needs a value")
			end
			if names[name] == "list" then
				opts[name] = opts[name] or {}
				table.insert(opts[name], ARGS[i + 1])
			else
				opts[name] = ARGS[i + 1]
			end
			i += 2
		elseif name then
			lib.fail("unknown option --" .. name)
		else
			table.insert(rest, a)
			i += 1
		end
	end
	return opts, rest
end
