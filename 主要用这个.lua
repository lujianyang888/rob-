local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local LP = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")

local boss, followConn, autoT = "Boss1"

-- 防挂机 + 清理
LP.Idled:Connect(function()
    local v = game:GetService("VirtualInputManager")
    v:SendKeyEvent(true, Enum.KeyCode.Y, false, game)
    task.wait(0.05)
    v:SendKeyEvent(false, Enum.KeyCode.Y, false, game)
end)
for _, v in pairs(game:GetDescendants()) do
    if v.Name == "RobloxForwardPortals" then v:Destroy() end
end
if LP.Character and LP.Character:FindFirstChild("bodyMovementScript") then
    LP.Character.bodyMovementScript:Destroy()
end

local function getBoss()
    local a = workspace:FindFirstChild("Events")
    a = a and a:FindFirstChild("BossArena")
    a = a and a:FindFirstChild(boss)
    return a and a:FindFirstChild("Boss")
end

local W = WindUI:CreateWindow({
    Title = "Boss 辅助", Folder = "BossHelper",
    Size = UDim2.fromOffset(450, 280), ToggleKey = Enum.KeyCode.RightShift
})
local Tab = W:Tab({ Title = "主功能" })

Tab:Dropdown({
    Title = "选择Boss", Values = {"Boss1","Boss2","Boss3","Boss4","Boss5"},
    Value = "Boss1", Callback = function(v) boss = v end
})

-- 1. 锁定跟随
Tab:Toggle({ Title = "锁定跟随Boss (高度50)", Callback = function(v)
    if followConn then followConn:Disconnect() followConn = nil end
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = v end
    if not v then
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if r then r.AssemblyLinearVelocity = Vector3.zero end
        return
    end

    local lockedY
    followConn = RS.Heartbeat:Connect(function()
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local b = getBoss()
        if not (r and b) then return end

        local cf = b:IsA("Model") and b:FindFirstChild("HumanoidRootPart")
        cf = cf and cf.CFrame or b:IsA("BasePart") and b.CFrame
        if not cf then return end

        lockedY = lockedY or cf.Position.Y + 50
        r.AssemblyLinearVelocity = (Vector3.new(cf.X, lockedY, cf.Z) - r.Position) * 18

        local d = Vector3.new(cf.X - r.Position.X, 0, cf.Z - r.Position.Z)
        if d.Magnitude > 0.5 then
            r.CFrame = r.CFrame:Lerp(CFrame.lookAt(r.Position, r.Position + d.Unit), 0.3)
        end
    end)
end })

-- 2. 自动挥拳（已含快速攻速 0.01）
Tab:Toggle({ Title = "自动挥拳 (含快速攻速)", Callback = function(v)
    if autoT then task.cancel(autoT) end
    if not v then return end
    autoT = task.spawn(function()
        local L, R = {}, {}
        for i, id in ipairs({"3638729053","3638767427","507768375","522635514",
                             "522638767","182393478","129967390","129967478"}) do
            table.insert(i % 2 == 1 and L or R, "rbxassetid://" .. id)
        end

        local left, lT, rT = true
        local tick = 0
        while v do
            -- 每 4 次循环（约 0.2s）刷新一次攻速 CD
            tick = tick + 1
            if tick % 4 == 0 then
                local p = LP.Backpack:FindFirstChild("Punch")
                local n = p and p:FindFirstChildOfClass("NumberValue")
                if n then n.Value = 0.01 end
            end

            pcall(function()
                local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                if not hum then return end
                local p = LP.Backpack:FindFirstChild("Punch")
                if p then hum:EquipTool(p) end
                if LP.muscleEvent then
                    LP.muscleEvent:FireServer("punch", left and "leftHand" or "rightHand")
                end
                local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
                local t = left and lT or rT
                if not t then
                    local id = (left and L[1] or R[1])
                    if id then
                        local a = Instance.new("Animation"); a.AnimationId = id
                        t = an:LoadAnimation(a)
                        if left then lT = t else rT = t end
                    end
                end
                if t then t:Stop(0); t:Play(0.1) end
                left = not left
            end)
            task.wait(0.05)
        end
    end)
end })

W:Notify({ Title = "加载成功", Content = "按右Shift隐藏/显示", Duration = 4 })