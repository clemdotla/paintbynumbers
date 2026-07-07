-- #region Rayfield
-- Edited version by clem.la
local Rayfield = loadstring(game:HttpGet('https://pastefy.app/xclbqwYp/raw'))()

local Window = Rayfield:CreateWindow({
	Name = "Paint by numbers | clem.la",
    ScriptID = "sid_4p1vdbqblhqn",
	Icon = "plane",
	LoadingTitle = "Coming up!",
	LoadingSubtitle = "by clem.la",
	ShowText = "Rayfield",
	Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

	ToggleUIKeybind = Enum.KeyCode.RightControl,

	DisableRayfieldPrompts = true,
	DisableBuildWarnings = false,

	ConfigurationSaving = {
		Enabled = true,
		FolderName = "clemdotla",
		FileName = "Paint by numbers"
	},
})

local Main = Window:CreateTab("Main", "badge")
local Fly = Window:CreateTab("Fly", "plane")
-- #endregion Rayfield

-- #region Defines
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Replicated = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")

local flyToggle = false
local flySpeed = 100
local moveDir = Vector3.new(0, 0, 0)

local att
local velocity
local orientation

local env = getgenv()["PaintByNumbers"]
env = env or { 
	Events = {},
	Variables = {},
    Parts = {}
}


-- #region Cleanup
local function Scrap(instance, callback)
    for i,v in instance do
        if type(v) == "table" then
            Scrap(v, callback)
            continue
        end
        pcall(function() callback(v) end)
    end
end

if env then
    if env.Events then
        Scrap(env.Events, function(event) event:Disconnect() end)
    end
    if env.Parts then
        Scrap(env.Parts, function(part) part:Destroy() end)
    end
end

local tempsave = env.AdInstances or {}
env = {Events = {}, Parts = {}, Variables = {}, AdInstances = tempsave}
getgenv()["PaintByNumbers"] = env

-- #endregion Cleanup

    function CleanParts()
        if env.Parts then
            for i,v in env.Parts do
                print("Destroying: ".. i)
                pcall(function() v:Destroy() end)
            end
        end
        env.Parts = {}
    end 

    function MakeParts()
        character = player.Character or player.CharacterAdded:Wait()
        root = character:WaitForChild("HumanoidRootPart")

        att = Instance.new("Attachment", root)
        att.Name = "FlyAttachment"
        env.Parts.att = att

        velocity = Instance.new("LinearVelocity")
        velocity.Name = "FlyVelocity"
        velocity.Attachment0 = att
        velocity.MaxForce = math.huge
        velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        velocity.Enabled = false
        velocity.Parent = root
        env.Parts.velocity = velocity

        orientation = Instance.new("AlignOrientation")
        orientation.Name = "FlyOrientation"
        orientation.Attachment0 = att
        orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
        orientation.Responsiveness = 200
        orientation.Enabled = false
        orientation.Parent = root
        env.Parts.orientation = orientation
    end

-- #endregion Parts

-- #region UI
local Toggle = Fly:CreateToggle({
    Name = "Toggle fly",
	CurrentValue = false,
	Callback = function(Value)
		flyToggle = Value
	end,
})

Fly:CreateKeybind({
	Name = "Toggle fly",
	CurrentKeybind = "Q",
	HoldToInteract = false,
	Flag = "FlyKeybind",
	Callback = function(Keybind)
		Toggle:Set(not flyToggle)
	end
})

Fly:CreateSlider({
    Name = "Speed",
    Range = {100, 300},
    Increment = 10,
    Suffix = "",
    CurrentValue = 100,
    Flag = "SpeedSlider",
    Callback = function(Value)
        flySpeed = Value
    end,
})
-- #endregion UI

-- #region Events
MakeParts()
env.Events.Respawn = player.CharacterAdded:Connect(function()
    CleanParts()
    MakeParts()
    Toggle:Set(false)
end)


local Keybinds = {
    W = Vector3.new(0, 0, -1),
    S = Vector3.new(0, 0, 1),
    A = Vector3.new(-1, 0, 0),
    D = Vector3.new(1, 0, 0),
    Space = Vector3.new(0, 1, 0),
    LeftControl = Vector3.new(0, -1, 0)
}

env.Events.InputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    local dir = Keybinds[input.KeyCode.Name]
	if not gp and dir then moveDir += dir end
end)
env.Events.InputEnded = UserInputService.InputEnded:Connect(function(input, gp)
	local dir = Keybinds[input.KeyCode.Name]
	if not gp and dir then moveDir -= dir end
end)

-- Loop every frame
env.Events.Loop = RunService.RenderStepped:Connect(function()
	if not flyToggle then
        velocity.Enabled = false
        orientation.Enabled = false
		return
	end
    
    velocity.Enabled = true
    orientation.Enabled = true

	local cam = workspace.CurrentCamera
	orientation.CFrame = cam.CFrame
    
	local dir = cam.CFrame:VectorToWorldSpace(moveDir)
	if dir.Magnitude > 0 then
		dir = dir.Unit
	end
    
    velocity.VectorVelocity = dir * flySpeed
end)


Main:CreateButton({
    Name = "Restart",
    Callback = function()
        -- loadstring(game:HttpGet('http://localhost/script/paintbynumbers'))()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/clemdotla/paintbynumbers/refs/heads/main/main.lua'))()
    end
})

-- Actual script

local HintModule = require(Replicated.Client.Core.HintClient)

env.AdInstances = env.AdInstances or {}
function HandleAdInstance(instance, name)
    if instance then 
        env.AdInstances[name] = {
            Instance = instance,
            Parent = instance.Parent
        }
    end
    
    local match = instance or env.AdInstances[name]
    if not match then return end 
    
    instance = instance or match.Instance
    if env.Variables.NoAdRobux then
        pcall(function() instance.Parent = nil end)
    else
        pcall(function() instance.Parent = match.Parent end)
    end
end

env.Events.NewPlot = workspace.Map.PlotModels.ChildAdded:Connect(function(plot)
    HandleAdInstance(plot:FindFirstChild("Systems"):FindFirstChild("RunGamepassPart"), ("RunGamepassPart.%s"):format(plot.Name))
end)

Main:CreateToggle({
    Name = "No ad/robux",
    Flag = "NoAdRobux",
    CurrentValue = false,
    Callback = function(Value)
        env.Variables.NoAdRobux = Value

        local Buttons = player.PlayerGui.SideButtonsGui
        local ui = {
            Buttons.LeftHolder.Rectangles.Shop,
            Buttons.LeftHolder.GroupRewardsHolder,
            Buttons.LeftHolder.Squares.Run,
            Buttons.RightHolder
        }

        for _,v in pairs(ui) do
            if v:IsA("ScreenGui") then 
                v.Enabled = not Value 
                continue 
            end
            v.Visible = not Value
        end
       
        for i,v in ipairs(workspace.Map.PlotModels:GetChildren()) do
            HandleAdInstance(v:FindFirstChild("Systems"):FindFirstChild("RunGamepassPart"), ("RunGamepassPart.%s"):format(v.Name))
        end
    end,
})

env.Variables.SelectedPlayer = env.Variables.SelectedPlayer or player.Name
local PlayerDropdown = Main:CreateDropdown({
    Name = "Select player",
    MultipleOptions = false,
    CurrentOption = ("%s (%s)"):format(Players[env.Variables.SelectedPlayer].DisplayName, env.Variables.SelectedPlayer),
    Options = {},
    Callback = function(Value)
        env.Variables.SelectedPlayer = string.match(Value[1], "%((.+)%)")
    end,
})

local playernames = {}
local function SetNames()
    playernames = {}
    for _,v in ipairs(Players:GetPlayers()) do
        table.insert(playernames, ("%s (%s)"):format(v.DisplayName, v.Name))
    end

    PlayerDropdown:Refresh(playernames)
end

SetNames()
env.Events.PlayerAdded = Players.PlayerAdded:Connect(SetNames)
env.Events.PlayerRemoving = Players.PlayerRemoving:Connect(SetNames)


local function CompleteNumber(number)
    task.spawn(function()
        local selected = env.Variables.SelectedPlayer or player.Name
        
        for i,v in ipairs(workspace.Map.PlotModels[selected].Systems.ActivePicture:GetChildren()) do 
            if v:GetAttribute("D") then continue end
            if number and v:GetAttribute("N") ~= number then continue end
            Replicated.Remotes.StepNumber:FireServer(v.Name, Players[selected])
        end 
    end)
end


Main:CreateButton({
    Name = "Instant complete (can be laggy)",
    Callback = function()
        CompleteNumber()
    end,
})

Main:CreateButton({
    Name = "Free hint",
    Callback = function()
        HintModule.ShowFreeHint(Players[env.Variables.SelectedPlayer])
    end,
})

env.Parts.Highlights = {}
env.Events.Highlights = {}

function Highlight(number, status)
    if status == nil then status = env.Variables.HighlightColor end
      
    Scrap(env.Events.Highlights, function(event) event:Disconnect() end)

    if status then
        if not number then number = Players[env.Variables.SelectedPlayer]:GetAttribute("SelectedColorNumber") end

        local index = 1
        for i,v in ipairs(workspace.Map.PlotModels[env.Variables.SelectedPlayer].Systems.ActivePicture:GetChildren()) do
            if v:GetAttribute("D") ~= true and v:GetAttribute("N") == number then
                local part = env.Parts.Highlights[index]
                if not part then 
                    part = Instance.new("BoxHandleAdornment")
                    part.Parent = nil
                    part.Adornee = nil
                    part.AlwaysOnTop = true
                    part.Transparency = 0.5
                    part.ZIndex = -1

                    env.Parts.Highlights[index] = part
                end

                table.insert(env.Events.Highlights, v:GetAttributeChangedSignal("D"):Connect(function()
                    if v:GetAttribute("D") then
                        pcall(function() part:Destroy() end)
                        env.Parts.Highlights[index] = nil
                    end
                end))

                pcall(function()    
                    part.Parent = v
                    part.Adornee = v
                    part.Size = v.Size
                end)
                index += 1
            end
        end
        -- Cleaning overflow
        for i = index, #env.Parts.Highlights do
            pcall(function() env.Parts.Highlights[i]:Destroy() end)
            env.Parts.Highlights[i] = nil
        end
    else
        Scrap(env.Parts.Highlights, function(part) part:Destroy() end)
        env.Parts.Highlights = {}
    end

end


Main:CreateToggle({
    Name = "Highlight color",
    Flag = "HighlightColor",
    CurrentValue = false,
    Callback = function(Value)
        env.Variables.HighlightColor = Value
        if Value then Highlight(nil, true) else Highlight(nil, false) end
    end
})

Main:CreateDivider()

-- env.Variables.MaxNumber = 0
-- local ColorPicker = player.PlayerGui.ColorPickerGui.MainFrame.ColorPickerHolder.Main
-- local function SetMaxNumber()
--     env.Variables.MaxNumber = 0

--     for i,v in ipairs(ColorPicker:GetChildren()) do
--         if v:IsA("TextButton") and v.Name:match("^%d+$") ~= nil then
--             env.Variables.MaxNumber += 1
--         end
--     end
-- end
-- env.Events.ColorPaletteAdded = ColorPicker.ChildAdded:Connect(SetMaxNumber)
-- env.Events.ColorPaletteRemoved = ColorPicker.ChildRemoved:Connect(SetMaxNumber)
-- SetMaxNumber()
-- I can't edit this in Rayfield unless i mod the library later

local NumberSlider = Main:CreateSlider({
    Name = "Complete number",
    Range = {1, env.Variables.MaxNumber or 100}, -- I can't edit this in Rayfield unless i mod the library later
    Increment = 1,
    Suffix = "",
    CurrentValue = player:GetAttribute("SelectedColorNumber") or 1,
    Callback = function(Value)
        env.Variables.SelectedColorNumber = Value
    end
})
Main:CreateButton({
    Name = "Complete color",
    Callback = function()
        CompleteNumber(env.Variables.SelectedColorNumber or player:GetAttribute("SelectedColorNumber") or 0)
    end
})


env.Events.ColorChanged = player:GetAttributeChangedSignal("SelectedColorNumber"):Connect(function(nb)
    local number =  player:GetAttribute("SelectedColorNumber") or 1
    Highlight(number)
    NumberSlider:Set(number)
end)

Rayfield:LoadConfiguration()
