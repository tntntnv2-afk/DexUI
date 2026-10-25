local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()

local Env = (getgenv and getgenv()) or _G
if Env.DexoriShowcase and not Env.DexoriShowcase.Unloaded then
	Env.DexoriShowcase:Unload()
end
Env.DexoriShowcase = Library

local Options = Library.Options
Library:SetFolder("Dexori/showcase")

local Window = Library:CreateWindow({
	Title = "Dexori",
	Subtitle = "UI showcase",
	Footer = "Dexori UI v" .. Library.Version,
	ToggleKey = "RightControl",
})

local Tabs = {
	Controls = Window:AddTab("Controls"),
	Inputs = Window:AddTab("Inputs"),
	Visuals = Window:AddTab("Visuals"),
}

local Toggles = Tabs.Controls:AddLeftGroupbox("Toggles")
Toggles:AddToggle("DemoEnabled", { Text = "Enabled", Default = true })
Toggles:AddToggle("DemoKeyed", { Text = "With keybind" }):AddKeybind("DemoKeyedKey", { Default = "F" })
Toggles:AddToggle("DemoHold", { Text = "Hold to activate" }):AddKeybind("DemoHoldKey", { Default = "LeftShift", Mode = "Hold" })
Toggles:AddToggle("DemoTinted", { Text = "With colour" }):AddColorPicker("DemoTint", { Default = Color3.fromRGB(155, 92, 255) })
local Combo = Toggles:AddToggle("DemoCombo", { Text = "Colour and key" })
Combo:AddColorPicker("DemoComboColor", { Default = Color3.fromRGB(62, 230, 208) })
Combo:AddKeybind("DemoComboKey", { Default = "V" })

local Buttons = Tabs.Controls:AddLeftGroupbox("Buttons and labels")
local clicks = 0
local ClickLabel = Buttons:AddLabel("Clicks: 0")
Buttons:AddButton({
	Text = "Click me",
	Func = function()
		clicks = clicks + 1
		ClickLabel:SetText("Clicks: " .. clicks)
	end,
})
Buttons:AddDivider()
Buttons:AddButton({
	Text = "Send notification",
	Func = function()
		Library:Notify("Dexori", "Notification", 4)
	end,
})
Buttons:AddButton({
	Text = "Long notification",
	Func = function()
		Library:Notify("Dexori", "A longer notification message that wraps onto a second line.", 8)
	end,
})
Buttons:AddDivider("Labels")
Buttons:AddLabel("Plain label")
Buttons:AddLabel("<b>Bold</b>  <font color=\"#9b5cff\">Accent</font>  <i>Italic</i>")

local Sliders = Tabs.Controls:AddRightGroupbox("Sliders")
Sliders:AddSlider("DemoVolume", { Text = "Volume", Min = 0, Max = 100, Default = 72, Suffix = "%" })
Sliders:AddSlider("DemoDelay", { Text = "Delay", Min = 0, Max = 2, Default = 0.25, Rounding = 2, Suffix = "s" })
Sliders:AddSlider("DemoCount", { Text = "Items", Min = 1, Max = 10, Default = 4 })

local Dropdowns = Tabs.Controls:AddRightGroupbox("Dropdowns")
Dropdowns:AddDropdown("DemoMode", { Text = "Mode", Values = { "Legit", "Balanced", "Rage" }, Default = 2 })
Dropdowns:AddDropdown("DemoFruit", {
	Text = "Fruit",
	Values = { "Apple", "Banana", "Cherry", "Dragonfruit", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Pear", "Plum" },
	Placeholder = "Pick a fruit",
	AllowNull = true,
})
Dropdowns:AddDropdown("DemoTargets", {
	Text = "Targets",
	Values = { "Players", "Mobs", "Bosses", "Chests", "NPCs" },
	Multi = true,
	Default = { "Mobs", "Bosses" },
})

local Text = Tabs.Inputs:AddLeftGroupbox("Text input")
Text:AddInput("DemoName", { Text = "Name", Placeholder = "Name", Finished = true })
Text:AddInput("DemoAmount", { Text = "Amount", Placeholder = "0", Numeric = true })
Text:AddInput("DemoPlain", { Placeholder = "No title" })

local Live = Tabs.Inputs:AddLeftGroupbox("Live values")
local LiveLabel = Live:AddLabel("")
local function refreshLive()
	local targets = {}
	for name in pairs(Options.DemoTargets.Value) do
		table.insert(targets, name)
	end
	table.sort(targets)
	LiveLabel:SetText(table.concat({
		"Enabled: " .. tostring(Options.DemoEnabled.Value),
		"Volume: " .. tostring(Options.DemoVolume.Value) .. "%",
		"Mode: " .. tostring(Options.DemoMode.Value),
		"Fruit: " .. tostring(Options.DemoFruit.Value or "none"),
		"Targets: " .. (#targets > 0 and table.concat(targets, ", ") or "none"),
		"Name: " .. (Options.DemoName.Value ~= "" and Options.DemoName.Value or "(empty)"),
		"Accent: " .. Options.DemoAccentPreview.Value:ToHex():upper(),
	}, "\n"))
end

local Keys = Tabs.Inputs:AddRightGroupbox("Keybinds")
local KeyLabel = Keys:AddLabel("Keys: G, H, J")
Keys:AddKeybind("DemoToggleKey", {
	Text = "Toggle mode",
	Default = "G",
	Mode = "Toggle",
	Callback = function(state)
		KeyLabel:SetText("Toggle: " .. (state and "on" or "off"))
	end,
})
Keys:AddKeybind("DemoHoldKey2", {
	Text = "Hold mode",
	Default = "H",
	Mode = "Hold",
	Callback = function(held)
		KeyLabel:SetText(held and "Hold: held" or "Hold: released")
	end,
})
Keys:AddKeybind("DemoPressKey", {
	Text = "Press mode",
	Default = "J",
	Mode = "Press",
	Callback = function()
		Library:Notify("Dexori", "J pressed", 3)
	end,
})

local Colors = Tabs.Inputs:AddRightGroupbox("Colour pickers")
Colors:AddColorPicker("DemoAccentPreview", { Text = "Accent preview", Default = Library.Theme.Accent })
Colors:AddColorPicker("DemoGlass", { Text = "With transparency", Default = Color3.fromRGB(255, 111, 181), Transparency = 0.3 })
Colors:AddLabel("Enemy"):AddColorPicker("DemoEnemyColor", { Default = Color3.fromRGB(255, 60, 60), Title = "Enemy colour" })
Colors:AddLabel("Team"):AddColorPicker("DemoTeamColor", { Default = Color3.fromRGB(60, 180, 255), Title = "Team colour" })
Colors:AddButton({
	Text = "Use preview as UI accent",
	Func = function()
		Library:SetTheme({ Accent = Options.DemoAccentPreview.Value })
	end,
})

for _, id in ipairs({ "DemoEnabled", "DemoVolume", "DemoMode", "DemoFruit", "DemoTargets", "DemoName", "DemoAccentPreview" }) do
	Options[id]:OnChanged(refreshLive)
end
refreshLive()

local EspBox = Tabs.Visuals:AddLeftGroupbox("ESP preview")
local Preview = EspBox:AddESPPreview({ Tabs = { "Enemy", "Team" }, Height = 260 })
Preview:Set("Team", { Colour = Color3.fromRGB(60, 180, 255) })

local EspOptions = Tabs.Visuals:AddRightGroupbox("ESP options")
EspOptions:AddDropdown("DemoEspTab", { Text = "Editing", Values = { "Enemy", "Team" }, Default = "Enemy" })
local function editing()
	return Preview:GetTab(Options.DemoEspTab.Value or "Enemy")
end
Options.DemoEspTab:OnChanged(function(name)
	local tab = Preview:GetTab(name or "Enemy")
	if tab then
		tab:Select()
	end
end)
EspOptions:AddToggle("DemoEspOutline", { Text = "Outline", Default = true }):AddColorPicker("DemoEspOutlineColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "Outline colour",
	Callback = function(color)
		editing():SetColour(color)
	end,
})
Options.DemoEspOutline:OnChanged(function(on)
	editing():SetOutline(on)
end)
for _, part in ipairs({ { "Name", "Name" }, { "Distance", "Distance" }, { "HealthBg", "Health bar" }, { "Tracer", "Tracer" } }) do
	EspOptions:AddToggle("DemoEsp" .. part[1], {
		Text = part[2],
		Default = part[1] ~= "Tracer",
		Callback = function(on)
			editing():Set({ [part[1]] = on })
		end,
	})
end
Preview:OnTabChanged(function(name, tab)
	Options.DemoEspTab:SetValue(name)
	Options.DemoEspOutline:SetValue(tab._show.Outline)
	Options.DemoEspOutlineColor:SetValue(tab.Colour)
	for _, part in ipairs({ "Name", "Distance", "HealthBg", "Tracer" }) do
		Options["DemoEsp" .. part]:SetValue(tab._show[part] ~= false)
	end
end)
EspOptions:AddSlider("DemoEspHealth", {
	Text = "Health",
	Min = 0,
	Max = 100,
	Default = 72,
	Suffix = "%",
	Callback = function(value)
		editing():SetHealth(value / 100)
	end,
})
EspOptions:AddInput("DemoEspName", {
	Text = "Name tag",
	Placeholder = "Player name",
	Callback = function(value)
		editing():SetText("Name", value ~= "" and value or "Player")
	end,
})
EspOptions:AddInput("DemoEspUser", {
	Text = "Avatar user id",
	Placeholder = "UserId",
	Numeric = true,
	Finished = true,
	Callback = function(value)
		if tonumber(value) then
			Preview:SetUser(tonumber(value))
		end
	end,
})

local Custom = Tabs.Visuals:AddLeftGroupbox("Custom row")
local Canvas = Custom:AddCustom(54)
local Strip = Instance.new("Frame")
Strip.Size = UDim2.fromScale(1, 1)
Strip.BackgroundColor3 = Color3.new(1, 1, 1)
Strip.BorderSizePixel = 0
Strip.Parent = Canvas
local StripCorner = Instance.new("UICorner")
StripCorner.CornerRadius = UDim.new(0, 8)
StripCorner.Parent = Strip
local StripGradient = Instance.new("UIGradient")
StripGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 92, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 111, 181)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(62, 230, 208)),
})
StripGradient.Parent = Strip
local StripText = Instance.new("TextLabel")
StripText.BackgroundTransparency = 1
StripText.Size = UDim2.fromScale(1, 1)
StripText.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
StripText.TextSize = 15
StripText.TextColor3 = Color3.new(1, 1, 1)
StripText.Text = "Custom row"
StripText.Parent = Strip

Library:BuildSettingsTab(Window)

Library:Notify("Dexori", "Loaded. Right Control toggles the menu.", 5)
