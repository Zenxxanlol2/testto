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

local original_pcall = pcall
local original_request_async = game:GetService("HttpService").RequestAsync
local original_json_decode = game:GetService("HttpService").JSONDecode

function isFunctionHooked(func, original_func)
    if func ~= original_func then
        return true
    end
    
    local info = debug.getinfo(func)
    if info and info.what == "Lua" then
        local ups = debug.getupvalues(func)
        for _, v in pairs(ups) do
            if type(v) == "function" and v ~= func then
                return true
            end
        end
    end
    
    return false
end

function AntiHookCheck()
    local current_request = game:GetService("HttpService").RequestAsync
    if current_request ~= original_request_async then
        local function r(n) return r(n + 1) end
        r(0)
    end
    
    local current_json = game:GetService("HttpService").JSONDecode
    if current_json ~= original_json_decode then
        local function r(n) return r(n + 1) end
        r(0)
    end
    
    if pcall ~= original_pcall then
        local function r(n) return r(n + 1) end
        r(0)
    end
    
    return true
end

AntiHookCheck()

if not AntiHookCheck() then
    function causeStackOverflow(n)
        return causeStackOverflow(n + 1)
    end
    causeStackOverflow(0)
end


function a()
local b={print,warn,require,getfenv,setfenv,pcall,xpcall,math.random};for c,d in ipairs(b)do
local e,f=pcall(debug.info,d,"s")
if not e or f~="[C]"then return true end;end;return false;end
if a()then local function b()
while true do end;end;b();end

function Base64Encode(Data)
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

function GenerateKey(Key, Length)
    local GeneratedKey = ""
    local KeyLength = #Key
    local CurrentIndex = 1
    while #GeneratedKey < Length do
        GeneratedKey = GeneratedKey .. stringSubOriginal(Key, CurrentIndex, CurrentIndex)
        CurrentIndex = (CurrentIndex % KeyLength) + 1
    end
    return GeneratedKey
end

function CalculateChecksum(Text)
    local Checksum = 0
    for i = 1, #Text do
        Checksum = (Checksum + stringByteOriginal(stringSubOriginal(Text, i, i))) % 256
    end
    return Checksum
end

function TransformInput(Input)
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

function EncryptData(Input, Key)
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
        if AuthSuccess then
            print("Authenticated!")
            ws:Close()
            task.spawn(function()
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local HttpService = game:GetService("HttpService")
                local UserInputService = game:GetService("UserInputService")
                local LocalPlayer = Players.LocalPlayer
                local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
                local Workspace = game:GetService("Workspace")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")

                local AnimalsModule = require(ReplicatedStorage.Datas.Animals)
                local TraitsModule = require(ReplicatedStorage.Datas.Traits)
                local MutationsModule = require(ReplicatedStorage.Datas.Mutations)

                local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

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
                frame.Position = UDim2.new(0.01, 0, 0.05, 0)
                frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
                frame.BackgroundTransparency = 0.08
                frame.BorderSizePixel = 0
                frame.ClipsDescendants = true
                frame.Parent = screenGui

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

                local dragging = false
                local dragStart = nil
                local startPos = nil

                header.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        dragStart = input.Position
                        startPos = frame.Position
                    end
                end)

                header.InputEnded:Connect(function()
                    dragging = false
                end)

                header.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local delta = input.Position - dragStart
                        local viewport = workspace.CurrentCamera.ViewportSize
                        local newX = math.clamp(startPos.X.Scale + (delta.X / viewport.X), 0, 1)
                        local newY = math.clamp(startPos.Y.Scale + (delta.Y / viewport.Y), 0, 1)
                        frame.Position = UDim2.new(newX, 0, newY, 0)
                    end
                end)

                local titleLabel = Instance.new("TextLabel", header)
                titleLabel.Size = UDim2.new(1, -40, 1, 0)
                titleLabel.Position = UDim2.new(0, 14, 0, 0)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = "Auto Buy Carpet"
                titleLabel.Font = Enum.Font.GothamBold
                titleLabel.TextSize = 14
                titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left

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

                local function lockToCarpet(hrp)
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
            end)
        else
            LocalPlayer:Kick("Auth Failed: " .. AuthMessage .. "\n\nContact support in Discord")
            ws:Close()
        end
    end
end)

ws.OnClose:Connect(function()
    if not AuthSuccess then
        print("Failed Tell Daddy Zenx")
    end
end)

ws:Send(HttpService:JSONEncode({
    type = "auth",
    key = ScriptKey,
    hwid = HWID,
    encryptedNonce = EncryptedNonce,
    encryptedTimestamp = EncryptedTimestamp
}))

do
    local FunctionList = {math.abs, os.clock, coroutine.isyieldable, debug.info, Request, LocalPlayer.Kick, table.insert, bit32.bxor, debug.getfenv, setrawmetatable, pcall, math.random, setmetatable, string.split, debug.traceback, debug.info, getrawmetatable, type, table.insert, math.random, Select, table.concat, string.byte, string.char, debug.getinfo, islclosure, GenerateString, GenerateKey, TransformInput, ReverseTransform, CalculateChecksum, string.reverse, Encrypt, Decrypt, SuperRequest, getmetatable}

    for Index, Value in next, FunctionList do
        for index = 1, 197 do
            Value = coroutine.wrap(Value)
        end

        if Select(2, pcall(Value)) == "C stack overflow" then
        end
    end

    JMPCount = JMPCount + 1
end
