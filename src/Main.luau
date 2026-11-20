-- Main.luau
local Reflection = require(script.Reflection)
local Serializer = require(script.Serializer)
local PanelUI = require(script.PanelUI)

local engine = Serializer.New(Reflection)

local function humanSize(bytes: number): string
	if bytes < 1024 then
		return string.format("%d B", bytes)
	elseif bytes < 1024 * 1024 then
		return string.format("%.1f KB", bytes / 1024)
	else
		return string.format("%.2f MB", bytes / (1024 * 1024))
	end
end

PanelUI.Create(
	function(options, updateUI)
		local startTime = os.clock()
		updateUI("Calculando instancias...", 0, 1, 0, "workspace/")

		local fileName = string.format("ZeryuxDump_%d_%d.rbxlx", game.PlaceId, os.time())
		local ok, resultInfo, finalBytes = engine:RunToFile(fileName, options, function(count, total, estBytes, currentName)
			updateUI("Leyendo: " .. tostring(currentName), count, total, estBytes, "workspace/")
		end)

		local elapsed = os.clock() - startTime
		if engine.Cancelled then
			updateUI(string.format("Cancelado (%.1fs)", elapsed), engine.ProcessedCount, engine.TotalEstimate, engine.EstimatedBytes, "workspace/")
			return
		end

		if ok then
			updateUI(
				string.format("Listo (%s | %.1fs | %d decomp)", humanSize(finalBytes), elapsed, engine.DecompiledCount),
				engine.TotalEstimate,
				engine.TotalEstimate,
				finalBytes,
				"workspace/" .. tostring(resultInfo)
			)
		else
			updateUI(tostring(resultInfo), engine.ProcessedCount, engine.TotalEstimate, finalBytes, "error")
		end
	end,
	function()
		engine.Cancelled = true
	end
)
