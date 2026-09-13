-- [ NEXZAN HUB ] - Anime Dice (V2.0.0)
-- Game: Anime Dice
-- Features: New UI V4, Auto Farm Flow, Specific Tab for Egg Collect

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

while not Players.LocalPlayer do task.wait(0.1) end
local LocalPlayer = Players.LocalPlayer

local ParentUI = nil
pcall(function() ParentUI = (gethui and gethui()) or CoreGui end)
if not ParentUI or not pcall(function() return ParentUI.Name end) then
    ParentUI = LocalPlayer:WaitForChild("PlayerGui")
end

local NexzanUI = {}
NexzanUI.__index = NexzanUI

-- ==========================================
-- GRADIENT ANIMATOR HELPER
-- ==========================================
local AnimatedGradients = {}
RunService.Heartbeat:Connect(function()
    local t = tick() * 0.8
    local offset = Vector2.new(math.sin(t) * 0.5, 0)
    for i = #AnimatedGradients, 1, -1 do
        local grad = AnimatedGradients[i]
        if typeof(grad) == "Instance" and grad.Parent and grad:IsDescendantOf(game) then
            pcall(function() grad.Offset = offset end)
        else
            table.remove(AnimatedGradients, i)
        end
    end
end)



local function Create(className, properties)
    local inst = Instance.new(className)
    for k, v in pairs(properties) do inst[k] = v end
    return inst
end

local function ApplyAnimatedGradient(parent, colorSequence, rotation)
    local gradient = Create("UIGradient", {Color = colorSequence, Rotation = rotation or 0, Parent = parent})
    table.insert(AnimatedGradients, gradient)
    return gradient
end

local function MakeDraggable(dragArea, moveFrame)
    local dragging, dragInput, mousePos, framePos
    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = moveFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragArea.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            moveFrame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

local function StartFallingStars(parent)
    task.spawn(function()
        while task.wait(math.random(3, 6) * 0.1) do
            if not parent or not parent.Parent then break end
            local size = math.random(8, 14)
            local star = Create("TextLabel", { Text = "★", TextColor3 = Color3.fromRGB(255, 255, 255), TextScaled = true, BackgroundTransparency = 1, Size = UDim2.new(0, size, 0, size), Position = UDim2.new(math.random(), 0, 0, -20), Rotation = math.random(0, 360), ZIndex = 0, Parent = parent })
            TweenService:Create(star, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.7}):Play()
            local duration = math.random(4, 8)
            local endX = star.Position.X.Scale + (math.random() - 0.5) * 0.3
            local tween = TweenService:Create(star, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Position = UDim2.new(endX, 0, 1, 20), Rotation = star.Rotation + math.random(180, 360) })
            tween:Play()
            tween.Completed:Connect(function() pcall(function() star:Destroy() end) end)
        end
    end)
end

local Icons = {}
local iconLoaded = false
task.spawn(function()
    pcall(function() 
        Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua"))() 
        iconLoaded = true
    end)
end)
local tStart = tick()
while not iconLoaded and tick() - tStart < 3 do task.wait(0.1) end
if type(Icons) ~= "table" then Icons = {} end

local BlueWhiteGradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))})
local RedWhiteGradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 50, 50))})
local BlackWhiteGradient = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50))})

local oldGui = ParentUI:FindFirstChild("NexzanHub")
if oldGui then pcall(function() oldGui:Destroy() end) end

local ScreenGui = Create("ScreenGui", { Name = "NexzanHub", Parent = ParentUI, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
local NotificationContainer = Create("Frame", { Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(1, -210, 0, 0), BackgroundTransparency = 1, Parent = ScreenGui })
local NotifLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = NotificationContainer })
Create("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = NotificationContainer })

function NexzanUI:Notify(config)
    task.spawn(function()
        local duration = config.Duration or 3
        local NotifFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.1, Position = UDim2.new(1, 50, 0, 0), Parent = NotificationContainer })
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = NotifFrame })
        local NStroke = Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(255,255,255), Parent = NotifFrame })
        ApplyAnimatedGradient(NStroke, BlueWhiteGradient, 45)
        local NTitle = Create("TextLabel", { Size = UDim2.new(1, -10, 0, 15), Position = UDim2.new(0, 5, 0, 4), BackgroundTransparency = 1, Text = config.Title or "Notification", Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = NotifFrame })
        ApplyAnimatedGradient(NTitle, BlueWhiteGradient, 0)
        local NText = Create("TextLabel", { Size = UDim2.new(1, -10, 1, -20), Position = UDim2.new(0, 5, 0, 18), BackgroundTransparency = 1, Text = config.Text or "", Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = NotifFrame })
        local BarBG = Create("Frame", { Size = UDim2.new(1, -10, 0, 2), Position = UDim2.new(0, 5, 1, -5), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Parent = NotifFrame })
        local BarFill = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = BarBG })
        ApplyAnimatedGradient(BarFill, BlueWhiteGradient, 0)
        TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        TweenService:Create(BarFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
        task.wait(duration)
        local out = TweenService:Create(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0, 0)})
        out:Play()
        out.Completed:Wait()
        pcall(function() NotifFrame:Destroy() end)
    end)
end

local function GetTextWidth(text, font, size)
    return TextService:GetTextSize(text, size, font, Vector2.new(1000, 100)).X
end

local function CreateSplittableText(parent, text, font, size, gradColor, cPos, cWidth)
    local Wrapper = Create("Frame", {Size=UDim2.new(0,cWidth,1,0), Position=cPos, BackgroundTransparency=1, Parent=parent})
    local TopClip = Create("Frame", {Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0,0), ClipsDescendants=true, BackgroundTransparency=1, Parent=Wrapper})
    local BotClip = Create("Frame", {Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0), ClipsDescendants=true, BackgroundTransparency=1, Parent=Wrapper})
    
    local TopText = Create("TextLabel", {Size=UDim2.new(1,0,2,0), Position=UDim2.new(0,0,0,0), BackgroundTransparency=1, Text=text, Font=font, TextSize=size, TextColor3=Color3.fromRGB(255,255,255), TextXAlignment=Enum.TextXAlignment.Left, Parent=TopClip})
    local BotText = Create("TextLabel", {Size=UDim2.new(1,0,2,0), Position=UDim2.new(0,0,-1,0), BackgroundTransparency=1, Text=text, Font=font, TextSize=size, TextColor3=Color3.fromRGB(255,255,255), TextXAlignment=Enum.TextXAlignment.Left, Parent=BotClip})
    
    ApplyAnimatedGradient(TopText, gradColor, 0)
    ApplyAnimatedGradient(BotText, gradColor, 0)
    
    local Slash = Create("Frame", {Size=UDim2.new(0,0,0,1), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, Parent=Wrapper})
    
    return Wrapper, TopClip, BotClip, TopText, BotText, Slash
end

function NexzanUI:Create(config)
    local library = setmetatable({}, NexzanUI)
    local logoUrl = config.Logo or "rbxassetid://13426176510"
    local loadTime = config.LoadTime or 14
    local mapName = "Roll Dice Game"
pcall(function() mapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    
    library.SearchableItems = {}
    library.Keybinds = {}
    
    -- ==========================================
    -- LOADING SCREEN & ANIMATIONS
    -- ==========================================
    local LoadingFrame = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(40, 40, 40), BackgroundTransparency = 0.5, Parent = ScreenGui })
    local LoadingCenter = Create("Frame", { Size = UDim2.new(0, 260, 0, 90), Position = UDim2.new(0.5, -130, 0.5, -45), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ClipsDescendants = true, Parent = LoadingFrame })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = LoadingCenter })
    Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 30, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 50, 100))}), Rotation = 90, Parent = LoadingCenter })
    StartFallingStars(LoadingCenter)
    local LoadStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 255), Parent = LoadingCenter })
    ApplyAnimatedGradient(LoadStroke, BlueWhiteGradient, 45)
    
    local LogoImg = Create("ImageLabel", { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 15, 0, 15), BackgroundTransparency = 1, Image = "rbxassetid://13426176510", Parent = LoadingCenter })
    
    local TitleArea = Create("Frame", {Size=UDim2.new(0, 190, 0, 20), Position=UDim2.new(0, 65, 0, 15), BackgroundTransparency=1, Parent=LoadingCenter})
    local SubtitleArea = Create("Frame", {Size=UDim2.new(0, 190, 0, 15), Position=UDim2.new(0, 65, 0, 35), BackgroundTransparency=1, Parent=LoadingCenter})
    
    local LoadingBarBG = Create("Frame", { Size = UDim2.new(0, 230, 0, 6), Position = UDim2.new(0, 15, 0, 70), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Parent = LoadingCenter })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = LoadingBarBG })
    local LoadingBar = Create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = LoadingBarBG })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = LoadingBar })
    ApplyAnimatedGradient(LoadingBar, BlackWhiteGradient, 0)
    
    -- ==========================================
    -- MAIN UI STRUCTURE
    -- ==========================================
    local MasterContainer = Create("Frame", { Size = UDim2.new(0, 520, 0, 310), Position = UDim2.new(0.5, -260, 0.5, -155), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui })
    local MainUI = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ClipsDescendants = true, Parent = MasterContainer })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = MainUI })
    Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 30, 60)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 50, 100))}), Rotation = 90, Parent = MainUI })
    StartFallingStars(MainUI)
    local MainStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 255), Parent = MainUI })
    ApplyAnimatedGradient(MainStroke, BlueWhiteGradient, 45)

    -- HEADER
    local HeaderFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = MainUI })
    Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 240, 255))}), Rotation = 0, Parent = HeaderFrame })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = HeaderFrame })
    
    
    MakeDraggable(HeaderFrame, MasterContainer)
    
    local HeaderLogo = Create("ImageLabel", { Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1, Image = "rbxassetid://13426176510", ScaleType = Enum.ScaleType.Fit, Parent = HeaderFrame })
    local HeaderTitle = Create("TextLabel", { Size = UDim2.new(0, 100, 0, 16), Position = UDim2.new(0, 55, 0, 6), BackgroundTransparency = 1, Text = config.Title or "Nexzan Hub", TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = HeaderFrame })
    Create("UIStroke", {Thickness = 1, Color = Color3.fromRGB(0, 50, 100), Transparency = 0.5, Parent = HeaderTitle})
    ApplyAnimatedGradient(HeaderTitle, BlueWhiteGradient, 0)
    local HeaderSub = Create("TextLabel", { Size = UDim2.new(0, 100, 0, 12), Position = UDim2.new(0, 55, 0, 24), BackgroundTransparency = 1, Text = mapName, TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = HeaderFrame })
    Create("UIStroke", {Thickness = 1, Color = Color3.fromRGB(150, 0, 0), Transparency = 0.5, Parent = HeaderSub})
    ApplyAnimatedGradient(HeaderSub, RedWhiteGradient, 0)
    
    -- TAGS CONTAINER (Version, Device, Executor)
    local TagsContainer = Create("Frame", { Size = UDim2.new(0, 200, 0, 18), Position = UDim2.new(0, 160, 0, 13), BackgroundTransparency = 1, Parent = HeaderFrame })
    local TagsLayout = Create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = TagsContainer })
    
    local function CreateTag(text, iconId)
        local Tag = Create("Frame", { Size = UDim2.new(0, 0, 0, 18), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Parent = TagsContainer })
        Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Tag })
        local hasIcon = iconId and iconId ~= ""
        if hasIcon then
            Create("ImageLabel", {Size=UDim2.new(0,10,0,10), Position=UDim2.new(0,4,0,4), BackgroundTransparency=1, Image=iconId, ImageColor3=Color3.fromRGB(0,150,255), Parent=Tag})
        end
        local xOffset = hasIcon and 18 or 6
        local tWidth = GetTextWidth(text, Enum.Font.GothamBold, 9)
        local Txt = Create("TextLabel", { Size = UDim2.new(0, tWidth, 1, 0), Position = UDim2.new(0, xOffset, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Color3.fromRGB(255,255,255), TextXAlignment = Enum.TextXAlignment.Left, Parent = Tag })
        ApplyAnimatedGradient(Txt, BlueWhiteGradient, 0)
        Tag.Size = UDim2.new(0, xOffset + tWidth + 6, 0, 18)
    end
    
    CreateTag("2.0.0", Icons["info"] or "rbxassetid://124560466474914")
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local deviceIcon = isMobile and (Icons["smartphone"] or "rbxassetid://114197258356976") or (Icons["monitor"] or "rbxassetid://106368305943444")
    CreateTag(isMobile and "Mobile" or "PC", deviceIcon)
    
    local execName = "Unknown"
    if identifyexecutor then execName = identifyexecutor() end
    CreateTag(execName, Icons["terminal"] or "rbxassetid://110987169760162")

    -- SEARCH BAR
    local SearchBG = Create("Frame", { Size = UDim2.new(0, 120, 0, 24), Position = UDim2.new(1, -190, 0, 10), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Parent = HeaderFrame })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SearchBG })
    local SearchStroke = Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(100, 100, 120), Parent = SearchBG })
    local SearchInput = Create("TextBox", { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search features...", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(255,255,255), PlaceholderColor3 = Color3.fromRGB(150,150,150), TextXAlignment = Enum.TextXAlignment.Left, Parent = SearchBG })
    
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(SearchInput.Text)
        for _, item in ipairs(library.SearchableItems) do
            if query == "" or string.find(item.Name, query) then
                item.Frame.Visible = true
            else
                item.Frame.Visible = false
            end
        end
    end)

    -- HEADER BUTTONS
    local MinimizeBtn = Create("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -60, 0, 10), BackgroundTransparency = 1, Text = "−", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = HeaderFrame })
    local CloseBtn = Create("TextButton", { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0, 10), BackgroundTransparency = 1, Text = "×", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(255, 50, 50), Parent = HeaderFrame })
    ApplyAnimatedGradient(MinimizeBtn, BlueWhiteGradient, 0)
    CloseBtn.MouseButton1Click:Connect(function() pcall(function() ScreenGui:Destroy() end) end)

    -- FIX CORNER BAWAH KIRI UNTUK SIDEBAR
    local SidebarBG = Create("Frame", {Size=UDim2.new(0,45,1,-45), Position=UDim2.new(0,0,0,45), BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.2, BorderSizePixel=0, Parent=MainUI})
    Create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 240, 255))}), Rotation = 90, Parent = SidebarBG })
    Create("UICorner", {CornerRadius=UDim.new(0,8), Parent=SidebarBG}) -- Cleaned up overlapping patches
    
    
    
    

    local Sidebar = Create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, Parent = SidebarBG })
    local TabListLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = Sidebar })
    Create("UIPadding", { PaddingTop = UDim.new(0, 10), Parent = Sidebar })
    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Sidebar.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 20) end)
    
    local Container = Create("Frame", { Size = UDim2.new(1, -45, 1, -45), Position = UDim2.new(0, 45, 0, 45), BackgroundTransparency = 1, Parent = MainUI })
    
    -- DROPDOWN FLYOUT (Samping Kanan - Padded fix perfectly inside border)
    local DropFlyout = Create("Frame", { Size = UDim2.new(0, 130, 0, 0), Position = UDim2.new(1, 10, 0, 45), BackgroundColor3 = Color3.fromRGB(25, 30, 45), ClipsDescendants = true, Visible = false, Parent = MasterContainer })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropFlyout })
    local FlyoutStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(255,255,255), Parent = DropFlyout })
    ApplyAnimatedGradient(FlyoutStroke, BlueWhiteGradient, 45)
    
    local FlyoutScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4), BackgroundTransparency = 1, ScrollBarThickness = 2, Parent = DropFlyout })
    local FlyoutLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = FlyoutScroll })
    
    -- KEYBIND FLYOUT (Samping Kanan)
    local KeybindFlyout = Create("Frame", { Size = UDim2.new(0, 130, 0, 160), Position = UDim2.new(1, 10, 0, 45), BackgroundColor3 = Color3.fromRGB(20, 25, 35), ClipsDescendants = true, Visible = false, Parent = MasterContainer })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KeybindFlyout })
    local KBStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(255,255,255), Parent = KeybindFlyout })
    ApplyAnimatedGradient(KBStroke, BlueWhiteGradient, 45)
    MakeDraggable(KeybindFlyout, KeybindFlyout)
    
    local KBTitle = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = "Keybinds", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255,255,255), Parent = KeybindFlyout })
    local KBScroll = Create("ScrollingFrame", { Size = UDim2.new(1, -10, 1, -30), Position = UDim2.new(0, 5, 0, 25), BackgroundTransparency = 1, ScrollBarThickness = 0, Parent = KeybindFlyout })
    local KBLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = KBScroll })
    
    function library:UpdateKeybindViewer()
        for _, v in ipairs(KBScroll:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
        for name, key in pairs(self.Keybinds) do
            local f = Create("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = KBScroll })
            Create("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency=1, Text = name, Font = Enum.Font.Gotham, TextSize=10, TextColor3 = Color3.fromRGB(200,200,200), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent = f })
            Create("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), Position=UDim2.new(0.6,0,0,0), BackgroundTransparency=1, Text = "["..key.."]", Font = Enum.Font.GothamBold, TextSize=10, TextColor3 = Color3.fromRGB(0,150,255), TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
        end
        KBScroll.CanvasSize = UDim2.new(0,0,0, KBLayout.AbsoluteContentSize.Y)
    end
    
    function library:ToggleKeybindViewer(state)
        KeybindFlyout.Visible = state
        if state then DropFlyout.Visible = false end -- tutup dropdown jika keybind buka (hanya untuk cegah numpuk)
    end

    local MinimizedLogo = Create("ImageButton", { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Color3.fromRGB(20, 20, 30), ScaleType = Enum.ScaleType.Fit, Visible = false, Parent = ScreenGui })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinimizedLogo })
    local MinStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(255, 255, 255), Parent = MinimizedLogo })
    ApplyAnimatedGradient(MinStroke, BlueWhiteGradient, 0)
    MakeDraggable(MinimizedLogo, MinimizedLogo)
    MinimizeBtn.MouseButton1Click:Connect(function() MasterContainer.Visible = false; MinimizedLogo.Visible = true end)
    MinimizedLogo.MouseButton1Click:Connect(function() MasterContainer.Visible = true; MinimizedLogo.Visible = false end)

    task.spawn(function()
        if logoUrl:match("^http") then
            pcall(function()
                if isfile and writefile and getcustomasset then
                    local fn = "Nexzan_Icon_Safe.png"
                    local imgData = game:HttpGet(logoUrl)
                    if imgData:sub(1,3) == "PNG" or string.find(imgData, "PNG") then
                        writefile(fn, imgData)
                        local asst = getcustomasset(fn)
                        LogoImg.Image = asst; HeaderLogo.Image = asst; MinimizedLogo.Image = asst
                    else
                        LogoImg.Image = "rbxassetid://13426176510"; HeaderLogo.Image = "rbxassetid://13426176510"; MinimizedLogo.Image = "rbxassetid://13426176510"
                    end
                end
            end)
        else
            LogoImg.Image = logoUrl; HeaderLogo.Image = logoUrl; MinimizedLogo.Image = logoUrl
        end
    end)

    -- ==========================================
    -- ANIMASI LOADING MASTERPIECE (SLOW, PRECISE SLASH)
    -- ==========================================
    task.spawn(function()
        TweenService:Create(LoadingBar, TweenInfo.new(loadTime, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        
        local wText, toText, nexText = "Welcome", "To ", (config.Title or "Nexzan Hub")
        local wWidth = GetTextWidth(wText, Enum.Font.GothamBold, 14)
        local toWidth = GetTextWidth(toText, Enum.Font.GothamBold, 14)
        local nexWidth = GetTextWidth(nexText, Enum.Font.GothamBold, 14)
        local subWidth = GetTextWidth(mapName, Enum.Font.Gotham, 10)
        
        local WelcomeWrap, WTopC, WBotC, WTopT, WBotT, WSlash = CreateSplittableText(TitleArea, wText, Enum.Font.GothamBold, 14, BlueWhiteGradient, UDim2.new(0,0,0,0), wWidth)
        local ToWrap, TTopC, TBotC, TTopT, TBotT, TSlash = CreateSplittableText(TitleArea, toText, Enum.Font.GothamBold, 14, BlueWhiteGradient, UDim2.new(0,0,0,0), toWidth)
        local NexWrap, NTopC, NBotC, NTopT, NBotT, NSlash = CreateSplittableText(TitleArea, nexText, Enum.Font.GothamBold, 14, BlueWhiteGradient, UDim2.new(0,toWidth,0,0), nexWidth)
        ToWrap.Visible = false; NexWrap.Visible = false
        
        local SubWrap, SubTopC, SubBotC, SubTopT, SubBotT, SubSlash = CreateSplittableText(SubtitleArea, mapName, Enum.Font.Gotham, 10, RedWhiteGradient, UDim2.new(0,0,0,0), math.min(subWidth, 190))
        SubTopT.TextTruncate = Enum.TextTruncate.AtEnd; SubBotT.TextTruncate = Enum.TextTruncate.AtEnd
        
        WTopT.MaxVisibleGraphemes = 0; WBotT.MaxVisibleGraphemes = 0
        SubTopT.MaxVisibleGraphemes = 0; SubBotT.MaxVisibleGraphemes = 0
        
        -- 1. "Welcome" Typewriter (Slow)
        for i=1, #wText do WTopT.MaxVisibleGraphemes=i; WBotT.MaxVisibleGraphemes=i; task.wait(0.15) end
        task.wait(0.6)
        
        -- 2. Tebasan (Slash) pada "Welcome" (Slow & precise thickness)
        TweenService:Create(WSlash, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {Size=UDim2.new(1,0,0,1)}):Play()
        task.wait(0.4)
        TweenService:Create(WTopC, TweenInfo.new(0.6), {Position=UDim2.new(0,0,-0.5,0)}):Play()
        TweenService:Create(WBotC, TweenInfo.new(0.6), {Position=UDim2.new(0,0,1,0)}):Play()
        TweenService:Create(WTopT, TweenInfo.new(0.6), {TextTransparency=1}):Play()
        TweenService:Create(WBotT, TweenInfo.new(0.6), {TextTransparency=1}):Play()
        TweenService:Create(WSlash, TweenInfo.new(0.6), {BackgroundTransparency=1}):Play()
        task.wait(0.6)
        WelcomeWrap.Visible = false
        
        -- 3. The Merge: "To Nexzan Hub" (Slow Merge)
        ToWrap.Visible = true; NexWrap.Visible = true
        TTopC.Position = UDim2.new(0,0,-0.5,0); TBotC.Position = UDim2.new(0,0,1,0)
        NTopC.Position = UDim2.new(0,0,-0.5,0); NBotC.Position = UDim2.new(0,0,1,0)
        TTopT.TextTransparency = 1; TBotT.TextTransparency = 1
        NTopT.TextTransparency = 1; NBotT.TextTransparency = 1
        
        local mergeTI = TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(TTopC, mergeTI, {Position=UDim2.new(0,0,0,0)}):Play()
        TweenService:Create(TBotC, mergeTI, {Position=UDim2.new(0,0,0.5,0)}):Play()
        TweenService:Create(NTopC, mergeTI, {Position=UDim2.new(0,0,0,0)}):Play()
        TweenService:Create(NBotC, mergeTI, {Position=UDim2.new(0,0,0.5,0)}):Play()
        TweenService:Create(TTopT, TweenInfo.new(0.4), {TextTransparency=0}):Play()
        TweenService:Create(TBotT, TweenInfo.new(0.4), {TextTransparency=0}):Play()
        TweenService:Create(NTopT, TweenInfo.new(0.4), {TextTransparency=0}):Play()
        TweenService:Create(NBotT, TweenInfo.new(0.4), {TextTransparency=0}):Play()
        
        -- 4. Subtitle Muncul Typewriter (Slow)
        task.spawn(function()
            for i=1, #mapName do SubTopT.MaxVisibleGraphemes=i; SubBotT.MaxVisibleGraphemes=i; task.wait(0.12) end
        end)
        
        task.wait(0.8)
        
        -- 5. "To" Hilang, "Nexzan Hub" Geser Kiri (Smooth)
        TweenService:Create(TTopT, TweenInfo.new(0.5), {TextTransparency=1}):Play()
        TweenService:Create(TBotT, TweenInfo.new(0.5), {TextTransparency=1}):Play()
        task.wait(0.3)
        TweenService:Create(NexWrap, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position=UDim2.new(0,0,0,0)}):Play()
        
        -- 6. TUNGGU SISA LOADING TIME
        task.wait(math.max(0.5, loadTime - 5.5)) 
        
        -- 7. OUTRO SLASH TEBASAN HILANG (Slow fade)
        TweenService:Create(NSlash, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,1)}):Play()
        TweenService:Create(SubSlash, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,1)}):Play()
        task.wait(0.3)
        
        local outTI = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(NTopC, outTI, {Position=UDim2.new(0,0,-1,0)}):Play()
        TweenService:Create(NBotC, outTI, {Position=UDim2.new(0,0,1,0)}):Play()
        TweenService:Create(SubTopC, outTI, {Position=UDim2.new(0,0,-1,0)}):Play()
        TweenService:Create(SubBotC, outTI, {Position=UDim2.new(0,0,1,0)}):Play()
        
        TweenService:Create(NTopT, outTI, {TextTransparency=1}):Play()
        TweenService:Create(NBotT, outTI, {TextTransparency=1}):Play()
        TweenService:Create(SubTopT, outTI, {TextTransparency=1}):Play()
        TweenService:Create(SubBotT, outTI, {TextTransparency=1}):Play()
        TweenService:Create(NSlash, outTI, {BackgroundTransparency=1}):Play()
        TweenService:Create(SubSlash, outTI, {BackgroundTransparency=1}):Play()
        
        task.wait(0.5)
        pcall(function() LoadingFrame:Destroy() end)
        MasterContainer.Visible = true
        library:Notify({Title = "Ready", Text = "Nexzan Hub loaded safely!", Duration = 3})
    end)

    library.MasterContainer = MasterContainer
    library.MinimizedLogo = MinimizedLogo
    library.ScreenGui = ScreenGui
    library.Container = Container
    library.Sidebar = Sidebar
    library.DropFlyout = DropFlyout
    library.FlyoutScroll = FlyoutScroll
    
    function library:CreateTab(iconName)
        local tab = {}
        local TabBtn = Create("ImageButton", { Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, Image = Icons[iconName] or Icons["list"] or "rbxassetid://113179976918783", ImageColor3 = Color3.fromRGB(20, 40, 100), Parent = self.Sidebar })
        
        local TabPage = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, ScrollBarThickness = 1, Visible = false, Parent = self.Container })
        local PageLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = TabPage })
        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20) end)
        
        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(self.Container:GetChildren()) do if v:IsA("ScrollingFrame") then v.Visible = false end end
            for _, v in pairs(self.Sidebar:GetChildren()) do 
                if v:IsA("ImageButton") then 
                    v.ImageColor3 = Color3.fromRGB(20, 40, 100)
                    for _, c in pairs(v:GetChildren()) do if c:IsA("UIGradient") then c:Destroy() end end
                end 
            end
            TabPage.Visible = true
            TabBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
            ApplyAnimatedGradient(TabBtn, BlueWhiteGradient, 0)
            self.DropFlyout.Visible = false
            -- PERHATIAN: KeybindFlyout.Visible TIDAK dimatikan di sini agar List Keybind tetap stay saat pindah tab
        end)
        
        if #self.Container:GetChildren() == 1 then 
            TabPage.Visible = true 
            TabBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
            ApplyAnimatedGradient(TabBtn, BlueWhiteGradient, 0)
        end
        
        function tab:CreateSection(titleText, subtitleText)
            local SectionFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Parent = TabPage })
            local TitleL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 2, 0, 0), BackgroundTransparency = 1, Text = titleText, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = SectionFrame })
            ApplyAnimatedGradient(TitleL, BlueWhiteGradient, 0)
            if subtitleText then
                local SubL = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 2, 0, 16), BackgroundTransparency = 1, Text = subtitleText, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = SectionFrame })
            end
            table.insert(library.SearchableItems, {Name = string.lower(titleText), Frame = SectionFrame})
        end

        function tab:CreateLabel(text)
            local LabelFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = LabelFrame })
            local Lbl = Create("TextLabel", { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LabelFrame })
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = LabelFrame})
        end
        
        function tab:CreateParagraph(title, text)
            local PFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = PFrame })
            local TLbl = Create("TextLabel", { Size = UDim2.new(1, -10, 0, 16), Position = UDim2.new(0, 5, 0, 4), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = PFrame })
            ApplyAnimatedGradient(TLbl, BlueWhiteGradient, 0)
            local CLbl = Create("TextLabel", { Size = UDim2.new(1, -10, 1, -22), Position = UDim2.new(0, 5, 0, 20), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 10, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = PFrame })
            table.insert(library.SearchableItems, {Name = string.lower(title), Frame = PFrame})
        end

        function tab:CreateButton(text, callback)
            local BtnFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(30, 35, 55), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BtnFrame })
            local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = BtnFrame })
            ApplyAnimatedGradient(Btn, BlueWhiteGradient, 0)
            Btn.MouseButton1Click:Connect(function()
                pcall(function() TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(50, 60, 90)}):Play() end)
                task.wait(0.1)
                pcall(function() TweenService:Create(BtnFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(30, 35, 55)}):Play() end)
                if callback then task.spawn(pcall, callback) end
            end)
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = BtnFrame})
        end

        function tab:CreateToggle(text, callback)
            local ToggleFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ToggleFrame })
            local Label = Create("TextLabel", { Size = UDim2.new(0.7, 0, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = ToggleFrame })
            
            local SwitchBG = Create("Frame", { Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -35, 0.5, -8), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Parent = ToggleFrame })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBG })
            local SwitchIndicator = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = SwitchBG })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchIndicator })
            local IndGradient = ApplyAnimatedGradient(SwitchIndicator, BlackWhiteGradient, 0)
            
            local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = ToggleFrame })
            
            local toggleObj = {}
            toggleObj.State = false
            
            function toggleObj:Set(newState)
                if toggleObj.State == newState then return end
                toggleObj.State = newState
                pcall(function()
                    if toggleObj.State then
                        TweenService:Create(SwitchIndicator, TweenInfo.new(0.2), {Position = UDim2.new(1, -14, 0.5, -6)}):Play()
                        IndGradient.Color = BlueWhiteGradient
                    else
                        TweenService:Create(SwitchIndicator, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
                        IndGradient.Color = BlackWhiteGradient
                    end
                end)
                if callback then task.spawn(pcall, callback, toggleObj.State) end
            end
            
            function toggleObj:Toggle()
                self:Set(not self.State)
            end

            Btn.MouseButton1Click:Connect(function()
                toggleObj:Toggle()
            end)
            
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = ToggleFrame})
            return toggleObj
        end
        

        function tab:CreateInput(text, placeholder, callback)
            local InputFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = InputFrame })
            
            local Label = Create("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = InputFrame })
            
            local TextBoxBG = Create("Frame", { Size = UDim2.new(0.4, 0, 0, 24), Position = UDim2.new(1, -5, 0.5, -12), AnchorPoint=Vector2.new(1,0), BackgroundColor3 = Color3.fromRGB(15, 20, 30), Parent = InputFrame })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = TextBoxBG })
            Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(100, 100, 120), Parent = TextBoxBG })
            
            local TextBox = Create("TextBox", { Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), ClearTextOnFocus = false, Parent = TextBoxBG })
            
            TextBox.FocusLost:Connect(function(enterPressed)
                if callback then
                    task.spawn(pcall, callback, TextBox.Text)
                end
            end)
            
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = InputFrame})
        end
        function tab:CreateSlider(text, min, max, default, callback)
            local SliderFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SliderFrame })
            local Label = Create("TextLabel", { Size = UDim2.new(0.5, 0, 0, 16), Position = UDim2.new(0, 5, 0, 4), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = SliderFrame })
            local ValueLabel = Create("TextLabel", { Size = UDim2.new(0.5, 0, 0, 16), Position = UDim2.new(0.5, -5, 0, 4), BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(0, 150, 255), Parent = SliderFrame })
            
            local SliderBG = Create("Frame", { Size = UDim2.new(1, -10, 0, 4), Position = UDim2.new(0, 5, 0, 26), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Parent = SliderFrame })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBG })
            local SliderFill = Create("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = SliderBG })
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderFill })
            ApplyAnimatedGradient(SliderFill, BlueWhiteGradient, 0)
            
            local SliderBtn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = SliderBG })
            local dragging = false
            SliderBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end end)
            UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mousePos = UserInputService:GetMouseLocation().X
                    local bgPos = SliderBG.AbsolutePosition.X
                    local bgSize = SliderBG.AbsoluteSize.X
                    local percent = math.clamp((mousePos - bgPos) / bgSize, 0, 1)
                    local value = math.floor(min + (max - min) * percent)
                    SliderFill.Size = UDim2.new(percent, 0, 1, 0)
                    ValueLabel.Text = tostring(value)
                    if callback then task.spawn(pcall, callback, value) end
                end
            end)
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = SliderFrame})
        end

        function tab:CreateDropdown(text, options, callback)
            local DropFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, ClipsDescendants = true, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = DropFrame })
            local Label = Create("TextLabel", { Size = UDim2.new(1, -25, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = DropFrame })
            local Icon = Create("TextLabel", { Size = UDim2.new(0, 16, 1, 0), Position = UDim2.new(1, -20, 0, 0), BackgroundTransparency = 1, Text = "▶", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(150, 150, 150), Parent = DropFrame })
            local Btn = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = DropFrame })
            
            Btn.MouseButton1Click:Connect(function()
                local flyout = library.DropFlyout
                local fScroll = library.FlyoutScroll
                if flyout.Visible and library.CurrentDropdown == DropFrame then
                    flyout.Visible = false; library.CurrentDropdown = nil; return
                end
                
                library.CurrentDropdown = DropFrame
                -- KITA TIDAK MATIKAN KEYBIND VIEWER LAGI (Biar gak konflik)
                for _, v in ipairs(fScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
                
                for _, opt in ipairs(options) do
                    -- Frame option diberi gap (-8px Size) dan diposisikan aman dari pinggir corner
                    local OptBtn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = opt, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = fScroll })
                    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptBtn })
                    OptBtn.MouseButton1Click:Connect(function()
                        Label.Text = text .. " : " .. opt; flyout.Visible = false; library.CurrentDropdown = nil
                        if callback then task.spawn(pcall, callback, opt) end
                    end)
                end
                
                local optHeight = 24
                local numOpts = #options
                local visibleOpts = math.clamp(numOpts, 1, 5)
                local contentHeight = (numOpts * optHeight) + ((numOpts - 1) * 2)
                fScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
                
                local frameHeight = (visibleOpts * optHeight) + ((visibleOpts - 1) * 2) + 8
                pcall(function()
                    flyout.Size = UDim2.new(0, 130, 0, frameHeight)
                    flyout.Visible = true
                end)
            end)
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = DropFrame})
        end
        
        function tab:CreateKeybind(text, defaultKey, callback)
            local KBFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Color3.fromRGB(20, 25, 40), BackgroundTransparency = 0.3, Parent = TabPage })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KBFrame })
            local Label = Create("TextLabel", { Size = UDim2.new(0.7, 0, 1, 0), Position = UDim2.new(0, 5, 0, 0), BackgroundTransparency = 1, Text = text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = KBFrame })
            
            local BindBtn = Create("TextButton", { Size = UDim2.new(0, 60, 0, 20), Position = UDim2.new(1, -65, 0.5, -10), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = defaultKey, Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(0, 150, 255), Parent = KBFrame })
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BindBtn })
            
            local currentKey = defaultKey
            library.Keybinds[text] = currentKey
            library:UpdateKeybindViewer()
            
            local isBinding = false
            BindBtn.MouseButton1Click:Connect(function() isBinding = true; BindBtn.Text = "..." end)
            
            UserInputService.InputBegan:Connect(function(input, gpe)
                if not gpe and isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode.Name; BindBtn.Text = currentKey; isBinding = false
                    library.Keybinds[text] = currentKey; library:UpdateKeybindViewer()
                elseif not gpe and not isBinding and input.KeyCode.Name == currentKey then
                    if callback then task.spawn(pcall, callback) end
                end
            end)
            table.insert(library.SearchableItems, {Name = string.lower(text), Frame = KBFrame})
        end

        return tab
    end
    return library
end

-- ==========================================

-- ==========================================
-- SCRIPT INITIALIZATION (STEAL A CHICKEN V18)
-- ==========================================

-- THE STATIC MANUAL PLOT / SAFEZONE
local CFrameManualPlot = CFrame.new(-29.85, 33.40, -296.06)

-- Make all Prompts Instant Globally
task.spawn(function()
    while task.wait(1) do
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                obj.HoldDuration = 0
            end
        end
    end
end)

local zoneList = {"Jungle", "Desert", "Snow", "Volcano", "Forest", "Lake", "Beach", "Cosmic", "Abyss", "Crystal"}

-- ==========================================
-- KEY SYSTEM NEXZAN HUB
-- ==========================================
local isKeyValid = false
local HWID = "NEXZAN-HWID-" .. tostring(LocalPlayer.UserId)
pcall(function() HWID = game:GetService("RbxAnalyticsService"):GetClientId() end)
local currentDay = tostring(math.floor(os.time() / 86400))
local expectedKey = "NXZ-" .. string.sub(HWID, 1, 6) .. "-" .. currentDay

if isfile and readfile then
    pcall(function()
        local savedKey = readfile("NexzanHub_Key.txt")
        if savedKey == expectedKey then isKeyValid = true end
    end)
end

if not isKeyValid then
    local mapName = "Roll Dice Game"
pcall(function() mapName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
    
    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "NexzanKeySystem"
    KeyGui.Parent = ParentUI
    KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeyGui.ResetOnSpawn = false
    
    local Master = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = KeyGui })
    local Dim = Create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.5, Parent = Master })
    
    local CenterPanel = Create("Frame", { Size = UDim2.new(0, 300, 0, 170), Position = UDim2.new(0.5, -150, 0.5, -85), BackgroundColor3 = Color3.fromRGB(15, 20, 30), ClipsDescendants=true, Parent = Master })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = CenterPanel })
    local CenterStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(0, 150, 255), Parent = CenterPanel })
    ApplyAnimatedGradient(CenterStroke, BlueWhiteGradient, 45)
    StartFallingStars(CenterPanel)
    
    Create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 0, 10), BackgroundTransparency = 1, Text = "Key System Nexzan Hub", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = CenterPanel })
    local subT = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 0, 0, 35), BackgroundTransparency = 1, Text = mapName, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = CenterPanel })
    ApplyAnimatedGradient(subT, RedWhiteGradient, 0)
    
    local KeyInput = Create("TextBox", { Size = UDim2.new(0, 220, 0, 30), Position = UDim2.new(0.5, -110, 0, 65), BackgroundColor3 = Color3.fromRGB(25, 30, 45), Text = "", PlaceholderText = "Enter your key here...", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = CenterPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KeyInput })
    Create("UIStroke", { Thickness = 1, Color = Color3.fromRGB(100, 100, 120), Parent = KeyInput })
    
    local SubmitBtn = Create("TextButton", { Size = UDim2.new(0, 105, 0, 30), Position = UDim2.new(0.5, -110, 0, 115), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = "Submit Key", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(0, 150, 255), Parent = CenterPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SubmitBtn })
    
    local GetKeyBtn = Create("TextButton", { Size = UDim2.new(0, 105, 0, 30), Position = UDim2.new(0.5, 5, 0, 115), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = "Get Key", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = CenterPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = GetKeyBtn })
    
    -- LEFT PANEL (INFO)
    local LeftPanel = Create("Frame", { Size = UDim2.new(0, 200, 0, 170), Position = UDim2.new(0.5, -150, 0.5, -85), BackgroundColor3 = Color3.fromRGB(20, 25, 35), ZIndex = 0, Visible = false, Parent = Master })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = LeftPanel })
    local LeftStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(0, 150, 255), Parent = LeftPanel })
    ApplyAnimatedGradient(LeftStroke, BlueWhiteGradient, 45)
    
    local pfp = Create("ImageLabel", { Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(0.5, -30, 0, 15), BackgroundTransparency = 1, Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(LocalPlayer.UserId).."&w=150&h=150", Parent = LeftPanel })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pfp })
    
    local dn = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 85), BackgroundTransparency = 1, Text = LocalPlayer.DisplayName, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    local un = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 100), BackgroundTransparency = 1, Text = "@"..LocalPlayer.Name, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = LeftPanel })
    
    local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local devTxt = isMobile and "Mobile" or "PC"
    local execTxt = "Unknown Executor"
    pcall(function() if identifyexecutor then execTxt = tostring(identifyexecutor()) end end)
    
    Create("TextLabel", { Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 125), BackgroundTransparency = 1, Text = "Device: " .. devTxt, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    Create("TextLabel", { Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 140), BackgroundTransparency = 1, Text = "Executor: " .. string.sub(execTxt, 1, 18), Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    Create("TextLabel", { Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 155), BackgroundTransparency = 1, Text = "HWID: " .. string.sub(HWID, 1, 15) .. "...", Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    
    local CopyHWID = Create("TextButton", { Size = UDim2.new(0, 80, 0, 20), Position = UDim2.new(0.5, -85, 0, 175), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = "Copy HWID", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CopyHWID })
    CopyHWID.MouseButton1Click:Connect(function() pcall(function() setclipboard(HWID) CopyHWID.Text = "Copied!" task.wait(1) CopyHWID.Text = "Copy HWID" end) end)
    
    local GetKeyLeftBtn = Create("TextButton", { Size = UDim2.new(0, 80, 0, 20), Position = UDim2.new(0.5, 5, 0, 175), BackgroundColor3 = Color3.fromRGB(0, 100, 200), Text = "Get Key", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = LeftPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = GetKeyLeftBtn })
    
    -- RIGHT PANEL (GENERATOR)
    local RightPanel = Create("Frame", { Size = UDim2.new(0, 200, 0, 170), Position = UDim2.new(0.5, -50, 0.5, -85), BackgroundColor3 = Color3.fromRGB(20, 25, 35), ZIndex = 0, Visible = false, Parent = Master })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = RightPanel })
    local RightStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(0, 150, 255), Parent = RightPanel })
    ApplyAnimatedGradient(RightStroke, BlueWhiteGradient, 45)
    
    Create("TextLabel", { Size = UDim2.new(1, 0, 0, 25), Position = UDim2.new(0, 0, 0, 10), BackgroundTransparency = 1, Text = "Key Generator", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = RightPanel })
    Create("TextLabel", { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 35), BackgroundTransparency = 1, Text = "Masukkan HWID kamu untuk mendapatkan Key 24 Jam.", Font = Enum.Font.Gotham, TextSize = 10, TextWrapped=true, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = RightPanel })
    
    local GenInput = Create("TextBox", { Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 65), BackgroundColor3 = Color3.fromRGB(30, 35, 45), Text = "", PlaceholderText = "Paste HWID here...", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = RightPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = GenInput })
    
    local GenBtn = Create("TextButton", { Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 95), BackgroundColor3 = Color3.fromRGB(0, 150, 255), Text = "Generate Key", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = RightPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = GenBtn })
    
    local OutputKey = Create("TextBox", { Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 125), BackgroundColor3 = Color3.fromRGB(25, 30, 40), Text = "", ClearTextOnFocus=false, TextEditable=false, PlaceholderText = "Your Key...", Font = Enum.Font.GothamBold, TextSize = 10, TextColor3 = Color3.fromRGB(0, 255, 100), Parent = RightPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OutputKey })
    
    local CopyKeyBtn = Create("TextButton", { Size = UDim2.new(1, -20, 0, 15), Position = UDim2.new(0, 10, 0, 150), BackgroundColor3 = Color3.fromRGB(40, 40, 50), Text = "Copy Key", Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = RightPanel })
    Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = CopyKeyBtn })
    
    -- ANIMATIONS & LOGIC
    GetKeyBtn.MouseButton1Click:Connect(function()
        LeftPanel.Visible = true
        TweenService:Create(LeftPanel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, -360, 0.5, -85)}):Play()
    end)
    
    GetKeyLeftBtn.MouseButton1Click:Connect(function()
        RightPanel.Visible = true
        TweenService:Create(RightPanel, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0.5, 160, 0.5, -85)}):Play()
    end)
    
    GenBtn.MouseButton1Click:Connect(function()
        if GenInput.Text == HWID then
            OutputKey.Text = expectedKey
        else
            OutputKey.Text = "Invalid HWID!"
            task.wait(1)
            OutputKey.Text = ""
        end
    end)
    
    CopyKeyBtn.MouseButton1Click:Connect(function()
        if OutputKey.Text ~= "" and OutputKey.Text ~= "Invalid HWID!" then
            pcall(function() setclipboard(OutputKey.Text) CopyKeyBtn.Text = "Copied!" task.wait(1) CopyKeyBtn.Text = "Copy Key" end)
        end
    end)
    
    local keyValidated = false
    SubmitBtn.MouseButton1Click:Connect(function()
        if KeyInput.Text == expectedKey then
            SubmitBtn.Text = "Success!"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            if writefile then pcall(function() writefile("NexzanHub_Key.txt", expectedKey) end) end
            task.wait(0.5)
            KeyGui:Destroy()
            keyValidated = true
        else
            SubmitBtn.Text = "Invalid Key!"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.wait(1)
            SubmitBtn.Text = "Submit Key"
            SubmitBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        end
    end)
    
    while not keyValidated do task.wait(0.1) end
end

local Window = NexzanUI:Create({
    Logo = "https://cdn.phototourl.com/free/2026-09-06-c651d7a2-1cce-46b5-8607-4e9a9f09cea3.png",
    Title = "Nexzan Hub",
    LoadTime = 10 
})

local selectedZone = "Jungle"
local flySpeed = 500
local autoFarm = false


-- ==========================================
-- TAB 1: AUTO ROLL & FARM
-- ==========================================

-- ==========================================
-- TAB INFO (MAIN)
-- ==========================================
local TabInfo = Window:CreateTab("info")

TabInfo:CreateSection("System Info", "Build Details")
TabInfo:CreateLabel("Version 2.0.0 (Anime Dice)")
TabInfo:CreateLabel("Cooming Soon Next Update: Next Update on Monday, September 14, 2026")

TabInfo:CreateSection("New Features", "New Features")
TabInfo:CreateLabel("
• Auto Sell Equip
• Buy Dice
• Auto Rebirth")

-- ==========================================
-- TAB AUTO ROLL & FARM
-- ==========================================
local TabFarm = Window:CreateTab("zap") -- fast/zap icon
TabFarm:CreateSection("Auto Roll Dice", "Auto Roll")

local autoFastRoll = false
local tglRoll = TabFarm:CreateToggle("Auto Roll", function(state) autoFastRoll = state end)
TabFarm:CreateKeybind("Toggle Auto Roll", "F", function() tglRoll:Toggle() end)

task.spawn(function()
    local rollRemote = nil
    pcall(function() rollRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("RollService"):WaitForChild("RF"):WaitForChild("RollDice") end)
    
    while task.wait() do
        if autoFastRoll and rollRemote then
            pcall(function() rollRemote:InvokeServer() end)
        end
    end
end)

TabFarm:CreateSection("Auto Equip Best", "equip unit terbaik")

local autoEquip = false
local tglEquip = TabFarm:CreateToggle("Auto Equip Best", function(state) autoEquip = state end)
TabFarm:CreateKeybind("Toggle Equip Best", "E", function() tglEquip:Toggle() end)

task.spawn(function()
    local equipRemote = nil
    pcall(function() equipRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("EquipBest") end)
    
    while task.wait(0.5) do
        if autoEquip and equipRemote then
            pcall(function() equipRemote:FireServer() end)
        end
    end
end)


TabFarm:CreateSection("Auto Sell Equip", "Jual unit yang sedang dipakai")
local autoSell = false
local sellSpeed = 20
TabFarm:CreateSlider("Spam Speed (Sell)", 1, 50, 20, function(val) sellSpeed = val end)
local tglSell = TabFarm:CreateToggle("Auto Sell Equip", function(state) autoSell = state end)
TabFarm:CreateLabel("Info: Aktifkan Auto Sell Equip, Lalu Equip Yang Mau Di Sell")
TabFarm:CreateKeybind("Toggle Sell Equip", "Q", function() tglSell:Toggle() end)

task.spawn(function()
    local sellRemote = nil
    pcall(function() sellRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("SellService"):WaitForChild("RF"):WaitForChild("SellEquipped") end)
    while task.wait() do
        if autoSell and sellRemote then
            pcall(function() sellRemote:InvokeServer() end)
            task.wait(1 / sellSpeed)
        end
    end
end)

TabFarm:CreateSection("Buy Dice", "Beli Dadu Spesifik")
local diceList = {"Normal", "Fire", "Water", "Nature", "Lightning", "Ice", "Magma", "Strom", "Shadow", "Light", "Blood Moon", "Void", "Solar", "Lunar", "Galaxy", "Black Hole", "Dragon", "Royal", "Prismatic", "Arcane", "Corrupted", "Titan", "Chrono", "Cyber", "Toxic"}
local selectedDice = "Normal"
TabFarm:CreateDropdown("Pilih Dice", diceList, function(opt) selectedDice = opt end)
TabFarm:CreateButton("Buy Selected Dice (1x)", function() 
    pcall(function() game:GetService("ReplicatedStorage").Network.DiceShopService.RE.BuyDice:FireServer(selectedDice) end)
    NexzanUI:Notify({Title="Buy Dice", Text="Attempted to buy: " .. selectedDice, Duration=2})
end)
-- ==========================================
-- TAB 2: AUTO PLOT (COLLECT & UPGRADE)
-- ==========================================
local TabPlot = Window:CreateTab("coins")
TabPlot:CreateSection("Auto Collect Balance", "Klaim uang/balance per slot")

local autoCollect = false
local maxCollectSlot = 10
local collectSpeed = 10

TabPlot:CreateInput("Masukkan Max Slot", "Contoh: 10", function(val) local n = tonumber(val) if n then maxCollectSlot = n NexzanUI:Notify({Title="Slot Set", Text="Max Slot Collect: "..n, Duration=2}) end end)
TabPlot:CreateSlider("Spam Speed (Collect)", 1, 50, 20, function(val) collectSpeed = val end)

local tglCollect = TabPlot:CreateToggle("Auto Collect Cash", function(state) autoCollect = state end)
TabPlot:CreateKeybind("Toggle Auto Collect", "R", function() tglCollect:Toggle() end)

task.spawn(function()
    local colRemote = nil
    pcall(function() colRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("CollectBalance") end)
    
    local currentSlot = 1
    while task.wait() do
        if autoCollect and colRemote then
            pcall(function() colRemote:FireServer(currentSlot) end)
            currentSlot = currentSlot + 1
            if currentSlot > maxCollectSlot then currentSlot = 1 end
            task.wait(1 / collectSpeed)
        end
    end
end)

TabPlot:CreateSection("Auto Upgrade Slot", "Level Up plot slots")

local autoUpgrade = false
local maxUpgradeSlot = 10
local upgradeSpeed = 10

TabPlot:CreateInput("Masukkan Max Slot", "Contoh: 10", function(val) local n = tonumber(val) if n then maxUpgradeSlot = n NexzanUI:Notify({Title="Slot Set", Text="Max Slot Upgrade: "..n, Duration=2}) end end)
TabPlot:CreateSlider("Spam Speed (Upgrade)", 1, 50, 10, function(val) upgradeSpeed = val end)

local tglUpgrade = TabPlot:CreateToggle("Auto Level Up Slot", function(state) autoUpgrade = state end)
TabPlot:CreateKeybind("Toggle Auto Upgrade", "T", function() tglUpgrade:Toggle() end)

task.spawn(function()
    local upgRemote = nil
    pcall(function() upgRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("LevelUpSlot") end)
    
    local currentUpSlot = 1
    while task.wait() do
        if autoUpgrade and upgRemote then
            pcall(function() upgRemote:FireServer(currentUpSlot) end)
            currentUpSlot = currentUpSlot + 1
            if currentUpSlot > maxUpgradeSlot then currentUpSlot = 1 end
            task.wait(1 / upgradeSpeed)
        end
    end
end)

-- ==========================================
-- TAB 3: PLAYER SETTINGS
-- ==========================================
local TabPlayer = Window:CreateTab("user-cog")
TabPlayer:CreateSection("Pengaturan Player", "Movement Modifiers")
local tglKB = TabPlayer:CreateToggle("Tampilkan Keybind UI", function(state)
    Window:ToggleKeybindViewer(state)
end)
TabPlayer:CreateKeybind("Toggle Keybind UI", "H", function()
    tglKB:Toggle()
end)
local infJump = false
local tglInfJump = TabPlayer:CreateToggle("Infinite Jump", function(state) infJump = state end)
TabPlayer:CreateKeybind("Toggle Infinite Jump", "J", function()
    tglInfJump:Toggle()
end)
UserInputService.JumpRequest:Connect(function()
    if infJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
local noclip = false
local tglNoClip = TabPlayer:CreateToggle("No Clip (Tembus Tembok)", function(state) noclip = state end)
TabPlayer:CreateKeybind("Toggle No Clip", "N", function()
    tglNoClip:Toggle()
end)
RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)
local antiAfk = false
local tglAntiAFK = TabPlayer:CreateToggle("Anti AFK", function(state)
    antiAfk = state
    if state then NexzanUI:Notify({Title="Anti AFK", Text="Kamu tidak akan di kick!", Duration=3}) end
end)
TabPlayer:CreateKeybind("Toggle Anti AFK", "K", function()
    tglAntiAFK:Toggle()
end)


-- ==========================================
-- TAB 3: COMBAT & REBIRTH
-- ==========================================
local TabCombat = Window:CreateTab("swords") -- Swords icon
TabCombat:CreateSection("Auto Rebirth", "Otomatis melakukan Rebirth")

local autoRebirth = false
local rebirthSpeed = 5
TabCombat:CreateSlider("Spam Speed (Rebirth)", 1, 50, 5, function(val) rebirthSpeed = val end)
local tglRebirth = TabCombat:CreateToggle("Auto Rebirth", function(state) autoRebirth = state end)
TabCombat:CreateKeybind("Toggle Auto Rebirth", "U", function() tglRebirth:Toggle() end)

task.spawn(function()
    local rbRemote = nil
    pcall(function() rbRemote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("RebirthService"):WaitForChild("RE"):WaitForChild("Rebirth") end)
    while task.wait() do
        if autoRebirth and rbRemote then
            pcall(function() rbRemote:FireServer() end)
            task.wait(1 / rebirthSpeed)
        end
    end
end)

-- ==========================================
-- TAB DISCORD & MUSIC
-- ==========================================
local TabMisc = Window:CreateTab("layout-grid")

-- DISCORD UI LOGIC
TabMisc:CreateSection("Community", "Official Links")

local DiscFlyout = Create("Frame", { Size = UDim2.new(0, 180, 0, 220), Position = UDim2.new(1, 10, 0, 45), BackgroundColor3 = Color3.fromRGB(20, 25, 35), ClipsDescendants = true, Visible = false, Parent = Window.MasterContainer })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DiscFlyout })
local DStroke = Create("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(114, 137, 218), Parent = DiscFlyout })
ApplyAnimatedGradient(DStroke, BlueWhiteGradient, 45)

local DHead = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 25), BackgroundColor3 = Color3.fromRGB(30, 35, 45), Text = " Official Discord", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, Parent = DiscFlyout })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DHead })
Create("Frame", { Size = UDim2.new(1, 0, 0, 5), Position = UDim2.new(0, 0, 1, -5), BackgroundColor3 = Color3.fromRGB(30, 35, 45), BorderSizePixel = 0, Parent = DHead })

local ImgFrame = Create("Frame", { Size = UDim2.new(1, -20, 0, 90), Position = UDim2.new(0, 10, 0, 35), BackgroundColor3 = Color3.fromRGB(10, 15, 20), Parent = DiscFlyout })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ImgFrame })
local DImg = Create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = "rbxassetid://13426176510", Parent = ImgFrame })
Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DImg })

task.spawn(function()
    if isfile and writefile and getcustomasset then
        pcall(function()
            local imgData = game:HttpGet("https://i.ibb.co/PvrfYDt2/file-00000000c53c822fb0289572a3e45e7d.png")
            if string.find(imgData, "PNG") then
                writefile("NexzanDiscordLogo.png", imgData)
                DImg.Image = getcustomasset("NexzanDiscordLogo.png")
            end
        end)
    end
end)

local OnlineLbl = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 130), BackgroundTransparency = 1, Text = "🟢 Online: Loading...", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(100, 255, 100), Parent = DiscFlyout })
local MemberLbl = Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 0, 0, 145), BackgroundTransparency = 1, Text = "👥 Members: Loading...", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(200, 200, 200), Parent = DiscFlyout })

task.spawn(function()
    local HttpService = game:GetService("HttpService")
    while task.wait(3) do
        if DiscFlyout.Visible then
            pcall(function()
                local res = game:HttpGet("https://discord.com/api/v9/invites/DNhYgwR9SZ?with_counts=true")
                local data = HttpService:JSONDecode(res)
                if data and data.approximate_presence_count then
                    OnlineLbl.Text = "🟢 Online: " .. tostring(data.approximate_presence_count)
                    MemberLbl.Text = "👥 Members: " .. tostring(data.approximate_member_count)
                end
            end)
        end
    end
end)

local JoinBtn = Create("TextButton", { Size = UDim2.new(1, -20, 0, 30), Position = UDim2.new(0, 10, 0, 175), BackgroundColor3 = Color3.fromRGB(114, 137, 218), Text = "To Discord", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(255, 255, 255), Parent = DiscFlyout })
Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = JoinBtn })
JoinBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/DNhYgwR9SZ") end)
    JoinBtn.Text = "Link Copied!"
    task.wait(2)
    JoinBtn.Text = "To Discord"
end)

local tglDisc = TabMisc:CreateToggle("Tampilkan Discord UI", function(state)
    DiscFlyout.Visible = state
    if state then 
        if Window.DropFlyout then Window.DropFlyout.Visible = false end
    end
end)
TabMisc:CreateKeybind("Toggle Discord UI", "Y", function() tglDisc:Toggle() end)
