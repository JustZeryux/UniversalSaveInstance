-- Reflection.luau
local Reflection = {}

local Classes = {
	Instance = {
		Properties = {
			Name = "string",
			Archivable = "bool",
		}
	},
	BasePart = {
		Inherits = "Instance",
		Properties = {
			CFrame = "CoordinateFrame",
			Size = "Vector3",
			Color = "Color3uint8",
			Material = "token",
			Anchored = "bool",
			CanCollide = "bool",
			Transparency = "float",
			Reflectance = "float",
			CastShadow = "bool",
		}
	},
	Part = {
		Inherits = "BasePart",
		Properties = {
			Shape = "token",
		}
	},
	WedgePart = { Inherits = "BasePart", Properties = {} },
	CornerWedgePart = { Inherits = "BasePart", Properties = {} },
	MeshPart = {
		Inherits = "BasePart",
		Properties = {
			MeshId = "Content",
			TextureID = "Content",
			DoubleSided = "bool",
		}
	},
	Model = {
		Inherits = "Instance",
		Properties = {
			PrimaryPart = "Ref",
			WorldPivot = "CoordinateFrame",
		}
	},
	Folder = { Inherits = "Instance", Properties = {} },
	Workspace = {
		Inherits = "Model",
		Properties = {
			Gravity = "float",
		}
	},
	Script = {
		Inherits = "Instance",
		Properties = {
			Disabled = "bool",
			Source = "ProtectedString",
		}
	},
	LocalScript = {
		Inherits = "Script",
		Properties = {}
	},
	ModuleScript = {
		Inherits = "Instance",
		Properties = {
			Source = "ProtectedString",
		}
	},
	SpecialMesh = {
		Inherits = "Instance",
		Properties = {
			MeshId = "Content",
			TextureId = "Content",
			MeshType = "token",
			Scale = "Vector3",
			Offset = "Vector3",
		}
	},
	Decal = {
		Inherits = "Instance",
		Properties = {
			Texture = "Content",
			Face = "token",
			Transparency = "float",
			Color3 = "Color3",
		}
	},
	Texture = {
		Inherits = "Decal",
		Properties = {
			StudsPerTileU = "float",
			StudsPerTileV = "float",
		}
	},
	PointLight = {
		Inherits = "Instance",
		Properties = {
			Color = "Color3",
			Brightness = "float",
			Range = "float",
			Enabled = "bool",
			Shadows = "bool",
		}
	},
	Sound = {
		Inherits = "Instance",
		Properties = {
			SoundId = "Content",
			Volume = "float",
			PlaybackSpeed = "float",
			Looped = "bool",
		}
	},
	-- Contenedores de UI y Servicios
	ScreenGui = { Inherits = "Instance", Properties = { Enabled = "bool", ResetOnSpawn = "bool" } },
	Frame = { Inherits = "Instance", Properties = { Position = "UDim2", Size = "UDim2", BackgroundColor3 = "Color3", BackgroundTransparency = "float" } },
	TextLabel = { Inherits = "Frame", Properties = { Text = "string", TextColor3 = "Color3", TextScaled = "bool" } },
	Lighting = { Inherits = "Instance", Properties = { Brightness = "float", ClockTime = "float", Ambient = "Color3" } },
	ReplicatedStorage = { Inherits = "Instance", Properties = {} },
	StarterGui = { Inherits = "Instance", Properties = {} },
	StarterPack = { Inherits = "Instance", Properties = {} },
	StarterPlayer = { Inherits = "Instance", Properties = {} },
	StarterPlayerScripts = { Inherits = "Instance", Properties = {} },
	StarterCharacterScripts = { Inherits = "Instance", Properties = {} },
}

local ResolvedCache = {}

function Reflection.GetProperties(className: string)
	if ResolvedCache[className] then
		return ResolvedCache[className]
	end

	local props = {}
	local current = className
	while current and Classes[current] do
		for k, v in pairs(Classes[current].Properties) do
			if not props[k] then
				props[k] = v
			end
		end
		current = Classes[current].Inherits
	end

	if next(props) == nil then
		return nil -- Clase no registrada
	end

	ResolvedCache[className] = props
	return props
end

return Reflection
