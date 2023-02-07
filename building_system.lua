local uis = game:GetService("UserInputService")
local cs = game:GetService("CollectionService")
local rs = game:GetService("RunService")

local player = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local buildParts = game.ReplicatedStorage.BuildParts
local event = game.ReplicatedStorage.BuildEvent

local mouse = player:GetMouse()

local tool = script.Parent
local gui = tool:WaitForChild("BuildGui")
local module = require(script.Keybinds)
local keybinds = module.GetKeybinds()

local mode = "Build"
local selected = nil
local activeGui = nil
local preview = nil
local egg = nil
local equipped = false
local valid = false
local rotation = 0

local viewPortCam = Instance.new("Camera", workspace)
viewPortCam.CFrame = CFrame.new(Vector3.new(6, 8, -10), Vector3.new())
viewPortCam.FieldOfView = 55

function CheckIfEven(num)
	
	return num % 2 == 0
	
end

function CreateGui()
	
	activeGui = gui:Clone()
	
	local frame = activeGui:WaitForChild("Frame")
	local label = frame:WaitForChild("Label")
	local buttons = frame:WaitForChild("Buttons")

	for _, button in pairs(buttons:GetChildren()) do
		
		local viewPort = Instance.new("ViewportFrame", frame.ViewPorts)
		viewPort.AnchorPoint = Vector2.new(0.5, 0.5)
		viewPort.BackgroundTransparency = 1
		viewPort.Size = button.Size
		viewPort.Position = button.Position
		viewPort.CurrentCamera = viewPortCam
		
		local part = buildParts[button.Name]:Clone()
		part.Parent = viewPort
		part:SetPrimaryPartCFrame(CFrame.new())
		
		for _, v in pairs(part:GetDescendants()) do
			
			if v.Name == "DebugPart" then
				
				v.Parent:Destroy()
				
			end
			
		end

		button.MouseEnter:Connect(function()

			button.BackgroundTransparency = 0
			label.Text = button.Name

		end)

		button.MouseLeave:Connect(function()

			button.BackgroundTransparency = 1
			label.Text = ""

		end)

		button.MouseButton1Down:Connect(function()
			
			activeGui:Destroy()
			activeGui = nil
			
			rotation = 0

			Place(button.Name)
			
		end)
		
	end
	
	activeGui.Parent = player.PlayerGui
	
end

function Place(name)

	if preview then

		preview:Destroy()
		preview = nil

	end

	if buildParts:FindFirstChild(name) then

		local ignore = cs:GetTagged("RayIgnore")
		local previewParts = {}
		
		for _, part in pairs(player.Character:GetDescendants()) do
			
			if part:IsA("Part") or part:IsA("BasePart") then
				
				table.insert(ignore, part)
				
			end
			
		end

		preview = buildParts[name]:Clone()

		for _, v in pairs(preview:GetDescendants()) do

			if v:IsA("Part") or v:IsA("WedgePart") or v:IsA("TrussPart") or v:IsA("MeshPart") then

				if v:FindFirstChild("DebugPart") then

					v.Transparency = 1

				else

					v.Transparency = 0.8
					v.Color = Color3.fromRGB(70, 200, 70)

				end

				v.CanCollide = false
				table.insert(ignore, v)
				table.insert(previewParts, v)

			end

		end

		preview.Parent = workspace

		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = ignore
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist

		repeat

			local mousePos = uis:GetMouseLocation()
			local unitRay = cam:ScreenPointToRay(mousePos.X, mousePos.Y - 35)
			local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)

			if rayResult then
				
				local size = preview.HitBox.Size

				if CheckIfEven(rotation) then

					size = size

				else

					size = Vector3.new(size.Z, size.Y, size.X)

				end
				
				local offset = rayResult.Normal * (size / 2)

				preview.PrimaryPart = preview.HitBox
				preview:SetPrimaryPartCFrame(CFrame.new(rayResult.Position + offset) * CFrame.Angles(0, math.rad(90 * rotation), 0))

				local snaps = preview.Snaps:GetChildren()
				local minimum = math.huge
				local snapTo = nil
				local snapPoint = nil

				for i, snap in pairs(snaps) do
					
					local offset = size / 2.1
					
					local region = Region3.new(snap.Position - offset, snap.Position + offset)
					local partsInRegion = workspace:FindPartsInRegion3(region, preview)

					for _, part in pairs(partsInRegion) do

						local distance = (part.Position - snap.Position).Magnitude

						if part:FindFirstChild("Snap") and distance < minimum then

							minimum = distance
							snapTo = part
							snapPoint = snap

						end

					end

				end

				if snapTo and snapPoint then

					preview.PrimaryPart = snapPoint
					preview:SetPrimaryPartCFrame(CFrame.new(snapTo.Position) * CFrame.Angles(0, math.rad(90 * rotation), 0))
					
				end

				for _, v in pairs(preview:GetDescendants()) do

					if v:IsA("Part") or v:IsA("WedgePart") or v:IsA("TrussPart") or v:IsA("MeshPart") then						
						
						if (preview.HitBox.Position - player.Character.HumanoidRootPart.Position).Magnitude <= 35 then
							
							v.Color = Color3.fromRGB(70, 200, 70)
							valid = true

						else
							
							v.Color = Color3.fromRGB(200, 70, 70)
							valid = false

						end

					end

				end

			else

				valid = false

			end

			rs.RenderStepped:Wait()

		until equipped == false or preview == nil

	end
	
end

function DestroyMode()
	
	local ignore = cs:GetTagged("RayIgnore")

	for _, part in pairs(player.Character:GetDescendants()) do

		if part:IsA("Part") or part:IsA("BasePart") then

			table.insert(ignore, part)

		end

	end
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = ignore
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	
	repeat
		
		local mousePos = uis:GetMouseLocation()
		local unitRay = cam:ScreenPointToRay(mousePos.X, mousePos.Y - 35)
		local rayResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 36, rayParams)
		
		if rayResult then
			
			local hit = rayResult.Instance
			local part = nil
			
			if hit.Parent and hit.Parent.Parent then
				
				if hit.Parent.Parent.Name == "BuildParts" and hit.Parent.Owner.Value == player.Name then
					
					part = hit.Parent
					
				elseif hit.Parent.Parent.Parent and hit.Parent.Parent.Parent.Name == "BuildParts" and hit.Parent.Parent.Owner.Value == player.Name then
					
					part = hit.Parent.Parent
					
				end
				
			end
			
			if selected then
	
				selected.HitBox.Color = Color3.fromRGB(91, 154, 76)
				selected.HitBox.Transparency = 1

			end
			
			if part then

				selected = part
				
				selected.HitBox.Color = Color3.fromRGB(200, 20, 20)
				selected.HitBox.Transparency = 0.9
				
			end
			
		end
		
		rs.RenderStepped:Wait()
		
	until mode ~= "Destroy" or equipped == false
	
	if selected then
		
		selected.HitBox.Color = Color3.fromRGB(91, 154, 76)
		selected.HitBox.Transparency = 1
		
	end
	
	selected = nil
	
end



tool.Equipped:Connect(function()
	
	equipped = true
	
end)

tool.Unequipped:Connect(function()
	
	equipped = false
	
	if egg then

		egg:Destroy()
		egg = nil

	end
	
	if preview then
		
		preview:Destroy()
		preview = nil
		
	end
	
	if activeGui then
		
		activeGui:Destroy()
		activeGui = nil
		
	end
	
end)

uis.InputBegan:Connect(function(input, gpe)
	
	if not gpe and equipped then
		
		if input.KeyCode == Enum.KeyCode[keybinds.Build] then
			
			if egg then
				
				egg:Destroy()
				egg = nil
				
			end
			
			if preview then
				
				preview:Destroy()
				preview = nil
				
			end
			
			if activeGui then
				
				activeGui:Destroy()
				activeGui = nil
				
			else
				
				mode = "Build"
				CreateGui()
				
			end
			
		elseif input.KeyCode == Enum.KeyCode[keybinds.Delete] then
			
			if egg then

				egg:Destroy()
				egg = nil

			end
			
			if preview then

				preview:Destroy()
				preview = nil

			end

			if activeGui then

				activeGui:Destroy()
				activeGui = nil

			end
			
			mode = "Destroy"
			DestroyMode()
			
		elseif preview and input.KeyCode == Enum.KeyCode[keybinds.Rotate] then

			rotation += 1

			if rotation >= 8 then

				rotation = 0

			end
			
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			
			if mode == "Build" and preview and valid then
				
				event:FireServer("Build", preview.Name, preview.HitBox.CFrame)
				
			elseif mode == "Destroy" and selected then
				
				event:FireServer("Destroy", selected)
				selected = nil
				
			end
			
		end
		
	end
	
end)
