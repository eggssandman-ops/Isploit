-- ISPLOIT
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.

local ASCII = [[
╔══════════════════════════════════════════════════════════════════════╗
║  ██╗███████╗██████╗ ██╗      ██████╗ ██╗████████╗                   ║
║  ██║██╔════╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝                   ║
║  ██║███████╗██████╔╝██║     ██║   ██║██║   ██║                      ║
║  ██║╚════██║██╔═══╝ ██║     ██║   ██║██║   ██║                      ║
║  ██║███████║██║     ███████╗╚██████╔╝██║   ██║                      ║
║  ╚═╝╚══════╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝                      ║
╠══════════════════════════════════════════════════════════════════════╣
║  01001001 01010011 01010000 01001100 01001111 01001001 01010100      ║
║  01101001 01110011 01110000 01101100 01101111 01101001 01110100      ║
╚══════════════════════════════════════════════════════════════════════╝
]]
print(ASCII)
print("[ISPLOIT] loaded")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Owner menu: put your Roblox UserId here. 0 = show for everyone.
local OWNER_USER_ID = 0
if OWNER_USER_ID ~= 0 and player.UserId ~= OWNER_USER_ID then
	return
end

local CAN_CHECK_OWNER = typeof(isnetworkowner) == "function"
local IS_TOUCH = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

local C = {
	black = Color3.fromRGB(8, 8, 9),
	panel = Color3.fromRGB(17, 17, 19),
	panel2 = Color3.fromRGB(38, 38, 44),
	hover = Color3.fromRGB(50, 50, 56),
	active = Color3.fromRGB(72, 72, 80),
	white = Color3.fromRGB(255, 255, 255),
	soft = Color3.fromRGB(238, 238, 244),
	dim = Color3.fromRGB(215, 215, 225),
	line = Color3.fromRGB(110, 110, 122),
	you = Color3.fromRGB(70, 220, 110),
	other = Color3.fromRGB(230, 70, 70),
	server = Color3.fromRGB(150, 150, 158),
}
local PIXEL_BLACK = Color3.fromRGB(10, 10, 10)
local PIXEL_WHITE = Color3.fromRGB(245, 245, 245)
local SKIN = Color3.fromRGB(245, 215, 180)
local BLUE = Color3.fromRGB(60, 120, 220)
local GREEN = Color3.fromRGB(70, 150, 90)

-- Clean up a previous run
local old = playerGui:FindFirstChild("IsploitGUI")
if old then old:Destroy() end
for _, name in ipairs({"UIClick", "UINotification", "IsploitLoadMeow"}) do
	local s = SoundService:FindFirstChild(name)
	if s then s:Destroy() end
end
local oldBlur = Lighting:FindFirstChild("IsploitStartupBlur")
if oldBlur then oldBlur:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "IsploitGUI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- Shared handles and state (tables keep the top-level local count low)
local U = {}
local ST = {
	minimized = false, closing = false, dragging = false,
	dragStartPos = Vector2.zero, dragStartOffset = Vector2.zero, mainOffset = Vector2.zero,
	smoothFps = 60, tiltX = 0, tiltY = 0, hoverAmount = 0,
	lastTouch = nil, baseScale = 1, mobileLayout = false,
	panelKey = nil, currentTab = nil, armed = nil,
	notifyOn = true, toastCount = 0,
	ownerClock = 0, jumpClock = 0, floatClock = 0,
}
local H = {part = nil, att = nil, align = nil, orient = nil, hl = nil, time = 0}
local EP = {aura = {}, ring = {}, jump = {}, tornado = {}, magnet = {}}
local EC = {aura = 0, ring = 0, jump = 0, tornado = 0, magnet = 0}
local R = {myParts = {}, man = nil, hands = nil, rayParams = nil, manRay = nil, charSaved = {}}
local OWN = {highlights = {}}
local TG = {targets = {}, drafts = {}}
local ROWS = {refs = {}, actionButtons = {}, tabs = {}, pages = {}}
local MAIN_W, MAIN_H = 560, 365

local S = {ownership = false, jump = false, aura = false, ring = false,
	tornado = false, magnet = false, man = false, vrhands = false, control = false}
local ORDER = {"ownership", "jump", "aura", "ring", "tornado", "magnet", "man", "vrhands", "control"}

local V = {
	scanRange = 150,
	jumpForce = 60, jumpRate = 0.6,
	auraRadius = 28, auraHeight = 2, auraSpin = 0.6,
	ringRadius = 14, ringHeight = 4, ringSpeed = 60,
	tornadoRadius = 14, tornadoHeight = 18, tornadoSpin = 1.5,
	magnetRange = 60, magnetPull = 40, magnetHeight = 4,
	manSpeed = 16, manJump = 50,
	holdDistance = 12, holdResponsive = 25, holdForce = 300000,
	follow = false, rotate = false,
}

local FEATURES = {
	ownership = {title = "Network ownership", desc = "Green you, red other, grey server", target = false,
		settings = {{"scanRange", "RANGE", 10, 30, 300}}},
	jump = {title = "Jump aura", desc = "Bounces nearby parts around the target", target = true,
		settings = {{"jumpForce", "FORCE", 10, 10, 300}, {"jumpRate", "INTERVAL", 0.1, 0.2, 3}}},
	aura = {title = "Block aura", desc = "Orbits nearby parts around the target", target = true,
		settings = {{"auraRadius", "RADIUS", 2, 4, 80}, {"auraHeight", "HEIGHT", 1, -10, 25}, {"auraSpin", "SPIN", 0.2, 0, 3}}},
	ring = {title = "Block ring", desc = "Floats parts in a ring around the target", target = true,
		settings = {{"ringRadius", "RADIUS", 2, 4, 60}, {"ringHeight", "HEIGHT", 1, -10, 25}, {"ringSpeed", "SPEED", 15, -360, 360}}},
	tornado = {title = "Block tornado", desc = "Spirals parts up a column around the target", target = true,
		settings = {{"tornadoRadius", "RADIUS", 2, 4, 60}, {"tornadoHeight", "HEIGHT", 2, 4, 60}, {"tornadoSpin", "SPIN", 0.25, 0, 5}}},
	magnet = {title = "Block magnet", desc = "Pulls nearby parts onto the target", target = true,
		settings = {{"magnetRange", "RANGE", 5, 10, 200}, {"magnetPull", "PULL", 5, 5, 150}, {"magnetHeight", "HOVER", 1, 0, 15}}},
	man = {title = "Block man", desc = "Walking block figure beside you, emotes on the right", target = false,
		settings = {{"manSpeed", "SPEED", 2, 4, 60}, {"manJump", "JUMP", 5, 10, 120}}},
	vrhands = {title = "VR hands", desc = "Block hands that follow your camera", target = false, settings = {}},
	control = {title = "Control object", desc = "Click a part to grab, click again to drop", target = true,
		settings = {{"holdDistance", "DISTANCE", 1, 3, 80}, {"holdResponsive", "RESPONSE", 5, 5, 100}, {"holdForce", "FORCE", 50000, 50000, 2000000}}},
}

local CAT_MAP = {
	"...........",
	".B.......B.",
	".BB.....BB.",
	".BWB...BWB.",
	".BWWBBBWWB.",
	".BWWWWWWWB.",
	".BWBWWWBWB.",
	".BWWWWWWWB.",
	"..BWWWWWB..",
	"...BBBBB...",
}

-- Block man: jointed figure built from owned unanchored parts.
-- pos is relative to the hip center. Feet sit 3.5 studs below the hip center.
local MAN = {
	groundOff = 3.5,
	order = {"torso1", "torso2", "head", "armL1", "armL2", "armR1", "armR2", "legL1", "legL2", "legR1", "legR2"},
	parts = {
		torso1 = {size = Vector3.new(2, 1.5, 1), color = BLUE, pos = Vector3.new(0, 1.25, 0)},
		torso2 = {size = Vector3.new(2, 1, 1), color = BLUE, pos = Vector3.new(0, 0, 0)},
		head = {size = Vector3.new(1.2, 1.2, 1.2), color = SKIN, pos = Vector3.new(0, 2.6, 0)},
		armL1 = {size = Vector3.new(0.9, 1.5, 0.9), color = SKIN, pos = Vector3.new(-1.5, 0.85, 0)},
		armL2 = {size = Vector3.new(0.9, 1.5, 0.9), color = SKIN, pos = Vector3.new(-1.5, -0.65, 0)},
		armR1 = {size = Vector3.new(0.9, 1.5, 0.9), color = SKIN, pos = Vector3.new(1.5, 0.85, 0)},
		armR2 = {size = Vector3.new(0.9, 1.5, 0.9), color = SKIN, pos = Vector3.new(1.5, -0.65, 0)},
		legL1 = {size = Vector3.new(1, 1.5, 1), color = GREEN, pos = Vector3.new(-0.5, -1.25, 0)},
		legL2 = {size = Vector3.new(1, 1.5, 1), color = GREEN, pos = Vector3.new(-0.5, -2.75, 0)},
		legR1 = {size = Vector3.new(1, 1.5, 1), color = GREEN, pos = Vector3.new(0.5, -1.25, 0)},
		legR2 = {size = Vector3.new(1, 1.5, 1), color = GREEN, pos = Vector3.new(0.5, -2.75, 0)},
	},
	joints = {
		{name = "neck", a = "torso1", b = "head", at = Vector3.new(0, 2, 0)},
		{name = "waist", a = "torso2", b = "torso1", at = Vector3.new(0, 0.5, 0)},
		{name = "shL", a = "torso1", b = "armL1", at = Vector3.new(-1, 1.6, 0)},
		{name = "elL", a = "armL1", b = "armL2", at = Vector3.new(-1.5, 0.1, 0)},
		{name = "shR", a = "torso1", b = "armR1", at = Vector3.new(1, 1.6, 0)},
		{name = "elR", a = "armR1", b = "armR2", at = Vector3.new(1.5, 0.1, 0)},
		{name = "hipL", a = "torso2", b = "legL1", at = Vector3.new(-0.5, -0.5, 0)},
		{name = "knL", a = "legL1", b = "legL2", at = Vector3.new(-0.5, -2, 0)},
		{name = "hipR", a = "torso2", b = "legR1", at = Vector3.new(0.5, -0.5, 0)},
		{name = "knR", a = "legR1", b = "legR2", at = Vector3.new(0.5, -2, 0)},
	},
}

local clickSound = Instance.new("Sound")
clickSound.Name = "UIClick"
clickSound.SoundId = "rbxassetid://535716488"
clickSound.Volume = 0.45
clickSound.Parent = SoundService

local notificationSound = Instance.new("Sound")
notificationSound.Name = "UINotification"
notificationSound.SoundId = "rbxassetid://117934611310434"
notificationSound.Volume = 0.65
notificationSound.Parent = SoundService

local loadSound = Instance.new("Sound")
loadSound.Name = "IsploitLoadMeow"
loadSound.SoundId = "rbxassetid://97634940045228"
loadSound.Volume = 0.8
loadSound.Parent = SoundService

local conns = {}
local function track(c)
	conns[#conns + 1] = c
	return c
end
gui.Destroying:Connect(function()
	for _, c in ipairs(conns) do c:Disconnect() end
end)

-- ===== UI helpers =====
local function playSound(s)
	pcall(function()
		s:Stop()
		s.TimePosition = 0
		s:Play()
	end)
end

local function tw(obj, dur, props, style, dir)
	local t = TweenService:Create(obj, TweenInfo.new(
		dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function stroke(parent, color, transp, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or C.line
	s.Transparency = transp or 0.5
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function label(parent, text, size, pos, font, color, tsize, xalign)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Size = size
	l.Position = pos
	l.Font = font or Enum.Font.Gotham
	l.TextColor3 = color or C.white
	l.TextSize = tsize or 14
	l.TextXAlignment = xalign or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.TextStrokeTransparency = 0.45
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.Parent = parent
	return l
end

local function button(parent, text, size, pos, base)
	base = base or C.panel2
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Text = text
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.TextColor3 = C.white
	b.BackgroundColor3 = base
	b.BackgroundTransparency = 0.2
	b.BorderSizePixel = 0
	b.Size = size
	b.Position = pos or UDim2.new()
	b.Parent = parent
	corner(b, 10)
	stroke(b, C.line, 0.2, 1)
	b.MouseEnter:Connect(function()
		tw(b, 0.15, {BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12)})
	end)
	b.MouseLeave:Connect(function()
		tw(b, 0.2, {BackgroundColor3 = base})
	end)
	b.Activated:Connect(function() playSound(clickSound) end)
	return b
end

local function makeTrack(parent)
	local t = Instance.new("TextButton")
	t.Size = UDim2.fromOffset(38, 20)
	t.AnchorPoint = Vector2.new(1, 0.5)
	t.Position = UDim2.new(1, -12, 0.5, 0)
	t.BackgroundColor3 = C.line
	t.BackgroundTransparency = 0.3
	t.BorderSizePixel = 0
	t.AutoButtonColor = false
	t.Text = ""
	t.Parent = parent
	corner(t, 10)
	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = UDim2.new(0, 3, 0.5, 0)
	knob.Size = UDim2.fromOffset(14, 14)
	knob.BackgroundColor3 = C.white
	knob.BorderSizePixel = 0
	knob.Parent = t
	corner(knob, 7)
	return t, knob
end

local function paintTrack(t, knob, on)
	tw(t, 0.2, {BackgroundColor3 = on and C.white or C.line, BackgroundTransparency = on and 0 or 0.3})
	tw(knob, 0.22, {
		Position = on and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
		BackgroundColor3 = on and C.black or C.white,
	})
end

local function fmtNum(v)
	if v == math.floor(v) then return tostring(math.floor(v)) end
	return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end

local function buildCat(parent, cell, x, y)
	local holder = Instance.new("Frame")
	holder.Name = "CatLogo"
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Size = UDim2.fromOffset(11 * cell, 10 * cell)
	holder.Position = UDim2.fromOffset(x, y)
	holder.Parent = parent
	for r, row in ipairs(CAT_MAP) do
		for c = 1, #row do
			local ch = row:sub(c, c)
			if ch ~= "." then
				local px = Instance.new("Frame")
				px.BorderSizePixel = 0
				px.Size = UDim2.fromOffset(cell, cell)
				px.Position = UDim2.fromOffset((c - 1) * cell, (r - 1) * cell)
				px.BackgroundColor3 = ch == "B" and PIXEL_BLACK or PIXEL_WHITE
				px.Parent = holder
			end
		end
	end
	return holder
end

-- ===== Notifications =====
local toastHolder = Instance.new("Frame")
toastHolder.Name = "Notifications"
toastHolder.BackgroundTransparency = 1
toastHolder.AnchorPoint = Vector2.new(1, 1)
toastHolder.Position = UDim2.new(1, -18, 1, -18)
toastHolder.Size = UDim2.fromOffset(245, 300)
toastHolder.ZIndex = 100
toastHolder.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.Parent = toastHolder

local function notify(message)
	if not ST.notifyOn then return end
	playSound(notificationSound)
	ST.toastCount += 1

	local toast = Instance.new("CanvasGroup")
	toast.Name = "Notification"
	toast.LayoutOrder = ST.toastCount
	toast.Size = UDim2.fromOffset(245, 44)
	toast.BackgroundColor3 = C.panel
	toast.BackgroundTransparency = 0.2
	toast.BorderSizePixel = 0
	toast.GroupTransparency = 1
	toast.ZIndex = 100
	toast.Parent = toastHolder
	corner(toast, 14)
	stroke(toast, Color3.fromRGB(125, 125, 133), 0.4, 1)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.new(0, 3, 1, -20)
	accent.Position = UDim2.fromOffset(12, 10)
	accent.BackgroundColor3 = C.white
	accent.BorderSizePixel = 0
	accent.ZIndex = 101
	accent.Parent = toast
	corner(accent, 2)

	local l = label(toast, message, UDim2.new(1, -36, 1, 0), UDim2.fromOffset(26, 0),
		Enum.Font.GothamMedium, C.white, 14)
	l.TextWrapped = true
	l.ZIndex = 101

	tw(toast, 0.25, {GroupTransparency = 0})
	task.delay(2.4, function()
		if toast.Parent then
			local out = tw(toast, 0.25, {GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			out.Completed:Wait()
			if toast.Parent then toast:Destroy() end
		end
	end)
end

-- ===== World helpers =====
local function needsTargetNow(key)
	if key == "control" then return V.follow end
	return FEATURES[key] ~= nil and FEATURES[key].target == true
end

local function validTarget(t)
	if t == "me" then return true end
	return typeof(t) == "Instance" and t:IsA("Player") and t.Parent == Players
end

local function targetName(t)
	if t == "me" then return "Me" end
	if validTarget(t) then return t.Name end
	return "none"
end

local function characterOf(t)
	if t == "me" then return player.Character end
	if validTarget(t) then return t.Character end
	return nil
end

local function targetPos(t)
	local c = characterOf(t)
	local r = c and c:FindFirstChild("HumanoidRootPart")
	return r and r.Position
end

local function hrpOf()
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function inCharacter(part)
	local node = part.Parent
	while node and node ~= workspace do
		if node:FindFirstChildOfClass("Humanoid") then return true end
		node = node.Parent
	end
	return false
end

local function canMove(part)
	return typeof(part) == "Instance" and part:IsA("BasePart")
		and not part.Anchored and not part:IsA("Terrain")
		and not inCharacter(part) and not R.myParts[part]
end

local function ownsPart(part)
	if not CAN_CHECK_OWNER then return true end
	local ok, res = pcall(isnetworkowner, part)
	return ok and res == true
end

local function ownerKind(part)
	if CAN_CHECK_OWNER and ownsPart(part) then return "you" end
	local node = part.Parent
	while node and node ~= workspace do
		if Players:GetPlayerFromCharacter(node) then return "other" end
		node = node.Parent
	end
	return "server"
end

local function pointerPos()
	if IS_TOUCH and ST.lastTouch then return ST.lastTouch end
	local m = UserInputService:GetMouseLocation()
	return Vector2.new(m.X, m.Y)
end

R.rayParams = RaycastParams.new()
R.rayParams.FilterType = Enum.RaycastFilterType.Exclude
R.manRay = RaycastParams.new()
R.manRay.FilterType = Enum.RaycastFilterType.Exclude

local function rayAt(pos)
	local cam = workspace.CurrentCamera
	if not cam then return nil, nil end
	local ray = cam:ViewportPointToRay(pos.X, pos.Y)
	local ch = player.Character
	R.rayParams.FilterDescendantsInstances = ch and {ch} or {}
	local res = workspace:Raycast(ray.Origin, ray.Direction * 1000, R.rayParams)
	if not res then return nil, nil end
	return res.Instance, res.Distance
end

local function steer(part, target, gain, maxSpeed)
	local vel = (target - part.Position) * gain
	if vel.Magnitude > maxSpeed then vel = vel.Unit * maxSpeed end
	part.AssemblyLinearVelocity = vel
end

local function inRect(obj, pos)
	if not obj or not obj.Visible then return false end
	local p, s = obj.AbsolutePosition, obj.AbsoluteSize
	return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

local function pickParts(origin, range, count)
	local list = {}
	for _, p in ipairs(workspace:GetPartBoundsInRadius(origin, range)) do
		if canMove(p) and ownsPart(p) then list[#list + 1] = p end
	end
	table.sort(list, function(a, b)
		return (a.Position - origin).Magnitude < (b.Position - origin).Magnitude
	end)
	local out = {}
	for i = 1, math.min(count, #list) do out[i] = list[i] end
	return out
end

-- ===== Ownership view =====
local function clearOwnerView()
	for _, h in pairs(OWN.highlights) do h:Destroy() end
	OWN.highlights = {}
end

local function updateOwnerView(origin)
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(origin, V.scanRange)) do
		if canMove(part) then
			seen[part] = true
			local kind = ownerKind(part)
			local col = kind == "you" and C.you or (kind == "other" and C.other or C.server)
			local h = OWN.highlights[part]
			if not h then
				h = Instance.new("Highlight")
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.FillTransparency = 0.8
				h.OutlineTransparency = 0.1
				h.Adornee = part
				h.Parent = part
				OWN.highlights[part] = h
			end
			h.FillColor = col
			h.OutlineColor = col
		end
	end
	for part, h in pairs(OWN.highlights) do
		if not seen[part] or not part.Parent then
			h:Destroy()
			OWN.highlights[part] = nil
		end
	end
end

-- ===== Effects =====
local function refreshEffectParts(key, origin, range)
	local set = EP[key]
	local keep = {}
	for _, p in ipairs(workspace:GetPartBoundsInRadius(origin, range)) do
		if canMove(p) and p ~= H.part then keep[p] = true end
	end
	for p in pairs(set) do
		if not keep[p] then set[p] = nil end
	end
	for p in pairs(keep) do
		if not set[p] then
			set[p] = {
				angle = math.random() * math.pi * 2,
				radius = 0.55 + math.random() * 0.45,
				phase = math.random() * math.pi * 2,
			}
		end
	end
end

local function runEffect(key, dt, origin)
	local set = EP[key]
	local range
	if key == "ring" then range = V.ringRadius + 25
	elseif key == "aura" then range = V.auraRadius + 25
	elseif key == "tornado" then range = V.tornadoRadius + 25
	else range = V.magnetRange end

	EC[key] += dt
	if EC[key] > 0.2 then
		EC[key] = 0
		refreshEffectParts(key, origin, range)
	end

	local t = os.clock()
	local list = {}
	for p in pairs(set) do list[#list + 1] = p end
	local count = math.max(#list, 1)
	for i, part in ipairs(list) do
		local data = set[part]
		if not canMove(part) or part == H.part then
			set[part] = nil
		elseif ownsPart(part) then
			local target, gain, maxS
			if key == "ring" then
				local a = math.rad(V.ringSpeed) * t + (i / count) * math.pi * 2
				target = origin + Vector3.new(math.cos(a) * V.ringRadius, V.ringHeight, math.sin(a) * V.ringRadius)
				gain, maxS = 9, 140
			elseif key == "aura" then
				local a = data.angle + t * V.auraSpin
				local r = V.auraRadius * data.radius
				local h = V.auraHeight + math.sin(t * 1.3 + data.phase) * 2.5
				target = origin + Vector3.new(math.cos(a) * r, h, math.sin(a) * r)
				gain, maxS = 9, 140
			elseif key == "tornado" then
				local frac = (data.angle / (math.pi * 2) + t * 0.25) % 1
				local a = t * V.tornadoSpin + frac * 6 * math.pi
				local r = V.tornadoRadius * (0.3 + 0.7 * frac)
				local h = frac * V.tornadoHeight
				target = origin + Vector3.new(math.cos(a) * r, h, math.sin(a) * r)
				gain, maxS = 10, 160
			else
				local r = 2 + data.radius * 3
				target = origin + Vector3.new(math.cos(data.angle) * r, V.magnetHeight, math.sin(data.angle) * r)
				gain, maxS = 8, V.magnetPull
			end
			steer(part, target, gain, maxS)
			if key ~= "magnet" then
				part.AssemblyAngularVelocity = Vector3.new(0, 1.5, 0)
			end
		end
	end
end

local function runJump(dt, origin)
	EC.jump += dt
	if EC.jump > 0.2 then
		EC.jump = 0
		refreshEffectParts("jump", origin, 30)
	end
	ST.jumpClock += dt
	if ST.jumpClock < V.jumpRate then return end
	ST.jumpClock = 0
	for part in pairs(EP.jump) do
		if canMove(part) and part ~= H.part and ownsPart(part) then
			part.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), V.jumpForce, math.random(-8, 8))
		end
	end
end

-- ===== Control object =====
local function releaseHold(reason)
	if H.align then H.align:Destroy() end
	if H.orient then H.orient:Destroy() end
	if H.att then H.att:Destroy() end
	if H.hl then H.hl:Destroy() end
	H.align, H.orient, H.att, H.hl, H.part = nil, nil, nil, nil, nil
	H.time = 0
	if reason then notify(reason) end
end

local function grab(part, dist)
	releaseHold()
	H.part = part
	H.time = 0
	if dist then V.holdDistance = math.clamp(dist, 3, 80) end

	local att = Instance.new("Attachment")
	att.Name = "IsploitHold"
	att.Parent = part
	H.att = att

	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.RigidityEnabled = false
	align.MaxForce = V.holdForce
	align.MaxVelocity = 250
	align.Responsiveness = V.holdResponsive
	align.Position = part.Position
	align.Parent = part
	H.align = align

	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = att
	orient.MaxTorque = 100000
	orient.MaxAngularVelocity = 25
	orient.Responsiveness = 15
	orient.Enabled = V.rotate
	orient.Parent = part
	H.orient = orient

	local h = Instance.new("Highlight")
	h.FillColor = C.white
	h.FillTransparency = 0.85
	h.OutlineColor = C.white
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Adornee = part
	h.Parent = part
	H.hl = h

	if CAN_CHECK_OWNER and not ownsPart(part) then
		notify("Grabbed, but you don't own it")
	else
		notify("Grabbed")
	end
end

local function updateHold(dt)
	if not H.part then return end
	if not H.part.Parent or H.part.Anchored then
		releaseHold("Dropped, part is gone")
		return
	end
	H.time += dt
	if CAN_CHECK_OWNER and H.time > 0.75 and not ownsPart(H.part) then
		releaseHold("Lost network ownership")
		return
	end

	local cam = workspace.CurrentCamera
	if not cam then return end
	local goal, facing
	if V.follow and validTarget(TG.targets.control) then
		local base = targetPos(TG.targets.control)
		if base then goal = base + Vector3.new(0, 6, 0) end
		local c = characterOf(TG.targets.control)
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		facing = hum and hum.MoveDirection
	else
		local p = pointerPos()
		local ray = cam:ViewportPointToRay(p.X, p.Y)
		goal = ray.Origin + ray.Direction * V.holdDistance
		local myHum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		facing = myHum and myHum.MoveDirection
		if not facing or facing.Magnitude < 0.1 then
			facing = cam.CFrame.LookVector
		end
	end

	H.align.MaxForce = V.holdForce
	H.align.Responsiveness = V.holdResponsive
	if goal then H.align.Position = goal end

	H.orient.Enabled = V.rotate
	if V.rotate and facing then
		local flat = Vector3.new(facing.X, 0, facing.Z)
		if flat.Magnitude > 0.01 then
			H.orient.CFrame = CFrame.lookAt(Vector3.zero, flat.Unit)
		end
	end
end

-- ===== Rig system (VR hands) =====
local function makeRig(parts, specs)
	local rig = {parts = parts, atts = {}, aligns = {}, orients = {}, saved = {}}
	for i, p in ipairs(parts) do
		local s = specs[i]
		rig.saved[i] = {size = p.Size, cc = p.CanCollide, color = p.Color, mat = p.Material}
		p.Size = s.size
		p.Color = s.color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.AssemblyAngularVelocity = Vector3.zero

		local att = Instance.new("Attachment")
		att.Name = "IsploitRig"
		att.Parent = p

		local ap = Instance.new("AlignPosition")
		ap.Mode = Enum.PositionAlignmentMode.OneAttachment
		ap.Attachment0 = att
		ap.RigidityEnabled = false
		ap.MaxForce = 1e7
		ap.MaxVelocity = 400
		ap.Responsiveness = 40
		ap.Position = p.Position
		ap.Parent = p

		local ao = Instance.new("AlignOrientation")
		ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
		ao.Attachment0 = att
		ao.MaxTorque = 1e6
		ao.MaxAngularVelocity = 60
		ao.Responsiveness = 40
		ao.CFrame = p.CFrame.Rotation
		ao.Parent = p

		rig.atts[i], rig.aligns[i], rig.orients[i] = att, ap, ao
		R.myParts[p] = true
	end
	return rig
end

local function destroyRig(rig)
	if not rig then return end
	for i, p in ipairs(rig.parts) do
		R.myParts[p] = nil
		local sv = rig.saved[i]
		if p.Parent and sv then
			p.Size = sv.size
			p.CanCollide = sv.cc
			p.Color = sv.color
			p.Material = sv.mat
		end
	end
	for i = 1, #rig.parts do
		rig.aligns[i]:Destroy()
		rig.orients[i]:Destroy()
		rig.atts[i]:Destroy()
	end
end

local function applyRig(rig, cfs)
	for i = 1, #rig.parts do
		local cf = cfs[i]
		if cf then
			rig.aligns[i].Position = cf.Position
			rig.orients[i].CFrame = cf.Rotation
		end
	end
end

-- ===== Hide your real character on your screen only =====
local function setCharHidden(on)
	local ch = player.Character
	if not ch then return end
	for _, d in ipairs(ch:GetDescendants()) do
		if d:IsA("BasePart") then
			if on then
				if R.charSaved[d] == nil then R.charSaved[d] = d.LocalTransparencyModifier end
				d.LocalTransparencyModifier = 1
			elseif R.charSaved[d] ~= nil then
				d.LocalTransparencyModifier = R.charSaved[d]
			end
		elseif d:IsA("BillboardGui") then
			if on then
				if R.charSaved[d] == nil then R.charSaved[d] = d.Enabled end
				d.Enabled = false
			elseif R.charSaved[d] ~= nil then
				d.Enabled = R.charSaved[d]
			end
		end
	end
	if not on then R.charSaved = {} end
end

-- ===== Block man (jointed figure with a walk cycle) =====
local function releaseMan(reason)
	local st = R.man
	if st then
		for _, inst in ipairs(st.inst) do inst:Destroy() end
		for p, sv in pairs(st.saved) do
			R.myParts[p] = nil
			if p.Parent then
				p.Size = sv.size
				p.CanCollide = sv.cc
				p.Color = sv.color
				p.Material = sv.mat
				p.Transparency = sv.tr
				p.AssemblyLinearVelocity = Vector3.zero
				p.AssemblyAngularVelocity = Vector3.zero
			end
		end
		local hrp = hrpOf()
		local torso = st.parts.torso1
		if hrp then
			if torso and torso.Parent then
				hrp.CFrame = CFrame.new(torso.Position + Vector3.new(0, 3, 0))
			end
			hrp.Anchored = st.hrpAnchored
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
		R.man = nil
	end
	setCharHidden(false)
	local cam = workspace.CurrentCamera
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if cam and hum then cam.CameraSubject = hum end
	if reason then notify(reason) end
end

local function buildMan()
	local hrp = hrpOf()
	if not hrp then
		notify("No character to build from")
		return false
	end
	local found = pickParts(hrp.Position, 60, #MAN.order)
	if #found < #MAN.order then
		notify("Need " .. #MAN.order .. " owned unanchored parts nearby (" .. #found .. " found)")
		return false
	end

	local cam = workspace.CurrentCamera
	local yaw = 0
	if cam then
		local look = cam.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
	local origin = hrp.Position + Vector3.new(0, MAN.groundOff + 2, 0)
	local root = CFrame.new(origin) * CFrame.Angles(0, yaw, 0)

	local st = {
		parts = {}, joints = {}, inst = {}, saved = {},
		yaw = yaw, walk = 0, moveAmt = 0, spin = 0,
		emote = nil, emoteT0 = 0, hrpAnchored = hrp.Anchored,
	}

	for i, role in ipairs(MAN.order) do
		local spec = MAN.parts[role]
		local p = found[i]
		st.parts[role] = p
		st.saved[p] = {size = p.Size, cc = p.CanCollide, color = p.Color, mat = p.Material, tr = p.Transparency}
		p.Size = spec.size
		p.Color = spec.color
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = 0
		p.CanCollide = true
		p.Anchored = false
		p.AssemblyLinearVelocity = Vector3.zero
		p.AssemblyAngularVelocity = Vector3.zero
		p.CFrame = root * CFrame.new(spec.pos)
		R.myParts[p] = true
	end

	for _, j in ipairs(MAN.joints) do
		local a, b = st.parts[j.a], st.parts[j.b]
		local jw = root * CFrame.new(j.at)
		local m = Instance.new("Motor6D")
		m.Name = j.name
		m.Part0 = a
		m.Part1 = b
		m.C0 = a.CFrame:ToObjectSpace(jw)
		m.C1 = b.CFrame:ToObjectSpace(jw)
		m.Parent = a
		st.joints[j.name] = m
		table.insert(st.inst, m)
	end

	-- Keeps the torso upright and turned the way the figure faces
	local att = Instance.new("Attachment")
	att.Name = "IsploitManAtt"
	att.Parent = st.parts.torso1
	table.insert(st.inst, att)
	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e6
	ao.MaxAngularVelocity = 30
	ao.Responsiveness = 30
	ao.CFrame = CFrame.Angles(0, yaw, 0)
	ao.Parent = st.parts.torso1
	table.insert(st.inst, ao)
	st.ao = ao

	-- Your real character is anchored under the figure, so the camera and controls follow the block man
	hrp.Anchored = true
	hrp.CFrame = CFrame.new(origin - Vector3.new(0, 6, 0))

	R.man = st
	local cam2 = workspace.CurrentCamera
	if cam2 then cam2.CameraSubject = st.parts.torso1 end
	notify("Block man built (WASD walk, Space jump)")
	return true
end

local function updateMan(dt)
	local st = R.man
	if not st then return end
	local P = st.parts
	for _, p in pairs(P) do
		if not p.Parent then
			releaseMan("Block man lost a part")
			return
		end
	end
	setCharHidden(true)

	local cam = workspace.CurrentCamera
	if not cam then return end
	local torso = P.torso1

	-- Movement relative to the camera
	local look, right = cam.CFrame.LookVector, cam.CFrame.RightVector
	local fwd = Vector3.new(look.X, 0, look.Z)
	local rgt = Vector3.new(right.X, 0, right.Z)
	if fwd.Magnitude > 0.01 then fwd = fwd.Unit end
	if rgt.Magnitude > 0.01 then rgt = rgt.Unit end
	local move = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += fwd end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= fwd end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += rgt end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= rgt end
	local moving = move.Magnitude > 0.1
	if moving then
		move = move.Unit
		st.emote = nil
	end

	-- Ground probe under the hips, ignoring the figure and your character
	local ex = {}
	for _, p in pairs(P) do ex[#ex + 1] = p end
	if player.Character then ex[#ex + 1] = player.Character end
	R.manRay.FilterDescendantsInstances = ex
	local hit = workspace:Raycast(torso.Position, Vector3.new(0, -(MAN.groundOff + 4), 0), R.manRay)
	local groundY = hit and hit.Position.Y or (torso.Position.Y - MAN.groundOff)
	local onGround = hit ~= nil and (torso.Position.Y - hit.Position.Y) < MAN.groundOff + 1.2

	-- Velocity drives the body: horizontal walk, vertical hold at leg height
	local vel = torso.AssemblyLinearVelocity
	local wantH = move * V.manSpeed
	local hz = Vector3.new(vel.X, 0, vel.Z):Lerp(Vector3.new(wantH.X, 0, wantH.Z), math.min(1, dt * 10))
	local vy = vel.Y
	if onGround then
		local err = (groundY + MAN.groundOff) - torso.Position.Y
		vy = math.clamp(err * 12, -30, 30)
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vy = V.manJump
		end
	end
	torso.AssemblyLinearVelocity = Vector3.new(hz.X, vy, hz.Z)

	-- Turn toward the walk direction
	if moving then
		local desired = math.atan2(-move.X, -move.Z)
		local diff = (desired - st.yaw + math.pi) % (2 * math.pi) - math.pi
		st.yaw += diff * math.min(1, dt * 10)
	end
	st.moveAmt += ((moving and 1 or 0) - st.moveAmt) * math.min(1, dt * 8)
	local hspeed = Vector3.new(hz.X, 0, hz.Z).Magnitude
	st.walk += hspeed * dt * 0.7

	if st.emote == "Spin" then
		st.spin += dt * 6
	end
	st.ao.CFrame = CFrame.Angles(0, st.yaw + st.spin, 0)

	-- Keep the real character parked under the figure
	local hrp = hrpOf()
	if hrp then
		hrp.Anchored = true
		hrp.CFrame = CFrame.new(torso.Position - Vector3.new(0, 6, 0))
		hrp.AssemblyLinearVelocity = Vector3.zero
	end

	-- Walk cycle through the joints
	local J = st.joints
	local t = os.clock()
	local m = st.moveAmt
	local p = st.walk
	local swing = math.sin(p) * 0.6 * m
	J.hipL.Transform = CFrame.Angles(swing, 0, 0)
	J.hipR.Transform = CFrame.Angles(-swing, 0, 0)
	J.knL.Transform = CFrame.Angles(-math.max(0, -math.sin(p)) * 0.9 * m, 0, 0)
	J.knR.Transform = CFrame.Angles(-math.max(0, math.sin(p)) * 0.9 * m, 0, 0)
	local armSw = math.sin(p) * 0.5 * m
	local idle = math.sin(t * 2) * 0.04 * (1 - m)
	J.shL.Transform = CFrame.Angles(-armSw + idle, 0, 0)
	J.shR.Transform = CFrame.Angles(armSw - idle, 0, 0)
	J.elL.Transform = CFrame.Angles(-0.25 * m, 0, 0)
	J.elR.Transform = CFrame.Angles(-0.25 * m, 0, 0)
	J.neck.Transform = CFrame.new()
	J.waist.Transform = CFrame.new()

	-- Emotes override the arms (and legs while standing still)
	if st.emote then
		local e = t - st.emoteT0
		if st.emote == "Dance" then
			local b = math.sin(e * 8)
			J.shL.Transform = CFrame.Angles(b * 1.3 - 0.2, 0, 0)
			J.shR.Transform = CFrame.Angles(-b * 1.3 - 0.2, 0, 0)
			J.elL.Transform = CFrame.Angles(-0.8, 0, 0)
			J.elR.Transform = CFrame.Angles(-0.8, 0, 0)
			J.hipL.Transform = CFrame.new()
			J.hipR.Transform = CFrame.new()
			J.knL.Transform = CFrame.new()
			J.knR.Transform = CFrame.new()
		elseif st.emote == "Wave" then
			J.shR.Transform = CFrame.Angles(-2.6 + math.sin(e * 10) * 0.3, 0, 0)
			J.elR.Transform = CFrame.Angles(-0.5, 0, 0)
			J.shL.Transform = CFrame.Angles(0.1, 0, 0)
		elseif st.emote == "Spin" then
			J.shL.Transform = CFrame.Angles(0, 0, -1.4)
			J.shR.Transform = CFrame.Angles(0, 0, 1.4)
			J.elL.Transform = CFrame.new()
			J.elR.Transform = CFrame.new()
			J.hipL.Transform = CFrame.new()
			J.hipR.Transform = CFrame.new()
			J.knL.Transform = CFrame.new()
			J.knR.Transform = CFrame.new()
		end
	end
end

local function playEmote(name)
	if not R.man then
		notify("Turn on Block man first")
		return
	end
	if name == "Stop" then
		R.man.emote = nil
		R.man.spin = 0
	else
		R.man.emote = name
		R.man.emoteT0 = os.clock()
		if name ~= "Spin" then R.man.spin = 0 end
	end
end

-- ===== VR hands =====
local HAND_ROLES = {"palm", "f1", "f2", "f3", "f4", "thumb"}
local HAND_SPEC = {
	palm = {size = Vector3.new(1.3, 0.35, 1.3), color = SKIN},
	f1 = {size = Vector3.new(0.24, 0.24, 0.9), color = SKIN},
	f2 = {size = Vector3.new(0.24, 0.24, 0.9), color = SKIN},
	f3 = {size = Vector3.new(0.24, 0.24, 0.9), color = SKIN},
	f4 = {size = Vector3.new(0.24, 0.24, 0.9), color = SKIN},
	thumb = {size = Vector3.new(0.26, 0.26, 0.6), color = SKIN},
}
local HAND_SPECS_ALL = {}
for _ = 1, 2 do
	for _, r in ipairs(HAND_ROLES) do HAND_SPECS_ALL[#HAND_SPECS_ALL + 1] = HAND_SPEC[r] end
end
local HAND_OFFS = {
	palm = CFrame.new(0, 0, 0),
	f1 = CFrame.new(-0.4, 0.05, -0.95),
	f2 = CFrame.new(-0.13, 0.05, -0.95),
	f3 = CFrame.new(0.13, 0.05, -0.95),
	f4 = CFrame.new(0.4, 0.05, -0.95),
}

local function handPoses(t)
	local cam = workspace.CurrentCamera
	local out = {}
	if not cam then return out end
	local bob = math.sin(t * 5) * 0.03
	for _, side in ipairs({-1, 1}) do
		local base = cam.CFrame * CFrame.new(side * 1.2, -0.9 + bob, -2.2) * CFrame.Angles(-0.35, 0, 0)
		local startIdx = side < 0 and 0 or #HAND_ROLES
		for i, r in ipairs(HAND_ROLES) do
			local off = r == "thumb" and CFrame.new(-side * 0.75, 0, -0.3) or HAND_OFFS[r]
			out[startIdx + i] = base * off
		end
	end
	return out
end

local function buildHands()
	local cam = workspace.CurrentCamera
	if not cam then
		notify("No camera")
		return false
	end
	local parts = pickParts(cam.CFrame.Position, 80, #HAND_SPECS_ALL)
	if #parts < #HAND_SPECS_ALL then
		notify("Need " .. #HAND_SPECS_ALL .. " owned unanchored parts nearby (" .. #parts .. " found)")
		return false
	end
	R.hands = makeRig(parts, HAND_SPECS_ALL)
	notify("VR hands built")
	return true
end

local function updateHands()
	if not R.hands then return end
	for _, p in ipairs(R.hands.parts) do
		if not p.Parent then
			destroyRig(R.hands)
			R.hands = nil
			S.vrhands = false
			notify("VR hands lost a part")
			return
		end
	end
	applyRig(R.hands, handPoses(os.clock()))
end

-- ===== Goto / bring arming =====
local function refreshActions()
	for key, b in pairs(ROWS.actionButtons) do
		local on = ST.armed == key
		b.Text = on and "ARMED" or "ARM"
		b.TextColor3 = on and C.black or C.white
		b.BackgroundColor3 = on and C.white or C.panel2
	end
end

local function setArmed(mode)
	if ST.armed == mode then
		ST.armed = nil
	else
		ST.armed = mode
		notify(mode == "goto" and "Click an object to goto" or "Click an object to bring")
	end
	refreshActions()
end

-- ===== Window =====
local wrap = Instance.new("Frame")
wrap.Name = "Wrap"
wrap.AnchorPoint = Vector2.new(0.5, 0.5)
wrap.Position = UDim2.new(0.5, 0, 0.5, 0)
wrap.Size = UDim2.fromOffset(MAIN_W, MAIN_H)
wrap.BackgroundTransparency = 1
wrap.BorderSizePixel = 0
wrap.Visible = false
wrap.Parent = gui
U.wrap = wrap

local wrapScale = Instance.new("UIScale")
wrapScale.Scale = 1
wrapScale.Parent = wrap
U.wrapScale = wrapScale

local main = Instance.new("CanvasGroup")
main.Name = "MainWindow"
main.Size = UDim2.fromScale(1, 1)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
main.BackgroundTransparency = 1
main.BorderSizePixel = 0
main.Parent = wrap
corner(main, 24)
stroke(main, Color3.fromRGB(150, 150, 160), 0.2, 1.2)
U.main = main

local mainBg = Instance.new("Frame")
mainBg.Name = "Background"
mainBg.BackgroundColor3 = Color3.new(1, 1, 1)
mainBg.BorderSizePixel = 0
mainBg.BackgroundTransparency = 0.5
mainBg.Size = UDim2.fromScale(1, 1)
mainBg.ZIndex = 0
mainBg.Parent = main
corner(mainBg, 24)
local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new(Color3.fromRGB(24, 24, 28), Color3.fromRGB(14, 14, 16))
mainGradient.Rotation = 90
mainGradient.Parent = mainBg

local starfield = Instance.new("Frame")
starfield.Name = "Starfield"
starfield.BackgroundTransparency = 1
starfield.Size = UDim2.new(1, 48, 1, 48)
starfield.Position = UDim2.fromOffset(-24, -24)
starfield.ZIndex = 0
starfield.Parent = main
U.starfield = starfield

U.stars = {}
for _, layer in ipairs({
	{count = 34, size = 1, speed = 0.004, alpha = 0.55},
	{count = 22, size = 2, speed = 0.009, alpha = 0.35},
	{count = 10, size = 3, speed = 0.016, alpha = 0.15},
}) do
	for _ = 1, layer.count do
		local dot = Instance.new("Frame")
		dot.Name = "Star"
		dot.BackgroundColor3 = C.white
		dot.BorderSizePixel = 0
		dot.Size = UDim2.fromOffset(layer.size, layer.size)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Parent = starfield
		corner(dot, 3)
		U.stars[#U.stars + 1] = {
			dot = dot, x = math.random(), y = math.random(),
			vx = layer.speed * (0.8 + math.random() * 0.4),
			base = layer.alpha, phase = math.random() * math.pi * 2,
			rate = 0.6 + math.random() * 1.4,
		}
	end
end

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundTransparency = 1
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 52)
header.Active = true
header.Parent = main
U.header = header

local headerDivider = Instance.new("Frame")
headerDivider.BackgroundColor3 = C.line
headerDivider.BackgroundTransparency = 0.5
headerDivider.BorderSizePixel = 0
headerDivider.Position = UDim2.new(0, 0, 1, -1)
headerDivider.Size = UDim2.new(1, 0, 0, 1)
headerDivider.Parent = header

buildCat(header, 3, 32, 26)
label(header, "ISPLOIT", UDim2.new(0, 120, 1, 0), UDim2.fromOffset(60, 0), Enum.Font.GothamBold, C.white, 17)

U.minimizeButton = button(header, "–", UDim2.fromOffset(34, 32), UDim2.new(1, -78, 0, 10))
U.minimizeButton.TextSize = 22
U.closeButton = button(header, "×", UDim2.fromOffset(34, 32), UDim2.new(1, -39, 0, 10))
U.closeButton.TextSize = 20

local content = Instance.new("CanvasGroup")
content.Name = "Content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.Position = UDim2.fromOffset(0, 52)
content.Size = UDim2.new(1, 0, 1, -52)
content.ClipsDescendants = true
content.Parent = main
U.content = content

local function newPage(name)
	local p = Instance.new("Frame")
	p.Name = name .. "Page"
	p.Size = UDim2.fromScale(1, 1)
	p.BackgroundTransparency = 1
	p.BorderSizePixel = 0
	p.Visible = false
	p.Parent = content
	ROWS.pages[name] = p
	return p
end
newPage("Home")
newPage("Troll")
newPage("Settings")

local sidebar = Instance.new("Frame")
sidebar.Name = "FloatingSidebar"
sidebar.AnchorPoint = Vector2.new(1, 0.5)
sidebar.Position = UDim2.new(0, -12, 0.5, 0)
sidebar.Size = UDim2.fromOffset(52, 176)
sidebar.BackgroundColor3 = C.panel
sidebar.BackgroundTransparency = 0.35
sidebar.BorderSizePixel = 0
sidebar.ZIndex = 2
sidebar.Parent = wrap
corner(sidebar, 22)
stroke(sidebar, Color3.fromRGB(150, 150, 160), 0.25, 1)
U.sidebar = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 9)
sidebarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Parent = sidebar
U.sidebarLayout = sidebarLayout

local function hammerIcon(parent)
	local icon = Instance.new("Frame")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(26, 26)
	icon.BackgroundTransparency = 1
	icon.Parent = parent
	local function part(size, center, rot, rad, col)
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Size = size
		f.Position = UDim2.fromOffset(center.X, center.Y)
		f.Rotation = rot
		f.BackgroundColor3 = col
		f.BorderSizePixel = 0
		f.Parent = icon
		corner(f, rad)
	end
	part(UDim2.fromOffset(4, 20), Vector2.new(12, 14), 45, 2, C.soft)
	part(UDim2.fromOffset(15, 7), Vector2.new(17, 8), 45, 2, C.white)
end

local panel = Instance.new("Frame")
panel.Name = "SettingsPanel"
panel.Position = UDim2.new(1, 12, 0, 0)
panel.Size = UDim2.new(0, 250, 1, 0)
panel.BackgroundColor3 = C.panel
panel.BackgroundTransparency = 0.5
panel.BorderSizePixel = 0
panel.Visible = false
panel.ZIndex = 60
panel.Parent = wrap
corner(panel, 18)
stroke(panel, C.line, 0.6, 1)
U.panel = panel

U.panelTitle = label(panel, "", UDim2.new(1, -60, 0, 22), UDim2.fromOffset(16, 12),
	Enum.Font.GothamBold, C.white, 16)
U.panelClose = button(panel, "×", UDim2.fromOffset(26, 26), UDim2.new(1, -36, 0, 10))
U.panelClose.TextSize = 16
U.panelDesc = label(panel, "", UDim2.new(1, -32, 0, 28), UDim2.fromOffset(16, 36),
	Enum.Font.Gotham, C.dim, 12)
U.panelDesc.TextWrapped = true
U.panelDesc.TextYAlignment = Enum.TextYAlignment.Top
U.panelDesc.TextTruncate = Enum.TextTruncate.None

U.pickerHdr = label(panel, "TARGET", UDim2.new(1, -24, 0, 14), UDim2.fromOffset(12, 70),
	Enum.Font.Code, C.dim, 11)
U.pickerBtn = button(panel, "Select a target   ▾", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 86), C.black)
U.pickerBtn.TextXAlignment = Enum.TextXAlignment.Left
U.pickerBtn.TextColor3 = C.dim
do
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 10)
	p.Parent = U.pickerBtn
end

U.pickerList = Instance.new("ScrollingFrame")
U.pickerList.Name = "PickerList"
U.pickerList.Position = UDim2.fromOffset(12, 120)
U.pickerList.Size = UDim2.new(1, -24, 0, 130)
U.pickerList.BackgroundColor3 = C.black
U.pickerList.BackgroundTransparency = 0.35
U.pickerList.BorderSizePixel = 0
U.pickerList.CanvasSize = UDim2.new()
U.pickerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.pickerList.ScrollBarThickness = 2
U.pickerList.ScrollBarImageColor3 = C.line
U.pickerList.Visible = false
U.pickerList.ZIndex = 40
U.pickerList.Parent = panel
corner(U.pickerList, 10)
stroke(U.pickerList, C.line, 0.4, 1)
local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 4)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = U.pickerList
local plPad = Instance.new("UIPadding")
plPad.PaddingTop = UDim.new(0, 4)
plPad.PaddingBottom = UDim.new(0, 4)
plPad.PaddingLeft = UDim.new(0, 4)
plPad.PaddingRight = UDim.new(0, 4)
plPad.Parent = U.pickerList

U.body = Instance.new("ScrollingFrame")
U.body.Name = "PanelBody"
U.body.BackgroundTransparency = 1
U.body.BorderSizePixel = 0
U.body.Position = UDim2.fromOffset(12, 124)
U.body.Size = UDim2.new(1, -24, 1, -182)
U.body.CanvasSize = UDim2.new()
U.body.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.body.ScrollBarThickness = 2
U.body.ScrollBarImageColor3 = C.line
U.body.ClipsDescendants = true
U.body.Parent = panel
local bodyLayout = Instance.new("UIListLayout")
bodyLayout.Padding = UDim.new(0, 6)
bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
bodyLayout.Parent = U.body
local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingRight = UDim.new(0, 8)
bodyPad.Parent = U.body

U.confirmBtn = button(panel, "CONFIRM", UDim2.new(1, -80, 0, 34), UDim2.new(0, 12, 1, -46), C.white)
U.confirmBtn.TextColor3 = C.black
U.stopBtn = button(panel, "STOP", UDim2.fromOffset(50, 34), UDim2.new(1, -62, 1, -46), C.panel2)
U.stopBtn.TextSize = 12

local emotePanel = Instance.new("Frame")
emotePanel.Name = "EmotePanel"
emotePanel.Size = UDim2.fromOffset(124, 176)
emotePanel.Position = UDim2.new(1, 12, 0, 0)
emotePanel.BackgroundColor3 = C.panel
emotePanel.BackgroundTransparency = 0.4
emotePanel.BorderSizePixel = 0
emotePanel.Visible = false
emotePanel.ZIndex = 62
emotePanel.Parent = wrap
corner(emotePanel, 16)
stroke(emotePanel, C.line, 0.5, 1)
U.emotePanel = emotePanel
label(emotePanel, "EMOTES", UDim2.new(1, -20, 0, 18), UDim2.fromOffset(10, 8), Enum.Font.Code, C.dim, 11)
for i, name in ipairs({"Dance", "Wave", "Spin", "Stop"}) do
	local b = button(emotePanel, name, UDim2.new(1, -20, 0, 32), UDim2.fromOffset(10, 32 + (i - 1) * 38))
	b.TextSize = 13
	b.ZIndex = 63
	b.Activated:Connect(function() playEmote(name) end)
end

-- Home page
local asciiLbl = label(ROWS.pages.Home, ASCII, UDim2.new(1, -16, 0, 170), UDim2.fromOffset(8, 6),
	Enum.Font.Code, C.white, 10, Enum.TextXAlignment.Center)
asciiLbl.TextYAlignment = Enum.TextYAlignment.Center
asciiLbl.TextTruncate = Enum.TextTruncate.None

local statRow = Instance.new("Frame")
statRow.Name = "StatCards"
statRow.BackgroundTransparency = 1
statRow.Position = UDim2.fromOffset(8, 214)
statRow.Size = UDim2.new(1, -16, 0, 62)
statRow.Parent = ROWS.pages.Home
local statLayout = Instance.new("UIListLayout")
statLayout.FillDirection = Enum.FillDirection.Horizontal
statLayout.Padding = UDim.new(0, 8)
statLayout.SortOrder = Enum.SortOrder.LayoutOrder
statLayout.Parent = statRow

U.statVals = {}
for i, key in ipairs({"FPS", "PING", "PLAYERS"}) do
	local card = Instance.new("Frame")
	card.LayoutOrder = i
	card.Size = UDim2.new(1 / 3, -6, 1, 0)
	card.BackgroundColor3 = C.panel2
	card.BackgroundTransparency = 0.45
	card.BorderSizePixel = 0
	card.Parent = statRow
	corner(card, 12)
	stroke(card, C.line, 0.1, 1)
	label(card, key, UDim2.new(1, -24, 0, 14), UDim2.fromOffset(12, 8), Enum.Font.Code, C.dim, 11)
	U.statVals[key] = label(card, "--", UDim2.new(1, -24, 0, 22), UDim2.fromOffset(12, 26),
		Enum.Font.GothamBold, C.white, 18)
end

U.runLabel = label(ROWS.pages.Home, "nothing running", UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 286),
	Enum.Font.Code, C.dim, 12)

-- Settings page
label(ROWS.pages.Settings, "Settings", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 6),
	Enum.Font.GothamBold, C.white, 19)
local settingsList = Instance.new("Frame")
settingsList.Position = UDim2.fromOffset(12, 40)
settingsList.Size = UDim2.new(1, -24, 1, -48)
settingsList.BackgroundTransparency = 1
settingsList.Parent = ROWS.pages.Settings
local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 8)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsList

-- Troll page
label(ROWS.pages.Troll, "Troll", UDim2.new(1, -24, 0, 24), UDim2.fromOffset(12, 6),
	Enum.Font.GothamBold, C.white, 19)
label(ROWS.pages.Troll, "Click a row to open its settings box. Pick a target, then confirm.",
	UDim2.new(1, -24, 0, 14), UDim2.fromOffset(12, 32), Enum.Font.Gotham, C.dim, 12)
U.trollScroll = Instance.new("ScrollingFrame")
U.trollScroll.Name = "TrollScroll"
U.trollScroll.BackgroundTransparency = 1
U.trollScroll.BorderSizePixel = 0
U.trollScroll.Position = UDim2.fromOffset(12, 56)
U.trollScroll.Size = UDim2.new(1, -24, 1, -64)
U.trollScroll.CanvasSize = UDim2.new()
U.trollScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
U.trollScroll.ScrollBarThickness = 3
U.trollScroll.ScrollBarImageColor3 = C.line
U.trollScroll.ScrollingEnabled = true
U.trollScroll.ClipsDescendants = true
U.trollScroll.Parent = ROWS.pages.Troll
local trollLayout = Instance.new("UIListLayout")
trollLayout.Padding = UDim.new(0, 7)
trollLayout.SortOrder = Enum.SortOrder.LayoutOrder
trollLayout.Parent = U.trollScroll
local trollPad = Instance.new("UIPadding")
trollPad.PaddingRight = UDim.new(0, 10)
trollPad.PaddingBottom = UDim.new(0, 6)
trollPad.Parent = U.trollScroll

-- Settings box internals
local thumbCache = {}
local function getThumb(userId)
	if thumbCache[userId] then return thumbCache[userId] end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if ok and content then
		thumbCache[userId] = content
		return content
	end
	return ""
end

local function paintPicker()
	local t = ST.panelKey and TG.drafts[ST.panelKey]
	if t ~= nil then
		U.pickerBtn.Text = targetName(t) .. "   ▾"
		U.pickerBtn.TextColor3 = C.white
	else
		U.pickerBtn.Text = "Select a target   ▾"
		U.pickerBtn.TextColor3 = C.dim
	end
end

local function rebuildPicker()
	for _, c in ipairs(U.pickerList:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	local opts = {"me"}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then table.insert(opts, p) end
	end
	for i, opt in ipairs(opts) do
		local o = Instance.new("TextButton")
		o.Name = "Option"
		o.LayoutOrder = i
		o.Size = UDim2.new(1, -8, 0, 32)
		o.BackgroundColor3 = C.panel
		o.BackgroundTransparency = 0.3
		o.BorderSizePixel = 0
		o.AutoButtonColor = false
		o.Text = ""
		o.ZIndex = 41
		o.Parent = U.pickerList
		corner(o, 8)

		local userId = opt == "me" and player.UserId or opt.UserId
		local av = Instance.new("ImageLabel")
		av.Size = UDim2.fromOffset(24, 24)
		av.Position = UDim2.fromOffset(6, 4)
		av.BackgroundColor3 = C.panel2
		av.BorderSizePixel = 0
		av.ZIndex = 42
		av.Image = getThumb(userId)
		av.Parent = o
		corner(av, 12)

		local nm = label(o, targetName(opt), UDim2.new(1, -44, 1, 0), UDim2.fromOffset(38, 0),
			Enum.Font.GothamMedium, C.white, 13)
		nm.ZIndex = 42

		o.Activated:Connect(function()
			if ST.panelKey then TG.drafts[ST.panelKey] = opt end
			U.pickerList.Visible = false
			paintPicker()
		end)
	end
end

U.pickerBtn.Activated:Connect(function()
	U.pickerList.Visible = not U.pickerList.Visible
	if U.pickerList.Visible then rebuildPicker() end
end)

local function stepperRow(parent, order, s)
	local key, caption, step, minV, maxV = s[1], s[2], s[3], s[4], s[5]
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -6, 0, 36)
	row.BackgroundColor3 = C.panel2
	row.BackgroundTransparency = 0.6
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 10)

	label(row, caption, UDim2.new(0.5, 0, 1, 0), UDim2.fromOffset(12, 0), Enum.Font.Code, C.soft, 12)
	local minus = button(row, "−", UDim2.fromOffset(26, 24), UDim2.new(1, -92, 0.5, -12))
	local val = label(row, "", UDim2.fromOffset(34, 24), UDim2.new(1, -62, 0.5, -12),
		Enum.Font.GothamBold, C.white, 13, Enum.TextXAlignment.Center)
	local plus = button(row, "+", UDim2.fromOffset(26, 24), UDim2.new(1, -26, 0.5, -12))

	local function refresh() val.Text = fmtNum(V[key]) end
	minus.Activated:Connect(function()
		V[key] = math.max(minV, math.floor((V[key] - step) * 100 + 0.5) / 100)
		refresh()
	end)
	plus.Activated:Connect(function()
		V[key] = math.min(maxV, math.floor((V[key] + step) * 100 + 0.5) / 100)
		refresh()
	end)
	refresh()
end

local function switchRow(parent, order, title, desc, getter, setter)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -6, 0, 44)
	row.BackgroundColor3 = C.panel2
	row.BackgroundTransparency = 0.6
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 10)
	label(row, title, UDim2.new(1, -70, 0, 18), UDim2.fromOffset(12, 6), Enum.Font.GothamMedium, C.white, 14)
	local d = label(row, desc, UDim2.new(1, -70, 0, 14), UDim2.fromOffset(12, 24), Enum.Font.Gotham, C.dim, 11)
	d.TextTruncate = Enum.TextTruncate.AtEnd
	local t, k = makeTrack(row)
	paintTrack(t, k, getter())
	t.Activated:Connect(function()
		setter(not getter())
		paintTrack(t, k, getter())
	end)
	return row
end

local function updateFooter()
	if not ST.panelKey then return end
	U.confirmBtn.Text = S[ST.panelKey] and "APPLY" or "CONFIRM"
	U.stopBtn.Visible = S[ST.panelKey] == true
end

local function layoutEmote()
	local show = S.man == true and wrap.Visible
	if ST.mobileLayout and panel.Visible then show = false end
	emotePanel.Visible = show
	local x = 12
	if ST.mobileLayout then
		x = -136
	elseif panel.Visible then
		x = 272
	end
	local y = ST.mobileLayout and 60 or 0
	tw(emotePanel, 0.25, {Position = UDim2.new(1, x, 0, y)})
end

local function openPanel(key)
	local f = FEATURES[key]
	if not f then return end
	ST.panelKey = key
	TG.drafts[key] = TG.targets[key]
	U.panelTitle.Text = f.title
	U.panelDesc.Text = f.desc
	local hasPicker = f.target
	U.pickerHdr.Visible = hasPicker
	U.pickerBtn.Visible = hasPicker
	U.pickerHdr.Text = key == "control" and "FOLLOW TARGET" or "TARGET"
	U.pickerList.Visible = false
	local top = hasPicker and 124 or 74
	U.body.Position = UDim2.fromOffset(12, top)
	U.body.Size = UDim2.new(1, -24, 1, -(top + 58))
	U.body.CanvasPosition = Vector2.zero
	for _, c in ipairs(U.body:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	paintPicker()

	local n = 0
	for _, s in ipairs(f.settings) do
		n += 1
		stepperRow(U.body, n, s)
	end
	if key == "control" then
		n += 1
		switchRow(U.body, n, "Follow target", "Floats the held part above the picked player",
			function() return V.follow end,
			function(v) V.follow = v; updateFooter() end)
		n += 1
		switchRow(U.body, n, "Rotate like player", "Turns the part toward movement or camera",
			function() return V.rotate end,
			function(v) V.rotate = v end)
	end

	updateFooter()
	panel.Visible = true
	layoutEmote()
end

local function closePanel()
	ST.panelKey = nil
	U.pickerList.Visible = false
	panel.Visible = false
	layoutEmote()
end

-- Row helpers
local function refreshRow(key)
	local r = ROWS.refs[key]
	if not r then return end
	paintTrack(r.track, r.knob, S[key] == true)
	if r.desc and r.baseDesc then
		local extra = ""
		if TG.targets[key] and FEATURES[key] and FEATURES[key].target then
			extra = "  ·  " .. targetName(TG.targets[key])
		end
		r.desc.Text = r.baseDesc .. extra
	end
end

local function turnOn(key)
	if S[key] then return end
	if key == "man" and not buildMan() then
		refreshRow(key)
		return
	end
	if key == "vrhands" and not buildHands() then
		refreshRow(key)
		return
	end
	S[key] = true
	refreshRow(key)
	if ST.panelKey == key then updateFooter() end
	layoutEmote()
	notify(FEATURES[key].title .. " enabled")
end

local function turnOff(key, silent)
	if not S[key] then return end
	S[key] = false
	if key == "ownership" then clearOwnerView() end
	if key == "control" then releaseHold() end
	if key == "man" then releaseMan() end
	if key == "vrhands" then
		destroyRig(R.hands)
		R.hands = nil
	end
	if EP[key] then EP[key] = {} end
	refreshRow(key)
	if ST.panelKey == key then updateFooter() end
	layoutEmote()
	if not silent then notify(FEATURES[key].title .. " disabled") end
end

local function onRowSwitch(key)
	if S[key] then
		turnOff(key)
		return
	end
	if needsTargetNow(key) and not TG.targets[key] then
		notify("Pick a target first")
		openPanel(key)
		return
	end
	turnOn(key)
end

local function rowFrame(parent, order, name)
	local row = Instance.new("Frame")
	row.Name = name
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 58)
	row.BackgroundColor3 = C.panel2
	row.BackgroundTransparency = 0.5
	row.BorderSizePixel = 0
	row.Parent = parent
	corner(row, 12)
	stroke(row, C.line, 0.5, 1)
	return row
end

local function makeSection(parent, order, text)
	local l = label(parent, text, UDim2.new(1, -6, 0, 16), UDim2.new(), Enum.Font.Code, C.dim, 11)
	l.LayoutOrder = order
	return l
end

local function featureRow(parent, order, key, title, desc)
	local row = rowFrame(parent, order, key)
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, -70, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Parent = row
	label(hit, title, UDim2.new(1, -16, 0, 18), UDim2.fromOffset(14, 10), Enum.Font.GothamMedium, C.white, 15)
	local d = label(hit, desc, UDim2.new(1, -16, 0, 14), UDim2.fromOffset(14, 32), Enum.Font.Gotham, C.dim, 12)
	hit.Activated:Connect(function()
		playSound(clickSound)
		openPanel(key)
	end)

	local t, k = makeTrack(row)
	ROWS.refs[key] = {track = t, knob = k, desc = d, baseDesc = desc}
	t.Activated:Connect(function()
		playSound(clickSound)
		onRowSwitch(key)
	end)
	refreshRow(key)
	return row
end

local function actionRow(parent, order, key, title, desc)
	local row = rowFrame(parent, order, key)
	label(row, title, UDim2.new(1, -100, 0, 18), UDim2.fromOffset(14, 10), Enum.Font.GothamMedium, C.white, 15)
	label(row, desc, UDim2.new(1, -100, 0, 14), UDim2.fromOffset(14, 32), Enum.Font.Gotham, C.dim, 12)
	local arm = button(row, "ARM", UDim2.fromOffset(60, 26), UDim2.new(1, -74, 0.5, -13))
	arm.TextSize = 12
	ROWS.actionButtons[key] = arm
	arm.Activated:Connect(function() setArmed(key) end)
	return row
end

makeSection(U.trollScroll, 1, "OBJECTS")
featureRow(U.trollScroll, 2, "ownership", "Show network ownership", FEATURES.ownership.desc)
featureRow(U.trollScroll, 3, "jump", "Jump aura", FEATURES.jump.desc)
featureRow(U.trollScroll, 4, "aura", "Block aura", FEATURES.aura.desc)
featureRow(U.trollScroll, 5, "ring", "Block ring", FEATURES.ring.desc)
featureRow(U.trollScroll, 6, "tornado", "Block tornado", FEATURES.tornado.desc)
featureRow(U.trollScroll, 7, "magnet", "Block magnet", FEATURES.magnet.desc)
makeSection(U.trollScroll, 8, "BUILD")
featureRow(U.trollScroll, 9, "man", "Block man", FEATURES.man.desc)
featureRow(U.trollScroll, 10, "vrhands", "VR hands", FEATURES.vrhands.desc)
makeSection(U.trollScroll, 11, "ACTIONS")
actionRow(U.trollScroll, 12, "goto", "Goto object", "Teleport to the next object you click")
actionRow(U.trollScroll, 13, "bring", "Bring object", "Pull the next object you click to you")
makeSection(U.trollScroll, 14, "CONTROL")
featureRow(U.trollScroll, 15, "control", "Control object", FEATURES.control.desc)

switchRow(settingsList, 1, "Notifications", "Toasts when you toggle things",
	function() return ST.notifyOn end,
	function(v) ST.notifyOn = v end)
local previewBtn = button(settingsList, "Preview notification", UDim2.new(1, -6, 0, 40), UDim2.new())
previewBtn.LayoutOrder = 2
previewBtn.Activated:Connect(function() notify("Notification preview") end)
local stopAllBtn = button(settingsList, "Stop all effects", UDim2.new(1, -6, 0, 40), UDim2.new())
stopAllBtn.LayoutOrder = 3
stopAllBtn.Activated:Connect(function()
	local any = false
	for _, k in ipairs(ORDER) do
		if S[k] then
			any = true
			turnOff(k, true)
		end
	end
	V.follow = false
	V.rotate = false
	closePanel()
	if any then notify("All effects stopped") end
end)

U.panelClose.Activated:Connect(closePanel)
U.confirmBtn.Activated:Connect(function()
	local key = ST.panelKey
	if not key then return end
	local f = FEATURES[key]
	if needsTargetNow(key) and not TG.drafts[key] then
		notify("Pick a target first")
		return
	end
	TG.targets[key] = TG.drafts[key]
	if EP[key] then EP[key] = {} end
	if S[key] then
		refreshRow(key)
		notify(f.title .. " updated")
		closePanel()
	else
		turnOn(key)
		closePanel()
	end
end)
U.stopBtn.Activated:Connect(function()
	if ST.panelKey then
		turnOff(ST.panelKey)
		closePanel()
	end
end)

local function switchTab(name)
	if ST.currentTab == name then return end
	closePanel()
	ST.currentTab = name
	for n, e in pairs(ROWS.tabs) do
		tw(e.button, 0.2, {BackgroundColor3 = n == name and C.active or C.panel2})
		tw(e.stroke, 0.2, {Transparency = n == name and 0 or 0.4})
	end
	for n, p in pairs(ROWS.pages) do
		p.Visible = n == name
	end
	U.content.GroupTransparency = 0.6
	tw(U.content, 0.25, {GroupTransparency = 0})
end

local function sideTab(name, symbol, order, iconBuilder)
	local b = Instance.new("TextButton")
	b.Name = name .. "Button"
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(36, 36)
	b.BackgroundColor3 = C.panel2
	b.BackgroundTransparency = 0.3
	b.BorderSizePixel = 0
	b.Text = iconBuilder and "" or symbol
	b.TextColor3 = C.white
	b.TextSize = 19
	b.Font = Enum.Font.GothamMedium
	b.AutoButtonColor = false
	b.Parent = sidebar
	corner(b, 13)
	local st = stroke(b, C.line, 0.4, 1)
	if iconBuilder then iconBuilder(b) end
	ROWS.tabs[name] = {button = b, stroke = st}
	b.Activated:Connect(function()
		playSound(clickSound)
		switchTab(name)
	end)
end
sideTab("Home", "⌂", 1)
sideTab("Troll", "", 2, hammerIcon)
sideTab("Settings", "⚙", 3)

-- ===== Logic loop =====
track(RunService.Heartbeat:Connect(function(dt)
	if ST.closing then return end

	for _, key in ipairs({"aura", "ring", "tornado", "magnet", "jump", "control"}) do
		if TG.targets[key] and not validTarget(TG.targets[key]) then
			TG.targets[key] = nil
			if S[key] and needsTargetNow(key) then
				turnOff(key, true)
				notify(FEATURES[key].title .. " stopped, target left")
			end
			refreshRow(key)
		end
	end

	if S.ownership then
		ST.ownerClock += dt
		if ST.ownerClock >= 0.25 then
			ST.ownerClock = 0
			local h = hrpOf()
			if h then updateOwnerView(h.Position) end
		end
	elseif next(OWN.highlights) then
		clearOwnerView()
	end

	for _, key in ipairs({"aura", "ring", "tornado", "magnet"}) do
		if S[key] and TG.targets[key] then
			local o = targetPos(TG.targets[key])
			if o then runEffect(key, dt, o) end
		else
			EP[key] = {}
		end
	end

	if S.jump and TG.targets.jump then
		local o = targetPos(TG.targets.jump)
		if o then runJump(dt, o) end
	else
		EP.jump = {}
	end

	updateMan(dt)
	updateHands()
	updateHold(dt)
end))

-- ===== Input =====
local function insideWindow(pos)
	return inRect(main, pos) or inRect(panel, pos) or inRect(sidebar, pos) or inRect(emotePanel, pos)
end

track(UserInputService.InputBegan:Connect(function(input, gp)
	local kind = input.UserInputType

	if kind == Enum.UserInputType.MouseButton2 then
		if ST.armed then
			ST.armed = nil
			refreshActions()
			notify("Cancelled")
		end
		if H.part then releaseHold("Dropped") end
		return
	end

	if kind == Enum.UserInputType.Keyboard then
		if gp or not H.part then return end
		if input.KeyCode == Enum.KeyCode.Q then
			V.holdDistance = math.max(3, V.holdDistance - 1)
		elseif input.KeyCode == Enum.KeyCode.E then
			V.holdDistance = math.min(80, V.holdDistance + 1)
		end
		return
	end

	if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then return end

	local pos
	if kind == Enum.UserInputType.Touch then
		pos = Vector2.new(input.Position.X, input.Position.Y)
		ST.lastTouch = pos
	else
		pos = pointerPos()
	end

	if gp or insideWindow(pos) then return end

	local part, dist = rayAt(pos)
	local hrp = hrpOf()

	if ST.armed == "goto" then
		ST.armed = nil
		refreshActions()
		if part and hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 0))
			notify("Teleported to object")
		else
			notify("No object there")
		end
		return
	elseif ST.armed == "bring" then
		ST.armed = nil
		refreshActions()
		if part and canMove(part) and hrp then
			if ownsPart(part) then
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
				part.CFrame = hrp.CFrame * CFrame.new(0, 3, -6)
				notify("Brought object")
			else
				notify("You don't own that object")
			end
		else
			notify("No object there")
		end
		return
	end

	if S.control then
		if H.part then
			releaseHold("Dropped")
		elseif part and canMove(part) then
			grab(part, dist)
		end
	end
end))

track(UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		ST.lastTouch = Vector2.new(input.Position.X, input.Position.Y)
	end
end))

-- ===== Home stats loop =====
task.spawn(function()
	while gui.Parent do
		if ST.currentTab == "Home" and wrap.Visible then
			local ok, ping = pcall(function() return player:GetNetworkPing() * 1000 end)
			U.statVals.PING.Text = ok and string.format("%d ms", math.floor(ping + 0.5)) or "-- ms"
			U.statVals.PLAYERS.Text = string.format("%d / %d", #Players:GetPlayers(), Players.MaxPlayers)
			local names = {}
			for _, k in ipairs(ORDER) do
				if S[k] then
					local tgt = TG.targets[k] and ("  ·  " .. targetName(TG.targets[k])) or ""
					names[#names + 1] = FEATURES[k].title .. tgt
				end
			end
			U.runLabel.Text = #names > 0 and table.concat(names, "   ·   ") or "nothing running"
		end
		task.wait(0.5)
	end
end)

-- ===== Sheen =====
local glare = Instance.new("Frame")
glare.Name = "Sheen"
glare.BackgroundColor3 = C.white
glare.BackgroundTransparency = 1
glare.BorderSizePixel = 0
glare.Size = UDim2.fromScale(1, 1)
glare.ZIndex = 50
glare.Parent = main
corner(glare, 24)
local glareGradient = Instance.new("UIGradient")
glareGradient.Rotation = 28
glareGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.3, 1),
	NumberSequenceKeypoint.new(0.5, 0.82),
	NumberSequenceKeypoint.new(0.7, 1),
	NumberSequenceKeypoint.new(1, 1),
})
glareGradient.Parent = glare

-- Minimize bubble (cat)
local record = Instance.new("TextButton")
record.Name = "RecordRestoreButton"
record.AnchorPoint = Vector2.new(0, 1)
record.Position = UDim2.new(0, 18, 1, -18)
record.Size = UDim2.fromOffset(58, 58)
record.BackgroundColor3 = C.black
record.BackgroundTransparency = 0.2
record.Text = ""
record.Visible = false
record.AutoButtonColor = false
record.ZIndex = 80
record.Parent = gui
corner(record, 100)
stroke(record, Color3.fromRGB(150, 150, 158), 0.4, 1.2)
local recordCat = buildCat(record, 3, 29, 29)
recordCat.ZIndex = 85

record.Activated:Connect(function()
	if not ST.minimized or ST.closing then return end
	playSound(clickSound)
	ST.minimized = false
	record.Visible = false
	wrap.Visible = true
	main.GroupTransparency = 1
	wrapScale.Scale = ST.baseScale * 0.94
	tw(wrapScale, 0.45, {Scale = ST.baseScale})
	tw(main, 0.35, {GroupTransparency = 0})
	layoutEmote()
end)

local function minimize()
	if ST.minimized or ST.closing then return end
	ST.minimized = true
	ST.dragging = false
	closePanel()
	tw(wrapScale, 0.22, {Scale = ST.baseScale * 0.92}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(main, 0.22, {GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.23, function()
		if not ST.minimized or ST.closing or not gui.Parent then return end
		wrap.Visible = false
		record.Visible = true
		record.Size = UDim2.fromOffset(46, 46)
		tw(record, 0.4, {Size = UDim2.fromOffset(58, 58)}, Enum.EasingStyle.Back)
	end)
end
U.minimizeButton.Activated:Connect(minimize)

U.closeButton.Activated:Connect(function()
	if ST.closing then return end
	ST.closing = true
	playSound(clickSound)
	for k in pairs(S) do S[k] = false end
	releaseHold()
	releaseMan()
	destroyRig(R.hands)
	R.hands = nil
	clearOwnerView()
	closePanel()
	tw(wrapScale, 0.35, {Scale = ST.baseScale * 0.92}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw(main, 0.3, {GroupTransparency = 1}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	record.Visible = false
	task.delay(0.4, function()
		if gui.Parent then gui:Destroy() end
	end)
end)

U.header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		ST.dragging = true
		ST.dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
		ST.dragStartOffset = ST.mainOffset
	end
end)

track(UserInputService.InputChanged:Connect(function(input)
	if not ST.dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local p = Vector2.new(input.Position.X, input.Position.Y)
		ST.mainOffset = ST.dragStartOffset + (p - ST.dragStartPos)
		wrap.Position = UDim2.new(0.5, ST.mainOffset.X, 0.5, ST.mainOffset.Y)
	end
end))

track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		ST.dragging = false
	end
end))

-- ===== Frame loop (UI only) =====
track(RunService.RenderStepped:Connect(function(dt)
	if ST.closing then return end

	if dt > 0 then
		ST.smoothFps += ((1 / dt) - ST.smoothFps) * math.min(1, dt * 3)
	end
	U.statVals.FPS.Text = string.format("%d", math.floor(ST.smoothFps + 0.5))

	local targetX, targetY, targetHover = 0, 0, 0
	if wrap.Visible and not ST.minimized and not ST.dragging and UserInputService.MouseEnabled then
		local m = UserInputService:GetMouseLocation()
		local half = main.AbsoluteSize / 2
		local center = main.AbsolutePosition + half
		local dx, dy = m.X - center.X, m.Y - center.Y
		if math.abs(dx) <= half.X and math.abs(dy) <= half.Y then
			targetX = dx / half.X
			targetY = dy / half.Y
			targetHover = 1
		end
	end
	local tiltAlpha = 1 - math.exp(-dt * 9)
	ST.tiltX += (targetX - ST.tiltX) * tiltAlpha
	ST.tiltY += (targetY - ST.tiltY) * tiltAlpha
	ST.hoverAmount += (targetHover - ST.hoverAmount) * tiltAlpha

	main.Rotation = ST.tiltX * 1.6
	starfield.Position = UDim2.fromOffset(-24 - ST.tiltX * 22, -24 - ST.tiltY * 22)
	glare.BackgroundTransparency = 1 - ST.hoverAmount
	glareGradient.Offset = Vector2.new(ST.tiltX * 0.9, ST.tiltY * 0.35)

	if wrap.Visible and not ST.minimized then
		for _, star in ipairs(U.stars) do
			star.x -= star.vx * dt
			star.y += star.vx * 0.25 * dt
			if star.x < -0.02 then
				star.x = 1.02
				star.y = math.random()
			elseif star.y > 1.02 then
				star.y = -0.02
			end
			star.phase += star.rate * dt
			star.dot.Position = UDim2.fromScale(star.x, star.y)
			star.dot.BackgroundTransparency = math.clamp(star.base + math.sin(star.phase) * 0.22, 0, 1)
		end
	end

	if record.Visible then
		record.Rotation = (record.Rotation + dt * 90) % 360
	end

	ST.floatClock += dt
	if not ST.mobileLayout and sidebar.Visible then
		sidebar.Position = UDim2.new(0, -12, 0.5, math.sin(ST.floatClock * 1.2) * 2)
	end
end))

-- ===== Responsive layout =====
local function updateResponsive()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	ST.mobileLayout = vp.X < 700

	if ST.mobileLayout then
		ST.baseScale = math.clamp(math.min(vp.X / 580, vp.Y / 520), 0.45, 1)
		sidebar.AnchorPoint = Vector2.new(0.5, 0)
		sidebar.Position = UDim2.new(0.5, 0, 1, 10)
		sidebar.Size = UDim2.fromOffset(170, 44)
		U.sidebarLayout.FillDirection = Enum.FillDirection.Horizontal
		U.sidebarLayout.Padding = UDim.new(0, 8)
		panel.Position = UDim2.new(0, 0, 0, 0)
		panel.Size = UDim2.new(1, 0, 1, 0)
	else
		ST.baseScale = math.clamp(math.min(vp.X / 920, vp.Y / 440), 0.5, 1)
		sidebar.AnchorPoint = Vector2.new(1, 0.5)
		sidebar.Position = UDim2.new(0, -12, 0.5, 0)
		sidebar.Size = UDim2.fromOffset(52, 176)
		U.sidebarLayout.FillDirection = Enum.FillDirection.Vertical
		U.sidebarLayout.Padding = UDim.new(0, 9)
		panel.Position = UDim2.new(1, 12, 0, 0)
		panel.Size = UDim2.new(0, 250, 1, 0)
	end

	if not ST.minimized and not ST.closing then
		wrapScale.Scale = ST.baseScale
	end
	layoutEmote()
end

updateResponsive()
if workspace.CurrentCamera then
	track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive))
end

-- ===== Loader =====
local bootBlur = Instance.new("BlurEffect")
bootBlur.Name = "IsploitStartupBlur"
bootBlur.Size = 0
bootBlur.Parent = Lighting

local loader = Instance.new("CanvasGroup")
loader.Name = "Loader"
loader.Size = UDim2.fromScale(1, 1)
loader.BackgroundColor3 = C.black
loader.BackgroundTransparency = 0.4
loader.BorderSizePixel = 0
loader.GroupTransparency = 1
loader.ZIndex = 200
loader.Parent = gui

local loaderCenter = Instance.new("Frame")
loaderCenter.BackgroundTransparency = 1
loaderCenter.AnchorPoint = Vector2.new(0.5, 0.5)
loaderCenter.Position = UDim2.fromScale(0.5, 0.5)
loaderCenter.Size = UDim2.fromOffset(260, 170)
loaderCenter.Parent = loader

local badge = Instance.new("Frame")
badge.AnchorPoint = Vector2.new(0.5, 0)
badge.Position = UDim2.new(0.5, 0, 0, 0)
badge.Size = UDim2.fromOffset(76, 76)
badge.BackgroundColor3 = C.black
badge.BackgroundTransparency = 0.1
badge.BorderSizePixel = 0
badge.Parent = loaderCenter
corner(badge, 38)
stroke(badge, Color3.fromRGB(170, 170, 180), 0.5, 1.5)
local badgeScale = Instance.new("UIScale")
badgeScale.Scale = 0.7
badgeScale.Parent = badge
buildCat(badge, 4, 38, 38)

label(loaderCenter, "ISPLOIT", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 92),
	Enum.Font.GothamBold, C.white, 24, Enum.TextXAlignment.Center)

local barTrack = Instance.new("Frame")
barTrack.AnchorPoint = Vector2.new(0.5, 0)
barTrack.Position = UDim2.new(0.5, 0, 0, 138)
barTrack.Size = UDim2.fromOffset(200, 4)
barTrack.BackgroundColor3 = C.panel2
barTrack.BackgroundTransparency = 0.3
barTrack.BorderSizePixel = 0
barTrack.Parent = loaderCenter
corner(barTrack, 2)

local barFill = Instance.new("Frame")
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = C.white
barFill.BorderSizePixel = 0
barFill.Parent = barTrack
corner(barFill, 2)

local barPercent = label(loaderCenter, "0%", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 150),
	Enum.Font.Code, C.soft, 12, Enum.TextXAlignment.Center)
barFill:GetPropertyChangedSignal("Size"):Connect(function()
	barPercent.Text = string.format("%d%%", math.floor(barFill.Size.X.Scale * 100 + 0.5))
end)

switchTab("Home")

task.spawn(function()
	tw(bootBlur, 0.4, {Size = 20}, Enum.EasingStyle.Quad)
	tw(loader, 0.35, {GroupTransparency = 0}, Enum.EasingStyle.Quad)
	tw(badgeScale, 0.6, {Scale = 1}, Enum.EasingStyle.Back)
	task.wait(0.45)
	for _, stage in ipairs({{0.22, 0.45}, {0.51, 0.7}, {0.74, 0.5}, {1, 0.6}}) do
		if not gui.Parent or ST.closing then break end
		local t = tw(barFill, stage[2], {Size = UDim2.new(stage[1], 0, 1, 0)},
			Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		t.Completed:Wait()
		task.wait(0.08)
	end
	if not gui.Parent or ST.closing then
		bootBlur:Destroy()
		return
	end
	task.wait(0.15)
	local blurOut = tw(bootBlur, 0.8, {Size = 0})
	tw(loader, 0.5, {GroupTransparency = 1}, Enum.EasingStyle.Quad)
	tw(loaderCenter, 0.5, {Position = UDim2.fromScale(0.5, 0.48)}, Enum.EasingStyle.Quad)
	main.GroupTransparency = 1
	wrapScale.Scale = ST.baseScale * 0.95
	wrap.Visible = true
	playSound(loadSound)
	tw(wrapScale, 0.65, {Scale = ST.baseScale})
	tw(main, 0.55, {GroupTransparency = 0})
	task.delay(0.55, function()
		if loader.Parent then loader:Destroy() end
	end)
	blurOut.Completed:Wait()
	bootBlur:Destroy()
end)
