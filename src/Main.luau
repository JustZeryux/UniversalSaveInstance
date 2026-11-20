-- Main.luau
local Reflection = require(script.Reflection)
local Serializer = require(script.Serializer)
local PanelUI = require(script.PanelUI)

local engine = Serializer.New(Reflection)

PanelUI.Create(function(options, updateStatus)
	local startTime = os.clock()
	updateStatus("Iniciando recorrido del DataModel...")

	local xmlContent = engine:Run(options, function(count, currentName)
		updateStatus(string.format("Procesando: %d instancias (%s)", count, currentName))
	end)

	local elapsed = os.clock() - startTime
	local fileName = string.format("Export_%d_%d.rbxlx", game.PlaceId, os.time())

	if typeof(writefile) == "function" then
		writefile(fileName, xmlContent)
		updateStatus(string.format("Guardado: %s (%.2fs | %d inst.)", fileName, elapsed, engine.ProcessedCount))
	else
		-- Respaldo para pruebas dentro de Roblox Studio
		warn("[CustomSaveInstance] XML generado (" .. #xmlContent .. " bytes) en " .. string.format("%.2fs", elapsed))
		updateStatus(string.format("Generado en memoria: %d bytes (%.2fs)", #xmlContent, elapsed))
	end
end)
