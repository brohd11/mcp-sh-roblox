-- summary: list instances under a dotted path as JSON lines (path, class)
-- usage: instances [PATH] [DEPTH]     e.g. instances Workspace 2
-- PATH defaults to the whole game; DEPTH defaults to 1.
local HttpService = game:GetService("HttpService")

local root = game
if ARGS[1] then
	for part in string.gmatch(ARGS[1], "[^%.]+") do
		root = root:FindFirstChild(part) or error("not found: " .. ARGS[1])
	end
end
local depth = tonumber(ARGS[2] or "1") or 1

local function walk(inst, d)
	for _, child in ipairs(inst:GetChildren()) do
		print(HttpService:JSONEncode({ path = child:GetFullName(), class = child.ClassName }))
		if d > 1 then
			walk(child, d - 1)
		end
	end
end
walk(root, depth)
