-- Serializer.luau
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Serializer = {}

-- Codificador Base64 en Luau puro para BinaryString en XML
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
	-- Evita romper etiquetas CDATA si el código contiene "]]>"
	local safeCdata = string.gsub(src, "]]>", "]]]]><![CDATA[>")
	return string.format('<ProtectedString name="%s"><![CDATA[%s]]></ProtectedString>', name, safeCdata)
end

function Serializer.New(ReflectionModule)
	local self = {
		Reflection = ReflectionModule,
		ReferentCount = 0,
		ReferentMap = {},
		ProcessedCount = 0,
		DecompiledCount = 0,
		NilCount = 0,
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
				result = string.format("-- [Timeout %.1fs excedido al descompilar %s]", timeoutSec, scriptInstance.Name)
			end
		end)

		while not finished do
			task.wait(0.05)
		end

		return result
	end

	function self:ShouldSkip(instance: Instance, options): boolean
		if options.IgnorePlayers and Players:GetPlayerFromCharacter(instance) then
			return true
		end
		if not options.SaveScripts and instance:IsA("LuaSourceContainer") then
			return true
		end
		if instance:IsA("Terrain") then
			return true
		end
		return false
	end

	function self:SerializeInstance(instance: Instance, buffer: {string}, options, onProgress)
		if self:ShouldSkip(instance, options) then
			return
		end

		local className = instance.ClassName
		local props = self.Reflection.GetProperties(className)

		if not props then
			for _, child in ipairs(instance:GetChildren()) do
				self:SerializeInstance(child, buffer, options, onProgress)
			end
			return
		end

		local ref = self:GetReferent(instance)
		table.insert(buffer, string.format('<Item class="%s" referent="%s">', className, ref))
		table.insert(buffer, "<Properties>")

		for propName, propType in pairs(props) do
			if propName == "Source" and instance:IsA("LuaSourceContainer") then
				local ok, src = pcall(function() return (instance :: any).Source end)
				if (not ok or type(src) ~= "string" or src == "") and options.UseDecompiler then
					src = self:DecompileWithTimeout(instance, options.DecompileTimeout or 4)
				end
				if type(src) == "string" then
					table.insert(buffer, formatProtectedString("Source", src))
				end
			else
				local ok, val = pcall(function()
					return (instance :: any)[propName]
				end)
				if not ok and typeof(gethiddenproperty) == "function" then
					ok, val = pcall(gethiddenproperty, instance, propName)
				end
				if ok and val ~= nil and TypeHandlers[propType] then
					table.insert(buffer, TypeHandlers[propType](propName, val))
				end
			end
		end

		-- Tags de CollectionService si está activado
		if options.SaveTagsAndAttributes then
			local tagsOk, tags = pcall(function() return CollectionService:GetTags(instance) end)
			if tagsOk and type(tags) == "table" and #tags > 0 then
				local rawTags = table.concat(tags, "\0")
				table.insert(buffer, TypeHandlers.BinaryString("Tags", rawTags))
			end

			-- Atributos ocultos si el entorno expone gethiddenproperty
			if typeof(gethiddenproperty) == "function" then
				local attrOk, attrBlob = pcall(gethiddenproperty, instance, "AttributesSerialize")
				if attrOk and type(attrBlob) == "string" and #attrBlob > 0 then
					table.insert(buffer, TypeHandlers.BinaryString("AttributesSerialize", attrBlob))
				end
			end
		end

		table.insert(buffer, "</Properties>")

		self.ProcessedCount += 1
		if self.ProcessedCount % 150 == 0 then
			if onProgress then
				onProgress(self.ProcessedCount, instance.Name)
			end
			task.wait()
		end

		for _, child in ipairs(instance:GetChildren()) do
			self:SerializeInstance(child, buffer, options, onProgress)
		end

		table.insert(buffer, "</Item>")
	end

	function self:Run(options, onProgress): string
		self.ReferentCount = 0
		self.ReferentMap = {}
		self.ProcessedCount = 0
		self.DecompiledCount = 0
		self.NilCount = 0

		local buffer = {
			'<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
			'<External>null</External>',
			'<External>nil</External>',
		}

		for serviceName, enabled in pairs(options.Services) do
			if enabled then
				local ok, service = pcall(function()
					return game:GetService(serviceName)
				end)
				if ok and service then
					self:SerializeInstance(service, buffer, options, onProgress)
				end
			end
		end

		-- Capturar PlayerGui y PlayerScripts del jugador local dentro de StarterGui / StarterPlayerScripts si se pide
		if options.IncludeLocalPlayerData and Players.LocalPlayer then
			local lp = Players.LocalPlayer
			local pGui = lp:FindFirstChildOfClass("PlayerGui")
			if pGui then
				for _, child in ipairs(pGui:GetChildren()) do
					self:SerializeInstance(child, buffer, options, onProgress)
				end
			end
			local pScripts = lp:FindFirstChild("PlayerScripts")
			if pScripts then
				for _, child in ipairs(pScripts:GetChildren()) do
					self:SerializeInstance(child, buffer, options, onProgress)
				end
			end
		end

		-- Capturar instancias en nil si el entorno ofrece getnilinstances()
		if options.NilInstances and typeof(getnilinstances) == "function" then
			local nilOk, nilList = pcall(getnilinstances)
			if nilOk and type(nilList) == "table" then
				local nilFolderOpen = false
				for _, inst in ipairs(nilList) do
					if typeof(inst) == "Instance" and inst.Parent == nil and not self:ShouldSkip(inst, options) then
						if not nilFolderOpen then
							table.insert(buffer, '<Item class="Folder" referent="RBX_NIL_ROOT"><Properties><string name="Name">NilInstances</string></Properties>')
							nilFolderOpen = true
						end
						self.NilCount += 1
						self:SerializeInstance(inst, buffer, options, onProgress)
					end
				end
				if nilFolderOpen then
					table.insert(buffer, "</Item>")
				end
			end
		end

		table.insert(buffer, "</roblox>")
		return table.concat(buffer, "\n")
	end

	return self
end

return Serializer
