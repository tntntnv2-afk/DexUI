local Library = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
	Version = "2.0.0",
	Registry = {},
	Toggles = {},
	Options = {},
	Signals = {},
	Windows = {},
	SearchIndex = {},
	OpenPopups = {},
	Unloaded = false,
	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	Theme = {
		Background = Color3.fromRGB(0, 0, 0),
		Well = Color3.fromRGB(0, 0, 0),
		Main = Color3.fromRGB(0, 0, 0),
		Element = Color3.fromRGB(0, 0, 0),
		ElementHover = Color3.fromRGB(13, 13, 15),
		Accent = Color3.fromRGB(214, 40, 48),
		AccentGradient = ColorSequence.new(Color3.fromRGB(243, 62, 70), Color3.fromRGB(128, 14, 20)),
		Outline = Color3.fromRGB(38, 38, 42),
		OutlineStrong = Color3.fromRGB(72, 22, 26),
		Font = Color3.fromRGB(238, 238, 241),
		FontDim = Color3.fromRGB(122, 122, 132),
		Risky = Color3.fromRGB(255, 92, 92),
	},
	FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	FontFaceBold = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
	ESPFont = Font.fromEnum(Enum.Font.Code),
	ToggleKeybind = Enum.KeyCode.RightControl,
	Icon = "rbxassetid://83607561451748",
	Effects = { Blur = false, Dim = false, Snow = true, BlurSize = 12, DimAmount = 0.32, SnowCount = 45 },
}

getgenv().Toggles = Library.Toggles
getgenv().Options = Library.Options

local function getGuiParent()
	local ok, hui = pcall(function() return gethui and gethui() end)
	if ok and hui then return hui end
	return CoreGui
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DexoriUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
pcall(function() ScreenGui.Parent = getGuiParent() end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
Library.ScreenGui = ScreenGui

local function Create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do if k ~= "Parent" then inst[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end
local function Tween(obj, props, t, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
function Library:AddToRegistry(inst, props)
	self.Registry[inst] = props
	for prop, key in pairs(props) do local v = self.Theme[key] if v ~= nil then pcall(function() inst[prop] = v end) end end
end
function Library:RemoveFromRegistry(inst) self.Registry[inst] = nil end
function Library:UpdateColorsUsingRegistry()
	for inst, props in pairs(self.Registry) do
		if inst and inst.Parent then
			for prop, key in pairs(props) do local v = self.Theme[key] if v ~= nil then pcall(function() inst[prop] = v end) end end
		else self.Registry[inst] = nil end
	end
end
function Library:SetTheme(theme) for k, v in pairs(theme) do self.Theme[k] = v end self:UpdateColorsUsingRegistry() end
function Library:GiveSignal(c) table.insert(self.Signals, c) return c end
local function Corner(p, r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 2), Parent = p }) end
local function Stroke(p, key, thick, transp)
	local s = Create("UIStroke", { Thickness = thick or 1, Transparency = transp or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
	Library:AddToRegistry(s, { Color = key or "Outline" })
	return s
end
local function Pad(p, l, r, t, b) return Create("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or 0), PaddingTop = UDim.new(0, t or 0), PaddingBottom = UDim.new(0, b or 0), Parent = p }) end
local function Text(parent, txt, size, bold, key)
	local l = Create("TextLabel", { BackgroundTransparency = 1, Text = txt or "", TextSize = size or 12, FontFace = bold and Library.FontFaceBold or Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Size = UDim2.new(1, 0, 0, 16), RichText = true, TextTruncate = Enum.TextTruncate.AtEnd, Parent = parent })
	Library:AddToRegistry(l, { TextColor3 = key or "Font" })
	return l
end
local function IsPressed(inp) return inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch end
local function Draggable(handle, frame)
	local dragging, dragStart, startPos = false, nil, nil
	handle.InputBegan:Connect(function(inp)
		if IsPressed(inp) then
			dragging = true dragStart = inp.Position startPos = frame.Position
			inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))
end

local function Ripple(btn, color)
	btn.ClipsDescendants = true
	btn.InputBegan:Connect(function(inp)
		if not (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then return end
		local abs = btn.AbsolutePosition
		local rx, ry = inp.Position.X - abs.X, inp.Position.Y - abs.Y
		local far = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
		local c = Create("Frame", { Size = UDim2.fromOffset(0, 0), Position = UDim2.fromOffset(rx, ry), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = color or Library.Theme.Accent, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = (btn.ZIndex or 1) + 1, Parent = btn })
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = c })
		Tween(c, { Size = UDim2.fromOffset(far, far), BackgroundTransparency = 1 }, 0.45, Enum.EasingStyle.Quint)
		task.delay(0.5, function() c:Destroy() end)
	end)
end

local function Press(btn, scale)
	local s = Create("UIScale", { Scale = 1, Parent = btn })
	btn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			Tween(s, { Scale = scale or 0.97 }, 0.08)
		end
	end)
	btn.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			Tween(s, { Scale = 1 }, 0.16, Enum.EasingStyle.Back)
		end
	end)
	return s
end

local function SearchIcon(parent, size, themeKey)
	local holder = Create("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = (parent.ZIndex or 1) + 1, Parent = parent })
	local ring = Create("Frame", { Size = UDim2.fromOffset(size - 5, size - 5), Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, ZIndex = holder.ZIndex, Parent = holder })
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	local rs = Create("UIStroke", { Thickness = 1.4, Parent = ring })
	Library:AddToRegistry(rs, { Color = themeKey or "FontDim" })
	local tail = Create("Frame", { Size = UDim2.fromOffset(1.4, 5), Position = UDim2.fromOffset(size - 6, size - 6), Rotation = -45, BorderSizePixel = 0, ZIndex = holder.ZIndex, Parent = holder })
	Library:AddToRegistry(tail, { BackgroundColor3 = themeKey or "FontDim" })
	return holder
end
local function Chevron(parent, size, themeKey)
	local holder = Create("Frame", { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = (parent.ZIndex or 1) + 1, Parent = parent })
	local a = Create("Frame", { Size = UDim2.fromOffset(6, 1.4), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.5, 1, 0.5, 0), Rotation = 45, BorderSizePixel = 0, ZIndex = holder.ZIndex, Parent = holder })
	local b = Create("Frame", { Size = UDim2.fromOffset(6, 1.4), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.5, -1, 0.5, 0), Rotation = -45, BorderSizePixel = 0, ZIndex = holder.ZIndex, Parent = holder })
	Library:AddToRegistry(a, { BackgroundColor3 = themeKey or "FontDim" })
	Library:AddToRegistry(b, { BackgroundColor3 = themeKey or "FontDim" })
	return holder
end
-- simple vector icons, drawn so they always render and always match the theme
local IconParts = setmetatable({}, { __mode = "k" })
local function SetIconKey(root, key)
	local parts = IconParts[root]
	if not parts then return end
	for _, pr in ipairs(parts) do
		if pr.fill then
			Library.Registry[pr.f] = { BackgroundColor3 = key }
			pr.f.BackgroundColor3 = Library.Theme[key]
		else
			Library.Registry[pr.f] = { Color = key }
			pr.f.Color = Library.Theme[key]
		end
	end
end
local function Icon(parent, name, size, themeKey)
	size = size or 18
	local key = themeKey or "FontDim"
	local root = Create("Frame", { Name = "Icon", Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = (parent.ZIndex or 1) + 1, Parent = parent })
	local parts = {}
	local function bar(w, h, x, y, rot, r)
		local f = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, x, 0.5, y), Rotation = rot or 0, BorderSizePixel = 0, ZIndex = root.ZIndex, Parent = root })
		Create("UICorner", { CornerRadius = UDim.new(0, r or 1), Parent = f })
		Library:AddToRegistry(f, { BackgroundColor3 = key })
		parts[#parts + 1] = { f = f, fill = true }
		return f
	end
	local function ring(w, h, x, y, thick)
		local f = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, x, 0.5, y), BackgroundTransparency = 1, ZIndex = root.ZIndex, Parent = root })
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = f })
		local s = Create("UIStroke", { Thickness = thick or 1.5, Parent = f })
		Library:AddToRegistry(s, { Color = key })
		parts[#parts + 1] = { f = s, fill = false }
		return f
	end
	local function box(w, h, x, y, thick, r)
		local f = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(w, h), Position = UDim2.new(0.5, x, 0.5, y), BackgroundTransparency = 1, ZIndex = root.ZIndex, Parent = root })
		Create("UICorner", { CornerRadius = UDim.new(0, r or 2), Parent = f })
		local s = Create("UIStroke", { Thickness = thick or 1.5, Parent = f })
		Library:AddToRegistry(s, { Color = key })
		parts[#parts + 1] = { f = s, fill = false }
		return f
	end

	local k = size / 18
	if name == "sliders" then
		bar(14 * k, 2, 0, -5 * k) bar(5 * k, 5 * k, 3 * k, -5 * k, 0, 3)
		bar(14 * k, 2, 0, 0) bar(5 * k, 5 * k, -3 * k, 0, 0, 3)
		bar(14 * k, 2, 0, 5 * k) bar(5 * k, 5 * k, 2 * k, 5 * k, 0, 3)
	elseif name == "eye" then
		ring(17 * k, 11 * k, 0, 0, 1.8) bar(5 * k, 5 * k, 0, 0, 0, 3)
	elseif name == "gear" then
		ring(9 * k, 9 * k, 0, 0, 2)
		for i = 0, 7 do
			local a = math.rad(i * 45)
			bar(3.2 * k, 3.2 * k, math.cos(a) * 7 * k, math.sin(a) * 7 * k, i * 45, 1.5)
		end
	elseif name == "user" then
		ring(8 * k, 8 * k, 0, -4 * k, 1.8) box(14 * k, 7 * k, 0, 5.5 * k, 1.8, 4)
	elseif name == "target" then
		ring(15 * k, 15 * k, 0, 0, 1.8) ring(7 * k, 7 * k, 0, 0, 1.8) bar(2.5 * k, 2.5 * k, 0, 0, 0, 2)
	elseif name == "bolt" then
		bar(3 * k, 9 * k, 1 * k, -4 * k, 18, 1.5) bar(3 * k, 9 * k, -1 * k, 4 * k, 18, 1.5) bar(7 * k, 2, 0, 0, 18)
	elseif name == "shield" then
		box(13 * k, 15 * k, 0, 0, 1.8, 6) bar(1.8, 7 * k, 0, 0, 0, 1)
	elseif name == "grid" then
		box(6 * k, 6 * k, -4 * k, -4 * k, 1.8, 2) box(6 * k, 6 * k, 4 * k, -4 * k, 1.8, 2) box(6 * k, 6 * k, -4 * k, 4 * k, 1.8, 2) box(6 * k, 6 * k, 4 * k, 4 * k, 1.8, 2)
	else
		ring(14 * k, 14 * k, 0, 0, 1.8)
	end
	IconParts[root] = parts
	return root
end
local function Hover(btn, normalKey, hoverKey)
	btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = Library.Theme[hoverKey] }, 0.1)
		local s = btn:FindFirstChildOfClass("UIStroke")
		if s then Tween(s, { Color = Library.Theme.FontDim }, 0.12) end
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = Library.Theme[normalKey] }, 0.1)
		local s = btn:FindFirstChildOfClass("UIStroke")
		if s then local key = Library.Registry[s] and Library.Registry[s].Color or "Outline" Tween(s, { Color = Library.Theme[key] or Library.Theme.Outline }, 0.12) end
	end)
end

local function Glass(frame)
	local sheen = Create("Frame", { Name = "_glass", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.985, BorderSizePixel = 0, ZIndex = (frame.ZIndex or 1), Parent = frame })
	Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = sheen })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.45, 0.98), NumberSequenceKeypoint.new(1, 1) }), Parent = sheen })
	local edge = Create("UIStroke", { Thickness = 1, Transparency = 0.8, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.fromRGB(255, 255, 255), Parent = frame })
	return sheen
end
local function Shadow(frame, spread)
	spread = spread or 16
	local host = frame.Parent
	if not host then return end
	local holder = Create("Frame", { Name = "_shadow", BackgroundTransparency = 1, ZIndex = math.max((frame.ZIndex or 1) - 1, 0), Parent = host })
	holder.LayoutOrder = -9999
	local function sync()
		holder.Size = UDim2.fromOffset(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
		holder.Position = UDim2.fromOffset(frame.AbsolutePosition.X - host.AbsolutePosition.X, frame.AbsolutePosition.Y - host.AbsolutePosition.Y)
		holder.Visible = frame.Visible
	end
	for i = 1, 3 do
		local pad = math.floor(spread * i / 3)
		local sh = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, pad * 2, 1, pad * 2), Position = UDim2.new(0.5, 0, 0.5, math.floor(pad * 0.25)), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.9 + (i - 1) * 0.03, BorderSizePixel = 0, ZIndex = holder.ZIndex, Parent = holder })
		Create("UICorner", { CornerRadius = UDim.new(0, 14 + pad), Parent = sh })
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(sync)
	frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(sync)
	frame:GetPropertyChangedSignal("Visible"):Connect(sync)
	frame.AncestryChanged:Connect(function(_, parent)
		if not parent then holder:Destroy() end
	end)
	frame.Destroying:Connect(function() holder:Destroy() end)
	task.defer(sync)
	return holder
end
local PopupLayer = Create("Frame", { Name = "Popups", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 500, Parent = ScreenGui })
-- dock a popup beside the window (right edge), level with its trigger, never over the content
local function DockPopup(popup, trigger)
	local win = nil
	for _, w in ipairs(Library.Windows) do
		if w.Frame and trigger:IsDescendantOf(w.Frame) then win = w.Frame break end
	end
	local x, y
	if win then
		local right = win.AbsolutePosition.X + win.AbsoluteSize.X
		local screenW = ScreenGui.AbsoluteSize.X
		if right + 12 + popup.AbsoluteSize.X <= screenW - 6 then
			x = right + 12
		else
			x = win.AbsolutePosition.X - 12 - popup.AbsoluteSize.X
		end
		y = trigger.AbsolutePosition.Y
		local top, bottom = win.AbsolutePosition.Y + 8, win.AbsolutePosition.Y + win.AbsoluteSize.Y - 8
		y = math.clamp(y, top, math.max(top, bottom - popup.AbsoluteSize.Y))
	else
		x = trigger.AbsolutePosition.X
		y = trigger.AbsolutePosition.Y + trigger.AbsoluteSize.Y + 6
	end
	popup.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	-- connector: a hairline from the trigger's edge to the popup
	local con = popup:FindFirstChild("_connector") or Create("Frame", { Name = "_connector", Size = UDim2.fromOffset(12, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = popup.ZIndex, Parent = popup })
	Library:AddToRegistry(con, { BackgroundColor3 = "Accent" })
	local left = win and (x > win.AbsolutePosition.X)
	con.AnchorPoint = Vector2.new(left and 1 or 0, 0)
	con.Position = UDim2.new(left and 0 or 1, 0, 0, math.clamp(trigger.AbsolutePosition.Y + trigger.AbsoluteSize.Y * 0.5 - y, 6, math.max(6, popup.AbsoluteSize.Y - 6)))
end
Library.DockPopup = DockPopup

local function PopupShell(width, z, radius, padding)
	local root = Create("Frame", { Size = UDim2.new(0, width, 0, 0), BackgroundTransparency = 0.08, Visible = false, ZIndex = z or 60, Parent = PopupLayer })
	Library:AddToRegistry(root, { BackgroundColor3 = "Main" })
	Create("UICorner", { CornerRadius = UDim.new(0, radius or 12), Parent = root })
	local st = Create("UIStroke", { Thickness = 1, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = root })
	Library:AddToRegistry(st, { Color = "Outline" })
	local edge = Create("UIStroke", { Thickness = 1, Transparency = 0.65, Parent = root })
	Library:AddToRegistry(edge, { Color = "Accent" })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = edge })
	local content = Create("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = (z or 60) + 1, Parent = root })
	Create("UIPadding", { PaddingLeft = UDim.new(0, padding or 6), PaddingRight = UDim.new(0, padding or 6), PaddingTop = UDim.new(0, padding or 6), PaddingBottom = UDim.new(0, padding or 6), Parent = content })
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	return root, content
end
local popupBase = 500
local function RaisePopup(frame)
	popupBase = popupBase + 20
	local old = frame.ZIndex
	local delta = popupBase - old
	frame.ZIndex = popupBase
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("GuiObject") then d.ZIndex = d.ZIndex + delta end
	end
end
Library.PopupLayer, Library.RaisePopup = PopupLayer, RaisePopup
Library.Create, Library.Tween, Library.Text, Library.Draggable = Create, Tween, Text, Draggable
Library.Ripple, Library.Press = Ripple, Press
Library.Glass, Library.Shadow = Glass, Shadow

local Backdrop = Create("Frame", { Name = "Backdrop", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 0, Parent = ScreenGui })
Create("UIGradient", {
	Rotation = 90,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
	}),
	Parent = Backdrop,
})
local BackdropGlow = Create("ImageLabel", { Name = "Glow", Size = UDim2.new(1.4, 0, 1.4, 0), Position = UDim2.new(-0.2, 0, -0.5, 0), BackgroundTransparency = 1, Image = "rbxassetid://5028857084", ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.5, ZIndex = 0, Parent = Backdrop })
local Blur = Create("BlurEffect", { Name = "DexoriBlur", Size = 0, Enabled = false, Parent = Lighting })
local flakes = {}
local snowConn = nil
local function makeFlake()
	local s = math.random(2, 5)
	local near = s >= 4
	local f = Create("ImageLabel", {
		Size = UDim2.fromOffset(s * 3, s * 3), BackgroundTransparency = 1,
		Image = "rbxassetid://4996891970", ImageColor3 = Color3.fromRGB(226, 240, 255),
		ImageTransparency = near and 0.25 or math.random(45, 75) / 100,
		ZIndex = 1, Parent = Backdrop,
	})
	return { f = f, x = math.random(), y = -math.random() * 0.4, vy = (near and math.random(45, 80) or math.random(18, 40)) / 1000, drift = math.random(-18, 18) / 1000, phase = math.random() * 6.28, spin = math.random(-40, 40) }
end
local function startSnow()
	if snowConn then return end
	for i = 1, Library.Effects.SnowCount do flakes[i] = flakes[i] or makeFlake() end
	snowConn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		for _, fl in ipairs(flakes) do
			fl.y = fl.y + fl.vy * dt * 3
			fl.x = fl.x + (fl.drift + math.sin(t * 0.8 + fl.phase) * 0.006) * dt * 3
			if fl.y > 1.05 then fl.y = -0.05 fl.x = math.random() end
			if fl.x < -0.03 then fl.x = 1.03 elseif fl.x > 1.03 then fl.x = -0.03 end
			fl.f.Position = UDim2.new(fl.x, 0, fl.y, 0)
			fl.f.Rotation = (t * fl.spin) % 360
		end
	end)
end
local function stopSnow()
	if snowConn then snowConn:Disconnect() snowConn = nil end
end
function Library:_SetBackdrop(on)
	if on then
		local dim = self.Effects.Dim and (self.Effects.DimAmount or 0.32) or 1
		Backdrop.Visible = (self.Effects.Dim or self.Effects.Snow) and true or false
		BackdropGlow.Visible = self.Effects.Dim and true or false
		Tween(Backdrop, { BackgroundTransparency = dim }, 0.25)
		if self.Effects.Blur then Blur.Enabled = true Tween(Blur, { Size = self.Effects.BlurSize }, 0.25) end
		if self.Effects.Snow then startSnow() end
	else
		Tween(Backdrop, { BackgroundTransparency = 1 }, 0.2).Completed:Connect(function()
			if Backdrop.BackgroundTransparency >= 0.99 then Backdrop.Visible = false end
		end)
		Tween(Blur, { Size = 0 }, 0.2).Completed:Connect(function() if Blur.Size == 0 then Blur.Enabled = false end end)
		stopSnow()
	end
end
function Library:SetEffects(cfg) for k, v in pairs(cfg) do self.Effects[k] = v end end

local NotifHolder = Create("Frame", { Name = "Notifications", BackgroundTransparency = 1, Size = UDim2.new(0, 280, 1, -20), Position = UDim2.new(1, -292, 0, 12), Parent = ScreenGui })
Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifHolder })
function Library:SetNotifySide(side)
	if side == "Left" then NotifHolder.Position = UDim2.new(0, 12, 0, 12) NotifHolder.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	else NotifHolder.Position = UDim2.new(1, -292, 0, 12) NotifHolder.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right end
end
function Library:Notify(opts, duration)
	if type(opts) ~= "table" then opts = { Description = tostring(opts), Time = duration } end
	local title = opts.Title
	local desc = opts.Description or ""
	local time = opts.Time or 4
	local W = 236
	local card = Create("Frame", { Size = UDim2.fromOffset(W, 34), BackgroundTransparency = 0.05, ClipsDescendants = true, Parent = NotifHolder })
	self:AddToRegistry(card, { BackgroundColor3 = "Main" })
	Corner(card, 8); Stroke(card, "Outline")
	local dot = Create("Frame", { Size = UDim2.fromOffset(5, 5), Position = UDim2.new(0, 12, 0, 15), BorderSizePixel = 0, ZIndex = 2, Parent = card })
	Corner(dot, 3); self:AddToRegistry(dot, { BackgroundColor3 = "Accent" })
	local body = Text(card, title and (title .. "  ") or "", 12, true)
	body.Position = UDim2.new(0, 26, 0, 0); body.Size = UDim2.new(1, -38, 1, 0); body.ZIndex = 2
	if title and desc ~= "" then
		body.RichText = true
		body.Text = string.format('%s <font color="rgb(122,122,132)">%s</font>', title, desc)
	elseif not title then
		body.Text = desc
	end
	task.defer(function()
		local lines = math.clamp(math.ceil(body.TextBounds.X / (W - 44)), 1, 2)
		if lines > 1 then
			body.TextWrapped = true
			card.Size = UDim2.fromOffset(W, 48)
			body.Position = UDim2.new(0, 26, 0, 6)
			body.Size = UDim2.new(1, -38, 0, 36)
			body.TextYAlignment = Enum.TextYAlignment.Top
			dot.Position = UDim2.new(0, 12, 0, 12)
		end
	end)
	card.Position = UDim2.new(1, W + 20, 0, 0)
	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.22, Enum.EasingStyle.Quint)
	local obj = { Frame = card }
	function obj:Destroy()
		if not card.Parent then return end
		Tween(card, { Position = UDim2.new(1, W + 20, 0, 0) }, 0.16).Completed:Connect(function() card:Destroy() end)
	end
	task.delay(time, function() obj:Destroy() end)
	card.InputBegan:Connect(function(inp) if IsPressed(inp) then obj:Destroy() end end)
	return obj
end

local Watermark = Create("Frame", { Name = "Watermark", Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 12, 0, 12), Visible = false, Parent = ScreenGui })
Library:AddToRegistry(Watermark, { BackgroundColor3 = "Main" })
Watermark.BackgroundTransparency = 0.12; Corner(Watermark, 2); Stroke(Watermark, "Outline")
local wmAccent = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = Watermark })
Create("UIGradient", { Parent = wmAccent }); Library:AddToRegistry(wmAccent.UIGradient, { Color = "AccentGradient" })
Pad(Watermark, 8, 8, 0, 0)
Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = Watermark })
Create("ImageLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Image = Library.Icon, Parent = Watermark })
local WmText = Create("TextLabel", { LayoutOrder = 2, BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), FontFace = Library.FontFaceBold, TextSize = 11, Text = "dexori", Parent = Watermark })
Library:AddToRegistry(WmText, { TextColor3 = "Font" })
local sep = Create("Frame", { LayoutOrder = 3, Size = UDim2.new(0, 1, 0, 12), BorderSizePixel = 0, Parent = Watermark }); Library:AddToRegistry(sep, { BackgroundColor3 = "Outline" })
local WmSearchBox = Create("Frame", { LayoutOrder = 4, Size = UDim2.new(0, 140, 0, 18), Parent = Watermark })
Library:AddToRegistry(WmSearchBox, { BackgroundColor3 = "Element" }); Corner(WmSearchBox, 2); Stroke(WmSearchBox, "Outline")
local WmSearch = Create("TextBox", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, 0), Position = UDim2.new(0, 6, 0, 0), PlaceholderText = "search", Text = "", TextSize = 11, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = WmSearchBox })
Library:AddToRegistry(WmSearch, { TextColor3 = "Font", PlaceholderColor3 = "FontDim" })
local WmResults = Create("Frame", { Size = UDim2.new(0, 260, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 12, 0, 42), Visible = false, ZIndex = 80, Parent = ScreenGui })
Library:AddToRegistry(WmResults, { BackgroundColor3 = "Main" }); Corner(WmResults, 2); Stroke(WmResults, "OutlineStrong")
Pad(WmResults, 3, 3, 3, 3)
Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = WmResults })
function Library:SetWatermarkVisibility(on) Watermark.Visible = on and true or false end
Watermark.Visible = false
function Library:SetWatermark(text) WmText.Text = text or "dexori" end
function Library:RegisterSearch(name, path, focus, obj) table.insert(self.SearchIndex, { name = name, path = path, focus = focus, obj = obj }) end
local function runSearch(q)
	for _, c in ipairs(WmResults:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	q = string.lower(q or "")
	if q == "" then WmResults.Visible = false return end
	local n = 0
	for _, e in ipairs(Library.SearchIndex) do
		if string.find(string.lower(e.name), q, 1, true) or string.find(string.lower(e.path), q, 1, true) then
			n = n + 1
			if n > 8 then break end
			local b = Create("TextButton", { AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 26), Text = "", LayoutOrder = n, ZIndex = 81, Parent = WmResults })
			Library:AddToRegistry(b, { BackgroundColor3 = "Element" }); Corner(b, 2)
			local nm = Text(b, e.name, 11, true); nm.Position = UDim2.new(0, 6, 0, 1); nm.Size = UDim2.new(1, -12, 0, 13); nm.ZIndex = 82
			local pt = Text(b, e.path, 10, false, "FontDim"); pt.Position = UDim2.new(0, 6, 0, 13); pt.Size = UDim2.new(1, -12, 0, 12); pt.ZIndex = 82
			Hover(b, "Element", "ElementHover")
			b.MouseButton1Click:Connect(function() pcall(e.focus) WmSearch.Text = "" WmResults.Visible = false end)
		end
	end
	WmResults.Visible = n > 0
end
WmSearch:GetPropertyChangedSignal("Text"):Connect(function() runSearch(WmSearch.Text) end)
Draggable(Watermark, Watermark)

local KeybindFrame = Create("Frame", { Name = "Keybinds", Size = UDim2.new(0, 150, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 12, 0.5, -60), Visible = false, Parent = ScreenGui })
Library:AddToRegistry(KeybindFrame, { BackgroundColor3 = "Main" }); Corner(KeybindFrame, 2); Stroke(KeybindFrame, "Outline")
local kbAccent = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, Parent = KeybindFrame })
Create("UIGradient", { Parent = kbAccent }); Library:AddToRegistry(kbAccent.UIGradient, { Color = "AccentGradient" })
Pad(KeybindFrame, 7, 7, 6, 6)
Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = KeybindFrame })
local kbTitle = Text(KeybindFrame, "keybinds", 11, true); kbTitle.LayoutOrder = 0; kbTitle.Size = UDim2.new(1, 0, 0, 14)
Library.KeybindFrame = KeybindFrame
Draggable(KeybindFrame, KeybindFrame)
KeybindFrame.Visible = false
function Library:SetKeybindVisibility(on) KeybindFrame.Visible = on and true or false end

function Library:_ClosePopups(except) for _, p in pairs(self.OpenPopups) do if p ~= except then pcall(function() p.Visible = false end) end end end
Library:GiveSignal(UserInputService.InputBegan:Connect(function(inp)
	if not IsPressed(inp) then return end
	local pos = inp.Position
	for _, p in pairs(Library.OpenPopups) do
		if p.Visible then
			local a, s = p.AbsolutePosition, p.AbsoluteSize
			local inside = pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
			if not inside then task.defer(function() p.Visible = false end) end
		end
	end
end))

function Library:Confirm(title, body, onYes, onNo)
	if self._confirm then self._confirm:Destroy() end
	local veil = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 900, Parent = PopupLayer })
	self._confirm = veil
	Tween(veil, { BackgroundTransparency = 0.6 }, 0.12)

	local box = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(268, 118), Position = UDim2.new(0.5, 0, 0.5, 0), ZIndex = 901, Parent = veil })
	self:AddToRegistry(box, { BackgroundColor3 = "Main" })
	Corner(box, 10)
	local st = Create("UIStroke", { Thickness = 1, Parent = box })
	self:AddToRegistry(st, { Color = "Outline" })

	local t = Text(box, title or "are you sure?", 12, true); t.Position = UDim2.new(0, 16, 0, 16); t.Size = UDim2.new(1, -32, 0, 15); t.ZIndex = 902
	local d = Text(box, body or "", 11, false, "FontDim")
	d.Position = UDim2.new(0, 16, 0, 35); d.Size = UDim2.new(1, -32, 0, 30); d.TextWrapped = true; d.TextYAlignment = Enum.TextYAlignment.Top; d.ZIndex = 902
	local rule = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -37), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 902, Parent = box })
	self:AddToRegistry(rule, { BackgroundColor3 = "Outline" })

	local scale = Create("UIScale", { Scale = 0.97, Parent = box })
	Tween(scale, { Scale = 1 }, 0.14, Enum.EasingStyle.Quint)

	local function close()
		Tween(veil, { BackgroundTransparency = 1 }, 0.1)
		Tween(scale, { Scale = 0.98 }, 0.1).Completed:Connect(function()
			if veil.Parent then veil:Destroy() end
			if self._confirm == veil then self._confirm = nil end
		end)
	end
	local function mk(text, xScale, accent, fn)
		local b = Create("TextButton", { Size = UDim2.new(0.5, -1, 0, 36), Position = UDim2.new(xScale, xScale == 0 and 0 or 1, 1, -36), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 902, Parent = box })
		local l = Text(b, text, 12, true, accent and "Accent" or "FontDim")
		l.TextXAlignment = Enum.TextXAlignment.Center; l.Size = UDim2.new(1, 0, 1, 0); l.ZIndex = 903
		b.MouseEnter:Connect(function() Tween(l, { TextColor3 = accent and Library.Theme.Accent or Library.Theme.Font }, 0.1) end)
		b.MouseLeave:Connect(function() Tween(l, { TextColor3 = accent and Library.Theme.Accent or Library.Theme.FontDim }, 0.1) end)
		b.MouseButton1Click:Connect(function() close() task.defer(function() if fn then pcall(fn) end end) end)
		return b
	end
	mk("cancel", 0, false, onNo)
	mk("unload", 0.5, true, onYes)
	local mid = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(1, 36), Position = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 903, Parent = box })
	self:AddToRegistry(mid, { BackgroundColor3 = "Outline" })
	veil.MouseButton1Click:Connect(close)
	box.Active = true
	return veil
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local window = { Tabs = {}, ActiveTab = nil }
	local size = cfg.Size or UDim2.fromOffset(720, 500)
	if Library.IsMobile then
		local vp = ScreenGui.AbsoluteSize
		size = UDim2.fromOffset(math.min(size.X.Offset, vp.X - 16), math.min(size.Y.Offset, vp.Y - 16))
	end

	local main = Create("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Size = size, Position = UDim2.new(0.5, 0, 0.5, 0), ClipsDescendants = true, ZIndex = 10, Parent = ScreenGui })
	self:AddToRegistry(main, { BackgroundColor3 = "Background" })
	Corner(main, 20)
	local edge = Create("UIStroke", { Thickness = 1, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main })
	self:AddToRegistry(edge, { Color = "Outline" })
	do
		local flow = Create("UIStroke", { Thickness = 1.5, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = main })
		self:AddToRegistry(flow, { Color = "Accent" })
		local g = Create("UIGradient", { Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1) }), Parent = flow })
		task.spawn(function()
			while not Library.Unloaded and g.Parent do
				g.Rotation = (g.Rotation + 1.4) % 360
				task.wait(0.03)
			end
		end)
	end
	window.Frame = main

	-- one soft ember glow low in the window; unrotated so the rounded clip holds it
	local ember = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1.2, 0, 0.55, 0), Position = UDim2.new(0.5, 0, 1, 40), BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 10, Parent = main })
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ember })
	self:AddToRegistry(ember, { BackgroundColor3 = "Accent" })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.55), NumberSequenceKeypoint.new(1, 0.15) }), Parent = ember })
	task.spawn(function()
		local t = 0
		while not Library.Unloaded and ember.Parent do
			t = t + task.wait(0.05)
			ember.BackgroundTransparency = 0.93 + 0.02 * math.sin(t * 0.7)
			ember.Position = UDim2.new(0.5 + 0.03 * math.sin(t * 0.25), 0, 1, 40)
		end
	end)

	-- ------------------------------------------------------------ rail (the original look, 5 tabs visible, little arrows)
	local RAIL, HEAD, FOOT = 150, 58, 28
	local TAB_H, TAB_PAD, VISIBLE_TABS = 32, 2, 5
	local LIST_H = TAB_H * VISIBLE_TABS + TAB_PAD * (VISIBLE_TABS - 1)
	local rail = Create("Frame", { Name = "Rail", Size = UDim2.new(0, RAIL, 1, 0), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 11, Parent = main })
	self:AddToRegistry(rail, { BackgroundColor3 = "Main" })
	Corner(rail, 20)
	local railPatch = Create("Frame", { Size = UDim2.new(0, 20, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 11, Parent = rail })
	self:AddToRegistry(railPatch, { BackgroundColor3 = "Main" })
	local railLine = Create("Frame", { Size = UDim2.new(0, 1, 1, -40), Position = UDim2.new(1, -1, 0, 20), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 12, Parent = rail })
	self:AddToRegistry(railLine, { BackgroundColor3 = "Outline" })
	do
		local spaced = {}
		for c in string.gmatch(string.upper(cfg.Title or "dexori"), ".") do spaced[#spaced + 1] = c end
		local brand = Create("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(300, 14), Position = UDim2.new(0, 12, 0.5, 10), Rotation = -90, BackgroundTransparency = 1, Text = table.concat(spaced, "   "), TextSize = 10, FontFace = Library.FontFaceBold, TextTransparency = 0.78, ZIndex = 12, Parent = rail })
		self:AddToRegistry(brand, { TextColor3 = "Accent" })
	end
	local plate = Create("Frame", { Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, 26, 0, 16), BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 12, Parent = rail })
	Corner(plate, 11)
	local halo = Create("UIStroke", { Thickness = 1, Transparency = 0.55, Parent = plate })
	self:AddToRegistry(halo, { Color = "Accent" })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.9) }), Parent = halo })
	Create("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(22, 22), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Image = cfg.Icon and ("rbxassetid://" .. tostring(cfg.Icon)) or Library.Icon, ZIndex = 13, Parent = plate })
	local brandName = Text(rail, string.lower(cfg.Title or "dexori"), 13, true); brandName.Position = UDim2.new(0, 70, 0, 18); brandName.Size = UDim2.new(1, -78, 0, 16); brandName.ZIndex = 13
	local brandSub = Text(rail, cfg.Subtitle or "", 10, false, "FontDim"); brandSub.Position = UDim2.new(0, 70, 0, 34); brandSub.Size = UDim2.new(1, -78, 0, 12); brandSub.ZIndex = 13

	local LIST_Y = 72
	local function arrow(y, rot)
		local b = Create("TextButton", { Size = UDim2.new(1, -36, 0, 16), Position = UDim2.new(0, 24, 0, y), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 14, Parent = rail })
		local ch = Chevron(b, 10, "FontDim"); ch.AnchorPoint = Vector2.new(0.5, 0.5); ch.Position = UDim2.new(0.5, 0, 0.5, 0); ch.Rotation = rot; ch.ZIndex = 15
		b.MouseEnter:Connect(function() if b.Active then for _, c in ipairs(ch:GetChildren()) do c.BackgroundColor3 = Library.Theme.Accent end end end)
		b.MouseLeave:Connect(function() for _, c in ipairs(ch:GetChildren()) do c.BackgroundColor3 = Library.Theme.FontDim end end)
		return b, ch
	end
	local upBtn, upCh = arrow(LIST_Y, 180)
	local tabList = Create("ScrollingFrame", { Size = UDim2.new(1, -36, 0, LIST_H), Position = UDim2.new(0, 24, 0, LIST_Y + 18), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ElasticBehavior = Enum.ElasticBehavior.Never, ClipsDescendants = true, ZIndex = 12, Parent = rail })
	local railList = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 12, Parent = tabList })
	Create("UIListLayout", { Padding = UDim.new(0, TAB_PAD), SortOrder = Enum.SortOrder.LayoutOrder, Parent = railList })
	local downBtn, downCh = arrow(LIST_Y + 18 + LIST_H + 2, 0)
	local tabPanel
	do
		local top = LIST_Y - 8
		local height = (LIST_Y + 18 + LIST_H + 2 + 16 + 8) - top
		local panel = Create("Frame", { Size = UDim2.new(1, -32, 0, height), Position = UDim2.new(0, 20, 0, top), BackgroundTransparency = 1, ZIndex = 11, Parent = rail })
		tabPanel = panel
		Corner(panel, 12)
		local base = Create("UIStroke", { Thickness = 1, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panel })
		self:AddToRegistry(base, { Color = "Outline" })
		local function glowStroke(thick, transp)
			local st = Create("UIStroke", { Thickness = thick, Transparency = transp, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panel })
			self:AddToRegistry(st, { Color = "Accent" })
			return Create("UIGradient", { Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.36, 1),
				NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.64, 1),
				NumberSequenceKeypoint.new(1, 1) }), Parent = st })
		end
		local core = glowStroke(1.5, 0)
		local haze = glowStroke(4, 0.72)
		task.spawn(function()
			local rot = 0
			while not Library.Unloaded and core.Parent do
				local dt = task.wait(0.03)
				rot = (rot + 55 * (dt or 0.03)) % 360
				core.Rotation, haze.Rotation = rot, rot
			end
		end)
	end
	local function maxScroll() return math.max(0, tabList.AbsoluteCanvasSize.Y - tabList.AbsoluteSize.Y) end
	local function refreshArrows()
		local y, my = tabList.CanvasPosition.Y, maxScroll()
		local canU, canD = y > 1, y < my - 1
		for _, c in ipairs(upCh:GetChildren()) do c.BackgroundTransparency = canU and 0 or 0.8 end
		for _, c in ipairs(downCh:GetChildren()) do c.BackgroundTransparency = canD and 0 or 0.8 end
		upBtn.Active, downBtn.Active = canU, canD
		local total = #window.Tabs
		local many = total > VISIBLE_TABS
		upBtn.Visible, downBtn.Visible = many, many
		local rows = math.clamp(total, 1, VISIBLE_TABS)
		local listH = rows * TAB_H + (rows - 1) * TAB_PAD
		local listTop = many and (LIST_Y + 18) or LIST_Y
		tabList.Size = UDim2.new(1, -36, 0, listH)
		tabList.Position = UDim2.new(0, 24, 0, listTop)
		downBtn.Position = UDim2.new(0, 24, 0, listTop + listH + 2)
		if tabPanel then
			local bottom = many and (listTop + listH + 2 + 16 + 8) or (listTop + listH + 8)
			tabPanel.Size = UDim2.new(1, -32, 0, bottom - (LIST_Y - 8))
		end
	end
	local function scrollTo(y)
		y = math.clamp(y, 0, maxScroll())
		Tween(tabList, { CanvasPosition = Vector2.new(0, y) }, 0.22, Enum.EasingStyle.Quint)
		task.delay(0.24, refreshArrows)
	end
	local function step(dir)
		local unit = TAB_H + TAB_PAD
		local cur = math.floor(tabList.CanvasPosition.Y / unit + 0.5)
		scrollTo((cur + dir) * unit)
	end
	upBtn.MouseButton1Click:Connect(function() step(-1) end)
	downBtn.MouseButton1Click:Connect(function() step(1) end)
	tabList:GetPropertyChangedSignal("CanvasPosition"):Connect(refreshArrows)
	tabList:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(refreshArrows)
	local function reveal(btn)
		local y0 = btn.AbsolutePosition.Y - tabList.AbsolutePosition.Y + tabList.CanvasPosition.Y
		local cy, vh = tabList.CanvasPosition.Y, tabList.AbsoluteSize.Y
		if y0 < cy then scrollTo(y0) elseif y0 + btn.AbsoluteSize.Y > cy + vh then scrollTo(y0 + btn.AbsoluteSize.Y - vh) end
	end

	-- rebindable menu key chip
	local hintBtn = Create("TextButton", { AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1, -36, 0, 26), Position = UDim2.new(0, 24, 1, -14), Text = "", AutoButtonColor = false, Active = true, ZIndex = 30, Parent = rail })
	Corner(hintBtn, 8); self:AddToRegistry(hintBtn, { BackgroundColor3 = "Element" }); Stroke(hintBtn, "Outline")
	local hint = Text(hintBtn, "", 10, true, "FontDim"); hint.TextXAlignment = Enum.TextXAlignment.Center; hint.Size = UDim2.new(1, 0, 1, 0); hint.ZIndex = 31
	local rebinding = false
	local function keyShort(k)
		local n = tostring(k and k.Name or "None")
		return (n:gsub("^Right", "R"):gsub("^Left", "L"):gsub("Control", "Ctrl"):gsub("Shift", "Shft"))
	end
	Library.ToggleKeybind = cfg.ToggleKeybind or Library.ToggleKeybind
	hint.Text = "menu  " .. keyShort(Library.ToggleKeybind)
	local menuKey = { Type = "KeyPicker", Idx = "MenuKeybind", Mode = "Toggle", Value = Library.ToggleKeybind }
	function menuKey:SetValue(v)
		if type(v) == "table" and typeof(v) ~= "EnumItem" then v = v[1] end
		if typeof(v) == "string" then
			local ok, k = pcall(function() return Enum.KeyCode[v] end)
			if not (ok and k) then return end
			v = k
		end
		if typeof(v) ~= "EnumItem" then return end
		Library.ToggleKeybind = v
		self.Value = v
		hint.Text = "menu  " .. keyShort(v)
	end
	function menuKey:OnChanged() end
	Library.Options.MenuKeybind = menuKey
	hintBtn.MouseButton1Click:Connect(function() rebinding = true hint.Text = "press a key" hint.TextColor3 = Library.Theme.Accent end)
	self:GiveSignal(UserInputService.InputBegan:Connect(function(inp)
		if rebinding and inp.UserInputType == Enum.UserInputType.Keyboard then
			rebinding = false
			if inp.KeyCode ~= Enum.KeyCode.Escape then Library.ToggleKeybind = inp.KeyCode end
			menuKey.Value = Library.ToggleKeybind
			hint.Text = "menu  " .. keyShort(Library.ToggleKeybind)
			hint.TextColor3 = Library.Theme.FontDim
		end
	end))

	-- ------------------------------------------------------------ header
	local head = Create("Frame", { Size = UDim2.new(1, -RAIL, 0, HEAD), Position = UDim2.new(0, RAIL, 0, 0), BackgroundTransparency = 1, ZIndex = 12, Parent = main })
	Draggable(head, main)
	local pageTitle = Text(head, "", 17, true); pageTitle.Position = UDim2.new(0, 20, 0, 18); pageTitle.Size = UDim2.new(0.5, -20, 0, 22); pageTitle.ZIndex = 13
	local baseLine = Create("Frame", { Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, HEAD - 1), BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 12, Parent = head })
	self:AddToRegistry(baseLine, { BackgroundColor3 = "Outline" })

	-- close
	local closeBtn = Create("TextButton", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -46, 0, 16), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 14, Parent = head })
	Corner(closeBtn, 9)
	do
		local a = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 1.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = 45, BorderSizePixel = 0, ZIndex = 15, Parent = closeBtn })
		local b = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 1.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = -45, BorderSizePixel = 0, ZIndex = 15, Parent = closeBtn })
		self:AddToRegistry(a, { BackgroundColor3 = "FontDim" }); self:AddToRegistry(b, { BackgroundColor3 = "FontDim" })
		closeBtn.MouseEnter:Connect(function() Tween(closeBtn, { BackgroundTransparency = 0 }, 0.12) closeBtn.BackgroundColor3 = Library.Theme.Element Tween(a, { BackgroundColor3 = Library.Theme.Risky }, 0.12) Tween(b, { BackgroundColor3 = Library.Theme.Risky }, 0.12) end)
		closeBtn.MouseLeave:Connect(function() Tween(closeBtn, { BackgroundTransparency = 1 }, 0.12) Tween(a, { BackgroundColor3 = Library.Theme.FontDim }, 0.12) Tween(b, { BackgroundColor3 = Library.Theme.FontDim }, 0.12) end)
	end
	closeBtn.MouseButton1Click:Connect(function() Library:Confirm("unload " .. (cfg.Title or "the menu") .. "?", "this closes the menu for this session. you'll need to run the script again.", function() Library:Unload() end) end)

	-- search
	local searchBox = Create("Frame", { Size = UDim2.new(0, 180, 0, 28), Position = UDim2.new(1, -240, 0, 15), BackgroundTransparency = 1, ZIndex = 13, Parent = head })
	Corner(searchBox, 10)
	local searchEdge = Stroke(searchBox, "Outline")
	local sIcon = SearchIcon(searchBox, 13, "FontDim"); sIcon.Position = UDim2.new(0, 11, 0.5, -7); sIcon.ZIndex = 14
	local searchIn = Create("TextBox", { Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "search", TextSize = 12, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 14, Parent = searchBox })
	self:AddToRegistry(searchIn, { TextColor3 = "Font", PlaceholderColor3 = "FontDim" })
	local results = Create("Frame", { Size = UDim2.new(0, 250, 0, 0), Visible = false, ZIndex = 200, Parent = PopupLayer })
	self:AddToRegistry(results, { BackgroundColor3 = "Main" }); Corner(results, 12); Stroke(results, "Outline"); Shadow(results, 10)
	local resultsBody = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 201, Parent = results })
	Pad(resultsBody, 6, 6, 6, 6)
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = resultsBody })
	local function runSearch(q)
		for _, c in ipairs(resultsBody:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		q = string.lower(tostring(q or ""))
		if q == "" then results.Visible = false return end
		results.Position = UDim2.fromOffset(searchBox.AbsolutePosition.X - 30, searchBox.AbsolutePosition.Y + searchBox.AbsoluteSize.Y + 6)
		RaisePopup(results)
		local n = 0
		for _, e in ipairs(Library.SearchIndex) do
			local nm2, pt2 = string.lower(tostring(e.name or "")), string.lower(tostring(e.path or ""))
			if string.find(nm2, q, 1, true) or string.find(pt2, q, 1, true) then
				n = n + 1
				if n > 7 then break end
				local b = Create("TextButton", { Size = UDim2.new(1, 0, 0, 34), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, LayoutOrder = n, ZIndex = 202, Parent = resultsBody })
				Corner(b, 8); Library:AddToRegistry(b, { BackgroundColor3 = "Element" })
				local nm = Text(b, e.name, 12, true); nm.Position = UDim2.new(0, 10, 0, 4); nm.Size = UDim2.new(1, -20, 0, 14); nm.ZIndex = 203
				local pt = Text(b, e.path, 10, false, "FontDim"); pt.Position = UDim2.new(0, 10, 0, 18); pt.Size = UDim2.new(1, -20, 0, 12); pt.ZIndex = 203
				b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
				b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
				b.MouseButton1Click:Connect(function() pcall(e.focus) searchIn.Text = "" results.Visible = false end)
			end
		end
		results.Size = UDim2.new(0, 250, 0, n > 0 and (n * 37 + 9) or 0)
		results.Visible = n > 0
	end
	searchIn:GetPropertyChangedSignal("Text"):Connect(function() runSearch(searchIn.Text) end)
	searchIn.Focused:Connect(function() searchEdge.Color = Library.Theme.Accent Library.Registry[searchEdge] = { Color = "Accent" } end)
	searchIn.FocusLost:Connect(function()
		searchEdge.Color = Library.Theme.Outline
		Library.Registry[searchEdge] = { Color = "Outline" }
		task.delay(0.25, function() if searchIn.Text == "" then results.Visible = false end end)
	end)

	-- ------------------------------------------------------------ body + footer
	local body = Create("Frame", { Size = UDim2.new(1, -RAIL, 1, -(HEAD + FOOT + 6)), Position = UDim2.new(0, RAIL, 0, HEAD + 6), BackgroundTransparency = 1, ZIndex = 11, Parent = main })
	local footer = Create("Frame", { Size = UDim2.new(1, -RAIL, 0, FOOT), Position = UDim2.new(0, RAIL, 1, -FOOT), BackgroundTransparency = 1, ZIndex = 12, Parent = main })
	local footL = Text(footer, cfg.Footer or "", 10, false, "FontDim"); footL.Position = UDim2.new(0, 20, 0, -2); footL.Size = UDim2.new(0.45, -20, 1, 0); footL.ZIndex = 13
	-- live readout with a tiny fps sparkline
	local spark = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(52, 12), Position = UDim2.new(1, -24, 0.5, -2), BackgroundTransparency = 1, ZIndex = 13, Parent = footer })
	local bars = {}
	for i = 1, 13 do
		local b = Create("Frame", { AnchorPoint = Vector2.new(0, 1), Size = UDim2.fromOffset(2, 2), Position = UDim2.new(0, (i - 1) * 4, 1, 0), BorderSizePixel = 0, ZIndex = 14, Parent = spark })
		Corner(b, 1); self:AddToRegistry(b, { BackgroundColor3 = "Accent" })
		bars[i] = b
	end
	local footR = Text(footer, "", 10, false, "FontDim"); footR.TextXAlignment = Enum.TextXAlignment.Right; footR.Position = UDim2.new(1, -294, 0, -2); footR.Size = UDim2.new(0, 210, 1, 0); footR.ZIndex = 13
	task.spawn(function()
		local frames, acc, fps = 0, 0, 0
		local hist = {}
		Library:GiveSignal(RunService.RenderStepped:Connect(function(dt) frames = frames + 1 acc = acc + dt if acc >= 1 then fps = frames frames = 0 acc = 0 end end))
		while not Library.Unloaded do
			local ping = ""
			pcall(function() ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValueString():match("^(%d+)") or "" end)
			footR.Text = string.format("%s     %d fps     %s ms", tostring(LocalPlayer.DisplayName), fps, ping)
			table.insert(hist, fps)
			if #hist > 13 then table.remove(hist, 1) end
			local mx = 1
			for _, v in ipairs(hist) do if v > mx then mx = v end end
			for i, b in ipairs(bars) do
				local v = hist[i]
				local h = v and math.max(2, math.floor((v / mx) * 12)) or 2
				Tween(b, { Size = UDim2.fromOffset(2, h) }, 0.3)
			end
			task.wait(1)
		end
	end)

	-- ------------------------------------------------------------ visibility
	local visible = cfg.AutoShow ~= false
	local winScale = Create("UIScale", { Scale = 1, Parent = main })
	local function show(on)
		visible = on
		Library:_SetBackdrop(on)
		if on then
			main.Visible = true
			winScale.Scale = 0.96
			Tween(winScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Quint)
		else
			Library:_ClosePopups()
			Tween(winScale, { Scale = 0.96 }, 0.14, Enum.EasingStyle.Quint).Completed:Connect(function()
				if not visible then main.Visible = false winScale.Scale = 1 end
			end)
		end
	end
	function window:SetVisible(on) show(on) end
	function window:Toggle() show(not visible) end
	function window:IsVisible() return visible end
	self:GiveSignal(UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe or rebinding then return end
		if inp.KeyCode == Library.ToggleKeybind then show(not visible) end
	end))
	if Library.IsMobile then
		local mob = Create("TextButton", { Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 14, 0.5, -23), Text = "", AutoButtonColor = false, ZIndex = 40, Parent = ScreenGui })
		self:AddToRegistry(mob, { BackgroundColor3 = "Main" }); Corner(mob, 14); Stroke(mob, "Outline")
		Create("ImageLabel", { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(0.5, -13, 0.5, -13), BackgroundTransparency = 1, Image = Library.Icon, ZIndex = 41, Parent = mob })
		mob.MouseButton1Click:Connect(function() show(not visible) end)
		Draggable(mob, mob)
	end

	-- ------------------------------------------------------------ tabs
	local order = 0
	local function columns(parent, top)
		-- the well: a slightly lifted panel the cards sit inside, with even gutters
		local well = Create("Frame", { Name = "Well", Size = UDim2.new(1, -40, 1, -(top + 8)), Position = UDim2.new(0, 20, 0, top), BackgroundTransparency = 1, ZIndex = 11, ClipsDescendants = true, Parent = parent })
		local scroller = Create("ScrollingFrame", { Name = "Scroll", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageTransparency = 0.75, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollingEnabled = true, Active = true, ClipsDescendants = true, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 12, Parent = well })
		Library:AddToRegistry(scroller, { ScrollBarImageColor3 = "FontDim" })
		local GUT = 12
		local inner = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 2), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 12, Parent = scroller })
		Pad(inner, 0, 0, 0, GUT)
		local function col(xs, xo)
			local c = Create("Frame", { Size = UDim2.new(0.5, -(GUT / 2)), Position = UDim2.new(xs, xo, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 12, Parent = inner })
			Create("UIListLayout", { Padding = UDim.new(0, GUT), SortOrder = Enum.SortOrder.LayoutOrder, Parent = c })
			return c
		end
		local l, r = col(0, 0), col(0.5, GUT / 2)
		return l, r, well
	end

	function window:AddTab(name, icon)
		order = order + 1
		local tab = { Name = name, Subtabs = {} }
		local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, TAB_H), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 14, Parent = railList })
		Corner(btn, 9)
		local glyph
		local useIcon = cfg.UseIcons == true and icon ~= nil
		if useIcon then
			if type(icon) == "number" or (type(icon) == "string" and string.sub(icon, 1, 3) == "rbx") then
				glyph = Create("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 10, 0.5, 0), BackgroundTransparency = 1, Image = (type(icon) == "number") and ("rbxassetid://" .. icon) or tostring(icon), ZIndex = 15, Parent = btn })
				Library:AddToRegistry(glyph, { ImageColor3 = "FontDim" })
			else
				glyph = Icon(btn, icon, 16, "FontDim")
				glyph.AnchorPoint = Vector2.new(0, 0.5)
				glyph.Position = UDim2.new(0, 10, 0.5, 0)
				glyph.ZIndex = 15
			end
		end
		local lbl = Text(btn, name, 12, true, "FontDim")
		lbl.AnchorPoint = Vector2.new(0, 0.5); lbl.Position = UDim2.new(0, useIcon and 34 or 12, 0.5, 0); lbl.Size = UDim2.new(1, -(useIcon and 40 or 16), 0, 16); lbl.ZIndex = 15
		local idx = Text(btn, string.format("%02d", order), 9, true, "FontDim")
		idx.AnchorPoint = Vector2.new(1, 0.5); idx.TextXAlignment = Enum.TextXAlignment.Right
		idx.Position = UDim2.new(1, -10, 0.5, 0); idx.Size = UDim2.new(0, 20, 0, 12); idx.TextTransparency = 0.5; idx.ZIndex = 15
		Press(btn, 0.97)
		btn.MouseEnter:Connect(function() if window.ActiveTab ~= tab then Tween(lbl, { TextColor3 = Library.Theme.Font }, 0.1) end end)
		btn.MouseLeave:Connect(function() if window.ActiveTab ~= tab then Tween(lbl, { TextColor3 = Library.Theme.FontDim }, 0.1) end end)
		tab._btn, tab._glyph, tab._label, tab._idx = btn, glyph, lbl, idx
		task.defer(refreshArrows)

		local page = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 11, Parent = body })
		tab.Page = page
		local subRow = Create("Frame", { Size = UDim2.new(1, -56, 0, 30), Position = UDim2.new(0, 28, 0, 8), BackgroundTransparency = 1, Visible = false, ZIndex = 12, Parent = page })
		Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = subRow })
		local l, r, well = columns(page, 12)
		tab.Left, tab.Right, tab._cols, tab._scroller = l, r, { l, r }, well

		local function relayout()
			local top = subRow.Visible and 46 or 12
			local all = { tab._scroller }
			for _, st in ipairs(tab.Subtabs) do all[#all + 1] = st._scroller end
			for _, s in ipairs(all) do
				s.Position = UDim2.new(0, 20, 0, top)
				s.Size = UDim2.new(1, -40, 1, -(top + 8))
			end
		end

		function tab:Select()
			for _, t in ipairs(window.Tabs) do
				t.Page.Visible = false
				Tween(t._label, { TextColor3 = Library.Theme.FontDim }, 0.12)
				if t._idx then Tween(t._idx, { TextColor3 = Library.Theme.FontDim, TextTransparency = 0.5 }, 0.12) end
				if t._glyph then
					if t._glyph:IsA("ImageLabel") then Tween(t._glyph, { ImageColor3 = Library.Theme.FontDim }, 0.12) else SetIconKey(t._glyph, "FontDim") end
				end
			end
			self.Page.Visible = true
			do
				local pageScale = self.Page:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = self.Page })
				pageScale.Scale = 0.985
				Tween(pageScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Quint)
			end
			Tween(self._label, { TextColor3 = Library.Theme.Font }, 0.12)
			if self._idx then Tween(self._idx, { TextColor3 = Library.Theme.Accent, TextTransparency = 0 }, 0.12) end
			if self._glyph then
				if self._glyph:IsA("ImageLabel") then Tween(self._glyph, { ImageColor3 = Library.Theme.Accent }, 0.12) else SetIconKey(self._glyph, "Accent") end
			end
			pageTitle.Text = name
			window.ActiveTab = self
			task.defer(function() reveal(self._btn) end)
			local i = 0
			for _, c in ipairs(self._cols) do
				for _, card in ipairs(c:GetChildren()) do
					if card:IsA("Frame") then
						i = i + 1
						local sc = card:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = card })
						sc.Scale = 0.97
						card.BackgroundTransparency = 1
						local delay = 0.025 * math.min(i, 8)
						task.delay(delay, function()
							Tween(sc, { Scale = 1 }, 0.26, Enum.EasingStyle.Back)
							Tween(card, { BackgroundTransparency = card:GetAttribute("BaseAlpha") or 0 }, 0.2)
						end)
					end
				end
			end
		end
		btn.MouseButton1Click:Connect(function() tab:Select() end)

		function tab:AddSubTab(subName)
			local st = { Name = subName }
			local sb = Create("TextButton", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, LayoutOrder = #tab.Subtabs + 1, ZIndex = 13, Parent = subRow })
			Corner(sb, 9); Pad(sb, 14, 14, 0, 0); Library:AddToRegistry(sb, { BackgroundColor3 = "Element" })
			local sl = Text(sb, subName, 11, true, "FontDim"); sl.AutomaticSize = Enum.AutomaticSize.X; sl.Size = UDim2.new(0, 0, 1, 0); sl.ZIndex = 14
			local sub = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 11, Parent = page })
			local sl2, sr2, sc2 = columns(sub, 46)
			st.Page, st.Left, st.Right, st._scroller, st._btn, st._label = sub, sl2, sr2, sc2, sb, sl
			function st:Select()
				tab._scroller.Visible = false
				for _, o in ipairs(tab.Subtabs) do
					o.Page.Visible = false
					o._btn.BackgroundTransparency = 1
					Tween(o._label, { TextColor3 = Library.Theme.FontDim }, 0.1)
				end
				self.Page.Visible = true
				self._btn.BackgroundTransparency = 0
				Tween(self._label, { TextColor3 = Library.Theme.Font }, 0.1)
			end
			sb.MouseButton1Click:Connect(function() st:Select() end)
			st.AddLeftGroupbox = function(_, n) return window:_MakeGroupbox(sl2, n, name .. " / " .. subName, tab, st) end
			st.AddRightGroupbox = function(_, n) return window:_MakeGroupbox(sr2, n, name .. " / " .. subName, tab, st) end
			table.insert(tab.Subtabs, st)
			subRow.Visible = true
			relayout()
			if #tab.Subtabs == 1 then task.defer(function() st:Select() end) end
			return st
		end

		tab.AddLeftGroupbox = function(_, n) return window:_MakeGroupbox(l, n, name, tab) end
		tab.AddRightGroupbox = function(_, n) return window:_MakeGroupbox(r, n, name, tab) end
		table.insert(window.Tabs, tab)
		if #window.Tabs == 1 then task.defer(function() tab:Select() end) end
		return tab
	end

	-- ------------------------------------------------------------ cards
	local gbOrder = 0
	function window:_MakeGroupbox(column, name, path, tabRef, subRef)
		gbOrder = gbOrder + 1
		local gb = { Name = name, Path = path .. " / " .. name }
		local card = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.35, LayoutOrder = gbOrder, ZIndex = 12, Parent = column })
		card:SetAttribute("BaseAlpha", 0.35)
		Library:AddToRegistry(card, { BackgroundColor3 = "Main" }); Corner(card, 12)
		local cs = Create("UIStroke", { Thickness = 1, Transparency = 0.25, Parent = card })
		Library:AddToRegistry(cs, { Color = "Outline" })
		-- light-catching top edge
		local lightEdge = Create("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = card })
		Library:AddToRegistry(lightEdge, { Color = "Accent" })
		Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.18, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = lightEdge })
		local head2 = Create("TextButton", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 13, Parent = card })
		local t = Text(head2, name, 12, true); t.Position = UDim2.new(0, 14, 0, 0); t.Size = UDim2.new(1, -56, 1, 0); t.ZIndex = 14
		local chev = Chevron(head2, 12, "FontDim"); chev.AnchorPoint = Vector2.new(0.5, 0.5); chev.Position = UDim2.new(1, -18, 0.5, 0); chev.ZIndex = 14; chev.Rotation = 180
		local rule = Create("Frame", { Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 33), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 13, Parent = card })
		Library:AddToRegistry(rule, { BackgroundColor3 = "Outline" })
		local holder = Create("Frame", { Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0, 14, 0, 38), BackgroundTransparency = 1, ZIndex = 13, Parent = card })
		Pad(holder, 0, 0, 0, 10)
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
		local collapsed = false
		head2.MouseButton1Click:Connect(function()
			collapsed = not collapsed
			holder.Visible = not collapsed
			rule.Visible = not collapsed
			card.AutomaticSize = collapsed and Enum.AutomaticSize.None or Enum.AutomaticSize.Y
			if collapsed then card.Size = UDim2.new(1, 0, 0, 34) end
			Tween(chev, { Rotation = collapsed and 0 or 180 }, 0.18)
		end)
		head2.MouseEnter:Connect(function() Tween(t, { TextColor3 = Library.Theme.Accent }, 0.12) end)
		head2.MouseLeave:Connect(function() Tween(t, { TextColor3 = Library.Theme.Font }, 0.12) end)
		gb.Frame, gb.Holder, gb._order = card, holder, 0
		function gb:_next() self._order = self._order + 1 return self._order end
		function gb:_focus(el)
			if tabRef then tabRef:Select() end
			if subRef then subRef:Select() end
			show(true)
			if el then local s = Stroke(el, "Accent", 1) task.delay(1.5, function() Library:RemoveFromRegistry(s) s:Destroy() end) end
		end
		setmetatable(gb, { __index = Library.GroupboxMethods })
		return gb
	end

	-- resize grip
	do
		local grip = Create("TextButton", { AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -6, 1, -6), Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 25, Parent = main })
		for i = 1, 3 do
			local d = Create("Frame", { AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(2, 2), Position = UDim2.new(1, -2 - (i - 1) * 5, 1, -2), BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 26, Parent = grip })
			self:AddToRegistry(d, { BackgroundColor3 = "FontDim" })
			local e2 = Create("Frame", { AnchorPoint = Vector2.new(1, 1), Size = UDim2.fromOffset(2, 2), Position = UDim2.new(1, -2, 1, -2 - (i - 1) * 5), BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 26, Parent = grip })
			self:AddToRegistry(e2, { BackgroundColor3 = "FontDim" })
		end
		local resizing, startPos, startSize = false, nil, nil
		grip.InputBegan:Connect(function(inp) if IsPressed(inp) then resizing = true startPos = inp.Position startSize = main.AbsoluteSize end end)
		self:GiveSignal(UserInputService.InputChanged:Connect(function(inp)
			if resizing and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
				local d = inp.Position - startPos
				local w = math.clamp(startSize.X + d.X, 560, ScreenGui.AbsoluteSize.X - 20)
				local h = math.clamp(startSize.Y + d.Y, 380, ScreenGui.AbsoluteSize.Y - 20)
				size = UDim2.fromOffset(math.floor(w), math.floor(h))
				main.Size = size
			end
		end))
		self:GiveSignal(UserInputService.InputEnded:Connect(function(inp) if IsPressed(inp) then resizing = false end end))
	end

	task.defer(function() show(visible) end)
	table.insert(self.Windows, window)
	return window
end


local GroupboxMethods = {}
Library.GroupboxMethods = GroupboxMethods

local ROW_H, LINE_H, CTRL_H = 28, 16, 30

-- tooltip: appears above the cursor after a short hover, styled like a popup
local TipFrame = Create("Frame", { Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, Visible = false, ZIndex = 900, Parent = PopupLayer })
Library:AddToRegistry(TipFrame, { BackgroundColor3 = "Main" }); Corner(TipFrame, 7)
local tipStroke = Create("UIStroke", { Thickness = 1, Transparency = 0.2, Parent = TipFrame }); Library:AddToRegistry(tipStroke, { Color = "Outline" })
Pad(TipFrame, 9, 9, 0, 0)
local TipText = Text(TipFrame, "", 11, false); TipText.AutomaticSize = Enum.AutomaticSize.X; TipText.Size = UDim2.new(0, 0, 1, 0); TipText.ZIndex = 901
local tipToken = 0
local function AttachTooltip(frame, text)
	if not text or text == "" then return end
	frame.MouseEnter:Connect(function()
		tipToken = tipToken + 1
		local my = tipToken
		task.delay(0.45, function()
			if my ~= tipToken then return end
			TipText.Text = text
			local pos = UserInputService:GetMouseLocation()
			TipFrame.Position = UDim2.fromOffset(pos.X + 12, pos.Y - 34)
			TipFrame.Visible = true
			RaisePopup(TipFrame)
		end)
	end)
	frame.MouseLeave:Connect(function() tipToken = tipToken + 1 TipFrame.Visible = false end)
end
Library.AttachTooltip = AttachTooltip

local function Badge(parent, text)
	local b = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 6, Parent = parent })
	Library:AddToRegistry(b, { BackgroundColor3 = "Accent" }); Corner(b, 4); Pad(b, 5, 5, 0, 0)
	local t = Text(b, string.lower(text), 9, true); t.TextColor3 = Color3.new(1, 1, 1); t.AutomaticSize = Enum.AutomaticSize.X; t.Size = UDim2.new(0, 0, 1, 0); t.ZIndex = 7
	Library:RemoveFromRegistry(t)
	return b
end

local function row(gb, h, plain)
	local f = Create("Frame", { Size = UDim2.new(1, 0, 0, h or ROW_H), BackgroundTransparency = 1, LayoutOrder = gb:_next(), ZIndex = 4, Parent = gb.Holder })
	if not plain then
		local hover = Create("Frame", { Name = "_hover", Size = UDim2.new(1, 16, 1, 6), Position = UDim2.new(0, -8, 0, -3), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3, Parent = f })
		Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = hover })
		f.MouseEnter:Connect(function() Tween(hover, { BackgroundTransparency = 0.965 }, 0.12) end)
		f.MouseLeave:Connect(function() Tween(hover, { BackgroundTransparency = 1 }, 0.16) end)
	end
	return f
end
local function reg(gb, name, frame, obj) Library:RegisterSearch(name, gb.Path, function() gb:_focus(frame) end, obj) end

local function slotHolder(frame)
	local h = frame:FindFirstChild("_slots")
	if h then return h end
	h = Create("Frame", { Name = "_slots", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 6, Parent = frame })
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = h })
	return h
end
local function bindLabelWidth(label, frame, leftInset)
	local h = frame:FindFirstChild("_slots")
	local function fit()
		local w = h and h.AbsoluteSize.X or 0
		label.Size = UDim2.new(1, -(leftInset + (w > 0 and (w + 10) or 0)), 0, label.Size.Y.Offset)
	end
	if h then h:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit) end
	fit()
	return fit
end

local function lineLabel(parent, text, dim)
	local l = Text(parent, text, 12, false, dim and "FontDim" or "Font")
	l.AnchorPoint = Vector2.new(0, 0.5)
	l.Position = UDim2.new(0, 0, 0, LINE_H / 2)
	l.Size = UDim2.new(1, 0, 0, LINE_H)
	l.ZIndex = 5
	return l
end

function GroupboxMethods:AddLabel(text, wrap)
	local f = row(self, LINE_H, true)
	local l = Text(f, text, 12, false, "FontDim")
	l.AnchorPoint = Vector2.new(0, 0.5); l.Position = UDim2.new(0, 0, 0.5, 0); l.Size = UDim2.new(1, 0, 0, LINE_H); l.ZIndex = 5
	if wrap then
		l.TextWrapped = true; l.TextTruncate = Enum.TextTruncate.None
		l.AnchorPoint = Vector2.new(0, 0); l.Position = UDim2.new(0, 0, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y; f.AutomaticSize = Enum.AutomaticSize.Y
	end
	local obj = { Frame = f, TextLabel = l }
	function obj:SetText(t) l.Text = t end
	function obj:AddKeyPicker(idx, cfg) local k = Library._AttachKeyPicker(self, f, idx, cfg) bindLabelWidth(l, f, 0) return k end
	function obj:AddColorPicker(idx, cfg) local c = Library._AttachColorPicker(self, f, idx, cfg) bindLabelWidth(l, f, 0) return c end
	return obj
end

function GroupboxMethods:AddDivider(label)
	if not label then
		local f = row(self, 9, true)
		local line = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BackgroundTransparency = 0.5, BorderSizePixel = 0, ZIndex = 5, Parent = f })
		Library:AddToRegistry(line, { BackgroundColor3 = "Outline" })
		return { Frame = f }
	end
	local f = row(self, 26, true)
	local t = Text(f, label, 10, true, "FontDim")
	t.AnchorPoint = Vector2.new(0, 1); t.Position = UDim2.new(0, 0, 1, -2); t.Size = UDim2.new(0, 0, 0, 12); t.AutomaticSize = Enum.AutomaticSize.X; t.ZIndex = 6
	local line = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(1, -(#label * 6 + 10), 0, 1), Position = UDim2.new(0, #label * 6 + 10, 1, -8), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 5, Parent = f })
	Library:AddToRegistry(line, { BackgroundColor3 = "Outline" })
	Create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = line })
	local function place()
		local w = t.TextBounds.X
		if w > 0 then
			line.Position = UDim2.new(0, w + 10, 1, -8)
			line.Size = UDim2.new(1, -(w + 10), 0, 1)
		end
	end
	t:GetPropertyChangedSignal("TextBounds"):Connect(place)
	task.defer(place)
	return { Frame = f }
end

local function makeButton(parent, cfg, width, xScale, xOffset)
	local b = Create("TextButton", { Size = UDim2.new(width, xScale or 0, 0, CTRL_H), Position = UDim2.new(xScale and 0.5 or 0, xOffset or 0, 0, 0), Text = "", AutoButtonColor = false, ClipsDescendants = true, ZIndex = 5, Parent = parent })
	Library:AddToRegistry(b, { BackgroundColor3 = "Element" }); Corner(b, 10); Stroke(b, cfg.Risky and "Risky" or "Outline")
	local sweep = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, BorderSizePixel = 0, ZIndex = 6, Parent = b })
	local sg = Create("UIGradient", { Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = sweep })
	b.MouseEnter:Connect(function()
		sg.Offset = Vector2.new(-1, 0)
		Tween(sg, { Offset = Vector2.new(1, 0) }, 0.45, Enum.EasingStyle.Quad)
	end)
	local l = Text(b, cfg.Text or "button", 12, true, cfg.Risky and "Risky" or "Font")
	l.TextXAlignment = Enum.TextXAlignment.Center; l.Size = UDim2.new(1, 0, 1, 0); l.ZIndex = 6
	Hover(b, "Element", "ElementHover"); Ripple(b); Press(b)
	return b, l
end
function GroupboxMethods:AddButton(cfg, func)
	if type(cfg) == "string" then cfg = { Text = cfg, Func = func } end
	local f = row(self, CTRL_H, true)
	local b, l = makeButton(f, cfg, 1)
	AttachTooltip(b, cfg.Tooltip)
	local obj, armed = { Frame = f, Button = b }, false
	b.MouseButton1Click:Connect(function()
		if cfg.DoubleClick then
			if armed then armed = false l.Text = cfg.Text pcall(cfg.Func)
			else armed = true l.Text = "confirm?" task.delay(1.4, function() if armed then armed = false l.Text = cfg.Text end end) end
		else pcall(cfg.Func) end
	end)
	obj.Type = "Button"
	obj.Click = function() pcall(cfg.Func) end
	function obj:SetText(t) l.Text = t end
	function obj:AddButton(cfg2, func2)
		if type(cfg2) == "string" then cfg2 = { Text = cfg2, Func = func2 } end
		b.Size = UDim2.new(0.5, -4, 0, CTRL_H)
		local b2, l2 = makeButton(f, cfg2, 0.5, -4, 4)
		b2.Position = UDim2.new(0.5, 4, 0, 0)
		b2.MouseButton1Click:Connect(function() pcall(cfg2.Func) end)
		local obj2 = { Frame = f, Button = b2, Type = "Button", Click = function() pcall(cfg2.Func) end, SetText = function(_, t) l2.Text = t end }
		reg(self, cfg2.Text or "button", f, obj2)
		return obj2
	end
	reg(self, cfg.Text or "button", f, obj)
	return obj
end

function GroupboxMethods:AddToggle(idx, cfg)
	cfg = cfg or {}
	local f = row(self, 24)
	local hit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = f })
	local sw = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(13, 13), Position = UDim2.new(0, 0, 0.5, 0), ZIndex = 5, Parent = f })
	Library:AddToRegistry(sw, { BackgroundColor3 = "Element" }); Corner(sw, 4); local bs = Stroke(sw, "Outline")
	local fill = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 6, Parent = sw })
	Corner(fill, 4); Library:AddToRegistry(fill, { BackgroundColor3 = "Accent" })
	local tick = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, ZIndex = 7, Parent = sw })
	local t1 = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(3.5, 1.6), Position = UDim2.new(0.5, -2.5, 0.5, 1.2), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 7, Parent = tick })
	local t2 = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6.5, 1.6), Position = UDim2.new(0.5, 1, 0.5, -0.4), Rotation = -45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 7, Parent = tick })
	local tickScale = Create("UIScale", { Scale = 0, Parent = tick })
	local l = Text(f, cfg.Text or idx, 12, false)
	l.AnchorPoint = Vector2.new(0, 0.5); l.Position = UDim2.new(0, 21, 0.5, 0); l.Size = UDim2.new(1, -21, 0, LINE_H); l.ZIndex = 5
	local fitLabel = function() bindLabelWidth(l, f, 21) end
	if cfg.Badge then
		local bd = Badge(f, cfg.Badge)
		task.defer(function() bd.Position = UDim2.new(0, 21 + l.TextBounds.X + 8, 0.5, 0) end)
	end
	AttachTooltip(f, cfg.Tooltip)
	local obj = { Frame = f, Value = cfg.Default and true or false, Type = "Toggle", Idx = idx, Callback = cfg.Callback, _changed = {} }
	local function render(anim)
		local on = obj.Value
		local t = anim and 0.18 or 0
		Tween(fill, { BackgroundTransparency = on and 0 or 1 }, t)
		Tween(tickScale, { Scale = on and 1 or 0 }, anim and 0.22 or 0, Enum.EasingStyle.Back)
		bs.Color = on and Library.Theme.Accent or Library.Theme.Outline
		Library.Registry[bs] = on and { Color = "Accent" } or { Color = "Outline" }
		Tween(l, { TextColor3 = on and Library.Theme.Font or Library.Theme.FontDim }, t)
		Library.Registry[l] = on and { TextColor3 = "Font" } or { TextColor3 = "FontDim" }
	end
	function obj:SetValue(v, silent)
		self.Value = v and true or false
		render(true)
		if not silent then
			if self.Callback then pcall(self.Callback, self.Value) end
			for _, fn in ipairs(self._changed) do pcall(fn, self.Value) end
		end
	end
	function obj:OnChanged(fn) table.insert(self._changed, fn) end
	function obj:SetText(t) l.Text = t end
	function obj:AddKeyPicker(kidx, kcfg) local k = Library._AttachKeyPicker(self, f, kidx, kcfg) fitLabel() return k end
	function obj:AddColorPicker(cidx, ccfg) local c = Library._AttachColorPicker(self, f, cidx, ccfg) fitLabel() return c end
	hit.MouseButton1Click:Connect(function() obj:SetValue(not obj.Value) end)
	render(false)
	if obj.Value and cfg.Callback then task.defer(function() pcall(cfg.Callback, true) end) end
	Library.Toggles[idx] = obj
	reg(self, cfg.Text or idx, f, obj)
	return obj
end

function GroupboxMethods:AddSlider(idx, cfg)
	cfg = cfg or {}
	local f = row(self, LINE_H + 16)
	local l = lineLabel(f, cfg.Text or idx, false)
	l.Size = UDim2.new(1, -80, 0, LINE_H)
	AttachTooltip(f, cfg.Tooltip)
	local chip = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(1, 0, 0, LINE_H / 2), ZIndex = 5, Parent = f })
	Library:AddToRegistry(chip, { BackgroundColor3 = "Element" }); Corner(chip, 6); Stroke(chip, "Outline"); Pad(chip, 7, 7, 0, 0)
	local val = Text(chip, "", 11, true)
	val.AnchorPoint = Vector2.new(0, 0.5); val.Position = UDim2.new(0, 0, 0.5, 0); val.AutomaticSize = Enum.AutomaticSize.X; val.Size = UDim2.new(0, 0, 0, LINE_H); val.ZIndex = 6
	local track = Create("Frame", { AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 1, -2), ZIndex = 5, Parent = f })
	Library:AddToRegistry(track, { BackgroundColor3 = "Element" }); Corner(track, 3); Stroke(track, "Outline")
	local fill = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0, ZIndex = 6, Parent = track }); Corner(fill, 3)
	Library:AddToRegistry(fill, { BackgroundColor3 = "Accent" })
	local fglow = Create("UIStroke", { Thickness = 2, Transparency = 0.75, Parent = fill })
	Library:AddToRegistry(fglow, { Color = "Accent" })
	local knob = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, ZIndex = 8, Parent = track })
	Library:AddToRegistry(knob, { BackgroundColor3 = "Font" }); Corner(knob, 5)
	local kr = Create("UIStroke", { Thickness = 2, Transparency = 0.35, Parent = knob })
	Library:AddToRegistry(kr, { Color = "Accent" })
	local hit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 14), Position = UDim2.new(0, 0, 0, -7), BackgroundTransparency = 1, Text = "", ZIndex = 9, Parent = track })
	local min, max, rounding = cfg.Min or 0, cfg.Max or 100, cfg.Rounding or 0
	local obj = { Frame = f, Value = cfg.Default or min, Type = "Slider", Idx = idx, Callback = cfg.Callback, Min = min, Max = max, _changed = {} }
	local function fmt(v) return (cfg.Prefix or "") .. string.format("%." .. rounding .. "f", v) .. (cfg.Suffix or "") end
	local function render()
		local a = math.clamp((obj.Value - min) / math.max(max - min, 1e-9), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		knob.Position = UDim2.new(a, 0, 0.5, 0)
		val.Text = fmt(obj.Value)
	end
	function obj:SetValue(v, silent)
		v = math.clamp(tonumber(v) or min, min, max)
		local m = 10 ^ rounding
		self.Value = math.floor(v * m + 0.5) / m
		render()
		if not silent then
			if self.Callback then pcall(self.Callback, self.Value) end
			for _, fn in ipairs(self._changed) do pcall(fn, self.Value) end
		end
	end
	function obj:SetMin(v) min = v self.Min = v self:SetValue(self.Value, true) end
	function obj:SetMax(v) max = v self.Max = v self:SetValue(self.Value, true) end
	function obj:OnChanged(fn) table.insert(self._changed, fn) end
	local dragging = false
	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		obj:SetValue(min + (max - min) * a)
	end
	local chipScale = Create("UIScale", { Scale = 1, Parent = chip })
	hit.InputBegan:Connect(function(inp) if IsPressed(inp) then dragging = true Tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.12, Enum.EasingStyle.Back) Tween(chipScale, { Scale = 1.12 }, 0.12, Enum.EasingStyle.Back) fromX(inp.Position.X) end end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then fromX(inp.Position.X) end
	end))
	Library:GiveSignal(UserInputService.InputEnded:Connect(function(inp)
		if IsPressed(inp) and dragging then dragging = false Tween(knob, { Size = UDim2.fromOffset(10, 10) }, 0.14) Tween(chipScale, { Scale = 1 }, 0.16) end
	end))
	render()
	Library.Options[idx] = obj
	reg(self, cfg.Text or idx, f, obj)
	return obj
end

function GroupboxMethods:AddInput(idx, cfg)
	cfg = cfg or {}
	local f = row(self, 40, true)
	local boxF = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = f })
	Library:AddToRegistry(boxF, { BackgroundColor3 = "Element" }); Corner(boxF, 10); local st = Stroke(boxF, "Outline")
	local l = Text(boxF, cfg.Text or idx, 9, true, "FontDim")
	l.Position = UDim2.new(0, 11, 0, 6); l.Size = UDim2.new(1, -22, 0, 11); l.ZIndex = 6
	local tb = Create("TextBox", { Size = UDim2.new(1, -22, 0, 16), Position = UDim2.new(0, 11, 0, 18), BackgroundTransparency = 1, Text = cfg.Default or "", PlaceholderText = cfg.Placeholder or "", TextSize = 12, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 6, Parent = boxF })
	Library:AddToRegistry(tb, { TextColor3 = "Font", PlaceholderColor3 = "FontDim" })
	local obj = { Frame = f, Value = cfg.Default or "", Type = "Input", Idx = idx, Callback = cfg.Callback, _changed = {} }
	local function fire()
		if cfg.Numeric and tb.Text ~= "" and not tonumber(tb.Text) then tb.Text = obj.Value return end
		obj.Value = tb.Text
		if obj.Callback then pcall(obj.Callback, obj.Value) end
		for _, fn in ipairs(obj._changed) do pcall(fn, obj.Value) end
	end
	tb.Focused:Connect(function() st.Color = Library.Theme.Accent Library.Registry[st] = { Color = "Accent" } end)
	tb.FocusLost:Connect(function() st.Color = Library.Theme.Outline Library.Registry[st] = { Color = "Outline" } fire() end)
	if not cfg.Finished then tb:GetPropertyChangedSignal("Text"):Connect(function() if tb:IsFocused() then fire() end end) end
	function obj:SetValue(v, silent) tb.Text = tostring(v or "") self.Value = tb.Text if not silent then fire() end end
	function obj:OnChanged(fn) table.insert(self._changed, fn) end
	Library.Options[idx] = obj
	reg(self, cfg.Text or idx, f, obj)
	return obj
end

function GroupboxMethods:AddDropdown(idx, cfg)
	cfg = cfg or {}
	local title = cfg.Text or idx
	local f = row(self, 30, true)
	local btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, ZIndex = 5, Parent = f })
	Library:AddToRegistry(btn, { BackgroundColor3 = "Element" }); Corner(btn, 8); local bstroke = Stroke(btn, "Outline"); Hover(btn, "Element", "ElementHover")
	local l = Text(btn, title, 11, false, "FontDim")
	l.Position = UDim2.new(0, 11, 0, 0); l.Size = UDim2.new(0.5, -11, 1, 0); l.ZIndex = 6
	local cur = Text(btn, "", 11, true)
	cur.AnchorPoint = Vector2.new(1, 0); cur.TextXAlignment = Enum.TextXAlignment.Right
	cur.Position = UDim2.new(1, -26, 0, 0); cur.Size = UDim2.new(0.5, -30, 1, 0); cur.ZIndex = 6
	-- count pill for multi-selects
	local pill = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(18, 16), Position = UDim2.new(1, -26, 0.5, 0), Visible = false, ZIndex = 6, Parent = btn })
	Corner(pill, 8); Library:AddToRegistry(pill, { BackgroundColor3 = "Accent" })
	local pillT = Text(pill, "", 10, true); pillT.TextXAlignment = Enum.TextXAlignment.Center; pillT.Size = UDim2.new(1, 0, 1, 0); pillT.ZIndex = 7
	pillT.TextColor3 = Color3.new(1, 1, 1); Library.Registry[pillT] = nil
	local arrow = Chevron(btn, 10, "FontDim"); arrow.AnchorPoint = Vector2.new(0.5, 0.5); arrow.Position = UDim2.new(1, -13, 0.5, 0); arrow.ZIndex = 6

	local list, listBody = PopupShell(240, 60, 12, 8)
	Shadow(list, 12)
	Library.OpenPopups[list] = list

	-- header: what you're picking, and how
	local head = Create("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = -3, ZIndex = 61, Parent = listBody })
	local ht = Text(head, title, 12, true); ht.Position = UDim2.new(0, 4, 0, 0); ht.Size = UDim2.new(1, -90, 1, 0); ht.ZIndex = 62
	local hint = Text(head, cfg.Multi and "pick any" or "pick one", 10, false, "FontDim"); hint.AnchorPoint = Vector2.new(1, 0); hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.Position = UDim2.new(1, -4, 0, 0); hint.Size = UDim2.new(0, 80, 1, 0); hint.ZIndex = 62
	local rule = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = -2, ZIndex = 61, Parent = listBody })
	Library:AddToRegistry(rule, { BackgroundColor3 = "Outline" })

	local search
	local useSearch = true
	if useSearch then
		local sf = Create("Frame", { Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0, ZIndex = 61, Parent = listBody })
		Library:AddToRegistry(sf, { BackgroundColor3 = "Well" }); Corner(sf, 8); local sfs = Stroke(sf, "Outline")
		local si = SearchIcon(sf, 12, "FontDim"); si.Position = UDim2.new(0, 10, 0.5, -6); si.ZIndex = 62
		search = Create("TextBox", { Size = UDim2.new(1, -36, 1, 0), Position = UDim2.new(0, 28, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "search " .. string.lower(tostring(title)), TextSize = 12, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 62, Parent = sf })
		Library:AddToRegistry(search, { TextColor3 = "Font", PlaceholderColor3 = "FontDim" })
		search.Focused:Connect(function() sfs.Color = Library.Theme.Accent Library.Registry[sfs] = { Color = "Accent" } end)
		search.FocusLost:Connect(function() sfs.Color = Library.Theme.Outline Library.Registry[sfs] = { Color = "Outline" } end)
	end
	local scroll = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageTransparency = 0.3, VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar, ScrollingDirection = Enum.ScrollingDirection.Y, Active = true, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), LayoutOrder = 1, ZIndex = 61, Parent = listBody })
	Library:AddToRegistry(scroll, { ScrollBarImageColor3 = "Accent" })
	Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

	-- footer (multi only): how many are picked, and quick all / clear
	local foot, footCount, allBtn, clearBtn
	do
		foot = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = 3, ZIndex = 61, Parent = listBody })
		local frule = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 61, Parent = foot })
		Library:AddToRegistry(frule, { BackgroundColor3 = "Outline" })
		footCount = Text(foot, "", 10, false, "FontDim"); footCount.Position = UDim2.new(0, 4, 0, 3); footCount.Size = UDim2.new(0.5, 0, 1, -3); footCount.ZIndex = 62
		local function smallBtn(text, xo)
			local b = Create("TextButton", { AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(42, 18), Position = UDim2.new(1, xo, 0, 4), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, ZIndex = 62, Parent = foot })
			Corner(b, 6)
			local t = Text(b, text, 10, true, "FontDim"); t.TextXAlignment = Enum.TextXAlignment.Center; t.Size = UDim2.new(1, 0, 1, 0); t.ZIndex = 63
			b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.94 }, 0.1) Tween(t, { TextColor3 = Library.Theme.Accent }, 0.1) end)
			b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 1 }, 0.12) Tween(t, { TextColor3 = Library.Theme.FontDim }, 0.12) end)
			return b
		end
		if cfg.Multi then
			clearBtn = smallBtn("clear", 0)
			allBtn = smallBtn("all", -46)
		elseif cfg.AllowNull then
			clearBtn = smallBtn("clear", 0)
		end
	end

	local obj = { Frame = f, Values = cfg.Values or {}, Multi = cfg.Multi, Type = "Dropdown", Idx = idx, Callback = cfg.Callback, _changed = {} }
	if cfg.Multi then
		obj.Value = {}
		if type(cfg.Default) == "table" then
			for k, v in pairs(cfg.Default) do
				if type(k) == "string" and v then obj.Value[k] = true elseif type(v) == "string" then obj.Value[v] = true end
			end
		end
	elseif type(cfg.Default) == "number" then obj.Value = obj.Values[cfg.Default]
	elseif type(cfg.Default) == "string" then obj.Value = cfg.Default end

	local function sizeScroll(n)
		local h = math.clamp(n * 28 - 2, 26, 236)
		scroll.Size = UDim2.new(1, 0, 0, h)
		local extra = 22 + 3 + 1 + 3 + (useSearch and 31 or 0) + 27
		list.Size = UDim2.new(0, list.Size.X.Offset, 0, h + extra + 16)
		if list.Visible then task.defer(function() DockPopup(list, btn) end) end
	end
	local function count()
		local n = 0
		if obj.Multi then for _, v in ipairs(obj.Values) do if obj.Value[v] then n = n + 1 end end end
		return n
	end
	local function display()
		if obj.Multi then
			local t = {}
			for _, v in ipairs(obj.Values) do if obj.Value[v] then t[#t + 1] = tostring(v) end end
			cur.Text = #t > 0 and table.concat(t, ", ") or "none"
			cur.TextColor3 = #t > 0 and Library.Theme.Font or Library.Theme.FontDim
			pill.Visible = #t > 1
			pillT.Text = tostring(#t)
			pill.Size = UDim2.fromOffset(#t > 9 and 24 or 18, 16)
			cur.Position = UDim2.new(1, pill.Visible and -(26 + pill.Size.X.Offset + 6) or -26, 0, 0)
			if footCount then footCount.Text = string.format("%d of %d picked", #t, #obj.Values) end
		else
			cur.Text = obj.Value ~= nil and tostring(obj.Value) or "none"
			cur.TextColor3 = obj.Value ~= nil and Library.Theme.Font or Library.Theme.FontDim
			if footCount then footCount.Text = string.format("%d of %d picked", obj.Value ~= nil and 1 or 0, #obj.Values) end
		end
	end
	local function fire()
		if obj.Callback then pcall(obj.Callback, obj.Value) end
		for _, fn in ipairs(obj._changed) do pcall(fn, obj.Value) end
	end
	local build
	build = function()
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local q = search and string.lower(search.Text) or ""
		local shown = 0
		for i, v in ipairs(obj.Values) do
			if q == "" or string.find(string.lower(tostring(v)), q, 1, true) then
				shown = shown + 1
				local selected = obj.Multi and obj.Value[v] or (not obj.Multi and obj.Value == v)
				local ib = Create("TextButton", { Size = UDim2.new(1, 0, 0, 26), Text = "", AutoButtonColor = false, BackgroundTransparency = selected and 0.86 or 1, LayoutOrder = i, ZIndex = 62, Parent = scroll })
				Corner(ib, 7)
				Library:AddToRegistry(ib, { BackgroundColor3 = selected and "Accent" or "ElementHover" })
				-- indicator: a checkbox for multi, a radio for single
				local ind = Create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 8, 0.5, 0), BackgroundTransparency = selected and 0 or 1, ZIndex = 63, Parent = ib })
				Library:AddToRegistry(ind, { BackgroundColor3 = "Accent" })
				Corner(ind, 4)
				local indS = Stroke(ind, selected and "Accent" or "Outline")
				do
					local tk = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Visible = selected and true or false, ZIndex = 64, Parent = ind })
					Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(3.5, 1.6), Position = UDim2.new(0.5, -2.5, 0.5, 1.2), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 65, Parent = tk })
					Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(6.5, 1.6), Position = UDim2.new(0.5, 1, 0.5, -0.4), Rotation = -45, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 65, Parent = tk })
				end
				local il = Text(ib, tostring(v), 12, selected, selected and "Font" or "FontDim")
				il.AnchorPoint = Vector2.new(0, 0.5); il.Position = UDim2.new(0, 30, 0.5, 0); il.Size = UDim2.new(1, -38, 0, LINE_H); il.ZIndex = 63
				ib.MouseEnter:Connect(function()
					if not selected then Tween(ib, { BackgroundTransparency = 0.5 }, 0.1) end
					Tween(il, { TextColor3 = Library.Theme.Font }, 0.1)
					if not selected then indS.Color = Library.Theme.FontDim end
				end)
				ib.MouseLeave:Connect(function()
					Tween(ib, { BackgroundTransparency = selected and 0.86 or 1 }, 0.14)
					if not selected then Tween(il, { TextColor3 = Library.Theme.FontDim }, 0.14) indS.Color = Library.Theme.Outline end
				end)
				ib.MouseButton1Click:Connect(function()
					if obj.Multi then
						if obj.Value[v] then obj.Value[v] = nil else obj.Value[v] = true end
					else
						if cfg.AllowNull and obj.Value == v then obj.Value = nil else obj.Value = v end
						list.Visible = false
					end
					display() build() fire()
				end)
			end
		end
		if shown == 0 then
			local empty = Text(scroll, q ~= "" and "no matches" or "nothing to pick", 11, false, "FontDim")
			empty.Size = UDim2.new(1, 0, 0, 26); empty.TextXAlignment = Enum.TextXAlignment.Center; empty.LayoutOrder = 0; empty.ZIndex = 62
		end
		sizeScroll(math.max(shown, 1))
	end
	if search then search:GetPropertyChangedSignal("Text"):Connect(build) end
	if allBtn then
		allBtn.MouseButton1Click:Connect(function()
			for _, v in ipairs(obj.Values) do obj.Value[v] = true end
			display() build() fire()
		end)
	end
	if clearBtn then
		clearBtn.MouseButton1Click:Connect(function()
			if obj.Multi then obj.Value = {} else obj.Value = nil end
			display() build() fire()
		end)
	end
	btn.MouseButton1Click:Connect(function()
		if list.Visible then list.Visible = false Tween(arrow, { Rotation = 0 }, 0.16) bstroke.Color = Library.Theme.Outline bstroke.Transparency = 0 return end
		bstroke.Color = Library.Theme.Accent
		bstroke.Transparency = 0.45
		Library:_ClosePopups(list)
		list.Size = UDim2.new(0, math.max(240, btn.AbsoluteSize.X), 0, 0)
		if search then search.Text = "" end
		build()
		RaisePopup(list)
		list.Visible = true
		task.defer(function() DockPopup(list, btn) end)
		local sc = list:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = list })
		sc.Scale = 0.95
		Tween(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint)
		Tween(arrow, { Rotation = 180 }, 0.16)
	end)
	list:GetPropertyChangedSignal("Visible"):Connect(function() if not list.Visible then bstroke.Color = Library.Theme.Outline bstroke.Transparency = 0 Tween(arrow, { Rotation = 0 }, 0.16) end end)
	function obj:SetValues(vals)
		self.Values = vals or {}
		if self.Multi then
			for k in pairs(self.Value) do if not table.find(self.Values, k) then self.Value[k] = nil end end
		elseif self.Value ~= nil and not table.find(self.Values, self.Value) then self.Value = nil end
		display()
		if list.Visible then build() end
	end
	function obj:SetValue(v, silent)
		if self.Multi then
			self.Value = {}
			if type(v) == "table" then for k, on in pairs(v) do if type(k) == "string" and on then self.Value[k] = true elseif type(on) == "string" then self.Value[on] = true end end end
		else self.Value = v end
		display()
		if list.Visible then build() end
		if not silent then fire() end
	end
	function obj:OnChanged(fn) table.insert(self._changed, fn) end
	display()
	Library.Options[idx] = obj
	reg(self, title, f, obj)
	return obj
end

local function toHex(c) return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function fromHex(s)
	s = tostring(s):gsub("#", "")
	if #s ~= 6 then return nil end
	local r, g, b = tonumber(s:sub(1, 2), 16), tonumber(s:sub(3, 4), 16), tonumber(s:sub(5, 6), 16)
	if not (r and g and b) then return nil end
	return Color3.fromRGB(r, g, b)
end

function Library._AttachColorPicker(parentObj, parentFrame, idx, cfg)
	cfg = cfg or {}
	local holder = slotHolder(parentFrame)
	local swatch = Create("TextButton", { Size = UDim2.fromOffset(18, 18), Text = "", AutoButtonColor = false, LayoutOrder = #holder:GetChildren(), ZIndex = 6, Parent = holder })
	Corner(swatch, 9)
	local swRing = Create("UIStroke", { Thickness = 2, Transparency = 0.5, Parent = swatch })
	Library:AddToRegistry(swRing, { Color = "Outline" })
	swatch.MouseEnter:Connect(function() Tween(swRing, { Transparency = 0.1 }, 0.12) end)
	swatch.MouseLeave:Connect(function() Tween(swRing, { Transparency = 0.5 }, 0.12) end)
	local swatchGrad = Create("UIGradient", { Enabled = false, Parent = swatch })

	local obj = { Frame = swatch, Type = "ColorPicker", Idx = idx, Callback = cfg.Callback, Gradient = cfg.Gradient, _changed = {} }
	obj.Value = cfg.Default or Color3.fromRGB(255, 255, 255)
	obj.Transparency = cfg.Transparency or 0
	obj.Value2 = cfg.Default2 or Color3.fromRGB(0, 0, 0)
	obj.Rotation = cfg.Rotation or 0
	local activeStop = 1

	local W = 226
	local popH = 20 + 16 + 8 + 118 + 8 + 12 + 8 + 26 + (cfg.Transparency ~= nil and 20 or 0) + (cfg.Gradient and 78 or 0)
	local pop, popBody = PopupShell(W, 70, 12, 10)
	pop.Size = UDim2.fromOffset(W, popH)
	popBody:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 8)
	Shadow(pop, 10)
	Library.OpenPopups[pop] = pop

	local title = Text(popBody, cfg.Title or cfg.Text or idx, 12, true); title.LayoutOrder = 0; title.Size = UDim2.new(1, 0, 0, LINE_H); title.ZIndex = 71

	local sv = Create("Frame", { Size = UDim2.new(1, 0, 0, 118), LayoutOrder = 1, BackgroundColor3 = Color3.fromRGB(255, 0, 0), ZIndex = 71, Parent = popBody })
	Corner(sv, 8)
	local satLayer = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 72, Parent = sv })
	Corner(satLayer, 8)
	Create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = satLayer })
	local valLayer = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 73, Parent = sv })
	Corner(valLayer, 8)
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }), Parent = valLayer })
	local svHit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 75, Parent = sv })
	local svCur = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 76, Parent = sv })
	Corner(svCur, 5); Create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = svCur })

	local hue = Create("Frame", { Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2, ZIndex = 71, Parent = popBody })
	Corner(hue, 6)
	Create("UIGradient", { Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)) }), Parent = hue })
	local hueHit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 6), Position = UDim2.new(0, 0, 0, -3), BackgroundTransparency = 1, Text = "", ZIndex = 74, Parent = hue })
	local hueCur = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 16), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 75, Parent = hue })
	Corner(hueCur, 2)

	local alpha, alphaCur
	if cfg.Transparency ~= nil then
		alpha = Create("Frame", { Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 3, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 71, Parent = popBody })
		Corner(alpha, 6)
		Create("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(0, 0, 0)), Parent = alpha })
		local aHit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 6), Position = UDim2.new(0, 0, 0, -3), BackgroundTransparency = 1, Text = "", ZIndex = 74, Parent = alpha })
		alphaCur = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, 16), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 30, 30), BorderSizePixel = 0, ZIndex = 75, Parent = alpha })
		Corner(alphaCur, 2)
		obj._aHit = aHit
	end

	local hexF = Create("Frame", { Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 4, ZIndex = 71, Parent = popBody })
	Library:AddToRegistry(hexF, { BackgroundColor3 = "Well" }); Corner(hexF, 8); Stroke(hexF, "Outline")
	local hexBox = Create("TextBox", { Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0), BackgroundTransparency = 1, Text = toHex(obj.Value), TextSize = 12, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 72, Parent = hexF })
	Library:AddToRegistry(hexBox, { TextColor3 = "Font" })

	local stopA, stopB, rotTrack, rotFill, prevGrad
	if cfg.Gradient then
		local gRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 5, ZIndex = 71, Parent = popBody })
		Corner(gRow, 6)
		prevGrad = Create("UIGradient", { Parent = gRow })
		local sRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 6, BackgroundTransparency = 1, ZIndex = 71, Parent = popBody })
		stopA = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), Text = "stop 1", TextSize = 11, FontFace = Library.FontFaceBold, AutoButtonColor = false, ZIndex = 72, Parent = sRow })
		stopB = Create("TextButton", { Size = UDim2.new(0.5, -3, 1, 0), Position = UDim2.new(0.5, 3, 0, 0), Text = "stop 2", TextSize = 11, FontFace = Library.FontFaceBold, AutoButtonColor = false, ZIndex = 72, Parent = sRow })
		for _, b in ipairs({ stopA, stopB }) do Corner(b, 7); Library:AddToRegistry(b, { BackgroundColor3 = "Element", TextColor3 = "Font" }) end
		local rRow = Create("Frame", { Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 7, BackgroundTransparency = 1, ZIndex = 71, Parent = popBody })
		local rl = Text(rRow, "rotation", 11, false, "FontDim"); rl.AnchorPoint = Vector2.new(0, 0.5); rl.Position = UDim2.new(0, 0, 0.5, 0); rl.Size = UDim2.new(0, 56, 0, LINE_H); rl.ZIndex = 72
		rotTrack = Create("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(1, -62, 0, 8), Position = UDim2.new(1, 0, 0.5, 0), Text = "", AutoButtonColor = false, ZIndex = 72, Parent = rRow })
		Library:AddToRegistry(rotTrack, { BackgroundColor3 = "Element" }); Corner(rotTrack, 4)
		rotFill = Create("Frame", { Size = UDim2.new(obj.Rotation / 360, 0, 1, 0), BorderSizePixel = 0, ZIndex = 73, Parent = rotTrack })
		Corner(rotFill, 4); Library:AddToRegistry(rotFill, { BackgroundColor3 = "Accent" })
	end

	local function current() return activeStop == 1 and obj.Value or obj.Value2 end
	local function render()
		local col = current()
		local h, s, v = col:ToHSV()
		sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCur.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCur.Position = UDim2.new(h, 0, 0.5, 0)
		if alphaCur then alphaCur.Position = UDim2.new(obj.Transparency, 0, 0.5, 0) alphaCur.BackgroundColor3 = obj.Value end
		swatch.BackgroundColor3 = obj.Value
		swatch.BackgroundTransparency = obj.Transparency * 0.85
		if cfg.Gradient then
			swatchGrad.Enabled = true
			swatchGrad.Color = ColorSequence.new(obj.Value, obj.Value2)
			swatchGrad.Rotation = obj.Rotation
			prevGrad.Color = ColorSequence.new(obj.Value, obj.Value2)
			prevGrad.Rotation = obj.Rotation
			stopA.TextColor3 = activeStop == 1 and Library.Theme.Accent or Library.Theme.Font
			stopB.TextColor3 = activeStop == 2 and Library.Theme.Accent or Library.Theme.Font
			rotFill.Size = UDim2.new(obj.Rotation / 360, 0, 1, 0)
		end
		if not hexBox:IsFocused() then hexBox.Text = toHex(col) end
	end
	local function fire()
		if obj.Callback then
			if cfg.Gradient then pcall(obj.Callback, ColorSequence.new(obj.Value, obj.Value2), obj.Rotation)
			else pcall(obj.Callback, obj.Value, obj.Transparency) end
		end
		for _, fn in ipairs(obj._changed) do pcall(fn, obj.Value, obj.Transparency) end
	end
	local function setCurrent(c) if activeStop == 1 then obj.Value = c else obj.Value2 = c end render() fire() end

	local drag = nil
	local function apply(kind, pos)
		if kind == "sv" then
			local a, sz = sv.AbsolutePosition, sv.AbsoluteSize
			local s = math.clamp((pos.X - a.X) / math.max(sz.X, 1), 0, 1)
			local v = 1 - math.clamp((pos.Y - a.Y) / math.max(sz.Y, 1), 0, 1)
			local h = select(1, current():ToHSV())
			setCurrent(Color3.fromHSV(h, s, v))
		elseif kind == "hue" then
			local a, sz = hue.AbsolutePosition, hue.AbsoluteSize
			local h = math.clamp((pos.X - a.X) / math.max(sz.X, 1), 0, 0.999)
			local _, s, v = current():ToHSV()
			setCurrent(Color3.fromHSV(h, s, v))
		elseif kind == "alpha" and alpha then
			local a, sz = alpha.AbsolutePosition, alpha.AbsoluteSize
			obj.Transparency = math.clamp((pos.X - a.X) / math.max(sz.X, 1), 0, 1) render() fire()
		elseif kind == "rot" and rotTrack then
			local a, sz = rotTrack.AbsolutePosition, rotTrack.AbsoluteSize
			obj.Rotation = math.floor(math.clamp((pos.X - a.X) / math.max(sz.X, 1), 0, 1) * 360) render() fire()
		end
	end
	svHit.InputBegan:Connect(function(inp) if IsPressed(inp) then drag = "sv" apply("sv", inp.Position) end end)
	hueHit.InputBegan:Connect(function(inp) if IsPressed(inp) then drag = "hue" apply("hue", inp.Position) end end)
	if obj._aHit then obj._aHit.InputBegan:Connect(function(inp) if IsPressed(inp) then drag = "alpha" apply("alpha", inp.Position) end end) end
	if rotTrack then rotTrack.InputBegan:Connect(function(inp) if IsPressed(inp) then drag = "rot" apply("rot", inp.Position) end end) end
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(inp)
		if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then apply(drag, inp.Position) end
	end))
	Library:GiveSignal(UserInputService.InputEnded:Connect(function(inp) if IsPressed(inp) then drag = nil end end))
	hexBox.FocusLost:Connect(function() local c = fromHex(hexBox.Text) if c then setCurrent(c) else render() end end)
	if stopA then
		stopA.MouseButton1Click:Connect(function() activeStop = 1 render() end)
		stopB.MouseButton1Click:Connect(function() activeStop = 2 render() end)
	end
	swatch.MouseButton1Click:Connect(function()
		if pop.Visible then pop.Visible = false return end
		Library:_ClosePopups(pop)
		RaisePopup(pop)
		pop.Visible = true
		task.defer(function() DockPopup(pop, swatch) end)
		local sc = pop:FindFirstChildOfClass("UIScale") or Create("UIScale", { Parent = pop })
		sc.Scale = 0.95
		Tween(sc, { Scale = 1 }, 0.2, Enum.EasingStyle.Quint)
	end)
	function obj:SetValueRGB(c, t, silent) self.Value = c if t then self.Transparency = t end render() if not silent then fire() end end
	function obj:SetValue(c, t, silent) self:SetValueRGB(c, t, silent) end
	function obj:SetValue2(c, silent) self.Value2 = c render() if not silent then fire() end end
	function obj:SetRotation(r, silent) self.Rotation = r render() if not silent then fire() end end
	function obj:GetSequence() return ColorSequence.new(self.Value, self.Value2) end
	function obj:OnChanged(fn) table.insert(self._changed, fn) end
	render()
	Library.Options[idx] = obj
	return obj
end

function GroupboxMethods:AddColorPicker(idx, cfg)
	cfg = cfg or {}
	local f = row(self, ROW_H)
	local l = Text(f, cfg.Text or idx, 12, false)
	l.AnchorPoint = Vector2.new(0, 0.5); l.Position = UDim2.new(0, 0, 0.5, 0); l.Size = UDim2.new(1, -40, 0, LINE_H); l.ZIndex = 5
	local obj = Library._AttachColorPicker(nil, f, idx, cfg)
	bindLabelWidth(l, f, 0)
	obj.Frame = f
	reg(self, cfg.Text or idx, f, obj)
	return obj
end

local KEY_SHORT = { MouseButton1 = "M1", MouseButton2 = "M2", MouseButton3 = "M3" }
local function keyName(k)
	if typeof(k) == "EnumItem" then
		local n = KEY_SHORT[k.Name] or k.Name
		n = n:gsub("^Right", "R"):gsub("^Left", "L"):gsub("Control", "Ctrl"):gsub("Shift", "Shft")
		return n
	end
	return tostring(k)
end

function Library._AttachKeyPicker(parentObj, parentFrame, idx, cfg)
	cfg = cfg or {}
	local holder = slotHolder(parentFrame)
	local btn = Create("TextButton", { Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, Text = "", AutoButtonColor = false, LayoutOrder = #holder:GetChildren(), ZIndex = 6, Parent = holder })
	Corner(btn, 6); Library:AddToRegistry(btn, { BackgroundColor3 = "Element" }); Stroke(btn, "Outline")
	local capEdge = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1, -6, 0, 2), Position = UDim2.new(0.5, 0, 1, -1), BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 7, Parent = btn })
	Corner(capEdge, 1); Library:AddToRegistry(capEdge, { BackgroundColor3 = "Accent" })
	Pad(btn, 8, 8, 0, 0)
	local kl = Text(btn, "", 11, true, "Accent")
	kl.AnchorPoint = Vector2.new(0, 0.5); kl.Position = UDim2.new(0, 0, 0.5, 0); kl.AutomaticSize = Enum.AutomaticSize.X; kl.Size = UDim2.new(0, 0, 0, 14); kl.TextXAlignment = Enum.TextXAlignment.Center; kl.ZIndex = 7

	local obj = { Frame = btn, Type = "KeyPicker", Idx = idx, Mode = cfg.Mode or "Toggle", Value = cfg.Default or "None", Toggled = false, Callback = cfg.Callback, ChangedCallback = cfg.ChangedCallback, SyncToggleState = cfg.SyncToggleState, Text = cfg.Text or idx, _changed = {} }
	local binding = false

	local menu, menuBody = PopupShell(92, 70, 10, 5)
	Shadow(menu, 8)
	Library.OpenPopups[menu] = menu
	local modes = {}
	local modeList = cfg.Modes or { "Always", "Toggle", "Hold" }
	menu.Size = UDim2.fromOffset(92, #modeList * 27 + 7 + 30)
	for i, mode in ipairs(modeList) do
		local mb = Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 71, Parent = menuBody })
		Corner(mb, 7)
		local ml = Text(mb, string.lower(mode), 11, true, "FontDim")
		ml.AnchorPoint = Vector2.new(0, 0.5); ml.Position = UDim2.new(0, 8, 0.5, 0); ml.Size = UDim2.new(1, -16, 0, 14); ml.ZIndex = 72
		mb.MouseButton1Click:Connect(function() obj.Mode = mode menu.Visible = false obj:_render() end)
		modes[mode] = { b = mb, l = ml }
	end
	do
		local rule = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0.4, BorderSizePixel = 0, LayoutOrder = #modeList + 1, ZIndex = 71, Parent = menuBody })
		Library:AddToRegistry(rule, { BackgroundColor3 = "Outline" })
		local cb = Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, LayoutOrder = #modeList + 2, ZIndex = 71, Parent = menuBody })
		Corner(cb, 7)
		local cl = Text(cb, "no key", 11, true, "FontDim")
		cl.AnchorPoint = Vector2.new(0, 0.5); cl.Position = UDim2.new(0, 8, 0.5, 0); cl.Size = UDim2.new(1, -16, 0, 14); cl.ZIndex = 72
		cb.MouseEnter:Connect(function() Tween(cb, { BackgroundTransparency = 0.94 }, 0.1) Tween(cl, { TextColor3 = Library.Theme.Risky }, 0.1) end)
		cb.MouseLeave:Connect(function() Tween(cb, { BackgroundTransparency = 1 }, 0.12) Tween(cl, { TextColor3 = Library.Theme.FontDim }, 0.12) end)
		cb.MouseButton1Click:Connect(function()
			menu.Visible = false
			binding = false
			if obj.Mode == "Hold" and obj._held then obj._held = false if obj.Callback then pcall(obj.Callback, false) end end
			obj:SetValue("None")
		end)
	end

	function obj:_render()
		kl.Text = binding and "..." or ((self.Value == "None" or self.Value == nil) and "-" or keyName(self.Value))
		kl.TextColor3 = binding and Library.Theme.Font or Library.Theme.Accent
		for mode, r in pairs(modes) do
			r.l.TextColor3 = (mode == self.Mode) and Library.Theme.Accent or Library.Theme.FontDim
			r.b.BackgroundTransparency = (mode == self.Mode) and 0.93 or 1
		end
	end
	function obj:GetState()
		if self.Mode == "Always" then return true end
		if self.Mode == "Hold" then return self._held == true end
		return self.Toggled
	end
	function obj:SetValue(v, silent)
		if type(v) == "table" and typeof(v) ~= "EnumItem" then self.Mode = v[2] or self.Mode v = v[1] end
		if typeof(v) == "string" then
			if v == "None" then self.Value = "None"
			else
				local ok, k = pcall(function() return Enum.KeyCode[v] end)
				if ok and k then self.Value = k else
					local ok2, m = pcall(function() return Enum.UserInputType[v] end)
					self.Value = (ok2 and m) or "None"
				end
			end
		else self.Value = v end
		self:_render()
		if not silent and self.ChangedCallback then pcall(self.ChangedCallback, self.Value) end
	end
	function obj:OnClick(fn) table.insert(self._changed, fn) end
	function obj:OnChanged(fn) self.ChangedCallback = fn end

	local function activate()
		if obj.Mode == "Toggle" then
			obj.Toggled = not obj.Toggled
			if obj.SyncToggleState and parentObj and parentObj.SetValue then parentObj:SetValue(obj.Toggled) end
		end
		if obj.Callback then pcall(obj.Callback, obj:GetState()) end
		for _, fn in ipairs(obj._changed) do pcall(fn, obj:GetState()) end
		obj:_render()
	end
	btn.MouseButton1Click:Connect(function() binding = true obj:_render() end)
	btn.MouseButton2Click:Connect(function()
		if menu.Visible then menu.Visible = false return end
		Library:_ClosePopups(menu)
		RaisePopup(menu)
		menu.Visible = true
		task.defer(function() DockPopup(menu, btn) end)
	end)
	Library:GiveSignal(UserInputService.InputBegan:Connect(function(inp, gpe)
		if binding then
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				binding = false
				local k = inp.KeyCode
				local clear = k == Enum.KeyCode.Escape or k == Enum.KeyCode.Backspace or k == Enum.KeyCode.Delete
				obj:SetValue(clear and "None" or k)
			elseif inp.UserInputType == Enum.UserInputType.MouseButton2 or inp.UserInputType == Enum.UserInputType.MouseButton3 then
				binding = false
				obj:SetValue(inp.UserInputType)
			end
			return
		end
		if gpe then return end
		local match = (inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == obj.Value) or (inp.UserInputType == obj.Value)
		if match then
			if obj.Mode == "Hold" then obj._held = true if obj.Callback then pcall(obj.Callback, true) end obj:_render() else activate() end
		end
	end))
	Library:GiveSignal(UserInputService.InputEnded:Connect(function(inp)
		local match = (inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == obj.Value) or (inp.UserInputType == obj.Value)
		if match and obj.Mode == "Hold" then obj._held = false if obj.Callback then pcall(obj.Callback, false) end obj:_render() end
	end))
	if parentObj and parentObj.OnChanged and obj.SyncToggleState then parentObj:OnChanged(function(v) obj.Toggled = v obj:_render() end) end
	obj:SetValue(cfg.Default or "None", true)
	obj:_render()
	Library.Options[idx] = obj
	return obj
end

function GroupboxMethods:AddKeyPicker(idx, cfg)
	cfg = cfg or {}
	local f = row(self, ROW_H)
	local l = Text(f, cfg.Text or idx, 12, false)
	l.AnchorPoint = Vector2.new(0, 0.5); l.Position = UDim2.new(0, 0, 0.5, 0); l.Size = UDim2.new(1, -60, 0, LINE_H); l.ZIndex = 5
	local obj = Library._AttachKeyPicker(nil, f, idx, cfg)
	bindLabelWidth(l, f, 0)
	obj.Frame = f
	reg(self, cfg.Text or idx, f, obj)
	return obj
end

function GroupboxMethods:AddESPPreview(cfg)
	cfg = cfg or {}
	local tabsCfg = cfg.Tabs or { "Enemy", "Team" }
	local CANVAS_H = cfg.Height or 250
	local userId = tonumber(cfg.UserId) or 5508585538
	local f = row(self, CANVAS_H + 26, true)

	-- segmented tabs
	local tabBar = Create("Frame", { Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 5, Parent = f })
	Corner(tabBar, 7); Stroke(tabBar, "Outline"); Pad(tabBar, 2, 2, 2, 2)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabBar })

	-- canvas
	local canvas = Create("Frame", { Size = UDim2.new(1, 0, 0, CANVAS_H), Position = UDim2.new(0, 0, 0, 26), ClipsDescendants = true, ZIndex = 5, Parent = f })
	Library:AddToRegistry(canvas, { BackgroundColor3 = "Well" }); Corner(canvas, 10); Stroke(canvas, "Outline")
	do
		local grid = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 5, Parent = canvas })
		for i = 1, 14 do
			local v = Create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(i / 15, 0, 0, 0), BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 5, Parent = grid })
			Library:AddToRegistry(v, { BackgroundColor3 = "FontDim" })
		end
		for i = 1, 8 do
			local h = Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, i / 9, 0), BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 5, Parent = grid })
			Library:AddToRegistry(h, { BackgroundColor3 = "FontDim" })
		end
	end

	-- 3D model
	local glowVp = Create("ViewportFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Ambient = Color3.fromRGB(255, 255, 255), LightColor = Color3.fromRGB(255, 255, 255), ZIndex = 6, Parent = canvas })
	local glowWm = Create("WorldModel", { Parent = glowVp })
	local glowCam = Create("Camera", { FieldOfView = 34, Parent = glowVp })
	glowVp.CurrentCamera = glowCam
	local vp = Create("ViewportFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Ambient = Color3.fromRGB(190, 190, 200), LightColor = Color3.fromRGB(255, 255, 255), LightDirection = Vector3.new(-0.5, -1, -0.8), ZIndex = 7, Parent = canvas })
	local wm = Create("WorldModel", { Parent = vp })
	local cam = Create("Camera", { FieldOfView = 34, Parent = vp })
	vp.CurrentCamera = cam
	local dummy = nil
	local glowParts = {}
	local yaw, dist = math.rad(20), 8.5
	local glowOn, glowColour = true, Color3.fromRGB(255, 0, 0)

	local function buildGlow(m)
		for _, g in ipairs(glowParts) do pcall(function() g.part:Destroy() end) end
		glowParts = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
				local pad = cfg.OutlineThickness or 0.035
				for _, spec in ipairs({ { 1.0, pad, 0.0 } }) do
					local shell
					local specialMesh = d:FindFirstChildOfClass("SpecialMesh")
					if d:IsA("MeshPart") then
						shell = d:Clone()
						for _, c in ipairs(shell:GetChildren()) do c:Destroy() end
						shell.TextureID = ""
					elseif specialMesh then
						shell = d:Clone()
						for _, c in ipairs(shell:GetChildren()) do
							if not c:IsA("SpecialMesh") then c:Destroy() end
						end
						local sm = shell:FindFirstChildOfClass("SpecialMesh")
						if sm then sm.TextureId = "" end
					else
						shell = Instance.new("Part")
						shell.Shape = (d:IsA("Part") and d.Shape) or Enum.PartType.Block
					end
					shell.Name = "_glow"
					shell.Anchored = true
					shell.CanCollide = false
					shell.CastShadow = false
					shell.Material = Enum.Material.Neon
					shell.Color = glowColour
					shell.Transparency = spec[3]
					local sm = shell:FindFirstChildOfClass("SpecialMesh")
					if sm and sm.MeshType == Enum.MeshType.FileMesh then
						local k = 1 + spec[2] / math.max(d.Size.Y, 0.5)
						sm.Scale = sm.Scale * k
						shell.Size = d.Size
					else
						shell.Size = d.Size * spec[1] + Vector3.new(spec[2], spec[2], spec[2])
					end
					shell.Parent = glowWm
					glowParts[#glowParts + 1] = { part = shell, src = d, base = spec[3] }
				end
			end
		end
	end
	local function loadUser(id)
		task.spawn(function()
			local ok, m = pcall(function() return Players:CreateHumanoidModelFromUserId(id) end)
			if not ok or not m then
				local ok2, m2 = pcall(function() return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15) end)
				m = ok2 and m2 or nil
			end
			if not m then return end
			if dummy then pcall(function() dummy:Destroy() end) end
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end end
			local hum = m:FindFirstChildOfClass("Humanoid")
			if hum then hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
			m:PivotTo(CFrame.new(0, 0, 0))
			m.Parent = wm
			dummy = m
			buildGlow(m)
			pcall(function()
				local h = m:FindFirstChildOfClass("Humanoid")
				if not h then return end
				local animator = h:FindFirstChildOfClass("Animator") or Instance.new("Animator", h)
				local anim = Instance.new("Animation")
				anim.AnimationId = h.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180435571" or "rbxassetid://507766666"
				local track = animator:LoadAnimation(anim)
				track.Looped = true
				track:Play()
			end)
		end)
	end
	loadUser(userId)

	-- drag to rotate, wheel / buttons to zoom
	local dragging, lastX = false, 0
	local sink = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, ScrollingEnabled = true, ElasticBehavior = Enum.ElasticBehavior.Never, CanvasSize = UDim2.new(0, 0, 3, 0), CanvasPosition = Vector2.new(0, 1), Active = true, ZIndex = 8, Parent = canvas })
	sink.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true lastX = inp.Position.X end
	end)
	sink.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseWheel then dist = math.clamp(dist - inp.Position.Z * 1.0, 4, 16) end
	end)
	sink:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local mid = math.max(0, (sink.AbsoluteCanvasSize.Y - sink.AbsoluteSize.Y) * 0.5)
		if math.abs(sink.CanvasPosition.Y - mid) > 0.5 then sink.CanvasPosition = Vector2.new(0, mid) end
	end)
	Library:GiveSignal(UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			yaw = yaw + (inp.Position.X - lastX) * 0.012
			lastX = inp.Position.X
		end
	end))
	Library:GiveSignal(UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end))
	local zoomBox = Create("Frame", { Size = UDim2.fromOffset(24, 50), Position = UDim2.new(1, -32, 1, -58), BackgroundTransparency = 1, ZIndex = 12, Parent = canvas })
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = zoomBox })
	for i, spec in ipairs({ { "+", -1.5 }, { "-", 1.5 } }) do
		local zb = Create("TextButton", { Size = UDim2.fromOffset(22, 22), Text = spec[1], TextSize = 14, FontFace = Library.FontFaceBold, AutoButtonColor = false, BackgroundTransparency = 0.4, LayoutOrder = i, ZIndex = 13, Parent = zoomBox })
		Corner(zb, 7); Library:AddToRegistry(zb, { BackgroundColor3 = "Main", TextColor3 = "FontDim" }); Stroke(zb, "Outline")
		zb.MouseButton1Click:Connect(function() dist = math.clamp(dist + spec[2], 4, 16) end)
	end
	local hintL = Text(canvas, "", 9, false, "FontDim"); hintL.Position = UDim2.new(0, 10, 1, -18); hintL.Size = UDim2.new(0, 200, 0, 12); hintL.ZIndex = 12; hintL.TextTransparency = 0.35
	hintL.Text = "drag to rotate   scroll to zoom"

	local preview = { Frame = f, Tabs = {}, Active = nil, Canvas = canvas }
	local function project(world)
		local rel = cam.CFrame:PointToObjectSpace(world)
		if rel.Z > -0.05 then return nil end
		local sz = canvas.AbsoluteSize
		if sz.X < 1 or sz.Y < 1 then return nil end
		local tanHalf = math.tan(math.rad(cam.FieldOfView) * 0.5)
		local px = (rel.X / -rel.Z) / (tanHalf * (sz.X / sz.Y))
		local py = (rel.Y / -rel.Z) / tanHalf
		return Vector2.new((px * 0.5 + 0.5) * sz.X, (0.5 - py * 0.5) * sz.Y)
	end
	local function applyGlow()
		for _, g in ipairs(glowParts) do g.part.Transparency = glowOn and g.base or 1 g.part.Color = glowColour end
	end

	for i, name in ipairs(tabsCfg) do
		local page = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ZIndex = 9, Parent = canvas })
		-- the veil card, verbatim: Code font, hard black stroke, name / "[dist] hp/max" / 60x3 bar, stacked above the head
		local card = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(160, 36), BackgroundTransparency = 1, ZIndex = 9, Parent = page })
		local nameL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 13, TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeColor3 = Color3.fromRGB(0, 0, 0), TextStrokeTransparency = 0, Text = "player", ZIndex = 10, Parent = card })
		local subL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 11, TextColor3 = Color3.fromRGB(220, 220, 220), TextStrokeColor3 = Color3.fromRGB(0, 0, 0), TextStrokeTransparency = 0, Text = "[42] 180/250", ZIndex = 10, Parent = card })
		local barBg = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), Size = UDim2.fromOffset(60, 3), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(0, 0, 0), ZIndex = 10, Parent = card })
		local bar = Create("Frame", { Size = UDim2.fromScale(0.72, 1), BackgroundColor3 = Color3.fromRGB(71, 255, 0), BorderSizePixel = 0, ZIndex = 11, Parent = barBg })
		local tracer = Create("Frame", { AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(1, 60), BackgroundColor3 = Color3.fromRGB(255, 0, 0), BorderSizePixel = 0, Visible = false, ZIndex = 8, Parent = page })

		local tab = { Name = name, Page = page, Colour = Color3.fromRGB(255, 0, 0), Parts = { Name = nameL, Distance = subL, HealthBg = barBg, Health = bar, Tracer = tracer, Card = card }, _show = { Name = true, Distance = true, HealthBg = true, Tracer = false, Outline = true } }
		function tab:_layout()
			if not dummy then return end
			local ok, boxCf, ext = pcall(function() return dummy:GetBoundingBox() end)
			if not ok then return end
			local top = project(boxCf.Position + Vector3.new(0, ext.Y * 0.5 + 0.4, 0))
			local bottom = project(boxCf.Position - Vector3.new(0, ext.Y * 0.5, 0))
			if not top then return end
			card.Position = UDim2.fromOffset(math.floor(top.X + 0.5), math.floor(top.Y + 0.5))
			-- pack the card like veil does: whichever rows are on stack from the bottom up
			local y = 36
			local rows = {}
			if self._show.HealthBg then rows[#rows + 1] = { barBg, 3 } end
			if self._show.Distance then rows[#rows + 1] = { subL, 12 } end
			if self._show.Name then rows[#rows + 1] = { nameL, 14 } end
			for _, r in ipairs(rows) do
				y = y - r[2]
				r[1].Position = UDim2.new(r[1] == barBg and 0.5 or 0, 0, 0, y)
				y = y - 2
			end
			if bottom then
				local ox, oy = canvas.AbsoluteSize.X * 0.5, canvas.AbsoluteSize.Y
				local dx, dy = bottom.X - ox, bottom.Y - oy
				tracer.Position = UDim2.fromOffset(math.floor(ox), math.floor(oy))
				tracer.Size = UDim2.fromOffset(1, math.floor(math.sqrt(dx * dx + dy * dy) + 0.5))
				tracer.Rotation = -math.deg(math.atan2(dx, -dy))
			end
		end
		function tab:SetColour(c)
			self.Colour = c
			tracer.BackgroundColor3 = c
			if preview.Active == self then glowColour = c applyGlow() end
		end
		function tab:SetOutline(on)
			self._show.Outline = on and true or false
			if preview.Active == self then glowOn = self._show.Outline applyGlow() end
		end
		function tab:SetText(which, text) local p = self.Parts[which] if p and p:IsA("TextLabel") then p.Text = text end end
		function tab:SetHealth(frac)
			frac = math.clamp(frac or 1, 0, 1)
			bar.Size = UDim2.fromScale(frac, 1)
			bar.BackgroundColor3 = Color3.fromRGB(math.clamp(math.floor(255 * (1 - frac)), 0, 255), math.clamp(math.floor(255 * frac), 0, 255), 0)
		end
		function tab:Set(settings)
			for key, val in pairs(settings) do
				if typeof(val) == "boolean" then
					if key == "Box" or key == "Outline" or key == "Highlight" then self:SetOutline(val)
					elseif self.Parts[key] then self.Parts[key].Visible = val self._show[key] = val end
				elseif typeof(val) == "Color3" then
					if key == "Box" or key == "Outline" or key == "Highlight" or key == "Colour" then self:SetColour(val)
					elseif key == "Name" then nameL.TextColor3 = val
					elseif key == "Tracer" then tracer.BackgroundColor3 = val end
				end
			end
		end
		function tab:SetBoxStyle() end

		local tb = Create("TextButton", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, LayoutOrder = i, ZIndex = 6, Parent = tabBar })
		Corner(tb, 5); Pad(tb, 9, 9, 0, 0)
		local tl = Text(tb, string.lower(name), 10, true, "FontDim"); tl.AutomaticSize = Enum.AutomaticSize.X; tl.Size = UDim2.new(0, 0, 1, 0); tl.ZIndex = 7
		tab._label, tab._btn = tl, tb
		function tab:Select()
			for _, o in ipairs(preview.Tabs) do
				o.Page.Visible = false
				Tween(o._label, { TextColor3 = Library.Theme.FontDim }, 0.1)
				Tween(o._btn, { BackgroundTransparency = 1 }, 0.1)
			end
			self.Page.Visible = true
			Tween(self._label, { TextColor3 = Library.Theme.Accent }, 0.1)
			Tween(self._btn, { BackgroundTransparency = 0.93 }, 0.1)
			preview.Active = self
			glowOn, glowColour = self._show.Outline, self.Colour
			applyGlow()
		end
		tb.MouseButton1Click:Connect(function() tab:Select() end)
		table.insert(preview.Tabs, tab)
	end

	Library:GiveSignal(RunService.RenderStepped:Connect(function()
		if not canvas.Visible or not f:IsDescendantOf(ScreenGui) then return end
		if dummy then
			local ok, boxCf = pcall(function() return dummy:GetBoundingBox() end)
			local pivot = ok and boxCf.Position or Vector3.zero
			cam.CFrame = CFrame.new(pivot + Vector3.new(math.sin(yaw) * dist, dist * 0.1, math.cos(yaw) * dist), pivot)
			glowCam.CFrame = cam.CFrame
			for _, g in ipairs(glowParts) do if g.src.Parent then g.part.CFrame = g.src.CFrame end end
		end
		for _, t in ipairs(preview.Tabs) do if t.Page.Visible then t:_layout() end end
	end))

	-- pop-out
	local popBtn = Create("TextButton", { Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -30, 0, 8), Text = "", AutoButtonColor = false, BackgroundTransparency = 0.4, ZIndex = 13, Parent = canvas })
	Corner(popBtn, 7); Library:AddToRegistry(popBtn, { BackgroundColor3 = "Main" }); Stroke(popBtn, "Outline")
	do
		local a = Create("Frame", { Size = UDim2.fromOffset(8, 6), Position = UDim2.new(0.5, -6, 0.5, -5), BackgroundTransparency = 1, ZIndex = 14, Parent = popBtn })
		local s1 = Create("UIStroke", { Thickness = 1, Parent = a }); Library:AddToRegistry(s1, { Color = "FontDim" })
		local b = Create("Frame", { Size = UDim2.fromOffset(8, 6), Position = UDim2.new(0.5, -2, 0.5, -1), BackgroundTransparency = 1, ZIndex = 15, Parent = popBtn })
		local s2 = Create("UIStroke", { Thickness = 1, Parent = b }); Library:AddToRegistry(s2, { Color = "Accent" })
	end
	local floating = nil
	popBtn.MouseButton1Click:Connect(function()
		if floating then
			canvas.Parent = f
			canvas.Position = UDim2.new(0, 0, 0, 26)
			canvas.Size = UDim2.new(1, 0, 0, CANVAS_H)
			if floating._shadow then floating._shadow:Destroy() end
			floating.Frame:Destroy()
			floating = nil
			return
		end
		local win = Create("Frame", { Size = UDim2.fromOffset(380, 350), Position = UDim2.new(0.5, -190, 0.5, -175), BackgroundTransparency = 0.05, ZIndex = 400, Parent = PopupLayer })
		Library:AddToRegistry(win, { BackgroundColor3 = "Main" })
		Corner(win, 14)
		local wst = Create("UIStroke", { Thickness = 1, Transparency = 0.15, Parent = win }); Library:AddToRegistry(wst, { Color = "Outline" })
		local wedge = Create("UIStroke", { Thickness = 1, Transparency = 0.65, Parent = win }); Library:AddToRegistry(wedge, { Color = "Accent" })
		Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = wedge })
		local winShadow = Shadow(win, 12)
		local bar = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 401, Parent = win })
		local tl = Text(bar, "esp preview", 12, true); tl.Position = UDim2.new(0, 12, 0, 0); tl.Size = UDim2.new(1, -40, 1, 0); tl.ZIndex = 402
		Draggable(bar, win)
		canvas.Parent = win
		canvas.Position = UDim2.new(0, 10, 0, 34)
		canvas.Size = UDim2.new(1, -20, 1, -44)
		floating = { Frame = win, _shadow = winShadow }
	end)

	function preview:GetTab(name) for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end end
	function preview:Set(name, settings) local t = self:GetTab(name) if t then t:Set(settings) end end
	function preview:SetUser(id) loadUser(tonumber(id) or userId) end
	if preview.Tabs[1] then preview.Tabs[1]:Select() end
	return preview
end

do
	local W = 520
	local veil = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", Visible = false, ZIndex = 950, Parent = PopupLayer })
	local box = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(W, 52), Position = UDim2.new(0.5, 0, 0.22, 0), BackgroundTransparency = 0.04, ZIndex = 951, Parent = veil })
	Library:AddToRegistry(box, { BackgroundColor3 = "Main" }); Corner(box, 12)
	local bst = Create("UIStroke", { Thickness = 1, Transparency = 0.1, Parent = box }); Library:AddToRegistry(bst, { Color = "Outline" })
	local bedge = Create("UIStroke", { Thickness = 1, Transparency = 0.55, Parent = box }); Library:AddToRegistry(bedge, { Color = "Accent" })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = bedge })
	Shadow(box, 16)
	local icon = SearchIcon(box, 14, "FontDim"); icon.Position = UDim2.new(0, 16, 0, 19); icon.ZIndex = 952
	local input = Create("TextBox", { Size = UDim2.new(1, -120, 0, 52), Position = UDim2.new(0, 38, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "type a setting, action, or value...", TextSize = 14, FontFace = Library.FontFace, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 952, Parent = box })
	Library:AddToRegistry(input, { TextColor3 = "Font", PlaceholderColor3 = "FontDim" })
	local hint = Text(box, "esc to close", 10, false, "FontDim"); hint.TextXAlignment = Enum.TextXAlignment.Right; hint.Position = UDim2.new(1, -90, 0, 0); hint.Size = UDim2.new(0, 76, 0, 52); hint.ZIndex = 952
	local rule = Create("Frame", { Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 52), BackgroundTransparency = 0.5, BorderSizePixel = 0, Visible = false, ZIndex = 952, Parent = box })
	Library:AddToRegistry(rule, { BackgroundColor3 = "Outline" })
	local listF = Create("Frame", { Size = UDim2.new(1, -12, 0, 0), Position = UDim2.new(0, 6, 0, 58), BackgroundTransparency = 1, ZIndex = 952, Parent = box })
	Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listF })

	local open, rows, sel, results = false, {}, 1, {}
	local ROW = 36

	local function describe(e)
		local o = e.obj
		if not o then return "", "open" end
		if o.Type == "Toggle" then return o.Value and "on" or "off", "toggle" end
		if o.Type == "Button" then return "", "run" end
		if o.Type == "Slider" then return tostring(o.Value), "set" end
		if o.Type == "Dropdown" then
			if o.Multi then local n = 0 for _ in pairs(o.Value or {}) do n = n + 1 end return n .. " selected", "open" end
			return tostring(o.Value or "none"), "open"
		end
		return "", "open"
	end

	local paint
	local function search(q)
		q = string.lower(q or "")
		results = {}
		local num = tonumber(q:match("(-?%d+%.?%d*)%s*$"))
		local name = q
		if num then name = q:gsub("(-?%d+%.?%d*)%s*$", "") name = name:gsub("%s+$", "") end
		if name == "" and not num then paint() return end
		local scored = {}
		for _, e in ipairs(Library.SearchIndex) do
			local nm = string.lower(tostring(e.name or ""))
			local pt = string.lower(tostring(e.path or ""))
			local score = nil
			if name ~= "" then
				local a = nm:find(name, 1, true)
				local b = pt:find(name, 1, true)
				if a == 1 then score = 0 elseif a then score = 1 elseif b then score = 2 end
			end
			if score then
				if num and e.obj and e.obj.Type ~= "Slider" then score = score + 5 end
				scored[#scored + 1] = { e = e, s = score }
			end
		end
		table.sort(scored, function(a, b) if a.s ~= b.s then return a.s < b.s end return tostring(a.e.name) < tostring(b.e.name) end)
		for i = 1, math.min(8, #scored) do results[i] = scored[i].e end
		Library._paletteNum = num
		sel = 1
		paint()
	end

	paint = function()
		for _, r in ipairs(rows) do r.f:Destroy() end
		rows = {}
		local n = #results
		listF.Size = UDim2.new(1, -12, 0, n * (ROW + 2))
		box.Size = UDim2.fromOffset(W, 52 + (n > 0 and (n * (ROW + 2) + 12) or 0))
		rule.Visible = n > 0
		for i, e in ipairs(results) do
			local f = Create("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = (i == sel) and 0.93 or 1, AutoButtonColor = false, Text = "", LayoutOrder = i, ZIndex = 953, Parent = listF })
			Corner(f, 8)
			local nm = Text(f, e.name, 13, true); nm.Position = UDim2.new(0, 12, 0, 5); nm.Size = UDim2.new(1, -160, 0, 16); nm.ZIndex = 954
			local pt = Text(f, e.path, 10, false, "FontDim"); pt.Position = UDim2.new(0, 12, 0, 21); pt.Size = UDim2.new(1, -160, 0, 12); pt.ZIndex = 954
			local state, verb = describe(e)
			local st = Text(f, state, 11, true, (state == "on") and "Accent" or "FontDim"); st.TextXAlignment = Enum.TextXAlignment.Right; st.AnchorPoint = Vector2.new(1, 0.5); st.Position = UDim2.new(1, -70, 0.5, 0); st.Size = UDim2.new(0, 80, 0, 14); st.ZIndex = 954
			local vb = Create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(1, -10, 0.5, 0), BackgroundTransparency = 1, ZIndex = 954, Parent = f })
			Corner(vb, 6); local vs = Create("UIStroke", { Thickness = 1, Transparency = 0.4, Parent = vb }); Library:AddToRegistry(vs, { Color = (i == sel) and "Accent" or "Outline" })
			Pad(vb, 7, 7, 0, 0)
			local vt = Text(vb, verb, 10, true, (i == sel) and "Accent" or "FontDim"); vt.AutomaticSize = Enum.AutomaticSize.X; vt.Size = UDim2.new(0, 0, 1, 0); vt.ZIndex = 955
			f.MouseEnter:Connect(function() if sel ~= i then sel = i paint() end end)
			f.MouseButton1Click:Connect(function() sel = i Library:_PaletteRun() end)
			rows[i] = { f = f }
		end
	end

	function Library:_PaletteRun()
		local e = results[sel]
		if not e then return end
		local o = e.obj
		local num = self._paletteNum
		if o and o.Type == "Toggle" then
			o:SetValue(not o.Value)
			search(input.Text)
			return
		elseif o and o.Type == "Button" then
			o.Click()
			self:Notify({ Title = "ran", Description = e.name, Time = 2 })
		elseif o and o.Type == "Slider" and num then
			o:SetValue(num)
			search(input.Text)
			return
		else
			pcall(e.focus)
		end
		self:_PaletteClose()
	end

	function Library:_PaletteOpen()
		if open then return end
		open = true
		veil.Visible = true
		RaisePopup(veil)
		input.Text = ""
		results = {}
		paint()
		box.Position = UDim2.new(0.5, 0, 0.2, 0)
		Tween(box, { Position = UDim2.new(0.5, 0, 0.22, 0) }, 0.18, Enum.EasingStyle.Quint)
		Tween(veil, { BackgroundTransparency = 0.5 }, 0.15)
		task.defer(function() input:CaptureFocus() end)
	end
	function Library:_PaletteClose()
		if not open then return end
		open = false
		input:ReleaseFocus()
		Tween(veil, { BackgroundTransparency = 1 }, 0.12).Completed:Connect(function() if not open then veil.Visible = false end end)
	end
	function Library:TogglePalette() if open then self:_PaletteClose() else self:_PaletteOpen() end end

	local launcher = Create("TextButton", { AnchorPoint = Vector2.new(0, 1), Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.new(0, 16, 1, -16), BackgroundTransparency = 0.06, AutoButtonColor = false, Text = "", ZIndex = 300, Parent = ScreenGui })
	Library:AddToRegistry(launcher, { BackgroundColor3 = "Main" }); Corner(launcher, 9)
	local lst = Create("UIStroke", { Thickness = 1, Transparency = 0.15, Parent = launcher }); Library:AddToRegistry(lst, { Color = "Outline" })
	local ledge = Create("UIStroke", { Thickness = 1, Transparency = 0.6, Parent = launcher }); Library:AddToRegistry(ledge, { Color = "Accent" })
	Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = ledge })
	Pad(launcher, 10, 12, 0, 0)
	Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = launcher })
	local licon = SearchIcon(launcher, 13, "Accent"); licon.LayoutOrder = 1; licon.ZIndex = 301
	local ltext = Text(launcher, "commands", 11, true); ltext.LayoutOrder = 2; ltext.AutomaticSize = Enum.AutomaticSize.X; ltext.Size = UDim2.new(0, 0, 1, 0); ltext.ZIndex = 301
	local lkey = Create("Frame", { LayoutOrder = 3, Size = UDim2.new(0, 0, 0, 18), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 301, Parent = launcher })
	Library:AddToRegistry(lkey, { BackgroundColor3 = "Element" }); Corner(lkey, 5); Stroke(lkey, "Outline"); Pad(lkey, 6, 6, 0, 0)
	local lkt = Text(lkey, "ctrl k", 10, true, "FontDim"); lkt.AutomaticSize = Enum.AutomaticSize.X; lkt.Size = UDim2.new(0, 0, 1, 0); lkt.ZIndex = 302
	Hover(launcher, "Main", "ElementHover"); Ripple(launcher); Press(launcher, 0.96)
	launcher.MouseButton1Click:Connect(function() Library:TogglePalette() end)
	function Library:SetPaletteButtonVisible(on) launcher.Visible = on and true or false end

	input:GetPropertyChangedSignal("Text"):Connect(function() if open then search(input.Text) end end)
	veil.MouseButton1Click:Connect(function() Library:_PaletteClose() end)
	Library:GiveSignal(UserInputService.InputBegan:Connect(function(inp, gpe)
		if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if inp.KeyCode == Enum.KeyCode.K and ctrl then Library:TogglePalette() return end
		if not open then return end
		if inp.KeyCode == Enum.KeyCode.Escape then Library:_PaletteClose()
		elseif inp.KeyCode == Enum.KeyCode.Down then sel = math.min(sel + 1, math.max(#results, 1)) paint()
		elseif inp.KeyCode == Enum.KeyCode.Up then sel = math.max(sel - 1, 1) paint()
		elseif inp.KeyCode == Enum.KeyCode.Return or inp.KeyCode == Enum.KeyCode.KeypadEnter then Library:_PaletteRun() end
	end))
end

Library._onUnload = {}
function Library:OnUnload(fn) table.insert(self._onUnload, fn) end
function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	for _, fn in ipairs(self._onUnload) do pcall(fn) end
	for _, c in ipairs(self.Signals) do pcall(function() c:Disconnect() end) end
	stopSnow()
	pcall(function() Blur:Destroy() end)
	pcall(function() ScreenGui:Destroy() end)
end

return Library

end)()

local ThemeManager = (function()
local HttpService = game:GetService("HttpService")

local ThemeManager = {}
ThemeManager.Folder = "DexoriUI"
ThemeManager.Library = nil
ThemeManager.BuiltIn = {
	["Frostbite"] = { Background = "070a10", Main = "0b0f17", Element = "111722", ElementHover = "18202e", Accent = "60b2ff", AccentGradient = { "96d6ff", "2260be", 0 }, Outline = "1c2636", OutlineStrong = "2e568c", Font = "e2ebf5", FontDim = "7889a0", Risky = "ff6060" },
	["Dexori Red"] = { Background = "000000", Well = "000000", Main = "000000", Element = "000000", ElementHover = "0d0d0f", Accent = "d62830", AccentGradient = { "f33e46", "800e14", 0 }, Outline = "26262a", OutlineStrong = "48161a", Font = "e6e6e8", FontDim = "808088", Risky = "ff5050" },
	["Nightshade"] = { Background = "0b0810", Main = "100c18", Element = "171124", ElementHover = "1f1830", Accent = "9b59ff", AccentGradient = { "c08cff", "5e2bd6", 0 }, Outline = "231a33", OutlineStrong = "42288c", Font = "ece6f8", FontDim = "8b7fa8", Risky = "ff6b6b" },
	["Pine"] = { Background = "07100c", Main = "0b1712", Element = "10201a", ElementHover = "172c24", Accent = "34d399", AccentGradient = { "6ee7b7", "0f9268", 0 }, Outline = "173028", OutlineStrong = "1d6b4c", Font = "e4f3ec", FontDim = "76998a", Risky = "ff6b6b" },
	["Carbon"] = { Background = "09090a", Main = "0e0e10", Element = "141416", ElementHover = "1c1c20", Accent = "d8d8dc", AccentGradient = { "ffffff", "8c8c94", 0 }, Outline = "1f1f23", OutlineStrong = "3a3a42", Font = "f2f2f4", FontDim = "83838c", Risky = "ff5050" },
	["Ember"] = { Background = "100b07", Main = "17100a", Element = "20170f", ElementHover = "2c2016", Accent = "ff8a3d", AccentGradient = { "ffb066", "cc5a10", 0 }, Outline = "2e2114", OutlineStrong = "7a4416", Font = "f6ece2", FontDim = "a08a76", Risky = "ff6060" },
}

local function hexToColor(h)
	h = tostring(h):gsub("#", "")
	return Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 0, tonumber(h:sub(3, 4), 16) or 0, tonumber(h:sub(5, 6), 16) or 0)
end
local function colorToHex(c)
	return string.format("%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

function ThemeManager:SetLibrary(lib) self.Library = lib end
function ThemeManager:SetFolder(folder) self.Folder = folder self:BuildFolderTree() end
function ThemeManager:BuildFolderTree()
	pcall(function()
		if not isfolder(self.Folder) then makefolder(self.Folder) end
		if not isfolder(self.Folder .. "/themes") then makefolder(self.Folder .. "/themes") end
	end)
end

function ThemeManager:Serialize()
	local T = self.Library.Theme
	local out = {}
	for k, v in pairs(T) do
		if typeof(v) == "Color3" then out[k] = colorToHex(v)
		elseif typeof(v) == "ColorSequence" then
			local kp = v.Keypoints
			out[k] = { colorToHex(kp[1].Value), colorToHex(kp[#kp].Value), self._accentRotation or 0 }
		end
	end
	return out
end
function ThemeManager:ApplyData(data)
	local theme = {}
	for k, v in pairs(data) do
		if type(v) == "string" then theme[k] = hexToColor(v)
		elseif type(v) == "table" then
			theme[k] = ColorSequence.new(hexToColor(v[1]), hexToColor(v[2]))
			self._accentRotation = v[3] or 0
		end
	end
	self.Library:SetTheme(theme)
	if self._pickers then
		for k, p in pairs(self._pickers) do
			if theme[k] and typeof(theme[k]) == "Color3" then p:SetValueRGB(theme[k], nil, true)
			elseif theme[k] and typeof(theme[k]) == "ColorSequence" then
				p:SetValueRGB(theme[k].Keypoints[1].Value, nil, true); p:SetValue2(theme[k].Keypoints[#theme[k].Keypoints].Value, true); p:SetRotation(self._accentRotation or 0, true)
			end
		end
	end
end

function ThemeManager:ApplyTheme(name)
	local data = self.BuiltIn[name]
	if not data then
		local ok, raw = pcall(readfile, self.Folder .. "/themes/" .. name .. ".json")
		if ok and raw then local ok2, d = pcall(HttpService.JSONDecode, HttpService, raw) if ok2 then data = d end end
	end
	if data then self:ApplyData(data) self.Library:Notify({ Title = "Theme", Description = "Applied " .. name, Time = 3 }) end
end
function ThemeManager:SaveTheme(name)
	if not name or name == "" then return end
	self:BuildFolderTree()
	pcall(writefile, self.Folder .. "/themes/" .. name .. ".json", HttpService:JSONEncode(self:Serialize()))
	self.Library:Notify({ Title = "Theme", Description = "Saved " .. name, Time = 3 })
end
function ThemeManager:DeleteTheme(name)
	if not name or self.BuiltIn[name] then return false end
	pcall(delfile, self.Folder .. "/themes/" .. name .. ".json")
	self.Library:Notify({ Title = "Theme", Description = "Deleted " .. name, Time = 3 })
	return true
end
function ThemeManager:ListThemes()
	local out = {}
	for k in pairs(self.BuiltIn) do out[#out + 1] = k end
	table.sort(out)
	pcall(function()
		for _, f in ipairs(listfiles(self.Folder .. "/themes")) do
			local name = f:match("([^/\\]+)%.json$")
			if name then out[#out + 1] = name end
		end
	end)
	return out
end
function ThemeManager:SetDefaultTheme(name)
	pcall(writefile, self.Folder .. "/themes/default.txt", name)
end
function ThemeManager:LoadDefault()
	local ok, name = pcall(readfile, self.Folder .. "/themes/default.txt")
	if ok and name and name ~= "" then self:ApplyTheme(name) end
end

function ThemeManager:ApplyToTab(tab)
	local Library = self.Library
	self:BuildFolderTree()
	local gb = tab:AddLeftGroupbox("Theme")
	self._pickers = {}
	local keys = { { "Background", "Background" }, { "Well", "Content well" }, { "Main", "Panels" }, { "Element", "Elements" }, { "ElementHover", "Element hover" }, { "Accent", "Accent" }, { "Outline", "Outline" }, { "OutlineStrong", "Strong outline" }, { "Font", "Text" }, { "FontDim", "Dim text" }, { "Risky", "Risky / danger" } }
	for _, pair in ipairs(keys) do
		local key, label = pair[1], pair[2]
		local p = gb:AddColorPicker("Theme_" .. key, { Text = label, Default = Library.Theme[key], Callback = function(c) Library.Theme[key] = c Library:UpdateColorsUsingRegistry() end })
		self._pickers[key] = p
	end
	local accKp = Library.Theme.AccentGradient.Keypoints
	local gp = gb:AddColorPicker("Theme_AccentGradient", { Text = "Accent gradient", Gradient = true, Default = accKp[1].Value, Default2 = accKp[#accKp].Value, Rotation = 0, Callback = function(seq, rot)
		Library.Theme.AccentGradient = seq
		self._accentRotation = rot
		Library:UpdateColorsUsingRegistry()
		for inst, props in pairs(Library.Registry) do
			if props.Color == "AccentGradient" and inst:IsA("UIGradient") then inst.Rotation = rot end
		end
	end })
	self._pickers.AccentGradient = gp

	local gb2 = tab:AddRightGroupbox("Theme Manager")
	local list = gb2:AddDropdown("ThemeManager_List", { Text = "Themes", Values = self:ListThemes(), Default = 1, Searchable = true })
	local nameBox = gb2:AddInput("ThemeManager_Name", { Text = "Theme name", Placeholder = "my theme", Finished = true })
	gb2:AddButton({ Text = "Load", Func = function() if list.Value then self:ApplyTheme(list.Value) end end })
		:AddButton({ Text = "Set default", Func = function() if list.Value then self:SetDefaultTheme(list.Value) Library:Notify({ Title = "Theme", Description = "Default: " .. list.Value, Time = 3 }) end end })
	gb2:AddButton({ Text = "Save as", Func = function() self:SaveTheme(nameBox.Value) list:SetValues(self:ListThemes()) end })
		:AddButton({ Text = "Delete", Risky = true, DoubleClick = true, Func = function() if list.Value and self:DeleteTheme(list.Value) then list:SetValues(self:ListThemes()) end end })
	gb2:AddButton({ Text = "Reset to Frostbite", Func = function() self:ApplyTheme("Frostbite") end })
	gb2:AddButton({ Text = "Refresh list", Func = function() list:SetValues(self:ListThemes()) end })
	gb2:AddButton({ Text = "Print theme to console", Func = function()
		local T = self.Library.Theme
		local order = { "Background", "Well", "Main", "Element", "ElementHover", "Accent", "Outline", "OutlineStrong", "Font", "FontDim", "Risky" }
		local out = { "Theme = {" }
		for _, k in ipairs(order) do
			local c = T[k]
			out[#out + 1] = string.format("\t%s = Color3.fromRGB(%d, %d, %d),", k, math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
		end
		local g = T.AccentGradient.Keypoints
		local a, b = g[1].Value, g[#g].Value
		out[#out + 1] = string.format("\tAccentGradient = ColorSequence.new(Color3.fromRGB(%d, %d, %d), Color3.fromRGB(%d, %d, %d)),",
			math.floor(a.R * 255 + 0.5), math.floor(a.G * 255 + 0.5), math.floor(a.B * 255 + 0.5),
			math.floor(b.R * 255 + 0.5), math.floor(b.G * 255 + 0.5), math.floor(b.B * 255 + 0.5))
		out[#out + 1] = "}"
		print(table.concat(out, "\n"))
		self.Library:Notify({ Title = "Theme", Description = "printed to console - copy it from there", Time = 4 })
	end })
	self:LoadDefault()
end

return ThemeManager

end)()

local SaveManager = (function()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SaveManager = {}
SaveManager.Folder = "DexoriUI"
SaveManager.Ignore = {}
SaveManager.Library = nil
SaveManager.AutoSave = true
SaveManager.AutoSaveInterval = 30
SaveManager.Parser = {
	Toggle = {
		Save = function(idx, obj) return { type = "Toggle", idx = idx, value = obj.Value } end,
		Load = function(idx, data) local o = SaveManager.Library.Toggles[idx] if o then o:SetValue(data.value) end end,
	},
	Slider = {
		Save = function(idx, obj) return { type = "Slider", idx = idx, value = obj.Value } end,
		Load = function(idx, data) local o = SaveManager.Library.Options[idx] if o then o:SetValue(data.value) end end,
	},
	Dropdown = {
		Save = function(idx, obj) return { type = "Dropdown", idx = idx, value = obj.Value, multi = obj.Multi } end,
		Load = function(idx, data) local o = SaveManager.Library.Options[idx] if o then o:SetValue(data.value) end end,
	},
	ColorPicker = {
		Save = function(idx, obj) return { type = "ColorPicker", idx = idx, value = obj.Value:ToHex(), value2 = obj.Value2 and obj.Value2:ToHex() or nil, transparency = obj.Transparency, rotation = obj.Rotation } end,
		Load = function(idx, data)
			local o = SaveManager.Library.Options[idx]
			if o then
				o:SetValueRGB(Color3.fromHex(data.value), data.transparency, true)
				if data.value2 and o.SetValue2 then o:SetValue2(Color3.fromHex(data.value2), true) end
				if data.rotation and o.SetRotation then o:SetRotation(data.rotation, true) end
				if o.Callback then pcall(o.Callback, o.Gradient and o:GetSequence() or o.Value, o.Gradient and o.Rotation or o.Transparency) end
			end
		end,
	},
	KeyPicker = {
		Save = function(idx, obj) return { type = "KeyPicker", idx = idx, mode = obj.Mode, key = typeof(obj.Value) == "EnumItem" and obj.Value.Name or tostring(obj.Value) } end,
		Load = function(idx, data) local o = SaveManager.Library.Options[idx] if o then o:SetValue({ data.key, data.mode }) end end,
	},
	Input = {
		Save = function(idx, obj) return { type = "Input", idx = idx, text = obj.Value } end,
		Load = function(idx, data) local o = SaveManager.Library.Options[idx] if o then o:SetValue(data.text) end end,
	},
}

function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:SetIgnoreIndexes(list) for _, k in ipairs(list) do self.Ignore[k] = true end end
function SaveManager:IgnoreThemeSettings()
	self:SetIgnoreIndexes({ "ThemeManager_List", "ThemeManager_Name", "SaveManager_ConfigList", "SaveManager_ConfigName" })
	self._ignoreThemePrefix = true
end
function SaveManager:SetFolder(folder) self.Folder = folder self:BuildFolderTree() end
function SaveManager:BuildFolderTree()
	pcall(function()
		local parts = {}
		for seg in string.gmatch(self.Folder, "[^/\\]+") do
			parts[#parts + 1] = seg
			local p = table.concat(parts, "/")
			if not isfolder(p) then makefolder(p) end
		end
		if not isfolder(self.Folder .. "/settings") then makefolder(self.Folder .. "/settings") end
	end)
end
function SaveManager:_path(name) return self.Folder .. "/settings/" .. name .. ".json" end

function SaveManager:Save(name)
	if not name or name == "" then return false, "no config name" end
	self:BuildFolderTree()
	local data = { objects = {} }
	for idx, obj in pairs(self.Library.Toggles) do
		if not self.Ignore[idx] then data.objects[#data.objects + 1] = self.Parser.Toggle.Save(idx, obj) end
	end
	for idx, obj in pairs(self.Library.Options) do
		if not self.Ignore[idx] and not (self._ignoreThemePrefix and string.sub(idx, 1, 6) == "Theme_") then
			local p = self.Parser[obj.Type]
			if p then data.objects[#data.objects + 1] = p.Save(idx, obj) end
		end
	end
	local ok, enc = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return false, "encode failed" end
	local ok2 = pcall(writefile, self:_path(name), enc)
	if not ok2 then return false, "write failed" end
	return true
end

function SaveManager:Load(name)
	if not name or name == "" then return false, "no config name" end
	local ok, raw = pcall(readfile, self:_path(name))
	if not ok or not raw then return false, "config not found" end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok2 or type(data) ~= "table" then return false, "decode failed" end
	for _, entry in ipairs(data.objects or {}) do
		local p = self.Parser[entry.type]
		if p then pcall(p.Load, entry.idx, entry) end
	end
	self._current = name
	return true
end

function SaveManager:Delete(name)
	if not name or name == "" then return false end
	local ok = pcall(delfile, self:_path(name))
	if self._current == name then self._current = nil end
	return ok
end

function SaveManager:ListConfigs()
	local out = {}
	pcall(function()
		for _, f in ipairs(listfiles(self.Folder .. "/settings")) do
			local n = f:match("([^/\\]+)%.json$")
			if n then out[#out + 1] = n end
		end
	end)
	table.sort(out)
	return out
end

function SaveManager:SetAutoload(name) pcall(writefile, self.Folder .. "/settings/autoload.txt", name) end
function SaveManager:RemoveAutoload() pcall(delfile, self.Folder .. "/settings/autoload.txt") end
function SaveManager:GetAutoload()
	local ok, n = pcall(readfile, self.Folder .. "/settings/autoload.txt")
	if ok and n and n ~= "" then return n end
	return nil
end
function SaveManager:LoadAutoloadConfig()
	local n = self:GetAutoload()
	if n then
		local ok, err = self:Load(n)
		if ok then self.Library:Notify({ Title = "Config", Description = "Auto-loaded " .. n, Time = 3 })
		else self.Library:Notify({ Title = "Config", Description = "Autoload failed: " .. tostring(err), Time = 4 }) end
	end
end

function SaveManager:_autosaveNow(reason)
	if not self.AutoSave then return end
	local name = self._current or self:GetAutoload() or "autosave"
	local ok = self:Save(name)
	if ok and reason ~= "tick" then pcall(function() self.Library:Notify({ Title = "Config", Description = "Auto-saved " .. name, Time = 2 }) end) end
end
function SaveManager:StartAutoSave()
	if self._autoStarted then return end
	self._autoStarted = true
	task.spawn(function()
		while not self.Library.Unloaded do
			task.wait(self.AutoSaveInterval)
			if self.AutoSave then pcall(function() self:_autosaveNow("tick") end) end
		end
	end)
	pcall(function() LocalPlayer.OnTeleport:Connect(function() self:_autosaveNow("teleport") end) end)
	pcall(function() game:GetService("GuiService").ErrorMessageChanged:Connect(function() self:_autosaveNow("disconnect") end) end)
	pcall(function() Players.PlayerRemoving:Connect(function(p) if p == LocalPlayer then self:_autosaveNow("leave") end end) end)
	pcall(function() game.Close:Connect(function() self:_autosaveNow("close") end) end)
	self.Library:OnUnload(function() self:_autosaveNow("unload") end)
end

function SaveManager:BuildConfigSection(tab)
	assert(self.Library, "SaveManager: SetLibrary first")
	self:BuildFolderTree()
	local Library = self.Library
	local gb = tab:AddRightGroupbox("Configuration")
	local list = gb:AddDropdown("SaveManager_ConfigList", { Text = "Configs", Values = self:ListConfigs(), Default = 1, Searchable = true, AllowNull = true })
	local nameBox = gb:AddInput("SaveManager_ConfigName", { Text = "Config name", Placeholder = "name", Finished = true })
	local status = gb:AddLabel("Current: none | Autoload: " .. (self:GetAutoload() or "none"))
	local function refresh()
		list:SetValues(self:ListConfigs())
		status:SetText("Current: " .. (self._current or "none") .. " | Autoload: " .. (self:GetAutoload() or "none"))
	end
	gb:AddButton({ Text = "Create", Func = function()
		local n = nameBox.Value
		if n == "" then Library:Notify({ Title = "Config", Description = "Enter a name first", Time = 3 }) return end
		local ok, err = self:Save(n)
		if ok then self._current = n Library:Notify({ Title = "Config", Description = "Created " .. n, Time = 3 }) else Library:Notify({ Title = "Config", Description = tostring(err), Time = 3 }) end
		refresh()
	end }):AddButton({ Text = "Load", Func = function()
		local n = list.Value
		if not n then return end
		local ok, err = self:Load(n)
		Library:Notify({ Title = "Config", Description = ok and ("Loaded " .. n) or tostring(err), Time = 3 })
		refresh()
	end })
	gb:AddButton({ Text = "Overwrite", Func = function()
		local n = list.Value
		if not n then return end
		local ok, err = self:Save(n)
		if ok then self._current = n end
		Library:Notify({ Title = "Config", Description = ok and ("Overwrote " .. n) or tostring(err), Time = 3 })
		refresh()
	end }):AddButton({ Text = "Delete", Risky = true, DoubleClick = true, Func = function()
		local n = list.Value
		if not n then return end
		self:Delete(n)
		Library:Notify({ Title = "Config", Description = "Deleted " .. n, Time = 3 })
		refresh()
	end })
	gb:AddButton({ Text = "Set autoload", Func = function()
		local n = list.Value
		if not n then return end
		self:SetAutoload(n)
		Library:Notify({ Title = "Config", Description = "Autoload: " .. n, Time = 3 })
		refresh()
	end }):AddButton({ Text = "Remove autoload", Func = function()
		self:RemoveAutoload()
		Library:Notify({ Title = "Config", Description = "Autoload removed", Time = 3 })
		refresh()
	end })
	gb:AddToggle("SaveManager_AutoSave", { Text = "Auto save (on leave / every " .. self.AutoSaveInterval .. "s)", Default = true, Callback = function(v) self.AutoSave = v end })
	gb:AddButton({ Text = "Refresh list", Func = refresh })
	self:SetIgnoreIndexes({ "SaveManager_ConfigList", "SaveManager_ConfigName", "SaveManager_AutoSave" })
	self:StartAutoSave()
end

return SaveManager

end)()

local Cosmetics = (function()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Cosmetics = { Library = nil, On = {}, Colour = {}, Alpha = {}, Rainbow = false, CharAlpha = 0, _conn = nil, _items = {}, _folder = nil,
	Assets = {
		HaloMesh = 94295002298033,
		CircleOuter = 137530322837065,
		CircleInner = 90176716791462,
		FloorGlow = 88776888306340,
		StepRune = 117125626391152,
		StepShock = 102666008230203,
		StepSigil = 112751014108946,
	} }
local function assetId(n) n = tonumber(n) or 0 if n > 0 then return "rbxassetid://" .. n end return nil end

local DEFAULTS = {
	Halo = { colour = Color3.fromRGB(255, 215, 110), alpha = 0 },
	Circle = { colour = Color3.fromRGB(214, 40, 48), alpha = 0 },
	Field = { colour = Color3.fromRGB(214, 40, 48), alpha = 0.55 },
	Steps = { colour = Color3.fromRGB(214, 40, 48), alpha = 0 },
}
Cosmetics.StepStyle = "rune"
Cosmetics.StepSize = 2.6
Cosmetics.StepLife = 0.7
Cosmetics.StepJumpBurst = true
for k, v in pairs(DEFAULTS) do Cosmetics.Colour[k] = v.colour Cosmetics.Alpha[k] = v.alpha Cosmetics.On[k] = false end

local function getChar()
	local ch = LocalPlayer.Character
	if not ch then return nil end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local head = ch:FindFirstChild("Head")
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso")
	return ch, hrp, head, torso
end

function Cosmetics:SetLibrary(lib) self.Library = lib end

function Cosmetics:_folderRef()
	if self._folder and self._folder.Parent then return self._folder end
	self._folder = Instance.new("Folder")
	self._folder.Name = "_dexoriCosmetics"
	self._folder.Parent = Workspace
	return self._folder
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end
	return p
end

function Cosmetics:_buildHalo()
	local f = self:_folderRef()
	local mesh = assetId(self.Assets.HaloMesh)
	if mesh then
		local p = part({ Name = "_halo", Size = Vector3.new(1, 1, 1), Parent = f })
		local sm = Instance.new("SpecialMesh")
		sm.MeshType = Enum.MeshType.FileMesh
		sm.MeshId = mesh
		sm.Scale = Vector3.new(1.15, 1.15, 1.15)
		sm.Parent = p
		return { kind = "Halo", mesh = p }
	end
	local segs = {}
	local N, R = 28, 1.15
	for i = 1, N do
		local a = (i / N) * math.pi * 2
		local s = part({ Name = "_halo", Size = Vector3.new(0.34, 0.11, 0.11), Parent = f })
		segs[i] = { p = s, a = a }
	end
	local _ = R
	return { kind = "Halo", segs = segs, radius = R }
end

function Cosmetics:_buildCircle()
	local f = self:_folderRef()
	local outer, inner, glow = assetId(self.Assets.CircleOuter), assetId(self.Assets.CircleInner), assetId(self.Assets.FloorGlow)
	if outer or inner then
		local layers = {}
		local function layer(tex, size, spin, alphaBoost)
			local p = part({ Name = "_circle", Size = Vector3.new(size, 0.05, size), Transparency = 1, Material = Enum.Material.SmoothPlastic, Parent = f })
			local d = Instance.new("Decal")
			d.Face = Enum.NormalId.Top
			d.Texture = tex
			d.Parent = p
			layers[#layers + 1] = { p = p, d = d, spin = spin, alphaBoost = alphaBoost or 0 }
		end
		if glow then layer(glow, 9, 0, 0.5) end
		if outer then layer(outer, 7.2, 0.35) end
		if inner then layer(inner, 7.2, -0.6) end
		return { kind = "Circle", layers = layers }
	end
	local rings = {}
	for _, r in ipairs({ 3.2, 2.35 }) do
		local N = math.floor(r * 12)
		local segs = {}
		for i = 1, N do
			local a = (i / N) * math.pi * 2
			segs[i] = { p = part({ Name = "_circle", Size = Vector3.new((2 * math.pi * r) / N * 1.05, 0.05, 0.12), Parent = f }), a = a }
		end
		rings[#rings + 1] = { segs = segs, r = r }
	end
	local spokes = {}
	for i = 1, 6 do
		spokes[i] = { p = part({ Name = "_circle", Size = Vector3.new(2.35 * math.sqrt(3), 0.05, 0.09), Parent = f }), a = math.rad(i * 60) }
	end
	return { kind = "Circle", rings = rings, spokes = spokes }
end

function Cosmetics:_stepTexture()
	local key = ({ rune = "StepRune", shock = "StepShock", sigil = "StepSigil" })[self.StepStyle] or "StepRune"
	return assetId(self.Assets[key])
end

function Cosmetics:_spawnRing(pos, big)
	local f = self:_folderRef()
	local colour = self.Rainbow and Color3.fromHSV((os.clock() * 0.15) % 1, 0.85, 1) or self.Colour.Steps
	local size = self.StepSize * (big and 1.9 or 1)
	local life = self.StepLife * (big and 1.4 or 1)
	local tex = self:_stepTexture()
	local p = part({ Name = "_step", Size = Vector3.new(size * 0.55, 0.05, size * 0.55), Transparency = 1, Material = Enum.Material.SmoothPlastic, CFrame = CFrame.new(pos) * CFrame.Angles(0, math.random() * 6.28, 0), Parent = f })
	local decal
	if tex then
		decal = Instance.new("Decal")
		decal.Face = Enum.NormalId.Top
		decal.Texture = tex
		decal.Color3 = colour
		decal.Transparency = self.Alpha.Steps
		decal.Parent = p
	else
		p.Transparency = self.Alpha.Steps
		p.Material = Enum.Material.Neon
		p.Color = colour
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.05, size * 0.55, size * 0.55)
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	end
	task.spawn(function()
		local t0 = os.clock()
		local spin = (math.random() > 0.5 and 1 or -1) * 0.6
		while p.Parent do
			local t = (os.clock() - t0) / life
			if t >= 1 then break end
			local ease = 1 - (1 - t) ^ 3
			local s = size * (0.55 + 0.45 * ease)
			if tex then
				p.Size = Vector3.new(s, 0.05, s)
				p.CFrame = CFrame.new(pos + Vector3.new(0, 0.02 * ease, 0)) * CFrame.Angles(0, spin * t, 0)
				decal.Transparency = self.Alpha.Steps + (1 - self.Alpha.Steps) * (t ^ 1.6)
			else
				p.Size = Vector3.new(0.05, s, s)
				p.Transparency = self.Alpha.Steps + (1 - self.Alpha.Steps) * (t ^ 1.6)
			end
			task.wait()
		end
		pcall(function() p:Destroy() end)
	end)
end

function Cosmetics:_floorY(ch, hrp)
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local hip = (hum and hum.HipHeight > 0) and hum.HipHeight or 2
	local floorY = hrp.Position.Y - (hip + hrp.Size.Y * 0.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ch, self._folder }
	local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
	if hit then floorY = hit.Position.Y end
	return floorY
end

function Cosmetics:_buildSteps()
	local ch, hrp = getChar()
	local feet = {}
	if ch then
		for _, n in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
			local f = ch:FindFirstChild(n)
			if f then feet[#feet + 1] = { part = f, down = false } end
		end
	end
	local item = { kind = "Steps", feet = feet, lastLand = 0 }
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then
		item.stateConn = hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Landed and self.StepJumpBurst and hrp then
				local floorY = self:_floorY(ch, hrp)
				self:_spawnRing(Vector3.new(hrp.Position.X, floorY + 0.06, hrp.Position.Z), true)
				item.lastLand = os.clock()
			end
		end)
	end
	return item
end

function Cosmetics:_buildField()
	local f = self:_folderRef()
	local ball = part({ Name = "_field", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 9, 9), Material = Enum.Material.ForceField, Parent = f })
	return { kind = "Field", ball = ball }
end

function Cosmetics:_update(dt)
	local ch, hrp, head, torso = getChar()
	if not (ch and hrp) then return end
	local t = os.clock()
	local rainbow = self.Rainbow and Color3.fromHSV((t * 0.15) % 1, 0.85, 1) or nil

	for kind, item in pairs(self._items) do
		local colour = rainbow or self.Colour[kind]
		local alpha = self.Alpha[kind]
		if kind == "Halo" and head then
			local centre = head.CFrame * CFrame.new(0, 1.05 + math.sin(t * 1.4) * 0.06, 0)
			local spin = t * 0.8
			if item.mesh then
				item.mesh.CFrame = CFrame.new(centre.Position) * CFrame.Angles(0, spin, 0)
				item.mesh.Color = colour item.mesh.Transparency = alpha
			end
			for _, s in ipairs(item.segs or {}) do
				local a = s.a + spin
				s.p.CFrame = centre * CFrame.Angles(0, a, 0) * CFrame.new(item.radius, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
				s.p.Color = colour s.p.Transparency = alpha
			end
		elseif kind == "Circle" then
			local hum = ch:FindFirstChildOfClass("Humanoid")
			local hip = (hum and hum.HipHeight > 0) and hum.HipHeight or 2
			local floorY = hrp.Position.Y - (hip + hrp.Size.Y * 0.5)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { ch, self._folder }
			local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), params)
			if hit then floorY = hit.Position.Y end
			local floor = CFrame.new(hrp.Position.X, floorY + 0.08, hrp.Position.Z)
			if item.layers then
				for _, ly in ipairs(item.layers) do
					ly.p.CFrame = floor * CFrame.Angles(0, t * ly.spin, 0)
					ly.d.Color3 = colour
					ly.d.Transparency = math.clamp(alpha + ly.alphaBoost, 0, 1)
				end
			end
			for ri, ring in ipairs(item.rings or {}) do
				local spin = t * (ri == 1 and 0.6 or -0.9)
				for _, s in ipairs(ring.segs) do
					local a = s.a + spin
					s.p.CFrame = floor * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, ring.r) * CFrame.Angles(0, math.rad(90), 0)
					s.p.Color = colour s.p.Transparency = alpha
				end
			end
			for _, sp in ipairs(item.spokes or {}) do
				sp.p.CFrame = floor * CFrame.Angles(0, sp.a - t * 0.9, 0) * CFrame.new(0, 0, 2.35 * 0.5)
				sp.p.Color = colour sp.p.Transparency = alpha
			end
		elseif kind == "Steps" then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { ch, self._folder }
			for _, ft in ipairs(item.feet) do
				if ft.part.Parent then
					local hit = Workspace:Raycast(ft.part.Position, Vector3.new(0, -(ft.part.Size.Y * 0.5 + 0.35), 0), params)
					local onGround = hit ~= nil
					if onGround and not ft.down and os.clock() - item.lastLand > 0.15 then
						if hrp.AssemblyLinearVelocity.Magnitude > 2 then
							self:_spawnRing(Vector3.new(ft.part.Position.X, hit.Position.Y + 0.06, ft.part.Position.Z), false)
						end
					end
					ft.down = onGround
				end
			end
		elseif kind == "Field" then
			local s = 9 + math.sin(t * 1.6) * 0.25
			item.ball.Size = Vector3.new(s, s, s)
			item.ball.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, t * 0.3, 0)
			item.ball.Color = colour item.ball.Transparency = alpha
		end
	end

	if self.CharAlpha > 0 then
		for _, d in ipairs(ch:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.LocalTransparencyModifier = self.CharAlpha
			elseif d:IsA("Decal") then d.Transparency = self.CharAlpha end
		end
	end
end

function Cosmetics:_ensureLoop()
	if self._conn then return end
	self._conn = RunService.RenderStepped:Connect(function(dt) pcall(function() self:_update(dt) end) end)
end

function Cosmetics:_destroyItem(kind)
	local item = self._items[kind]
	if not item then return end
	local function kill(p) pcall(function() p:Destroy() end) end
	if item.segs then for _, s in ipairs(item.segs) do kill(s.p) end end
	if item.rings then for _, r in ipairs(item.rings) do for _, s in ipairs(r.segs) do kill(s.p) end end end
	if item.spokes then for _, s in ipairs(item.spokes) do kill(s.p) end end
	if item.ball then kill(item.ball) end
	if item.mesh then kill(item.mesh) end
	if item.layers then for _, ly in ipairs(item.layers) do kill(ly.p) end end
	if item.stateConn then pcall(function() item.stateConn:Disconnect() end) end
	self._items[kind] = nil
end

function Cosmetics:Set(kind, on)
	self.On[kind] = on and true or false
	self:_destroyItem(kind)
	if on then
		if kind == "Halo" then self._items[kind] = self:_buildHalo()
		elseif kind == "Circle" then self._items[kind] = self:_buildCircle()
		elseif kind == "Field" then self._items[kind] = self:_buildField()
		elseif kind == "Steps" then self._items[kind] = self:_buildSteps() end
		self:_ensureLoop()
	end
end

function Cosmetics:SetCharacterAlpha(a)
	self.CharAlpha = math.clamp(a or 0, 0, 1)
	if self.CharAlpha == 0 then
		local ch = LocalPlayer.Character
		if ch then
			for _, d in ipairs(ch:GetDescendants()) do
				if d:IsA("BasePart") then d.LocalTransparencyModifier = 0 elseif d:IsA("Decal") then d.Transparency = 0 end
			end
		end
	else
		self:_ensureLoop()
	end
end

function Cosmetics:Rebuild()
	for kind, on in pairs(self.On) do if on then self:Set(kind, true) end end
end

function Cosmetics:Stop()
	for kind in pairs(self._items) do self:_destroyItem(kind) end
	self:SetCharacterAlpha(0)
	if self._conn then self._conn:Disconnect() self._conn = nil end
	if self._folder then pcall(function() self._folder:Destroy() end) self._folder = nil end
end

Cosmetics.After = { On = false, Colour = Color3.fromRGB(255, 60, 60), Neon = true, Count = 3, Gap = 0.13, Life = 0.45, _hist = {}, _ghosts = {}, _conn = nil, _last = 0 }

local function snapshotPose(ch)

	local hrp = ch:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local pose = { root = hrp.CFrame, parts = {} }
	for _, d in ipairs(ch:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
			pose.parts[#pose.parts + 1] = { rel = hrp.CFrame:ToObjectSpace(d.CFrame), size = d.Size, part = d }
		end
	end
	return pose
end

function Cosmetics.After:_makeGhost()
	local ch = LocalPlayer.Character
	if not ch then return nil end
	local folder = Cosmetics:_folderRef()
	local model = Instance.new("Model")
	model.Name = "_afterghost"
	local slots = {}
	for _, d in ipairs(ch:GetChildren()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 1 then
			local clone
			if d:IsA("MeshPart") then
				clone = d:Clone()
				for _, c in ipairs(clone:GetChildren()) do c:Destroy() end
				clone.TextureID = ""
			else
				clone = d:Clone()
				for _, c in ipairs(clone:GetChildren()) do
					if not c:IsA("SpecialMesh") then c:Destroy() else c.TextureId = "" end
				end
			end
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CastShadow = false
			clone.Massless = true
			if self.Neon then clone.Material = Enum.Material.Neon end
			clone.Color = self.Colour
			clone.Parent = model
			slots[#slots + 1] = { clone = clone, src = d }
		end
	end
	model.Parent = folder
	return { model = model, slots = slots }
end

function Cosmetics.After:_apply(ghost, pose, alpha)
	local col = Cosmetics.Rainbow and Color3.fromHSV((os.clock() * 0.15) % 1, 0.85, 1) or self.Colour

	for i, slot in ipairs(ghost.slots) do
		local rec = pose.parts[i]
		if rec then
			slot.clone.CFrame = pose.root * rec.rel
			slot.clone.Transparency = alpha
			slot.clone.Color = col
		else
			slot.clone.Transparency = 1
		end
	end
end

function Cosmetics.After:Set(on)
	self.On = on
	if not on then
		for _, g in ipairs(self._ghosts) do pcall(function() g.model:Destroy() end) end
		self._ghosts = {}
		self._hist = {}
		if self._conn then self._conn:Disconnect() self._conn = nil end
		return
	end

	self._ghosts = {}
	for _ = 1, self.Count do
		local g = self:_makeGhost()
		if g then g.model:Destroy() end
	end
	self._conn = RunService.Heartbeat:Connect(function()
		if not self.On then return end
		local ch = LocalPlayer.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not (ch and hrp) then return end

		local moving = hrp.AssemblyLinearVelocity.Magnitude > 4
		local now = os.clock()
		if moving and now - self._last >= self.Gap then
			self._last = now
			local pose = snapshotPose(ch)
			if pose then
				local g = self:_makeGhost()
				if g then
					self:_apply(g, pose, 0.35)
					table.insert(self._ghosts, { model = g.model, slots = g.slots, born = now })
				end
			end
		end

		for i = #self._ghosts, 1, -1 do
			local gh = self._ghosts[i]
			local t = (now - gh.born) / self.Life
			if t >= 1 then
				pcall(function() gh.model:Destroy() end)
				table.remove(self._ghosts, i)
			else
				for _, slot in ipairs(gh.slots) do
					if slot.clone.Parent then slot.clone.Transparency = 0.35 + 0.65 * t end
				end
			end
		end
	end)
end

function Cosmetics:BuildTab(tab)
	local Library = self.Library
	local left = tab:AddLeftGroupbox("Cosmetics")
	local labels = { Halo = "halo", Circle = "magic circle", Field = "force field", Steps = "footstep rings" }
	for _, kind in ipairs({ "Halo", "Circle", "Field", "Steps" }) do
		left:AddToggle("Cosm_" .. kind, { Text = labels[kind], Default = false, Callback = function(v) self:Set(kind, v) end })
			:AddColorPicker("Cosm_" .. kind .. "_Colour", { Default = self.Colour[kind], Title = labels[kind] .. " colour", Callback = function(c) self.Colour[kind] = c end })
		left:AddSlider("Cosm_" .. kind .. "_Alpha", { Text = labels[kind] .. " transparency", Default = self.Alpha[kind], Min = 0, Max = 0.95, Rounding = 2, Callback = function(v) self.Alpha[kind] = v end })
	end
	left:AddDropdown("Cosm_StepStyle", { Text = "footstep style", Values = { "rune", "shock", "sigil" }, Default = 1, Callback = function(v)
		if type(v) == "table" then for k, on in pairs(v) do if on then v = k break end end end
		self.StepStyle = v
	end })
	left:AddSlider("Cosm_StepSize", { Text = "ring size", Default = 2.6, Min = 1, Max = 6, Rounding = 1, Suffix = " studs", Callback = function(v) self.StepSize = v end })
	left:AddSlider("Cosm_StepLife", { Text = "ring lifetime", Default = 0.7, Min = 0.2, Max = 2, Rounding = 2, Suffix = "s", Callback = function(v) self.StepLife = v end })
	left:AddToggle("Cosm_StepJump", { Text = "big ring on landing", Default = true, Callback = function(v) self.StepJumpBurst = v end })
	local right = tab:AddRightGroupbox("Character")
	right:AddSlider("Cosm_CharAlpha", { Text = "character transparency", Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) self:SetCharacterAlpha(v) end })
	right:AddToggle("Cosm_Rainbow", { Text = "rainbow cycle (all cosmetics)", Default = false, Callback = function(v) self.Rainbow = v end })
	right:AddButton({ Text = "clear everything", Risky = true, Func = function()
		for _, kind in ipairs({ "Halo", "Circle", "Field", "Steps" }) do
			local t = Library.Toggles["Cosm_" .. kind]
			if t then t:SetValue(false) end
		end
		local s = Library.Options.Cosm_CharAlpha
		if s then s:SetValue(0) end
	end })
	right:AddLabel("everything here is client side. only you can see it.", true)

	local fx = tab:AddLeftGroupbox("Effects")
	fx:AddToggle("Cosm_After", { Text = "afterimages (while moving)", Default = false, Callback = function(v) Cosmetics.After.Colour = self.After.Colour Cosmetics.After:Set(v) end })
		:AddColorPicker("Cosm_After_Colour", { Default = Cosmetics.After.Colour, Title = "afterimage colour", Callback = function(c) Cosmetics.After.Colour = c end })
	fx:AddSlider("Cosm_After_Gap", { Text = "spawn interval", Default = 0.13, Min = 0.05, Max = 0.4, Rounding = 2, Suffix = "s", Callback = function(v) Cosmetics.After.Gap = v end })
	fx:AddSlider("Cosm_After_Life", { Text = "fade time", Default = 0.45, Min = 0.2, Max = 1.2, Rounding = 2, Suffix = "s", Callback = function(v) Cosmetics.After.Life = v end })
	fx:AddToggle("Cosm_After_Neon", { Text = "neon glow", Default = true, Callback = function(v) Cosmetics.After.Neon = v end })

	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.5)
		self:Rebuild()
		if Cosmetics.After.On then Cosmetics.After:Set(false) Cosmetics.After:Set(true) end
	end)
	Library:OnUnload(function() self:Stop() Cosmetics.After:Set(false) end)
end

return Cosmetics

end)()

return { Library = Library, ThemeManager = ThemeManager, SaveManager = SaveManager, Cosmetics = Cosmetics }
