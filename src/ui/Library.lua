local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Name = "Dexori",
	Version = "1.0.0-dev",
	Repo = "https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/",
	Options = {},
	Unloaded = false,
	Picking = false,
	Folder = "Dexori",
	UserScale = 1,
	GlowEnabled = false,
	KeybindListEnabled = true,
	WatermarkEnabled = true,
	Lowercase = false,
	Theme = {
		Background = Color3.fromHex("0c0c0d"),
		Chrome = Color3.fromHex("080809"),
		Panel = Color3.fromHex("111113"),
		Field = Color3.fromHex("0d0d0f"),
		Button = Color3.fromHex("151517"),
		Hover = Color3.fromHex("121214"),
		Outline = Color3.fromHex("000000"),
		Divider = Color3.fromHex("18181b"),
		Border = Color3.fromHex("1c1c20"),
		BorderLight = Color3.fromHex("29292e"),
		Text = Color3.fromHex("ecebee"),
		SubText = Color3.fromHex("adabb3"),
		Muted = Color3.fromHex("7b7983"),
		Accent = Color3.fromHex("e21a22"),
		Toggle = Color3.fromHex("2a2a30"),
	},
	AccentPresets = {
		Red = Color3.fromHex("e21a22"),
	},
	ForceAccent = true,
	ForceGold = true,
}

local Registry = {}
local ThemeCallbacks = {}
local Connections = {}
local UnloadCallbacks = {}
local SearchIndex = {}
local Loops = {}
local PopupScales = {}
local ScaleHooks = {}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local FONT = Font.new(FAMILY, Enum.FontWeight.Medium)
local FONT_MEDIUM = Font.new(FAMILY, Enum.FontWeight.SemiBold)
local FONT_SEMI = Font.new(FAMILY, Enum.FontWeight.SemiBold)
local FONT_BOLD = Font.new(FAMILY, Enum.FontWeight.Bold)

local RADIUS = 8
local WINDOW_RADIUS = 12
local SIDEBAR = 184
local SIDEBAR_COMPACT = 60
local HEADER = 56
local FOOTER = 30
local USERCARD = 66
local ROW_PAD = 9


local TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local POP_IN = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local POP_OUT = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FADE_PROPS = {
	{ "GuiObject", "BackgroundTransparency" },
	{ "TextLabel", "TextTransparency" },
	{ "TextButton", "TextTransparency" },
	{ "TextBox", "TextTransparency" },
	{ "ImageLabel", "ImageTransparency" },
	{ "ImageButton", "ImageTransparency" },
	{ "ViewportFrame", "ImageTransparency" },
	{ "ScrollingFrame", "ScrollBarImageTransparency" },
	{ "UIStroke", "Transparency" },
}

local MIN_WIDTH, MIN_HEIGHT = 440, 340

local KEY_ALIASES = { MB1 = "MouseButton1", MB2 = "MouseButton2", MB3 = "MouseButton3" }
local KEY_SHORT = { MouseButton1 = "MB1", MouseButton2 = "MB2", MouseButton3 = "MB3" }

local function lowercase(label)
	local function apply()
		if Library.Lowercase then
			local lower = string.lower(label.Text)
			if lower ~= label.Text then
				label.Text = lower
			end
		end
	end
	apply()
	label:GetPropertyChangedSignal("Text"):Connect(apply)
end

local function create(className, props, children)
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
	end
	local parent
	local keepCase = false
	for key, value in pairs(props or {}) do
		if key == "Theme" then
			table.insert(Registry, { instance, value })
			for property, themeKey in pairs(value) do
				instance[property] = Library.Theme[themeKey]
			end
		elseif key == "Parent" then
			parent = value
		elseif key == "KeepCase" then
			keepCase = value == true
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if not keepCase and (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
		lowercase(instance)
	end
	instance.Parent = parent
	return instance
end

local function text(props)
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	props.FontFace = props.FontFace or FONT
	props.TextSize = props.TextSize or 13
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	if props.Theme == nil then
		props.Theme = { TextColor3 = "Text" }
	elseif props.Theme == false then
		props.Theme = nil
	end
	return create("TextLabel", props)
end

local function corner(radius)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or RADIUS) })
end

local function round()
	return create("UICorner", { CornerRadius = UDim.new(1, 0) })
end

local function stroke(themeKey)
	return create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Theme = { Color = themeKey or "Outline" },
	})
end

local function ripple(button)
	button.ClipsDescendants = true
	button.InputBegan:Connect(function(input)
		if not (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			return
		end
		local origin = button.AbsolutePosition
		local reach = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
		local Wave = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(input.Position.X - origin.X, input.Position.Y - origin.Y),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = Library.Theme.Accent,
			BackgroundTransparency = 0.72,
			ZIndex = button.ZIndex + 1,
			Parent = button,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local grow = TweenService:Create(Wave, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(reach, reach),
			BackgroundTransparency = 1,
		})
		grow.Completed:Connect(function()
			Wave:Destroy()
		end)
		grow:Play()
	end)
end

local function pressScale(button)
	local Scale = create("UIScale", { Scale = 1, Parent = button })
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(Scale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.97 }):Play()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			TweenService:Create(Scale, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		end
	end)
	return Scale
end

local function padding(top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
	})
end

local function list(gap, horizontal, props)
	local layout = create("UIListLayout", {
		Padding = UDim.new(0, gap or 0),
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	for key, value in pairs(props or {}) do
		layout[key] = value
	end
	return layout
end

local function tween(instance, goals, info)
	local t = TweenService:Create(instance, info or TWEEN, goals)
	t:Play()
	return t
end

local function connect(signal, fn)
	local connection = signal:Connect(fn)
	table.insert(Connections, connection)
	return connection
end

local function fadeEntries(root)
	local entries = {}
	local function add(instance)
		for _, pair in ipairs(FADE_PROPS) do
			if instance:IsA(pair[1]) and instance[pair[2]] < 1 then
				table.insert(entries, { instance, pair[2], instance[pair[2]] })
			end
		end
	end
	add(root)
	for _, instance in ipairs(root:GetDescendants()) do
		add(instance)
	end
	return entries
end

local Fades = setmetatable({}, { __mode = "k" })

local function popout(root, show, onHidden)
	local fade = Fades[root]
	if not fade then
		fade = { Shown = root.Visible, Token = 0 }
		Fades[root] = fade
	end
	if fade.Shown == show then
		return
	end
	fade.Shown = show
	fade.Token = fade.Token + 1
	local token = fade.Token
	local entries = fade.Entries
	if not entries then
		entries = fadeEntries(root)
		fade.Entries = entries
	end
	if show then
		if not root.Visible then
			for _, entry in ipairs(entries) do
				entry[1][entry[2]] = 1
			end
			root.Visible = true
		end
		for _, entry in ipairs(entries) do
			tween(entry[1], { [entry[2]] = entry[3] }, POP_IN)
		end
		task.delay(POP_IN.Time + 0.02, function()
			if fade.Token == token then
				fade.Entries = nil
			end
		end)
	else
		for _, entry in ipairs(entries) do
			tween(entry[1], { [entry[2]] = 1 }, POP_OUT)
		end
		task.delay(POP_OUT.Time + 0.02, function()
			if fade.Token == token then
				root.Visible = false
				for _, entry in ipairs(entries) do
					entry[1][entry[2]] = entry[3]
				end
				fade.Entries = nil
				if onHidden then
					onHidden()
				end
			end
		end)
	end
end

local function hideTooltip()
	if Library.Tooltip then
		popout(Library.Tooltip, false)
	end
end

local function fire(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local args = table.pack(...)
	task.spawn(function()
		local ok, err = pcall(fn, table.unpack(args, 1, args.n))
		if not ok then
			warn("[Dexori UI] Callback error: " .. tostring(err))
		end
	end)
end

local function scaleFactor()
	local s = Library.Scale and Library.Scale.Scale or 1
	return s > 0 and s or 1
end

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function parseKey(value)
	if typeof(value) == "EnumItem" then
		return value
	end
	if type(value) ~= "string" or value == "" or value == "None" then
		return nil
	end
	value = KEY_ALIASES[value] or value
	local ok, key = pcall(function()
		return Enum.KeyCode[value]
	end)
	if ok and key then
		return key
	end
	ok, key = pcall(function()
		return Enum.UserInputType[value]
	end)
	if ok and key then
		return key
	end
	return nil
end

local function keyName(key)
	if not key then
		return "None"
	end
	return KEY_SHORT[key.Name] or key.Name
end

local function inputMatches(input, key)
	if not key then
		return false
	end
	if key.EnumType == Enum.KeyCode then
		return input.KeyCode == key
	end
	return input.UserInputType == key
end

local function parentGui(gui)
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		gui.Parent = hui
		return
	end
	if pcall(function()
		gui.Parent = CoreGui
	end) then
		return
	end
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function attachTooltip(target, tip)
	if not tip then
		return
	end
	target.MouseEnter:Connect(function()
		local Tooltip = Library.Tooltip
		if Tooltip then
			local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			Tooltip.Text = tip
			Tooltip.Position = UDim2.fromOffset(mouse.X + 14, mouse.Y + 16)
			popout(Tooltip, true)
		end
	end)
	target.MouseLeave:Connect(hideTooltip)
end

local function flash(target)
	local Round
	if not target:FindFirstChildOfClass("UICorner") then
		Round = create("UICorner", { CornerRadius = UDim.new(0, RADIUS), Parent = target })
	end
	local Outline = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Theme = { Color = "Accent" },
		Parent = target,
	})
	task.delay(0.9, function()
		tween(Outline, { Transparency = 1 }, TweenInfo.new(0.5)).Completed:Connect(function()
			Outline:Destroy()
			if Round then
				Round:Destroy()
			end
		end)
	end)
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
		local source = spec.Path or spec.Url or name
		local extension = source:match("%.(%w+)$") or "png"
		local base = source:match("([^/]+)%.%w+$") or name
		local folder = "Dexori/assets"
		local file = string.format("%s/%s_v%s.%s", folder, base, tostring(spec.Version or 1), extension)
		local cached = isfile(file) and readfile(file) or ""
		if not isImage(cached) then
			local data = game:HttpGet(spec.Url or (Library.Repo .. spec.Path))
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
			Library:GetAsset(name)
		end)
	end
end

local AnimatedLogos = {}
local animConnection
local animClock = 0
local function stepLogos(dt)
	animClock += dt or 0
	for i = #AnimatedLogos, 1, -1 do
		local entry = AnimatedLogos[i]
		local image, sheet = entry[1], entry[2]
		if image.Parent == nil then
			table.remove(AnimatedLogos, i)
		elseif image.Visible then
			local frame
			local durations = sheet.Durations
			if durations then
				if not sheet._total then
					local total = 0
					for _, ms in ipairs(durations) do
						total += ms
					end
					sheet._total = math.max(total, 1)
				end
				local at = (animClock * 1000) % sheet._total
				frame = #durations - 1
				for index, ms in ipairs(durations) do
					if at < ms then
						frame = index - 1
						break
					end
					at -= ms
				end
			else
				frame = math.floor(animClock * (sheet.Fps or 20)) % sheet.Frames
			end
			local offset = Vector2.new((frame % sheet.Columns) * sheet.Width, math.floor(frame / sheet.Columns) * sheet.Height)
			if image.ImageRectOffset ~= offset then
				image.ImageRectOffset = offset
			end
		end
	end
end
local function animateLogo(image, sheet)
	image.ImageRectSize = Vector2.new(sheet.Width, sheet.Height)
	image.ImageRectOffset = Vector2.zero
	table.insert(AnimatedLogos, { image, sheet })
	if not animConnection then
		animConnection = RunService.RenderStepped:Connect(stepLogos)
		table.insert(Connections, animConnection)
	end
	return image
end
function Library:Animate(image, sheet)
	assert(sheet and sheet.Width and sheet.Height and sheet.Columns and sheet.Frames, "sprite sheet needs Width, Height, Columns, Frames")
	return animateLogo(image, sheet)
end
function Library:Image(parent, name, props)
	props = props or {}
	local image = create("ImageLabel", {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "",
		Size = props.Size or UDim2.fromOffset(24, 24),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		ImageColor3 = props.ImageColor3 or Color3.new(1, 1, 1),
		Parent = parent,
	})
	task.spawn(function()
		local id = Library:GetAsset(name)
		if not id or image.Parent == nil then
			fire(props.OnFailed, image)
			return
		end
		image.Image = id
		local spec = Assets[name]
		if spec and spec.Sheet then
			animateLogo(image, spec.Sheet)
		end
		fire(props.OnLoaded, image)
	end)
	return image
end

local LOGO_SHEET = { Width = 128, Height = 128, Columns = 8, Frames = 45, Fps = 50, Durations = { 360, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
	20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 1580 } }
Library:DefineAsset("Wordmark", { Path = "assets/dexori_d_anim.png", Version = 1, Sheet = LOGO_SHEET })
Library:DefineAsset("Icon", { Path = "assets/dexori_d_anim.png", Version = 1, Sheet = LOGO_SHEET })

local function buildLogo(parent, height, layoutOrder)
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, height),
		LayoutOrder = layoutOrder or 1,
		Parent = parent,
	}, { list(0, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local First = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, height), FontFace = FONT_BOLD, TextSize = height + 2, Text = "d", LayoutOrder = 1, Theme = { TextColor3 = "Accent" }, Parent = Holder })
	local Rest = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, height), FontFace = FONT_BOLD, TextSize = height + 2, Text = "exori", LayoutOrder = 2, Parent = Holder })
	local spec = Assets.Wordmark
	if spec then
		task.spawn(function()
			local asset = Library:GetAsset("Wordmark")
			if not (asset and Holder.Parent) then
				return
			end
			First:Destroy()
			Rest:Destroy()
			local sheet = spec.Sheet
			local ratio = sheet and (sheet.Width / sheet.Height) or spec.Ratio or 4
			local tall = sheet and math.floor(height * 1.12 + 0.5) or height
			local Image = create("ImageLabel", {
				BackgroundTransparency = 1,
				Image = asset,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(math.floor(tall * ratio + 0.5), tall),
				Parent = Holder,
			})
			if sheet then
				animateLogo(Image, sheet)
			end
		end)
	end
	return Holder
end
Library.BuildLogo = function(parent, height, layoutOrder)
	return buildLogo(parent, height, layoutOrder)
end
local function buildIcon(parent, size, fallback)
	local spec = Assets.Icon
	if not spec then
		return
	end
	task.spawn(function()
		local asset = Library:GetAsset("Icon")
		if not (asset and parent.Parent) then
			return
		end
		if fallback then
			fallback.TextTransparency = 1
		end
		local Image = create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			BackgroundTransparency = 1,
			Image = asset,
			ScaleType = Enum.ScaleType.Fit,
			Parent = parent,
		})
		if spec.Sheet then
			animateLogo(Image, spec.Sheet)
		end
	end)
end
Library.BuildIcon = function(parent, size)
	return buildIcon(parent, size)
end

local ICON_NAMES = {
	"sprout", "sword", "swords", "crosshair", "map-pin", "layout-grid", "settings", "star", "search", "x",
	"minus", "chevron-down", "chevron-right", "chevron-up", "chevron-left", "check", "eye", "eye-off", "user",
	"users", "zap", "shield", "target", "flame", "skull", "coins", "clock", "trophy", "package", "gem", "heart",
	"bell", "info", "triangle-alert", "lock", "lock-open", "refresh-cw", "play", "pause", "square", "plus",
	"copy", "trash-2", "folder", "save", "download", "upload", "palette", "monitor", "keyboard",
	"mouse-pointer-2", "wand-sparkles", "bot", "ghost", "footprints", "wind", "axe", "hammer", "compass", "globe",
	"server", "wifi", "activity", "chart-column", "list", "sliders-horizontal", "toggle-right", "sparkles",
	"moon", "sun", "droplet", "fish", "tree-pine", "mountain", "cloud", "store", "shopping-cart", "gift", "crown",
	"medal", "book-open", "scroll-text", "message-square", "link", "external-link", "log-out", "power",
	"rotate-ccw", "maximize-2", "minimize-2", "grip-vertical", "menu", "filter", "house", "circle-help",
	"circle-check", "circle-x", "flag", "bomb", "rocket", "pickaxe", "backpack", "dices", "sparkle", "shirt",
	"car", "plane", "anchor", "bug", "code", "terminal", "command", "fingerprint", "radar", "scan", "locate",
	"navigation", "route", "timer", "hourglass", "calendar", "award", "badge-check", "box", "boxes", "shuffle",
	"repeat", "infinity", "skip-forward", "fast-forward", "mic", "volume-2", "volume-x", "image", "camera",
	"video", "music", "gamepad-2", "joystick"
}
local ICON_INDEX = {}
for index, name in ipairs(ICON_NAMES) do
	ICON_INDEX[name] = index
end
local ICON_ALIASES = { home = "house", gear = "settings", close = "x", farm = "sprout", combat = "swords", teleport = "map-pin", misc = "layout-grid", credits = "star", visuals = "eye", player = "user", players = "users", world = "globe", config = "save" }
local ICON_CELL, ICON_COLUMNS = 64, 16
Library:DefineAsset("Icons", { Path = "assets/icons.png", Version = 1 })

local function iconRect(name)
	if type(name) ~= "string" then
		return nil
	end
	local key = string.lower(name)
	local index = ICON_INDEX[key] or ICON_INDEX[ICON_ALIASES[key] or ""]
	if not index then
		return nil
	end
	return Vector2.new(((index - 1) % ICON_COLUMNS) * ICON_CELL, math.floor((index - 1) / ICON_COLUMNS) * ICON_CELL)
end

local function setIcon(image, name)
	local rect = iconRect(name)
	image.Visible = rect ~= nil and image:GetAttribute("DexoriHidden") ~= true
	if rect then
		image.ImageRectOffset = rect
		image.ImageRectSize = Vector2.new(ICON_CELL, ICON_CELL)
	end
end

local function icon(parent, name, size, props)
	props = props or {}
	local image = create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(size or 16, size or 16),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Theme = props.Theme,
		Parent = parent,
	})
	if not props.Theme then
		image.ImageColor3 = props.Color or Library.Theme.SubText
	end
	setIcon(image, name)
	task.spawn(function()
		local id = Library:GetAsset("Icons")
		if id and image.Parent then
			image.Image = id
		end
	end)
	return image
end

function Library:Icon(parent, name, size, props)
	return icon(parent, name, size, props)
end

function Library:SetIcon(image, name)
	setIcon(image, name)
end

function Library:HasIcon(name)
	return iconRect(name) ~= nil
end

function Library:SetTheme(changes)
	for key, value in pairs(changes) do
		if key ~= "Accent" then
			self.Theme[key] = value
		end
	end
	for _, entry in ipairs(Registry) do
		for property, themeKey in pairs(entry[2]) do
			entry[1][property] = self.Theme[themeKey]
		end
	end
	for _, paint in ipairs(ThemeCallbacks) do
		paint()
	end
end

function Library:SetScale(scale)
	self.UserScale = scale
	if self.Scale then
		self.Scale.Scale = scale
	end
	if self.PanelScale then
		self.PanelScale.Scale = scale
	end
	if self.WatermarkScale then
		self.WatermarkScale.Scale = scale
	end
	for _, popupScale in ipairs(PopupScales) do
		popupScale.Scale = scale
	end
	for _, hook in ipairs(ScaleHooks) do
		hook(scale)
	end
end

local function newOption(id, kind, opts)
	local option = {
		Id = id,
		Type = kind,
		Callback = opts.Callback,
		Save = opts.Save ~= false,
		Changed = {},
	}
	function option:OnChanged(fn)
		table.insert(self.Changed, fn)
	end
	function option:_emit()
		fire(self.Callback, self.Value)
		for _, fn in ipairs(self.Changed) do
			fire(fn, self.Value)
		end
	end
	if id then
		if Library.Options[id] then
			warn("[Dexori UI] Duplicate option id: " .. tostring(id))
		end
		Library.Options[id] = option
	end
	return option
end

local KeybindEntries = {}
local keybindRefreshPending = false
local function refreshKeybinds()
	if keybindRefreshPending then
		return
	end
	keybindRefreshPending = true
	task.defer(function()
		keybindRefreshPending = false
		if Library._renderKeybinds and not Library.Unloaded then
			Library._renderKeybinds()
		end
	end)
end

local function newKeybind(id, opts, parent, position, onPress, onRelease, meta)
	meta = meta or {}
	local option = newOption(id, "Keybind", opts)
	option.Value = parseKey(opts.Default)
	option.Mode = opts.Mode or "Toggle"
	option.State = false
	local entry = { Option = option, Label = meta.Label or opts.Text or id or "Keybind", Hidden = opts.ShowInList == false }
	entry.GetState = meta.GetState or function()
		if option.Mode == "Press" then
			return entry.PulseUntil ~= nil and os.clock() < entry.PulseUntil
		end
		return option.State
	end
	table.insert(KeybindEntries, entry)

	local picking = false
	local ChipEdge = stroke("BorderLight")
	local Chip = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = position,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		AutoButtonColor = false,
		FontFace = FONT_SEMI,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Theme = { BackgroundColor3 = "Field", TextColor3 = "SubText" },
		Parent = parent,
	}, { corner(5), ChipEdge, padding(0, 7, 0, 7) })
	local function paintChip()
		local T = Library.Theme
		tween(Chip, { TextColor3 = picking and T.Accent or T.SubText }, TWEEN_FAST)
		tween(ChipEdge, { Color = picking and T.Accent or T.BorderLight }, TWEEN_FAST)
	end
	table.insert(ThemeCallbacks, paintChip)
	Chip.MouseEnter:Connect(function()
		if not picking then
			tween(Chip, { TextColor3 = Library.Theme.Text })
			tween(ChipEdge, { Color = Library.Theme.Muted })
		end
	end)
	Chip.MouseLeave:Connect(function()
		if not picking then
			tween(Chip, { TextColor3 = Library.Theme.SubText })
			tween(ChipEdge, { Color = Library.Theme.BorderLight })
		end
	end)

	local function display()
		Chip.Text = picking and "..." or keyName(option.Value)
	end
	display()

	function option:SetValue(key)
		self.Value = parseKey(key)
		display()
		for _, fn in ipairs(self.Changed) do
			fire(fn, self.Value)
		end
		refreshKeybinds()
	end

	Chip.MouseButton1Click:Connect(function()
		picking = true
		Library.Picking = true
		paintChip()
		display()
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if picking then
			local kind = input.UserInputType
			if kind == Enum.UserInputType.Keyboard then
				option:SetValue(input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode or nil)
			elseif kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.MouseButton3 then
				option:SetValue(kind)
			elseif kind ~= Enum.UserInputType.MouseButton1 then
				return
			end
			picking = false
			paintChip()
			display()
			task.defer(function()
				Library.Picking = false
			end)
			return
		end

		if processed or Library.Picking or not inputMatches(input, option.Value) then
			return
		end
		if option.Mode == "Toggle" then
			option.State = not option.State
			fire(opts.Callback, option.State)
		elseif option.Mode == "Hold" then
			option.State = true
			fire(opts.Callback, true)
		else
			fire(opts.Callback)
			entry.PulseUntil = os.clock() + 0.3
			task.delay(0.32, refreshKeybinds)
		end
		if onPress then
			onPress()
		end
		refreshKeybinds()
	end)

	connect(UserInputService.InputEnded, function(input)
		if option.Mode == "Hold" and option.State and inputMatches(input, option.Value) then
			option.State = false
			fire(opts.Callback, false)
			if onRelease then
				onRelease()
			end
			refreshKeybinds()
		end
	end)

	return option
end

local function accentLine(parent)
	local Line = create("Frame", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 0, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = parent,
	})
	local Glow = create("UIGradient", {
		Offset = Vector2.new(-0.6, 0),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Line,
	})
	local loop = tween(Glow, { Offset = Vector2.new(0.6, 0) }, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true))
	table.insert(Loops, loop)
	return Line, loop
end

local function magnifier(parent)
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(12, 12),
		Parent = parent,
	})
	create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(8, 8),
		Parent = Holder,
	}, { round(), create("UIStroke", { Thickness = 1.4, Theme = { Color = "SubText" } }) })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(9, 9),
		Size = UDim2.fromOffset(2, 5),
		Rotation = -45,
		Theme = { BackgroundColor3 = "SubText" },
		Parent = Holder,
	}, { corner(1) })
	return Holder
end

local function tickMark(parent)
	local Tick = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	local Scale = create("UIScale", { Scale = 0, Parent = Tick })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, -2, 0.5, 1),
		Size = UDim2.fromOffset(4, 2),
		Rotation = 45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Tick,
	}, { corner(1) })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 1, 0.5, 0),
		Size = UDim2.fromOffset(7, 2),
		Rotation = -45,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = Tick,
	}, { corner(1) })
	return Scale
end

local function toHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function fromHex(value)
	local hex = tostring(value or ""):gsub("#", ""):gsub("%s", "")
	if #hex ~= 6 then
		return nil
	end
	local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	if not (r and g and b) then
		return nil
	end
	return Color3.fromRGB(r, g, b)
end

local function readColor(value)
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		return fromHex(value)
	end
	if type(value) == "table" then
		if value.hex then
			return fromHex(value.hex), tonumber(value.transparency)
		end
		if value.R and value.G and value.B then
			return Color3.new(value.R, value.G, value.B)
		end
		if value[1] and value[2] and value[3] then
			return Color3.fromRGB(value[1], value[2], value[3])
		end
	end
	return nil
end

local function dragBy(frame, canStart)
	local dragging, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if isPointer(input) and (not canStart or canStart(input)) then
			dragging, dragStart, startPos = true, input.Position, frame.Position
		end
	end)
	local moved = connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	local ended = connect(UserInputService.InputEnded, function(input)
		if isPointer(input) then
			dragging = false
		end
	end)
	return function()
		moved:Disconnect()
		ended:Disconnect()
	end
end

local HUE_COLORS = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
})

local function attachColorPicker(group, slotParent, id, opts)
	opts = opts or {}
	local option = newOption(id, "ColorPicker", opts)
	local hasAlpha = opts.Transparency ~= nil
	option.Value = readColor(opts.Default) or Color3.new(1, 1, 1)
	option.Transparency = math.clamp(tonumber(opts.Transparency) or 0, 0, 1)
	local h, s, v = option.Value:ToHSV()

	local SwatchEdge = stroke("BorderLight")
	local Swatch = create("TextButton", {
		Size = UDim2.fromOffset(28, 16),
		AutoButtonColor = false,
		Text = "",
		Parent = slotParent,
	}, { corner(5), SwatchEdge })

	local Panel = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = group:_next(),
		Theme = { BackgroundColor3 = "Background" },
		Parent = group.Container,
	}, { corner(10), stroke("BorderLight") })
	local Body = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Panel,
	}, { padding(8), list(8) })
	text({
		Size = UDim2.new(1, 0, 0, 16),
		FontFace = FONT_SEMI,
		Text = opts.Title or opts.Text or id or "Color",
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = 0,
		Parent = Body,
	})

	local Sv = create("Frame", {
		Size = UDim2.new(1, 0, 0, 110),
		LayoutOrder = 1,
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		Parent = Body,
	}, { corner(8) })
	create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 1,
		Parent = Sv,
	}, {
		corner(8),
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		ZIndex = 2,
		Parent = Sv,
	}, {
		corner(8),
		create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }),
	})
	local SvHit = create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = Sv })
	local SvCursor = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = Sv,
	}, { round(), create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })

	local function bar(order)
		local Bar = create("Frame", {
			Size = UDim2.new(1, 0, 0, 12),
			LayoutOrder = order,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Body,
		}, { corner(6) })
		local Hit = create("TextButton", {
			Position = UDim2.fromOffset(0, -4),
			Size = UDim2.new(1, 0, 1, 8),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 3,
			Parent = Bar,
		})
		local Cursor = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(6, 16),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 4,
			Parent = Bar,
		}, { corner(3), create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.5, Thickness = 1 }) })
		return Bar, Hit, Cursor
	end
	local Hue, HueHit, HueCursor = bar(2)
	create("UIGradient", { Color = HUE_COLORS, Parent = Hue })
	local Alpha, AlphaHit, AlphaCursor
	if hasAlpha then
		Alpha, AlphaHit, AlphaCursor = bar(3)
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.92) }), Parent = Alpha })
	end

	local HexRow = create("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 4,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Body,
	}, { corner(7), stroke("BorderLight") })
	local Preview = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.fromOffset(30, 16),
		Parent = HexRow,
	}, { corner(4) })
	local HexBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(9, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Text = "",
		ClearTextOnFocus = false,
		FontFace = FONT_SEMI,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = HexRow,
	})

	local function render()
		Sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		SvCursor.Position = UDim2.fromScale(s, 1 - v)
		HueCursor.Position = UDim2.fromScale(h, 0.5)
		if Alpha then
			Alpha.BackgroundColor3 = option.Value
			AlphaCursor.Position = UDim2.fromScale(option.Transparency, 0.5)
		end
		Swatch.BackgroundColor3 = option.Value
		Swatch.BackgroundTransparency = option.Transparency * 0.85
		Preview.BackgroundColor3 = option.Value
		Preview.BackgroundTransparency = option.Transparency * 0.85
		if not HexBox:IsFocused() then
			HexBox.Text = toHex(option.Value)
		end
	end

	function option:_emit()
		fire(self.Callback, self.Value, self.Transparency)
		for _, fn in ipairs(self.Changed) do
			fire(fn, self.Value, self.Transparency)
		end
	end

	local function commit()
		option.Value = Color3.fromHSV(h, s, v)
		render()
		option:_emit()
	end

	function option:SetValue(value, transparency)
		local color, saved = readColor(value)
		if not color then
			return
		end
		local t = tonumber(transparency) or saved
		if t then
			self.Transparency = math.clamp(t, 0, 1)
		end
		self.Value = color
		h, s, v = color:ToHSV()
		render()
		self:_emit()
	end
	option.SetValueRGB = option.SetValue

	local dragKind
	local function apply(kind, position)
		if kind == "sv" then
			local at, size = Sv.AbsolutePosition, Sv.AbsoluteSize
			s = math.clamp((position.X - at.X) / math.max(size.X, 1), 0, 1)
			v = 1 - math.clamp((position.Y - at.Y) / math.max(size.Y, 1), 0, 1)
			commit()
		elseif kind == "hue" then
			local at, size = Hue.AbsolutePosition, Hue.AbsoluteSize
			h = math.clamp((position.X - at.X) / math.max(size.X, 1), 0, 0.999)
			commit()
		elseif kind == "alpha" and Alpha then
			local at, size = Alpha.AbsolutePosition, Alpha.AbsoluteSize
			option.Transparency = math.clamp((position.X - at.X) / math.max(size.X, 1), 0, 1)
			render()
			option:_emit()
		end
	end
	local function grab(hit, kind)
		hit.InputBegan:Connect(function(input)
			if isPointer(input) then
				dragKind = kind
				apply(kind, input.Position)
			end
		end)
	end
	grab(SvHit, "sv")
	grab(HueHit, "hue")
	if AlphaHit then
		grab(AlphaHit, "alpha")
	end
	connect(UserInputService.InputChanged, function(input)
		if dragKind and isMove(input) then
			apply(dragKind, input.Position)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPointer(input) then
			dragKind = nil
		end
	end)
	HexBox.FocusLost:Connect(function()
		local color = fromHex(HexBox.Text)
		if color then
			option:SetValue(color)
		else
			render()
		end
	end)

	local open, panelId = false, 0
	local fullHeight = 204 + (hasAlpha and 20 or 0)
	local function setOpen(state)
		open = state
		panelId = panelId + 1
		local id = panelId
		tween(SwatchEdge, { Color = state and Library.Theme.Accent or Library.Theme.BorderLight })
		if state then
			if not Panel.Visible then
				Panel.Size = UDim2.new(1, 0, 0, 0)
				Panel.Visible = true
			end
			tween(Panel, { Size = UDim2.new(1, 0, 0, fullHeight) }, TWEEN_SMOOTH)
		else
			tween(Panel, { Size = UDim2.new(1, 0, 0, 0) }, POP_OUT).Completed:Connect(function()
				if id == panelId then
					Panel.Visible = false
				end
			end)
		end
	end
	Swatch.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)
	Swatch.MouseEnter:Connect(function()
		if not open then
			tween(SwatchEdge, { Color = Library.Theme.Muted })
		end
	end)
	Swatch.MouseLeave:Connect(function()
		if not open then
			tween(SwatchEdge, { Color = Library.Theme.BorderLight })
		end
	end)
	table.insert(ThemeCallbacks, function()
		SwatchEdge.Color = open and Library.Theme.Accent or Library.Theme.BorderLight
	end)
	render()
	return option
end

local function slotRow(parent)
	return create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = parent,
	}, { list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
end

local Elements = {}
Elements.__index = Elements

function Elements:_next()
	self.Order = self.Order + 1
	return self.Order
end

function Elements:_separator()
	self.Rows = (self.Rows or 0) + 1
end

function Elements:_holder(height)
	if self.Rows > 0 then
		create("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			LayoutOrder = self:_next(),
			Theme = { BackgroundColor3 = "Divider" },
			Parent = self.Container,
		})
	end
	self:_separator()
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height and height + ROW_PAD * 2 or 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Container,
	}, { padding(ROW_PAD, 0, ROW_PAD, 0) })
	return Holder
end

function Elements:_index(name, holder, flashTarget)
	table.insert(SearchIndex, { Name = name, Holder = holder, Flash = flashTarget, Tab = self.Tab, Column = self.Column, Group = self })
end

local function described(opts)
	return type(opts.Description) == "string" and opts.Description ~= ""
end

local function rowHeight(opts, minimum)
	return math.max(described(opts) and 34 or 22, minimum or 0)
end

local function rowText(parent, opts, fallback, widthScale, widthOffset)
	local hasDescription = described(opts)
	local Label = text({
		AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
		Position = hasDescription and UDim2.new() or UDim2.fromScale(0, 0.5),
		Size = UDim2.new(widthScale or 1, -(widthOffset or 0), 0, 18),
		FontFace = FONT_MEDIUM,
		TextSize = 13,
		Text = opts.Text or fallback or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = parent,
	})
	local Description
	if hasDescription then
		Description = text({
			Position = UDim2.fromOffset(0, 19),
			Size = UDim2.new(widthScale or 1, -(widthOffset or 0), 0, 15),
			TextSize = 12,
			Text = opts.Description,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "Muted" },
			Parent = parent,
		})
	end
	local row = {}
	function row.Width(scale, offset)
		Label.Size = UDim2.new(scale, -offset, 0, 18)
		if Description then
			Description.Size = UDim2.new(scale, -offset, 0, 15)
		end
	end
	function row.SetDescription(value)
		if Description then
			Description.Text = tostring(value or "")
		end
	end
	return Label, Description, row
end

function Elements:AddLabel(content, wrap)
	local Holder = self:_holder()
	local Label = text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = content or "",
		TextWrapped = wrap ~= false,
		RichText = true,
		Theme = { TextColor3 = "SubText" },
		Parent = Holder,
	})
	local group = self
	local Slots
	local object = {}
	function object:SetText(newText)
		Label.Text = newText
	end
	function object:AddColorPicker(pickerId, pickerOpts)
		if not Slots then
			create("UIPadding", { PaddingRight = UDim.new(0, 40), Parent = Label })
			Slots = create("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 40, 0, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Parent = Label,
			}, { list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
		end
		pickerOpts = pickerOpts or {}
		pickerOpts.Text = pickerOpts.Text or Label.Text
		return attachColorPicker(group, Slots, pickerId, pickerOpts)
	end
	return object
end

function Elements:AddDivider(label)
	if label then
		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 30),
			LayoutOrder = self:_next(),
			Parent = self.Container,
		})
		create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 3),
			Size = UDim2.new(1, 0, 0, 1),
			Theme = { BackgroundColor3 = "Divider" },
			Parent = Holder,
		})
		local Tag = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 3),
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			Theme = { BackgroundColor3 = "Panel" },
			Parent = Holder,
		}, { padding(0, 8, 0, 0) })
		text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			FontFace = FONT_BOLD,
			TextSize = 11,
			Text = string.upper(label),
			Theme = { TextColor3 = "Muted" },
			Parent = Tag,
		})
		self.Rows = 0
		return
	end
	create("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		LayoutOrder = self:_next(),
		Theme = { BackgroundColor3 = "BorderLight" },
		Parent = self.Container,
	})
	self.Rows = 0
end

function Elements:AddCustom(height)
	local Holder = self:_holder(height or 120)
	Holder.ClipsDescendants = true
	return Holder
end

function Elements:AddColorPicker(id, opts)
	opts = opts or {}
	local Holder = self:_holder(rowHeight(opts))
	rowText(Holder, opts, id, 1, 44)
	local option = attachColorPicker(self, slotRow(Holder), id, opts)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

local TextService = game:GetService("TextService")
local textWidths = {}
local function measureText(value, font, size)
	value = tostring(value or "")
	local key = value .. "\0" .. size .. "\0" .. tostring(font.Weight)
	if textWidths[key] then
		return textWidths[key]
	end
	local width = (utf8.len(value) or #value) * size * 0.52
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = value
		params.Font = font
		params.Size = size
		params.Width = 1000
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and typeof(bounds) == "Vector2" and bounds.X > 0 then
		width = bounds.X
		textWidths[key] = width
	end
	return math.ceil(width)
end
local function textWidth(value, font, size, onMeasured)
	value = tostring(value or "")
	local key = value .. "\0" .. size .. "\0" .. tostring(font.Weight)
	if textWidths[key] then
		return math.ceil(textWidths[key])
	end
	if onMeasured then
		task.spawn(function()
			onMeasured(measureText(value, font, size))
		end)
	end
	return math.ceil((utf8.len(value) or #value) * size * 0.52)
end

local function accentButton(parent, label, props)
	local Edge = create("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Thickness = 1,
		Transparency = 0.45,
		Theme = { Color = "Accent" },
	})
	local Button = create("TextButton", {
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.new(),
		Size = props.Size,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		FontFace = FONT_SEMI,
		TextSize = 13,
		Text = label,
		Theme = { BackgroundColor3 = "Accent", TextColor3 = "Accent" },
		Parent = parent,
	}, { corner(7), Edge, padding(0, 14, 0, 14) })
	ripple(Button)
	pressScale(Button)
	Button.MouseEnter:Connect(function()
		tween(Button, { BackgroundTransparency = 0.88 })
		tween(Edge, { Transparency = 0 })
	end)
	Button.MouseLeave:Connect(function()
		tween(Button, { BackgroundTransparency = 1 })
		tween(Edge, { Transparency = 0.45 })
	end)
	return Button
end

function Elements:AddButton(opts, func)
	if type(opts) == "string" then
		opts = { Text = opts, Func = func }
	end
	local labelled = opts.Label ~= nil or described(opts)
	local Holder = self:_holder(labelled and rowHeight(opts, 28) or 30)
	local Button
	if labelled then
		local _, _, row = rowText(Holder, { Text = opts.Label or "", Description = opts.Description }, nil, 1, 0)
		Button = accentButton(Holder, opts.Text or "Button", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(64, 28),
		})
		local function apply(textSize)
			local width = math.max(textSize + 30, 64)
			Button.Size = UDim2.fromOffset(width, 28)
			row.Width(1, width + 12)
		end
		local function fit()
			local label = Button.Text
			apply(textWidth(label, FONT_SEMI, 13, function(measured)
				if Button.Text == label then
					apply(measured)
				end
			end))
		end
		Button:GetPropertyChangedSignal("Text"):Connect(fit)
		fit()
	else
		Button = accentButton(Holder, opts.Text or "Button", { Size = UDim2.fromScale(1, 1) })
	end
	Button.MouseButton1Click:Connect(function()
		fire(opts.Func)
	end)
	attachTooltip(Button, opts.Tooltip)
	self:_index(opts.Label or opts.Text or "Button", Holder, Holder)

	local object = { Button = Button }
	function object:SetText(newText)
		Button.Text = newText
	end
	return object
end

function Elements:AddToggle(id, opts)
	local option = newOption(id, "Toggle", opts)
	option.Value = opts.Default == true
	local group = self
	local hasDescription = described(opts)

	local Holder = self:_holder(hasDescription and 34 or 22)
	local Row = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		Parent = Holder,
	})

	local BoxEdge = stroke("BorderLight")
	local Box = create("Frame", {
		AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
		Position = hasDescription and UDim2.fromOffset(0, 2) or UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Theme = { BackgroundColor3 = "Field" },
		Parent = Row,
	}, { corner(4), BoxEdge })
	local Fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Box,
	}, { corner(4) })
	local TickScale = tickMark(Box)
	local Text = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -22, 1, 0),
		Parent = Row,
	})
	local Label, _, row = rowText(Text, opts, id, 1, 0)

	local function paint(animated)
		local T = Library.Theme
		local on = option.Value
		if animated then
			tween(Fill, { BackgroundTransparency = on and 0 or 1 }, TweenInfo.new(0.18, Enum.EasingStyle.Quad))
			tween(TickScale, { Scale = on and 1 or 0 }, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
			tween(BoxEdge, { Color = on and T.Accent or T.BorderLight })
			tween(Label, { TextColor3 = on and T.Text or T.SubText })
		else
			Fill.BackgroundTransparency = on and 0 or 1
			TickScale.Scale = on and 1 or 0
			BoxEdge.Color = on and T.Accent or T.BorderLight
			Label.TextColor3 = on and T.Text or T.SubText
		end
	end
	table.insert(ThemeCallbacks, function()
		paint(false)
	end)
	paint(false)

	function option:SetValue(value)
		value = value == true
		if value == self.Value then
			return
		end
		self.Value = value
		paint(true)
		self:_emit()
		refreshKeybinds()
	end

	local Slots
	local reserve = 0
	local function slot(width)
		Slots = Slots or slotRow(Row)
		reserve = reserve + width
		row.Width(1, reserve)
		return Slots
	end

	function option:AddColorPicker(pickerId, pickerOpts)
		pickerOpts = pickerOpts or {}
		pickerOpts.Text = pickerOpts.Text or opts.Text or id
		return attachColorPicker(group, slot(36), pickerId, pickerOpts)
	end

	function option:AddKeybind(keyId, keyOpts)
		keyOpts = keyOpts or {}
		return newKeybind(keyId, keyOpts, slot(84), UDim2.new(1, 0, 0.5, 0), function()
			if keyOpts.Mode == "Hold" then
				option:SetValue(true)
			else
				option:SetValue(not option.Value)
			end
		end, function()
			option:SetValue(false)
		end, {
			Label = opts.Text or id,
			GetState = function()
				return option.Value
			end,
		})
	end

	function option:SetDescription(value)
		row.SetDescription(value)
	end

	Row.MouseEnter:Connect(function()
		if not option.Value then
			tween(Label, { TextColor3 = Library.Theme.Text })
			tween(BoxEdge, { Color = Library.Theme.Muted })
		end
	end)
	Row.MouseLeave:Connect(function()
		paint(true)
	end)
	Row.MouseButton1Click:Connect(function()
		option:SetValue(not option.Value)
	end)
	attachTooltip(Row, opts.Tooltip)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddSlider(id, opts)
	local option = newOption(id, "Slider", opts)
	local min, max = opts.Min or 0, opts.Max or 100
	local rounding = opts.Rounding or 0
	local suffix = opts.Suffix or ""

	local function snap(value)
		local m = 10 ^ rounding
		return math.floor(value * m + 0.5) / m
	end
	option.Value = math.clamp(snap(opts.Default or min), min, max)

	local top = described(opts) and 36 or 20
	local Holder = self:_holder(top + 22)
	local Head = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, top),
		Parent = Holder,
	})
	local _, _, row = rowText(Head, opts, id, 1, 90)
	local Chip = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(6), stroke("BorderLight"), padding(0, 8, 0, 8) })
	local ChipScale = create("UIScale", { Scale = 1, Parent = Chip })
	local Value = text({
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		FontFace = FONT_SEMI,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = Chip,
	})
	Chip:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		row.Width(1, Chip.AbsoluteSize.X / scaleFactor() + 10)
	end)
	local Track = create("Frame", {
		Position = UDim2.fromOffset(0, top + 10),
		Size = UDim2.new(1, 0, 0, 6),
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(3), stroke("BorderLight") })
	local Fill = create("Frame", { Theme = { BackgroundColor3 = "Accent" }, Parent = Track }, {
		corner(3),
		create("UIStroke", { Thickness = 2, Transparency = 0.75, Theme = { Color = "Accent" } }),
	})
	local Knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 10),
		ZIndex = 3,
		Theme = { BackgroundColor3 = "Text" },
		Parent = Track,
	}, {
		round(),
		create("UIStroke", { Thickness = 2, Transparency = 0.35, Theme = { Color = "Accent" } }),
	})
	local Hit = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		Position = UDim2.fromOffset(0, top + 3),
		Size = UDim2.new(1, 0, 0, 19),
		Parent = Holder,
	})

	local function display(instant)
		local pct = max == min and 0 or (option.Value - min) / (max - min)
		Value.Text = string.format("%." .. rounding .. "f", option.Value) .. suffix
		if instant then
			Fill.Size = UDim2.fromScale(pct, 1)
			Knob.Position = UDim2.fromScale(pct, 0.5)
		else
			tween(Fill, { Size = UDim2.fromScale(pct, 1) }, TWEEN_FAST)
			tween(Knob, { Position = UDim2.fromScale(pct, 0.5) }, TWEEN_FAST)
		end
	end

	function option:SetValue(value)
		value = math.clamp(snap(tonumber(value) or min), min, max)
		if value == self.Value then
			return
		end
		self.Value = value
		display(false)
		self:_emit()
	end

	local dragging = false
	local function update(x)
		local pct = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		option:SetValue(min + (max - min) * pct)
	end
	local POP = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	Hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true
			tween(Knob, { Size = UDim2.fromOffset(14, 14) }, POP)
			tween(ChipScale, { Scale = 1.1 }, POP)
			update(input.Position.X)
		end
	end)
	Hit.MouseEnter:Connect(function()
		if not dragging then
			tween(Knob, { Size = UDim2.fromOffset(12, 12) })
		end
	end)
	Hit.MouseLeave:Connect(function()
		if not dragging then
			tween(Knob, { Size = UDim2.fromOffset(10, 10) })
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			update(input.Position.X)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPointer(input) and dragging then
			dragging = false
			tween(Knob, { Size = UDim2.fromOffset(10, 10) })
			tween(ChipScale, { Scale = 1 })
		end
	end)

	display(true)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddStats(stats)
	stats = stats or {}
	local Holder = self:_holder(54)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Holder,
	})
	local count = math.max(#stats, 1)
	local cells = {}
	for index, stat in ipairs(stats) do
		local Cell = create("Frame", {
			Size = UDim2.new(1 / count, -math.ceil(8 * (count - 1) / count), 1, 0),
			LayoutOrder = index,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Holder,
		}, { corner(8), stroke("Border"), padding(9, 9, 8, 9) })
		text({
			Size = UDim2.new(1, 0, 0, 12),
			FontFace = FONT_BOLD,
			TextSize = 9,
			Text = string.upper(stat.Label or stat[1] or ""),
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "Muted" },
			Parent = Cell,
		})
		local Value = text({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = FONT_BOLD,
			TextSize = 16,
			TextScaled = true,
			Text = tostring(stat.Value or stat[2] or "0"),
			KeepCase = true,
			Theme = { TextColor3 = stat.Accent and "Accent" or "Text" },
			Parent = Cell,
		})
		create("UITextSizeConstraint", { MaxTextSize = 16, MinTextSize = 9, Parent = Value })
		cells[index] = Value
		cells[stat.Label or stat[1] or index] = Value
	end
	local object = {}
	function object:Set(key, value)
		local label = cells[key]
		if label then
			label.Text = tostring(value)
		end
	end
	return object
end

function Elements:AddProgress(id, opts)
	if type(id) == "table" then
		id, opts = nil, id
	end
	opts = opts or {}
	local Holder = self:_holder(34)
	local Label = text({
		Size = UDim2.new(1, -60, 0, 18),
		FontFace = FONT_MEDIUM,
		TextSize = 13,
		Text = opts.Text or id or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Holder,
	})
	local Percent = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(60, 18),
		FontFace = FONT_SEMI,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Theme = { TextColor3 = "SubText" },
		Parent = Holder,
	})
	local Bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 6),
		Theme = { BackgroundColor3 = "Toggle" },
		Parent = Holder,
	}, { round() })
	local Fill = create("Frame", { Size = UDim2.fromScale(0, 1), Theme = { BackgroundColor3 = "Accent" }, Parent = Bar }, { round() })
	local object = { Value = 0 }
	function object:SetValue(value, instant)
		value = math.clamp(tonumber(value) or 0, 0, 1)
		self.Value = value
		Percent.Text = opts.Format and opts.Format(value) or (math.floor(value * 100 + 0.5) .. "%")
		if instant then
			Fill.Size = UDim2.fromScale(value, 1)
		else
			tween(Fill, { Size = UDim2.fromScale(value, 1) }, TWEEN_SMOOTH)
		end
	end
	function object:SetText(newText)
		Label.Text = tostring(newText or "")
	end
	object:SetValue(opts.Value or opts.Default or 0, true)
	self:_index(opts.Text or id or "Progress", Holder, Holder)
	return object
end

function Elements:AddDropdown(id, opts)
	local option = newOption(id, "Dropdown", opts)
	option.Values = opts.Values or {}
	option.Multi = opts.Multi == true

	local function resolve(value)
		if option.Multi then

			local set = {}
			if type(value) == "table" then
				for key, v in pairs(value) do
					if type(key) == "number" then
						set[v] = true
					elseif v then
						set[key] = true
					end
				end
			elseif value ~= nil then
				set[value] = true
			end
			return set
		end
		if type(value) == "number" then
			return option.Values[value]
		end
		return value
	end
	option.Value = resolve(opts.Default)

	local function isSelected(value)
		if option.Multi then
			return option.Value[value] == true
		end
		return value == option.Value
	end

	local Holder = self:_holder()
	list(8).Parent = Holder

	local Top = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, rowHeight(opts, 30)),
		LayoutOrder = 1,
		Parent = Holder,
	})
	if opts.Text then
		rowText(Top, opts, nil, 0.5, 10)
	end
	local FieldEdge = stroke("Border")
	local Field = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(opts.Text and 0.5 or 1, 0, 0, 30),
		AutoButtonColor = false,
		Text = "",
		Theme = { BackgroundColor3 = "Field" },
		Parent = Top,
	}, { corner(7), FieldEdge })
	local Selected = text({
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -36, 1, 0),
		FontFace = FONT_MEDIUM,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = false,
		Parent = Field,
	})
	local Count = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -28, 0.5, 0),
		Size = UDim2.fromOffset(18, 16),
		Visible = false,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Field,
	}, { corner(8) })
	local CountText = text({
		Size = UDim2.fromScale(1, 1),
		FontFace = FONT_BOLD,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1),
		Theme = false,
		Parent = Count,
	})
	local Chevron = icon(Field, "chevron-down", 14, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -15, 0.5, 0),
		Theme = { ImageColor3 = "SubText" },
	})

	local Popup = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Holder,
	}, { corner(10), stroke("BorderLight") })
	local PopupPop = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Popup,
	}, { padding(8), list(4) })
	local _, PopupGlow = accentLine(Popup)
	PopupGlow:Pause()

	local Head = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = PopupPop })
	text({
		Position = UDim2.fromOffset(4, 0),
		Size = UDim2.new(1, -90, 1, 0),
		FontFace = FONT_SEMI,
		Text = opts.Text or id or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Head,
	})
	text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -4, 0, 0),
		Size = UDim2.fromOffset(80, 22),
		TextSize = 11,
		Text = option.Multi and "pick any" or "pick one",
		TextXAlignment = Enum.TextXAlignment.Right,
		Theme = { TextColor3 = "Muted" },
		Parent = Head,
	})
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), LayoutOrder = 2, Theme = { BackgroundColor3 = "Border" }, Parent = PopupPop })

	local FilterEdge = stroke("BorderLight")
	local FilterField = create("Frame", {
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 3,
		Theme = { BackgroundColor3 = "Field" },
		Parent = PopupPop,
	}, { corner(7), FilterEdge })
	magnifier(FilterField).Position = UDim2.fromOffset(10, 8)
	local Filter = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(28, 0),
		Size = UDim2.new(1, -36, 1, 0),
		Text = "",
		PlaceholderText = "Search " .. tostring(opts.Text or id or ""),
		ClearTextOnFocus = false,
		FontFace = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = FilterField,
	})
	Filter.Focused:Connect(function()
		tween(FilterEdge, { Color = Library.Theme.Accent })
	end)
	Filter.FocusLost:Connect(function()
		tween(FilterEdge, { Color = Library.Theme.BorderLight })
	end)

	local ListFrame = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.3,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		LayoutOrder = 4,
		Theme = { ScrollBarImageColor3 = "Accent" },
		Parent = PopupPop,
	}, { list(2) })

	local Foot = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 5, Parent = PopupPop })
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Border" }, Parent = Foot })
	local FootCount = text({
		Position = UDim2.fromOffset(4, 3),
		Size = UDim2.new(0.5, 0, 1, -3),
		TextSize = 11,
		Theme = { TextColor3 = "Muted" },
		Parent = Foot,
	})
	local function footButton(label, x)
		local Button = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, x, 0, 4),
			Size = UDim2.fromOffset(42, 18),
			AutoButtonColor = false,
			Text = "",
			BackgroundTransparency = 1,
			Theme = { BackgroundColor3 = "Button" },
			Parent = Foot,
		}, { corner(6) })
		local Label = text({
			Size = UDim2.fromScale(1, 1),
			FontFace = FONT_SEMI,
			TextSize = 11,
			Text = label,
			TextXAlignment = Enum.TextXAlignment.Center,
			Theme = false,
			TextColor3 = Library.Theme.Muted,
			Parent = Button,
		})
		Button.MouseEnter:Connect(function()
			tween(Button, { BackgroundTransparency = 0 })
			tween(Label, { TextColor3 = Library.Theme.Accent })
		end)
		Button.MouseLeave:Connect(function()
			tween(Button, { BackgroundTransparency = 1 })
			tween(Label, { TextColor3 = Library.Theme.Muted })
		end)
		return Button
	end
	local AllButton, ClearButton
	if option.Multi then
		ClearButton = footButton("clear", 0)
		AllButton = footButton("all", -46)
	elseif opts.AllowNull then
		ClearButton = footButton("clear", 0)
	end

	local items = {}
	local open = false
	local panelId = 0

	local function picked()
		local n = 0
		if option.Multi then
			for _, value in ipairs(option.Values) do
				if option.Value[value] then
					n = n + 1
				end
			end
		elseif option.Value ~= nil then
			n = 1
		end
		return n
	end

	local function display()
		local T = Library.Theme
		local shown
		if option.Multi then
			local names = {}
			for _, value in ipairs(option.Values) do
				if option.Value[value] then
					table.insert(names, tostring(value))
				end
			end
			shown = #names > 0 and table.concat(names, ", ") or nil
			Count.Visible = #names > 1
			CountText.Text = tostring(#names)
			Count.Size = UDim2.fromOffset(#names > 9 and 24 or 18, 16)
			local shift = Count.Visible and (32 + Count.Size.X.Offset + 4) or 26
			Selected.Size = UDim2.new(1, -(shift + 10), 1, 0)
		elseif option.Value ~= nil then
			shown = tostring(option.Value)
		end
		Selected.Text = shown or opts.Placeholder or "None"
		Selected.TextColor3 = shown and T.Text or T.Muted
		FootCount.Text = picked() .. " of " .. #option.Values .. " picked"
	end

	local function paintItem(item, animated)
		local T = Library.Theme
		local on = isSelected(item.Value)
		local goals = {
			Row = { BackgroundColor3 = on and T.Accent or T.Hover, BackgroundTransparency = on and 0.86 or (item.Hot and 0 or 1) },
			Box = { BackgroundTransparency = on and 0 or 1 },
			Edge = { Color = on and T.Accent or (item.Hot and T.Muted or T.BorderLight) },
			Label = { TextColor3 = (on or item.Hot) and T.Text or T.SubText },
			Tick = { Scale = on and 1 or 0 },
		}
		item.Label.FontFace = on and FONT_SEMI or FONT
		for key, goal in pairs(goals) do
			if animated then
				tween(item[key], goal, key == "Tick" and TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out) or TWEEN)
			else
				for property, value in pairs(goal) do
					item[key][property] = value
				end
			end
		end
	end

	local function paintItems(animated)
		for _, item in ipairs(items) do
			paintItem(item, animated)
		end
	end

	local setOpen

	local function rebuild()
		for _, item in ipairs(items) do
			item.Row:Destroy()
		end
		items = {}
		if ListFrame:FindFirstChild("Empty") then
			ListFrame.Empty:Destroy()
		end
		local query = Filter.Text:lower()
		for index, value in ipairs(option.Values) do
			local label = tostring(value)
			if query == "" or label:lower():find(query, 1, true) then
				local Row = create("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					AutoButtonColor = false,
					Text = "",
					LayoutOrder = index,
					Parent = ListFrame,
				}, { corner(7) })
				local Edge = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 })
				local Box = create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 8, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 1,
					Theme = { BackgroundColor3 = "Accent" },
					Parent = Row,
				}, { corner(4), Edge })
				local Tick = tickMark(Box)
				local Label = text({
					Position = UDim2.fromOffset(30, 0),
					Size = UDim2.new(1, -38, 1, 0),
					Text = label,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Theme = false,
					Parent = Row,
				})
				local item = { Row = Row, Box = Box, Edge = Edge, Label = Label, Tick = Tick, Value = value, Hot = false }
				Row.MouseEnter:Connect(function()
					item.Hot = true
					paintItem(item, true)
				end)
				Row.MouseLeave:Connect(function()
					item.Hot = false
					paintItem(item, true)
				end)
				Row.MouseButton1Click:Connect(function()
					if option.Multi then
						local set = table.clone(option.Value)
						set[value] = (not set[value]) or nil
						option:SetValue(set)
					elseif opts.AllowNull and option.Value == value then
						option:SetValue(nil)
					else
						option:SetValue(value)
					end
				end)
				table.insert(items, item)
				paintItem(item, false)
			end
		end
		if #items == 0 then
			text({
				Name = "Empty",
				Size = UDim2.new(1, 0, 0, 26),
				TextSize = 12,
				Text = query ~= "" and "No matches" or "Nothing to pick",
				TextXAlignment = Enum.TextXAlignment.Center,
				Theme = { TextColor3 = "Muted" },
				Parent = ListFrame,
			})
		end
		local rows = math.clamp(#items, 1, opts.MaxVisible or 7)
		ListFrame.Size = UDim2.new(1, 0, 0, rows * 28 - 2)
		if open then
			tween(Popup, { Size = UDim2.new(1, 0, 0, 107 + ListFrame.Size.Y.Offset) }, TWEEN_SMOOTH)
		end
	end

	setOpen = function(state)
		if state == open then
			return
		end
		open = state
		panelId = panelId + 1
		local id = panelId
		tween(Chevron, { Rotation = state and 180 or 0 }, TWEEN_SMOOTH)
		tween(FieldEdge, { Color = state and Library.Theme.Accent or Library.Theme.Border })
		if state then
			if not Popup.Visible then
				Popup.Size = UDim2.new(1, 0, 0, 0)
				Popup.Visible = true
			end
			rebuild()
			PopupGlow:Play()
		else
			if Filter:IsFocused() then
				Filter:ReleaseFocus()
			end
			PopupGlow:Pause()
			tween(Popup, { Size = UDim2.new(1, 0, 0, 0) }, POP_OUT).Completed:Connect(function()
				if id == panelId then
					Popup.Visible = false
					Filter.Text = ""
				end
			end)
		end
	end

	Field.MouseButton1Click:Connect(function()
		setOpen(not open)
	end)
	Field.MouseEnter:Connect(function()
		if not open then
			tween(FieldEdge, { Color = Library.Theme.Muted })
		end
	end)
	Field.MouseLeave:Connect(function()
		if not open then
			tween(FieldEdge, { Color = Library.Theme.Border })
		end
	end)
	Filter:GetPropertyChangedSignal("Text"):Connect(function()
		if open then
			rebuild()
		end
	end)
	if AllButton then
		AllButton.MouseButton1Click:Connect(function()
			local set = {}
			for _, value in ipairs(option.Values) do
				set[value] = true
			end
			option:SetValue(set)
		end)
	end
	if ClearButton then
		ClearButton.MouseButton1Click:Connect(function()
			option:SetValue(option.Multi and {} or nil)
		end)
	end
	local function sameSet(a, b)
		for key in pairs(a) do
			if not b[key] then
				return false
			end
		end
		for key in pairs(b) do
			if not a[key] then
				return false
			end
		end
		return true
	end

	function option:SetValue(value)
		value = resolve(value)
		if self.Multi and sameSet(value, self.Value) or not self.Multi and value == self.Value then
			return
		end
		self.Value = value
		display()
		paintItems(true)
		self:_emit()
	end

	function option:SetValues(values)
		self.Values = values or {}
		if self.Multi then
			local kept, dropped = {}, false
			for value in pairs(self.Value) do
				if table.find(self.Values, value) then
					kept[value] = true
				else
					dropped = true
				end
			end
			if dropped then
				self.Value = kept
			end
		elseif self.Value ~= nil and not table.find(self.Values, self.Value) then
			self.Value = nil
		end
		display()
		if open then
			rebuild()
		end
	end

	table.insert(ThemeCallbacks, function()
		display()
		paintItems(false)
		FieldEdge.Color = open and Library.Theme.Accent or Library.Theme.Border
	end)
	display()
	attachTooltip(Field, opts.Tooltip)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddInput(id, opts)
	local option = newOption(id, "Input", opts)
	option.Value = tostring(opts.Default or "")

	local titled = opts.Text ~= nil
	local Holder = self:_holder(titled and rowHeight(opts, 30) or 30)
	if titled then
		rowText(Holder, opts, nil, 0.5, 10)
	end
	local Edge = stroke("Border")
	local Frame = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(titled and 0.5 or 1, 0, 0, 30),
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(7), Edge })
	local Box = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = option.Value,
		PlaceholderText = opts.Placeholder or "",
		ClearTextOnFocus = opts.ClearTextOnFocus == true,
		ClipsDescendants = true,
		FontFace = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = Frame,
	})

	function option:SetValue(value)
		value = tostring(value or "")
		if opts.Numeric and value ~= "" and not tonumber(value) then
			Box.Text = self.Value
			return
		end
		Box.Text = value
		if value == self.Value then
			return
		end
		self.Value = value
		self:_emit()
	end

	local focused = false
	table.insert(ThemeCallbacks, function()
		Edge.Color = focused and Library.Theme.Accent or Library.Theme.Border
	end)
	Frame.MouseEnter:Connect(function()
		if not focused then
			tween(Edge, { Color = Library.Theme.Muted })
		end
	end)
	Frame.MouseLeave:Connect(function()
		if not focused then
			tween(Edge, { Color = Library.Theme.Border })
		end
	end)
	Box.Focused:Connect(function()
		focused = true
		tween(Edge, { Color = Library.Theme.Accent })
	end)
	Box.FocusLost:Connect(function()
		focused = false
		tween(Edge, { Color = Library.Theme.Border })
		if opts.Finished then
			option:SetValue(Box.Text)
		end
	end)
	if not opts.Finished then
		Box:GetPropertyChangedSignal("Text"):Connect(function()
			option:SetValue(Box.Text)
		end)
	end
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddKeybind(id, opts)
	local Holder = self:_holder(rowHeight(opts))
	rowText(Holder, opts, id, 1, 100)
	self:_index(opts.Text or id, Holder, Holder)
	return newKeybind(id, opts, Holder, UDim2.new(1, 0, 0.5, 0))
end

function Elements:AddESPPreview(opts)
	opts = opts or {}
	local tabNames = opts.Tabs or { "Enemy", "Team" }
	local height = opts.Height or 250
	local userId = tonumber(opts.UserId) or (LocalPlayer.UserId > 0 and LocalPlayer.UserId) or 1
	local Holder = self:_holder(height + 34)

	local Switch = create("Frame", {
		Size = UDim2.fromOffset(0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(8), stroke("BorderLight"), padding(3), list(3, true) })

	local Canvas = create("Frame", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, height),
		ClipsDescendants = true,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Holder,
	}, { corner(10), stroke("BorderLight") })
	for i = 1, 11 do
		create("Frame", {
			Position = UDim2.fromScale(i / 12, 0),
			Size = UDim2.new(0, 1, 1, 0),
			BackgroundTransparency = 0.55,
			Theme = { BackgroundColor3 = "Border" },
			Parent = Canvas,
		})
	end
	for i = 1, 7 do
		create("Frame", {
			Position = UDim2.fromScale(0, i / 8),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundTransparency = 0.55,
			Theme = { BackgroundColor3 = "Border" },
			Parent = Canvas,
		})
	end

	local GlowView = create("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.new(1, 1, 1),
		LightColor = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = Canvas,
	})
	local GlowWorld = create("WorldModel", { Parent = GlowView })
	local GlowCamera = create("Camera", { FieldOfView = 34, Parent = GlowView })
	GlowView.CurrentCamera = GlowCamera
	local View = create("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-0.5, -1, -0.8),
		ZIndex = 3,
		Parent = Canvas,
	})
	local World = create("WorldModel", { Parent = View })
	local Camera = create("Camera", { FieldOfView = 34, Parent = View })
	View.CurrentCamera = Camera

	local dummy
	local glowParts = {}
	local yaw, distance = math.rad(20), 8.5
	local glowOn, glowColor = true, Color3.fromRGB(255, 0, 0)

	local function applyGlow()
		for _, glow in ipairs(glowParts) do
			glow.Part.Transparency = glowOn and 0 or 1
			glow.Part.Color = glowColor
		end
	end

	local function buildGlow(model)
		for _, glow in ipairs(glowParts) do
			pcall(function()
				glow.Part:Destroy()
			end)
		end
		glowParts = {}
		local pad = opts.OutlineThickness or 0.035
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 then
				local shell
				local mesh = part:FindFirstChildOfClass("SpecialMesh")
				if part:IsA("MeshPart") then
					shell = part:Clone()
					for _, child in ipairs(shell:GetChildren()) do
						child:Destroy()
					end
					shell.TextureID = ""
				elseif mesh then
					shell = part:Clone()
					for _, child in ipairs(shell:GetChildren()) do
						if not child:IsA("SpecialMesh") then
							child:Destroy()
						end
					end
					local copy = shell:FindFirstChildOfClass("SpecialMesh")
					if copy then
						copy.TextureId = ""
					end
				else
					shell = Instance.new("Part")
					shell.Shape = part:IsA("Part") and part.Shape or Enum.PartType.Block
				end
				shell.Name = "Glow"
				shell.Anchored = true
				shell.CanCollide = false
				shell.CastShadow = false
				shell.Material = Enum.Material.Neon
				shell.Color = glowColor
				local copy = shell:FindFirstChildOfClass("SpecialMesh")
				if copy and copy.MeshType == Enum.MeshType.FileMesh then
					copy.Scale = copy.Scale * (1 + pad / math.max(part.Size.Y, 0.5))
					shell.Size = part.Size
				else
					shell.Size = part.Size + Vector3.new(pad, pad, pad)
				end
				shell.Parent = GlowWorld
				table.insert(glowParts, { Part = shell, Source = part })
			end
		end
		applyGlow()
	end

	local loadId = 0
	local function loadUser(id)
		loadId = loadId + 1
		local mine = loadId
		task.spawn(function()
			local ok, model = pcall(function()
				return Players:CreateHumanoidModelFromUserId(id)
			end)
			if not ok or not model then
				ok, model = pcall(function()
					return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
				end)
				if not ok then
					model = nil
				end
			end
			if not model or mine ~= loadId or Library.Unloaded then
				return
			end
			if dummy then
				pcall(function()
					dummy:Destroy()
				end)
			end
			for _, item in ipairs(model:GetDescendants()) do
				if item:IsA("Script") or item:IsA("LocalScript") then
					item:Destroy()
				end
			end
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			model:PivotTo(CFrame.new(0, 0, 0))
			model.Parent = World
			dummy = model
			buildGlow(model)
			pcall(function()
				if not humanoid then
					return
				end
				local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
				local animation = Instance.new("Animation")
				animation.AnimationId = humanoid.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180435571" or "rbxassetid://507766666"
				local track = animator:LoadAnimation(animation)
				track.Looped = true
				track:Play()
			end)
		end)
	end
	loadUser(userId)

	local spinning, lastX = false, 0
	local Sink = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		CanvasSize = UDim2.fromScale(0, 3),
		CanvasPosition = Vector2.new(0, 1),
		Active = true,
		ZIndex = 5,
		Parent = Canvas,
	})
	Sink.InputBegan:Connect(function(input)
		if isPointer(input) then
			spinning, lastX = true, input.Position.X
		end
	end)
	Sink.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z, 4, 16)
		end
	end)
	Sink:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local middle = math.max(0, (Sink.AbsoluteCanvasSize.Y - Sink.AbsoluteSize.Y) * 0.5)
		if math.abs(Sink.CanvasPosition.Y - middle) > 0.5 then
			Sink.CanvasPosition = Vector2.new(0, middle)
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if spinning and isMove(input) then
			yaw = yaw + (input.Position.X - lastX) * 0.012
			lastX = input.Position.X
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPointer(input) then
			spinning = false
		end
	end)

	local function smallButton(parent, position, size)
		local Button = create("TextButton", {
			Position = position,
			Size = size,
			AutoButtonColor = false,
			FontFace = FONT_BOLD,
			TextSize = 14,
			Text = "",
			BackgroundTransparency = 0.15,
			ZIndex = 8,
			Theme = { BackgroundColor3 = "Background", TextColor3 = "SubText" },
			Parent = parent,
		}, { corner(7), stroke("BorderLight") })
		pressScale(Button)
		Button.MouseEnter:Connect(function()
			tween(Button, { TextColor3 = Library.Theme.Text, BackgroundColor3 = Library.Theme.Hover })
		end)
		Button.MouseLeave:Connect(function()
			tween(Button, { TextColor3 = Library.Theme.SubText, BackgroundColor3 = Library.Theme.Background })
		end)
		return Button
	end
	for index, spec in ipairs({ { "+", -1.5 }, { "-", 1.5 } }) do
		local Zoom = smallButton(Canvas, UDim2.new(1, -32, 1, -60 + (index - 1) * 26), UDim2.fromOffset(22, 22))
		Zoom.Text = spec[1]
		Zoom.MouseButton1Click:Connect(function()
			distance = math.clamp(distance + spec[2], 4, 16)
		end)
	end
	text({
		Position = UDim2.new(0, 10, 1, -20),
		Size = UDim2.fromOffset(220, 14),
		TextSize = 11,
		Text = "Drag to rotate · scroll to zoom",
		ZIndex = 8,
		Theme = { TextColor3 = "Muted" },
		Parent = Canvas,
	})

	local preview = { Frame = Holder, Canvas = Canvas, Tabs = {}, Active = nil, Changed = {} }
	function preview:OnTabChanged(fn)
		table.insert(self.Changed, fn)
	end
	local Probe = create("Frame", { Size = UDim2.fromOffset(100, 100), BackgroundTransparency = 1, Parent = Canvas })

	local function project(point)
		local relative = Camera.CFrame:PointToObjectSpace(point)
		if relative.Z > -0.05 then
			return nil
		end
		local size = Canvas.AbsoluteSize
		if size.X < 1 or size.Y < 1 then
			return nil
		end
		local tanHalf = math.tan(math.rad(Camera.FieldOfView) * 0.5)
		local px = (relative.X / -relative.Z) / (tanHalf * (size.X / size.Y))
		local py = (relative.Y / -relative.Z) / tanHalf
		local scale = Probe.AbsoluteSize.X / 100
		return Vector2.new((px * 0.5 + 0.5) * size.X, (0.5 - py * 0.5) * size.Y), scale
	end

	local function espLabel(parent, size, position, textSize, color)
		return text({
			Position = position,
			Size = size,
			FontFace = FONT_SEMI,
			TextSize = textSize,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = color,
			TextStrokeTransparency = 0.2,
			Theme = false,
			ZIndex = 7,
			Parent = parent,
		})
	end

	for index, name in ipairs(tabNames) do
		local Page = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 6, Parent = Canvas })
		local Card = create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(160, 36), BackgroundTransparency = 1, ZIndex = 6, Parent = Page })
		local NameLabel = espLabel(Card, UDim2.new(1, 0, 0, 14), UDim2.new(), 13, Color3.new(1, 1, 1))
		NameLabel.Text = LocalPlayer.DisplayName
		local DistanceLabel = espLabel(Card, UDim2.new(1, 0, 0, 12), UDim2.fromOffset(0, 14), 11, Color3.fromRGB(220, 220, 220))
		DistanceLabel.Text = "[42m] 180/250"
		local HealthBack = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 28),
			Size = UDim2.fromOffset(60, 4),
			BackgroundColor3 = Color3.new(0, 0, 0),
			ZIndex = 7,
			Parent = Card,
		}, { corner(2) })
		local Health = create("Frame", {
			Size = UDim2.fromScale(0.72, 1),
			BackgroundColor3 = Color3.fromRGB(71, 255, 0),
			ZIndex = 8,
			Parent = HealthBack,
		}, { corner(2) })
		local Tracer = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromOffset(1, 60),
			BackgroundColor3 = Color3.fromRGB(255, 0, 0),
			Visible = false,
			ZIndex = 6,
			Parent = Page,
		})

		local tab = {
			Name = name,
			Page = Page,
			Colour = Color3.fromRGB(255, 0, 0),
			Parts = { Name = NameLabel, Distance = DistanceLabel, HealthBg = HealthBack, Health = Health, Tracer = Tracer, Card = Card },
			_show = { Name = true, Distance = true, HealthBg = true, Tracer = false, Outline = true },
		}

		function tab:_layout()
			if not dummy then
				return
			end
			local ok, box, extent = pcall(function()
				return dummy:GetBoundingBox()
			end)
			if not ok then
				return
			end
			local top, scale = project(box.Position + Vector3.new(0, extent.Y * 0.5 + 0.4, 0))
			local bottom = project(box.Position - Vector3.new(0, extent.Y * 0.5, 0))
			if not top then
				return
			end
			scale = scale > 0 and scale or 1
			Card.Position = UDim2.fromOffset(math.floor(top.X / scale + 0.5), math.floor(top.Y / scale + 0.5))
			local y = 36
			local rows = {}
			if self._show.HealthBg then
				table.insert(rows, { HealthBack, 4 })
			end
			if self._show.Distance then
				table.insert(rows, { DistanceLabel, 12 })
			end
			if self._show.Name then
				table.insert(rows, { NameLabel, 14 })
			end
			for _, row in ipairs(rows) do
				y = y - row[2]
				row[1].Position = UDim2.new(row[1] == HealthBack and 0.5 or 0, 0, 0, y)
				y = y - 2
			end
			if bottom then
				local size = Canvas.AbsoluteSize
				local originX, originY = size.X * 0.5, size.Y
				local dx, dy = bottom.X - originX, bottom.Y - originY
				Tracer.Position = UDim2.fromOffset(math.floor(originX / scale), math.floor(originY / scale))
				Tracer.Size = UDim2.fromOffset(1, math.floor(math.sqrt(dx * dx + dy * dy) / scale + 0.5))
				Tracer.Rotation = -math.deg(math.atan2(dx, -dy))
			end
		end

		function tab:SetColour(color)
			self.Colour = color
			Tracer.BackgroundColor3 = color
			if preview.Active == self then
				glowColor = color
				applyGlow()
			end
		end
		tab.SetColor = tab.SetColour

		function tab:SetOutline(on)
			self._show.Outline = on and true or false
			if preview.Active == self then
				glowOn = self._show.Outline
				applyGlow()
			end
		end

		function tab:SetText(which, value)
			local part = self.Parts[which]
			if part and part:IsA("TextLabel") then
				part.Text = value
			end
		end

		function tab:SetHealth(fraction)
			fraction = math.clamp(fraction or 1, 0, 1)
			Health.Size = UDim2.fromScale(fraction, 1)
			Health.BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - fraction)), math.floor(255 * fraction), 0)
		end

		function tab:Set(settings)
			for key, value in pairs(settings) do
				if typeof(value) == "boolean" then
					if key == "Box" or key == "Outline" or key == "Highlight" then
						self:SetOutline(value)
					elseif self.Parts[key] then
						self.Parts[key].Visible = value
						self._show[key] = value
						if key == "HealthBg" then
							self._show.HealthBg = value
						end
					end
				elseif typeof(value) == "Color3" then
					if key == "Box" or key == "Outline" or key == "Highlight" or key == "Colour" or key == "Color" then
						self:SetColour(value)
					elseif key == "Name" then
						NameLabel.TextColor3 = value
					elseif key == "Distance" then
						DistanceLabel.TextColor3 = value
					elseif key == "Tracer" then
						Tracer.BackgroundColor3 = value
					end
				end
			end
		end

		function tab:SetBoxStyle() end

		local Button = create("TextButton", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			AutoButtonColor = false,
			Text = "",
			BackgroundTransparency = 1,
			LayoutOrder = index,
			Theme = { BackgroundColor3 = "Button" },
			Parent = Switch,
		}, { corner(6), padding(0, 10, 0, 10) })
		local ButtonLabel = text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromScale(0, 1),
			FontFace = FONT_SEMI,
			TextSize = 12,
			Text = name,
			Theme = false,
			TextColor3 = Library.Theme.SubText,
			Parent = Button,
		})
		tab._label, tab._button = ButtonLabel, Button

		function tab:Select()
			for _, other in ipairs(preview.Tabs) do
				other.Page.Visible = false
				tween(other._label, { TextColor3 = Library.Theme.SubText })
				tween(other._button, { BackgroundTransparency = 1 })
			end
			self.Page.Visible = true
			tween(self._label, { TextColor3 = Library.Theme.Accent })
			tween(self._button, { BackgroundTransparency = 0 })
			local changed = preview.Active ~= self
			preview.Active = self
			glowOn, glowColor = self._show.Outline, self.Colour
			applyGlow()
			if changed then
				for _, fn in ipairs(preview.Changed) do
					fire(fn, self.Name, self)
				end
			end
		end

		Button.MouseEnter:Connect(function()
			if preview.Active ~= tab then
				tween(ButtonLabel, { TextColor3 = Library.Theme.Text })
			end
		end)
		Button.MouseLeave:Connect(function()
			if preview.Active ~= tab then
				tween(ButtonLabel, { TextColor3 = Library.Theme.SubText })
			end
		end)
		Button.MouseButton1Click:Connect(function()
			tab:Select()
		end)
		table.insert(preview.Tabs, tab)
	end

	table.insert(ThemeCallbacks, function()
		for _, tab in ipairs(preview.Tabs) do
			tab._label.TextColor3 = preview.Active == tab and Library.Theme.Accent or Library.Theme.SubText
		end
	end)

	local function shown()
		local node = Canvas
		while node and node:IsA("GuiObject") do
			if not node.Visible then
				return false
			end
			node = node.Parent
		end
		return node ~= nil
	end

	connect(RunService.RenderStepped, function()
		if not shown() then
			return
		end
		if dummy then
			local ok, box = pcall(function()
				return dummy:GetBoundingBox()
			end)
			local pivot = ok and box.Position or Vector3.new()
			Camera.CFrame = CFrame.new(pivot + Vector3.new(math.sin(yaw) * distance, distance * 0.1, math.cos(yaw) * distance), pivot)
			GlowCamera.CFrame = Camera.CFrame
			for _, glow in ipairs(glowParts) do
				if glow.Source.Parent then
					glow.Part.CFrame = glow.Source.CFrame
				end
			end
		end
		for _, tab in ipairs(preview.Tabs) do
			if tab.Page.Visible then
				tab:_layout()
			end
		end
	end)

	local PopButton = smallButton(Canvas, UDim2.new(1, -32, 0, 8), UDim2.fromOffset(22, 22))
	create("Frame", {
		Position = UDim2.fromOffset(5, 8),
		Size = UDim2.fromOffset(9, 7),
		BackgroundTransparency = 1,
		ZIndex = 9,
		Parent = PopButton,
	}, { corner(2), create("UIStroke", { Thickness = 1, Theme = { Color = "SubText" } }) })
	create("Frame", {
		Position = UDim2.fromOffset(8, 5),
		Size = UDim2.fromOffset(9, 7),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = PopButton,
	}, { corner(2), create("UIStroke", { Thickness = 1, Theme = { Color = "Accent" } }) })

	local floating
	PopButton.MouseButton1Click:Connect(function()
		if floating then
			Canvas.Parent = Holder
			Canvas.Position = UDim2.fromOffset(0, 34)
			Canvas.Size = UDim2.new(1, 0, 0, height)
			local index = table.find(PopupScales, floating.Scale)
			if index then
				table.remove(PopupScales, index)
			end
			floating.Release()
			floating.Glow:Cancel()
			floating.Frame:Destroy()
			floating = nil
			return
		end
		local Float = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(380, 360),
			Active = true,
			Visible = false,
			Theme = { BackgroundColor3 = "Background" },
			Parent = Library.PopupLayer,
		}, { corner(12), stroke("BorderLight") })
		local FloatScale = create("UIScale", { Scale = Library.UserScale, Parent = Float })
		table.insert(PopupScales, FloatScale)
		local _, glow = accentLine(Float)
		text({
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 0, 34),
			FontFace = FONT_SEMI,
			Text = opts.Title or "ESP preview",
			Parent = Float,
		})
		local release = dragBy(Float, function(input)
			return input.Position.Y - Float.AbsolutePosition.Y <= 34 * FloatScale.Scale
		end)
		Canvas.Parent = Float
		Canvas.Position = UDim2.fromOffset(10, 36)
		Canvas.Size = UDim2.new(1, -20, 1, -46)
		floating = { Frame = Float, Scale = FloatScale, Glow = glow, Release = release }
		popout(Float, true)
	end)

	function preview:GetTab(name)
		for _, tab in ipairs(self.Tabs) do
			if tab.Name == name then
				return tab
			end
		end
	end
	function preview:Set(name, settings)
		local tab = self:GetTab(name)
		if tab then
			tab:Set(settings)
		end
	end
	function preview:SetUser(id)
		loadUser(tonumber(id) or userId)
	end
	if preview.Tabs[1] then
		preview.Tabs[1]:Select()
	end
	self:_index(opts.Text or "ESP preview", Holder, Holder)
	return preview
end

local function newGroupbox(tab, column, title)
	local Outer = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = #column:GetChildren(),
		Theme = { BackgroundColor3 = "Panel" },
		Parent = column,
	}, { corner(10), stroke("Border"), padding(13, 16, 6, 16), list(4) })
	local Header = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = 1,
		Parent = Outer,
	})
	create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(6, 6),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Header,
	}, { round() })
	local Title = text({
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -14, 1, 0),
		FontFace = FONT_BOLD,
		TextSize = 14,
		Text = title or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = Header,
	})
	local Content = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = Outer,
	}, { list(0) })

	local group = setmetatable({ Container = Content, Order = 0, Rows = 0, Tab = tab, Column = column, Title = title or "", Frame = Outer }, Elements)
	function group.Expand() end
	function group:SetTitle(value)
		self.Title = tostring(value or "")
		Title.Text = self.Title
	end
	return group
end

local function buildKeybindPanel(ScreenGui)
	local Panel = create("Frame", {
		Position = UDim2.new(0, 16, 0.38, 0),
		Size = UDim2.fromOffset(220, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = ScreenGui,
	}, { corner(10), stroke("Border") })
	Library.PanelScale = create("UIScale", { Scale = Library.UserScale, Parent = Panel })
	Library.KeybindPanel = Panel
	local Head = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
		Parent = Panel,
	})
	local Badge = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 0.88,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Head,
	}, { corner(6) })
	icon(Badge, "keyboard", 13, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Theme = { ImageColor3 = "Accent" },
	})
	text({
		Position = UDim2.fromOffset(42, 0),
		Size = UDim2.new(1, -96, 1, 0),
		FontFace = FONT_BOLD,
		TextSize = 13,
		Text = "Keybinds",
		Parent = Head,
	})
	local CountChip = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Head,
	}, { corner(5), stroke("Border"), padding(0, 7, 0, 7) })
	local Count = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		FontFace = FONT_SEMI,
		TextSize = 11,
		Theme = { TextColor3 = "SubText" },
		Parent = CountChip,
	})
	create("Frame", { Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Border" }, Parent = Panel })
	local Rows = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 39),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Panel,
	}, { list(2), padding(6, 6, 7, 6) })

	dragBy(Panel, function(input)
		return input.Position.Y - Panel.AbsolutePosition.Y <= 38 * Library.PanelScale.Scale
	end)

	local MODE_SHORT = { Toggle = "toggle", Hold = "hold", Press = "press" }
	local rows = {}
	function Library._renderKeybinds()
		for _, row in ipairs(rows) do
			row:Destroy()
		end
		rows = {}
		local T = Library.Theme
		local on = 0
		for index, entry in ipairs(KeybindEntries) do
			if not entry.Hidden and entry.Option.Value then
				local active = entry.GetState() == true
				if active then
					on = on + 1
				end
				local Row = create("Frame", {
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = index,
					BackgroundColor3 = T.Accent,
					BackgroundTransparency = active and 0.9 or 1,
					Parent = Rows,
				}, { corner(6) })
				text({
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -100, 1, 0),
					FontFace = FONT_MEDIUM,
					TextSize = 12,
					Text = entry.Label,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextColor3 = active and T.Text or T.SubText,
					Theme = false,
					Parent = Row,
				})
				local Right = create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					Parent = Row,
				}, { list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
				text({
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 18),
					TextSize = 11,
					Text = MODE_SHORT[entry.Option.Mode] or "",
					LayoutOrder = 1,
					TextColor3 = T.Muted,
					Theme = false,
					Parent = Right,
				})
				local Chip = create("Frame", {
					Size = UDim2.fromOffset(0, 18),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 2,
					BackgroundColor3 = T.Field,
					Parent = Right,
				}, {
					corner(5),
					create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 1,
						Color = active and T.Accent or T.Border,
						Transparency = active and 0.4 or 0,
					}),
					padding(0, 7, 0, 7),
				})
				text({
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 18),
					FontFace = FONT_SEMI,
					TextSize = 11,
					Text = keyName(entry.Option.Value),
					TextColor3 = active and T.Accent or T.SubText,
					Theme = false,
					Parent = Chip,
				})
				table.insert(rows, Row)
			end
		end
		Count.Text = on .. " / " .. #rows
		popout(Panel, Library.KeybindListEnabled and #rows > 0)
	end
	table.insert(ThemeCallbacks, refreshKeybinds)
	refreshKeybinds()
end

function Library:SetKeybindList(enabled)
	self.KeybindListEnabled = enabled
	refreshKeybinds()
end

local function buildWatermark(ScreenGui)
	local Bar = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = Library.WatermarkEnabled,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = ScreenGui,
	}, { corner(10), stroke("Border"), list(0, true, { VerticalAlignment = Enum.VerticalAlignment.Center }), padding(0, 6, 0, 6) })
	Library.WatermarkScale = create("UIScale", { Scale = Library.UserScale, Parent = Bar })
	Library.Watermark = Bar

	local order = 0
	local function segment()
		order = order + 1
		return create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 34),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order,
			Parent = Bar,
		}, { list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center }), padding(0, 8, 0, 8) })
	end
	local function stat(iconName, themeKey)
		local Segment = segment()
		icon(Segment, iconName, 13, { LayoutOrder = 1, Theme = { ImageColor3 = "Muted" } })
		return text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			FontFace = FONT_SEMI,
			TextSize = 12,
			LayoutOrder = 2,
			KeepCase = true,
			Theme = { TextColor3 = themeKey or "SubText" },
			Parent = Segment,
		})
	end

	local Brand = segment()
	local Mark = create("Frame", {
		Size = UDim2.fromOffset(20, 20),
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Parent = Brand,
	})
	local MarkLetter = text({
		Size = UDim2.fromScale(1, 1),
		FontFace = FONT_BOLD,
		TextSize = 15,
		Text = "d",
		TextXAlignment = Enum.TextXAlignment.Center,
		Theme = { TextColor3 = "Accent" },
		Parent = Mark,
	})
	buildIcon(Mark, 20, MarkLetter)
	text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 16),
		FontFace = FONT_BOLD,
		TextSize = 13,
		Text = Library.Title or "Dexori",
		LayoutOrder = 2,
		KeepCase = true,
		Parent = Brand,
	})
	stat("user", "Text").Text = LocalPlayer.DisplayName
	local FpsValue = stat("activity")
	local PingValue = stat("wifi")
	local PlayerValue = stat("users")

	dragBy(Bar)

	local lastFps, lastPing = 0, 0
	local function paint(fps, ping)
		lastFps, lastPing = fps or lastFps, ping or lastPing
		FpsValue.Text = lastFps .. " fps"
		PingValue.Text = lastPing .. " ms"
		local count = #Players:GetPlayers()
		PlayerValue.Text = count .. (count == 1 and " player" or " players")
	end
	paint(0, 0)
	Library._paintWatermark = paint
end

function Library:SetWatermark(enabled)
	self.WatermarkEnabled = enabled
	if self.Watermark then
		popout(self.Watermark, enabled)
	end
end

local ACCENT_SHEEN = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.new(0.55, 0.3, 0.3)),
	ColorSequenceKeypoint.new(0.4, Color3.new(0.95, 0.86, 0.86)),
	ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(0.6, Color3.new(0.95, 0.86, 0.86)),
	ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.26, 0.27)),
})
local ACCENT_SWAY = TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local sheenStarted = false
local function startSheen()
	if sheenStarted then
		return
	end
	sheenStarted = true
	local sheens = setmetatable({}, { __mode = "k" })
	local otherGradient = setmetatable({}, { __mode = "k" })
	local function near(a, b)
		return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.035
	end
	local function uses(inst, accent)
		if inst:IsA("UIStroke") then
			return inst.Enabled and inst.Transparency < 1 and near(inst.Color, accent)
		end
		if inst.BackgroundTransparency < 1 and near(inst.BackgroundColor3, accent) then
			return true
		end
		if (inst:IsA("TextLabel") or inst:IsA("TextButton")) and inst.TextTransparency < 1 and near(inst.TextColor3, accent) then
			return true
		end
		if (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) and inst.ImageTransparency < 1 and near(inst.ImageColor3, accent) then
			return true
		end
		return false
	end
	local function removeSheen(inst)
		local entry = sheens[inst]
		if entry then
			sheens[inst] = nil
			entry.tween:Cancel()
			entry.gradient:Destroy()
		end
	end
	local function addSheen(inst)
		local base = 45
		if inst:IsA("GuiObject") then
			local size = inst.AbsoluteSize
			base = size.X > size.Y * 4 and 0 or 90
		end
		local gradient = Instance.new("UIGradient")
		gradient.Name = "DexoriSheen"
		gradient.Color = ACCENT_SHEEN
		gradient.Rotation = base - 14
		gradient.Parent = inst
		local sway = TweenService:Create(gradient, ACCENT_SWAY, { Rotation = base + 14 })
		sway:Play()
		sheens[inst] = { gradient = gradient, tween = sway }
	end
	local function process(inst, accent, blocked)
		local has = sheens[inst]
		if not has then
			local other = otherGradient[inst]
			if other == nil then
				other = inst:FindFirstChildOfClass("UIGradient") ~= nil
				otherGradient[inst] = other
			end
			if other then
				return
			end
		end
		if not blocked and uses(inst, accent) then
			if not has then
				addSheen(inst)
			end
		elseif has then
			removeSheen(inst)
		end
	end
	local function roots()
		local list = {}
		local main = Library.ScreenGui
		if main then
			table.insert(list, main)
			local holder = main.Parent
			for _, child in ipairs(holder and holder:GetChildren() or {}) do
				if child ~= main and child:IsA("ScreenGui") and child.Name:sub(1, 6) == "Dexori" and not Library.SheenSkip[child.Name] then
					table.insert(list, child)
				end
			end
		end
		return list
	end
	local queue, index, skipped, nextCycle = {}, 1, {}, 0
	local function refill()
		queue, index, skipped = {}, 1, {}
		for _, root in ipairs(roots()) do
			for _, inst in ipairs(root:GetDescendants()) do
				if Library.SheenSkip[inst.Name] and inst:IsA("GuiObject") then
					table.insert(skipped, inst)
				end
				if inst:IsA("GuiObject") or inst:IsA("UIStroke") then
					table.insert(queue, inst)
				end
			end
		end
	end
	local function blockedBy(inst)
		for _, panel in ipairs(skipped) do
			if inst == panel or inst:IsDescendantOf(panel) then
				return true
			end
		end
		return false
	end
	connect(RunService.Heartbeat, function()
		if Library.Unloaded then
			return
		end
		if index > #queue then
			local now = os.clock()
			if now < nextCycle then
				return
			end
			nextCycle = now + 1.5
			refill()
		end
		local accent = Library.Theme.Accent
		local started = os.clock()
		while index <= #queue and os.clock() - started < 0.0015 do
			local inst = queue[index]
			index = index + 1
			if inst.Parent then
				pcall(process, inst, accent, #skipped > 0 and blockedBy(inst))
			end
		end
	end)
end
Library.SheenSkip = { DexoriEspText = true, EspPreview = true }
Library.GoldSkip = Library.SheenSkip

local function headerButton(parent, iconName, position)
	local Edge = stroke("Border")
	local Button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = position,
		Size = UDim2.fromOffset(30, 30),
		AutoButtonColor = false,
		Text = "",
		Theme = { BackgroundColor3 = "Panel" },
		Parent = parent,
	}, { corner(8), Edge })
	pressScale(Button)
	local Glyph = icon(Button, iconName, 14, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
	})
	local hot = false
	local danger = false
	local function paint()
		local T = Library.Theme
		local lit = hot or danger
		tween(Glyph, { ImageColor3 = danger and T.Accent or (hot and T.Text or T.SubText) })
		tween(Edge, { Color = danger and T.Accent or (lit and T.BorderLight or T.Border) })
	end
	table.insert(ThemeCallbacks, paint)
	Button.MouseEnter:Connect(function()
		hot = true
		paint()
	end)
	Button.MouseLeave:Connect(function()
		hot = false
		paint()
	end)
	return Button, function(state)
		danger = state
		paint()
	end
end

local TARGET_STATES = {
	fighting = { "Fighting" },
	attacking = { "Attacking" },
	dodging = { "Dodging", Color3.fromHex("ffb648") },
	looting = { "Looting", Color3.fromHex("4ade80") },
	finishing = { "Finishing", Color3.fromHex("4ade80") },
	gripping = { "Gripping", Color3.fromHex("4ade80") },
	retreating = { "Retreating", Color3.fromHex("ff5c7a") },
	healing = { "Healing", Color3.fromHex("4ade80") },
	resetting = { "Resetting", Color3.fromHex("ffb648") },
	waiting = { "Waiting" },
	defeated = { "Defeated", Color3.fromHex("4ade80") },
}
local COPY_STRIP = { "LuaSourceContainer", "Sound", "ParticleEmitter", "Beam", "Trail", "Light", "Fire", "Smoke",
	"Sparkles", "LayerCollector", "ProximityPrompt", "ClickDetector", "Animator", "JointInstance", "Constraint",
	"BodyMover", "Explosion", "ForceField" }

local function commas(n)
	local value = tostring(math.floor(n + 0.5))
	local count
	repeat
		value, count = value:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
	until count == 0
	return value
end

local function shortNumber(n)
	n = math.abs(n)
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	return commas(n)
end

local function clockText(seconds)
	seconds = math.max(0, math.floor(seconds + 0.5))
	if seconds >= 3600 then
		return string.format("%d:%02d:%02d", seconds // 3600, (seconds % 3600) // 60, seconds % 60)
	end
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Library:CreateTargetCard(opts)
	opts = opts or {}
	assert(self.ScreenGui, "create the window before the target card")
	local card = {
		Enabled = opts.Enabled ~= false,
		Kills = 0,
		Target = nil,
		AutoHide = opts.AutoHide ~= false,
		Scale = opts.Scale or 1,
		ShowDistance = opts.ShowDistance ~= false,
	}
	local WIDTH = opts.Width or 330
	local PORTRAIT = 66

	local Card = create("Frame", {
		Name = "DexoriTargetCard",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 58),
		Size = UDim2.fromOffset(WIDTH, 132),
		Visible = false,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = self.ScreenGui,
	}, { corner(12), stroke("Border") })
	local CardScale = create("UIScale", { Scale = card.Scale * self.UserScale, Parent = Card })
	table.insert(ScaleHooks, function(scale)
		CardScale.Scale = card.Scale * scale
	end)

	local Portrait = create("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.fromOffset(PORTRAIT, PORTRAIT),
		ClipsDescendants = true,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Card,
	}, { corner(10), stroke("Border") })
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0.55, 0.55, 0.6)),
		Parent = Portrait,
	})
	local PortraitIcon = icon(Portrait, opts.Icon or "skull", 26, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Theme = { ImageColor3 = "Muted" },
	})
	local View = create("ViewportFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(165, 160, 175),
		LightColor = Color3.fromRGB(255, 245, 240),
		LightDirection = Vector3.new(0.45, -0.7, 1),
		Parent = Portrait,
	}, { corner(10) })
	local Camera = create("Camera", { FieldOfView = 34, Parent = View })
	View.CurrentCamera = Camera
	local Badge = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(12 + PORTRAIT / 2, 12 + PORTRAIT),
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		Visible = false,
		ZIndex = 5,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Card,
	}, { corner(5), padding(0, 6, 0, 6) })
	local BadgeText = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 16),
		FontFace = FONT_BOLD,
		TextSize = 10,
		ZIndex = 6,
		KeepCase = true,
		TextColor3 = Color3.new(1, 1, 1),
		Theme = false,
		Parent = Badge,
	})

	local Info = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(PORTRAIT + 24, 11),
		Size = UDim2.new(1, -(PORTRAIT + 36), 0, PORTRAIT + 2),
		Parent = Card,
	})
	local NameText = text({
		Size = UDim2.new(1, -90, 0, 18),
		FontFace = FONT_BOLD,
		TextSize = 15,
		TextTruncate = Enum.TextTruncate.AtEnd,
		KeepCase = true,
		Parent = Info,
	})
	local Subtitle = text({
		Position = UDim2.fromOffset(0, 19),
		Size = UDim2.new(1, -90, 0, 14),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		KeepCase = true,
		Theme = { TextColor3 = "Muted" },
		Parent = Info,
	})
	local StateChip = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.88,
		BackgroundColor3 = self.Theme.Accent,
		Parent = Info,
	}, { corner(6), padding(0, 8, 0, 8) })
	local StateText = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 20),
		FontFace = FONT_SEMI,
		TextSize = 11,
		KeepCase = true,
		TextColor3 = self.Theme.Accent,
		Theme = false,
		Parent = StateChip,
	})

	local Bars = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 39),
		Size = UDim2.new(1, 0, 0, 12),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Info,
	}, { list(4) })
	local Track = create("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		LayoutOrder = 1,
		ClipsDescendants = true,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Bars,
	}, { round(), stroke("Border") })
	local Lag = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.5,
		Theme = { BackgroundColor3 = "Text" },
		Parent = Track,
	}, { round() })
	local Fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Track,
	}, { round() })
	local Gloss = create("Frame", {
		Size = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.86,
		Parent = Fill,
	}, { round() })
	local HpText = text({
		Position = UDim2.new(0, 0, 1, -14),
		Size = UDim2.new(1, -60, 0, 14),
		FontFace = FONT_SEMI,
		TextSize = 12,
		RichText = true,
		KeepCase = true,
		Theme = false,
		Parent = Info,
	})
	local PctText = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 1, -14),
		Size = UDim2.fromOffset(60, 14),
		FontFace = FONT_BOLD,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		KeepCase = true,
		Theme = { TextColor3 = "SubText" },
		Parent = Info,
	})

	local Rule = create("Frame", {
		Position = UDim2.fromOffset(12, PORTRAIT + 24),
		Size = UDim2.new(1, -24, 0, 1),
		Theme = { BackgroundColor3 = "Border" },
		Parent = Card,
	})
	local Stats = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, PORTRAIT + 25),
		Size = UDim2.new(1, -24, 0, 30),
		Parent = Card,
	}, { list(0, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local function stat(order, iconName, tip)
		local Cell = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.25, 0, 1, 0),
			LayoutOrder = order,
			Parent = Stats,
		}, { list(5, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = order == 1 and Enum.HorizontalAlignment.Left or (order == 4 and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Center) }) })
		icon(Cell, iconName, 12, { LayoutOrder = 1, Theme = { ImageColor3 = "Muted" } })
		local Value = text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 14),
			FontFace = FONT_SEMI,
			TextSize = 12,
			LayoutOrder = 2,
			KeepCase = true,
			Theme = { TextColor3 = "SubText" },
			Parent = Cell,
		})
		attachTooltip(Cell, tip)
		return Value
	end
	local TimeValue = stat(1, "clock", "Time on this target")
	local DpsValue = stat(2, "zap", "Damage per second")
	local EtaValue = stat(3, "hourglass", "Time left at this rate")
	local KillValue = stat(4, "skull", "Kills this session")

	local Pops = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Parent = Card,
	})

	local extra = {}
	local function layout()
		local barsHeight = 12
		for _, bar in pairs(extra) do
			if bar.Frame.Visible then
				barsHeight = barsHeight + 4 + bar.Frame.Size.Y.Offset
			end
		end
		local infoHeight = math.max(PORTRAIT + 2, 39 + barsHeight + 20)
		Info.Size = UDim2.new(1, -(PORTRAIT + 36), 0, infoHeight)
		Rule.Position = UDim2.fromOffset(12, infoHeight + 22)
		Stats.Position = UDim2.fromOffset(12, infoHeight + 23)
		Card.Size = UDim2.fromOffset(WIDTH, infoHeight + 23 + 30 + 4)
	end
	layout()

	function card:AddBar(name, barOpts)
		barOpts = barOpts or {}
		local Frame = create("Frame", {
			Size = UDim2.new(1, 0, 0, barOpts.Height or 5),
			LayoutOrder = 10 + #Bars:GetChildren(),
			ClipsDescendants = true,
			Visible = barOpts.Visible ~= false,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Bars,
		}, { round() })
		local BarFill = create("Frame", {
			Size = UDim2.fromScale(barOpts.Value or 0, 1),
			BackgroundColor3 = barOpts.Color or Library.Theme.SubText,
			Parent = Frame,
		}, { round() })
		local bar = { Frame = Frame, Fill = BarFill }
		function bar:Set(value, max)
			local ratio = max and max > 0 and value / max or value
			tween(BarFill, { Size = UDim2.fromScale(math.clamp(ratio or 0, 0, 1), 1) }, TWEEN)
		end
		function bar:SetVisible(state)
			Frame.Visible = state == true
			layout()
		end
		function bar:SetColor(color)
			BarFill.BackgroundColor3 = color
		end
		extra[name] = bar
		layout()
		return bar
	end
	function card:GetBar(name)
		return extra[name]
	end

	local copy, source, sourceRoot, partPairs, head, focus = nil, nil, nil, {}, nil, nil
	local function clearCopy()
		if copy then
			copy:Destroy()
		end
		copy, source, sourceRoot, partPairs, head, focus = nil, nil, nil, {}, nil, nil
		PortraitIcon.Visible = true
	end
	local function buildCopy(model, root)
		clearCopy()
		source, sourceRoot = model, root
		if not (model and root) or opts.Portrait == false then
			return
		end
		local flipped = {}
		for _, object in ipairs(model:GetDescendants()) do
			if not object.Archivable then
				object.Archivable = true
				table.insert(flipped, object)
			end
		end
		local wasArchivable = model.Archivable
		model.Archivable = true
		local ok, clone = pcall(model.Clone, model)
		model.Archivable = wasArchivable
		for _, object in ipairs(flipped) do
			object.Archivable = false
		end
		if not (ok and clone) then
			return
		end
		local sourceParts, cloneParts = {}, {}
		for _, object in ipairs(model:GetDescendants()) do
			if object:IsA("BasePart") then
				table.insert(sourceParts, object)
			end
		end
		for _, object in ipairs(clone:GetDescendants()) do
			if object:IsA("BasePart") then
				table.insert(cloneParts, object)
			end
		end
		for index, part in ipairs(sourceParts) do
			local twin = cloneParts[index]
			if twin and twin.Name == part.Name then
				twin.Anchored = true
				twin.CanCollide = false
				table.insert(partPairs, { part, twin })
			end
		end
		for _, object in ipairs(clone:GetDescendants()) do
			for _, className in ipairs(COPY_STRIP) do
				if object:IsA(className) then
					object:Destroy()
					break
				end
			end
		end
		local humanoid = clone:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end
		local headPart = model:FindFirstChild("Head", true)
		head = (headPart and headPart:IsA("BasePart")) and headPart or nil
		copy = clone
		copy.Parent = View
		PortraitIcon.Visible = false
	end
	local function pose()
		if not (copy and sourceRoot and sourceRoot.Parent) then
			return
		end
		local base = sourceRoot.CFrame
		for _, pair in ipairs(partPairs) do
			local original, twin = pair[1], pair[2]
			if original.Parent then
				twin.CFrame = base:ToObjectSpace(original.CFrame)
				twin.Transparency = original.Transparency
			end
		end
		local target, size
		if head and head.Parent then
			target, size = base:ToObjectSpace(head.CFrame).Position, head.Size.Magnitude
		else
			local ok, boxCFrame, boxSize = pcall(source.GetBoundingBox, source)
			if not ok then
				return
			end
			target = base:ToObjectSpace(boxCFrame).Position + Vector3.new(0, boxSize.Y * 0.4, 0)
			size = math.max(boxSize.X, boxSize.Z) * 0.45
		end
		focus = focus and focus:Lerp(target, 0.25) or target
		local distance = size * 1.25 / math.tan(math.rad(Camera.FieldOfView / 2))
		Camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, size * 0.12, -distance), focus)
	end

	local shown = false
	local function setShown(state)
		if state == shown then
			return
		end
		shown = state
		if state then
			CardScale.Scale = card.Scale * Library.UserScale * 0.94
			tween(CardScale, { Scale = card.Scale * Library.UserScale }, POP_IN)
		end
		popout(Card, state)
	end

	local stateKey, stateColor
	local function paintState(label, color)
		local T = Library.Theme
		local chip = color or T.Accent
		StateText.Text = label or ""
		StateText.TextColor3 = chip
		StateChip.BackgroundColor3 = chip
		StateChip.Visible = label ~= nil and label ~= ""
	end
	function card:SetState(value, color)
		stateKey, stateColor = value, color
		local known = type(value) == "string" and TARGET_STATES[string.lower(value)]
		if known then
			paintState(known[1], color or known[2])
		else
			paintState(value and tostring(value) or nil, color)
		end
	end

	local health, maxHealth, shownHealth = 0, 1, 0
	local ratioNow, lagRatio, lastDrop = 1, 1, 0
	local engagedAt, samples, lastSample = os.clock(), {}, 0
	local pendingDamage, pendingSince = 0, 0
	local defeatedAt = nil
	local defeatedModel = nil
	local lastKillTime = nil

	local function damagePop(amount)
		local s = math.max(CardScale.Scale, 0.01)
		local left = (Track.AbsolutePosition.X - Card.AbsolutePosition.X) / s
		local top = (Track.AbsolutePosition.Y - Card.AbsolutePosition.Y) / s
		local x = left + Track.AbsoluteSize.X / s * math.clamp(ratioNow, 0.08, 0.92)
		local Pop = text({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromOffset(x, top - 2),
			Size = UDim2.fromOffset(80, 16),
			FontFace = FONT_BOLD,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			Text = "-" .. shortNumber(amount),
			KeepCase = true,
			ZIndex = 11,
			Theme = { TextColor3 = "Accent" },
			Parent = Pops,
		})
		local PopScale = create("UIScale", { Scale = 0.6, Parent = Pop })
		tween(PopScale, { Scale = 1 }, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		tween(Pop, { Position = Pop.Position - UDim2.fromOffset(0, 18) }, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
		task.delay(0.35, function()
			tween(Pop, { TextTransparency = 1 }, TweenInfo.new(0.45)).Completed:Connect(function()
				Pop:Destroy()
			end)
		end)
	end

	local function resetStats()
		engagedAt, samples, lastSample = os.clock(), {}, 0
		pendingDamage, pendingSince = 0, 0
		lagRatio, defeatedAt = 1, nil
		shownHealth = health
	end

	local function readTarget(target)
		local humanoid = target.Humanoid
		if humanoid then
			if humanoid.Parent then
				health = math.max(humanoid.Health, 0)
				maxHealth = math.max(humanoid.MaxHealth, 1)
			else
				health = 0
			end
		end
		if target.Model and not target.Model.Parent then
			health = 0
		end
	end

	function card:SetTarget(target)
		if typeof(target) == "Instance" then
			local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
			target = { Model = model }
		end
		if target == nil then
			self.Target = nil
			clearCopy()
			if self.AutoHide then
				setShown(false)
			end
			return
		end
		local model = target.Model
		if model and model == defeatedModel and not self.Target then
			local humanoid = target.Humanoid or model:FindFirstChildOfClass("Humanoid")
			if not model.Parent or not humanoid or humanoid.Health <= 0 then
				return
			end
		end
		target.Humanoid = target.Humanoid or (model and model:FindFirstChildOfClass("Humanoid"))
		target.Root = target.Root or (model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart))
		target.Name = target.Name or (model and model.Name) or "Target"
		local same = self.Target and model ~= nil and self.Target.Model == model
		self.Target = target
		if target.Health then
			health = target.Health
		end
		if target.MaxHealth then
			maxHealth = math.max(target.MaxHealth, 1)
		end
		readTarget(target)
		if not same then
			buildCopy(model, target.Root)
			resetStats()
			ratioNow = health / maxHealth
			lagRatio = ratioNow
			if stateKey == "defeated" or stateKey == "Defeated" then
				self:SetState(nil)
			end
		end
		NameText.Text = target.Name
		Badge.Visible = target.Badge ~= nil
		BadgeText.Text = target.Badge and string.upper(tostring(target.Badge)) or ""
		PortraitIcon.Visible = copy == nil
		if target.Icon then
			Library:SetIcon(PortraitIcon, target.Icon)
		end
		if self.Enabled then
			setShown(true)
		end
		if not same then
			shownHealth = health
			self._step(0)
		end
	end

	function card:SetHealth(value, max)
		health = math.max(tonumber(value) or 0, 0)
		if max then
			maxHealth = math.max(tonumber(max) or 1, 1)
		end
	end

	function card:SetEnabled(state)
		self.Enabled = state ~= false
		setShown(self.Enabled and self.Target ~= nil)
	end

	function card:SetScale(scale)
		self.Scale = tonumber(scale) or 1
		CardScale.Scale = self.Scale * Library.UserScale
	end

	function card:ResetPosition()
		card.Dragged = false
	end

	function card:ResetKills()
		self.Kills = 0
		KillValue.Text = "0"
	end

	function card:Destroy()
		clearCopy()
		Card:Destroy()
	end

	local dragging, dragStart, startPos
	Card.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging, dragStart, startPos = true, input.Position, Card.Position
		end
	end)
	connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local delta = input.Position - dragStart
			Card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			card.Dragged = true
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if isPointer(input) then
			dragging = false
		end
	end)

	local pulse = 0
	local function step(dt)
		local target = card.Target
		if not target or not Card.Visible then
			return
		end
		dt = math.min(dt or 0, 0.1)
		readTarget(target)
		pose()
		local now = os.clock()
		local T = Library.Theme

		if not card.Dragged then
			local watermark = Library.Watermark
			local y = 12
			if watermark and watermark.Visible then
				y = watermark.Position.Y.Offset + watermark.AbsoluteSize.Y + 8
			end
			Card.Position = UDim2.new(0.5, 0, 0, y)
		end

		local ratio = math.clamp(health / maxHealth, 0, 1)
		if ratio < ratioNow - 0.0005 then
			lastDrop = now
			pendingDamage = pendingDamage + (ratioNow - ratio) * maxHealth
			if pendingSince == 0 then
				pendingSince = now
			end
		end
		if ratio > lagRatio then
			lagRatio = ratio
		end
		ratioNow = ratioNow + (ratio - ratioNow) * (1 - math.exp(-dt * 16))
		if math.abs(ratioNow - ratio) < 0.0005 then
			ratioNow = ratio
		end
		if now - lastDrop > 0.35 then
			lagRatio = math.max(ratioNow, lagRatio - dt * 0.7)
		end
		if pendingDamage > 0 and now - pendingSince > 0.14 then
			if opts.DamageNumbers ~= false then
				damagePop(pendingDamage)
			end
			pendingDamage, pendingSince = 0, 0
		end
		Fill.Size = UDim2.fromScale(ratioNow, 1)
		Lag.Size = UDim2.fromScale(lagRatio, 1)
		if ratio <= 0.2 and ratio > 0 then
			pulse = pulse + dt * 6
			Gloss.BackgroundTransparency = 0.86 - 0.12 * (0.5 + 0.5 * math.sin(pulse))
		else
			Gloss.BackgroundTransparency = 0.86
		end

		shownHealth = shownHealth + (health - shownHealth) * (1 - math.exp(-dt * 12))
		if math.abs(shownHealth - health) < 1 then
			shownHealth = health
		end
		HpText.Text = string.format('<font color="#%s">%s</font><font color="#%s"> / %s</font>', T.Text:ToHex(), commas(math.ceil(shownHealth)), T.Muted:ToHex(), commas(math.floor(maxHealth)))
		PctText.Text = string.format("%d%%", math.floor(ratio * 100 + 0.5))

		local subtitle = target.Subtitle or ""
		if card.ShowDistance and target.Root and target.Root.Parent then
			local character = LocalPlayer.Character
			local mine = character and character:FindFirstChild("HumanoidRootPart")
			if mine then
				local studs = math.floor((mine.Position - target.Root.Position).Magnitude + 0.5)
				subtitle = subtitle ~= "" and (subtitle .. " · " .. studs .. " studs") or (studs .. " studs")
			end
		end
		Subtitle.Text = subtitle

		if health <= 0 and not defeatedAt then
			defeatedAt = now
			defeatedModel = target.Model
			card.Kills = card.Kills + 1
			lastKillTime = now - engagedAt
			card:SetState("defeated")
			fire(opts.OnDefeated, target, lastKillTime)
		elseif health > 0 and defeatedAt then
			defeatedAt = nil
			card:SetState(nil)
		end
		if defeatedAt and card.AutoHide and now - defeatedAt > (opts.HideDelay or 1.6) then
			card.Target = nil
			clearCopy()
			setShown(false)
		end

		if now - lastSample >= 0.2 and not defeatedAt then
			lastSample = now
			table.insert(samples, { t = now, hp = health })
			while #samples > 2 and now - samples[1].t > 6 do
				table.remove(samples, 1)
			end
		end
		local dps
		local first = samples[1]
		if first and now - first.t >= 1 then
			local lost = first.hp - health
			dps = lost > 0 and lost / (now - first.t) or 0
		end
		TimeValue.Text = defeatedAt and clockText(lastKillTime or 0) or clockText(now - engagedAt)
		DpsValue.Text = dps and (shortNumber(dps) .. "/s") or "--"
		EtaValue.Text = defeatedAt and "done" or ((dps and dps > 0) and ("~" .. clockText(health / dps)) or "--")
		KillValue.Text = tostring(card.Kills)
	end
	connect(RunService.RenderStepped, step)
	card._step = step

	table.insert(ThemeCallbacks, function()
		card:SetState(stateKey, stateColor)
	end)
	card:SetState(opts.State)
	KillValue.Text = "0"
	TimeValue.Text = "0:00"
	DpsValue.Text = "--"
	EtaValue.Text = "--"
	function card:AddSettings(group, prefix)
		prefix = prefix or "TargetCard"
		group:AddToggle(prefix, {
			Text = opts.Title or "Target card",
			Description = "Shows the mob or boss you're fighting",
			Default = card.Enabled,
			Callback = function(enabled)
				card:SetEnabled(enabled)
			end,
		})
		group:AddToggle(prefix .. "Damage", {
			Text = "Damage numbers",
			Default = opts.DamageNumbers ~= false,
			Callback = function(enabled)
				opts.DamageNumbers = enabled
			end,
		})
		group:AddSlider(prefix .. "Scale", {
			Text = "Card scale",
			Min = 50,
			Max = 200,
			Default = math.floor(card.Scale * 100 + 0.5),
			Suffix = "%",
			Callback = function(value)
				card:SetScale(value / 100)
			end,
		})
		group:AddButton({
			Label = "Card position",
			Text = "Reset",
			Func = function()
				card:ResetPosition()
			end,
		})
	end

	self.TargetCard = card
	table.insert(UnloadCallbacks, function()
		clearCopy()
	end)
	return card
end

function Library:CreateWindow(info)
	info = info or {}
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local width = math.min(info.Width or 780, viewport.X - 24)
	local height = math.min(info.Height or 520, viewport.Y - 24)

	self.Title = info.Title or "Dexori"
	self.ToggleKey = parseKey(info.ToggleKey or "RightControl")

	local ScreenGui = create("ScreenGui", {
		Name = "Dexori",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 999,
	})
	parentGui(ScreenGui)
	self.ScreenGui = ScreenGui
	startSheen()

	local Root = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(width, height),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = ScreenGui,
	})
	self.Scale = create("UIScale", { Scale = self.UserScale, Parent = Root })

	self.PopupLayer = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 30,
		Parent = ScreenGui,
	})

	local Body = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Root,
	})
	local OpenScale = create("UIScale", { Scale = 1, Parent = Body })

	local chrome = {}
	for index, spread in ipairs({ 3, 8, 15 }) do
		local Shadow = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 4),
			Size = UDim2.new(1, spread * 2, 1, spread * 2),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.78 + index * 0.06,
			ZIndex = 0,
			Parent = Body,
		}, { corner(WINDOW_RADIUS + spread) })
		table.insert(chrome, { Shadow, "BackgroundTransparency", Shadow.BackgroundTransparency })
	end

	local Fader = create("CanvasGroup", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 1,
		Parent = Body,
	}, { corner(WINDOW_RADIUS) })
	local Main = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Fader,
	}, { corner(WINDOW_RADIUS) })
	create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(1, 1),
		Size = UDim2.new(1, -2, 1, -2),
		ZIndex = 60,
		Parent = Main,
	}, { corner(WINDOW_RADIUS - 1), create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Transparency = 0.35, Theme = { Color = "BorderLight" } }) })

	local EdgeStroke = stroke()
	create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = Body }, { corner(WINDOW_RADIUS), EdgeStroke })
	table.insert(chrome, { EdgeStroke, "Transparency", 0 })

	local FlowStroke = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1.5, Theme = { Color = "Accent" } })
	local FlowGradient = create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.38, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(0.62, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = FlowStroke,
	})
	local Flow = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = self.GlowEnabled,
		ZIndex = 3,
		Parent = Body,
	}, { corner(WINDOW_RADIUS), FlowStroke })
	table.insert(Loops, tween(FlowGradient, { Rotation = 360 }, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)))
	table.insert(chrome, { FlowStroke, "Transparency", 0 })

	function Library:SetGlow(enabled)
		self.GlowEnabled = enabled
		Flow.Visible = enabled
	end

	local showUser = info.User ~= false
	local cardHeight = showUser and USERCARD or 0
	local compactHooks = {}

	local Sidebar = create("Frame", {
		Size = UDim2.new(0, SIDEBAR, 1, 0),
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Main,
	}, { corner(WINDOW_RADIUS) })
	create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, WINDOW_RADIUS, 1, 0),
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Sidebar,
	})
	create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Sidebar,
	})

	local Brand = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER),
		Parent = Sidebar,
	})
	local Mark = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(32, 32),
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Brand,
	}, { corner(9), stroke("Border") })
	local MarkLetter = text({
		Size = UDim2.fromScale(1, 1),
		FontFace = FONT_BOLD,
		TextSize = 20,
		Text = "d",
		TextXAlignment = Enum.TextXAlignment.Center,
		Theme = { TextColor3 = "Accent" },
		Parent = Mark,
	})
	buildIcon(Mark, 28, MarkLetter)
	local BrandText = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 56, 0.5, 0),
		Size = UDim2.new(1, -66, 0, 34),
		Parent = Brand,
	})
	text({
		Size = UDim2.new(1, 0, 0, 19),
		FontFace = FONT_BOLD,
		TextSize = 16,
		Text = self.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		KeepCase = true,
		Parent = BrandText,
	})
	local SubtitleLabel = text({
		Position = UDim2.fromOffset(0, 19),
		Size = UDim2.new(1, 0, 0, 15),
		TextSize = 11,
		Text = info.Subtitle or ("v" .. (tostring(Library.Version):match("^(%d+%.%d+)") or Library.Version) .. " · Script Hub"),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Muted" },
		Parent = BrandText,
	})
	table.insert(compactHooks, function(compact)
		BrandText.Visible = not compact
		Mark.Position = compact and UDim2.new(0.5, -16, 0.5, 0) or UDim2.new(0, 14, 0.5, 0)
	end)

	local Nav = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 1, -(HEADER + cardHeight)),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,
		Parent = Sidebar,
	}, { list(3), padding(8, 10, 10, 10) })

	if showUser then
		local Card = create("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, cardHeight),
			BackgroundTransparency = 1,
			Parent = Sidebar,
		})
		create("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Border" }, Parent = Card })
		local Inner = create("Frame", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.new(1, -20, 1, -20),
			Theme = { BackgroundColor3 = "Panel" },
			Parent = Card,
		}, { corner(9), stroke("Border") })
		local Avatar = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 8, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundTransparency = 0.82,
			ClipsDescendants = true,
			Theme = { BackgroundColor3 = "Accent" },
			Parent = Inner,
		}, { round() })
		local displayName = LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name
		text({
			Size = UDim2.fromScale(1, 1),
			FontFace = FONT_BOLD,
			TextSize = 14,
			Text = string.upper(displayName:sub(1, 1)),
			TextXAlignment = Enum.TextXAlignment.Center,
			KeepCase = true,
			Theme = { TextColor3 = "Accent" },
			Parent = Avatar,
		})
		if info.Avatar ~= false and LocalPlayer.UserId > 0 then
			create("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=48&h=48",
				Parent = Avatar,
			}, { round() })
		end
		local Who = create("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 46, 0.5, 0),
			Size = UDim2.new(1, -54, 0, 32),
			Parent = Inner,
		})
		text({
			Size = UDim2.new(1, 0, 0, 16),
			FontFace = FONT_SEMI,
			TextSize = 13,
			Text = displayName,
			TextTruncate = Enum.TextTruncate.AtEnd,
			KeepCase = true,
			Parent = Who,
		})
		if info.Badge then
			local Badge = create("Frame", {
				Position = UDim2.fromOffset(0, 18),
				Size = UDim2.fromOffset(0, 14),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0.84,
				Theme = { BackgroundColor3 = "Accent" },
				Parent = Who,
			}, { corner(4), padding(0, 5, 0, 5) })
			text({
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 14),
				FontFace = FONT_BOLD,
				TextSize = 9,
				Text = string.upper(tostring(info.Badge)),
				KeepCase = true,
				Theme = { TextColor3 = "Accent" },
				Parent = Badge,
			})
		else
			text({
				Position = UDim2.fromOffset(0, 17),
				Size = UDim2.new(1, 0, 0, 14),
				TextSize = 11,
				Text = "@" .. LocalPlayer.Name,
				TextTruncate = Enum.TextTruncate.AtEnd,
				KeepCase = true,
				Theme = { TextColor3 = "Muted" },
				Parent = Who,
			})
		end
		table.insert(compactHooks, function(compact)
			Who.Visible = not compact
			Inner.BackgroundTransparency = compact and 1 or 0
			Inner:FindFirstChildOfClass("UIStroke").Enabled = not compact
			Avatar.Position = compact and UDim2.new(0.5, -15, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
		end)
	end

	local Content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIDEBAR, 0),
		Size = UDim2.new(1, -SIDEBAR, 1, 0),
		Parent = Main,
	})
	create("Frame", {
		Position = UDim2.fromOffset(0, HEADER - 1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 2,
		Theme = { BackgroundColor3 = "Border" },
		Parent = Main,
	})

	local Header = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, HEADER),
		Parent = Content,
	})
	local CloseButton, armClose = headerButton(Header, "x", UDim2.new(1, -14, 0.5, 0))
	local HideButton = headerButton(Header, "minus", UDim2.new(1, -50, 0.5, 0))

	local SEARCH_WIDTH, SEARCH_OPEN = 190, 230
	local searchWidth, searchOpen = SEARCH_WIDTH, SEARCH_OPEN
	local SearchEdge = stroke("Border")
	local SearchField = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -88, 0.5, 0),
		Size = UDim2.fromOffset(SEARCH_WIDTH, 30),
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Header,
	}, { corner(8), SearchEdge })
	icon(SearchField, "search", 14, {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Theme = { ImageColor3 = "Muted" },
	})
	local SearchBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = "",
		PlaceholderText = "Search...",
		ClearTextOnFocus = false,
		FontFace = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = SearchField,
	})
	SearchField.MouseEnter:Connect(function()
		if not SearchBox:IsFocused() then
			tween(SearchEdge, { Color = Library.Theme.BorderLight })
		end
	end)
	SearchField.MouseLeave:Connect(function()
		if not SearchBox:IsFocused() then
			tween(SearchEdge, { Color = Library.Theme.Border })
		end
	end)

	local HeadLeft = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 0),
		Size = UDim2.new(1, -(20 + 88 + SEARCH_WIDTH + 14), 1, 0),
		ClipsDescendants = true,
		Parent = Header,
	}, { list(12, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local PageTitle = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		FontFace = FONT_BOLD,
		TextSize = 18,
		LayoutOrder = 1,
		Parent = HeadLeft,
	})
	local GamePill = create("Frame", {
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Visible = false,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = HeadLeft,
	}, { round(), stroke("Border"), padding(0, 11, 0, 11), list(7, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local GameName = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 14),
		FontFace = FONT_MEDIUM,
		TextSize = 12,
		LayoutOrder = 2,
		KeepCase = true,
		Theme = { TextColor3 = "SubText" },
		Parent = GamePill,
	})
	function Library:SetGame(name)
		GameName.Text = tostring(name or "")
		GamePill.Visible = name ~= nil and name ~= false and name ~= ""
	end
	if type(info.Game) == "string" then
		Library:SetGame(info.Game)
	elseif info.Game ~= false then
		task.spawn(function()
			local ok, product = pcall(function()
				return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
			end)
			if ok and type(product) == "table" and type(product.Name) == "string" and not Library.Unloaded then
				Library:SetGame(product.Name)
			end
		end)
	end

	local Pages = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 1, -(HEADER + FOOTER)),
		ClipsDescendants = true,
		Parent = Content,
	})
	local Cover = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Pages,
	})

	local Footer = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, FOOTER),
		BackgroundTransparency = 1,
		Parent = Content,
	})
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Border" }, Parent = Footer })
	local FooterLeft = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(20, 1),
		Size = UDim2.new(0, 0, 1, -1),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = Footer,
	}, { list(10, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local FooterLabel = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 14),
		FontFace = FONT_SEMI,
		TextSize = 12,
		Text = info.Footer or self.Title,
		LayoutOrder = 1,
		KeepCase = true,
		Theme = { TextColor3 = "SubText" },
		Parent = FooterLeft,
	})
	local KeyChip = create("Frame", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 2,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = FooterLeft,
	}, { corner(5), stroke("Border"), list(5, true, { VerticalAlignment = Enum.VerticalAlignment.Center }), padding(0, 6, 0, 6) })
	text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), TextSize = 11, Text = "Menu", LayoutOrder = 1, Theme = { TextColor3 = "Muted" }, Parent = KeyChip })
	local KeyLabel = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), FontFace = FONT_SEMI, TextSize = 11, LayoutOrder = 2, Theme = { TextColor3 = "SubText" }, Parent = KeyChip })

	local FooterRight = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -30, 0, 1),
		Size = UDim2.new(0.6, 0, 1, -1),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		KeepCase = true,
		Theme = { TextColor3 = "Muted" },
		Parent = Footer,
	})

	local Grip = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(18, 18),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		ZIndex = 55,
		Parent = Main,
	})
	local gripDots = {}
	for _, spot in ipairs({ { 14, 14 }, { 9, 14 }, { 14, 9 }, { 4, 14 }, { 9, 9 }, { 14, 4 } }) do
		table.insert(gripDots, create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(spot[1], spot[2]),
			Size = UDim2.fromOffset(3, 3),
			ZIndex = 56,
			Theme = { BackgroundColor3 = "BorderLight" },
			Parent = Grip,
		}, { round() }))
	end
	local resizing, gripHover = false, false
	local function paintGrip()
		local color = (resizing or gripHover) and Library.Theme.Accent or Library.Theme.BorderLight
		for _, dot in ipairs(gripDots) do
			tween(dot, { BackgroundColor3 = color })
		end
	end
	Grip.MouseEnter:Connect(function()
		gripHover = true
		paintGrip()
	end)
	Grip.MouseLeave:Connect(function()
		gripHover = false
		paintGrip()
	end)
	table.insert(ThemeCallbacks, paintGrip)

	local footerRight = info.FooterRight
	local narrow = false
	local fps, ping = 0, 0
	local function paintStatus()
		KeyLabel.Text = keyName(Library.ToggleKey)
		local stats = fps .. " fps · " .. ping .. " ms"
		FooterRight.Text = not narrow and footerRight and footerRight ~= "" and (footerRight .. "     " .. stats) or stats
	end
	table.insert(compactHooks, function(isCompact)
		narrow = isCompact
		searchWidth = isCompact and 130 or SEARCH_WIDTH
		searchOpen = isCompact and 180 or SEARCH_OPEN
		SearchField.Size = UDim2.fromOffset(searchWidth, 30)
		HeadLeft.Size = UDim2.new(1, -(20 + 88 + searchWidth + 14), 1, 0)
		KeyChip.Visible = not isCompact
		FooterRight.Size = UDim2.new(isCompact and 0.5 or 0.6, 0, 1, -1)
		paintStatus()
	end)
	table.insert(ThemeCallbacks, paintStatus)
	paintStatus()

	function Library:SetFooter(content)
		FooterLabel.Text = tostring(content or "")
	end
	function Library:SetFooterRight(content)
		footerRight = content and tostring(content) or nil
		paintStatus()
	end
	function Library:SetSubtitle(content)
		SubtitleLabel.Text = tostring(content or "")
	end

	local frames = 0
	connect(RunService.RenderStepped, function()
		frames = frames + 1
	end)
	task.spawn(function()
		while not Library.Unloaded do
			task.wait(0.5)
			fps = frames * 2
			frames = 0
			local ok, seconds = pcall(function()
				return LocalPlayer:GetNetworkPing()
			end)
			ping = ok and math.floor(seconds * 1000 + 0.5) or 0
			paintStatus()
			if Library._paintWatermark then
				Library._paintWatermark(fps, ping)
			end
		end
	end)

	local Results = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -88, 0, HEADER - 8),
		Size = UDim2.fromOffset(SEARCH_OPEN, 0),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 20,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = Content,
	}, { corner(8), stroke("BorderLight"), padding(4), list(2) })
	local resultsId = 0
	local function showResults(rows)
		resultsId = resultsId + 1
		local id = resultsId
		if rows == 0 then
			if Results.Visible then
				tween(Results, { Size = UDim2.fromOffset(SEARCH_OPEN, 0) }, POP_OUT).Completed:Connect(function()
					if id == resultsId then
						Results.Visible = false
					end
				end)
			end
			return
		end
		if not Results.Visible then
			Results.Size = UDim2.fromOffset(SEARCH_OPEN, 0)
			Results.Visible = true
		end
		tween(Results, { Size = UDim2.fromOffset(SEARCH_OPEN, 8 + rows * 26 + (rows - 1) * 2) }, TWEEN_SMOOTH)
	end

	buildKeybindPanel(ScreenGui)
	buildWatermark(ScreenGui)

	self.NotifyHolder = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 280, 1, -32),
		Parent = ScreenGui,
	}, { list(8, false, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })
	self.Tooltip = text({
		Visible = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		BackgroundTransparency = 0,
		TextSize = 12,
		ZIndex = 50,
		Theme = { BackgroundColor3 = "Panel", TextColor3 = "SubText" },
		Parent = ScreenGui,
	})
	corner(6).Parent = self.Tooltip
	stroke("BorderLight").Parent = self.Tooltip
	padding(5, 9, 5, 9).Parent = self.Tooltip

	local Window = { Tabs = {}, Main = Main, Root = Root, Sidebar = Sidebar }

	local compact = nil
	local function applyLayout()
		local now = Root.Size.X.Offset < 600
		if now == compact then
			return
		end
		compact = now
		local side = now and SIDEBAR_COMPACT or SIDEBAR
		Sidebar.Size = UDim2.new(0, side, 1, 0)
		Content.Position = UDim2.fromOffset(side, 0)
		Content.Size = UDim2.new(1, -side, 1, 0)
		for _, hook in ipairs(compactHooks) do
			hook(now)
		end
	end

	local OPEN = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local FADE_OPEN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local CLOSE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local open, toggleId = false, 0

	local function setChrome(hidden, tweenInfo)
		local goal = hidden and 1 or 0
		if tweenInfo then
			tween(Fader, { GroupTransparency = goal }, tweenInfo)
		else
			Fader.GroupTransparency = goal
		end
		for _, entry in ipairs(chrome) do
			local target = hidden and 1 or entry[3]
			if tweenInfo then
				tween(entry[1], { [entry[2]] = target }, tweenInfo)
			else
				entry[1][entry[2]] = target
			end
		end
	end

	function Window:Toggle(state)
		if state == nil then
			state = not open
		end
		if state == open then
			return
		end
		open = state
		toggleId = toggleId + 1
		local id = toggleId
		Main.Parent = Fader
		if state then
			Library.PopupLayer.Visible = true
			if not Root.Visible then
				OpenScale.Scale = 0.92
				setChrome(true)
				Root.Visible = true
			end
			tween(OpenScale, { Scale = 1 }, OPEN)
			setChrome(false, FADE_OPEN)
			task.delay(OPEN.Time + 0.02, function()
				if id == toggleId and not Library.Unloaded then
					Main.Parent = Body
				end
			end)
		else
			hideTooltip()
			SearchBox:ReleaseFocus()
			showResults(0)
			tween(OpenScale, { Scale = 0.94 }, CLOSE)
			setChrome(true, CLOSE)
			task.delay(CLOSE.Time + 0.02, function()
				if id == toggleId then
					Root.Visible = false
					Library.PopupLayer.Visible = false
				end
			end)
		end
	end

	function Library:SetToggleKey(key)
		self.ToggleKey = parseKey(key)
		paintStatus()
	end

	HideButton.MouseButton1Click:Connect(function()
		Window:Toggle(false)
		Library:Notify(Library.Title, "Menu hidden. Press " .. keyName(Library.ToggleKey) .. " to bring it back.")
	end)

	local closeArmed = 0
	CloseButton.MouseButton1Click:Connect(function()
		if os.clock() < closeArmed then
			Library:Unload()
			return
		end
		closeArmed = os.clock() + 2.5
		armClose(true)
		Library:Notify(Library.Title, "Press close again to unload.", 2.5)
		task.delay(2.5, function()
			if os.clock() >= closeArmed then
				armClose(false)
			end
		end)
	end)

	local dragging, dragStart, startPos, dragGoal
	local resizeStart, startSize, resizePos
	local function landDrag()
		if dragGoal then
			Root.Position = dragGoal
			dragGoal = nil
		end
	end
	connect(Main.InputBegan, function(input)
		if isPointer(input) and not resizing and input.Position.Y - Main.AbsolutePosition.Y <= HEADER * scaleFactor() then
			dragging, dragStart, startPos = true, input.Position, dragGoal or Root.Position
		end
	end)
	connect(Grip.InputBegan, function(input)
		if isPointer(input) then
			dragging = false
			landDrag()
			resizing, resizeStart, startSize, resizePos = true, input.Position, Root.Size, Root.Position
			paintGrip()
		end
	end)
	connect(RunService.RenderStepped, function(dt)
		if not dragGoal then
			return
		end
		local current = Root.Position
		local dx, dy = dragGoal.X.Offset - current.X.Offset, dragGoal.Y.Offset - current.Y.Offset
		if not dragging and math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
			landDrag()
			return
		end
		local alpha = 1 - math.exp(-math.min(dt, 0.1) * 18)
		Root.Position = UDim2.new(dragGoal.X.Scale, current.X.Offset + dx * alpha, dragGoal.Y.Scale, current.Y.Offset + dy * alpha)
	end)
	connect(UserInputService.InputChanged, function(input)
		if resizing and isMove(input) then
			local s = scaleFactor()
			local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			local delta = (input.Position - resizeStart) / s
			local minW, minH = math.min(MIN_WIDTH, startSize.X.Offset), math.min(MIN_HEIGHT, startSize.Y.Offset)
			local w = math.clamp(startSize.X.Offset + delta.X, minW, math.max(minW, view.X / s - 16))
			local h = math.clamp(startSize.Y.Offset + delta.Y, minH, math.max(minH, view.Y / s - 16))
			Root.Size = UDim2.fromOffset(w, h)
			local dw, dh = (w - startSize.X.Offset) * s, (h - startSize.Y.Offset) * s
			Root.Position = UDim2.new(resizePos.X.Scale, resizePos.X.Offset + dw * Root.AnchorPoint.X, resizePos.Y.Scale, resizePos.Y.Offset + dh * Root.AnchorPoint.Y)
			applyLayout()
		elseif dragging and isMove(input) then
			local delta = input.Position - dragStart
			dragGoal = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
		if Library.Tooltip.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
			Library.Tooltip.Position = UDim2.fromOffset(input.Position.X + 14, input.Position.Y + 16)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if not isPointer(input) then
			return
		end
		if resizing then
			resizing = false
			paintGrip()
		end
		dragging = false
	end)

	connect(UserInputService.InputBegan, function(input, processed)
		if not processed and not Library.Picking and inputMatches(input, Library.ToggleKey) then
			Window:Toggle()
		end
	end)

	if UserInputService.TouchEnabled then
		local MobileButton = create("TextButton", {
			Position = UDim2.fromOffset(16, 16),
			Size = UDim2.fromOffset(42, 42),
			AutoButtonColor = false,
			FontFace = FONT_BOLD,
			TextSize = 20,
			Text = "d",
			Theme = { BackgroundColor3 = "Background", TextColor3 = "Accent" },
			Parent = ScreenGui,
		}, { corner(12), stroke("BorderLight") })
		pressScale(MobileButton)
		buildIcon(MobileButton, 34, MobileButton)
		Library.MobileButton = MobileButton
		MobileButton.MouseButton1Click:Connect(function()
			Window:Toggle()
		end)
	end

	local resultButtons = {}
	local function reveal(entry)
		SearchBox.Text = ""
		showResults(0)
		entry.Tab:Select()
		if entry.Group and entry.Group.Expand then
			entry.Group.Expand()
		end
		task.delay(0.05, function()
			local column = entry.Column
			local s = scaleFactor()
			local y = (entry.Holder.AbsolutePosition.Y - column.AbsolutePosition.Y) / s + column.CanvasPosition.Y - 50
			column.CanvasPosition = Vector2.new(0, math.max(0, y))
			flash(entry.Flash)
		end)
	end

	local function runSearch()
		for _, button in ipairs(resultButtons) do
			button:Destroy()
		end
		resultButtons = {}
		local query = SearchBox.Text:lower()
		if query:match("^%s*$") then
			showResults(0)
			return
		end
		local matches = {}
		for _, entry in ipairs(SearchIndex) do
			if entry.Name:lower():find(query, 1, true) then
				table.insert(matches, entry)
				if #matches == 8 then
					break
				end
			end
		end
		if #matches == 0 then
			table.insert(resultButtons, text({ Size = UDim2.new(1, 0, 0, 26), Text = "  Nothing found", TextSize = 12, Theme = { TextColor3 = "Muted" }, Parent = Results }))
			showResults(1)
			return
		end
		for index, entry in ipairs(matches) do
			local Button = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = index == 1 and 0 or 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Theme = { BackgroundColor3 = "Button" },
				Parent = Results,
			}, { corner(6) })
			local Name = text({ Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.62, -10, 1, 0), Text = entry.Name, TextTruncate = Enum.TextTruncate.AtEnd, Theme = false, TextColor3 = index == 1 and Library.Theme.Text or Library.Theme.SubText, Parent = Button })
			text({
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -8, 0, 0),
				Size = UDim2.new(0.38, -8, 1, 0),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = entry.Tab.Name,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Theme = { TextColor3 = "Muted" },
				Parent = Button,
			})
			local function paintRow(hot)
				tween(Button, { BackgroundTransparency = hot and 0 or 1 })
				tween(Name, { TextColor3 = hot and Library.Theme.Text or Library.Theme.SubText })
			end
			Button.MouseEnter:Connect(function()
				paintRow(true)
			end)
			Button.MouseLeave:Connect(function()
				paintRow(index == 1)
			end)
			Button.MouseButton1Click:Connect(function()
				reveal(entry)
			end)
			table.insert(resultButtons, Button)
		end
		resultButtons.First = matches[1]
		showResults(#matches)
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(runSearch)
	SearchBox.Focused:Connect(function()
		tween(SearchEdge, { Color = Library.Theme.Accent })
		tween(SearchField, { Size = UDim2.fromOffset(searchOpen, 30) }, TWEEN_SMOOTH)
		runSearch()
	end)
	SearchBox.FocusLost:Connect(function(enterPressed)
		tween(SearchEdge, { Color = Library.Theme.Border })
		tween(SearchField, { Size = UDim2.fromOffset(searchWidth, 30) }, TWEEN_SMOOTH)
		if enterPressed and resultButtons.First then
			reveal(resultButtons.First)
			return
		end
		task.delay(0.2, function()
			if not SearchBox:IsFocused() then
				showResults(0)
			end
		end)
	end)

	local PAGE_IN = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local COVER_IN = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local navOrder = 0

	function Window:AddSection(title)
		navOrder = navOrder + 1
		local first = navOrder == 1
		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, first and 24 or 34),
			LayoutOrder = navOrder,
			Parent = Nav,
		})
		local Label = text({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -5),
			Size = UDim2.new(1, -10, 0, 13),
			FontFace = FONT_BOLD,
			TextSize = 10,
			Text = string.upper(tostring(title or "")),
			TextTruncate = Enum.TextTruncate.AtEnd,
			KeepCase = true,
			Theme = { TextColor3 = "Muted" },
			Parent = Holder,
		})
		local Rule = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(18, 1),
			Visible = false,
			Theme = { BackgroundColor3 = "BorderLight" },
			Parent = Holder,
		})
		local function fit(isCompact)
			Label.Visible = not isCompact
			Rule.Visible = isCompact and not first
			Holder.Size = UDim2.new(1, 0, 0, isCompact and (first and 4 or 14) or (first and 24 or 34))
		end
		table.insert(compactHooks, fit)
		if compact ~= nil then
			fit(compact)
		end
		self.Section = title
		return Holder
	end

	function Window:AddTab(name, iconName, opts)
		if type(iconName) == "table" then
			iconName, opts = iconName.Icon, iconName
		end
		opts = opts or {}
		navOrder = navOrder + 1
		local selected, hovering = false, false
		local Button = create("TextButton", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = navOrder,
			Parent = Nav,
		})
		local HoverFill = create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Theme = { BackgroundColor3 = "Panel" },
			Parent = Button,
		}, { corner(8) })
		local SelectFill = create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Theme = { BackgroundColor3 = "Accent" },
			Parent = Button,
		}, { corner(8) })
		local wanted = iconName or name
		local Glyph = icon(Button, Library:HasIcon(wanted) and wanted or "layout-grid", 16, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
		})
		local Label = text({
			Position = UDim2.fromOffset(38, 0),
			Size = UDim2.new(1, -44, 1, 0),
			FontFace = FONT_MEDIUM,
			TextSize = 13,
			Text = name,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = false,
			Parent = Button,
		})
		local function fit(isCompact)
			Label.Visible = not isCompact
			Glyph.Position = isCompact and UDim2.new(0.5, -8, 0.5, 0) or UDim2.new(0, 12, 0.5, 0)
		end
		table.insert(compactHooks, fit)
		if compact ~= nil then
			fit(compact)
		end

		local Page = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = Pages })
		local function column(left)
			return create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = left and UDim2.fromOffset(16, 0) or UDim2.new(0.5, 6, 0, 0),
				Size = UDim2.new(0.5, -22, 1, 0),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 2,
				Theme = { ScrollBarImageColor3 = "BorderLight" },
				Parent = Page,
			}, { list(12), padding(16, 4, 16, 1) })
		end
		local LeftColumn, RightColumn = column(true), column(false)

		local Tab = { Name = name, Title = opts.Title or name, Button = Button, Page = Page }

		local function paint()
			local T = Library.Theme
			local color = selected and T.Accent or (hovering and T.Text or T.SubText)
			tween(HoverFill, { BackgroundTransparency = (hovering and not selected) and 0 or 1 })
			tween(SelectFill, { BackgroundTransparency = selected and 0.9 or 1 })
			tween(Label, { TextColor3 = color })
			tween(Glyph, { ImageColor3 = color })
		end
		table.insert(ThemeCallbacks, paint)
		Label.TextColor3 = Library.Theme.SubText
		Glyph.ImageColor3 = Library.Theme.SubText

		function Tab:AddLeftGroupbox(title)
			return newGroupbox(Tab, LeftColumn, title)
		end
		function Tab:AddRightGroupbox(title)
			return newGroupbox(Tab, RightColumn, title)
		end
		function Tab:SetTitle(value)
			self.Title = tostring(value or "")
			if selected then
				PageTitle.Text = self.Title
			end
		end
		function Tab:SetIcon(value)
			Library:SetIcon(Glyph, value)
		end

		function Tab:Select()
			for _, other in ipairs(Window.Tabs) do
				other._setSelected(other == Tab)
			end
		end

		function Tab._setSelected(state)
			local was = selected
			selected = state
			Page.Visible = state
			if state then
				PageTitle.Text = Tab.Title
			end
			if state and not was then
				Page.Position = UDim2.fromOffset(0, 12)
				tween(Page, { Position = UDim2.new() }, PAGE_IN)
				Cover.BackgroundTransparency = 0
				tween(Cover, { BackgroundTransparency = 1 }, COVER_IN)
			end
			paint()
		end

		Button.MouseEnter:Connect(function()
			hovering = true
			paint()
		end)
		Button.MouseLeave:Connect(function()
			hovering = false
			paint()
		end)
		Button.MouseButton1Click:Connect(function()
			Tab:Select()
		end)
		attachTooltip(Button, opts.Tooltip)

		table.insert(self.Tabs, Tab)
		if #self.Tabs == 1 then
			Tab:Select()
		end
		return Tab
	end

	applyLayout()
	self.Window = Window
	if info.AutoShow == false or Library:GetSilentLoad() then
		Library.PopupLayer.Visible = false
	else
		Window:Toggle(true)
	end
	return Window
end

function Library:Notify(title, description, duration)
	if type(title) == "table" then
		title, description, duration = title.Title, title.Description, title.Time
	elseif description == nil or type(description) == "number" then
		title, description, duration = self.Title or "Dexori", title, description
	end
	if not self.NotifyHolder then
		warn("[Dexori UI] " .. tostring(description))
		return
	end
	duration = duration or 4

	local Slot = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.NotifyHolder,
	})
	local Card = create("Frame", {
		Position = UDim2.fromOffset(320, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Slot,
	}, { corner(), stroke("BorderLight") })
	local Body = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(13, 10),
		Size = UDim2.new(1, -26, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Card,
	}, { list(3), padding(0, 0, 16, 0) })
	text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = FONT_SEMI,
		Text = tostring(title),
		TextWrapped = true,
		LayoutOrder = 1,
		Parent = Body,
	})
	text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 12,
		Text = tostring(description or ""),
		TextWrapped = true,
		LayoutOrder = 2,
		Theme = { TextColor3 = "SubText" },
		Parent = Body,
	})
	local Track = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 11, 1, -7),
		Size = UDim2.new(1, -22, 0, 2),
		Theme = { BackgroundColor3 = "Divider" },
		Parent = Card,
	}, { corner(1) })
	local Fill = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Track,
	}, { corner(1) })

	local entries = fadeEntries(Card)
	for _, entry in ipairs(entries) do
		entry[1][entry[2]] = 1
	end
	task.defer(function()
		for _, entry in ipairs(entries) do
			tween(entry[1], { [entry[2]] = entry[3] }, POP_IN)
		end
		tween(Slot, { Size = UDim2.new(1, 0, 0, Card.AbsoluteSize.Y) }, TWEEN_SMOOTH)
		tween(Card, { Position = UDim2.fromOffset(0, 0) }, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
		tween(Fill, { Size = UDim2.fromScale(0, 1) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))
	end)

	local gone = false
	local function dismiss()
		if gone then
			return
		end
		gone = true
		for _, entry in ipairs(entries) do
			tween(entry[1], { [entry[2]] = 1 }, POP_OUT)
		end
		tween(Card, { Position = UDim2.fromOffset(320, 0) }, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In)).Completed:Wait()
		tween(Slot, { Size = UDim2.new(1, 0, 0, 0) }, TWEEN_SMOOTH).Completed:Wait()
		Slot:Destroy()
	end
	Card.InputBegan:Connect(function(input)
		if isPointer(input) then
			task.spawn(dismiss)
		end
	end)
	task.delay(duration, dismiss)
end

local function hasFileApi()
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(listfiles) == "function"
end
local function ensureFolder(path)
	local current = ""
	for part in path:gmatch("[^/]+") do
		current = current == "" and part or (current .. "/" .. part)
		if not isfolder(current) then
			makefolder(current)
		end
	end
end

local function cleanName(name)
	return (tostring(name or ""):gsub("[^%w%-_ ]", ""))
end

function Library:SetFolder(folder)
	self.Folder = folder
end

function Library:_configPath(name)
	return self.Folder .. "/configs/" .. name .. ".json"
end

function Library:SaveConfig(name)
	if not hasFileApi() then
		return false, "Your executor can't save files."
	end
	name = cleanName(name)
	if name == "" then
		return false, "Enter a config name first."
	end
	local objects = {}
	for id, option in pairs(self.Options) do
		if option.Save then
			local value = option.Value
			if option.Type == "Keybind" then
				value = option.Value and option.Value.Name or "None"
			elseif option.Type == "ColorPicker" then
				value = { hex = toHex(option.Value), transparency = option.Transparency }
			end
			table.insert(objects, { type = option.Type, idx = id, value = value })
		end
	end
	table.sort(objects, function(a, b)
		return tostring(a.idx) < tostring(b.idx)
	end)
	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode({ objects = objects })
	end)
	if not okEncode then
		return false, "Couldn't encode the config: " .. tostring(encoded)
	end
	local path = self:_configPath(name)
	local ok, err = pcall(function()
		ensureFolder(self.Folder .. "/configs")
		writefile(path, encoded)
	end)
	if not ok then
		return false, "Couldn't write the file: " .. tostring(err)
	end

	local okRead, back = pcall(readfile, path)
	if not okRead or back ~= encoded then
		return false, "The config file didn't save correctly."
	end
	return true, name
end

function Library:LoadConfig(name)
	if not hasFileApi() then
		return false, "Your executor can't read files."
	end
	local path = self:_configPath(cleanName(name))
	if not isfile(path) then
		return false, "Config not found."
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" then
		return false, "That config file is corrupted."
	end

	local entries = data
	if type(data.objects) == "table" then
		entries = {}
		for _, object in ipairs(data.objects) do
			if type(object) == "table" and object.idx ~= nil then
				entries[object.idx] = object.value
			end
		end
	end
	local toggles, applied = {}, 0
	for id, value in pairs(entries) do
		local option = self.Options[id]
		if option and option.Save then
			if option.Type == "Toggle" then
				toggles[id] = value
			else
				pcall(option.SetValue, option, value)
				applied = applied + 1
			end
		end
	end
	for id, value in pairs(toggles) do
		pcall(self.Options[id].SetValue, self.Options[id], value)
		applied = applied + 1
	end
	return true, applied
end

function Library:DeleteConfig(name)
	if not hasFileApi() or type(delfile) ~= "function" then
		return false, "Your executor can't delete files."
	end
	local path = self:_configPath(cleanName(name))
	if not isfile(path) then
		return false, "Config not found."
	end
	delfile(path)
	return true
end

function Library:ListConfigs()
	local folder = self.Folder .. "/configs"
	if not hasFileApi() or not isfolder(folder) then
		return {}
	end
	local names = {}
	for _, path in ipairs(listfiles(folder)) do
		local name = path:match("([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function Library:SetAutoload(name)
	if not hasFileApi() then
		return
	end
	ensureFolder(self.Folder)
	writefile(self.Folder .. "/autoload.txt", cleanName(name))
end

function Library:GetAutoload()
	local path = self.Folder .. "/autoload.txt"
	if hasFileApi() and isfile(path) then
		local name = readfile(path)
		return name ~= "" and name or nil
	end
	return nil
end

function Library:SetSilentLoad(enabled)
	self.SilentLoad = enabled == true
	if not hasFileApi() then
		return
	end
	pcall(function()
		ensureFolder(self.Folder)
		writefile(self.Folder .. "/silent_load.txt", self.SilentLoad and "1" or "0")
	end)
end

function Library:GetSilentLoad()
	if hasFileApi() then
		local path = self.Folder .. "/silent_load.txt"
		local ok, data = pcall(function()
			return isfile(path) and readfile(path) or nil
		end)
		if ok and data then
			return data == "1"
		end
	end
	return self.SilentLoad == true
end

function Library:LoadAutoload()
	local name = self:GetAutoload()
	if not name then
		return
	end
	local ok, result = self:LoadConfig(name)
	if ok then
		self:Notify("Dexori", "Auto loaded config \"" .. name .. "\".")
	else
		self:Notify("Dexori", "Failed to load autoload config \"" .. name .. "\": " .. tostring(result))
	end
end

function Library:BuildSettingsTab(window, name, section)
	if section ~= false and window.AddSection and window.Section ~= (section or "Other") then
		window:AddSection(section or "Other")
	end
	local Tab = window:AddTab(name or "Settings", "settings")

	local Menu = Tab:AddLeftGroupbox("Menu")
	local MenuKey = Menu:AddKeybind("MenuKeybind", {
		Text = "Menu key",
		Default = self.ToggleKey and self.ToggleKey.Name or "RightControl",
		Mode = "Press",
		ShowInList = false,
	})
	MenuKey:OnChanged(function(key)
		Library:SetToggleKey(key)
	end)
	Menu:AddToggle("KeybindList", {
		Text = "Keybind list",
		Default = self.KeybindListEnabled,
		Callback = function(enabled)
			Library:SetKeybindList(enabled)
		end,
	})
	Menu:AddToggle("Watermark", {
		Text = "Watermark",
		Default = self.WatermarkEnabled,
		Callback = function(enabled)
			Library:SetWatermark(enabled)
		end,
	})
	if hasFileApi() then
		Menu:AddToggle("SilentLoad", {
			Text = "Silent load",
			Description = "Start with the menu hidden",
			Default = self:GetSilentLoad(),
			Save = false,
			Callback = function(enabled)
				Library:SetSilentLoad(enabled)
			end,
		})
	end
	Menu:AddDropdown("UIScale", {
		Text = "UI scale",
		Values = { "75%", "90%", "100%", "110%", "125%" },
		Default = "100%",
		Callback = function(value)
			Library:SetScale(tonumber((value:gsub("%%", ""))) / 100)
		end,
	})
	Menu:AddDivider()
	Menu:AddButton({
		Text = "Unload",
		Func = function()
			Library:Unload()
		end,
	})

	local Configs = Tab:AddRightGroupbox("Configs")
	if not hasFileApi() then
		Configs:AddLabel("Your executor can't save files, so configs aren't available.")
		return Tab
	end

	local function iconButton(parent, iconName, tip, props)
		props = props or {}
		local Edge = stroke("Border")
		local Button = create("TextButton", {
			AnchorPoint = props.AnchorPoint or Vector2.zero,
			Position = props.Position or UDim2.new(),
			Size = UDim2.fromOffset(props.Size or 26, props.Size or 26),
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = props.LayoutOrder or 0,
			BackgroundTransparency = props.Filled and 0 or 1,
			Theme = { BackgroundColor3 = props.Filled and "Field" or "Panel" },
			Parent = parent,
		}, { corner(7), Edge })
		Edge.Enabled = props.Filled == true
		pressScale(Button)
		local Glyph = icon(Button, iconName, props.IconSize or 13, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		})
		local state = { hot = false, lit = false, danger = false }
		local function paint()
			local T = Library.Theme
			local color = (state.lit or state.danger) and T.Accent or (state.hot and T.Text or T.Muted)
			tween(Glyph, { ImageColor3 = color })
			if props.Filled then
				tween(Edge, { Color = (state.danger or state.hot) and (state.danger and T.Accent or T.BorderLight) or T.Border })
			else
				tween(Button, { BackgroundTransparency = state.hot and 0 or 1, BackgroundColor3 = T.Hover })
			end
		end
		table.insert(ThemeCallbacks, paint)
		paint()
		Button.MouseEnter:Connect(function()
			state.hot = true
			paint()
		end)
		Button.MouseLeave:Connect(function()
			state.hot = false
			paint()
		end)
		attachTooltip(Button, tip)
		return Button, function(key, value)
			state[key] = value
			paint()
		end
	end

	local NameRow = Configs:_holder(30)
	local NameEdge = stroke("Border")
	local NameField = create("Frame", {
		Size = UDim2.new(1, -38, 1, 0),
		Theme = { BackgroundColor3 = "Field" },
		Parent = NameRow,
	}, { corner(7), NameEdge })
	local NameBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Text = "",
		PlaceholderText = "New config name",
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		FontFace = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = NameField,
	})
	NameBox.Focused:Connect(function()
		tween(NameEdge, { Color = Library.Theme.Accent })
	end)
	NameBox.FocusLost:Connect(function()
		tween(NameEdge, { Color = Library.Theme.Border })
	end)
	local CreateButton = iconButton(NameRow, "plus", "Save a new config", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = 30,
		IconSize = 15,
		Filled = true,
	})
	Configs:_index("Create config", NameRow, NameRow)

	Configs.Rows = 0
	local Head = Configs:_holder(18)
	local HeadText = text({
		Size = UDim2.new(1, -30, 1, 0),
		FontFace = FONT_BOLD,
		TextSize = 10,
		KeepCase = true,
		Theme = { TextColor3 = "Muted" },
		Parent = Head,
	})
	local RefreshButton = iconButton(Head, "refresh-cw", "Refresh the list", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = 22,
		IconSize = 12,
	})

	Configs.Rows = 0
	local ListHolder = Configs:_holder()
	local ListFrame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = ListHolder,
	}, { list(5) })

	local rows = {}
	local refresh
	local function notify(message)
		Library:Notify(Library.Title or "Dexori", message)
	end

	local function configRow(name, index, autoload)
		local Row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			LayoutOrder = index,
			Theme = { BackgroundColor3 = "Field" },
			Parent = ListFrame,
		}, { corner(8), stroke("Border") })
		icon(Row, "folder", 13, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 11, 0.5, 0),
			Theme = { ImageColor3 = autoload and "Accent" or "Muted" },
		})
		local Name = create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(1, -150, 1, 0),
			Parent = Row,
		})
		text({
			Size = UDim2.fromScale(1, 1),
			FontFace = FONT_MEDIUM,
			TextSize = 13,
			Text = name,
			TextTruncate = Enum.TextTruncate.AtEnd,
			KeepCase = true,
			Theme = { TextColor3 = autoload and "Accent" or "Text" },
			Parent = Name,
		})
		local Actions = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -5, 0.5, 0),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = Row,
		}, { list(2, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local Load = iconButton(Actions, "play", "Load", { LayoutOrder = 1 })
		local Save = iconButton(Actions, "save", "Overwrite with current settings", { LayoutOrder = 2 })
		local Star, setStar = iconButton(Actions, "star", autoload and "Stop autoloading" or "Load this on start", { LayoutOrder = 3 })
		setStar("lit", autoload)
		local Delete, setDelete = iconButton(Actions, "trash-2", "Delete (click twice)", { LayoutOrder = 4 })

		Load.MouseButton1Click:Connect(function()
			local ok, result = Library:LoadConfig(name)
			notify(ok and ("Loaded \"" .. name .. "\" (" .. tostring(result) .. " settings).") or ("Couldn't load: " .. tostring(result)))
		end)
		Save.MouseButton1Click:Connect(function()
			local ok, result = Library:SaveConfig(name)
			notify(ok and ("Saved over \"" .. name .. "\".") or ("Couldn't save: " .. tostring(result)))
		end)
		Star.MouseButton1Click:Connect(function()
			if autoload then
				Library:SetAutoload("")
				notify("\"" .. name .. "\" won't load on start any more.")
			else
				Library:SetAutoload(name)
				notify("\"" .. name .. "\" will load on start.")
			end
			refresh()
		end)
		local armedUntil = 0
		Delete.MouseButton1Click:Connect(function()
			if os.clock() > armedUntil then
				armedUntil = os.clock() + 2.5
				setDelete("danger", true)
				task.delay(2.5, function()
					if os.clock() >= armedUntil and Delete.Parent then
						setDelete("danger", false)
					end
				end)
				return
			end
			local ok, err = Library:DeleteConfig(name)
			if ok and autoload then
				Library:SetAutoload("")
			end
			notify(ok and ("Deleted \"" .. name .. "\".") or ("Couldn't delete: " .. tostring(err)))
			refresh()
		end)
		return Row
	end

	refresh = function()
		for _, row in ipairs(rows) do
			row:Destroy()
		end
		rows = {}
		local names = Library:ListConfigs()
		local current = Library:GetAutoload()
		HeadText.Text = "SAVED CONFIGS · " .. #names
		for index, name in ipairs(names) do
			table.insert(rows, configRow(name, index, name == current))
		end
		if #names == 0 then
			table.insert(rows, text({
				Size = UDim2.new(1, 0, 0, 34),
				TextSize = 12,
				Text = "No configs yet. Name one above and press +.",
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				Theme = { TextColor3 = "Muted" },
				Parent = ListFrame,
			}))
		end
	end

	local function createConfig()
		if cleanName(NameBox.Text) == "" then
			notify("Type a config name first.")
			return
		end
		local ok, result = Library:SaveConfig(NameBox.Text)
		if not ok then
			notify("Couldn't save: " .. tostring(result))
			return
		end
		NameBox.Text = ""
		notify("Saved \"" .. result .. "\".")
		refresh()
	end
	CreateButton.MouseButton1Click:Connect(createConfig)
	NameBox.FocusLost:Connect(function(enter)
		if enter then
			createConfig()
		end
	end)
	RefreshButton.MouseButton1Click:Connect(refresh)
	refresh()

	return Tab
end

function Library:OnUnload(fn)
	table.insert(UnloadCallbacks, fn)
end

function Library:Unload()
	if self.Unloaded then
		return
	end
	self.Unloaded = true
	for _, fn in ipairs(UnloadCallbacks) do
		local ok, err = pcall(fn)
		if not ok then
			warn("[Dexori UI] Unload callback error: " .. tostring(err))
		end
	end
	for _, connection in ipairs(Connections) do
		connection:Disconnect()
	end
	local gui = self.ScreenGui
	if not gui then
		return
	end
	if self.Window then
		self.Window:Toggle(false)
	end
	hideTooltip()
	for _, target in ipairs({ self.Watermark, self.KeybindPanel, self.MobileButton, self.NotifyHolder }) do
		if target then
			popout(target, false)
		end
	end
	task.delay(0.24, function()
		for _, loop in ipairs(Loops) do
			loop:Cancel()
		end
		table.clear(Loops)
		gui:Destroy()
	end)
end

return Library
