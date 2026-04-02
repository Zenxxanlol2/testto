local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local WS_URL = "wss://booo-jczf.onrender.com"

local AuthTime = os.clock()
local EncryptionKey = "f7a2b9c4d1e6f3a8b5c2d9e4f1a6b3c8"

local function EncryptLightspeed(Input)
    local Result = {}
    local InputLen = #Input
    local KeyLen = #EncryptionKey
    for i = 1, InputLen do
        Result[i] = string.char(bit32.bxor(string.byte(Input, i), string.byte(EncryptionKey, ((i - 1) % KeyLen) + 1)))
    end
    return table.concat(Result)
end

local ScriptKey = getgenv().ScriptKey
if not ScriptKey or ScriptKey == "" then return end

local Data = HttpService:JSONEncode({
    u = tostring(LocalPlayer.UserId),
    k = ScriptKey,
    h = (gethwid and gethwid()) or game:GetService("RbxAnalyticsService"):GetClientId()
})

local ws = (syn and syn.websocket or WebSocket).connect(WS_URL)
if not ws then return end

local Done = false
local Success = false
local Msg = ""

ws.OnMessage:Connect(function(m)
    local ok, d = pcall(HttpService.JSONDecode, HttpService, m)
    if ok and d.type == "auth_response" then
        Success, Msg, Done = d.success, d.message, true
    end
end)

ws.OnClose:Connect(function() Done = true end)
ws:Send(HttpService:JSONEncode({type="auth", d=EncryptLightspeed(Data)}))

repeat task.wait() until Done or os.clock() - AuthTime > 1

ws:Close()
if not Success then return end

print("[AUTH] " .. string.format("%.3fms", (os.clock() - AuthTime) * 1000))
loadstring(game:HttpGet("https://raw.githubusercontent.com/Zenxxanlol2/testto/refs/heads/main/test.lua"))()
