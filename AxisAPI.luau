local AxisAPI = {}
AxisAPI.Version = 1.4

local recording = false
local connection = nil
local cutscene = {}
local code

local Services = {
	Players = game:GetService('Players');
	StarterGui = game:GetService('StarterGui');
	TweenService = game:GetService('TweenService');
	RunService = game:GetService('RunService');
}

local npcs = {
	['Guest'] = {
		ID = 'rbxassetid://364978886',
		Name = 'Guest'
	};
	['Noob'] = {
		ID = 'rbxassetid://4446576906',
		Name = 'Noob'
	};
	['Bacon'] = {
		ID = 'rbxassetid://8477690354',
		Name = 'Bacon'
	};
	['Dummy'] = {
		ID = 'rbxassetid://8114157416',
		Name = 'Dummy'
	};
}

local messageTable = {
	Credits = '-- // KFS CONVERTED TO LUA TABLE BY AXIS API // --',
	PropertiesTitle = '-- Code assignment: --',
	Name = '-- [[ {keyName} KeyframeSequence`s ]] --',
	Marker = '-- [[ Keyframes Converted: {num} ]] --'
}

local player = Services.Players.LocalPlayer
local char = player["Character"]
local cam = workspace.CurrentCamera

local function parsePose(pose)
    local poseData = {
        Name = pose.Name;
        CFrame = {pose.CFrame:GetComponents()};
        EasingStyle = pose.EasingStyle.Name;
        EasingDirection = pose.EasingDirection.Name;
    }
    
    local children = {}
    for _, subPose in ipairs(pose:GetChildren()) do
        if subPose:IsA('Pose') then
            table.insert(children, parsePose(subPose))
        end
    end
    poseData.SubPoses = children
    return poseData
end

local function tableToString(tbl, indent)
    indent = indent or ''
    local result = '{\n'
    for k, v in pairs(tbl) do
        local key = type(k) == 'number' and '' or '["' .. tostring(k) .. '"] = '
        if type(v) == 'table' then
            result = result .. indent .. "  " .. key .. tableToString(v, indent .. "  ") .. ',\n'
        elseif type(v) == 'number' then
            result = result .. indent .. "  " .. key .. string.format('%.9g', v) .. ',\n'
        elseif type(v) == 'string' then
            result = result .. indent .. "  " .. key .. string.format('%q', v)
        end
    end
    
    return result .. indent .. '}'
end

local function framesToString(cTable)
	local lines = {}
	table.insert(lines, "local Frames = {")

	for i, frame in ipairs(cTable) do
		local components = {frame.CFrame:GetComponents()}
		for k, v in ipairs(components) do
			components[k] = string.format("%.8g", v)
		end

		local cframe = "CFrame.new(".. table.concat(components, ", ").. ")"
		local frameLine = string.format(
			"\t[%d] = {CFrame = %s, Fov = %.6f, dt = %.6f};",
			i,
			cframe,
			frame.Fov,
			frame.dt
		)
		table.insert(lines, frameLine)
	end

	table.insert(lines, "}")
	return table.concat(lines, "\n")
end

local function startCutsceneLog()
	if recording then return end
	task.wait()
	recording = true
	cutscene = {}

	local root = char["HumanoidRootPart"]
	warn("[AXIS API]: Saving cutscene into cache code..")

	connection = Services.RunService.RenderStepped:Connect(function(dt)
		local frameData = {
			CFrame = root.CFrame:ToObjectSpace(cam.CFrame),
			Fov = cam.FieldOfView,
			dt = dt
		}
		table.insert(cutscene, frameData)
	end)
end

local function finishCutsceneLog(name)
	if not recording then return end
	task.wait()
	recording = false

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if #cutscene > 0 then
		code = framesToString(cutscene)
		if writefile then
			writefile(name, code)
			print('✅Cutscene saved succesfully✅')
		else
			error("Expected 'writefile' global function, Unsupported executor.")
		end
	else
		error('[ERROR]: Expected cutscene to save, got nil')
		return
	end
end

AxisAPI.SpawnNPC = function(config)
	if typeof(config) ~= 'table' then
    	warn('[WARN] If you dont have a UserId, you can insert a string with a predetermined character value into UserId (Guest, Noob, Bacon, Dummy).')
    	error('[ERROR] Expected a valid table / [CONTEXT]: This function expects a configured table (Name, UserId, Position).')
	end
	
	if typeof(config.UserId) == 'string' then
		if npcs[config.UserId] then
			local model = game:GetObjects(npcs[config.UserId].ID)[1]
			model.Name = config.Name or npcs[config.UserId].Name
			model.Parent = workspace
			model:MoveTo(config.Position or Vector3.new(0, 0, 1.2))
		else
			error('[ERROR] Default character not founded / [CONTEXT]: String key was not founded in default characters table.')
			return
		end
	elseif typeof(config.UserId) == 'number' then
		local model = Services.Players:CreateHumanoidModelFromUserId(config.UserId)
		if model then
			if not config.Name then model.Name = Services.Players:GetNameFromUserIdAsync(config.UserId)
			else model.Name = config.Name end
			model:MoveTo(config.Position or Vector3.new(0, 0, 1.2))
			model.Parent = workspace
		end
	else
		error('Invalid argument #1 / [CONTEXT]: UserId not founded or Invalid String')
	end
end

AxisAPI.DecodeRBXMSequence = function(kfs)
	if not kfs or not kfs:IsA('KeyframeSequence') then
		warn('Please, Insert an valid KFS before run this convertor.')
    	return
	end
	
	local totalKf = 0
	for _,kf in ipairs(kfs:GetChildren()) do
    	if kf:IsA('Keyframe') then
        	totalKf += 1
    	end
	end

	if totalKf <= 1 then
    	messageTable.Marker = string.gsub(messageTable.Marker, ' Keyframes', ' Keyframe')
    else
    	messageTable.Marker = string.gsub(messageTable.Marker, ' Keyframe', ' Keyframes')
	end

	messageTable.Name = string.gsub(messageTable.Name, '{keyName}', kfs.Name)
	messageTable.Marker = string.gsub(messageTable.Marker, '{num}', tostring(totalKf))

	local animationTable = {}
	for _, keyframe in ipairs(kfs:GetKeyframes()) do
    	local kfData = {
        	Time = keyframe.Time,
        	Poses = {}
		}
    	for _, pose in ipairs(keyframe:GetChildren()) do
        	if pose:IsA('Pose') then
            	table.insert(kfData.Poses, parsePose(pose))
        	end
    	end
    	table.insert(animationTable, kfData)
	end
	
	table.sort(animationTable, function(a, b) return a.Time < b.Time end)
	
	local fileName = kfs.Name:gsub('[<>:\'/\\|?*]', '_') .. '.luau'
	local header = table.concat({
    	'-- // KFS CONVERTED TO LUA TABLE BY AXIS API // --',
    	'-- WARNING: THIS IS NOT A PLUGIN',
    	'-- Animation: ' .. kfs.Name,
    	'-- Keyframes: ' .. totalKf,
    	'-- Looped: ' .. tostring(kfs.Loop),
    	'-- Generated by Axis API',
    	''
	}, '\n')
	local code =
    	header ..
    	'return {\n' ..
    	'    Looped = ' .. tostring(kfs.Loop) .. ',\n' ..
    	tableToString(animationTable, '    '):sub(2, -2) ..
    	'\n}'

	writefile(fileName, code)

    warn(("DecodeRBXMSequence: '%s' exported successfully!"):format(fileName))
end

AxisAPI.CutsceneLogger = function(name)
	local defaultCamera = cam.CameraType
	local fileName = name.. "_cutscene.luau"

	cam:GetPropertyChangedSignal("CameraType"):Connect(function()
		if cam.CameraType ~= defaultCamera then
			startCutsceneLog()
		elseif cam.CameraType == defaultCamera then
			finishCutsceneLog(fileName)
		end
	end)
end

pcall(function()
	if player then
		Services.StarterGui:SetCore("SendNotification", {
			Title = "Axis API v".. tostring(AxisAPI.Version);
			Text = "Axis API Loaded (TaskSpawner)";
			Button1 = "Ok!";
			Button2 = "Bye!";
			Icon = "rbxthumb://type=Asset&id=134211110776652&w=150&h=150";
			Duration = 10.5;
		})
	end
end)

return AxisAPI;
