local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer
AnimPlayer.ClassName = 'Animator'
AnimPlayer.Version = 3.4

--local Signal = require(script:WaitForChild('LuauPureSignal'))

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
	if not Animate then return end

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
	if not Animate then return end

	local Humanoid = self.Character:FindFirstChild('Humanoid')
	if not Humanoid then return end

	local Animator = Humanoid:FindFirstChild('Animator')
	if not Animator then Instance.new('Animator', Humanoid) end

	-- Los LocalScript usan Disabled, no Enabled
	Animate.Disabled = false
end

function AnimPlayer.new(charRig, anim)
	local self = setmetatable({}, AnimPlayer)
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
		
		self.CameraConnection = Services.RunService.RenderStepped:Connect(function(dt: number)
			local function Alpha(n)
				return math.clamp(n * dt * 60, 0, 1)
			end
			humanoid.CameraOffset = humanoid.CameraOffset:Lerp((rootPart.CFrame * CFrame.new(0, 1.5, 0)):PointToObjectSpace(head.Position), Alpha(0.15))
		end)
	end)
	
	return self
end

function AnimPlayer:Play()
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

	-- Capturar la pose actual del rig para el fade-in
	self.StartC0 = {}
	for motor in pairs(self.SavedC0) do
		self.StartC0[motor] = motor.C0
	end

	self.Connection = Services.RunService.Heartbeat:Connect(function(dt)
		if not self.IsPlaying then return end
		self.TimePosition += dt * self.Speed
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
		local alpha = 0

		if currentFrame ~= nextFrame then
			alpha = (self.TimePosition - currentFrame.Time) / (nextFrame.Time - currentFrame.Time)
			alpha = math.clamp(alpha, 0, 1)
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
						local fadeAlpha = math.clamp(self.TimePosition / self.FadeTime, 0, 1)
						motor.C0 = self.StartC0[motor]:Lerp(targetC0, fadeAlpha)
					else
						motor.C0 = targetC0
					end
				end)
			end
		end
	end)
end

function AnimPlayer:Stop(restore)
	if restore == nil then restore = true
	elseif typeof(restore) ~= 'boolean' then error('[ERROR]: Invalid #1 parameter inserted.') end

	self.IsPlaying = false

	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	if self.diedConnection then
		self.diedConnection:Disconnect()
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

task.wait(.1)

warn(AnimPlayer.ClassName.. " ".. AnimPlayer.Version.. " Loaded.")

Services.StarterGui:SetCore('SendNotification', {
	Title = 'Animator API v'.. tostring(AnimPlayer.Version);
	Text = 'Welcome '.. Services.Players.LocalPlayer.DisplayName.. "!";
	Button1 = 'Ok!';
	Button2 = 'Bye!';
})

return AnimPlayer;
