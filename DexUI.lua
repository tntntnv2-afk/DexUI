--[[
	DexUI  -  a custom UI library for Roblox exploit scripts
	Drop-in-shaped replacement for Obsidian: matches Library:CreateWindow / Window:AddTab /
	Tab:AddLeftGroupbox / Box:AddToggle|AddSlider|AddDropdown|AddInput|AddButton|AddLabel|
	AddDivider|AddKeyPicker, plus Toggles / Options global tables, Library:Notify,
	Library:AddDraggableLabel, Library:Unload / OnUnload, and a SaveManager.

	Goals over Obsidian:
	  - Mobile-first: large touch targets, drag by header, pinch-free scaling, a floating
	    open/close bubble, responsive sizing that fits phone screens.
	  - Cleaner look: rounded cards, soft shadows, accent glow, smooth tweens.
	  - Same API surface so existing scripts need (almost) no changes.

	Load with:  local Library = loadstring(game:HttpGet("<raw url>/DexUI.lua"))()
--]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")
local GuiService        = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

-- =========================================================================
-- Library root
-- =========================================================================
local Library = {
	Version       = "1.0.0",
	Toggles       = {},
	Options       = {},
	Windows       = {},
	Connections   = {},
	Unloaded      = false,
	_unloadCbs    = {},

	-- Obsidian-compatible scheme table (script sets Library.Scheme.AccentColor)
	Scheme = {
		BackgroundColor = Color3.fromRGB(12, 12, 12),
		MainColor       = Color3.fromRGB(20, 20, 20),
		CardColor       = Color3.fromRGB(26, 22, 23),
		AccentColor     = Color3.fromRGB(200, 30, 30),
		OutlineColor    = Color3.fromRGB(45, 12, 12),
		FontColor       = Color3.fromRGB(240, 240, 240),
		DimColor        = Color3.fromRGB(150, 120, 120),
		Font            = Enum.Font.GothamMedium,
	},

	ShowCustomCursor = false,
	MinSize = Vector2.new(300, 380),
}
Library.Toggles = Library.Toggles
Library.Options = Library.Options

-- expose the two global tables the way Obsidian does
local Toggles = Library.Toggles
local Options = Library.Options

-- =========================================================================
-- utilities
-- =========================================================================
local function isMobile()
	local ok, touch = pcall(function() return UserInputService.TouchEnabled end)
	local ok2, kb = pcall(function() return UserInputService.KeyboardEnabled end)
	-- treat as mobile when touch is on and there is no keyboard/mouse
	return (ok and touch) and not (ok2 and kb)
end
Library.IsMobile = isMobile()

local function conn(signal, fn)
	local c = signal:Connect(fn)
	Library.Connections[#Library.Connections + 1] = c
	return c
end

local function tween(obj, ti, props)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end
local FAST  = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SMOOTH= TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function new(class, props, children)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then o[k] = v end
		end
	end
	if children then
		for _, c in ipairs(children) do c.Parent = o end
	end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end

local function corner(parent, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = parent })
end
local function stroke(parent, color, thick, transparency)
	return new("UIStroke", {
		Color = color or Library.Scheme.OutlineColor,
		Thickness = thick or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end
local function pad(parent, all, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or all or 0),
		PaddingRight = UDim.new(0, r or all or 0),
		PaddingTop = UDim.new(0, t or all or 0),
		PaddingBottom = UDim.new(0, b or all or 0),
		Parent = parent,
	})
end
local function listLayout(parent, spacing, dir)
	return new("UIListLayout", {
		Padding = UDim.new(0, spacing or 6),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = parent,
	})
end

-- protect the gui (executor-dependent, best-effort)
local function protect(gui)
	pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui)
		elseif protect_gui then protect_gui(gui) end
	end)
	local ok = false
	pcall(function()
		if gethui then gui.Parent = gethui(); ok = true end
	end)
	if not ok then
		pcall(function() gui.Parent = CoreGui end)
	end
end

-- =========================================================================
-- Root ScreenGui
-- =========================================================================
local ScreenGui = new("ScreenGui", {
	Name = "DexUI_" .. tostring(math.random(1000, 9999)),
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 9999,
})
protect(ScreenGui)
Library.ScreenGui = ScreenGui

-- notifications holder (top-right, or top-center on mobile)
local NotifyHolder = new("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Size = UDim2.new(0, 300, 1, -28),
	Parent = ScreenGui,
})
new("UIListLayout", {
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Top,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = NotifyHolder,
})

-- =========================================================================
-- Notify
-- =========================================================================
function Library:Notify(a, b, c)
	-- accept Obsidian styles: Notify({Title=,Description=,Time=}) OR Notify(text, duration)
	local title, desc, dur
	if type(a) == "table" then
		title = a.Title; desc = a.Description or a.Text or ""; dur = a.Time or 5
	else
		title = nil; desc = tostring(a or ""); dur = tonumber(b) or 5
	end

	local card = new("Frame", {
		BackgroundColor3 = Library.Scheme.MainColor,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		Parent = NotifyHolder,
		ClipsDescendants = true,
	})
	corner(card, 10)
	stroke(card, Library.Scheme.OutlineColor, 1, 0.2)
	-- accent bar
	local bar = new("Frame", {
		BackgroundColor3 = Library.Scheme.AccentColor,
		Size = UDim2.new(0, 3, 1, -14),
		Position = UDim2.new(0, 0, 0, 7),
		BorderSizePixel = 0,
		Parent = card,
	})
	corner(bar, 3)
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 14, 0, 0), Parent = card })
	pad(inner, nil, 0, 8, 10, 10)
	listLayout(inner, 3)
	if title and title ~= "" then
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
			Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Library.Scheme.AccentColor,
			TextXAlignment = Enum.TextXAlignment.Left, Text = title, Parent = inner,
		})
	end
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = Library.Scheme.Font, TextSize = 13, TextColor3 = Library.Scheme.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Text = desc, Parent = inner,
	})

	-- slide in
	card.Position = UDim2.new(1, 30, 0, 0)
	tween(card, SMOOTH, { Position = UDim2.new(0, 0, 0, 0) })

	task.delay(dur, function()
		if card and card.Parent then
			tween(card, FAST, { BackgroundTransparency = 1 })
			for _, d in ipairs(card:GetDescendants()) do
				pcall(function()
					if d:IsA("TextLabel") then tween(d, FAST, { TextTransparency = 1 }) end
					if d:IsA("UIStroke") then tween(d, FAST, { Transparency = 1 }) end
					if d:IsA("Frame") then tween(d, FAST, { BackgroundTransparency = 1 }) end
				end)
			end
			task.wait(0.16)
			card:Destroy()
		end
	end)
	return card
end

-- =========================================================================
-- Unload
-- =========================================================================
function Library:OnUnload(cb) self._unloadCbs[#self._unloadCbs + 1] = cb end
function Library:Unload()
	if self.Unloaded then return end
	self.Unloaded = true
	for _, cb in ipairs(self._unloadCbs) do pcall(cb) end
	for _, c in ipairs(self.Connections) do pcall(function() c:Disconnect() end) end
	pcall(function() ScreenGui:Destroy() end)
end
-- Obsidian compat no-ops / passthroughs
function Library:UpdateColorsUsingRegistry() end
function Library:SetWatermark() end

-- =========================================================================
-- Icon mapping (lucide-style names -> Roblox asset ids)
-- =========================================================================
local ICONS = {
	sword    = 10709806778, swords = 10709807303, gift = 10709788037,
	package  = 10723380948, castle = 10709752591, settings = 10734950309,
	home     = 10723345094, star = 10734949856, zap = 10723415903,
	shield   = 10747384394, users = 10747374057, box = 10723380948,
	crosshair= 10709790592, target = 10747375962, flame = 10723345348,
	list     = 10734896206, wrench = 10734961102, bell = 10723345301,
}
local function iconId(name)
	if type(name) == "number" then return name end
	if type(name) == "string" then
		local n = tonumber(name)
		if n then return n end
		return ICONS[name:lower()] or 10723370199 -- generic dot fallback
	end
	return 10723370199
end
_G.__dexui_icon = iconId

-- =========================================================================
-- ELEMENT BUILDERS  (attached to each Box via require_elements)
--   populate Library.Toggles[idx] / Library.Options[idx] like Obsidian.
-- =========================================================================
function require_elements(Box, Library, H)
	local new, corner, stroke, pad = H.new, H.corner, H.stroke, H.pad
	local listLayout, tween, FAST, SMOOTH, conn = H.listLayout, H.tween, H.FAST, H.SMOOTH, H.conn
	local scheme = H.scheme
	local parent = Box._container
	local MOBILE = Library.IsMobile
	local ROWH = MOBILE and 38 or 30

	local function nextOrder() Box._order = (Box._order or 1) + 1; return Box._order end

	-- shared row wrapper with a left-aligned label
	local function row(height)
		local f = new("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, height or ROWH),
			LayoutOrder = nextOrder(),
			Parent = parent,
		})
		return f
	end

	-- ---------- Toggle ----------
	function Box:AddToggle(idx, opts)
		opts = opts or {}
		local default = opts.Default == true
		local f = row(ROWH)
		local lbl = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -56, 1, 0),
			Font = scheme.Font, TextSize = MOBILE and 15 or 13, TextColor3 = scheme.FontColor,
			TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text or idx, Parent = f,
		})
		-- switch track
		local trackW, trackH = (MOBILE and 46 or 40), (MOBILE and 24 or 20)
		local track = new("Frame", {
			BackgroundColor3 = scheme.CardColor,
			Size = UDim2.fromOffset(trackW, trackH),
			Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
			Parent = f,
		})
		corner(track, trackH / 2)
		stroke(track, scheme.OutlineColor, 1, 0.2)
		local knob = new("Frame", {
			BackgroundColor3 = scheme.DimColor,
			Size = UDim2.fromOffset(trackH - 6, trackH - 6),
			Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
			Parent = track,
		})
		corner(knob, (trackH - 6) / 2)
		local btn = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = "", Parent = f })

		local Toggle = { Value = default, Type = "Toggle", Callback = opts.Callback }
		function Toggle:SetValue(v)
			v = v and true or false
			self.Value = v
			if v then
				tween(track, FAST, { BackgroundColor3 = scheme.AccentColor })
				tween(knob, FAST, { Position = UDim2.new(1, -3, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5) })
				knob.BackgroundColor3 = Color3.new(1, 1, 1)
			else
				tween(track, FAST, { BackgroundColor3 = scheme.CardColor })
				tween(knob, FAST, { Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5) })
				knob.BackgroundColor3 = scheme.DimColor
			end
			if self.Callback then pcall(self.Callback, v) end
		end
		function Toggle:OnChanged(fn) self.Callback = fn end
		conn(btn.MouseButton1Click, function() Toggle:SetValue(not Toggle.Value) end)

		Library.Toggles[idx] = Toggle
		-- apply default (visual only, no callback spam at build — but Obsidian fires it; we set silently)
		if default then
			track.BackgroundColor3 = scheme.AccentColor
			knob.Position = UDim2.new(1, -3, 0.5, 0); knob.AnchorPoint = Vector2.new(1, 0.5)
			knob.BackgroundColor3 = Color3.new(1, 1, 1)
		end
		return Box
	end

	-- ---------- Slider ----------
	function Box:AddSlider(idx, opts)
		opts = opts or {}
		local min, max = opts.Min or 0, opts.Max or 100
		local default = math.clamp(opts.Default or min, min, max)
		local rounding = opts.Rounding or 0
		local suffix = opts.Suffix or ""
		local function roundv(v)
			local m = 10 ^ rounding
			return math.floor(v * m + 0.5) / m
		end

		local f = row((MOBILE and 52 or 44))
		local top = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MOBILE and 20 or 16), Parent = f })
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -70, 1, 0),
			Font = scheme.Font, TextSize = MOBILE and 15 or 13, TextColor3 = scheme.FontColor,
			TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text or idx, Parent = top,
		})
		local valLbl = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(0, 70, 1, 0), Position = UDim2.new(1, -70, 0, 0),
			Font = Enum.Font.GothamBold, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.AccentColor,
			TextXAlignment = Enum.TextXAlignment.Right, Text = tostring(roundv(default)) .. suffix, Parent = top,
		})
		local barBG = new("Frame", {
			BackgroundColor3 = scheme.CardColor,
			Size = UDim2.new(1, 0, 0, MOBILE and 8 or 6),
			Position = UDim2.new(0, 0, 1, MOBILE and -12 or -8),
			Parent = f,
		})
		corner(barBG, 4)
		local fill = new("Frame", {
			BackgroundColor3 = scheme.AccentColor,
			Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
			Parent = barBG,
		})
		corner(fill, 4)
		local hit = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MOBILE and 26 or 20), Position = UDim2.new(0, 0, 1, MOBILE and -22 or -16), Text = "", Parent = f })

		local Slider = { Value = roundv(default), Type = "Slider", Callback = opts.Callback, Min = min, Max = max }
		local function setFromScale(s)
			s = math.clamp(s, 0, 1)
			local v = roundv(min + (max - min) * s)
			Slider.Value = v
			fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
			valLbl.Text = tostring(v) .. suffix
			if Slider.Callback then pcall(Slider.Callback, v) end
		end
		function Slider:SetValue(v)
			v = math.clamp(v, min, max)
			setFromScale((v - min) / (max - min))
		end
		function Slider:OnChanged(fn) self.Callback = fn end

		local dragging = false
		local function updateFromInput(inputX)
			local rel = (inputX - barBG.AbsolutePosition.X) / barBG.AbsoluteSize.X
			setFromScale(rel)
		end
		conn(hit.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; updateFromInput(input.Position.X)
			end
		end)
		conn(hit.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end)
		conn(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromInput(input.Position.X)
			end
		end)

		Library.Options[idx] = Slider
		return Box
	end

	-- ---------- Dropdown ----------
	function Box:AddDropdown(idx, opts)
		opts = opts or {}
		local values = opts.Values or {}
		local multi = opts.Multi == true
		local f = row((MOBILE and 44 or 36))
		if opts.Text and opts.Text ~= "" then
			new("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MOBILE and 18 or 15),
				Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.DimColor,
				TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text, Parent = f,
			})
			f.Size = UDim2.new(1, 0, 0, (MOBILE and 44 or 36) + (MOBILE and 18 or 15))
		end
		local ddBtn = new("TextButton", {
			BackgroundColor3 = scheme.CardColor,
			Size = UDim2.new(1, 0, 0, MOBILE and 38 or 30),
			Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1),
			Text = "", AutoButtonColor = false, Parent = f,
		})
		corner(ddBtn, 7)
		stroke(ddBtn, scheme.OutlineColor, 1, 0.2)
		local ddText = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 10, 0, 0),
			Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.FontColor,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "...", Parent = ddBtn,
		})
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -26, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5), Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = scheme.DimColor, Text = "\u{25BC}", Parent = ddBtn,
		})

		local Dropdown = { Value = multi and {} or nil, Type = "Dropdown", Callback = opts.Callback, Values = values, Multi = multi }

		local function refreshText()
			if multi then
				local sel = {}
				for k, on in pairs(Dropdown.Value) do if on then sel[#sel + 1] = k end end
				ddText.Text = #sel > 0 and table.concat(sel, ", ") or "None"
			else
				ddText.Text = tostring(Dropdown.Value or "...")
			end
		end

		-- popup list (built on demand, overlay at window level)
		local open = false
		local popup
		local function closePopup()
			open = false
			if popup then popup:Destroy(); popup = nil end
		end
		local function openPopup()
			if open then closePopup(); return end
			open = true
			popup = new("Frame", {
				BackgroundColor3 = scheme.MainColor,
				Size = UDim2.new(0, ddBtn.AbsoluteSize.X, 0, 0),
				Position = UDim2.fromOffset(ddBtn.AbsolutePosition.X, ddBtn.AbsolutePosition.Y + ddBtn.AbsoluteSize.Y + 4),
				AutomaticSize = Enum.AutomaticSize.Y, Parent = Library.ScreenGui, ZIndex = 50,
			})
			corner(popup, 7); stroke(popup, scheme.OutlineColor, 1, 0.1)
			local scroll = new("ScrollingFrame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
				ZIndex = 51, Parent = popup,
			})
			pad(scroll, 4); listLayout(scroll, 3)
			for _, v in ipairs(values) do
				local optBtn = new("TextButton", {
					BackgroundColor3 = scheme.CardColor, BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, MOBILE and 34 or 28), Text = "", AutoButtonColor = false,
					ZIndex = 52, Parent = scroll,
				})
				corner(optBtn, 6)
				local ol = new("TextLabel", {
					BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 10, 0, 0),
					Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.FontColor,
					TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(v), ZIndex = 52, Parent = optBtn,
				})
				local function markSel()
					local isSel = multi and Dropdown.Value[v] or (Dropdown.Value == v)
					optBtn.BackgroundTransparency = isSel and 0 or 1
					ol.TextColor3 = isSel and scheme.AccentColor or scheme.FontColor
				end
				markSel()
				conn(optBtn.MouseButton1Click, function()
					if multi then
						Dropdown.Value[v] = not Dropdown.Value[v]
						markSel(); refreshText()
						if Dropdown.Callback then pcall(Dropdown.Callback, Dropdown.Value) end
					else
						Dropdown.Value = v
						refreshText(); closePopup()
						if Dropdown.Callback then pcall(Dropdown.Callback, v) end
					end
				end)
			end
		end
		conn(ddBtn.MouseButton1Click, openPopup)

		function Dropdown:SetValue(v)
			if multi and type(v) == "table" then self.Value = v else self.Value = v end
			refreshText()
			if self.Callback then pcall(self.Callback, self.Value) end
		end
		function Dropdown:SetValues(vals) self.Values = vals; values = vals end
		function Dropdown:OnChanged(fn) self.Callback = fn end

		-- apply default
		if opts.Default then
			if type(opts.Default) == "number" and values[opts.Default] ~= nil then
				Dropdown.Value = values[opts.Default]
			elseif multi and type(opts.Default) == "table" then
				Dropdown.Value = opts.Default
			else
				Dropdown.Value = opts.Default
			end
		end
		refreshText()

		Library.Options[idx] = Dropdown
		return Box
	end

	-- ---------- Input ----------
	function Box:AddInput(idx, opts)
		opts = opts or {}
		local f = row((MOBILE and 60 or 50))
		if opts.Text and opts.Text ~= "" then
			new("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, MOBILE and 18 or 15),
				Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.DimColor,
				TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text, Parent = f,
			})
		end
		local boxF = new("Frame", {
			BackgroundColor3 = scheme.CardColor, Size = UDim2.new(1, 0, 0, MOBILE and 38 or 30),
			Position = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0, 1), Parent = f,
		})
		corner(boxF, 7); stroke(boxF, scheme.OutlineColor, 1, 0.2)
		local tb = new("TextBox", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0),
			Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.FontColor,
			PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = scheme.DimColor,
			TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
			Text = opts.Default or "", Parent = boxF,
		})

		local Input = { Value = opts.Default or "", Type = "Input", Callback = opts.Callback }
		function Input:SetValue(v) self.Value = tostring(v); tb.Text = self.Value; if self.Callback then pcall(self.Callback, self.Value) end end
		function Input:OnChanged(fn) self.Callback = fn end

		local function fire()
			local v = tb.Text
			if opts.Numeric then v = v:gsub("[^%d%.%-]", "") end
			Input.Value = v
			if Input.Callback then pcall(Input.Callback, v) end
		end
		if opts.Finished then
			conn(tb.FocusLost, function(enter) if enter or true then fire() end end)
		else
			conn(tb:GetPropertyChangedSignal("Text"), fire)
		end

		Library.Options[idx] = Input
		return Box
	end

	-- ---------- Button ----------
	function Box:AddButton(opts, maybeFunc)
		opts = opts or {}
		-- Obsidian supports AddButton({Text=,Func=}) or AddButton(text, func)
		local text, func, risky
		if type(opts) == "table" then text = opts.Text; func = opts.Func or opts.Callback; risky = opts.Risky
		else text = opts; func = maybeFunc end
		local f = row((MOBILE and 40 or 34))
		local b = new("TextButton", {
			BackgroundColor3 = risky and Color3.fromRGB(120, 25, 25) or scheme.CardColor,
			Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false, Parent = f,
		})
		corner(b, 7); stroke(b, scheme.OutlineColor, 1, 0.2)
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
			Font = Enum.Font.GothamMedium, TextSize = MOBILE and 15 or 13,
			TextColor3 = scheme.FontColor, Text = text or "Button", Parent = b,
		})
		conn(b.MouseButton1Click, function() if func then pcall(func) end end)
		conn(b.MouseEnter, function() tween(b, FAST, { BackgroundColor3 = risky and Color3.fromRGB(160, 30, 30) or scheme.AccentColor }) end)
		conn(b.MouseLeave, function() tween(b, FAST, { BackgroundColor3 = risky and Color3.fromRGB(120, 25, 25) or scheme.CardColor }) end)
		local Button = { Type = "Button" }
		function Button:AddButton() return Box end -- allow chaining sub-buttons (compat)
		return Box
	end

	-- ---------- Label ----------
	function Box:AddLabel(text, wrap)
		local f = row(0)
		f.AutomaticSize = Enum.AutomaticSize.Y
		f.Size = UDim2.new(1, 0, 0, 0)
		local l = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Font = scheme.Font, TextSize = MOBILE and 14 or 12, TextColor3 = scheme.DimColor,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = (wrap ~= false),
			RichText = true, Text = text or "", Parent = f,
		})
		local Label = { Type = "Label", TextLabel = l }
		function Label:SetText(t) l.Text = t end
		return Box
	end

	-- ---------- Divider ----------
	function Box:AddDivider()
		local f = row(8)
		new("Frame", { BackgroundColor3 = scheme.OutlineColor, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0, Parent = f })
		return Box
	end

	-- ---------- KeyPicker ----------
	function Box:AddKeyPicker(idx, opts)
		opts = opts or {}
		local f = row(ROWH)
		new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0),
			Font = scheme.Font, TextSize = MOBILE and 15 or 13, TextColor3 = scheme.FontColor,
			TextXAlignment = Enum.TextXAlignment.Left, Text = opts.Text or idx, Parent = f,
		})
		local keyBtn = new("TextButton", {
			BackgroundColor3 = scheme.CardColor, Size = UDim2.fromOffset(76, MOBILE and 30 or 24),
			Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
			Font = Enum.Font.GothamBold, TextSize = MOBILE and 13 or 11, TextColor3 = scheme.FontColor,
			Text = tostring(opts.Default or "None"), AutoButtonColor = false, Parent = f,
		})
		corner(keyBtn, 6); stroke(keyBtn, scheme.OutlineColor, 1, 0.2)

		local KeyPicker = { Value = opts.Default, Type = "KeyPicker", Callback = opts.Callback }
		local listening = false
		conn(keyBtn.MouseButton1Click, function()
			listening = true; keyBtn.Text = "..."
			keyBtn.TextColor3 = scheme.AccentColor
		end)
		conn(UserInputService.InputBegan, function(input, gpe)
			if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
				listening = false
				KeyPicker.Value = input.KeyCode.Name
				keyBtn.Text = input.KeyCode.Name; keyBtn.TextColor3 = scheme.FontColor
				if KeyPicker.Callback then pcall(KeyPicker.Callback, input.KeyCode) end
			end
		end)
		function KeyPicker:SetValue(v) self.Value = v; keyBtn.Text = tostring(v) end
		function KeyPicker:OnChanged(fn) self.Callback = fn end

		Library.Options[idx] = KeyPicker
		return Box
	end

	return Box
end

-- =========================================================================
-- Draggable helper (works with touch + mouse)
-- =========================================================================
local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	conn(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			local ended
			ended = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					ended:Disconnect()
				end
			end)
		end
	end)
	conn(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- =========================================================================
-- Window
-- =========================================================================
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local scheme = self.Scheme

	-- responsive size: on mobile, fit the viewport
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local wantW = (cfg.Size and cfg.Size.X.Offset) or 720
	local wantH = (cfg.Size and cfg.Size.Y.Offset) or 600
	local W, H
	if Library.IsMobile then
		W = math.min(wantW, vp.X - 24)
		H = math.min(wantH, vp.Y - 90)
		W = math.max(W, 300); H = math.max(H, 340)
	else
		W = wantW; H = wantH
	end

	local Window = { Tabs = {}, _tabOrder = {} }

	-- root frame
	local root = new("Frame", {
		Name = "Window",
		BackgroundColor3 = scheme.BackgroundColor,
		Size = UDim2.fromOffset(W, H),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Visible = (cfg.AutoShow ~= false),
		Parent = ScreenGui,
	})
	corner(root, 14)
	stroke(root, scheme.OutlineColor, 1.5, 0.1)
	new("UIScale", { Name = "WinScale", Parent = root })
	Window.Root = root

	-- soft drop shadow
	local shadow = new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.3,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		Size = UDim2.new(1, 60, 1, 60),
		Position = UDim2.new(0, -30, 0, -30),
		ZIndex = 0,
		Parent = root,
	})

	-- ===== Header =====
	local HEADER_H = Library.IsMobile and 52 or 46
	local header = new("Frame", {
		Name = "Header",
		BackgroundColor3 = scheme.MainColor,
		Size = UDim2.new(1, 0, 0, HEADER_H),
		BorderSizePixel = 0,
		Parent = root,
	})
	corner(header, 14)
	-- mask the bottom corners of the header
	new("Frame", { BackgroundColor3 = scheme.MainColor, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), Parent = header })
	makeDraggable(root, header)

	-- icon
	local titleX = 14
	if cfg.Icon then
		local iconImg = "rbxassetid://" .. tostring(cfg.Icon)
		local ic = new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = iconImg,
			Size = UDim2.fromOffset(HEADER_H - 20, HEADER_H - 20),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = header,
		})
		titleX = 12 + (HEADER_H - 20) + 8
	end
	-- title text
	new("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold, TextSize = Library.IsMobile and 17 or 15,
		TextColor3 = scheme.FontColor, TextXAlignment = Enum.TextXAlignment.Left,
		Text = (cfg.Title ~= nil and cfg.Title ~= "") and cfg.Title or "Dexori",
		Position = UDim2.new(0, titleX, 0, 0), Size = UDim2.new(1, -titleX - 90, 1, 0),
		Parent = header,
	})

	-- close/hide button (big on mobile)
	local btnSize = Library.IsMobile and 34 or 26
	local closeBtn = new("TextButton", {
		BackgroundColor3 = scheme.CardColor,
		Size = UDim2.fromOffset(btnSize, btnSize),
		Position = UDim2.new(1, -btnSize - 12, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Font = Enum.Font.GothamBold, Text = "\u{2715}", TextSize = Library.IsMobile and 15 or 13,
		TextColor3 = scheme.DimColor, AutoButtonColor = false,
		Parent = header,
	})
	corner(closeBtn, 7)
	conn(closeBtn.MouseButton1Click, function() Window:Toggle() end)
	conn(closeBtn.MouseEnter, function() tween(closeBtn, FAST, { BackgroundColor3 = scheme.AccentColor }); closeBtn.TextColor3 = scheme.FontColor end)
	conn(closeBtn.MouseLeave, function() tween(closeBtn, FAST, { BackgroundColor3 = scheme.CardColor }); closeBtn.TextColor3 = scheme.DimColor end)

	-- ===== Body: tab rail + content =====
	local RAIL_W = Library.IsMobile and 128 or 150
	local body = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -HEADER_H),
		Position = UDim2.new(0, 0, 0, HEADER_H),
		Parent = root,
	})

	local rail = new("Frame", {
		Name = "TabRail",
		BackgroundColor3 = scheme.MainColor,
		Size = UDim2.new(0, RAIL_W, 1, 0),
		BorderSizePixel = 0,
		Parent = body,
	})
	local railScroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = rail,
	})
	pad(railScroll, nil, 8, 8, 10, 10)
	listLayout(railScroll, 6)

	local content = new("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -RAIL_W, 1, 0),
		Position = UDim2.new(0, RAIL_W, 0, 0),
		Parent = body,
	})

	Window._content = content
	Window._rail = railScroll

	-- ===== Toggle visibility (with keybind + mobile bubble) =====
	Window._visible = (cfg.AutoShow ~= false)
	function Window:Toggle(force)
		local target = force
		if target == nil then target = not self._visible end
		self._visible = target
		root.Visible = true
		local sc = root:FindFirstChild("WinScale")
		if target then
			root.Visible = true
			sc.Scale = 0.92
			tween(sc, SMOOTH, { Scale = 1 })
			tween(root, FAST, { BackgroundTransparency = 0 })
		else
			tween(sc, FAST, { Scale = 0.94 })
			task.delay(0.12, function() if not self._visible then root.Visible = false end end)
		end
	end

	-- keybind toggle
	local toggleKey = cfg.ToggleKeybind or Enum.KeyCode.RightControl
	conn(UserInputService.InputBegan, function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then Window:Toggle() end
	end)

	-- floating open bubble (always available, essential on mobile)
	local bubble = new("TextButton", {
		Name = "OpenBubble",
		BackgroundColor3 = scheme.AccentColor,
		Size = UDim2.fromOffset(Library.IsMobile and 52 or 44, Library.IsMobile and 52 or 44),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Text = "", AutoButtonColor = false,
		Parent = ScreenGui,
	})
	corner(bubble, 999)
	stroke(bubble, scheme.OutlineColor, 2, 0)
	local bubbleIcon = new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = cfg.Icon and ("rbxassetid://" .. tostring(cfg.Icon)) or "rbxassetid://6034509993",
		Size = UDim2.new(0.62, 0, 0.62, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = bubble,
	})
	makeDraggable(bubble, bubble)
	local bubbleDown
	conn(bubble.MouseButton1Click, function() Window:Toggle() end)
	Window._bubble = bubble

	-- ===== AddTab =====
	function Window:AddTab(name, icon)
		local Tab = { Name = name, _groupboxes = {}, _leftCol = nil, _rightCol = nil }

		-- rail button
		local tabBtn = new("TextButton", {
			BackgroundColor3 = scheme.CardColor,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Library.IsMobile and 42 or 36),
			Text = "", AutoButtonColor = false,
			Parent = railScroll,
		})
		corner(tabBtn, 8)
		local tabIcon
		local labelX = 12
		local resolvedIcon = icon and iconId(icon) or nil
		-- only show an icon image if we resolved a real (mapped or numeric) id;
		-- unknown names fall back to a small accent dot so nothing looks broken.
		if icon then
			tabIcon = new("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://" .. tostring(resolvedIcon),
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ImageColor3 = scheme.DimColor,
				Parent = tabBtn,
			})
			-- if the image fails to load, swap to a simple dot marker
			task.delay(1.5, function()
				pcall(function()
					if tabIcon and tabIcon.Parent and tabIcon.IsLoaded == false then
						tabIcon.Image = ""
						tabIcon.BackgroundColor3 = scheme.AccentColor
						tabIcon.BackgroundTransparency = 0
						tabIcon.Size = UDim2.fromOffset(6, 6)
						tabIcon.Position = UDim2.new(0, 14, 0.5, 0)
						corner(tabIcon, 3)
					end
				end)
			end)
			labelX = 36
		end
		local tabLabel = new("TextLabel", {
			BackgroundTransparency = 1,
			Font = scheme.Font, TextSize = Library.IsMobile and 15 or 13,
			TextColor3 = scheme.DimColor, TextXAlignment = Enum.TextXAlignment.Left,
			Text = name, Position = UDim2.new(0, labelX, 0, 0), Size = UDim2.new(1, -labelX - 8, 1, 0),
			Parent = tabBtn,
		})
		-- active accent pill
		local pill = new("Frame", {
			BackgroundColor3 = scheme.AccentColor,
			Size = UDim2.new(0, 3, 0.55, 0), Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0,
			Parent = tabBtn,
		})
		corner(pill, 3)

		-- page (scrolling, holds two columns)
		local page = new("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = Library.IsMobile and 0 or 4,
			ScrollBarImageColor3 = scheme.AccentColor,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Visible = false,
			Parent = content,
		})
		pad(page, nil, 12, 12, 12, 12)

		-- columns: two side-by-side on desktop, single stacked on mobile
		local columnsHolder = new("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, Parent = page,
		})
		local twoCol = not Library.IsMobile
		local leftCol = new("Frame", {
			BackgroundTransparency = 1,
			Size = twoCol and UDim2.new(0.5, -6, 0, 0) or UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, Parent = columnsHolder,
		})
		listLayout(leftCol, 12)
		local rightCol = new("Frame", {
			BackgroundTransparency = 1,
			Size = twoCol and UDim2.new(0.5, -6, 0, 0) or UDim2.new(1, 0, 0, 0),
			Position = twoCol and UDim2.new(0.5, 6, 0, 0) or UDim2.new(0, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, Parent = columnsHolder,
		})
		listLayout(rightCol, 12)
		if not twoCol then
			-- stack: put rightCol below leftCol via a vertical layout on the holder
			listLayout(columnsHolder, 12)
			leftCol.Size = UDim2.new(1, 0, 0, 0)
			rightCol.Size = UDim2.new(1, 0, 0, 0)
			rightCol.Position = UDim2.new(0, 0, 0, 0)
		end

		Tab._page = page
		Tab._leftCol = leftCol
		Tab._rightCol = rightCol
		Tab._btn = tabBtn

		-- selection
		local function select()
			for _, t in ipairs(Window._tabOrder) do
				t._page.Visible = false
				tween(t._btn, FAST, { BackgroundTransparency = 1 })
				local lbl = t._btn:FindFirstChildWhichIsA("TextLabel")
				if lbl then lbl.TextColor3 = scheme.DimColor end
				local ico = t._btn:FindFirstChildWhichIsA("ImageLabel")
				if ico then ico.ImageColor3 = scheme.DimColor end
				local p = t._btn:FindFirstChildOfClass("Frame")
				if p then p.BackgroundTransparency = 1 end
			end
			page.Visible = true
			tween(tabBtn, FAST, { BackgroundTransparency = 0, BackgroundColor3 = scheme.CardColor })
			tabLabel.TextColor3 = scheme.FontColor
			if tabIcon then tabIcon.ImageColor3 = scheme.AccentColor end
			pill.BackgroundTransparency = 0
			Window._active = Tab
		end
		Tab.Select = select
		conn(tabBtn.MouseButton1Click, select)
		conn(tabBtn.MouseEnter, function() if not page.Visible then tween(tabBtn, FAST, { BackgroundTransparency = 0.6 }) end end)
		conn(tabBtn.MouseLeave, function() if not page.Visible then tween(tabBtn, FAST, { BackgroundTransparency = 1 }) end end)

		Window._tabOrder[#Window._tabOrder + 1] = Tab
		Window.Tabs[name] = Tab
		if #Window._tabOrder == 1 then select() end

		-- ===== Groupboxes =====
		local function makeGroupbox(gbName, parentCol)
			local box = new("Frame", {
				BackgroundColor3 = scheme.MainColor,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = parentCol,
			})
			corner(box, 10)
			stroke(box, scheme.OutlineColor, 1, 0.15)
			local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = box })
			pad(inner, nil, 14, 14, 12, 14)
			listLayout(inner, 9)
			-- title
			new("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.GothamBold, TextSize = Library.IsMobile and 15 or 13,
				TextColor3 = scheme.FontColor, TextXAlignment = Enum.TextXAlignment.Left,
				Text = gbName, Parent = inner, LayoutOrder = -1,
			})
			new("Frame", { -- underline
				BackgroundColor3 = scheme.OutlineColor, Size = UDim2.new(1, 0, 0, 1),
				BorderSizePixel = 0, LayoutOrder = 0, Parent = inner,
			})

			local Box = { _inner = inner, _order = 1 }
			Box._container = inner

			-- element builders are attached below (returns Box for chaining)
			require_elements(Box, Library, {
				new = new, corner = corner, stroke = stroke, pad = pad, listLayout = listLayout,
				tween = tween, FAST = FAST, SMOOTH = SMOOTH, conn = conn, scheme = scheme,
			})
			return Box
		end

		function Tab:AddLeftGroupbox(gbName) return makeGroupbox(gbName, leftCol) end
		function Tab:AddRightGroupbox(gbName) return makeGroupbox(gbName, twoCol and rightCol or leftCol) end
		-- Obsidian also has AddLeftTabbox/RightTabbox; alias to groupbox for compat
		Tab.AddLeftTabbox = Tab.AddLeftGroupbox
		Tab.AddRightTabbox = Tab.AddRightGroupbox

		return Tab
	end

	Library.Windows[#Library.Windows + 1] = Window
	Library.MainWindow = Window
	return Window
end

-- =========================================================================
-- Draggable label (the live info label the script uses)
-- =========================================================================
function Library:AddDraggableLabel(text)
	local scheme = self.Scheme
	local frame = new("Frame", {
		BackgroundColor3 = scheme.MainColor,
		Size = UDim2.new(0, 220, 0, 30),
		Position = UDim2.new(0, 16, 0, 16),
		AnchorPoint = Vector2.new(0, 0),
		Parent = ScreenGui,
	})
	corner(frame, 8)
	stroke(frame, scheme.OutlineColor, 1, 0.2)
	local bar = new("Frame", { BackgroundColor3 = scheme.AccentColor, Size = UDim2.new(0, 3, 1, -10), Position = UDim2.new(0, 0, 0, 5), BorderSizePixel = 0, Parent = frame })
	corner(bar, 3)
	local label = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 12, 0, 0),
		Font = scheme.Font, TextSize = 13, TextColor3 = scheme.FontColor,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text or "Dexori", Parent = frame,
	})
	makeDraggable(frame, frame)
	-- return an object with :SetText so the script can update it live
	return setmetatable({ Frame = frame, TextLabel = label }, {
		__index = {
			SetText = function(self, t) label.Text = t end,
		},
	})
end

-- =========================================================================
-- SaveManager  (config save/load, Obsidian-compatible surface)
-- =========================================================================
local SaveManager = {
	Folder = "DexUI",
	Library = Library,
	Ignore = {},
	_themeIgnored = false,
}
function SaveManager:SetLibrary(lib) self.Library = lib end
function SaveManager:SetFolder(folder) self.Folder = folder; self:_ensureFolders() end
function SaveManager:SetIgnoreIndexes(list) for _, i in ipairs(list or {}) do self.Ignore[i] = true end end
function SaveManager:IgnoreThemeSettings() self._themeIgnored = true end

function SaveManager:_ensureFolders()
	pcall(function()
		if type(makefolder) ~= "function" or type(isfolder) ~= "function" then return end
		local parts = {}
		for p in tostring(self.Folder):gmatch("[^/]+") do parts[#parts + 1] = p end
		local cur = ""
		for _, p in ipairs(parts) do
			cur = (cur == "") and p or (cur .. "/" .. p)
			if not isfolder(cur) then makefolder(cur) end
		end
		if not isfolder(self.Folder .. "/settings") then makefolder(self.Folder .. "/settings") end
	end)
end

function SaveManager:_path(name)
	return self.Folder .. "/settings/" .. tostring(name) .. ".json"
end

function SaveManager:_collect()
	local data = { objects = {} }
	for idx, tog in pairs(self.Library.Toggles) do
		if not self.Ignore[idx] then
			data.objects[idx] = { type = "Toggle", value = tog.Value }
		end
	end
	for idx, opt in pairs(self.Library.Options) do
		if not self.Ignore[idx] then
			data.objects[idx] = { type = opt.Type or "Option", value = opt.Value }
		end
	end
	return data
end

function SaveManager:Save(name)
	if type(writefile) ~= "function" then return false, "no writefile" end
	self:_ensureFolders()
	local data = self:_collect()
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false, "encode failed" end
	local ok2 = pcall(function() writefile(self:_path(name), encoded) end)
	return ok2
end

function SaveManager:Load(name)
	if type(readfile) ~= "function" or type(isfile) ~= "function" then return false, "no readfile" end
	if not isfile(self:_path(name)) then return false, "no config" end
	local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(self:_path(name))) end)
	if not ok or type(decoded) ~= "table" or type(decoded.objects) ~= "table" then return false, "decode failed" end
	for idx, saved in pairs(decoded.objects) do
		local tog = self.Library.Toggles[idx]
		local opt = self.Library.Options[idx]
		if tog and tog.SetValue then pcall(function() tog:SetValue(saved.value) end)
		elseif opt and opt.SetValue then pcall(function() opt:SetValue(saved.value) end) end
	end
	return true
end

function SaveManager:_autoloadPath() return self.Folder .. "/settings/autoload.txt" end
function SaveManager:SetAutoloadConfig(name)
	pcall(function() if type(writefile) == "function" then writefile(self:_autoloadPath(), name) end end)
end
function SaveManager:LoadAutoloadConfig()
	pcall(function()
		if type(isfile) == "function" and isfile(self:_autoloadPath()) then
			local name = readfile(self:_autoloadPath())
			if name and name ~= "" then self:Load(name) end
		end
	end)
end

function SaveManager:RefreshConfigList()
	local out = {}
	pcall(function()
		if type(listfiles) ~= "function" then return end
		for _, file in ipairs(listfiles(self.Folder .. "/settings")) do
			local nm = tostring(file):match("([^/\\]+)%.json$")
			if nm and nm ~= "autoload" then out[#out + 1] = nm end
		end
	end)
	return out
end

-- Build a config UI section in the given tab (compat with Obsidian:BuildConfigSection)
function SaveManager:BuildConfigSection(tab)
	if not tab or not tab.AddRightGroupbox then return end
	self:_ensureFolders()
	local box = tab:AddRightGroupbox("Configuration")
	local L = self.Library
	-- input for config name
	box:AddInput("SaveManager_ConfigName", { Text = "Config name", Default = "", Placeholder = "my config", Finished = false })
	box:AddDropdown("SaveManager_ConfigList", { Text = "Configs", Values = self:RefreshConfigList(), Default = 1, Multi = false })

	local function currentName()
		local o = L.Options["SaveManager_ConfigName"]
		local nm = o and o.Value or ""
		if nm == "" then
			local d = L.Options["SaveManager_ConfigList"]
			nm = d and d.Value or ""
		end
		return nm
	end

	box:AddButton({ Text = "Create / Save", Func = function()
		local nm = currentName()
		if nm == "" then L:Notify({ Title = "Config", Description = "Enter a config name", Time = 4 }); return end
		local ok = self:Save(nm)
		L:Notify({ Title = "Config", Description = ok and ("Saved '" .. nm .. "'") or "Save failed", Time = 4 })
		local d = L.Options["SaveManager_ConfigList"]
		if d and d.SetValues then d:SetValues(self:RefreshConfigList()) end
	end })
	box:AddButton({ Text = "Load", Func = function()
		local nm = currentName()
		if nm == "" then L:Notify({ Title = "Config", Description = "Pick a config", Time = 4 }); return end
		local ok = self:Load(nm)
		L:Notify({ Title = "Config", Description = ok and ("Loaded '" .. nm .. "'") or "Load failed", Time = 4 })
	end })
	box:AddButton({ Text = "Set as Autoload", Func = function()
		local nm = currentName()
		if nm == "" then L:Notify({ Title = "Config", Description = "Pick a config", Time = 4 }); return end
		self:SetAutoloadConfig(nm)
		L:Notify({ Title = "Config", Description = "Autoload set: " .. nm, Time = 4 })
	end })
	box:AddButton({ Text = "Refresh List", Func = function()
		local d = L.Options["SaveManager_ConfigList"]
		if d and d.SetValues then d:SetValues(self:RefreshConfigList()) end
		L:Notify({ Title = "Config", Description = "Refreshed", Time = 3 })
	end })
end

Library.SaveManager = SaveManager
-- Obsidian scripts sometimes reference a ThemeManager; provide a no-op-ish stub
Library.ThemeManager = {
	SetLibrary = function() end, SetFolder = function() end,
	ApplyToTab = function() end, ApplyToGroupbox = function() end,
	LoadDefault = function() end,
}

return Library
