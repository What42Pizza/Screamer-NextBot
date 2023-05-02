-- started 23/05/01
-- last updated 23/05/02

-- scripting docs: https://teardowngame.com/modding/api.html



local MODE_CHASING = 1
local MODE_RUNNING = 2
local MODE_WANDERING = 3



#include "utils.lua"
#include "entityAI.lua"
#include "brain.lua"
local entityAI = initEntityAI()
local brain = initBrain()



local bot = entityAI:initEmptyBot()

local loaded = false



------- SETTINGS -------
local speed = 7.5
local maxPathComputeTime = 5
local canPlaySounds = true
local canJump = true
local canPushObjects = true
local canExplode = true
local canExplodeVehicles = true
local disableOnKill = true
local resetBadPositions = true
local simplifiedCollisionLogic = false
local debugMode = false



local texture = LoadSprite("MOD/images/current.png")
local chasingSound = LoadSound("MOD/sounds/chasing.ogg")
local killSound = LoadSound("MOD/sounds/kill.ogg")

local isDisabled = false

local timesFailed = 0
local timeStuck = 0
local framesOnIsStuck = 0
local framesOnNotStuck = 0
local lastUnstuckTime = 0
local recentPositions = {}

local isSpawned = false
local timeSinceStart = 0.0
local tickNum = 0

local chasingSoundLength = 1.1
local timeSinceChasingSoundPlayed = chasingSoundLength + 0.123



-- code to run to update settings
local updateSettingsFunctions = {
	
	function() -- if on version 1
		if debugMode then print("Settings are up to date") end
	end,
	
	-- UPDATE OPTIONS.LUA INIT() TOO
	
}



function init()
	isSpawned = false
	
	
	speed = GetFloatOr("savegame.mod.ScreamerNextBot.speed", speed)
	maxPathComputeTime = GetFloatOr("savegame.mod.ScreamerNextBot.maxPathComputeTime", maxPathComputeTime)
	canPlaySounds = GetBoolOr("savegame.mod.ScreamerNextBot.canPlaySounds", canPlaySounds)
	canPushObjects = GetBoolOr("savegame.mod.ScreamerNextBot.canPushObjects", canPushObjects)
	canJump = GetBoolOr("savegame.mod.ScreamerNextBot.canJump", canJump)
	canExplode = GetBoolOr("savegame.mod.ScreamerNextBot.canExplode", canExplode)
	canExplodeVehicles = GetBoolOr("savegame.mod.ScreamerNextBot.canExplodeVehicles", canExplodeVehicles)
	disableOnKill = GetBoolOr("savegame.mod.ScreamerNextBot.disableOnKill", disableOnKill)
	resetBadPositions = GetBoolOr("savegame.mod.ScreamerNextBot.resetBadPositions", resetBadPositions)
	simplifiedCollisionLogic = GetBoolOr("savegame.mod.ScreamerNextBot.simplifiedCollisionLogic", simplifiedCollisionLogic)
	debugMode = GetBoolOr("savegame.mod.ScreamerNextBot.debugMode", debugMode)
	
	
	-- update options to fix balancing
	local currentSettingsVersion = #updateSettingsFunctions
	local savedOptionsVersion = GetIntOr("savegame.mod.ScreamerNextBot.savedOptionsVersion", currentSettingsVersion)
	for i=savedOptionsVersion, currentSettingsVersion do
		updateSettingsFunctions[i]()
	end
	SetInt("savegame.mod.ScreamerNextBot.savedOptionsVersion", currentSettingsVersion)
	
	
	loaded = true
end





function tick(dt)
	
	--if timeSinceStart > 5 then
	--	isDisabled = true
	--	return
	--end
	
	if not loaded then
		init()
	end
	
	
	-- basics
	if isDisabled then return end
	if bot.position[2] < -500 then
		disableOrReset(not resetBadPositions, "Notice: nextbot has fallen off the map (and is now disabled)", "Notice: nextbot position reset due to falling off map")
		if isDisabled then return end
	end
	if bot.position[2] < -1000 then
		disableOrReset(not resetBadPositions, "Notice: nextbot has gone above the map (and is now disabled)", "Notice: nextbot position reset due to going above map")
		if isDisabled then return end
	end
	if VecLength(bot.position) ~= VecLength(bot.position) then
		disableOrReset(not resetBadPositions, "Notice: nextbot has a nan position (and is now disabled)", "Notice: nextbot position reset due to being invalid")
		if isDisabled then return end
	end
	timeSinceStart = timeSinceStart + dt
	
	
	-- spawning (wait for placement and set position to placed pos)
	if not isSpawned then
		local camTransform = GetCameraTransform()
		
		local dir = TransformToParentVec(camTransform, Vec(0, 0, -1))
		local hit, d, n = QueryRaycast(camTransform.pos, dir, 100)
		if not hit then return end
		
		local hitPoint = VecAdd(camTransform.pos, VecScale(dir, d))
		local newPosition = VecAdd(hitPoint, Vec(0,1,0))
		bot.position = newPosition
		if InputDown("lmb") and timeSinceStart > 0.1 then
			bot = initBot(newPosition)
			isSpawned = true
		end
		return
	end
	
	
	-- debug mode
	if debugMode and bot.currentPath then
		for i=2, #bot.currentPath do
			DebugLine(bot.currentPath[i-1],bot.currentPath[i], 1, 1, 1, 1)
		end
		DebugCross(bot.position, 1, 1, 1, 1)
		DebugCross(bot.pathQueryStart, 1, 0, 0, 1)
		DebugCross(bot.pathQueryEnd, 1, 0, 0, 1)
	end
	
	
	-- update brain
	brain:update(bot.position, dt)
	
	
	-- update bot
	table.insert(recentPositions, bot.position)
	if #recentPositions > 5 then
		table.remove(recentPositions, 1)
	end
	bot:update(dt)
	
	
	-- throw objects & explode vehicles
	if bot.tickNum % 10 == 0 and (canPushObjects or canExplodeVehicles) then
		QueryRequire("physical dynamic large")
		local hit, _, _, shape = QueryClosestPoint(bot.position, 3)
		if hit then
			local body = GetShapeBody(shape)
			if canPushObjects then
				SetBodyVelocity(body, VecScale(bot.velocity, -5))
			end
			if canExplodeVehicles then
				local bodyVehicle = GetBodyVehicle(body)
				local playerVehicle = GetPlayerVehicle()
				if bodyVehicle ~= 0 and bodyVehicle == playerVehicle then
					if debugMode then print("destroying player's vehicle") end
					local pos = GetBodyTransform(body).pos
					MakeHole(pos, 5, 5, 3)
					SetPlayerVehicle(0)
				end
			end
		end
	end
	
	
	-- unstuck self
	if bot.isStuck then
		framesOnIsStuck = framesOnIsStuck + 1
		framesOnNotStuck = 0
	else
		framesOnIsStuck = 0
		framesOnNotStuck = framesOnNotStuck + 1
	end
	local lowMovement = GetDist(bot.position, recentPositions[1]) < 0.3
	if (framesOnIsStuck > 1 or lowMovement) and #bot.currentPath > 0 then
		timeStuck = timeStuck + dt
	end
	if framesOnNotStuck > 3 and not lowMovement then
		timeStuck = 0
	end
	if timeStuck > 1 then
		if debugMode then print("unstucking (moving up)") end
		bot.position[2] = bot.position[2] + 1
		timeStuck = 0
	end
	
	
	-- kill player and disable
	if GetPlayerHealth() > 0.0 and GetDist(bot.position, GetPlayerPos()) < 1.5 then
		SetPlayerHealth(0.0)
		if canPlaySounds then PlaySound(killSound, GetPlayerPos(), 1) end
		disableOrReset(disableOnKill)
		if isDisabled then return end
	end
	
	
	-- play chase music
	if brain.mode == MODE_CHASING then
		timeSinceChasingSoundPlayed = timeSinceChasingSoundPlayed + dt
		if canPlaySounds and timeSinceChasingSoundPlayed >= chasingSoundLength then
			local playerPos = GetPlayerPos()
			local distToPlayer = GetDist(playerPos, bot.position)
			distToPlayer = math.pow(distToPlayer, 0.75)
			PlaySound(chasingSound, playerPos, math.min(3/distToPlayer, 1))
			timeSinceChasingSoundPlayed = 0
		end
	end
	
	
	tickNum = tickNum + 1
	if debugMode and tickNum % 60 == 0 then
		print("bot dist: " .. GetDist(GetPlayerPos(), bot.position))
	end
	
	
end



function draw()
	if isDisabled then return end
	
	local faceT = Transform(VecAdd(bot.position,Vec(0, 0.55, 0)), QuatLookAt(bot.position, GetCameraTransform().pos))
	DrawSprite(texture, faceT, 2.5, 2.5, 1, 1, 1, 1, true)
	
end





function initBot (position)
	return entityAI:initBot(position, {
		
		speed = speed/10,
		maxPathComputeTime = maxPathComputeTime,
		canPushObjects = canPushObjects,
		simplifiedCollisionLogic = simplifiedCollisionLogic,
		
		functions = {
			
			getTarget = function()
				return brain.target
			end,
			
			onPathingFinished = function()
				if
					(#bot.currentPath == 0 and GetDist(bot.position, targetPos) > 3) -- level-ish ground, no path generated
					or (#bot.currentPath > 0 and GetDist(bot.lastPathPos, bot.pathQueryEnd) > 2) -- path doesn't end at desired point
				then
					timesFailed = timesFailed + 1
					unstuck("pathing did not reach target")
				else
					if debugMode then print("new path") end
					timesFailed = 0
				end
			end,
			
			onPathingFailed = function()
				timesFailed = timesFailed + 1
				unstuck("pathing failed")
			end,
			
			onPathingAborted = function()
				timesFailed = timesFailed + 1
				unstuck("pathing aborting")
			end,
			
			onNanVelcoty = function()
				if debugMode then print("warning: nan velocity") end
				bot.position[2] = bot.position[2] + 1
			end,
			
			forceSetPathingMode = function()
				if GetPlayerVehicle() ~= 0 then return false end -- chase if player is in vehicle
				return nil -- else, use default logic
			end,
			
		},
		
	})
end



function unstuck (reason)
	
	if timeSinceStart - lastUnstuckTime < 2 then return end
	lastUnstuckTime = timeSinceStart
	
	if debugMode then print("untucking... (" .. reason .. ")") end
	
	local playerPos = GetPlayerPos()
	
	if canJump and playerPos[2] - bot.position[2] > 3 and Chance(75) then
		if debugMode then print("unstuck:jump1") end
		bot:jump(playerPos[2] + 2)
		return
	end
	
	if canExplode and Chance(math.min(50 + timesFailed * 10, 90)) then
		if debugMode then print("unstuck:MakeHole") end
		MakeHole(VecAdd(bot.position, Vec(0, 3, 0)), 5, 5, 3)
		MakeHole(VecAdd(bot.position, Vec(0, 6, 0)), 3, 3, 2)
		return
	end
	
	if canJump and Chance(50) then
		if debugMode then print("unstuck:jump2") end
		bot:jump(playerPos[2] + 2)
		return
	end
	
	if debugMode then print("no unstuck chosen") end
	
end



function disableOrReset (condition, msg1, msg2)
	if condition then
		isDisabled = true
		if msg1 then DebugPrint(msg1) end
	else
		local playerPos = GetPlayerPos()
		bot.position = VecAdd(playerPos, Vec(0, 50, 0))
		bot.velocity = Vec(0, 0, 0)
		if msg2 then DebugPrint(msg2) end
	end
end
