local P=game:GetService("Players").LocalPlayer
local R=game:GetService("RunService")
local U=game:GetService("UserInputService")
local bs,fc,at,on="Boss1",nil,nil,false

local function gb()
    local a=workspace:FindFirstChild("Events")
    a=a and a:FindFirstChild("BossArena")
    a=a and a:FindFirstChild(bs)
    return a and a:FindFirstChild("Boss")
end

local g=Instance.new("ScreenGui",P:WaitForChild("PlayerGui"))
g.ResetOnSpawn=false
local p=Instance.new("Frame",g)
p.Size=UDim2.new(0,130,0,310)
p.Position=UDim2.new(1,-145,0,80)
p.BackgroundTransparency=1
Instance.new("UIListLayout",p).Padding=UDim.new(0,6)

local function N(c,pr,par)
    local o=Instance.new(c)
    for k,v in pairs(pr)do o[k]=v end
    o.Parent=par
    return o
end

-- 拖动条
local d=N("TextButton",{Size=UDim2.new(1,0,0,22),BackgroundColor3=Color3.fromRGB(60,60,60),BackgroundTransparency=.3,Text="≡",TextSize=14,TextColor3=Color3.new(1,1,1)},p)
N("UICorner",{CornerRadius=UDim.new(0,6)},d)
local dg,ds,sp
d.InputBegan:Connect(function(i)if i.UserInputType.Name:find("MouseButton1")or i.UserInputType.Name:find("Touch")then dg=true ds=i.Position sp=p.Position end end)
U.InputChanged:Connect(function(i)if dg then local x=i.Position-ds p.Position=UDim2.new(sp.X.Scale,sp.X.Offset+x.X,sp.Y.Scale,sp.Y.Offset+x.Y)end end)
U.InputEnded:Connect(function(i)if i.UserInputType.Name:find("MouseButton1")or i.UserInputType.Name:find("Touch")then dg=false end end)

local function B(t,c,fn)
    local b=N("TextButton",{Size=UDim2.new(1,0,0,40),BackgroundColor3=c,Text=t,TextSize=15,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold},p)
    N("UICorner",{CornerRadius=UDim.new(0,8)},b)
    b.MouseButton1Click:Connect(fn)
    return b
end

-- Boss 切换
local bb=B("Boss: "..bs,Color3.fromRGB(80,80,80),function()
    bs="Boss"..tonumber(bs:sub(5))%5+1
    bb.Text="Boss: "..bs
end)

-- 跟随
local fb
local function tf()
    on=not on
    fb.Text="跟随 "..(on and "开" or "关")
    if fc then fc:Disconnect()fc=nil end
    local h=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand=on end
    if not on then
        local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        if r then r.AssemblyLinearVelocity=Vector3.zero end
        return
    end
    local y
    fc=R.Heartbeat:Connect(function()
        local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
        local b=gb()
        if not(r and b)then return end
        local cf=b:IsA("Model")and b:FindFirstChild("HumanoidRootPart")
        cf=cf and cf.CFrame or b:IsA("BasePart")and b.CFrame
        if not cf then return end
        y=y or cf.Position.Y+50
        r.AssemblyLinearVelocity=(Vector3.new(cf.X,y,cf.Z)-r.Position)*18
        local dx=cf.X-r.Position.X
        local dz=cf.Z-r.Position.Z
        if dx*dx+dz*dz>.25 then
            r.CFrame=r.CFrame:Lerp(CFrame.lookAt(r.Position,r.Position+Vector3.new(dx,0,dz).Unit),.3)
        end
    end)
end
fb=B("跟随 关",Color3.fromRGB(0,120,255),tf)

-- 自动挥拳
B("自动挥拳",Color3.fromRGB(160,50,220),function()
    if at then task.cancel(at)end
    at=task.spawn(function()
        local L,Rt={},{}
        for i,id in ipairs({"3638729053","3638767427","507768375","522635514","522638767","182393478","129967390","129967478"})do
            table.insert(i%2==1 and L or Rt,"rbxassetid://"..id)
        end
        local lf,lt,rt=true
        while true do
            pcall(function()
                local h=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
                if not h then return end
                local pt=P.Backpack:FindFirstChild("Punch")
                if pt then h:EquipTool(pt)end
                if P.muscleEvent then P.muscleEvent:FireServer("punch",lf and"leftHand"or"rightHand")end
                local an=h:FindFirstChildOfClass("Animator")or Instance.new("Animator",h)
                local t=lf and lt or rt
                if not t then
                    local id=lf and L[1]or Rt[1]
                    if id then
                        local a=Instance.new("Animation")
                        a.AnimationId=id
                        t=an:LoadAnimation(a)
                        if lf then lt=t else rt=t end
                    end
                end
                if t then t:Stop(0)t:Play(.1)end
                lf=not lf
            end)
            task.wait(.05)
        end
    end)
end)

B("全部停止",Color3.fromRGB(200,50,50),function()
    if at then task.cancel(at)at=nil end
end)

-- 关闭脚本
B("关闭脚本",Color3.fromRGB(30,30,30),function()
    if fc then fc:Disconnect()fc=nil end
    if at then task.cancel(at)at=nil end
    local h=P.Character and P.Character:FindFirstChildOfClass("Humanoid")
    if h then h.PlatformStand=false end
    local r=P.Character and P.Character:FindFirstChild("HumanoidRootPart")
    if r then r.AssemblyLinearVelocity=Vector3.zero end
    g:Destroy()
end)

U.InputBegan:Connect(function(i,gp)if not gp and i.KeyCode==Enum.KeyCode.F then tf()end end)