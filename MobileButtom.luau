-- Versão autossuficiente: roda no executor OU como LocalScript
-- Se writefile/readfile existirem (executor), salva posição/tamanho/curva localmente (JSON).
-- Senão, mantém em memória durante a sessão.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SAVE_FILE = "interact_button_pos.txt"

local DEFAULT_DATA = {
	x = -20,
	y = -100,
	size = 80,
	corner = 1, -- 0 = quadrado, 1 = pílula/círculo
}

-- Carrega posição/tamanho/curva salvos localmente (se o executor suportar)
local function loadSavedData()
	if typeof(readfile) == "function" then
		local ok, raw = pcall(readfile, SAVE_FILE)
		if ok and raw then
			local okDecode, decoded = pcall(function()
				return HttpService:JSONDecode(raw)
			end)
			if okDecode and typeof(decoded) == "table" then
				return {
					x = decoded.x or DEFAULT_DATA.x,
					y = decoded.y or DEFAULT_DATA.y,
					size = decoded.size or DEFAULT_DATA.size,
					corner = decoded.corner or DEFAULT_DATA.corner,
				}
			end

			-- Fallback: formato antigo "x,y" (sem tamanho/curva)
			local x, y = raw:match("([%-%d%.]+),([%-%d%.]+)")
			if x and y then
				return {
					x = tonumber(x),
					y = tonumber(y),
					size = DEFAULT_DATA.size,
					corner = DEFAULT_DATA.corner,
				}
			end
		end
	end
	return DEFAULT_DATA
end

local function saveData(data)
	if typeof(writefile) == "function" then
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(data)
		end)
		if ok then
			pcall(writefile, SAVE_FILE, encoded)
		end
	end
end

local savedData = loadSavedData()

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
interactButton.Size = UDim2.new(0, savedData.size, 0, savedData.size)
interactButton.Position = UDim2.new(1, savedData.x, 1, savedData.y)
interactButton.AnchorPoint = Vector2.new(1, 1)
interactButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
interactButton.TextColor3 = Color3.fromRGB(255, 255, 255)
interactButton.Font = Enum.Font.GothamBold
interactButton.Text = "Interagir"
interactButton.Visible = false
interactButton.Active = true
interactButton.TextScaled = true
interactButton.TextWrapped = true
interactButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(savedData.corner, 0)
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

-- Painel de edição (sliders de Tamanho e Curva)
local editPanel = Instance.new("Frame")
editPanel.Name = "EditPanel"
editPanel.Size = UDim2.new(0, 220, 0, 100)
editPanel.Position = UDim2.new(1, -12, 0, 12)
editPanel.AnchorPoint = Vector2.new(1, 0)
editPanel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
editPanel.BackgroundTransparency = 0.1
editPanel.Visible = false
editPanel.ZIndex = 5
editPanel.Parent = screenGui

local editPanelCorner = Instance.new("UICorner")
editPanelCorner.CornerRadius = UDim.new(0, 10)
editPanelCorner.Parent = editPanel

local editPanelPadding = Instance.new("UIPadding")
editPanelPadding.PaddingTop = UDim.new(0, 10)
editPanelPadding.PaddingLeft = UDim.new(0, 12)
editPanelPadding.PaddingRight = UDim.new(0, 12)
editPanelPadding.Parent = editPanel

local editPanelLayout = Instance.new("UIListLayout")
editPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
editPanelLayout.Padding = UDim.new(0, 10)
editPanelLayout.Parent = editPanel

-- Cria um slider arrastável genérico (label + trilho + alça)
local function createSlider(parent, layoutOrder, labelPrefix, min, max, initial, step, formatFn, onChange)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 40)
	container.BackgroundTransparency = 1
	container.LayoutOrder = layoutOrder
	container.Parent = parent

	local labelText = Instance.new("TextLabel")
	labelText.Size = UDim2.new(1, 0, 0, 16)
	labelText.BackgroundTransparency = 1
	labelText.TextColor3 = Color3.fromRGB(255, 255, 255)
	labelText.Font = Enum.Font.Gotham
	labelText.TextSize = 13
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.Parent = container

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.new(0, 0, 0, 24)
	track.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	track.BorderSizePixel = 0
	track.Active = true
	track.Parent = container

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local thumb = Instance.new("Frame")
	thumb.Size = UDim2.new(0, 20, 0, 20)
	thumb.AnchorPoint = Vector2.new(0.5, 0.5)
	thumb.Position = UDim2.new(0, 0, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(0, 170, 220)
	thumb.BorderSizePixel = 0
	thumb.Active = true
	thumb.Parent = track

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(1, 0)
	thumbCorner.Parent = thumb

	local currentValue = initial

	local function fractionFromValue(v)
		return math.clamp((v - min) / (max - min), 0, 1)
	end

	local function refresh()
		thumb.Position = UDim2.new(fractionFromValue(currentValue), 0, 0.5, 0)
		labelText.Text = labelPrefix .. ": " .. formatFn(currentValue)
	end

	local dragging = false

	local function setFromAbsoluteX(absoluteX)
		local trackPos = track.AbsolutePosition.X
		local trackWidth = track.AbsoluteSize.X
		if trackWidth <= 0 then return end
		local fraction = math.clamp((absoluteX - trackPos) / trackWidth, 0, 1)
		local value = min + fraction * (max - min)
		if step and step > 0 then
			value = math.floor(value / step + 0.5) * step
		end
		currentValue = math.clamp(value, min, max)
		refresh()
		onChange(currentValue)
	end

	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromAbsoluteX(input.Position.X)
		end
	end

	thumb.InputBegan:Connect(beginDrag)
	track.InputBegan:Connect(beginDrag)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement then
			setFromAbsoluteX(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	refresh()

	return {
		getValue = function()
			return currentValue
		end,
	}
end

local sizeSlider = createSlider(
	editPanel, 1, "Tamanho", 50, 140, savedData.size, 1,
	function(v) return string.format("%dpx", math.floor(v + 0.5)) end,
	function(v) interactButton.Size = UDim2.new(0, v, 0, v) end
)

local cornerSlider = createSlider(
	editPanel, 2, "Curva", 0, 1, savedData.corner, 0.01,
	function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end,
	function(v) corner.CornerRadius = UDim.new(v, 0) end
)

-- Estado
local activePrompts = {}
local activeCount = 0
local currentPrompt = nil
local isEditing = false
local isDragging = false
local holdActive = false
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

-- Clique/hold (fora do modo edição) e início do arrasto (dentro do modo edição)
-- Handler único: evita duplicidade e evita conexões soltas por arrasto.
interactButton.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if isEditing then
		isDragging = true
		dragStart = input.Position
		startPos = interactButton.Position
	else
		if currentPrompt and currentPrompt.Parent and not holdActive then
			holdActive = true
			currentPrompt:InputHoldBegin()
		end
	end
end)

interactButton.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Touch
		and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	if holdActive then
		holdActive = false
		if currentPrompt and currentPrompt.Parent then
			currentPrompt:InputHoldEnd()
		end
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

-- Edição
editToggle.Activated:Connect(function()
	editButton.Visible = not editButton.Visible
end)

editButton.Activated:Connect(function()
	isEditing = true
	editButton.Visible = false
	fixButton.Visible = true
	editToggle.Visible = false
	editPanel.Visible = true
	updateButton()
end)

fixButton.Activated:Connect(function()
	isEditing = false
	fixButton.Visible = false
	editButton.Visible = true
	editToggle.Visible = true
	editPanel.Visible = false
	saveData({
		x = interactButton.Position.X.Offset,
		y = interactButton.Position.Y.Offset,
		size = sizeSlider.getValue(),
		corner = cornerSlider.getValue(),
	})
	updateButton()
end)

updateButton()
