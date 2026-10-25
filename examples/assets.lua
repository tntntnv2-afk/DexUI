local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
local gui = Library:CreateScreenGui("DexUIAssetTest")
local frame = Library:Create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(320, 140),
	Theme = { BackgroundColor3 = "Background" },
	Parent = gui,
}, { Library:Create("UICorner", { CornerRadius = UDim.new(0, 10) }) })
Library:DefineAsset("Wordmark", { Path = "assets/wordmark.png", Version = 1 })
Library:DefineAsset("Icon", { Path = "assets/icon_anim.png", Version = 1, Sheet = { Width = 96, Height = 96, Columns = 10, Frames = 60, Fps = 20 } })
local names = { "Wordmark", "Icon" }
for index, name in ipairs(names) do
	Library:Image(frame, name, {
		Position = UDim2.fromOffset(20 + (index - 1) * 150, 20),
		Size = UDim2.fromOffset(130, 100),
		OnFailed = function()
			warn("[DexUI] couldn't load asset " .. name)
		end,
	})
end
task.delay(10, function()
	Library:Unload()
end)
