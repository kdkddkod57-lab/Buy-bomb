-- =================================================================
-- 💣 Mine A Mountain - Absolute Warp, Hold & Sniper Fix Version 💣
-- =================================================================

local Config = {
    AutoSniperActive = false,     -- สถานะเปิด/ปิดระบบ
    RefreshRate = 0.3,            -- ความถี่ในการตรวจเช็กและรีเฟรชสต็อก (วินาที)
    SpamBuyCount = 3,             -- จำนวนครั้งที่กดย้ำรัว ๆ เมื่อสต็อกโผล่มา
    
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
    -- 📍 พิกัดหน้าร้านระเบิดล็อกจุด
    Positions = {
        BombShop = Vector3.new(13.9704008102417, 29.407285690307617, 1051.5174560546875)
    }
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BombBuyRequest = Remotes:WaitForChild("BombBuyRequest") -- RemoteFunction (InvokeServer)
local BombShopQuery = Remotes:WaitForChild("BombShopQuery")

-- ⚡ ฟังก์ชันบังคับวาร์ปตัวละครไปที่หน้าร้านค้า
local function warpToShopPosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.CFrame = CFrame.new(Config.Positions.BombShop)
        task.wait(0.1)
    end
end

-- ⚡ ฟังก์ชันจำลองการกดค้างเพื่อเปิดหน้าร้านค้า (Hold Simulator)
local function forceOpenShop()
    pcall(function()
        -- 1. ตรวจหา ProximityPrompt ใกล้พิกัดร้านระเบิด
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") and v.Parent and (v.Parent:IsA("BasePart") or v.Parent:IsA("Model")) then
                local dist = (v.Parent.Position - Config.Positions.BombShop).Magnitude
                if dist < 15 then
                    v:InputHoldBegin()
                    task.wait(v.HoldDuration + 0.05)
                    v:InputHoldEnd()
                    return
                end
            end
        end
        
        -- 2. ดักกรณีที่เป็นปุ่มเมนูบนหน้าจอ
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

-- 👁️ ฟังก์ชันสแกนหาตัวเลขสต็อกจริง (แก้ไข Path ตรงตามภาพ Explorer ของผู้ใช้)
local function checkCurrentStock(bombName)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    -- เปลี่ยนแปลง Path ให้ตรงตาม: PlayerGui -> BombShop -> Main -> BombFrame -> Holder
    local bombShopGui = playerGui and playerGui:FindFirstChild("BombShop")
    
    if bombShopGui and bombShopGui:FindFirstChild("Main") then
        local bombFrame = bombShopGui.Main:FindFirstChild("BombFrame")
        local holder = bombFrame and bombFrame:FindFirstChild("Holder")
        
        if holder then
            local targetItem = holder:FindFirstChild(bombName)
            if targetItem and targetItem:FindFirstChild("Test") and targetItem.Test:FindFirstChild("StockAmount") then
                local textStr = targetItem.Test.StockAmount.Text
                -- ค้นหาตัวเลขสต็อก เช่น "X3 Stock" หรือ "X0 Stock"
                local stockNum = tonumber(string.match(textStr, "%d+"))
                return stockNum or 0
            end
        end
    end
    return 0
end

-- ⚡ ฟังก์ชันยิงคำสั่งซื้อผ่าน RemoteFunction ด้วยความเร็วสูง ป้องกันการดึงเธรดหลักค้าง
local function sniperFire(bombName)
    print("🚨 [SNIPER DETECTED] ตรวจพบของในสต็อก: " .. bombName .. " กำลังส่งคำสั่งซื้อ...")
    for i = 1, Config.SpamBuyCount do
        task.spawn(function()
            local success, result = pcall(function()
                return BombBuyRequest:InvokeServer(bombName)
            end)
            if success then
                print("✅ [BUY SUCCESS] ส่งคำสั่งซื้อระเบิดเรียบร้อย: " .. bombName)
            else
                warn("❌ [BUY ERROR] เกิดข้อผิดพลาดในการยิงรีโมท: ", result)
            end
        end)
    end
end

-- =================================================================
-- 🎨 RAYFIELD UI INTERFACE
-- =================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🎯 WARP & SNIPER V6 (FIXED UI PATH)",
   LoadingTitle = "Loading Fixed Components...",
   LoadingSubtitle = "By Gemini Fixer",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🛒 ระบบสไนเปอร์", 4483362458)

MainTab:CreateToggle({
   Name = "เปิดระบบ Auto Warp & Sniper (ทำงานอัตโนมัติ)",
   CurrentValue = false,
   Flag = "ToggleSniperV6",
   Callback = function(Value)
      Config.AutoSniperActive = Value
      if Value then
          Rayfield:Notify({Title = "Sniper Active!", Content = "เปิดระบบดักซื้อและแก้ไของค์ประกอบ UI แล้ว...", Duration = 3})
          warpToShopPosition()
      end
   end,
})

MainTab:CreateButton({
   Name = "📍 วาร์ปไปที่ร้านระเบิด (Manual Warp)",
   Callback = function()
       warpToShopPosition()
   end,
})

local SettingsTab = Window:CreateTab("⚙️ ตั้งค่าระเบิดเป้าหมาย", 4483362458)

local function createBombToggle(displayName, internalName)
    SettingsTab:CreateToggle({
       Name = "เฝ้าซื้อ " .. displayName,
       CurrentValue = true,
       Flag = "TargetV6_" .. internalName,
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
-- 🚀 CORE WORKER LOOP (ลูปประมวลผลหลัก)
-- =================================================================
task.spawn(function()
    while true do
        task.wait(Config.RefreshRate)
        
        if Config.AutoSniperActive then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            local isShopOpen = playerGui and playerGui:FindFirstChild("BombShop") and playerGui.BombShop.Main.Visible
            
            -- 1. หากหน้าต่างร้านค้ายังไม่เปิด ให้ตัวละครวาร์ปไปหน้าร้านแล้วกดเปิดอัตโนมัติ
            if not isShopOpen then
                warpToShopPosition()
                forceOpenShop()
                task.wait(0.2)
            end
            
            -- 2. บังคับเซิร์ฟเวอร์ให้อัปเดตข้อมูลร้านค้ามาที่ตัวเรา
            pcall(function()
                BombShopQuery:InvokeServer()
            end)
            task.wait(0.05)
            
            -- 3. ตรวจสอบสต็อกของระเบิดแต่ละชิ้น
            for bombName, isActive in pairs(Config.Targets) do
                if isActive then
                    local stock = checkCurrentStock(bombName)
                    -- หากสต็อกในหน้าจอดีดมากกว่า 0 ให้ทำการยิงคำสั่งซื้อทันที
                    if stock > 0 then
                        sniperFire(bombName)
                        task.wait(0.1) -- เว้นจังหวะสั้น ๆ เพื่อไม่ให้ระบบเตะเนื่องจากยิงแพ็กเก็ตถี่เกินไป
                    end
                end
            end
        end
    end
end)
