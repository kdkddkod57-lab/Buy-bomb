-- =================================================================
-- 💣 Mine A Mountain - Smart Warp Jumper & Stock Sniper 💣
-- =================================================================

local Config = {
    AutoSniperActive = false,     -- สถานะเปิด/ปิดระบบ
    SpamSpeed = 0.08,             -- ความเร็วในการกดย้ำสั่งซื้อ (วินาที)
    WarpBeforeSeconds = 15,       -- ให้วาร์ปไปสแตนด์บายก่อนรีสต็อกกี่วินาที (15 วินาทีกำลังปลอดภัย)
    ReturnAfterSeconds = 10,      -- หลังจากเวลาดีดเข้าชั่วโมงใหม่ ให้ยิงซื้อค้างไว้กี่วินาทีก่อนวาร์ปกลับ (10 วินาทีเพื่อให้ชัวร์ว่าได้ของ)
    
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

local SavedPosition = nil -- ตัวแปรเก็บพิกัดเดิมของพี่
local IsSniperPhase = false

-- 👁️ ฟังก์ชันอ่านเวลาถอยหลังที่เหลือจาก UI ของ Mountain RNG (ซ้ายล่างจอ)
local function getRngTimeLeft()
    pcall(function()
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local mainGui = playerGui and playerGui:FindFirstChild("MainGui") -- เปลี่ยนเป็นชื่อ Gui หลักของเกมพี่ถ้าทราบ
        -- หรือดักจับตรง UI ซ้ายล่างตามรูปภาพ Mountain RNG
        local mountainRngText = playerGui and playerGui:FindFirstChild("MountainRngGui") or playerGui:FindFirstChild("ScreenGui")
        -- โค้ดจะพยายามค้นหา Text ที่มีเครื่องหมาย ":" เช่น "34:29" หรือดักจากปุ่มล่างซ้าย
        for _, v in pairs(playerGui:GetDescendants()) do
            if v:IsA("TextLabel") and string.find(v.Text, ":") and (string.find(string.lower(v.Name), "time") or string.find(string.lower(v.Name), "rng") or string.find(string.lower(v.Parent.Name), "mountain")) then
                local minutes, seconds = string.match(v.Text, "(%d+):(%d+)")
                if minutes and seconds then
                    return (tonumber(minutes) * 60) + tonumber(seconds)
                end
            end
        end
    end)
    -- ถ้าหา UI เวลาไม่เจอ บอทจะใช้การดักเวลาจากตัวนับวินาทีของระบบเบื้องหลังแทน (สำรองข้อมูล)
    return (60 - (os.date("*t").min)) * 60 - os.date("*t").sec
end

-- ⚡ ฟังก์ชันสั่งวาร์ปตัวละครไปยังพิกัดเป้าหมาย
local function teleportTo(position)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and position then
        hrp.CFrame = CFrame.new(position)
    end
end

-- 🤝 ฟังก์ชันทริกเกอร์คุยกับ NPC หน้าร้าน
local function triggerNpcInteract()
    pcall(function()
        BombShopQuery:InvokeServer()
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

-- =================================================================
-- 🎨 RAYFIELD UI INTERFACE
-- =================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "🎯 SMART TIME SNIPER V7",
   LoadingTitle = "Loading Dynamic Warp System...",
   LoadingSubtitle = "By Gemini Fixer",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local MainTab = Window:CreateTab("🛒 ระบบจัมเปอร์", 4483362458)

MainTab:CreateToggle({
   Name = "เปิดระบบวาร์ปไปซื้อและกลับที่เดิมอัตโนมัติ",
   CurrentValue = false,
   Flag = "ToggleSmartJumper",
   Callback = function(Value)
      Config.AutoSniperActive = Value
      if Value then
          Rayfield:Notify({Title = "Smart System Active!", Content = "บอทจะยืนอยู่ที่เดิม และจะวาร์ปไปหน้าร้านเมื่อใกล้ถึงเวลารีสต็อกเองครับพี่", Duration = 4})
      else
          IsSniperPhase = false
          SavedPosition = nil
      end
   end,
})

local SettingsTab = Window:CreateTab("⚙️ ตั้งค่าระเบิดเป้าหมาย", 4483362458)

local function createBombToggle(displayName, internalName)
    SettingsTab:CreateToggle({
       Name = "สไนเปอร์ " .. displayName,
       CurrentValue = true,
       Flag = "TargetSmart_" .. internalName,
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
-- 🚀 CORE TIME CONTROL LOOP (ลูปควบคุมเวลาและสลับตำแหน่งวาร์ป)
-- =================================================================
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if Config.AutoSniperActive then
            local timeLeft = getRngTimeLeft() -- วินาทีที่เหลือก่อนรีสต็อก
            
            -- จังหวะที่ 1: ใกล้ถึงเวลารีสต็อกแล้ว (เหลือน้อยกว่า 15 วินาที) และยังไม่ได้อยู่ในช่วงสไนเปอร์
            if timeLeft <= Config.WarpBeforeSeconds and not IsSniperPhase then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                
                if hrp then
                    -- เซฟพิกัดปัจจุบันของพี่เอาไว้ก่อนวาร์ปไป
                    SavedPosition = hrp.Position
                    print("📍 [Smart Sniper] บันทึกตำแหน่งปัจจุบันเรียบร้อย กำลังวาร์ปไปหน้าร้านค้า...")
                    
                    IsSniperPhase = true
                    
                    -- เริ่มลูปเร่งด่วนยิงสไนเปอร์หน้าร้าน
                    task.spawn(function()
                        while IsSniperPhase and Config.AutoSniperActive do
                            teleportTo(Config.Positions.BombShop) -- ล็อกตัวละครไว้หน้าร้าน
                            triggerNpcInteract()                  -- เปิดคุย NPC ค้างไว้
                            
                            -- กระหน่ำส่งคำสั่งซื้อ
                            for bombName, isActive in pairs(Config.Targets) do
                                if isActive and Config.AutoSniperActive then
                                    task.spawn(function()
                                        pcall(function()
                                            BombBuyRequest:InvokeServer(bombName)
                                        end)
                                    end)
                                end
                            end
                            task.wait(Config.SpamSpeed)
                        end
                    end)
                end
            end
            
            -- จังหวะที่ 2: เลยเวลารีสต็อกมาแล้ว (เช่น เวลาดีดกลับไปเริ่มนับ 3600 วินาทีใหม่ หรือเลยช่วง 10 วินาทีแรกของชั่วโมงใหม่มาแล้ว)
            -- หรือตรวจจับว่าพ้นวินาทีวิกฤตมาแล้ว ให้พากลับบ้าน
            if IsSniperPhase and (timeLeft > Config.WarpBeforeSeconds and timeLeft < (3600 - Config.ReturnAfterSeconds)) then
                print("✅ [Smart Sniper] หมดเวลารีสต็อกประจำชั่วโมงแล้ว! กำลังพาวาร์ปกลับไปพิกัดฟาร์มเดิม...")
                IsSniperPhase = false -- หยุดการยิงสไนเปอร์หน้าร้าน
                
                task.wait(0.5)
                if SavedPosition then
                    teleportTo(SavedPosition) -- พาวาร์ปกลับมาจุดเดิมที่เซฟไว้ตอนแรก 100%
                    SavedPosition = nil
                end
            end
            
        end
    end
end)
