local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/tntntnv2-afk/DexUI/main/loader.lua"))()
Library:DefineAsset("Wordmark", { Path = "assets/wordmark.png", Version = 1 })
Library:DefineAsset("Icon", { Path = "assets/icon_anim.png", Version = 1, Sheet = { Width = 96, Height = 96, Columns = 10, Frames = 60, Fps = 20 } })
local Window = Library:CreateWindow({ Title = "Dexori", Subtitle = "Asset test", Footer = "Dexori" })
local Box = Window:AddTab("Assets"):AddLeftGroupbox("Images")
local Area = Box:AddCustom(120)
for index, name in ipairs({ "Wordmark", "Icon" }) do
	Library:Image(Area, name, {
		Position = UDim2.fromOffset(10 + (index - 1) * 130, 10),
		Size = UDim2.fromOffset(110, 100),
		OnFailed = function()
			Library:Notify("Dexori", "Couldn't load " .. name .. " (is it in assets/?)", 5)
		end,
	})
end
