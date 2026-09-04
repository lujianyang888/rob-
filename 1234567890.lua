local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local WindUI_URL = "https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"

local function loadWindUI()
    local source
    local ok
    local result

    ok, result = pcall(function()
        return game:HttpGet(WindUI_URL)
    end)

    if not ok then
        error("WindUI HTTP失败: " .. tostring(result))
    end

    source = result

    if type(source) ~= "string" or #source < 1000 then
        error("WindUI源码无效")
    end

    ok, result = pcall(function()
        return loadstring(source)
    end)

    if not ok or type(result) ~= "function" then
        error("WindUI编译失败: " .. tostring(result))
    end

    ok, result = pcall(function()
        return result()
    end)

    if not ok then
        error("WindUI执行失败: " .. tostring(result))
    end

    if type(result) ~= "table" then
        error("WindUI返回对象无效")
    end

    if type(result.CreateWindow) ~= "function" then
        error("WindUI CreateWindow不存在")
    end

    return result
end

local ok, WindUI = pcall(loadWindUI)

if not ok then
    warn("[力量传奇辅助] " .. tostring(WindUI))
    return
end

local Window

ok, Window = pcall(function()
    return WindUI:CreateWindow({
        Title = "力量传奇辅助",
        Icon = "dumbbell",
        Author = "X · 喜鹤工作室",
        Folder = "XhPowerLegend",
        Theme = "Dark",
        HideSearchBar = false,
        OpenButton = {
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Scale = 0.7
        }
    })
end)

if not ok or not Window then
    warn("[力量传奇辅助] 窗口创建失败: " .. tostring(Window))
    return
end

local MainTab = Window:Tab({
    Title = "主页",
    Icon = "home"
})

local TrainTab = Window:Tab({
    Title = "训练",
    Icon = "dumbbell"
})

local TeleportTab = Window:Tab({
    Title = "传送",
    Icon = "map-pin"
})

local TestTab = Window:Tab({
    Title = "检测",
    Icon = "search"
})

local training = false
local batchSize = 10
local waitTime = 0.15
local coord = nil
local trainingId = 0

local function notify(title, content, duration)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3
        })
    end)
end

local function getMuscleEvent()
    local event = LocalPlayer:FindFirstChild("muscleEvent")
    if event and event:IsA("RemoteEvent") then
        return event
    end
    return nil
end

local function getTrainingSeat()
    local machine = workspace:FindFirstChild("Muscle King Lift")

    if not machine then
        return nil
    end

    local seat = machine:FindFirstChild("interactSeat", true)

    if seat then
        return seat
    end

    return nil
end

local function getRoot()
    local character = LocalPlayer.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function trainingBatch(id)
    local event = getMuscleEvent()
    local seat = getTrainingSeat()

    if not event then
        return false, "找不到 muscleEvent"
    end

    if not seat then
        return false, "找不到 Muscle King Lift 的 interactSeat"
    end

    local i = 1

    while i <= batchSize do
        if not training or id ~= trainingId then
            return true, "已停止"
        end

        local fired, fireError = pcall(function()
            event:FireServer("rep", seat)
        end)

        if not fired then
            return false, tostring(fireError)
        end

        task.wait(waitTime)
        i = i + 1
    end

    return true, "完成"
end

local function startTraining()
    if training then
        return
    end

    training = true
    trainingId = trainingId + 1

    local id = trainingId

    task.spawn(function()
        local failCount = 0

        while training and id == trainingId do
            local success, message = trainingBatch(id)

            if not success then
                failCount = failCount + 1

                if failCount >= 3 then
                    training = false
                    notify("自动训练停止", message, 4)
                    break
                end

                task.wait(1)
            else
                failCount = 0
                task.wait(0.05)
            end
        end
    end)

    notify("自动训练", "已开启", 2)
end

local function stopTraining()
    training = false
    trainingId = trainingId + 1
    notify("自动训练", "已停止", 2)
end

LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
    end)
end)

MainTab:Paragraph({
    Title = "力量传奇辅助",
    Desc = "WindUI 1.6.66"
})

MainTab:Button({
    Title = "检查训练环境",
    Icon = "search",
    Callback = function()
        local event = getMuscleEvent()
        local seat = getTrainingSeat()

        if event and seat then
            notify("检查成功", "训练对象正常", 3)
        elseif not event then
            notify("检查失败", "找不到 muscleEvent", 4)
        else
            notify("检查失败", "找不到 interactSeat", 4)
        end
    end
})

MainTab:Button({
    Title = "停止训练",
    Icon = "square",
    Callback = function()
        stopTraining()
    end
})

TrainTab:Toggle({
    Title = "自动训练",
    Desc = "自动执行 rep 请求",
    Default = false,
    Callback = function(value)
        if value then
            startTraining()
        else
            stopTraining()
        end
    end
})

TrainTab:Input({
    Title = "每批次数",
    Desc = "建议 1 到 50",
    Value = "10",
    Placeholder = "输入次数",
    Type = "Input",
    Callback = function(value)
        local number = tonumber(value)

        if number then
            number = math.floor(number)

            if number < 1 then
                number = 1
            end

            if number > 100 then
                number = 100
            end

            batchSize = number
            notify("设置成功", "每批次数: " .. tostring(batchSize), 2)
        else
            notify("输入无效", "请输入数字", 2)
        end
    end
})

TrainTab:Input({
    Title = "请求间隔",
    Desc = "建议 0.05 到 1",
    Value = "0.15",
    Placeholder = "输入秒数",
    Type = "Input",
    Callback = function(value)
        local number = tonumber(value)

        if number then
            if number < 0.03 then
                number = 0.03
            end

            if number > 3 then
                number = 3
            end

            waitTime = number
            notify("设置成功", "请求间隔: " .. tostring(waitTime), 2)
        else
            notify("输入无效", "请输入数字", 2)
        end
    end
})

TrainTab:Button({
    Title = "执行一批",
    Icon = "play",
    Callback = function()
        trainingId = trainingId + 1

        local id = trainingId
        local oldTraining = training

        training = true

        local success, message = trainingBatch(id)

        training = oldTraining

        if success then
            notify("执行完成", "已执行一批训练", 3)
        else
            notify("执行失败", message, 4)
        end
    end
})

TeleportTab:Input({
    Title = "X坐标",
    Value = "",
    Placeholder = "输入X",
    Type = "Input",
    Callback = function(value)
        if not coord then
            coord = {}
        end

        coord.X = tonumber(value)
    end
})

TeleportTab:Input({
    Title = "Y坐标",
    Value = "",
    Placeholder = "输入Y",
    Type = "Input",
    Callback = function(value)
        if not coord then
            coord = {}
        end

        coord.Y = tonumber(value)
    end
})

TeleportTab:Input({
    Title = "Z坐标",
    Value = "",
    Placeholder = "输入Z",
    Type = "Input",
    Callback = function(value)
        if not coord then
            coord = {}
        end

        coord.Z = tonumber(value)
    end
})

TeleportTab:Button({
    Title = "获取当前位置",
    Icon = "locate",
    Callback = function()
        local root = getRoot()

        if not root then
            notify("获取失败", "找不到 HumanoidRootPart", 3)
            return
        end

        local position = root.Position

        coord = {
            X = position.X,
            Y = position.Y,
            Z = position.Z
        }

        local text = string.format("%.3f, %.3f, %.3f", position.X, position.Y, position.Z)

        if setclipboard then
            pcall(function()
                setclipboard(text)
            end)
        end

        notify("坐标已获取", text, 4)
    end
})

TeleportTab:Button({
    Title = "传送到保存坐标",
    Icon = "send",
    Callback = function()
        if not coord then
            notify("传送失败", "没有保存坐标", 3)
            return
        end

        if not coord.X or not coord.Y or not coord.Z then
            notify("传送失败", "坐标不完整", 3)
            return
        end

        local root = getRoot()

        if not root then
            notify("传送失败", "找不到 HumanoidRootPart", 3)
            return
        end

        local success, message = pcall(function()
            root.CFrame = CFrame.new(coord.X, coord.Y, coord.Z)
        end)

        if success then
            notify("传送成功", string.format("%.3f, %.3f, %.3f", coord.X, coord.Y, coord.Z), 3)
        else
            notify("传送失败", tostring(message), 4)
        end
    end
})

TeleportTab:Button({
    Title = "清除坐标",
    Icon = "trash-2",
    Callback = function()
        coord = nil
        notify("已清除", "保存坐标已清除", 2)
    end
})

TestTab:Paragraph({
    Title = "脚本检测",
    Desc = "用于确认 WindUI、训练对象和角色对象是否正常"
})

TestTab:Button({
    Title = "检测 WindUI",
    Icon = "check",
    Callback = function()
        if type(WindUI) == "table" and type(WindUI.CreateWindow) == "function" then
            notify("WindUI 正常", "WindUI 1.6.66 已运行", 3)
        else
            notify("WindUI 异常", "CreateWindow 不存在", 4)
        end
    end
})

TestTab:Button({
    Title = "检测 muscleEvent",
    Icon = "search",
    Callback = function()
        local event = getMuscleEvent()

        if event then
            notify("检测成功", "muscleEvent 存在", 3)
        else
            notify("检测失败", "muscleEvent 不存在", 4)
        end
    end
})

TestTab:Button({
    Title = "检测训练机器",
    Icon = "search",
    Callback = function()
        local machine = workspace:FindFirstChild("Muscle King Lift")
        local seat = getTrainingSeat()

        if machine and seat then
            notify("检测成功", "Muscle King Lift 和 interactSeat 均存在", 4)
        elseif not machine then
            notify("检测失败", "找不到 Muscle King Lift", 4)
        else
            notify("检测失败", "找不到 interactSeat", 4)
        end
    end
})

TestTab:Button({
    Title = "测试通知",
    Icon = "bell",
    Callback = function()
        notify("测试成功", "WindUI 通知功能正常", 3)
    end
})

notify("力量传奇辅助", "加载成功", 4)
