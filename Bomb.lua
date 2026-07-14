-- =================================================================
-- 💣 Mine A Mountain - Absolute Warp, Hold & Sniper Ultimate 💣
-- =================================================================

local Config = {
    AutoSniperActive = false,     -- สถานะเปิด/ปิดระบบ
    RefreshRate = 0.4,            -- ความถี่ในการรีเฟรชเช็กสต็อก (วินาที)
    SpamBuyCount = 5,             -- จำนวนครั้งที่กดย้ำรัว ๆ เมื่อสต็อกโผล่มา
    
    Targets = {
        ["ClassicBomb"] = true,
        ["WinBomb"] = true,
        ["IceBomb"] = true,
        ["FireBomb"] = true,
        ["ThunderBomb"] = true,
        ["PoisonBomb"] = true,
        ["TimeBomb"] = true,
        ["AgonyBomb"] = true
    },
    -- 📍 พิกัดร้านค้าที่พี่ส่งมา ล็อกตำแหน่งเข้าหาจุดนี้ 100%
    Positions = {
        BombShop = Vector3.new(13.9704008102417, 29.407285690307617, 1051.5174560546875)
    }
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BombBuyRequest = Remotes:WaitForChild("BombBuyRequest")
local BombShopQuery = Remotes:WaitForChild("BombShopQuery")

-- ⚡ ฟังก์ชันบังคับวาร์ปตัวละครไปที่ร้านค้า
local function warpToShopPosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(Config.Positions.BombShop)
        task.wait(0.2) -- หน่วงเวลาสั้น ๆ ให้ตัวละครและฟิสิกส์โหลดพิกัดเสร็จสมบูรณ์
    end
end

-- ⚡ ฟังก์ชันจำลองการกดค้างเพื่อเปิดหน้าร้านค้า (Hold Simulator)
local function forceOpenShop()
    pcall(function()
        -- 1. ตรวจหา ProximityPrompt (จุดกดค้างในฉากเกม) ที่อยู่ใกล้พิกัดร้านระเบิด
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent and (v.Parent:IsA("BasePart") or v.Parent:IsA("Model")) then
                local dist = (v.Parent.Position - Config.Positions.BombShop).Magnitude
                if dist < 15 then -- ถ้าระยะห่างวัตถุใกล้พิกัดร้าน
                    v:InputHoldBegin()
                    task.wait(v.HoldDuration + 0.1)
                    v:InputHoldEnd()
                    return
                end
            end
        end
        
        -- 2. เผื่อกรณีที่เป็นปุ่มเมนูบนหน้าจอ Gui ที่ต้องกด (UI Button Click)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, ui in pairs(playerGui:GetDescendants()) do
                if (ui:IsA("TextButton") or ui:IsA("ImageButton")) and string.find(string.lower(ui.Name), "shop") then
                    local events = {"MouseButton1Down", "TouchStart", "Activated"}
                    for _, ev in ipairs(events) do
                        if ui[ev] then ui[ev]:Fire() end
                    end
                end
            end
        end
    end)
end

-- 👁️ ฟังก์ชันสแกนหาตัวเลขสต็อกปัจจุบันจากหน้าจอ PlayerGui
local function checkCurrentStock(bombName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local bombShopGui = playerGui and playerGui:FindFirstChild("BombShop")
    
    if bombShopGui and bombShopGui:FindFirstChild("Main") then
        local holder = bombShopGui.Main:FindFirstChild("SettingsFrame") and bombShopGui.Main.SettingsFrame:FindFirstChild("Holder")
        if holder then
            local bombFrame = holder:FindFirstChild(bombName)
            if bombFrame and bombFrame:FindFirstChild("Test") and bombFrame.Test:FindFirstChild("StockAmount") then
                local textStr = bombFrame.Test.StockAmount.Text
                local stockNum = tonumber(string.match(textStr, "%d+"))
                return stockNum or 0
            end
        end
    end
    return 0
end

-- ⚡ ฟังก์ชันสไนเปอร์ยิงรีโมทซื้อรัวความเร็วสูง
local function sniperFire(bombName)
    print("🚨 [SNIPER] สต็อกเติมแล้ว!: " .. bombName .. " ยิงคำสั่งแย่งซื้อหัวคิว...")
    for i = 1, Config.SpamBuyCount do
        task.spawn(function()
            pcall(function()
                BombBuyRequest:InvokeServer(bombName)
            end)
        end)
    end
end

-- =================================================================
-- 🎨 RAYFIELD UI INTERFACE
-- =================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🎯 WARP & SNIPER V5",
   LoadingTitle = "Loading Warp Components...",
   LoadingSubtitle = "By Gemini Fix",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🛒 ระบบสไนเปอร์", 4483362458)

MainTab:CreateToggle({
   Name = "เปิดระบบ Auto Warp & Sniper (เฝ้าซื้ออัตโนมัติ)",
   CurrentValue = false,
   Flag = "ToggleSniperV5",
   Callback = function(Value)
      Config.AutoSniperActive = Value
      if Value then
          Rayfield:Notify({Title = "Sniper Active!", Content = "วาร์ปไปหน้าร้าน จำลองการกดค้าง และเฝ้าสต็อกแล้ว...", Duration = 3})
          warpToShopPosition() -- วาร์ปไปพิกัดร้านทันทีกดเปิดใช้งาน
      end
   end,
})

MainTab:CreateButton({
   Name = "📍 วาร์ปไปร้านระเบิดเอง (Manual Teleport)",
   Callback = function()
       warpToShopPosition()
   end,
})

local SettingsTab = Window:CreateTab("⚙️ ตั้งค่าเป้าหมาย", 4483362458)

local function createBombToggle(displayName, internalName)
    SettingsTab:CreateToggle({
       Name = "เฝ้าซื้อ " .. displayName,
       CurrentValue = true,
       Flag = "TargetV5_" .. internalName,
       Callback = function(Value)
          Config.Targets[internalName] = Value
       end,
    })
end

createBombToggle("Classic Bomb", "ClassicBomb")
createBombToggle("Win Bomb", "WinBomb")
createBombToggle("Ice Bomb", "IceBomb")
createBombToggle("Fire Bomb", "FireBomb")
createBombToggle("Thunder Bomb", "ThunderBomb")
createBombToggle("Poison Bomb", "PoisonBomb")
createBombToggle("Time Bomb", "TimeBomb")
createBombToggle("Agony Bomb", "AgonyBomb")

-- =================================================================
-- 🚀 CORE WORKER LOOP (ลูปวาร์ป + จำลองกดค้างเปิดร้าน + สไนเปอร์)
-- =================================================================
task.spawn(function()
    while true do
        task.wait(Config.RefreshRate)
        
        if Config.AutoSniperActive then
            -- 1. เช็กสถานะหน้าต่างร้านค้า ถ้าปิดอยู่ ให้วาร์ปไปที่ร้านและจำลองกดค้างเปิดร้านเองทันที
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local isShopOpen = playerGui and playerGui:FindFirstChild("BombShop") and playerGui.BombShop.Main.Visible
            
            if not isShopOpen then
                warpToShopPosition() -- บังคับล็อกพิกัดตัวละครให้อยู่หน้าร้าน
                forceOpenShop()      -- สั่งระบบจำลองการกดค้างเปิดร้าน
                task.wait(0.3)
            end
            
            -- 2. บังคับส่งแพ็กเก็ตอัปเดตข้อมูลเซิร์ฟเวอร์
            pcall(function()
                BombShopQuery:InvokeServer()
            end)
            task.wait(0.05)
            
            -- 3. สแกนและสไนเปอร์ซื้อเมื่อสต็อกดีดมากกว่า 0
            for bombName, isActive in pairs(Config.Targets) do
                if isActive then
                    local stock = checkCurrentStock(bombName)
                    if stock > 0 then
                        sniperFire(bombName)
                    end
                end
            end
        end
    end
end)
