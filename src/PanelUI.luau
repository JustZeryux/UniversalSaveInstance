-- PanelUI.luau
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local PanelUI = {}

function PanelUI.Create(onExportCallback, onCancelCallback)
	local targetParent = pcall(function() return CoreGui.Name end) and CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = targetParent:FindFirstChild("ZeryuxSaveInstanceUI")
	if existing then existing:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZeryuxSaveInstanceUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = targetParent

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.fromOffset(370, 500)
	main.Position = UDim2.new(0.5, -185, 0.5, -250)
	main.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = screenGui

	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 230, 255)
	stroke.Thickness = 1.5
	stroke.Parent = main

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 38)
	header.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
	header.BorderSizePixel = 0
	header.Parent = main
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Text = "ZERYUX DUMP // PRO CLIENT"
	title.TextColor3 = Color3.fromRGB(0, 230, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -33, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 70)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 13
	closeBtn.Parent = header
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
	closeBtn.MouseButton1Click:Connect(function()
		if onCancelCallback then onCancelCallback() end
		screenGui:Destroy()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -135)
	scroll.Position = UDim2.fromOffset(12, 46)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 230, 255)
	scroll.CanvasSize = UDim2.fromOffset(0, 600)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = main

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = scroll

	local modes = { "full", "scripts", "map_ui" }
	local modeIndex = 1

	local state = {
		Mode = "full",
		Services = {
			Workspace = true,
			ReplicatedStorage = true,
			ReplicatedFirst = true,
			Lighting = true,
			StarterGui = true,
			StarterPack = true,
			StarterPlayer = true,
			SoundService = true,
		},
		SaveScripts = true,
		UseDecompiler = true,
		DecompileTimeout = 4,
		IgnorePlayers = true,
		SaveTerrain = true,
		TerrainHalfExtent = 256,
		ConvertAnimationsToKeyframes = true,
		KeyframeDuration = 0,
		KeyframeFPS = 30,
		NilInstances = true,
		IncludeLocalPlayerData = true,
		SaveTagsAndAttributes = true,
	}

	local modeBtn = Instance.new("TextButton")
	modeBtn.Size = UDim2.new(1, -6, 0, 30)
	modeBtn.BackgroundColor3 = Color3.fromRGB(32, 38, 56)
	modeBtn.Text = "Modo: FULL (Todo lo replicado)"
	modeBtn.TextColor3 = Color3.fromRGB(0, 230, 255)
	modeBtn.Font = Enum.Font.GothamBold
	modeBtn.TextSize = 12
	modeBtn.Parent = scroll
	Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)
	modeBtn.MouseButton1Click:Connect(function()
		modeIndex = (modeIndex % #modes) + 1
		state.Mode = modes[modeIndex]
		if state.Mode == "full" then
			modeBtn.Text = "Modo: FULL (Todo lo replicado)"
		elseif state.Mode == "scripts" then
			modeBtn.Text = "Modo: SCRIPTS (Solo scripts y rutas)"
		else
			modeBtn.Text = "Modo: MAP_UI (Sin scripts)"
		end
	end)

	local function addSectionTitle(text)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 20)
		lbl.BackgroundTransparency = 1
		lbl.Text = text
		lbl.TextColor3 = Color3.fromRGB(160, 175, 200)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = scroll
	end

	local function addToggle(labelText, defaultVal, onChange)
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -6, 0, 27)
		row.BackgroundColor3 = Color3.fromRGB(26, 30, 44)
		row.Text = ""
		row.AutoButtonColor = false
		row.Parent = scroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -45, 1, 0)
		lbl.Position = UDim2.fromOffset(10, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = labelText
		lbl.TextColor3 = Color3.fromRGB(235, 240, 250)
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = row

		local indicator = Instance.new("Frame")
		indicator.Size = UDim2.fromOffset(18, 18)
		indicator.Position = UDim2.new(1, -26, 0.5, -9)
		indicator.BackgroundColor3 = defaultVal and Color3.fromRGB(0, 230, 255) or Color3.fromRGB(55, 60, 80)
		indicator.Parent = row
		Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 4)

		local active = defaultVal
		row.MouseButton1Click:Connect(function()
			active = not active
			indicator.BackgroundColor3 = active and Color3.fromRGB(0, 230, 255) or Color3.fromRGB(55, 60, 80)
			onChange(active)
		end)
	end

	addSectionTitle("FILTROS Y EXTRACCION")
	addToggle("Guardar Scripts (Local / Module)", state.SaveScripts, function(v) state.SaveScripts = v end)
	addToggle("Usar Decompiler (con timeout)", state.UseDecompiler, function(v) state.UseDecompiler = v end)
	addToggle("Ignorar Personajes de Jugadores", state.IgnorePlayers, function(v) state.IgnorePlayers = v end)
	addToggle("Incluir Terrain (SmoothGrid)", state.SaveTerrain, function(v) state.SaveTerrain = v end)
	addToggle("Animaciones -> KeyframeSequence", state.ConvertAnimationsToKeyframes, function(v) state.ConvertAnimationsToKeyframes = v end)
	addToggle("Muestrear 2s de Animacion (30 FPS)", false, function(v) state.KeyframeDuration = v and 2 or 0 end)
	addToggle("Capturar NilInstances", state.NilInstances, function(v) state.NilInstances = v end)
	addToggle("Incluir PlayerGui y PlayerScripts", state.IncludeLocalPlayerData, function(v) state.IncludeLocalPlayerData = v end)
	addToggle("Guardar Tags y Atributos", state.SaveTagsAndAttributes, function(v) state.SaveTagsAndAttributes = v end)

	addSectionTitle("SERVICIOS A EXPORTAR")
	for serviceName, defaultVal in pairs(state.Services) do
		addToggle(serviceName, defaultVal, function(v)
			state.Services[serviceName] = v
		end)
	end

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 24)
	statusLabel.Position = UDim2.new(0, 12, 1, -76)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Estado: Listo para exportar"
	statusLabel.TextColor3 = Color3.fromRGB(140, 220, 180)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 11
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = main

	local exportBtn = Instance.new("TextButton")
	exportBtn.Size = UDim2.new(0.68, -15, 0, 38)
	exportBtn.Position = UDim2.new(0, 12, 1, -46)
	exportBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 230)
	exportBtn.Text = "EXPORTAR .RBXLX"
	exportBtn.TextColor3 = Color3.fromRGB(10, 14, 20)
	exportBtn.Font = Enum.Font.GothamBold
	exportBtn.TextSize = 13
	exportBtn.Parent = main
	Instance.new("UICorner", exportBtn).CornerRadius = UDim.new(0, 8)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.32, -12, 0, 38)
	cancelBtn.Position = UDim2.new(0.68, 3, 1, -46)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(70, 35, 45)
	cancelBtn.Text = "CANCELAR"
	cancelBtn.TextColor3 = Color3.fromRGB(255, 130, 145)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 12
	cancelBtn.Parent = main
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

	local isRunning = false

	cancelBtn.MouseButton1Click:Connect(function()
		if isRunning and onCancelCallback then
			onCancelCallback()
			statusLabel.Text = "Cancelando serializacion..."
		end
	end)

	exportBtn.MouseButton1Click:Connect(function()
		if isRunning then return end
		isRunning = true
		exportBtn.Text = "EXPORTANDO..."
		exportBtn.BackgroundColor3 = Color3.fromRGB(90, 100, 120)

		task.spawn(function()
			onExportCallback(state, function(msg)
				statusLabel.Text = msg
			end)
			isRunning = false
			exportBtn.Text = "EXPORTAR .RBXLX"
			exportBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 230)
		end)
	end)
end

return PanelUI
