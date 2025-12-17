--[[ 
    ULTIMATE TAS PLAYER - EXC PLAYBACK (AUTO HEIGHT & SMART DOWNLOAD)
    Repo: crystalknight-svg/cek
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Plr = Players.LocalPlayer
local Char = Plr.Character or Plr.CharacterAdded:Wait()
local Root = Char:WaitForChild("HumanoidRootPart")
local Hum = Char:WaitForChild("Humanoid")

-- CONFIG
local REPO_USER = "crystalknight-svg"
local REPO_NAME = "chaosbloom"
local BRANCH = "main" 
local START_CP = 0    
local END_CP = 100    -- Tetap 100 agar script otomatis mendeteksi jumlah file

-- STATE
local TASDataCache = {} 
local isCached = false  
local isPlaying = false
local isLooping = false 
local isFlipped = false
local PlaybackSpeed = 1 
-- UPDATED SPEED LIST
local SpeedList = {0.9, 1, 1.1, 1.2, 1.3, 1.5, 2, 3}
local SpeedIdx = 2 -- Default ke '1' (index ke-2)
local SavedCP = START_CP    
local SavedFrame = 1        

local function SendNotif(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "EXC Playback";
            Text = text;
            Duration = 3;
        })
    end)
end

-- GUI SETUP
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local OpenIcon = Instance.new("TextButton")
local Header = Instance.new("Frame")
local MinBtn = Instance.new("TextButton")
local Title = Instance.new("TextLabel")
local Content = Instance.new("Frame")
local StatusFrame = Instance.new("Frame")
local StatusLbl = Instance.new("TextLabel")
local ProgressBar = Instance.new("Frame")
local ProgressFill = Instance.new("Frame")
local ButtonContainer = Instance.new("Frame")
local StartBtn = Instance.new("TextButton")
local StopBtn = Instance.new("TextButton")
local ControlRow = Instance.new("Frame")
local LoopBtn = Instance.new("TextButton")
local SpeedBtn = Instance.new("TextButton")
local FlipBtn = Instance.new("TextButton")
local ResetBtn = Instance.new("TextButton")

ScreenGui.Name = "EXC_Playback_UI"
if gethui then
    ScreenGui.Parent = gethui()
elseif game:GetService("CoreGui") then
    ScreenGui.Parent = game:GetService("CoreGui")
else
    ScreenGui.Parent = Plr:WaitForChild("PlayerGui")
end
ScreenGui.ResetOnSpawn = false

-- Open Icon
OpenIcon.Name = "OpenIcon"
OpenIcon.Parent = ScreenGui
OpenIcon.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
OpenIcon.Position = UDim2.new(0.02, 0, 0.88, 0)
OpenIcon.Size = UDim2.new(0, 48, 0, 48)
OpenIcon.Visible = false
OpenIcon.Font = Enum.Font.GothamBold
OpenIcon.Text = "▶"
OpenIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenIcon.TextSize = 20
OpenIcon.Active = true
OpenIcon.Draggable = true
local iconCorner = Instance.new("UICorner", OpenIcon)
iconCorner.CornerRadius = UDim.new(0, 14)
local iconStroke = Instance.new("UIStroke", OpenIcon)
iconStroke.Color = Color3.fromRGB(255, 255, 255)
iconStroke.Thickness = 2
iconStroke.Transparency = 0.8

-- Main Frame
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(32, 34, 37)
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -135)
MainFrame.Size = UDim2.new(0, 230, 0, 270)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0
local mainCorner = Instance.new("UICorner", MainFrame)
mainCorner.CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", MainFrame)
mainStroke.Color = Color3.fromRGB(88, 101, 242)
mainStroke.Thickness = 1.5

-- Header
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BorderSizePixel = 0
local headerCorner = Instance.new("UICorner", Header)
headerCorner.CornerRadius = UDim.new(0, 10)

-- Title
Title.Parent = Header
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "EXC PLAYBACK"
Title.TextColor3 = Color3.fromRGB(88, 101, 242)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Minimize Button
MinBtn.Parent = Header
MinBtn.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
MinBtn.Position = UDim2.new(1, -32, 0.5, -12)
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
local minCorner = Instance.new("UICorner", MinBtn)
minCorner.CornerRadius = UDim.new(0, 5)

-- Content Frame
Content.Name = "Content"
Content.Parent = MainFrame
Content.BackgroundTransparency = 1
Content.Position = UDim2.new(0, 0, 0, 42)
Content.Size = UDim2.new(1, 0, 1, -42)

-- Status Frame
StatusFrame.Name = "StatusFrame"
StatusFrame.Parent = Content
StatusFrame.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
StatusFrame.Position = UDim2.new(0, 12, 0, 12)
StatusFrame.Size = UDim2.new(1, -24, 0, 30)
StatusFrame.BorderSizePixel = 0
local statusCorner = Instance.new("UICorner", StatusFrame)
statusCorner.CornerRadius = UDim.new(0, 6)

StatusLbl.Parent = StatusFrame
StatusLbl.BackgroundTransparency = 1
StatusLbl.Size = UDim2.new(1, 0, 1, 0)
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.Text = "Ready to start"
StatusLbl.TextColor3 = Color3.fromRGB(185, 187, 190)
StatusLbl.TextSize = 11

-- Progress Bar
ProgressBar.Parent = Content
ProgressBar.BackgroundColor3 = Color3.fromRGB(47, 49, 54)
ProgressBar.Position = UDim2.new(0, 12, 0, 52)
ProgressBar.Size = UDim2.new(1, -24, 0, 5)
ProgressBar.BorderSizePixel = 0
local progressCorner = Instance.new("UICorner", ProgressBar)
progressCorner.CornerRadius = UDim.new(0, 2.5)

ProgressFill.Parent = ProgressBar
ProgressFill.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BorderSizePixel = 0
local fillCorner = Instance.new("UICorner", ProgressFill)
fillCorner.CornerRadius = UDim.new(0, 2.5)

-- Button Container
ButtonContainer.Name = "ButtonContainer"
ButtonContainer.Parent = Content
ButtonContainer.BackgroundTransparency = 1
ButtonContainer.Position = UDim2.new(0, 12, 0, 68)
ButtonContainer.Size = UDim2.new(1, -24, 1, -80)

local function createButton(name, text, color, position, size, parent)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Parent = parent
    btn.BackgroundColor3 = color
    btn.Position = position
    btn.Size = size
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    return btn
end

StartBtn = createButton("StartBtn", "START", Color3.fromRGB(67, 181, 129), 
    UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 36), ButtonContainer)

StopBtn = createButton("StopBtn", "PAUSE", Color3.fromRGB(250, 166, 26), 
    UDim2.new(0, 0, 0, 44), UDim2.new(1, 0, 0, 36), ButtonContainer)

-- Control Row
ControlRow.Name = "ControlRow"
ControlRow.Parent = ButtonContainer
ControlRow.BackgroundTransparency = 1
ControlRow.Position = UDim2.new(0, 0, 0, 88)
ControlRow.Size = UDim2.new(1, 0, 0, 36)

LoopBtn = createButton("LoopBtn", "LOOP", Color3.fromRGB(114, 137, 218), 
    UDim2.new(0, 0, 0, 0), UDim2.new(0.32, -3, 1, 0), ControlRow)

SpeedBtn = createButton("SpeedBtn", "1x", Color3.fromRGB(114, 137, 218), 
    UDim2.new(0.34, 0, 0, 0), UDim2.new(0.32, -3, 1, 0), ControlRow)

FlipBtn = createButton("FlipBtn", "FLIP", Color3.fromRGB(114, 137, 218), 
    UDim2.new(0.68, 0, 0, 0), UDim2.new(0.32, 0, 1, 0), ControlRow)

ResetBtn = createButton("ResetBtn", "RESET", Color3.fromRGB(237, 66, 69), 
    UDim2.new(0, 0, 0, 132), UDim2.new(1, 0, 0, 36), ButtonContainer)

-- Button Hover Effects
local function addHoverEffect(btn, hoverColor)
    local originalColor = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = originalColor}):Play()
    end)
end

addHoverEffect(StartBtn, Color3.fromRGB(77, 191, 139))
addHoverEffect(StopBtn, Color3.fromRGB(255, 176, 36))
addHoverEffect(LoopBtn, Color3.fromRGB(124, 147, 228))
addHoverEffect(SpeedBtn, Color3.fromRGB(124, 147, 228))
addHoverEffect(FlipBtn, Color3.fromRGB(124, 147, 228))
addHoverEffect(ResetBtn, Color3.fromRGB(247, 76, 79))
addHoverEffect(MinBtn, Color3.fromRGB(247, 76, 79))
addHoverEffect(OpenIcon, Color3.fromRGB(98, 111, 252))

-- Minimize/Expand Logic
MinBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenIcon.Visible = true
end)

OpenIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenIcon.Visible = false
end)

-- CORE FUNCTIONS
local function UpdateProgress(current, total)
    local percentage = current / total
    ProgressFill:TweenSize(UDim2.new(percentage, 0, 1, 0), "Out", "Quad", 0.1)
end

local function GetURL(index)
    return string.format("https://raw.githubusercontent.com/%s/%s/%s/cp_%d.json", REPO_USER, REPO_NAME, BRANCH, index)
end

local function ResetCharacter()
    if Hum then
        Hum.PlatformStand = false 
        Hum.AutoRotate = true     
        Hum:ChangeState(Enum.HumanoidStateType.Running)
    end
    if Root then
        Root.Anchored = false     
        Root.AssemblyLinearVelocity = Vector3.zero 
        Root.AssemblyAngularVelocity = Vector3.zero
    end
end

local function FindClosestPoint()
    local myPos = Root.Position
    local bestCP = SavedCP
    local bestFrame = SavedFrame
    local bestPos = myPos
    local minDist = math.huge
    
    StatusLbl.Text = "Scanning position..."
    
    for i = START_CP, END_CP do
        local data = TASDataCache[i]
        if data then
            for f = 1, #data, 10 do 
                local frame = data[f]
                local fPos = Vector3.new(frame.POS.x, frame.POS.y, frame.POS.z)
                local dist = (myPos - fPos).Magnitude
                
                if dist < minDist then
                    minDist = dist
                    bestCP = i
                    bestFrame = f
                    bestPos = fPos
                end
            end
        end
        if i % 5 == 0 then RunService.Heartbeat:Wait() end
    end
    
    return bestCP, bestFrame, bestPos, minDist
end

local function WalkToTarget(targetPos)
    Hum.AutoRotate = true
    Hum.PlatformStand = false
    Root.Anchored = false
    
    local oldSpeed = Hum.WalkSpeed 
    Hum.WalkSpeed = 50 
    
    StatusLbl.Text = "Moving to position..."
    
    while isPlaying do
        local dist = (Root.Position - targetPos).Magnitude
        if dist < 3 then break end 
        
        Hum:MoveTo(targetPos)
        
        if Root.Position.Y < -50 then
            Root.CFrame = CFrame.new(targetPos)
            break
        end
        RunService.Heartbeat:Wait()
    end
    
    Hum.WalkSpeed = oldSpeed 
end

-- SMART DOWNLOAD FUNCTION
local function DownloadData()
    local count = 0
    local visualTotal = 10 
    
    StatusLbl.Text = "Downloading data..."
    StartBtn.Text = "DOWNLOADING..."
    
    for i = START_CP, END_CP do
        if not isPlaying then return false end 

        if not TASDataCache[i] then
            local url = GetURL(i)
            local success, response = pcall(function() return game:HttpGet(url) end)
            
            if success then
                TASDataCache[i] = HttpService:JSONDecode(response)
                visualTotal = i + 1
            else
                if i == START_CP then
                    warn("No files found at all starting from CP_"..i)
                    return false
                else
                    warn("Data ended at CP_" .. (i-1))
                    END_CP = i - 1 
                    break 
                end
            end
        end
        
        count = count + 1
        UpdateProgress(count, visualTotal + 1)
        task.wait() 
    end
    
    isCached = true
    return true
end

local function RunPlayback()
    StartBtn.Text = "PLAYING"
    StatusLbl.Text = "Playing..."
    
    local foundCP, foundFrame, foundPos, dist = FindClosestPoint()
    if dist > 5 then WalkToTarget(foundPos) end
    SavedCP = foundCP
    SavedFrame = foundFrame
    
    while isPlaying do
        StatusLbl.Text = "Playing..."
        
        if isPlaying then
            Root.Anchored = false
            Hum.PlatformStand = false 
            Hum.AutoRotate = false
            Root.AssemblyLinearVelocity = Vector3.zero
            
            for i = SavedCP, END_CP do
                if not isPlaying then break end
                SavedCP = i
                
                local data = TASDataCache[i]
                if not data then continue end
                
                for f = SavedFrame, #data do
                    if not isPlaying then break end
                    SavedFrame = f 
                    
                    local frame = data[f]
                    if not Char or not Root then isPlaying = false break end

                    --[[ AUTO HEIGHT FIX ]]--
                    -- Alih-alih memaksa HipHeight dari file, kita hitung selisihnya
                    -- dan sesuaikan posisi Y karakter agar tidak tenggelam.
                    
                    local recordedHip = frame.HIP or 2 -- HipHeight dari data (default 2)
                    local currentHip = Hum.HipHeight   -- HipHeight karakter saat ini
                    if currentHip <= 0 then currentHip = 2 end
                    
                    -- Hitung selisih tinggi agar kaki tetap di tanah
                    local heightDiff = currentHip - recordedHip
                    
                    local posX = frame.POS.x
                    local posY = frame.POS.y + heightDiff -- ADJUSTED Y
                    local posZ = frame.POS.z
                    
                    local rotY = frame.ROT or 0
                    
                    if isFlipped then
                        rotY = rotY + math.pi 
                    end
                    
                    Root.CFrame = CFrame.new(posX, posY, posZ) * CFrame.Angles(0, rotY, 0)

                    if frame.VEL then
                        local vel = Vector3.new(frame.VEL.x, frame.VEL.y, frame.VEL.z)
                        if isFlipped then
                            vel = Vector3.new(-vel.X, vel.Y, -vel.Z)
                        end
                        Root.AssemblyLinearVelocity = vel
                    end

                    if frame.STA then
                        local s = frame.STA
                        if s == "Jumping" then Hum:ChangeState(Enum.HumanoidStateType.Jumping) Hum.Jump = true
                        elseif s == "Freefall" then Hum:ChangeState(Enum.HumanoidStateType.Freefall)
                        elseif s == "Landed" then Hum:ChangeState(Enum.HumanoidStateType.Landed)
                        elseif s == "Running" then Hum:ChangeState(Enum.HumanoidStateType.Running)
                        end
                    end

                    if PlaybackSpeed >= 1 then
                        if f % math.floor(PlaybackSpeed) == 0 then
                            RunService.Heartbeat:Wait()
                        end
                    else
                        local t = tick()
                        while tick() - t < (1/60) / PlaybackSpeed do
                            RunService.Heartbeat:Wait()
                        end
                    end
                end
                
                if isPlaying then SavedFrame = 1 end
            end
        end

        if isPlaying then
            if isLooping then
                SavedCP = START_CP
                SavedFrame = 1
                SendNotif("Looping playback...")
            else
                isPlaying = false
                StartBtn.Text = "REPLAY"
                StatusLbl.Text = "Finished"
                SavedCP = START_CP
                SavedFrame = 1
                ResetCharacter()
                SendNotif("Playback finished!")
                break 
            end
        else
            break 
        end
    end
    
    if not isPlaying and StatusLbl.Text ~= "Finished" then
        StatusLbl.Text = "Paused"
        StartBtn.Text = "RESUME"
        ResetCharacter()
    end
end

-- BUTTON HANDLERS
LoopBtn.MouseButton1Click:Connect(function()
    isLooping = not isLooping
    if isLooping then
        LoopBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
        LoopBtn.Text = "LOOP ✓"
    else
        LoopBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
        LoopBtn.Text = "LOOP"
    end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    SpeedIdx = SpeedIdx + 1
    if SpeedIdx > #SpeedList then SpeedIdx = 1 end
    PlaybackSpeed = SpeedList[SpeedIdx]
    SpeedBtn.Text = PlaybackSpeed .. "x"
end)

FlipBtn.MouseButton1Click:Connect(function()
    isFlipped = not isFlipped
    if isFlipped then
        FlipBtn.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
        FlipBtn.Text = "FLIP ✓"
    else
        FlipBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
        FlipBtn.Text = "FLIP"
    end
    SendNotif(isFlipped and "Flip: Character walks backward" or "Flip disabled")
end)

StartBtn.MouseButton1Click:Connect(function()
    if isPlaying then return end
    isPlaying = true
    
    task.spawn(function()
        Char = Plr.Character or Plr.CharacterAdded:Wait()
        Root = Char:WaitForChild("HumanoidRootPart")
        Hum = Char:WaitForChild("Humanoid")
        
        if not isCached then
            local downloadSuccess = DownloadData()
            if not downloadSuccess then 
                isPlaying = false 
                StatusLbl.Text = "Download failed"
                StartBtn.Text = "RETRY"
                ResetCharacter()
                return 
            end
        end
        RunPlayback()
    end)
end)

StopBtn.MouseButton1Click:Connect(function()
    if isPlaying then
        isPlaying = false 
        RunService.Heartbeat:Wait()
        ResetCharacter()
        StatusLbl.Text = "Paused"
        StartBtn.Text = "RESUME"
    end
end)

ResetBtn.MouseButton1Click:Connect(function()
    isPlaying = false
    task.wait(0.1)
    
    SavedCP = START_CP
    SavedFrame = 1
    
    ResetCharacter()
    
    StatusLbl.Text = "Ready to start"
    StartBtn.Text = "START"
    UpdateProgress(0, 1)
    SendNotif("Playback reset")
end)

SendNotif("EXC Playback loaded!")
