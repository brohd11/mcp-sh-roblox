-- summary: CollectionService tags: tag ls [PATH...] | tag add TAG [PATH...] | tag rm TAG [PATH...] | tag find TAG
-- usage: tag ls                list every tag in the place with its count
--        tag ls PATH...        JSON lines {"path", "tags"}
--        tag add TAG [PATH...] / tag rm TAG [PATH...]   prints each path; one undo step
--        tag find TAG          paths of every tagged instance
local CollectionService = game:GetService("CollectionService")
local op, tagName = ARGS[1], ARGS[2]

if op == "ls" then
	local targets = lib.targets(2, nil, true)
	if #targets == 0 then
		local tags = CollectionService:GetAllTags()
		table.sort(tags)
		for _, t in ipairs(tags) do
			print(#CollectionService:GetTagged(t) .. "\t" .. t)
		end
		return
	end
	for _, inst in ipairs(targets) do
		local tags = inst:GetTags()
		table.sort(tags)
		lib.emit({ path = lib.where(inst), tags = tags })
	end
	return
end

if op == "find" then
	local paths = {}
	for _, inst in ipairs(CollectionService:GetTagged(tagName or lib.fail("missing TAG"))) do
		table.insert(paths, lib.where(inst))
	end
	table.sort(paths)
	for _, p in ipairs(paths) do
		print(p)
	end
	return
end

if op ~= "add" and op ~= "rm" then
	lib.fail("usage: tag ls [PATH...] | tag add TAG [PATH...] | tag rm TAG [PATH...] | tag find TAG")
end
if not tagName then
	lib.fail("missing TAG")
end
local targets = lib.targets(3)
lib.record("tag " .. op .. " " .. tagName, function()
	for _, inst in ipairs(targets) do
		if op == "add" then
			lib.addTag(inst, tagName)
		else
			lib.removeTag(inst, tagName)
		end
		print(lib.where(inst))
	end
end)
