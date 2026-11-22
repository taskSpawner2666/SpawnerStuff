--// MUSIC STORAGE
if isfolder and not isfolder("Evil Musics") then
    makefolder("Evil Musics")
end

--// API
local Animator = loadstring(game:HttpGet("https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/Animator.luau"))()

--// SERVICES
local UIS = game:GetService("UserInputService");
local RS = game:GetService("RunService");
local SG = game:GetService("StarterGui");
local PLRS = game:GetService("Players");

--// LOCAL
local PLR = PLRS.LocalPlayer;
local CHAR = PLR.Character;
local HUM = CHAR.Humanoid;

--// INSTANCES
local sound50 = Instance.new("Sound", RS);

--// NIL-BOOLEAN VALUES
local idle = true;
local walking = false;
local dancing = false;
local page = 1;
local currentanim = nil;
local INPUTCONNECT;
local anim50;

--// LOCAL FUNCTIONS
local function HTTP_REQUEST(name, write)
    local id = name:gsub("Evil Musics/", ""):gsub(".mp3", "")

    if write then
        if isfile and writefile and not isfile(id .. ".mp3") then
            local url = "https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/Musics/" .. id .. ".mp3"
            
            local success, body = pcall(function() 
                return game:HttpGet(url) 
            end)
            
            if success and body then
                writefile(id .. ".mp3", body)
            else
                warn("No se pudo descargar la música desde: " .. url)
                return nil
            end
        end

        if getcustomasset then
            return getcustomasset(id .. ".mp3")
        elseif getsynasset then
            return getsynasset(id .. ".mp3")
        else
            warn("Tu ejecutor no soporta getcustomasset")
            return nil
        end
    else
        local url = "https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/AnimTables/" .. id .. ".luau"
        
        local success, body = pcall(function() 
            return game:HttpGet(url) 
        end)
        
        if success and body then
            local loaded = loadstring(body)
            if loaded then
                return loaded()
            end
        end
        
        warn("No se pudo cargar la animación desde: " .. url)
        return nil
    end
end

local function playanim(anim, loop, speed)
    speed = speed or 1
    loop = loop or true
    if currentanim then currentanim:Stop() end
    currentanim = Animator.new(CHAR, anim)
    currentanim.Looped = loop
    currentanim.Speed = speed
    currentanim:Play()
end

local function stopanim()
   if dancing then
        dancing = false
        idle = true
        walking = false
        HUM:Move(Vector3.new(0, 0, -1), true)
        if sound50.IsPlaying == true then sound50:Stop() end
        if walking and not idle and HUM.MoveDirection ~= Vector3.new(0, 0, 0) and not dancing then
            task.spawn(function()
                playanim(0, false, 1)
            end)
        end
   end
end

--// ANIMATION EVENTS
INPUTCONNECT = UIS.InputBegan:Connect(function(input, c)
    if HUM.Sit then return nil end
    if c then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.None then return end
    local keyCodeString = tostring(input.KeyCode)
    local k = string.lower(
        string.gsub(
            keyCodeString,
            "Enum.KeyCode.",
            ""
        )
    )

    if page == 1 then
        if k == "one" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/rat_dance-background", true)
                anim50 = HTTP_REQUEST("rat_dance-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        elseif k == "two" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/boogie_down-background", true)
                anim50 = HTTP_REQUEST("boogie_down-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        end
    elseif page == 2 then
        if k == "one" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/XO-background", true)
                anim50 = HTTP_REQUEST("XO-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        elseif k == "two" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/drip-background", true)
                anim50 = HTTP_REQUEST("drip-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        end
    elseif page == 3 then
        if k == "one" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/crisscross-background", true)
                anim50 = HTTP_REQUEST("crisscross-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        elseif k == "two" then
            if not dancing then
                stopanim()
                sound50.SoundId = HTTP_REQUEST("Evil Musics/bird_brain-background", true)
                anim50 = HTTP_REQUEST("bird_brain-animation", false)
                sound50:Play()
                playanim(anim50)
            else
                stopanim()
            end
        end
    end

    if k == "capslock" then
        if page == 1 then
            page = 2
            SG:SetCore("SendNotification", {
                Title = "Evil Experience",
                Text = "You are in page 2 now",
                Duration = 3.5
            })
        elseif page == 2 then
            page = 3
            SG:SetCore("SendNotification", {
                Title = "Evil Experience",
                Text = "You are in page 3 now",
                Duration = 3.5
            })
        elseif page == 3 then
            page = 4
            SG:SetCore("SendNotification", {
                Title = "Evil Experience",
                Text = "You are in page 4 now",
                Duration = 3.5
            })
        elseif page == 4 then
            page = 5
            SG:SetCore("SendNotification", {
                Title = "Evil Experience",
                Text = "You are in page 5 now",
                Duration = 3.5
            })
        elseif page == 5 then
            page = 1
            SG:SetCore("SendNotification", {
                Title = "Evil Experience",
                Text = "You are in page 1 now",
                Duration = 3.5
            })
        end
    end
end)

HUM:GetPropertyChangedSignal("MoveDirection"):Connect(function()
    if not HUM.Sit then
        if HUM.MoveDirection == Vector3.new(0, 0, 0) and not dancing and not idle then
            walking = false
            idle = true
            stopanim()
        end
    end
end)
