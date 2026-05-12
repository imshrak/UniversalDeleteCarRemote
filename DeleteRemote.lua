local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local deleteRemote = ReplicatedStorage:WaitForChild("DeleteCar")

local clickDeleteEnabled = false
local modelDeleteEnabled = false

local deleteToolEquipped = false
local modelToolEquipped = false

local deleteTool
local modelTool

local partBox
local modelBoxes = {}
local currentModel

local function getGroupModel(part)
	if not part then
		return nil
	end

	local model = part:FindFirstAncestorOfClass("Model")

	if not model then
		return nil
	end

	if model == workspace then
		return nil
	end

	local count = 0

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			count += 1

			if count > 800 then
				return nil
			end
		end
	end

	return model
end

local function clearPartHighlight()
	if partBox then
		partBox:Destroy()
		partBox = nil
	end
end

local function highlightPart(part)
	if partBox and partBox.Adornee == part then
		return
	end

	clearPartHighlight()

	if part and part:IsA("BasePart") then
		partBox = Instance.new("SelectionBox")
		partBox.Adornee = part
		partBox.Color3 = Color3.fromRGB(255, 60, 60)
		partBox.LineThickness = 0.05
		partBox.SurfaceTransparency = 0.8
		partBox.Parent = part
	end
end

local function clearModelHighlight()
	for _, v in ipairs(modelBoxes) do
		v:Destroy()
	end

	modelBoxes = {}
	currentModel = nil
end

local function highlightModel(model)
	if currentModel == model then
		return
	end

	clearModelHighlight()

	currentModel = model

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			local box = Instance.new("SelectionBox")
			box.Adornee = obj
			box.Color3 = Color3.fromRGB(0, 255, 120)
			box.LineThickness = 0.05
			box.SurfaceTransparency = 0.8
			box.Parent = obj

			table.insert(modelBoxes, box)
		end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "DeleteMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999

local parent = gethui and gethui() or game:GetService("CoreGui")
gui.Parent = parent

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, 190)
frame.Position = UDim2.new(0.5, -115, 0.5, -95)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(40, 40, 40)
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -35, 0, 35)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Delete Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.Position = UDim2.new(1, -33, 0, 4)
closeButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 14
closeButton.TextColor3 = Color3.new(1,1,1)
closeButton.Parent = frame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local function makeButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 40)
	button.Position = UDim2.new(0, 10, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	button.BorderSizePixel = 0
	button.Text = text
	button.Font = Enum.Font.Gotham
	button.TextSize = 14
	button.TextColor3 = Color3.new(1,1,1)
	button.Parent = frame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = button

	return button
end

local toolsButton = makeButton("Get Tools", 45)
local clickDeleteButton = makeButton("ClickDelete : OFF", 90)
local modelDeleteButton = makeButton("ModelDelete : OFF", 135)

local function createTools()
	if not deleteTool then
		deleteTool = Instance.new("Tool")
		deleteTool.Name = "DeleteTool"
		deleteTool.RequiresHandle = false
		deleteTool.Parent = player.Backpack

		deleteTool.Equipped:Connect(function()
			deleteToolEquipped = true
		end)

		deleteTool.Unequipped:Connect(function()
			deleteToolEquipped = false
			clearPartHighlight()
		end)

		deleteTool.Activated:Connect(function()
			local target = mouse.Target

			if target and target:IsA("BasePart") then
				deleteRemote:FireServer(target)
			end
		end)
	end

	if not modelTool then
		modelTool = Instance.new("Tool")
		modelTool.Name = "DeleteModelTool"
		modelTool.RequiresHandle = false
		modelTool.Parent = player.Backpack

		modelTool.Equipped:Connect(function()
			modelToolEquipped = true
		end)

		modelTool.Unequipped:Connect(function()
			modelToolEquipped = false
			clearModelHighlight()
		end)

		modelTool.Activated:Connect(function()
			local model = getGroupModel(mouse.Target)

			if model then
				deleteRemote:FireServer(model)
			end
		end)
	end
end

toolsButton.MouseButton1Click:Connect(function()
	createTools()
end)

clickDeleteButton.MouseButton1Click:Connect(function()
	clickDeleteEnabled = not clickDeleteEnabled

	if clickDeleteEnabled then
		clickDeleteButton.Text = "ClickDelete : ON"

		modelDeleteEnabled = false
		modelDeleteButton.Text = "ModelDelete : OFF"

		clearModelHighlight()
	else
		clickDeleteButton.Text = "ClickDelete : OFF"

		clearPartHighlight()
	end
end)

modelDeleteButton.MouseButton1Click:Connect(function()
	modelDeleteEnabled = not modelDeleteEnabled

	if modelDeleteEnabled then
		modelDeleteButton.Text = "ModelDelete : ON"

		clickDeleteEnabled = false
		clickDeleteButton.Text = "ClickDelete : OFF"

		clearPartHighlight()
	else
		modelDeleteButton.Text = "ModelDelete : OFF"

		clearModelHighlight()
	end
end)

mouse.Move:Connect(function()
	local target = mouse.Target

	if clickDeleteEnabled or deleteToolEquipped then
		if target and target:IsA("BasePart") then
			highlightPart(target)
		else
			clearPartHighlight()
		end
	elseif not modelDeleteEnabled and not modelToolEquipped then
		clearPartHighlight()
	end

	if modelDeleteEnabled or modelToolEquipped then
		local model = getGroupModel(target)

		if model then
			highlightModel(model)
		else
			clearModelHighlight()
		end
	elseif not clickDeleteEnabled and not deleteToolEquipped then
		clearModelHighlight()
	end
end)

mouse.Button1Down:Connect(function()
	if clickDeleteEnabled then
		local target = mouse.Target

		if target and target:IsA("BasePart") then
			deleteRemote:FireServer(target)
		end
	end

	if modelDeleteEnabled then
		local model = getGroupModel(mouse.Target)

		if model then
			deleteRemote:FireServer(model)
		end
	end
end)

closeButton.MouseButton1Click:Connect(function()
	clickDeleteEnabled = false
	modelDeleteEnabled = false

	clearPartHighlight()
	clearModelHighlight()

	if deleteTool then
		deleteTool:Destroy()
	end

	if modelTool then
		modelTool:Destroy()
	end

	gui:Destroy()
end)

local dragging = false
local dragStart
local startPos

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
