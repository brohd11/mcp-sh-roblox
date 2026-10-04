-- summary: list scripts as JSON lines (path, class, lines, enabled, runContext)
-- usage: scripts [ROOT]      ROOT defaults to game
-- Pairs with jq and the studio script tools, e.g. the five longest scripts:
--   scripts | jq -s -c 'sort_by(-.lines) | .[:5][] | {path, lines}'
local root = lib.resolve(ARGS[1] or "game")
for _, inst in ipairs(root:GetDescendants()) do
	if inst:IsA("LuaSourceContainer") then
		local ok, source = pcall(function()
			return inst.Source
		end)
		local lines
		if ok and source then
			local _, n = string.gsub(source, "\n", "")
			lines = n + 1
		end
		local enabled
		if inst:IsA("BaseScript") then
			enabled = inst.Enabled
		end
		local runContext
		if inst:IsA("Script") then
			runContext = tostring(inst.RunContext)
		end
		lib.emit({
			path = lib.where(inst),
			class = inst.ClassName,
			lines = lines,
			enabled = enabled,
			runContext = runContext,
		})
	end
end
