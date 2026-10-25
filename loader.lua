local REPO = "https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/"
local CACHE = "Dexori/library_cache.lua"
local function fromGitHub()
	local source = game:HttpGet(REPO .. "src/ui/Library.lua")
	pcall(function()
		if not isfolder("Dexori") then
			makefolder("Dexori")
		end
		writefile(CACHE, source)
	end)
	return source
end
local cached = nil
pcall(function()
	cached = isfile(CACHE) and readfile(CACHE) or nil
end)
if type(cached) == "string" and #cached > 1000 then
	local fn = loadstring(cached, "=Dexori UI")
	if fn then
		local ok, lib = pcall(fn)
		if ok and type(lib) == "table" then
			task.spawn(pcall, fromGitHub)
			return lib
		end
	end
end
return loadstring(fromGitHub(), "=Dexori UI")()
