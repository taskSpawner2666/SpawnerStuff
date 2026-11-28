--  // EVIL EXPERIENCE // -- [[
	-- Script based in SEWH
	-- In honor of KDV3
	-- by TaskSpawner
--]]

--// TO PREVENT CONSTANT CODE EXECUTION {
if _G.EvilExperienceLoaded then warn("WARN: Script already playing (reset character)") return end
_G.EvilExperienceLoaded = true
--}

--// MUSIC-SOUND STORAGE {
if isfolder and not isfolder('Evil Musics') then makefolder('Evil Musics') end
if isfolder and not isfolder('Evil Effects') then makefolder('Evil Effects') end
--}

--// API LIBRARY UTILITIES {
local Animator = loadstring(game:HttpGet('https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/Animator.luau'))();
local AxisAPI = loadstring(game:HttpGet('https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/AxisAPI.luau'))();
--}

--// SERVICES {
local UIS = game:GetService('UserInputService');
local SS = game:GetService('SoundService');
local SG = game:GetService('StarterGui');
local PLRS = game:GetService('Players');
local TS = game:GetService('TweenService');
--}

--// LOCAL {
local PLR = PLRS.LocalPlayer;
local CHAR = PLR.Character or PLR.CharacterAdded:Wait();
local HUM = CHAR:WaitForChild('Humanoid');
--}

--// INSTANCES {
local sound50 = Instance.new('Sound', SS);
sound50.Volume = 2
sound50.Name = 'Emote';

local ost3 = Instance.new('Sound', SS);
ost3.Name = 'Background';

local bgui = Instance.new('BillboardGui', CHAR.Head);
bgui.AlwaysOnTop = true
bgui.StudsOffset = Vector3.new(0, 0.4, 0)
bgui.Size = UDim2.fromScale(1, 1)
--}

--// VALUES {
local dancing = false;
local return_stickers = false;
local page = 1;
local MAX_PAGES = 5;
local currentanim = nil;
local lastKey = nil;
local currentPage;
local EFFECTENDED;
local INPUTCONNECT;
local OSTENDED;
local sticker23;
local anim50;
local emote;
--}

--// METATABLES {
local EMOTES_PAGES = {
    [1] = { -- generic emotes
        ['one'] = {music = 'Evil Musics/chess-background.mp3', anim = 'chess-animation.luau'},
        ['two'] = {music = 'Evil Musics/caramelldansen-background.mp3', anim = 'caramelldansen-animation.luau'},
        ['three'] = {music = 'Evil Musics/number-background.mp3', anim = 'number-animation.luau'},
        ['four'] = {music = 'Evil Musics/cat_bath-background.mp3', anim = 'cat_bath-animation.luau'},
        ['five'] = {music = 'Evil Musics/class_c14-background.mp3', anim = 'class_c14-animation.luau'},
        ['six'] = {music = 'Evil Musics/birthday-background.mp3', anim = 'birthday-animation.luau'},
        ['seven'] = {music = 'Evil Musics/what_u_want-background.mp3', anim = 'what_u_want-animation.luau'},
        ['eight'] = {music = 'Evil Musics/dosh_bag-background.mp3', anim = 'dosh_bag-animation.luau'},
        ['nine'] = {music = 'Evil Musics/territory-background.mp3', anim = 'territory-animation.luau'},
        ['zero'] = {music = 'Evil Musics/get_down-background.mp3', anim = 'get_down-animation.luau'}
    };
    [2] = { -- grupal emotes
        ['one'] = {music = 'Evil Musics/otsukare_summer-background.mp3', anim = 'otsukare_summer-animation.luau'},
        ['two'] = {music = 'Evil Musics/one_two_three-background.mp3', anim = 'one_two_three-animation.luau'},
		['three'] = {music = 'Evil Musics/kill_me_baby-background.mp3', anim = 'kill_me_baby-animation.luau'},
        ['four'] = {music = 'Evil Musics/mesmerizer-background.mp3', anim = 'mesmerizer-animation.luau'},
        ['five'] = {music = 'Evil Musics/static-background.mp3', anim = 'static-animation.luau'},
        ['six'] = {music = 'Evil Musics/turron-background.mp3', anim = 'turron-animation.luau'},
        ['seven'] = {music = 'Evil Musics/turning_love-background.mp3', anim = 'turning_love-animation.luau'},
        ['eight'] = {music = 'Evil Musics/wild_side-background.mp3', anim = 'wild_side-animation.luau'},
        ['nine'] = {music = 'Evil Musics/jitter_bug-background.mp3', anim = 'jitter_bug-animation.luau'},
        ['zero'] = {music = 'Evil Musics/lockstep-background.mp3', anim = 'lockstep-animation.luau'}
    };
    [3] = { -- generic emotes again
        ['one'] = {music = 'Evil Musics/konton_boogie-background.mp3', anim = 'konton_boogie-animation.luau'},
        ['two'] = {music = 'Evil Musics/yonky-background.mp3', anim = 'yonky-animation.luau'},
        ['three'] = {music = 'Evil Musics/party_hips-background.mp3', anim = 'party_hips-animation.luau'},
        ['four'] = {music = 'Evil Musics/internet-background.mp3', anim = 'internet-animation.luau'},
        ['five'] = {music = 'Evil Musics/vegetable_juice-background.mp3', anim = 'vegetable_juice-animation.luau'},
        ['six'] = {music = 'Evil Musics/liar_dancer-background.mp3', anim = 'liar_dancer-animation.luau'},
        ['seven'] = {music = 'Evil Musics/doodle-background.mp3', anim = 'doodle-animation.luau'},
        ['eight'] = {music = 'Evil Musics/hyadain-background.mp3', anim = 'hyadain-animation.luau'},
        ['nine'] = {music = 'Evil Musics/giri_giri_dansu-background.mp3', anim = 'giri_giri_dansu-animation.luau'},
        ['zero'] = {music = 'Evil Musics/die_lit-background.mp3', anim = 'die_lit-animation.luau'}
    };
    [4] = { -- emotes with effects
        ['one'] = {music = 'Evil Musics/boiii-background.mp3', anim = 'boiii-animation.luau'},
        ['two'] = {music = 'Evil Musics/kyoufuu-background.mp3', anim = 'kyoufuu-animation.luau'},
        ['three'] = {music = 'Evil Musics/rolling_star-background.mp3', anim = 'rolling_star-animation.luau'},
        ['four'] = {music = 'Evil Musics/captain-background.mp3', anim = 'captain-animation.luau'},
        ['five'] = {music = 'Evil Musics/monster_mash-background.mp3', anim = 'monster_mash-animation.luau'},
        ['six'] = {music = 'Evil Musics/kwik_drip-background.mp3', anim = 'kwik_drip-animation.luau'},
        ['seven'] = {music = 'Evil Musics/cosmic_relief-background.mp3', anim = 'cosmic_relief-animation.luau'},
        ['eight'] = {music = 'Evil Musics/w_ur_eyes_closed-background.mp3', anim = 'w_ur_eyes_closed-animation.luau'},
        ['nine'] = {music = 'Evil Musics/shika-background.mp3', anim = 'shika-animation.luau'},
        ['zero'] = {music = 'Evil Musics/witch-background.mp3', anim = 'witch-animation.luau'}
    };
    [5] = { -- additional emotes
        ['one'] = {music = 'Evil Musics/the_hero-background.mp3', anim = 'the_hero-animation.luau'},
        ['two'] = {music = 'Evil Musics/the_flop-background.mp3', anim = 'the_flop-animation.luau'},
        ['three'] = {music = 'Evil Musics/pog-background.mp3', anim = 'pog-animation.luau'},
        --['four'] = {music = 'Evil Musics/pogo-background.mp3', anim = 'pogo-animation.luau'},
        ['five'] = {music = 'Evil Musics/its_a_secret-background.mp3', anim = 'its_a_secret-animation.luau'},
        ['six'] = {music = 'Evil Musics/rakuten-background.mp3', anim = 'rakuten-animation.luau'},
        ['seven'] = {music = 'Evil Musics/moongazer-background.mp3', anim = 'moongazer-animation.luau'},
        ['eight'] = {music = 'Evil Musics/boogie_down-background.mp3', anim = 'boogie_down-animation.luau'},
        ['nine'] = {music = 'Evil Musics/assumptions-background.mp3', anim = 'assumptions-animation.luau'},
        ['zero'] = {music = 'Evil Musics/shigure_ui-background.mp3', anim = 'shigure_ui-animation.luau'}
    };
}

local STICKERS = {
	['q'] = {sound = 'Evil Effects/the_rock-effect.mp3', image = 11648246803}, ['f']  = {sound = 'Evil Effects/la_bendicion-effect.mp3', image = 140068475155116}, ['c'] = {sound = 'Evil Effects/chad-effect.mp3', image = 10867751884},
	['e'] = {sound = 'Evil Effects/que_pro-effect.mp3', image = 8373881910}, ['g'] = {sound = 'Evil Effects/get_out-effect.mp3', image = 78437391}, ['v'] = {sound = 'Evil Effects/you_bastards-effect.mp3', image = 13981973301},
	['r'] = {sound = 'Evil Effects/sad_spongebob-effect.mp3', image = 10729455634}, ['h'] = {sound = 'Evil Effects/tsundere-effect.mp3', image = 94404853592451}, ['b'] = {sound = 'Evil Effects/bruh-effect.mp3', image = 5264933189},
	['t'] = {sound = 'Evil Effects/einstein_tesla-effect.mp3', image = 15285912871}, ['j'] = {sound = 'Evil Effects/boykisser-effect.mp3', image = 14841432885}, ['n'] = {sound = 'Evil Effects/eric_crying-effect.mp3', image = 14821042789},
	['y'] = {sound = 'Evil Effects/iq-effect.mp3', image = 9905477935}, ['k'] = {sound = 'Evil Effects/100_dollars-effect.mp3', image = 18651621418}, ['m'] = {sound = 'Evil Effects/mambo-effect.mp3', image = 94292546842967},
	['u'] = {sound = 'Evil Effects/ysn-effect.mp3', image = 9802355141}, ['l'] = {sound = 'Evil Effects/say_wallahi-effect.mp3', image = 117651988026572},
	['i'] = {sound = 'Evil Effects/are_u_sure-effect.mp3', image = 78733623040503}, ['ñ'] = {sound = 'Evil Effects/pocion_china-effect.mp3', image = 77947597511300},
	['o'] = {sound = 'Evil Effects/ah_shwga-effect.mp3', image = 14979876817}, ['z'] = {sound = 'Evil Effects/burenyuu-effect.mp3', image = 9758741504},
	['p'] = {sound = 'Evil Effects/wtf_boom-effect.mp3', image = 5178174483}, ['x'] = {sound = 'Evil Effects/polyester-effect.mp3', image = 127092847754218},
}
--}

--// LOCAL FUNCTIONS {
local function HTTP_REQUEST(id, rep, write)
    local name = id:gsub('Evil Musics/', ''):gsub('Evil Effects/', '')

    if write then
        if isfile and writefile and not isfile(id) then
            local url = 'https://github.com/taskSpawner2666/SpawnerStuff/raw/refs/heads/main/'.. rep.. "/".. name
            local success, body = pcall(function() return game:HttpGet(url) end)
            
            if success and body then
                writefile(id, body)
				print(url)
            else
                warn('Failed to load music: ' .. url)
                return nil
            end
        end

        if getcustomasset then return getcustomasset(id)
        elseif getsynasset then return getsynasset(id)
        else warn('Expected `getcustomasset` global function. Incompatible executor.') return nil
        end
    else
        local url = 'https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/'.. rep.. "/".. name
        local success, body = pcall(function() return game:HttpGet(url) end)
        
        if success and body then
            local loaded = loadstring(body)
            if loaded then return loaded() end
        end
        
        warn('Failed to load animation: ' .. url)
        return nil
    end
end

local function chooseOst()
    local choice = math.random(1, 3)
    if choice == 1 then return HTTP_REQUEST('Evil Musics/diginova-ost.mp3', 'Musics', true)
    elseif choice == 2 then return HTTP_REQUEST('Evil Musics/shh-ost.mp3', 'Musics', true)
    elseif choice == 3 then return HTTP_REQUEST('Evil Musics/duck_ndive-ost.mp3', 'Musics', true)
    end
end

local function playanim(anim, model, loop, speed)
    loop = loop == nil and true or loop
    speed = speed or 1

    if currentanim then
        currentanim:Stop()
        currentanim = nil
    end

    local newAnim = Animator.new(model, anim)
    newAnim.Looped = loop
    newAnim.Speed = speed
    newAnim:Play()

    currentanim = newAnim
    dancing = true
end

local function spawnSticker(image, soundId)
    local sticker = Instance.new('ImageLabel', bgui)
    sticker.Image = 'rbxthumb://type=Asset&id='.. tostring(image) ..'&w=420&h=420'
    sticker.ImageTransparency = 0
    sticker.BackgroundTransparency = 0
    sticker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    sticker.AnchorPoint = Vector2.new(0.5, 0.5)
    sticker.Position = UDim2.fromScale(0.5, 0.5)
    sticker.Size = UDim2.fromScale(2, 2)

    local sound = Instance.new('Sound', CHAR.Head)
    sound.SoundId = HTTP_REQUEST(soundId, 'Sound%20Effects', true)
    sound.Volume = 2

    sound.Ended:Connect(function()
        local tween = TS:Create(sticker, TweenInfo.new(1), {ImageTransparency = 1, BackgroundTransparency = 1})
        tween.Completed:Connect(function()
            sticker:Destroy()
            sound:Destroy()
        end)
        
        tween:Play()
    end)

    sound:Play()
end

local function stopanim(resumeOst)
    if currentanim then
        currentanim:Stop()
        currentanim = nil
    end

    sound50:Stop()
    dancing = false

    if resumeOst and ost3.IsPaused then
        ost3:Resume()
    end
end
--}

--// ANIMATION EVENTS {
INPUTCONNECT = UIS.InputBegan:Connect(function(input, gameProcessed)
	-- shit from kdv3 btw (but improved)
    if HUM.Sit or gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == Enum.KeyCode.None then return end
    
    local k = string.lower(
    	string.gsub(
    		tostring(input.KeyCode),
    		'Enum.KeyCode.',
    		''
    	)
    )
	
	if page == 1 then
		currentPage = EMOTES_PAGES[page]
		if currentPage[k] then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			
			emote = currentPage[k]
			sound50.SoundId = HTTP_REQUEST(emote.music, 'Musics', true)
			anim50 = HTTP_REQUEST(emote.anim, 'AnimTables', false)
			
			if sound50.SoundId and anim50 then
				sound50:Play()
				playanim(anim50, CHAR)
			end
		end
	
	elseif page == 2 then
		currentPage = EMOTES_PAGES[page]
		if k == 'one' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'two' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'three' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'four' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'five' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'six' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'seven' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'eight' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'nine' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'zero' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		end
	elseif page == 3 then
		currentPage = EMOTES_PAGES[page]
		if currentPage[k] then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			
			emote = currentPage[k]
			sound50.SoundId = HTTP_REQUEST(emote.music, 'Musics', true)
			anim50 = HTTP_REQUEST(emote.anim, 'AnimTables', false)
			
			if sound50.SoundId and anim50 then
				sound50:Play()
				playanim(anim50, CHAR)
			end
		end
	elseif page == 4 then
		currentPage = EMOTES_PAGES[page]
		if k == 'one' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'two' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'three' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'four' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'five' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'six' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'seven' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'eight' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'nine' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		elseif k == 'zero' then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			--..
		end
	elseif page == 5 then
		currentPage = EMOTES_PAGES[page]
		if currentPage[k] then
			if dancing and lastKey == k then stopanim(true) lastKey = nil return end
			lastKey = k
			stopanim(false)
			ost3:Pause()
			
			emote = currentPage[k]
			sound50.SoundId = HTTP_REQUEST(emote.music, 'Musics', true)
			anim50 = HTTP_REQUEST(emote.anim, 'AnimTables', false)
			
			if sound50.SoundId and anim50 then
				sound50:Play()
				playanim(anim50, CHAR)
			end
		end
	end
	
	if STICKERS[k] then
		if not return_stickers then
			sticker23 = STICKERS[k]
			spawnSticker(sticker23.image, sticker23.sound)
		else
			return
		end
	end
	
	if k == 'backspace' then
		return_stickers = not return_stickers
        if return_stickers then
            for _,v in bgui:GetChildren() do if v:IsA("ImageLabel") then v:Destroy() end end
            for _,v in CHAR.Head:GetChildren() do if v:IsA("Sound") then v:Destroy() end end
        end

        SG:SetCore('SendNotification', {
			Title = 'Evil Experience',
			Text = return_stickers and 'Stickers Disabled.' or 'Stickers Enabled.',
			Duration = 3.5
		})
	end
	
	if k == 'capslock' then
		page = (page >= MAX_PAGES) and 1 or (page + 1)
		SG:SetCore('SendNotification', {
			Title = 'Evil Experience',
			Text = 'You are in page ' .. tostring(page) .. ' now!',
			Duration = 3.5
		})
	end
end)
--}

--// INIT BACKGROUND MUSIC {
ost3.SoundId = chooseOst()
if ost3.SoundId then ost3:Play() end

OSTENDED = ost3.Ended:Connect(function()
	ost3.SoundId = chooseOst()
	if ost3.SoundId then ost3:Play() end
end)
--}

--// CLEANUP ON DEATH {
HUM.Died:Connect(function()
	stopanim(false)
    if currentanim then currentanim:Destroy() end
	if sound50 then sound50:Destroy() end
	if ost3 then ost3:Destroy() end
	if bgui then bgui:Destroy() end
	if INPUTCONNECT then INPUTCONNECT:Disconnect() INPUTCONNECT = nil end
	if OSTENDED then OSTENDED:Disconnect() OSTENDED = nil end
	for _,v in CHAR.Head:GetChildren() do if v:IsA('Sound') then v:Destroy() end end
	
	_G.EvilExperienceLoaded = nil
end)
--}
