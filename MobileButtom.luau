-- Script adaptado para executor (ou LocalScript)
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove GUI anterior se existir (evita duplicar)
local oldGui = playerGui:FindFirstChild("InteractionGuiExecutor")
if oldGui then oldGui:Destroy() end

-- Cria o ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InteractionGuiExecutor"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Cria o botão
local interactButton = Instance.new("TextButton")
interactButton.Name = "InteractButton"
interactButton.Size = UDim2.new(0, 150, 0, 50)
interactButton.Position = UDim2.new(1, -20, 1, -100) -- canto inferior direito
interactButton.AnchorPoint = Vector2.new(1, 1)
interactButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
interactButton.TextColor3 = Color3.fromRGB(255, 255, 255)
interactButton.Text = "Interagir"
interactButton.Visible = false
interactButton.Parent = screenGui

-- Opcional: borda arredondada
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = interactButton

-- Lógica
local activePrompts = {}
local currentPrompt = nil

local function updateButton()
	interactButton.Visible = (#activePrompts > 0)
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
		currentPrompt = prompt
		updateButton()
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	if activePrompts[prompt] then
		activePrompts[prompt] = nil
		if currentPrompt == prompt then
			currentPrompt = next(activePrompts)
		end
		updateButton()
	end
end)

interactButton.Activated:Connect(function()
	if currentPrompt then
		local holdTime = currentPrompt.HoldDuration or 0
		ProximityPromptService:InputHoldBegin(currentPrompt)
		task.wait(holdTime + 0.05)
		ProximityPromptService:InputHoldEnd(currentPrompt)
	end
end)
