-- Serializer.luau
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Serializer = {}

local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function toBase64(data: string): string
	local out = {}
	local len = #data
	for i = 1, len, 3 do
		local b1 = string.byte(data, i)
		local b2 = (i + 1 <= len) and string.byte(data, i + 1) or 0
		local b3 = (i + 2 <= len) and string.byte(data, i + 2) or 0

		local triple = bit32.bor(
			bit32.lshift(b1, 16),
			bit32.lshift(b2, 8),
			b3
		)

		local c1 = bit32.extract(triple, 18, 6) + 1
		local c2 = bit32.extract(triple, 12, 6) + 1
		local c3 = bit32.extract(triple, 6, 6) + 1
		local c4 = bit32.extract(triple, 0, 6) + 1

		table.insert(out, string.sub(B64_CHARS, c1, c1))
		table.insert(out, string.sub(B64_CHARS, c2, c2))
		table.insert(out, (i + 1 <= len) and string.sub(B64_CHARS, c3, c3) or "=")
		table.insert(out, (i + 2 <= len) and string.sub(B64_CHARS, c4, c4) or "=")
	end
	return table.concat(out)
end

local function escapeXml(str: string): string
	return str:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
		:gsub('"', "&quot;")
		:gsub("'", "&apos;")
end

local function formatProtectedString(name: string, src: string): string
	local safeCdata = string.gsub(src, "]]>", "]]]]><![CDATA[>")
	return string.format('<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>', name, safeCdata)
end

local function buildSmoothGridBinary(terrain: Terrain, halfExtentStuds: number): string?
	local ok, materials, occupancy = pcall(function()
		local minV = Vector3.new(-halfExtentStuds, -64, -halfExtentStuds)
		local maxV = Vector3.new(halfExtentStuds, 64, halfExtentStuds)
		local region = Region3.new(minV, maxV):ExpandToGrid(4)
		return terrain:ReadVoxels(region, 4)
	end)

	if not ok or not materials or not occupancy then
		return nil
	end

	local sx = #materials
	local sy = materials[1] and #materials[1] or 0
	local sz = (materials[1] and materials[1][1]) and #materials[1][1] or 0
	if sx == 0 or sy == 0 or sz == 0 then
		return nil
	end

	local bytes = {}
	local function pushU32(n: number)
		local v = math.max(0, math.floor(n))
		table.insert(bytes, string.char(
			bit32.band(v, 0xFF),
			bit32.band(bit32.rshift(v, 8), 0xFF),
			bit32.band(bit32.rshift(v, 16), 0xFF),
			bit32.band(bit32.rshift(v, 24), 0xFF)
		))
	end

	pushU32(sx)
	pushU32(sy)
	pushU32(sz)

	for x = 1, sx do
		for y = 1, sy do
			for z = 1, sz do
				local mat = materials[x][y][z]
				local occ = occupancy[x][y][z] or 0
				local matId = (typeof(mat) == "EnumItem" and mat.Value) or 0
				local occByte = math.clamp(math.floor(occ * 255 + 0.5), 0, 255)
				table.insert(bytes, string.char(
					bit32.band(matId, 0xFF),
					occByte,
					0,
					0
				))
			end
		end
		if x % 8 == 0 then
			task.wait()
		end
	end

	return table.concat(bytes)
end

function Serializer.New(ReflectionModule)
	local self = {
		Reflection = ReflectionModule,
		ReferentCount = 0,
		ReferentMap = {},
		ProcessedCount = 0,
		TotalEstimate = 1,
		EstimatedBytes = 0,
		DecompiledCount = 0,
		NilCount = 0,
		KeyframeSequencesCount = 0,
		Cancelled = false,
	}

	function self:GetReferent(instance: Instance): string
		if not self.ReferentMap[instance] then
			self.ReferentMap[instance] = "RBX" .. tostring(self.ReferentCount)
			self.ReferentCount += 1
		end
		return self.ReferentMap[instance]
	end

	local TypeHandlers = {
		string = function(name, val)
			return string.format('<string name="%s">%s</string>', name, escapeXml(tostring(val)))
		end,
		BinaryString = function(name, val)
			return string.format('<BinaryString name="%s">%s</BinaryString>', name, toBase64(tostring(val)))
		end,
		Content = function(name, val)
			local s = tostring(val)
			if s == "" then
				return string.format('<Content name="%s"><null></null></Content>', name)
			end
			return string.format('<Content name="%s"><url>%s</url></Content>', name, escapeXml(s))
		end,
		bool = function(name, val)
			return string.format('<bool name="%s">%s</bool>', name, val and "true" or "false")
		end,
		int = function(name, val)
			return string.format('<int name="%s">%d</int>', name, math.floor(tonumber(val) or 0))
		end,
		int64 = function(name, val)
			return string.format('<int64 name="%s">%s</int64>', name, tostring(val))
		end,
		float = function(name, val)
			return string.format('<float name="%s">%s</float>', name, tostring(val))
		end,
		double = function(name, val)
			return string.format('<double name="%s">%s</double>', name, tostring(val))
		end,
		token = function(name, val)
			local num = typeof(val) == "EnumItem" and val.Value or tonumber(val) or 0
			return string.format('<token name="%s">%d</token>', name, num)
		end,
		BrickColor = function(name, val)
			local bc = typeof(val) == "BrickColor" and val or BrickColor.new(tonumber(val) or 194)
			return string.format('<int name="%s">%d</int>', name, bc.Number)
		end,
		PhysicalProperties = function(name, val)
			if typeof(val) ~= "PhysicalProperties" then
				return string.format('<PhysicalProperties name="%s"><CustomPhysics>false</CustomPhysics></PhysicalProperties>', name)
			end
			return string.format(
				'<PhysicalProperties name="%s"><CustomPhysics>true</CustomPhysics><Density>%s</Density><Friction>%s</Friction><Elasticity>%s</Elasticity><FrictionWeight>%s</FrictionWeight><ElasticityWeight>%s</ElasticityWeight></PhysicalProperties>',
				name, val.Density, val.Friction, val.Elasticity, val.FrictionWeight, val.ElasticityWeight
			)
		end,
		Rect = function(name, val)
			return string.format(
				'<Rect name="%s"><min><X>%s</X><Y>%s</Y></min><max><X>%s</X><Y>%s</Y></max></Rect>',
				name, val.Min.X, val.Min.Y, val.Max.X, val.Max.Y
			)
		end,
		Color3 = function(name, val)
			return string.format('<Color3 name="%s"><R>%s</R><G>%s</G><B>%s</B></Color3>', name, val.R, val.G, val.B)
		end,
		Color3uint8 = function(name, val)
			local r = math.floor(val.R * 255 + 0.5)
			local g = math.floor(val.G * 255 + 0.5)
			local b = math.floor(val.B * 255 + 0.5)
			local packed = bit32.bor(0xFF000000, bit32.lshift(r, 16), bit32.lshift(g, 8), b)
			return string.format('<Color3uint8 name="%s">%u</Color3uint8>', name, packed)
		end,
		Vector2 = function(name, val)
			return string.format('<Vector2 name="%s"><X>%s</X><Y>%s</Y></Vector2>', name, val.X, val.Y)
		end,
		Vector3 = function(name, val)
			return string.format('<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>', name, val.X, val.Y, val.Z)
		end,
		UDim = function(name, val)
			return string.format('<UDim name="%s"><S>%s</S><O>%d</O></UDim>', name, val.Scale, val.Offset)
		end,
		UDim2 = function(name, val)
			return string.format(
				'<UDim2 name="%s"><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>',
				name, val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset
			)
		end,
		NumberRange = function(name, val)
			return string.format('<NumberRange name="%s">%s %s </NumberRange>', name, val.Min, val.Max)
		end,
		ColorSequence = function(name, val)
			local parts = {}
			for _, kp in ipairs(val.Keypoints) do
				table.insert(parts, string.format("%s %s %s %s %s", kp.Time, kp.Value.R, kp.Value.G, kp.Value.B, kp.Envelope or 0))
			end
			return string.format('<ColorSequence name="%s">%s </ColorSequence>', name, table.concat(parts, " "))
		end,
		NumberSequence = function(name, val)
			local parts = {}
			for _, kp in ipairs(val.Keypoints) do
				table.insert(parts, string.format("%s %s %s", kp.Time, kp.Value, kp.Envelope or 0))
			end
			return string.format('<NumberSequence name="%s">%s </NumberSequence>', name, table.concat(parts, " "))
		end,
		CoordinateFrame = function(name, val)
			local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = val:GetComponents()
			return string.format(
				'<CoordinateFrame name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z>' ..
				'<R00>%s</R00><R01>%s</R01><R02>%s</R02>' ..
				'<R10>%s</R10><R11>%s</R11><R12>%s</R12>' ..
				'<R20>%s</R20><R21>%s</R21><R22>%s</R22></CoordinateFrame>',
				name, x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22
			)
		end,
		Ref = function(name, val)
			local ref = val and self:GetReferent(val) or "null"
			return string.format('<Ref name="%s">%s</Ref>', name, ref)
		end,
	}

	local function pushLine(buffer: {string}, serializerSelf, line: string)
		table.insert(buffer, line)
		serializerSelf.EstimatedBytes += #line + 1
	end

	function self:EstimateTotal(options): number
		local total = 0
		for serviceName, enabled in pairs(options.Services) do
			if enabled then
				local ok, service = pcall(function() return game:GetService(serviceName) end)
				if ok and service then
					total += 1 + #service:GetDescendants()
				end
			end
		end
		if options.IncludeLocalPlayerData and Players.LocalPlayer then
			local pGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if pGui then total += #pGui:GetDescendants() end
			local pScripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
			if pScripts then total += #pScripts:GetDescendants() end
		end
		if options.NilInstances and typeof(getnilinstances) == "function" then
			local ok, list = pcall(getnilinstances)
			if ok and type(list) == "table" then
				total += #list
			end
		end
		return math.max(1, total)
	end

	function self:DecompileWithTimeout(scriptInstance: Instance, timeoutSec: number): string
		local finished = false
		local result = "-- [Decompile no disponible]"

		if typeof(decompile) ~= "function" then
			return "-- [Funcion decompile() no encontrada en el entorno]"
		end

		local thread = task.spawn(function()
			local ok, output = pcall(decompile, scriptInstance)
			if not finished then
				finished = true
				if ok and type(output) == "string" and #output > 0 then
					self.DecompiledCount += 1
					result = output
				else
					result = "-- [Error al descompilar: " .. tostring(output) .. "]"
				end
			end
		end)

		task.delay(timeoutSec, function()
			if not finished then
				finished = true
				pcall(task.cancel, thread)
				result = string.format("-- [Timeout %.1fs: %s]", timeoutSec, scriptInstance.Name)
			end
		end)

		while not finished and not self.Cancelled do
			task.wait(0.03)
		end

		if self.Cancelled then
			pcall(task.cancel, thread)
			return "-- [Cancelado]"
		end

		return result
	end

	function self:CollectMotor6Ds(root: Instance, out: {Motor6D})
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("Motor6D") and desc.Part1 then
				table.insert(out, desc)
			end
		end
	end

	function self:CapturePoseKeyframe(timePos: number, motors: {Motor6D})
		local poses = {}
		for _, motor in ipairs(motors) do
			local ok, jointCFrame = pcall(function()
				local t = motor.Transform
				if t ~= CFrame.identity then
					return t
				end
				return motor.C0
			end)
			table.insert(poses, {
				Name = motor.Part1 and motor.Part1.Name or motor.Name,
				CFrame = (ok and typeof(jointCFrame) == "CFrame") and jointCFrame or CFrame.identity,
			})
		end
		return { Time = timePos, Poses = poses }
	end

	function self:SerializeGeneratedKeyframeSequence(rig: Instance, buffer: {string}, options)
		local motors: {Motor6D} = {}
		self:CollectMotor6Ds(rig, motors)
		if #motors == 0 then return end

		local duration = math.max(0, tonumber(options.KeyframeDuration) or 0)
		local fps = math.max(1, tonumber(options.KeyframeFPS) or 30)
		local frames = {}

		if duration <= 0 then
			table.insert(frames, self:CapturePoseKeyframe(0, motors))
		else
			local step = 1 / fps
			local elapsed = 0
			while elapsed <= duration and not self.Cancelled do
				table.insert(frames, self:CapturePoseKeyframe(elapsed, motors))
				elapsed += step
				if elapsed <= duration and not self.Cancelled then
					task.wait(step)
				end
			end
		end

		if #frames == 0 then return end

		self.KeyframeSequencesCount += 1
		local seqRef = self:GetReferent(rig) .. "_KFS"
		pushLine(buffer, self, string.format('<Item class="KeyframeSequence" referent="%s">', seqRef))
		pushLine(buffer, self, "<Properties>")
		pushLine(buffer, self, TypeHandlers.string("Name", rig.Name .. "_ExportedKeyframes"))
		pushLine(buffer, self, TypeHandlers.bool("Loop", true))
		pushLine(buffer, self, TypeHandlers.token("Priority", Enum.AnimationPriority.Action.Value))
		pushLine(buffer, self, "</Properties>")

		for idx, frame in ipairs(frames) do
			local kfRef = string.format("%s_KF%d", seqRef, idx)
			pushLine(buffer, self, string.format('<Item class="Keyframe" referent="%s">', kfRef))
			pushLine(buffer, self, "<Properties>")
			pushLine(buffer, self, TypeHandlers.string("Name", string.format("Keyframe_%.2f", frame.Time)))
			pushLine(buffer, self, TypeHandlers.float("Time", frame.Time))
			pushLine(buffer, self, "</Properties>")

			for pIdx, pose in ipairs(frame.Poses) do
				local poseRef = string.format("%s_P%d", kfRef, pIdx)
				pushLine(buffer, self, string.format('<Item class="Pose" referent="%s">', poseRef))
				pushLine(buffer, self, "<Properties>")
				pushLine(buffer, self, TypeHandlers.string("Name", pose.Name))
				pushLine(buffer, self, TypeHandlers.CoordinateFrame("CFrame", pose.CFrame))
				pushLine(buffer, self, TypeHandlers.float("Weight", 1))
				pushLine(buffer, self, TypeHandlers.token("EasingStyle", Enum.PoseEasingStyle.Linear.Value))
				pushLine(buffer, self, TypeHandlers.token("EasingDirection", Enum.PoseEasingDirection.InOut.Value))
				pushLine(buffer, self, "</Properties>")
				pushLine(buffer, self, "</Item>")
			end

			pushLine(buffer, self, "</Item>")
		end

		pushLine(buffer, self, "</Item>")
	end

	function self:ShouldSkip(instance: Instance, options): boolean
		if options.IgnorePlayers and Players:GetPlayerFromCharacter(instance) then
			return true
		end
		if options.Mode == "scripts" and not instance:IsA("LuaSourceContainer") then
			local hasScript = false
			for _, d in ipairs(instance:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					hasScript = true
					break
				end
			end
			if not hasScript then return true end
		elseif options.Mode == "map_ui" and instance:IsA("LuaSourceContainer") then
			return true
		end

		if not options.SaveScripts and instance:IsA("LuaSourceContainer") then
			return true
		end
		if instance:IsA("Terrain") and not options.SaveTerrain then
			return true
		end
		return false
	end

	function self:SerializeInstance(instance: Instance, buffer: {string}, options, onProgress)
		if self.Cancelled or self:ShouldSkip(instance, options) then
			return
		end

		local className = instance.ClassName
		local props = self.Reflection.GetProperties(className)

		if not props then
			for _, child in ipairs(instance:GetChildren()) do
				if self.Cancelled then break end
				self:SerializeInstance(child, buffer, options, onProgress)
			end
			return
		end

		local ref = self:GetReferent(instance)
		pushLine(buffer, self, string.format('<Item class="%s" referent="%s">', className, ref))
		pushLine(buffer, self, "<Properties>")

		for propName, propType in pairs(props) do
			if propName == "Source" and instance:IsA("LuaSourceContainer") then
				local ok, src = pcall(function() return (instance :: any).Source end)
				if (not ok or type(src) ~= "string" or src == "") and options.UseDecompiler then
					src = self:DecompileWithTimeout(instance, options.DecompileTimeout or 3)
				end
				if type(src) == "string" then
					pushLine(buffer, self, formatProtectedString("Source", src))
				end
			elseif propName == "SmoothGrid" and instance:IsA("Terrain") then
				local gridBin = buildSmoothGridBinary(instance :: Terrain, options.TerrainHalfExtent or 128)
				if gridBin then
					pushLine(buffer, self, TypeHandlers.BinaryString("SmoothGrid", gridBin))
				end
			else
				local ok, val = pcall(function()
					return (instance :: any)[propName]
				end)
				if not ok and typeof(gethiddenproperty) == "function" then
					ok, val = pcall(gethiddenproperty, instance, propName)
				end
				if ok and val ~= nil and TypeHandlers[propType] then
					pushLine(buffer, self, TypeHandlers[propType](propName, val))
				end
			end
		end

		if options.SaveTagsAndAttributes then
			local tagsOk, tags = pcall(function() return CollectionService:GetTags(instance) end)
			if tagsOk and type(tags) == "table" and #tags > 0 then
				pushLine(buffer, self, TypeHandlers.BinaryString("Tags", table.concat(tags, "\0")))
			end

			if typeof(gethiddenproperty) == "function" then
				local attrOk, attrBlob = pcall(gethiddenproperty, instance, "AttributesSerialize")
				if attrOk and type(attrBlob) == "string" and #attrBlob > 0 then
					pushLine(buffer, self, TypeHandlers.BinaryString("AttributesSerialize", attrBlob))
				end
			end
		end

		pushLine(buffer, self, "</Properties>")

		self.ProcessedCount += 1
		local yieldEvery = options.YieldEvery or 35
		if self.ProcessedCount % yieldEvery == 0 then
			if onProgress then
				onProgress(self.ProcessedCount, self.TotalEstimate, self.EstimatedBytes, instance.Name)
			end
			task.wait()
		end

		for _, child in ipairs(instance:GetChildren()) do
			if self.Cancelled then break end
			self:SerializeInstance(child, buffer, options, onProgress)
		end

		if options.ConvertAnimationsToKeyframes and (instance:FindFirstChildOfClass("Humanoid") or instance:FindFirstChildOfClass("AnimationController")) then
			self:SerializeGeneratedKeyframeSequence(instance, buffer, options)
		end

		pushLine(buffer, self, "</Item>")
	end

	function self:Run(options, onProgress): string
		self.ReferentCount = 0
		self.ReferentMap = {}
		self.ProcessedCount = 0
		self.EstimatedBytes = 0
		self.DecompiledCount = 0
		self.NilCount = 0
		self.KeyframeSequencesCount = 0
		self.Cancelled = false
		self.TotalEstimate = self:EstimateTotal(options)

		local buffer = {}
		pushLine(buffer, self, '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">')
		pushLine(buffer, self, '<External>null</External>')
		pushLine(buffer, self, '<External>nil</External>')

		for serviceName, enabled in pairs(options.Services) do
			if self.Cancelled then break end
			if enabled then
				local ok, service = pcall(function() return game:GetService(serviceName) end)
				if ok and service then
					self:SerializeInstance(service, buffer, options, onProgress)
				end
			end
		end

		if not self.Cancelled and options.IncludeLocalPlayerData and Players.LocalPlayer then
			local lp = Players.LocalPlayer
			local pGui = lp:FindFirstChildOfClass("PlayerGui")
			if pGui then
				for _, child in ipairs(pGui:GetChildren()) do
					if self.Cancelled then break end
					self:SerializeInstance(child, buffer, options, onProgress)
				end
			end
			local pScripts = lp:FindFirstChild("PlayerScripts")
			if pScripts then
				for _, child in ipairs(pScripts:GetChildren()) do
					if self.Cancelled then break end
					self:SerializeInstance(child, buffer, options, onProgress)
				end
			end
		end

		if not self.Cancelled and options.NilInstances and typeof(getnilinstances) == "function" then
			local nilOk, nilList = pcall(getnilinstances)
			if nilOk and type(nilList) == "table" then
				local nilFolderOpen = false
				for _, inst in ipairs(nilList) do
					if self.Cancelled then break end
					if typeof(inst) == "Instance" and inst.Parent == nil and not self:ShouldSkip(inst, options) then
						if not nilFolderOpen then
							pushLine(buffer, self, '<Item class="Folder" referent="RBX_NIL_ROOT"><Properties><string name="Name">NilInstances</string></Properties>')
							nilFolderOpen = true
						end
						self.NilCount += 1
						self:SerializeInstance(inst, buffer, options, onProgress)
					end
				end
				if nilFolderOpen then
					pushLine(buffer, self, "</Item>")
				end
			end
		end

		pushLine(buffer, self, "</roblox>")
		return table.concat(buffer, "\n")
	end

	return self
end

return Serializer
