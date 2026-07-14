-- =================================================================
-- 💣 Mine A Mountain - Auto Refresh & Stock Sniper 💣
-- =================================================================

local Config = {
    AutoSniperActive = false,     -- สถานะเปิด/ปิดระบบ
    RefreshRate = 0.3,            -- ความถี่ในการรีเฟรชเช็กสต็อก (ยิ่งน้อยยิ่งไว 0.3 วินาทีคือกำลังดีไม่หลุด)
    SpamBuyCount = 5,             -- จำนวนครั้งที่กดย้ำรัว ๆ เมื่อสต็อกโผล่มา เพื่อความชัวร์ว่าได้ชิ้นนั้นแน่นอน
    
    -- รายชื่อระเบิดที่เปิดให้บอทเฝ้ารอซื้อ (เปิดเฉพาะชิ้นที่ต้องการได้)
    Targets = {
        ["ClassicBomb"] = true,
        ["WindBomb"] = true,
        ["IceBomb"] = true,
        ["FireBomb"] = true,
        ["ThunderBomb"] = true,
        ["PoisonBomb"] = true,
        ["TimeBomb"] = true,
        ["AgonyBomb"] = true
    }
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BombBuyRequest = Remotes:WaitForChild("BombBuyRequest")
local BombShopQuery = Remotes:WaitForChild("BombShopQuery")

-- 👁️ ฟังก์ชันสแกนหาตัวเลขสต็อกปัจจุบันจากหน้าจอ PlayerGui
local function checkCurrentStock(bombName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local holder = playerGui and playerGui:FindFirstChild("BombShop") 
        and playerGui.BombShop:FindFirstChild("Main")
        and playerGui.BombShop.Main:FindFirstChild("SettingsFrame")
        and playerGui.BombShop.Main.SettingsFrame:FindFirstChild("Holder")
        
    if holder then
        local bombFrame = holder:FindFirstChild(bombName)
        if bombFrame and bombFrame:FindFirstChild("Test") and bombFrame.Test:FindFirstChild("StockAmount") then
            local textStr = bombFrame.Test.StockAmount.Text
            -- ใช้ Regex ดักเอาเฉพาะตัวเลขออกมา
            local stockNum = tonumber(string.match(textStr, "%d+"))
            return stockNum or 0
        end
    end
    return 0
end

-- ⚡ ฟังก์ชันสไนเปอร์ยิงรีโมทซื้อรัวความเร็วสูง
local function sniperFire(bombName)
    print("🚨 [SNIPER DETECTED] ของเติมสต็อกแล้ว!: " .. bombName .. " กำลังแย่งซื้อหัวคิว...")
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
   Name = "🎯 STOCK SNIPER V3",
   LoadingTitle = "Loading Hyper Sniper System...",
   LoadingSubtitle = "By Gemini Security",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🛒 ระบบสไนเปอร์", 4483362458)

MainTab:CreateToggle({
   Name = "เปิดระบบดักรอซื้อทันทีที่รีสต็อก (Sniper Mode)",
   CurrentValue = false,
   Flag = "ToggleSniperMode",
   Callback = function(Value)
      Config.AutoSniperActive = Value
      if Value then
          Rayfield:Notify({Title = "Sniper Active!", Content = "บอทกำลังเฝ้าร้านค้าและรีเฟรชหาจังหวะสต็อกเติมตลอดเวลา...", Duration = 3})
      end
   end,
})

local SettingsTab = Window:CreateTab("⚙️ ตั้งค่าเป้าหมาย", 4483362458)

local function createBombToggle(displayName, internalName)
    SettingsTab:CreateToggle({
       Name = "เฝ้าซื้อ " .. displayName,
       CurrentValue = true,
       Flag = "SniperTarget_" .. internalName,
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
-- 🚀 CORE WORKER LOOP (ลูปรีเฟรชข้อมูลและสไนเปอร์)
-- =================================================================
task.spawn(function()
    while true do
        task.wait(Config.RefreshRate)
        
        if Config.AutoSniperActive then
            -- 1. บังคับยิง Query ไปที่ Server เพื่อบังคับให้เซิร์ฟเวอร์อัปเดตค่าสต็อกใหม่ล่าสุดมาที่หน้าจอ UI ของเรา
            pcall(function()
                BombShopQuery:InvokeServer()
            end)
            
            -- หน่วงเวลาเล็กน้อยให้ UI อัปเดตข้อมูลเสร็จ
            task.wait(0.05)
            
            -- 2. วนลูปเช็กระเบิดทุกชิ้นที่เราสั่งให้เฝ้าไว้
            for bombName, isActive in pairs(Config.Targets) do
                if isActive then
                    local stock = checkCurrentStock(bombName)
                    
                    -- 🔥 ถ้าจังหวะนี้สต็อกมันดีดขึ้นมามากกว่า 0 (คือของเพิ่งเติม) สั่งสไนเปอร์ทำงานทันที!
                    if stock > 0 then
                        sniperFire(bombName)
                    end
                end
            end
        end
    end
end)

Rayfield:Notify({
   Title = "Sniper Injected!",
   Content = "ระบบรีเฟรชและดักซื้อหัวคิวพร้อมทำงานแล้วครับพี่!",
   Duration = 5,
   Image = 4483362458,
})
