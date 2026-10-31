return function(env)
	local AP = env.AP
	local Library = env.Library
	local Options = env.Options or {}
	local Workspace = env.Workspace or workspace
	local UserInputService = env.UserInputService or game:GetService("UserInputService")
	local RunService = env.RunService or game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local TweenService = game:GetService("TweenService")

	local UI = {}
	UI.FAMILY = "rbxasset://fonts/families/BuilderSans.json"
	UI.FONT = Font.new(UI.FAMILY, Enum.FontWeight.Medium)
	UI.SEMI = Font.new(UI.FAMILY, Enum.FontWeight.SemiBold)
	UI.BOLD = Font.new(UI.FAMILY, Enum.FontWeight.Bold)
	UI.MONO = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium)
	UI.DEFAULT = {
		Background = Color3.fromHex("0c0c0d"),
		Chrome = Color3.fromHex("080809"),
		Panel = Color3.fromHex("111113"),
		Field = Color3.fromHex("101012"),
		Button = Color3.fromHex("151517"),
		Divider = Color3.fromHex("18181b"),
		Border = Color3.fromHex("1c1c20"),
		BorderLight = Color3.fromHex("29292e"),
		Text = Color3.fromHex("ecebee"),
		SubText = Color3.fromHex("adabb3"),
		Muted = Color3.fromHex("7b7983"),
		Accent = Color3.fromHex("2563eb"),
	}
	UI.WHITE = Color3.new(1, 1, 1)
	UI.MODE_LABEL = AP.MODE_LABEL or { timed = "Timed", rush = "Rush", dash = "Dash", range = "Range" }
	UI.MODE_HELP = {
		timed = "Blocks at each time while in range.",
		rush = "Blocks at each time, even far away.",
		dash = "Blocks once within Close studs.",
		range = "Base + ms per stud of distance.",
	}

	local SETTINGS_FILE = "Dexori/Universal/ap_builder.json"
	local DEFAULTS = { scale = 1, preview = true, compact = false, tab = "parry", nudge = 20, hideKey = "RightControl" }
	local Settings = table.clone(DEFAULTS)
	pcall(function()
		if isfile(SETTINGS_FILE) then
			local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
			if type(data) == "table" then
				for key, value in pairs(DEFAULTS) do
					if type(data[key]) == type(value) then
						Settings[key] = data[key]
					end
				end
			end
		end
	end)
	Settings.scale = math.clamp(Settings.scale, 0.7, 1.3)
	if not table.find({ "parry", "auto", "manual", "moves" }, Settings.tab) then
		Settings.tab = "parry"
	end
	if not table.find({ 10, 20, 50 }, Settings.nudge) then
		Settings.nudge = 20
	end
	local function saveSettings()
		pcall(function()
			for _, folder in ipairs({ "Dexori", "Dexori/Universal" }) do
				if not isfolder(folder) then
					makefolder(folder)
				end
			end
			writefile(SETTINGS_FILE, HttpService:JSONEncode(Settings))
		end)
	end

	function UI.T(key)
		local theme = Library and Library.Theme
		local value = type(theme) == "table" and theme[key] or nil
		return typeof(value) == "Color3" and value or UI.DEFAULT[key]
	end
	function UI.mode()
		return UI.T("Accent")
	end
	function UI.new(class, props, parent)
		local object = Instance.new(class)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		object.Parent = parent
		return object
	end
	function UI.corner(object, radius)
		UI.new("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, object)
		return object
	end
	function UI.stroke(object, color, transparency, thickness)
		return UI.new("UIStroke", { Color = color or UI.T("BorderLight"), Thickness = thickness or 1, Transparency = transparency or 0,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, object)
	end
	function UI.pad(object, l, r, t, b)
		UI.new("UIPadding", { PaddingLeft = UDim.new(0, l or 0), PaddingRight = UDim.new(0, r or l or 0), PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or t or 0) }, object)
		return object
	end
	function UI.row(parent, props, gap, align)
		local holder = UI.new("Frame", { BackgroundTransparency = 1 }, parent)
		for key, value in pairs(props or {}) do
			holder[key] = value
		end
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap or 6), VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = align or Enum.HorizontalAlignment.Left, SortOrder = Enum.SortOrder.LayoutOrder }, holder)
		return holder
	end
	function UI.label(parent, props)
		local object = UI.new("TextLabel", { BackgroundTransparency = 1, FontFace = UI.FONT, TextSize = 13, TextColor3 = UI.T("Text"),
			TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, parent)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		return object
	end
	function UI.pill(parent, text, color, props)
		local object = UI.new("TextLabel", { BackgroundColor3 = UI.T("Field"), FontFace = UI.SEMI, TextSize = 11, TextColor3 = color or UI.T("Muted"),
			Text = text, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18), TextXAlignment = Enum.TextXAlignment.Center }, parent)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		UI.corner(object, 9)
		UI.stroke(object, color and color:Lerp(UI.T("BorderLight"), 0.6) or UI.T("BorderLight"))
		UI.pad(object, 8, 8)
		return object
	end
	function UI.button(parent, text, props)
		local object = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = UI.T("Button"), FontFace = UI.SEMI, TextSize = 13,
			TextColor3 = UI.T("Text"), Text = text }, parent)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		UI.corner(object, 6)
		local edge = UI.stroke(object)
		object.MouseEnter:Connect(function()
			edge.Color = UI.T("Muted")
		end)
		object.MouseLeave:Connect(function()
			edge.Color = UI.T("BorderLight")
		end)
		return object
	end
	function UI.primary(parent, text, props)
		local object = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = UI.T("Accent"), FontFace = UI.BOLD, TextSize = 13,
			TextColor3 = UI.WHITE, Text = text }, parent)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		UI.corner(object, 6)
		UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 225)) }, object)
		object.MouseEnter:Connect(function()
			object.BackgroundColor3 = UI.T("Accent"):Lerp(UI.WHITE, 0.12)
		end)
		object.MouseLeave:Connect(function()
			object.BackgroundColor3 = UI.T("Accent")
		end)
		return object
	end
	function UI.danger(parent, text, props)
		local object = UI.button(parent, text, props)
		object.TextColor3 = UI.T("Text")
		return object
	end
	function UI.field(parent, props)
		local object = UI.new("TextBox", { BackgroundColor3 = UI.T("Field"), FontFace = UI.FONT, TextSize = 13, TextColor3 = UI.T("Text"),
			PlaceholderColor3 = UI.T("Muted"), ClearTextOnFocus = false, Text = "", TextXAlignment = Enum.TextXAlignment.Left }, parent)
		for key, value in pairs(props or {}) do
			object[key] = value
		end
		UI.corner(object, 6)
		local edge = UI.stroke(object)
		UI.pad(object, 9, 9)
		object.Focused:Connect(function()
			edge.Color = UI.T("Accent")
		end)
		object.FocusLost:Connect(function()
			edge.Color = UI.T("BorderLight")
		end)
		return object
	end
	function UI.panel(parent, x, y, w, h)
		local frame = UI.new("Frame", { BackgroundColor3 = UI.T("Chrome"), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
		UI.corner(frame, 10)
		UI.stroke(frame)
		return frame
	end
	function UI.heading(parent, text, y, x)
		local l = UI.label(parent, { Text = text, FontFace = UI.SEMI, TextSize = 12, TextColor3 = UI.T("Muted"), Position = UDim2.fromOffset(x or 14, y),
			Size = UDim2.new(1, -(x or 14) * 2, 0, 16) })
		return l
	end
	function UI.scroll(parent, props, padding)
		local s = UI.new("ScrollingFrame", { BackgroundTransparency = 1, ScrollBarThickness = 3, ScrollBarImageColor3 = UI.T("BorderLight"),
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0 }, parent)
		for key, value in pairs(props or {}) do
			s[key] = value
		end
		UI.new("UIListLayout", { Padding = UDim.new(0, padding or 4), SortOrder = Enum.SortOrder.LayoutOrder }, s)
		UI.pad(s, 1, 6, 1, 1)
		return s
	end
	function UI.wrap(parent, props, gap)
		local holder = UI.new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true }, parent)
		for key, value in pairs(props or {}) do
			holder[key] = value
		end
		UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, gap or 5),
			SortOrder = Enum.SortOrder.LayoutOrder }, holder)
		return holder
	end
	function UI.clear(container)
		for _, child in ipairs(container:GetChildren()) do
			if not (child:IsA("UIListLayout") or child:IsA("UIPadding") or child:IsA("UICorner") or child:IsA("UIStroke") or child:IsA("UIGradient")) then
				child:Destroy()
			end
		end
	end
	function UI.segmented(parent, items, props, onPick)
		local holder = UI.new("Frame", { BackgroundColor3 = UI.T("Field") }, parent)
		for key, value in pairs(props or {}) do
			holder[key] = value
		end
		UI.corner(holder, 7)
		UI.stroke(holder)
		local buttons = {}
		local width = 1 / #items
		for i, item in ipairs(items) do
			local b = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = UI.T("Accent"), BackgroundTransparency = 1, FontFace = UI.SEMI,
				TextSize = 12, TextColor3 = UI.T("SubText"), Text = item[2], Position = UDim2.new(width * (i - 1), 3, 0, 3), Size = UDim2.new(width, -6, 1, -6) }, holder)
			UI.corner(b, 5)
			b.MouseButton1Click:Connect(function()
				onPick(item[1])
			end)
			buttons[item[1]] = { button = b, item = item }
		end
		return function(value)
			for key, entry in pairs(buttons) do
				local on = key == value
				local b = entry.button
				b.BackgroundColor3 = UI.T("Accent")
				b.BackgroundTransparency = on and 0 or 1
				b.TextColor3 = on and UI.WHITE or UI.T("SubText")
				b.FontFace = on and UI.BOLD or UI.SEMI
			end
		end
	end
	function UI.fmt(t)
		return string.format("%.3f", t or 0)
	end
	local Toasts = { n = 0 }
	function UI.toast(text, duration)
		local gui = Toasts.gui
		if not gui or not gui.Parent then
			gui = UI.new("ScreenGui", { Name = "DexoriApToasts", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1001,
				ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, UI.gui())
			Toasts.gui = gui
			Toasts.holder = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18),
				Size = UDim2.fromOffset(320, 420) }, gui)
			UI.new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Toasts.holder)
		end
		Toasts.n += 1
		local card = UI.new("Frame", { BackgroundColor3 = UI.T("Chrome"), Size = UDim2.new(1, 0, 0, 40), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = Toasts.n }, Toasts.holder)
		UI.corner(card, 8)
		UI.stroke(card)
		UI.pad(card, 16, 14, 10, 11)
		local bar = UI.new("Frame", { BackgroundColor3 = UI.T("Accent"), BorderSizePixel = 0, Position = UDim2.new(0, -16, 0, 2), Size = UDim2.new(0, 3, 1, -4) }, card)
		UI.corner(bar, 2)
		UI.label(card, { Text = tostring(text), TextWrapped = true, TextSize = 13, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 19) })
		local kids = {}
		for _, child in ipairs(Toasts.holder:GetChildren()) do
			if child:IsA("Frame") then
				table.insert(kids, child)
			end
		end
		if #kids > 4 then
			table.sort(kids, function(a, b)
				return a.LayoutOrder < b.LayoutOrder
			end)
			kids[1]:Destroy()
		end
		task.delay(duration or 4, function()
			if card.Parent then
				card:Destroy()
			end
		end)
	end
	function UI.notify(text)
		UI.toast(text, 4)
	end
	function UI.keyFrom(value)
		if typeof(value) == "EnumItem" then
			return value
		end
		if type(value) ~= "string" or value == "" or value == "None" then
			return nil
		end
		local kind, name = value:match("^(%w+)%.(%w+)$")
		if not kind then
			kind, name = "KeyCode", value
		end
		local ok, item = pcall(function()
			return Enum[kind][name]
		end)
		return ok and item or nil
	end
	function UI.keyLabel(key)
		if typeof(key) ~= "EnumItem" then
			return "None"
		end
		local short = { MouseButton1 = "Mouse 1", MouseButton2 = "Mouse 2", MouseButton3 = "Mouse 3", RightControl = "Right Ctrl", LeftControl = "Left Ctrl",
			RightShift = "Right Shift", LeftShift = "Left Shift", LeftAlt = "Left Alt", RightAlt = "Right Alt" }
		return short[key.Name] or key.Name
	end
	function UI.keyMatches(input, key)
		return typeof(key) == "EnumItem" and (input.KeyCode == key or input.UserInputType == key)
	end
	function UI.modePill(parent, move, props)
		if move.off then
			return UI.pill(parent, "off", UI.T("Muted"), props)
		end
		local press = move.press == "hold" and " · hold" or (move.press == "dodge" and " · dodge" or "")
		return UI.pill(parent, UI.MODE_LABEL[move.mode] .. press, UI.mode(), props)
	end
	function UI.statPill(parent, id, props)
		local stat = AP.stats and AP.stats[id]
		if not stat or (stat.blocks or 0) == 0 then
			return nil
		end
		local good = stat.blocks - math.min(stat.misses or 0, stat.blocks)
		local color = (stat.misses or 0) == 0 and UI.T("Accent") or UI.T("SubText")
		return UI.pill(parent, string.format("parried %d/%d", good, stat.blocks), color, props)
	end
	function UI.gui()
		local ok, hui = pcall(function()
			return gethui and gethui()
		end)
		if ok and typeof(hui) == "Instance" then
			return hui
		end
		return game:GetService("CoreGui")
	end

	local Preview = {}
	Preview.__index = Preview
	function Preview.new(viewport)
		local p = setmetatable({ viewport = viewport, yaw = math.rad(35), pitch = math.rad(14), dist = 14, center = Vector3.zero }, Preview)
		p.camera = UI.new("Camera", { FieldOfView = 45 }, viewport)
		viewport.CurrentCamera = p.camera
		p.world = UI.new("WorldModel", {}, viewport)
		return p
	end
	function Preview:clear()
		self.world:ClearAllChildren()
		self.parts, self.rec = nil, nil
	end
	function Preview:find(model, path)
		local node = model
		for _, name in ipairs(path) do
			node = node and node:FindFirstChild(name)
		end
		return node
	end
	function Preview:load(entry)
		self:clear()
		local rec = entry and entry.rec
		if not rec or #rec.frames == 0 then
			return false
		end
		self.rec = rec
		self.parts = {}
		local rig = nil
		if entry.rig then
			local ok, copy = pcall(function()
				return entry.rig:Clone()
			end)
			rig = ok and copy or nil
		end
		if rig then
			rig.Parent = self.world
			for i, info in ipairs(rec.parts) do
				local part = self:find(rig, info.path)
				self.parts[i] = part and part:IsA("BasePart") and part or nil
			end
		else
			local holder = UI.new("Model", { Name = "Rig" }, self.world)
			for i, info in ipairs(rec.parts) do
				if info.transparency < 1 then
					self.parts[i] = UI.new("Part", { Anchored = true, CanCollide = false, Size = info.size, Color = info.color,
						Material = Enum.Material.SmoothPlastic, Transparency = info.transparency }, holder)
				end
			end
		end
		local first = rec.frames[1]
		local lowest, sum, count = math.huge, Vector3.zero, 0
		for i, cf in pairs(first.cf) do
			local info = rec.parts[i]
			if info and cf then
				lowest = math.min(lowest, cf.Position.Y - info.size.Y / 2)
				sum += cf.Position
				count += 1
			end
		end
		if lowest == math.huge then
			lowest = -3
		end
		local floor = UI.new("Part", { Anchored = true, CanCollide = false, Size = Vector3.new(80, 0.2, 80), Color = UI.T("Panel"),
			Material = Enum.Material.SmoothPlastic, CFrame = CFrame.new(0, lowest - 0.1, 0) }, self.world)
		floor.Name = "Floor"
		for i = -4, 4 do
			UI.new("Part", { Anchored = true, CanCollide = false, Size = Vector3.new(0.05, 0.02, 80), Color = UI.T("BorderLight"), Material = Enum.Material.Neon,
				Transparency = 0.6, CFrame = CFrame.new(i * 5, lowest, 0) }, self.world)
			UI.new("Part", { Anchored = true, CanCollide = false, Size = Vector3.new(80, 0.02, 0.05), Color = UI.T("BorderLight"), Material = Enum.Material.Neon,
				Transparency = 0.6, CFrame = CFrame.new(0, lowest, i * 5) }, self.world)
		end
		local focus = count > 0 and sum / count or Vector3.zero
		if rec.me then
			local me = Vector3.new(rec.me.X, lowest + 2.5, rec.me.Z)
			local you = UI.new("Part", { Anchored = true, CanCollide = false, Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 2.6, 2.6),
				Color = UI.T("Accent"), Material = Enum.Material.ForceField, Transparency = 0.25, CFrame = CFrame.new(me) * CFrame.Angles(0, 0, math.rad(90)) }, self.world)
			you.Name = "You"
			local ring = UI.new("Part", { Anchored = true, CanCollide = false, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 4, 4), Color = UI.T("Accent"),
				Material = Enum.Material.Neon, Transparency = 0.4, CFrame = CFrame.new(me.X, lowest + 0.05, me.Z) * CFrame.Angles(0, 0, math.rad(90)) }, self.world)
			ring.Name = "YouRing"
			if (me - focus).Magnitude < 60 then
				focus = (focus + Vector3.new(me.X, focus.Y, me.Z)) / 2
			end
			self.dist = math.clamp((Vector3.new(me.X, 0, me.Z) - Vector3.new(focus.X, 0, focus.Z)).Magnitude * 2 + 12, 12, 70)
		else
			self.dist = 14
		end
		for _, hit in ipairs(entry.hits or {}) do
			if hit.spot then
				local dot = UI.new("Part", { Anchored = true, CanCollide = false, Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7), Color = UI.T("SubText"),
					Material = Enum.Material.Neon, Transparency = 0.2, CFrame = CFrame.new(hit.spot.X, lowest + 0.4, hit.spot.Z) }, self.world)
				dot.Name = "Hit"
			end
		end
		self.center = focus
		self:pose(0)
		self:aim()
		return true
	end
	function Preview:frameAt(t)
		local frames = self.rec and self.rec.frames
		if not frames or #frames == 0 then
			return nil
		end
		local lo, hi = 1, #frames
		while lo < hi do
			local mid = math.floor((lo + hi + 1) / 2)
			if frames[mid].t <= t then
				lo = mid
			else
				hi = mid - 1
			end
		end
		return frames[lo]
	end
	function Preview:pose(t)
		local frame = self:frameAt(t)
		if not (frame and self.parts) then
			return
		end
		for i, part in pairs(self.parts) do
			local cf = frame.cf[i]
			if cf and part.Parent then
				part.CFrame = cf
			end
		end
	end
	function Preview:aim()
		local offset = Vector3.new(math.sin(self.yaw) * math.cos(self.pitch), math.sin(self.pitch), math.cos(self.yaw) * math.cos(self.pitch)) * self.dist
		self.camera.CFrame = CFrame.lookAt(self.center + offset, self.center)
	end
	function Preview:length()
		local frames = self.rec and self.rec.frames
		return frames and #frames > 0 and frames[#frames].t or 0
	end

	local W, H = 920, 620
	local TOP, FOOT, LW = 54, 44, 276
	local RX = 12 + LW + 10
	local RW = W - RX - 12
	local BODY = H - TOP - FOOT
	local B = { tab = Settings.tab, filter = "all", search = "", t = 0, playing = false, speed = 1, synth = {} }
	local S = nil

	local function entryFor(id)
		if not id then
			return nil
		end
		if AP.logged[id] then
			return AP.logged[id]
		end
		local move = AP.moves[id]
		if not move then
			return nil
		end
		local e = B.synth[id]
		if not e then
			e = { id = id, hits = {}, plays = 0, saved = true }
			B.synth[id] = e
		end
		e.name = move.name or ("Anim " .. id)
		return e
	end
	local function hitTimes(entry)
		local ts = {}
		for _, h in ipairs(entry.hits) do
			table.insert(ts, h.t)
		end
		return ts
	end
	local function used(id)
		return AP.moves[id] ~= nil and AP.isUsed(AP.moves[id])
	end
	local function listRows()
		local q = B.search:lower()
		local rows, seen = {}, {}
		local function match(entry)
			return q == "" or tostring(entry.name):lower():find(q, 1, true) ~= nil or entry.id:find(q, 1, true) ~= nil
		end
		for _, entry in ipairs(AP.order) do
			seen[entry.id] = true
			local keep = (B.filter == "all") or (B.filter == "hit" and #entry.hits > 0) or (B.filter == "saved" and used(entry.id))
			if keep and match(entry) then
				table.insert(rows, entry)
			end
		end
		table.sort(rows, function(a, b)
			if B.filter == "hit" then
				return (a.lastHit or 0) > (b.lastHit or 0)
			end
			return (a.last or 0) > (b.last or 0)
		end)
		if B.filter ~= "hit" then
			local extra = {}
			for id in pairs(AP.moves) do
				if not seen[id] and used(id) then
					local e = entryFor(id)
					if match(e) then
						table.insert(extra, e)
					end
				end
			end
			table.sort(extra, function(a, b)
				return tostring(a.name):lower() < tostring(b.name):lower()
			end)
			for _, e in ipairs(extra) do
				table.insert(rows, e)
			end
		end
		return rows
	end

	local function select(id)
		if not S then
			B.selected = id
			AP.selectedId = id
			return
		end
		local changed = B.selected ~= id
		B.selected = id
		AP.selectedId = id
		if changed then
			B.playing, B.t, S.chosen = false, 0, nil
		end
		S.refresh()
	end

	local function buildWindow()
		local s = { conns = {}, ui = {}, tabs = {} }
		local ui = s.ui
		s.gui = UI.new("ScreenGui", { Name = "DexoriApBuilder", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1000,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, UI.gui())
		local camera = Workspace.CurrentCamera
		local view = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local root = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(W, H), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = B.pos or UDim2.fromOffset(math.floor(view.X / 2), math.floor(view.Y / 2)) }, s.gui)
		s.root = root
		UI.new("UIScale", { Scale = math.min(Settings.scale, (view.Y - 30) / H, (view.X - 30) / W) }, root)
		for index, spread in ipairs({ 3, 8, 15 }) do
			local shadow = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4), Size = UDim2.new(1, spread * 2, 1, spread * 2),
				BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.78 + index * 0.06, ZIndex = 0 }, root)
			UI.corner(shadow, 12 + spread)
		end
		local win = UI.new("Frame", { BackgroundColor3 = UI.T("Background"), Size = UDim2.fromScale(1, 1), ZIndex = 1 }, root)
		UI.corner(win, 12)
		s.win = win
		local inner = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 1, -2), ZIndex = 60 }, win)
		UI.corner(inner, 11)
		UI.stroke(inner, UI.T("BorderLight"), 0.35)
		local glow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, root)
		UI.corner(glow, 12)
		local flow = UI.stroke(glow, UI.T("Accent"), 0, 1.5)
		local flowGrad = UI.new("UIGradient", { Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.38, 1), NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(0.62, 1), NumberSequenceKeypoint.new(1, 1) }) }, flow)
		s.spin = TweenService:Create(flowGrad, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), { Rotation = 360 })
		s.spin:Play()
		UI.new("TextButton", { BackgroundTransparency = 1, Text = "", Modal = true, Size = UDim2.fromOffset(1, 1) }, win)

		local bar = UI.new("Frame", { BackgroundColor3 = UI.T("Chrome"), Size = UDim2.new(1, 0, 0, 44), Active = true }, win)
		UI.corner(bar, 12)
		UI.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 12), BorderSizePixel = 0,
			BackgroundColor3 = UI.T("Chrome"), ZIndex = 0 }, bar)
		UI.new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
			BackgroundColor3 = UI.T("Divider") }, bar)
		local left = UI.row(bar, { Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0, 260, 1, 0) }, 8)
		local word = UI.row(left, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18), LayoutOrder = 1 }, 0)
		UI.label(word, { Text = "d", FontFace = UI.BOLD, TextSize = 17, TextColor3 = UI.T("Accent"), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18), LayoutOrder = 1 })
		UI.label(word, { Text = "exori", FontFace = UI.BOLD, TextSize = 17, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 18), LayoutOrder = 2 })
		UI.label(left, { Text = "/", TextColor3 = UI.T("BorderLight"), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), LayoutOrder = 2 })
		UI.label(left, { Text = "AP Builder", TextColor3 = UI.T("SubText"), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), LayoutOrder = 3 })
		s.paintTab = UI.segmented(bar, { { "parry", "Auto Parry" }, { "auto", "Auto" }, { "manual", "Manual" }, { "moves", "Moves" } },
			{ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(396, 30) }, function(tab)
				B.tab = tab
				s.refresh()
			end)
		local function iconButton(text, x, size)
			local b = UI.new("TextButton", { AutoButtonColor = false, BackgroundTransparency = 1, Text = text, FontFace = UI.SEMI, TextSize = size or 18,
				TextColor3 = UI.T("Muted"), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(30, 30) }, bar)
			b.MouseEnter:Connect(function()
				b.TextColor3 = UI.T("Text")
			end)
			b.MouseLeave:Connect(function()
				b.TextColor3 = UI.T("Muted")
			end)
			return b
		end
		ui.close = iconButton("×", -10, 22)
		ui.gear = UI.button(bar, "Settings", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -46, 0.5, 0), Size = UDim2.fromOffset(78, 28), TextSize = 12 })

		local dragFrom, dragPos
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragFrom, dragPos = input.Position, root.Position
			end
		end)

		local side = UI.panel(win, 12, TOP, LW, BODY)
		s.side = side
		ui.search = UI.field(side, { PlaceholderText = "Search name or id", Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 30) })
		s.paintFilter = UI.segmented(side, { { "all", "All" }, { "hit", "Hit you" }, { "saved", "Saved" } },
			{ Position = UDim2.fromOffset(12, 50), Size = UDim2.new(1, -24, 0, 28) }, function(filter)
				B.filter = filter
				s.refresh()
			end)
		ui.list = UI.scroll(side, { Position = UDim2.fromOffset(8, 88), Size = UDim2.new(1, -16, 1, -132) }, Settings.compact and 3 or 5)
		ui.count = UI.label(side, { TextColor3 = UI.T("Muted"), TextSize = 12, Position = UDim2.new(0, 14, 1, -38), Size = UDim2.new(1, -100, 0, 28) })
		ui.clear = UI.button(side, "Clear", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 1, -38), Size = UDim2.fromOffset(64, 28), TextSize = 12 })

		ui.foot = UI.row(win, { Position = UDim2.new(0, 14, 1, -FOOT + 6), Size = UDim2.new(0.6, 0, 0, FOOT - 12) }, 6)
		ui.hint = UI.label(win, { TextColor3 = UI.T("Muted"), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 1, -FOOT + 6), Size = UDim2.new(0.4, -16, 0, FOOT - 12) })

		local function tabFrame(name, full)
			local frame = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(full and 12 or RX, TOP),
				Size = UDim2.fromOffset(full and W - 24 or RW, BODY), Visible = false }, win)
			s.tabs[name] = frame
			return frame
		end

		local auto = tabFrame("auto")
		do
			local card = UI.panel(auto, 0, 0, RW, BODY)
			ui.aEmpty = UI.label(card, { Text = "", TextColor3 = UI.T("Muted"), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -80, 1, 0) })
			local d = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, card)
			ui.aDetail = d
			ui.aTitle = UI.label(d, { FontFace = UI.BOLD, TextSize = 17, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -260, 0, 22),
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.aSub = UI.label(d, { FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("Muted"), Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -32, 0, 14) })
			ui.aStatus = UI.row(d, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 16), Size = UDim2.fromOffset(240, 20) }, 5, Enum.HorizontalAlignment.Right)
			UI.new("Frame", { BackgroundColor3 = UI.T("Divider"), BorderSizePixel = 0, Position = UDim2.fromOffset(14, 62), Size = UDim2.new(1, -28, 0, 1) }, d)
			ui.aHitsHead = UI.heading(d, "HITS", 74, 16)
			ui.aHits = UI.wrap(d, { Position = UDim2.fromOffset(16, 96), Size = UDim2.new(1, -32, 0, 54) })
			UI.heading(d, "BEST SETUP", 158, 16)
			ui.best = UI.new("Frame", { BackgroundColor3 = UI.T("Panel"), Position = UDim2.fromOffset(16, 180), Size = UDim2.new(1, -32, 0, 84) }, d)
			UI.corner(ui.best, 8)
			ui.bestEdge = UI.stroke(ui.best, UI.T("Border"))
			ui.bestBar = UI.new("Frame", { BackgroundColor3 = UI.T("Accent"), BorderSizePixel = 0, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(0, 3, 1, -28) }, ui.best)
			UI.corner(ui.bestBar, 2)
			ui.bestPills = UI.row(ui.best, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 20) }, 5)
			ui.bestLabel = UI.label(ui.best, { FontFace = UI.BOLD, TextSize = 16, Position = UDim2.fromOffset(16, 37), Size = UDim2.new(1, -32, 0, 20),
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.why = UI.label(ui.best, { TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(16, 59), Size = UDim2.new(1, -32, 0, 16),
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.soundsHead = UI.heading(d, "SOUNDS", 276, 16)
			ui.sounds = UI.wrap(d, { Position = UDim2.fromOffset(16, 296), Size = UDim2.new(1, -32, 0, 24) })
			ui.othersHead = UI.heading(d, "OTHER WAYS  ·  click one to use it instead", 332, 16)
			ui.others = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 352), Size = UDim2.new(1, -32, 0, 56), ClipsDescendants = true }, d)
			UI.new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, ui.others)
			UI.new("Frame", { BackgroundColor3 = UI.T("Divider"), BorderSizePixel = 0, Position = UDim2.new(0, 14, 1, -112), Size = UDim2.new(1, -28, 0, 1) }, d)
			ui.save = UI.primary(d, "Save Setup", { Position = UDim2.new(0, 16, 1, -96), Size = UDim2.fromOffset(132, 32) })
			ui.toManual = UI.button(d, "Fine-tune", { Position = UDim2.new(0, 156, 1, -96), Size = UDim2.fromOffset(96, 32) })
			ui.aNudge = UI.row(d, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 1, -96), Size = UDim2.fromOffset(200, 32) }, 4, Enum.HorizontalAlignment.Right)
			ui.tip = UI.label(d, { TextColor3 = UI.T("Muted"), TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top,
				Position = UDim2.new(0, 16, 1, -54), Size = UDim2.new(1, -32, 0, 40) })
		end

		local manual = tabFrame("manual")
		do
			local y = 0
			if Settings.preview then
				local prev = UI.panel(manual, 0, 0, RW, 196)
				ui.viewport = UI.new("ViewportFrame", { BackgroundColor3 = UI.T("Field"), Ambient = Color3.fromRGB(150, 150, 160), LightColor = Color3.fromRGB(255, 250, 240),
					LightDirection = Vector3.new(-0.5, -1, -0.4), Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 1, -16) }, prev)
				UI.corner(ui.viewport, 8)
				ui.preview = Preview.new(ui.viewport)
				ui.overlayTop = UI.label(ui.viewport, { FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("SubText"), Position = UDim2.fromOffset(10, 8),
					Size = UDim2.new(1, -20, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd })
				UI.label(ui.viewport, { Text = "drag to orbit · scroll to zoom", TextColor3 = UI.T("Muted"), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
					AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -8), Size = UDim2.fromOffset(200, 16) })
				ui.noRec = UI.label(ui.viewport, { TextColor3 = UI.T("Muted"), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
				y = 204
			end
			local tl = UI.panel(manual, 0, y, RW, 96)
			ui.mTitle = UI.label(tl, { FontFace = UI.SEMI, TextSize = 14, Position = UDim2.fromOffset(14, 9), Size = UDim2.new(1, -330, 0, 20),
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.controls = UI.row(tl, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 7), Size = UDim2.fromOffset(310, 24) }, 4, Enum.HorizontalAlignment.Right)
			ui.time = UI.label(ui.controls, { FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("SubText"), AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 24), LayoutOrder = 0 })
			ui.back = UI.button(ui.controls, "‹", { Size = UDim2.fromOffset(26, 24), TextSize = 16, LayoutOrder = 1 })
			ui.play = UI.primary(ui.controls, "▶  Play", { Size = UDim2.fromOffset(74, 24), TextSize = 12, LayoutOrder = 2 })
			ui.fwd = UI.button(ui.controls, "›", { Size = UDim2.fromOffset(26, 24), TextSize = 16, LayoutOrder = 3 })
			ui.speed = UI.button(ui.controls, "1x", { Size = UDim2.fromOffset(42, 24), TextSize = 12, FontFace = UI.MONO, LayoutOrder = 4 })
			ui.track = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = UI.T("Field"), Position = UDim2.fromOffset(12, 38),
				Size = UDim2.new(1, -24, 0, 36) }, tl)
			UI.corner(ui.track, 7)
			UI.stroke(ui.track)
			ui.grid = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, ui.track)
			ui.ticks = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true }, ui.track)
			ui.head = UI.new("Frame", { BackgroundColor3 = UI.WHITE, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 2, 1, 6),
				Position = UDim2.new(0, 0, 0, -3), ZIndex = 5 }, ui.track)
			ui.live = UI.new("Frame", { BackgroundColor3 = UI.T("SubText"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.new(0, 2, 1, 0),
				Visible = false, ZIndex = 4 }, ui.track)
			ui.scale = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 77), Size = UDim2.new(1, -24, 0, 13) }, tl)
			y += 104
			local setup = UI.panel(manual, 0, y, RW, BODY - y)
			ui.blockAt = UI.primary(setup, "Block At 0.000 s", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(146, 30) })
			ui.useHits = UI.button(setup, "Use Hits", { Position = UDim2.fromOffset(164, 12), Size = UDim2.fromOffset(80, 30) })
			ui.chips = UI.row(setup, { Position = UDim2.fromOffset(252, 12), Size = UDim2.new(1, -340, 0, 30), ClipsDescendants = true }, 5)
			ui.clearTimes = UI.button(setup, "Clear", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(66, 30), TextSize = 12 })
			UI.label(setup, { Text = "Mode", TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(44, 30) })
			ui.modeHelp = UI.label(setup, { TextColor3 = UI.T("Muted"), TextSize = 12, Position = UDim2.fromOffset(366, 52), Size = UDim2.new(1, -378, 0, 30),
				TextTruncate = Enum.TextTruncate.AtEnd })
			UI.label(setup, { Text = "Press", TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(12, 92), Size = UDim2.fromOffset(44, 30) })
			ui.inputs = UI.row(setup, { Position = UDim2.fromOffset(276, 92), Size = UDim2.new(1, -288, 0, 30) }, 8)
			UI.label(setup, { Text = "Hitbox", TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(12, 132), Size = UDim2.fromOffset(44, 30) })
			ui.boxInfo = UI.label(setup, { TextColor3 = UI.T("Muted"), TextSize = 12, Position = UDim2.fromOffset(60, 132), Size = UDim2.fromOffset(200, 30),
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.boxFit = UI.button(setup, "Learn", { Position = UDim2.fromOffset(262, 133), Size = UDim2.fromOffset(56, 28), TextSize = 12 })
			ui.boxClear = UI.button(setup, "Off", { Position = UDim2.fromOffset(322, 133), Size = UDim2.fromOffset(44, 28), TextSize = 12 })
			UI.label(setup, { Text = "Sound", TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(386, 132), Size = UDim2.fromOffset(44, 30) })
			ui.soundPick = UI.button(setup, "any", { Position = UDim2.fromOffset(432, 133), Size = UDim2.new(1, -444, 0, 28), TextSize = 12, FontFace = UI.MONO,
				TextTruncate = Enum.TextTruncate.AtEnd })
			ui.mNudge = UI.row(setup, { Position = UDim2.fromOffset(12, 172), Size = UDim2.new(1, -150, 0, 30) }, 4)
			ui.delete = UI.danger(setup, "Delete Move", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 172), Size = UDim2.fromOffset(104, 30), TextSize = 12 })
			ui.mStatus = UI.row(setup, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -124, 0, 177), Size = UDim2.fromOffset(240, 20) }, 5, Enum.HorizontalAlignment.Right)
			local function labeled(text, placeholder, order, width)
				local holder = UI.row(ui.inputs, { AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), LayoutOrder = order }, 6)
				UI.label(holder, { Text = text, TextColor3 = UI.T("SubText"), TextSize = 12, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), LayoutOrder = 1 })
				local box = UI.field(holder, { PlaceholderText = placeholder, Size = UDim2.fromOffset(width or 60, 28), LayoutOrder = 2, FontFace = UI.MONO })
				return holder, box
			end
			local holdDefault = Options.UParryHold and tostring(Options.UParryHold.Value) or "400"
			ui.holdField, ui.holdBox = labeled("Hold ms", holdDefault, 1, 62)
			ui.closeField, ui.closeBox = labeled("Close studs", "10", 2, 52)
			ui.baseField, ui.baseBox = labeled("Base s", "0.300", 3, 62)
			ui.perField, ui.perBox = labeled("ms/stud", "0.0", 4, 52)
			ui.fit = UI.button(ui.inputs, "Fit", { Size = UDim2.fromOffset(46, 28), LayoutOrder = 5, TextSize = 12 })
			s.paintMode = UI.segmented(setup, { { "timed", "Timed" }, { "rush", "Rush" }, { "dash", "Dash" }, { "range", "Range" } },
				{ Position = UDim2.fromOffset(56, 52), Size = UDim2.fromOffset(300, 30) }, function(value)
					local entry = entryFor(B.selected)
					if not entry then
						return
					end
					local move = AP.moveOf(entry.id, entry.name)
					move.mode = value
					if value == "range" and not move.base then
						local base, per = AP.fitRange(entry.hits)
						move.base, move.perStud = base and math.max(base - AP.BAKE, 0) or nil, per
					end
					if value == "dash" and not move.close then
						move.close = 10
					end
					AP.changed(entry.id)
					s.refresh()
				end)
			s.paintPress = UI.segmented(setup, { { "tap", "Tap" }, { "hold", "Hold" }, { "dodge", "Dodge" } }, { Position = UDim2.fromOffset(56, 92), Size = UDim2.fromOffset(210, 30) },
				function(value)
					local entry = entryFor(B.selected)
					if not entry then
						return
					end
					local move = AP.moveOf(entry.id, entry.name)
					move.press = value
					AP.changed(entry.id)
					s.refresh()
				end)
			local function numberInto(box, key, factor, lo, hi, integer)
				box.FocusLost:Connect(function()
					local entry = entryFor(B.selected)
					if not entry then
						return
					end
					local move = AP.moveOf(entry.id, entry.name)
					local value = tonumber((box.Text:gsub("[^%d%.]", "")))
					if value then
						value = math.clamp(value * factor, lo, hi)
						move[key] = integer and math.floor(value) or value
					else
						move[key] = nil
					end
					AP.changed(entry.id)
					s.refresh()
				end)
			end
			numberInto(ui.closeBox, "close", 1, 2, 200)
			numberInto(ui.baseBox, "base", 1, 0, 30)
			numberInto(ui.perBox, "perStud", 0.001, 0, 1)
			numberInto(ui.holdBox, "hold", 1, 30, 5000, true)
			ui.boxFit.MouseButton1Click:Connect(function()
				local entry = entryFor(B.selected)
				local box, n = AP.fitBox(entry and entry.hits or {})
				if not box then
					return UI.notify("Get hit by it first so it can learn where it reaches")
				end
				local move = AP.moveOf(entry.id, entry.name)
				move.box = box
				AP.changed(entry.id)
				UI.notify(string.format("Learned the hitbox from %d hit%s", n, n == 1 and "" or "s"))
				s.refresh()
			end)
			ui.boxClear.MouseButton1Click:Connect(function()
				local move = B.selected and AP.moves[B.selected]
				if move then
					move.box = nil
					AP.changed(B.selected)
					s.refresh()
				end
			end)
			ui.soundPick.MouseButton1Click:Connect(function()
				local entry = entryFor(B.selected)
				if not entry then
					return
				end
				local cues = AP.soundCues(entry)
				if #cues == 0 then
					return UI.notify("No sounds heard from this move yet. Watch it play with this open.")
				end
				local move = AP.moveOf(entry.id, entry.name)
				local at = 0
				for i, c in ipairs(cues) do
					if c.id == move.sound then
						at = i
					end
				end
				local nextCue = cues[at + 1]
				move.sound = nextCue and nextCue.id or nil
				AP.changed(entry.id)
				s.refresh()
			end)
		end

		local moves = tabFrame("moves", true)
		do
			local panel = UI.panel(moves, 0, 0, W - 24, BODY)
			ui.mvSearch = UI.field(panel, { PlaceholderText = "Search saved moves", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(300, 30) })
			ui.mvTools = UI.row(panel, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(400, 30) }, 6,
				Enum.HorizontalAlignment.Right)
			ui.allOn = UI.button(ui.mvTools, "All On", { Size = UDim2.fromOffset(72, 30), TextSize = 12, LayoutOrder = 1 })
			ui.allOff = UI.button(ui.mvTools, "All Off", { Size = UDim2.fromOffset(72, 30), TextSize = 12, LayoutOrder = 2 })
			ui.mvList = UI.scroll(panel, { Position = UDim2.fromOffset(8, 52), Size = UDim2.new(1, -16, 1, -104) }, Settings.compact and 3 or 5)
			UI.new("Frame", { BackgroundColor3 = UI.T("Divider"), BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -48), Size = UDim2.new(1, -24, 0, 1) }, panel)
			ui.mvCount = UI.label(panel, { TextColor3 = UI.T("Muted"), TextSize = 12, Position = UDim2.new(0, 14, 1, -40), Size = UDim2.new(0.4, 0, 0, 30) })
			ui.mvActions = UI.row(panel, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 1, -40), Size = UDim2.fromOffset(460, 30) }, 6,
				Enum.HorizontalAlignment.Right)
			ui.exportAll = UI.button(ui.mvActions, "Export All", { Size = UDim2.fromOffset(100, 30), TextSize = 12, LayoutOrder = 1 })
			ui.exportChanged = UI.button(ui.mvActions, "Export Changes", { Size = UDim2.fromOffset(150, 30), TextSize = 12, LayoutOrder = 2 })
			ui.importOpen = UI.primary(ui.mvActions, "Import", { Size = UDim2.fromOffset(90, 30), TextSize = 12, LayoutOrder = 3 })
		end

		local parry = tabFrame("parry", true)
		s.optionPaint = {}
		local function keyChip(parent, props, getValue, setValue)
			local chip = UI.button(parent, UI.keyLabel(getValue()), props)
			chip.FontFace = UI.MONO
			chip.TextSize = 12
			local function paint()
				if B.picking and B.picking.chip == chip then
					chip.Text = "press a key…"
					chip.TextColor3 = UI.T("Accent")
				else
					chip.Text = UI.keyLabel(getValue())
					chip.TextColor3 = typeof(getValue()) == "EnumItem" and UI.T("Text") or UI.T("Muted")
				end
			end
			chip.MouseButton1Click:Connect(function()
				if B.picking and B.picking.chip == chip then
					return
				end
				local old = B.picking
				B.picking = { chip = chip, set = setValue, paint = paint, at = os.clock() }
				if old and old.paint then
					pcall(old.paint)
				end
				paint()
			end)
			paint()
			return chip, paint
		end
		s.keyChip = keyChip
		local function optionRow(panel, option, y, width)
			local spec = option.Spec or {}
			local row = UI.new("Frame", { BackgroundColor3 = UI.T("Panel"), Position = UDim2.fromOffset(12, y), Size = UDim2.fromOffset(width - 24, 48) }, panel)
			UI.corner(row, 8)
			UI.stroke(row, UI.T("Border"))
			UI.label(row, { Text = spec.Text or option.Id, FontFace = UI.SEMI, TextSize = 13, Position = UDim2.fromOffset(14, 7), Size = UDim2.new(1, -220, 0, 18),
				TextTruncate = Enum.TextTruncate.AtEnd })
			UI.label(row, { Text = spec.Desc or "", TextColor3 = UI.T("Muted"), TextSize = 11, Position = UDim2.fromOffset(14, 25), Size = UDim2.new(1, -220, 0, 15),
				TextTruncate = Enum.TextTruncate.AtEnd })
			local paint
			if option.Type == "Toggle" then
				local switch = UI.new("TextButton", { AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0),
					Size = UDim2.fromOffset(38, 20) }, row)
				UI.corner(switch, 10)
				local edge = UI.stroke(switch)
				local knob = UI.new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14) }, switch)
				UI.corner(knob, 7)
				paint = function()
					local on = option.Value == true
					switch.BackgroundColor3 = on and UI.T("Accent") or UI.T("Field")
					edge.Color = on and UI.T("Accent") or UI.T("BorderLight")
					knob.BackgroundColor3 = on and UI.WHITE or UI.T("Muted")
					knob.Position = UDim2.new(0, on and 28 or 10, 0.5, 0)
				end
				switch.MouseButton1Click:Connect(function()
					option:SetValue(not option.Value)
					paint()
					s.drawFoot()
				end)
			elseif option.Type == "Slider" then
				local value = UI.label(row, { FontFace = UI.MONO, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(62, 18) })
				local track = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = UI.T("Field"), AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.fromOffset(120, 6) }, row)
				UI.corner(track, 3)
				UI.stroke(track, UI.T("BorderLight"))
				local fill = UI.new("Frame", { BackgroundColor3 = UI.T("Accent"), BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, track)
				UI.corner(fill, 3)
				local knob = UI.new("Frame", { BackgroundColor3 = UI.WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12), ZIndex = 2 }, track)
				UI.corner(knob, 6)
				paint = function()
					local frac = (option.Value - spec.Min) / math.max(spec.Max - spec.Min, 1e-6)
					frac = math.clamp(frac, 0, 1)
					fill.Size = UDim2.fromScale(frac, 1)
					knob.Position = UDim2.new(frac, 0, 0.5, 0)
					local digits = spec.Rounding or 0
					value.Text = string.format("%." .. digits .. "f", option.Value) .. (spec.Suffix or "")
				end
				local function setFrom(x)
					local frac = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
					option:SetValue(spec.Min + frac * (spec.Max - spec.Min))
					paint()
				end
				track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						s.sliding = setFrom
						setFrom(input.Position.X)
					end
				end)
			elseif option.Type == "Keybind" then
				local _, chipPaint = keyChip(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(110, 28) },
					function()
						return option.Value
					end, function(key)
						option:SetValue(key)
					end)
				paint = chipPaint
			end
			if paint then
				paint()
				s.optionPaint[option.Id] = paint
			end
		end
		do
			local half = math.floor((W - 24 - 10) / 2)
			local function section(x, title, sub, key)
				local panel = UI.panel(parry, x, 0, half, BODY)
				UI.label(panel, { Text = title, FontFace = UI.SEMI, TextSize = 15, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 20) })
				UI.label(panel, { Text = sub, TextColor3 = UI.T("Muted"), TextSize = 12, Position = UDim2.fromOffset(16, 35), Size = UDim2.new(1, -32, 0, 16) })
				local rule = UI.new("Frame", { BackgroundColor3 = UI.T("BorderLight"), BorderSizePixel = 0, Position = UDim2.fromOffset(14, 60), Size = UDim2.new(1, -28, 0, 1) }, panel)
				UI.new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, rule)
				local y = 72
				for _, entry in ipairs(AP.SPEC or {}) do
					local option = Options[entry[1]]
					if option and (option.Spec or entry[2]).Section == key then
						optionRow(panel, option, y, half)
						y += 56
					end
				end
				return panel
			end
			section(0, "Auto Parry", "Inputs and timing", "main")
			section(half + 10, "Checks", "When it's allowed to block", "checks")
		end

		ui.shade = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
			Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 20 }, win)
		UI.corner(ui.shade, 12)
		ui.pop = UI.new("Frame", { BackgroundColor3 = UI.T("Chrome"), Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(480, 280), ZIndex = 21 }, win)
		UI.corner(ui.pop, 10)
		UI.stroke(ui.pop)
		UI.label(ui.pop, { Text = "Import Moves", FontFace = UI.SEMI, TextSize = 15, Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -32, 0, 20), ZIndex = 22 })
		UI.label(ui.pop, { Text = "Paste an export. Moves with the same animation get replaced, everything else stays.", TextColor3 = UI.T("Muted"),
			TextSize = 12, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 16), ZIndex = 22, TextTruncate = Enum.TextTruncate.AtEnd })
		ui.paste = UI.field(ui.pop, { MultiLine = true, TextWrapped = true, TextSize = 11, FontFace = UI.MONO, PlaceholderText = "{ ... }",
			TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(16, 60), Size = UDim2.new(1, -32, 1, -112), ZIndex = 22 })
		ui.apply = UI.primary(ui.pop, "Import", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -14), Size = UDim2.fromOffset(90, 30), ZIndex = 22 })
		ui.cancel = UI.button(ui.pop, "Cancel", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -114, 1, -14), Size = UDim2.fromOffset(80, 30), ZIndex = 22 })

		ui.settings = UI.new("Frame", { BackgroundColor3 = UI.T("Chrome"), Visible = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 48),
			Size = UDim2.fromOffset(350, 322), ZIndex = 30 }, win)
		UI.corner(ui.settings, 10)
		UI.stroke(ui.settings)
		UI.label(ui.settings, { Text = "Builder Settings", FontFace = UI.SEMI, TextSize = 14, Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 20), ZIndex = 31 })
		s.settingPaint = {}
		local function setting(order, text, key, items, rebuild)
			local y = 40 + (order - 1) * 40
			UI.label(ui.settings, { Text = text, TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(14, y), Size = UDim2.fromOffset(100, 30), ZIndex = 31 })
			local paint = UI.segmented(ui.settings, items, { Position = UDim2.fromOffset(112, y), Size = UDim2.fromOffset(224, 30), ZIndex = 31 }, function(value)
				Settings[key] = value
				saveSettings()
				if rebuild then
					B.rebuild()
				else
					s.paintSettings()
					s.refresh()
				end
			end)
			s.settingPaint[key] = paint
		end
		setting(1, "Size", "scale", { { 0.85, "Small" }, { 1, "Normal" }, { 1.15, "Big" } }, true)
		setting(2, "3D Preview", "preview", { { true, "On" }, { false, "Off" } }, true)
		setting(3, "List Rows", "compact", { { false, "Roomy" }, { true, "Compact" } }, true)
		setting(4, "Nudge Step", "nudge", { { 10, "10 ms" }, { 20, "20 ms" }, { 50, "50 ms" } })
		setting(5, "Opens On", "tab", { { "parry", "Parry" }, { "auto", "Auto" }, { "manual", "Manual" }, { "moves", "Moves" } })
		UI.label(ui.settings, { Text = "Hide Key", TextColor3 = UI.T("SubText"), TextSize = 12, Position = UDim2.fromOffset(14, 240), Size = UDim2.fromOffset(100, 30) })
		local _, hidePaint = keyChip(ui.settings, { Position = UDim2.fromOffset(112, 241), Size = UDim2.fromOffset(120, 28) }, function()
			return UI.keyFrom(Settings.hideKey)
		end, function(key)
			Settings.hideKey = typeof(key) == "EnumItem" and (tostring(key.EnumType) .. "." .. key.Name) or "None"
			saveSettings()
		end)
		s.hidePaint = hidePaint
		ui.reset = UI.button(ui.settings, "Reset", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.fromOffset(70, 26), TextSize = 12 })
		ui.unload = UI.danger(ui.settings, "Unload Script", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -12), Size = UDim2.fromOffset(110, 26), TextSize = 12 })
		ui.unload.MouseButton1Click:Connect(function()
			if Library and type(Library.Unload) == "function" then
				Library:Unload()
			else
				B.destroy()
			end
		end)
		ui.reset.MouseButton1Click:Connect(function()
			for key, value in pairs(DEFAULTS) do
				Settings[key] = value
			end
			saveSettings()
			B.rebuild()
		end)
		function s.paintSettings()
			for key, paint in pairs(s.settingPaint) do
				paint(Settings[key])
			end
			if s.hidePaint then
				s.hidePaint()
			end
		end

		local function nudgeRow(holder, id)
			UI.clear(holder)
			UI.label(holder, { Text = "Nudge", TextColor3 = UI.T("SubText"), TextSize = 12, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), LayoutOrder = 1 })
			for i, sign in ipairs({ -1, 1 }) do
				local b = UI.button(holder, (sign < 0 and "−" or "+") .. Settings.nudge .. " ms", { Size = UDim2.fromOffset(64, 28), TextSize = 12, FontFace = UI.MONO, LayoutOrder = 1 + i })
				b.MouseButton1Click:Connect(function()
					AP.nudge(id, sign * Settings.nudge)
					s.refresh()
				end)
			end
		end

		local function listRow(parent, order, entry)
			local move = AP.moves[entry.id]
			local picked = entry.id == B.selected
			local h = Settings.compact and 32 or 46
			local row = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = picked and UI.T("Button") or UI.T("Panel"),
				Size = UDim2.new(1, 0, 0, h), LayoutOrder = order }, parent)
			UI.corner(row, 7)
			local edge = UI.stroke(row, picked and UI.T("Accent") or UI.T("Border"))
			if picked then
				local tab = UI.new("Frame", { BackgroundColor3 = UI.T("Accent"), BorderSizePixel = 0, Position = UDim2.fromOffset(0, math.floor(h / 4)),
					Size = UDim2.new(0, 2, 0.5, 0) }, row)
				UI.corner(tab, 1)
			else
				row.MouseEnter:Connect(function()
					edge.Color = UI.T("BorderLight")
				end)
				row.MouseLeave:Connect(function()
					edge.Color = UI.T("Border")
				end)
			end
			if Settings.compact then
				UI.label(row, { Text = tostring(entry.name), FontFace = UI.SEMI, TextSize = 13, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd })
			else
				UI.label(row, { Text = tostring(entry.name), FontFace = UI.SEMI, TextSize = 13, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -110, 0, 18),
					TextTruncate = Enum.TextTruncate.AtEnd })
				UI.label(row, { Text = (entry.who and (tostring(entry.who) .. "  ·  ") or "") .. entry.id, TextColor3 = UI.T("Muted"), TextSize = 11,
					Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -110, 0, 15), TextTruncate = Enum.TextTruncate.AtEnd })
			end
			local logged = AP.logged[entry.id] ~= nil
			local holder = UI.row(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, logged and -34 or -10, 0.5, 0), Size = UDim2.fromOffset(100, 20) }, 4,
				Enum.HorizontalAlignment.Right)
			if logged then
				local x = UI.new("TextButton", { AutoButtonColor = false, BackgroundTransparency = 1, Text = "×", FontFace = UI.SEMI, TextSize = 17,
					TextColor3 = UI.T("Muted"), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(22, 22), Name = "Remove" }, row)
				x.MouseEnter:Connect(function()
					x.TextColor3 = UI.T("Text")
				end)
				x.MouseLeave:Connect(function()
					x.TextColor3 = UI.T("Muted")
				end)
				x.MouseButton1Click:Connect(function()
					AP.forget(entry.id)
					if B.selected == entry.id then
						B.selected = nil
					end
					s.refresh()
				end)
			end
			if move and AP.isUsed(move) then
				UI.modePill(holder, move)
			elseif #entry.hits > 0 then
				UI.pill(holder, #entry.hits .. (#entry.hits == 1 and " hit" or " hits"), UI.T("SubText"))
			else
				UI.pill(holder, "new", UI.T("Muted"))
			end
			row.MouseButton1Click:Connect(function()
				select(entry.id)
			end)
			return row
		end

		function s.drawList()
			UI.clear(ui.list)
			local rows = listRows()
			for i, entry in ipairs(rows) do
				listRow(ui.list, i, entry)
			end
			if #rows == 0 then
				local text
				if B.search ~= "" then
					text = "Nothing matches."
				elseif B.filter == "hit" then
					text = "Nothing has hit you yet.\nGet hit while this is open."
				elseif B.filter == "saved" then
					text = "No saved moves for this game yet."
				else
					text = "Nothing logged yet.\nAttacks near you show up here."
				end
				UI.label(ui.list, { Text = text, TextColor3 = UI.T("Muted"), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 60) })
			end
			ui.count.Text = string.format("%d shown", #rows)
		end

		local function conf(score, n)
			if n < 2 then
				return "only 1 hit", UI.T("Muted")
			elseif score >= 80 then
				return "high confidence", UI.T("Accent")
			elseif score >= 60 then
				return "medium", UI.T("SubText")
			end
			return "low", UI.T("Muted")
		end

		function s.drawAuto()
			local entry = entryFor(B.selected)
			ui.aEmpty.Visible = entry == nil
			ui.aDetail.Visible = entry ~= nil
			ui.aEmpty.Text = "Pick a move on the left.\n\nFight with this open: anything that hits you shows up with a suggested block time."
			if not entry then
				return
			end
			local result = AP.analyze(entry)
			ui.aTitle.Text = tostring(entry.name)
			ui.aSub.Text = string.format("%s  ·  id %s  ·  %d play%s", tostring(entry.who or "?"), entry.id, entry.plays or 0, (entry.plays or 0) == 1 and "" or "s")
			UI.clear(ui.aStatus)
			local move = AP.moves[entry.id]
			local saved = move and AP.isUsed(move)
			if saved then
				UI.statPill(ui.aStatus, entry.id, { LayoutOrder = 0 })
				UI.modePill(ui.aStatus, move, { LayoutOrder = 1 })
			else
				UI.pill(ui.aStatus, "not saved", UI.T("Muted"))
			end
			ui.aHitsHead.Text = result.n == 0 and "HITS" or string.format("HITS  ·  %d  ·  click one to drop it", result.n)
			UI.clear(ui.aHits)
			for i, h in ipairs(entry.hits) do
				local chip = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = UI.T("Field"), FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("SubText"),
					Text = string.format("%s s%s", UI.fmt(h.t), h.d0 and h.d0 < 1000 and string.format(" · %.0f st", h.d0) or ""),
					AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), LayoutOrder = i }, ui.aHits)
				UI.corner(chip, 11)
				UI.stroke(chip, UI.T("BorderLight"))
				UI.pad(chip, 8, 8)
				chip.MouseEnter:Connect(function()
					chip.Text = chip.Text .. "  ×"
				end)
				chip.MouseLeave:Connect(function()
					chip.Text = chip.Text:gsub("  ×$", "")
				end)
				chip.MouseButton1Click:Connect(function()
					local at = table.find(entry.hits, h)
					if at then
						table.remove(entry.hits, at)
						s.chosen = nil
						s.refresh()
					end
				end)
			end
			if #entry.hits == 0 then
				UI.label(ui.aHits, { Text = "No hits yet. Let it hit you a few times.", TextColor3 = UI.T("Muted"), TextSize = 12, AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 22) })
			end
			UI.clear(ui.sounds)
			local cues = result.sounds or AP.soundCues(entry)
			local current = AP.moves[entry.id] and AP.moves[entry.id].sound
			ui.soundsHead.Text = #cues == 0 and "SOUNDS  ·  none heard from them during this move yet"
				or "SOUNDS  ·  click one so it only blocks when that sound plays"
			for i, cue in ipairs(cues) do
				if i > 6 then
					break
				end
				local on = current == cue.id
				local chip = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = on and UI.T("Accent") or UI.T("Field"), FontFace = UI.MONO, TextSize = 11,
					TextColor3 = on and Color3.new(1, 1, 1) or UI.T("SubText"),
					Text = string.format("%s · %s s · %d/%d", cue.name or cue.id, UI.fmt(cue.t), cue.seen, cue.plays),
					AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 22), LayoutOrder = i }, ui.sounds)
				UI.corner(chip, 11)
				UI.stroke(chip, on and UI.T("Accent") or UI.T("BorderLight"))
				UI.pad(chip, 8, 8)
				chip.MouseButton1Click:Connect(function()
					local move = AP.moveOf(entry.id, entry.name)
					move.sound = (move.sound ~= cue.id) and cue.id or nil
					AP.changed(entry.id)
					s.refresh()
				end)
			end
			local option = nil
			if s.chosen then
				for _, o in ipairs(result.options) do
					if o.mode == s.chosen then
						option = o
					end
				end
			end
			option = option or result.best
			UI.clear(ui.others)
			UI.clear(ui.bestPills)
			ui.othersHead.Visible = #result.options > 1
			if option then
				local text, color = conf(option.score, result.n)
				local modeColor = UI.mode()
				UI.pill(ui.bestPills, UI.MODE_LABEL[option.mode], modeColor, { LayoutOrder = 1 })
				UI.pill(ui.bestPills, text, color, { LayoutOrder = 2 })
				UI.pill(ui.bestPills, option.score .. "%", UI.T("SubText"), { LayoutOrder = 3 })
				if option.box then
					UI.pill(ui.bestPills, "hitbox from " .. (result.boxHits or 0) .. " hit" .. ((result.boxHits or 0) == 1 and "" or "s"), UI.T("Accent"), { LayoutOrder = 4 })
				end
				ui.bestLabel.Text = option.label
				ui.why.Text = option.why
				ui.bestEdge.Color = modeColor:Lerp(UI.T("BorderLight"), 0.45)
				ui.bestBar.BackgroundColor3 = modeColor
				for i, o in ipairs(result.options) do
					if o ~= option then
						local oc = UI.mode()
						local b = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = UI.T("Panel"), Size = UDim2.new(1, 0, 0, 30), LayoutOrder = i }, ui.others)
						UI.corner(b, 6)
						local edge = UI.stroke(b, UI.T("Border"))
						b.MouseEnter:Connect(function()
							edge.Color = UI.T("BorderLight")
						end)
						b.MouseLeave:Connect(function()
							edge.Color = UI.T("Border")
						end)
						UI.pill(b, UI.MODE_LABEL[o.mode], oc, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0) })
						UI.label(b, { Text = o.label, TextSize = 12, Position = UDim2.fromOffset(78, 0), Size = UDim2.new(1, -170, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
						local back = UI.new("Frame", { BackgroundColor3 = UI.T("Border"), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0),
							Size = UDim2.fromOffset(46, 4) }, b)
						UI.corner(back, 2)
						local fill = UI.new("Frame", { BackgroundColor3 = oc, BorderSizePixel = 0, Size = UDim2.new(math.clamp(o.score / 100, 0, 1), 0, 1, 0) }, back)
						UI.corner(fill, 2)
						UI.label(b, { Text = o.score .. "%", FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("Muted"), TextXAlignment = Enum.TextXAlignment.Right,
							AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(32, 16) })
						b.MouseButton1Click:Connect(function()
							s.chosen = o.mode
							s.refresh()
						end)
					end
				end
			else
				UI.pill(ui.bestPills, "waiting for hits", UI.T("Muted"))
				ui.bestLabel.Text = saved and "Already saved" or "Nothing to suggest yet"
				ui.why.Text = saved and "Get hit by it again to get a fresh suggestion." or "Get hit by this move a few times while this is open."
				ui.bestEdge.Color = UI.T("Border")
				ui.bestBar.BackgroundColor3 = UI.T("BorderLight")
			end
			s.option = option
			ui.save.Visible = option ~= nil
			ui.toManual.Position = UDim2.new(0, option and 156 or 16, 1, -96)
			ui.aNudge.Visible = saved
			if saved then
				nudgeRow(ui.aNudge, entry.id)
			end
			local stat = AP.stats and AP.stats[entry.id]
			if saved and stat and (stat.misses or 0) > 0 then
				ui.tip.Text = string.format("Still got hit %d time%s right after blocking. If it keeps happening, nudge it earlier.", stat.misses,
					stat.misses == 1 and "" or "s")
			elseif saved then
				ui.tip.Text = "Saved. Turn on Auto Parry and fight: the parried count shows how it's doing."
			else
				ui.tip.Text = "Saving uses the best setup above. Pick one of the other ways first to save that instead."
			end
		end

		local function lengthOf(entry)
			local move = AP.moves[entry.id]
			local len = math.max(entry.length or 0, ui.preview and ui.preview:length() or 0, 0.5)
			for _, t in ipairs(move and move.t or {}) do
				len = math.max(len, t + 0.1)
			end
			if move and move.mode == "range" and move.base then
				len = math.max(len, math.min(move.base, 5) + 0.1)
			end
			for _, h in ipairs(entry.hits) do
				len = math.max(len, h.t + 0.1)
			end
			return len
		end
		function s.setTime(t)
			B.t = math.clamp(t, 0, B.len or 1)
			if ui.preview then
				ui.preview:pose(B.t)
			end
			ui.head.Position = UDim2.new(B.len and B.t / B.len or 0, 0, 0, -3)
			ui.blockAt.Text = "Block At " .. UI.fmt(B.t) .. " s"
			ui.time.Text = string.format("%s / %s s", UI.fmt(B.t), UI.fmt(B.len or 0))
		end
		function s.drawTimeline(entry)
			UI.clear(ui.ticks)
			UI.clear(ui.grid)
			UI.clear(ui.scale)
			if not entry then
				B.len = nil
				ui.time.Text = ""
				return
			end
			local move = AP.moves[entry.id]
			local len = lengthOf(entry)
			B.len = len
			for i = 1, 19 do
				UI.new("Frame", { BackgroundColor3 = UI.T("BorderLight"), BackgroundTransparency = i % 5 == 0 and 0.2 or 0.65, BorderSizePixel = 0,
					Position = UDim2.new(i / 20, 0, i % 5 == 0 and 0 or 0.55, 0), Size = UDim2.new(0, 1, i % 5 == 0 and 1 or 0.45, 0) }, ui.grid)
			end
			for i = 0, 4 do
				UI.label(ui.scale, { Text = string.format("%.2fs", len * i / 4), FontFace = UI.MONO, TextSize = 10, TextColor3 = UI.T("Muted"),
					AnchorPoint = Vector2.new(i == 0 and 0 or (i == 4 and 1 or 0.5), 0), Position = UDim2.new(i / 4, 0, 0, 0), Size = UDim2.fromOffset(50, 13),
					TextXAlignment = i == 0 and Enum.TextXAlignment.Left or (i == 4 and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center) })
			end
			for _, h in ipairs(entry.hits) do
				local dot = UI.new("Frame", { BackgroundColor3 = UI.T("SubText"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h.t / len, 0, 1, -8),
					Size = UDim2.fromOffset(7, 7) }, ui.ticks)
				UI.corner(dot, 4)
			end
			local markColor = UI.mode()
			for _, t in ipairs(move and move.t or {}) do
				UI.new("Frame", { BackgroundColor3 = markColor, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(t / len, 0, 0, 9),
					Size = UDim2.new(0, 2, 1, -13), ZIndex = 2 }, ui.ticks)
				local gem = UI.new("Frame", { BackgroundColor3 = markColor, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(t / len, 0, 0, 8),
					Size = UDim2.fromOffset(9, 9), Rotation = 45, ZIndex = 3 }, ui.ticks)
				UI.corner(gem, 2)
			end
			if move and move.mode == "range" and move.base then
				UI.new("Frame", { BackgroundColor3 = UI.T("Muted"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(math.min(move.base / len, 1), 0, 0, 4),
					Size = UDim2.new(0, 2, 1, -8) }, ui.ticks)
			end
			s.setTime(B.t)
		end
		function s.drawManual()
			local entry = entryFor(B.selected)
			local move = entry and AP.moves[entry.id]
			if ui.preview then
				local key = entry and (entry.id .. tostring(entry.rec)) or ""
				if key ~= s.loadedKey then
					s.loadedKey = key
					if entry then
						ui.preview:load(entry)
					else
						ui.preview:clear()
					end
				end
				ui.overlayTop.Text = entry and string.format("%s  ·  %d hit%s", tostring(entry.who or "?"), #entry.hits, #entry.hits == 1 and "" or "s") or ""
				ui.noRec.Text = not entry and "Pick an animation on the left." or ((not entry.rec) and "Watch this move once while this is open to get a 3D preview." or "")
			end
			ui.mTitle.Text = entry and tostring(entry.name) or "Pick an animation on the left"
			UI.clear(ui.mStatus)
			UI.clear(ui.chips)
			if entry then
				if move and AP.isUsed(move) then
					UI.modePill(ui.mStatus, move, { LayoutOrder = 2 })
					UI.statPill(ui.mStatus, entry.id, { LayoutOrder = 1 })
				else
					UI.pill(ui.mStatus, "not saved", UI.T("Muted"), { LayoutOrder = 2 })
				end
				local ts = hitTimes(entry)
				if #ts > 0 then
					UI.pill(ui.mStatus, "hits ~" .. UI.fmt(AP.median(ts)) .. " s", UI.T("SubText"), { LayoutOrder = 0 })
				end
			end
			local markColor = UI.mode()
			for i, t in ipairs(move and move.t or {}) do
				local chip = UI.new("TextButton", { AutoButtonColor = false, BackgroundColor3 = UI.T("Field"), FontFace = UI.MONO, TextSize = 11,
					TextColor3 = markColor, Text = UI.fmt(t) .. "  ×", AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), LayoutOrder = i }, ui.chips)
				UI.corner(chip, 12)
				UI.stroke(chip, markColor:Lerp(UI.T("BorderLight"), 0.55))
				UI.pad(chip, 9, 9)
				chip.MouseEnter:Connect(function()
					chip.TextColor3 = UI.T("Text")
				end)
				chip.MouseLeave:Connect(function()
					chip.TextColor3 = markColor
				end)
				chip.MouseButton1Click:Connect(function()
					local m = AP.moves[entry.id]
					if m and m.t[i] then
						table.remove(m.t, i)
						AP.changed(entry.id)
						s.refresh()
					end
				end)
			end
			if entry and (not move or #move.t == 0) then
				UI.label(ui.chips, { Text = "no block times yet · press B or Block At", TextColor3 = UI.T("Muted"), TextSize = 12, AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 24) })
			end
			local mode = move and move.mode or "timed"
			s.paintMode(mode)
			ui.modeHelp.Text = UI.MODE_HELP[mode]
			local press = move and move.press or "tap"
			s.paintPress(press)
			ui.holdField.Visible = press == "hold"
			ui.closeField.Visible = mode == "dash"
			ui.baseField.Visible, ui.perField.Visible, ui.fit.Visible = mode == "range", mode == "range", mode == "range"
			if not ui.closeBox:IsFocused() then
				ui.closeBox.Text = move and move.close and tostring(move.close) or ""
			end
			if not ui.baseBox:IsFocused() then
				ui.baseBox.Text = move and move.base and UI.fmt(move.base) or ""
			end
			if not ui.perBox:IsFocused() then
				ui.perBox.Text = move and move.perStud and string.format("%.1f", move.perStud * 1000) or ""
			end
			if not ui.holdBox:IsFocused() then
				ui.holdBox.Text = move and move.hold and tostring(move.hold) or ""
			end
			if move and move.box then
				local b = move.box
				ui.boxInfo.Text = string.format("%.0f × %.0f × %.0f st, only blocks inside it", b[4] - b[1], b[5] - b[2], b[6] - b[3])
				ui.boxInfo.TextColor3 = UI.T("Text")
			else
				local _, n = AP.fitBox(entry and entry.hits or {})
				ui.boxInfo.Text = n > 0 and string.format("off · %d hit%s to learn from", n, n == 1 and "" or "s") or "off · uses Max Range"
				ui.boxInfo.TextColor3 = UI.T("Muted")
			end
			ui.boxFit.Visible = entry ~= nil
			ui.boxClear.Visible = move ~= nil and move.box ~= nil
			local cue = move and move.sound
			local cueName = cue
			for _, c in ipairs(entry and AP.soundCues(entry) or {}) do
				if c.id == cue then
					cueName = c.name or c.id
				end
			end
			ui.soundPick.Text = cue and ("needs " .. tostring(cueName)) or "any (click to pick)"
			ui.soundPick.Visible = entry ~= nil
			ui.useHits.Visible = entry ~= nil and #entry.hits > 0
			ui.chips.Position = UDim2.fromOffset(ui.useHits.Visible and 252 or 164, 12)
			ui.clearTimes.Visible = move ~= nil and #move.t > 0
			ui.delete.Visible = move ~= nil and AP.isUsed(move)
			ui.blockAt.Visible = entry ~= nil
			ui.mNudge.Visible = move ~= nil and AP.isUsed(move)
			if ui.mNudge.Visible then
				nudgeRow(ui.mNudge, entry.id)
			end
			s.drawTimeline(entry)
		end

		function s.drawMoves()
			UI.clear(ui.mvList)
			local q = ui.mvSearch.Text:lower()
			local rows = {}
			for id, move in pairs(AP.moves) do
				if AP.isUsed(move) then
					local name = move.name or ("Anim " .. id)
					if q == "" or name:lower():find(q, 1, true) or id:find(q, 1, true) then
						table.insert(rows, { id = id, move = move, name = name })
					end
				end
			end
			table.sort(rows, function(a, b)
				return a.name:lower() < b.name:lower()
			end)
			local h = Settings.compact and 32 or 42
			for i, r in ipairs(rows) do
				local on = not r.move.off
				local row = UI.new("Frame", { BackgroundColor3 = UI.T("Panel"), Size = UDim2.new(1, 0, 0, h), LayoutOrder = i }, ui.mvList)
				UI.corner(row, 7)
				UI.stroke(row, UI.T("Border"))
				local switch = UI.new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = on and UI.T("Accent") or UI.T("Field"),
					AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(32, 18) }, row)
				UI.corner(switch, 9)
				UI.stroke(switch, on and UI.T("Accent") or UI.T("BorderLight"))
				local knob = UI.new("Frame", { BackgroundColor3 = on and UI.WHITE or UI.T("Muted"), AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, on and 23 or 9, 0.5, 0), Size = UDim2.fromOffset(12, 12) }, switch)
				UI.corner(knob, 6)
				UI.label(row, { Text = r.name, FontFace = UI.SEMI, TextSize = 13, TextColor3 = on and UI.T("Text") or UI.T("Muted"), Position = UDim2.fromOffset(56, 0),
					Size = UDim2.new(0.4, -56, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
				local times = {}
				if r.move.mode == "range" then
					table.insert(times, string.format("%s s + %.1f ms/st", UI.fmt(r.move.base), (r.move.perStud or 0) * 1000))
				else
					for _, t in ipairs(r.move.t) do
						table.insert(times, UI.fmt(t))
					end
				end
				UI.label(row, { Text = table.concat(times, ", ") .. (r.move.mode == "dash" and string.format("  ·  %d st", r.move.close or 10) or "")
					.. (r.move.box and "  ·  hitbox" or "") .. (r.move.sound and "  ·  sound" or ""),
					FontFace = UI.MONO, TextSize = 11, TextColor3 = UI.T("SubText"), Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, -250, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd })
				local holder = UI.row(row, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(240, 24) }, 6,
					Enum.HorizontalAlignment.Right)
				UI.statPill(holder, r.id, { LayoutOrder = 1 })
				UI.modePill(holder, r.move, { LayoutOrder = 2 })
				local edit = UI.button(holder, "Edit", { Size = UDim2.fromOffset(46, 24), TextSize = 12, LayoutOrder = 3 })
				local del = UI.danger(holder, "×", { Size = UDim2.fromOffset(26, 24), TextSize = 16, LayoutOrder = 4 })
				switch.MouseButton1Click:Connect(function()
					r.move.off = (not r.move.off) or nil
					AP.changed(r.id)
					s.refresh()
				end)
				edit.MouseButton1Click:Connect(function()
					B.tab = "manual"
					select(r.id)
				end)
				local armed = false
				del.MouseButton1Click:Connect(function()
					if not armed then
						armed = true
						del.Text = "Delete?"
						del.Size = UDim2.fromOffset(64, 24)
						task.delay(2.5, function()
							if armed and del.Parent then
								armed = false
								del.Text = "×"
								del.Size = UDim2.fromOffset(26, 24)
							end
						end)
						return
					end
					AP.deleteMove(r.id)
					s.refresh()
				end)
			end
			if #rows == 0 then
				UI.label(ui.mvList, { Text = q == "" and "No saved moves for this game yet.\nUse Auto or Manual to make some, or Import a list." or "No moves match.",
					TextColor3 = UI.T("Muted"), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 60) })
			end
			local total = AP.savedCount()
			local changed = AP.changedCount and AP.changedCount() or 0
			ui.mvCount.Text = string.format("%d saved  ·  %d changed this session", total, changed)
			ui.exportChanged.Text = string.format("Export Changes (%d)", changed)
		end

		function s.drawFoot()
			UI.clear(ui.foot)
			local saved = AP.savedCount()
			UI.pill(ui.foot, saved .. " saved", UI.T("SubText"), { LayoutOrder = 1 })
			UI.pill(ui.foot, "ping " .. math.floor((AP.pingCache or 0) * 1000 + 0.5) .. " ms", UI.T("SubText"), { LayoutOrder = 2 })
			local on = Options.UAutoParry and Options.UAutoParry.Value
			UI.pill(ui.foot, on and "auto parry on" or "auto parry off", on and UI.T("Accent") or UI.T("Muted"), { LayoutOrder = 3 })
			if AP.readOnly then
				UI.pill(ui.foot, "not saving: file unreadable", UI.T("Text"), { LayoutOrder = 4 })
			end
			if B.tab == "parry" then
				ui.hint.Text = "settings save automatically  ·  " .. UI.keyLabel(UI.keyFrom(Settings.hideKey)) .. " hides this"
			elseif B.tab == "manual" then
				ui.hint.Text = "B marks a block  ·  ← → step a frame"
			elseif B.tab == "auto" then
				ui.hint.Text = "logging while this is open"
			else
				ui.hint.Text = "saved per game"
			end
		end

		function s.refresh()
			if not s.gui.Parent then
				return
			end
			s.paintTab(B.tab)
			s.paintFilter(B.filter)
			for name, frame in pairs(s.tabs) do
				frame.Visible = name == B.tab
			end
			side.Visible = B.tab ~= "moves" and B.tab ~= "parry"
			if side.Visible then
				s.drawList()
			end
			if B.tab == "parry" then
				for _, paint in pairs(s.optionPaint) do
					pcall(paint)
				end
			elseif B.tab == "auto" then
				s.drawAuto()
			elseif B.tab == "manual" then
				s.drawManual()
			else
				s.drawMoves()
			end
			s.drawFoot()
		end

		ui.close.MouseButton1Click:Connect(function()
			B.close()
			UI.notify("AP Builder hidden. Press " .. UI.keyLabel(UI.keyFrom(Settings.hideKey)) .. " to show it again.")
		end)
		ui.gear.MouseButton1Click:Connect(function()
			ui.settings.Visible = not ui.settings.Visible
			s.paintSettings()
		end)
		ui.search:GetPropertyChangedSignal("Text"):Connect(function()
			B.search = ui.search.Text
			s.drawList()
		end)
		ui.search.Text = B.search
		ui.mvSearch:GetPropertyChangedSignal("Text"):Connect(function()
			if B.tab == "moves" then
				s.drawMoves()
			end
		end)
		ui.clear.MouseButton1Click:Connect(function()
			table.clear(AP.logged)
			table.clear(AP.order)
			B.selected, AP.selectedId, s.chosen = nil, nil, nil
			s.refresh()
		end)
		ui.save.MouseButton1Click:Connect(function()
			local entry = entryFor(B.selected)
			local option = entry and (s.option or AP.analyze(entry).best)
			if not option then
				return UI.notify("Get hit by it a few times first")
			end
			AP.applyOption(entry, option)
			UI.notify("Saved " .. tostring(entry.name) .. ": " .. option.label)
			s.refresh()
		end)
		ui.toManual.MouseButton1Click:Connect(function()
			B.tab = "manual"
			s.refresh()
		end)
		local function markAt(t)
			local entry = entryFor(B.selected)
			if not entry or not t then
				return
			end
			AP.addMark(entry.id, entry.name, t)
			s.refresh()
		end
		ui.blockAt.MouseButton1Click:Connect(function()
			markAt(B.t)
		end)
		ui.useHits.MouseButton1Click:Connect(function()
			local entry = entryFor(B.selected)
			if not entry or #entry.hits == 0 then
				return
			end
			local groups = AP.clusters(hitTimes(entry))
			local move = AP.moveOf(entry.id, entry.name)
			move.t = {}
			for _, g in ipairs(groups) do
				table.insert(move.t, math.floor(math.max(AP.median(g) - AP.BAKE, 0) * 1000 + 0.5) / 1000)
			end
			AP.changed(entry.id)
			s.setTime(move.t[1] or 0)
			s.refresh()
		end)
		ui.clearTimes.MouseButton1Click:Connect(function()
			local move = B.selected and AP.moves[B.selected]
			if move then
				move.t = {}
				AP.changed(B.selected)
				s.refresh()
			end
		end)
		ui.fit.MouseButton1Click:Connect(function()
			local entry = entryFor(B.selected)
			local base, per, _, span = AP.fitRange(entry and entry.hits or {})
			if not base then
				return UI.notify("Get hit by it from a couple of distances first")
			end
			local move = AP.moveOf(entry.id, entry.name)
			move.base, move.perStud = math.max(base - AP.BAKE, 0), per
			AP.changed(entry.id)
			s.refresh()
			if span < 6 then
				UI.notify("All hits were about the same distance: get hit from closer and farther too")
			end
		end)
		ui.delete.MouseButton1Click:Connect(function()
			if B.selected then
				AP.deleteMove(B.selected)
				s.refresh()
			end
		end)
		local function setPlaying(on)
			B.playing = on
			ui.play.Text = on and "❚❚  Pause" or "▶  Play"
		end
		s.setPlaying = setPlaying
		ui.play.MouseButton1Click:Connect(function()
			if not B.playing and B.len and B.t >= B.len - 0.001 then
				s.setTime(0)
			end
			setPlaying(not B.playing)
		end)
		local function step(dir)
			setPlaying(false)
			s.setTime(B.t + dir / 60)
		end
		ui.back.MouseButton1Click:Connect(function()
			step(-1)
		end)
		ui.fwd.MouseButton1Click:Connect(function()
			step(1)
		end)
		local SPEEDS = { 1, 0.5, 0.25 }
		ui.speed.MouseButton1Click:Connect(function()
			local at = table.find(SPEEDS, B.speed) or 1
			B.speed = SPEEDS[at % #SPEEDS + 1]
			ui.speed.Text = tostring(B.speed) .. "x"
		end)
		ui.speed.Text = tostring(B.speed) .. "x"
		local function scrubTo(x)
			local abs, size = ui.track.AbsolutePosition.X, math.max(ui.track.AbsoluteSize.X, 1)
			setPlaying(false)
			s.setTime(math.clamp((x - abs) / size, 0, 1) * (B.len or 1))
		end
		ui.track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				s.scrubbing = true
				scrubTo(input.Position.X)
			end
		end)
		if ui.viewport then
			ui.viewport.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					s.orbitFrom = input.Position
				end
			end)
			ui.viewport.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					local p = ui.preview
					p.dist = math.clamp(p.dist * (input.Position.Z > 0 and 0.88 or 1.14), 5, 120)
					p:aim()
				end
			end)
		end
		table.insert(s.conns, UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if s.sliding then
				s.sliding(input.Position.X)
			elseif dragFrom then
				local d = input.Position - dragFrom
				root.Position = UDim2.fromOffset(dragPos.X.Offset + d.X, dragPos.Y.Offset + d.Y)
				B.pos = root.Position
			elseif s.scrubbing then
				scrubTo(input.Position.X)
			elseif s.orbitFrom and ui.preview then
				local d = input.Position - s.orbitFrom
				s.orbitFrom = input.Position
				local p = ui.preview
				p.yaw -= d.X * 0.012
				p.pitch = math.clamp(p.pitch + d.Y * 0.008, math.rad(-10), math.rad(80))
				p:aim()
			end
		end))
		table.insert(s.conns, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				s.scrubbing, s.orbitFrom, dragFrom, s.sliding = false, nil, nil, nil
			end
		end))
		table.insert(s.conns, UserInputService.InputBegan:Connect(function(input)
			local pick = B.picking
			if not pick or os.clock() - pick.at < 0.05 then
				return
			end
			local key = nil
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				key = false
			elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				key = input.KeyCode
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				key = input.UserInputType
			end
			if key == nil then
				return
			end
			B.picking = nil
			B.lastPickInput = input
			pcall(pick.set, key or nil)
			pcall(pick.paint)
			s.drawFoot()
		end))
		table.insert(s.conns, UserInputService.InputBegan:Connect(function(input, processed)
			if processed or UserInputService:GetFocusedTextBox() or B.tab ~= "manual" or B.picking or input == B.lastPickInput then
				return
			end
			local entry = entryFor(B.selected)
			if input.KeyCode == Enum.KeyCode.B then
				local play = entry and entry.lastPlay
				if play and play.track and play.track.IsPlaying then
					markAt(AP.trackTime(play))
				elseif entry then
					markAt(B.t)
				end
			elseif input.KeyCode == Enum.KeyCode.Left then
				step(-1)
			elseif input.KeyCode == Enum.KeyCode.Right then
				step(1)
			end
		end))
		table.insert(s.conns, RunService.RenderStepped:Connect(function(dt)
			if B.tab ~= "manual" then
				return
			end
			if B.playing and B.len then
				local t = B.t + dt * B.speed
				if t >= B.len then
					t = 0
				end
				s.setTime(t)
			end
			local entry = B.selected and AP.logged[B.selected]
			local play = entry and entry.lastPlay
			if play and play.track and play.track.IsPlaying and B.len then
				ui.live.Visible = true
				ui.live.Position = UDim2.new(math.clamp(AP.trackTime(play) / B.len, 0, 1), 0, 0, 0)
			elseif ui.live.Visible then
				ui.live.Visible = false
			end
		end))
		ui.exportAll.MouseButton1Click:Connect(function()
			local n = AP.savedCount()
			if n == 0 then
				return UI.notify("No saved moves to export yet")
			end
			AP.copy(AP.encode(false), n .. " moves")
		end)
		ui.exportChanged.MouseButton1Click:Connect(function()
			local n = AP.changedCount and AP.changedCount() or 0
			if n == 0 then
				return UI.notify("Nothing changed this session yet")
			end
			AP.copy(AP.encode(true), n .. " changed moves")
		end)
		ui.allOn.MouseButton1Click:Connect(function()
			for id, move in pairs(AP.moves) do
				if move.off then
					move.off = nil
					AP.touched[id] = true
				end
			end
			AP.changed()
			s.refresh()
		end)
		ui.allOff.MouseButton1Click:Connect(function()
			for id, move in pairs(AP.moves) do
				if AP.isUsed(move) and not move.off then
					move.off = true
					AP.touched[id] = true
				end
			end
			AP.changed()
			s.refresh()
		end)
		local function closePop()
			ui.pop.Visible, ui.shade.Visible = false, false
		end
		ui.importOpen.MouseButton1Click:Connect(function()
			ui.paste.Text = ""
			ui.pop.Visible, ui.shade.Visible = true, true
		end)
		ui.cancel.MouseButton1Click:Connect(closePop)
		ui.shade.MouseButton1Click:Connect(closePop)
		ui.apply.MouseButton1Click:Connect(function()
			local n = AP.import(ui.paste.Text)
			if n == 0 then
				return UI.notify("That isn't an exported moves list")
			end
			closePop()
			UI.notify("Imported " .. n .. " move" .. (n == 1 and "" or "s"))
			s.refresh()
		end)
		s.gui.Destroying:Connect(function()
			for _, conn in ipairs(s.conns) do
				conn:Disconnect()
			end
			s.spin:Cancel()
		end)
		s.alive = true
		task.spawn(function()
			local lastOn = nil
			while s.alive and s.gui.Parent do
				local on = Options.UAutoParry and Options.UAutoParry.Value
				if lastOn ~= on then
					lastOn = on
					AP.uiDirty = true
				end
				if AP.uiDirty then
					AP.uiDirty = false
					local focused = UserInputService:GetFocusedTextBox()
					if not (focused and focused:IsDescendantOf(s.gui)) then
						pcall(s.refresh)
					else
						AP.uiDirty = true
					end
				end
				task.wait(0.35)
			end
		end)
		return s
	end

	function B.open(keepTab)
		if S then
			return
		end
		if not keepTab then
			B.tab = Settings.tab
		end
		AP.builderOpen = true
		local ok, result = pcall(buildWindow)
		if not ok then
			AP.builderOpen = false
			for _, gui in ipairs(UI.gui():GetChildren()) do
				if gui.Name == "DexoriApBuilder" then
					gui:Destroy()
				end
			end
			UI.notify("AP Builder window failed to open: " .. tostring(result))
			if AP.paintButtons then
				AP.paintButtons()
			end
			return
		end
		S = result
		S.paintSettings()
		S.setPlaying(false)
		S.refresh()
		if AP.paintButtons then
			AP.paintButtons()
		end
	end
	function B.close()
		if not S then
			return
		end
		local s = S
		S = nil
		s.alive = false
		B.picking = nil
		B.playing = false
		AP.builderOpen = false
		pcall(function()
			s.gui:Destroy()
		end)
		if AP.paintButtons then
			AP.paintButtons()
		end
	end
	function B.rebuild()
		if S then
			B.close()
			B.open(true)
		end
	end
	function B.toggle()
		if S then
			B.close()
		else
			B.open()
		end
	end
	function B.isOpen()
		return S ~= nil
	end
	function B.select(id, tab)
		if tab then
			B.tab = tab
		end
		select(id)
	end
	function B.state()
		return { tab = B.tab, filter = B.filter, selected = B.selected, t = B.t, settings = Settings, window = S }
	end
	function B.setTab(tab)
		B.tab = tab
		if S then
			S.refresh()
		end
	end
	function B.setFilter(filter)
		B.filter = filter
		if S then
			S.refresh()
		end
	end
	function B.setTime(t)
		if S then
			S.setTime(t)
		else
			B.t = t
		end
	end
	function B.notify(text, duration)
		UI.toast(text, duration)
	end
	function B.isPicking(input)
		return B.picking ~= nil or (input ~= nil and input == B.lastPickInput)
	end
	function B.hideKeyName()
		return UI.keyLabel(UI.keyFrom(Settings.hideKey))
	end
	B.hideConn = UserInputService.InputBegan:Connect(function(input)
		if B.isPicking(input) or UserInputService:GetFocusedTextBox() then
			return
		end
		if UI.keyMatches(input, UI.keyFrom(Settings.hideKey)) then
			B.toggle()
		end
	end)
	function B.destroy()
		B.picking = nil
		B.close()
		if B.hideConn then
			B.hideConn:Disconnect()
			B.hideConn = nil
		end
		if Toasts.gui then
			Toasts.gui:Destroy()
			Toasts.gui = nil
		end
	end
	return B
end
