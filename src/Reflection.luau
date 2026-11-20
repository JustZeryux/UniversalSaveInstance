-- Reflection.luau
local Reflection = {}

local Classes = {
	Instance = {
		Properties = {
			Name = "string",
			Archivable = "bool",
		}
	},

	-- Servicios y contenedores
	Workspace = { Inherits = "Model", Properties = { Gravity = "float" } },
	Lighting = {
		Inherits = "Instance",
		Properties = {
			Ambient = "Color3",
			OutdoorAmbient = "Color3",
			Brightness = "float",
			ClockTime = "float",
			GeographicLatitude = "float",
			GlobalShadows = "bool",
			EnvironmentDiffuseScale = "float",
			EnvironmentSpecularScale = "float",
		}
	},
	ReplicatedStorage = { Inherits = "Instance", Properties = {} },
	ReplicatedFirst = { Inherits = "Instance", Properties = {} },
	StarterGui = { Inherits = "Instance", Properties = {} },
	StarterPack = { Inherits = "Instance", Properties = {} },
	StarterPlayer = { Inherits = "Instance", Properties = {} },
	StarterPlayerScripts = { Inherits = "Instance", Properties = {} },
	StarterCharacterScripts = { Inherits = "Instance", Properties = {} },
	SoundService = { Inherits = "Instance", Properties = { AmbientReverb = "token", RespectFilteringEnabled = "bool" } },

	-- Partes y geometría
	BasePart = {
		Inherits = "Instance",
		Properties = {
			CFrame = "CoordinateFrame",
			Size = "Vector3",
			Color = "Color3uint8",
			Material = "token",
			Anchored = "bool",
			CanCollide = "bool",
			CanTouch = "bool",
			CanQuery = "bool",
			Transparency = "float",
			Reflectance = "float",
			CastShadow = "bool",
		}
	},
	Part = { Inherits = "BasePart", Properties = { Shape = "token" } },
	WedgePart = { Inherits = "BasePart", Properties = {} },
	CornerWedgePart = { Inherits = "BasePart", Properties = {} },
	TrussPart = { Inherits = "BasePart", Properties = { Style = "token" } },
	Seat = { Inherits = "Part", Properties = { Disabled = "bool" } },
	VehicleSeat = { Inherits = "Part", Properties = { Disabled = "bool", MaxSpeed = "float", SteerFloat = "float", ThrottleFloat = "float" } },
	SpawnLocation = { Inherits = "Part", Properties = { Duration = "int", Neutral = "bool", Enabled = "bool" } },
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
	Tool = {
		Inherits = "Instance",
		Properties = {
			Grip = "CoordinateFrame",
			CanBeDropped = "bool",
			RequiresHandle = "bool",
			ToolTip = "string",
			Enabled = "bool",
		}
	},

	-- Scripts
	BaseScript = {
		Inherits = "Instance",
		Properties = {
			Enabled = "bool",
			Source = "ProtectedString",
		}
	},
	Script = { Inherits = "BaseScript", Properties = {} },
	LocalScript = { Inherits = "BaseScript", Properties = {} },
	ModuleScript = {
		Inherits = "Instance",
		Properties = {
			Source = "ProtectedString",
		}
	},

	-- Efectos visuales, iluminación y audio
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
	ParticleEmitter = {
		Inherits = "Instance",
		Properties = {
			Texture = "Content",
			Color = "ColorSequence",
			Size = "NumberSequence",
			Transparency = "NumberSequence",
			Lifetime = "NumberRange",
			Rate = "float",
			Speed = "NumberRange",
			Rotation = "NumberRange",
			RotSpeed = "NumberRange",
			LightEmission = "float",
			LightInfluence = "float",
			Drag = "float",
			Acceleration = "Vector3",
			Enabled = "bool",
			LockedToPart = "bool",
		}
	},
	Beam = {
		Inherits = "Instance",
		Properties = {
			Texture = "Content",
			Color = "ColorSequence",
			Width0 = "float",
			Width1 = "float",
			CurveSize0 = "float",
			CurveSize1 = "float",
			Segments = "int",
			FaceCamera = "bool",
			LightEmission = "float",
			Transparency = "NumberSequence",
			Attachment0 = "Ref",
			Attachment1 = "Ref",
			Enabled = "bool",
		}
	},
	Trail = {
		Inherits = "Instance",
		Properties = {
			Texture = "Content",
			Color = "ColorSequence",
			Lifetime = "float",
			MinLength = "float",
			MaxLength = "float",
			WidthScale = "float",
			Transparency = "NumberSequence",
			Attachment0 = "Ref",
			Attachment1 = "Ref",
			Enabled = "bool",
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
	SpotLight = {
		Inherits = "Instance",
		Properties = {
			Color = "Color3",
			Brightness = "float",
			Range = "float",
			Angle = "float",
			Face = "token",
			Enabled = "bool",
			Shadows = "bool",
		}
	},
	SurfaceLight = {
		Inherits = "Instance",
		Properties = {
			Color = "Color3",
			Brightness = "float",
			Range = "float",
			Angle = "float",
			Face = "token",
			Enabled = "bool",
			Shadows = "bool",
		}
	},
	Atmosphere = {
		Inherits = "Instance",
		Properties = {
			Density = "float",
			Offset = "float",
			Color = "Color3",
			Decay = "Color3",
			Glare = "float",
			Haze = "float",
		}
	},
	Sky = {
		Inherits = "Instance",
		Properties = {
			SkyboxBk = "Content",
			SkyboxDn = "Content",
			SkyboxFt = "Content",
			SkyboxLf = "Content",
			SkyboxRt = "Content",
			SkyboxUp = "Content",
			SunAngularSize = "float",
			MoonAngularSize = "float",
			CelestialBodiesShown = "bool",
		}
	},
	BloomEffect = { Inherits = "Instance", Properties = { Enabled = "bool", Intensity = "float", Size = "float", Threshold = "float" } },
	ColorCorrectionEffect = { Inherits = "Instance", Properties = { Enabled = "bool", TintColor = "Color3", Brightness = "float", Contrast = "float", Saturation = "float" } },
	SunRaysEffect = { Inherits = "Instance", Properties = { Enabled = "bool", Intensity = "float", Spread = "float" } },
	BlurEffect = { Inherits = "Instance", Properties = { Enabled = "bool", Size = "float" } },
	Sound = {
		Inherits = "Instance",
		Properties = {
			SoundId = "Content",
			Volume = "float",
			PlaybackSpeed = "float",
			Looped = "bool",
			RollOffMinDistance = "float",
			RollOffMaxDistance = "float",
		}
	},

	-- Interacción y conexiones
	Attachment = { Inherits = "Instance", Properties = { CFrame = "CoordinateFrame", Visible = "bool" } },
	WeldConstraint = { Inherits = "Instance", Properties = { Part0 = "Ref", Part1 = "Ref", Enabled = "bool" } },
	Motor6D = { Inherits = "Instance", Properties = { Part0 = "Ref", Part1 = "Ref", C0 = "CoordinateFrame", C1 = "CoordinateFrame", Enabled = "bool" } },
	ProximityPrompt = {
		Inherits = "Instance",
		Properties = {
			ActionText = "string",
			ObjectText = "string",
			KeyboardKeyCode = "token",
			HoldDuration = "float",
			MaxActivationDistance = "float",
			RequiresLineOfSight = "bool",
			Enabled = "bool",
		}
	},
	ClickDetector = { Inherits = "Instance", Properties = { MaxActivationDistance = "float", CursorIcon = "Content" } },
	RemoteEvent = { Inherits = "Instance", Properties = {} },
	RemoteFunction = { Inherits = "Instance", Properties = {} },
	BindableEvent = { Inherits = "Instance", Properties = {} },
	BindableFunction = { Inherits = "Instance", Properties = {} },

	-- ValueObjects
	StringValue = { Inherits = "Instance", Properties = { Value = "string" } },
	IntValue = { Inherits = "Instance", Properties = { Value = "int64" } },
	NumberValue = { Inherits = "Instance", Properties = { Value = "double" } },
	BoolValue = { Inherits = "Instance", Properties = { Value = "bool" } },
	ObjectValue = { Inherits = "Instance", Properties = { Value = "Ref" } },
	Color3Value = { Inherits = "Instance", Properties = { Value = "Color3" } },
	Vector3Value = { Inherits = "Instance", Properties = { Value = "Vector3" } },
	CFrameValue = { Inherits = "Instance", Properties = { Value = "CoordinateFrame" } },

	-- UI (GuiBase2d / GuiObject / UI modifiers)
	ScreenGui = {
		Inherits = "Instance",
		Properties = {
			Enabled = "bool",
			ResetOnSpawn = "bool",
			DisplayOrder = "int",
			IgnoreGuiInset = "bool",
		}
	},
	BillboardGui = {
		Inherits = "Instance",
		Properties = {
			Enabled = "bool",
			Size = "UDim2",
			StudsOffset = "Vector3",
			AlwaysOnTop = "bool",
			MaxDistance = "float",
		}
	},
	SurfaceGui = {
		Inherits = "Instance",
		Properties = {
			Enabled = "bool",
			Face = "token",
			AlwaysOnTop = "bool",
		}
	},
	GuiObject = {
		Inherits = "Instance",
		Properties = {
			Position = "UDim2",
			Size = "UDim2",
			AnchorPoint = "Vector2",
			BackgroundColor3 = "Color3",
			BackgroundTransparency = "float",
			BorderSizePixel = "int",
			Visible = "bool",
			ZIndex = "int",
			LayoutOrder = "int",
		}
	},
	Frame = { Inherits = "GuiObject", Properties = {} },
	ScrollingFrame = {
		Inherits = "GuiObject",
		Properties = {
			CanvasSize = "UDim2",
			CanvasPosition = "Vector2",
			ScrollBarThickness = "int",
			ScrollingDirection = "token",
		}
	},
	TextLabel = {
		Inherits = "GuiObject",
		Properties = {
			Text = "string",
			TextColor3 = "Color3",
			TextSize = "float",
			TextScaled = "bool",
			RichText = "bool",
			Font = "token",
		}
	},
	TextButton = {
		Inherits = "TextLabel",
		Properties = {
			AutoButtonColor = "bool",
		}
	},
	TextBox = {
		Inherits = "TextLabel",
		Properties = {
			PlaceholderText = "string",
			ClearTextOnFocus = "bool",
		}
	},
	ImageLabel = {
		Inherits = "GuiObject",
		Properties = {
			Image = "Content",
			ImageColor3 = "Color3",
			ImageTransparency = "float",
			ScaleType = "token",
		}
	},
	ImageButton = {
		Inherits = "ImageLabel",
		Properties = {
			AutoButtonColor = "bool",
		}
	},
	UICorner = { Inherits = "Instance", Properties = { CornerRadius = "UDim" } },
	UIStroke = {
		Inherits = "Instance",
		Properties = {
			Color = "Color3",
			Thickness = "float",
			Transparency = "float",
			ApplyStrokeMode = "token",
		}
	},
	UIGradient = {
		Inherits = "Instance",
		Properties = {
			Color = "ColorSequence",
			Transparency = "NumberSequence",
			Rotation = "float",
			Offset = "Vector2",
			Enabled = "bool",
		}
	},
	UIPadding = {
		Inherits = "Instance",
		Properties = {
			PaddingTop = "UDim",
			PaddingBottom = "UDim",
			PaddingLeft = "UDim",
			PaddingRight = "UDim",
		}
	},
	UIListLayout = {
		Inherits = "Instance",
		Properties = {
			Padding = "UDim",
			FillDirection = "token",
			HorizontalAlignment = "token",
			VerticalAlignment = "token",
			SortOrder = "token",
		}
	},
	UIGridLayout = {
		Inherits = "Instance",
		Properties = {
			CellSize = "UDim2",
			CellPadding = "UDim2",
			FillDirection = "token",
			SortOrder = "token",
		}
	},
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
			if props[k] == nil then
				props[k] = v
			end
		end
		current = Classes[current].Inherits
	end

	if next(props) == nil then
		return nil
	end

	ResolvedCache[className] = props
	return props
end

return Reflection
