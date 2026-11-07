--[[_______________________/=========================\@@@
==>     ___          _                 __			  <==
==>    /   |  ____  (_)___ ___  ____ _/ /_____  _____ <==
==>   / /| | / __ \/ / __ `__ \/ __ `/ __/ __ \/ ___/ <==
==>  / ___ |/ / / / / / / / / / /_/ / /_/ /_/ / /	  <==
==> /_/  |_/_/ /_/_/_/ /_/ /_/\__,_/\__/\____/_/	  <==
==>									>>>TaskSpawner    <==
@@@========================\_________________________/--]]

--[[
    =================== HOW TO USE ====================

    1. >INITIALIZATION
    ---------------------------------------------------
    [Initialize Animator API]:
    	local Animator = loadstring(game:HttpGet('https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/Animator.luau'))()
    
    [Then, create an animation by inserting the following parameters]:
        - Character: The character Model to animate.
        - Animation: A KeyframeSequence or animation table.
    	[Example]:
        	local anim = Animator.new(character, animationData) --Character,Animation

    2. >CONFIGURATION
    ---------------------------------------------------
    [Configure the animation before playing it]: -- Optional
        anim.Speed = 1
        anim.Looped = false
        anim.FadeTime = 0.2
    [Available properties]:
        Speed        - Playback speed.
        Looped       - Enables or disables looping.
        FadeTime     - Motor transition duration (Default: 0.15).
        TimePosition - Current playback position.

    3. >PLAYBACK
    ---------------------------------------------------
    Start the animation --> anim:Play()
    Stop the animation --> anim:Stop()
    Stop without restoring the original motor positions --> anim:Stop(false) -- Default: true

    4. >EVENTS
    ---------------------------------------------------
    [Connect to the Animator's signals]:
        anim.Stopped
        anim.DidLoop
        anim.KeyframeReached
    [Example]:
        anim.KeyframeReached:Connect(function(index, time)
            print("Keyframe:", index, time)
        end)

    5. >CLEANUP
    ---------------------------------------------------
    [Destroy the Animator instance if its no longer needed]:
        anim:Destroy()
    This cleans up its connections and signals.
    ===================================================
]]

local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer
AnimPlayer.ClassName = 'Animator'
AnimPlayer.Version = 3.91

local Signal = require(script:FindFirstChild('LuauPureSignal')) or loadstring(game:HttpGet("https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/LUAUTools/LuauPureSignal.luau"))()
local Maid = require(script:FindFirstChild('LuauPureMaid')) or loadstring(game:HttpGet("https://raw.githubusercontent.com/taskSpawner2666/SpawnerStuff/refs/heads/main/LUAUTools/LuauPureMaid.luau"))()

local Services = {
	Players = game:GetService('Players');
	StarterGui = game:GetService('StarterGui');
	RunService = game:GetService('RunService');
	TweenService = game:GetService('TweenService');
}

local R6Map = {
	['Head'] = 'Neck';
	['Torso'] = 'RootJoint';
	['Right Arm'] = 'Right Shoulder';
	['Left Arm'] = 'Left Shoulder';
	['Right Leg'] = 'Right Hip';
	['Left Leg'] = 'Left Hip';
}

local __EasingStyles__ = Enum.EasingStyle
local __EasingDirections__ = Enum.EasingDirection
local __Enum__PoseEasingStyle__ = #'Enum.PoseEasingStyle.'
local __Enum__PoseEasingDirection__ = #'Enum.PoseEasingDirection.'

local function EasingStyleFix(style)
	if tostring(style) == 'Enum.EasingStyle.Constant' then return "Constant" end

	local name = string.sub(tostring(style), __Enum__PoseEasingStyle__ + 1)
	local suc, res = pcall(function()
		return __EasingStyles__[name]
	end)
	if not suc then
		return Enum.EasingStyle.Linear
	end
	
	return res
end

local function EasingDirectionFix(dir)
	local name = string.sub(tostring(dir), __Enum__PoseEasingDirection__ + 1)
	return __EasingDirections__[name] or Enum.EasingDirection.In
end

local function FindMotor(poseName, map, lower)
	local match = R6Map[poseName] or poseName
	return map[match] or lower[string.lower(match)]
end

local function BuildMotorMap(rig)
	local map, lower = {}, {}
	for _, m in ipairs(rig:GetDescendants()) do
		if m:IsA('Motor6D') then
			map[m.Name] = m
			lower[string.lower(m.Name)] = m
		end
	end
	return map, lower
end

local function ConvertToTable(kfs)
	assert(typeof(kfs) == 'Instance', 'Expected Instance')
	if not kfs:IsA('KeyframeSequence') then
		for _, obj in ipairs(kfs:GetDescendants()) do
			if obj:IsA('KeyframeSequence') then
				kfs = obj
				break
			end
		end
	end

	assert(kfs and typeof(kfs) == 'Instance' and kfs:IsA('KeyframeSequence'), 'Expected KeyframeSequence')

	local seq = {}
	for _, frame in ipairs(kfs:GetKeyframes()) do
		local entry = {
			Time = frame.Time,
			Data = {}
		}
		for _, pose in ipairs(frame:GetDescendants()) do
			if pose:IsA('Pose') and pose.Weight > 0 then
				entry.Data[pose.Name] = {
					CFrame = pose.CFrame;
					EasingStyle = EasingStyleFix(pose.EasingStyle);
					EasingDirection = EasingDirectionFix(pose.EasingDirection);
					Weight = pose.Weight;
				}
			end
		end
		table.insert(seq, entry)
	end
	table.sort(seq, function(a, b) return a.Time < b.Time end)
	return seq, kfs.Loop
end

local function ReadPose(pose, data)
	data[pose.Name] = {
		CFrame = CFrame.new(unpack(pose.CFrame));
		EasingStyle = pose.EasingStyle;
		EasingDirection = pose.EasingDirection;
		Weight = pose.Weight;
	}

	for _, sub in ipairs(pose.SubPoses) do
		ReadPose(sub, data)
	end
end

local function ConvertAnimationTable(animTable)
	local seq = {}
	for _, frame in ipairs(animTable) do
		local entry = {
			Time = frame.Time,
			Data = {}
		}
		for _, pose in ipairs(frame.Poses) do
			ReadPose(pose, entry.Data)
		end
		table.insert(seq, entry)
	end

	return seq
end

local function RestoreMotors(self)
	for motor, origC0 in pairs(self.SavedC0) do
		motor.C0 = origC0
	end
end

local function TransformIdentity(self)
	for _, motor in pairs(self.Motors) do
		motor.Transform = CFrame.identity
	end
end

local function disableDefaultAnimations(self)
	local Animate = self.Character:FindFirstChild('Animate')
	if not Animate or not Animate:IsA('LocalScript') then return end

	local Humanoid = self.Character:FindFirstChild('Humanoid')
	if not Humanoid then return end

	local Animator = Humanoid:FindFirstChild('Animator')
	if not Animator then return end

	TransformIdentity(self)

	for _, v in ipairs(Animator:GetPlayingAnimationTracks()) do
		v:Stop()
	end

	Animate.Disabled = true
	Animator:Destroy()
end

local function enableDefaultAnimations(self)
	local Animate = self.Character:FindFirstChild('Animate')
	if not Animate or not Animate:IsA('LocalScript') then return end

	local Humanoid = self.Character:FindFirstChild('Humanoid')
	if not Humanoid then return end

	local Animator = Humanoid:FindFirstChild('Animator')
	if not Animator then Instance.new('Animator', Humanoid) end

	-- Los LocalScript usan Disabled, no Enabled
	Animate.Disabled = false
end

function AnimPlayer.new(charRig, anim)
	if typeof(charRig) ~= 'Instance' or not charRig:IsA('Model') then error('[ERROR]: Invalid #1 argument (not a model)') end
	
	local self = setmetatable({}, AnimPlayer)
	self.Destroyed = false
	
	self.Stopped = Signal.new()
	self.KeyframeReached = Signal.new()
	self.DidLoop = Signal.new()
	self.Sequence = {}
	self.Looped = false
	
	if typeof(anim) == 'Instance' and anim:IsA('KeyframeSequence') then
		self.Sequence, self.Looped = ConvertToTable(anim)
	elseif typeof(anim) == 'table' then
		self.Sequence, self.Looped = ConvertAnimationTable(anim), anim.Looped or false
	end
	
	assert(#self.Sequence > 0, 'Animation sequence is empty')
	
	self.Character = charRig
	self.Motors, self.LowerMap = BuildMotorMap(charRig)
	self.Speed, self.Length = 1, self.Sequence[#self.Sequence].Time
	self.TimePosition, self.CurrentKeyframe = 0, 1
	self.IsPlaying = false

	-- Duración del fade in/out en segundos (como el FadeTime de los AnimationTracks)
	self.FadeTime = 0.15

	self.SavedC0 = {}
	for _, m in pairs(self.Motors) do
		self.SavedC0[m] = m.C0
	end

	local humanoid = self.Character:FindFirstChild('Humanoid')
	if humanoid then
		self.diedConnection = humanoid.Died:Connect(function()
			self:Stop()
		end)
	end
	
	pcall(function()
		local rootPart = self.Character["HumanoidRootPart"]
		local head = self.Character["Head"]
		
		if humanoid and rootPart and head then
			self.CameraConnection = Services.RunService.RenderStepped:Connect(function(dt: number)
				local function Alpha(n)
					return math.clamp(n * dt * 60, 0, 1)
				end
				humanoid.CameraOffset = humanoid.CameraOffset:Lerp((rootPart.CFrame * CFrame.new(0, 1.5, 0)):PointToObjectSpace(head.Position), Alpha(0.15))
			end)
		end
	end)
	
	self._maid = Maid.new()
	self._maid.Stopped = self.Stopped
	self._maid.DidLoop = self.DidLoop
	self._maid.KeyframeReached = self.KeyframeReached
	
	self._maid.diedConnection = self.diedConnection
	self._maid.CameraConnection = self.CameraConnection
	
	return self
end

function AnimPlayer:Play()
	if self.Destroyed then error('[ERROR]: This animation cannot be player; Reason: nil') end
	
	if self.IsPlaying then return end
	disableDefaultAnimations(self)

	-- Reconectar diedConnection si fue desconectado por un Stop anterior
	if not self.diedConnection then
		local humanoid = self.Character:FindFirstChild('Humanoid')
		if humanoid then
			self.diedConnection = humanoid.Died:Connect(function()
				self:Stop()
			end)
		end
	end

	self.IsPlaying = true
	self.CurrentKeyframe = 1
	self.TimePosition = 0
	self.FadeInPosition = 0

	-- Capturar la pose actual del rig para el fade-in
	self.StartC0 = {}
	for motor in pairs(self.SavedC0) do
		self.StartC0[motor] = motor.C0
	end

	self.Connection = Services.RunService.Heartbeat:Connect(function(dt)
		if not self.IsPlaying then return end
		self.TimePosition += dt * self.Speed
		self.FadeInPosition += dt
		if self.TimePosition > self.Length then
			if self.Looped then
				self.TimePosition -= self.Length
				self.CurrentKeyframe = 1
				self.DidLoop:Fire()
			else
				self:Stop()
				return
			end
		end

		while self.CurrentKeyframe < #self.Sequence and self.TimePosition >= self.Sequence[self.CurrentKeyframe + 1].Time do
			self.CurrentKeyframe += 1
			self.KeyframeReached:Fire(self.CurrentKeyframe, self.TimePosition)
		end

		local currentFrame = self.Sequence[self.CurrentKeyframe]
		local nextFrame = self.Sequence[self.CurrentKeyframe + 1] or currentFrame
		local alpha = 1

		if self.FadeTime > 0 then
			alpha = math.clamp(
				self.FadeInPosition / self.FadeTime,
				0,
				1
			)
		end

		for jointName in pairs(currentFrame.Data) do
			local motor = FindMotor(jointName, self.Motors, self.LowerMap)
			if motor and self.SavedC0[motor] then
				pcall(function()
					local pose1 = currentFrame.Data[jointName]
					local pose2 = nextFrame.Data[jointName] or pose1
					local targetC0

					if pose2.EasingStyle == "Constant" then
						if alpha < 1 then
							targetC0 = self.SavedC0[motor] * pose1.CFrame
						else
							targetC0 = self.SavedC0[motor] * pose2.CFrame
						end
					else
						local easedAlpha = Services.TweenService:GetValue(
							alpha,
							pose2.EasingStyle,
							pose2.EasingDirection
						)

						local cf = pose1.CFrame:Lerp(pose2.CFrame, easedAlpha)
						targetC0 = self.SavedC0[motor] * cf
					end

					-- FADE-IN: mezclar la pose capturada al iniciar con la pose de la animación
					if self.FadeTime and self.FadeTime > 0 and self.StartC0[motor] then
						local fadeAlpha = math.clamp(self.FadeInPosition / self.FadeTime, 0, 1)
						motor.C0 = self.StartC0[motor]:Lerp(targetC0, fadeAlpha)
					else
						motor.C0 = targetC0
					end
				end)
			end
		end
	end)
	
	self._maid.Connection = self.Connection
end

function AnimPlayer:Stop(restore)
	if self.Destroyed then return end
	
	if restore == nil then restore = true
	elseif typeof(restore) ~= 'boolean' then error('[ERROR]: Invalid #1 parameter inserted.') end

	self.IsPlaying = false

	if self.Connection then
		self._maid.Connection = nil
		self.Connection = nil
	end

	if self.diedConnection then
		self._maid.diedConnection = nil
		self.diedConnection = nil
	end

	if restore == true then
		-- FADE-OUT: volver suavemente a la pose original antes de restaurar
		local startC0 = {}
		for motor in pairs(self.SavedC0) do
			startC0[motor] = motor.C0
		end
		local fadeTime = self.FadeTime or 0.2

		task.spawn(function()
			local t = 0
			while t < fadeTime do
				-- Cancelar el fade si se vuelve a reproducir la animación
				if self.IsPlaying then return end
				local dt = task.wait()
				t += dt
				local a = math.clamp(t / fadeTime, 0, 1)
				for motor, origC0 in pairs(self.SavedC0) do
					if startC0[motor] then
						motor.C0 = startC0[motor]:Lerp(origC0, a)
					end
				end
			end

			RestoreMotors(self)
			enableDefaultAnimations(self)
			self.Stopped:Fire()
		end)
	else
		enableDefaultAnimations(self)
		self.Stopped:Fire()
	end
end

function AnimPlayer:Destroy()
    if self.Destroyed then return end

    if self.IsPlaying then
        self.FadeTime = 0
        self:Stop(false)
    end

    self.Destroyed = true

    if self._maid then
        self._maid:DoCleaning()
    end
end

task.wait(.1)

warn(AnimPlayer.ClassName.. " v".. AnimPlayer.Version.. " Loaded.")

pcall(function()
	local plr = Services.Players.LocalPlayer
	if plr then
		Services.StarterGui:SetCore('SendNotification', {
			Title = 'Animator API v'.. tostring(AnimPlayer.Version);
			Text = 'Welcome '.. Services.Players.LocalPlayer.DisplayName.. "!";
			Button1 = 'Ok!';
			Button2 = 'Bye!';
		})
	end
end)

return AnimPlayer;

--//====================================================\\--
--||			  		 END OF SCRIPT
--\\====================================================//--
