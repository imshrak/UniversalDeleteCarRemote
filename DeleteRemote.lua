local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local deleteRemote = ReplicatedStorage:WaitForChild("DeleteCar")

--====================================================
-- MODEL FINDER (SAFE GROUP FIX)
--====================================================
local function getGroupModel(part)
	if not part then return nil end

	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return nil end

	if model == workspace then return nil end

	-- prevent selecting whole map/world
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

--====================================================
-- 🧹 DELETE PART TOOL
--====================================================
local deleteTool = Instance.new("Tool")
deleteTool.Name = "DeleteTool"
deleteTool.RequiresHandle = false
deleteTool.Parent = player:WaitForChild("Backpack")

local deleteEquipped = false
local partBox

local function highlightPart(part)
	if partBox then partBox:Destroy() end

	if part and part:IsA("BasePart") then
		partBox = Instance.new("SelectionBox")
		partBox.Adornee = part
		partBox.Color3 = Color3.new(1, 0, 0)
		partBox.LineThickness = 0.05
		partBox.SurfaceTransparency = 0.8
		partBox.Parent = part
	end
end

local function clearPartHighlight()
	if partBox then
		partBox:Destroy()
		partBox = nil
	end
end

deleteTool.Equipped:Connect(function()
	deleteEquipped = true
end)

deleteTool.Unequipped:Connect(function()
	deleteEquipped = false
	clearPartHighlight()
end)

--====================================================
-- 🧨 DELETE MODEL TOOL
--====================================================
local deleteModelTool = Instance.new("Tool")
deleteModelTool.Name = "DeleteModelTool"
deleteModelTool.RequiresHandle = false
deleteModelTool.Parent = player:WaitForChild("Backpack")

local modelEquipped = false
local modelBoxes = {}
local currentModel = nil

local function clearModelHighlight()
	for _, b in ipairs(modelBoxes) do
		b:Destroy()
	end
	modelBoxes = {}
	currentModel = nil
end

local function highlightModel(model)
	if model == currentModel then return end
	currentModel = model

	clearModelHighlight()

	if not model then return end

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			local box = Instance.new("SelectionBox")
			box.Adornee = obj
			box.Color3 = Color3.new(0, 1, 0)
			box.LineThickness = 0.05
			box.SurfaceTransparency = 0.8
			box.Parent = obj

			table.insert(modelBoxes, box)
		end
	end
end

deleteModelTool.Equipped:Connect(function()
	modelEquipped = true
end)

deleteModelTool.Unequipped:Connect(function()
	modelEquipped = false
	clearModelHighlight()
end)

--====================================================
-- 🎯 SINGLE SAFE LOOP
--====================================================
local last = 0
local rate = 0.08

mouse.Move:Connect(function()
	if tick() - last < rate then return end
	last = tick()

	local target = mouse.Target
	if not target then
		clearPartHighlight()
		clearModelHighlight()
		return
	end

	-- DELETE PART TOOL
	if deleteEquipped then
		if target:IsA("BasePart") then
			highlightPart(target)
		else
			clearPartHighlight()
		end
	end

	-- DELETE MODEL TOOL
	if modelEquipped then
		local model = getGroupModel(target)
		if model then
			highlightModel(model)
		else
			clearModelHighlight()
		end
	end
end)

--====================================================
-- CLICK ACTIONS
--====================================================

deleteTool.Activated:Connect(function()
	if not deleteEquipped then return end

	local t = mouse.Target
	if t and t:IsA("BasePart") then
		deleteRemote:FireServer(t)
	end
end)

deleteModelTool.Activated:Connect(function()
	if not modelEquipped then return end

	local model = getGroupModel(mouse.Target)
	if model then
		deleteRemote:FireServer(model) -- server should handle model deletion
	end
end)