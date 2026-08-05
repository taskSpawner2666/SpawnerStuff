local AnimPlayer = {}
AnimPlayer.__index = AnimPlayer
AnimPlayer.ClassName = 'Animator v1.5'

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
		local entry = { Time = frame.Time, Data = {} }
		for _, pose in ipairs(frame:GetDescendants()) do
			if pose:IsA('Pose') and pose.Weight > 0 then
				entry.Data[pose.Name] = { CFrame = pose.CFrame }
			end
		end
		table.insert(seq, entry)
	end
	table.sort(seq, function(a, b) return a.Time < b.Time end)
	return seq, kfs.Loop
end

local function ReadPose(pose, data)
    data[pose.Name] = {
        CFrame = CFrame.new(unpack(pose.CFrame))
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
    self.SavedC0 = {}
    
    local humanoid = charRig:FindFirstChild('Humanoid')
    if humanoid then
        self.diedConnection = humanoid.Died:Connect(function()
            self:Stop()
            self:RestoreMotors()
        end)
    end
    
    for _, m in pairs(self.Motors) do
		self.SavedC0[m] = m.C0
    end
    
    return self
end

function AnimPlayer:Play()
    local Animate = self.Character:FindFirstChild('Animate')
    local Animator = self.Character.Humanoid:FindFirstChild('Animator')
    if Animate and Animator then Animate.Disabled = true Animator:Destroy() end

    if self.IsPlaying then return end
	self:RestoreMotors()
	self.IsPlaying = true
	self.CurrentKeyframe = 1
	self.TimePosition = 0
	
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
				self:RestoreMotors()
				return
			end
		end

		while self.CurrentKeyframe < #self.Sequence and self.TimePosition >= self.Sequence[self.CurrentKeyframe + 1].Time do
		    self.CurrentKeyframe += 1
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
		            
		            local cf = pose1.CFrame:Lerp(pose2.CFrame, alpha)
		            motor.C0 = self.SavedC0[motor] * cf
		        end)
		    end
		end
	end)
end

function AnimPlayer:Stop()
    if not self.IsPlaying then warn('Expected animation playing') end
    self.IsPlaying = false
    
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    if self.diedConnection then
        self.diedConnection:Disconnect()
        self.diedConnection = nil
    end
    
    local Animate = self.Character:FindFirstChild('Animate')
    if Animate then Animate.Enabled = true end
    
    local Humanoid = self.Character:FindFirstChild('Humanoid')
    if Humanoid and not Humanoid:FindFirstChildOfClass('Animator') then
        local Animator = Instance.new('Animator', Humanoid)
    end
    
    self.Stopped:Fire()
end

function AnimPlayer:RestoreMotors()
    for motor, origC0 in pairs(self.SavedC0) do
		pcall(function() motor.C0 = origC0 end)
	end
end

local Character = Services.Players.LocalPlayer.Character
local Humanoid = Character['Humanoid']
local RootPart = Character['HumanoidRootPart']
local Head = Character:FindFirstChild('Head')

Services.RunService.RenderStepped:Connect(function(dt: number)
    local function Alpha(n)
        return math.clamp(n * dt * 60, 0, 1)
    end
	Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp((RootPart.CFrame * CFrame.new(0, 1.5, 0)):PointToObjectSpace(Head.Position),Alpha(0.15))
end)

pcall(function()
    Services.StarterGui:SetCore('SendNotification', {
        Title = 'API Animator',
        Text = 'TaskSpawner API Loaded',
        Button1 = 'Ok!'
    })
end)
    warn(AnimPlayer.ClassName)

return AnimPlayer;
