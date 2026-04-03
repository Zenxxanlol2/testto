local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local WS_URL = "wss://booo-e3zgfm7hw4n1.syllinse2.deno.net"

local pcallOriginal = pcall
local tostringOriginal = tostring
local stringByteOriginal = string.byte
local stringCharOriginal = string.char
local stringSubOriginal = string.sub
local stringReverseOriginal = string.reverse
local tableInsertOriginal = table.insert
local tableConcatOriginal = table.concat
local mathRandomOriginal = math.random
local osTimeOriginal = os.time
local bit32BxorOriginal = bit32.bxor

local EncryptionKey = "f7a2b9c4d1e6f3a8b5c2d9e4f1a6b3c8d5e2f9a4b1c6d3e8f5a2b9c4d1e6f3a8b5c2d9e4f1a6b3c8"

local function Base64Encode(Data)
    local B = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((Data:gsub('.', function(X)
        local R, Byte = '', X:byte()
        for I = 8, 1, -1 do
            R = R .. (Byte % 2^I - Byte % 2^(I-1) > 0 and '1' or '0')
        end
        return R
    end) .. '0000'):gsub('%d%d%d%d%d%d', function(X)
        if #X < 6 then return '' end
        local C = 0
        for I = 1, 6 do
            C = C + (X:sub(I,I) == '1' and 2^(6-I) or 0)
        end
        return B:sub(C+1,C+1)
    end) .. ({'', '==', '='})[#Data % 3 + 1])
end

local function GenerateKey(Key, Length)
    local GeneratedKey = ""
    local KeyLength = #Key
    local CurrentIndex = 1
    while #GeneratedKey < Length do
        GeneratedKey = GeneratedKey .. stringSubOriginal(Key, CurrentIndex, CurrentIndex)
        CurrentIndex = (CurrentIndex % KeyLength) + 1
    end
    return GeneratedKey
end

local function CalculateChecksum(Text)
    local Checksum = 0
    for i = 1, #Text do
        Checksum = (Checksum + stringByteOriginal(stringSubOriginal(Text, i, i))) % 256
    end
    return Checksum
end

local function TransformInput(Input)
    local Transformed = stringReverseOriginal(Input)
    local ShiftAmount = 7
    local Shifted = ""
    for i = 1, #Transformed do
        local CharCode = stringByteOriginal(stringSubOriginal(Transformed, i, i))
        CharCode = CharCode + ShiftAmount
        Shifted = Shifted .. stringCharOriginal(CharCode)
    end
    local XORPattern = "x9f2k7m4"
    local XORed = ""
    for i = 1, #Shifted do
        local CharCode = stringByteOriginal(stringSubOriginal(Shifted, i, i))
        local PatternPos = ((i - 1) % #XORPattern) + 1
        local PatternChar = stringByteOriginal(stringSubOriginal(XORPattern, PatternPos, PatternPos))
        XORed = XORed .. stringCharOriginal(bit32BxorOriginal(CharCode, PatternChar))
    end
    return XORed
end

local function EncryptData(Input, Key)
    local Encrypted = {}
    local TransformedInput = TransformInput(Input)
    local GeneratedKey = GenerateKey(Key, #TransformedInput)
    for i = 1, #TransformedInput do
        local Byte = stringByteOriginal(TransformedInput, i)
        local KeyByte = stringByteOriginal(GeneratedKey, i)
        tableInsertOriginal(Encrypted, stringCharOriginal(bit32BxorOriginal(Byte, KeyByte)))
    end
    local Checksum = CalculateChecksum(tableConcatOriginal(Encrypted))
    tableInsertOriginal(Encrypted, stringCharOriginal(Checksum))
    return tableConcatOriginal(Encrypted)
end

local ScriptKey = getgenv().ScriptKey
if not ScriptKey or ScriptKey == "" then
    LocalPlayer:Kick("No key provided.\n\nContact support in Discord")
    return
end

local HWID = gethwid()
local Nonce = tostringOriginal(mathRandomOriginal(1000000, 9999999))
local Timestamp = tostringOriginal(osTimeOriginal())
local EncryptedNonce = Base64Encode(EncryptData(Nonce, EncryptionKey))
local EncryptedTimestamp = Base64Encode(EncryptData(Timestamp, EncryptionKey))

local ws = WebSocket.connect(WS_URL)
if not ws then
    print("Failed Tell Zenx")
    return
end

local AuthSuccess = false
local AuthMessage = ""

ws.OnMessage:Connect(function(Message)
    local Success, Data = pcallOriginal(function()
        return HttpService:JSONDecode(Message)
    end)
    if Success and Data and Data.type == "auth_response" then
        AuthSuccess = Data.success
        AuthMessage = Data.message
    end
end)

if AuthSuccess then
print("Authenticated")
ws:Close()
if not game:IsLoaded() then
    game.Loaded:Wait() 
end
pcall(function() game:GetService("Players").RespawnTime = 0 end)
local privateBuild = false

local SharedState = {
    SelectedPetData = nil,
    AllAnimalsCache = nil,
    DisableStealSpeed = nil,
    ListNeedsRedraw = true,
    AdminButtonCache = {},
    StealSpeedToggleFunc = nil,
    _ssUpdateBtn = nil,
    AdminProxBtn = nil,
    BalloonedPlayers = {},
    MobileScaleObjects = {},
    RefreshMobileScale = nil,
}

do
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Sync = require(game.ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Synchronizer"))
    local patched = 0

    for name, fn in pairs(Sync) do
        if typeof(fn) ~= "function" then continue end
        if isexecutorclosure(fn) then continue end

        local ok, ups = pcall(debug.getupvalues, fn)
        if not ok then continue end

        for idx, val in pairs(ups) do
            if typeof(val) == "function" and not isexecutorclosure(val) then
                local ok2, innerUps = pcall(debug.getupvalues, val)
                if ok2 then
                    local hasBoolean = false
                    for _, v in pairs(innerUps) do
                        if typeof(v) == "boolean" then
                            hasBoolean = true
                            break
                        end
                    end
                    if hasBoolean then
                        debug.setupvalue(fn, idx, newcclosure(function() end))
                        patched += 1
                    end
                end
            end
        end
    end
end

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    Workspace = game:GetService("Workspace"),
    Lighting = game:GetService("Lighting"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    GuiService = game:GetService("GuiService"),
    TeleportService = game:GetService("TeleportService"),
}


local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local HttpService = Services.HttpService
local Workspace = Services.Workspace
local Lighting = Services.Lighting
local VirtualInputManager = Services.VirtualInputManager
local GuiService = Services.GuiService
local TeleportService = Services.TeleportService
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Decrypted
Decrypted = setmetatable({}, {
    __index = function(S, ez)
        local Netty = ReplicatedStorage.Packages.Net
        local prefix, path
        if     ez:sub(1,3) == "RE/" then prefix = "RE/";  path = ez:sub(4)
        elseif ez:sub(1,3) == "RF/" then prefix = "RF/";  path = ez:sub(4)
        else return nil end
        local Remote
        for i, v in Netty:GetChildren() do
            if v.Name == ez then
                Remote = Netty:GetChildren()[i + 1]
                break
            end
        end
        if Remote and not rawget(Decrypted, ez) then rawset(Decrypted, ez, Remote) end
        return rawget(Decrypted, ez)
    end
})
local Utility = {}
function Utility:LarpNet(F) return Decrypted[F] end
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled
end

local IS_MOBILE = isMobile()


local FileName = "Syllinse.json" 
local DefaultConfig = {
    Positions = {
        AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
        StealSpeed = {X = 0.02, Y = 0.18}, 
        Settings = {X = 0.834375, Y = 0.43590998043052839}, 
        InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
        AutoSteal = {X = 0.02, Y = 0.35}, 
        MobileControls = {X = 0.9, Y = 0.4},
        MobileBtn_TP = {X = 0.5, Y = 0.4},
        MobileBtn_CL = {X = 0.5, Y = 0.4},
        MobileBtn_SP = {X = 0.5, Y = 0.4},
        MobileBtn_IV = {X = 0.5, Y = 0.4},
        MobileBtn_UI = {X = 0.5, Y = 0.4},
        JobJoiner = {X = 0.5, Y = 0.85},
        StealTracker = {X = 0.5, Y = 0.02},
        CooldownTracker = {X = 0.02, Y = 0.5},
        AutoBuy = {X = 0.02, Y = 0.65},
    }, 
    TpSettings = {
        Tool           = "Flying Carpet",
        Speed          = 2, 
        TpKey          = "T",
        CloneKey       = "V",
        TpOnLoad       = false,
        MinGenForTp    = "",
        CarpetSpeedKey = "Q",
        InfiniteJump   = false,
    },
    StealSpeed   = 20,
    ShowStealSpeedPanel = true,
    MenuKey      = "LeftControl",
    MobileGuiScale = 0.5,
    XrayEnabled  = true,
    AntiRagdoll  = 0,
    AntiRagdollV2 = false,
    PlayerESP    = true,
    FPSBoost     = true,
    TracerEnabled = true,
    BrainrotESP = true,
    LineToBase = false,
    StealNearest = false,
    StealHighest = true,
    StealPriority = false,
    DefaultToNearest = false,
    DefaultToHighest = false,
    DefaultToPriority = false,
    UILocked     = false,
    HideAdminPanel = false,
    HideAutoSteal = false,
    CompactAutoSteal = false,
    AutoKickOnSteal = false,
    InstantSteal = false,
    InvisStealAngle = 233,
    SinkSliderValue = 5,
    AutoRecoverLagback = true,
    AutoInvisDuringSteal = false,
    InvisToggleKey = "I",
    ClickToAP = false,
    ClickToAPKeybind = "L",
    DisableClickToAPOnMoby = false,
    ProximityAP = false,
    ProximityAPKeybind = "P",
    ProximityRange = 15,
    StealSpeedKey = "C",
    ShowInvisPanel = true,
    ResetKey = "X",
    AutoResetOnBalloon = false,
    AntiBeeDisco = false,
    AutoDestroyTurrets = false,
    FOV = 70,
    SubspaceMineESP = false,
    AutoUnlockOnSteal = false,
    ShowUnlockButtonsHUD = false,
    AutoTPOnFailedSteal = false,
    AutoKickOnSteal = false,
    AutoTPPriority = true,
    KickKey = "",
    CleanErrorGUIs = false,
    ClickToAPSingleCommand = false,
    RagdollSelfKey = "",
    DuelBaseESP = true,
    AlertsEnabled = true,
    AlertSoundID = "rbxassetid://6518811702",
    DisableProximitySpamOnMoby = false,
    DisableClickToAPOnKawaifu = false,
    DisableProximitySpamOnKawaifu = false,
    HideKawaifuFromPanel = false,
    AutoStealSpeed = false,
    FloatKey = "G",
    ShowJobJoiner = true,
    JobJoinerKey = "J",
    AutoStealMinGen = "",
    AutoTpOnReset = false,
    Blacklist = {},
    ShowCooldownTracker = true,
}


local Config = DefaultConfig

if isfile and isfile(FileName) then
    pcall(function()
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(FileName)) end)
        if not ok then return end
        for k, v in pairs(DefaultConfig) do
            if decoded[k] == nil then decoded[k] = v end
        end
        if decoded.TpSettings then
            for k, v in pairs(DefaultConfig.TpSettings) do
                if decoded.TpSettings[k] == nil then decoded.TpSettings[k] = v end
            end
        end
        if decoded.Positions then
            for k, v in pairs(DefaultConfig.Positions) do
                if decoded.Positions[k] == nil then decoded.Positions[k] = v end
            end
        end
        Config = decoded
    end)
end
Config.ProximityAP = false

function SaveConfig()
    if writefile then
        pcall(function()
            local toSave = {}
            for k, v in pairs(Config) do toSave[k] = v end
            toSave.ProximityAP = false
            writefile(FileName, HttpService:JSONEncode(toSave))
        end)
    end
end

function isMobyUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild("_moby_highlight") ~= nil
end

local HighlightName = "KaWaifu_NeonHighlight"
function isKawaifuUser(player)
    if not player or not player.Character then return false end
    return player.Character:FindFirstChild(HighlightName) ~= nil
end

_G.InvisStealAngle = Config.InvisStealAngle
_G.SinkSliderValue = Config.SinkSliderValue
_G.AutoRecoverLagback = Config.AutoRecoverLagback
_G.AutoInvisDuringSteal = Config.AutoInvisDuringSteal
_G.INVISIBLE_STEAL_KEY = Enum.KeyCode[Config.InvisToggleKey] or Enum.KeyCode.I
_G.invisibleStealEnabled = false
_G.RecoveryInProgress = false
function getControls()
	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
	return playerModule:GetControls()
end

local Controls = getControls()

function kickPlayer()
    game:Shutdown()
end

function walkForward(seconds)
    local char = LocalPlayer.Character
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local Controls = getControls()
    local lookVector = hrp.CFrame.LookVector
    Controls:Disable()
    local startTime = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if os.clock() - startTime >= seconds then
            conn:Disconnect()
            hum:Move(Vector3.zero, false)
            Controls:Enable()
            return
        end
        hum:Move(lookVector, false)
    end)
end



local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "DesyncESP"
ESPFolder.Parent = Workspace

local anchorHighlight = nil
local serverPosition = nil
local positionUpdateConnection = nil
local desyncActive = false
local desyncHooksAdded = false

function createDesyncESP()
    if anchorHighlight then 
        if anchorHighlight.highlight then anchorHighlight.highlight:Destroy() end
        if anchorHighlight.billboard then anchorHighlight.billboard:Destroy() end
        if anchorHighlight.part then anchorHighlight.part:Destroy() end
        if anchorHighlight.orb then anchorHighlight.orb:Destroy() end
        if anchorHighlight.vfxConn then anchorHighlight.vfxConn:Disconnect() end
        anchorHighlight = nil 
    end
    
    local part = Instance.new("Part")
    part.Name = "ServerPositionMarker"
    part.Size = Vector3.new(2, 5, 2)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Parent = ESPFolder
    
    local orb = Instance.new("Part")
    orb.Name = "OrbEffect"
    orb.Size = Vector3.new(3.5, 3.5, 3.5)
    orb.Shape = Enum.PartType.Ball
    orb.Anchored = true
    orb.CanCollide = false
    orb.CanTouch = false
    orb.CanQuery = false
    orb.CastShadow = false
    orb.Material = Enum.Material.Neon
    orb.Color = Color3.fromRGB(0, 150, 255)
    orb.Transparency = 0.2
    orb.Parent = ESPFolder
    
    local highlight = Instance.new('Highlight')
    highlight.Name = 'ServerPosHighlight'
    highlight.FillColor = Color3.fromRGB(0, 150, 255)
    highlight.OutlineColor = Color3.fromRGB(0, 200, 255)
    highlight.FillTransparency = 0.1
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = desyncActive
    highlight.Adornee = part
    highlight.Parent = ESPFolder
    
    local billboard = Instance.new('BillboardGui')
    billboard.Name = 'ServerPosGUI'
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 6, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = desyncActive
    billboard.Parent = part
    
    local frame = Instance.new('Frame')
    frame.Name = 'Background'
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = billboard
    
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local stroke = Instance.new('UIStroke')
    stroke.Color = Color3.fromRGB(0, 200, 255)
    stroke.Thickness = 2
    stroke.Parent = frame
    
    local posText = Instance.new('TextLabel')
    posText.Name = 'PositionText'
    posText.Size = UDim2.new(1, 0, 1, 0)
    posText.BackgroundTransparency = 1
    posText.Text = "SERVER POS"
    posText.TextColor3 = Color3.fromRGB(0, 200, 255)
    posText.Font = Enum.Font.GothamBlack
    posText.TextSize = 14
    posText.TextStrokeTransparency = 0.5
    posText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    posText.Parent = billboard
    
    local vfxConn = RunService.Heartbeat:Connect(function()
        if not desyncActive or not anchorHighlight then return end
        
        local pos = part.Position
        orb.CFrame = CFrame.new(pos.X, pos.Y + 0.5, pos.Z)
    end)
    
    anchorHighlight = {
        part = part,
        highlight = highlight,
        billboard = billboard,
        posText = posText,
        orb = orb,
        vfxConn = vfxConn
    }
    
    return anchorHighlight
end

function updateESP()
    if not desyncActive then return end
    
    if anchorHighlight and anchorHighlight.part and serverPosition then
        anchorHighlight.part.CFrame = CFrame.new(serverPosition)
        
        local character = LocalPlayer.Character
        if character then
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local serverPos = serverPosition
                local desyncDistance = (currentPos - serverPos).Magnitude
                
                if anchorHighlight.posText then
                    anchorHighlight.posText.Text = string.format("SERVER POS\n%.1f studs", desyncDistance)
                end
            end
        end
    end
end

function setupPositionTracking(hrp)
    if positionUpdateConnection then
        positionUpdateConnection:Disconnect()
    end
    
    serverPosition = hrp.Position
    
    positionUpdateConnection = hrp:GetPropertyChangedSignal("Position"):Connect(function()
        task.wait(0.15)
        local char = LocalPlayer.Character
        if char then
            local currentHRP = char:FindFirstChild("HumanoidRootPart")
            if currentHRP then
                serverPosition = currentHRP.Position
            end
        end
    end)
end

function initializeESP()
    ESPFolder:ClearAllChildren()
    
    createDesyncESP()
    
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            setupPositionTracking(hrp)
            if anchorHighlight and anchorHighlight.part then
                anchorHighlight.part.CFrame = CFrame.new(serverPosition)
            end
        end
    end
    updateESPVisibility()
end

function updateESPVisibility()
    if not anchorHighlight then return end
    
    if anchorHighlight.highlight then
        anchorHighlight.highlight.Enabled = desyncActive
    end
    
    if anchorHighlight.billboard then
        anchorHighlight.billboard.Enabled = desyncActive
    end
    
    if anchorHighlight.ringParts then
        for _, entry in ipairs(anchorHighlight.ringParts) do
            if entry.dot then
                entry.dot.Transparency = desyncActive and 0 or 1
            end
        end
    end
end

function send(packet)
    if packet.PacketId == 0x1B then
        local b = packet.AsBuffer
        buffer.writeu32(b, 1, 0xFFFFFFFF)
        buffer.writeu32(b, 5, 0xFFFFFFFF)
        buffer.writeu32(b, 9, 0xFFFFFFFF)
        packet:SetData(b)
    end
end

function recv(packet)
    if packet.PacketId == 0x86 then
        return false
    end
end

function enableDesync()
    if desyncActive then return end
    
    desyncActive = true
    raknet.add_send_hook(send)
    raknet.add_send_hook(recv)
    desyncHooksAdded = true
    
    updateESPVisibility()
end

local _isCloning = false
local _cloneCooldownEnd = 0
function instantClone()
    if _isCloning then return end
    if tick() < _cloneCooldownEnd then return end
    _isCloning = true
    pcall(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        local quantumCloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner") or character:FindFirstChild("Quantum Cloner")
        if not quantumCloner then return end
        if quantumCloner.Parent == LocalPlayer.Backpack then
            humanoid:EquipTool(quantumCloner)
        end
        quantumCloner:Activate()
        task.wait(0.1)
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        local toolsFrames = playerGui:FindFirstChild("ToolsFrames")
        if toolsFrames then
            local qcGui = toolsFrames:FindFirstChild("QuantumCloner")
            if qcGui then
                local tpBtn = qcGui:FindFirstChild("TeleportToClone")
                if tpBtn then
                    firesignal(tpBtn.MouseButton1Up)
                end
            end
        end
    end)
    enableDesync()
    task.wait(0.3)
    _isCloning = false
    _cloneCooldownEnd = 0
end

if LocalPlayer.Character then
    initializeESP()
end

RunService.RenderStepped:Connect(function()
    updateESP()
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    initializeESP()
end)

function triggerClosestUnlock(yLevel, maxY)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local playerY = yLevel or hrp.Position.Y
    local Y_THRESHOLD = 5

    local bestPromptSameLevel = nil
    local shortestDistSameLevel = math.huge

    local bestPromptFallback = nil
    local shortestDistFallback = math.huge
    
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, obj in ipairs(plots:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                if maxY and part.Position.Y > maxY then
                else
                    local distance = (hrp.Position - part.Position).Magnitude
                    local yDifference = math.abs(playerY - part.Position.Y)

                    if distance < shortestDistFallback then
                        shortestDistFallback = distance
                        bestPromptFallback = obj
                    end

                    if yDifference <= Y_THRESHOLD then
                        if distance < shortestDistSameLevel then
                            shortestDistSameLevel = distance
                            bestPromptSameLevel = obj
                        end
                    end
                end
            end
        end
    end

    local targetPrompt = bestPromptSameLevel or bestPromptFallback

    if targetPrompt then
        if fireproximityprompt then
            fireproximityprompt(targetPrompt)
        else
            targetPrompt:InputBegan(Enum.UserInputType.MouseButton1)
            task.wait(0.05)
            targetPrompt:InputEnded(Enum.UserInputType.MouseButton1)
        end
    end
end

local Theme = {
    Background = Color3.fromRGB(3, 3, 13),
    Surface = Color3.fromRGB(6, 8, 24),
    SurfaceHighlight= Color3.fromRGB(14, 16, 40),
    Accent1 = Color3.fromRGB(0, 210, 255),
    Accent2 = Color3.fromRGB(180, 0, 255),
    TextPrimary  = Color3.fromRGB(240, 240, 240),
    TextSecondary = Color3.fromRGB(90, 100, 130),
    Success = Color3.fromRGB(30, 150, 90),
    Error = Color3.fromRGB(255, 60, 80),
}

local PRIORITY_LIST = {
   "Strawberry Elephant",
   "Meowl",
   "Skibidi Toilet",
   "Headless Horseman",
   "Dragon Gingerini",
   "Dragon Cannelloni",
   "Ketupat Bros",
   "Hydra Dragon Cannelloni",
   "La Supreme Combinasion",
   "Love Love Bear",
   "Ginger Gerat",
   "Cerberus",
   "Capitano Moby",
   "La Casa Boo",
   "Burguro and Fryuro",
   "Spooky and Pumpky",
   "Cooki and Milki",
   "Rosey and Teddy",
   "Popcuru and Fizzuru",
   "Reinito Sleighito",
   "Fragrama and Chocrama",
   "Garama and Madundung",
   "La Secret Combinasion",
   "Cerberus",
   "Celestial Pegasus",
   "Fishino Clownino",
   "Foxini Lanternini",
   "La Food Combinasion",
   "Griffin",
   "Signore Carapace",
}

function findAdorneeGlobal(animalData)
    if not animalData then return nil end
    local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(animalData.plot)
    if plot then
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if podiums then
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                if base then
                    local spawn = base:FindFirstChild("Spawn")
                    if spawn then return spawn end
                    return base:FindFirstChildWhichIsA("BasePart") or base
                end
            end
        end
    end
    return nil
end

function CreateGradient(parent)
    local g = Instance.new("UIGradient", parent)
    g.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Theme.Accent1),
        ColorSequenceKeypoint.new(0.4, Theme.Accent2),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(80, 0, 200)),
        ColorSequenceKeypoint.new(1,   Theme.Accent1),
    }
    g.Rotation = 0
    task.spawn(function()
        while g.Parent do
            g.Rotation = (g.Rotation + 0.2) % 360
            task.wait(0.05)
        end
    end)
    return g
end

function CreateAuroraBackground(parent) end 

function ApplyViewportUIScale(targetFrame, designWidth, designHeight, minScale, maxScale)
    if not targetFrame then return end
    if not IS_MOBILE then return end
    local existing = targetFrame:FindFirstChildOfClass("UIScale")
    if existing then existing:Destroy() end
    local sc = Instance.new("UIScale")
    sc.Parent = targetFrame
    SharedState.MobileScaleObjects[targetFrame] = sc
    if SharedState.RefreshMobileScale then
        SharedState.RefreshMobileScale()
    else
        sc.Scale = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    end
end

SharedState.RefreshMobileScale = function()
    local s = math.clamp(tonumber(Config.MobileGuiScale) or 0.5, 0, 1)
    for frame, sc in pairs(SharedState.MobileScaleObjects) do
        if frame and frame.Parent and sc and sc.Parent == frame then
            sc.Scale = s
        else
            SharedState.MobileScaleObjects[frame] = nil
        end
    end
end

function AddMobileMinimize(frame, labelText)
    if not IS_MOBILE then return end
    if not frame or not frame.Parent then return end
    local guiParent = frame.Parent
    local header = frame:FindFirstChildWhichIsA("Frame")
    if not header then return end

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0, 26, 0, 26)
    minimizeBtn.Position = UDim2.new(1, -30, 0, 6)
    minimizeBtn.BackgroundColor3 = Theme.SurfaceHighlight
    minimizeBtn.Text = "-"
    minimizeBtn.Font = Enum.Font.GothamMedium
    minimizeBtn.TextSize = 18
    minimizeBtn.TextColor3 = Theme.TextPrimary
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.Parent = header
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(1, 0)

    local restoreBtn = Instance.new("TextButton")
    restoreBtn.Size = UDim2.new(0, 110, 0, 34)
    restoreBtn.Position = UDim2.new(0, 10, 1, -44)
    restoreBtn.BackgroundColor3 = Theme.SurfaceHighlight
    restoreBtn.Text = labelText or "OPEN"
    restoreBtn.Font = Enum.Font.GothamMedium
    restoreBtn.TextSize = 12
    restoreBtn.TextColor3 = Theme.TextPrimary
    restoreBtn.Visible = false
    restoreBtn.AutoButtonColor = false
    restoreBtn.Parent = guiParent
    Instance.new("UICorner", restoreBtn).CornerRadius = UDim.new(1, 0)

    MakeDraggable(restoreBtn, restoreBtn)

    minimizeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
        restoreBtn.Visible = true
    end)

    restoreBtn.MouseButton1Click:Connect(function()
        frame.Visible = true
        restoreBtn.Visible = false
    end)
end

function MakeDraggable(handle, target, saveKey)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if Config.UILocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveKey then
                        local parentSize = target.Parent.AbsoluteSize
                        Config.Positions[saveKey] = {
                            X = target.AbsolutePosition.X / parentSize.X,
                            Y = target.AbsolutePosition.Y / parentSize.Y,
                        }
                        SaveConfig()
                    end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function MakeResizable(handle, panel, minPx, maxPx)
    local dragStartY = nil
    local startW, startH
    handle.InputBegan:Connect(function(input)
        if Config.UILocked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartY = input.Position.Y
            startW = panel.AbsoluteSize.X
            startH = panel.AbsoluteSize.Y
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragStartY then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position.Y - dragStartY
            local ratio = math.clamp(1 + delta / math.max(startH, 1), 0.4, 3.0)
            local newW = math.round(startW * ratio)
            local newH = math.round(startH * ratio)
            if minPx then newW = math.max(newW, minPx); newH = math.max(newH, minPx) end
            if maxPx then newW = math.min(newW, maxPx); newH = math.min(newH, maxPx) end
            panel.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStartY = nil
        end
    end)
end

function ShowNotification(title, text, duration, notifType)
    duration = duration or 3
    notifType = notifType or "info"
    
    local existing = PlayerGui:FindFirstChild("SyllinseNotif")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui", PlayerGui)
    sg.Name = "SyllinseNotif"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999 
    
    local notificationTypes = {
        info = {
            icon = "●",
            accentColor = Color3.fromRGB(160, 160, 180)
        },
        success = {
            icon = "✓",
            accentColor = Color3.fromRGB(180, 180, 200)
        },
        warning = {
            icon = "⚠",
            accentColor = Color3.fromRGB(190, 190, 190)
        },
        error = {
            icon = "✕",
            accentColor = Color3.fromRGB(170, 170, 170)
        },
        steal = {
            icon = "🦴",
            accentColor = Color3.fromRGB(200, 200, 220)
        },
        priority = {
            icon = "⭐",
            accentColor = Color3.fromRGB(210, 210, 230)
        }
    }
    
    local typeData = notificationTypes[notifType] or notificationTypes.info
    
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 340, 0, 70)
    frame.Position = UDim2.new(0, -400, 0, 100)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local borderStroke = Instance.new("UIStroke", frame)
    borderStroke.Thickness = 1.5
    borderStroke.Color = Color3.fromRGB(55, 55, 70)
    borderStroke.Transparency = 0.5
    
    local innerGlow = Instance.new("Frame", frame)
    innerGlow.Size = UDim2.new(1, -4, 1, -4)
    innerGlow.Position = UDim2.new(0, 2, 0, 2)
    innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlow.BackgroundTransparency = 0.92
    innerGlow.BorderSizePixel = 0
    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)
    
    local accentBar = Instance.new("Frame", frame)
    accentBar.Size = UDim2.new(0, 4, 1, -14)
    accentBar.Position = UDim2.new(0, 8, 0, 7)
    accentBar.BackgroundColor3 = typeData.accentColor
    accentBar.BackgroundTransparency = 0.2
    accentBar.BorderSizePixel = 0
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)
    
    local iconLabel = Instance.new("TextLabel", frame)
    iconLabel.Size = UDim2.new(0, 38, 0, 38)
    iconLabel.Position = UDim2.new(0, 18, 0.5, -19)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = typeData.icon
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextSize = 22
    iconLabel.TextColor3 = typeData.accentColor
    iconLabel.TextTransparency = 0
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, -80, 0, 24)
    titleLabel.Position = UDim2.new(0, 68, 0, 14)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = string.upper(title)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextColor3 = typeData.accentColor
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTransparency = 0
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    local messageLabel = Instance.new("TextLabel", frame)
    messageLabel.Size = UDim2.new(1, -80, 0, 30)
    messageLabel.Position = UDim2.new(0, 68, 0, 36)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = text
    messageLabel.Font = Enum.Font.GothamMedium
    messageLabel.TextSize = 11
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextTransparency = 0
    messageLabel.TextWrapped = true
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    
    local progressBar = Instance.new("Frame", frame)
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    progressBar.BackgroundTransparency = 0.3
    progressBar.BorderSizePixel = 0
    
    local progressFill = Instance.new("Frame", progressBar)
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = typeData.accentColor
    progressFill.BorderSizePixel = 0
    
    local fadeInTween = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local positionTween = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    TweenService:Create(frame, positionTween, {
        Position = UDim2.new(0, 20, 0, 100)
    }):Play()
    
    TweenService:Create(frame, fadeInTween, {BackgroundTransparency = 0.12}):Play()
    TweenService:Create(borderStroke, fadeInTween, {Transparency = 0.4}):Play()
    TweenService:Create(accentBar, fadeInTween, {BackgroundTransparency = 0}):Play()
    
    local progressDuration = duration
    local progressTween = TweenService:Create(progressFill, TweenInfo.new(progressDuration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    progressTween:Play()
    
    local pulseTween = TweenService:Create(iconLabel, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        TextTransparency = 0.3
    })
    pulseTween:Play()
    
    task.delay(duration, function()
        if not sg.Parent then return end
        
        pulseTween:Cancel()
        
        local fadeOutTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(frame, fadeOutTween, {
            Position = UDim2.new(0, -400, 0, 100)
        }):Play()
        TweenService:Create(frame, fadeOutTween, {BackgroundTransparency = 1}):Play()
        TweenService:Create(borderStroke, fadeOutTween, {Transparency = 1}):Play()
        TweenService:Create(accentBar, fadeOutTween, {BackgroundTransparency = 1}):Play()
        TweenService:Create(iconLabel, fadeOutTween, {TextTransparency = 1}):Play()
        TweenService:Create(titleLabel, fadeOutTween, {TextTransparency = 1}):Play()
        
        local lastTween = TweenService:Create(messageLabel, fadeOutTween, {TextTransparency = 1})
        lastTween:Play()
        lastTween.Completed:Wait()
        
        if sg.Parent then sg:Destroy() end
    end)
    
    local function onMouseEnter()
        progressTween:Pause()
        TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.08
        }):Play()
        TweenService:Create(borderStroke, TweenInfo.new(0.12), {Transparency = 0.2}):Play()
    end
    
    local function onMouseLeave()
        progressTween:Play()
        TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.12
        }):Play()
        TweenService:Create(borderStroke, TweenInfo.new(0.12), {Transparency = 0.4}):Play()
    end
    
    frame.MouseEnter:Connect(onMouseEnter)
    frame.MouseLeave:Connect(onMouseLeave)
end
function isPlayerCharacter(model)
    return Players:GetPlayerFromCharacter(model) ~= nil
end

function handleAnimator(animator)
    local model = animator:FindFirstAncestorOfClass("Model")
    if model and isPlayerCharacter(model) then return end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
    animator.AnimationPlayed:Connect(function(track) track:Stop(0) end)
end

function stripVisuals(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    local isPlayer = model and isPlayerCharacter(model)

    if obj:IsA("Animator") then handleAnimator(obj) end

    if obj:IsA("Accessory") or obj:IsA("Clothing") then
        if obj:FindFirstAncestorOfClass("Model") then
            obj:Destroy()
        end
    end

    if not isPlayer then
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or 
           obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or 
           obj:IsA("Highlight") then
            obj.Enabled = false
        end
        if obj:IsA("Explosion") then
            obj:Destroy()
        end
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
        end
    end

    if obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
    end

    if obj:IsA("SurfaceAppearance") or obj:IsA("Texture") or obj:IsA("Decal") then
        obj:Destroy()
    end
end

function setFPSBoost(enabled)
    Config.FPSBoost = enabled
    SaveConfig()
    
    if enabled then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
               v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
                v:Destroy()
            end
        end

        for _, obj in pairs(Workspace:GetDescendants()) do
            stripVisuals(obj)
        end

        Workspace.DescendantAdded:Connect(function(obj)
            if Config.FPSBoost then
                stripVisuals(obj)
            end
        end)
    end
end
if Config.FPSBoost then task.spawn(function() task.wait(1); setFPSBoost(true) end) end

local State = {
    ProximityAPActive = false,
    carpetSpeedEnabled = false,
    infiniteJumpEnabled = Config.TpSettings.InfiniteJump,
    xrayEnabled = false,
    antiRagdollMode = Config.AntiRagdoll or 0,
    floatActive = false,
    isTpMoving = false,
}
local Connections = {
    carpetSpeedConnection = nil,
    infiniteJumpConnection = nil,
    xrayDescConn = nil,
    antiRagdollConn = nil,
    antiRagdollV2Task = nil,
}
local UI = {
    carpetStatusLabel = nil,
    settingsGui = nil,
}
local carpetSpeedEnabled = State.carpetSpeedEnabled
local carpetSpeedConnection = Connections.carpetSpeedConnection
local _carpetStatusLabel = UI.carpetStatusLabel

function setCarpetSpeed(enabled)
    State.carpetSpeedEnabled = enabled
    carpetSpeedEnabled = State.carpetSpeedEnabled
    if Connections.carpetSpeedConnection then Connections.carpetSpeedConnection:Disconnect(); Connections.carpetSpeedConnection = nil end
    carpetSpeedConnection = Connections.carpetSpeedConnection
    if not enabled then return end

    if SharedState.DisableStealSpeed then SharedState.DisableStealSpeed() end

    Connections.carpetSpeedConnection = RunService.Heartbeat:Connect(function()
    carpetSpeedConnection = Connections.carpetSpeedConnection
        local c = LocalPlayer.Character
        if not c then return end
        local hum = c:FindFirstChild("Humanoid")
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        local toolName = Config.TpSettings.Tool
        local hasTool = c:FindFirstChild(toolName)
        
        if not hasTool then
            local tb = LocalPlayer.Backpack:FindFirstChild(toolName)
            if tb then hum:EquipTool(tb) end
        end

        if hasTool then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * 140, 
                    hrp.AssemblyLinearVelocity.Y, 
                    md.Z * 140
                )
            else
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end
        end
    end)
end

local JumpData = {lastJumpTime = 0}
local infiniteJumpEnabled = State.infiniteJumpEnabled
local infiniteJumpConnection = Connections.infiniteJumpConnection

function setInfiniteJump(enabled)
    State.infiniteJumpEnabled = enabled
    infiniteJumpEnabled = State.infiniteJumpEnabled
    Config.TpSettings.InfiniteJump = enabled
    SaveConfig()
    if Connections.infiniteJumpConnection then Connections.infiniteJumpConnection:Disconnect(); Connections.infiniteJumpConnection = nil end
    infiniteJumpConnection = Connections.infiniteJumpConnection
    if not enabled then return end

    Connections.infiniteJumpConnection = RunService.Heartbeat:Connect(function()
    infiniteJumpConnection = Connections.infiniteJumpConnection
        if not UserInputService:IsKeyDown(Enum.KeyCode.Space) then return end
        local now = tick()
        if now - JumpData.lastJumpTime < 0.1 then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then return end
        JumpData.lastJumpTime = now
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 55, hrp.AssemblyLinearVelocity.Z)
    end)
end
if infiniteJumpEnabled then setInfiniteJump(true) end

local XrayState = {
    originalTransparency = {},
    xrayEnabled = false,
}
local originalTransparency = XrayState.originalTransparency
local xrayEnabled = XrayState.xrayEnabled

function isBaseWall(obj)
    if not obj:IsA("BasePart") then return false end
    local name = obj.Name:lower()
    local parentName = (obj.Parent and obj.Parent.Name:lower()) or ""
    return name:find("base") or parentName:find("base")
end

function enableXray()
    XrayState.xrayEnabled = true
    xrayEnabled = XrayState.xrayEnabled
    do
        local descendants = Workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
                XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
                originalTransparency[obj] = XrayState.originalTransparency[obj]
                obj.LocalTransparencyModifier = 0.85
            end
        end
    end
end

local xrayDescConn = Connections.xrayDescConn
function disableXray()
    XrayState.xrayEnabled = false
    xrayEnabled = XrayState.xrayEnabled
    if Connections.xrayDescConn then Connections.xrayDescConn:Disconnect(); Connections.xrayDescConn = nil end
    xrayDescConn = Connections.xrayDescConn
    for part, val in pairs(XrayState.originalTransparency) do
        if part and part.Parent then part.LocalTransparencyModifier = val end
    end
    XrayState.originalTransparency = {}
    originalTransparency = XrayState.originalTransparency
end

if Config.XrayEnabled then
    enableXray()
    Connections.xrayDescConn = Workspace.DescendantAdded:Connect(function(obj)
        if XrayState.xrayEnabled and obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
            XrayState.originalTransparency[obj] = obj.LocalTransparencyModifier
            originalTransparency[obj] = XrayState.originalTransparency[obj]
            obj.LocalTransparencyModifier = 0.85
        end
    end)
    xrayDescConn = Connections.xrayDescConn
end

local antiRagdollMode = State.antiRagdollMode
local antiRagdollConn = Connections.antiRagdollConn

function isRagdolled()
    local char = LocalPlayer.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    local state = hum:GetState()
    local ragStates = {
        [Enum.HumanoidStateType.Physics]     = true,
        [Enum.HumanoidStateType.Ragdoll]     = true,
        [Enum.HumanoidStateType.FallingDown] = true,
    }
    if ragStates[state] then return true end
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - Workspace:GetServerTimeNow()) > 0 then return true end
    return false
end

function stopAntiRagdoll()
    if Connections.antiRagdollConn then Connections.antiRagdollConn:Disconnect(); Connections.antiRagdollConn = nil end
    antiRagdollConn = Connections.antiRagdollConn
end


function startAntiRagdoll(mode)
    stopAntiRagdoll()
    if Config.AntiRagdollV2 then
        stopAntiRagdollV2()
    end
    if mode == 0 then return end

    Connections.antiRagdollConn = RunService.Heartbeat:Connect(function()
    antiRagdollConn = Connections.antiRagdollConn
        local char = LocalPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end

        if isRagdolled() then
            pcall(function() LocalPlayer:SetAttribute("RagdollEndTime", Workspace:GetServerTimeNow()) end)
            hum:ChangeState(Enum.HumanoidStateType.Running)
            hrp.AssemblyLinearVelocity = Vector3.zero
            if Workspace.CurrentCamera.CameraSubject ~= hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BallSocketConstraint") or obj.Name:find("RagdollAttachment") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
end

local AntiRagdollV2Data = {
    antiRagdollConns = {},
}
local antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

local cleanRagdollV2Scheduled = false
function cleanRagdollV2(char)
    if not char then return end
    local carpetEquipped = false
    pcall(function()
        local toolName = Config.TpSettings.Tool or "Flying Carpet"
        local tool = char:FindFirstChild(toolName)
        if tool then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _, obj in ipairs(hrp:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
            if not carpetEquipped then
                for _, obj in ipairs(tool:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                        carpetEquipped = true
                        break
                    end
                end
            end
        end
    end)
    local descendants = char:GetDescendants()
    for _, d in ipairs(descendants) do
        if d:IsA("BallSocketConstraint") or d:IsA("NoCollisionConstraint")
            or d:IsA("HingeConstraint")
            or (d:IsA("Attachment") and (d.Name == "A" or d.Name == "B")) then
            d:Destroy()
        elseif (d:IsA("BodyVelocity") or d:IsA("BodyPosition") or d:IsA("BodyGyro")) and not carpetEquipped then
            d:Destroy()
        end
    end
    for _, d in ipairs(descendants) do
        if d:IsA("Motor6D") then d.Enabled = true end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local animator = hum:FindFirstChild("Animator")
        if animator then
            for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                local n = track.Animation and track.Animation.Name:lower() or ""
                if n:find("rag") or n:find("fall") or n:find("hurt") or n:find("down") then
                    track:Stop(0)
                end
            end
        end
    end
    task.defer(function()
        pcall(function()
            local pm = LocalPlayer:FindFirstChild("PlayerScripts")
            if pm then pm = pm:FindFirstChild("PlayerModule") end
            if pm then require(pm):GetControls():Enable() end
        end)
    end)
end
function cleanRagdollV2Debounced(char)
    if cleanRagdollV2Scheduled then return end
    cleanRagdollV2Scheduled = true
    task.defer(function()
        cleanRagdollV2Scheduled = false
        if char and char.Parent then cleanRagdollV2(char) end
    end)
end
function isRagdollRelatedDescendant(obj)
    if obj:IsA("BallSocketConstraint") or obj:IsA("NoCollisionConstraint") or obj:IsA("HingeConstraint") then return true end
    if obj:IsA("Attachment") and (obj.Name == "A" or obj.Name == "B") then return true end
    if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then return true end
    return false
end

function hookAntiRagV2(char)
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns

    local hum = char:WaitForChild("Humanoid", 10)
    local hrp = char:WaitForChild("HumanoidRootPart", 10)
    if not hum or not hrp then return end

    local lastVel = Vector3.new(0, 0, 0)

    local c1 = hum.StateChanged:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            local carpetActive = false
            pcall(function()
                local toolName = Config.TpSettings.Tool or "Flying Carpet"
                local tool = char:FindFirstChild(toolName)
                if tool and hrp then
                    for _, obj in ipairs(hrp:GetChildren()) do
                        if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                            carpetActive = true
                        end
                    end
                end
            end)
            if not carpetActive then
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
            cleanRagdollV2(char)
            pcall(function() Workspace.CurrentCamera.CameraSubject = hum end)
            pcall(function()
                local pm = LocalPlayer:FindFirstChild("PlayerScripts")
                if pm then pm = pm:FindFirstChild("PlayerModule") end
                if pm then require(pm):GetControls():Enable() end
            end)
        end
    end)
    table.insert(antiRagdollConns, c1)

    local c2 = char.DescendantAdded:Connect(function(desc)
        if isRagdollRelatedDescendant(desc) then
            cleanRagdollV2Debounced(char)
        end
    end)
    table.insert(antiRagdollConns, c2)

    pcall(function()
        local pkg = ReplicatedStorage:FindFirstChild("Packages")
        if pkg then
            local net = pkg:FindFirstChild("Net")
            if net then
                local applyImp = net:FindFirstChild("RE/CombatService/ApplyImpulse")
                if applyImp and applyImp:IsA("RemoteEvent") then
                    local c3 = applyImp.OnClientEvent:Connect(function()
                        local st = hum:GetState()
                        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
                            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
                            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
                        end
                    end)
                    table.insert(antiRagdollConns, c3)
                end
            end
        end
    end)

    local c4 = RunService.Heartbeat:Connect(function()
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll
            or st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.GettingUp then
            cleanRagdollV2(char)
            local vel = hrp.AssemblyLinearVelocity
            if (vel - lastVel).Magnitude > 40 and vel.Magnitude > 25 then
                hrp.AssemblyLinearVelocity = vel.Unit * math.min(vel.Magnitude, 15)
            end
        end
        lastVel = hrp.AssemblyLinearVelocity
    end)
    table.insert(antiRagdollConns, c4)

    cleanRagdollV2(char)
end

function stopAntiRagdollV2()
    cleanRagdollV2Scheduled = false
    for _, c in ipairs(antiRagdollConns) do pcall(function() c:Disconnect() end) end
    AntiRagdollV2Data.antiRagdollConns = {}
    antiRagdollConns = AntiRagdollV2Data.antiRagdollConns
end

function startAntiRagdollV2(enabled)
    stopAntiRagdoll()
    stopAntiRagdollV2()
    if not enabled then
        return
    end

    local char = LocalPlayer.Character
    if char then task.spawn(function() hookAntiRagV2(char) end) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.spawn(function() hookAntiRagV2(c) end)
    end)
end

if antiRagdollMode > 0 then startAntiRagdoll(antiRagdollMode) end
if Config.AntiRagdollV2 then startAntiRagdollV2(true) end

do
    local plotBeam = nil
    local plotBeamAttachment0 = nil
    local plotBeamAttachment1 = nil

    local function findMyPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            if sign then
                local surfaceGui = sign:FindFirstChildWhichIsA("SurfaceGui", true)
                if surfaceGui then
                    local label = surfaceGui:FindFirstChildWhichIsA("TextLabel", true)
                    if label then
                        local text = label.Text:lower()
                        if text:find(LocalPlayer.DisplayName:lower(), 1, true) or text:find(LocalPlayer.Name:lower(), 1, true) then
                            return plot
                        end
                    end
                end
            end
        end
        return nil
    end

    local function createPlotBeam()
        if not Config.LineToBase then return end
        
        local myPlot = findMyPlot()
        if not myPlot or not myPlot.Parent then return end
        local character = LocalPlayer.Character
        if not character or not character.Parent then return end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp.Parent then return end
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        if plotBeamAttachment1 then pcall(function() plotBeamAttachment1:Destroy() end) end
        plotBeamAttachment0 = hrp:FindFirstChild("PlotBeamAttach_Player") or Instance.new("Attachment")
        plotBeamAttachment0.Name = "PlotBeamAttach_Player"
        plotBeamAttachment0.Position = Vector3.new(0, 0, 0)
        plotBeamAttachment0.Parent = hrp
        local plotPart = myPlot:FindFirstChild("MainRootPart") or myPlot:FindFirstChildWhichIsA("BasePart")
        if not plotPart or not plotPart.Parent then return end
        plotBeamAttachment1 = plotPart:FindFirstChild("PlotBeamAttach_Plot") or Instance.new("Attachment")
        plotBeamAttachment1.Name = "PlotBeamAttach_Plot"
        plotBeamAttachment1.Position = Vector3.new(0, 5, 0)
        plotBeamAttachment1.Parent = plotPart
        plotBeam = hrp:FindFirstChild("PlotBeam") or Instance.new("Beam")
        plotBeam.Name = "PlotBeam"
        plotBeam.Attachment0 = plotBeamAttachment0
        plotBeam.Attachment1 = plotBeamAttachment1
        plotBeam.FaceCamera = true
        plotBeam.LightEmission = 1
        plotBeam.Color = ColorSequence.new(Color3.fromRGB(180, 180, 210))
        plotBeam.Transparency = NumberSequence.new(0)
        plotBeam.Width0 = 0.6
        plotBeam.Width1 = 0.6
        plotBeam.TextureMode = Enum.TextureMode.Wrap
        plotBeam.TextureSpeed = 0
        plotBeam.Parent = hrp
    end

    local function resetPlotBeam()
        if plotBeam then pcall(function() plotBeam:Destroy() end) end
        if plotBeamAttachment0 then pcall(function() plotBeamAttachment0:Destroy() end) end
        if plotBeamAttachment1 then pcall(function() plotBeamAttachment1:Destroy() end) end
        plotBeam = nil
        plotBeamAttachment0 = nil
        plotBeamAttachment1 = nil
    end

    task.spawn(function()
        local checkCounter = 0
        RunService.Heartbeat:Connect(function()
            if not Config.LineToBase then 
                if plotBeam then resetPlotBeam() end
                return 
            end
            checkCounter = checkCounter + 1
            if checkCounter >= 30 then
                checkCounter = 0
                if not plotBeam or not plotBeam.Parent or not plotBeamAttachment0 or not plotBeamAttachment0.Parent then
                    pcall(createPlotBeam)
                end
            end
        end)
    end)

    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if Config.LineToBase and character then
            pcall(createPlotBeam)
        else
            resetPlotBeam()
        end
    end)

    if LocalPlayer.Character then
        task.spawn(function()
            task.wait(0.2)
            if Config.LineToBase then 
                createPlotBeam() 
            end
        end)
    end

    _G.createPlotBeam = createPlotBeam
    _G.resetPlotBeam = resetPlotBeam
end

task.spawn(function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local AnimalsModule = require(ReplicatedStorage.Datas.Animals)
    local TraitsModule = require(ReplicatedStorage.Datas.Traits)
    local MutationsModule = require(ReplicatedStorage.Datas.Mutations)


    local autoBuyEnabled = false
    local bestCarpet = nil
    local carpetEquipped = false
    local hasTeleported = false

    local renderedMovingAnimals = Workspace:FindFirstChild("RenderedMovingAnimals")

    local function getTraitMultiplier(model)
        local traitJson = model:GetAttribute("Traits")
        if not traitJson or traitJson == "" then return 0 end
        local traitTable
        local ok, dec = pcall(function() return HttpService:JSONDecode(traitJson) end)
        if ok and typeof(dec) == "table" then
            traitTable = dec
        else
            traitTable = {}
            for t in string.gmatch(traitJson, "[^,]+") do 
                table.insert(traitTable, t) 
            end
        end
        local mult = 0
        for _, entry in pairs(traitTable) do
            local name = typeof(entry) == "table" and entry.Name or tostring(entry)
            name = name:gsub("^_Trait%.", "")
            local t = TraitsModule[name]
            if t then 
                mult = mult + (tonumber(t.MultiplierModifier) or 0) 
            end
        end
        return mult
    end

    local function getFinalGeneration(model)
        if not model or not model.Name then return 0 end
        local data = AnimalsModule[model.Name]
        if not data then return 0 end
        local baseGen = tonumber(data.Generation) or (tonumber(data.Price or 0) * 1)
        local traitMult = getTraitMultiplier(model)
        local mutMult = 0
        local mutName = model:GetAttribute("Mutation")
        if mutName and MutationsModule[mutName] then
            mutMult = tonumber(MutationsModule[mutName].Modifier or 0)
        end
        return math.max(1, math.round(baseGen * (1 + traitMult + mutMult)))
    end

    local function formatValue(v)
        if v >= 1e12 then return string.format("%.1fT/s", v/1e12)
        elseif v >= 1e9 then return string.format("%.1fB/s", v/1e9)
        elseif v >= 1e6 then return string.format("%.1fM/s", v/1e6)
        elseif v >= 1e3 then return string.format("%.1fK/s", v/1e3)
        else return math.floor(v) .. "/s" end
    end

    local function scanBestCarpet()
        if not renderedMovingAnimals then return end
        local best = nil
        local bestValue = 0
        for _, animal in ipairs(renderedMovingAnimals:GetChildren()) do
            if animal:IsA("Model") then
                local value = getFinalGeneration(animal)
                if value > bestValue then
                    bestValue = value
                    best = {
                        name = animal.Name,
                        value = value,
                        valueText = "$" .. formatValue(value) .. "/s",
                        animal = animal,
                        position = animal:GetPivot().Position
                    }
                end
            end
        end
        bestCarpet = best
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoBuyUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    local PANEL_W = 260
    local PANEL_H = 200
    local mobileScale = IS_MOBILE and 0.6 or 1

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, PANEL_W * mobileScale, 0, PANEL_H * mobileScale)
    frame.Position = UDim2.new(Config.Positions.AutoBuy and Config.Positions.AutoBuy.X or 0.02, 0, Config.Positions.AutoBuy and Config.Positions.AutoBuy.Y or 0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    ApplyViewportUIScale(frame, PANEL_W, PANEL_H, 0.45, 0.8)
    AddMobileMinimize(frame, "AUTO BUY")

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 0.75
    UIScale.Parent = frame

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local outerStroke = Instance.new("UIStroke", frame)
    outerStroke.Color = Color3.fromRGB(55, 55, 70)
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.3

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    header.BackgroundTransparency = 0.2
    header.BorderSizePixel = 0

    local headerGrad = Instance.new("UIGradient", header)
    headerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26))
    })
    headerGrad.Rotation = 90

    local headerSep = Instance.new("Frame", frame)
    headerSep.Size = UDim2.new(1, 0, 0, 1)
    headerSep.Position = UDim2.new(0, 0, 0, 44)
    headerSep.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    headerSep.BackgroundTransparency = 0.3
    headerSep.BorderSizePixel = 0

    MakeDraggable(header, frame, "AutoBuy")

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -40, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Auto Buy Carpet"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    do
        local _rh = Instance.new("TextButton", header)
        _rh.Size = UDim2.new(0, 20, 0, 20)
        _rh.Position = UDim2.new(1, -24, 0.5, -10)
        _rh.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        _rh.Text = "+"
        _rh.Font = Enum.Font.GothamMedium
        _rh.TextSize = 10
        _rh.TextColor3 = Color3.fromRGB(180, 180, 200)
        _rh.ZIndex = 10
        Instance.new("UICorner", _rh).CornerRadius = UDim.new(1, 0)
        MakeResizable(_rh, frame)
    end

    local contentFrame = Instance.new("Frame", frame)
    contentFrame.Size = UDim2.new(1, -16, 1, -60)
    contentFrame.Position = UDim2.new(0, 8, 0, 52)
    contentFrame.BackgroundTransparency = 1

    local carpetPanel = Instance.new("Frame", contentFrame)
    carpetPanel.Size = UDim2.new(1, 0, 0, 80)
    carpetPanel.Position = UDim2.new(0, 0, 0, 0)
    carpetPanel.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    carpetPanel.BackgroundTransparency = 0.3
    carpetPanel.BorderSizePixel = 0
    Instance.new("UICorner", carpetPanel).CornerRadius = UDim.new(0, 10)
    local carpetPanelStroke = Instance.new("UIStroke", carpetPanel)
    carpetPanelStroke.Color = Color3.fromRGB(50, 50, 65)
    carpetPanelStroke.Thickness = 1
    carpetPanelStroke.Transparency = 0.4

    local carpetTitle = Instance.new("TextLabel", carpetPanel)
    carpetTitle.Size = UDim2.new(1, -20, 0, 18)
    carpetTitle.Position = UDim2.new(0, 10, 0, 8)
    carpetTitle.BackgroundTransparency = 1
    carpetTitle.Text = "BEST CARPET"
    carpetTitle.Font = Enum.Font.GothamMedium
    carpetTitle.TextSize = 9
    carpetTitle.TextColor3 = Color3.fromRGB(140, 140, 160)
    carpetTitle.TextXAlignment = Enum.TextXAlignment.Left

    local carpetName = Instance.new("TextLabel", carpetPanel)
    carpetName.Size = UDim2.new(1, -20, 0, 28)
    carpetName.Position = UDim2.new(0, 10, 0, 28)
    carpetName.BackgroundTransparency = 1
    carpetName.Font = Enum.Font.GothamBold
    carpetName.TextSize = 16
    carpetName.TextColor3 = Color3.fromRGB(220, 180, 80)
    carpetName.TextXAlignment = Enum.TextXAlignment.Left
    carpetName.TextTruncate = Enum.TextTruncate.AtEnd
    carpetName.Text = "None"

    local carpetValue = Instance.new("TextLabel", carpetPanel)
    carpetValue.Size = UDim2.new(1, -20, 0, 18)
    carpetValue.Position = UDim2.new(0, 10, 0, 58)
    carpetValue.BackgroundTransparency = 1
    carpetValue.Font = Enum.Font.GothamMedium
    carpetValue.TextSize = 11
    carpetValue.TextColor3 = Color3.fromRGB(160, 160, 180)
    carpetValue.TextXAlignment = Enum.TextXAlignment.Left
    carpetValue.Text = ""

    local buyBtn = Instance.new("TextButton", contentFrame)
    buyBtn.Size = UDim2.new(1, 0, 0, 44)
    buyBtn.Position = UDim2.new(0, 0, 1, -50)
    buyBtn.BackgroundColor3 = Color3.fromRGB(55, 200, 110)
    buyBtn.BackgroundTransparency = 0.1
    buyBtn.BorderSizePixel = 0
    buyBtn.Text = "AUTO BUY: OFF"
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

    local function updateUI()
        if bestCarpet then
            carpetName.Text = bestCarpet.name
            carpetValue.Text = bestCarpet.valueText
        else
            carpetName.Text = "No carpets"
            carpetValue.Text = ""
        end
        buyBtn.Text = autoBuyEnabled and "AUTO BUY: ON" or "AUTO BUY: OFF"
        buyBtn.BackgroundColor3 = autoBuyEnabled and Color3.fromRGB(55, 200, 110) or Color3.fromRGB(30, 30, 42)
        buyBtn.TextColor3 = autoBuyEnabled and Color3.fromRGB(10, 10, 15) or Color3.fromRGB(140, 140, 160)
    end

    buyBtn.MouseButton1Click:Connect(function()
        autoBuyEnabled = not autoBuyEnabled
        updateUI()
        if not autoBuyEnabled then
            carpetEquipped = false
        end
    end)

    local function equipCarpet()
        local toolName = "Flying Carpet"
        local char = LocalPlayer.Character
        if not char then return false end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return false end
        
        if char:FindFirstChild(toolName) then
            carpetEquipped = true
            return true
        end
        
        local tool = LocalPlayer.Backpack:FindFirstChild(toolName)
        if tool then
            hum:EquipTool(tool)
            carpetEquipped = true
            return true
        end
        return false
    end

    local locked = false
    local lockConnection = nil
    local currentTarget = nil

    local function lockToCarpet(hrp, targetPos)
        if lockConnection then return end
        locked = true
        lockConnection = RunService.Heartbeat:Connect(function()
            if locked and hrp and hrp.Parent and currentTarget then
                pcall(function()
                    local targetPos = currentTarget:GetPivot().Position
                    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
        end)
    end

    local function unlockPosition()
        locked = false
        if lockConnection then
            lockConnection:Disconnect()
            lockConnection = nil
        end
        currentTarget = nil
    end

    RunService.Heartbeat:Connect(function()
        if not autoBuyEnabled or not bestCarpet or not bestCarpet.animal then 
            unlockPosition()
            return 
        end
        
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        equipCarpet()
        currentTarget = bestCarpet.animal
        
        if not hasTeleported then
            local targetPos = currentTarget:GetPivot().Position
            hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
            hasTeleported = true
            task.wait(0.2)
        end
        
        lockToCarpet(hrp)
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText == "Purchase" then
                fireproximityprompt(obj)
            end
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function()
        carpetEquipped = false
        hasTeleported = false
        if autoBuyEnabled and bestCarpet then
            equipCarpet()
        end
    end)

    if renderedMovingAnimals then
        renderedMovingAnimals.ChildAdded:Connect(function()
            task.wait(0.1)
            scanBestCarpet()
            updateUI()
        end)
        renderedMovingAnimals.ChildRemoved:Connect(function()
            scanBestCarpet()
            updateUI()
        end)
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            scanBestCarpet()
            updateUI()
        end
    end)

    scanBestCarpet()
    updateUI()

    local function savePosition()
        if Config.Positions then
            Config.Positions.AutoBuy = {
                X = frame.Position.X.Scale,
                Y = frame.Position.Y.Scale
            }
            SaveConfig()
        end
    end

    header:GetPropertyChangedSignal("Position"):Connect(savePosition)
end)

task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))

    local autoStealEnabled = true

    if Config.DefaultToPriority and Config.DefaultToHighest then Config.DefaultToHighest = false end
    if Config.DefaultToPriority and Config.DefaultToNearest then Config.DefaultToNearest = false end
    if Config.DefaultToHighest and Config.DefaultToNearest then Config.DefaultToNearest = false end
    if not Config.DefaultToPriority and not Config.DefaultToHighest and not Config.DefaultToNearest then
        Config.DefaultToHighest = true
    end

    local stealNearestEnabled = false
    local stealHighestEnabled = false
    local stealPriorityEnabled = false

    if Config.DefaultToNearest then
        stealNearestEnabled = true
        Config.StealNearest = true; Config.StealHighest = false; Config.StealPriority = false
        Config.AutoTPPriority = true
    elseif Config.DefaultToHighest then
        stealHighestEnabled = true
        Config.StealHighest = true; Config.StealNearest = false; Config.StealPriority = false
        Config.AutoTPPriority = false
    elseif Config.DefaultToPriority then
        stealPriorityEnabled = true
        Config.StealPriority = true; Config.StealNearest = false; Config.StealHighest = false
        Config.AutoTPPriority = true
    else
        stealNearestEnabled = Config.StealNearest
        stealHighestEnabled = Config.StealHighest
        stealPriorityEnabled = Config.StealPriority
        if Config.StealPriority then Config.AutoTPPriority = true
        elseif Config.StealNearest then Config.AutoTPPriority = true
        elseif Config.StealHighest then Config.AutoTPPriority = false end
    end

    local selectedTargetIndex = 1
    local selectedTargetUID = nil
    local allAnimalsCache = {}
    local PromptCache = {}
    local StealTimes = {}
    local STEAL_CD = 0
    local petButtons = {}

    local AnimalModels = ReplicatedStorage:WaitForChild("Models"):WaitForChild("Animals")
    local AnimalAnimations = ReplicatedStorage:WaitForChild("Animations"):WaitForChild("Animals")

    local function getMinGenValue()
        if not Config.AutoStealMinGen or Config.AutoStealMinGen == "" then return 0 end
        local str = Config.AutoStealMinGen:upper():gsub("%s+", "")
        local num = tonumber(str:match("%d+%.?%d*"))
        if not num then return 0 end
        if str:find("M") then return num * 1000000
        elseif str:find("K") then return num * 1000
        elseif str:find("B") then return num * 1000000000
        else return num end
    end

    local function isMyBaseAnimal(animalData)
        if not animalData or not animalData.plot then return false end
        local plots = Workspace:FindFirstChild("Plots"); if not plots then return false end
        local plot = plots:FindFirstChild(animalData.plot); if not plot then return false end
        local channel = Synchronizer:Get(plot.Name)
        if channel then
            local owner = channel:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "table" and owner.UserId then return owner.UserId == LocalPlayer.UserId
                elseif typeof(owner) == "Instance" then return owner == LocalPlayer end
            end
        end
        return false
    end

    local function formatMutationText(mutationName)
        if not mutationName or mutationName == "None" then return "" end
        local f = ""
        if mutationName == "Cursed" then
            f = "<font color='rgb(200,0,0)'>Cur</font><font color='rgb(0,0,0)'>sed</font>"
        elseif mutationName == "Gold" then
            f = "<font color='rgb(255,215,0)'>Gold</font>"
        elseif mutationName == "Diamond" then
            f = "<font color='rgb(0,255,255)'>Diamond</font>"
        elseif mutationName == "YinYang" then
            f = "<font color='rgb(255,255,255)'>Yin</font><font color='rgb(0,0,0)'>Yang</font>"
        elseif mutationName == "Candy" then
            f = "<font color='rgb(255,105,180)'>Candy</font>"
        elseif mutationName == "Divine" then
            f = "<font color='rgb(255,255,200)'>Divine</font>"
        elseif mutationName == "Rainbow" then
            local cols = {"rgb(255,0,0)","rgb(255,127,0)","rgb(255,255,0)","rgb(0,255,0)","rgb(0,0,255)","rgb(75,0,130)","rgb(148,0,211)"}
            for i = 1, #mutationName do
                f = f.."<font color='"..cols[(i-1)%#cols+1].."'>"..mutationName:sub(i,i).."</font>"
            end
        elseif mutationName == "Bloodrot" then
            f = "<font color='rgb(139,0,0)'>Bloodrot</font>"
        elseif mutationName == "Lava" then
            f = "<font color='rgb(255,100,20)'>Lava</font>"
        elseif mutationName == "Radioactive" then
            f = "<font color='rgb(0,255,0)'>Radioactive</font>"
        else
            f = mutationName
        end
        return "<font weight='800'>"..f.." </font>"
    end

    function buildViewport(vpContainer, animalName)
        if not AnimalModels then return end
        local tmpl = AnimalModels:FindFirstChild(animalName)
        if not tmpl then return end
        local vp = Instance.new("ViewportFrame")
        vp.Size = UDim2.new(1, 0, 1, 0)
        vp.Position = UDim2.new(0, 0, 0, 0)
        vp.BackgroundTransparency = 1
        vp.BorderSizePixel = 0
        vp.LightColor = Color3.fromRGB(220, 220, 220)
        vp.LightDirection = Vector3.new(-1, -2, -1)
        vp.Ambient = Color3.fromRGB(100, 100, 100)
        vp.Parent = vpContainer
        local clone = tmpl:Clone()
        local wm = Instance.new("WorldModel"); wm.Parent = vp
        clone.Parent = wm
        if clone.PrimaryPart then clone.PrimaryPart.Anchored = true end
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored = true; d.CanCollide = false
                d.CastShadow = false; d.Massless = true
                d.Material = Enum.Material.SmoothPlastic
            end
        end
        local ok, bbCF, bbSize = pcall(function() return clone:GetBoundingBox() end)
        if not ok then bbCF = clone:GetPivot(); bbSize = Vector3.new(4, 4, 4) end
        local sz = math.max(bbSize.X, bbSize.Y, bbSize.Z)
        local fov = 50
        local dist = (sz * 0.5) / math.tan(math.rad(fov * 0.5)) * 0.85
        local modelCF = (clone.PrimaryPart and clone.PrimaryPart.CFrame) or clone:GetPivot()
        local offset = (modelCF.LookVector + Vector3.new(0, 0.25, 0)).Unit
        local cam = Instance.new("Camera")
        cam.FieldOfView = fov
        cam.CFrame = CFrame.new(bbCF.Position + offset * (dist + sz * 0.5), bbCF.Position)
        cam.Parent = vp; vp.CurrentCamera = cam
        if not AnimalAnimations then return end
        local animFolder = AnimalAnimations:FindFirstChild(animalName)
        local idleAnim = animFolder and (
            animFolder:FindFirstChild("Idle") or
            animFolder:FindFirstChild("idle") or
            (animFolder:GetChildren()[1])
        )
        if not idleAnim then return end
        local animCtrl = clone:FindFirstChildWhichIsA("AnimationController", true)
        if not animCtrl then
            animCtrl = Instance.new("AnimationController"); animCtrl.Parent = clone
        end
        local animator = animCtrl:FindFirstChildOfClass("Animator")
        if not animator then
            animator = Instance.new("Animator"); animator.Parent = animCtrl
        end
        local track = animator:LoadAnimation(idleAnim)
        track.Looped = true; track:Play(0)
        if track.Length > 0 then track.TimePosition = os.clock() % track.Length end
        task.spawn(function()
            while vp.Parent do
                task.wait(1)
                pcall(function()
                    if track.Length > 0 then
                        local t = os.clock() % track.Length
                        if math.abs(t - track.TimePosition) > 0.05 then track.TimePosition = t end
                    end
                end)
            end
        end)
    end

    local function get_all_pets()
        local out = {}
        local minGen = getMinGenValue()
        for _, a in ipairs(allAnimalsCache) do
            if a.genValue >= 1 and not isMyBaseAnimal(a) then
                if minGen == 0 or a.genValue >= minGen then
                    table.insert(out, {petName=a.name, mpsText=a.genText, mpsValue=a.genValue,
                        owner=a.owner, plot=a.plot, slot=a.slot, uid=a.uid, mutation=a.mutation, animalData=a})
                end
            end
        end
        return out
    end

    local function preparePrompt(prompt)
        pcall(function()
            prompt.HoldDuration = -9e9
            prompt.MaxActivationDistance = 9e9
            prompt.RequiresLineOfSight = false
            prompt.Enabled = false
        end)
    end

    local function instantSteal(prompt)
        if not prompt then return end
        if fireproximityprompt then
            pcall(fireproximityprompt, prompt)
            return
        end
        pcall(function()
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end)
    end

    local function executeSteal(prompt)
        local now = os.clock()
        if StealTimes[prompt] and (now - StealTimes[prompt]) < STEAL_CD then return end
        StealTimes[prompt] = now
        instantSteal(prompt)
    end

    local function findPromptForAnimal(animalData)
        if not animalData then return nil end
        local cached = PromptCache[animalData.uid]
        if cached and cached.Parent then return cached end
        local plots = Workspace:FindFirstChild("Plots"); if not plots then return nil end
        local plot = plots:FindFirstChild(animalData.plot); if not plot then return nil end
        local podiums = plot:FindFirstChild("AnimalPodiums"); if not podiums then return nil end
        local ch = Synchronizer:Get(plot.Name)
        if not ch then
            local podium = podiums:FindFirstChild(animalData.slot)
            if podium then
                local base = podium:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local attach = spawn:FindFirstChild("PromptAttachment")
                    if attach then
                        for _, p in ipairs(attach:GetChildren()) do
                            if p:IsA("ProximityPrompt") then
                                PromptCache[animalData.uid] = p
                                preparePrompt(p)
                                return p
                            end
                        end
                    end
                end
            end
            return nil
        end
        local al = ch:Get("AnimalList"); if not al then return nil end
        local brainrotName = animalData.name and animalData.name:lower() or ""
        local foundPodium = nil
        for slot, ad in pairs(al) do
            if type(ad) == "table" and tostring(slot) == animalData.slot then
                local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                if aInfo and (aInfo.DisplayName or aName):lower() == brainrotName then
                    foundPodium = podiums:FindFirstChild(tostring(slot)); break
                end
            end
        end
        if not foundPodium then foundPodium = podiums:FindFirstChild(animalData.slot) end
        if foundPodium then
            local base = foundPodium:FindFirstChild("Base")
            local spawn = base and base:FindFirstChild("Spawn")
            if spawn then
                local attach = spawn:FindFirstChild("PromptAttachment")
                if attach then
                    for _, p in ipairs(attach:GetChildren()) do
                        if p:IsA("ProximityPrompt") then
                            PromptCache[animalData.uid] = p
                            preparePrompt(p)
                            return p
                        end
                    end
                end
                local startPos = spawn.Position
                local slotX, slotZ = startPos.X, startPos.Z
                local nearestPrompt, minDist = nil, math.huge
                for _, desc in pairs(plot:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.ActionText == "Steal" then
                        local part = desc.Parent
                        local promptPos = nil
                        if part and part:IsA("BasePart") then promptPos = part.Position
                        elseif part and part:IsA("Attachment") and part.Parent and part.Parent:IsA("BasePart") then promptPos = part.Parent.Position end
                        if promptPos then
                            local checkStartY = startPos.Y
                            if brainrotName:find("la secret combinasion") then checkStartY = startPos.Y - 5 end
                            local horizontalDist = math.sqrt((promptPos.X - slotX)^2 + (promptPos.Z - slotZ)^2)
                            if horizontalDist < 5 and promptPos.Y > checkStartY then
                                local yDist = promptPos.Y - checkStartY
                                if yDist < minDist then minDist = yDist; nearestPrompt = desc end
                            end
                        end
                    end
                end
                if nearestPrompt then
                    PromptCache[animalData.uid] = nearestPrompt
                    preparePrompt(nearestPrompt)
                    return nearestPrompt
                end
            end
        end
        return nil
    end

    task.spawn(function()
        while task.wait(1) do
            for uid, p in pairs(PromptCache) do
                if p and p.Parent then preparePrompt(p)
                else PromptCache[uid] = nil end
            end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoStealUI"; screenGui.ResetOnSpawn = false; screenGui.Parent = PlayerGui

    local PANEL_W = 260
    local PANEL_H = 480
    local mobileScale = IS_MOBILE and 0.6 or 1

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, PANEL_W * mobileScale, 0, PANEL_H * mobileScale)
    frame.Position = UDim2.new(Config.Positions.AutoSteal.X, 0, Config.Positions.AutoSteal.Y, 0)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = screenGui

    local blur = Instance.new("BlurEffect", game.Lighting)
    blur.Size = 0
    local function applyBlur()
        if not frame.Visible then return end
        blur.Size = 12
        task.delay(0.1, function() blur.Size = 0 end)
    end
    frame:GetPropertyChangedSignal("Visible"):Connect(applyBlur)
    applyBlur()

    ApplyViewportUIScale(frame, PANEL_W, PANEL_H, 0.45, 0.8)
    AddMobileMinimize(frame, "AUTO STEAL")

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local outerStroke = Instance.new("UIStroke", frame)
    outerStroke.Color = Color3.fromRGB(55, 55, 70)
    outerStroke.Thickness = 1
    outerStroke.Transparency = 0.3

    local _ab = Instance.new("Frame", screenGui)
    _ab.BackgroundTransparency = 1; _ab.BorderSizePixel = 0; _ab.ZIndex = 100
    Instance.new("UICorner", _ab).CornerRadius = UDim.new(0, 10)
    local mainStroke = Instance.new("UIStroke", _ab)
    mainStroke.Color = Color3.fromRGB(70, 70, 80); mainStroke.Thickness = 1; mainStroke.Transparency = 0.5
    local function _absync() _ab.Size = frame.Size; _ab.Position = frame.Position; _ab.Visible = frame.Visible end
    _absync()
    frame:GetPropertyChangedSignal("Size"):Connect(_absync)
    frame:GetPropertyChangedSignal("Position"):Connect(_absync)
    frame:GetPropertyChangedSignal("Visible"):Connect(_absync)

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    header.BackgroundTransparency = 0.2
    header.BorderSizePixel = 0

    local headerGrad = Instance.new("UIGradient", header)
    headerGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 26))
    })
    headerGrad.Rotation = 90

    local headerSep = Instance.new("Frame", frame)
    headerSep.Size = UDim2.new(1, 0, 0, 1)
    headerSep.Position = UDim2.new(0, 0, 0, 44)
    headerSep.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    headerSep.BackgroundTransparency = 0.3
    headerSep.BorderSizePixel = 0

    MakeDraggable(header, frame, "AutoSteal")

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 14, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Auto-Steal Targets"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local distanceBadge = Instance.new("Frame", header)
    distanceBadge.Size = UDim2.new(0, 80, 0, 24)
    distanceBadge.Position = UDim2.new(1, -116, 0.5, -12)
    distanceBadge.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    distanceBadge.BackgroundTransparency = 0.3
    distanceBadge.BorderSizePixel = 0
    Instance.new("UICorner", distanceBadge).CornerRadius = UDim.new(1, 0)
    local distStroke = Instance.new("UIStroke", distanceBadge)
    distStroke.Color = Color3.fromRGB(70, 70, 90); distStroke.Thickness = 1; distStroke.Transparency = 0.4

    local distLabel = Instance.new("TextLabel", distanceBadge)
    distLabel.Size = UDim2.new(1, -6, 1, 0)
    distLabel.Position = UDim2.new(0, 3, 0, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.GothamMedium
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.fromRGB(190, 190, 210)
    distLabel.Text = "-- studs"

    RunService.RenderStepped:Connect(function()
       if not frame.Parent then
            connection:Disconnect()
            return
        end

        local pets = get_all_pets()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hrp and pets and pets[selectedTargetIndex] then
            local tp = pets[selectedTargetIndex]
            local targetPart = tp.animalData and findAdorneeGlobal(tp.animalData)

            if targetPart and targetPart:IsA("BasePart") then
                local d = (hrp.Position - targetPart.Position).Magnitude
                distLabel.Text = string.format("%.1f studs", d)
            else
                distLabel.Text = "-- studs"
            end
        else
            distLabel.Text = "-- studs"
        end
    end)

    do
        local _rh = Instance.new("TextButton", header)
        _rh.Size = UDim2.new(0, 20, 0, 20)
        _rh.Position = UDim2.new(1, -24, 0.5, -10)
        _rh.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        _rh.Text = "+"
        _rh.Font = Enum.Font.GothamMedium; _rh.TextSize = 10
        _rh.TextColor3 = Color3.fromRGB(180, 180, 200); _rh.ZIndex = 10
        Instance.new("UICorner", _rh).CornerRadius = UDim.new(1, 0)
        MakeResizable(_rh, frame)
    end

    if IS_MOBILE then
        local menuToggleBtn = Instance.new("TextButton", header)
        menuToggleBtn.Size = UDim2.new(0, 60, 0, 24)
        menuToggleBtn.Position = UDim2.new(0, -68, 0.5, -12)
        menuToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        menuToggleBtn.Text = "MENU"; menuToggleBtn.Font = Enum.Font.GothamMedium
        menuToggleBtn.TextSize = 10; menuToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", menuToggleBtn).CornerRadius = UDim.new(1, 0)
        menuToggleBtn.MouseButton1Click:Connect(function()
            if settingsGui then settingsGui.Enabled = not settingsGui.Enabled end
        end)
    end

    local modeBar = Instance.new("Frame", frame)
    modeBar.Size = UDim2.new(1, -16, 0, 30)
    modeBar.Position = UDim2.new(0, 8, 0, 52)
    modeBar.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
    modeBar.BackgroundTransparency = 0.3
    modeBar.BorderSizePixel = 0
    Instance.new("UICorner", modeBar).CornerRadius = UDim.new(0, 7)
    local modeBarStroke = Instance.new("UIStroke", modeBar)
    modeBarStroke.Color = Color3.fromRGB(50, 50, 65); modeBarStroke.Thickness = 1; modeBarStroke.Transparency = 0.4

    local modeLayout = Instance.new("UIListLayout", modeBar)
    modeLayout.FillDirection = Enum.FillDirection.Horizontal
    modeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    modeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    modeLayout.Padding = UDim.new(0, 4)

    local function makeModeBtn(text)
        local btn = Instance.new("TextButton", modeBar)
        btn.Size = UDim2.new(0, 68, 0, 22)
        btn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
        btn.BackgroundTransparency = 0.5
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 10
        btn.TextColor3 = Color3.fromRGB(160, 160, 185)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
        local s = Instance.new("UIStroke", btn)
        s.Color = Color3.fromRGB(70, 70, 90); s.Thickness = 1; s.Transparency = 0.6
        return btn, s
    end

    local nearestBtn, _nStroke = makeModeBtn("NEAREST")
    local highestBtn, _hStroke = makeModeBtn("HIGHEST")
    local priorityBtn, _pStroke = makeModeBtn("PRIORITY")

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1, -16, 1, -208)
    listFrame.Position = UDim2.new(0, 8, 0, 90)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    listFrame.ScrollBarImageTransparency = 0.8
    listFrame.ScrollBarThickness = 3
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)

    local uiListLayout = Instance.new("UIListLayout", listFrame)
    uiListLayout.Padding = UDim.new(0, 2)
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local bottomSep = Instance.new("Frame", frame)
    bottomSep.Size = UDim2.new(1, 0, 0, 1)
    bottomSep.Position = UDim2.new(0, 0, 1, -90)
    bottomSep.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    bottomSep.BackgroundTransparency = 0.4
    bottomSep.BorderSizePixel = 0

    local bottomBar = Instance.new("Frame", frame)
    bottomBar.Size = UDim2.new(1, -16, 0, 84)
    bottomBar.Position = UDim2.new(0, 8, 1, -88)
    bottomBar.BackgroundTransparency = 1

    local customizePriorityBtn = Instance.new("TextButton", bottomBar)
    customizePriorityBtn.Size = UDim2.new(1, 0, 0, 30)
    customizePriorityBtn.Position = UDim2.new(0, 0, 0, 0)
    customizePriorityBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    customizePriorityBtn.BackgroundTransparency = 0.3
    customizePriorityBtn.BorderSizePixel = 0
    customizePriorityBtn.Text = "CUSTOMIZE PRIORITY"
    customizePriorityBtn.Font = Enum.Font.GothamMedium
    customizePriorityBtn.TextSize = 11
    customizePriorityBtn.TextColor3 = Color3.fromRGB(160, 160, 190)
    Instance.new("UICorner", customizePriorityBtn).CornerRadius = UDim.new(0, 7)
    local _cpStroke = Instance.new("UIStroke", customizePriorityBtn)
    _cpStroke.Color = Color3.fromRGB(65, 65, 85); _cpStroke.Transparency = 0.4; _cpStroke.Thickness = 1
    customizePriorityBtn.Visible = not IS_MOBILE
    customizePriorityBtn.MouseButton1Click:Connect(function()
        local priorityGui = PlayerGui:FindFirstChild("PriorityListGUI")
        if priorityGui then priorityGui.Enabled = not priorityGui.Enabled end
    end)

    local enableBtn = Instance.new("TextButton", bottomBar)
    enableBtn.Size = UDim2.new(1, 0, 0, 44)
    enableBtn.Position = UDim2.new(0, 0, 0, 36)
    enableBtn.BackgroundColor3 = Color3.fromRGB(55, 200, 110)
    enableBtn.BackgroundTransparency = 0.1
    enableBtn.BorderSizePixel = 0
    enableBtn.Text = "ENABLED"
    enableBtn.Font = Enum.Font.GothamBold
    enableBtn.TextSize = 13
    enableBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
    Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0, 8)

    local MUT_COLORS_UI = {
        Cursed = Color3.fromRGB(200, 0, 0),
        Gold = Color3.fromRGB(255, 215, 0),
        Diamond = Color3.fromRGB(0, 255, 255),
        YinYang = Color3.fromRGB(220, 220, 220),
        Rainbow = Color3.fromRGB(255, 100, 200),
        Lava = Color3.fromRGB(255, 100, 20),
        Candy = Color3.fromRGB(255, 105, 180),
        Divine = Color3.fromRGB(255, 223, 0)
    }

    local RANK_COLORS = {
        Color3.fromRGB(255, 200, 50),
        Color3.fromRGB(190, 190, 200),
        Color3.fromRGB(200, 120, 60),
    }

    local function updateUI(enabled, allPets)
        autoStealEnabled = enabled

        if enabled then
            enableBtn.Text = "ENABLED"
            enableBtn.BackgroundColor3 = Color3.fromRGB(55, 200, 110)
            enableBtn.BackgroundTransparency = 0.1
            enableBtn.TextColor3 = Color3.fromRGB(10, 10, 15)
        else
            enableBtn.Text = "DISABLED"
            enableBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
            enableBtn.BackgroundTransparency = 0.3
            enableBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
        end

        local function styleMode(btn, stroke, active)
            if active then
                btn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
                btn.BackgroundTransparency = 0.15
                btn.TextColor3 = Color3.fromRGB(220, 220, 255)
                stroke.Color = Color3.fromRGB(120, 120, 170)
                stroke.Transparency = 0.2
            else
                btn.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
                btn.BackgroundTransparency = 0.5
                btn.TextColor3 = Color3.fromRGB(140, 140, 165)
                stroke.Color = Color3.fromRGB(70, 70, 90)
                stroke.Transparency = 0.6
            end
        end

        styleMode(nearestBtn, _nStroke, stealNearestEnabled)
        styleMode(highestBtn, _hStroke, stealHighestEnabled)
        styleMode(priorityBtn, _pStroke, stealPriorityEnabled)

        if selectedTargetUID and allPets then
            for i, p in ipairs(allPets) do
                if p.uid == selectedTargetUID then selectedTargetIndex = i; break end
            end
        end

        if SharedState.ListNeedsRedraw then
            for _, c in ipairs(listFrame:GetChildren()) do
                if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
            end
            petButtons = {}

            if allPets and #allPets > 0 then
                for i = 1, #allPets do
                    local petData = allPets[i]

                    local row = Instance.new("TextButton")
                    row.Size = UDim2.new(1, 0, 0, 36)
                    row.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
                    row.BackgroundTransparency = 0.5
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.LayoutOrder = i
                    row.Parent = listFrame
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                    local rowStroke = Instance.new("UIStroke", row)
                    rowStroke.Color = Color3.fromRGB(55, 55, 72); rowStroke.Thickness = 1; rowStroke.Transparency = 0.7

                    local rankLbl = Instance.new("TextLabel", row)
                    rankLbl.Size = UDim2.new(0, 28, 1, 0)
                    rankLbl.Position = UDim2.new(0, 4, 0, 0)
                    rankLbl.BackgroundTransparency = 1
                    rankLbl.Font = Enum.Font.GothamBold
                    rankLbl.TextSize = 12
                    rankLbl.TextXAlignment = Enum.TextXAlignment.Center
                    if i <= 3 then
                        rankLbl.TextColor3 = RANK_COLORS[i]
                    else
                        rankLbl.TextColor3 = Color3.fromRGB(110, 110, 130)
                    end
                    rankLbl.Text = tostring(i)

                    local vpContainer = Instance.new("Frame", row)
                    vpContainer.Size = UDim2.new(0, 28, 0, 28)
                    vpContainer.Position = UDim2.new(0, 32, 0.5, -14)
                    vpContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
                    vpContainer.BackgroundTransparency = 0.5
                    vpContainer.BorderSizePixel = 0
                    vpContainer.ClipsDescendants = true
                    Instance.new("UICorner", vpContainer).CornerRadius = UDim.new(0, 5)

                    local hasMut = petData.mutation and petData.mutation ~= "None"
                    local mutCol = hasMut and (MUT_COLORS_UI[petData.mutation] or Color3.fromRGB(160, 160, 180)) or nil
                    if mutCol then
                        local vpStroke2 = Instance.new("UIStroke", vpContainer)
                        vpStroke2.Color = mutCol; vpStroke2.Thickness = 1; vpStroke2.Transparency = 0.3
                    end

                    task.spawn(buildViewport, vpContainer, petData.petName)

                    local nameLabel = Instance.new("TextLabel", row)
                    nameLabel.Size = UDim2.new(1, -130, 0, 18)
                    nameLabel.Position = UDim2.new(0, 64, 0, 5)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.RichText = true
                    nameLabel.Font = Enum.Font.GothamMedium
                    nameLabel.TextSize = 12
                    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLabel.Text = formatMutationText(petData.mutation)..petData.petName

                    local ownerLabel = Instance.new("TextLabel", row)
                    ownerLabel.Size = UDim2.new(1, -130, 0, 13)
                    ownerLabel.Position = UDim2.new(0, 64, 0, 21)
                    ownerLabel.BackgroundTransparency = 1
                    ownerLabel.Font = Enum.Font.Gotham
                    ownerLabel.TextSize = 9
                    ownerLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
                    ownerLabel.TextXAlignment = Enum.TextXAlignment.Left
                    ownerLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    ownerLabel.Text = petData.owner or ""

                    local valueLabel = Instance.new("TextLabel", row)
                    valueLabel.Size = UDim2.new(0, 60, 1, 0)
                    valueLabel.Position = UDim2.new(1, -64, 0, 0)
                    valueLabel.BackgroundTransparency = 1
                    valueLabel.Font = Enum.Font.GothamMedium
                    valueLabel.TextSize = 12
                    valueLabel.TextColor3 = Color3.fromRGB(180, 220, 180)
                    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    valueLabel.Text = petData.mpsText

                    petButtons[i] = {
                        button = row,
                        stroke = rowStroke,
                        rank = rankLbl,
                        name = nameLabel,
                        value = valueLabel,
                        owner = ownerLabel
                    }

                    row.MouseButton1Click:Connect(function()
                        selectedTargetIndex = i
                        selectedTargetUID = petData.uid
                        stealNearestEnabled = false; stealHighestEnabled = false; stealPriorityEnabled = false
                        Config.StealNearest = false; Config.StealHighest = false; Config.StealPriority = false
                        SaveConfig()
                        SharedState.ListNeedsRedraw = false
                        updateUI(autoStealEnabled, get_all_pets())
                    end)
                end
            end
            SharedState.ListNeedsRedraw = false
        end

        if selectedTargetIndex > #petButtons then selectedTargetIndex = 1 end

        for i, pb in ipairs(petButtons) do
            local sel = (i == selectedTargetIndex)
            if sel then
                pb.button.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
                pb.button.BackgroundTransparency = 0.2
                pb.stroke.Color = Color3.fromRGB(100, 100, 140)
                pb.stroke.Transparency = 0.2
                pb.name.TextColor3 = Color3.fromRGB(230, 230, 255)
                pb.value.TextColor3 = Color3.fromRGB(140, 240, 160)
            else
                pb.button.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
                pb.button.BackgroundTransparency = 0.5
                pb.stroke.Color = Color3.fromRGB(55, 55, 72)
                pb.stroke.Transparency = 0.7
                pb.name.TextColor3 = Color3.fromRGB(170, 170, 195)
                pb.value.TextColor3 = Color3.fromRGB(130, 170, 130)
            end
        end

        local ct = allPets and allPets[selectedTargetIndex]
        SharedState.SelectedPetData = ct

        listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end

    uiListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(0, uiListLayout.AbsoluteContentSize.Y))
    end)

    SharedState.UpdateAutoStealUI = function()
        updateUI(autoStealEnabled, get_all_pets())
    end

    enableBtn.MouseButton1Click:Connect(function()
        autoStealEnabled = not autoStealEnabled
        SharedState.ListNeedsRedraw = false
        updateUI(autoStealEnabled, get_all_pets())
    end)

    nearestBtn.MouseButton1Click:Connect(function()
        stealNearestEnabled = not stealNearestEnabled
        if stealNearestEnabled then stealHighestEnabled = false; stealPriorityEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig(); SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    highestBtn.MouseButton1Click:Connect(function()
        stealHighestEnabled = not stealHighestEnabled
        if stealHighestEnabled then stealNearestEnabled = false; stealPriorityEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig(); SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    priorityBtn.MouseButton1Click:Connect(function()
        stealPriorityEnabled = not stealPriorityEnabled
        if stealPriorityEnabled then stealNearestEnabled = false; stealHighestEnabled = false end
        Config.StealNearest = stealNearestEnabled; Config.StealHighest = stealHighestEnabled; Config.StealPriority = stealPriorityEnabled
        SaveConfig(); SharedState.ListNeedsRedraw = false; updateUI(autoStealEnabled, get_all_pets())
    end)

    local lastAnimalData = {}
    local function getAnimalHash(al)
        if not al then return "" end
        local h = ""
        for slot, d in pairs(al) do if type(d) == "table" then h = h..tostring(slot)..tostring(d.Index)..tostring(d.Mutation) end end
        return h
    end

    local function scanSinglePlot(plot)
        local changed = false
        pcall(function()
            local ch = Synchronizer:Get(plot.Name); if not ch then return end
            local al = ch:Get("AnimalList")
            local hash = getAnimalHash(al)
            if lastAnimalData[plot.Name] == hash then return end
            lastAnimalData[plot.Name] = hash; changed = true
            for i = #allAnimalsCache, 1, -1 do if allAnimalsCache[i].plot == plot.Name then table.remove(allAnimalsCache, i) end end
            local owner = ch:Get("Owner")
            if not owner or not Players:FindFirstChild(owner.Name) then return end
            local ownerName = owner.Name or "Unknown"
            if not al then return end
            for slot, ad in pairs(al) do
                if type(ad) == "table" then
                    local aName, aInfo = ad.Index, AnimalsData[ad.Index]
                    if aInfo then
                        local mut = ad.Mutation or "None"
                        if mut == "Yin Yang" then mut = "YinYang" end
                        local traits = (ad.Traits and #ad.Traits > 0) and table.concat(ad.Traits, ", ") or "None"
                        local gv = AnimalsShared:GetGeneration(aName, ad.Mutation, ad.Traits, nil)
                        local gt = "$"..NumberUtils:ToString(gv).."/s"
                        table.insert(allAnimalsCache, {
                            name = aInfo.DisplayName or aName, genText = gt, genValue = gv,
                            mutation = mut, traits = traits, owner = ownerName,
                            plot = plot.Name, slot = tostring(slot), uid = plot.Name.."_"..tostring(slot)
                        })
                    end
                end
            end
        end)
        if changed then
            table.sort(allAnimalsCache, function(a, b) return a.genValue > b.genValue end)
            SharedState.ListNeedsRedraw = true
            if not hasShownPriorityAlert and Config.AlertsEnabled then
                task.spawn(function()
                    local foundPriorityPet = nil
                    for i = 1, #PRIORITY_LIST do
                        local searchName = PRIORITY_LIST[i]:lower()
                        for _, pet in ipairs(allAnimalsCache) do
                            if pet.name and pet.name:lower() == searchName then foundPriorityPet = pet; break end
                        end
                        if foundPriorityPet then break end
                    end
                    if foundPriorityPet then
                        local ownerUsername = foundPriorityPet.owner
                        local ownerPlayer = nil
                        local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(foundPriorityPet.plot)
                        if plot then
                            local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
                            if ok and ch then
                                local owner = ch:Get("Owner")
                                if owner then
                                    if typeof(owner) == "Instance" and owner:IsA("Player") then
                                        ownerPlayer = owner; ownerUsername = owner.Name
                                    elseif type(owner) == "table" and owner.Name then
                                        ownerUsername = owner.Name; ownerPlayer = Players:FindFirstChild(owner.Name)
                                    end
                                end
                            end
                        end
                        if not ownerPlayer and ownerUsername then ownerPlayer = Players:FindFirstChild(ownerUsername) end
                        ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, ownerUsername)
                    end
                end)
            end
        end
    end

    local function setupPlotListener(plot)
        local ch, retries = nil, 0
        while not ch and retries < 50 do
            local ok, r = pcall(function() return Synchronizer:Get(plot.Name) end)
            if ok and r then ch = r; break else retries = retries + 1; task.wait(0.1) end
        end
        if not ch then return end
        scanSinglePlot(plot)
        plot.DescendantAdded:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        plot.DescendantRemoving:Connect(function() task.wait(0.1); scanSinglePlot(plot) end)
        task.spawn(function() while plot.Parent do task.wait(5); scanSinglePlot(plot) end end)
    end

    local plots = Workspace:WaitForChild("Plots", 8)
    if plots then
        for _, p in ipairs(plots:GetChildren()) do setupPlotListener(p) end
        plots.ChildAdded:Connect(function(p) task.wait(0.5); setupPlotListener(p) end)
        plots.ChildRemoved:Connect(function(p)
            lastAnimalData[p.Name] = nil
            for i = #allAnimalsCache, 1, -1 do if allAnimalsCache[i].plot == p.Name then table.remove(allAnimalsCache, i) end end
            SharedState.ListNeedsRedraw = true
            for uid in pairs(PromptCache) do
                if uid:find(p.Name, 1, true) then PromptCache[uid] = nil end
            end
            for prompt in pairs(StealTimes) do
                if not prompt.Parent then StealTimes[prompt] = nil end
            end
        end)
    end

    local duelBaseHighlights = {}
    local duelBaseBillboards = {}

    local function clearDuelBaseVisuals()
        for _, h in pairs(duelBaseHighlights) do if h and h.Parent then h:Destroy() end end
        duelBaseHighlights = {}
        for _, b in pairs(duelBaseBillboards) do if b and b.Parent then b:Destroy() end end
        duelBaseBillboards = {}
    end

    local function createDuelBaseMarker(plot, sign)
        local plotName = plot.Name
        if duelBaseHighlights[plotName] then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "DuelBaseHighlight"
        highlight.FillColor = Color3.fromRGB(80, 80, 80)
        highlight.OutlineColor = Color3.fromRGB(50, 50, 50)
        highlight.FillTransparency = 0.6; highlight.OutlineTransparency = 0.4
        highlight.Adornee = plot; highlight.Parent = plot
        duelBaseHighlights[plotName] = highlight
        local bb = Instance.new("BillboardGui")
        bb.Name = "DuelBaseMarker"
        bb.Size = UDim2.new(0, 180, 0, 40)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
        bb.AlwaysOnTop = true; bb.LightInfluence = 0; bb.ResetOnSpawn = false
        bb.Adornee = sign; bb.Parent = sign
        local bbFrame = Instance.new("Frame", bb)
        bbFrame.Size = UDim2.new(1, 0, 1, 0)
        bbFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        bbFrame.BackgroundTransparency = 0.4; bbFrame.BorderSizePixel = 0
        Instance.new("UICorner", bbFrame).CornerRadius = UDim.new(0, 4)
        local stroke = Instance.new("UIStroke", bbFrame)
        stroke.Color = Color3.fromRGB(100, 100, 100); stroke.Thickness = 2
        local label = Instance.new("TextLabel", bbFrame)
        label.Size = UDim2.new(1, 0, 1, 0); label.BackgroundTransparency = 1
        label.Text = "DUEL BASE"; label.Font = Enum.Font.GothamMedium; label.TextSize = 18
        label.TextColor3 = Color3.fromRGB(150, 150, 150)
        label.TextStrokeTransparency = 0; label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        duelBaseBillboards[plotName] = bb
    end

    task.spawn(function()
        while true do
            task.wait(1)
            if not Config.DuelBaseESP then
                clearDuelBaseVisuals()
            else
                local Plots = Workspace:FindFirstChild("Plots")
                if Plots then
                    for _, plot in ipairs(Plots:GetChildren()) do
                        local sign = plot:FindFirstChild("PlotSign")
                        if sign then
                            local textLabel = sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
                            local baseText = textLabel and textLabel.Text or nil
                            if baseText and baseText ~= "Empty Base" then
                                local nickname = baseText:match("^(.-)'") or baseText
                                local ownerPlayer = nil
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p.DisplayName == nickname or p.Name == nickname then ownerPlayer = p; break end
                                end
                                if ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true then
                                    if Config.DuelBaseESP then createDuelBaseMarker(plot, sign) end
                                else
                                    local plotName = plot.Name
                                    if duelBaseHighlights[plotName] then duelBaseHighlights[plotName]:Destroy(); duelBaseHighlights[plotName] = nil end
                                    if duelBaseBillboards[plotName] then duelBaseBillboards[plotName]:Destroy(); duelBaseBillboards[plotName] = nil end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    local hasShownPriorityAlert = false

    local function ShowPriorityAlert(brainrotName, genText, mutation, ownerUsername)
        if not Config.AlertsEnabled then return end
        if hasShownPriorityAlert then return end
        local ownerPlayer = ownerUsername and Players:FindFirstChild(ownerUsername) or nil
        local isInDuel = ownerPlayer and ownerPlayer:GetAttribute("__duels_block_steal") == true or false
        local duelStatusText = isInDuel and "IN DUEL" or "NOT IN DUEL"
        local duelStatusColor = isInDuel and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(200, 200, 200)
        local existing = PlayerGui:FindFirstChild("XiPriorityAlert")
        if existing then existing:Destroy() end
        local alertGui = Instance.new("ScreenGui")
        alertGui.Name = "XiPriorityAlert"; alertGui.ResetOnSpawn = false
        alertGui.DisplayOrder = 999; alertGui.Parent = PlayerGui
        hasShownPriorityAlert = true
        local alertFrame = Instance.new("Frame")
        alertFrame.Size = UDim2.new(0, 400, 0, 60)
        alertFrame.Position = UDim2.new(0.5, 0, 0, -70)
        alertFrame.AnchorPoint = Vector2.new(0.5, 0)
        alertFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        alertFrame.BackgroundTransparency = 0.3
        alertFrame.BorderSizePixel = 0
        alertFrame.Parent = alertGui
        Instance.new("UICorner", alertFrame).CornerRadius = UDim.new(0, 8)
        local glowStroke = Instance.new("UIStroke", alertFrame)
        glowStroke.Name = "GlowStroke"; glowStroke.Thickness = 2
        glowStroke.Color = Color3.fromRGB(150, 150, 170); glowStroke.Transparency = 1
        local innerGlowAlert = Instance.new("Frame", alertFrame)
        innerGlowAlert.Name = "InnerGlow"
        innerGlowAlert.Size = UDim2.new(1, 6, 1, 6); innerGlowAlert.Position = UDim2.new(0.5, 0, 0.5, 0)
        innerGlowAlert.AnchorPoint = Vector2.new(0.5, 0.5); innerGlowAlert.BackgroundColor3 = Color3.fromRGB(150, 150, 170)
        innerGlowAlert.BackgroundTransparency = 1; innerGlowAlert.ZIndex = 0
        Instance.new("UICorner", innerGlowAlert).CornerRadius = UDim.new(0, 8)
        local accentBar = Instance.new("Frame", alertFrame)
        accentBar.Size = UDim2.new(0, 4, 1, -12); accentBar.Position = UDim2.new(0, 8, 0, 6)
        accentBar.BackgroundColor3 = Color3.fromRGB(160, 160, 180); accentBar.BorderSizePixel = 0
        Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 4)
        local nameLabel = Instance.new("TextLabel", alertFrame)
        nameLabel.Size = UDim2.new(1, -30, 0.55, 0); nameLabel.Position = UDim2.new(0, 20, 0, 6)
        nameLabel.BackgroundTransparency = 1; nameLabel.Text = brainrotName.." - "..genText
        nameLabel.Font = Enum.Font.GothamMedium; nameLabel.TextSize = 18
        nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220); nameLabel.TextXAlignment = Enum.TextXAlignment.Center
        nameLabel.TextStrokeTransparency = 0; nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        local genLabel = Instance.new("TextLabel", alertFrame)
        genLabel.Size = UDim2.new(1, -30, 0.4, 0); genLabel.Position = UDim2.new(0, 20, 0.55, 0)
        genLabel.BackgroundTransparency = 1; genLabel.Text = duelStatusText
        genLabel.Font = Enum.Font.GothamMedium; genLabel.TextSize = 17
        genLabel.TextColor3 = duelStatusColor; genLabel.TextXAlignment = Enum.TextXAlignment.Center
        genLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); genLabel.TextStrokeTransparency = 1
        TweenService:Create(alertFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 15)
        }):Play()
        if Config.AlertSoundID and Config.AlertSoundID ~= "" then
            local sound = Instance.new("Sound")
            sound.SoundId = Config.AlertSoundID; sound.Volume = 0.5
            sound.Parent = alertFrame; sound:Play()
            TweenService:Create(glowStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.4}):Play()
            TweenService:Create(innerGlowAlert, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.85}):Play()
            task.delay(0.4, function()
                TweenService:Create(glowStroke, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0.8}):Play()
                TweenService:Create(innerGlowAlert, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
            end)
            sound.Ended:Connect(function() sound:Destroy() end)
        end
        task.delay(4, function()
            TweenService:Create(alertFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0, -70)
            }):Play()
            task.wait(0.35); alertGui:Destroy()
        end)
    end

    task.spawn(function()
        task.wait(0.5)
        while true do
            task.wait(0.5)
            if not hasShownPriorityAlert and Config.AlertsEnabled and #allAnimalsCache > 0 then
                local foundPriorityPet = nil
                for i = 1, #PRIORITY_LIST do
                    local searchName = PRIORITY_LIST[i]:lower()
                    for _, pet in ipairs(allAnimalsCache) do
                        if pet.name and pet.name:lower() == searchName then foundPriorityPet = pet; break end
                    end
                    if foundPriorityPet then break end
                end
                if foundPriorityPet then
                    local ownerUsername = foundPriorityPet.owner
                    local ownerPlayer = nil
                    local plot = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild(foundPriorityPet.plot)
                    if plot then
                        local ok, ch = pcall(function() return Synchronizer:Get(plot.Name) end)
                        if ok and ch then
                            local owner = ch:Get("Owner")
                            if owner then
                                if typeof(owner) == "Instance" and owner:IsA("Player") then
                                    ownerPlayer = owner; ownerUsername = owner.Name
                                elseif type(owner) == "table" and owner.Name then
                                    ownerUsername = owner.Name; ownerPlayer = Players:FindFirstChild(owner.Name)
                                end
                            end
                        end
                    end
                    if not ownerPlayer and ownerUsername then ownerPlayer = Players:FindFirstChild(ownerUsername) end
                    ShowPriorityAlert(foundPriorityPet.name, foundPriorityPet.genText, foundPriorityPet.mutation, ownerUsername)
                end
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            if autoStealEnabled then
                local pets = get_all_pets()
                if #pets > 0 then
                    local function applySelection(newIndex)
                        if newIndex and newIndex >= 1 and newIndex <= #pets and selectedTargetIndex ~= newIndex then
                            selectedTargetIndex = newIndex
                            selectedTargetUID = pets[newIndex].uid
                            SharedState.ListNeedsRedraw = false
                            updateUI(autoStealEnabled, pets)
                        end
                    end
                    if stealPriorityEnabled then
                        local foundPrioIndex = nil
                        for _, pName in ipairs(PRIORITY_LIST) do
                            local searchName = pName:lower()
                            for i, p in ipairs(pets) do
                                if p.petName and p.petName:lower() == searchName then foundPrioIndex = i; break end
                            end
                            if foundPrioIndex then break end
                        end
                        applySelection(foundPrioIndex or 1)
                    elseif stealNearestEnabled then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bestIndex, bestDist = nil, math.huge
                            for i, p in ipairs(pets) do
                                local targetPart = p.animalData and findAdorneeGlobal(p.animalData)
                                if targetPart and targetPart:IsA("BasePart") then
                                    local d = (hrp.Position - targetPart.Position).Magnitude
                                    if d < bestDist then bestDist = d; bestIndex = i end
                                end
                            end
                            applySelection(bestIndex or 1)
                        else
                            applySelection(1)
                        end
                    elseif stealHighestEnabled then
                        applySelection(1)
                    end
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not autoStealEnabled then return end
        local pets = get_all_pets()
        if #pets == 0 then return end
        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
        local tp = pets[selectedTargetIndex]
        if not tp or isMyBaseAnimal(tp.animalData) then return end
        local pr = PromptCache[tp.uid]
        if not pr or not pr.Parent then pr = findPromptForAnimal(tp.animalData) end
        if not pr then return end
        executeSteal(pr)
    end)

    task.spawn(function() while task.wait(0.5) do updateUI(autoStealEnabled, get_all_pets()) end end)
    task.delay(1, function() SharedState.ListNeedsRedraw = true; updateUI(autoStealEnabled, get_all_pets()) end)
    task.spawn(function() while true do SharedState.AllAnimalsCache = allAnimalsCache; task.wait(0.5) end end)

    local beamFolder = Instance.new("Folder", Workspace)
    beamFolder.Name = "XiTracers"
    local currentBeam, currentAtt0, currentAtt1 = nil, nil, nil

    local function updateTracer()
        if not autoStealEnabled or not Config.TracerEnabled then
            if currentBeam then currentBeam:Destroy(); currentBeam = nil end
            if currentAtt0 then currentAtt0:Destroy(); currentAtt0 = nil end
            if currentAtt1 then currentAtt1:Destroy(); currentAtt1 = nil end
            return
        end
        local best, targetPart = nil, nil
        local pets = get_all_pets()
        if #pets == 0 then
            if currentBeam then currentBeam.Enabled = false end
            return
        end
        if selectedTargetIndex > #pets then selectedTargetIndex = #pets end
        if selectedTargetIndex < 1 then selectedTargetIndex = 1 end
        best = pets[selectedTargetIndex] or pets[1]
        targetPart = findAdorneeGlobal(best.animalData)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and targetPart then
            if not currentAtt0 or currentAtt0.Parent ~= hrp then
                if currentAtt0 then currentAtt0:Destroy() end
                currentAtt0 = Instance.new("Attachment", hrp)
                currentAtt0.Name = "BrainrotTracer_Att0"
            end
            if not currentAtt1 or currentAtt1.Parent ~= targetPart then
                if currentAtt1 then currentAtt1:Destroy() end
                currentAtt1 = Instance.new("Attachment", targetPart)
                currentAtt1.Name = "BrainrotTracer_Att1"
            end
            if not currentBeam then
                currentBeam = Instance.new("Beam", beamFolder)
                currentBeam.Name = "BrainrotTracer"
                currentBeam.FaceCamera = true
                currentBeam.Width0 = 0.6
                currentBeam.Width1 = 0.6
                currentBeam.TextureMode = Enum.TextureMode.Static
                currentBeam.TextureSpeed = 3
            end
            currentBeam.Attachment0 = currentAtt0
            currentBeam.Attachment1 = currentAtt1
            currentBeam.Enabled = true
            local MUT_COLORS_TRACE = {
                Cursed = Color3.fromRGB(200, 0, 0), Gold = Color3.fromRGB(255, 215, 0),
                Diamond = Color3.fromRGB(0, 255, 255), YinYang = Color3.fromRGB(220, 220, 220),
                Rainbow = Color3.fromRGB(255, 100, 200), Lava = Color3.fromRGB(255, 100, 20),
                Candy = Color3.fromRGB(255, 105, 180), Divine = Color3.fromRGB(255, 223, 0)
            }
            local col = (best and best.mutation and MUT_COLORS_TRACE[best.mutation]) or Color3.fromRGB(160, 160, 180)
            currentBeam.Color = ColorSequence.new(col)
        else
            if currentBeam then currentBeam.Enabled = false end
        end
    end

    RunService.Heartbeat:Connect(updateTracer)
end)


task.spawn(function()
    local COOLDOWNS = {
        rocket = 120, ragdoll = 30, balloon = 30, inverse = 60,
        nightvision = 60, jail = 60, tiny = 60, jumpscare = 60, morph = 60
    }
    local ALL_COMMANDS = {
        "balloon", "inverse", "jail", "jumpscare", "morph",
        "nightvision", "ragdoll", "rocket", "tiny"
    }

    local activeCooldowns = {}
    SharedState.AdminButtonCache = {}

    local onlyTargetNonStealing = false
    local proximityDelay = 5

    local removePlayer
    local sortAdminPanelList
    local isOnCooldown
    local runAdminCommand
    local updateBalloonButtons
    local setGlobalVisualCooldown
    local triggerAll
    local getNextAvailableCommand
    local addPlayer
    local createPlayerRow

    local S = {
        Glass = Color3.fromRGB(8, 8, 12),
        GlassEdge = Color3.fromRGB(255, 255, 255),
        Surface = Color3.fromRGB(18, 18, 24),
        SurfaceHover = Color3.fromRGB(28, 28, 36),
        TextPri = Color3.fromRGB(245, 245, 250),
        TextSec = Color3.fromRGB(150, 150, 165),
        Accent = Color3.fromRGB(100, 180, 255),
        AccentDim = Color3.fromRGB(70, 130, 200),
        Danger = Color3.fromRGB(255, 70, 90),
        Success = Color3.fromRGB(80, 200, 120),
    }

    local adminGui = Instance.new("ScreenGui")
    adminGui.Name = "SyllinseAdminPanel"
    adminGui.ResetOnSpawn = false
    adminGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.65 or 1
    frame.Size = UDim2.new(0, 380 * mobileScale, 0, 480 * mobileScale)
    frame.Position = UDim2.new(Config.Positions.AdminPanel.X, 0, Config.Positions.AdminPanel.Y, 0)
    frame.BackgroundColor3 = S.Glass
    frame.BackgroundTransparency = 0.12
    frame.BorderSizePixel = 0
    frame.Parent = adminGui

    ApplyViewportUIScale(frame, 380, 480, 0.45, 0.85)
    AddMobileMinimize(frame, "ADMIN")

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)

    local grain = Instance.new("ImageLabel", frame)
    grain.Size = UDim2.new(1, 0, 1, 0)
    grain.BackgroundTransparency = 1
    grain.Image = "rbxassetid://6580642296"
    grain.ImageTransparency = 0.94
    grain.ImageColor3 = Color3.new(1, 1, 1)
    grain.ZIndex = 2
    Instance.new("UICorner", grain).CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = S.GlassEdge
    stroke.Thickness = 1
    stroke.Transparency = 0.78

    local shimmer = Instance.new("Frame", frame)
    shimmer.Size = UDim2.new(0.7, 0, 0, 1)
    shimmer.Position = UDim2.new(0.15, 0, 0, 1)
    shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
    shimmer.BackgroundTransparency = 0.6
    shimmer.BorderSizePixel = 0
    shimmer.ZIndex = 3
    Instance.new("UICorner", shimmer).CornerRadius = UDim.new(1, 0)

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundTransparency = 1
    header.ZIndex = 4
    MakeDraggable(header, frame, "AdminPanel")

    local divider = Instance.new("Frame", frame)
    divider.Size = UDim2.new(1, -32, 0, 1)
    divider.Position = UDim2.new(0, 16, 0, 44)
    divider.BackgroundColor3 = Color3.new(1, 1, 1)
    divider.BackgroundTransparency = 0.88
    divider.BorderSizePixel = 0
    divider.ZIndex = 4

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SYLLINSE"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 15
    title.TextColor3 = S.TextPri
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5

    local titleDot = Instance.new("TextLabel", header)
    titleDot.Size = UDim2.new(0, 80, 0, 14)
    titleDot.Position = UDim2.new(0, 16, 0, 26)
    titleDot.BackgroundTransparency = 1
    titleDot.Text = "ADMIN PANEL"
    titleDot.Font = Enum.Font.Gotham
    titleDot.TextSize = 9
    titleDot.TextColor3 = S.TextSec
    titleDot.TextXAlignment = Enum.TextXAlignment.Left
    titleDot.ZIndex = 5

    local controlBar = Instance.new("Frame", frame)
    controlBar.Size = UDim2.new(1, -20, 0, 80)
    controlBar.Position = UDim2.new(0, 10, 0, 62)
    controlBar.BackgroundColor3 = S.Surface
    controlBar.BackgroundTransparency = 0.35
    controlBar.ZIndex = 4
    Instance.new("UICorner", controlBar).CornerRadius = UDim.new(0, 12)
    local controlBarStroke = Instance.new("UIStroke", controlBar)
    controlBarStroke.Color = S.GlassEdge
    controlBarStroke.Thickness = 1
    controlBarStroke.Transparency = 0.82

    local targetToggleBtn = Instance.new("TextButton", controlBar)
    targetToggleBtn.Size = UDim2.new(0, 120, 0, 32)
    targetToggleBtn.Position = UDim2.new(0, 8, 0, 8)
    targetToggleBtn.BackgroundColor3 = S.SurfaceHover
    targetToggleBtn.BackgroundTransparency = 0.2
    targetToggleBtn.Text = "TARGET: ALL"
    targetToggleBtn.Font = Enum.Font.GothamBold
    targetToggleBtn.TextSize = 11
    targetToggleBtn.TextColor3 = S.TextSec
    targetToggleBtn.ZIndex = 5
    Instance.new("UICorner", targetToggleBtn).CornerRadius = UDim.new(0, 8)
    local targetToggleStroke = Instance.new("UIStroke", targetToggleBtn)
    targetToggleStroke.Color = S.GlassEdge
    targetToggleStroke.Thickness = 1
    targetToggleStroke.Transparency = 0.85

    local delayLabel = Instance.new("TextLabel", controlBar)
    delayLabel.Size = UDim2.new(0, 100, 0, 16)
    delayLabel.Position = UDim2.new(0, 8, 0, 48)
    delayLabel.BackgroundTransparency = 1
    delayLabel.Text = "DELAY: " .. proximityDelay .. "s"
    delayLabel.Font = Enum.Font.GothamMedium
    delayLabel.TextSize = 10
    delayLabel.TextColor3 = S.TextSec
    delayLabel.TextXAlignment = Enum.TextXAlignment.Left
    delayLabel.ZIndex = 5

    local delaySliderBg = Instance.new("Frame", controlBar)
    delaySliderBg.Size = UDim2.new(0, 200, 0, 4)
    delaySliderBg.Position = UDim2.new(0, 8, 0, 68)
    delaySliderBg.BackgroundColor3 = S.SurfaceHover
    delaySliderBg.BackgroundTransparency = 0.2
    Instance.new("UICorner", delaySliderBg).CornerRadius = UDim.new(1, 0)
    
    local delaySliderFill = Instance.new("Frame", delaySliderBg)
    delaySliderFill.BackgroundColor3 = S.Accent
    delaySliderFill.BackgroundTransparency = 0.0
    delaySliderFill.Size = UDim2.new((proximityDelay - 1) / 9, 0, 1, 0)
    Instance.new("UICorner", delaySliderFill).CornerRadius = UDim.new(1, 0)
    
    local delaySliderKnob = Instance.new("Frame", delaySliderBg)
    delaySliderKnob.Size = UDim2.new(0, 11, 0, 11)
    delaySliderKnob.BackgroundColor3 = S.TextPri
    delaySliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    delaySliderKnob.Position = UDim2.new((proximityDelay - 1) / 9, 0, 0.5, 0)
    Instance.new("UICorner", delaySliderKnob).CornerRadius = UDim.new(1, 0)
    local delayKnobStroke = Instance.new("UIStroke", delaySliderKnob)
    delayKnobStroke.Color = S.Glass
    delayKnobStroke.Thickness = 1.5
    delayKnobStroke.Transparency = 0.5

    local function updateDelaySlider(val)
        val = math.clamp(val, 1, 10)
        proximityDelay = val
        local pct = (val - 1) / 9
        delaySliderFill.Size = UDim2.new(pct, 0, 1, 0)
        delaySliderKnob.Position = UDim2.new(pct, 0, 0.5, 0)
        delayLabel.Text = "DELAY: " .. proximityDelay .. "s"
    end

    local delayDragging = false
    delaySliderBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            delayDragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            delayDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if delayDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = i.Position.X
            local r = delaySliderBg.AbsolutePosition.X
            local w = delaySliderBg.AbsoluteSize.X
            local p = math.clamp((x - r) / w, 0, 1)
            updateDelaySlider(1 + (p * 9))
        end
    end)

    local proxCont = Instance.new("Frame", frame)
    proxCont.Size = UDim2.new(1, -20, 0, 44)
    proxCont.Position = UDim2.new(0, 10, 0, 150)
    proxCont.BackgroundColor3 = S.Surface
    proxCont.BackgroundTransparency = 0.35
    proxCont.ZIndex = 4
    Instance.new("UICorner", proxCont).CornerRadius = UDim.new(0, 12)
    local proxContStroke = Instance.new("UIStroke", proxCont)
    proxContStroke.Color = S.GlassEdge
    proxContStroke.Thickness = 1
    proxContStroke.Transparency = 0.82

    local proxBtn = Instance.new("TextButton", proxCont)
    proxBtn.Name = "ProximityAPButton"
    proxBtn.Size = UDim2.new(0, 70, 0, 28)
    proxBtn.Position = UDim2.new(0, 6, 0.5, -14)
    proxBtn.BackgroundColor3 = ProximityAPActive and S.Accent or S.SurfaceHover
    proxBtn.BackgroundTransparency = ProximityAPActive and 0.0 or 0.2
    proxBtn.Text = "PROX"
    proxBtn.Font = Enum.Font.GothamBold
    proxBtn.TextSize = 11
    proxBtn.TextColor3 = ProximityAPActive and S.Glass or S.TextSec
    proxBtn.ZIndex = 5
    Instance.new("UICorner", proxBtn).CornerRadius = UDim.new(0, 8)
    local proxBtnStroke = Instance.new("UIStroke", proxBtn)
    proxBtnStroke.Color = S.GlassEdge
    proxBtnStroke.Thickness = 1
    proxBtnStroke.Transparency = ProximityAPActive and 0.6 or 0.85
    SharedState.ProximityAPButton = proxBtn
    SharedState.ProximityAPButtonStroke = proxBtnStroke
    SharedState.AdminProxBtn = proxBtn

    local spamBaseBtn = Instance.new("TextButton", proxCont)
    spamBaseBtn.Size = UDim2.new(0, 80, 0, 28)
    spamBaseBtn.Position = UDim2.new(0, 82, 0.5, -14)
    spamBaseBtn.BackgroundColor3 = S.SurfaceHover
    spamBaseBtn.BackgroundTransparency = 0.2
    spamBaseBtn.Text = "SPAM BASE"
    spamBaseBtn.Font = Enum.Font.GothamBold
    spamBaseBtn.TextSize = 10
    spamBaseBtn.TextColor3 = S.TextSec
    spamBaseBtn.ZIndex = 5
    Instance.new("UICorner", spamBaseBtn).CornerRadius = UDim.new(0, 8)
    local spamBaseBtnStroke = Instance.new("UIStroke", spamBaseBtn)
    spamBaseBtnStroke.Color = S.GlassEdge
    spamBaseBtnStroke.Thickness = 1
    spamBaseBtnStroke.Transparency = 0.85
    spamBaseBtn.MouseEnter:Connect(function()
        spamBaseBtn.BackgroundTransparency = 0.05
        spamBaseBtn.TextColor3 = S.TextPri
        spamBaseBtnStroke.Transparency = 0.65
    end)
    spamBaseBtn.MouseLeave:Connect(function()
        spamBaseBtn.BackgroundTransparency = 0.2
        spamBaseBtn.TextColor3 = S.TextSec
        spamBaseBtnStroke.Transparency = 0.85
    end)

    spamBaseBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then ShowNotification("SPAM OWNER", "No character found"); return end

        local nearestPlot, nearestDist = nil, math.huge
        local Plots = Workspace:FindFirstChild("Plots")
        if Plots then
            for _, plot in ipairs(Plots:GetChildren()) do
                local sign = plot:FindFirstChild("PlotSign")
                if sign then
                    local yourBase = sign:FindFirstChild("YourBase")
                    if not yourBase or not yourBase.Enabled then
                        local signPos = sign:IsA("BasePart") and sign.Position or (sign.PrimaryPart and sign.PrimaryPart.Position)
                        if not signPos then
                            local part = sign:FindFirstChildWhichIsA("BasePart", true)
                            signPos = part and part.Position
                        end
                        if signPos then
                            local dist = (hrp.Position - signPos).Magnitude
                            if dist < nearestDist then nearestDist = dist; nearestPlot = plot end
                        end
                    end
                end
            end
        end

        if not nearestPlot then ShowNotification("SPAM OWNER", "No nearby base found"); return end

        local targetPlayer = nil
        local ok, ch = pcall(function() return Synchronizer:Get(nearestPlot.Name) end)
        if ok and ch then
            local owner = ch:Get("Owner")
            if owner then
                if typeof(owner) == "Instance" and owner:IsA("Player") then
                    targetPlayer = owner
                elseif type(owner) == "table" and owner.Name then
                    targetPlayer = Players:FindFirstChild(owner.Name)
                end
            end
        end

        if not targetPlayer then
            local sign = nearestPlot:FindFirstChild("PlotSign")
            local textLabel = sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame") and sign.SurfaceGui.Frame:FindFirstChild("TextLabel")
            if textLabel then
                local nickname = textLabel.Text and textLabel.Text:match("^(.-)'") or textLabel.Text
                if nickname then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.DisplayName == nickname or p.Name == nickname then targetPlayer = p; break end
                    end
                end
            end
        end

        if not targetPlayer or targetPlayer == LocalPlayer then
            ShowNotification("SPAM OWNER", "Owner not found or is you"); return
        end

        spamBaseBtn.BackgroundColor3 = S.Accent
        spamBaseBtn.TextColor3 = Color3.new(1, 1, 1)
        ShowNotification("SPAM OWNER", "Spamming " .. targetPlayer.DisplayName)

        task.spawn(function()
            local cmds = {"balloon", "inverse", "jail", "jumpscare", "morph", "nightvision", "ragdoll", "rocket", "tiny"}
            local cmdCount = 0
            local adminFunc = _G.runAdminCommand
            if not adminFunc then task.wait(0.05); adminFunc = _G.runAdminCommand end
            if not adminFunc then
                spamBaseBtn.BackgroundColor3 = S.SurfaceHover
                spamBaseBtn.TextColor3 = S.TextSec
                ShowNotification("SPAM OWNER", "Admin command not ready"); return
            end
            for _, cmd in ipairs(cmds) do
                local success, result = pcall(function() return adminFunc(targetPlayer, cmd) end)
                if success and result then cmdCount = cmdCount + 1 end
                task.wait(0.12)
            end
            task.wait(0.2)
            spamBaseBtn.BackgroundColor3 = S.SurfaceHover
            spamBaseBtn.TextColor3 = S.TextSec
            ShowNotification("SPAM OWNER", "Sent " .. cmdCount .. " commands to " .. targetPlayer.DisplayName)
        end)
    end)

    local proxSliderBg = Instance.new("Frame", proxCont)
    proxSliderBg.Size = UDim2.new(0, 140, 0, 4)
    proxSliderBg.Position = UDim2.new(0, 168, 0.5, -2)
    proxSliderBg.BackgroundColor3 = S.SurfaceHover
    proxSliderBg.BackgroundTransparency = 0.2
    Instance.new("UICorner", proxSliderBg).CornerRadius = UDim.new(1, 0)
    local proxFill = Instance.new("Frame", proxSliderBg)
    proxFill.BackgroundColor3 = S.Accent
    proxFill.BackgroundTransparency = 0.0
    proxFill.Size = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", proxFill).CornerRadius = UDim.new(1, 0)
    local proxKnob = Instance.new("Frame", proxSliderBg)
    proxKnob.Size = UDim2.new(0, 11, 0, 11)
    proxKnob.BackgroundColor3 = S.TextPri
    proxKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    proxKnob.Position = UDim2.new(0, 0, 0.5, 0)
    Instance.new("UICorner", proxKnob).CornerRadius = UDim.new(1, 0)
    local proxKnobStroke = Instance.new("UIStroke", proxKnob)
    proxKnobStroke.Color = S.Glass
    proxKnobStroke.Thickness = 1.5
    proxKnobStroke.Transparency = 0.5

    local function updateProxSlider(val)
        local min, max = 5, 50
        val = math.clamp(val, min, max)
        Config.ProximityRange = val; SaveConfig()
        local pct = (val - min) / (max - min)
        proxFill.Size = UDim2.new(pct, 0, 1, 0)
        proxKnob.Position = UDim2.new(pct, 0, 0.5, 0)
        ShowNotification("PROXIMITY RANGE", string.format("%.1f", val) .. " studs")
    end
    updateProxSlider(Config.ProximityRange)

    local pDragging = false
    proxSliderBg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pDragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then pDragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if pDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local x = i.Position.X
            local r = proxSliderBg.AbsolutePosition.X
            local w = proxSliderBg.AbsoluteSize.X
            local p = (x - r) / w
            updateProxSlider(5 + (p * 45))
        end
    end)

    local proxViz = nil
    local function updateProxViz()
        if ProximityAPActive then
            if not proxViz then
                proxViz = Instance.new("Part")
                proxViz.Name = "XiProxViz"
                proxViz.Anchored = true; proxViz.CanCollide = false
                proxViz.Shape = Enum.PartType.Cylinder
                proxViz.Color = S.Accent; proxViz.Transparency = 0.65
                proxViz.CastShadow = false; proxViz.Parent = Workspace
            end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                proxViz.Size = Vector3.new(0.5, Config.ProximityRange * 2, Config.ProximityRange * 2)
                proxViz.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90)) + Vector3.new(0, -2.5, 0)
            end
        else
            if proxViz then proxViz:Destroy(); proxViz = nil end
        end
    end
    RunService.Heartbeat:Connect(updateProxViz)

    local function updateProximityAPButton()
        if SharedState.ProximityAPButton then
            SharedState.ProximityAPButton.BackgroundColor3 = ProximityAPActive and S.Accent or S.SurfaceHover
            SharedState.ProximityAPButton.BackgroundTransparency = ProximityAPActive and 0.0 or 0.2
            SharedState.ProximityAPButton.TextColor3 = ProximityAPActive and S.Glass or S.TextSec
            if SharedState.ProximityAPButtonStroke then
                SharedState.ProximityAPButtonStroke.Transparency = ProximityAPActive and 0.6 or 0.85
            end
        end
    end

    proxBtn.MouseButton1Click:Connect(function()
        ProximityAPActive = not ProximityAPActive
        updateProximityAPButton()
        ShowNotification("PROXIMITY AP", ProximityAPActive and "ENABLED" or "DISABLED")
    end)

    targetToggleBtn.MouseButton1Click:Connect(function()
        onlyTargetNonStealing = not onlyTargetNonStealing
        if onlyTargetNonStealing then
            targetToggleBtn.Text = "TARGET: NON-STEAL"
            targetToggleBtn.BackgroundColor3 = S.Accent
            targetToggleBtn.BackgroundTransparency = 0.0
            targetToggleBtn.TextColor3 = S.Glass
            targetToggleStroke.Transparency = 0.6
        else
            targetToggleBtn.Text = "TARGET: ALL"
            targetToggleBtn.BackgroundColor3 = S.SurfaceHover
            targetToggleBtn.BackgroundTransparency = 0.2
            targetToggleBtn.TextColor3 = S.TextSec
            targetToggleStroke.Transparency = 0.85
        end
        ShowNotification("TARGET", onlyTargetNonStealing and "NON-STEALING ONLY" or "ALL PLAYERS")
    end)

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1, -20, 1, -210)
    listFrame.Position = UDim2.new(0, 10, 0, 200)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 3
    listFrame.ScrollBarImageColor3 = S.AccentDim
    listFrame.ZIndex = 4
    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function getAdminPanelSortKey(plr)
        if not plr or not plr.Parent then return 3, 9999, "" end
        local stealing = plr:GetAttribute("Stealing")
        local brainrotName = plr:GetAttribute("StealingIndex")
        if not stealing then return 3, 9999, plr.Name or "" end
        if brainrotName then
            for i, pName in ipairs(PRIORITY_LIST) do
                if pName == brainrotName then return 1, i, plr.Name or "" end
            end
            return 2, 9999, plr.Name or ""
        end
        return 2, 9999, plr.Name or ""
    end

    sortAdminPanelList = function()
        local rows = {}
        for _, child in ipairs(listFrame:GetChildren()) do
            if child:IsA("TextButton") and child.Name ~= "" then
                local plr = Players:FindFirstChild(child.Name)
                if plr then table.insert(rows, {row = child, plr = plr}) end
            end
        end
        table.sort(rows, function(a, b)
            local t1, p1, n1 = getAdminPanelSortKey(a.plr)
            local t2, p2, n2 = getAdminPanelSortKey(b.plr)
            if t1 ~= t2 then return t1 < t2 end
            if p1 ~= p2 then return p1 < p2 end
            return (n1 or "") < (n2 or "")
        end)
        for i, entry in ipairs(rows) do entry.row.LayoutOrder = i end
    end

    local function fireClick(button)
        if button then
            if firesignal then
                firesignal(button.MouseButton1Click)
                firesignal(button.MouseButton1Down)
                firesignal(button.Activated)
            else
                local x = button.AbsolutePosition.X + (button.AbsoluteSize.X / 2)
                local y = button.AbsolutePosition.Y + (button.AbsoluteSize.Y / 2) + 58
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
                VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
            end
        end
    end
    _G.fireClick = fireClick

    runAdminCommand = function(targetPlayer, commandName)
        local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
        if not realAdminGui then return false end
        local contentScroll = realAdminGui.AdminPanel:WaitForChild("Content"):WaitForChild("ScrollingFrame")
        local cmdBtn = contentScroll:FindFirstChild(commandName)
        if not cmdBtn then return false end
        fireClick(cmdBtn)
        task.wait(0.05)
        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
        local playerBtn = profilesScroll:FindFirstChild(targetPlayer.Name)
        if not playerBtn then return false end
        fireClick(playerBtn)
        return true
    end
    _G.runAdminCommand = runAdminCommand

    isOnCooldown = function(cmd)
        local adminGui = PlayerGui:FindFirstChild("AdminPanel")
        if adminGui then
            local content = adminGui:FindFirstChild("AdminPanel")
            if content then
                local scrollFrame = content:FindFirstChild("Content")
                if scrollFrame then
                    local scrollingFrame = scrollFrame:FindFirstChild("ScrollingFrame")
                    if scrollingFrame then
                        local cmdButton = scrollingFrame:FindFirstChild(cmd)
                        if cmdButton then
                            local timerLabel = cmdButton:FindFirstChild("Timer")
                            if timerLabel then return timerLabel.Visible end
                        end
                    end
                end
            end
        end
        if not activeCooldowns[cmd] then return false end
        return (tick() - activeCooldowns[cmd]) < (COOLDOWNS[cmd] or 0)
    end

    getNextAvailableCommand = function()
        local priorityCommands = {"ragdoll", "balloon", "rocket", "jail"}
        local otherCommands = {}
        for _, cmd in ipairs(ALL_COMMANDS) do
            local isPriority = false
            for _, pc in ipairs(priorityCommands) do
                if cmd == pc then isPriority = true; break end
            end
            if not isPriority then table.insert(otherCommands, cmd) end
        end
        for _, cmd in ipairs(priorityCommands) do
            if not isOnCooldown(cmd) then return cmd end
        end
        for _, cmd in ipairs(otherCommands) do
            if not isOnCooldown(cmd) then return cmd end
        end
        return nil
    end

    setGlobalVisualCooldown = function(cmd)
        if SharedState.AdminButtonCache[cmd] then
            for _, b in ipairs(SharedState.AdminButtonCache[cmd]) do
                if b and b.Parent then
                    b.BackgroundColor3 = S.Danger
                    task.delay(COOLDOWNS[cmd] or 5, function()
                        if b and b.Parent then
                            local hasBallooned = (cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil)
                            b.BackgroundColor3 = hasBallooned and S.Danger or S.SurfaceHover
                        end
                    end)
                end
            end
        end
    end

    updateBalloonButtons = function()
        local hasBallooned = false
        for _ in pairs(SharedState.BalloonedPlayers) do hasBallooned = true; break end
        if SharedState.AdminButtonCache and SharedState.AdminButtonCache["balloon"] then
            for _, b in ipairs(SharedState.AdminButtonCache["balloon"]) do
                if b and b.Parent then
                    b.BackgroundColor3 = hasBallooned and S.Danger or S.SurfaceHover
                end
            end
        end
    end

    triggerAll = function(plr)
        local count = 0
        for _, cmd in ipairs(ALL_COMMANDS) do
            if not isOnCooldown(cmd) then
                task.delay(count * 0.1, function()
                    if runAdminCommand(plr, cmd) then
                        activeCooldowns[cmd] = tick()
                        setGlobalVisualCooldown(cmd)
                        if cmd == "balloon" then
                            SharedState.BalloonedPlayers[plr.UserId] = true
                            updateBalloonButtons()
                        end
                    end
                end)
                count = count + 1
            end
        end
    end

    local function rayToCubeIntersect(rayOrigin, rayDirection, cubeCenter, cubeSize)
        local halfSize = cubeSize / 2
        local minBounds = cubeCenter - Vector3.new(halfSize, halfSize, halfSize)
        local maxBounds = cubeCenter + Vector3.new(halfSize, halfSize, halfSize)
        if rayDirection.X == 0 then rayDirection = Vector3.new(0.0001, rayDirection.Y, rayDirection.Z) end
        if rayDirection.Y == 0 then rayDirection = Vector3.new(rayDirection.X, 0.0001, rayDirection.Z) end
        if rayDirection.Z == 0 then rayDirection = Vector3.new(rayDirection.X, rayDirection.Y, 0.0001) end
        local tmin = (minBounds.X - rayOrigin.X) / rayDirection.X
        local tmax = (maxBounds.X - rayOrigin.X) / rayDirection.X
        if tmin > tmax then tmin, tmax = tmax, tmin end
        local tymin = (minBounds.Y - rayOrigin.Y) / rayDirection.Y
        local tymax = (maxBounds.Y - rayOrigin.Y) / rayDirection.Y
        if tymin > tymax then tymin, tymax = tymax, tymin end
        if tmin > tymax or tymin > tmax then return false end
        if tymin > tmin then tmin = tymin end
        if tymax < tmax then tmax = tymax end
        local tzmin = (minBounds.Z - rayOrigin.Z) / rayDirection.Z
        local tzmax = (maxBounds.Z - rayOrigin.Z) / rayDirection.Z
        if tzmin > tzmax then tzmin, tzmax = tzmax, tzmin end
        if tmin > tzmax or tzmin > tmax then return false end
        return true
    end

    local highlight = Instance.new("Highlight", game:GetService("CoreGui"))
    highlight.FillColor = S.Accent
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = S.Accent
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = nil
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    RunService.RenderStepped:Connect(function()
        if Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local hitboxSize = 8
            local bestPlayer, bestDistance = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    if rayToCubeIntersect(ray.Origin, ray.Direction, hrp.Position, hitboxSize) then
                        local distance = (ray.Origin - hrp.Position).Magnitude
                        if distance < bestDistance then bestDistance = distance; bestPlayer = p end
                    end
                end
            end
            local newAdornee = bestPlayer and bestPlayer.Character or nil
            if highlight.Adornee ~= newAdornee then highlight.Adornee = newAdornee end
        else
            highlight.Adornee = nil
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, g)
        if not g and inp.UserInputType == Enum.UserInputType.MouseButton1 and Config.ClickToAP then
            local camera = Workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
            local hitboxSize = 8
            local bestPlayer, bestDistance = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Parent then
                    local hrp = p.Character.HumanoidRootPart
                    if rayToCubeIntersect(ray.Origin, ray.Direction, hrp.Position, hitboxSize) then
                        local distance = (ray.Origin - hrp.Position).Magnitude
                        if distance < bestDistance then bestDistance = distance; bestPlayer = p end
                    end
                end
            end
            if bestPlayer then
                if Config.DisableClickToAPOnMoby and isMobyUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Moby users"); return
                end
                if Config.DisableClickToAPOnKawaifu and isKawaifuUser(bestPlayer) then
                    ShowNotification("CLICK TO AP", "Disabled on Kawaifu users"); return
                end
                local hasAnyAvailable = false
                for _, cmd in ipairs(ALL_COMMANDS) do
                    if not isOnCooldown(cmd) then hasAnyAvailable = true; break end
                end
                if hasAnyAvailable then
                    if Config.ClickToAPSingleCommand then
                        local nextCmd = getNextAvailableCommand()
                        if nextCmd then
                            if runAdminCommand(bestPlayer, nextCmd) then
                                activeCooldowns[nextCmd] = tick()
                                setGlobalVisualCooldown(nextCmd)
                                if nextCmd == "balloon" then
                                    SharedState.BalloonedPlayers[bestPlayer.UserId] = true
                                    updateBalloonButtons()
                                end
                                ShowNotification("CLICK AP", "Sent " .. nextCmd .. " to " .. bestPlayer.Name)
                            else
                                ShowNotification("CLICK AP", "Failed: " .. nextCmd)
                            end
                        else
                            ShowNotification("CLICK AP", "All commands on cooldown")
                        end
                    else
                        triggerAll(bestPlayer)
                        ShowNotification("CLICK AP", "Triggered on " .. bestPlayer.Name)
                    end
                else
                    local realAdminGui = PlayerGui:WaitForChild("AdminPanel", 5)
                    if realAdminGui then
                        local profilesScroll = realAdminGui:WaitForChild("AdminPanel"):WaitForChild("Profiles"):WaitForChild("ScrollingFrame")
                        local playerBtn = profilesScroll:FindFirstChild(bestPlayer.Name)
                        if playerBtn then fireClick(playerBtn); ShowNotification("CLICK AP", "Selected " .. bestPlayer.Name) end
                    end
                end
            end
        end
    end)

    local lastProxRun = 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            if ProximityAPActive then
                local now = tick()
                if now - lastProxRun >= proximityDelay then
                    lastProxRun = now
                    local myChar = LocalPlayer.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                if onlyTargetNonStealing then
                                    local isStealing = p:GetAttribute("Stealing")
                                    if isStealing then continue end
                                end
                                local dist = (p.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                                if dist <= Config.ProximityRange then
                                    if not (Config.DisableProximitySpamOnMoby and isMobyUser(p)) and not (Config.DisableProximitySpamOnKawaifu and isKawaifuUser(p)) then
                                        local hasAnyAvailable = false
                                        for _, cmd in ipairs(ALL_COMMANDS) do
                                            if not isOnCooldown(cmd) then hasAnyAvailable = true; break end
                                        end
                                        if hasAnyAvailable then
                                            triggerAll(p)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    createPlayerRow = function(plr)
        local row = Instance.new("TextButton")
        row.Name = plr.Name
        row.LayoutOrder = 0
        row.Size = UDim2.new(1, -4, 0, 64)
        row.BackgroundColor3 = S.Surface
        row.BackgroundTransparency = 0.3
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = listFrame
        row.ZIndex = 5
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)
        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = S.GlassEdge
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.88

        row.MouseEnter:Connect(function()
            row.BackgroundTransparency = 0.1
            rowStroke.Transparency = 0.65
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundTransparency = 0.3
            rowStroke.Transparency = 0.88
        end)

        local headshot = Instance.new("ImageLabel", row)
        headshot.Size = UDim2.new(0, 42, 0, 42)
        headshot.Position = UDim2.new(0, 12, 0.5, -21)
        headshot.BackgroundColor3 = S.SurfaceHover
        pcall(function()
            headshot.Image = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        end)
        headshot.ZIndex = 6
        Instance.new("UICorner", headshot).CornerRadius = UDim.new(1, 0)
        local headshotStroke = Instance.new("UIStroke", headshot)
        headshotStroke.Color = S.GlassEdge
        headshotStroke.Thickness = 1.5
        headshotStroke.Transparency = 0.6

        local dName = Instance.new("TextLabel", row)
        dName.Size = UDim2.new(0, 160, 0, 20)
        dName.Position = UDim2.new(0, 62, 0, 10)
        dName.BackgroundTransparency = 1
        dName.Text = plr.DisplayName
        dName.Font = Enum.Font.GothamBold
        dName.TextSize = 13
        dName.TextColor3 = S.TextPri
        dName.TextXAlignment = Enum.TextXAlignment.Left
        dName.ZIndex = 6

        local uName = Instance.new("TextLabel", row)
        uName.Size = UDim2.new(0, 180, 0, 18)
        uName.Position = UDim2.new(0, 62, 0, 32)
        uName.BackgroundTransparency = 1
        uName.Text = "@" .. plr.Name
        uName.Font = Enum.Font.Gotham
        uName.TextSize = 10
        uName.TextColor3 = S.TextSec
        uName.TextXAlignment = Enum.TextXAlignment.Left
        uName.ZIndex = 6

        local function updateStealLabel()
            if not row.Parent then return end
            local stealing = plr:GetAttribute("Stealing")
            local brainrotName = plr:GetAttribute("StealingIndex")
            if stealing then
                uName.Text = brainrotName or "STEALING"
                uName.TextColor3 = brainrotName and Color3.fromRGB(255, 200, 80) or Color3.fromRGB(255, 150, 80)
                uName.Font = Enum.Font.GothamBold
                uName.TextSize = 11
            else
                uName.Text = "@" .. plr.Name
                uName.TextColor3 = S.TextSec
                uName.Font = Enum.Font.Gotham
                uName.TextSize = 10
            end
        end
        updateStealLabel()

        task.spawn(function()
            while row.Parent do
                task.wait(0.5)
                if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then
                    pcall(removePlayer, plr); break
                end
                pcall(updateStealLabel)
            end
        end)

        local btnCont = Instance.new("Frame", row)
        btnCont.Size = UDim2.new(0, 140, 1, 0)
        btnCont.Position = UDim2.new(1, -145, 0, 0)
        btnCont.BackgroundTransparency = 1
        btnCont.ZIndex = 10

        local buttonsDef = {
            {icon = "🚀", cmd = "rocket"},
            {icon = "🏃", cmd = "ragdoll"},
            {icon = "🔒", cmd = "jail"},
            {icon = "🎈", cmd = "balloon"}
        }

        for i, def in ipairs(buttonsDef) do
            local b = Instance.new("TextButton", btnCont)
            b.Size = UDim2.new(0, 32, 0, 32)
            b.Position = UDim2.new(0, (i - 1) * 35, 0.5, -16)
            b.AutoButtonColor = false
            b.Text = def.icon
            b.TextSize = 18
            b.TextColor3 = S.TextPri
            b.Font = Enum.Font.GothamBold
            b.ZIndex = 11
            b.Active = true
            local isOnCD = isOnCooldown(def.cmd)
            local hasBallooned = def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
            b.BackgroundColor3 = (isOnCD or hasBallooned) and S.Danger or S.SurfaceHover
            b.BackgroundTransparency = (isOnCD or hasBallooned) and 0.1 or 0.25
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
            local bStroke = Instance.new("UIStroke", b)
            bStroke.Color = (isOnCD or hasBallooned) and S.Danger or S.GlassEdge
            bStroke.Thickness = 1
            bStroke.Transparency = (isOnCD or hasBallooned) and 0.3 or 0.82
            bStroke.ZIndex = 12

            b.MouseEnter:Connect(function()
                local cd = isOnCooldown(def.cmd)
                local bal = def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
                if not cd and not bal then
                    b.BackgroundTransparency = 0.05
                    bStroke.Transparency = 0.55
                end
            end)
            b.MouseLeave:Connect(function()
                local cd = isOnCooldown(def.cmd)
                local bal = def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
                if not cd and not bal then
                    b.BackgroundTransparency = 0.25
                    bStroke.Transparency = 0.82
                end
            end)

            if not SharedState.AdminButtonCache[def.cmd] then SharedState.AdminButtonCache[def.cmd] = {} end
            table.insert(SharedState.AdminButtonCache[def.cmd], b)

            task.spawn(function()
                while b and b.Parent do
                    task.wait(0.05)
                    local cd = isOnCooldown(def.cmd)
                    local balloon = def.cmd == "balloon" and SharedState.BalloonedPlayers and next(SharedState.BalloonedPlayers) ~= nil
                    if cd or balloon then
                        b.BackgroundColor3 = S.Danger
                        b.BackgroundTransparency = 0.1
                        bStroke.Color = S.Danger
                        bStroke.Transparency = 0.3
                    else
                        b.BackgroundColor3 = S.SurfaceHover
                        b.BackgroundTransparency = 0.25
                        bStroke.Color = S.GlassEdge
                        bStroke.Transparency = 0.82
                    end
                end
            end)

            b.MouseButton1Click:Connect(function()
                ShowNotification("ADMIN", "Attempting " .. def.cmd .. " on " .. plr.Name)
                if runAdminCommand(plr, def.cmd) then
                    activeCooldowns[def.cmd] = tick()
                    setGlobalVisualCooldown(def.cmd)
                    if def.cmd == "balloon" then
                        SharedState.BalloonedPlayers[plr.UserId] = true
                        for _, btn in ipairs(SharedState.AdminButtonCache["balloon"] or {}) do
                            if btn and btn.Parent then btn.BackgroundColor3 = S.Danger end
                        end
                    end
                    ShowNotification("ADMIN", "Sent " .. def.cmd .. " to " .. plr.Name)
                else
                    ShowNotification("ADMIN", "Failed: " .. def.cmd .. " on " .. plr.Name)
                end
            end)
        end

        local rowHighlight = Instance.new("Frame", row)
        rowHighlight.Size = UDim2.new(1, 0, 1, 0)
        rowHighlight.BackgroundColor3 = S.Accent
        rowHighlight.BackgroundTransparency = 1
        rowHighlight.BorderSizePixel = 0
        rowHighlight.ZIndex = 1
        Instance.new("UICorner", rowHighlight).CornerRadius = UDim.new(0, 12)
        row.MouseEnter:Connect(function() rowHighlight.BackgroundTransparency = 0.85 end)
        row.MouseLeave:Connect(function() rowHighlight.BackgroundTransparency = 1 end)
        row.MouseButton1Click:Connect(function()
            local hasAnyAvailable = false
            for _, cmd in ipairs(ALL_COMMANDS) do
                if not isOnCooldown(cmd) then hasAnyAvailable = true; break end
            end
            if hasAnyAvailable then
                triggerAll(plr)
                ShowNotification("ADMIN", "Triggered ALL on " .. plr.Name)
            end
        end)

        return row
    end

    local playerRows = {}
    local playerRowsByUserId = {}
    local addingPlayers = {}

    addPlayer = function(plr)
        if plr == LocalPlayer then return end
        if not plr or not plr.Parent then return end
        if not Players:FindFirstChild(plr.Name) then return end
        if Config.HideKawaifuFromPanel and isKawaifuUser(plr) then return end
        if playerRowsByUserId[plr.UserId] then return end
        if addingPlayers[plr.UserId] then return end

        addingPlayers[plr.UserId] = true

        local row = createPlayerRow(plr)
        if not playerRowsByUserId[plr.UserId] then
            playerRows[plr] = row
            playerRowsByUserId[plr.UserId] = {player = plr, row = row}
            listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
            sortAdminPanelList()
        else
            row:Destroy()
        end

        addingPlayers[plr.UserId] = nil
    end

    removePlayer = function(plr)
        local userId = plr and plr.UserId or nil
        local entry = userId and playerRowsByUserId[userId] or nil
        local row = entry and entry.row or playerRows[plr]

        if row then
            if row.Parent then
                for cmd, buttons in pairs(SharedState.AdminButtonCache) do
                    for i = #buttons, 1, -1 do
                        if buttons[i] and buttons[i].Parent and buttons[i]:IsDescendantOf(row) then
                            table.remove(buttons, i)
                        end
                    end
                end
                row:Destroy()
            end
            if plr then playerRows[plr] = nil end
            if userId then playerRowsByUserId[userId] = nil end
            if SharedState.BalloonedPlayers and userId then
                SharedState.BalloonedPlayers[userId] = nil
            end
            addingPlayers[userId] = nil
            listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
        end
    end

    Players.PlayerAdded:Connect(function(plr)
        task.wait(0.3)
        if plr and plr.Parent then addPlayer(plr) end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        removePlayer(plr)
    end)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then addPlayer(p) end
    end
    sortAdminPanelList()

    task.spawn(function()
        while listFrame and listFrame.Parent do
            task.wait(0.5)
            pcall(sortAdminPanelList)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            local currentPlayerIds = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Parent then
                    currentPlayerIds[p.UserId] = p
                end
            end
            for userId, entry in pairs(playerRowsByUserId) do
                if not currentPlayerIds[userId] or not entry.player or not entry.player.Parent then
                    pcall(removePlayer, entry.player)
                end
            end
            for userId, p in pairs(currentPlayerIds) do
                if not playerRowsByUserId[userId] then
                    addPlayer(p)
                end
            end
        end
    end)

    layout.Changed:Connect(function()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
end)

task.spawn(function()
    local COOLDOWNS = {
        rocket = 120,
        ragdoll = 30,
        balloon = 30,
        inverse = 60,
        nightvision = 60,
        jail = 60,
        tiny = 60,
        jumpscare = 60,
        morph = 60
    }

    local ALL_COMMANDS = {
        "jail", "rocket", "inverse", "ragdoll", "jumpscare", "tiny", "balloon", "morph", "nightvision"
    }

    local function formatTime(seconds)
        if seconds >= 60 then
            return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
        else
            return string.format("%ds", seconds)
        end
    end

    local function capitalize(str)
        return str:sub(1,1):upper() .. str:sub(2)
    end

    local isOnCooldown = function(cmd)
        local adminGui = PlayerGui:FindFirstChild("AdminPanel")
        if adminGui then
            local content = adminGui:FindFirstChild("AdminPanel")
            if content then
                local scrollFrame = content:FindFirstChild("Content")
                if scrollFrame then
                    local scrollingFrame = scrollFrame:FindFirstChild("ScrollingFrame")
                    if scrollingFrame then
                        local cmdButton = scrollingFrame:FindFirstChild(cmd)
                        if cmdButton then
                            local timerLabel = cmdButton:FindFirstChild("Timer")
                            if timerLabel then
                                return timerLabel.Visible
                            end
                        end
                    end
                end
            end
        end
        return false
    end

    local function getRemainingCooldown(cmd)
        local adminGui = PlayerGui:FindFirstChild("AdminPanel")
        if adminGui then
            local content = adminGui:FindFirstChild("AdminPanel")
            if content then
                local scrollFrame = content:FindFirstChild("Content")
                if scrollFrame then
                    local scrollingFrame = scrollFrame:FindFirstChild("ScrollingFrame")
                    if scrollingFrame then
                        local cmdButton = scrollingFrame:FindFirstChild(cmd)
                        if cmdButton then
                            local timerLabel = cmdButton:FindFirstChild("Timer")
                            if timerLabel and timerLabel.Visible then
                                local text = timerLabel.Text
                                local num = tonumber(text:match("%d+"))
                                if num then
                                    return num
                                end
                            end
                        end
                    end
                end
            end
        end
        return 0
    end

    if not Config.Positions.CooldownTracker then
        Config.Positions.CooldownTracker = {X = 0.02, Y = 0.5}
    end

    local cooldownGui = Instance.new("ScreenGui")
    cooldownGui.Name = "CooldownTracker"
    cooldownGui.ResetOnSpawn = false
    cooldownGui.Parent = PlayerGui
    cooldownGui.Enabled = Config.ShowCooldownTracker or false

    local mainFrame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.65 or 1
    mainFrame.Size = UDim2.new(0, 280 * mobileScale, 0, 420 * mobileScale)
    mainFrame.Position = UDim2.new(Config.Positions.CooldownTracker.X, 0, Config.Positions.CooldownTracker.Y, -210)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = cooldownGui

    ApplyViewportUIScale(mainFrame, 280, 420, 0.45, 0.85)
    AddMobileMinimize(mainFrame, "COOLDOWNS")

    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(50, 50, 65)
    stroke.Thickness = 1
    stroke.Transparency = 0.4

    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 50)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    header.BackgroundTransparency = 0.2
    header.ZIndex = 4

    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 14)

    local headerDivider = Instance.new("Frame", mainFrame)
    headerDivider.Size = UDim2.new(1, 0, 0, 1)
    headerDivider.Position = UDim2.new(0, 0, 0, 50)
    headerDivider.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 4

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -100, 0, 20)
    title.Position = UDim2.new(0, 16, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Command Cooldowns"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(235, 235, 250)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5

    local subtitle = Instance.new("TextLabel", header)
    subtitle.Size = UDim2.new(1, -100, 0, 14)
    subtitle.Position = UDim2.new(0, 16, 0, 30)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Status monitor"
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 9
    subtitle.TextColor3 = Color3.fromRGB(130, 130, 155)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 5

    local function dragCooldownTracker()
        local dragging = false
        local dragStart = nil
        local startPos = nil
        
        header.InputBegan:Connect(function(input)
            if Config.UILocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        if Config.Positions then
                            Config.Positions.CooldownTracker = {
                                X = mainFrame.Position.X.Scale,
                                Y = mainFrame.Position.Y.Scale
                            }
                            SaveConfig()
                        end
                    end
                end)
            end
        end)
        
        header.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local viewport = workspace.CurrentCamera.ViewportSize
                local newX = math.clamp(startPos.X.Scale + (delta.X / viewport.X), 0, 1)
                local newY = math.clamp(startPos.Y.Scale + (delta.Y / viewport.Y), 0, 1)
                mainFrame.Position = UDim2.new(newX, 0, newY, -210)
            end
        end)
    end
    
    dragCooldownTracker()

    local listFrame = Instance.new("ScrollingFrame", mainFrame)
    listFrame.Size = UDim2.new(1, -16, 1, -70)
    listFrame.Position = UDim2.new(0, 8, 0, 60)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 3
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
    listFrame.ZIndex = 4
    listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local cooldownRows = {}

    local function createCommandRow(cmdName)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
        row.BackgroundTransparency = 0.4
        row.BorderSizePixel = 0
        row.Parent = listFrame
        row.ZIndex = 5
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        local rowStroke = Instance.new("UIStroke", row)
        rowStroke.Color = Color3.fromRGB(55, 55, 75)
        rowStroke.Thickness = 1
        rowStroke.Transparency = 0.6

        local nameLabel = Instance.new("TextLabel", row)
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 16, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = capitalize(cmdName)
        nameLabel.Font = Enum.Font.GothamMedium
        nameLabel.TextSize = 13
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.ZIndex = 6

        local statusFrame = Instance.new("Frame", row)
        statusFrame.Size = UDim2.new(0, 90, 0, 32)
        statusFrame.Position = UDim2.new(1, -100, 0.5, -16)
        statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        statusFrame.BackgroundTransparency = 0.2
        statusFrame.BorderSizePixel = 0
        statusFrame.ZIndex = 6
        Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 8)

        local statusText = Instance.new("TextLabel", statusFrame)
        statusText.Size = UDim2.new(1, 0, 1, 0)
        statusText.BackgroundTransparency = 1
        statusText.Text = "READY"
        statusText.Font = Enum.Font.GothamBold
        statusText.TextSize = 11
        statusText.TextColor3 = Color3.fromRGB(150, 150, 200)
        statusText.TextXAlignment = Enum.TextXAlignment.Center
        statusText.ZIndex = 7

        return {
            row = row,
            statusText = statusText,
            statusFrame = statusFrame,
            name = cmdName,
            totalCooldown = COOLDOWNS[cmdName]
        }
    end

    for _, cmd in ipairs(ALL_COMMANDS) do
        local rowData = createCommandRow(cmd)
        cooldownRows[cmd] = rowData
        table.insert(cooldownRows, rowData)
    end

    local function updateCooldowns()
        for _, rowData in ipairs(cooldownRows) do
            local cmd = rowData.name
            local onCD = isOnCooldown(cmd)
            local remaining = getRemainingCooldown(cmd)

            if onCD and remaining > 0 then
                rowData.statusText.Text = formatTime(remaining)
                rowData.statusText.TextColor3 = Color3.fromRGB(220, 120, 120)
                rowData.statusFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
                rowData.statusFrame.BackgroundTransparency = 0.1
                rowData.row.BackgroundTransparency = 0.2
            else
                rowData.statusText.Text = "READY"
                rowData.statusText.TextColor3 = Color3.fromRGB(150, 150, 200)
                rowData.statusFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                rowData.statusFrame.BackgroundTransparency = 0.2
                rowData.row.BackgroundTransparency = 0.4
            end
        end
    end

    local function updateCanvasSize()
        listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    updateCanvasSize()

    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(updateCooldowns)
        end
    end)

    updateCooldowns()
    
    _G.toggleCooldownTracker = function(enabled)
        cooldownGui.Enabled = enabled
    end
end)

task.spawn(function()
    if not Config.Positions.StealTracker then
        Config.Positions.StealTracker = {X = 0.5, Y = 0.02}
    end

    local stealTrackerGui = Instance.new("ScreenGui")
    stealTrackerGui.Name = "StealTracker"
    stealTrackerGui.ResetOnSpawn = false
    stealTrackerGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    local mobileScale = IS_MOBILE and 0.65 or 1
    frame.Size = UDim2.new(0, 260 * mobileScale, 0, 0)
    frame.Position = UDim2.new(Config.Positions.StealTracker.X, 0, Config.Positions.StealTracker.Y, 0)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = stealTrackerGui
    frame.AutomaticSize = Enum.AutomaticSize.Y

    ApplyViewportUIScale(frame, 260, 0, 0.45, 0.85)
    AddMobileMinimize(frame, "STEAL TRACKER")

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local frameStroke = Instance.new("UIStroke", frame)
    frameStroke.Color = Color3.fromRGB(55, 55, 70)
    frameStroke.Thickness = 1
    frameStroke.Transparency = 0.5

    local innerGlow = Instance.new("Frame", frame)
    innerGlow.Size = UDim2.new(1, -4, 1, -4)
    innerGlow.Position = UDim2.new(0, 2, 0, 2)
    innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlow.BackgroundTransparency = 0.96
    innerGlow.BorderSizePixel = 0
    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)

    local topAccent = Instance.new("Frame", frame)
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    topAccent.BorderSizePixel = 0
    topAccent.ZIndex = 5
    Instance.new("UICorner", topAccent).CornerRadius = UDim.new(0, 12)

    local header = Instance.new("Frame", frame)
    header.Size = UDim2.new(1, 0, 0, 42)
    header.Position = UDim2.new(0, 0, 0, 2)
    header.BackgroundTransparency = 1
    header.ZIndex = 4

    do
        local dragging = false
        local dragStart = nil
        local startAbsX = nil
        local startAbsY = nil

        header.InputBegan:Connect(function(input)
            if Config.UILocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startAbsX = frame.AbsolutePosition.X
                startAbsY = frame.AbsolutePosition.Y
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        Config.Positions.StealTracker = {
                            X = frame.AbsolutePosition.X / frame.Parent.AbsoluteSize.X,
                            Y = frame.AbsolutePosition.Y / frame.Parent.AbsoluteSize.Y,
                        }
                        SaveConfig()
                    end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                local vp = workspace.CurrentCamera.ViewportSize
                local newX = math.clamp(startAbsX + delta.X, 0, vp.X - frame.AbsoluteSize.X)
                local newY = math.clamp(startAbsY + delta.Y, 0, vp.Y - frame.AbsoluteSize.Y)
                frame.Position = UDim2.new(0, newX, 0, newY)
            end
        end)
    end

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "STEALING"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(200, 80, 80)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 5

    local countLabel = Instance.new("TextLabel", header)
    countLabel.Size = UDim2.new(0, 28, 0, 22)
    countLabel.Position = UDim2.new(1, -38, 0.5, -11)
    countLabel.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
    countLabel.BackgroundTransparency = 0.3
    countLabel.Text = "0"
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextSize = 11
    countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    countLabel.ZIndex = 5
    Instance.new("UICorner", countLabel).CornerRadius = UDim.new(1, 0)

    local divider = Instance.new("Frame", frame)
    divider.Size = UDim2.new(1, -16, 0, 1)
    divider.Position = UDim2.new(0, 8, 0, 44)
    divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    divider.BorderSizePixel = 0
    divider.ZIndex = 4

    local listFrame = Instance.new("ScrollingFrame", frame)
    listFrame.Size = UDim2.new(1, -16, 0, 0)
    listFrame.Position = UDim2.new(0, 8, 0, 50)
    listFrame.BackgroundTransparency = 1
    listFrame.BorderSizePixel = 0
    listFrame.ScrollBarThickness = 2
    listFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 80, 80)
    listFrame.ZIndex = 4
    listFrame.AutomaticSize = Enum.AutomaticSize.Y

    local layout = Instance.new("UIListLayout", listFrame)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local activeRows = {}

    local function createStealerRow(plr)
        local brainrotName = plr:GetAttribute("StealingIndex") or "???"

        local row = Instance.new("Frame")
        row.Name = plr.Name
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        row.BackgroundTransparency = 0.5
        row.BorderSizePixel = 0
        row.Parent = listFrame
        row.ZIndex = 5
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        local leftBar = Instance.new("Frame", row)
        leftBar.Size = UDim2.new(0, 3, 0.7, 0)
        leftBar.Position = UDim2.new(0, 0, 0.15, 0)
        leftBar.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        leftBar.BorderSizePixel = 0
        leftBar.ZIndex = 6
        Instance.new("UICorner", leftBar).CornerRadius = UDim.new(1, 0)

        local nameLabel = Instance.new("TextLabel", row)
        nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = plr.DisplayName
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.ZIndex = 6

        local arrowLabel = Instance.new("TextLabel", row)
        arrowLabel.Size = UDim2.new(0.1, 0, 1, 0)
        arrowLabel.Position = UDim2.new(0.4, 0, 0, 0)
        arrowLabel.BackgroundTransparency = 1
        arrowLabel.Text = "→"
        arrowLabel.Font = Enum.Font.GothamBold
        arrowLabel.TextSize = 14
        arrowLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
        arrowLabel.TextXAlignment = Enum.TextXAlignment.Center
        arrowLabel.ZIndex = 6

        local brainrotLabel = Instance.new("TextLabel", row)
        brainrotLabel.Size = UDim2.new(0.5, -10, 1, 0)
        brainrotLabel.Position = UDim2.new(0.5, 0, 0, 0)
        brainrotLabel.BackgroundTransparency = 1
        brainrotLabel.Text = brainrotName
        brainrotLabel.Font = Enum.Font.GothamBold
        brainrotLabel.TextSize = 12
        brainrotLabel.TextColor3 = Color3.fromRGB(200, 80, 80)
        brainrotLabel.TextXAlignment = Enum.TextXAlignment.Left
        brainrotLabel.TextTruncate = Enum.TextTruncate.AtEnd
        brainrotLabel.ZIndex = 6

        local rowHighlight = Instance.new("Frame", row)
        rowHighlight.Size = UDim2.new(1, 0, 1, 0)
        rowHighlight.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        rowHighlight.BackgroundTransparency = 1
        rowHighlight.BorderSizePixel = 0
        rowHighlight.ZIndex = 1
        Instance.new("UICorner", rowHighlight).CornerRadius = UDim.new(0, 8)
        
        row.MouseEnter:Connect(function()
            row.BackgroundTransparency = 0.3
            rowHighlight.BackgroundTransparency = 0.85
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundTransparency = 0.5
            rowHighlight.BackgroundTransparency = 1
        end)

        task.spawn(function()
            while row.Parent do
                task.wait(1)
                if not plr or not plr.Parent or not Players:FindFirstChild(plr.Name) then
                    if row and row.Parent then row:Destroy() end
                    activeRows[plr.Name] = nil
                    break
                end
                local newBrainrot = plr:GetAttribute("StealingIndex")
                if newBrainrot and brainrotLabel.Text ~= newBrainrot then
                    brainrotLabel.Text = newBrainrot
                end
            end
        end)

        return row
    end

    local function updateTracker()
        local stealingPlayers = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p:GetAttribute("Stealing") == true then
                table.insert(stealingPlayers, p)
            end
        end

        local stealingByName = {}
        for _, p in ipairs(stealingPlayers) do
            stealingByName[p.Name] = p
        end

        for name, row in pairs(activeRows) do
            if not stealingByName[name] then
                if row and row.Parent then row:Destroy() end
                activeRows[name] = nil
            end
        end

        for _, p in ipairs(stealingPlayers) do
            if not activeRows[p.Name] then
                activeRows[p.Name] = createStealerRow(p)
            end
        end

        local activeCount = #stealingPlayers
        countLabel.Text = tostring(activeCount)
        
        if activeCount == 0 then
            frame.Visible = false
        else
            frame.Visible = true
            listFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
            frame.Size = UDim2.new(0, 260 * mobileScale, 0, 0)
            frame.AutomaticSize = Enum.AutomaticSize.Y
        end
    end

    task.spawn(function()
        while stealTrackerGui and stealTrackerGui.Parent do
            task.wait(1)
            pcall(updateTracker)
        end
    end)

    updateTracker()
    
    if #Players:GetPlayers() == 0 then
        frame.Visible = false
    end
end)

local BASES_LOW = {
    [1] = Vector3.new(-460, -6, 219), [5] = Vector3.new(-355, -6, 217),
    [2] = Vector3.new(-460, -6, 111), [6] = Vector3.new(-355, -6, 113),
    [3] = Vector3.new(-460, -6, 5),   [7] = Vector3.new(-355, -6, 5),
    [4] = Vector3.new(-460, -6, -100),[8] = Vector3.new(-355, -6, -100)
}

local BASES_HIGH = {
    [1] = Vector3.new(-476.474853515625, 20.732906341552734, 220.94090270996094), [5] = Vector3.new(-342.5367126464844, 20.69801902770996, 221.44737243652344),
    [2] = Vector3.new(-476.5684814453125, 20.70664405822754, 113.77315521240234), [6] = Vector3.new(-342.8604736328125, 20.669641494750977, 113.41409301757812),
    [3] = Vector3.new(-476.8675842285156, 20.74148178100586, 6.178487777709961),  [7] = Vector3.new(-342.42108154296875, 20.687667846679688, 6.249461650848389),
    [4] = Vector3.new(-476.6324768066406, 20.744949340820312, -101.07275390625), [8] = Vector3.new(-342.7937927246094, 20.748071670532227, -99.73458862304688)
}

local CLONE_POSITIONS_FLOOR = {
    Vector3.new(-476, -4, 221), Vector3.new(-476, -4, 114),
    Vector3.new(-476, -4, 7),   Vector3.new(-476, -4, -100),
    Vector3.new(-342, -4, -100),Vector3.new(-342, -4, 6),
    Vector3.new(-342, -4, 114), Vector3.new(-342, -4, 220)
}

local FACE_TARGETS = {
    Vector3.new(-519, -3, 221), Vector3.new(-519, -3, 114),
    Vector3.new(-518, -3, 7),   Vector3.new(-519, -3, -100),
    Vector3.new(-301, -3, -100),Vector3.new(-301, -3, 7),
    Vector3.new(-302, -3, 114), Vector3.new(-300, -3, 220)
}

local TeleportData = {
    bodyController = nil,
}
local bodyController = TeleportData.bodyController
local floatActive = State.floatActive

task.spawn(function()
    local plr = LocalPlayer
    if not plr then return end
    _G.FloatEnabled = _G.FloatEnabled or false
    local floatPlatform = nil
    local function getHRP()
        local c = plr.Character
        if not c then return end
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")
    end
    local stopFloat
    local function startFloat()
        if floatPlatform then floatPlatform:Destroy() end
        floatPlatform = Instance.new("Part")
        floatPlatform.Size = Vector3.new(6, 1, 6)
        floatPlatform.Anchored = true
        floatPlatform.CanCollide = true
        floatPlatform.Transparency = 1
        floatPlatform.Parent = workspace
        task.spawn(function()
            while _G.FloatEnabled and floatPlatform do
                if plr:GetAttribute("Stealing") then
                    stopFloat()
                    if _G.updateFloatPanelToggle then
                        pcall(function() _G.updateFloatPanelToggle(false) end)
                    end
                    break
                end
                local hrp = getHRP()
                if hrp then
                    floatPlatform.Position = hrp.Position - Vector3.new(0, 3, 0)
                end
                task.wait(0.05)
            end
        end)
    end
    stopFloat = function()
        _G.FloatEnabled = false
        if floatPlatform then
            floatPlatform:Destroy()
            floatPlatform = nil
        end
        if _G.updateMovementPanelFloatVisual then pcall(_G.updateMovementPanelFloatVisual, false) end
    end
    _G.enableFloat = function()
        _G.FloatEnabled = true
        startFloat()
        if _G.updateMovementPanelFloatVisual then pcall(_G.updateMovementPanelFloatVisual, true) end
    end
    _G.disableFloat = function()
        stopFloat()
        if _G.updateMovementPanelFloatVisual then pcall(_G.updateMovementPanelFloatVisual, false) end
    end
    plr.CharacterAdded:Connect(function()
        if _G.FloatEnabled then
            stopFloat()
            if _G.updateFloatPanelToggle then
                pcall(function() _G.updateFloatPanelToggle(false) end)
            end
        end
    end)
    if IS_MOBILE then
        UserInputService.JumpRequest:Connect(function()
            if _G.FloatEnabled then
                stopFloat()
                if _G.updateFloatPanelToggle then
                    pcall(function() _G.updateFloatPanelToggle(false) end)
                end
            end
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == (Enum.KeyCode[Config.FloatKey] or Enum.KeyCode.G) then
        if _G.FloatEnabled then
            if _G.disableFloat then pcall(_G.disableFloat) end
        else
            if _G.enableFloat then pcall(_G.enableFloat) end
        end
        if _G.updateMovementPanelFloatVisual then pcall(_G.updateMovementPanelFloatVisual, _G.FloatEnabled) end
        ShowNotification("FLOAT", _G.FloatEnabled and "ENABLED" or "DISABLED")
    end
end)

function getClosestBaseIdx(pos)
    local closest, dist = 1, math.huge
    for i, basePos in pairs(BASES_LOW) do
        local d = (Vector2.new(pos.X, pos.Z) - Vector2.new(basePos.X, basePos.Z)).Magnitude
        if d < dist then dist = d; closest = i end
    end
    return closest
end

local isTpMoving = State.isTpMoving

_G._isTargetPlotUnlocked = function(plotName)
    local ok, res = pcall(function()
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return false end
        local targetPlot = plots:FindFirstChild(plotName)
        if not targetPlot then return false end
        local unlockFolder = targetPlot:FindFirstChild("Unlock")
        if not unlockFolder then return true end
        local unlockItems = {}
        for _, item in pairs(unlockFolder:GetChildren()) do
            local pos = nil
            if item:IsA("Model") then pcall(function() pos = item:GetPivot().Position end)
            elseif item:IsA("BasePart") then pos = item.Position end
            if pos then table.insert(unlockItems, {Object = item, Height = pos.Y}) end
        end
        table.sort(unlockItems, function(a, b) return a.Height < b.Height end)
        if #unlockItems == 0 then return true end
        local floor1Door = unlockItems[1].Object
        for _, desc in ipairs(floor1Door:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Enabled then return false end
        end
        for _, child in ipairs(floor1Door:GetChildren()) do
            if child:IsA("ProximityPrompt") and child.Enabled then return false end
        end
        return true
    end)
    return ok and res or false
end

local function runAutoSnipe()
    if State.isTpMoving then return end
    
    if State.carpetSpeedEnabled then
        setCarpetSpeed(false)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = "OFF"
            _carpetStatusLabel.TextColor3 = Theme.Error
        end
    end

    local targetPetData = nil
    
    if Config.AutoTPPriority then
        local bestEntry = nil
        local cache = SharedState.AllAnimalsCache
        if cache and type(cache) == "table" then
            local priorityList = Config.PriorityList or PRIORITY_LIST
            if priorityList and #priorityList > 0 then
                for _, pName in ipairs(priorityList) do
                    local searchName = pName:lower()
                    for _, a in ipairs(cache) do
                        local petName = a.name and a.name:lower() or ""
                        if petName == searchName and a.owner ~= LocalPlayer.Name then
                            bestEntry = a
                            break
                        end
                    end
                    if bestEntry then break end
                end
            end
            if not bestEntry then
                for _, a in ipairs(cache) do
                    if a and a.owner ~= LocalPlayer.Name then
                        bestEntry = a
                        break
                    end
                end
            end
        end
        if bestEntry then
            targetPetData = bestEntry
        else
            if not SharedState.SelectedPetData then 
                ShowNotification("ERROR","No target selected!")
                return 
            end
            targetPetData = SharedState.SelectedPetData.animalData
        end
    else
        if not SharedState.SelectedPetData then 
            ShowNotification("ERROR","No target selected!")
            return 
        end
        targetPetData = SharedState.SelectedPetData.animalData
    end
    if not targetPetData then return end


    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if not hrp or not hum or hum.Health <= 0 then return end
    
    State.isTpMoving = true
    isTpMoving = State.isTpMoving
    
    local targetPart = findAdorneeGlobal(targetPetData)
    if not targetPart then 
        State.isTpMoving = false
        isTpMoving = State.isTpMoving
        return 
    end
    
    local exactPos = targetPart.Position
    local carpetName = Config.TpSettings.Tool
    local carpet = LocalPlayer.Backpack:FindFirstChild(carpetName) or char:FindFirstChild(carpetName)
    local cloner = LocalPlayer.Backpack:FindFirstChild("Quantum Cloner") or char:FindFirstChild("Quantum Cloner")

    if carpet then hum:EquipTool(carpet) end
    local isSecondFloor = exactPos.Y > 10
    local plotIndex = getClosestBaseIdx(exactPos)
    local targetBasePos = isSecondFloor and BASES_HIGH[plotIndex] or BASES_LOW[plotIndex]
    
    local minHeight = 50
    local targetHeight = math.max(targetBasePos.Y, minHeight)
    
    task.wait(0.1)

    local jumpStart = tick()
    while hrp.Position.Y < targetHeight and (tick() - jumpStart) < 3 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 200, hrp.AssemblyLinearVelocity.Z)
        RunService.Heartbeat:Wait()
    end

    for i = 1, 10 do
        hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        if (hrp.Position - targetBasePos).Magnitude > 3 then
            hrp.CFrame = CFrame.new(targetBasePos)
            task.wait(0.05)
        end
    end

    local bestFace = FACE_TARGETS[1]
    local minFaceDist = math.huge
    for _, v in ipairs(FACE_TARGETS) do
        local d = (hrp.Position - v).Magnitude
        if d < minFaceDist then
            minFaceDist = d
            bestFace = v
        end
    end

    if not isSecondFloor then
        local bestSpot = CLONE_POSITIONS_FLOOR[1]
        local minDst = math.huge
        for _, v in ipairs(CLONE_POSITIONS_FLOOR) do
            local d = (targetPart.Position - v).Magnitude
            if d < minDst then minDst = d; bestSpot = v end
        end
        for i = 1, 6 do
            if (hrp.Position - bestSpot).Magnitude > 3 then
                hrp.CFrame = CFrame.new(bestSpot)
                task.wait(0.05)
            end
        end
    end

    hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(bestFace.X, hrp.Position.Y, bestFace.Z))
    task.wait(0.1)

    local targetPlotUnlocked = _G._isTargetPlotUnlocked(targetPetData.plot)
    local itemHeight = exactPos.Y

    if targetPlotUnlocked and not isSecondFloor then
        pcall(function()
            local directChar = LocalPlayer.Character
            if not directChar then return end
            local directHRP = directChar:FindFirstChild("HumanoidRootPart")
            local directHumanoid = directChar:FindFirstChildOfClass("Humanoid")
            if not directHRP or not directHumanoid then return end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                local c = bp:FindFirstChild(Config.TpSettings.Tool or "Flying Carpet")
                if c then directHumanoid:EquipTool(c) end
            end
            directHRP.AssemblyLinearVelocity = Vector3.zero
            directHRP.AssemblyAngularVelocity = Vector3.zero
            directHRP.CFrame = CFrame.new(exactPos.X, directHRP.Position.Y, exactPos.Z)
            directHRP.AssemblyLinearVelocity = Vector3.zero
            directHRP.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    if isSecondFloor or not targetPlotUnlocked then
        walkForward(0.3)
        task.wait(0.5)
        local posBeforeClone = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or hrp.Position
        instantClone()
        while _G.isCloning do task.wait() end

        local newChar, newHRP, newHumanoid
        local cloneTimeout = os.clock() + 3
        while os.clock() < cloneTimeout do
            newChar = LocalPlayer.Character
            if newChar then
                newHRP = newChar:FindFirstChild("HumanoidRootPart")
                if newHRP and (newHRP.Position - posBeforeClone).Magnitude > 0.3 then
                    break
                end
            end
            task.wait()
        end
        if not newChar then newChar = LocalPlayer.CharacterAdded:Wait() end
        newHRP = newChar and newChar:WaitForChild("HumanoidRootPart", 3)
        newHumanoid = newChar and newChar:WaitForChild("Humanoid", 3)
        local distMoved = newHRP and (newHRP.Position - posBeforeClone).Magnitude or 0
        if distMoved < 0.3 or not newHRP or not newHumanoid then
            State.isTpMoving = false
            isTpMoving = State.isTpMoving
            return
        end

        local inPlotRadius = false
        local plotsFolder = Workspace:FindFirstChild("Plots")
        if plotsFolder then
            local pos = newHRP.Position
            for _, plot in ipairs(plotsFolder:GetChildren()) do
                pcall(function()
                    local plotPos = plot:GetPivot().Position
                    local xDist = math.abs(pos.X - plotPos.X)
                    local zDist = math.abs(pos.Z - plotPos.Z)
                    if xDist < 23 and zDist < 23 then
                        inPlotRadius = true
                    end
                end)
                if inPlotRadius then break end
            end
        end

        if inPlotRadius then
            task.wait(0.2)
            pcall(function()
                local bp = LocalPlayer:FindFirstChild("Backpack")
                if bp then
                    local c = bp:FindFirstChild(Config.TpSettings.Tool or "Flying Carpet")
                    if c then newHumanoid:EquipTool(c) end
                end
            end)

            local itemPos = targetPart.Position
            local itemHeight = itemPos.Y
            local targetY = newHRP.Position.Y
            if itemHeight > 23.15 then
                targetY = 21
            elseif itemHeight >= 11 and itemHeight <= 23.15 then
                targetY = 14.5
            elseif itemHeight >= -6.9 and itemHeight <= 8.9 then
                targetY = -4
            end

            newHRP.AssemblyLinearVelocity = Vector3.zero
            newHRP.AssemblyAngularVelocity = Vector3.zero
            newHRP.CFrame = CFrame.new(itemPos.X, targetY, itemPos.Z)
            newHRP.AssemblyLinearVelocity = Vector3.zero
            newHRP.AssemblyAngularVelocity = Vector3.zero

            if itemHeight > 23.15 then
                task.wait(0.05)
                if _G.enableFloat then
                    pcall(_G.enableFloat)
                end
            end
        end
    end
    
    State.isTpMoving = false
    isTpMoving = State.isTpMoving
end

local resetFlyingItems = { "Flying Carpet", "Cupid's Wings", "Broom" }

local function resetFindAndEquipFlying(character)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local equipped = humanoid:FindFirstChildOfClass("Tool")
    for _, itemName in ipairs(resetFlyingItems) do
        local item = backpack:FindFirstChild(itemName)
        if item and (item:IsA("Tool") or item:IsA("HopperBin")) then
            if equipped then equipped.Parent = backpack end
            humanoid:EquipTool(item)
            return
        end
    end
end


local function executeReset()
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not (humanoid and root) then return end
    resetFindAndEquipFlying(character)
    root.CFrame = CFrame.new(0, 5000, 0)
    _G.AntiDieDisabled = true
    humanoid.Health = 0
    LocalPlayer.CharacterAdded:Wait()
    _G.AntiDieDisabled = false
end

task.spawn(function()
    local balloonPhrase = 'ran "balloon" on you'
    while true do
        task.wait(1)
        if not Config.AutoResetOnBalloon then continue end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
            if txt and string.find(txt, balloonPhrase) then
                executeReset()
                break
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if not Config.AutoKickOnSteal then continue end
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            local txt = (gui:IsA("TextLabel") or gui:IsA("TextButton")) and gui.Text
            if txt and string.find(txt, "You stole") then
                kickPlayer()
                return
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    local tpKey = Enum.KeyCode[Config.TpSettings.TpKey] or Enum.KeyCode.T
    local cloneKey = Enum.KeyCode[Config.TpSettings.CloneKey] or Enum.KeyCode.V

    if input.KeyCode == tpKey then
        runAutoSnipe()
    end

    if input.KeyCode == cloneKey then
        task.spawn(instantClone)
    end
    
    if input.KeyCode == (Enum.KeyCode[Config.TpSettings.CarpetSpeedKey] or Enum.KeyCode.Q) then
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        if _carpetStatusLabel then
            _carpetStatusLabel.Text = carpetSpeedEnabled and "ON" or "OFF"
            _carpetStatusLabel.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.Error
        end
        ShowNotification("CARPET SPEED", carpetSpeedEnabled and ("ON  |  "..Config.TpSettings.Tool.."  |  140") or "OFF")
    end

    if input.KeyCode == (Enum.KeyCode[Config.StealSpeedKey] or Enum.KeyCode.Z) then
        if SharedState.StealSpeedToggleFunc then
            SharedState.StealSpeedToggleFunc()
        end
    end

    if input.KeyCode == (Enum.KeyCode[Config.ResetKey] or Enum.KeyCode.X) then
        executeReset()
    end
    
    if pcall(function() return input.KeyCode == (Enum.KeyCode[Config.RagdollSelfKey] or Enum.KeyCode.R) end) and input.KeyCode == (Enum.KeyCode[Config.RagdollSelfKey] or Enum.KeyCode.R) then
        task.spawn(function()
            if _G.runAdminCommand then
                if _G.runAdminCommand(LocalPlayer, "ragdoll") then
                    ShowNotification("RAGDOLL SELF", "Triggered")
                else
                    ShowNotification("RAGDOLL SELF", "Failed")
                end
            else
                ShowNotification("RAGDOLL SELF", "Function not available")
            end
        end)
    end

end)

local settingsGui = UI.settingsGui

if IS_MOBILE then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "XiMobileControls"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = PlayerGui

    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(0, 50, 0, 260)
    controlsFrame.Position = UDim2.new(1, -60, 0.5, -130)
    controlsFrame.BackgroundColor3 = Theme.Background
    controlsFrame.BackgroundTransparency = 0.2
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = mobileGui

    ApplyViewportUIScale(controlsFrame, 50, 260, 0.6, 1)

    Instance.new("UICorner", controlsFrame).CornerRadius = UDim.new(0, 4)
    local cStroke = Instance.new("UIStroke", controlsFrame)
    cStroke.Color = Theme.Accent1
    cStroke.Thickness = 1.5
    cStroke.Transparency = 0.4

    MakeDraggable(controlsFrame, controlsFrame, "MobileControls")

    local layout = Instance.new("UIListLayout", controlsFrame)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local function createMobBtn(text, color, layoutOrder, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 40)
        btn.BackgroundColor3 = Theme.SurfaceHighlight
        btn.Text = text
        btn.TextColor3 = Theme.TextPrimary
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 14
        btn.LayoutOrder = layoutOrder
        btn.Parent = mobileGui 
        
        local posKey = "MobileBtn_" .. text
        if Config.Positions[posKey] then
            btn.Position = UDim2.new(Config.Positions[posKey].X, 0, Config.Positions[posKey].Y, 0)
        else
            local angle = (layoutOrder - 1) * (math.pi * 2 / 5) - math.pi/2
            local radius = 60
            btn.Position = UDim2.new(0.5, math.cos(angle) * radius - 20, 0.5, math.sin(angle) * radius - 20)
        end

        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = color
        stroke.Thickness = 1
        stroke.Transparency = 1

        MakeDraggable(btn, btn, "MobileBtn_" .. text)

        btn.MouseButton1Click:Connect(function()
            local oldColor = btn.BackgroundColor3
            btn.BackgroundColor3 = color
            task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
            callback(btn)
        end)
        return btn
    end

    createMobBtn("TP", Theme.Accent1, 1, function()
        
        if SharedState.ForcePrioritySelection then
            SharedState.ForcePrioritySelection()
            task.wait(0.1) 
        end
        runAutoSnipe()
        ShowNotification("MOBILE", "Teleporting...")
    end)

    createMobBtn("CL", Theme.Accent2, 2, function()
        instantClone()
        ShowNotification("MOBILE", "Cloning...")
    end)

    createMobBtn("SP", Theme.Success, 3, function(self)
        carpetSpeedEnabled = not carpetSpeedEnabled
        setCarpetSpeed(carpetSpeedEnabled)
        self.TextColor3 = carpetSpeedEnabled and Theme.Success or Theme.TextPrimary
        ShowNotification("MOBILE", carpetSpeedEnabled and "Speed ON" or "Speed OFF")
    end)

    createMobBtn("IV", Color3.fromRGB(255, 50, 50), 4, function(self)
        if _G.toggleInvisibleSteal then
            _G.toggleInvisibleSteal()
            task.delay(0.1, function()
                local isOn = _G.invisibleStealEnabled
                self.TextColor3 = isOn and Color3.fromRGB(255, 0, 0) or Theme.TextPrimary
                ShowNotification("MOBILE", isOn and "Invis ON" or "Invis OFF")
            end)
        end
    end)

    createMobBtn("UI", Color3.fromRGB(255, 255, 255), 5, function()
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = not asUI.Enabled end

        local adUI = PlayerGui:FindFirstChild("AdminPanel")
        if adUI then adUI.Enabled = not adUI.Enabled end
    end)

    local resetBtn = Instance.new("TextButton")
    resetBtn.Name = "MobileResetButton"
    resetBtn.Size = UDim2.new(0, 42, 0, 42)
    resetBtn.Position = UDim2.new(1, -58, 1, -105)
    resetBtn.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    resetBtn.AutoButtonColor = false
    resetBtn.Text = "🔧"
    resetBtn.Font = Enum.Font.GothamMedium
    resetBtn.TextSize = 20
    resetBtn.TextColor3 = Color3.new(0, 0, 0)
    resetBtn.Parent = mobileGui
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(1, 0)
    local resetStroke = Instance.new("UIStroke", resetBtn)
    resetStroke.Color = Color3.fromRGB(255, 100, 0)
    resetStroke.Thickness = 1.5
    resetStroke.Transparency = 0.25

    MakeDraggable(resetBtn, resetBtn)

    resetBtn.MouseButton1Click:Connect(function()
        Config.Positions = {
            AdminPanel = {X = 0.1859375, Y = 0.5767123526556385}, 
            StealSpeed = {X = 0.02, Y = 0.18}, 
            Settings = {X = 0.834375, Y = 0.43590998043052839}, 
            InvisPanel = {X = 0.8578125, Y = 0.17260276361454258}, 
            AutoSteal = {X = 0.02, Y = 0.35}, 
            MobileControls = {X = 0.9, Y = 0.4},
            MobileBtn_TP = {X = 0.5, Y = 0.4},
            MobileBtn_CL = {X = 0.5, Y = 0.4},
            MobileBtn_SP = {X = 0.5, Y = 0.4},
            MobileBtn_IV = {X = 0.5, Y = 0.4},
            MobileBtn_UI = {X = 0.5, Y = 0.4},
        }
        Config.MobileGuiScale = 0.5
        SaveConfig()
        
        if SharedState.RefreshMobileScale then SharedState.RefreshMobileScale() end
        
        if mobileGui then
            mobileGui.Position = UDim2.new(Config.Positions.MobileControls.X, 0, Config.Positions.MobileControls.Y, 0)
        end
        
        ShowNotification("RESET", "All GUI positions and scale reset")
    end)

    local openBtn = Instance.new("TextButton")
    openBtn.Name = "MobileSettingsButton"
    openBtn.Size = UDim2.new(0, 42, 0, 42)
    openBtn.Position = UDim2.new(1, -58, 1, -58)
    openBtn.BackgroundColor3 = Theme.Accent1
    openBtn.AutoButtonColor = false
    openBtn.Text = "⚙"
    openBtn.Font = Enum.Font.GothamMedium
    openBtn.TextSize = 20
    openBtn.TextColor3 = Color3.new(0, 0, 0)
    openBtn.Parent = mobileGui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(1, 0)
    local openStroke = Instance.new("UIStroke", openBtn)
    openStroke.Color = Theme.Accent2
    openStroke.Thickness = 1.5
    openStroke.Transparency = 0.25

    MakeDraggable(openBtn, openBtn)

    openBtn.MouseButton1Click:Connect(function()
        if settingsGui then
            settingsGui.Enabled = not settingsGui.Enabled
        end
        if SharedState.RefreshMobileScale then
            SharedState.RefreshMobileScale()
        end
    end)
end

settingsGui = Instance.new("ScreenGui")
settingsGui.Name = "SettingsUI"; settingsGui.ResetOnSpawn = false
settingsGui.Parent = PlayerGui; settingsGui.Enabled = false

local sFrame = Instance.new("Frame")
sFrame.Size = UDim2.new(0, 440, 0, 480)
sFrame.Position = UDim2.new(Config.Positions.Settings.X, 0, Config.Positions.Settings.Y, 0)
sFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
sFrame.BackgroundTransparency = 0.08
sFrame.BorderSizePixel = 0
sFrame.ClipsDescendants = true
sFrame.Parent = settingsGui

ApplyViewportUIScale(sFrame, 440, 480, 0.45, 0.85)
AddMobileMinimize(sFrame, "SETTINGS")

local corner = Instance.new("UICorner", sFrame)
corner.CornerRadius = UDim.new(0, 12)

local backgroundGradient = Instance.new("UIGradient", sFrame)
backgroundGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 12))
})
backgroundGradient.Rotation = 90

local borderStroke = Instance.new("UIStroke", sFrame)
borderStroke.Color = Color3.fromRGB(55, 55, 70)
borderStroke.Thickness = 1
borderStroke.Transparency = 0.5

local innerGlow = Instance.new("Frame", sFrame)
innerGlow.Size = UDim2.new(1, -4, 1, -4)
innerGlow.Position = UDim2.new(0, 2, 0, 2)
innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
innerGlow.BackgroundTransparency = 0.96
innerGlow.BorderSizePixel = 0
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)

local _ab = Instance.new("Frame", settingsGui)
_ab.BackgroundTransparency = 1
_ab.BorderSizePixel = 0
_ab.ZIndex = 100
Instance.new("UICorner", _ab).CornerRadius = UDim.new(0, 12)
local sStroke = Instance.new("UIStroke", _ab)
sStroke.Color = Color3.fromRGB(70, 70, 80)
sStroke.Thickness = 1
sStroke.Transparency = 0.5
local function _absync() _ab.Size = sFrame.Size; _ab.Position = sFrame.Position; _ab.Visible = sFrame.Visible end
_absync(); sFrame:GetPropertyChangedSignal("Size"):Connect(_absync); sFrame:GetPropertyChangedSignal("Position"):Connect(_absync); sFrame:GetPropertyChangedSignal("Visible"):Connect(_absync)

local accentBar = Instance.new("Frame", sFrame)
accentBar.Size = UDim2.new(1, 0, 0, 3)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 5
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 12)

local sHeader = Instance.new("Frame", sFrame)
sHeader.Size = UDim2.new(1, 0, 0, 48)
sHeader.Position = UDim2.new(0, 0, 0, 3)
sHeader.BackgroundTransparency = 1
MakeDraggable(sHeader, sFrame, "Settings")

do
    local _rh = Instance.new("TextButton", sHeader)
    _rh.Size = UDim2.new(0, 22, 0, 22)
    _rh.Position = UDim2.new(1, -28, 0.5, -11)
    _rh.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    _rh.Text = "↕"
    _rh.Font = Enum.Font.GothamMedium
    _rh.TextSize = 11
    _rh.TextColor3 = Color3.fromRGB(180, 180, 210)
    _rh.ZIndex = 10
    Instance.new("UICorner", _rh).CornerRadius = UDim.new(1, 0)
    MakeResizable(_rh, sFrame, 380, 640)
end

local sTitle = Instance.new("TextLabel", sHeader)
sTitle.Size = UDim2.new(1, -20, 1, 0)
sTitle.Position = UDim2.new(0, 16, 0, 0)
sTitle.BackgroundTransparency = 1
sTitle.Text = "SETTINGS"
sTitle.Font = Enum.Font.GothamBold
sTitle.TextSize = 16
sTitle.TextColor3 = Color3.fromRGB(210, 210, 230)
sTitle.TextXAlignment = Enum.TextXAlignment.Left

local headerSep = Instance.new("Frame", sFrame)
headerSep.Size = UDim2.new(1, -24, 0, 1)
headerSep.Position = UDim2.new(0, 12, 0, 52)
headerSep.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
headerSep.BorderSizePixel = 0

local sList = Instance.new("ScrollingFrame", sFrame)
sList.Size = UDim2.new(1, -24, 1, -100)
sList.Position = UDim2.new(0, 12, 0, 102)
sList.BackgroundTransparency = 1
sList.BorderSizePixel = 0
sList.ScrollBarThickness = 4
sList.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 70)

local sLayout = Instance.new("UIListLayout", sList)
sLayout.Padding = UDim.new(0, 8)
sLayout.SortOrder = Enum.SortOrder.LayoutOrder

local tabBtns = {}
local tabContainers = {}
local activeTabName = "General"
local curTabContainer
local updateSettingsCanvasSize

local function setActiveTab(name)
    activeTabName = name
    curTabContainer = tabContainers[name]
    for n, c in pairs(tabContainers) do 
        c.Visible = (n == name) 
    end
    for n, b in pairs(tabBtns) do
        if n == name then
            b.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
            b.TextColor3 = Color3.fromRGB(8, 8, 12)
        else
            b.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
            b.TextColor3 = Color3.fromRGB(180, 180, 210)
        end
    end
    task.defer(function() 
        if updateSettingsCanvasSize then 
            updateSettingsCanvasSize() 
        end 
    end)
end

do
    local tabBar = Instance.new("Frame", sFrame)
    tabBar.Size = UDim2.new(1, -24, 0, 32)
    tabBar.Position = UDim2.new(0, 12, 0, 58)
    tabBar.BackgroundTransparency = 1
    local tbl = Instance.new("UIListLayout", tabBar)
    tbl.FillDirection = Enum.FillDirection.Horizontal
    tbl.Padding = UDim.new(0, 6)
    tbl.SortOrder = Enum.SortOrder.LayoutOrder
    local tabNames = {"General", "Auto TP", "Carpet", "Movement", "ESP", "Auto Steal"}
    for i, tName in ipairs(tabNames) do
        local tb = Instance.new("TextButton", tabBar)
        tb.Size = UDim2.new(0, 65, 1, 0)
        tb.BackgroundColor3 = (i == 1) and Color3.fromRGB(180, 180, 210) or Color3.fromRGB(28, 28, 36)
        tb.Text = tName
        tb.Font = Enum.Font.GothamMedium
        tb.TextSize = 10
        tb.TextColor3 = (i == 1) and Color3.fromRGB(8, 8, 12) or Color3.fromRGB(180, 180, 210)
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
        tb.MouseButton1Click:Connect(function() 
            setActiveTab(tName) 
        end)
        tabBtns[tName] = tb
        local cont = Instance.new("Frame", sList)
        cont.Size = UDim2.new(1, 0, 0, 0)
        cont.AutomaticSize = Enum.AutomaticSize.Y
        cont.BackgroundTransparency = 1
        cont.Visible = (i == 1)
        local cl = Instance.new("UIListLayout", cont)
        cl.Padding = UDim.new(0, 8)
        cl.SortOrder = Enum.SortOrder.LayoutOrder
        tabContainers[tName] = cont
    end
end

local function CreateToggleSwitch(parent, initialState, callback)
    local sw = Instance.new("Frame")
    sw.Size = UDim2.new(0, 44, 0, 22)
    sw.Position = UDim2.new(1, -54, 0.5, -11)
    sw.BackgroundColor3 = initialState and Color3.fromRGB(180, 180, 210) or Color3.fromRGB(28, 28, 36)
    Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
    sw.Parent = parent
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = initialState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    dot.BackgroundColor3 = Color3.fromRGB(220, 220, 240)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    dot.Parent = sw
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = sw
    local isOn = initialState
    local function SetState(s)
        isOn = s
        local tp = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        local tc = isOn and Color3.fromRGB(180, 180, 210) or Color3.fromRGB(28, 28, 36)
        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = tp}):Play()
        TweenService:Create(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = tc}):Play()
    end
    btn.MouseButton1Click:Connect(function() callback(not isOn, SetState) end)
    return {Set = SetState, Container = sw}
end

local function CreateRow(text, height)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, height or 34)
    row.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    row.BackgroundTransparency = 0.5
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextColor3 = Color3.fromRGB(210, 210, 230)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    row.Parent = curTabContainer
    return row
end

local function CreateSectionHeader(text)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = curTabContainer
    
    local accent = Instance.new("Frame", row)
    accent.Size = UDim2.new(0, 3, 0, 14)
    accent.Position = UDim2.new(0, 0, 0.5, -7)
    accent.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -16, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(140, 140, 160)
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local line = Instance.new("Frame", row)
    line.Size = UDim2.new(1, -100, 0, 1)
    line.Position = UDim2.new(0, 85, 0.5, 0)
    line.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
    line.BackgroundTransparency = 0.7
    line.BorderSizePixel = 0
    
    return row
end

local espToggleRef = {enabled=true, setFn=nil}
local playerESPToggleRef = {setFn=nil}
do 
curTabContainer = tabContainers["Auto TP"]
local rAutoTPLoad = CreateRow("Auto TP on Script Load")
CreateToggleSwitch(rAutoTPLoad, Config.TpSettings.TpOnLoad, function(ns, set)
    set(ns); Config.TpSettings.TpOnLoad = ns; SaveConfig()
    ShowNotification("AUTO TP ON LOAD", ns and "ENABLED" or "DISABLED")
end)
local rAutoSnipeOnReset = CreateRow("Auto TP On Reset")
CreateToggleSwitch(rAutoSnipeOnReset, Config.AutoSnipeOnReset or false, function(ns, set)
    set(ns)
    Config.AutoTpOnReset = ns
    SaveConfig()
    ShowNotification("AUTO SNIPE ON RESET", ns and "ENABLED" or "DISABLED")
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Config.AutoTpOnReset then
        runAutoSnipe()
    end
end)


local rMinGen = CreateRow("Min Gen for Auto TP")
local minGenBox = Instance.new("TextBox", rMinGen)
minGenBox.Size = UDim2.new(0, 100, 0, 24)
minGenBox.Position = UDim2.new(1, -110, 0.5, -12)
minGenBox.BackgroundColor3 = Theme.SurfaceHighlight
minGenBox.Text = tostring(Config.TpSettings.MinGenForTp or "")
minGenBox.Font = Enum.Font.GothamMedium
minGenBox.TextSize = 11
minGenBox.TextColor3 = Theme.TextPrimary
minGenBox.PlaceholderText = "e.g. 5k, 1m, 1b"
Instance.new("UICorner", minGenBox).CornerRadius = UDim.new(0, 4)
minGenBox.FocusLost:Connect(function()
    local raw = minGenBox.Text:gsub("%s", "")
    Config.TpSettings.MinGenForTp = (raw == "" and "" or raw)
    SaveConfig()
    ShowNotification("MIN GEN FOR TP", Config.TpSettings.MinGenForTp == "" and "No minimum" or "Min: " .. (Config.TpSettings.MinGenForTp or ""))
end)

curTabContainer = tabContainers["Auto Steal"]
local rAutoStealMinGen = CreateRow("Auto Steal Min Gen")
local autoStealMinGenBox = Instance.new("TextBox", rAutoStealMinGen)
autoStealMinGenBox.Size = UDim2.new(0, 100, 0, 24)
autoStealMinGenBox.Position = UDim2.new(1, -110, 0.5, -12)
autoStealMinGenBox.BackgroundColor3 = Theme.SurfaceHighlight
autoStealMinGenBox.Text = tostring(Config.AutoStealMinGen or "")
autoStealMinGenBox.Font = Enum.Font.GothamMedium
autoStealMinGenBox.TextSize = 11
autoStealMinGenBox.TextColor3 = Theme.TextPrimary
autoStealMinGenBox.PlaceholderText = "e.g. 5k, 1m, 1b"
Instance.new("UICorner", autoStealMinGenBox).CornerRadius = UDim.new(0, 4)

autoStealMinGenBox.FocusLost:Connect(function()
    local raw = autoStealMinGenBox.Text:gsub("%s", "")
    Config.AutoStealMinGen = (raw == "" and "" or raw)
    SaveConfig()
    ShowNotification("AUTO STEAL MIN GEN", Config.AutoStealMinGen == "" and "No minimum" or "Min: " .. (Config.AutoStealMinGen or ""))
    if SharedState and SharedState.ListNeedsRedraw ~= nil then
        SharedState.ListNeedsRedraw = true
    end
end)

curTabContainer = tabContainers["ESP"]
local rFPS = CreateRow("FPS Boost")
CreateToggleSwitch(rFPS, Config.FPSBoost, function(ns, set)
    set(ns); setFPSBoost(ns)
    ShowNotification("FPS BOOST", ns and "ENABLED" or "DISABLED")
end)

local rTrace = CreateRow("Tracer Best Brainrot")
CreateToggleSwitch(rTrace, Config.TracerEnabled, function(ns, set)
    set(ns); Config.TracerEnabled = ns; SaveConfig()
    ShowNotification("TRACER", ns and "ENABLED" or "DISABLED")
end)

local rLineToBase = CreateRow("Line to base")
CreateToggleSwitch(rLineToBase, Config.LineToBase, function(ns, set)
    set(ns); Config.LineToBase = ns; SaveConfig()
    if not ns and _G.resetPlotBeam then pcall(_G.resetPlotBeam) end
    ShowNotification("LINE TO BASE", ns and "ENABLED" or "DISABLED")
end)

local rXray = CreateRow("X-Ray")
CreateToggleSwitch(rXray, Config.XrayEnabled, function(ns, set)
    set(ns); Config.XrayEnabled = ns; if ns then enableXray() else disableXray() end; SaveConfig()
    ShowNotification("X-RAY", ns and "ENABLED" or "DISABLED")
end)

curTabContainer = tabContainers["Auto TP"]
local toolOptions = {"Flying Carpet", "Cupid's Wings", "Santa's Sleigh", "Witch's Broom"}
local toolSwitches = {}
for _, toolName in ipairs(toolOptions) do
    local r = CreateRow(toolName)
    local ts = CreateToggleSwitch(r, Config.TpSettings.Tool==toolName, function(rs, set)
        if rs then
            Config.TpSettings.Tool=toolName; SaveConfig(); set(true)
            for n, sw in pairs(toolSwitches) do if n~=toolName then sw.Set(false) end end
            ShowNotification("TP TOOL", toolName)
        else
            set(Config.TpSettings.Tool==toolName)
        end
    end)
    toolSwitches[toolName] = ts
end

local rSpeed = CreateRow("Teleport Delay (1=Fast)")
local speedCont = Instance.new("Frame", rSpeed)
speedCont.Size = UDim2.new(0,100,0,24); speedCont.Position = UDim2.new(1,-110,0.5,-12); speedCont.BackgroundTransparency=1
local speedBtns = {}
for i = 1, 4 do
    local b = Instance.new("TextButton", speedCont)
    b.Size = UDim2.new(0.22,0,1,0); b.Position = UDim2.new((i-1)*0.26,0,0,0)
    local act = Config.TpSettings.Speed==i
    b.BackgroundColor3 = act and Theme.Accent1 or Theme.SurfaceHighlight
    b.Text = tostring(i); b.TextColor3 = act and Color3.new(0,0,0) or Theme.TextPrimary
    b.Font = Enum.Font.GothamMedium; b.TextSize = 12
    Instance.new("UICorner",b).CornerRadius = UDim.new(1, 0)
    b.MouseButton1Click:Connect(function()
        Config.TpSettings.Speed=i; SaveConfig()
        for idx, btn in ipairs(speedBtns) do
            local a=(idx==i); btn.BackgroundColor3=a and Theme.Accent1 or Theme.SurfaceHighlight
            btn.TextColor3=a and Color3.new(0,0,0) or Theme.TextPrimary
        end
        ShowNotification("TP SPEED", "Set to " .. tostring(i))
    end)
    table.insert(speedBtns,b)
end

local rBind = CreateRow("TP Keybind")
local bBind = Instance.new("TextButton", rBind)
bBind.Size=UDim2.new(0,60,0,24); bBind.Position=UDim2.new(1,-70,0.5,-12)
bBind.BackgroundColor3=Theme.SurfaceHighlight; bBind.Text=Config.TpSettings.TpKey
bBind.Font=Enum.Font.GothamMedium; bBind.TextColor3=Theme.TextPrimary; bBind.TextSize=12
Instance.new("UICorner",bBind).CornerRadius=UDim.new(1, 0)
bBind.MouseButton1Click:Connect(function()
    bBind.Text="..."; bBind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.TpKey=inp.KeyCode.Name; bBind.Text=inp.KeyCode.Name
            bBind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("TP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rBindClone = CreateRow("Auto Clone Keybind")
local bBindClone = Instance.new("TextButton", rBindClone)
bBindClone.Size=UDim2.new(0,60,0,24); bBindClone.Position=UDim2.new(1,-70,0.5,-12)
bBindClone.BackgroundColor3=Theme.SurfaceHighlight; bBindClone.Text=Config.TpSettings.CloneKey
bBindClone.Font=Enum.Font.GothamMedium; bBindClone.TextColor3=Theme.TextPrimary; bBindClone.TextSize=12
Instance.new("UICorner",bBindClone).CornerRadius=UDim.new(1, 0)
bBindClone.MouseButton1Click:Connect(function()
    bBindClone.Text="..."; bBindClone.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CloneKey=inp.KeyCode.Name; bBindClone.Text=inp.KeyCode.Name
            bBindClone.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CLONE KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

curTabContainer = tabContainers["Carpet"]
local rCarpetBind = CreateRow("Carpet Speed Keybind")
local bCarpet = Instance.new("TextButton", rCarpetBind)
bCarpet.Size=UDim2.new(0,60,0,24); bCarpet.Position=UDim2.new(1,-70,0.5,-12)
bCarpet.BackgroundColor3=Theme.SurfaceHighlight; bCarpet.Text=Config.TpSettings.CarpetSpeedKey
bCarpet.Font=Enum.Font.GothamMedium; bCarpet.TextColor3=Theme.TextPrimary; bCarpet.TextSize=12
Instance.new("UICorner",bCarpet).CornerRadius=UDim.new(1, 0)
bCarpet.MouseButton1Click:Connect(function()
    bCarpet.Text="..."; bCarpet.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.TpSettings.CarpetSpeedKey=inp.KeyCode.Name; bCarpet.Text=inp.KeyCode.Name
            bCarpet.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CARPET SPEED KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rRagdollSelf = CreateRow("Ragdoll Self Keybind")
local bRagdollSelf = Instance.new("TextButton", rRagdollSelf)
bRagdollSelf.Size=UDim2.new(0,60,0,24); bRagdollSelf.Position=UDim2.new(1,-70,0.5,-12)
bRagdollSelf.BackgroundColor3=Theme.SurfaceHighlight; bRagdollSelf.Text=Config.RagdollSelfKey ~= "" and Config.RagdollSelfKey or "NONE"
bRagdollSelf.Font=Enum.Font.GothamMedium; bRagdollSelf.TextColor3=Theme.TextPrimary; bRagdollSelf.TextSize=12
Instance.new("UICorner",bRagdollSelf).CornerRadius=UDim.new(1, 0)
bRagdollSelf.MouseButton1Click:Connect(function()
    bRagdollSelf.Text="..."; bRagdollSelf.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.RagdollSelfKey=inp.KeyCode.Name; bRagdollSelf.Text=inp.KeyCode.Name
            bRagdollSelf.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("RAGDOLL SELF KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rCarpetStatus = CreateRow("Carpet Speed Status")
local carpetStatusLbl = Instance.new("TextLabel", rCarpetStatus)
carpetStatusLbl.Size=UDim2.new(0,50,0,20); carpetStatusLbl.Position=UDim2.new(1,-60,0.5,-10)
carpetStatusLbl.BackgroundTransparency=1
carpetStatusLbl.Text=carpetSpeedEnabled and "ON" or "OFF"
carpetStatusLbl.TextColor3=carpetSpeedEnabled and Theme.Success or Theme.Error
carpetStatusLbl.Font=Enum.Font.GothamMedium; carpetStatusLbl.TextSize=13
carpetStatusLbl.TextXAlignment=Enum.TextXAlignment.Right
_carpetStatusLabel = carpetStatusLbl

curTabContainer = tabContainers["Movement"]
local rInfJump = CreateRow("Infinite Jump")
CreateToggleSwitch(rInfJump, infiniteJumpEnabled, function(ns, set)
    set(ns); setInfiniteJump(ns)
    ShowNotification("INFINITE JUMP", ns and "ENABLED" or "DISABLED")
end)

local rStealSpeedKey = CreateRow("Steal Speed Keybind")
local bStealSpeedKey = Instance.new("TextButton", rStealSpeedKey)
bStealSpeedKey.Size=UDim2.new(0,60,0,24); bStealSpeedKey.Position=UDim2.new(1,-70,0.5,-12)
bStealSpeedKey.BackgroundColor3=Theme.SurfaceHighlight; bStealSpeedKey.Text=Config.StealSpeedKey
bStealSpeedKey.Font=Enum.Font.GothamMedium; bStealSpeedKey.TextColor3=Theme.TextPrimary; bStealSpeedKey.TextSize=12
Instance.new("UICorner",bStealSpeedKey).CornerRadius=UDim.new(1, 0)
bStealSpeedKey.MouseButton1Click:Connect(function()
    bStealSpeedKey.Text="..."; bStealSpeedKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.StealSpeedKey=inp.KeyCode.Name; bStealSpeedKey.Text=inp.KeyCode.Name
            bStealSpeedKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("STEAL SPEED KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

pcall(function()
local rFloatKey = CreateRow("Float Keybind")
local bFloatKey = Instance.new("TextButton", rFloatKey)
bFloatKey.Size=UDim2.new(0,60,0,24); bFloatKey.Position=UDim2.new(1,-70,0.5,-12)
bFloatKey.BackgroundColor3=Theme.SurfaceHighlight; bFloatKey.Text=Config.FloatKey
bFloatKey.Font=Enum.Font.GothamMedium; bFloatKey.TextColor3=Theme.TextPrimary; bFloatKey.TextSize=12
Instance.new("UICorner",bFloatKey).CornerRadius=UDim.new(1, 0)
bFloatKey.MouseButton1Click:Connect(function()
    bFloatKey.Text="..."; bFloatKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.FloatKey=inp.KeyCode.Name; bFloatKey.Text=inp.KeyCode.Name
            bFloatKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("FLOAT KEYBIND", inp.KeyCode.Name)
        end
    end)
end)
end)
curTabContainer = tabContainers["Auto Steal"]
local rAutoUnlock = CreateRow("Auto Unlock on Steal")
CreateToggleSwitch(rAutoUnlock, Config.AutoUnlockOnSteal, function(ns, set)
    set(ns); Config.AutoUnlockOnSteal = ns; SaveConfig()
    ShowNotification("AUTO UNLOCK", ns and "ENABLED" or "DISABLED")
end)

local rShowUnlockHUD = CreateRow("Show Unlock Buttons HUD")
CreateToggleSwitch(rShowUnlockHUD, Config.ShowUnlockButtonsHUD, function(ns, set)
    set(ns); Config.ShowUnlockButtonsHUD = ns; SaveConfig()
    local hudGui = PlayerGui:FindFirstChild("XiStatusHUD")
    if hudGui then
        local main = hudGui:FindFirstChild("Main")
        local unlockContainer = main and main:FindFirstChild("UnlockButtonsContainer")
        if main and unlockContainer then
            unlockContainer.Visible = ns
            if ns then
                TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 500, 0, 100)
                }):Play()
            else
                TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 500, 0, 50)
                }):Play()
            end
        end
    end
end)

local rCooldownTracker = CreateRow("Show Cooldown Tracker")
CreateToggleSwitch(rCooldownTracker, Config.ShowCooldownTracker, function(ns, set)
    set(ns)
    Config.ShowCooldownTracker = ns
    SaveConfig()
    local trackerGui = PlayerGui:FindFirstChild("CooldownTracker")
    if trackerGui then
        trackerGui.Enabled = ns
    end
    ShowNotification("COOLDOWN TRACKER", ns and "ENABLED" or "DISABLED")
end)

curTabContainer = tabContainers["General"]
local arV1SetRef, arV2SetRef = {}, {}
local rAr = CreateRow("Anti-Ragdoll V1")
CreateToggleSwitch(rAr, Config.AntiRagdoll > 0, function(ns, set)
    arV1SetRef.fn = set
    if ns and Config.AntiRagdollV2 then
        set(false)
        ShowNotification("ANTI-RAGDOLL", "DISABLE V2 FIRST")
        return
    end
    set(ns)
    local mode = ns and 1 or 0
    Config.AntiRagdoll = mode
    if ns then
        Config.AntiRagdollV2 = false
        if arV2SetRef.fn then arV2SetRef.fn(false) end
    end
    SaveConfig()
    startAntiRagdoll(mode)
    if ns then startAntiRagdollV2(false) end
    ShowNotification("ANTI-RAGDOLL V1", ns and "ENABLED" or "DISABLED")
end)
local rArV2 = CreateRow("Anti-Ragdoll V2")
CreateToggleSwitch(rArV2, Config.AntiRagdollV2, function(ns, set)
    arV2SetRef.fn = set
    if ns and Config.AntiRagdoll > 0 then
        set(false)
        ShowNotification("ANTI-RAGDOLL", "DISABLE V1 FIRST")
        return
    end
    set(ns)
    Config.AntiRagdollV2 = ns
    if ns then
        Config.AntiRagdoll = 0
        SaveConfig()
        if arV1SetRef.fn then arV1SetRef.fn(false) end
        startAntiRagdoll(0)
        startAntiRagdollV2(true)
    else
        SaveConfig()
        startAntiRagdollV2(false)
    end
    ShowNotification("ANTI-RAGDOLL V2", ns and "ENABLED" or "DISABLED")
end)

curTabContainer = tabContainers["ESP"]
local rXray = CreateRow("Base X-Ray")
local xrayToggle = CreateToggleSwitch(rXray, xrayEnabled, function(ns, set)
    set(ns)
    if ns then
        enableXray()
        xrayDescConn = Workspace.DescendantAdded:Connect(function(obj)
            if xrayEnabled and obj:IsA("BasePart") and obj.Anchored and isBaseWall(obj) then
                originalTransparency[obj] = obj.LocalTransparencyModifier
                obj.LocalTransparencyModifier = 0.85
            end
        end)
    else
        disableXray()
    end
    Config.XrayEnabled = ns; SaveConfig()
    ShowNotification("BASE X-RAY", ns and "ENABLED" or "DISABLED")
end)
playerESPToggleRef = {setFn=nil}
local rPlayerEsp = CreateRow("Player ESP (Hides Names)")
CreateToggleSwitch(rPlayerEsp, Config.PlayerESP, function(ns, set)
    set(ns); Config.PlayerESP = ns; SaveConfig()
    if playerESPToggleRef.setFn then playerESPToggleRef.setFn(ns) end
    ShowNotification("PLAYER ESP", ns and "ENABLED" or "DISABLED")
end)

espToggleRef = {enabled=true, setFn=nil}
local rEsp = CreateRow("Brainrot ESP")
local espSettingsSwitch = CreateToggleSwitch(rEsp, Config.BrainrotESP, function(ns, set)
    set(ns); Config.BrainrotESP = ns; SaveConfig()
    if espToggleRef.setFn then espToggleRef.setFn(ns) end
    ShowNotification("BRAINROT ESP", ns and "ENABLED" or "DISABLED")
end)
local subspaceMineESPToggleRef = {setFn=nil}
local rSubspaceMineEsp = CreateRow("Subspace Mine Esp")
CreateToggleSwitch(rSubspaceMineEsp, Config.SubspaceMineESP, function(ns, set)
    set(ns); Config.SubspaceMineESP = ns; SaveConfig()
    if subspaceMineESPToggleRef.setFn then subspaceMineESPToggleRef.setFn(ns) end
    ShowNotification("SUBSPACE MINE ESP", ns and "ENABLED" or "DISABLED")
end)
local rDuelBaseESP = CreateRow("Duel Base ESP")
CreateToggleSwitch(rDuelBaseESP, Config.DuelBaseESP, function(ns, set)
    set(ns); Config.DuelBaseESP = ns; SaveConfig()
    ShowNotification("DUEL BASE ESP", ns and "ENABLED" or "DISABLED")
end)

curTabContainer = tabContainers["Auto Steal"]
local nearestToggleRef = {}
local highestToggleRef = {}
local priorityToggleRef = {}
local autoTPPriorityToggleRef = {setFn = nil}

local rDefaultNearest = CreateRow("Default To Nearest")
local nearestToggleSwitch = CreateToggleSwitch(rDefaultNearest, Config.DefaultToNearest, function(ns, set)
    if ns then
        Config.DefaultToNearest = true
        Config.DefaultToHighest = false
        Config.DefaultToPriority = false
        set(true)
        if highestToggleRef.setFn then highestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
        
        Config.AutoTPPriority = true
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(true)
        end
    else
        local otherDefaults = Config.DefaultToHighest or Config.DefaultToPriority
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToNearest = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO NEAREST", ns and "ENABLED" or "DISABLED")
end)
nearestToggleRef.setFn = nearestToggleSwitch.Set

local rDefaultHighest = CreateRow("Default To Highest")
local highestToggleSwitch = CreateToggleSwitch(rDefaultHighest, Config.DefaultToHighest, function(ns, set)
    if ns then
        Config.DefaultToNearest = false
        Config.DefaultToHighest = true
        Config.DefaultToPriority = false
        set(true)
        if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if priorityToggleRef.setFn then priorityToggleRef.setFn(false) end
        
        Config.AutoTPPriority = false
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(false)
        end
    else
        local otherDefaults = Config.DefaultToNearest or Config.DefaultToPriority
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToHighest = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO HIGHEST", ns and "ENABLED" or "DISABLED")
end)
highestToggleRef.setFn = highestToggleSwitch.Set

local rDefaultPriority = CreateRow("Default To Priority")
local priorityToggleSwitch = CreateToggleSwitch(rDefaultPriority, Config.DefaultToPriority, function(ns, set)
    if ns then
        Config.DefaultToNearest = false
        Config.DefaultToHighest = false
        Config.DefaultToPriority = true
        set(true)
        if nearestToggleRef.setFn then nearestToggleRef.setFn(false) end
        if highestToggleRef.setFn then highestToggleRef.setFn(false) end
        
        Config.AutoTPPriority = true
        if autoTPPriorityToggleRef and autoTPPriorityToggleRef.setFn then
            autoTPPriorityToggleRef.setFn(true)
        end
    else
        local otherDefaults = Config.DefaultToNearest or Config.DefaultToHighest
        if not otherDefaults then
            set(true)
            ShowNotification("DEFAULT MODE", "At least one default must be enabled")
            return
        end
        Config.DefaultToPriority = false
        set(false)
    end
    SaveConfig()
    ShowNotification("DEFAULT TO PRIORITY", ns and "ENABLED" or "DISABLED")
end)
priorityToggleRef.setFn = priorityToggleSwitch.Set

curTabContainer = tabContainers["Auto Steal"]
local rAutoInvis = CreateRow("Auto Invis During Steal")
CreateToggleSwitch(rAutoInvis, Config.AutoInvisDuringSteal, function(ns, set)
    set(ns); Config.AutoInvisDuringSteal = ns; _G.AutoInvisDuringSteal = ns; SaveConfig()
    ShowNotification("AUTO INVIS", ns and "ENABLED" or "DISABLED")
end)
curTabContainer = tabContainers["Auto TP"]
local rAutoTpFail = CreateRow("Auto TP on Failed Steal")
CreateToggleSwitch(rAutoTpFail, Config.AutoTpOnFailedSteal, function(ns, set)
    set(ns); Config.AutoTpOnFailedSteal = ns; SaveConfig()
    ShowNotification("AUTO TP ON FAILED STEAL", ns and "ENABLED" or "DISABLED")
end)
local rAutoTpPriority = CreateRow("Auto TP Priority Mode")
local autoTPPriorityToggleSwitch = CreateToggleSwitch(rAutoTpPriority, Config.AutoTPPriority, function(ns, set)
    set(ns); Config.AutoTPPriority = ns; SaveConfig()
    ShowNotification("AUTO TP PRIORITY", ns and "PRIORITY" or "HIGHEST")
end)
autoTPPriorityToggleRef.setFn = autoTPPriorityToggleSwitch.Set
curTabContainer = tabContainers["Auto Steal"]
local rAutoKick = CreateRow("Auto-Kick on Steal")
CreateToggleSwitch(rAutoKick, Config.AutoKickOnSteal, function(ns, set)
    set(ns); Config.AutoKickOnSteal = ns; SaveConfig()
    ShowNotification("AUTO-KICK ON STEAL", ns and "ENABLED" or "DISABLED")
end)

curTabContainer = tabContainers["General"]

local rResetKey = CreateRow("Reset")
local bResetKey = Instance.new("TextButton", rResetKey)
bResetKey.Size=UDim2.new(0,60,0,24); bResetKey.Position=UDim2.new(1,-70,0.5,-12)
bResetKey.BackgroundColor3=Theme.SurfaceHighlight; bResetKey.Text=Config.ResetKey
bResetKey.Font=Enum.Font.GothamMedium; bResetKey.TextColor3=Theme.TextPrimary; bResetKey.TextSize=12
Instance.new("UICorner",bResetKey).CornerRadius=UDim.new(1, 0)
bResetKey.MouseButton1Click:Connect(function()
    bResetKey.Text="..."; bResetKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ResetKey=inp.KeyCode.Name; bResetKey.Text=inp.KeyCode.Name
            bResetKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("RESET KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rAutoResetBalloon = CreateRow("Auto reset on balloon")
CreateToggleSwitch(rAutoResetBalloon, Config.AutoResetOnBalloon, function(ns, set)
    set(ns); Config.AutoResetOnBalloon = ns; SaveConfig()
    ShowNotification("AUTO RESET ON BALLOON", ns and "ENABLED" or "DISABLED")
end)

local rKickKey = CreateRow("Kick")
local bKickKey = Instance.new("TextButton", rKickKey)
bKickKey.Size=UDim2.new(0,60,0,24); bKickKey.Position=UDim2.new(1,-70,0.5,-12)
bKickKey.BackgroundColor3=Theme.SurfaceHighlight; bKickKey.Text=Config.KickKey ~= "" and Config.KickKey or "NONE"
bKickKey.Font=Enum.Font.GothamMedium; bKickKey.TextColor3=Theme.TextPrimary; bKickKey.TextSize=12
Instance.new("UICorner",bKickKey).CornerRadius=UDim.new(1, 0)
bKickKey.MouseButton1Click:Connect(function()
    bKickKey.Text="..."; bKickKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.KickKey=inp.KeyCode.Name; bKickKey.Text=inp.KeyCode.Name
            bKickKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("KICK KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rCleanErrors = CreateRow("Clean Error GUIs")
CreateToggleSwitch(rCleanErrors, Config.CleanErrorGUIs, function(ns, set)
    set(ns); Config.CleanErrorGUIs = ns; SaveConfig()
    ShowNotification("CLEAN ERROR GUIS", ns and "ENABLED" or "DISABLED")
end)


local rClickToAPSingle = CreateRow("Click To AP Single Command")
CreateToggleSwitch(rClickToAPSingle, Config.ClickToAPSingleCommand, function(ns, set)
    set(ns); Config.ClickToAPSingleCommand = ns; SaveConfig()
    ShowNotification("CLICK TO AP SINGLE", ns and "ENABLED" or "DISABLED")
end)
local rClickToAPKeybind = CreateRow("Click To AP Keybind")
local bClickToAPKeybind = Instance.new("TextButton", rClickToAPKeybind)
bClickToAPKeybind.Size=UDim2.new(0,60,0,24); bClickToAPKeybind.Position=UDim2.new(1,-65,0.5,-12)
bClickToAPKeybind.BackgroundColor3=Theme.SurfaceHighlight; bClickToAPKeybind.Text=Config.ClickToAPKeybind or "L"
bClickToAPKeybind.Font=Enum.Font.GothamMedium; bClickToAPKeybind.TextColor3=Theme.TextPrimary; bClickToAPKeybind.TextSize=12
Instance.new("UICorner",bClickToAPKeybind).CornerRadius=UDim.new(1, 0)
bClickToAPKeybind.MouseButton1Click:Connect(function()
    bClickToAPKeybind.Text="..."; bClickToAPKeybind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ClickToAPKeybind=inp.KeyCode.Name; bClickToAPKeybind.Text=inp.KeyCode.Name
            bClickToAPKeybind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("CLICK TO AP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)
local rProximityAPKeybind = CreateRow("Proximity AP Keybind")
local bProximityAPKeybind = Instance.new("TextButton", rProximityAPKeybind)
bProximityAPKeybind.Size=UDim2.new(0,60,0,24); bProximityAPKeybind.Position=UDim2.new(1,-70,0.5,-12)
bProximityAPKeybind.BackgroundColor3=Theme.SurfaceHighlight; bProximityAPKeybind.Text=Config.ProximityAPKeybind or "P"
bProximityAPKeybind.Font=Enum.Font.GothamMedium; bProximityAPKeybind.TextColor3=Theme.TextPrimary; bProximityAPKeybind.TextSize=12
Instance.new("UICorner",bProximityAPKeybind).CornerRadius=UDim.new(1, 0)
bProximityAPKeybind.MouseButton1Click:Connect(function()
    bProximityAPKeybind.Text="..."; bProximityAPKeybind.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ProximityAPKeybind=inp.KeyCode.Name; bProximityAPKeybind.Text=inp.KeyCode.Name
            bProximityAPKeybind.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("PROXIMITY AP KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rAlertsEnabled = CreateRow("Enable Alerts")
CreateToggleSwitch(rAlertsEnabled, Config.AlertsEnabled, function(ns, set)
    set(ns); Config.AlertsEnabled = ns; SaveConfig()
    ShowNotification("PRIORITY ALERTS", ns and "ENABLED" or "DISABLED")
end)
local rAlertSound = CreateRow("Alert Sound ID")
local soundBox = Instance.new("TextBox", rAlertSound)
soundBox.Size = UDim2.new(0, 180, 0, 24)
soundBox.Position = UDim2.new(1, -185, 0.5, -12)
soundBox.BackgroundColor3 = Theme.SurfaceHighlight
soundBox.Text = Config.AlertSoundID or "rbxassetid://6518811702"
soundBox.Font = Enum.Font.GothamMedium
soundBox.TextSize = 10
soundBox.TextColor3 = Theme.TextPrimary
soundBox.PlaceholderText = "Sound ID"
Instance.new("UICorner", soundBox).CornerRadius = UDim.new(0, 4)
soundBox.FocusLost:Connect(function()
    Config.AlertSoundID = soundBox.Text
    SaveConfig()
    ShowNotification("ALERT SOUND", "Updated")
end)

local rJoinerRow = CreateRow("Job ID Joiner")
CreateToggleSwitch(rJoinerRow, Config.ShowJobJoiner, function(ns, set)
    set(ns); Config.ShowJobJoiner = ns; SaveConfig()
    local gui = PlayerGui:FindFirstChild("XiJobJoiner")
    if gui then gui.Enabled = Config.ShowJobJoiner end
    ShowNotification("JOB ID JOINER", ns and "ENABLED" or "DISABLED")
end)
local rJoinerKey = CreateRow("Job Joiner Keybind")
local bJoinerKey = Instance.new("TextButton", rJoinerKey)
bJoinerKey.Size=UDim2.new(0,60,0,24); bJoinerKey.Position=UDim2.new(1,-70,0.5,-12)
bJoinerKey.BackgroundColor3=Theme.SurfaceHighlight; bJoinerKey.Text=Config.JobJoinerKey or "J"
bJoinerKey.Font=Enum.Font.GothamMedium; bJoinerKey.TextColor3=Theme.TextPrimary; bJoinerKey.TextSize=12
Instance.new("UICorner",bJoinerKey).CornerRadius=UDim.new(1, 0)
bJoinerKey.MouseButton1Click:Connect(function()
    bJoinerKey.Text="..."; bJoinerKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.JobJoinerKey=inp.KeyCode.Name; bJoinerKey.Text=inp.KeyCode.Name
            bJoinerKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("JOB JOINER KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rAntiBeeDisco = CreateRow("Anti-Bee & Anti-Disco")
CreateToggleSwitch(rAntiBeeDisco, Config.AntiBeeDisco, function(ns, set)
    set(ns); Config.AntiBeeDisco = ns; SaveConfig()
    if ns then
        if _G.ANTI_BEE_DISCO and _G.ANTI_BEE_DISCO.Enable then
            _G.ANTI_BEE_DISCO.Enable()
        end
    else
        if _G.ANTI_BEE_DISCO and _G.ANTI_BEE_DISCO.Disable then
            _G.ANTI_BEE_DISCO.Disable()
        end
    end
    ShowNotification("ANTI-BEE & DISCO", ns and "ENABLED" or "DISABLED")
end)


local rFOV = CreateRow("FOV")
local fovSliderBg = Instance.new("Frame", rFOV)
fovSliderBg.Size = UDim2.new(0, 140, 0, 5)
fovSliderBg.Position = UDim2.new(1, -200, 0.5, -2.5)
fovSliderBg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
Instance.new("UICorner", fovSliderBg).CornerRadius = UDim.new(1, 0)
local fovFill = Instance.new("Frame", fovSliderBg)
fovFill.BackgroundColor3 = Theme.Accent1
fovFill.Size = UDim2.new(0, 0, 1, 0)
Instance.new("UICorner", fovFill).CornerRadius = UDim.new(1, 0)
local fovKnob = Instance.new("Frame", fovSliderBg)
fovKnob.Size = UDim2.new(0, 12, 0, 12)
fovKnob.BackgroundColor3 = Theme.TextPrimary
fovKnob.AnchorPoint = Vector2.new(0.5, 0.5)
fovKnob.Position = UDim2.new(0, 0, 0.5, 0)
Instance.new("UICorner", fovKnob).CornerRadius = UDim.new(1, 0)
local fovKnobStroke = Instance.new("UIStroke", fovKnob)
fovKnobStroke.Color = Theme.Accent1
fovKnobStroke.Thickness = 1.5
fovKnobStroke.Transparency = 0.2
local fovValLbl = Instance.new("TextLabel", rFOV)
fovValLbl.Size = UDim2.new(0, 40, 0, 20)
fovValLbl.Position = UDim2.new(1, -50, 0.5, -10)
fovValLbl.BackgroundTransparency = 1
fovValLbl.Text = string.format("%.1f", Config.FOV)
fovValLbl.TextColor3 = Theme.TextPrimary
fovValLbl.Font = Enum.Font.GothamMedium
fovValLbl.TextSize = 13

local function updateFOVSlider(val)
    val = math.clamp(val, 30, 120)
    Config.FOV = val
    SaveConfig()
    fovValLbl.Text = string.format("%.1f", val)
    local pct = (val - 30) / 90
    fovFill.Size = UDim2.new(pct, 0, 1, 0)
    fovKnob.Position = UDim2.new(pct, 0, 0.5, 0)
    if Workspace.CurrentCamera then
        Workspace.CurrentCamera.FieldOfView = val
    end
    ShowNotification("FIELD OF VIEW", string.format("%.1f", val))
end
updateFOVSlider(Config.FOV)

local fovDragging = false
fovSliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fovDragging = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then fovDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if fovDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local x = i.Position.X
        local r = fovSliderBg.AbsolutePosition.X
        local w = fovSliderBg.AbsoluteSize.X
        local p = (x - r) / w
        updateFOVSlider(30 + (p * 90))
    end
end)

local rFOVReset = CreateRow("Reset FOV")
local bFOVReset = Instance.new("TextButton", rFOVReset)
bFOVReset.Size = UDim2.new(0, 60, 0, 24)
bFOVReset.Position = UDim2.new(1, -70, 0.5, -12)
bFOVReset.BackgroundColor3 = Theme.SurfaceHighlight
bFOVReset.Text = "Reset"
bFOVReset.Font = Enum.Font.GothamMedium
bFOVReset.TextColor3 = Theme.TextPrimary
bFOVReset.TextSize = 12
Instance.new("UICorner", bFOVReset).CornerRadius = UDim.new(1, 0)
bFOVReset.MouseButton1Click:Connect(function()
    updateFOVSlider(70)
    ShowNotification("FIELD OF VIEW", "Reset to 70")
end)

if not IS_MOBILE then
    local rMenu = CreateRow("Menu Toggle Key")
    local bMenu = Instance.new("TextButton", rMenu)
    bMenu.Size=UDim2.new(0,80,0,24); bMenu.Position=UDim2.new(1,-90,0.5,-12)
    bMenu.BackgroundColor3=Theme.SurfaceHighlight; bMenu.Text=Config.MenuKey
    bMenu.Font=Enum.Font.GothamMedium; bMenu.TextColor3=Theme.TextPrimary; bMenu.TextSize=12
    Instance.new("UICorner",bMenu).CornerRadius=UDim.new(1, 0)
    bMenu.MouseButton1Click:Connect(function()
        bMenu.Text="..."; bMenu.TextColor3=Theme.Accent1
        local con; con=UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                Config.MenuKey=inp.KeyCode.Name; bMenu.Text=inp.KeyCode.Name
                bMenu.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
                ShowNotification("MENU KEYBIND", inp.KeyCode.Name)
            end
        end)
    end)
else
    CreateRow("Menu Toggle: Touch Icon")
end

do local rLock = CreateRow("Lock UI")
CreateToggleSwitch(rLock, Config.UILocked, function(ns, set)
    set(ns); Config.UILocked = ns; SaveConfig()
    ShowNotification("UI LOCK", ns and "LOCKED" or "UNLOCKED")
end) end

local rRejoinKey = CreateRow("Rejoin Keybind")
local bRejoinKey = Instance.new("TextButton", rRejoinKey)
bRejoinKey.Size=UDim2.new(0,60,0,24); bRejoinKey.Position=UDim2.new(1,-70,0.5,-12)
bRejoinKey.BackgroundColor3=Theme.SurfaceHighlight; bRejoinKey.Text=Config.ReJoinKey or "NONE"
bRejoinKey.Font=Enum.Font.GothamMedium; bRejoinKey.TextColor3=Theme.TextPrimary; bRejoinKey.TextSize=12
Instance.new("UICorner",bRejoinKey).CornerRadius=UDim.new(1, 0)
bRejoinKey.MouseButton1Click:Connect(function()
    bRejoinKey.Text="..."; bRejoinKey.TextColor3=Theme.Accent1
    local con; con=UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.Keyboard then
            Config.ReJoinKey=inp.KeyCode.Name; bRejoinKey.Text=inp.KeyCode.Name
            bRejoinKey.TextColor3=Theme.TextPrimary; SaveConfig(); con:Disconnect()
            ShowNotification("REJOIN KEYBIND", inp.KeyCode.Name)
        end
    end)
end)

local rReset = CreateRow("Reset UI Positions")
local bReset = Instance.new("TextButton", rReset)
bReset.Size=UDim2.new(0,80,0,24); bReset.Position=UDim2.new(1,-90,0.5,-12)
bReset.BackgroundColor3=Theme.Error; bReset.Text="RESET"
bReset.Font=Enum.Font.GothamMedium; bReset.TextColor3=Theme.TextPrimary; bReset.TextSize=12
Instance.new("UICorner",bReset).CornerRadius=UDim.new(1, 0)
bReset.MouseButton1Click:Connect(function()
    Config.Positions = DefaultConfig.Positions
    SaveConfig()
    ShowNotification("UI RESET", "Positions restored")
    sFrame.Position = UDim2.new(DefaultConfig.Positions.Settings.X, 0, DefaultConfig.Positions.Settings.Y, 0)
    if PlayerGui:FindFirstChild("AutoStealUI") then
        PlayerGui.AutoStealUI.Frame.Position = UDim2.new(DefaultConfig.Positions.AutoSteal.X, 0, DefaultConfig.Positions.AutoSteal.Y, 0)
    end
    if PlayerGui:FindFirstChild("StealSpeedUI") then
        PlayerGui.StealSpeedUI.Frame.Position = UDim2.new(DefaultConfig.Positions.StealSpeed.X, 0, DefaultConfig.Positions.StealSpeed.Y, 0)
    end
    if PlayerGui:FindFirstChild("SyllinseAdminPanel") and PlayerGui.SyllinseAdminPanel:FindFirstChild("Frame") then
        PlayerGui.SyllinseAdminPanel.Frame.Position = UDim2.new(DefaultConfig.Positions.AdminPanel.X, 0, DefaultConfig.Positions.AdminPanel.Y, 0)
    end
    if PlayerGui:FindFirstChild("InvisPanel") and PlayerGui.InvisPanel:FindFirstChild("Frame") then
        PlayerGui.InvisPanel.Frame.Position = UDim2.new(DefaultConfig.Positions.InvisPanel.X, 0, DefaultConfig.Positions.InvisPanel.Y, 0)
    end
    ShowNotification("UI RESET", "Positions restored to default")
end)

updateSettingsCanvasSize = function()
    local activeContainer = tabContainers[activeTabName]
    if activeContainer then
        local cl = activeContainer:FindFirstChildOfClass("UIListLayout")
        local contentHeight = cl and cl.AbsoluteContentSize.Y or 0
        sList.CanvasSize = UDim2.new(0, 0, 0, math.max(contentHeight + 20, sList.AbsoluteSize.Y))
    end
end

for _, cont in pairs(tabContainers) do
    local cl = cont:FindFirstChildOfClass("UIListLayout")
    if cl then
        cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSettingsCanvasSize)
    end
end
task.defer(updateSettingsCanvasSize)
end -- settings row creation

if IS_MOBILE then
    sList.ScrollBarThickness = 6
    sList.ScrollingEnabled = true
    sList.ElasticBehavior = Enum.ElasticBehavior.Always
end

if not IS_MOBILE then
    UserInputService.InputBegan:Connect(function(input, gp)
        if input.KeyCode == (Enum.KeyCode[Config.MenuKey] or Enum.KeyCode.LeftControl) then
            settingsGui.Enabled = not settingsGui.Enabled
        end
        if Config.KickKey ~= "" and input.KeyCode == Enum.KeyCode[Config.KickKey] then
            kickPlayer()
        end
        if Config.RagdollSelfKey ~= "" and input.KeyCode == Enum.KeyCode[Config.RagdollSelfKey] then
            if not isOnCooldown("ragdoll") then
                if runAdminCommand(LocalPlayer, "ragdoll") then
                    activeCooldowns["ragdoll"] = tick()
                    setGlobalVisualCooldown("ragdoll")
                    ShowNotification("RAGDOLL SELF", "Ragdolled " .. LocalPlayer.Name)
                end
            else
                ShowNotification("RAGDOLL SELF", "Ragdoll on cooldown")
            end
        end
        if Config.ProximityAPKeybind and input.KeyCode == Enum.KeyCode[Config.ProximityAPKeybind] then
            ProximityAPActive = not ProximityAPActive
            if SharedState.updateProximityAPButton then SharedState.updateProximityAPButton() end
            ShowNotification("PROXIMITY AP", ProximityAPActive and "ENABLED" or "DISABLED")
        end
        if input.KeyCode == (Enum.KeyCode[Config.ClickToAPKeybind] or Enum.KeyCode.L) then
            Config.ClickToAP = not Config.ClickToAP
            SaveConfig()
            if SharedState.UpdateClickAPButton then SharedState.UpdateClickAPButton() end
            ShowNotification("CLICK TO AP", Config.ClickToAP and "ENABLED" or "DISABLED")
        end
        if Config.JobJoinerKey and input.KeyCode == Enum.KeyCode[Config.JobJoinerKey] then
            local joinerGui = PlayerGui:FindFirstChild("XiJobJoiner")
            if joinerGui then
                Config.ShowJobJoiner = not Config.ShowJobJoiner
                joinerGui.Enabled = Config.ShowJobJoiner
                SaveConfig()
                ShowNotification("JOB ID JOINER", Config.ShowJobJoiner and "OPENED" or "CLOSED")
            end
        end
    end)
end


task.spawn(function()
    task.wait(1)
    if Config.HideAdminPanel then
        local adUI = PlayerGui:FindFirstChild("XiAdminPanel")
        if adUI then adUI.Enabled = false end
    end
    if Config.HideAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI then asUI.Enabled = false end
    end
    if Config.CompactAutoSteal then
        local asUI = PlayerGui:FindFirstChild("AutoStealUI")
        if asUI and asUI:FindFirstChild("Frame") then
            local frame = asUI.Frame
            local mobileScale = IS_MOBILE and 0.6 or 1
            frame.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, 5 * 44 + 135)
        end
    end
end)

function parseMinGen(str)
    if not str or type(str) ~= "string" then return 0 end
    str = str:gsub("%s", ""):lower()
    if str == "" then return 0 end
    local num, suffix = str:match("^([%d%.]+)([kmb]?)$")
    if not num then return 0 end
    num = tonumber(num)
    if not num or num < 0 then return 0 end
    if suffix == "k" then return num * 1e3
    elseif suffix == "m" then return num * 1e6
    elseif suffix == "b" then return num * 1e9
    end
    return num
end

if Config.TpSettings.TpOnLoad then
    task.spawn(function()
        local t = 0
        local player = game.Players.LocalPlayer

        while not SharedState.SelectedPetData and t < 150 do
            task.wait(0.1)
            t = t + 1
        end

        if not SharedState.SelectedPetData then
            ShowNotification("TIMEOUT", "Auto TP timed out.")
            return
        end

        local minGen = parseMinGen(Config.TpSettings.MinGenForTp)
        if minGen > 0 then
            local waitCache = 0
            while (not SharedState.AllAnimalsCache or #SharedState.AllAnimalsCache == 0) and waitCache < 100 do
                task.wait(0.1)
                waitCache = waitCache + 1
            end
            local cache = SharedState.AllAnimalsCache or {}
            local highestGen = (cache[1] and cache[1].genValue) or 0
            if highestGen < minGen then
                ShowNotification("MIN GEN", "Highest brainrot below " .. (Config.TpSettings.MinGenForTp or "") .. ", skipping auto TP.")
                return
            end
        end

        runAutoSnipe()
    end)
end


LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
    local isStealing = LocalPlayer:GetAttribute("Stealing")
    local wasStealing = not isStealing 

    if isStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and not _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
        if Config.AutoUnlockOnSteal then
            triggerClosestUnlock(nil, 19)
        end
    elseif wasStealing then
        if Config.AutoInvisDuringSteal and _G.toggleInvisibleSteal and _G.invisibleStealEnabled then
            _G.toggleInvisibleSteal()
        end
    end
end)

task.spawn(function()
    local stealSpeedEnabled = false
    local STEAL_SPEED = Config.StealSpeed or 25.5
    local stealConn = nil

    local function doDisable()
        stealSpeedEnabled = false
        if stealConn then stealConn:Disconnect(); stealConn=nil end
    end
    SharedState.DisableStealSpeed = function()
        doDisable()
        SharedState._ssEnabled = false
        if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
    end

    SharedState.SetStealSpeed = function(v)
        STEAL_SPEED = math.clamp(v, 5, 100)
    end

    local function doEnable()
        stealSpeedEnabled = true
        if stealConn then stealConn:Disconnect(); stealConn=nil end
        stealConn = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character; if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * STEAL_SPEED, hrp.AssemblyLinearVelocity.Y, md.Z * STEAL_SPEED)
            end
        end)
    end

    SharedState.StealSpeedToggleFunc = function()
        if stealSpeedEnabled then doDisable() else doEnable() end
        SharedState._ssEnabled = stealSpeedEnabled
        if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
    end

    task.spawn(function()
        local lastHadSteal = nil
        while true do
            task.wait(0.3)
            if not Config.AutoStealSpeed then lastHadSteal = nil; continue end
            local hasSteal = (LocalPlayer:GetAttribute("Stealing") == true)
            if lastHadSteal == hasSteal then continue end
            lastHadSteal = hasSteal
            if hasSteal and not stealSpeedEnabled then
                doEnable(); SharedState._ssEnabled = true; if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
            elseif not hasSteal and stealSpeedEnabled then
                doDisable(); if SharedState._ssUpdateBtn then SharedState._ssUpdateBtn() end
            end
        end
    end)
end)

task.spawn(function()
    local brainrotESPEnabled = Config.BrainrotESP
    local brainrotESPFolder = Instance.new("Folder")
    brainrotESPFolder.Name = "XiBrainrotESP"
    brainrotESPFolder.Parent = Workspace
    local brainrotBillboards = {}
    local hiddenOverheads = {}
    local MIN_GEN_VALUE = 10000000

    local MUT_COLORS = {
        Cursed = Color3.fromRGB(136,0,0),
        Gold = Color3.fromRGB(255, 200, 50),
        Diamond = Color3.fromRGB(100, 200, 230),
        YinYang = Color3.fromRGB(200, 200, 220),
        Rainbow = Color3.fromRGB(180, 140, 200),
        Lava = Color3.fromRGB(230, 120, 50),
        Candy = Color3.fromRGB(230, 150, 180),
        Bloodrot = Color3.fromRGB(180, 70, 70),
        Radioactive = Color3.fromRGB(100, 220, 100),
        Divine = Color3.fromRGB(255, 220, 150)
    }

    local MUT_ICONS = {
        Cursed = "◈",
        Gold = "◆",
        Diamond = "♢",
        YinYang = "☯",
        Rainbow = "◉",
        Lava = "◌",
        Candy = "♢",
        Bloodrot = "◈",
        Radioactive = "☢",
        Divine = "☆"
    }

    local function formatGenValue(value)
        if value >= 1000000000 then
            return string.format("%.1fB", value / 1000000000)
        elseif value >= 1000000 then
            return string.format("%.1fM", value / 1000000)
        elseif value >= 1000 then
            return string.format("%.1fK", value / 1000)
        else
            return tostring(value)
        end
    end

    local function createBrainrotBillboard(data)
        local bb = Instance.new("BillboardGui")
        bb.Name = "BrainrotESP_" .. data.uid
        bb.Size = UDim2.new(0, 130, 0, 60)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.MaxDistance = 3000
        bb.ResetOnSpawn = false
        bb.ZIndexBehavior = Enum.ZIndexBehavior.Global

        local hasMut = data.mutation and data.mutation ~= "None" and data.mutation ~= "N/A"
        local mutColor = hasMut and MUT_COLORS[data.mutation] or Color3.fromRGB(100, 100, 120)

        local container = Instance.new("Frame", bb)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
        container.BackgroundTransparency = 0.4
        container.BorderSizePixel = 0
        Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", container)
        stroke.Color = mutColor
        stroke.Thickness = hasMut and 2.5 or 1.5
        stroke.Transparency = 0.2

        if hasMut then
            local mutBadge = Instance.new("Frame", container)
            mutBadge.Size = UDim2.new(1, -16, 0, 18)
            mutBadge.Position = UDim2.new(0, 8, 0, 5)
            mutBadge.BackgroundColor3 = mutColor
            mutBadge.BackgroundTransparency = 0.85
            mutBadge.BorderSizePixel = 0
            Instance.new("UICorner", mutBadge).CornerRadius = UDim.new(0, 6)

            local mutIcon = Instance.new("TextLabel", mutBadge)
            mutIcon.Size = UDim2.new(0, 18, 1, 0)
            mutIcon.Position = UDim2.new(0, 4, 0, 0)
            mutIcon.BackgroundTransparency = 1
            mutIcon.Font = Enum.Font.GothamBold
            mutIcon.TextSize = 10
            mutIcon.TextColor3 = mutColor
            mutIcon.Text = MUT_ICONS[data.mutation] or "●"
            mutIcon.TextXAlignment = Enum.TextXAlignment.Left

            local mutText = Instance.new("TextLabel", mutBadge)
            mutText.Size = UDim2.new(1, -26, 1, 0)
            mutText.Position = UDim2.new(0, 22, 0, 0)
            mutText.BackgroundTransparency = 1
            mutText.Font = Enum.Font.GothamBold
            mutText.TextSize = 9
            mutText.TextColor3 = mutColor
            mutText.Text = data.mutation:upper()
            mutText.TextXAlignment = Enum.TextXAlignment.Left
        end

        local nameLabel = Instance.new("TextLabel", container)
        nameLabel.Size = UDim2.new(1, -16, 0, 18)
        nameLabel.Position = UDim2.new(0, 8, 0, hasMut and 27 or 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = hasMut and mutColor or Color3.fromRGB(220, 220, 240)
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameLabel.Text = (data.name or data.petName) or "???"
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local genLabel = Instance.new("TextLabel", container)
        genLabel.Size = UDim2.new(1, -16, 0, 14)
        genLabel.Position = UDim2.new(0, 8, 0, hasMut and 45 or 28)
        genLabel.BackgroundTransparency = 1
        genLabel.Font = Enum.Font.GothamMedium
        genLabel.TextSize = 10
        genLabel.TextColor3 = Color3.fromRGB(220, 180, 60)
        genLabel.TextStrokeTransparency = 0.5
        genLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        genLabel.Text = "★ " .. formatGenValue(data.genValue) .. "/s"
        genLabel.TextXAlignment = Enum.TextXAlignment.Left

        local pulseTween = TweenService:Create(stroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Transparency = 0.5
        })
        pulseTween:Play()

        return bb, pulseTween
    end

    function findAnimalAdornee(data)
        if not data or not data.plot or not data.slot then return nil end
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return nil end
        local plot = plots:FindFirstChild(data.plot)
        if not plot then return nil end
        local podiums = plot:FindFirstChild("AnimalPodiums")
        if not podiums then return nil end
        local podium = podiums:FindFirstChild(data.slot)
        if not podium then return nil end
        local base = podium:FindFirstChild("Base")
        if not base then return nil end
        local spawn = base:FindFirstChild("Spawn")
        if spawn and spawn:IsA("BasePart") then return spawn end
        local model = podium:FindFirstChildWhichIsA("Model")
        if model then
            local hrp = model:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:IsA("BasePart") then return hrp end
            local primaryPart = model.PrimaryPart
            if primaryPart and primaryPart:IsA("BasePart") then return primaryPart end
            local anyPart = model:FindFirstChildWhichIsA("BasePart")
            if anyPart then return anyPart end
        end
        return nil
    end

    function findAnimalOverhead(adornee)
        if not adornee then return nil end
        local model = adornee.Parent
        if not model then return nil end
        while model and not model:IsA("Model") do
            model = model.Parent
        end
        if not model then return nil end
        for _, child in ipairs(model:GetDescendants()) do
            if child.Name == "AnimalOverhead" and child:IsA("BillboardGui") then
                return child
            end
        end
        return nil
    end

    function hideDefaultOverhead(overhead)
        if overhead and overhead.Parent and not hiddenOverheads[overhead] then
            hiddenOverheads[overhead] = overhead.Enabled
            overhead.Enabled = false
        end
    end

    function showDefaultOverhead(overhead)
        if overhead and hiddenOverheads[overhead] ~= nil then
            overhead.Enabled = hiddenOverheads[overhead]
            hiddenOverheads[overhead] = nil
        end
    end

    function restoreAllOverheads()
        for overhead, wasEnabled in pairs(hiddenOverheads) do
            if overhead and overhead.Parent then
                overhead.Enabled = wasEnabled
            end
        end
        hiddenOverheads = {}
    end

    function cleanupOrphanedBillboards()
        local toRemove = {}
        for uid, entry in pairs(brainrotBillboards) do
            local shouldRemove = false
            if not entry.bb or not entry.bb.Parent then
                shouldRemove = true
            elseif entry.bb.Adornee and not entry.bb.Adornee.Parent then
                shouldRemove = true
            elseif entry.bb.Adornee and entry.bb.Adornee:IsDescendantOf(Workspace) == false then
                shouldRemove = true
            end
            if shouldRemove then
                if entry.bb then pcall(function() entry.bb:Destroy() end) end
                if entry.overhead then showDefaultOverhead(entry.overhead) end
                if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
                toRemove[uid] = true
            end
        end
        for uid in pairs(toRemove) do
            brainrotBillboards[uid] = nil
        end
    end

    function refreshBrainrotESP()
        if not brainrotESPEnabled then
            cleanupOrphanedBillboards()
            return
        end
        local cache = SharedState.AllAnimalsCache
        if not cache or #cache == 0 then
            cleanupOrphanedBillboards()
            return
        end
        local seen = {}
        local currentTime = os.clock()
        for _, data in ipairs(cache) do
            if data.genValue >= MIN_GEN_VALUE then
                seen[data.uid] = true
                if not brainrotBillboards[data.uid] then
                    local adornee = findAnimalAdornee(data)
                    if adornee then
                        local overhead = findAnimalOverhead(adornee)
                        if overhead and overhead:IsA("BillboardGui") then
                            hideDefaultOverhead(overhead)
                        end
                        local bb, pulseTween = createBrainrotBillboard(data)
                        bb.Adornee = adornee
                        bb.Parent = adornee
                        brainrotBillboards[data.uid] = {
                            bb = bb,
                            overhead = overhead,
                            lastSeen = currentTime,
                            plot = data.plot,
                            slot = data.slot,
                            pulseTween = pulseTween
                        }
                    end
                else
                    brainrotBillboards[data.uid].lastSeen = currentTime
                    if brainrotBillboards[data.uid].bb and brainrotBillboards[data.uid].bb.Adornee then
                        local currentAdornee = brainrotBillboards[data.uid].bb.Adornee
                        if not currentAdornee.Parent or not currentAdornee:IsDescendantOf(Workspace) then
                            local newAdornee = findAnimalAdornee(data)
                            if newAdornee and newAdornee ~= currentAdornee then
                                brainrotBillboards[data.uid].bb.Adornee = newAdornee
                                brainrotBillboards[data.uid].bb.Parent = newAdornee
                            end
                        end
                    end
                end
            end
        end
        local toRemove = {}
        for uid, entry in pairs(brainrotBillboards) do
            if not seen[uid] then
                toRemove[uid] = entry
            elseif entry.lastSeen and currentTime - entry.lastSeen > 5 then
                toRemove[uid] = entry
            end
        end
        for uid, entry in pairs(toRemove) do
            if entry.bb then pcall(function() entry.bb:Destroy() end) end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
            if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
            brainrotBillboards[uid] = nil
        end
    end

    function clearBrainrotESP()
        for _, entry in pairs(brainrotBillboards) do
            if entry.bb then pcall(function() entry.bb:Destroy() end) end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
            if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
        end
        brainrotBillboards = {}
        restoreAllOverheads()
    end

    function cleanupInvalidReferences()
        for uid, entry in pairs(brainrotBillboards) do
            local isValid = false
            if entry.bb and entry.bb.Parent and entry.bb.Adornee and entry.bb.Adornee.Parent then
                isValid = true
            end
            if not isValid then
                if entry.bb then pcall(function() entry.bb:Destroy() end) end
                if entry.overhead then showDefaultOverhead(entry.overhead) end
                if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
                brainrotBillboards[uid] = nil
            end
        end
    end

    function onPlotRemoved(plotName)
        local toRemove = {}
        for uid, entry in pairs(brainrotBillboards) do
            if entry.plot == plotName then
                toRemove[uid] = entry
            end
        end
        for uid, entry in pairs(toRemove) do
            if entry.bb then pcall(function() entry.bb:Destroy() end) end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
            if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
            brainrotBillboards[uid] = nil
        end
    end

    function onAnimalRemoved(uid)
        local entry = brainrotBillboards[uid]
        if entry then
            if entry.bb then pcall(function() entry.bb:Destroy() end) end
            if entry.overhead then showDefaultOverhead(entry.overhead) end
            if entry.pulseTween then pcall(function() entry.pulseTween:Cancel() end) end
            brainrotBillboards[uid] = nil
        end
    end

    espToggleRef.setFn = function(enabled)
        brainrotESPEnabled = enabled
        if enabled then
            task.spawn(function()
                task.wait(0.5)
                refreshBrainrotESP()
            end)
        else
            clearBrainrotESP()
        end
    end

    local plots = Workspace:FindFirstChild("Plots")
    if plots then
        plots.ChildRemoved:Connect(function(plot)
            if plot and plot.Name then
                onPlotRemoved(plot.Name)
            end
        end)
    end

    local function setupAnimalRemovalListener()
        if SharedState and SharedState.AllAnimalsCache then
            local function checkForRemovals()
                local currentCache = SharedState.AllAnimalsCache or {}
                local currentUIDs = {}
                for _, data in ipairs(currentCache) do
                    currentUIDs[data.uid] = true
                end
                for uid in pairs(brainrotBillboards) do
                    if not currentUIDs[uid] then
                        onAnimalRemoved(uid)
                    end
                end
            end
            task.spawn(function()
                while true do
                    task.wait(1)
                    if brainrotESPEnabled then
                        pcall(checkForRemovals)
                    end
                end
            end)
        end
    end

    task.spawn(function()
        while true do
            task.wait(0.3)
            if brainrotESPEnabled then
                pcall(refreshBrainrotESP)
            else
                pcall(cleanupOrphanedBillboards)
            end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(1)
            if brainrotESPEnabled then
                pcall(cleanupInvalidReferences)
            end
        end
    end)

    task.spawn(setupAnimalRemovalListener)

    if not brainrotESPEnabled then
        clearBrainrotESP()
    end
end)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
    Background  = Color3.fromRGB(12, 12, 18),
    Surface = Color3.fromRGB(18, 18, 26),
    SurfaceHighlight = Color3.fromRGB(28, 28, 38),
    Accent1 = Color3.fromRGB(180, 180, 210),
    Accent2 = Color3.fromRGB(160, 160, 180),
    TextPrimary = Color3.fromRGB(220, 220, 240),
    TextSecondary = Color3.fromRGB(120, 120, 140),
    Success = Color3.fromRGB(140, 180, 140),
    Error = Color3.fromRGB(200, 120, 120),
}

local SyllinsePanel = Instance.new("ScreenGui")
SyllinsePanel.Name = "SyllinsePanel"
SyllinsePanel.ResetOnSpawn = false
SyllinsePanel.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.ClipsDescendants = true
Frame.Size = UDim2.new(0, 300, 0, 450)
local uiScale = Instance.new("UIScale", Frame)
uiScale.Scale = 1
do
    local _ip = Config.Positions and Config.Positions.InvisPanel
    Frame.Position = _ip and UDim2.new(_ip.X, 0, _ip.Y, 0) or UDim2.new(0.50, -150, 0.30, 144)
end
Frame.BorderSizePixel = 0
Frame.BackgroundColor3 = Theme.Background
Frame.BackgroundTransparency = 0.08
Frame.Parent = SyllinsePanel
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local borderStroke = Instance.new("UIStroke", Frame)
borderStroke.Color = Color3.fromRGB(55, 55, 70)
borderStroke.Thickness = 1
borderStroke.Transparency = 0.5

local innerGlow = Instance.new("Frame", Frame)
innerGlow.Size = UDim2.new(1, -4, 1, -4)
innerGlow.Position = UDim2.new(0, 2, 0, 2)
innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
innerGlow.BackgroundTransparency = 0.96
innerGlow.BorderSizePixel = 0
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)

local accentBar = Instance.new("Frame", Frame)
accentBar.Size = UDim2.new(1, 0, 0, 3)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.BackgroundColor3 = Theme.Accent1
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 5
Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 12)

local header = Instance.new("Frame", Frame)
header.Size = UDim2.new(1, 0, 0, 46)
header.Position = UDim2.new(0, 0, 0, 3)
header.BackgroundTransparency = 1

local titleLeft = Instance.new("TextLabel", header)
titleLeft.Font = Enum.Font.GothamBold
titleLeft.TextXAlignment = Enum.TextXAlignment.Left
titleLeft.TextSize = 15
titleLeft.Size = UDim2.new(0, 58, 1, 0)
titleLeft.Position = UDim2.new(0, 14, 0, 0)
titleLeft.Text = "STEAL"
titleLeft.TextColor3 = Theme.TextPrimary
titleLeft.BackgroundTransparency = 1

local titleRight = Instance.new("TextLabel", header)
titleRight.Font = Enum.Font.GothamBold
titleRight.TextXAlignment = Enum.TextXAlignment.Left
titleRight.TextSize = 15
titleRight.Size = UDim2.new(0, 70, 1, 0)
titleRight.Position = UDim2.new(0, 68, 0, 0)
titleRight.Text = "HELPER"
titleRight.TextColor3 = Theme.Accent1
titleRight.BackgroundTransparency = 1

local headerSep = Instance.new("Frame", Frame)
headerSep.Size = UDim2.new(1, -20, 0, 1)
headerSep.Position = UDim2.new(0, 10, 0, 49)
headerSep.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
headerSep.BorderSizePixel = 0

local resizeBtn = Instance.new("TextButton", header)
resizeBtn.ZIndex = 10
resizeBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
resizeBtn.Font = Enum.Font.GothamMedium
resizeBtn.TextSize = 11
resizeBtn.Size = UDim2.new(0, 22, 0, 22)
resizeBtn.TextColor3 = Theme.Accent1
resizeBtn.Text = "↕"
resizeBtn.Position = UDim2.new(1, -26, 0.5, -11)
Instance.new("UICorner", resizeBtn).CornerRadius = UDim.new(1, 0)

do
    local dragging, dragStart, startAbsX, startAbsY
    header.InputBegan:Connect(function(inp)
        if Config.UILocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = inp.Position
            startAbsX = Frame.AbsolutePosition.X
            startAbsY = Frame.AbsolutePosition.Y
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    local parentSize = Frame.Parent.AbsoluteSize
                    Config.Positions = Config.Positions or {}
                    Config.Positions.InvisPanel = {
                        X = Frame.AbsolutePosition.X / parentSize.X,
                        Y = Frame.AbsolutePosition.Y / parentSize.Y,
                    }
                    SaveConfig()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragStart
            local vp = workspace.CurrentCamera.ViewportSize
            local newX = math.clamp(startAbsX + d.X, 0, vp.X - Frame.AbsoluteSize.X)
            local newY = math.clamp(startAbsY + d.Y, 0, vp.Y - Frame.AbsoluteSize.Y)
            Frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

do
    local dragY, startScale
    resizeBtn.InputBegan:Connect(function(inp)
        if Config.UILocked then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragY = inp.Position.Y
            startScale = uiScale.Scale
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragY and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position.Y - dragY
            uiScale.Scale = math.clamp(startScale + delta / 200, 0.6, 1.4)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragY = nil end
    end)
end

local container = Instance.new("ScrollingFrame", Frame)
container.Size = UDim2.new(1, -20, 1, -52)
container.Position = UDim2.new(0, 10, 0, 52)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.ScrollBarThickness = 3
container.ScrollBarImageColor3 = Color3.fromRGB(55, 55, 70)
container.CanvasSize = UDim2.new(0, 0, 0, 0)

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function styleBtn(btn, on)
    btn.Text = on and "ON" or "OFF"
    btn.BackgroundColor3 = on and Theme.Accent1 or Color3.fromRGB(28, 28, 36)
    btn.TextColor3 = on and Color3.fromRGB(12, 12, 18) or Theme.Accent1
end

local function styleStroke(stroke, on)
    stroke.Transparency = on and 1 or 0.5
end

local function createToggleRow(leftText, rightText, leftCallback, rightCallback, leftDefault, rightDefault)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 34)
    row.BackgroundTransparency = 1
    row.Parent = container

    local leftFrame = Instance.new("Frame", row)
    leftFrame.Size = UDim2.new(0.48, 0, 1, 0)
    leftFrame.Position = UDim2.new(0, 0, 0, 0)
    leftFrame.BackgroundTransparency = 1

    local rightFrame = Instance.new("Frame", row)
    rightFrame.Size = UDim2.new(0.48, 0, 1, 0)
    rightFrame.Position = UDim2.new(0.52, 0, 0, 0)
    rightFrame.BackgroundTransparency = 1

    local function makeToggle(parent, text, callback, defaultValue)
        local label = Instance.new("TextLabel", parent)
        label.Size = UDim2.new(0.55, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 11
        label.TextColor3 = Theme.TextPrimary
        label.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton", parent)
        btn.Size = UDim2.new(0, 45, 0, 24)
        btn.Position = UDim2.new(1, -45, 0.5, -12)
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = Theme.Accent1
        stroke.Thickness = 1

        styleBtn(btn, defaultValue)
        styleStroke(stroke, defaultValue)

        btn.MouseButton1Click:Connect(function()
            callback(btn, stroke)
        end)

        return btn, stroke
    end

    local leftBtn, leftStroke = makeToggle(leftFrame, leftText, leftCallback, leftDefault)
    local rightBtn, rightStroke = makeToggle(rightFrame, rightText, rightCallback, rightDefault)

    return {
        left  = {btn = leftBtn,  stroke = leftStroke},
        right = {btn = rightBtn, stroke = rightStroke}
    }
end

local function Divider()
    local r = Instance.new("Frame", container)
    r.Size = UDim2.new(1, 0, 0, 1)
    r.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    r.BorderSizePixel = 0
end

local function SliderRow(title, minVal, maxVal, defaultValue, callback)
    local row = Instance.new("Frame", container)
    row.Size = UDim2.new(1, 0, 0, 48)
    row.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", row)
    label.Size = UDim2.new(0.7, 0, 0, 18)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextColor3 = Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Left

    local valueLabel = Instance.new("TextLabel", row)
    valueLabel.Size = UDim2.new(0.3, 0, 0, 18)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.Font = Enum.Font.GothamMedium
    valueLabel.TextSize = 10
    valueLabel.TextColor3 = Theme.Accent1
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(1, 0, 0, 4)
    bg.Position = UDim2.new(0, 0, 0, 26)
    bg.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent1
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", bg)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((defaultValue - minVal) / (maxVal - minVal), 0, 0.5, -6)
    knob.BackgroundColor3 = Theme.TextPrimary
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(x)
        local p = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        local val = minVal + p * (maxVal - minVal)
        if title:find("Speed") then val = math.floor(val) end
        valueLabel.Text = string.format("%.1f", val):gsub("%.0$", "")
        fill.Size = UDim2.new(p, 0, 1, 0)
        knob.Position = UDim2.new(p, 0, 0.5, -6)
        callback(val)
    end

    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)

    return row
end

local invisData = createToggleRow("Invis", "Auto Fix Lagback",
    function(btn, stroke)
        if _G.toggleInvisibleSteal then
            pcall(_G.toggleInvisibleSteal)
            local on = _G.invisibleStealEnabled or false
            styleBtn(btn, on); styleStroke(stroke, on)
        end
    end,
    function(btn, stroke)
        _G.AutoRecoverLagback = not (_G.AutoRecoverLagback or false)
        local on = _G.AutoRecoverLagback
        styleBtn(btn, on); styleStroke(stroke, on)
    end,
    _G.invisibleStealEnabled or false,
    _G.AutoRecoverLagback or false
)

Divider()

local autoRow = createToggleRow("Auto Invis Steal", "Auto Destroy Turrets",
    function(btn, stroke)
        _G.AutoInvisDuringSteal = not (_G.AutoInvisDuringSteal or false)
        Config.AutoInvisDuringSteal = _G.AutoInvisDuringSteal
        local on = _G.AutoInvisDuringSteal
        styleBtn(btn, on); styleStroke(stroke, on)
    end,
    function(btn, stroke)
        Config.AutoDestroyTurrets = not Config.AutoDestroyTurrets
        SaveConfig()
        local on = Config.AutoDestroyTurrets
        styleBtn(btn, on); styleStroke(stroke, on)
    end,
    _G.AutoInvisDuringSteal or false,
    Config.AutoDestroyTurrets or false
)

Divider()

local kickISRow = createToggleRow("Auto Kick Steal", "Instant Steal",
    function(btn, stroke)
        Config.AutoKickOnSteal = not Config.AutoKickOnSteal
        SaveConfig()
        local on = Config.AutoKickOnSteal
        styleBtn(btn, on); styleStroke(stroke, on)
    end,
    function(btn, stroke)
        if SharedState and SharedState.InstantStealToggleFunc then
            SharedState.InstantStealToggleFunc()
        end
        local on = Config.InstantSteal or false
        styleBtn(btn, on); styleStroke(stroke, on)
    end,
    Config.AutoKickOnSteal or false,
    Config.InstantSteal or false
)

SharedState._isUpdateBtn = function()
    local on = Config.InstantSteal or false
    styleBtn(kickISRow.right.btn, on)
    styleStroke(kickISRow.right.stroke, on)
end

Divider()

local ssRow = Instance.new("Frame", container)
ssRow.Size = UDim2.new(1, 0, 0, 48)
ssRow.BackgroundTransparency = 1

local ssLabel = Instance.new("TextLabel", ssRow)
ssLabel.Size = UDim2.new(0.55, 0, 0, 18)
ssLabel.Position = UDim2.new(0, 0, 0, 0)
ssLabel.BackgroundTransparency = 1
ssLabel.Text = "Steal Speed"
ssLabel.Font = Enum.Font.GothamMedium
ssLabel.TextSize = 11
ssLabel.TextColor3 = Theme.TextPrimary
ssLabel.TextXAlignment = Enum.TextXAlignment.Left

local ssToggleBtn = Instance.new("TextButton", ssRow)
ssToggleBtn.Size = UDim2.new(0, 45, 0, 24)
ssToggleBtn.Position = UDim2.new(1, -45, 0, -3)
ssToggleBtn.BorderSizePixel = 0
Instance.new("UICorner", ssToggleBtn).CornerRadius = UDim.new(0, 6)
local ssToggleStroke = Instance.new("UIStroke", ssToggleBtn)
ssToggleStroke.Color = Theme.Accent1
ssToggleStroke.Thickness = 1
styleBtn(ssToggleBtn, SharedState._ssEnabled or false)
styleStroke(ssToggleStroke, SharedState._ssEnabled or false)

ssToggleBtn.MouseButton1Click:Connect(function()
    if SharedState and SharedState.StealSpeedToggleFunc then
        SharedState.StealSpeedToggleFunc()
    end
end)

SharedState._ssUpdateBtn = function()
    local on = SharedState._ssEnabled or false
    styleBtn(ssToggleBtn, on)
    styleStroke(ssToggleStroke, on)
end

local ssBg = Instance.new("Frame", ssRow)
ssBg.Size = UDim2.new(1, 0, 0, 4)
ssBg.Position = UDim2.new(0, 0, 0, 32)
ssBg.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
ssBg.BorderSizePixel = 0
Instance.new("UICorner", ssBg).CornerRadius = UDim.new(1, 0)

local ssSliderValue = Config.StealSpeed or 20
local ssFill = Instance.new("Frame", ssBg)
ssFill.Size = UDim2.new((ssSliderValue - 5) / 95, 0, 1, 0)
ssFill.BackgroundColor3 = Theme.Accent1
ssFill.BorderSizePixel = 0
Instance.new("UICorner", ssFill).CornerRadius = UDim.new(1, 0)

local ssKnob = Instance.new("Frame", ssBg)
ssKnob.Size = UDim2.new(0, 12, 0, 12)
ssKnob.Position = UDim2.new((ssSliderValue - 5) / 95, 0, 0.5, -6)
ssKnob.BackgroundColor3 = Theme.TextPrimary
ssKnob.BorderSizePixel = 0
Instance.new("UICorner", ssKnob).CornerRadius = UDim.new(1, 0)

local ssValLabel = Instance.new("TextLabel", ssRow)
ssValLabel.Size = UDim2.new(0.3, 0, 0, 18)
ssValLabel.Position = UDim2.new(0.55, 0, 0, 0)
ssValLabel.BackgroundTransparency = 1
ssValLabel.Text = tostring(ssSliderValue)
ssValLabel.Font = Enum.Font.GothamMedium
ssValLabel.TextSize = 10
ssValLabel.TextColor3 = Theme.Accent1
ssValLabel.TextXAlignment = Enum.TextXAlignment.Center

local ssDragging = false
function ssUpdate(x)
    local p = math.clamp((x - ssBg.AbsolutePosition.X) / ssBg.AbsoluteSize.X, 0, 1)
    ssSliderValue = math.floor(5 + p * 95)
    ssFill.Size = UDim2.new(p, 0, 1, 0)
    ssKnob.Position = UDim2.new(p, 0, 0.5, -6)
    ssValLabel.Text = tostring(ssSliderValue)
    Config.StealSpeed = ssSliderValue
    SaveConfig()
    if SharedState and SharedState.SetStealSpeed then SharedState.SetStealSpeed(ssSliderValue) end
end
ssBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then ssDragging = true; ssUpdate(i.Position.X) end
end)
ssKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then ssDragging = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then ssDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if ssDragging and i.UserInputType == Enum.UserInputType.MouseMovement then ssUpdate(i.Position.X) end
end)

Divider()

SliderRow("Rotation Angle", 180, 360, _G.InvisStealAngle or 233, function(v)
    _G.InvisStealAngle = math.floor(v)
end)

Divider()

SliderRow("Sink Depth", 0.5, 10, _G.SinkSliderValue or 5, function(v)
    _G.SinkSliderValue = v
end)

Divider()

local keyRow = Instance.new("Frame", container)
keyRow.Size = UDim2.new(1, 0, 0, 34)
keyRow.BackgroundTransparency = 1

local keyLabel = Instance.new("TextLabel", keyRow)
keyLabel.Size = UDim2.new(0.6, 0, 1, 0)
keyLabel.Position = UDim2.new(0, 0, 0, 0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = "Invis Keybind"
keyLabel.Font = Enum.Font.GothamMedium
keyLabel.TextSize = 11
keyLabel.TextColor3 = Theme.TextPrimary
keyLabel.TextXAlignment = Enum.TextXAlignment.Left

local keyBtn = Instance.new("TextButton", keyRow)
keyBtn.Size = UDim2.new(0, 55, 0, 26)
keyBtn.Position = UDim2.new(1, -55, 0.5, -13)
keyBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
keyBtn.Text = (_G.INVISIBLE_STEAL_KEY and _G.INVISIBLE_STEAL_KEY.Name) or "V"
keyBtn.Font = Enum.Font.GothamMedium
keyBtn.TextSize = 11
keyBtn.TextColor3 = Theme.Accent1
keyBtn.BorderSizePixel = 0
Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)
local keyStroke = Instance.new("UIStroke", keyBtn)
keyStroke.Color = Theme.Accent1
keyStroke.Thickness = 1
keyStroke.Transparency = 0.5

keyBtn.MouseButton1Click:Connect(function()
    keyBtn.Text = "..."
    local c; c = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            keyBtn.Text = inp.KeyCode.Name
            _G.INVISIBLE_STEAL_KEY = inp.KeyCode
            c:Disconnect()
        end
    end)
end)

Divider()

local actionRow = Instance.new("Frame", container)
actionRow.Size = UDim2.new(1, 0, 0, 34)
actionRow.BackgroundTransparency = 1

local function makeActionBtn(parent, text, xPos, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.48, 0, 1, 0)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.TextColor3 = Theme.Accent1
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn)
    s.Color = Theme.Accent1; s.Thickness = 1; s.Transparency = 0.7
    btn.MouseEnter:Connect(function() s.Transparency = 0.3 end)
    btn.MouseLeave:Connect(function() s.Transparency = 0.7 end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

makeActionBtn(actionRow, "RESET", 0, function() task.spawn(executeReset) end)
makeActionBtn(actionRow, "REJOIN", 0.52, function()
    ShowNotification("REJOIN", "Rejoining...")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

local actionRow2 = Instance.new("Frame", container)
actionRow2.Size = UDim2.new(1, 0, 0, 34)
actionRow2.BackgroundTransparency = 1

makeActionBtn(actionRow2, "KICK", 0, function() kickPlayer() end)
makeActionBtn(actionRow2, "SETTINGS", 0.52, function()
    if settingsGui then settingsGui.Enabled = not settingsGui.Enabled end
end)

function updateCanvas()
    container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
task.defer(updateCanvas)

_G.updateVisualState = function(on)
    styleBtn(invisData.left.btn, on)
    styleStroke(invisData.left.stroke, on)
    if _G.updateMovementPanelInvisVisual then
        pcall(_G.updateMovementPanelInvisVisual, on)
    end
end

task.spawn(function()
    local animPlaying = false
    local tracks = {}
    local clone, oldRoot, hip, connection
    local folderConnections = {}
    local serverGhosts = {}
    local ghostEnabled = true
    local lagbackCallCount = 0
    local lagbackWindowStart = 0
    local lastLagbackTime = 0
    local errorOrbActive = false
    local errorOrb = nil
    local errorOrbConnection = nil

    local function clearErrorOrb()
        if errorOrb and errorOrb.Parent then errorOrb:Destroy() end
        errorOrb = nil; errorOrbActive = false
        if errorOrbConnection then errorOrbConnection:Disconnect(); errorOrbConnection = nil end
    end

    local function createErrorOrb()
        if errorOrbActive then return end
        errorOrbActive = true
        for _, ghost in pairs(serverGhosts) do if ghost and ghost.Parent then ghost:Destroy() end end
        serverGhosts = {}
        local sg = Instance.new("ScreenGui")
        sg.Name = "ErrorOrbGui"; sg.ResetOnSpawn = false
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(0, 500, 0, 60)
        fr.Position = UDim2.new(0.5, -250, 0.3, 0)
        fr.BackgroundTransparency = 1; fr.BorderSizePixel = 0; fr.Parent = sg
        local l1 = Instance.new("TextLabel")
        l1.Size = UDim2.new(1, 0, 0.5, 0); l1.BackgroundTransparency = 1
        l1.Text = "ERROR CAUSED BY PLAYER DEATH"
        l1.TextColor3 = Color3.fromRGB(255, 0, 0)
        l1.TextStrokeTransparency = 0; l1.TextStrokeColor3 = Color3.new(0, 0, 0)
        l1.Font = Enum.Font.SourceSansBold; l1.TextScaled = true; l1.Parent = fr
        local l2 = Instance.new("TextLabel")
        l2.Size = UDim2.new(1, 0, 0.5, 0); l2.Position = UDim2.new(0, 0, 0.5, 0)
        l2.BackgroundTransparency = 1; l2.Text = "MUST RESET TO FIX ERROR"
        l2.TextColor3 = Color3.fromRGB(255, 0, 0)
        l2.TextStrokeTransparency = 0; l2.TextStrokeColor3 = Color3.new(0, 0, 0)
        l2.Font = Enum.Font.SourceSansBold; l2.TextScaled = true; l2.Parent = fr
        errorOrb = sg
    end

    local function createServerGhost(position)
        if not ghostEnabled or errorOrbActive then return end
        local now = tick()
        if now - lastLagbackTime < 0.05 then return end
        lastLagbackTime = now
        if now - lagbackWindowStart > 1 then lagbackCallCount = 0; lagbackWindowStart = now end
        lagbackCallCount = lagbackCallCount + 1
        if lagbackCallCount >= 7 then createErrorOrb(); return end
        for _, g in pairs(serverGhosts) do if g and g.Parent then g:Destroy() end end
        serverGhosts = {}
        local sg = Instance.new("ScreenGui")
        sg.Name = "LagbackNotification"; sg.ResetOnSpawn = false
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local sl = Instance.new("TextLabel")
        sl.Size = UDim2.new(0, 500, 0, 30); sl.Position = UDim2.new(0.5, -250, 0.15, 0)
        sl.BackgroundTransparency = 1; sl.Text = "LAGBACK DETECTED"
        sl.TextColor3 = Color3.fromRGB(255, 0, 0)
        sl.TextStrokeTransparency = 0; sl.TextStrokeColor3 = Color3.new(0, 0, 0)
        sl.Font = Enum.Font.SourceSansBold; sl.TextScaled = true; sl.Parent = sg
        local sw = Instance.new("TextLabel")
        sw.Size = UDim2.new(0, 650, 0, 25); sw.Position = UDim2.new(0.5, -325, 0.15, 32)
        sw.BackgroundTransparency = 1
        sw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
        sw.TextColor3 = Color3.fromRGB(200, 200, 200)
        sw.TextStrokeTransparency = 0; sw.TextStrokeColor3 = Color3.new(0, 0, 0)
        sw.Font = Enum.Font.SourceSansBold; sw.TextScaled = true; sw.Parent = sg
        task.delay(1.5, function() if sg and sg.Parent then sg:Destroy() end end)
        local ghost = Instance.new("Part")
        ghost.Name = "LagbackGhost"; ghost.Shape = Enum.PartType.Ball
        ghost.Size = Vector3.new(3, 3, 3); ghost.Color = Color3.fromRGB(255, 0, 0)
        ghost.Material = Enum.Material.Glass; ghost.Transparency = 0.3
        ghost.CanCollide = false; ghost.Anchored = true; ghost.CastShadow = false
        ghost.Position = position + Vector3.new(0, 5, 0); ghost.Parent = Workspace.CurrentCamera
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 400, 0, 60); bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true; bb.Parent = ghost
        local bl = Instance.new("TextLabel")
        bl.Size = UDim2.new(1, 0, 0, 25); bl.BackgroundTransparency = 1
        bl.Text = "LAGBACK DETECTED"; bl.TextColor3 = Color3.fromRGB(255, 0, 0)
        bl.TextStrokeTransparency = 0; bl.TextStrokeColor3 = Color3.new(0, 0, 0)
        bl.Font = Enum.Font.SourceSansBold; bl.TextScaled = true; bl.Parent = bb
        local bw = Instance.new("TextLabel")
        bw.Size = UDim2.new(1, 0, 0, 25); bw.Position = UDim2.new(0, 0, 0, 25)
        bw.BackgroundTransparency = 1
        bw.Text = "DISABLE INVISIBLE STEAL NOW OR YOU WILL BE KILLED BY ANTICHEAT"
        bw.TextColor3 = Color3.fromRGB(200, 200, 200)
        bw.TextStrokeTransparency = 0; bw.TextStrokeColor3 = Color3.new(0, 0, 0)
        bw.Font = Enum.Font.SourceSansBold; bw.TextScaled = true; bw.Parent = bb
        table.insert(serverGhosts, ghost)
    end

    local function clearAllGhosts()
        for _, ghost in pairs(serverGhosts) do pcall(function() if ghost and ghost.Parent then ghost:Destroy() end end) end
        serverGhosts = {}; clearErrorOrb(); lagbackCallCount = 0; lastLagbackTime = 0
        pcall(function()
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then for _, gui in pairs(pg:GetChildren()) do if gui.Name == "LagbackNotification" then gui:Destroy() end end end
        end)
        pcall(function() if Workspace.CurrentCamera then for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do if c.Name == "LagbackGhost" then c:Destroy() end end end end)
        pcall(function() for _, c in pairs(Workspace:GetDescendants()) do if c.Name == "LagbackGhost" then c:Destroy() end end end)
    end

    local function removeFolders()
        local pf = Workspace:FindFirstChild(LocalPlayer.Name)
        if not pf then return end
        local dr = pf:FindFirstChild("DoubleRig")
        if dr then
            local rr = dr:FindFirstChild("HumanoidRootPart") or dr:FindFirstChildWhichIsA("BasePart")
            if rr and ghostEnabled then createServerGhost(rr.Position) end
            dr:Destroy()
        end
        local cs = pf:FindFirstChild("Constraints")
        if cs then cs:Destroy() end
        local conn = pf.ChildAdded:Connect(function(child)
            if child.Name == "DoubleRig" then
                task.defer(function()
                    local rr = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                    if rr and ghostEnabled then createServerGhost(rr.Position) end
                    child:Destroy()
                end)
            elseif child.Name == "Constraints" then child:Destroy() end
        end)
        table.insert(folderConnections, conn)
    end

    local function doClone()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            hip = character.Humanoid.HipHeight
            oldRoot = character:FindFirstChild("HumanoidRootPart")
            if not oldRoot or not oldRoot.Parent then return false end
            for _, c in pairs(oldRoot:GetChildren()) do
                if c:IsA("Attachment") and (c.Name:find("Beam") or c.Name:find("Attach")) then c:Destroy() end
            end
            for _, c in pairs(oldRoot:GetChildren()) do if c:IsA("Beam") then c:Destroy() end end
            local tmp = Instance.new("Model"); tmp.Parent = game
            character.Parent = tmp
            clone = oldRoot:Clone(); clone.Parent = character
            oldRoot.Parent = Workspace.CurrentCamera
            clone.CFrame = oldRoot.CFrame; character.PrimaryPart = clone
            character.Parent = Workspace
            for _, v in pairs(character:GetDescendants()) do
                if v:IsA("Weld") or v:IsA("Motor6D") then
                    if v.Part0 == oldRoot then v.Part0 = clone end
                    if v.Part1 == oldRoot then v.Part1 = clone end
                end
            end
            tmp:Destroy(); return true
        end
        return false
    end

    local function revertClone()
        local character = LocalPlayer.Character
        if not oldRoot or not oldRoot:IsDescendantOf(Workspace) or not character or character.Humanoid.Health <= 0 then return end
        local tmp = Instance.new("Model"); tmp.Parent = game
        character.Parent = tmp
        oldRoot.Parent = character; character.PrimaryPart = oldRoot
        character.Parent = Workspace; oldRoot.CanCollide = true
        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("Weld") or v:IsA("Motor6D") then
                if v.Part0 == clone then v.Part0 = oldRoot end
                if v.Part1 == clone then v.Part1 = oldRoot end
            end
        end
        if clone then local p = clone.CFrame; clone:Destroy(); clone = nil; oldRoot.CFrame = p end
        oldRoot = nil
        if character and character.Humanoid then character.Humanoid.HipHeight = hip end
        clearAllGhosts()
    end

    local function animationTrickery()
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
            local anim = Instance.new("Animation")
            anim.AnimationId = "http://www.roblox.com/asset/?id=18537363391"
            local humanoid = character.Humanoid
            local animator = humanoid:FindFirstChild("Animator") or Instance.new("Animator", humanoid)
            local animTrack = animator:LoadAnimation(anim)
            animTrack.Priority = Enum.AnimationPriority.Action4
            animTrack:Play(0, 1, 0); anim:Destroy()
            table.insert(tracks, animTrack)
            animTrack.Stopped:Connect(function() if animPlaying then animationTrickery() end end)
            task.delay(0, function()
                animTrack.TimePosition = 0.7
                task.delay(0.3, function() if animTrack then animTrack:AdjustSpeed(math.huge) end end)
            end)
        end
    end

    local turnOff
    local turnOn

    turnOff = function()
        clearAllGhosts()
        if not animPlaying then return end
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        animPlaying = false; _G.invisibleStealEnabled = false
        for _, t in pairs(tracks) do pcall(function() t:Stop() end) end
        tracks = {}
        if connection then connection:Disconnect(); connection = nil end
        for _, c in ipairs(folderConnections) do if c then c:Disconnect() end end
        folderConnections = {}
        revertClone(); clearAllGhosts()
        if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end) end
        if _G.updateVisualState then _G.updateVisualState(false) end
    end

    turnOn = function()
        if animPlaying then return end
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        animPlaying = true; _G.invisibleStealEnabled = true
        if _G.updateVisualState then _G.updateVisualState(true) end
        tracks = {}; removeFolders()
        local success = doClone()
        if success then
            task.wait(0.05); animationTrickery()
            task.defer(function()
                if _G.resetBrainrotBeam then pcall(_G.resetBrainrotBeam) end
                if _G.resetPlotBeam then pcall(_G.resetPlotBeam) end
                task.wait(0.1)
                if _G.updateBrainrotBeam then pcall(_G.updateBrainrotBeam) end
                if _G.createPlotBeam then pcall(_G.createPlotBeam) end
            end)
            local lastSetPosition = nil
            local skipFrames = 5
            connection = RunService.PreSimulation:Connect(function()
                if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 and oldRoot then
                    local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
                    if root then
                        if skipFrames > 0 then
                            skipFrames = skipFrames - 1; lastSetPosition = nil
                        elseif lastSetPosition and ghostEnabled then
                            local currentPos = oldRoot.Position
                            local jumpDist = (currentPos - lastSetPosition).Magnitude
                            if jumpDist > 3 and not _G.RecoveryInProgress then
                                lastSetPosition = nil; createServerGhost(currentPos)
                                if _G.AutoRecoverLagback and _G.toggleInvisibleSteal then
                                    _G.RecoveryInProgress = true
                                    task.spawn(function()
                                        pcall(_G.toggleInvisibleSteal); task.wait(0.5)
                                        pcall(_G.toggleInvisibleSteal); _G.RecoveryInProgress = false
                                    end)
                                end
                            end
                        end
                        if clone then clone.CanCollide = false end
                        for _, c in pairs(oldRoot:GetChildren()) do
                            if c:IsA("Attachment") or c:IsA("Beam") then c:Destroy() end
                        end
                        local rotAngle = _G.InvisStealAngle or 180
                        local sa = (_G.SinkSliderValue or 5) * 0.5
                        local cf = root.CFrame - Vector3.new(0, sa, 0)
                        oldRoot.CFrame = cf * CFrame.Angles(math.rad(rotAngle), 0, 0)
                        oldRoot.AssemblyLinearVelocity = root.AssemblyLinearVelocity
                        oldRoot.CanCollide = false
                        lastSetPosition = oldRoot.Position
                    end
                end
            end)
        end
    end

    _G.toggleInvisibleSteal = function()
        if animPlaying then turnOff() else turnOn() end
    end

    UserInputService.InputBegan:Connect(function(input)
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == (_G.INVISIBLE_STEAL_KEY or Enum.KeyCode.V) then
            pcall(_G.toggleInvisibleSteal)
        end
    end)

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0
        pcall(function()
            for _, c in pairs(Workspace.CurrentCamera:GetChildren()) do
                if c:IsA("BasePart") and c.Name == "HumanoidRootPart" then c:Destroy() end
            end
        end)
        if oldRoot then pcall(function() oldRoot:Destroy() end); oldRoot = nil end
        if clone then pcall(function() clone:Destroy() end); clone = nil end
        animPlaying = false
        _G.invisibleStealEnabled = false
        if _G.updateVisualState then _G.updateVisualState(false) end
        task.wait(0.2)
        local camera = Workspace.CurrentCamera
        if camera and newChar then
            local h = newChar:FindFirstChildOfClass("Humanoid")
            if h then camera.CameraSubject = h; camera.CameraType = Enum.CameraType.Custom end
        end
    end)

    local function setupDeathListener()
        local ch = LocalPlayer.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then
                h.Died:Connect(function()
                    clearErrorOrb(); clearAllGhosts(); lagbackCallCount = 0
                end)
            end
        end
    end
    setupDeathListener()
    LocalPlayer.CharacterAdded:Connect(function() task.wait(0.1); setupDeathListener() end)

    local currentConnection = nil
    _G.AntiDieDisabled = false
    local function setupAntiDie()
        if _G.AntiDieDisabled then return end
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        if currentConnection then pcall(function() currentConnection:Disconnect() end) end
        currentConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if _G.AntiDieDisabled then return end
            if humanoid.Health <= 0 then humanoid.Health = humanoid.MaxHealth end
        end)
        _G.AntiDieConnection = currentConnection
    end
    _G.setupAntiDie = setupAntiDie
    setupAntiDie()
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if not _G.AntiDieDisabled then setupAntiDie() end
    end)

    local wasStealingForInvis = false
    local autoEnabledInvis = false
    task.wait(1)
    while task.wait(0.1) do
        if not _G.AutoInvisDuringSteal then
            wasStealingForInvis = false
            autoEnabledInvis = false
        else
            local isStealing = LocalPlayer:GetAttribute("Stealing")
            if isStealing and not wasStealingForInvis then
                if not _G.invisibleStealEnabled and _G.toggleInvisibleSteal then
                    task.delay(0.25, function()
                        if LocalPlayer:GetAttribute("Stealing") and not _G.invisibleStealEnabled then
                            pcall(_G.toggleInvisibleSteal)
                            autoEnabledInvis = true
                        end
                    end)
                end
            end
            if not isStealing and autoEnabledInvis and _G.invisibleStealEnabled and _G.toggleInvisibleSteal then
                pcall(_G.toggleInvisibleSteal)
                autoEnabledInvis = false
            end
            wasStealingForInvis = isStealing
        end
    end
end)

task.spawn(function()
    local function getChar()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        return char, char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
    end

    local function hasExclamation(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BillboardGui") then
                local label = d:FindFirstChildWhichIsA("TextLabel", true)
                if label and label.Text:find("!") then return true end
            end
        end
        return false
    end

    local function applyVisuals(target)
        for _, d in ipairs(target:GetDescendants()) do
            if d:IsA("BasePart") and d ~= target then
                d.Transparency = 0.5; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
            elseif d:IsA("BillboardGui") and d.Name ~= "SentryLabel" then
                d:Destroy()
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 0.5
            end
        end
        if target:IsA("BasePart") and target.Name ~= "ProxyVisual" then
            target.Transparency = 1; target.CanCollide = false
        end
    end

    local function getClosestSentry()
        local _, hrp = getChar()
        local closest, shortestDist = nil, math.huge
        for _, inst in ipairs(Workspace:GetDescendants()) do
            if inst.Name:match("^Sentry_") and hasExclamation(inst) then
                local root = inst:IsA("BasePart") and inst or inst:FindFirstChildWhichIsA("BasePart", true)
                if root then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist < shortestDist then shortestDist = dist; closest = inst end
                end
            end
        end
        return closest
    end

    while true do
        if Config.AutoDestroyTurrets then
            if LocalPlayer:GetAttribute("Stealing") == true then
                task.wait(0.5)
            else
                local targetSentry = getClosestSentry()
                if targetSentry then
                    while targetSentry and targetSentry.Parent and LocalPlayer:GetAttribute("Stealing") ~= true do
                        local char, hrp, hum = getChar()
                        local bat = LocalPlayer.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
                        applyVisuals(targetSentry)
                        local targetCF = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 4, hrp.Position)
                        if targetSentry:IsA("Model") then targetSentry:PivotTo(targetCF)
                        elseif targetSentry:IsA("BasePart") then targetSentry.CFrame = targetCF end
                        if bat then
                            if bat.Parent ~= char then hum:EquipTool(bat) end
                            bat:Activate()
                        end
                        task.wait(0.1)
                        if not hasExclamation(targetSentry) then break end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

SharedState.FOV_MANAGER = {
    activeCount = 0,
    conn = nil,
    forcedFOV = 70,
}
function SharedState.FOV_MANAGER:Start()
    if self.conn then return end
    self.forcedFOV = Config.FOV or 70
    self.conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local targetFOV = Config.FOV or self.forcedFOV
            if cam.FieldOfView ~= targetFOV then
                cam.FieldOfView = targetFOV
            end
        end
    end)
end
function SharedState.FOV_MANAGER:Stop()
    if self.conn then
        self.conn:Disconnect()
        self.conn = nil
    end
end
function SharedState.FOV_MANAGER:Push()
    self.activeCount = self.activeCount + 1
    self:Start()
end
function SharedState.FOV_MANAGER:Pop()
    if self.activeCount > 0 then
        self.activeCount = self.activeCount - 1
    end
    if self.activeCount == 0 then
        self:Stop()
    end
end

SharedState.ANTI_BEE_DISCO = {
    running = false,
    connections = {},
    originalMoveFunction = nil,
    controlsProtected = false,
    badLightingNames = { Blue = true, DiscoEffect = true, BeeBlur = true, ColorCorrection = true },
}
function SharedState.ANTI_BEE_DISCO.nuke(obj)
    if not obj or not obj.Parent then return end
    if SharedState.ANTI_BEE_DISCO.badLightingNames[obj.Name] then
        pcall(function() obj:Destroy() end)
    end
end
function SharedState.ANTI_BEE_DISCO.disconnectAll()
    for _, conn in ipairs(SharedState.ANTI_BEE_DISCO.connections) do
        if typeof(conn) == "RBXScriptConnection" then conn:Disconnect() end
    end
    SharedState.ANTI_BEE_DISCO.connections = {}
end
function SharedState.ANTI_BEE_DISCO.protectControls()
    if SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerScripts = LocalPlayer.PlayerScripts
        local PlayerModule = PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        if not Controls then return end
        local ab = SharedState.ANTI_BEE_DISCO
        if not ab.originalMoveFunction then ab.originalMoveFunction = Controls.moveFunction end
        local function protectedMoveFunction(self, moveVector, relativeToCamera)
            if ab.originalMoveFunction then ab.originalMoveFunction(self, moveVector, relativeToCamera) end
        end
        table.insert(ab.connections, RunService.Heartbeat:Connect(function()
            if not ab.running or not Config.AntiBeeDisco then return end
            if Controls.moveFunction ~= protectedMoveFunction then Controls.moveFunction = protectedMoveFunction end
        end))
        Controls.moveFunction = protectedMoveFunction
        ab.controlsProtected = true
    end)
end
function SharedState.ANTI_BEE_DISCO.restoreControls()
    if not SharedState.ANTI_BEE_DISCO.controlsProtected then return end
    pcall(function()
        local PlayerModule = LocalPlayer.PlayerScripts:FindFirstChild("PlayerModule")
        if not PlayerModule then return end
        local Controls = require(PlayerModule):GetControls()
        local ab = SharedState.ANTI_BEE_DISCO
        if Controls and ab.originalMoveFunction then
            Controls.moveFunction = ab.originalMoveFunction
            ab.controlsProtected = false
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.blockBuzzingSound()
    pcall(function()
        local beeScript = LocalPlayer.PlayerScripts:FindFirstChild("Bee", true)
        if beeScript then
            local buzzing = beeScript:FindFirstChild("Buzzing")
            if buzzing and buzzing:IsA("Sound") then buzzing:Stop(); buzzing.Volume = 0 end
        end
    end)
end
function SharedState.ANTI_BEE_DISCO.Enable()
    local ab = SharedState.ANTI_BEE_DISCO
    if ab.running then return end
    ab.running = true
    for _, inst in ipairs(Lighting:GetDescendants()) do ab.nuke(inst) end
    table.insert(ab.connections, Lighting.DescendantAdded:Connect(function(obj)
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.nuke(obj)
    end))
    ab.protectControls()
    table.insert(ab.connections, RunService.Heartbeat:Connect(function()
        if not ab.running or not Config.AntiBeeDisco then return end
        ab.blockBuzzingSound()
    end))
    SharedState.FOV_MANAGER:Push()
    ShowNotification("ANTI-BEE & DISCO", "Enabled")
end
function SharedState.ANTI_BEE_DISCO.Disable()
    local ab = SharedState.ANTI_BEE_DISCO
    if not ab.running then return end
    ab.running = false
    ab.restoreControls()
    ab.disconnectAll()
    SharedState.FOV_MANAGER:Pop()
    ShowNotification("ANTI-BEE & DISCO", "Disabled")
end

_G.ANTI_BEE_DISCO = SharedState.ANTI_BEE_DISCO

if Config.AntiBeeDisco then
    task.delay(1, function()
        if SharedState.ANTI_BEE_DISCO.Enable then SharedState.ANTI_BEE_DISCO.Enable() end
    end)
end

task.spawn(function()
    while true do
        if Workspace.CurrentCamera then
            if Config.FOV and Config.FOV ~= Workspace.CurrentCamera.FieldOfView then
                Workspace.CurrentCamera.FieldOfView = Config.FOV
            end
        end
        task.wait(0.1)
    end
end)

function applyUIScale(scale)
    local targets = {
        {guiName = "AutoStealUI",       frameName = nil},
        {guiName = "SyllinseAdminPanel", frameName = nil},
        {guiName = "CooldownTracker",   frameName = nil},
        {guiName = "SyllinsePanel",     frameName = nil},
    }
    for _, t in ipairs(targets) do
        local gui = PlayerGui:FindFirstChild(t.guiName)
        if gui then
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("Frame") and child.Parent == gui then
                    local sc = child:FindFirstChildOfClass("UIScale")
                    if not sc then
                        sc = Instance.new("UIScale")
                        sc.Parent = child
                    end
                    sc.Scale = scale
                end
            end
            local topFrame = gui:FindFirstChildOfClass("Frame")
            if topFrame then
                local sc = topFrame:FindFirstChildOfClass("UIScale")
                if not sc then
                    sc = Instance.new("UIScale")
                    sc.Parent = topFrame
                end
                sc.Scale = scale
            end
        end
    end
    Config.UIScale = scale
    SaveConfig()
end
 
curTabContainer = tabContainers["General"]
 
local rUIScale = CreateRow("UI Scale")
local uiScaleDefault = Config.UIScale or 1.0
 
local uiScaleSliderBg = Instance.new("Frame", rUIScale)
uiScaleSliderBg.Size = UDim2.new(0, 140, 0, 5)
uiScaleSliderBg.Position = UDim2.new(1, -200, 0.5, -2.5)
uiScaleSliderBg.BackgroundColor3 = Color3.fromRGB(30, 32, 38)
uiScaleSliderBg.BorderSizePixel = 0
Instance.new("UICorner", uiScaleSliderBg).CornerRadius = UDim.new(1, 0)
 
local uiScaleFill = Instance.new("Frame", uiScaleSliderBg)
uiScaleFill.BackgroundColor3 = Theme.Accent1
uiScaleFill.BorderSizePixel = 0
uiScaleFill.Size = UDim2.new(0, 0, 1, 0)
Instance.new("UICorner", uiScaleFill).CornerRadius = UDim.new(1, 0)
 
local uiScaleKnob = Instance.new("Frame", uiScaleSliderBg)
uiScaleKnob.Size = UDim2.new(0, 12, 0, 12)
uiScaleKnob.BackgroundColor3 = Theme.TextPrimary
uiScaleKnob.AnchorPoint = Vector2.new(0.5, 0.5)
uiScaleKnob.Position = UDim2.new(0, 0, 0.5, 0)
uiScaleKnob.BorderSizePixel = 0
Instance.new("UICorner", uiScaleKnob).CornerRadius = UDim.new(1, 0)
local uiScaleKnobStroke = Instance.new("UIStroke", uiScaleKnob)
uiScaleKnobStroke.Color = Theme.Accent1
uiScaleKnobStroke.Thickness = 1.5
uiScaleKnobStroke.Transparency = 0.2
 
local uiScaleValLbl = Instance.new("TextLabel", rUIScale)
uiScaleValLbl.Size = UDim2.new(0, 40, 0, 20)
uiScaleValLbl.Position = UDim2.new(1, -50, 0.5, -10)
uiScaleValLbl.BackgroundTransparency = 1
uiScaleValLbl.Font = Enum.Font.GothamMedium
uiScaleValLbl.TextSize = 13
uiScaleValLbl.TextColor3 = Theme.TextPrimary
 
function updateUIScaleSlider(val)
    val = math.clamp(math.floor(val * 10) / 10, 0.1, 1.0)
    local pct = (val - 0.1) / 0.9
    uiScaleFill.Size = UDim2.new(pct, 0, 1, 0)
    uiScaleKnob.Position = UDim2.new(pct, 0, 0.5, 0)
    uiScaleValLbl.Text = string.format("%.1f", val)
    applyUIScale(val)
end
 
updateUIScaleSlider(uiScaleDefault)
 
local uiScaleDragging = false
uiScaleSliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        uiScaleDragging = true
        local x = i.Position.X
        local r = uiScaleSliderBg.AbsolutePosition.X
        local w = uiScaleSliderBg.AbsoluteSize.X
        local p = math.clamp((x - r) / w, 0, 1)
        updateUIScaleSlider(0.1 + p * 0.9)
    end
end)
uiScaleKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then uiScaleDragging = true end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then uiScaleDragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if uiScaleDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local x = i.Position.X
        local r = uiScaleSliderBg.AbsolutePosition.X
        local w = uiScaleSliderBg.AbsoluteSize.X
        local p = math.clamp((x - r) / w, 0, 1)
        updateUIScaleSlider(0.1 + p * 0.9)
    end
end)
 
local rUIScaleReset = CreateRow("Reset UI Scale")
local bUIScaleReset = Instance.new("TextButton", rUIScaleReset)
bUIScaleReset.Size = UDim2.new(0, 60, 0, 24)
bUIScaleReset.Position = UDim2.new(1, -70, 0.5, -12)
bUIScaleReset.BackgroundColor3 = Theme.SurfaceHighlight
bUIScaleReset.Text = "Reset"
bUIScaleReset.Font = Enum.Font.GothamMedium
bUIScaleReset.TextColor3 = Theme.TextPrimary
bUIScaleReset.TextSize = 12
bUIScaleReset.BorderSizePixel = 0
Instance.new("UICorner", bUIScaleReset).CornerRadius = UDim.new(1, 0)
bUIScaleReset.MouseButton1Click:Connect(function()
    updateUIScaleSlider(1.0)
    ShowNotification("UI SCALE", "Reset to 1.0")
end)


task.spawn(function()
    if IS_MOBILE then return end
    if PlayerGui:FindFirstChild("SyllinseHUD") then PlayerGui.SyllinseHUD:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SyllinseHUD"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.AnchorPoint = Vector2.new(0.5, 0)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Main.BackgroundTransparency = 0.08
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, 0, 0, 18)
    Main.Size = UDim2.new(0, 420, 0, 58)
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 0.85
    UIScale.Parent = Main

    local borderStroke = Instance.new("UIStroke", Main)
    borderStroke.Color = Color3.fromRGB(55, 55, 70)
    borderStroke.Thickness = 1
    borderStroke.Transparency = 0.5

    local accentBar = Instance.new("Frame", Main)
    accentBar.Size = UDim2.new(1, 0, 0, 2)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 5
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 12)

    local innerGlow = Instance.new("Frame", Main)
    innerGlow.Size = UDim2.new(1, -4, 1, -4)
    innerGlow.Position = UDim2.new(0, 2, 0, 2)
    innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlow.BackgroundTransparency = 0.96
    innerGlow.BorderSizePixel = 0
    Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(0, 10)

    local function getCurrentTime()
        local time = os.date("*t")
        local hour = time.hour
        local minute = string.format("%02d", time.min)
        local period = hour >= 12 and "PM" or "AM"
        hour = hour % 12
        if hour == 0 then hour = 12 end
        return string.format("%d:%s %s", hour, minute, period)
    end

    local logoLabel = Instance.new("ImageLabel", Main)
    logoLabel.Size = UDim2.new(0, 32, 0, 32)
    logoLabel.Position = UDim2.new(0, 12, 0.5, -16)
    logoLabel.BackgroundTransparency = 1
    logoLabel.Image = "rbxassetid://96928078987243"
    logoLabel.ImageTransparency = 0.1

    local titleLabel = Instance.new("TextLabel", Main) 
    titleLabel.Size = UDim2.new(0, 80, 0, 22)
    titleLabel.Position = UDim2.new(0, 52, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "SYLLINSE"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local timeLabel = Instance.new("TextLabel", Main)
    timeLabel.Size = UDim2.new(0, 90, 0, 16)
    timeLabel.Position = UDim2.new(0, 52, 0, 34)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = getCurrentTime()
    timeLabel.Font = Enum.Font.GothamMedium
    timeLabel.TextSize = 10
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local divider1 = Instance.new("Frame", Main)
    divider1.Size = UDim2.new(0, 1, 1, -16)
    divider1.Position = UDim2.new(0, 178, 0, 8)
    divider1.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    divider1.BorderSizePixel = 0

    local fpsValueLabel = Instance.new("TextLabel", Main)
    fpsValueLabel.Size = UDim2.new(0, 40, 0, 20)
    fpsValueLabel.Position = UDim2.new(0, 218, 0, 10)
    fpsValueLabel.BackgroundTransparency = 1
    fpsValueLabel.Font = Enum.Font.GothamBold
    fpsValueLabel.Text = "60"
    fpsValueLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
    fpsValueLabel.TextSize = 14
    fpsValueLabel.TextXAlignment = Enum.TextXAlignment.Left

    local fpsTagLabel = Instance.new("TextLabel", Main)
    fpsTagLabel.Size = UDim2.new(0, 35, 0, 16)
    fpsTagLabel.Position = UDim2.new(0, 185, 0, 12)
    fpsTagLabel.BackgroundTransparency = 1
    fpsTagLabel.Font = Enum.Font.GothamMedium
    fpsTagLabel.Text = "FPS"
    fpsTagLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    fpsTagLabel.TextSize = 11
    fpsTagLabel.TextXAlignment = Enum.TextXAlignment.Left

    local pingValueLabel = Instance.new("TextLabel", Main)
    pingValueLabel.Size = UDim2.new(0, 50, 0, 20)
    pingValueLabel.Position = UDim2.new(0, 218, 0, 32)
    pingValueLabel.BackgroundTransparency = 1
    pingValueLabel.Font = Enum.Font.GothamBold
    pingValueLabel.Text = "0ms"
    pingValueLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
    pingValueLabel.TextSize = 14
    pingValueLabel.TextXAlignment = Enum.TextXAlignment.Left

    local pingTagLabel = Instance.new("TextLabel", Main)
    pingTagLabel.Size = UDim2.new(0, 40, 0, 16)
    pingTagLabel.Position = UDim2.new(0, 185, 0, 34)
    pingTagLabel.BackgroundTransparency = 1
    pingTagLabel.Font = Enum.Font.GothamMedium
    pingTagLabel.Text = "PING"
    pingTagLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
    pingTagLabel.TextSize = 11
    pingTagLabel.TextXAlignment = Enum.TextXAlignment.Left

    local divider2 = Instance.new("Frame", Main)
    divider2.Size = UDim2.new(0, 1, 1, -16)
    divider2.Position = UDim2.new(0, 273, 0, 8)
    divider2.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    divider2.BorderSizePixel = 0

    local desyncValueLabel = Instance.new("TextLabel", Main)
    desyncValueLabel.Size = UDim2.new(0, 110, 0, 40)
    desyncValueLabel.Position = UDim2.new(0, 288, 0, 9)
    desyncValueLabel.BackgroundTransparency = 1
    desyncValueLabel.Font = Enum.Font.GothamBold
    desyncValueLabel.Text = "DESYNC: OFF"
    desyncValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    desyncValueLabel.TextSize = 13
    desyncValueLabel.TextXAlignment = Enum.TextXAlignment.Left

    local C_WHITE   = Color3.fromRGB(220, 220, 240)
    local C_GRAY    = Color3.fromRGB(160, 160, 180)
    local C_DARK    = Color3.fromRGB(120, 120, 140)
    local C_GREEN   = Color3.fromRGB(150, 200, 150)
    local C_RED     = Color3.fromRGB(200, 120, 120)

    local lastDesync = nil
    local lastFpsColor = C_WHITE
    local lastPingColor = C_WHITE
    local lastFpsVal = -1
    local lastPingVal = -1

    local frameCount = 0
    local fpsAcc = 0
    local lastFps = 60

    RunService.Heartbeat:Connect(function(dt)
        frameCount = frameCount + 1
        fpsAcc = fpsAcc + dt

        if fpsAcc >= 0.5 then
            lastFps = math.floor(frameCount / fpsAcc)
            frameCount = 0
            fpsAcc = 0
        end

        if frameCount % 10 ~= 0 then 
            if frameCount % 30 == 0 then
                timeLabel.Text = getCurrentTime()
            end
            return 
        end

        local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)

        if lastFps ~= lastFpsVal then
            lastFpsVal = lastFps
            fpsValueLabel.Text = tostring(lastFps)
            local fc = (lastFps >= 50) and C_WHITE or (lastFps >= 30) and C_GRAY or C_RED
            if fc ~= lastFpsColor then
                lastFpsColor = fc
                fpsValueLabel.TextColor3 = fc
            end
        end

        if ping ~= lastPingVal then
            lastPingVal = ping
            pingValueLabel.Text = tostring(ping) .. "ms"
            local pc = (ping < 100) and C_WHITE or (ping < 200) and C_GRAY or C_RED
            if pc ~= lastPingColor then
                lastPingColor = pc
                pingValueLabel.TextColor3 = pc
            end
        end

        local curDesync = desyncActive
        if curDesync ~= lastDesync then
            lastDesync = curDesync
            if curDesync then
                desyncValueLabel.Text = "DESYNC: ON"
                desyncValueLabel.TextColor3 = C_GREEN
            else
                desyncValueLabel.Text = "DESYNC: OFF"
                desyncValueLabel.TextColor3 = C_RED
            end
        end

        timeLabel.Text = getCurrentTime()
    end)

    local unlockContainer = Instance.new("Frame", ScreenGui)
    unlockContainer.Name = "UnlockButtonsContainer"
    unlockContainer.Size = UDim2.new(0, 160, 0, 42)
    unlockContainer.Position = UDim2.new(0.5, 0, 0, 76)
    unlockContainer.AnchorPoint = Vector2.new(0.5, 0)
    unlockContainer.BackgroundTransparency = 1
    unlockContainer.Visible = Config.ShowUnlockButtonsHUD or false

    local Scale = Instance.new("UIScale")

    Scale.Scale = 0.85
    Scale.Parent = unlockContainer

    local unlockLevels = {-2, 15, 32}
    for i = 1, 3 do
        local lvl = unlockLevels[i]
        local btn = Instance.new("TextButton", unlockContainer)
        btn.Size = UDim2.new(0, 40, 0, 36)
        btn.Position = UDim2.new(0, (i - 1) * 52, 0, 0)
        btn.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
        btn.BackgroundTransparency = 0
        btn.Text = tostring(i)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = Color3.fromRGB(70, 70, 90)
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5

        local C_ACTIVE = Color3.fromRGB(45, 45, 55)
        local C_INACTIVE = Color3.fromRGB(25, 25, 32)
        local CT_ACTIVE = Color3.fromRGB(220, 220, 240)
        local CT_INACTIVE = Color3.fromRGB(180, 180, 210)

        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = C_ON
            btn.TextColor3 = CT_ON
            btnStroke.Transparency = 0.2
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = C_OFF
            btn.TextColor3 = CT_OFF
            btnStroke.Transparency = 0.5
        end)
        btn.MouseButton1Click:Connect(function()
            triggerClosestUnlock(lvl)
            ShowNotification("UNLOCK", "Level " .. i)
        end)
    end
    
    local function updateTime()
        while ScreenGui and ScreenGui.Parent do
            task.wait(10)
            if timeLabel and timeLabel.Parent then
                timeLabel.Text = getCurrentTime()
            end
        end
    end
    
    task.spawn(updateTime)
end)



task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))

    local playerESPEnabled = Config.PlayerESP
    local playerBillboards = {}
    local playerHighlights = {}

    local SOV = Vector3.new(0, 2.5, 0)
    local C_ACC = Color3.fromRGB(220, 220, 240)
    local C_BLK = Color3.fromRGB(0, 0, 0)
    local NONE_TYPE = Enum.HumanoidDisplayDistanceType.None
    local VIEWER_TYPE = Enum.HumanoidDisplayDistanceType.Viewer
    
    local HIGHLIGHT_STEAL = Color3.fromRGB(255, 100, 100)
    local HIGHLIGHT_NORMAL = Color3.fromRGB(200, 200, 220)

    function makePlayerBillboard(player)
        local bb = Instance.new("BillboardGui")
        bb.Name = "PlayerESP_" .. tostring(player.UserId)
        bb.Size = UDim2.new(0, 160, 0, 32)
        bb.StudsOffsetWorldSpace = SOV
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.ResetOnSpawn = false
        bb.ZIndexBehavior = Enum.ZIndexBehavior.Global
        bb.Enabled = true
        
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
        nameLbl.Position = UDim2.new(0, 0, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBlack
        nameLbl.TextSize = 20
        nameLbl.TextColor3 = C_ACC
        nameLbl.TextXAlignment = Enum.TextXAlignment.Center
        nameLbl.TextStrokeTransparency = 0.15
        nameLbl.TextStrokeColor3 = C_BLK
        nameLbl.Text = player.DisplayName or player.Name

        local stealLbl = Instance.new("TextLabel", bb)
        stealLbl.Size = UDim2.new(1, 0, 0.5, 0)
        stealLbl.Position = UDim2.new(0, 0, 0.5, 0)
        stealLbl.BackgroundTransparency = 1
        stealLbl.Font = Enum.Font.GothamBold
        stealLbl.TextSize = 16
        stealLbl.TextColor3 = HIGHLIGHT_STEAL
        stealLbl.TextXAlignment = Enum.TextXAlignment.Center
        stealLbl.TextStrokeTransparency = 0.2
        stealLbl.TextStrokeColor3 = C_BLK
        stealLbl.Text = ""
        
        return bb, nameLbl, stealLbl
    end

    function makePlayerHighlight(player)
        local char = player.Character
        if not char then return nil end
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "PlayerESP_Highlight_" .. tostring(player.UserId)
        highlight.FillTransparency = 0.4
        highlight.OutlineTransparency = 0.2
        highlight.OutlineColor = HIGHLIGHT_NORMAL
        highlight.FillColor = HIGHLIGHT_NORMAL
        highlight.Adornee = char
        highlight.Parent = char
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        return highlight
    end

    function updateHighlightColor(highlight, isStealing)
        if not highlight then return end
        if isStealing then
            highlight.FillColor = HIGHLIGHT_STEAL
            highlight.OutlineColor = HIGHLIGHT_STEAL
            highlight.FillTransparency = 0.35
        else
            highlight.FillColor = HIGHLIGHT_NORMAL
            highlight.OutlineColor = HIGHLIGHT_NORMAL
            highlight.FillTransparency = 0.4
        end
    end

    function createOrRefresh(player)
        if player == LocalPlayer then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChild("Humanoid")
        if hum and hum.DisplayDistanceType ~= NONE_TYPE then
            hum.DisplayDistanceType = NONE_TYPE
        end
        
        local uid = player.UserId
        local entry = playerBillboards[uid]
        local isStealing = player:GetAttribute("Stealing") == true
        local stealingBrainrot = player:GetAttribute("StealingIndex") or ""
        
        if not entry or not entry.bb or not entry.bb.Parent then
            if entry and entry.bb then pcall(function() entry.bb:Destroy() end) end
            local bb, nameLbl, stealLbl = makePlayerBillboard(player)
            bb.Adornee = hrp
            bb.Parent = hrp
            playerBillboards[uid] = {
                bb = bb, 
                nameLbl = nameLbl,
                stealLbl = stealLbl,
                player = player
            }
            entry = playerBillboards[uid]
        elseif entry.bb.Adornee ~= hrp then
            entry.bb.Adornee = hrp
            entry.bb.Parent = hrp
        end
        
        if entry then
            if isStealing then
                entry.nameLbl.TextColor3 = HIGHLIGHT_STEAL
                entry.stealLbl.Text = "STEALING: " .. (stealingBrainrot)
            else
                entry.nameLbl.TextColor3 = C_ACC
                entry.stealLbl.Text = ""
            end
        end
        
        local highlightEntry = playerHighlights[uid]
        if not highlightEntry or not highlightEntry.Parent then
            local newHighlight = makePlayerHighlight(player)
            if newHighlight then
                playerHighlights[uid] = newHighlight
                updateHighlightColor(newHighlight, isStealing)
            end
        else
            if highlightEntry.Parent ~= char then
                highlightEntry.Adornee = char
                highlightEntry.Parent = char
            end
            updateHighlightColor(highlightEntry, isStealing)
        end
    end

    function clearAll()
        for uid, entry in pairs(playerBillboards) do
            if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
            playerBillboards[uid] = nil
        end
        for uid, highlight in pairs(playerHighlights) do
            if highlight and highlight.Parent then pcall(function() highlight:Destroy() end) end
            playerHighlights[uid] = nil
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("Humanoid")
                if h then h.DisplayDistanceType = VIEWER_TYPE end
            end
        end
    end

    playerESPToggleRef.setFn = function(enabled)
        playerESPEnabled = enabled
        if not enabled then 
            clearAll() 
        end
    end

    local function onCharAdded(p)
        task.wait(0.5)
        if playerESPEnabled then 
            pcall(createOrRefresh, p) 
        end
    end

    local function onAttributeChanged(player, attribute)
        if attribute == "Stealing" then
            if playerESPEnabled and player ~= LocalPlayer then
                pcall(createOrRefresh, player)
            end
        end
    end

    Players.PlayerAdded:Connect(function(p)
        p.CharacterAdded:Connect(function() onCharAdded(p) end)
        p.AttributeChanged:Connect(function(attr) onAttributeChanged(p, attr) end)
    end)
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            p.CharacterAdded:Connect(function() onCharAdded(p) end)
            p.AttributeChanged:Connect(function(attr) onAttributeChanged(p, attr) end)
            task.wait(0.1)
            pcall(createOrRefresh, p)
        end
    end

    while true do
        task.wait(1)
        if not playerESPEnabled then 
            task.wait()
            continue 
        end
        for uid, entry in pairs(playerBillboards) do
            if not Players:GetPlayerByUserId(uid) then
                if entry.bb and entry.bb.Parent then pcall(function() entry.bb:Destroy() end) end
                playerBillboards[uid] = nil
            end
        end
        for uid, highlight in pairs(playerHighlights) do
            if not Players:GetPlayerByUserId(uid) then
                if highlight and highlight.Parent then pcall(function() highlight:Destroy() end) end
                playerHighlights[uid] = nil
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then 
                pcall(createOrRefresh, player) 
            end
        end
    end
end)


task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local AnimalsData = require(Datas:WaitForChild("Animals"))

    local secretPets = (function()
        local list = {}
        for petName, data in pairs(AnimalsData) do
            if data.Rarity == "Secret" and not petName:find("Lucky Block") then
                table.insert(list, petName)
            end
        end
        table.sort(list)
        return list
    end)()

    local ogPets = (function()
        local list = {}
        for petName, data in pairs(AnimalsData) do
            if data.Rarity == "OG" then
                table.insert(list, petName)
            end
        end
        table.sort(list)
        return list
    end)()

    if not Config.PriorityList or type(Config.PriorityList) ~= "table" then
        Config.PriorityList = {}
        for _, pet in ipairs(secretPets) do
            table.insert(Config.PriorityList, pet)
        end
        for _, pet in ipairs(ogPets) do
            table.insert(Config.PriorityList, pet)
        end
    end

    local PRIORITY_LIST = Config.PriorityList

    local function savePriorityList()
        Config.PriorityList = PRIORITY_LIST
        SaveConfig()
        if SharedState and SharedState.UpdateAutoStealUI then
            SharedState.ListNeedsRedraw = true
            SharedState.UpdateAutoStealUI()
        end
    end

    local priorityGui = Instance.new("ScreenGui")
    priorityGui.Name = "PriorityListGUI"
    priorityGui.ResetOnSpawn = false
    priorityGui.Parent = PlayerGui
    priorityGui.Enabled = false
    priorityGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 700, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -325)
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = priorityGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Color3.fromRGB(60, 60, 80)
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.4

    local innerGlowMain = Instance.new("Frame", mainFrame)
    innerGlowMain.Size = UDim2.new(1, -4, 1, -4)
    innerGlowMain.Position = UDim2.new(0, 2, 0, 2)
    innerGlowMain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlowMain.BackgroundTransparency = 0.96
    innerGlowMain.BorderSizePixel = 0
    Instance.new("UICorner", innerGlowMain).CornerRadius = UDim.new(0, 14)

    local accentTop = Instance.new("Frame", mainFrame)
    accentTop.Size = UDim2.new(1, 0, 0, 2)
    accentTop.Position = UDim2.new(0, 0, 0, 0)
    accentTop.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
    accentTop.BorderSizePixel = 0
    accentTop.ZIndex = 5
    Instance.new("UICorner", accentTop).CornerRadius = UDim.new(0, 16)

    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 56)
    header.Position = UDim2.new(0, 0, 0, 2)
    header.BackgroundTransparency = 1
    MakeDraggable(header, mainFrame, nil)

    do
        local resizeBtn = Instance.new("TextButton", header)
        resizeBtn.Size = UDim2.new(0, 22, 0, 22)
        resizeBtn.Position = UDim2.new(1, -30, 0.5, -11)
        resizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        resizeBtn.Text = "↕"
        resizeBtn.Font = Enum.Font.GothamMedium
        resizeBtn.TextSize = 11
        resizeBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
        resizeBtn.ZIndex = 10
        Instance.new("UICorner", resizeBtn).CornerRadius = UDim.new(1, 0)
        MakeResizable(resizeBtn, mainFrame)
    end

    local titleLabel = Instance.new("TextLabel", header)
    titleLabel.Size = UDim2.new(1, -180, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PRIORITY LIST"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    local headerSep = Instance.new("Frame", mainFrame)
    headerSep.Size = UDim2.new(1, -40, 0, 1)
    headerSep.Position = UDim2.new(0, 20, 0, 58)
    headerSep.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    headerSep.BorderSizePixel = 0

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 80, 0, 30)
    closeBtn.Position = UDim2.new(1, -110, 0.5, -15)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    closeBtn.Text = "CLOSE"
    closeBtn.Font = Enum.Font.GothamMedium
    closeBtn.TextSize = 11
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
    local closeBtnStroke = Instance.new("UIStroke", closeBtn)
    closeBtnStroke.Color = Color3.fromRGB(60, 60, 80)
    closeBtnStroke.Thickness = 1
    closeBtnStroke.Transparency = 0.4
    closeBtn.MouseButton1Click:Connect(function() priorityGui.Enabled = false end)

    local contentFrame = Instance.new("Frame", mainFrame)
    contentFrame.Size = UDim2.new(1, -40, 1, -140)
    contentFrame.Position = UDim2.new(0, 20, 0, 68)
    contentFrame.BackgroundTransparency = 1

    local function makeScrollPanel(xPos, labelText)
        local panelFrame = Instance.new("Frame", contentFrame)
        panelFrame.Size = UDim2.new(0.47, 0, 1, 0)
        panelFrame.Position = UDim2.new(xPos, 0, 0, 0)
        panelFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        panelFrame.BackgroundTransparency = 0.2
        panelFrame.BorderSizePixel = 0
        Instance.new("UICorner", panelFrame).CornerRadius = UDim.new(0, 12)

        local panelStroke = Instance.new("UIStroke", panelFrame)
        panelStroke.Color = Color3.fromRGB(50, 50, 68)
        panelStroke.Thickness = 1
        panelStroke.Transparency = 0.3

        local panelInnerGlow = Instance.new("Frame", panelFrame)
        panelInnerGlow.Size = UDim2.new(1, -4, 1, -4)
        panelInnerGlow.Position = UDim2.new(0, 2, 0, 2)
        panelInnerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        panelInnerGlow.BackgroundTransparency = 0.97
        panelInnerGlow.BorderSizePixel = 0
        Instance.new("UICorner", panelInnerGlow).CornerRadius = UDim.new(0, 10)

        local headerBar = Instance.new("Frame", panelFrame)
        headerBar.Size = UDim2.new(1, 0, 0, 38)
        headerBar.Position = UDim2.new(0, 0, 0, 0)
        headerBar.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        headerBar.BackgroundTransparency = 0.3
        headerBar.BorderSizePixel = 0
        Instance.new("UICorner", headerBar).CornerRadius = UDim.new(0, 12)

        local headerBarBottom = Instance.new("Frame", headerBar)
        headerBarBottom.Size = UDim2.new(1, 0, 0.5, 0)
        headerBarBottom.Position = UDim2.new(0, 0, 0.5, 0)
        headerBarBottom.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
        headerBarBottom.BackgroundTransparency = 0.3
        headerBarBottom.BorderSizePixel = 0

        local lbl = Instance.new("TextLabel", headerBar)
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 14, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextColor3 = Color3.fromRGB(180, 180, 210)
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local countBadge = Instance.new("Frame", headerBar)
        countBadge.Size = UDim2.new(0, 36, 0, 20)
        countBadge.Position = UDim2.new(1, -46, 0.5, -10)
        countBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
        countBadge.BorderSizePixel = 0
        Instance.new("UICorner", countBadge).CornerRadius = UDim.new(0, 6)
        local countBadgeStroke = Instance.new("UIStroke", countBadge)
        countBadgeStroke.Color = Color3.fromRGB(60, 60, 80)
        countBadgeStroke.Thickness = 1
        countBadgeStroke.Transparency = 0.4

        local countLabel = Instance.new("TextLabel", countBadge)
        countLabel.Size = UDim2.new(1, 0, 1, 0)
        countLabel.BackgroundTransparency = 1
        countLabel.Text = "0"
        countLabel.Font = Enum.Font.GothamBold
        countLabel.TextSize = 11
        countLabel.TextColor3 = Color3.fromRGB(180, 180, 210)

        local scroll = Instance.new("ScrollingFrame", panelFrame)
        scroll.Size = UDim2.new(1, -16, 1, -48)
        scroll.Position = UDim2.new(0, 8, 0, 42)
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 110)

        local pad = Instance.new("UIPadding", scroll)
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)

        local layout = Instance.new("UIListLayout", scroll)
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder

        return scroll, layout, countLabel
    end

    local availableScroll, availableListLayout, availableCount = makeScrollPanel(0, "AVAILABLE BRAINROTS")
    local priorityScroll, priorityListLayout, priorityCount = makeScrollPanel(0.53, "PRIORITY LIST")

    local priorityButtons = {}
    local availableButtons = {}

    local function updateScrollSizes()
        task.defer(function()
            availableScroll.CanvasSize = UDim2.new(0, 0, 0, availableListLayout.AbsoluteContentSize.Y + 12)
            priorityScroll.CanvasSize = UDim2.new(0, 0, 0, priorityListLayout.AbsoluteContentSize.Y + 12)
            availableCount.Text = tostring(#availableButtons)
            priorityCount.Text = tostring(#priorityButtons)
        end)
    end

    availableListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)
    priorityListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateScrollSizes)

    local function makeSmallBtn(parent, text, xOffset)
        local b = Instance.new("TextButton", parent)
        b.Size = UDim2.new(0, 28, 0, 24)
        b.Position = UDim2.new(1, xOffset, 0.5, 0)
        b.AnchorPoint = Vector2.new(0, 0.5)
        b.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 10
        b.TextColor3 = Color3.fromRGB(160, 160, 190)
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", b)
        s.Color = Color3.fromRGB(55, 55, 75)
        s.Thickness = 1
        s.Transparency = 0.3
        return b
    end

    local refreshPriorityList
    local refreshAvailableList

    refreshPriorityList = function()
        for _, btn in ipairs(priorityButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        priorityButtons = {}

        for i, petName in ipairs(PRIORITY_LIST) do
            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 38)
            itemFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
            itemFrame.BackgroundTransparency = 0.1
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)
            local itemStroke = Instance.new("UIStroke", itemFrame)
            itemStroke.Color = Color3.fromRGB(45, 45, 62)
            itemStroke.Thickness = 1
            itemStroke.Transparency = 0.4
            itemFrame.Parent = priorityScroll

            local rankLabel = Instance.new("TextLabel", itemFrame)
            rankLabel.Size = UDim2.new(0, 30, 1, 0)
            rankLabel.Position = UDim2.new(0, 8, 0, 0)
            rankLabel.BackgroundTransparency = 1
            rankLabel.Text = "#" .. i
            rankLabel.Font = Enum.Font.GothamBold
            rankLabel.TextSize = 11
            rankLabel.TextColor3 = Color3.fromRGB(120, 120, 160)

            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -130, 1, 0)
            nameLabel.Position = UDim2.new(0, 44, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

            local upBtn = makeSmallBtn(itemFrame, "▲", -100)
            local downBtn = makeSmallBtn(itemFrame, "▼", -68)
            local remBtn = makeSmallBtn(itemFrame, "✖", -34)
            remBtn.TextColor3 = Color3.fromRGB(180, 100, 100)

            local captured = petName

            upBtn.MouseButton1Click:Connect(function()
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == captured and idx > 1 then
                        PRIORITY_LIST[idx], PRIORITY_LIST[idx-1] = PRIORITY_LIST[idx-1], PRIORITY_LIST[idx]
                        refreshPriorityList()
                        refreshAvailableList()
                        savePriorityList()
                        break
                    end
                end
            end)

            downBtn.MouseButton1Click:Connect(function()
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == captured and idx < #PRIORITY_LIST then
                        PRIORITY_LIST[idx], PRIORITY_LIST[idx+1] = PRIORITY_LIST[idx+1], PRIORITY_LIST[idx]
                        refreshPriorityList()
                        refreshAvailableList()
                        savePriorityList()
                        break
                    end
                end
            end)

            remBtn.MouseButton1Click:Connect(function()
                for idx, pName in ipairs(PRIORITY_LIST) do
                    if pName == captured then
                        table.remove(PRIORITY_LIST, idx)
                        refreshPriorityList()
                        refreshAvailableList()
                        savePriorityList()
                        break
                    end
                end
            end)

            table.insert(priorityButtons, itemFrame)
        end

        updateScrollSizes()
    end

    local prioritySet = {}
    refreshAvailableList = function()
        for _, btn in ipairs(availableButtons) do
            if btn and btn.Parent then btn:Destroy() end
        end
        availableButtons = {}

        prioritySet = {}
        for _, pName in ipairs(PRIORITY_LIST) do
            prioritySet[pName:lower()] = true
        end

        local allPets = {}
        for _, pet in ipairs(secretPets) do
            table.insert(allPets, {name = pet, rarity = "Secret"})
        end
        for _, pet in ipairs(ogPets) do
            table.insert(allPets, {name = pet, rarity = "OG"})
        end
        table.sort(allPets, function(a, b) return a.name < b.name end)

        for _, petInfo in ipairs(allPets) do
            local petName = petInfo.name
            local rarity = petInfo.rarity

            local itemFrame = Instance.new("Frame")
            itemFrame.Size = UDim2.new(1, 0, 0, 38)
            itemFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
            itemFrame.BackgroundTransparency = 0.1
            itemFrame.BorderSizePixel = 0
            Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 8)
            local itemStroke = Instance.new("UIStroke", itemFrame)
            itemStroke.Color = Color3.fromRGB(45, 45, 62)
            itemStroke.Thickness = 1
            itemStroke.Transparency = 0.4
            itemFrame.Parent = availableScroll

            if rarity == "Secret" then
                local secretBadge = Instance.new("Frame", itemFrame)
                secretBadge.Size = UDim2.new(0, 46, 0, 20)
                secretBadge.Position = UDim2.new(0, 6, 0.5, -10)
                secretBadge.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
                secretBadge.BorderSizePixel = 0
                Instance.new("UICorner", secretBadge).CornerRadius = UDim.new(0, 4)
                local secretStroke = Instance.new("UIStroke", secretBadge)
                secretStroke.Color = Color3.fromRGB(220, 220, 220)
                secretStroke.Thickness = 1.5
                secretStroke.Transparency = 0
                local secretText = Instance.new("TextLabel", secretBadge)
                secretText.Size = UDim2.new(1, 0, 1, 0)
                secretText.BackgroundTransparency = 1
                secretText.Text = "SECRET"
                secretText.Font = Enum.Font.GothamBold
                secretText.TextSize = 8
                secretText.TextColor3 = Color3.fromRGB(240, 240, 240)
            else
                local ogBadge = Instance.new("Frame", itemFrame)
                ogBadge.Size = UDim2.new(0, 36, 0, 20)
                ogBadge.Position = UDim2.new(0, 6, 0.5, -10)
                ogBadge.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
                ogBadge.ClipsDescendants = true
                ogBadge.BorderSizePixel = 0
                Instance.new("UICorner", ogBadge).CornerRadius = UDim.new(0, 4)

                local ogLeft = Instance.new("Frame", ogBadge)
                ogLeft.Size = UDim2.new(0.5, 0, 1, 0)
                ogLeft.Position = UDim2.new(0, 0, 0, 0)
                ogLeft.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
                ogLeft.BorderSizePixel = 0

                local ogRight = Instance.new("Frame", ogBadge)
                ogRight.Size = UDim2.new(0.5, 0, 1, 0)
                ogRight.Position = UDim2.new(0.5, 0, 0, 0)
                ogRight.BackgroundColor3 = Color3.fromRGB(200, 160, 20)
                ogRight.BorderSizePixel = 0

                local ogText = Instance.new("TextLabel", ogBadge)
                ogText.Size = UDim2.new(1, 0, 1, 0)
                ogText.BackgroundTransparency = 1
                ogText.Text = "OG"
                ogText.Font = Enum.Font.GothamBold
                ogText.TextSize = 9
                ogText.TextColor3 = Color3.fromRGB(240, 240, 240)
                ogText.ZIndex = 2

                local ogStroke = Instance.new("UIStroke", ogBadge)
                ogStroke.Color = Color3.fromRGB(180, 140, 10)
                ogStroke.Thickness = 1.5
                ogStroke.Transparency = 0.1
            end

            local nameLabel = Instance.new("TextLabel", itemFrame)
            nameLabel.Size = UDim2.new(1, -120, 1, 0)
            nameLabel.Position = UDim2.new(0, 60, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = petName
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextSize = 11
            nameLabel.TextColor3 = Color3.fromRGB(190, 190, 210)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

            local isIn = prioritySet[petName:lower()]
            local addBtn = Instance.new("TextButton", itemFrame)
            addBtn.Size = UDim2.new(0, 52, 0, 26)
            addBtn.Position = UDim2.new(1, -58, 0.5, 0)
            addBtn.AnchorPoint = Vector2.new(0, 0.5)
            addBtn.Font = Enum.Font.GothamBold
            addBtn.TextSize = 10
            addBtn.BorderSizePixel = 0
            Instance.new("UICorner", addBtn).CornerRadius = UDim.new(0, 6)
            local addBtnStroke = Instance.new("UIStroke", addBtn)
            addBtnStroke.Thickness = 1
            addBtnStroke.Transparency = 0.3

            local captured = petName

            if isIn then
                addBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
                addBtn.Text = "REMOVE"
                addBtn.TextColor3 = Color3.fromRGB(160, 80, 80)
                addBtnStroke.Color = Color3.fromRGB(100, 50, 50)
                addBtn.MouseButton1Click:Connect(function()
                    for i, pName in ipairs(PRIORITY_LIST) do
                        if pName:lower() == captured:lower() then
                            table.remove(PRIORITY_LIST, i)
                            refreshPriorityList()
                            refreshAvailableList()
                            savePriorityList()
                            break
                        end
                    end
                end)
            else
                addBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
                addBtn.Text = "ADD"
                addBtn.TextColor3 = Color3.fromRGB(100, 160, 100)
                addBtnStroke.Color = Color3.fromRGB(50, 100, 50)
                addBtn.MouseButton1Click:Connect(function()
                    table.insert(PRIORITY_LIST, captured)
                    refreshPriorityList()
                    refreshAvailableList()
                    savePriorityList()
                end)
            end

            table.insert(availableButtons, itemFrame)
        end

        updateScrollSizes()
    end

    refreshAvailableList()
    refreshPriorityList()

    local bottomContainer = Instance.new("Frame", mainFrame)
    bottomContainer.Size = UDim2.new(1, -40, 0, 60)
    bottomContainer.Position = UDim2.new(0, 20, 1, -68)
    bottomContainer.BackgroundTransparency = 1

    local bottomSep = Instance.new("Frame", mainFrame)
    bottomSep.Size = UDim2.new(1, -40, 0, 1)
    bottomSep.Position = UDim2.new(0, 20, 1, -72)
    bottomSep.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    bottomSep.BorderSizePixel = 0

    local resetBtn = Instance.new("TextButton", bottomContainer)
    resetBtn.Size = UDim2.new(0, 130, 0, 36)
    resetBtn.Position = UDim2.new(0, 0, 0.5, -18)
    resetBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    resetBtn.Text = "RESET DEFAULT"
    resetBtn.Font = Enum.Font.GothamMedium
    resetBtn.TextSize = 11
    resetBtn.TextColor3 = Color3.fromRGB(150, 150, 180)
    resetBtn.BorderSizePixel = 0
    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)
    local resetStroke = Instance.new("UIStroke", resetBtn)
    resetStroke.Color = Color3.fromRGB(50, 50, 70)
    resetStroke.Thickness = 1
    resetStroke.Transparency = 0.3

    resetBtn.MouseButton1Click:Connect(function()
        local defaultList = {
            "Strawberry Elephant",
            "Meowl",
            "Skibidi Toilet",
            "Headless Horseman",
            "Dragon Gingerini",
            "Dragon Cannelloni",
            "Ketupat Bros",
            "Hydra Dragon Cannelloni",
            "La Supreme Combinasion",
            "Love Love Bear",
            "Ginger Gerat",
            "Cerberus",
            "Capitano Moby",
            "La Casa Boo",
            "Burguro and Fryuro",
            "Spooky and Pumpky",
            "Cooki and Milki",
            "Rosey and Teddy",
            "Popcuru and Fizzuru",
            "Reinito Sleighito",
            "Fragrama and Chocrama",
            "Garama and Madundung",
            "Antonio",
            "La Secret Combinasion",
            "Celestial Pegasus",
            "Fishino Clownino",
            "Foxini Lanternini",
            "La Food Combinasion",
            "Griffin",
            "Signore Carapace"
        }
    
        PRIORITY_LIST = {}
        for _, pet in ipairs(defaultList) do
           table.insert(PRIORITY_LIST, pet)
        end
    
        refreshPriorityList()
        refreshAvailableList()
        savePriorityList()
    end)

    local saveBtn = Instance.new("TextButton", bottomContainer)
    saveBtn.Size = UDim2.new(0, 130, 0, 36)
    saveBtn.Position = UDim2.new(1, -130, 0.5, -18)
    saveBtn.BackgroundColor3 = Color3.fromRGB(180, 180, 210)
    saveBtn.Text = "SAVE & CLOSE"
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 11
    saveBtn.TextColor3 = Color3.fromRGB(8, 8, 14)
    saveBtn.BorderSizePixel = 0
    Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)
    saveBtn.MouseButton1Click:Connect(function()
        savePriorityList()
        priorityGui.Enabled = false
    end)

    if not IS_MOBILE then
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                priorityGui.Enabled = not priorityGui.Enabled
            end
        end)
    end
end)

task.spawn(function()
    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))

    local isStealing = false
    local baseSnapshot = {}
    local stealStartTime = 0
    local stealStartPosition = Vector3.new(0, 0, 0)

    local function GetMyPlot()
        for _, plot in ipairs(Workspace.Plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if channel then
                local owner = channel:Get("Owner")
                if (typeof(owner) == "Instance" and owner == LocalPlayer) or
                   (typeof(owner) == "table" and owner.UserId == LocalPlayer.UserId) then
                    return plot
                end
            end
        end
        return nil
    end

    local function GetPetsOnPlot(plot)
        local pets = {}
        if not plot then return pets end
        local channel = Synchronizer:Get(plot.Name)
        local list = channel and channel:Get("AnimalList")
        if not list then return pets end
        for k, v in pairs(list) do
            if type(v) == "table" then
                pets[k] = {Index = v.Index, Mutation = v.Mutation, Traits = v.Traits}
            end
        end
        return pets
    end

    local function GetInfo(data)
        local info = AnimalsData[data.Index]
        local name = info and info.DisplayName or data.Index
        local genVal = AnimalsShared:GetGeneration(data.Index, data.Mutation, data.Traits, nil)
        local valStr = "$" .. NumberUtils:ToString(genVal) .. "/s"
        return name, valStr, data.Mutation
    end

    local function TeleportToTarget()
        local targetPetData = SharedState.SelectedPetData and SharedState.SelectedPetData.animalData
        if not targetPetData then return end
        local targetPart = findAdorneeGlobal(targetPetData)
        if not targetPart then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local itemPos = targetPart.Position
        local targetY = hrp.Position.Y
        if itemPos.Y > 23.15 then
            targetY = 21
        elseif itemPos.Y >= 11 and itemPos.Y <= 23.15 then
            targetY = 14.5
        elseif itemPos.Y >= -6.9 and itemPos.Y <= 8.9 then
            targetY = -4
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = CFrame.new(itemPos.X, targetY, itemPos.Z)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if itemPos.Y > 23.15 then
            task.wait(0.05)
            if _G.enableFloat then pcall(_G.enableFloat) end
        end
    end

    LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
        local state = LocalPlayer:GetAttribute("Stealing")

        if state then
            isStealing = true
            baseSnapshot = GetPetsOnPlot(GetMyPlot())
            stealStartTime = tick()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then stealStartPosition = hrp.Position end
        else
            if not isStealing then return end
            isStealing = false

            local stealDuration = tick() - stealStartTime
            local distanceMoved = 0
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then distanceMoved = (hrp.Position - stealStartPosition).Magnitude end

            task.wait(0.1)

            local currentPets = GetPetsOnPlot(GetMyPlot())
            local stolenData = nil
            for slot, data in pairs(currentPets) do
                local old = baseSnapshot[slot]
                if not old or (old.Index ~= data.Index or old.Mutation ~= data.Mutation) then
                    stolenData = data
                    break
                end
            end

            if stolenData then
                local name, gen, mut = GetInfo(stolenData)
            elseif Config.AutoTpOnFailedSteal then
                if distanceMoved > 60 then
                    ShowNotification("STEAL FAILED", string.format("Kicked far (%.0f studs), re-sniping...", distanceMoved))
                    task.spawn(runAutoSnipe)
                elseif distanceMoved >= 2 then
                    ShowNotification("STEAL FAILED", string.format("Knocked back (%.0f studs), returning to pet...", distanceMoved))
                    task.spawn(TeleportToTarget)
                end
            end
        end
    end)
end)


SharedState.XrayData = {
    TARGET_TRANS = 0.7,
    INVISIBLE_TRANS = 1,
    ENFORCE_EVERY_FRAME = true,
    trackedObjects = {},
    trackedModels = {},
}


SharedState.XrayFunctions = {}
SharedState.XrayFunctions.nameHasClone = function(name)
	return string.find(string.lower(name), "clone", 1, true) ~= nil
end
SharedState.XrayFunctions.getTargetTransparency = function(obj)
	local xd = SharedState.XrayData
	if obj.Name == "HumanoidRootPart" then return xd.INVISIBLE_TRANS end
	return xd.TARGET_TRANS
end
SharedState.XrayFunctions.applyObject = function(obj)
	local target = SharedState.XrayFunctions.getTargetTransparency(obj)
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.Transparency = target
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		obj.Transparency = target
	end
end
SharedState.XrayFunctions.trackObject = function(obj)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedObjects[obj] then return end
	if not (obj:IsA("BasePart") or obj:IsA("Decal") or obj:IsA("Texture")) then return end
	xd.trackedObjects[obj] = true
	xf.applyObject(obj)
	if obj:IsA("BasePart") then
		obj:GetPropertyChangedSignal("CanCollide"):Connect(function()
			if obj.CanCollide ~= false then obj.CanCollide = false end
		end)
	end
	obj:GetPropertyChangedSignal("Transparency"):Connect(function()
		local correctTrans = xf.getTargetTransparency(obj)
		if obj.Transparency ~= correctTrans then obj.Transparency = correctTrans end
	end)
	obj.AncestryChanged:Connect(function()
		if obj.Parent == nil then xd.trackedObjects[obj] = nil end
	end)
end
SharedState.XrayFunctions.trackModel = function(model)
	local xd = SharedState.XrayData
	local xf = SharedState.XrayFunctions
	if xd.trackedModels[model] then return end
	xd.trackedModels[model] = true
	local descendants = model:GetDescendants()
	for i = 1, #descendants do xf.trackObject(descendants[i]) end
	model.DescendantAdded:Connect(function(d) xf.trackObject(d) end)
	model.AncestryChanged:Connect(function()
		if model.Parent == nil then xd.trackedModels[model] = nil end
	end)
end
SharedState.XrayFunctions.handleWorkspaceChild = function(child)
	if child.Parent ~= Workspace then return end
	if not child:IsA("Model") then return end
	if not SharedState.XrayFunctions.nameHasClone(child.Name) then return end
	SharedState.XrayFunctions.trackModel(child)
end
SharedState.XrayFunctions.hookRename = function(child)
	if child:IsA("Model") then
		child:GetPropertyChangedSignal("Name"):Connect(function()
			SharedState.XrayFunctions.handleWorkspaceChild(child)
		end)
	end
end
SharedState.XrayFunctions.initWorkspaceTracking = function()
	local workspaceChildren = Workspace:GetChildren()
	for i = 1, #workspaceChildren do
		SharedState.XrayFunctions.handleWorkspaceChild(workspaceChildren[i])
		SharedState.XrayFunctions.hookRename(workspaceChildren[i])
	end
end
SharedState.XrayFunctions.initWorkspaceTracking()
Workspace.ChildAdded:Connect(function(child)
	task.defer(function() SharedState.XrayFunctions.handleWorkspaceChild(child) end)
	SharedState.XrayFunctions.hookRename(child)
end)
if SharedState.XrayData.ENFORCE_EVERY_FRAME then
	SharedState.XrayFunctions.enforceXrayFrame = function()
		local xd = SharedState.XrayData
		local xf = SharedState.XrayFunctions
		local objList = {}
		for obj in pairs(xd.trackedObjects) do table.insert(objList, obj) end
		for i = 1, #objList do
			local obj = objList[i]
			if obj.Parent == nil then
				xd.trackedObjects[obj] = nil
			else
				if obj:IsA("BasePart") and obj.CanCollide ~= false then obj.CanCollide = false end
				local target = xf.getTargetTransparency(obj)
				if obj.Transparency ~= target then obj.Transparency = target end
			end
		end
	end
	RunService.Heartbeat:Connect(SharedState.XrayFunctions.enforceXrayFrame)
end

SharedState.FPSFunctions = {}
SharedState.FPSFunctions.removeMeshes = function(tool)
	if not tool:IsA("Tool") then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local descendants = handle:GetDescendants()
	for i = 1, #descendants do
		local descendant = descendants[i]
		if descendant:IsA("SpecialMesh") or descendant:IsA("Mesh") or descendant:IsA("FileMesh") then
			descendant:Destroy()
		end
	end
end
SharedState.FPSFunctions.onCharacterAdded = function(character)
	local ff = SharedState.FPSFunctions
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and Config.FPSBoost then ff.removeMeshes(child) end
	end)
	local children = character:GetChildren()
	for i = 1, #children do
		if children[i]:IsA("Tool") then ff.removeMeshes(children[i]) end
	end
end
SharedState.FPSFunctions.onPlayerAdded = function(player)
	local ff = SharedState.FPSFunctions
	player.CharacterAdded:Connect(ff.onCharacterAdded)
	if player.Character then ff.onCharacterAdded(player.Character) end
end
SharedState.FPSFunctions.initPlayerTracking = function()
	local ff = SharedState.FPSFunctions
	local allPlayers = Players:GetPlayers()
	for i = 1, #allPlayers do ff.onPlayerAdded(allPlayers[i]) end
	Players.PlayerAdded:Connect(ff.onPlayerAdded)
end
SharedState.FPSFunctions.initPlayerTracking()

if Config.CleanErrorGUIs then
    task.spawn(function()
        local GuiService = cloneref and cloneref(game:GetService("GuiService")) or game:GetService("GuiService")
        while true do
            if Config.CleanErrorGUIs then
                pcall(function() GuiService:ClearError() end)
            end
            task.wait(0.005)
        end
    end)
end

local LocalPlayer = Players.LocalPlayer

function bypassRagdoll()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    char:GetAttributeChangedSignal("RagdollEndTime"):Connect(function()
        if char:GetAttribute("RagdollEndTime") then
            char:SetAttribute("RagdollEndTime", nil)
        end
    end)
    
    local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if PlayerScripts then
        local PlayerModule = require(PlayerScripts:FindFirstChild("PlayerModule"))
        local Controls = PlayerModule:GetControls()
        
        local originalDisable = Controls.Disable
        Controls.Disable = function()
        end
        
        Controls:Enable()
    end
end

LocalPlayer.CharacterAdded:Connect(bypassRagdoll)
if LocalPlayer.Character then bypassRagdoll() end


local decalsyeeted = true 
local g = game
local w = g.Workspace
local l = g.Lighting
local t = w.Terrain
sethiddenproperty(l,"Technology",2)
sethiddenproperty(t,"Decoration",false)
t.WaterWaveSize = 0
t.WaterWaveSpeed = 0
t.WaterReflectance = 0
t.WaterTransparency = 0
l.GlobalShadows = 0
l.FogEnd = 9e9
l.Brightness = 0
settings().Rendering.QualityLevel = "Level01"
for i, v in pairs(w:GetDescendants()) do
    if v:IsA("BasePart") and not v:IsA("MeshPart") then
        v.Material = "Plastic"
        v.Reflectance = 0
    elseif (v:IsA("Decal") or v:IsA("Texture")) and decalsyeeted then
        v.Transparency = 1
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Lifetime = NumberRange.new(0)
    elseif v:IsA("Explosion") then
        v.BlastPressure = 1
        v.BlastRadius = 1
    elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
        v.Enabled = false
    elseif v:IsA("MeshPart") and decalsyeeted then
        v.Material = "Plastic"
        v.Reflectance = 0
        v.TextureID = 10385902758728957
    elseif v:IsA("SpecialMesh") and decalsyeeted  then
        v.TextureId=0
    elseif v:IsA("ShirtGraphic") and decalsyeeted then
        v.Graphic=0
    elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
        v[v.ClassName.."Template"]=0
    end
end
for i = 1,#l:GetChildren() do
    e=l:GetChildren()[i]
    if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
        e.Enabled = false
    end
end
w.DescendantAdded:Connect(function(v)
    wait()
   if v:IsA("BasePart") and not v:IsA("MeshPart") then
        v.Material = "Plastic"
        v.Reflectance = 0
    elseif v:IsA("Decal") or v:IsA("Texture") and decalsyeeted then
        v.Transparency = 1
    elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
        v.Lifetime = NumberRange.new(0)
    elseif v:IsA("Explosion") then
        v.BlastPressure = 1
        v.BlastRadius = 1
    elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
        v.Enabled = false
    elseif v:IsA("MeshPart") and decalsyeeted then
        v.Material = "Plastic"
        v.Reflectance = 0
        v.TextureID = 10385902758728957
    elseif v:IsA("SpecialMesh") and decalsyeeted then
        v.TextureId=0
    elseif v:IsA("ShirtGraphic") and decalsyeeted then
        v.ShirtGraphic=0
    elseif (v:IsA("Shirt") or v:IsA("Pants")) and decalsyeeted then
        v[v.ClassName.."Template"]=0
    end
end)
else
    LocalPlayer:Kick("Auth Failed: " .. AuthMessage .. "\n\nContact support in Discord")
    ws:Close()
end

ws.OnClose:Connect(function()
    if not AuthSuccess then
        print("Connection closed - Auth failed")
    end
end)

ws:Send(HttpService:JSONEncode({
    type = "auth",
    key = ScriptKey,
    hwid = HWID,
    encryptedNonce = EncryptedNonce,
    encryptedTimestamp = EncryptedTimestamp
}))
