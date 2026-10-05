local Players           = game:GetService("Players")
local StarterGui        = game:GetService("StarterGui")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local AssetService      = game:GetService("AssetService")
local MaterialService   = game:GetService("MaterialService")
local CAS               = game:GetService("ContextActionService")

local UIS = UserInputService

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local LP        = player

local ours = {}

local HEART_FULL  = "rbxassetid://71982775577774"
local HEART_EMPTY = "rbxassetid://72490262317198"
local HEART_HALF  = "rbxassetid://112532643693600"

local SIZE_MULTIPLIER = 1
local GUI_SCALE       = nil
local KEEP_CHAT       = false
local WHITELIST       = {}
local SHOW_3D_ICONS   = true

local KILL_XP            = 5
local CREDIT_NEARBY_KILLS = true
local NEARBY_RANGE       = 40
local RESET_XP_ON_DEATH  = true
local ORB_ATTRACT_RANGE  = 12
local ORB_ABSORB_RANGE   = 3

task.spawn(function()
	for _ = 1, 30 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			if KEEP_CHAT then
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			end
		end)
		if ok then break end
		task.wait(0.25)
	end
end)

local function hideGui(g)
	if g:IsA("ScreenGui") and not ours[g] and not table.find(WHITELIST, g.Name) then
		g.Enabled = false
		g:GetPropertyChangedSignal("Enabled"):Connect(function()
			if g.Enabled then g.Enabled = false end
		end)
	end
end
for _, g in ipairs(playerGui:GetChildren()) do hideGui(g) end
playerGui.ChildAdded:Connect(hideGui)

local function newScreenGui(name, order)
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.DisplayOrder = order
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ours[g] = true
	return g
end

local function rect(parent, x, y, w, h, color, name)
	local f = Instance.new("Frame")
	if name then f.Name = name end
	f.Position = UDim2.fromOffset(x, y)
	f.Size = UDim2.fromOffset(w, h)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function outline(parent, x, y, w, h, t, color)
	rect(parent, x, y, w, t, color)
	rect(parent, x, y + h - t, w, t, color)
	rect(parent, x, y + t, t, h - 2 * t, color)
	rect(parent, x + w - t, y + t, t, h - 2 * t, color)
end

local function pixelText(parent, name, size, color)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Code
	t.TextSize = size
	t.TextColor3 = color
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.TextStrokeTransparency = 0.2
	t.Text = ""
	t.Parent = parent
	return t
end

local crossGui = newScreenGui("MinecraftCrosshair", 100)
crossGui.IgnoreGuiInset = true
pcall(function() crossGui.ScreenInsets = Enum.ScreenInsets.None end)
crossGui.Parent = playerGui

local cross = Instance.new("Frame")
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(11, 11)
cross.BackgroundTransparency = 1
cross.Visible = false
cross.Parent = crossGui
local crossScale = Instance.new("UIScale", cross)

for _, d in ipairs({ { 11, 1 }, { 1, 11 } }) do
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.fromOffset(d[1], d[2])
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BackgroundTransparency = 0.15
	line.BorderSizePixel = 0
	line.Parent = cross
end

local function shouldShowCrosshair()
	local cam = workspace.CurrentCamera
	if not cam then return false end

	if cam.CameraSubject then
		local hum = cam.CameraSubject
		if hum:IsA("Humanoid") then
			local char = hum.Parent
			local head = char and char:FindFirstChild("Head")
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if head and root then
				local dist = (cam.CFrame.Position - head.Position).Magnitude
				if dist < 1.5 then return true end
			end
		end
	end

	if cam.CameraType == Enum.CameraType.Scriptable then return false end

	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if head then
		local dist = (cam.CFrame.Position - head.Position).Magnitude
		if UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
			and dist < 20 and dist > 1.5 then
			return true
		end
	end

	return false
end

local crosshairActive = false
local function updateCrosshair()
	local show = shouldShowCrosshair()
	cross.Visible = show

	if show and not crosshairActive then
		crosshairActive = true
		pcall(function() UIS.MouseIconEnabled = false end)
		pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
	elseif not show and crosshairActive then
		crosshairActive = false
		pcall(function() UIS.MouseIconEnabled = true end)
	end
end

RunService.RenderStepped:Connect(updateCrosshair)

local gui = newScreenGui("MinecraftUI", 101)
gui.IgnoreGuiInset = true
pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
gui.Parent = playerGui

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.AnchorPoint = Vector2.new(0.5, 1)
hud.Position = UDim2.fromScale(0.5, 1)
hud.Size = UDim2.fromOffset(182, 55)
hud.BackgroundTransparency = 1
hud.Parent = gui
local hudScale = Instance.new("UIScale", hud)

local GRAY = Color3.fromRGB(139, 139, 139)
local DARK = Color3.fromRGB(45, 45, 45)

local hotbar = rect(hud, 0, 33, 182, 22, Color3.new(0, 0, 0), "Hotbar")
hotbar.BackgroundTransparency = 0.55
rect(hotbar, 0, 0, 182, 1, GRAY)
rect(hotbar, 0, 21, 182, 1, GRAY)
for i = 0, 9 do
	rect(hotbar, 20 * i, 0, 2, 22, GRAY)
end

local slotFrames, slotIcons, slotLabels, slotCounts = {}, {}, {}, {}

for i = 1, 9 do
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. i
	slot.Position = UDim2.fromOffset(20 * (i - 1) + 2, 1)
	slot.Size = UDim2.fromOffset(18, 20)
	slot.BackgroundTransparency = 1
	slot.Active = true
	slot.Parent = hotbar
	outline(slot, 0, 0, 18, 20, 1, DARK)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Position = UDim2.fromOffset(1, 2)
	icon.Size = UDim2.fromOffset(16, 16)
	icon.BackgroundTransparency = 1
	icon.ResampleMode = Enum.ResamplerMode.Pixelated
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Visible = false
	icon.Parent = slot

	local label = pixelText(slot, "ToolName", 7, Color3.new(1, 1, 1))
	label.Position = UDim2.fromOffset(1, 2)
	label.Size = UDim2.fromOffset(16, 16)
	label.TextWrapped = true
	label.Visible = false

	local count = pixelText(slot, "Count", 8, Color3.new(1, 1, 1))
	count.Position = UDim2.fromOffset(0, 0)
	count.Size = UDim2.fromOffset(19, 20)
	count.TextXAlignment = Enum.TextXAlignment.Right
	count.TextYAlignment = Enum.TextYAlignment.Bottom
	count.ZIndex = 5

	slotFrames[i], slotIcons[i], slotLabels[i], slotCounts[i] = slot, icon, label, count
end

local selector = Instance.new("Frame")
selector.Name = "Selector"
selector.Size = UDim2.fromOffset(24, 24)
selector.BackgroundTransparency = 1
selector.ZIndex = 10
selector.Parent = hotbar
outline(selector, 0, 0, 24, 24, 2, Color3.fromRGB(235, 245, 238))
outline(selector, 2, 2, 20, 20, 1, Color3.fromRGB(70, 70, 70))

local xpBar = rect(hud, 0, 25, 182, 5, Color3.fromRGB(24, 33, 31), "XPBar")
local xpTrack = rect(xpBar, 1, 1, 180, 3, Color3.fromRGB(52, 74, 70), "Track")
for k = 1, 22 do
	rect(xpTrack, k * 8, 0, 1, 3, Color3.fromRGB(30, 43, 40))
end

local xpFill = rect(xpTrack, 0, 0, 0, 3, Color3.fromRGB(126, 252, 31), "Fill")
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.ClipsDescendants = true
local hl = rect(xpFill, 0, 0, 0, 1, Color3.fromRGB(190, 255, 120))
hl.Size = UDim2.new(1, 0, 0, 1)
local sh = rect(xpFill, 0, 2, 0, 1, Color3.fromRGB(82, 184, 28))
sh.Size = UDim2.new(1, 0, 0, 1)
for k = 1, 22 do
	rect(xpFill, k * 8, 0, 1, 3, Color3.fromRGB(60, 140, 24))
end

local levelLabel = pixelText(hud, "Level", 9, Color3.fromRGB(126, 252, 31))
levelLabel.AnchorPoint = Vector2.new(0.5, 0)
levelLabel.Position = UDim2.fromOffset(91, 15)
levelLabel.Size = UDim2.fromOffset(40, 9)
levelLabel.TextStrokeTransparency = 0

local hearts = {}
for i = 1, 10 do
	local h = Instance.new("ImageLabel")
	h.Name = "Heart" .. i
	h.Position = UDim2.fromOffset((i - 1) * 8, 14)
	h.Size = UDim2.fromOffset(9, 9)
	h.BackgroundTransparency = 1
	h.Image = HEART_FULL
	h.ResampleMode = Enum.ResamplerMode.Pixelated
	h.ScaleType = Enum.ScaleType.Fit
	h.Parent = hud
	hearts[i] = h
end

local itemName = pixelText(hud, "ItemName", 9, Color3.new(1, 1, 1))
itemName.AnchorPoint = Vector2.new(0.5, 0)
itemName.Position = UDim2.fromOffset(91, 1)
itemName.Size = UDim2.fromOffset(182, 10)
itemName.TextTransparency = 1
itemName.TextStrokeTransparency = 1

local function computeScale()
	local size = gui.AbsoluteSize
	if size.X < 1 or size.Y < 1 then return 1 end

	local s
	if GUI_SCALE then
		s = GUI_SCALE
	else
		local byWidth  = (size.X * 0.26) / 182
		local byHeight = (size.Y * 0.05) / 22
		s = math.max(1, math.min(byWidth, byHeight)) * SIZE_MULTIPLIER
	end

	s = math.min(s, (size.X * 0.96) / 182)
	return math.floor(s * 4 + 0.5) / 4
end

local function updateScale()
	local s = computeScale()
	hudScale.Scale = s
	crossScale.Scale = math.max(1, math.min(s, 1.5))
end
updateScale()
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

local currentHP = 20

local function renderHearts()
	for i = 1, 10 do
		local full = i * 2
		if currentHP >= full then
			hearts[i].Image = HEART_FULL
		elseif currentHP == full - 1 then
			hearts[i].Image = HEART_HALF
		else
			hearts[i].Image = HEART_EMPTY
		end
	end
end

local lastShake = 0
RunService.RenderStepped:Connect(function()
	local now = os.clock()
	if now - lastShake < 0.1 then return end
	lastShake = now
	for i = 1, 10 do
		local y = 0
		if currentHP > 0 and currentHP <= 4 and math.random(1, 4) == 1 then
			y = math.random(-1, 1)
		end
		hearts[i].Position = UDim2.fromOffset((i - 1) * 8, 14 + y)
	end
end)

local xpTotal = 0
local lastLevel = 0

local function needed(level)
	if level <= 15 then return 2 * level + 7
	elseif level <= 30 then return 5 * level - 38
	else return 9 * level - 158 end
end

local function levelFromTotal(total)
	local level, into = 0, total
	while into >= needed(level) do
		into -= needed(level)
		level += 1
	end
	return level, into / needed(level)
end

local function renderXP(instant)
	local level, progress = levelFromTotal(xpTotal)
	levelLabel.Text = level > 0 and tostring(level) or ""

	local goal = { Size = UDim2.new(progress, 0, 1, 0) }
	if instant then
		xpFill.Size = goal.Size
	else
		TweenService:Create(xpFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad), goal):Play()
	end

	if level > lastLevel then
		levelLabel.TextColor3 = Color3.new(1, 1, 1)
		TweenService:Create(levelLabel, TweenInfo.new(0.6), { TextColor3 = Color3.fromRGB(126, 252, 31) }):Play()
	end
	lastLevel = level
end

local function addXP(amount)
	amount = tonumber(amount)
	if not amount or amount <= 0 then return end
	xpTotal += amount
	renderXP()
end

local addXPEvent = ReplicatedStorage:FindFirstChild("MinecraftAddXP")
if not addXPEvent then
	addXPEvent = Instance.new("BindableEvent")
	addXPEvent.Name = "MinecraftAddXP"
	addXPEvent.Parent = ReplicatedStorage
end
addXPEvent.Event:Connect(addXP)

local orbFolder = Instance.new("Folder")
orbFolder.Name = "MinecraftXPOrbs"
orbFolder.Parent = workspace

local ORB_LIME, ORB_YELLOW = Color3.fromRGB(126, 252, 31), Color3.fromRGB(235, 255, 90)
local orbs = {}

local function spawnOrb(pos, value)
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * (0.35 + 0.1 * value)
	part.Material = Enum.Material.Neon
	part.Color = ORB_LIME
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Position = pos
	part.Parent = orbFolder

	table.insert(orbs, {
		part = part,
		value = value,
		born = os.clock(),
		phase = math.random() * 6,
		v = Vector3.new(math.random(-8, 8), math.random(14, 24), math.random(-8, 8)),
	})
end

local function spawnOrbs(pos, total)
	local remaining = total
	while remaining > 0 do
		local v = math.min(remaining, math.random(1, 3))
		remaining -= v
		spawnOrb(pos + Vector3.new(0, 1.5, 0), v)
	end
end

RunService.Heartbeat:Connect(function(dt)
	if #orbs == 0 then return end

	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local alive = root ~= nil and hum ~= nil and hum.Health > 0

	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { orbFolder }
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then table.insert(ignore, p.Character) end
	end
	rp.FilterDescendantsInstances = ignore

	local t = os.clock()
	for i = #orbs, 1, -1 do
		local o = orbs[i]
		local part = o.part
		local remove = false

		if not part.Parent or t - o.born > 60 then
			remove = true
		else
			local pos = part.Position
			local attracting = false

			if alive then
				local to = root.Position - pos
				local dist = to.Magnitude
				if dist <= ORB_ABSORB_RANGE then
					addXP(o.value)
					remove = true
				elseif dist <= ORB_ATTRACT_RANGE then
					attracting = true
					local speed = 16 + (ORB_ATTRACT_RANGE - dist) * 3
					o.v = o.v:Lerp(to.Unit * speed, math.min(1, dt * 8))
				end
			end

			if not remove then
				if not attracting then
					local fr = 1 - math.min(1, dt * 2)
					o.v = Vector3.new(o.v.X * fr, o.v.Y - 70 * dt, o.v.Z * fr)
				end

				local newPos = pos + o.v * dt
				if not attracting and o.v.Y <= 0 then
					local half = part.Size.Y / 2
					local hit = workspace:Raycast(pos, Vector3.new(0, -(half + math.abs(o.v.Y * dt) + 0.1), 0), rp)
					if hit then
						newPos = Vector3.new(newPos.X, hit.Position.Y + half, newPos.Z)
						o.v = Vector3.new(o.v.X * 0.5, 0, o.v.Z * 0.5)
					end
				end

				part.Position = newPos
				part.Color = ORB_LIME:Lerp(ORB_YELLOW, (math.sin(t * 8 + o.phase) + 1) / 2)
			end
		end

		if remove then
			part:Destroy()
			table.remove(orbs, i)
		end
	end
end)

local function creditKill(hum)
	local char = hum.Parent
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
		or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart")
	if not root then return end

	local tag = hum:FindFirstChild("creator")
	local credited = tag ~= nil and tag:IsA("ObjectValue") and tag.Value == player

	if not credited and CREDIT_NEARBY_KILLS and not Players:GetPlayerFromCharacter(char) then
		local myChar = player.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
		if myRoot and myHum and myHum.Health > 0
			and (myRoot.Position - root.Position).Magnitude <= NEARBY_RANGE then
			credited = true
		end
	end

	if credited then spawnOrbs(root.Position, KILL_XP) end
end

local hooked = setmetatable({}, { __mode = "k" })
local function hookHumanoid(hum)
	if hooked[hum] then return end
	hooked[hum] = true
	hum.Died:Connect(function()
		if hum.Parent and hum.Parent == player.Character then return end
		creditKill(hum)
	end)
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("Humanoid") then hookHumanoid(d) end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("Humanoid") then hookHumanoid(d) end
end)

renderXP(true)

local healthConns = {}
local function bindHumanoid(char)
	for _, c in ipairs(healthConns) do c:Disconnect() end
	table.clear(healthConns)

	local hum = char:WaitForChild("Humanoid")
	local function update()
		local frac = hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth) or 0
		currentHP = math.clamp(math.ceil(frac * 20 - 1e-4), 0, 20)
		renderHearts()
	end
	update()
	table.insert(healthConns, hum.HealthChanged:Connect(update))
	table.insert(healthConns, hum:GetPropertyChangedSignal("MaxHealth"):Connect(update))
	table.insert(healthConns, hum.Died:Connect(function()
		if RESET_XP_ON_DEATH then
			xpTotal = 0
			lastLevel = 0
			renderXP(true)
		end
	end))
end

local slots = {}
local shown = {}
local slotViewports = {}
local countConns = {}
local selected = 1
local popupToken = 0

local function getBackpack() return player:FindFirstChildOfClass("Backpack") end

local function ownsTool(tool)
	if not tool or not tool.Parent then return false end
	return tool.Parent == getBackpack() or tool.Parent == player.Character
end

local function showPopup(text)
	popupToken += 1
	local token = popupToken
	itemName.Text = text
	itemName.TextTransparency = 0
	itemName.TextStrokeTransparency = 0.4
	task.delay(1.5, function()
		if token ~= popupToken then return end
		TweenService:Create(itemName, TweenInfo.new(0.5), {
			TextTransparency = 1, TextStrokeTransparency = 1,
		}):Play()
	end)
end

local function buildViewport(tool, parent)
	if not tool:FindFirstChild("Handle") then return nil end

	local model = Instance.new("Model")
	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("BasePart") then
			local c = d:Clone()
			if c then
				for _, x in ipairs(c:GetDescendants()) do
					if x:IsA("LuaSourceContainer") or x:IsA("Sound") or x:IsA("JointInstance")
						or x:IsA("WeldConstraint") or x:IsA("Constraint") then
						x:Destroy()
					end
				end
				c.Anchored = true
				c.Parent = model
			end
		end
	end
	if #model:GetChildren() == 0 then model:Destroy() return nil end

	local vp = Instance.new("ViewportFrame")
	vp.Name = "Preview"
	vp.Position = UDim2.fromOffset(1, 2)
	vp.Size = UDim2.fromOffset(16, 16)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(190, 190, 190)
	vp.LightColor = Color3.new(1, 1, 1)
	vp.LightDirection = Vector3.new(-1, -1.2, -0.6)
	model.Parent = vp

	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	vp.CurrentCamera = cam
	cam.Parent = vp

	local cf, size = model:GetBoundingBox()
	local radius = math.max(size.Magnitude / 2, 0.5)
	local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.05
	local dir = Vector3.new(1, 0.7, 1).Unit
	cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)

	vp.Parent = parent
	return vp
end

local function clearSlotVisual(i)
	slotIcons[i].Visible = false
	slotLabels[i].Visible = false
	slotCounts[i].Text = ""
	if slotViewports[i] then slotViewports[i]:Destroy() slotViewports[i] = nil end
	if countConns[i] then countConns[i]:Disconnect() countConns[i] = nil end
end

local function drawSlot(i)
	local tool = slots[i]
	if shown[i] == tool then return end
	shown[i] = tool
	clearSlotVisual(i)
	if not tool then return end

	if tool.TextureId ~= "" then
		slotIcons[i].Image = tool.TextureId
		slotIcons[i].Visible = true
	else
		local vp = SHOW_3D_ICONS and buildViewport(tool, slotFrames[i]) or nil
		if vp then
			slotViewports[i] = vp
		else
			slotLabels[i].Text = tool.Name
			slotLabels[i].Visible = true
		end
	end

	local function updateCount()
		local c = tool:GetAttribute("Count")
		slotCounts[i].Text = (type(c) == "number" and c > 1) and tostring(c) or ""
	end
	updateCount()
	countConns[i] = tool:GetAttributeChangedSignal("Count"):Connect(updateCount)
end

local function refreshSlots()
	for i = 1, 9 do
		if slots[i] and not ownsTool(slots[i]) then slots[i] = nil end
	end

	local found = {}
	local bp = getBackpack()
	if bp then
		for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then table.insert(found, t) end end
	end
	if player.Character then
		for _, t in ipairs(player.Character:GetChildren()) do if t:IsA("Tool") then table.insert(found, t) end end
	end
	for _, tool in ipairs(found) do
		if not table.find(slots, tool) then
			for i = 1, 9 do
				if not slots[i] then slots[i] = tool break end
			end
		end
	end

	for i = 1, 9 do drawSlot(i) end
end

local function moveSelector()
	selector.Position = UDim2.fromOffset(20 * (selected - 1) - 1, -1)
end

local function selectSlot(i)
	selected = ((i - 1) % 9) + 1
	moveSelector()

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local tool = slots[selected]
	if tool and ownsTool(tool) then
		hum:EquipTool(tool)
		showPopup(tool.Name)
	else
		hum:UnequipTools()
	end
end

local function syncSelection()
	local char = player.Character
	local equipped = char and char:FindFirstChildOfClass("Tool")
	if equipped then
		local idx = table.find(slots, equipped)
		if idx and idx ~= selected then
			selected = idx
			moveSelector()
		end
	end
end

local keyMap = {
	[Enum.KeyCode.One] = 1,   [Enum.KeyCode.Two] = 2,   [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,  [Enum.KeyCode.Five] = 5,  [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8, [Enum.KeyCode.Nine] = 9,
}
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	local n = keyMap[input.KeyCode]
	if n then selectSlot(n) end
end)

for i, slot in ipairs(slotFrames) do
	slot.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			selectSlot(i)
		end
	end)
end

local function hookContainer(container)
	container.ChildAdded:Connect(function()
		refreshSlots()
		syncSelection()
	end)
	container.ChildRemoved:Connect(function()
		task.defer(refreshSlots)
	end)
end

local function onCharacter(char)
	bindHumanoid(char)
	hookContainer(char)
	refreshSlots()
	selected = 1
	moveSelector()
end

local function hookBackpack(bp)
	hookContainer(bp)
	refreshSlots()
end

hookBackpack(getBackpack() or player:WaitForChild("Backpack"))
player.ChildAdded:Connect(function(c)
	if c:IsA("Backpack") then
		table.clear(slots)
		hookBackpack(c)
	end
end)

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end

moveSelector()
renderHearts()

local IDLE_ID  = "rbxassetid://14618196485"
local IDLE_NUM = 14618196485

local NAME_IDS = {
    Animation1 = IDLE_ID, Animation2 = IDLE_ID,
    IdleAnim = IDLE_ID, IdleAnimation = IDLE_ID,
    WalkAnim = "rbxassetid://73935678087300",
    walk     = "rbxassetid://73935678087300",
    RunAnim  = "rbxassetid://86028285109536",
    run      = "rbxassetid://86028285109536",
    JumpAnim = "rbxassetid://128193557442109",
    jump     = "rbxassetid://128193557442109",
    FallAnim = "rbxassetid://105844133916862",
    fall     = "rbxassetid://105844133916862",
    ClimbAnim= "rbxassetid://119233460706851",
    climb    = "rbxassetid://119233460706851",
    SwimAnim = "rbxassetid://72103407662583",
    Swim     = "rbxassetid://72103407662583",
    SwimIdleAnim = "rbxassetid://85254089135641",
    SwimIdle     = "rbxassetid://85254089135641",
    Animation = IDLE_ID, mood = IDLE_ID,
    SitAnim = "rbxassetid://2506281703",
    WaveAnim = "rbxassetid://507770239",
    PointAnim = "rbxassetid://507770453",
    CheerAnim = "rbxassetid://507770677",
    LaughAnim = "rbxassetid://507770818",
    ToolNoneAnim = "rbxassetid://507768375",
    ToolSlashAnim = "rbxassetid://522635514",
    ToolLungeAnim = "rbxassetid://522638767",
    Animation3 = "rbxassetid://507772104",
}

local ORIG_TO_NEW = {
    [507766666]=IDLE_NUM, [507766951]=IDLE_NUM, [507766388]=IDLE_NUM,
    [507771019]=IDLE_NUM, [507771955]=IDLE_NUM, [14366558676]=IDLE_NUM,
    [10921230744]=IDLE_NUM, [10921232093]=IDLE_NUM, [10921233298]=IDLE_NUM,
    [105514975554898]=IDLE_NUM, [80873549026270]=IDLE_NUM,
    [80851859697313]=IDLE_NUM, [104771812454967]=IDLE_NUM,
    [133895673122280]=IDLE_NUM, [95740666194832]=IDLE_NUM,
    [73956906322787]=IDLE_NUM, [135783589150448]=IDLE_NUM,
    [10921144709]=IDLE_NUM, [10921145797]=IDLE_NUM,
    [10921272275]=IDLE_NUM, [10921273958]=IDLE_NUM,
    [10921101664]=IDLE_NUM, [10921102574]=IDLE_NUM,
    [112482859092761]=IDLE_NUM, [132594239160740]=IDLE_NUM,
    [17172918855]=IDLE_NUM, [17173014241]=IDLE_NUM,
    [10921301576]=IDLE_NUM, [10921302207]=IDLE_NUM,
    [96881713084822]=IDLE_NUM, [139108370441727]=IDLE_NUM,
    [125002802413463]=IDLE_NUM, [135832836685353]=IDLE_NUM,
    [121544739965950]=IDLE_NUM, [128694271964813]=IDLE_NUM,
    [10789316847]=IDLE_NUM,
    [507777826]=73935678087300, [913402848]=73935678087300,
    [10921244891]=73935678087300, [140535536297327]=73935678087300,
    [95648589784234]=73935678087300, [75672876125375]=73935678087300,
    [83682154404268]=73935678087300, [10921152678]=73935678087300,
    [82055796073914]=73935678087300, [10921283326]=73935678087300,
    [10921111375]=73935678087300, [74744724688769]=73935678087300,
    [104183910868678]=73935678087300, [10921312010]=73935678087300,
    [507767714]=86028285109536, [913376220]=86028285109536,
    [10921240218]=86028285109536, [131446204283995]=86028285109536,
    [86028285109536]=86028285109536,
    [87380318549717]=86028285109536, [77202164478294]=86028285109536,
    [86046103059668]=86028285109536, [10921148209]=86028285109536,
    [139569292637224]=86028285109536, [10921276116]=86028285109536,
    [10921104374]=86028285109536, [85678544705012]=86028285109536,
    [125903372570871]=86028285109536, [10921306285]=86028285109536,
    [507765000]=128193557442109, [87182355463462]=128193557442109,
    [10921242013]=128193557442109, [128193557442109]=128193557442109,
    [92575045784987]=128193557442109, [138733585730222]=128193557442109,
    [75710495467494]=128193557442109, [10921149743]=128193557442109,
    [73779824944177]=128193557442109, [10921279832]=128193557442109,
    [10921107367]=128193557442109, [100557689306064]=128193557442109,
    [140638376837248]=128193557442109, [10921308158]=128193557442109,
    [507767968]=105844133916862, [10921262864]=105844133916862,
    [10921241244]=105844133916862, [105844133916862]=105844133916862,
    [80112960361043]=105844133916862, [132339680071044]=105844133916862,
    [139409132577179]=105844133916862, [10921148939]=105844133916862,
    [85631336834768]=105844133916862, [10921278648]=105844133916862,
    [10921105765]=105844133916862, [129138704522700]=105844133916862,
    [126120967409342]=105844133916862, [119546655136861]=105844133916862,
    [507765644]=119233460706851, [10921229866]=119233460706851,
    [119233460706851]=119233460706851,
    [123809632266998]=119233460706851, [96819740672329]=119233460706851,
    [95003197762953]=119233460706851, [10921143404]=119233460706851,
    [71656254569935]=119233460706851, [10921271391]=119233460706851,
    [10921100400]=119233460706851, [85173178725730]=119233460706851,
    [137361418430790]=119233460706851, [78662570655863]=119233460706851,
    [507784897]=72103407662583, [913384386]=72103407662583,
    [10921243048]=72103407662583, [72103407662583]=72103407662583,
    [135891843854416]=72103407662583, [108048444170875]=72103407662583,
    [77815733207740]=72103407662583, [10921150788]=72103407662583,
    [130414392214126]=72103407662583, [10921281000]=72103407662583,
    [10921108971]=72103407662583, [112147015864553]=72103407662583,
    [113640205379270]=72103407662583, [98062782127543]=72103407662583,
    [507785072]=85254089135641, [913389285]=85254089135641,
    [10921244018]=85254089135641, [85254089135641]=85254089135641,
    [75796990153058]=85254089135641, [123807571445558]=85254089135641,
    [70471674713701]=85254089135641, [10921151661]=85254089135641,
    [116729337549524]=85254089135641, [10921281964]=85254089135641,
    [10921110146]=85254089135641, [79227379062727]=85254089135641,
    [120117541852015]=85254089135641, [98233901195014]=85254089135641,
    [2506281703]=2506281703, [507768133]=2506281703,
    [507770239]=507770239, [507770453]=507770453,
    [507770677]=507770677, [507770818]=507770818,
    [507768375]=507768375, [522635514]=522635514,
    [522638767]=522638767, [507772104]=507772104,
    [507776043]=507776043, [507776720]=507776720,
    [507776879]=507776879, [507777268]=507777268,
    [507777451]=507777451, [507777623]=507777623,
}

local function normalize(id)
    if not id then return id end
    local n = id:match("%d+")
    return n and ("rbxassetid://" .. n) or id
end
local function idFromUrl(id)
    if not id then return nil end
    local n = id:match("%d+")
    return n and tonumber(n) or nil
end
local function remapId(originalUrl)
    if not originalUrl then return nil end
    local oldNum = idFromUrl(originalUrl)
    if not oldNum then return nil end
    local newNum = ORIG_TO_NEW[oldNum]
    if not newNum then return nil end
    return "rbxassetid://" .. tostring(newNum)
end

local crouching = false
local originalWalkSpeed = 16
local CROUCH_SPEED = 6
local CROUCH_KEY = Enum.KeyCode.LeftControl
local cKeyDown = false
local ready = false

local function getHumanoid()
    local char = LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end
local function getAnimator()
    local char = LP.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    return humanoid:FindFirstChildOfClass("Animator")
end

CAS:BindActionAtPriority("FusedCrouchBind", function(_, state)
    if state == Enum.UserInputState.Begin then cKeyDown = true
    elseif state == Enum.UserInputState.End then cKeyDown = false end
    return Enum.ContextActionResult.Pass
end, false, 2000000, CROUCH_KEY)

local function setCrouch(on)
    local hum = getHumanoid()
    if not hum then return end
    if on then
        if not crouching then
            originalWalkSpeed = hum.WalkSpeed
            crouching = true
        end
        hum.WalkSpeed = CROUCH_SPEED
    else
        if crouching then crouching = false end
        if hum.WalkSpeed == CROUCH_SPEED then
            hum.WalkSpeed = originalWalkSpeed ~= CROUCH_SPEED and originalWalkSpeed or 16
        end
    end
end

RunService.Heartbeat:Connect(function()
    local hum = getHumanoid()
    if not hum then return end
    local down = cKeyDown or UIS:IsKeyDown(CROUCH_KEY)
    if down then
        if not crouching then setCrouch(true) end
        if hum.WalkSpeed ~= CROUCH_SPEED then hum.WalkSpeed = CROUCH_SPEED end
    else
        if crouching then setCrouch(false) end
    end
end)

local function applyAnimToObj(obj)
    if not obj:IsA("Animation") then return false end
    if crouching and (obj.Name == "RunAnim" or obj.Name == "run"
                      or obj.Name == "WalkAnim" or obj.Name == "walk") then
        local walkId = normalize(NAME_IDS.WalkAnim)
        if obj.AnimationId ~= walkId then
            obj.AnimationId = walkId
            return true
        end
        return false
    end
    local nameId = NAME_IDS[obj.Name]
    if nameId then
        local want = normalize(nameId)
        if obj.AnimationId ~= want then
            obj.AnimationId = want
            return true
        end
        return false
    end
    local mapped = remapId(obj.AnimationId)
    if mapped and obj.AnimationId ~= mapped then
        obj.AnimationId = mapped
        return true
    end
    return false
end

local function hookCharacter(char)
    if not char then return end
    char.DescendantAdded:Connect(function(obj)
        if obj:IsA("Animation") then
            task.defer(applyAnimToObj, obj)
        end
    end)
end

local function applyAnims()
    local char = LP.Character
    if not char then return 0 end
    local n = 0
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Animation") then
            if applyAnimToObj(obj) then n += 1 end
        end
    end
    return n
end

local function forceRestartTracks()
    local animator = getAnimator()
    if not animator then return end
    local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
    if not ok or not tracks then return end
    for _, tr in ipairs(tracks) do
        pcall(function()
            local anim = tr.Animation
            if anim then applyAnimToObj(anim) end
        end)
    end
end

local function reloadAnimate()
    local char = LP.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local c = animate:Clone()
    animate:Destroy()
    c.Parent = char
end

local MESHES = {
    ["Head"]="rbxassetid://14685555797",
    ["UpperTorso"]="rbxassetid://14976210306",
    ["LowerTorso"]="rbxassetid://14976210546",
    ["LeftUpperArm"]="rbxassetid://14976210274",
    ["LeftLowerArm"]="rbxassetid://14976210491",
    ["LeftHand"]="rbxassetid://14976210503",
    ["RightUpperArm"]="rbxassetid://14976210272",
    ["RightLowerArm"]="rbxassetid://14976210506",
    ["RightHand"]="rbxassetid://14976210528",
    ["LeftUpperLeg"]="rbxassetid://14900058211",
    ["LeftLowerLeg"]="rbxassetid://14900058374",
    ["LeftFoot"]="rbxassetid://14900058391",
    ["RightUpperLeg"]="rbxassetid://14900058189",
    ["RightLowerLeg"]="rbxassetid://14900058388",
    ["RightFoot"]="rbxassetid://14900058386",
}

local SIZES = {
    ["Head"]        = Vector3.new(0.66, 0.9, 0.65),
    ["UpperTorso"]  = Vector3.new(1.36, 1.67, 0.70),
    ["LowerTorso"]  = Vector3.new(1.39, 0.32, 0.70),
    ["LeftUpperArm"]= Vector3.new(0.55, 1.00, 0.55),
    ["LeftLowerArm"]= Vector3.new(0.55, 0.70, 0.55),
    ["LeftHand"]    = Vector3.new(0.55, 0.30, 0.55),
    ["RightUpperArm"]=Vector3.new(0.55, 1.00, 0.55),
    ["RightLowerArm"]=Vector3.new(0.55, 0.70, 0.55),
    ["RightHand"]   = Vector3.new(0.55, 0.30, 0.55),
    ["LeftUpperLeg"]= Vector3.new(0.58, 1.08, 0.58),
    ["LeftLowerLeg"]= Vector3.new(0.58, 1.46, 0.58),
    ["LeftFoot"]    = Vector3.new(0.60, 0.29, 0.62),
    ["RightUpperLeg"]=Vector3.new(0.58, 1.08, 0.58),
    ["RightLowerLeg"]=Vector3.new(0.58, 1.46, 0.58),
    ["RightFoot"]   = Vector3.new(0.60, 0.29, 0.62),
}

local R15_JOINTS = {
    {"Root","HumanoidRootPart","LowerTorso","RootRigAttachment","RootRigAttachment"},
    {"Waist","LowerTorso","UpperTorso","WaistRigAttachment","WaistRigAttachment"},
    {"Neck","UpperTorso","Head","NeckRigAttachment","NeckRigAttachment"},
    {"LeftShoulder","UpperTorso","LeftUpperArm","LeftShoulderRigAttachment","LeftShoulderRigAttachment"},
    {"LeftElbow","LeftUpperArm","LeftLowerArm","LeftElbowRigAttachment","LeftElbowRigAttachment"},
    {"LeftWrist","LeftLowerArm","LeftHand","LeftWristRigAttachment","LeftWristRigAttachment"},
    {"RightShoulder","UpperTorso","RightUpperArm","RightShoulderRigAttachment","RightShoulderRigAttachment"},
    {"RightElbow","RightUpperArm","RightLowerArm","RightElbowRigAttachment","RightElbowRigAttachment"},
    {"RightWrist","RightLowerArm","RightHand","RightWristRigAttachment","RightWristRigAttachment"},
    {"LeftHip","LowerTorso","LeftUpperLeg","LeftHipRigAttachment","LeftHipRigAttachment"},
    {"LeftKnee","LeftUpperLeg","LeftLowerLeg","LeftKneeRigAttachment","LeftKneeRigAttachment"},
    {"LeftAnkle","LeftLowerLeg","LeftFoot","LeftAnkleRigAttachment","LeftAnkleRigAttachment"},
    {"RightHip","LowerTorso","RightUpperLeg","RightHipRigAttachment","RightHipRigAttachment"},
    {"RightKnee","RightUpperLeg","RightLowerLeg","RightKneeRigAttachment","RightKneeRigAttachment"},
    {"RightAnkle","RightLowerLeg","RightFoot","RightAnkleRigAttachment","RightAnkleRigAttachment"},
}

local COLORS = {
    Head="111111",
    Torso="f8f8f8",
    LeftArm="f8f8f8", RightArm="f8f8f8",
    LeftLeg="f8f8f8", RightLeg="f8f8f8",
}
local CLOTHING = {
    Shirt="http://www.roblox.com/asset/?id=81756336444461",
    Pants="http://www.roblox.com/asset/?id=15090597911",
}
local ACC_MESH="rbxassetid://107491623328425"
local ACC_TEX="rbxassetid://114394272546230"
local ACC_SIZE=Vector3.new(1.2, 1.0, 0.95)
local ACC_ROT=CFrame.Angles(0, math.pi, 0)
local ACC_Y = 0

local function hex3(h)
    h = h:gsub("#", "")
    return Color3.fromRGB(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16))
end

local ATT_FRACTIONS = {
    HumanoidRootPart = { RootRigAttachment = Vector3.new(0, -1, 0) },
    LowerTorso = {
        RootRigAttachment     = Vector3.new(0, 1, 0),
        WaistRigAttachment    = Vector3.new(0, 1, 0),
        LeftHipRigAttachment  = Vector3.new(-0.40, -1, 0),
        RightHipRigAttachment = Vector3.new(0.40, -1, 0),
    },
    UpperTorso = {
        WaistRigAttachment         = Vector3.new(0, -1, 0),
        NeckRigAttachment          = Vector3.new(0, 1, 0),
        LeftShoulderRigAttachment  = Vector3.new(-1, 0.5, 0),
        RightShoulderRigAttachment = Vector3.new(1, 0.5, 0),
    },
    Head = { NeckRigAttachment = Vector3.new(0, -1, 0) },
    LeftUpperArm  = { LeftShoulderRigAttachment = Vector3.new(0, 1, 0), LeftElbowRigAttachment = Vector3.new(0, -1, 0) },
    LeftLowerArm  = { LeftElbowRigAttachment = Vector3.new(0, 1, 0), LeftWristRigAttachment = Vector3.new(0, -1, 0) },
    LeftHand      = { LeftWristRigAttachment = Vector3.new(0, 1, 0) },
    RightUpperArm = { RightShoulderRigAttachment = Vector3.new(0, 1, 0), RightElbowRigAttachment = Vector3.new(0, -1, 0) },
    RightLowerArm = { RightElbowRigAttachment = Vector3.new(0, 1, 0), RightWristRigAttachment = Vector3.new(0, -1, 0) },
    RightHand     = { RightWristRigAttachment = Vector3.new(0, 1, 0) },
    LeftUpperLeg  = { LeftHipRigAttachment = Vector3.new(0, 1, 0), LeftKneeRigAttachment = Vector3.new(0, -1, 0) },
    LeftLowerLeg  = { LeftKneeRigAttachment = Vector3.new(0, 1, 0), LeftAnkleRigAttachment = Vector3.new(0, -1, 0) },
    LeftFoot      = { LeftAnkleRigAttachment = Vector3.new(0, 1, 0) },
    RightUpperLeg = { RightHipRigAttachment = Vector3.new(0, 1, 0), RightKneeRigAttachment = Vector3.new(0, -1, 0) },
    RightLowerLeg = { RightKneeRigAttachment = Vector3.new(0, 1, 0), RightAnkleRigAttachment = Vector3.new(0, -1, 0) },
    RightFoot     = { RightAnkleRigAttachment = Vector3.new(0, 1, 0) },
}

local function insetFor(partName, attName)
    if attName:find("Waist") then
        return partName == "UpperTorso" and 0.3 or 0
    elseif attName:find("Hip") then
        return partName == "LowerTorso" and 0.05 or 0.45
    elseif attName:find("Knee") then
        return 0.22
    elseif attName:find("Ankle") then
        return 0.10
    elseif attName:find("Elbow") or attName:find("Wrist") then
        return 0.10
    end
    return 0
end

local ARM_RAISE = 0.45
local ARM_OUT   = 0.05

local function updateAttachments(character)
    for partName, atts in pairs(ATT_FRACTIONS) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local half = part.Size * 0.5
            for attName, frac in pairs(atts) do
                local att = part:FindFirstChild(attName)
                if att and att:IsA("Attachment") then
                    local x = frac.X * half.X
                    local y = frac.Y * half.Y

                    if partName == "UpperTorso" and attName:find("Shoulder") then
                        y = y + ARM_RAISE
                        x = x + (frac.X > 0 and ARM_OUT or -ARM_OUT)
                    end

                    local inset = math.min(insetFor(partName, attName), half.Y * 0.6)
                    if math.abs(frac.Y) == 1 then
                        y = y - (frac.Y > 0 and inset or -inset)
                    end

                    local want = CFrame.new(x, y, frac.Z * half.Z)
                    if (att.CFrame.Position - want.Position).Magnitude > 1e-4 or att.CFrame.Rotation ~= want.Rotation then
                        att.CFrame = want
                    end
                end
            end
        end
    end
end

local function fixJoints(character)
    for _, j in ipairs(R15_JOINTS) do
        local motorName, p0Name, p1Name, a0Name, a1Name = j[1], j[2], j[3], j[4], j[5]
        if motorName ~= "LeftElbow" and motorName ~= "RightElbow" then
            local p0 = character:FindFirstChild(p0Name)
            local p1 = character:FindFirstChild(p1Name)
            if p0 and p1 then
                local a0 = p0:FindFirstChild(a0Name)
                local a1 = p1:FindFirstChild(a1Name)
                if a0 and a1 then
                    local motor
                    for _, c in ipairs(p0:GetChildren()) do
                        if c:IsA("Motor6D") and c.Name == motorName then motor = c break end
                    end
                    if not motor then
                        motor = Instance.new("Motor6D")
                        motor.Name = motorName
                        motor.Part0 = p0
                        motor.Part1 = p1
                        motor.Parent = p0
                    end
                    if motor.Part0 ~= p0 then motor.Part0 = p0 end
                    if motor.Part1 ~= p1 then motor.Part1 = p1 end
                    if motor.Parent ~= p0 then motor.Parent = p0 end
                    if motor.C0 ~= a0.CFrame then motor.C0 = a0.CFrame end
                    if motor.C1 ~= a1.CFrame then motor.C1 = a1.CFrame end
                end
            end
        end
    end
end

local function applyBody(character)
    for name, meshId in pairs(MESHES) do
        local p = character:FindFirstChild(name)
        if p and p:IsA("MeshPart") then
            if p.MeshId ~= meshId then p.MeshId = meshId end
            local s = SIZES[name]
            if s and p.Size ~= s then p.Size = s end
        end
    end

    local bc = character:FindFirstChildOfClass("BodyColors")
    if not bc then
        bc = Instance.new("BodyColors")
        bc.Parent = character
    end
    local target = {
        head = hex3(COLORS.Head),
        torso = hex3(COLORS.Torso),
        la = hex3(COLORS.LeftArm), ra = hex3(COLORS.RightArm),
        ll = hex3(COLORS.LeftLeg), rl = hex3(COLORS.RightLeg),
    }
    if bc.HeadColor3 ~= target.head then bc.HeadColor3 = target.head end
    if bc.TorsoColor3 ~= target.torso then bc.TorsoColor3 = target.torso end
    if bc.LeftArmColor3 ~= target.la then bc.LeftArmColor3 = target.la end
    if bc.RightArmColor3 ~= target.ra then bc.RightArmColor3 = target.ra end
    if bc.LeftLegColor3 ~= target.ll then bc.LeftLegColor3 = target.ll end
    if bc.RightLegColor3 ~= target.rl then bc.RightLegColor3 = target.rl end

    local head = character:FindFirstChild("Head")
    if head and head.Transparency ~= 1 then head.Transparency = 1 end
end

local function applyClothing(character)
    for class, template in pairs(CLOTHING) do
        local e = character:FindFirstChildOfClass(class)
        if not e then
            local o = Instance.new(class)
            o.Name = class
            if class == "Shirt" then o.ShirtTemplate = template
            elseif class == "Pants" then o.PantsTemplate = template end
            o.Parent = character
        else
            if class == "Shirt" and e.ShirtTemplate ~= template then e.ShirtTemplate = template end
            if class == "Pants" and e.PantsTemplate ~= template then e.PantsTemplate = template end
        end
    end
end

local function applyAccessory(character)
    local chosen
    for _, a in ipairs(character:GetChildren()) do
        if a:IsA("Accessory") then
            if not chosen then chosen = a
            else
                local h = a:FindFirstChild("Handle")
                if h and h.Transparency ~= 1 then h.Transparency = 1 end
            end
        end
    end
    if not chosen then return end
    local handle = chosen:FindFirstChild("Handle")
    local head = character:FindFirstChild("Head")
    if not handle or not head then return end
    if handle.MeshId ~= ACC_MESH then handle.MeshId = ACC_MESH end
    if handle.Size ~= ACC_SIZE then handle.Size = ACC_SIZE end
    pcall(function() if handle.TextureID ~= ACC_TEX then handle.TextureID = ACC_TEX end end)
    if handle.Color ~= Color3.fromRGB(163,162,165) then handle.Color = Color3.fromRGB(163,162,165) end
    if handle.Transparency ~= 0 then handle.Transparency = 0 end
    if handle.CanCollide then handle.CanCollide = false end
    if not handle.Massless then handle.Massless = true end

    local hasWeld = false
    for _, c in ipairs(handle:GetChildren()) do
        if c:IsA("Weld") and c.Part0 == head and c.Part1 == handle then
            hasWeld = true
            local wantC0 = CFrame.new(0, ACC_Y, 0)
            if c.C0 ~= wantC0 then c.C0 = wantC0 end
            break
        end
    end
    if not hasWeld then
        for _, c in ipairs(handle:GetChildren()) do
            if c:IsA("Weld") or c:IsA("WeldConstraint") or c:IsA("RigidConstraint") or c:IsA("Motor6D") then
                c:Destroy()
            end
        end
        local w = Instance.new("Weld")
        w.Part0 = head
        w.Part1 = handle
        w.C0 = CFrame.new(0, ACC_Y, 0)
        w.C1 = ACC_ROT
        w.Parent = handle
    end
end

local elbowMotors = {}
local function weldElbow(upperName, lowerName, motorName, attName)
    local char = LP.Character
    if not char then return end
    local upper = char:FindFirstChild(upperName)
    local lower = char:FindFirstChild(lowerName)
    if not upper or not lower then return end

    local weldName = "ElbowWeld_" .. motorName
    local existing = upper:FindFirstChild(weldName)
    local upperAtt = upper:FindFirstChild(attName)
    local lowerAtt = lower:FindFirstChild(attName)
    if not upperAtt or not lowerAtt then return end

    if existing and existing:IsA("Weld") then
        if existing.Part0 ~= upper then existing.Part0 = upper end
        if existing.Part1 ~= lower then existing.Part1 = lower end
        if existing.Parent ~= upper then existing.Parent = upper end
        if existing.C0 ~= upperAtt.CFrame then existing.C0 = upperAtt.CFrame end
        if existing.C1 ~= lowerAtt.CFrame then existing.C1 = lowerAtt.CFrame end
        return
    end

    local motor
    for _, c in ipairs(upper:GetChildren()) do
        if c:IsA("Motor6D") and c.Name == motorName then motor = c break end
    end
    if motor then
        if not elbowMotors[motorName] then
            elbowMotors[motorName] = { Name = motor.Name, Part0 = motor.Part0, Part1 = motor.Part1, C0 = motor.C0, C1 = motor.C1 }
        end
        motor:Destroy()
    end

    local w = Instance.new("Weld")
    w.Name = weldName
    w.Part0 = upper
    w.Part1 = lower
    w.C0 = upperAtt.CFrame
    w.C1 = lowerAtt.CFrame
    w.Parent = upper
end

local function lockElbows()
    weldElbow("LeftUpperArm", "LeftLowerArm", "LeftElbow", "LeftElbowRigAttachment")
    weldElbow("RightUpperArm", "RightLowerArm", "RightElbow", "RightElbowRigAttachment")
end

local function onCharacterBody(char)
    ready = false
    char:WaitForChild("HumanoidRootPart", 10)
    for name in pairs(MESHES) do
        char:WaitForChild(name, 10)
    end
    ready = true

    hookCharacter(char)
    task.wait(0.5)
    applyAnims()
    reloadAnimate()
    task.wait(0.1)
    applyAnims()
    forceRestartTracks()
    pcall(function()
        applyBody(char)
        updateAttachments(char)
        fixJoints(char)
        applyClothing(char)
        applyAccessory(char)
        lockElbows()
    end)
end

if LP.Character then task.spawn(onCharacterBody, LP.Character) end
LP.CharacterAdded:Connect(function(c)
    ready = false
    elbowMotors = {}
    crouching = false
    onCharacterBody(c)
end)

local bodyFrame = 0
RunService.Heartbeat:Connect(function()
    bodyFrame += 1
    local char = LP.Character
    if char and ready then
        if bodyFrame % 2 == 0 then
            applyBody(char)
            updateAttachments(char)
            fixJoints(char)
            applyClothing(char)
            applyAccessory(char)
        end
        lockElbows()
        for _, mn in ipairs({"LeftElbow", "RightElbow"}) do
            local upperName = mn == "LeftElbow" and "LeftUpperArm" or "RightUpperArm"
            local lowerName = mn == "LeftElbow" and "LeftLowerArm" or "RightLowerArm"
            local upper = char:FindFirstChild(upperName)
            local lower = char:FindFirstChild(lowerName)
            if upper and lower then
                local w = upper:FindFirstChild("ElbowWeld_" .. mn)
                local ua = upper:FindFirstChild(mn .. "RigAttachment")
                local la = lower:FindFirstChild(mn .. "RigAttachment")
                if w and ua and la then
                    if w.C0 ~= ua.CFrame then w.C0 = ua.CFrame end
                    if w.C1 ~= la.CFrame then w.C1 = la.CFrame end
                end
            end
        end
    end
    if bodyFrame % 3 == 0 then
        applyAnims()
        forceRestartTracks()
    end
end)

LP.DevEnableMouseLock = false
LP.CharacterAdded:Connect(function()
    task.wait(0.2)
    pcall(function() LP.DevEnableMouseLock = false end)
end)

local HIT_ID   = "rbxassetid://97516072729255"
local SLASH_ID = "rbxassetid://110024326124687"

local MESH_ID    = "rbxassetid://103090911005480"
local TEXTURE_ID = "rbxassetid://73069823328929"
local MESH_SCALE = Vector3.new(0.6, 4.9538, 0.1696)

local REPLACEMENT_ID = "rbxassetid://522635514"
local SWAP_IDS = {
    ["rbxassetid://90613325915364"] = true,
    ["http://www.roblox.com/asset/?id=90613325915364"] = true,
    ["90613325915364"] = true,
}

local VIEWMODEL_BASE  = CFrame.new(0.8, -1.4, -4.5) * CFrame.Angles(math.rad(0), math.rad(-15), math.rad(-10))
local VIEWMODEL_SWING = CFrame.new(0.3, -0.8, -3.2) * CFrame.Angles(math.rad(-40), math.rad(-10), math.rad(35))

local SWING_DURATION = 0.35

local RENDER_BIND_NAME = "BatViewModelRender"
local FP_ENTER_DIST = 1.1
local FP_EXIT_DIST  = 2.2

local camera = Workspace.CurrentCamera
local replacementAnim = Instance.new("Animation")
replacementAnim.AnimationId = REPLACEMENT_ID

local batState = {
    character = nil,
    bat = nil,
    handle = nil,
    connections = {},
    batAnims = {},
    swappedTracks = {},
    viewModel = nil,
    thirdFake = nil,
    lastFP = nil,
    fpSwingStart = -math.huge,
    tpSwingStart = -math.huge,
    lastSwing = -math.huge,
    cursorGui = nil,
    crosshair = nil,
}

local function batClearConnections()
    for _, c in ipairs(batState.connections) do
        pcall(function() c:Disconnect() end)
    end
    batState.connections = {}
end

local function destroyViewModel()
    if batState.viewModel then pcall(function() batState.viewModel:Destroy() end); batState.viewModel = nil end
end

local function destroyThirdFake()
    if batState.thirdFake then pcall(function() batState.thirdFake:Destroy() end); batState.thirdFake = nil end
end

local function destroyCrosshair()
    if batState.cursorGui then
        pcall(function() batState.cursorGui:Destroy() end)
        batState.cursorGui = nil
        batState.crosshair = nil
    end
    pcall(function() UIS.MouseIconEnabled = true end)
end

local function forceSounds()
    if not batState.bat then return end
    local hit = batState.bat:FindFirstChild("Hit")
    if hit and hit:IsA("Sound") and hit.SoundId ~= HIT_ID then hit.SoundId = HIT_ID end
    local slash = batState.bat:FindFirstChild("Slash")
    if slash and slash:IsA("Sound") and slash.SoundId ~= SLASH_ID then slash.SoundId = SLASH_ID end
end

local function isBatAnim(track)
    local a = track.Animation
    if not a then return false end
    if batState.batAnims[a] then return true end
    if SWAP_IDS[a.AnimationId] then return true end
    local num = string.match(a.AnimationId, "%d+")
    if num and SWAP_IDS[num] then return true end
    return false
end

local function isFirstPerson()
    if not camera or not batState.character then return false end
    local head = batState.character:FindFirstChild("Head")
    if not head then return false end
    local d = (camera.CFrame.Position - head.Position).Magnitude
    if batState.lastFP == true then
        return d < FP_EXIT_DIST
    end
    return d < FP_ENTER_DIST
end

local function isShiftLock()
    return UIS.MouseBehavior == Enum.MouseBehavior.LockCenter
        or UIS.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition
end

local function hideRealBat()
    if not batState.bat or not batState.bat.Parent then return end
    if batState.bat.Parent ~= batState.character then return end

    for _, d in ipairs(batState.bat:GetDescendants()) do
        if d:IsA("BasePart") then
            if d.LocalTransparencyModifier ~= 1 then
                d.LocalTransparencyModifier = 1
            end
        end
    end
    if batState.handle and batState.handle.LocalTransparencyModifier ~= 1 then
        batState.handle.LocalTransparencyModifier = 1
    end
end

local function stripJoints(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("JointInstance") or d:IsA("Constraint") then
            pcall(function() d:Destroy() end)
        end
    end
end

local function buildCrosshair()
    destroyCrosshair()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MC_Crosshair"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.Parent = LP:WaitForChild("PlayerGui")

    local holder = Instance.new("Frame")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(20, 20)
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Parent = gui

    local h = Instance.new("Frame")
    h.BackgroundColor3 = Color3.new(1, 1, 1)
    h.BorderSizePixel = 0
    h.Size = UDim2.fromOffset(18, 2)
    h.Position = UDim2.fromScale(0.5, 0.5)
    h.AnchorPoint = Vector2.new(0.5, 0.5)
    h.Parent = holder

    local v = Instance.new("Frame")
    v.BackgroundColor3 = Color3.new(1, 1, 1)
    v.BorderSizePixel = 0
    v.Size = UDim2.fromOffset(2, 18)
    v.Position = UDim2.fromScale(0.5, 0.5)
    v.AnchorPoint = Vector2.new(0.5, 0.5)
    v.Parent = holder

    batState.cursorGui = gui
    batState.crosshair = holder

    local function update()
        if not batState.crosshair or not batState.crosshair.Parent then return end
        pcall(function() UIS.MouseIconEnabled = false end)
        if isShiftLock() then
            batState.crosshair.Position = UDim2.fromScale(0.5, 0.5)
        else
            local m = UIS:GetMouseLocation()
            batState.crosshair.Position = UDim2.fromOffset(m.X, m.Y)
        end
    end

    table.insert(batState.connections, RunService.RenderStepped:Connect(update))
    update()
end

local function buildThirdFake()
    destroyThirdFake()
    if not batState.handle or not batState.character then return end
    local torso = batState.character:FindFirstChild("UpperTorso")
        or batState.character:FindFirstChild("Torso")
        or batState.character:FindFirstChild("HumanoidRootPart")
    if not torso then return end

    local fake = batState.handle:Clone()
    fake.Name = "BatThirdPersonFake"
    stripJoints(fake)
    fake.CanCollide = false
    fake.CanQuery = false
    fake.CanTouch = false
    fake.Massless = true
    fake.Anchored = true
    fake.LocalTransparencyModifier = 0
    fake.CFrame = batState.handle.CFrame * CFrame.new(0, -1, 0)

    fake.Parent = batState.character
    batState.thirdFake = fake
end

local function buildViewModel()
    destroyViewModel()
    if not batState.handle then return end
    local vm = batState.handle:Clone()
    vm.Name = "BatViewModel"
    stripJoints(vm)
    vm.Anchored = true
    vm.CanCollide = false
    vm.CanQuery = false
    vm.CanTouch = false
    vm.Massless = true
    vm.LocalTransparencyModifier = 0
    vm.Parent = camera
    batState.viewModel = vm
end

local function applyViewModel()
    local fp = isFirstPerson()
    if fp == batState.lastFP then return end
    batState.lastFP = fp
    if not batState.handle then return end
    hideRealBat()
    if fp then
        destroyThirdFake()
        buildViewModel()
    else
        destroyViewModel()
        buildThirdFake()
    end
end

local function batSwing()
    local now = tick()
    if now - batState.lastSwing < 0.75 then return end
    batState.lastSwing = now

    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if animator then
            local nt = animator:LoadAnimation(replacementAnim)
            nt.Priority = Enum.AnimationPriority.Action
            nt:Play(0, 1, 1)
        end
    end

    batState.fpSwingStart = now - 0.1
    batState.tpSwingStart = now - 0.1
end

local function onRender()
    if not batState.bat or batState.bat.Parent ~= batState.character then
        destroyViewModel()
        destroyThirdFake()
        return
    end
    applyViewModel()
    hideRealBat()

    local now = tick()

    if batState.viewModel then
        local t = math.clamp((now - batState.fpSwingStart) / SWING_DURATION, 0, 1)
        local cf
        if t < 0.5 then
            cf = VIEWMODEL_BASE:Lerp(VIEWMODEL_SWING, t * 2)
        else
            cf = VIEWMODEL_SWING:Lerp(VIEWMODEL_BASE, (t - 0.5) * 2)
        end
        batState.viewModel.CFrame = camera.CFrame * cf
    end

    if batState.thirdFake and batState.thirdFake.Parent and batState.handle then
        local t = math.clamp((now - batState.tpSwingStart) / SWING_DURATION, 0, 1)
        local swingCf
        if t < 0.5 then
            swingCf = CFrame.new(0, -1, -0.15):Lerp(CFrame.new(0, -1.1, -1.4) * CFrame.Angles(math.rad(-70), 0, math.rad(20)), t * 2)
        else
            swingCf = (CFrame.new(0, -1.1, -1.4) * CFrame.Angles(math.rad(-70), 0, math.rad(20))):Lerp(CFrame.new(0, -1, -0.15), (t - 0.5) * 2)
        end
        batState.thirdFake.CFrame = batState.handle.CFrame * swingCf
    end
end

local function batSetup()
    pcall(function() RunService:UnbindFromRenderStep(RENDER_BIND_NAME) end)
    batClearConnections()
    destroyViewModel()
    destroyThirdFake()
    destroyCrosshair()

    batState.batAnims = {}
    batState.swappedTracks = {}
    batState.lastFP = nil
    batState.fpSwingStart = -math.huge
    batState.tpSwingStart = -math.huge
    batState.lastSwing = -math.huge

    local character = LP.Character or LP.CharacterAdded:Wait()
    task.wait()
    batState.character = character

    local bat
    for _, c in ipairs(character:GetChildren()) do
        if c:IsA("Tool") and c.Name:lower():find("bat") then
            bat = c; break
        end
    end
    if not bat then return end
    batState.bat = bat

    local handle = bat:FindFirstChild("Handle") or bat:FindFirstChildWhichIsA("BasePart")
    if not handle then return end
    batState.handle = handle

    table.insert(batState.connections, bat.Unequipped:Connect(function()
        destroyViewModel()
        destroyThirdFake()
        if batState.handle then
            for _, d in ipairs(batState.bat:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.LocalTransparencyModifier = 0
                end
            end
            batState.handle.LocalTransparencyModifier = 0
        end
    end))

    table.insert(batState.connections, bat.Equipped:Connect(function()
        batState.lastFP = nil
    end))

    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if not mesh and not handle:IsA("MeshPart") then
        mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.Parent = handle
    end
    if mesh then
        mesh.MeshId = MESH_ID
        mesh.TextureId = TEXTURE_ID
        mesh.Scale = MESH_SCALE
    elseif handle:IsA("MeshPart") then
        handle.MeshId = MESH_ID
        handle.TextureID = TEXTURE_ID
        handle.Size = MESH_SCALE
    end

    for _, d in ipairs(bat:GetDescendants()) do
        if d:IsA("Animation") then batState.batAnims[d] = true end
    end
    table.insert(batState.connections, bat.DescendantAdded:Connect(function(d)
        if d:IsA("Animation") then batState.batAnims[d] = true end
    end))
    table.insert(batState.connections, bat.Activated:Connect(batSwing))

    table.insert(batState.connections, RunService.Heartbeat:Connect(function()
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator"); if not animator then return end
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if isBatAnim(track) and not batState.swappedTracks[track] then
                batState.swappedTracks[track] = true
                track:Stop(0)
                task.defer(function() pcall(function() track:Destroy() end) end)
                local nt = animator:LoadAnimation(replacementAnim)
                nt.Priority = Enum.AnimationPriority.Action
                nt:Play(0, 1, 1)
            end
        end
        for t in pairs(batState.swappedTracks) do
            local still = false
            for _, x in ipairs(animator:GetPlayingAnimationTracks()) do
                if x == t then still = true break end
            end
            if not still then batState.swappedTracks[t] = nil end
        end
    end))

    RunService:BindToRenderStep(RENDER_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, onRender)

    buildCrosshair()

    task.spawn(function()
        while batState.bat and batState.bat.Parent do
            forceSounds()
            hideRealBat()
            task.wait()
        end
    end)
    forceSounds()
    hideRealBat()
end

LP.CharacterAdded:Connect(function()
    task.wait(1)
    pcall(batSetup)
end)
task.spawn(function()
    while true do
        task.wait(2)
        if not batState.bat or not batState.bat.Parent then
            local char = LP.Character
            if char then
                for _, c in ipairs(char:GetChildren()) do
                    if c:IsA("Tool") and c.Name:lower():find("bat") then
                        pcall(batSetup)
                        break
                    end
                end
            end
        end
    end
end)

pcall(batSetup)

do
    local Terrain = Workspace.Terrain

    local ENABLE_DAY_NIGHT_CYCLE = true
    local DAY_LENGTH_SECONDS = 1200
    local START_CLOCK_TIME = 8
    local SKY_RAY_LENGTH = 512
    local MIN_CAVE_LIGHT = 0.85

    local parked = {}
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
            table.insert(parked, { inst = child, parent = Lighting })
        end
    end
    for _, child in ipairs(Terrain:GetChildren()) do
        if child:IsA("Clouds") then
            table.insert(parked, { inst = child, parent = Terrain })
        end
    end

    local editableImages = {}

    local function makeSquareTexture(size, painter)
        local ok, img = pcall(function()
            return AssetService:CreateEditableImage({ Size = Vector2.new(size, size) })
        end)
        if not ok or not img then return nil end

        local buf = buffer.create(size * size * 4)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local r, g, b = painter(x, y)
                local o = (y * size + x) * 4
                buffer.writeu8(buf, o, r)
                buffer.writeu8(buf, o + 1, g)
                buffer.writeu8(buf, o + 2, b)
                buffer.writeu8(buf, o + 3, 255)
            end
        end

        local wrote = pcall(function()
            img:WritePixelsBuffer(Vector2.new(0, 0), Vector2.new(size, size), buf)
        end)
        if not wrote then
            pcall(function() img:Destroy() end)
            return nil
        end
        table.insert(editableImages, img)
        return img
    end

    local function paintSun(x, y)
        local edge = math.min(x, y, 63 - x, 63 - y)
        if edge < 4 then
            return 255, 238, 170
        end
        return 255, 255, 240
    end

    local function paintMoon(x, y)
        local bx, by = x // 8, y // 8
        local h = (bx * 73 + by * 151 + bx * by * 7) % 7
        if h == 0 then
            return 168, 172, 186
        elseif h == 3 then
            return 196, 200, 212
        end
        return 232, 235, 244
    end

    local mcSky = Instance.new("Sky")
    mcSky.Name = "MC_Sky"
    mcSky.SkyboxBk = ""
    mcSky.SkyboxDn = ""
    mcSky.SkyboxFt = ""
    mcSky.SkyboxLf = ""
    mcSky.SkyboxRt = ""
    mcSky.SkyboxUp = ""
    mcSky.CelestialBodiesShown = true
    mcSky.StarCount = 3000
    mcSky.SunAngularSize = 18
    mcSky.MoonAngularSize = 12

    do
        local sunImg = makeSquareTexture(64, paintSun)
        if sunImg then
            pcall(function()
                mcSky.SunTextureContent = Content.fromObject(sunImg)
            end)
        end

        local moonImg = makeSquareTexture(64, paintMoon)
        if moonImg then
            pcall(function()
                mcSky.MoonTextureContent = Content.fromObject(moonImg)
            end)
        end
    end

    local mcAtmos = Instance.new("Atmosphere")
    mcAtmos.Name = "MC_Atmosphere"
    mcAtmos.Density = 0.3
    mcAtmos.Offset = 0.25
    mcAtmos.Glare = 0
    mcAtmos.Haze = 1

    local mcCC = Instance.new("ColorCorrectionEffect")
    mcCC.Name = "MC_ColorCorrection"
    mcCC.Saturation = 0.12
    mcCC.Contrast = 0.08
    mcCC.Brightness = 0

    local mcBloom = Instance.new("BloomEffect")
    mcBloom.Name = "MC_Bloom"
    mcBloom.Intensity = 0.2
    mcBloom.Size = 24
    mcBloom.Threshold = 2

    local mcRays = Instance.new("SunRaysEffect")
    mcRays.Name = "MC_SunRays"
    mcRays.Intensity = 0.04
    mcRays.Spread = 0.8

    local mcClouds = Instance.new("Clouds")
    mcClouds.Name = "MC_Clouds"
    mcClouds.Cover = 0.5
    mcClouds.Density = 0.6

    local mine = {
        { inst = mcSky, parent = Lighting },
        { inst = mcAtmos, parent = Lighting },
        { inst = mcCC, parent = Lighting },
        { inst = mcBloom, parent = Lighting },
        { inst = mcRays, parent = Lighting },
        { inst = mcClouds, parent = Terrain },
    }

    local function rgb(r, g, b)
        return Color3.fromRGB(r, g, b)
    end

    local NIGHT = {
        ambient = rgb(34, 38, 70), outdoor = rgb(48, 56, 100), brightness = 0.3,
        horizon = rgb(14, 18, 40), zenith = rgb(4, 6, 18), tint = rgb(200, 210, 255), cloud = rgb(38, 42, 68),
    }
    local DAY = {
        ambient = rgb(138, 148, 170), outdoor = rgb(168, 180, 205), brightness = 2.6,
        horizon = rgb(192, 216, 255), zenith = rgb(120, 167, 255), tint = rgb(255, 252, 245), cloud = rgb(255, 255, 255),
    }

    local KEYFRAMES = {
        { t = 0,    d = NIGHT },
        { t = 5,    d = NIGHT },
        { t = 5.9,  d = { ambient = rgb(70, 66, 100), outdoor = rgb(95, 90, 125), brightness = 0.7,
            horizon = rgb(120, 80, 90), zenith = rgb(28, 36, 82), tint = rgb(235, 215, 240), cloud = rgb(110, 90, 110) } },
        { t = 6.6,  d = { ambient = rgb(120, 108, 120), outdoor = rgb(160, 138, 135), brightness = 1.6,
            horizon = rgb(255, 160, 100), zenith = rgb(92, 120, 200), tint = rgb(255, 228, 205), cloud = rgb(255, 200, 170) } },
        { t = 8,    d = DAY },
        { t = 12,   d = { ambient = rgb(150, 160, 180), outdoor = rgb(180, 192, 215), brightness = 3.0,
            horizon = rgb(196, 220, 255), zenith = rgb(120, 167, 255), tint = rgb(255, 255, 250), cloud = rgb(255, 255, 255) } },
        { t = 16,   d = DAY },
        { t = 17.4, d = { ambient = rgb(130, 125, 140), outdoor = rgb(170, 160, 170), brightness = 2.0,
            horizon = rgb(230, 200, 190), zenith = rgb(110, 140, 225), tint = rgb(255, 240, 220), cloud = rgb(255, 235, 220) } },
        { t = 18.2, d = { ambient = rgb(118, 100, 112), outdoor = rgb(155, 125, 120), brightness = 1.3,
            horizon = rgb(255, 120, 60), zenith = rgb(92, 88, 165), tint = rgb(255, 214, 180), cloud = rgb(255, 170, 130) } },
        { t = 19.2, d = { ambient = rgb(62, 58, 96), outdoor = rgb(85, 78, 122), brightness = 0.6,
            horizon = rgb(95, 55, 95), zenith = rgb(26, 30, 72), tint = rgb(225, 210, 245), cloud = rgb(110, 85, 115) } },
        { t = 20.5, d = NIGHT },
        { t = 24,   d = NIGHT },
    }

    local function sample(clock)
        local a, b = KEYFRAMES[1], KEYFRAMES[#KEYFRAMES]
        for i = 1, #KEYFRAMES - 1 do
            if clock >= KEYFRAMES[i].t and clock <= KEYFRAMES[i + 1].t then
                a, b = KEYFRAMES[i], KEYFRAMES[i + 1]
                break
            end
        end
        local span = b.t - a.t
        local alpha = span > 0 and (clock - a.t) / span or 0
        local da, db = a.d, b.d
        return {
            ambient = da.ambient:Lerp(db.ambient, alpha),
            outdoor = da.outdoor:Lerp(db.outdoor, alpha),
            brightness = da.brightness + (db.brightness - da.brightness) * alpha,
            horizon = da.horizon:Lerp(db.horizon, alpha),
            zenith = da.zenith:Lerp(db.zenith, alpha),
            tint = da.tint:Lerp(db.tint, alpha),
            cloud = da.cloud:Lerp(db.cloud, alpha),
        }
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.IgnoreWater = true
    rayParams.RespectCanCollide = true

    local function setFilter(char)
        rayParams.FilterDescendantsInstances = char and { char } or {}
    end
    setFilter(LP.Character)

    local exposure = 1

    local function exposureTarget()
        local cam = Workspace.CurrentCamera
        if not cam then return 1 end
        local hit = Workspace:Raycast(cam.CFrame.Position, Vector3.new(0, SKY_RAY_LENGTH, 0), rayParams)
        return hit and 0 or 1
    end

    local BLACK = Color3.new(0, 0, 0)
    local clock = START_CLOCK_TIME % 24

    local function applyMinecraft()
        for _, e in ipairs(parked) do
            e.inst.Parent = nil
        end
        for _, e in ipairs(mine) do
            e.inst.Parent = e.parent
        end
        Lighting.GeographicLatitude = 0
        Lighting.GlobalShadows = false
        Lighting.ShadowSoftness = 1
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ExposureCompensation = 0.5
        Lighting.ColorShift_Top = BLACK
        Lighting.ColorShift_Bottom = BLACK
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
    end

    LP.CharacterAdded:Connect(setFilter)

    RunService.RenderStepped:Connect(function(dt)
        if ENABLE_DAY_NIGHT_CYCLE then
            clock = (clock + dt * 24 / DAY_LENGTH_SECONDS) % 24
        end

        exposure = exposure + (exposureTarget() - exposure) * (1 - math.exp(-dt * 2.5))
        local light = MIN_CAVE_LIGHT + (1 - MIN_CAVE_LIGHT) * exposure
        local s = sample(clock)

        Lighting.ClockTime = clock
        Lighting.Ambient = s.ambient:Lerp(Color3.new(1,1,1), (1 - light) * 0.15)
        Lighting.OutdoorAmbient = s.outdoor:Lerp(Color3.new(1,1,1), (1 - light) * 0.15)
        Lighting.Brightness = s.brightness
        mcAtmos.Color = s.horizon:Lerp(BLACK, (1 - exposure) * 0.75)
        mcAtmos.Decay = s.zenith
        mcCC.TintColor = s.tint
        mcClouds.Color = s.cloud
    end)

    applyMinecraft()
end

local CONFIG = {
    MAP_FOLDER_NAME = "Map",
    STUDS_PER_TILE  = 2,
    SKIP_CHARACTERS          = true,
    SKIP_INVISIBLE           = true,
}

local TEX = {
    GrassTop      = "rbxassetid://6645342915",
    GrassBottom   = "rbxassetid://7901287342",
    OakPlanks     = "rbxassetid://5625184464",
    OakLogTop     = "rbxassetid://131220330997689",
    StoneBrick    = "rbxassetid://6456393235",
    Stone         = "rbxassetid://137727371885734",
    Brick         = "rbxassetid://10777285622",
    Sand          = "rbxassetid://140466988252257",
    Water         = "rbxassetid://70399722744482",
    Glass         = "rbxassetid://106504727089007",
    RedSmoothPlastic = "rbxassetid://13706313364",
}

local PLOT_TEX = {
    Sign          = "rbxassetid://8678671166",
    SignChildren  = "rbxassetid://16357832031",
    CashHomeGUI   = "rbxassetid://11413450216",
    CashHomePlain = "rbxassetid://112006332656762",
    Laser         = "rbxassetid://89616449169395",
    PlasticBlue   = "rbxassetid://106504727089007",
    PlotDefault   = "rbxassetid://136966049937099",
}

local MATERIAL_MAP = {
    [Enum.Material.Grass]      = {top = TEX.GrassTop, side = TEX.GrassTop, bottom = TEX.GrassBottom},
    [Enum.Material.LeafyGrass] = {top = TEX.GrassTop, side = TEX.GrassTop, bottom = TEX.GrassBottom},
    [Enum.Material.Mud]        = {top = TEX.GrassBottom, side = TEX.GrassBottom, bottom = TEX.GrassBottom},
    [Enum.Material.Ground]     = {top = TEX.GrassBottom, side = TEX.GrassBottom, bottom = TEX.GrassBottom},
    [Enum.Material.Wood]        = {all = TEX.OakPlanks},
    [Enum.Material.WoodPlanks]  = {all = TEX.OakPlanks},
    [Enum.Material.Brick]       = {all = TEX.Brick},
    [Enum.Material.Cobblestone] = {all = TEX.StoneBrick},
    [Enum.Material.Concrete]    = {all = TEX.StoneBrick},
    [Enum.Material.Slate]       = {all = TEX.StoneBrick},
    [Enum.Material.Rock]        = {all = TEX.Stone},
    [Enum.Material.Basalt]      = {all = TEX.Stone},
    [Enum.Material.Limestone]   = {all = TEX.Stone},
    [Enum.Material.Sand]        = {all = TEX.Sand},
    [Enum.Material.Sandstone]   = {all = TEX.Sand},
    [Enum.Material.Salt]        = {all = TEX.Sand},
    [Enum.Material.Water]       = {all = TEX.Water},
    [Enum.Material.Glacier]     = {all = TEX.Water},
    [Enum.Material.Glass]       = {all = TEX.Glass},
    [Enum.Material.Neon]        = {all = TEX.Glass},
    [Enum.Material.Snow]        = {all = TEX.GrassTop},
}

local NAME_MAP = {
    {keyword = "grass",      tex = {top = TEX.GrassTop, side = TEX.GrassTop, bottom = TEX.GrassBottom}},
    {keyword = "dirt",       tex = {all = TEX.GrassBottom}},
    {keyword = "plank",      tex = {all = TEX.OakPlanks}},
    {keyword = "wood",       tex = {all = TEX.OakPlanks}},
    {keyword = "log",        tex = {all = TEX.OakLogTop}},
    {keyword = "brick",      tex = {all = TEX.Brick}},
    {keyword = "cobble",     tex = {all = TEX.StoneBrick}},
    {keyword = "stonebrick", tex = {all = TEX.StoneBrick}},
    {keyword = "stone",      tex = {all = TEX.Stone}},
    {keyword = "rock",       tex = {all = TEX.Stone}},
    {keyword = "sand",       tex = {all = TEX.Sand}},
    {keyword = "water",      tex = {all = TEX.Water}},
    {keyword = "glass",      tex = {all = TEX.Glass}},
}

local SPECIAL_COLOR = Color3.fromRGB(106, 57, 9)
local SPECIAL_TEX   = {all = TEX.Stone}

local PLASTIC_BLUE  = Color3.fromRGB(27, 42, 53)
local PLASTIC_MASS  = 2331
local PLASTIC_ALPHA = 0.9

local function matchesSpecialColor(c)
    return math.abs(c.R - SPECIAL_COLOR.R) < 0.01
       and math.abs(c.G - SPECIAL_COLOR.G) < 0.01
       and math.abs(c.B - SPECIAL_COLOR.B) < 0.01
end

local function matchesBlueColor(c)
    return math.abs(c.R - PLASTIC_BLUE.R) < 0.01
       and math.abs(c.G - PLASTIC_BLUE.G) < 0.01
       and math.abs(c.B - PLASTIC_BLUE.B) < 0.01
end

local function inAlphaRange(a)
    return a >= 0.59 and a <= 0.61
end

local function isRed(c)
    local r, g, b = c.R, c.G, c.B
    if r < 0.35 then return false end
    if r <= g or r <= b then return false end
    if (r - g) < 0.15 and (r - b) < 0.15 then return false end
    if g > 0.5 and b > 0.5 then return false end
    if g > 0.55 and b < 0.4 then return false end
    return true
end

local function colorToTex(part)
    local color = part.Color
    if matchesSpecialColor(color) then return SPECIAL_TEX end
    if part.Material == Enum.Material.SmoothPlastic and isRed(color) then
        return {all = TEX.RedSmoothPlastic}
    end
    local r, g, b = color.R * 255, color.G * 255, color.B * 255
    if g > r + 20 and g > b + 20 then
        return {top = TEX.GrassTop, side = TEX.GrassTop, bottom = TEX.GrassBottom}
    elseif r > 140 and g > 100 and b < 90 then
        return {all = TEX.Sand}
    elseif r > 100 and r < 160 and g > 70 and g < 110 and b < 80 then
        return {all = TEX.OakPlanks}
    elseif math.abs(r - g) < 20 and math.abs(g - b) < 20 then
        return {all = TEX.Stone}
    end
    return nil
end

local createdTextures, savedChildren, savedMeshTex, createdVariants = {}, {}, {}, {}
local savedMass = {}
local savedTransparency = {}

local function isCharacterPart(part)
    if not CONFIG.SKIP_CHARACTERS then return false end
    local model = part:FindFirstAncestorWhichIsA("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function isInvisible(part)
    if not CONFIG.SKIP_INVISIBLE then return false end
    if part.Transparency >= 1 then return true end
    if part.LocalTransparencyModifier >= 1 then return true end
    if part.Transparency > 0
       and part.Material ~= Enum.Material.Glass
       and part.Material ~= Enum.Material.Water
       and part.Material ~= Enum.Material.Glacier
       and part.Material ~= Enum.Material.Neon then
        return true
    end
    return false
end

local function resolveTexture(part)
    if part:IsA("BasePart") and matchesSpecialColor(part.Color) then
        return SPECIAL_TEX
    end
    if part.Material == Enum.Material.SmoothPlastic and isRed(part.Color) then
        return {all = TEX.RedSmoothPlastic}
    end
    local lowerName = part.Name:lower()
    for _, entry in ipairs(NAME_MAP) do
        if lowerName:find(entry.keyword, 1, true) then
            return entry.tex
        end
    end
    if MATERIAL_MAP[part.Material] then return MATERIAL_MAP[part.Material] end
    if part:IsA("BasePart") then return colorToTex(part) end
    return nil
end

local function saveAndWipe(part)
    savedChildren[part] = savedChildren[part] or {}
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("Texture") or child:IsA("Decal") then
            table.insert(savedChildren[part], child)
            child.Parent = nil
        end
    end
end

local function makeTex(part, id)
    for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
        local t = Instance.new("Texture")
        t.Texture = id
        t.Face = face
        t.StudsPerTileU = CONFIG.STUDS_PER_TILE
        t.StudsPerTileV = CONFIG.STUDS_PER_TILE
        t.Parent = part
        table.insert(createdTextures, t)
    end
end

local function applyFlat(part, id, ignoreInvisible)
    if not ignoreInvisible and isInvisible(part) then return end
    if part:IsA("MeshPart") then
        if savedMeshTex[part] == nil then
            savedMeshTex[part] = part.TextureID
        end
        part.TextureID = id
    end
    saveAndWipe(part)
    makeTex(part, id)
end

local function applyDirectional(part, tex)
    if isInvisible(part) then return end
    if part:IsA("MeshPart") then
        local id = tex.all or tex.top or tex.side
        if id then
            if savedMeshTex[part] == nil then
                savedMeshTex[part] = part.TextureID
            end
            part.TextureID = id
        end
    end
    saveAndWipe(part)
    if tex.all then
        for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
            local t = Instance.new("Texture")
            t.Texture = tex.all; t.Face = face
            t.StudsPerTileU = CONFIG.STUDS_PER_TILE
            t.StudsPerTileV = CONFIG.STUDS_PER_TILE
            t.Parent = part
            table.insert(createdTextures, t)
        end
    else
        local function mk(id, face)
            local t = Instance.new("Texture")
            t.Texture = id; t.Face = face
            t.StudsPerTileU = CONFIG.STUDS_PER_TILE
            t.StudsPerTileV = CONFIG.STUDS_PER_TILE
            t.Parent = part
            table.insert(createdTextures, t)
        end
        if tex.top    then mk(tex.top,    Enum.NormalId.Top)    end
        if tex.bottom then mk(tex.bottom, Enum.NormalId.Bottom) end
        local side = tex.side or tex.top or tex.bottom
        if side then
            mk(side, Enum.NormalId.Front); mk(side, Enum.NormalId.Back)
            mk(side, Enum.NormalId.Left);  mk(side, Enum.NormalId.Right)
        end
    end
end

local function applyMass(part, mass)
    if not part:IsA("BasePart") then return end
    if savedMass[part] == nil then
        savedMass[part] = part.CustomPhysicalProperties
    end
    part.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 1, mass)
end

local function applyTransparency(part, alpha)
    if not part:IsA("BasePart") then return end
    if savedTransparency[part] == nil then
        savedTransparency[part] = part.Transparency
    end
    part.Transparency = alpha
end

local function handleMapPart(part)
    if isCharacterPart(part) then return end
    if isInvisible(part) then return end
    local tex = resolveTexture(part)
    if not tex then return end
    applyDirectional(part, tex)
end

local function applyTerrain()
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    local terrainMap = {
        [Enum.Material.Grass]       = TEX.GrassTop,
        [Enum.Material.LeafyGrass]  = TEX.GrassTop,
        [Enum.Material.Ground]      = TEX.GrassBottom,
        [Enum.Material.Mud]         = TEX.GrassBottom,
        [Enum.Material.Rock]        = TEX.Stone,
        [Enum.Material.Basalt]      = TEX.Stone,
        [Enum.Material.Limestone]   = TEX.Stone,
        [Enum.Material.Sand]        = TEX.Sand,
        [Enum.Material.Sandstone]   = TEX.Sand,
        [Enum.Material.Snow]        = TEX.GrassTop,
        [Enum.Material.Water]       = TEX.Water,
        [Enum.Material.Glacier]     = TEX.Water,
    }
    for material, id in pairs(terrainMap) do
        local variant = Instance.new("MaterialVariant")
        variant.Name         = "MC_" .. material.Name
        variant.BaseMaterial = material
        variant.ColorMap     = id
        variant.Parent       = MaterialService
        table.insert(createdVariants, variant)
    end
end

local PLOTS_NAME    = "Plots"
local PLOTSIGN_NAME = "PlotSign"
local CASH_NAME     = "Cash"
local HOME_NAME     = "structure base home"
local LASER_NAME    = "Laser"

local function runPlots()
    local plots = Workspace:FindFirstChild(PLOTS_NAME)
    if not plots then return 0 end

    local n = 0

    for _, plot in ipairs(plots:GetChildren()) do
        if plot:IsA("Model") then
            local sign  = plot:FindFirstChild(PLOTSIGN_NAME)
            local cash  = plot:FindFirstChild(CASH_NAME)
            local laser = plot:FindFirstChild(LASER_NAME)

            local function inWhitelistedModel(obj)
                local m = obj:FindFirstAncestorWhichIsA("Model")
                while m and m ~= plot do
                    if m.Parent == plot then return true end
                    m = m:FindFirstAncestorWhichIsA("Model")
                end
                return false
            end

            if sign and sign:IsA("BasePart") then
                pcall(applyFlat, sign, PLOT_TEX.Sign, false); n = n + 1
            end

            if sign then
                for _, obj in ipairs(sign:GetDescendants()) do
                    if obj:IsA("BasePart") and obj ~= sign then
                        pcall(applyFlat, obj, PLOT_TEX.SignChildren, false); n = n + 1
                    end
                end
            end

            if cash then
                for _, home in ipairs(cash:GetChildren()) do
                    if home.Name == HOME_NAME and home:IsA("BasePart") then
                        local hasGUI = false
                        for _, d in ipairs(home:GetDescendants()) do
                            if d:IsA("SurfaceGui") then hasGUI = true break end
                        end
                        local id = hasGUI and PLOT_TEX.CashHomeGUI or PLOT_TEX.CashHomePlain
                        pcall(applyFlat, home, id, false); n = n + 1
                    end
                end
            end

            if laser then
                for _, obj in ipairs(laser:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        pcall(applyFlat, obj, PLOT_TEX.Laser, true); n = n + 1
                    end
                end
            end

            for _, obj in ipairs(plot:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local skip = false
                    if sign and (obj == sign or obj:IsDescendantOf(sign)) then skip = true end
                    if cash and obj:IsDescendantOf(cash) then skip = true end
                    if laser and (obj == laser or obj:IsDescendantOf(laser)) then skip = true end
                    if inWhitelistedModel(obj) then skip = true end

                    if not skip then
                        local isBlueTarget = matchesBlueColor(obj.Color)
                                             and inAlphaRange(obj.Transparency)

                        if isBlueTarget then
                            pcall(applyFlat, obj, PLOT_TEX.PlasticBlue, true); n = n + 1
                            pcall(applyMass, obj, PLASTIC_MASS)
                            pcall(applyTransparency, obj, PLASTIC_ALPHA)
                        elseif not isInvisible(obj) then
                            pcall(applyFlat, obj, PLOT_TEX.PlotDefault, false); n = n + 1
                        end
                    end
                end
            end
        end
    end

    return n
end

local root = (CONFIG.MAP_FOLDER_NAME ~= "" and Workspace:FindFirstChild(CONFIG.MAP_FOLDER_NAME, true)) or Workspace

for _, obj in ipairs(root:GetDescendants()) do
    if obj:IsA("BasePart") then
        pcall(handleMapPart, obj)
    end
end

applyTerrain()
runPlots()

do
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
    end
    sky.Name = "Sky"

    local skySettings = {
        CelestialBodiesShown = true,
        MoonAngularSize = 11,
        MoonTextureId = "rbxassetid://8735166687",
        SkyboxBk = "rbxassetid://8735166756",
        SkyboxDn = "rbxassetid://8735166707",
        SkyboxFt = "rbxassetid://8735231668",
        SkyboxLf = "rbxassetid://8735166755",
        SkyboxRt = "rbxassetid://8735166751",
        SkyboxUp = "rbxassetid://8735166729",
        StarCount = 3000,
        SunAngularSize = 11,
        SunTextureId = "rbxassetid://8735166708"
    }

    for property, value in pairs(skySettings) do
        sky[property] = value
    end

    task.spawn(function()
        while true do
            for property, value in pairs(skySettings) do
                if sky[property] ~= value then
                    sky[property] = value
                end
            end
            task.wait(0.5)
        end
    end)
end

print("Combined script running")
