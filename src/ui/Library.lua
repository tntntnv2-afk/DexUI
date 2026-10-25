if not LPH_OBFUSCATED then
	LPH_NO_VIRTUALIZE = function(f)
		return f
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Name = "DexUI",
	Version = "3.0.0-dev",
	Folder = "DexUI",
	Repo = "https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/",
	Options = {},
	Unloaded = false,
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	Theme = {
		Background = Color3.fromHex("0a0a0c"),
		Surface = Color3.fromHex("111114"),
		Field = Color3.fromHex("16161a"),
		Border = Color3.fromHex("1f1f25"),
		BorderLight = Color3.fromHex("2a2a32"),
		Text = Color3.fromHex("ecebf2"),
		SubText = Color3.fromHex("a9a7b6"),
		Muted = Color3.fromHex("6f6c7d"),
		Accent = Color3.fromHex("ffffff"),
		Danger = Color3.fromHex("ff5c5c"),
	},
}
Library.Toggles = Library.Options

local Connections = {}
local UnloadCallbacks = {}
local Registry = {}
local ThemeCallbacks = {}

local function connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(Connections, connection)
	return connection
end
Library.Connect = function(_, signal, fn)
	return connect(signal, fn)
end

local function fire(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[DexUI] Callback error: " .. tostring(err))
	end
end

local function paintEntry(entry)
	for property, key in pairs(entry.Keys) do
		local value = Library.Theme[key]
		if value ~= nil then
			pcall(function()
				entry.Instance[property] = value
			end)
		end
	end
end

local function create(className, props, children)
	local instance = Instance.new(className)
	local theme = props and props.Theme
	for key, value in pairs(props or {}) do
		if key ~= "Theme" and key ~= "Parent" then
			instance[key] = value
		end
	end
	if theme then
		local entry = { Instance = instance, Keys = theme }
		Registry[instance] = entry
		paintEntry(entry)
		instance.Destroying:Connect(function()
			Registry[instance] = nil
		end)
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if props and props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end
Library.Create = function(_, className, props, children)
	return create(className, props, children)
end

local function tween(instance, goals, info)
	local ok, object = pcall(TweenService.Create, TweenService, instance, info or TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goals)
	if ok and object then
		object:Play()
		return object
	end
	return nil
end
Library.Tween = function(_, instance, goals, info)
	return tween(instance, goals, info)
end

function Library:SetTheme(changes)
	for key, value in pairs(changes or {}) do
		self.Theme[key] = value
	end
	for _, entry in pairs(Registry) do
		paintEntry(entry)
	end
	for _, fn in ipairs(ThemeCallbacks) do
		fire(fn, self.Theme)
	end
end

function Library:OnThemeChanged(fn)
	table.insert(ThemeCallbacks, fn)
end

local function guiParent()
	local ok, hidden = pcall(function()
		return gethui and gethui()
	end)
	if ok and typeof(hidden) == "Instance" then
		return hidden
	end
	local okCore = pcall(function()
		return CoreGui:GetChildren()
	end)
	if okCore then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

function Library:CreateScreenGui(name)
	local gui = create("ScreenGui", {
		Name = name or self.Name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
	gui.Parent = guiParent()
	table.insert(UnloadCallbacks, function()
		gui:Destroy()
	end)
	return gui
end

local Assets = {}
local assetCache = {}
local assetLoading = {}

local function hasFileApi()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
		and type(isfolder) == "function" and type(makefolder) == "function"
end

local function isImage(data)
	if type(data) ~= "string" or #data < 8 then
		return false
	end
	return data:sub(2, 4) == "PNG" or data:sub(1, 2) == "\255\216"
end

local function ensureFolder(path)
	local built = ""
	for part in path:gmatch("[^/]+") do
		built = built == "" and part or (built .. "/" .. part)
		if not isfolder(built) then
			makefolder(built)
		end
	end
end

function Library:DefineAsset(name, spec)
	assert(type(name) == "string" and name ~= "", "asset name expected")
	assert(type(spec) == "table", "asset spec expected")
	Assets[name] = spec
	assetCache[name] = nil
	return spec
end

function Library:GetAssetSpec(name)
	return Assets[name]
end

function Library:GetAsset(name)
	local spec = Assets[name]
	if not spec then
		return nil
	end
	while assetLoading[name] do
		task.wait()
	end
	if assetCache[name] ~= nil then
		return assetCache[name] or nil
	end
	assetCache[name] = false
	local getAsset = getcustomasset or getsynasset
	if type(getAsset) ~= "function" or not hasFileApi() then
		assetCache[name] = spec.Fallback or false
		return assetCache[name] or nil
	end
	assetLoading[name] = true
	local ok, id = pcall(function()
		local extension = (spec.Path or spec.Url or ""):match("%.(%w+)$") or "png"
		local folder = self.Folder .. "/assets"
		local file = string.format("%s/%s_v%s.%s", folder, name, tostring(spec.Version or 1), extension)
		local cached = isfile(file) and readfile(file) or ""
		if not isImage(cached) then
			local url = spec.Url or (self.Repo .. spec.Path)
			local data = game:HttpGet(url)
			if not isImage(data) then
				return nil
			end
			ensureFolder(folder)
			writefile(file, data)
		end
		return getAsset(file)
	end)
	assetLoading[name] = nil
	if ok and type(id) == "string" and id ~= "" then
		assetCache[name] = id
	else
		assetCache[name] = spec.Fallback or false
	end
	return assetCache[name] or nil
end

function Library:PreloadAssets(names)
	for _, name in ipairs(names or {}) do
		task.spawn(function()
			self:GetAsset(name)
		end)
	end
end

local Animated = {}
local animConnection
local animClock = 0
local function stepAnimations(dt)
	animClock += dt or 0
	for i = #Animated, 1, -1 do
		local entry = Animated[i]
		local image, sheet = entry.Image, entry.Sheet
		if image.Parent == nil then
			table.remove(Animated, i)
		elseif image.Visible then
			local frame = math.floor(animClock * (sheet.Fps or 20)) % sheet.Frames
			local offset = Vector2.new((frame % sheet.Columns) * sheet.Width, math.floor(frame / sheet.Columns) * sheet.Height)
			if image.ImageRectOffset ~= offset then
				image.ImageRectOffset = offset
			end
		end
	end
end

function Library:Animate(image, sheet)
	assert(sheet and sheet.Width and sheet.Height and sheet.Columns and sheet.Frames, "sprite sheet needs Width, Height, Columns, Frames")
	image.ImageRectSize = Vector2.new(sheet.Width, sheet.Height)
	image.ImageRectOffset = Vector2.zero
	table.insert(Animated, { Image = image, Sheet = sheet })
	if not animConnection then
		animConnection = connect(RunService.RenderStepped, LPH_NO_VIRTUALIZE(stepAnimations))
	end
	return image
end

function Library:Image(parent, name, props)
	props = props or {}
	local spec = Assets[name]
	local image = create("ImageLabel", {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Size = props.Size or UDim2.fromOffset(24, 24),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		ImageColor3 = props.ImageColor3,
		Theme = props.Theme,
		Parent = parent,
	})
	task.spawn(function()
		local id = self:GetAsset(name)
		if not id or image.Parent == nil then
			if props.OnFailed then
				fire(props.OnFailed, image)
			end
			return
		end
		image.Image = id
		if spec and spec.Sheet then
			self:Animate(image, spec.Sheet)
		end
		if props.OnLoaded then
			fire(props.OnLoaded, image)
		end
	end)
	return image
end

function Library:OnUnload(fn)
	table.insert(UnloadCallbacks, fn)
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	for _, connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(Connections)
	for i = #UnloadCallbacks, 1, -1 do
		fire(UnloadCallbacks[i])
	end
	table.clear(UnloadCallbacks)
	table.clear(Animated)
	animConnection = nil
end

return Library
