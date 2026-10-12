-- Versão autossuficiente: roda no executor OU como LocalScript
-- Se writefile/readfile existirem (executor), salva a posição localmente.
-- Senão, mantém em memória durante a sessão.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEFAULT_POSITION = UDim2.new(1, -20, 1, -100)
local SAVE_FILE = "interact_button_pos.txt"

-- Carrega posição salva localmente (se o executor suportar)
local function loadSavedPosition()
	if typeof(writefile) == "function" and typeof(readfile) == "function" then
		local ok, data = pcall(readfile, SAVE_FILE)
		if ok and data then
			local x, y = data:match("([%-%d%.]+),([%-%d%.]+)")
			if x and y then
				return UDim2.new(1, tonumber(x), 1, tonumber(y))
			end
		end
	end
	return DEFAULT_POSITION
end

local function savePosition(pos)
	if typeof(writefile) == "function" then
		pcall(writefile, SAVE_FILE, tostring(pos.X.Offset) .. "," .. tostring(pos.Y.Offset))
	end
end

-- Remove GUI anterior
local oldGui = playerGui:FindFirstChild("InteractionGuiExecutor")
if oldGui then oldGui:Destroy() end

-- ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InteractionGuiExecutor"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Botão de interação
local interactButton = Instance.new("TextButton")
interactButton.Size = UDim2.new(0, 150, 0, 50)
interactButton.Position = loadSavedPosition()
interactButton.AnchorPoint = Vector2.new(1, 1)
interactButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
interactButton.TextColor3 = Color3.fromRGB(255, 255, 255)
interactButton.Font = Enum.Font.GothamBold
interactButton.TextSize = 18
interactButton.Text = "Interagir"
interactButton.Visible = false
interactButton.Active = true
interactButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = interactButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.7
stroke.Thickness = 1
stroke.Parent = interactButton

-- Engrenagem (toggle do modo edição)
local editToggle = Instance.new("TextButton")
editToggle.Size = UDim2.new(0, 36, 0, 36)
editToggle.Position = UDim2.new(1, -12, 1, -12)
editToggle.AnchorPoint = Vector2.new(1, 1)
editToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
editToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
editToggle.Font = Enum.Font.GothamBold
editToggle.TextSize = 16
editToggle.Text = "⚙"
editToggle.Visible = true
editToggle.ZIndex = 5
editToggle.Parent = screenGui

local editToggleCorner = Instance.new("UICorner")
editToggleCorner.CornerRadius = UDim.new(1, 0)
editToggleCorner.Parent = editToggle

-- Botão Editar
local editButton = Instance.new("TextButton")
editButton.Size = UDim2.new(0, 100, 0, 36)
editButton.Position = UDim2.new(1, -12, 1, -56)
editButton.AnchorPoint = Vector2.new(1, 1)
editButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
editButton.TextColor3 = Color3.fromRGB(255, 255, 255)
editButton.Font = Enum.Font.GothamBold
editButton.TextSize = 16
editButton.Text = "Editar"
editButton.Visible = false
editButton.ZIndex = 5
editButton.Parent = screenGui

local editButtonCorner = Instance.new("UICorner")
editButtonCorner.CornerRadius = UDim.new(0, 8)
editButtonCorner.Parent = editButton

-- Botão Fixar
local fixButton = Instance.new("TextButton")
fixButton.Size = UDim2.new(0, 100, 0, 36)
fixButton.Position = UDim2.new(1, -120, 1, -56)
fixButton.AnchorPoint = Vector2.new(1, 1)
fixButton.BackgroundColor3 = Color3.fromRGB(0, 170, 90)
fixButton.TextColor3 = Color3.fromRGB(255, 255, 255)
fixButton.Font = Enum.Font.GothamBold
fixButton.TextSize = 16
fixButton.Text = "Fixar"
fixButton.Visible = false
fixButton.ZIndex = 5
fixButton.Parent = screenGui

local fixButtonCorner = Instance.new("UICorner")
fixButtonCorner.CornerRadius = UDim.new(0, 8)
fixButtonCorner.Parent = fixButton

-- Estado
local activePrompts = {}
local activeCount = 0
local currentPrompt = nil
local isEditing = false
local isDragging = false
local dragStart, startPos

local function updateButton()
	if isEditing then
		interactButton.Visible = true
		interactButton.Text = "Arraste-me"
		return
	end
	interactButton.Visible = (activeCount > 0)
	if currentPrompt then
		local nome = currentPrompt.ObjectText
		if nome == "" then nome = "Objeto" end
		interactButton.Text = "Abrir " .. nome
	else
		interactButton.Text = "Interagir"
	end
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if not activePrompts[prompt] then
		activePrompts[prompt] = true
		activeCount += 1
		currentPrompt = prompt
		updateButton()
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if activePrompts[prompt] then
		activePrompts[prompt] = nil
		activeCount -= 1
		if currentPrompt == prompt then
			currentPrompt = next(activePrompts)
		end
		updateButton()
	end
end)

-- Clique e hold
local holdActive = false

interactButton.InputBegan:Connect(function(input)
	if isEditing then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Verifica se o prompt ainda existe e está ativo antes de disparar
		if currentPrompt and currentPrompt.Parent and not holdActive then
			holdActive = true
			currentPrompt:InputHoldBegin()
		end
	end
end)

interactButton.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		if holdActive then
			holdActive = false
			if currentPrompt and currentPrompt.Parent then
				currentPrompt:InputHoldEnd()
			end
		end
	end
end)

-- Edição
editToggle.Activated:Connect(function()
	editButton.Visible = not editButton.Visible
end)

editButton.Activated:Connect(function()
	isEditing = true
	editButton.Visible = false
	fixButton.Visible = true
	editToggle.Visible = false
	updateButton()
end)

fixButton.Activated:Connect(function()
	isEditing = false
	fixButton.Visible = false
	editButton.Visible = true
	editToggle.Visible = true
	savePosition(interactButton.Position)
	updateButton()
end)

-- Arrastar
interactButton.InputBegan:Connect(function(input)
	if not isEditing then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = true
		dragStart = input.Position
		startPos = interactButton.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				isDragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not isDragging then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		interactButton.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

updateButton()
