-- =================================================================
-- 💣 Mine A Mountain - Permanent Sniper & NPC Interaction Bypass 💣
-- =================================================================

local Config = {
    AutoSniperActive = false,     -- สถานะเปิด/ปิดระบบ
    SpamSpeed = 0.1,              -- ความเร็วในการกดย้ำสั่งซื้ออย่างต่อเนื่อง (วินาที)
    
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

-- ⚡ ฟังก์ชันวาร์ปตัวละครเข้าประชิดจุดร้านค้า
local function warpToShopPosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(Config.Positions.BombShop)
    end
end

-- 🤝 ฟังก์ชันทริกเกอร์ให้เซิร์ฟเวอร์รับรู้ว่าเราคุยกับ NPC ร้านระเบิดอยู่ตลอดเวลา
local function keepNpcConnectionAlive()
    pcall(function()
        -- 1. ยิงเรียกดูข้อมูลร้านค้าเพื่อกระตุ้น Session
        BombShopQuery:InvokeServer()
        
        -- 2. ค้นหาและสั่งรัน ProximityPrompt (แท่นกดค้าง) ในระยะประชิดเพื่อยืนยันว่าตัวละครยืนอยู่ตรงนั้นจริง
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent and (v.Parent:IsA("BasePart") or v.Parent:IsA("Model")) then
                local dist = (v.Parent.Position - Config.Positions.BombShop).Magnitude
                if dist < 15 then
                    v:InputHoldBegin()
                    task.wait(0.05)
                    v:InputHoldEnd()
                    break
                end
            end
        end
    end)
end

-- 🚀 ฟังก์ชันลูปหลักที่ทำหน้าที่สับคำสั่งซื้อรัวๆ รอเวลารีสต็อก
local function startUltimateSniperLoop()
    while Config.AutoSniperActive do
        -- วาร์ปล็อกพิกัดไว้ป้องกันตัวละครไหล
        warpToShopPosition()
        
        -- รักษาสถานะการคุยกับร้านค้าฝั่ง Server
        keepNpcConnectionAlive()
        
        -- กระหน่ำยิงคำสั่งซื้อระเบิดทุกชิ้นที่เปิดทิ้งไว้ทันทีโดยไม่สน Stock บนจอ
        for bombName, isActive in pairs(Config.Targets) do
            if isActive and Config.AutoSniperActive then
                task.spawn(function()
                    pcall(function()
                        -- ใช้ InvokeServer ยิงตรงเข้าท่อส่งคำสั่งของเกม
                        BombBuyRequest:InvokeServer(bombName)
                    end)
                end)
            end
        end
        
        -- หน่วงเวลาเล็กน้อยเพื่อป้องกันไม่ให้โดนตัวเกมเตะ (Anti-Spam Kick)
        task.wait(Config.SpamSpeed)
    end
end

-- =================================================================
-- 🎨 RAYFIELD UI INTERFACE
-- =================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🎯 1-HOUR STOCK SNIPER (BYPASS)",
   LoadingTitle = "Injecting Hourly Sniper...",
   LoadingSubtitle = "By Gemini Fixer",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🛒 ระบบสไนเปอร์รายชั่วโมง", 4483362458)

MainTab:CreateToggle({
   Name = "เปิดระบบยิงคำสั่งซื้อค้างรอเวลารีสต็อก",
   CurrentValue = false,
   Flag = "ToggleHourlySniper",
   Callback = function(Value)
      Config.AutoSniperActive = Value
      if Value then
          Rayfield:Notify({Title = "Sniper Started!", Content = "ระบบกำลังยิงคำสั่งซื้อค้างไว้ในระบบ รอจังหวะรีสต็อกต้นชั่วโมง...", Duration = 4})
          task.spawn(startUltimateSniperLoop)
      else
          Rayfield:Notify({Title = "Sniper Stopped", Content = "หยุดการทำงานระบบสไนเปอร์แล้ว", Duration = 2})
      end
   end,
})

local SettingsTab = Window:CreateTab("⚙️ ตั้งค่าระเบิดเป้าหมาย", 4483362458)

local function createBombToggle(displayName, internalName)
    SettingsTab:CreateToggle({
       Name = "สไนเปอร์ " .. displayName,
       CurrentValue = true,
       Flag = "TargetHourly_" .. internalName,
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
