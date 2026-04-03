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
        if AuthSuccess then
            print("Authenticated!")
            ws:Close()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Zenxxanlol2/testto/refs/heads/main/test.lua"))()
        else
            LocalPlayer:Kick("Auth Failed: " .. AuthMessage .. "\n\nContact support in Discord")
            ws:Close()
        end
    end
end)

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
