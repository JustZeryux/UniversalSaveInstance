-- Serializer.luau
local Players = game:GetService("Players")

local Serializer = {}

local function escapeXml(str: string): string
	return str:gsub("&", "&amp;")
		:gsub("<", "&lt;")
		:gsub(">", "&gt;")
		:gsub('"', "&quot;")
		:gsub("'", "&apos;")
end

function Serializer.New(ReflectionModule)
	local self = {
		Reflection = ReflectionModule,
		ReferentCount = 0,
		ReferentMap = {},
		ProcessedCount = 0,
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
		ProtectedString = function(name, val)
			return string.format('<ProtectedString name="%s">%s</ProtectedString>', name, escapeXml(tostring(val)))
		end,
		Content = function(name, val)
			if val == "" then
				return string.format('<Content name="%s"><null></null></Content>', name)
			end
			return string.format('<Content name="%s"><url>%s</url></Content>', name, escapeXml(tostring(val)))
		end,
		bool = function(name, val)
			return string.format('<bool name="%s">%s</bool>', name, val and "true" or "false")
		end,
		float = function(name, val)
			return string.format('<float name="%s">%s</float>', name, tostring(val))
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
		Vector3 = function(name, val)
			return string.format('<Vector3 name="%s"><X>%s</X><Y>%s</Y><Z>%s</Z></Vector3>', name, val.X, val.Y, val.Z)
		end,
		UDim2 = function(name, val)
			return string.format(
				'<UDim2 name="%s"><XS>%s</XS><XO>%d</XO><YS>%s</YS><YO>%d</YO></UDim2>',
				name, val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset
			)
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

	function self:ShouldSkip(instance: Instance, options): boolean
		-- Ignorar personajes de jugadores si está activado
		if options.IgnorePlayers and Players:GetPlayerFromCharacter(instance) then
			return true
		end
		-- Ignorar scripts si está desactivado
		if not options.SaveScripts and instance:IsA("LuaSourceContainer") then
			return true
		end
		-- Ignorar terrenos si no está soportado/activado
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

		-- Si la clase no está registrada pero tiene hijos (ej. un contenedor desconocido), pasamos a sus hijos
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
				-- Intentar leer Source (Studio) o usar descompilador del entorno si existe
				local ok, src = pcall(function() return instance.Source end)
				if (not ok or src == "") and options.UseDecompiler and typeof(decompile) == "function" then
					local dOk, dSrc = pcall(decompile, instance)
					src = dOk and dSrc or "-- [No se pudo extraer el codigo]"
				end
				if src then
					table.insert(buffer, TypeHandlers.ProtectedString("Source", src))
				end
			else
				local ok, val = pcall(function()
					return (instance :: any)[propName]
				end)
				if ok and val ~= nil and TypeHandlers[propType] then
					table.insert(buffer, TypeHandlers[propType](propName, val))
				end
			end
		end

		table.insert(buffer, "</Properties>")

		self.ProcessedCount += 1
		if self.ProcessedCount % 150 == 0 then
			if onProgress then
				onProgress(self.ProcessedCount, instance.Name)
			end
			task.wait() -- Evita congelar el hilo principal en mapas grandes
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

		table.insert(buffer, "</roblox>")
		return table.concat(buffer, "\n")
	end

	return self
end

return Serializer
