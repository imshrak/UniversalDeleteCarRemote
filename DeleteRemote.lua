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

local partBox
local modelBoxes = {}
local currentModel

local function getGroupModel(part)
	if not part then return nil end

	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return nil end
	if model == workspace then return nil end

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

player.Chatted:Connect(function(msg)
	msg = msg:lower()

	if msg == "$seatnuke" or msg == "$seatnuke all" then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("Seat") or obj:IsA("VehicleSeat") then
				deleteRemote:FireServer(obj)
			end
		end
	end

	if msg == "$kill all" or msg == "$headnuke" then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= player then
				local char = plr.Character

				if char then
					local head = char:FindFirstChild("Head")

					if head then
						deleteRemote:FireServer(head)
					end
				end
			end
		end
	end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "DeleteMenu"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 180)
frame.Position = UDim2.new(0.5, -110, 0.5, -90)
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
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "Delete Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

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

toolsButton.MouseButton1Click:Connect(function()
	local deleteTool = Instance.new("Tool")
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

	local modelTool = Instance.new("Tool")
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
