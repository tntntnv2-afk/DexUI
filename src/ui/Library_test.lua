local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local Library = {
	Name = "Dexori",
	Version = "1.0.0-dev",
	Repo = "https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/",
	Options = {},
	Unloaded = false,
	Picking = false,
	Folder = "Dexori",
	UserScale = 1,
	GlowEnabled = true,
	RowDividers = true,
	KeybindListEnabled = true,
	WatermarkEnabled = true,
	Lowercase = false,
	Theme = {
		Background = Color3.fromHex("0c0c0d"),
		Chrome = Color3.fromHex("080809"),
		Panel = Color3.fromHex("111113"),
		Field = Color3.fromHex("101012"),
		Button = Color3.fromHex("151517"),
		Hover = Color3.fromHex("121214"),
		Outline = Color3.fromHex("000000"),
		Divider = Color3.fromHex("18181b"),
		Border = Color3.fromHex("1c1c20"),
		BorderLight = Color3.fromHex("29292e"),
		Text = Color3.fromHex("ecebee"),
		SubText = Color3.fromHex("adabb3"),
		Muted = Color3.fromHex("7b7983"),
		Accent = Color3.fromHex("2563eb"),
		Toggle = Color3.fromHex("2a2a30"),
	},
	AccentPresets = {
		Blue = Color3.fromHex("2563eb"),
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

local idleConnection
local function guardIdle()
	if not LocalPlayer then
		return
	end
	if idleConnection then
		idleConnection:Disconnect()
		idleConnection = nil
	end
	if type(getconnections) == "function" then
		pcall(function()
			local disabled = {}
			for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
				if connection.Disable and connection.Enable then
					connection:Disable()
					table.insert(disabled, connection)
				end
			end
			table.insert(UnloadCallbacks, function()
				for _, connection in ipairs(disabled) do
					pcall(connection.Enable, connection)
				end
			end)
		end)
	end
	local okUser, VirtualUser = pcall(game.GetService, game, "VirtualUser")
	if okUser and VirtualUser then
		idleConnection = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
		table.insert(Connections, idleConnection)
	end
end
guardIdle()

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local FONT = Font.new(FAMILY, Enum.FontWeight.Medium)
local FONT_MEDIUM = Font.new(FAMILY, Enum.FontWeight.SemiBold)
local FONT_SEMI = Font.new(FAMILY, Enum.FontWeight.SemiBold)
local FONT_BOLD = Font.new(FAMILY, Enum.FontWeight.Bold)
local FONT_MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)

local RADIUS = 8
local WINDOW_RADIUS = 12
local TITLEBAR = 36
local TABBAR = 28
local STATUSBAR = 26
local ROW_PAD = 3


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
			Registry[instance] = value
			instance.Destroying:Connect(function()
				Registry[instance] = nil
			end)
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
		local s = Library.Scale and Library.Scale.Scale or 1
		s = s > 0 and s or 1
		local reach = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2 / s
		local Wave = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset((input.Position.X - origin.X) / s, (input.Position.Y - origin.Y) / s),
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
	button.MouseLeave:Connect(function()
		if Scale.Scale ~= 1 then
			TweenService:Create(Scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play()
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
			if instance:IsA(pair[1]) then
				local value = instance[pair[2]]
				if type(value) == "number" and value < 1 then
					table.insert(entries, { instance, pair[2], value })
				end
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

local MOUSE_BINDS = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
}

local function validKey(key)
	if typeof(key) ~= "EnumItem" then
		return nil
	end
	if key.EnumType == Enum.KeyCode then
		return key ~= Enum.KeyCode.Unknown and key or nil
	end
	return MOUSE_BINDS[key] and key or nil
end

local function parseKey(value)
	if typeof(value) == "EnumItem" then
		return validKey(value)
	end
	if type(value) ~= "string" or value == "" or value == "None" then
		return nil
	end
	value = KEY_ALIASES[value] or value
	local ok, key = pcall(function()
		return Enum.KeyCode[value]
	end)
	if ok and key then
		return validKey(key)
	end
	ok, key = pcall(function()
		return Enum.UserInputType[value]
	end)
	if ok and key then
		return validKey(key)
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

local function isTyping()
	if UserInputService:GetFocusedTextBox() then
		return true
	end
	local ok, focused = pcall(function()
		local bar = game:GetService("TextChatService"):FindFirstChildOfClass("ChatInputBarConfiguration")
		return bar ~= nil and bar.IsFocused
	end)
	return ok and focused == true
end

local function inputBlocked(input, processed)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		return GuiService.MenuIsOpen or isTyping()
	end
	return processed
end

local function sameDrag(began, input, ending)
	if began.UserInputType == Enum.UserInputType.Touch then
		return input == began
	end
	return input.UserInputType == (ending and Enum.UserInputType.MouseButton1 or Enum.UserInputType.MouseMovement)
end

local function truthy(value)
	if type(value) == "string" then
		value = string.lower(value)
		return value == "true" or value == "on" or value == "yes" or value == "1"
	end
	return value ~= nil and value ~= false and value ~= 0
end

local activeDrag
local function endDrag()
	local drag = activeDrag
	if not drag then
		return
	end
	activeDrag = nil
	if drag.Column then
		drag.Column.ScrollingEnabled = true
	end
	if drag.Stop then
		drag.Stop()
	end
end
connect(UserInputService.InputChanged, function(input)
	if activeDrag and sameDrag(activeDrag.Input, input) then
		activeDrag.Move(input)
	end
end)
connect(UserInputService.InputEnded, function(input)
	if activeDrag and sameDrag(activeDrag.Input, input, true) then
		endDrag()
	end
end)
connect(UserInputService.WindowFocusReleased, endDrag)

local function beginDrag(input, move, stop, column)
	endDrag()
	activeDrag = { Input = input, Move = move, Stop = stop, Column = column }
	if column and input.UserInputType == Enum.UserInputType.Touch then
		column.ScrollingEnabled = false
	end
	move(input)
end

local function themed(instance, paint)
	table.insert(ThemeCallbacks, paint)
	instance.Destroying:Connect(function()
		local index = table.find(ThemeCallbacks, paint)
		if index then
			table.remove(ThemeCallbacks, index)
		end
	end)
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

local tooltipOwner
local function placeTooltip(x, y)
	local Tooltip = Library.Tooltip
	local gui = Library.ScreenGui
	if not Tooltip or not gui then
		return
	end
	local view, size = gui.AbsoluteSize, Tooltip.AbsoluteSize
	Tooltip.Position = UDim2.fromOffset(
		math.clamp(x + 14, 0, math.max(view.X - size.X - 4, 0)),
		math.clamp(y + 16, 0, math.max(view.Y - size.Y - 4, 0))
	)
end

local function attachTooltip(target, tip)
	if not tip then
		return
	end
	target.MouseEnter:Connect(function()
		local Tooltip = Library.Tooltip
		if Tooltip then
			local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			tooltipOwner = target
			Tooltip.Text = tostring(tip)
			placeTooltip(mouse.X, mouse.Y)
			popout(Tooltip, true)
		end
	end)
	target.MouseLeave:Connect(function()
		if tooltipOwner == target then
			tooltipOwner = nil
			hideTooltip()
		end
	end)
	target.Destroying:Connect(function()
		if tooltipOwner == target then
			tooltipOwner = nil
			hideTooltip()
		end
	end)
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
Library:DefineAsset("Wordmark", { Path = "assets/dexori_d_anim_blue.png", Version = 1, Sheet = LOGO_SHEET })
Library:DefineAsset("Icon", { Path = "assets/dexori_d_anim_blue.png", Version = 1, Sheet = LOGO_SHEET })

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
	for key, value in pairs(changes or {}) do
		if typeof(value) == "Color3" and (key ~= "Accent" or not self.ForceAccent) then
			self.Theme[key] = value
		end
	end
	for instance, map in pairs(Registry) do
		for property, themeKey in pairs(map) do
			instance[property] = self.Theme[themeKey]
		end
	end
	for _, paint in ipairs(table.clone(ThemeCallbacks)) do
		local ok, err = pcall(paint)
		if not ok then
			warn("[Dexori UI] Theme error: " .. tostring(err))
		end
	end
end

function Library:SetScale(scale)
	scale = tonumber(scale)
	if not scale or scale ~= scale then
		return self.UserScale
	end
	scale = math.clamp(scale, 0.5, 2)
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
	opts = opts or {}
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
	option.Mode = (opts.Mode == "Hold" or opts.Mode == "Press") and opts.Mode or "Toggle"
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
	themed(Chip, paintChip)
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

	function option:SetValue(key, mode)
		if type(key) == "table" and typeof(key) ~= "EnumItem" then
			key, mode = key[1] or key.Key, key[2] or key.Mode
		end
		local parsed = parseKey(key)
		if parsed == nil and not (key == nil or key == false or key == "" or key == "None") then
			return false
		end
		if self.Mode == "Hold" and self.State then
			self.State = false
			fire(opts.Callback, false)
			if onRelease then
				onRelease()
			end
		end
		if mode == "Toggle" or mode == "Hold" or mode == "Press" then
			self.Mode = mode
		end
		self.Value = parsed
		display()
		for _, fn in ipairs(self.Changed) do
			fire(fn, self.Value)
		end
		refreshKeybinds()
		return true
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
				if input.KeyCode == Enum.KeyCode.Unknown then
					return
				end
				local clear = input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace
				option:SetValue(not clear and input.KeyCode or nil)
			elseif kind == Enum.UserInputType.MouseButton2 or kind == Enum.UserInputType.MouseButton3 then
				option:SetValue(kind)
			elseif kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
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

		if Library.Picking or not inputMatches(input, option.Value) or inputBlocked(input, processed) then
			return
		end
		if onPress then
			onPress()
		end
		if option.Mode == "Toggle" then
			if meta.GetState then
				option.State = meta.GetState() == true
			else
				option.State = not option.State
			end
			fire(opts.Callback, option.State)
		elseif option.Mode == "Hold" then
			option.State = true
			fire(opts.Callback, true)
		else
			fire(opts.Callback)
			entry.PulseUntil = os.clock() + 0.3
			task.delay(0.32, refreshKeybinds)
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

local function glyph(parent, name, size, props, fallback)
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
	local Backup = fallback and fallback(Holder) or nil
	local Image = icon(Holder, name, size, props)
	if Backup then
		task.spawn(function()
			if Library:GetAsset("Icons") and Backup.Parent then
				Backup:Destroy()
			end
		end)
	end
	return Holder, Image
end

local function chevron(parent)
	return glyph(parent, "chevron-down", 12, { Theme = { ImageColor3 = "SubText" } }, function(Holder)
		return text({
			Size = UDim2.fromScale(1, 1),
			Text = "v",
			FontFace = FONT_BOLD,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			KeepCase = true,
			Theme = { TextColor3 = "SubText" },
			Parent = Holder,
		})
	end)
end

local function magnifier(parent)
	return glyph(parent, "search", 12, { Theme = { ImageColor3 = "SubText" } }, function(Holder)
		return create("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.fromOffset(8, 8),
			Parent = Holder,
		}, { round(), create("UIStroke", { Thickness = 1.4, Theme = { Color = "SubText" } }) })
	end)
end

local function tickMark(parent)
	local Tick = glyph(parent, "check", 10, { Color = Color3.new(1, 1, 1) }, function(Holder)
		return create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = Holder,
		}, { corner(2) })
	end)
	Tick.AnchorPoint = Vector2.new(0.5, 0.5)
	Tick.Position = UDim2.fromScale(0.5, 0.5)
	return create("UIScale", { Scale = 0, Parent = Tick })
end

local function toHex(color)
	return string.format("#%02X%02X%02X", math.floor(color.R * 255 + 0.5), math.floor(color.G * 255 + 0.5), math.floor(color.B * 255 + 0.5))
end

local function fromHex(value)
	local hex = tostring(value or ""):gsub("[#%s]", "")
	if #hex == 3 then
		hex = hex:gsub(".", "%0%0")
	elseif #hex == 8 then
		hex = hex:sub(1, 6)
	end
	if not hex:match("^%x%x%x%x%x%x$") then
		return nil
	end
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
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
	local alive = true
	frame.InputBegan:Connect(function(input)
		if alive and isPointer(input) and (not canStart or canStart(input)) then
			local dragStart, startPos = input.Position, frame.Position
			beginDrag(input, function(moved)
				local delta = moved.Position - dragStart
				frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end)
		end
	end)
	return function()
		alive = false
	end
end

local function fitCanvas(scroll, layout, horizontal, extra)
	local function fit()
		local size = layout.AbsoluteContentSize
		local s = scaleFactor()
		if horizontal then
			scroll.CanvasSize = UDim2.fromOffset(math.ceil(size.X / s) + extra, 0)
		else
			scroll.CanvasSize = UDim2.fromOffset(0, math.ceil(size.Y / s) + extra)
		end
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	table.insert(ScaleHooks, fit)
	fit()
end

local function reveal(anchor, height, gap)
	local scroller = anchor:FindFirstAncestorWhichIsA("ScrollingFrame")
	if not scroller then
		return
	end
	local s = scaleFactor()
	local bottom = anchor.AbsolutePosition.Y + anchor.AbsoluteSize.Y - scroller.AbsolutePosition.Y + (height + (gap or 0) + 8) * s
	local over = bottom - scroller.AbsoluteWindowSize.Y
	if over > 0 then
		tween(scroller, { CanvasPosition = scroller.CanvasPosition + Vector2.new(0, over) }, TWEEN_SMOOTH)
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

local function attachColorPicker(group, slotParent, id, opts, holder)
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
		LayoutOrder = holder and holder:GetAttribute("PanelOrder") or group:_next(),
		Theme = { BackgroundColor3 = "Background" },
		Parent = group.Container,
	}, { corner(10), stroke("BorderLight") })
	local holderOrder = holder and holder.LayoutOrder
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
	local SvShade = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		ZIndex = 4,
		Parent = Sv,
	}, { round(), create("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.5, Thickness = 1 }) })
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
		SvShade.Position = SvCursor.Position
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
		local color = Color3.fromHSV(h, s, v)
		local same = toHex(color) == toHex(option.Value)
		option.Value = color
		render()
		if not same then
			option:_emit()
		end
	end

	function option:SetValue(value, transparency)
		local color, saved = readColor(value)
		if not color then
			return
		end
		local t = tonumber(transparency) or saved
		local unchanged = toHex(color) == toHex(self.Value)
		if t and t == t and hasAlpha then
			t = math.clamp(t, 0, 1)
			unchanged = unchanged and t == self.Transparency
			self.Transparency = t
		end
		self.Value = color
		local nh, ns, nv = color:ToHSV()
		if nv > 0 and ns > 0 then
			h = nh
		end
		if nv > 0 then
			s = ns
		end
		v = nv
		render()
		if not unchanged then
			self:_emit()
		end
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
			local t = math.floor(math.clamp((position.X - at.X) / math.max(size.X, 1), 0, 1) * 100 + 0.5) / 100
			if t ~= option.Transparency then
				option.Transparency = t
				render()
				option:_emit()
			end
		end
	end
	local function grab(hit, kind)
		hit.InputBegan:Connect(function(input)
			if isPointer(input) then
				dragKind = kind
				beginDrag(input, function(moved)
					apply(kind, moved.Position)
				end, function()
					dragKind = nil
				end, hit:FindFirstAncestorWhichIsA("ScrollingFrame"))
			end
		end)
	end
	grab(SvHit, "sv")
	grab(HueHit, "hue")
	if AlphaHit then
		grab(AlphaHit, "alpha")
	end
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
			if holder then
				if holder.Parent and Panel.Parent ~= holder.Parent then
					Panel.Parent = holder.Parent
				end
				if holder.LayoutOrder ~= holderOrder then
					Panel.LayoutOrder = holder.LayoutOrder
				end
			end
			if not Panel.Visible then
				Panel.Size = UDim2.new(1, 0, 0, 0)
				Panel.Visible = true
			end
			tween(Panel, { Size = UDim2.new(1, 0, 0, fullHeight) }, TWEEN_SMOOTH)
			task.defer(reveal, holder or Swatch, fullHeight, 0)
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
	themed(Swatch, function()
		SwatchEdge.Color = open and Library.Theme.Accent or Library.Theme.BorderLight
	end)
	Swatch:SetAttribute("DexoriNoSheen", true)
	Preview:SetAttribute("DexoriNoSheen", true)
	Sv:SetAttribute("DexoriNoSheen", true)
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

local function followSlots(row, Slots, estimate)
	local function fit()
		local width = Slots.AbsoluteSize.X / scaleFactor()
		if width <= 0 then
			width = estimate and estimate() or 0
		end
		row.Width(1, math.ceil(width) + 8)
	end
	Slots:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	return fit
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

local function relayoutRows(container)
	local items = {}
	for index, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			table.insert(items, { child, index })
		end
	end
	table.sort(items, function(a, b)
		if a[1].LayoutOrder ~= b[1].LayoutOrder then
			return a[1].LayoutOrder < b[1].LayoutOrder
		end
		return a[2] < b[2]
	end)
	local open = false
	for _, item in ipairs(items) do
		local child = item[1]
		local line = child:FindFirstChild("RowDivider")
		if line then
			line.Visible = open and Library.RowDividers ~= false
			if child.Visible then
				open = true
			end
		elseif child.Visible then
			open = child:GetAttribute("DexoriBreak") ~= true
		end
	end
end

local function watchRows(container)
	local pending = false
	local function schedule()
		if pending then
			return
		end
		pending = true
		task.defer(function()
			pending = false
			if container.Parent then
				relayoutRows(container)
			end
		end)
	end
	local function track(child)
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(schedule)
			child:GetPropertyChangedSignal("LayoutOrder"):Connect(schedule)
		end
		schedule()
	end
	for _, child in ipairs(container:GetChildren()) do
		track(child)
	end
	container.ChildAdded:Connect(track)
	container.ChildRemoved:Connect(schedule)
end

function Elements:_holder(height, plain)
	self:_separator()
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, height and height + ROW_PAD * 2 or 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Container,
	}, { padding(ROW_PAD, 0, ROW_PAD, 0) })
	Holder:SetAttribute("PanelOrder", self:_next())
	if not plain then
		create("Frame", {
			Name = "RowDivider",
			Position = UDim2.fromOffset(0, -ROW_PAD),
			Size = UDim2.new(1, 0, 0, 1),
			Visible = false,
			Theme = { BackgroundColor3 = "Divider" },
			Parent = Holder,
		})
	end
	return Holder
end

function Elements:_index(name, holder, flashTarget)
	if name == nil or name == "" then
		return nil
	end
	local entry = { Name = tostring(name), Holder = holder, Flash = flashTarget, Tab = self.Tab, Column = self.Column, Group = self }
	table.insert(SearchIndex, entry)
	return entry
end

local function described(opts)
	return type(opts.Description) == "string" and opts.Description ~= ""
end

local function rowHeight(opts, minimum)
	return math.max(described(opts) and 36 or 26, minimum or 0)
end

local function stacked(opts)
	if opts.Stacked ~= nil then
		return opts.Stacked == true
	end
	return type(opts.Text) == "string" and (utf8.len(opts.Text) or #opts.Text) > 15
end

local function rowText(parent, opts, fallback, widthScale, widthOffset)
	local hasDescription = described(opts)
	local Label = text({
		AnchorPoint = Vector2.new(0, hasDescription and 0 or 0.5),
		Position = hasDescription and UDim2.fromOffset(0, 1) or UDim2.fromScale(0, 0.5),
		Size = UDim2.new(widthScale or 1, -(widthOffset or 0), 0, 18),
		Text = opts.Text or fallback or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
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
		Label.Text = tostring(newText or "")
	end
	function object:AddColorPicker(pickerId, pickerOpts)
		if not Slots then
			local Pad = create("UIPadding", { PaddingRight = UDim.new(0, 40), Parent = Label })
			Slots = create("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 40, 0, 0),
				Size = UDim2.fromOffset(0, 18),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Parent = Label,
			}, { list(6, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
			Slots:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local width = math.ceil(Slots.AbsoluteSize.X / scaleFactor())
				if width > 0 then
					Pad.PaddingRight = UDim.new(0, width + 12)
					Slots.Position = UDim2.new(1, width + 12, 0, 0)
				end
			end)
		end
		pickerOpts = pickerOpts or {}
		pickerOpts.Text = pickerOpts.Text or Label.Text
		return attachColorPicker(group, Slots, pickerId, pickerOpts, Holder)
	end
	return object
end

function Elements:AddDivider(label)
	if label then
		local Holder = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = self:_next(),
			Parent = self.Container,
		})
		Holder:SetAttribute("DexoriBreak", true)
		local Line = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, 1),
			Theme = { BackgroundColor3 = "BorderLight" },
			Parent = Holder,
		})
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = Line,
		})
		local Tag = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			Theme = { BackgroundColor3 = "Chrome" },
			Parent = Holder,
		}, { padding(0, 8, 0, 8) })
		text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			FontFace = FONT_SEMI,
			TextSize = 12,
			Text = label,
			Theme = { TextColor3 = "Muted" },
			Parent = Tag,
		})
		self.Rows = 0
		return
	end
	local Holder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 7),
		LayoutOrder = self:_next(),
		Parent = self.Container,
	})
	Holder:SetAttribute("DexoriBreak", true)
	local Line = create("Frame", {
		Position = UDim2.fromOffset(0, 3),
		Size = UDim2.new(1, 0, 0, 1),
		Theme = { BackgroundColor3 = "BorderLight" },
		Parent = Holder,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Line,
	})
	self.Rows = 0
end

function Elements:AddCustom(height)
	local Holder = self:_holder(height or 120)
	return create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ClipsDescendants = true,
		Parent = Holder,
	})
end

function Elements:AddColorPicker(id, opts)
	opts = opts or {}
	local Holder = self:_holder(rowHeight(opts))
	rowText(Holder, opts, id, 1, 44)
	local option = attachColorPicker(self, slotRow(Holder), id, opts, Holder)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

local TextService = game:GetService("TextService")
local textWidths = {}
local textWidthCount = 0
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
		textWidthCount = textWidthCount + 1
		if textWidthCount > 600 then
			table.clear(textWidths)
			textWidthCount = 1
		end
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
		local returned = false
		task.spawn(function()
			local width = measureText(value, font, size)
			if returned then
				onMeasured(width)
			end
		end)
		returned = true
		if textWidths[key] then
			return math.ceil(textWidths[key])
		end
	end
	return math.ceil((utf8.len(value) or #value) * size * 0.52)
end
local function plainButton(parent, label, props)
	local Edge = stroke("BorderLight")
	local Button = create("TextButton", {
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position or UDim2.new(),
		Size = props.Size,
		AutoButtonColor = false,
		FontFace = FONT_MEDIUM,
		TextSize = 13,
		Text = label,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { BackgroundColor3 = "Button", TextColor3 = "Text" },
		Parent = parent,
	}, { corner(), Edge })
	ripple(Button)
	pressScale(Button)
	local hovering = false
	local function paint()
		local T = Library.Theme
		Edge.Color = hovering and T.Accent or T.BorderLight
		Button.BackgroundColor3 = T.Button
	end
	themed(Button, paint)
	Button.MouseEnter:Connect(function()
		hovering = true
		tween(Edge, { Color = Library.Theme.Accent })
	end)
	Button.MouseLeave:Connect(function()
		hovering = false
		tween(Edge, { Color = Library.Theme.BorderLight })
	end)
	return Button
end

function Elements:AddButton(opts, func)
	if type(opts) ~= "table" then
		opts = { Text = opts ~= nil and tostring(opts) or nil, Func = func }
	end
	local labelled = opts.Label ~= nil or described(opts)
	local Holder = self:_holder(labelled and rowHeight(opts, 30) or 30)
	local Button
	if labelled then
		local _, _, row = rowText(Holder, { Text = opts.Label or "", Description = opts.Description }, nil, 1, 0)
		Button = plainButton(Holder, opts.Text or "Button", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(64, 26),
		})
		local lastSize = 0
		local function apply(textSize)
			lastSize = textSize
			local room = Holder.AbsoluteSize.X / scaleFactor()
			local width = math.max(textSize + 28, 64)
			if room > 0 then
				width = math.min(width, math.max(64, math.floor(room * 0.6)))
			end
			Button.Size = UDim2.fromOffset(width, 26)
			row.Width(1, width + 12)
		end
		local function fit()
			local label = Button.Text
			apply(textWidth(label, FONT_MEDIUM, 13, function(measured)
				if Button.Text == label then
					apply(measured)
				end
			end))
		end
		Button:GetPropertyChangedSignal("Text"):Connect(fit)
		Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			apply(lastSize)
		end)
		fit()
	else
		Button = plainButton(Holder, opts.Text or "Button", { Size = UDim2.fromScale(1, 1) })
	end
	Button.MouseButton1Click:Connect(function()
		fire(opts.Func or opts.Callback)
	end)
	attachTooltip(Button, opts.Tooltip)
	local indexed = self:_index(opts.Label or opts.Text or "Button", Holder, Holder)

	local object = { Button = Button }
	function object:SetText(newText)
		Button.Text = tostring(newText or "")
		if indexed and opts.Label == nil then
			indexed.Name = Button.Text
		end
	end
	return object
end

function Elements:AddToggle(id, opts)
	opts = opts or {}
	local option = newOption(id, "Toggle", opts)
	option.Value = truthy(opts.Default)
	local group = self
	local hasDescription = described(opts)

	local Holder = self:_holder(rowHeight(opts))
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
		Position = hasDescription and UDim2.fromOffset(0, 3) or UDim2.fromScale(0, 0.5),
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
	themed(Holder, function()
		paint(false)
	end)
	paint(false)

	function option:SetValue(value)
		value = truthy(value)
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
	local refit
	local function slot(width)
		if not Slots then
			Slots = slotRow(Row)
			refit = followSlots(row, Slots, function()
				return reserve
			end)
		end
		reserve = reserve + width
		refit()
		return Slots
	end

	function option:AddColorPicker(pickerId, pickerOpts)
		pickerOpts = pickerOpts or {}
		pickerOpts.Text = pickerOpts.Text or opts.Text or id
		return attachColorPicker(group, slot(34), pickerId, pickerOpts, Holder)
	end

	function option:AddKeybind(keyId, keyOpts)
		keyOpts = keyOpts or {}
		local key
		local estimate = textWidth(keyName(parseKey(keyOpts.Default)), FONT_SEMI, 12) + 20
		key = newKeybind(keyId, keyOpts, slot(estimate), UDim2.new(1, 0, 0.5, 0), function()
			if key and key.Mode == "Hold" then
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
		return key
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
	opts = opts or {}
	local option = newOption(id, "Slider", opts)
	local group = self
	local min, max = tonumber(opts.Min) or 0, tonumber(opts.Max) or 100
	if min > max then
		min, max = max, min
	end
	local rounding = math.clamp(math.floor(tonumber(opts.Rounding) or 0), 0, 6)
	local suffix = opts.Suffix or ""

	local function snap(value)
		local m = 10 ^ rounding
		return math.floor(value * m + 0.5) / m
	end
	local default = tonumber(opts.Default)
	option.Value = math.clamp(snap(default and default == default and default or min), min, max)

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
		row.Width(1, math.max(Chip.AbsoluteSize.X / (scaleFactor() * math.max(ChipScale.Scale, 0.01)) + 10, 40))
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
		value = tonumber(value)
		if not value or value ~= value then
			return
		end
		value = math.clamp(snap(value), min, max)
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
			beginDrag(input, function(moved)
				update(moved.Position.X)
			end, function()
				dragging = false
				tween(Knob, { Size = UDim2.fromOffset(10, 10) })
				tween(ChipScale, { Scale = 1 })
			end, Hit:FindFirstAncestorWhichIsA("ScrollingFrame"))
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
	display(true)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddStats(stats)
	stats = stats or {}
	local Holder = self:_holder(50)
	local Strip = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = Holder,
	}, { list(6, true) })
	local count = math.max(#stats, 1)
	local cells = {}
	for index, stat in ipairs(stats) do
		local Cell = create("Frame", {
			Size = UDim2.new(1 / count, -math.ceil(6 * (count - 1) / count), 1, 0),
			LayoutOrder = index,
			Theme = { BackgroundColor3 = "Field" },
			Parent = Strip,
		}, { corner(), stroke("BorderLight"), padding(7, 6, 6, 7) })
		local Caption = text({
			Size = UDim2.new(1, 0, 0, 13),
			FontFace = FONT_SEMI,
			TextSize = 11,
			TextScaled = true,
			Text = stat.Label or stat[1] or "",
			Theme = { TextColor3 = "Muted" },
			Parent = Cell,
		})
		create("UITextSizeConstraint", { MaxTextSize = 11, MinTextSize = 8, Parent = Caption })
		local Value = text({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = FONT_SEMI,
			TextSize = 15,
			TextScaled = true,
			Text = tostring(stat.Value or stat[2] or "0"),
			KeepCase = true,
			Theme = { TextColor3 = stat.Accent and "Accent" or "Text" },
			Parent = Cell,
		})
		create("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 9, Parent = Value })
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
		Size = UDim2.new(1, -60, 0, 20),
		Text = opts.Text or id or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Holder,
	})
	local Percent = text({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(60, 20),
		FontFace = FONT_SEMI,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		Theme = { TextColor3 = "SubText" },
		Parent = Holder,
	})
	local Bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(1, 0, 0, 6),
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(3), stroke("BorderLight") })
	local Fill = create("Frame", { Size = UDim2.fromScale(0, 1), Theme = { BackgroundColor3 = "Accent" }, Parent = Bar }, { corner(3) })
	local object = { Value = 0 }
	function object:SetValue(value, instant)
		value = tonumber(value)
		if not value or value ~= value then
			value = 0
		end
		value = math.clamp(value, 0, 1)
		self.Value = value
		local shown = math.floor(value * 100 + 0.5) .. "%"
		if type(opts.Format) == "function" then
			local ok, custom = pcall(opts.Format, value)
			if ok and custom ~= nil then
				shown = tostring(custom)
			end
		end
		Percent.Text = shown
		local function fitPercent(width)
			if Percent.Text == shown then
				Percent.Size = UDim2.fromOffset(width + 4, 20)
				Label.Size = UDim2.new(1, -(width + 12), 0, 20)
			end
		end
		fitPercent(textWidth(shown, FONT_SEMI, 12, fitPercent))
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
	opts = opts or {}
	local option = newOption(id, "Dropdown", opts)
	option.Values = type(opts.Values) == "table" and opts.Values or {}
	option.Multi = opts.Multi == true

	local strict = opts.Strict == true
	local function resolve(value, allowIndex)
		local missing = false
		if option.Multi then
			local set = {}
			local function add(item)
				if not strict or table.find(option.Values, item) then
					set[item] = true
				else
					missing = true
				end
			end
			if type(value) == "table" then
				for key, v in pairs(value) do
					if type(key) == "number" and type(v) ~= "boolean" then
						add(v)
					elseif v == true then
						add(key)
					end
				end
			elseif value ~= nil and value ~= false then
				add(value)
			end
			return set, missing
		end
		if value == false then
			value = nil
		end
		if (allowIndex or not strict) and type(value) == "number" and not table.find(option.Values, value) then
			value = option.Values[value]
		end
		if value == nil then
			if strict and not opts.AllowNull then
				return option.Value, false
			end
			return nil, false
		end
		if strict and not table.find(option.Values, value) then
			return option.Value, true
		end
		return value, false
	end
	if option.Multi then
		option.Value = {}
	end
	do
		local value, missing = resolve(opts.Default, true)
		option.Value = value
		if missing then
			option._wanted = opts.Default
		end
	end

	local function isSelected(value)
		if option.Multi then
			return option.Value[value] == true
		end
		return value == option.Value
	end

	local inline = opts.Text ~= nil and not stacked(opts) and not described(opts)
	local above = opts.Text ~= nil and not inline

	local Holder = self:_holder()
	local Stack = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Holder,
	}, { list(6) })

	if above then
		local Top = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, described(opts) and 34 or 16),
			LayoutOrder = 0,
			Parent = Stack,
		})
		local Label = rowText(Top, opts, nil, 1, 0)
		if not described(opts) then
			Label.AnchorPoint = Vector2.zero
			Label.Position = UDim2.new()
			Label.Size = UDim2.new(1, 0, 1, 0)
		end
	end

	local FieldEdge = stroke("BorderLight")
	local Field = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = 1,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Stack,
	}, { corner(), FieldEdge })
	local FieldLabel
	local labelWidth = 0
	if inline then
		FieldLabel = text({
			Position = UDim2.fromOffset(11, 0),
			Size = UDim2.new(0.5, -11, 1, 0),
			Text = opts.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "SubText" },
			Parent = Field,
		})
	end
	local Selected = text({
		AnchorPoint = Vector2.new(inline and 1 or 0, 0),
		Position = inline and UDim2.new(1, -28, 0, 0) or UDim2.fromOffset(11, 0),
		Size = inline and UDim2.new(0.5, -30, 1, 0) or UDim2.new(1, -40, 1, 0),
		FontFace = FONT_SEMI,
		TextXAlignment = inline and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
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
	local Chevron, ChevronImage = chevron(Field)
	Chevron.AnchorPoint = Vector2.new(0.5, 0.5)
	Chevron.Position = UDim2.new(1, -14, 0.5, 0)

	local Popup = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		ClipsDescendants = true,
		Visible = false,
		LayoutOrder = 2,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Stack,
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

	local function layoutField()
		local shift = Count.Visible and (28 + Count.Size.X.Offset + 6) or 28
		if not inline then
			Selected.Position = UDim2.fromOffset(11, 0)
			Selected.Size = UDim2.new(1, -(shift + 12), 1, 0)
			return
		end
		local room = Field.AbsoluteSize.X / scaleFactor()
		local width = labelWidth
		if room > 0 then
			width = math.min(width, math.floor(room * 0.6) - 11)
		end
		width = math.max(width, 20)
		FieldLabel.Size = UDim2.new(0, width, 1, 0)
		Selected.Position = UDim2.new(1, -shift, 0, 0)
		Selected.Size = UDim2.new(1, -(shift + width + 22), 1, 0)
	end
	if inline then
		labelWidth = textWidth(opts.Text, FONT, 13, function(measured)
			labelWidth = measured + 4
			layoutField()
		end) + 4
		Field:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutField)
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
		elseif option.Value ~= nil then
			shown = tostring(option.Value)
		end
		layoutField()
		Selected.Text = shown or opts.Placeholder or "None"
		Selected.TextColor3 = shown and T.Text or T.Muted
		FootCount.Text = picked() .. " of " .. #option.Values .. " picked"
	end

	local function paintItem(item, animated)
		local T = Library.Theme
		local on = isSelected(item.Value)
		local goals = {
			Row = { BackgroundColor3 = on and T.Accent or T.Hover, BackgroundTransparency = on and 0.86 or (item.Hot and 0 or 1) },
			Box = { BackgroundColor3 = T.Accent, BackgroundTransparency = on and 0 or 1 },
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

	local built = false
	local Empty = text({
		Name = "Empty",
		Size = UDim2.new(1, 0, 0, 26),
		TextSize = 12,
		Text = "Nothing to pick",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 0,
		Visible = false,
		Theme = { TextColor3 = "Muted" },
		Parent = ListFrame,
	})

	local function maxRows()
		local limit = math.max(tonumber(opts.MaxVisible) or 7, 1)
		local scroller = Popup:FindFirstAncestorWhichIsA("ScrollingFrame")
		local window = scroller and scroller.AbsoluteWindowSize.Y / scaleFactor() or 0
		if window > 0 then
			limit = math.max(3, math.min(limit, math.floor((window - 160) / 28)))
		end
		return limit
	end

	local function applyFilter()
		local query = Filter.Text:lower()
		local shown = 0
		for _, item in ipairs(items) do
			local visible = query == "" or item.Search:find(query, 1, true) ~= nil
			item.Row.Visible = visible
			if visible then
				shown = shown + 1
			end
		end
		Empty.Visible = shown == 0
		Empty.Text = query ~= "" and "No matches" or "Nothing to pick"
		local rows = math.clamp(shown, 1, maxRows())
		ListFrame.Size = UDim2.new(1, 0, 0, rows * 28 - 2)
		ListFrame.CanvasSize = UDim2.fromOffset(0, math.max(shown, 1) * 28 - 2)
		if open then
			tween(Popup, { Size = UDim2.new(1, 0, 0, 107 + ListFrame.Size.Y.Offset) }, TWEEN_SMOOTH)
		end
	end

	local function rebuild()
		for _, item in ipairs(items) do
			item.Row:Destroy()
		end
		items = {}
		for index, value in ipairs(option.Values) do
			local label = tostring(value)
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
				BackgroundColor3 = Library.Theme.Accent,
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
			local item = { Row = Row, Box = Box, Edge = Edge, Label = Label, Tick = Tick, Value = value, Hot = false, Search = label:lower() }
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
		built = true
		applyFilter()
	end

	setOpen = function(state)
		if state == open then
			return
		end
		open = state
		panelId = panelId + 1
		local id = panelId
		setIcon(ChevronImage, state and "chevron-up" or "chevron-down")
		tween(FieldEdge, { Color = state and Library.Theme.Accent or Library.Theme.BorderLight })
		if state then
			if not Popup.Visible then
				Popup.Size = UDim2.new(1, 0, 0, 0)
				Popup.Visible = true
			end
			if built then
				applyFilter()
			else
				rebuild()
			end
			PopupGlow:Play()
			task.defer(reveal, Field, 107 + ListFrame.Size.Y.Offset, 6)
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
		tween(Field, { BackgroundColor3 = Library.Theme.Hover })
	end)
	Field.MouseLeave:Connect(function()
		if not open then
			tween(FieldEdge, { Color = Library.Theme.BorderLight })
		end
		tween(Field, { BackgroundColor3 = Library.Theme.Field })
	end)
	Filter:GetPropertyChangedSignal("Text"):Connect(function()
		if open and built then
			applyFilter()
		end
	end)
	if AllButton then
		AllButton.MouseButton1Click:Connect(function()
			local set = {}
			if Filter.Text ~= "" and built then
				set = table.clone(option.Value)
				for _, item in ipairs(items) do
					if item.Row.Visible then
						set[item.Value] = true
					end
				end
			else
				for _, value in ipairs(option.Values) do
					set[value] = true
				end
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
		local wanted = value
		local missing
		value, missing = resolve(value)
		self._wanted = missing and wanted or nil
		if self.Multi and sameSet(value, self.Value) or not self.Multi and value == self.Value then
			return
		end
		self.Value = value
		display()
		paintItems(true)
		self:_emit()
	end

	function option:SetValues(values)
		self.Values = type(values) == "table" and values or {}
		local before = self.Multi and table.clone(self.Value) or self.Value
		local changed = false
		if self.Multi then
			local kept = {}
			for value in pairs(self.Value) do
				if table.find(self.Values, value) then
					kept[value] = true
				else
					changed = true
				end
			end
			if changed then
				self.Value = kept
			end
		elseif self.Value ~= nil and not table.find(self.Values, self.Value) then
			self.Value = nil
			changed = true
		end
		if self._wanted ~= nil then
			local value, missing = resolve(self._wanted)
			if not missing then
				self._wanted = nil
			end
			if self.Multi then
				if next(value) ~= nil and not sameSet(value, self.Value) then
					self.Value = value
					changed = true
				end
			elseif value ~= nil and value ~= self.Value then
				self.Value = value
				changed = true
			end
		end
		built = false
		display()
		if open then
			rebuild()
		end
		if changed then
			task.defer(function()
				if Library.Unloaded then
					return
				end
				local same
				if self.Multi then
					same = sameSet(before, self.Value)
				else
					same = before == self.Value
				end
				if not same then
					self:_emit()
				end
			end)
		end
	end

	themed(Holder, function()
		display()
		paintItems(false)
		FieldEdge.Color = open and Library.Theme.Accent or Library.Theme.BorderLight
	end)
	display()
	attachTooltip(Field, opts.Tooltip)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddInput(id, opts)
	opts = opts or {}
	local option = newOption(id, "Input", opts)
	option.Value = tostring(opts.Default or "")

	local titled = opts.Text ~= nil
	local above = titled and described(opts)
	local Holder = self:_holder(above and 72 or (titled and 44 or 32))
	if above then
		local Top = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 34),
			Parent = Holder,
		})
		rowText(Top, opts, nil, 1, 0)
	end
	local Edge = stroke("BorderLight")
	local Frame = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = above and UDim2.new(1, 0, 0, 32) or UDim2.fromScale(1, 1),
		Theme = { BackgroundColor3 = "Field" },
		Parent = Holder,
	}, { corner(), Edge })
	local inside = titled and not above
	if inside then
		text({
			Position = UDim2.fromOffset(11, 6),
			Size = UDim2.new(1, -22, 0, 13),
			FontFace = FONT_SEMI,
			TextSize = 11,
			Text = opts.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Theme = { TextColor3 = "SubText" },
			Parent = Frame,
		})
	end
	local Box = create("TextBox", {
		BackgroundTransparency = 1,
		Position = inside and UDim2.fromOffset(11, 21) or UDim2.fromOffset(11, 0),
		Size = inside and UDim2.new(1, -22, 0, 18) or UDim2.new(1, -22, 1, 0),
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
		if opts.Numeric and (value == "-" or value == "." or value == "-.") then
			Box.Text = value
			return
		end
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
	themed(Holder, function()
		Edge.Color = focused and Library.Theme.Accent or Library.Theme.BorderLight
	end)
	Frame.MouseEnter:Connect(function()
		if not focused then
			tween(Edge, { Color = Library.Theme.Muted })
		end
	end)
	Frame.MouseLeave:Connect(function()
		if not focused then
			tween(Edge, { Color = Library.Theme.BorderLight })
		end
	end)
	Box.Focused:Connect(function()
		focused = true
		tween(Edge, { Color = Library.Theme.Accent })
	end)
	Box.FocusLost:Connect(function()
		focused = false
		tween(Edge, { Color = Library.Theme.BorderLight })
		if opts.Finished then
			option:SetValue(Box.Text)
		end
		if opts.Numeric and Box.Text ~= "" and not tonumber(Box.Text) then
			Box.Text = option.Value
		end
	end)
	if not opts.Finished then
		Box:GetPropertyChangedSignal("Text"):Connect(function()
			option:SetValue(Box.Text)
		end)
	end
	attachTooltip(Frame, opts.Tooltip)
	self:_index(opts.Text or id, Holder, Holder)
	return option
end

function Elements:AddKeybind(id, opts)
	opts = opts or {}
	local Holder = self:_holder(rowHeight(opts))
	local _, _, row = rowText(Holder, opts, id, 1, 100)
	local Slots = slotRow(Holder)
	local estimate = textWidth(keyName(parseKey(opts.Default)), FONT_SEMI, 12) + 20
	followSlots(row, Slots, function()
		return estimate
	end)
	self:_index(opts.Text or id, Holder, Holder)
	return newKeybind(id, opts, Slots, UDim2.new(1, 0, 0.5, 0))
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
		Name = "EspPreview",
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
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 1 and not part:FindFirstChildOfClass("WrapLayer") then
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

	local Missing = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -20, 0, 16),
		TextSize = 12,
		Text = "Avatar unavailable",
		TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false,
		ZIndex = 6,
		Theme = { TextColor3 = "Muted" },
		Parent = Canvas,
	})
	local dummyBox
	local function dummyBounds()
		if not dummy then
			return nil
		end
		if not dummyBox then
			local ok, box, extent = pcall(dummy.GetBoundingBox, dummy)
			if not ok then
				return nil
			end
			dummyBox = { box, extent }
		end
		return dummyBox[1], dummyBox[2]
	end
	local function fetchModel(id)
		local attempts = {
			function()
				return Players:CreateHumanoidModelFromUserIdAsync(id)
			end,
			function()
				return Players:CreateHumanoidModelFromUserId(id)
			end,
			function()
				return Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
			end,
			function()
				return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
			end,
		}
		for _, attempt in ipairs(attempts) do
			local ok, model = pcall(attempt)
			if ok and typeof(model) == "Instance" then
				return model
			end
		end
		return nil
	end
	local loadId = 0
	local function loadUser(id, retried)
		loadId = loadId + 1
		local mine = loadId
		task.spawn(function()
			local model = fetchModel(id)
			if mine ~= loadId or Library.Unloaded then
				if model then
					model:Destroy()
				end
				return
			end
			if not model then
				Missing.Visible = dummy == nil
				if not retried then
					task.delay(5, function()
						if mine == loadId and not Library.Unloaded then
							loadUser(id, true)
						end
					end)
				end
				return
			end
			Missing.Visible = false
			dummyBox = nil
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
			local lastX = input.Position.X
			beginDrag(input, function(moved)
				yaw = yaw + (moved.Position.X - lastX) * 0.012
				lastX = moved.Position.X
			end)
		end
	end)
	Sink.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z, 4, 16)
		end
	end)
	local function recentre()
		local middle = math.max(0, (Sink.AbsoluteCanvasSize.Y - Sink.AbsoluteSize.Y) * 0.5)
		if math.abs(Sink.CanvasPosition.Y - middle) > 0.5 then
			Sink.CanvasPosition = Vector2.new(0, middle)
		end
	end
	Sink:GetPropertyChangedSignal("CanvasPosition"):Connect(recentre)
	Sink:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(recentre)
	Sink:GetPropertyChangedSignal("AbsoluteSize"):Connect(recentre)

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
		Size = UDim2.new(1, -48, 0, 14),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
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
			local box, extent = dummyBounds()
			if not box then
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
			local box = dummyBounds()
			local pivot = box and box.Position or Vector3.new()
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
	local dockedSize = Holder.Size
	PopButton.MouseButton1Click:Connect(function()
		if floating then
			Canvas.Parent = Holder
			Canvas.Position = UDim2.fromOffset(0, 34)
			Canvas.Size = UDim2.new(1, 0, 0, height)
			Holder.Size = dockedSize
			local index = table.find(PopupScales, floating.Scale)
			if index then
				table.remove(PopupScales, index)
			end
			floating.Release()
			floating.Glow:Cancel()
			index = table.find(Loops, floating.Glow)
			if index then
				table.remove(Loops, index)
			end
			floating.Frame:Destroy()
			floating = nil
			return
		end
		dockedSize = Holder.Size
		Holder.Size = UDim2.new(dockedSize.X.Scale, dockedSize.X.Offset, 0, math.max(dockedSize.Y.Offset - height - 4, 0))
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
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = column,
	}, { corner(10), stroke("BorderLight"), padding(10, 12, 12 - ROW_PAD, 12), list(9 - ROW_PAD) })
	local Header = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 1,
		Parent = Outer,
	})
	local Title = text({
		Position = UDim2.fromOffset(1, 0),
		Size = UDim2.new(1, -1, 0, 20),
		FontFace = FONT_SEMI,
		TextSize = 14,
		Text = title or "",
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Text" },
		Parent = Header,
	})
	local Rule = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		Theme = { BackgroundColor3 = "BorderLight" },
		Parent = Header,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Rule,
	})
	local Content = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 2,
		Parent = Outer,
	}, { list(0) })
	watchRows(Content)

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
		Size = UDim2.fromOffset(220, 39),
		Visible = false,
		Active = true,
		ZIndex = 0,
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
		Parent = Panel,
	}, { list(2), padding(6, 6, 7, 6) })

	dragBy(Panel, function(input)
		return input.Position.Y - Panel.AbsolutePosition.Y <= 38 * Library.PanelScale.Scale
	end)

	local MODE_SHORT = { Toggle = "toggle", Hold = "hold", Press = "press" }
	local rows = {}
	local function buildRow(entry)
		local Row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Parent = Rows,
		})
		local Tint = create("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 0.9,
			Visible = false,
			Parent = Row,
		}, { corner(6) })
		local Label = text({
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -100, 1, 0),
			FontFace = FONT_MEDIUM,
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
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
		local Mode = text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			TextSize = 11,
			LayoutOrder = 1,
			Theme = false,
			Parent = Right,
		})
		local Edge = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 })
		local Chip = create("Frame", {
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = 2,
			Parent = Right,
		}, { corner(5), Edge, padding(0, 7, 0, 7) })
		local Key = text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			FontFace = FONT_SEMI,
			TextSize = 11,
			Theme = false,
			Parent = Chip,
		})
		local function fit()
			local scale = Library.PanelScale and Library.PanelScale.Scale or 1
			Label.Size = UDim2.new(1, -(Right.AbsoluteSize.X / math.max(scale, 0.01) + 22), 1, 0)
		end
		Right:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		fit()
		return { Row = Row, Tint = Tint, Label = Label, Mode = Mode, Edge = Edge, Chip = Chip, Key = Key }
	end
	function Library._renderKeybinds()
		local T = Library.Theme
		local on, count = 0, 0
		local seen = {}
		for index, entry in ipairs(KeybindEntries) do
			seen[entry] = true
			local row = rows[entry]
			if not entry.Hidden and entry.Option.Value then
				local active = entry.GetState() == true
				count = count + 1
				if active then
					on = on + 1
				end
				if not row then
					row = buildRow(entry)
					rows[entry] = row
				end
				row.Row.LayoutOrder = index
				row.Row.Visible = true
				row.Tint.BackgroundColor3 = T.Accent
				row.Tint.Visible = active
				row.Label.Text = tostring(entry.Label)
				row.Label.TextColor3 = active and T.Text or T.SubText
				row.Mode.Text = MODE_SHORT[entry.Option.Mode] or ""
				row.Mode.TextColor3 = T.Muted
				row.Chip.BackgroundColor3 = T.Field
				row.Edge.Color = active and T.Border:Lerp(T.Accent, 0.6) or T.Border
				row.Key.Text = keyName(entry.Option.Value)
				row.Key.TextColor3 = active and T.Accent or T.SubText
			elseif row then
				row.Row.Visible = false
			end
		end
		for entry, row in pairs(rows) do
			if not seen[entry] then
				row.Row:Destroy()
				rows[entry] = nil
			end
		end
		Count.Text = on .. " / " .. count
		if count > 0 then
			local tall = count * 28 + 11
			Rows.Size = UDim2.new(1, 0, 0, tall)
			Panel.Size = UDim2.fromOffset(220, 39 + tall)
		end
		popout(Panel, Library.KeybindListEnabled and count > 0)
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
		Active = true,
		ZIndex = 0,
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
		local okPlayers, playerList = pcall(Players.GetPlayers, Players)
		local count = (okPlayers and type(playerList) == "table") and #playerList or 0
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
	ColorSequenceKeypoint.new(0, Color3.new(0.3, 0.38, 0.55)),
	ColorSequenceKeypoint.new(0.4, Color3.new(0.86, 0.9, 0.96)),
	ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(0.6, Color3.new(0.86, 0.9, 0.96)),
	ColorSequenceKeypoint.new(1, Color3.new(0.26, 0.33, 0.5)),
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
	table.insert(UnloadCallbacks, function()
		for _, entry in pairs(sheens) do
			entry.tween:Cancel()
		end
	end)
	local function process(inst, accent, blocked)
		if inst:GetAttribute("DexoriNoSheen") then
			removeSheen(inst)
			return
		end
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
			local window = Library.Window
			nextCycle = now + ((window and not window.Root.Visible) and 3 or 1.5)
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

local function titleButton(parent, glyph, position)
	local Edge = stroke("BorderLight")
	local Button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = position,
		Size = UDim2.fromOffset(22, 22),
		AutoButtonColor = false,
		Text = "",
		Theme = { BackgroundColor3 = "Field" },
		Parent = parent,
	}, { corner(6), Edge })
	pressScale(Button)
	local bars = {}
	local rest, wide
	if glyph == "x" then
		rest, wide = UDim2.fromOffset(10, 2), UDim2.fromOffset(12, 2)
		for _, angle in ipairs({ 45, -45 }) do
			table.insert(bars, create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = rest,
				Rotation = angle,
				Theme = { BackgroundColor3 = "SubText" },
				Parent = Button,
			}, { corner(1) }))
		end
	else
		rest, wide = UDim2.fromOffset(9, 2), UDim2.fromOffset(11, 2)
		table.insert(bars, create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = rest,
			Theme = { BackgroundColor3 = "SubText" },
			Parent = Button,
		}, { corner(1) }))
	end
	local hot, danger = false, false
	local function paint()
		local T = Library.Theme
		for _, bar in ipairs(bars) do
			tween(bar, { BackgroundColor3 = danger and T.Accent or (hot and T.Text or T.SubText), Size = (hot or danger) and wide or rest })
		end
		tween(Edge, { Color = (hot or danger) and T.Accent or T.BorderLight })
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
		return string.format("%d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60), seconds % 60)
	end
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
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
		Active = true,
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Panel" },
		Parent = self.ScreenGui,
	}, { corner(12), stroke("Border") })
	card.Frame = Card
	local CardScale = create("UIScale", { Scale = card.Scale * self.UserScale, Parent = Card })
	table.insert(ScaleHooks, function(scale)
		if not card.Destroyed then
			CardScale.Scale = card.Scale * scale
		end
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

	local copy, source, sourceRoot, partPairs, head, focus, box = nil, nil, nil, {}, nil, nil, nil
	local function clearCopy()
		if copy then
			copy:Destroy()
		end
		copy, source, sourceRoot, partPairs, head, focus, box = nil, nil, nil, {}, nil, nil, nil
		PortraitIcon.Visible = true
	end
	local function buildCopy(model, root)
		clearCopy()
		source, sourceRoot = model, root
		if not (model and root) or opts.Portrait == false then
			return
		end
		if #model:GetDescendants() > 1500 then
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
			if not box then
				local ok, boxCFrame, boxSize = pcall(source.GetBoundingBox, source)
				if not ok then
					return
				end
				box = { base:ToObjectSpace(boxCFrame).Position + Vector3.new(0, boxSize.Y * 0.4, 0), math.max(boxSize.X, boxSize.Z) * 0.45 }
			end
			target, size = box[1], box[2]
		end
		focus = focus and focus:Lerp(target, 0.25) or target
		local distance = size * 1.25 / math.tan(math.rad(Camera.FieldOfView / 2))
		Camera.CFrame = CFrame.lookAt(focus + Vector3.new(0, size * 0.12, -distance), focus)
	end

	local shown = false
	local function setShown(state)
		if state == shown then
			if not state and not card.Target then
				clearCopy()
			end
			return
		end
		shown = state
		if state then
			CardScale.Scale = card.Scale * Library.UserScale * 0.94
			tween(CardScale, { Scale = card.Scale * Library.UserScale }, POP_IN)
			popout(Card, true)
		else
			popout(Card, false, function()
				if not card.Target then
					clearCopy()
				end
			end)
		end
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
	local lastKillTime = nil
	local lastHealth, alive, endless, dps = 0, false, false, nil
	local iconShown = opts.Icon or "skull"
	local hpShown, hpMax, hpEndless, hpInk

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
		lastHealth = health
		alive = health > 0
		dps = nil
	end

	local function finite()
		endless = maxHealth == math.huge or health == math.huge or health ~= health or maxHealth ~= maxHealth
		if endless then
			health, maxHealth = (health ~= health or health > 0) and 1 or 0, 1
		end
	end

	local function readTarget(target)
		local humanoid = target.Humanoid
		if humanoid then
			if humanoid.Parent then
				health = math.max(humanoid.Health, 0)
				maxHealth = math.max(humanoid.MaxHealth, 1)
				finite()
			else
				health = 0
			end
		end
		if target.Model and not target.Model.Parent then
			health = 0
		end
	end

	function card:SetTarget(target)
		if self.Destroyed or Library.Unloaded then
			return
		end
		if typeof(target) == "Instance" then
			local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
			target = { Model = model }
		end
		if type(target) ~= "table" then
			self.Target = nil
			if self.AutoHide then
				setShown(false)
			else
				clearCopy()
			end
			return
		end
		local model = target.Model
		target.Humanoid = target.Humanoid or (model and model:FindFirstChildOfClass("Humanoid"))
		target.Root = target.Root or (model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart))
		target.Name = target.Name or (model and model.Name) or "Target"
		local previous = self.Target
		local same = previous ~= nil and ((model ~= nil and previous.Model == model) or (model == nil and previous.Model == nil and previous.Name == target.Name))
		if target.Health then
			health = math.max(tonumber(target.Health) or 0, 0)
		end
		if target.MaxHealth then
			maxHealth = math.max(tonumber(target.MaxHealth) or 1, 1)
		end
		finite()
		readTarget(target)
		if not previous and health <= 0 and self.AutoHide then
			return
		end
		self.Target = target
		if not same then
			buildCopy(model, target.Root)
			resetStats()
			ratioNow = health / maxHealth
			lagRatio = ratioNow
			if stateKey == "defeated" or stateKey == "Defeated" then
				self:SetState(nil)
			end
		end
		NameText.Text = tostring(target.Name)
		Badge.Visible = target.Badge ~= nil
		BadgeText.Text = target.Badge and string.upper(tostring(target.Badge)) or ""
		local wantIcon = target.Icon or opts.Icon or "skull"
		if wantIcon ~= iconShown then
			iconShown = wantIcon
			Library:SetIcon(PortraitIcon, wantIcon)
		end
		PortraitIcon.Visible = copy == nil
		if self.Enabled then
			setShown(true)
		end
		if not same then
			shownHealth = health
			self._step(0)
		end
	end

	function card:SetHealth(value, max)
		if self.Destroyed then
			return
		end
		health = math.max(tonumber(value) or 0, 0)
		if max then
			maxHealth = math.max(tonumber(max) or 1, 1)
		end
		finite()
	end

	function card:SetEnabled(state)
		if self.Destroyed or Library.Unloaded then
			return
		end
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

	local stepHook
	function card:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true
		self.Target = nil
		if stepHook then
			stepHook:Disconnect()
		end
		clearCopy()
		Card:Destroy()
		if Library.TargetCard == self then
			Library.TargetCard = nil
		end
	end

	Card.InputBegan:Connect(function(input)
		if card.Destroyed or not isPointer(input) then
			return
		end
		local dragStart, startPos = input.Position, Card.Position
		beginDrag(input, function(moved)
			local delta = moved.Position - dragStart
			if not card.Dragged and math.abs(delta.X) + math.abs(delta.Y) < 4 then
				return
			end
			Card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			card.Dragged = true
		end)
	end)

	local pulse = 0
	local function step(dt)
		local target = card.Target
		if not target then
			return
		end
		dt = math.min(dt or 0, 0.1)
		readTarget(target)
		local now = os.clock()
		local T = Library.Theme
		local visible = Card.Visible

		local lost = lastHealth - health
		if lost > maxHealth * 0.0005 then
			lastDrop = now
			pendingDamage = pendingDamage + lost
			if pendingSince == 0 then
				pendingSince = now
			end
			lastHealth = health
		elseif lost < 0 then
			lastHealth = health
		end

		if health > 0 then
			alive = true
		end
		if health <= 0 and not defeatedAt then
			defeatedAt = now
			card:SetState("defeated")
			if alive then
				alive = false
				card.Kills = card.Kills + 1
				lastKillTime = now - engagedAt
				fire(opts.OnDefeated, target, lastKillTime)
			end
		elseif health > 0 and defeatedAt then
			defeatedAt = nil
			card:SetState(nil)
		end
		if defeatedAt and card.AutoHide and now - defeatedAt > (opts.HideDelay or 1.6) then
			card.Target = nil
			setShown(false)
		end

		if not defeatedAt then
			if now - lastSample >= 0.2 then
				lastSample = now
				table.insert(samples, { t = now, hp = health })
				while #samples > 2 and now - samples[1].t > 6 do
					table.remove(samples, 1)
				end
			end
			local first = samples[1]
			if first and now - first.t >= 1 then
				local drop = first.hp - health
				dps = drop > 0 and drop / (now - first.t) or 0
			end
		end

		local ratio = math.clamp(health / maxHealth, 0, 1)
		if not visible then
			pendingDamage, pendingSince = 0, 0
			ratioNow, lagRatio, shownHealth = ratio, ratio, health
			return
		end
		pose()

		if not card.Dragged then
			local watermark = Library.Watermark
			local y = 12
			if watermark and watermark.Visible and watermark.AbsolutePosition.Y < 80 then
				y = watermark.Position.Y.Offset + watermark.AbsoluteSize.Y + 8
			end
			Card.Position = UDim2.new(0.5, 0, 0, y + (card.Offset or 0))
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
			if opts.DamageNumbers ~= false and not endless then
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
		local shownInt, maxInt = math.ceil(shownHealth), math.floor(maxHealth)
		if shownInt ~= hpShown or maxInt ~= hpMax or endless ~= hpEndless or T.Text ~= hpInk then
			hpShown, hpMax, hpEndless, hpInk = shownInt, maxInt, endless, T.Text
			if endless then
				HpText.Text = string.format('<font color="#%s">∞</font>', T.Text:ToHex())
				PctText.Text = ""
			else
				HpText.Text = string.format('<font color="#%s">%s</font><font color="#%s"> / %s</font>', T.Text:ToHex(), commas(math.ceil(shownHealth)), T.Muted:ToHex(), commas(math.floor(maxHealth)))
			end
		end
		if not endless then
			PctText.Text = string.format("%d%%", math.floor(ratio * 100 + 0.5))
		end

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

		TimeValue.Text = defeatedAt and clockText(lastKillTime or 0) or clockText(now - engagedAt)
		DpsValue.Text = dps and (shortNumber(dps) .. "/s") or "--"
		EtaValue.Text = defeatedAt and "done" or ((dps and dps > 0 and not endless) and ("~" .. clockText(health / dps)) or "--")
		KillValue.Text = tostring(card.Kills)
	end
	stepHook = connect(RunService.RenderStepped, step)
	card._step = step

	themed(Card, function()
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
	local env = type(getgenv) == "function" and getgenv() or _G
	local slot = "DexoriInstance:" .. tostring(self.Folder)
	local previous = rawget(env, slot)
	if type(previous) == "table" and previous ~= self and not previous.Unloaded and type(previous.Unload) == "function" then
		pcall(previous.Unload, previous)
		guardIdle()
	end
	rawset(env, slot, self)
	self._instanceSlot = slot

	self.Title = info.Title or "Dexori"
	self.ToggleKey = parseKey(info.ToggleKey) or Enum.KeyCode.RightControl

	local ScreenGui = create("ScreenGui", {
		Name = "Dexori",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 1000000000,
	})
	parentGui(ScreenGui)
	self.ScreenGui = ScreenGui
	startSheen()

	local wantWidth, wantHeight = tonumber(info.Width) or 550, tonumber(info.Height) or 600
	local function usable()
		local size = ScreenGui.AbsoluteSize
		if size.X < 200 or size.Y < 200 then
			local camera = workspace.CurrentCamera
			size = camera and camera.ViewportSize or size
		end
		if size.X < 200 or size.Y < 200 then
			size = Vector2.new(1280, 720)
		end
		return size
	end
	local function fitted(w, h)
		local s, area = self.UserScale, usable()
		s = type(s) == "number" and s > 0 and s or 1
		return math.max(math.min(w, area.X / s - 24), 240), math.max(math.min(h, area.Y / s - 24), 200)
	end
	local width, height = fitted(wantWidth, wantHeight)

	local ModalButton = create("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 0),
		Text = "",
		Modal = false,
		Parent = ScreenGui,
	})

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
		Active = true,
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

	local compactHooks = {}

	local TitleBar = create("Frame", {
		Size = UDim2.new(1, 0, 0, TITLEBAR),
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Main,
	}, { corner(WINDOW_RADIUS) })
	create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, WINDOW_RADIUS),
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = TitleBar,
	})

	local SEARCH_WIDTH, SEARCH_OPEN = 130, 160
	local searchWidth, searchOpen = SEARCH_WIDTH, SEARCH_OPEN
	local Left = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -(14 + 66 + SEARCH_WIDTH + 10), 1, 0),
		ClipsDescendants = true,
		Parent = TitleBar,
	}, { list(8, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	buildLogo(Left, 15, 1)
	local subtitle = info.Subtitle or "Script Hub"
	local Slash = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), Text = "/", LayoutOrder = 2, Visible = subtitle ~= "", Theme = { TextColor3 = "BorderLight" }, Parent = Left })
	local SubtitleLabel = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), Text = subtitle, LayoutOrder = 3, Visible = subtitle ~= "", Theme = { TextColor3 = "SubText" }, Parent = Left })
	local GamePill = create("Frame", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 4,
		Visible = false,
		Theme = { BackgroundColor3 = "Field" },
		Parent = Left,
	}, { corner(9), stroke("BorderLight"), padding(0, 8, 0, 8) })
	local GameName = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 18),
		TextSize = 11,
		KeepCase = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Muted" },
		Parent = GamePill,
	})
	local GameLimit = create("UISizeConstraint", { MaxSize = Vector2.new(170, 18), Parent = GameName })
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
				local shown, sub = string.lower(product.Name), string.lower(SubtitleLabel.Text)
				if sub == "" or not (shown:find(sub, 1, true) or sub:find(shown, 1, true)) then
					Library:SetGame(product.Name)
				end
			end
		end)
	end

	local TabBar = create("Frame", {
		Position = UDim2.fromOffset(0, TITLEBAR),
		Size = UDim2.new(1, 0, 0, TABBAR),
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Main,
	})
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Divider" }, Parent = TabBar })
	create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Outline" }, Parent = TabBar })
	local TabLayout = list(18, true)
	local TabList = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 1),
		Size = UDim2.new(1, -28, 1, -2),
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.X,
		ScrollBarThickness = 0,
		Parent = TabBar,
	}, { TabLayout })
	fitCanvas(TabList, TabLayout, true, 0)
	local function edgeFade(right)
		local Fade = create("Frame", {
			AnchorPoint = Vector2.new(right and 1 or 0, 0),
			Position = right and UDim2.new(1, 0, 0, 1) or UDim2.fromOffset(0, 1),
			Size = UDim2.new(0, 36, 1, -2),
			Visible = false,
			ZIndex = 3,
			Theme = { BackgroundColor3 = "Chrome" },
			Parent = TabBar,
		})
		create("UIGradient", { Rotation = right and 180 or 0, Transparency = NumberSequence.new(0, 1), Parent = Fade })
		return Fade
	end
	local FadeLeft, FadeRight = edgeFade(false), edgeFade(true)
	local function paintOverflow()
		local room = TabList.AbsoluteCanvasSize.X - TabList.AbsoluteWindowSize.X
		FadeLeft.Visible = TabList.CanvasPosition.X > 1
		FadeRight.Visible = TabList.CanvasPosition.X < room - 1
	end
	TabList:GetPropertyChangedSignal("CanvasPosition"):Connect(paintOverflow)
	TabList:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(paintOverflow)
	TabList:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(paintOverflow)
	local wheelGoal
	TabList.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local room = math.max(TabList.AbsoluteCanvasSize.X - TabList.AbsoluteWindowSize.X, 0)
			wheelGoal = math.clamp((wheelGoal or TabList.CanvasPosition.X) - input.Position.Z * 60, 0, room)
			local goal = wheelGoal
			tween(TabList, { CanvasPosition = Vector2.new(goal, 0) }, TWEEN_SMOOTH).Completed:Connect(function()
				if wheelGoal == goal then
					wheelGoal = nil
				end
			end)
		end
	end)

	local CloseButton, armClose = titleButton(TitleBar, "x", UDim2.new(1, -10, 0.5, 0))
	local HideButton = titleButton(TitleBar, "minus", UDim2.new(1, -38, 0.5, 0))

	local SearchEdge = stroke("BorderLight")
	local SearchField = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -66, 0.5, 0),
		Size = UDim2.fromOffset(SEARCH_WIDTH, 22),
		Theme = { BackgroundColor3 = "Field" },
		Parent = TitleBar,
	}, { corner(6), SearchEdge })
	create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.fromOffset(8, 8),
		Parent = SearchField,
	}, { round(), create("UIStroke", { Thickness = 1.3, Theme = { Color = "Muted" } }) })
	create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(17.5, 15.5),
		Size = UDim2.fromOffset(1.4, 4),
		Rotation = -45,
		Theme = { BackgroundColor3 = "Muted" },
		Parent = SearchField,
	})
	local SearchBox = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(25, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Text = "",
		PlaceholderText = "Search",
		ClearTextOnFocus = false,
		FontFace = FONT,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Theme = { TextColor3 = "Text", PlaceholderColor3 = "Muted" },
		Parent = SearchField,
	})
	SearchField.MouseEnter:Connect(function()
		if not SearchBox:IsFocused() then
			tween(SearchEdge, { Color = Library.Theme.Muted })
		end
	end)
	SearchField.MouseLeave:Connect(function()
		if not SearchBox:IsFocused() then
			tween(SearchEdge, { Color = Library.Theme.BorderLight })
		end
	end)

	local Pages = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, TITLEBAR + TABBAR),
		Size = UDim2.new(1, 0, 1, -(TITLEBAR + TABBAR + STATUSBAR)),
		ClipsDescendants = true,
		Parent = Main,
	})
	local Cover = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Pages,
	})

	local StatusBar = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, STATUSBAR),
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = Main,
	}, { corner(WINDOW_RADIUS) })
	create("Frame", {
		Size = UDim2.new(1, 0, 0, WINDOW_RADIUS),
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Chrome" },
		Parent = StatusBar,
	})
	create("Frame", { Size = UDim2.new(1, 0, 0, 1), Theme = { BackgroundColor3 = "Outline" }, Parent = StatusBar })

	local StatusLeft = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 1),
		Size = UDim2.new(0, 0, 1, -1),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = StatusBar,
	}, { list(10, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local KeyChip = create("Frame", {
		Size = UDim2.fromOffset(0, 16),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = 1,
		Theme = { BackgroundColor3 = "Field" },
		Parent = StatusLeft,
	}, { corner(5), stroke("BorderLight"), list(5, true, { VerticalAlignment = Enum.VerticalAlignment.Center }), padding(0, 6, 0, 6) })
	text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), TextSize = 12, Text = "Menu", LayoutOrder = 1, Theme = { TextColor3 = "Muted" }, Parent = KeyChip })
	local KeyLabel = text({ AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 14), FontFace = FONT_SEMI, TextSize = 12, LayoutOrder = 2, Parent = KeyChip })
	local FooterLabel = text({
		Size = UDim2.fromOffset(0, 14),
		FontFace = FONT,
		TextSize = 12,
		Text = tostring(info.Footer or ""),
		LayoutOrder = 2,
		KeepCase = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { TextColor3 = "Muted" },
		Parent = StatusLeft,
	})

	local StatusRight = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -28, 0, 1),
		Size = UDim2.new(0, 0, 1, -1),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = StatusBar,
	}, { list(10, true, { VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
	local RightLabel = text({
		Size = UDim2.fromOffset(0, 14),
		FontFace = FONT_MONO,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		KeepCase = true,
		LayoutOrder = 1,
		Visible = false,
		Theme = { TextColor3 = "Muted" },
		Parent = StatusRight,
	})
	local StatsLabel = text({
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 14),
		FontFace = FONT_MONO,
		TextSize = 11,
		KeepCase = true,
		LayoutOrder = 2,
		Theme = { TextColor3 = "Muted" },
		Parent = StatusRight,
	})

	local gripPad = UserInputService.TouchEnabled and 12 or 0
	local Grip = create("TextButton", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(18 + gripPad, 18 + gripPad),
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
			Position = UDim2.fromOffset(spot[1] + gripPad, spot[2] + gripPad),
			Size = UDim2.fromOffset(3, 3),
			ZIndex = 56,
			Theme = { BackgroundColor3 = "Muted" },
			Parent = Grip,
		}, { round() }))
	end
	local resizing, gripHover = false, false
	local function paintGrip()
		local color = (resizing or gripHover) and Library.Theme.Accent or Library.Theme.Muted
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

	local footerRight = info.FooterRight and tostring(info.FooterRight) or nil
	local narrow = false
	local fps, ping = 0, 0
	local fitStatus
	local asked, askedCount = {}, 0
	local function widthOf(value, font, size)
		local key = size .. value
		if asked[key] then
			return textWidth(value, font, size)
		end
		askedCount = askedCount + 1
		if askedCount > 200 then
			asked, askedCount = {}, 1
		end
		asked[key] = true
		return textWidth(value, font, size, function()
			fitStatus()
		end)
	end
	fitStatus = function()
		local s = scaleFactor()
		local total = StatusBar.AbsoluteSize.X / s - 40
		if total <= 0 then
			return
		end
		local chip = KeyChip.Visible and KeyChip.AbsoluteSize.X / s + 10 or 0
		local left = FooterLabel.Text
		local right = not narrow and footerRight or ""
		local wantLeft = left == "" and 0 or widthOf(left, FONT, 12) + 4
		local wantRight = right == "" and 0 or math.max(widthOf(right, FONT_MONO, 11), math.ceil((utf8.len(right) or #right) * 6.7)) + 4
		local free = math.max(total - chip - StatsLabel.AbsoluteSize.X / s - 16 - (wantRight > 0 and 10 or 0), 0)
		if wantLeft + wantRight > free then
			local half = free / 2
			if wantLeft <= half then
				wantRight = free - wantLeft
			elseif wantRight <= half then
				wantLeft = free - wantRight
			else
				wantLeft, wantRight = half, half
			end
		end
		FooterLabel.Size = UDim2.fromOffset(math.floor(wantLeft), 14)
		FooterLabel.Visible = wantLeft >= 12
		RightLabel.Size = UDim2.fromOffset(math.floor(wantRight), 14)
		RightLabel.Visible = wantRight >= 12
	end
	local function paintStatus()
		KeyLabel.Text = keyName(Library.ToggleKey)
		StatsLabel.Text = fps .. " fps · " .. ping .. " ms"
		RightLabel.Text = footerRight or ""
		fitStatus()
	end
	StatusBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitStatus)
	StatsLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitStatus)
	KeyChip:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitStatus)
	table.insert(compactHooks, function(isCompact)
		narrow = isCompact
		searchWidth = isCompact and 96 or SEARCH_WIDTH
		searchOpen = isCompact and 130 or SEARCH_OPEN
		SearchField.Size = UDim2.fromOffset(searchWidth, 22)
		Left.Size = UDim2.new(1, -(14 + 66 + searchWidth + 10), 1, 0)
		GameLimit.MaxSize = Vector2.new(isCompact and 90 or 170, 18)
		KeyChip.Visible = not isCompact
		paintStatus()
	end)
	table.insert(ThemeCallbacks, paintStatus)
	paintStatus()

	function Library:SetFooter(content)
		FooterLabel.Text = tostring(content or "")
		fitStatus()
	end
	function Library:SetFooterRight(content)
		footerRight = content and tostring(content) or nil
		paintStatus()
	end
	function Library:SetSubtitle(content)
		local value = tostring(content or "")
		SubtitleLabel.Text = value
		SubtitleLabel.Visible = value ~= ""
		Slash.Visible = value ~= ""
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
		Position = UDim2.new(1, -66, 0, TITLEBAR - 4),
		Size = UDim2.fromOffset(240, 0),
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 20,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Main,
	}, { corner(), stroke("BorderLight"), padding(4), list(2) })
	local resultsId = 0
	local function showResults(rows)
		resultsId = resultsId + 1
		local id = resultsId
		if rows == 0 then
			if Results.Visible then
				tween(Results, { Size = UDim2.fromOffset(240, 0) }, POP_OUT).Completed:Connect(function()
					if id == resultsId then
						Results.Visible = false
					end
				end)
			end
			return
		end
		if not Results.Visible then
			Results.Size = UDim2.fromOffset(240, 0)
			Results.Visible = true
		end
		tween(Results, { Size = UDim2.fromOffset(240, 8 + rows * 24 + (rows - 1) * 2) }, TWEEN_SMOOTH)
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
		TextWrapped = true,
		ZIndex = 50,
		Theme = { BackgroundColor3 = "Background", TextColor3 = "SubText" },
		Parent = ScreenGui,
	})
	local TooltipLimit = create("UISizeConstraint", { MaxSize = Vector2.new(280, 400), Parent = self.Tooltip })
	local function scaleTooltip()
		local s = scaleFactor()
		Library.Tooltip.TextSize = math.floor(12 * s + 0.5)
		TooltipLimit.MaxSize = Vector2.new(math.floor(280 * s), 400)
	end
	table.insert(ScaleHooks, scaleTooltip)
	corner(6).Parent = self.Tooltip
	stroke("BorderLight").Parent = self.Tooltip
	padding(5, 9, 5, 9).Parent = self.Tooltip

	local Window = { Tabs = {}, Main = Main, Root = Root, TabBar = TabBar, Sidebar = TabBar }

	local compact = nil
	local function applyLayout()
		local now = Root.Size.X.Offset < 480
		if now == compact then
			return
		end
		compact = now
		for _, hook in ipairs(compactHooks) do
			hook(now)
		end
	end

	local OPEN = TweenInfo.new(0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local FADE_OPEN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local CLOSE = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local open, toggleId = false, 0
	local iconWasHidden = false

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
		ModalButton.Modal = state
		if state then
			if UserInputService.MouseIconEnabled == false then
				iconWasHidden = true
				UserInputService.MouseIconEnabled = true
			end
		elseif iconWasHidden then
			iconWasHidden = false
			UserInputService.MouseIconEnabled = false
		end
		toggleId = toggleId + 1
		local id = toggleId
		Main.Parent = Fader
		popout(Library.PopupLayer, state)
		if state then
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
				end
			end)
		end
	end

	function Library:SetToggleKey(key)
		self.ToggleKey = parseKey(key) or Enum.KeyCode.RightControl
		paintStatus()
	end

	HideButton.MouseButton1Click:Connect(function()
		Window:Toggle(false)
		local hint = "Press " .. keyName(Library.ToggleKey) .. " to bring it back."
		if Library.MobileButton and not UserInputService.KeyboardEnabled then
			hint = "Tap the Dexori button to bring it back."
		end
		Library:Notify(Library.Title, "Menu hidden. " .. hint)
	end)

	local closeArmed, closeToken = false, 0
	CloseButton.MouseButton1Click:Connect(function()
		if closeArmed then
			Library:Unload()
			return
		end
		closeArmed = true
		closeToken = closeToken + 1
		local token = closeToken
		armClose(true)
		Library:Notify(Library.Title, "Press close again to unload.", 2.5)
		task.delay(2.5, function()
			if token == closeToken then
				closeArmed = false
				armClose(false)
			end
		end)
	end)

	local dragging, dragGoal = false, nil
	local function clampGoal(position)
		local area, s = usable(), scaleFactor()
		local w, h = Root.Size.X.Offset * s, Root.Size.Y.Offset * s
		local low = 80 - w / 2
		local cx = math.clamp(area.X * position.X.Scale + position.X.Offset, low, math.max(area.X - 80 + w / 2, low))
		local top = math.clamp(area.Y * position.Y.Scale + position.Y.Offset - h / 2, 0, math.max(area.Y - TITLEBAR * s, 0))
		return UDim2.new(position.X.Scale, cx - area.X * position.X.Scale, position.Y.Scale, top + h / 2 - area.Y * position.Y.Scale)
	end
	local function landDrag()
		if dragGoal then
			Root.Position = dragGoal
			dragGoal = nil
		end
	end
	connect(Main.InputBegan, function(input)
		if isPointer(input) and not resizing and input.Position.Y - Main.AbsolutePosition.Y <= TITLEBAR * scaleFactor() then
			local dragStart, startPos = input.Position, dragGoal or Root.Position
			dragging = true
			beginDrag(input, function(moved)
				local delta = moved.Position - dragStart
				dragGoal = clampGoal(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y))
			end, function()
				dragging = false
			end)
		end
	end)
	connect(Grip.InputBegan, function(input)
		if not isPointer(input) then
			return
		end
		landDrag()
		local resizeStart, startSize, resizePos = input.Position, Root.Size, Root.Position
		resizing = true
		paintGrip()
		beginDrag(input, function(moved)
			local s, view = scaleFactor(), usable()
			local delta = (moved.Position - resizeStart) / s
			local minW, minH = math.min(MIN_WIDTH, startSize.X.Offset), math.min(MIN_HEIGHT, startSize.Y.Offset)
			local w = math.clamp(startSize.X.Offset + delta.X, minW, math.max(minW, view.X / s - 16))
			local h = math.clamp(startSize.Y.Offset + delta.Y, minH, math.max(minH, view.Y / s - 16))
			Root.Size = UDim2.fromOffset(w, h)
			wantWidth, wantHeight = w, h
			local dw, dh = (w - startSize.X.Offset) * s, (h - startSize.Y.Offset) * s
			Root.Position = UDim2.new(resizePos.X.Scale, resizePos.X.Offset + dw * Root.AnchorPoint.X, resizePos.Y.Scale, resizePos.Y.Offset + dh * Root.AnchorPoint.Y)
			applyLayout()
		end, function()
			resizing = false
			paintGrip()
		end)
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
		local Tooltip = Library.Tooltip
		if not (Tooltip and Tooltip.Visible) then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			placeTooltip(input.Position.X, input.Position.Y)
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			tooltipOwner = nil
			hideTooltip()
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.Touch and tooltipOwner then
			tooltipOwner = nil
			hideTooltip()
		end
	end)

	local function refit()
		if Library.Unloaded or resizing then
			return
		end
		local w, h = fitted(wantWidth, wantHeight)
		Root.Size = UDim2.fromOffset(w, h)
		dragGoal = nil
		Root.Position = clampGoal(Root.Position)
		applyLayout()
	end
	ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	table.insert(ScaleHooks, refit)

	connect(UserInputService.InputBegan, function(input, processed)
		if Library.Picking or not inputMatches(input, Library.ToggleKey) or inputBlocked(input, processed) then
			return
		end
		Window:Toggle()
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
		local moved = false
		MobileButton.InputBegan:Connect(function(input)
			if not isPointer(input) then
				return
			end
			local start, origin = input.Position, MobileButton.Position
			moved = false
			beginDrag(input, function(at)
				local delta = at.Position - start
				if not moved and math.abs(delta.X) + math.abs(delta.Y) < 8 then
					return
				end
				moved = true
				local area = usable()
				MobileButton.Position = UDim2.fromOffset(
					math.clamp(origin.X.Offset + delta.X, 4, math.max(area.X - 46, 4)),
					math.clamp(origin.Y.Offset + delta.Y, 4, math.max(area.Y - 46, 4))
				)
			end)
		end)
		MobileButton.MouseButton1Click:Connect(function()
			if not moved then
				Window:Toggle()
			end
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
			if not column then
				return
			end
			local y = entry.Holder.AbsolutePosition.Y - column.AbsolutePosition.Y + column.CanvasPosition.Y - 50 * scaleFactor()
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
			local hidden = entry.Tab and typeof(entry.Tab.Button) == "Instance" and not entry.Tab.Button.Visible
			if not hidden and entry.Name:lower():find(query, 1, true) then
				table.insert(matches, entry)
				if #matches == 8 then
					break
				end
			end
		end
		if #matches == 0 then
			table.insert(resultButtons, text({ Size = UDim2.new(1, 0, 0, 24), Text = "  Nothing found", TextSize = 12, Theme = { TextColor3 = "Muted" }, Parent = Results }))
			showResults(1)
			return
		end
		for index, entry in ipairs(matches) do
			local Button = create("TextButton", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = index == 1 and 0 or 1,
				AutoButtonColor = false,
				Text = "",
				LayoutOrder = index,
				Theme = { BackgroundColor3 = "Button" },
				Parent = Results,
			}, { corner(5) })
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
			Button.MouseButton1Down:Connect(function()
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
		tween(SearchField, { Size = UDim2.fromOffset(searchOpen, 22) }, TWEEN_SMOOTH)
		runSearch()
	end)
	SearchBox.FocusLost:Connect(function(enterPressed)
		tween(SearchEdge, { Color = Library.Theme.BorderLight })
		tween(SearchField, { Size = UDim2.fromOffset(searchWidth, 22) }, TWEEN_SMOOTH)
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
	local tabIcons = info.TabIcons ~= false

	function Window:AddSection(title)
		navOrder = navOrder + 1
		local Spacer = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 1),
			LayoutOrder = navOrder,
			Visible = navOrder > 1,
			Parent = TabList,
		})
		self.Section = title
		return Spacer
	end

	local function scrollIntoView(Button)
		task.defer(function()
			if not Button.Parent then
				return
			end
			local left = Button.AbsolutePosition.X - TabList.AbsolutePosition.X + TabList.CanvasPosition.X
			local right = left + Button.AbsoluteSize.X
			local view = TabList.AbsoluteWindowSize.X
			local x = TabList.CanvasPosition.X
			if left < x then
				x = left
			elseif right > x + view then
				x = right - view
			end
			if x ~= TabList.CanvasPosition.X then
				tween(TabList, { CanvasPosition = Vector2.new(math.max(x, 0), 0) }, TWEEN_SMOOTH)
			end
		end)
	end

	function Window:AddTab(name, iconName, opts)
		if type(iconName) == "table" then
			iconName, opts = iconName.Icon, iconName
		end
		opts = opts or {}
		navOrder = navOrder + 1
		local selected, hovering = false, false
		local Button = create("TextButton", {
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = navOrder,
			Parent = TabList,
		})
		local Inner = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Parent = Button,
		}, { list(5, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local wanted = iconName or opts.Icon
		local Glyph
		if tabIcons and wanted and Library:HasIcon(wanted) then
			Glyph = icon(Inner, wanted, 13, { LayoutOrder = 1 })
			Glyph:SetAttribute("DexoriHidden", true)
			Glyph.Visible = false
			task.spawn(function()
				local id = Library:GetAsset("Icons")
				if id and Glyph.Parent then
					Glyph:SetAttribute("DexoriHidden", false)
					Glyph.Visible = Library:HasIcon(wanted)
				end
			end)
		end
		local Label = text({
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			FontFace = FONT_MEDIUM,
			TextSize = 13,
			Text = name,
			LayoutOrder = 2,
			Theme = false,
			Parent = Inner,
		})
		local Bar = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.new(0, 0, 0, 2),
			Theme = { BackgroundColor3 = "Accent" },
			Parent = Button,
		}, { corner(1) })

		local Page = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = Pages })
		local function column(left)
			local Layout = list(12)
			local Scroll = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Position = left and UDim2.fromOffset(12, 0) or UDim2.new(0.5, 13, 0, 0),
				Size = UDim2.new(0.5, -24, 1, 0),
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				ScrollBarThickness = 2,
				Theme = { ScrollBarImageColor3 = "BorderLight" },
				Parent = Page,
			}, { Layout, padding(12, 4, 14, 2) })
			fitCanvas(Scroll, Layout, false, 26)
			return Scroll
		end
		local LeftColumn, RightColumn = column(true), column(false)

		local Tab = { Name = name, Title = opts.Title or name, Button = Button, Page = Page, Label = Label }

		local function paint()
			local T = Library.Theme
			local color = (selected or hovering) and T.Text or T.SubText
			tween(Bar, { Size = UDim2.new(selected and 1 or (hovering and 0.4 or 0), 0, 0, 2) }, TWEEN_SMOOTH)
			tween(Label, { TextColor3 = color })
			if Glyph then
				tween(Glyph, { ImageColor3 = selected and T.Accent or color })
			end
		end
		table.insert(ThemeCallbacks, paint)
		Label.TextColor3 = Library.Theme.SubText
		if Glyph then
			Glyph.ImageColor3 = Library.Theme.SubText
		end

		function Tab:AddLeftGroupbox(title)
			return newGroupbox(Tab, LeftColumn, title)
		end
		function Tab:AddRightGroupbox(title)
			return newGroupbox(Tab, RightColumn, title)
		end
		function Tab:SetTitle(value)
			self.Title = tostring(value or "")
		end
		function Tab:SetIcon(value)
			wanted = value
			if Glyph then
				Glyph:SetAttribute("DexoriHidden", false)
				Library:SetIcon(Glyph, value)
			end
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
			if state and not was then
				Page.Position = UDim2.fromOffset(0, 12)
				tween(Page, { Position = UDim2.new() }, PAGE_IN)
				Cover.BackgroundTransparency = 0
				tween(Cover, { BackgroundTransparency = 1 }, COVER_IN)
				scrollIntoView(Button)
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
	scaleTooltip()
	if info.AutoShow == false or Library:GetSilentLoad() then
		Library.PopupLayer.Visible = false
	else
		Window:Toggle(true)
	end
	return Window
end

function Library:Notify(title, description, duration)
	if type(title) == "table" then
		title, description, duration = title.Title or self.Title or "Dexori", title.Description or title.Text, title.Time or title.Duration
	elseif description == nil or type(description) == "number" then
		title, description, duration = self.Title or "Dexori", title, duration or description
	end
	if self.Unloaded then
		return
	end
	if not self.NotifyHolder then
		warn("[Dexori UI] " .. tostring(description))
		return
	end
	duration = math.max(tonumber(duration) or 4, 0.5)
	local Holder = self.NotifyHolder

	local live = {}
	for _, child in ipairs(self.NotifyHolder:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(live, child)
		end
	end
	if #live >= 5 then
		table.sort(live, function(a, b)
			return (a:GetAttribute("At") or 0) < (b:GetAttribute("At") or 0)
		end)
		for i = 1, #live - 4 do
			live[i]:Destroy()
		end
	end
	local Slot = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = self.NotifyHolder,
	})
	Slot:SetAttribute("At", os.clock())
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
		tween(Card, { Position = UDim2.fromOffset(0, 0) }, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
		tween(Fill, { Size = UDim2.fromScale(0, 1) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))
	end)

	local gone = false
	local function fitSlot()
		if gone or not Slot.Parent then
			return
		end
		local height = Card.AbsoluteSize.Y
		Slot:SetAttribute("Height", height)
		tween(Slot, { Size = UDim2.new(1, 0, 0, height) }, TWEEN_SMOOTH)
		local slots, total = {}, 0
		for _, child in ipairs(Holder:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(slots, child)
				total = total + (child:GetAttribute("Height") or 0) + 8
			end
		end
		local room = Holder.AbsoluteSize.Y
		if room > 0 and total > room and #slots > 1 then
			table.sort(slots, function(a, b)
				return (a:GetAttribute("At") or 0) < (b:GetAttribute("At") or 0)
			end)
			for index = 1, #slots - 1 do
				if total <= room then
					break
				end
				total = total - (slots[index]:GetAttribute("Height") or 0) - 8
				slots[index]:Destroy()
			end
		end
	end
	Card:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitSlot)
	task.defer(fitSlot)
	local function dismiss()
		if gone then
			return
		end
		gone = true
		for _, entry in ipairs(entries) do
			tween(entry[1], { [entry[2]] = 1 }, POP_OUT)
		end
		if not Slot.Parent then
			return
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

local RESERVED_NAMES = { CON = true, PRN = true, AUX = true, NUL = true }
for index = 1, 9 do
	RESERVED_NAMES["COM" .. index] = true
	RESERVED_NAMES["LPT" .. index] = true
end
local function cleanName(name)
	local cleaned = tostring(name or ""):gsub("[%c/\\:%*%?\"<>|]", "")
	cleaned = cleaned:gsub("^[%s%.]+", ""):gsub("[%s%.]+$", "")
	if RESERVED_NAMES[string.upper(cleaned)] then
		return ""
	end
	return cleaned
end

local function fileExists(path)
	local ok, exists = pcall(isfile, path)
	return ok and exists == true
end

function Library:SetFolder(folder)
	self.Folder = folder
end

function Library:_configPath(name)
	return self.Folder .. "/configs/" .. name .. ".json"
end

function Library:_configName(name)
	return cleanName(name)
end

function Library:_readMenu()
	if self._menu then
		return self._menu
	end
	local data
	if hasFileApi() then
		local path = self.Folder .. "/menu.json"
		local ok, decoded = pcall(function()
			return isfile(path) and HttpService:JSONDecode(readfile(path)) or nil
		end)
		if ok and type(decoded) == "table" then
			data = decoded
		end
	end
	self._menuFresh = data == nil
	self._menu = data or {}
	return self._menu
end

function Library:_writeMenu(key, value)
	local data = self:_readMenu()
	if key ~= nil then
		if data[key] == value then
			return
		end
		data[key] = value
	end
	if not hasFileApi() then
		return
	end
	pcall(function()
		ensureFolder(self.Folder)
		writefile(self.Folder .. "/menu.json", HttpService:JSONEncode(data))
	end)
end

local function fits(option, value)
	local kind = option.Type
	if kind == "Toggle" then
		return type(value) == "boolean"
	elseif kind == "Slider" then
		return type(value) == "number" and value == value
	elseif kind == "Input" then
		return type(value) == "string" or type(value) == "number"
	elseif kind == "Keybind" then
		return type(value) == "string"
	elseif kind == "ColorPicker" then
		return type(value) == "string" or type(value) == "table"
	elseif kind == "Dropdown" then
		if option.Multi then
			return type(value) == "table"
		end
		return value == false or type(value) == "string" or (type(value) == "number" and table.find(option.Values, value) ~= nil)
	end
	return true
end

local function configSnapshot(text)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(text)
	end)
	if not ok or type(data) ~= "table" or type(data.objects) ~= "table" then
		return nil
	end
	local map = {}
	for _, object in ipairs(data.objects) do
		if type(object) == "table" and object.idx ~= nil then
			local okValue, value = pcall(function()
				return HttpService:JSONEncode({ object.value })
			end)
			map[tostring(object.idx)] = okValue and value or "?"
		end
	end
	return map
end

local function sameSnapshot(a, b)
	if not (a and b) then
		return false
	end
	for key, value in pairs(a) do
		if b[key] ~= value then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

function Library:SaveConfig(name)
	if not hasFileApi() then
		return false, "Your executor can't save files."
	end
	name = self:_configName(name)
	if name == "" then
		return false, "Enter a config name first."
	end
	local objects, skipped = {}, {}
	for id, option in pairs(self.Options) do
		if option.Save then
			local value = option.Value
			local plain = true
			if option.Type == "Keybind" then
				value = typeof(option.Value) == "EnumItem" and option.Value.Name or "None"
			elseif option.Type == "ColorPicker" then
				value = { hex = toHex(option.Value), transparency = option.Transparency }
			elseif option.Type == "Dropdown" and option.Multi and type(value) == "table" then
				local list = {}
				for key, on in pairs(value) do
					if on then
						if type(key) == "string" or type(key) == "number" then
							table.insert(list, key)
						else
							plain = false
						end
					end
				end
				table.sort(list, function(a, b)
					return tostring(a) < tostring(b)
				end)
				value = list
			elseif option.Type == "Dropdown" and value == nil then
				value = false
			end
			local kind = type(value)
			if kind ~= "string" and kind ~= "number" and kind ~= "boolean" and kind ~= "table" then
				plain = false
			end
			local okValue = plain and pcall(function()
				return HttpService:JSONEncode({ value })
			end)
			if okValue then
				table.insert(objects, { type = option.Type, idx = id, value = value })
			else
				table.insert(skipped, tostring(id))
			end
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
	local want = configSnapshot(encoded)
	local function written()
		local okRead, back = pcall(readfile, path)
		if not okRead or type(back) ~= "string" then
			return false
		end
		return back == encoded or sameSnapshot(want, configSnapshot(back))
	end
	local ok, err = pcall(function()
		ensureFolder(self.Folder .. "/configs")
		writefile(path, encoded)
	end)
	if not ok then
		return false, "Couldn't write the file: " .. tostring(err)
	end
	if not written() then
		if type(delfile) == "function" then
			pcall(delfile, path)
		end
		pcall(writefile, path, encoded)
		if not written() then
			pcall(writefile, path, encoded)
		end
		if not written() then
			return false, "Your executor didn't overwrite the file (it still has the old settings)."
		end
	end
	self.CurrentConfig = name
	if self.ConfigListRefresh then
		self.ConfigListRefresh()
	end
	return true, name, #objects, skipped
end

function Library:LoadConfig(name)
	if not hasFileApi() then
		return false, "Your executor can't read files."
	end
	name = self:_configName(name)
	local path = self:_configPath(name)
	if name == "" or not fileExists(path) then
		return false, "Config not found."
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" then
		return false, "That config file is corrupted."
	end

	local entries, kinds = data, {}
	if type(data.objects) == "table" then
		entries = {}
		for _, object in ipairs(data.objects) do
			if type(object) == "table" and object.idx ~= nil then
				entries[object.idx] = object.value
				kinds[object.idx] = object.type
			end
		end
	end
	local migrate = self._migrating and self._menuFresh
	local toggles, applied, skipped = {}, 0, 0
	for id, value in pairs(entries) do
		local option = self.Options[id]
		if option and (option.Save or (migrate and option.MenuSetting)) then
			if (kinds[id] ~= nil and kinds[id] ~= option.Type) or not fits(option, value) then
				skipped = skipped + 1
			elseif option.Type == "Toggle" then
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
	self.CurrentConfig = name
	return true, applied, skipped
end

function Library:DeleteConfig(name)
	if not hasFileApi() or type(delfile) ~= "function" then
		return false, "Your executor can't delete files."
	end
	name = self:_configName(name)
	local path = self:_configPath(name)
	if name == "" or not fileExists(path) then
		return false, "Config not found."
	end
	local wasAutoload = self:GetAutoload() == name
	local ok, err = pcall(delfile, path)
	if not ok then
		return false, tostring(err)
	end
	if wasAutoload then
		self:SetAutoload("")
	end
	if self.ConfigListRefresh then
		self.ConfigListRefresh()
	end
	return true
end

function Library:ListConfigs()
	local folder = self.Folder .. "/configs"
	if not hasFileApi() then
		return {}
	end
	local ok, files = pcall(function()
		return isfolder(folder) and listfiles(folder) or {}
	end)
	if not ok or type(files) ~= "table" then
		return {}
	end
	local names = {}
	for _, path in ipairs(files) do
		local name = type(path) == "string" and path:match("([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

function Library:SetAutoload(name)
	if not hasFileApi() then
		return false
	end
	local ok = pcall(function()
		ensureFolder(self.Folder)
		writefile(self.Folder .. "/autoload.txt", (name == nil or name == "") and "" or self:_configName(name))
	end)
	if self.ConfigListRefresh then
		self.ConfigListRefresh()
	end
	return ok
end

function Library:GetAutoload()
	local path = self.Folder .. "/autoload.txt"
	if hasFileApi() and fileExists(path) then
		local ok, name = pcall(readfile, path)
		name = ok and type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
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
	self._migrating = true
	local ok, result, skipped = self:LoadConfig(name)
	self._migrating = nil
	if ok then
		if self._menuFresh and self._menu then
			self._menuFresh = false
			self:_writeMenu()
		end
		local note = type(skipped) == "number" and skipped > 0 and (" " .. skipped .. " settings didn't fit and were skipped.") or ""
		self:Notify("Dexori", "Auto loaded config \"" .. name .. "\"." .. note)
	elseif result == "Config not found." then
		self:SetAutoload("")
		self:Notify("Dexori", "Autoload config \"" .. name .. "\" is gone, so autoload was turned off.")
	else
		self:Notify("Dexori", "Failed to load autoload config \"" .. name .. "\": " .. tostring(result))
	end
end

function Library:BuildSettingsTab(window, name, section)
	if section ~= false and window.AddSection and window.Section ~= (section or "Other") then
		window:AddSection(section or "Other")
	end
	local Tab = window:AddTab(name or "Settings", "settings")

	local saved = self:_readMenu()
	if parseKey(saved.MenuKeybind) then
		self:SetToggleKey(saved.MenuKeybind)
	end
	if type(saved.KeybindList) == "boolean" then
		self:SetKeybindList(saved.KeybindList)
	end
	if type(saved.Watermark) == "boolean" then
		self:SetWatermark(saved.Watermark)
	end
	local SCALES = { "75%", "90%", "100%", "110%", "125%" }
	local scaleDefault = "100%"
	if type(saved.UIScale) == "number" and table.find(SCALES, saved.UIScale .. "%") then
		scaleDefault = saved.UIScale .. "%"
		self:SetScale(saved.UIScale / 100)
	end

	local Menu = Tab:AddLeftGroupbox("Menu")
	local MenuKey = Menu:AddKeybind("MenuKeybind", {
		Text = "Menu key",
		Default = self.ToggleKey and self.ToggleKey.Name or "RightControl",
		Mode = "Press",
		ShowInList = false,
		Save = false,
	})
	MenuKey.MenuSetting = true
	MenuKey:OnChanged(function(key)
		if key == nil then
			local keep = Library.ToggleKey or Enum.KeyCode.RightControl
			Library:Notify("Dexori", "The menu key can't be empty, so it stays " .. tostring(keep.Name) .. ".")
			task.defer(function()
				MenuKey:SetValue(keep)
			end)
			return
		end
		Library:SetToggleKey(key)
		Library:_writeMenu("MenuKeybind", key.Name)
	end)
	Menu:AddToggle("KeybindList", {
		Text = "Keybind list",
		Default = self.KeybindListEnabled,
		Save = false,
		Callback = function(enabled)
			Library:SetKeybindList(enabled)
			Library:_writeMenu("KeybindList", enabled)
		end,
	}).MenuSetting = true
	Menu:AddToggle("Watermark", {
		Text = "Watermark",
		Default = self.WatermarkEnabled,
		Save = false,
		Callback = function(enabled)
			Library:SetWatermark(enabled)
			Library:_writeMenu("Watermark", enabled)
		end,
	}).MenuSetting = true
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
		Values = SCALES,
		Default = scaleDefault,
		Strict = true,
		Save = false,
		Callback = function(value)
			local percent = type(value) == "string" and tonumber((value:gsub("%%", "")))
			if percent then
				percent = math.clamp(percent, 50, 150)
				Library:SetScale(percent / 100)
				Library:_writeMenu("UIScale", percent)
			end
		end,
	}).MenuSetting = true
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
		local Edge = stroke("BorderLight")
		local Button = create("TextButton", {
			AnchorPoint = props.AnchorPoint or Vector2.zero,
			Position = props.Position or UDim2.new(),
			Size = UDim2.fromOffset(props.Size or 26, props.Size or 26),
			AutoButtonColor = false,
			Text = props.Fallback or "",
			FontFace = FONT_BOLD,
			TextSize = 12,
			LayoutOrder = props.LayoutOrder or 0,
			BackgroundTransparency = props.Filled and 0 or 1,
			Theme = { BackgroundColor3 = props.Filled and "Field" or "Panel", TextColor3 = "SubText" },
			Parent = parent,
		}, { corner(7), Edge })
		Edge.Enabled = props.Filled == true
		pressScale(Button)
		local Glyph = icon(Button, iconName, props.IconSize or 13, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
		})
		task.spawn(function()
			if Library:GetAsset("Icons") and Button.Parent then
				Button.Text = ""
			end
		end)
		local state = { hot = false, lit = false, danger = false }
		local function paint()
			local T = Library.Theme
			local color = (state.lit or state.danger) and T.Accent or (state.hot and T.Text or T.Muted)
			tween(Glyph, { ImageColor3 = color })
			if props.Filled then
				tween(Edge, { Color = (state.danger or state.hot) and (state.danger and T.Accent or T.Muted) or T.BorderLight })
			else
				tween(Button, { BackgroundTransparency = state.hot and 0 or 1, BackgroundColor3 = T.Hover })
			end
		end
		themed(Button, paint)
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
	local NameEdge = stroke("BorderLight")
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
		tween(NameEdge, { Color = Library.Theme.BorderLight })
	end)
	local CreateButton = iconButton(NameRow, "plus", "Save a new config", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = 30,
		IconSize = 15,
		Filled = true,
		Fallback = "+",
	})
	Configs:_index("Create config", NameRow, NameRow)

	local Head = Configs:_holder(18, true)
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
		Fallback = "R",
	})

	local ListHolder = Configs:_holder(nil, true)
	local ListFrame = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = ListHolder,
	}, { list(5) })

	local rows = {}
	local refresh
	local shownKey = nil
	local function paintHead(count)
		HeadText.Text = "SAVED CONFIGS · " .. tostring(count)
	end
	local function notify(message)
		Library:Notify(Library.Title or "Dexori", message)
	end

	local function configRow(name, index, autoload)
		local Row = create("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			LayoutOrder = index,
			Theme = { BackgroundColor3 = "Field" },
			Parent = ListFrame,
		}, { corner(8), stroke("BorderLight") })
		icon(Row, "folder", 13, {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(11, 16),
			Theme = { ImageColor3 = autoload and "Accent" or "Muted" },
		})
		text({
			Position = UDim2.fromOffset(32, 4),
			Size = UDim2.new(1, -42, 0, 24),
			FontFace = FONT_MEDIUM,
			TextSize = 13,
			Text = name,
			TextTruncate = Enum.TextTruncate.AtEnd,
			KeepCase = true,
			Theme = { TextColor3 = autoload and "Accent" or "Text" },
			Parent = Row,
		})
		local Actions = create("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -5, 1, -4),
			Size = UDim2.fromOffset(0, 26),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = Row,
		}, { list(2, true, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
		local Load = iconButton(Actions, "play", "Load", { LayoutOrder = 1, Fallback = "L" })
		local Save = iconButton(Actions, "save", "Overwrite with current settings", { LayoutOrder = 2, Fallback = "S" })
		local Star, setStar = iconButton(Actions, "star", autoload and "Stop autoloading" or "Load this on start", { LayoutOrder = 3, Fallback = "A" })
		setStar("lit", autoload)
		local Delete, setDelete = iconButton(Actions, "trash-2", "Delete (click twice)", { LayoutOrder = 4, Fallback = "X" })

		Load.MouseButton1Click:Connect(function()
			local ok, result, skipped = Library:LoadConfig(name)
			if not ok then
				notify("Couldn't load: " .. tostring(result))
				return
			end
			local note = type(skipped) == "number" and skipped > 0 and (", " .. skipped .. " skipped") or ""
			notify("Loaded \"" .. name .. "\" (" .. tostring(result) .. " settings" .. note .. ").")
		end)
		Save.MouseButton1Click:Connect(function()
			local ok, result, count, skipped = Library:SaveConfig(name)
			if not ok then
				notify("Couldn't save: " .. tostring(result))
				return
			end
			local note = type(skipped) == "table" and #skipped > 0 and (", " .. #skipped .. " couldn't be saved") or ""
			notify("Saved over \"" .. name .. "\" (" .. tostring(count) .. " settings" .. note .. ").")
			Library.ConfigListRefresh()
		end)
		Star.MouseButton1Click:Connect(function()
			if autoload then
				Library:SetAutoload("")
				notify("\"" .. name .. "\" won't load on start any more.")
			else
				Library:SetAutoload(name)
				notify("\"" .. name .. "\" will load on start.")
			end
			Library.ConfigListRefresh()
		end)
		local armed, armToken = false, 0
		Delete.MouseButton1Click:Connect(function()
			if not armed then
				armed = true
				armToken = armToken + 1
				local token = armToken
				setDelete("danger", true)
				task.delay(2.5, function()
					if token == armToken and Delete.Parent then
						armed = false
						setDelete("danger", false)
					end
				end)
				return
			end
			armToken = armToken + 1
			local ok, err = Library:DeleteConfig(name)
			notify(ok and ("Deleted \"" .. name .. "\".") or ("Couldn't delete: " .. tostring(err)))
			if not ok and Delete.Parent then
				armed = false
				setDelete("danger", false)
			end
			Library.ConfigListRefresh()
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
		shownKey = table.concat(names, "\0") .. "\1" .. tostring(current)
		paintHead(#names)
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
		local wanted = cleanName(NameBox.Text)
		if wanted == "" then
			notify("Type a config name first.")
			return
		end
		if table.find(Library:ListConfigs(), wanted) then
			notify("\"" .. wanted .. "\" already exists. Use its save button to overwrite it.")
			return
		end
		local ok, result, _, skipped = Library:SaveConfig(wanted)
		if not ok then
			notify("Couldn't save: " .. tostring(result))
			return
		end
		NameBox.Text = ""
		local note = type(skipped) == "table" and #skipped > 0 and (" " .. #skipped .. " settings couldn't be saved.") or ""
		notify("Saved \"" .. result .. "\"." .. note)
		Library.ConfigListRefresh()
	end
	CreateButton.MouseButton1Click:Connect(createConfig)
	NameBox.FocusLost:Connect(function(enter)
		if enter then
			createConfig()
		end
	end)
	RefreshButton.MouseButton1Click:Connect(refresh)
	Library.ConfigListRefresh = function()
		if Library.Unloaded or not ListFrame.Parent then
			return
		end
		local names = Library:ListConfigs()
		local key = table.concat(names, "\0") .. "\1" .. tostring(Library:GetAutoload())
		if key ~= shownKey then
			refresh()
		else
			paintHead(#names)
		end
	end
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
	local env = type(getgenv) == "function" and getgenv() or _G
	if self._instanceSlot and rawget(env, self._instanceSlot) == self then
		rawset(env, self._instanceSlot, nil)
	end
	endDrag()
	table.clear(ScaleHooks)
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
	for _, target in pairs({ self.Watermark, self.KeybindPanel, self.MobileButton, self.NotifyHolder, self.TargetCard and self.TargetCard.Frame }) do
		popout(target, false)
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
