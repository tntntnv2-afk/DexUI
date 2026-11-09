local REPO = "https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/"
local CACHE = "Dexori/library_cache.lua"
local function compile(source)
	if type(source) ~= "string" or #source < 1000 or not source:find("function Library:CreateWindow", 1, true) then
		return nil
	end
	return (loadstring(source, "=Dexori UI"))
end
local function run(source)
	local fn = compile(source)
	if not fn then
		return nil, nil
	end
	local ok, lib = pcall(fn)
	if ok and type(lib) == "table" then
		return lib
	end
	return nil, lib
end
local function store(source)
	pcall(function()
		if not isfolder("Dexori") then
			makefolder("Dexori")
		end
		writefile(CACHE, source)
	end)
end
local fresh, done, gaveUp = nil, false, false
task.spawn(function()
	local ok, source = pcall(function()
		return game:HttpGet(REPO .. "src/ui/Library.lua")
	end)
	fresh = ok and source or nil
	done = true
	if gaveUp and compile(fresh) then
		store(fresh)
	end
end)
local okRead, cached = pcall(function()
	return isfile(CACHE) and readfile(CACHE) or nil
end)
local haveCache = okRead and compile(cached) ~= nil
local started = os.clock()
while not done and (not haveCache or os.clock() - started < 5) do
	task.wait()
end
gaveUp = not done
local lib, runError = run(fresh)
if lib then
	store(fresh)
	return lib
end
lib = haveCache and run(cached) or nil
if not lib then
	error("[Dexori UI] " .. (runError and ("The library failed to start: " .. tostring(runError)) or "Couldn't download the library and there is no usable saved copy."), 0)
end
return lib
