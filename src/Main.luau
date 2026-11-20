-- Main.luau
local Reflection = require(script.Reflection)
local Serializer = require(script.Serializer)
local PanelUI = require(script.PanelUI)

local engine = Serializer.New(Reflection)

PanelUI.Create(
	function(options, updateStatus)
		local startTime = os.clock()
		updateStatus("Iniciando recorrido del DataModel...")

		local xmlContent = engine:Run(options, function(count, currentName)
			updateStatus(string.format("Instancias: %d | Actual: %s", count, currentName))
		end)

		local elapsed = os.clock() - startTime
		if engine.Cancelled then
			updateStatus(string.format("Cancelado tras %.2fs (%d inst).", elapsed, engine.ProcessedCount))
			return
		end

		local fileName = string.format("Export_%d_%d.rbxlx", game.PlaceId, os.time())

		if typeof(writefile) == "function" then
			writefile(fileName, xmlContent)
			updateStatus(string.format(
				"OK: %s | %.2fs | %d inst | %d decomp | %d anim | %d nil",
				fileName, elapsed, engine.ProcessedCount, engine.DecompiledCount, engine.KeyframeSequencesCount, engine.NilCount
			))
		else
			warn(string.format(
				"[ZeryuxDump] %d bytes | %.2fs | %d inst | %d decomp | %d anim | %d nil",
				#xmlContent, elapsed, engine.ProcessedCount, engine.DecompiledCount, engine.KeyframeSequencesCount, engine.NilCount
			))
			updateStatus(string.format(
				"Memoria: %d bytes (%.2fs | %d inst | %d decomp | %d anim)",
				#xmlContent, elapsed, engine.ProcessedCount, engine.DecompiledCount, engine.KeyframeSequencesCount
			))
		end
	end,
	function()
		engine.Cancelled = true
	end
)
