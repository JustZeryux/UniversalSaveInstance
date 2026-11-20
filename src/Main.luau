-- Main.luau
local Reflection = require(script.Reflection)
local Serializer = require(script.Serializer)
local PanelUI = require(script.PanelUI)

local engine = Serializer.New(Reflection)

PanelUI.Create(function(options, updateStatus)
	local startTime = os.clock()
	updateStatus("Iniciando recorrido del DataModel...")

	local xmlContent = engine:Run(options, function(count, currentName)
		updateStatus(string.format("Procesando: %d inst. (%s)", count, currentName))
	end)

	local elapsed = os.clock() - startTime
	local fileName = string.format("Export_%d_%d.rbxlx", game.PlaceId, os.time())

	if typeof(writefile) == "function" then
		writefile(fileName, xmlContent)
		updateStatus(string.format(
			"Listo: %s (%.2fs | %d inst | %d decomp | %d nil)",
			fileName, elapsed, engine.ProcessedCount, engine.DecompiledCount, engine.NilCount
		))
	else
		warn(string.format(
			"[CustomSaveInstance] %d bytes | %.2fs | %d inst | %d decomp | %d nil",
			#xmlContent, elapsed, engine.ProcessedCount, engine.DecompiledCount, engine.NilCount
		))
		updateStatus(string.format(
			"Memoria: %d bytes (%.2fs | %d inst | %d decomp)",
			#xmlContent, elapsed, engine.ProcessedCount, engine.DecompiledCount
		))
	end
end)
