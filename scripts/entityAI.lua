#include "utils.lua"



function initEntityAI()
	local entityAI = {}
	entityAI_initEmptyBot(entityAI)
	entityAI_initBot(entityAI)
	return entityAI
end



function entityAI_initEmptyBot (entityAI)
	function entityAI:initEmptyBot()
		return {
			position = Vec(0, 0, 0)
		}
	end
end



function entityAI_initBot (entityAI)
	function entityAI:initBot (position, settings)
		local bot = {}
		
		
		-- bot settings
		bot.speed = settings.speed or 6
		bot.forwardDragCoef = settings.forwardDragCoef or 1
		bot.backwardDragCoef = settings.backwardDragCoef or 0.25
		bot.isPathingModeDragCoefMult = settings.isPathingModeDragCoefMult or 0
		bot.isPathingModeSpeedMult = settings.isPathingModeSpeedMult or 30
		bot.canPushObjects = (settings.canPushObjects ~= nil) and settings.canPushObjects or true
		bot.maxPathComputeTime = settings.maxPathComputeTime or 5
		bot.simplifiedCollisionLogic = settings.simplifiedCollisionLogic or false
		
		bot.functions = settings.functions or {}
		local fns = bot.functions
		fns.onPathingFinished   = fns.onPathingFinished   or BlankFunction
		fns.onPathingFailed     = fns.onPathingFailed     or BlankFunction
		fns.onPathingAborted    = fns.onPathingAborted    or BlankFunction
		fns.onNanVelocity       = fns.onNanVelocity       or BlankFunction
		fns.getTarget           = fns.getTarget           or GetPlayerPos
		fns.forceSetPathingMode = fns.forceSetPathingMode or BlankFunction -- returns true, false, or nil
		
		
		-- bot vars
		bot.position = position or Vec(0, 0, 0)
		bot.velocity = Vec(0, 0, 0)
		bot.isOnGround = false
		bot.isStuck = false
		bot.tickNum = 0
		
		bot.currentPath = {}
		bot.pathResultAcknowledged = false
		bot.pathQueryStart = nil
		bot.pathQueryEnd = nil
		bot.lastPathPos = nil
		bot.pathComputeTime = 0
		bot.pathWillContinue = false
		bot.isPathingMode = false
		
		
		bot_update(bot)
		bot_updateNavigation(bot)
		bot_move(bot)
		bot_jump(bot)
		
		return bot
		
	end
end





function bot_update (bot)
	function bot:update (dt)
		bot.tickNum = bot.tickNum + 1
		bot:updateNavigation(dt)
		bot:move(dt)
	end
end



function bot_updateNavigation (bot)
	function bot:updateNavigation (dt)
		local pathState = GetPathState()
		local targetPos = bot.functions.getTarget()
		
		
		if pathState == "busy" then
			bot.pathComputeTime = bot.pathComputeTime + dt
			if bot.pathComputeTime > bot.maxPathComputeTime then
				--DebugPrint("aborting path")
				AbortPath()
				bot.functions.onPathingAborted()
			end
		end
		
		
		if pathState == "done" and not bot.pathResultAcknowledged then
			--DebugPrint("pathing done")
			bot.pathResultAcknowledged = true
			
			local newPath = retrievePath()
			setPath(bot, newPath)
			
			if
				(#bot.currentPath > 0 and GetDist(bot.lastPathPos, bot.pathQueryEnd) > 2)
				and (targetPos[2] - bot.lastPathPos[2] > 0.25) -- target pos is 0.25 higher than last pos
				and (bot.lastPathPos[2] - bot.position[2] > 0.5) -- last pos is 0.5 higher than bot pos
			then
				--DebugPrint("continuing path (A)")
				bot.pathWillContinue = true
				startPathQuery(bot, lastPathPos, targetPos)
				return
			end
			
			bot.pathWillContinue = false
			bot.functions.onPathingFinished()
			
		end
		
		
		if pathState == "fail" and not bot.pathResultAcknowledged then
			--DebugPrint("pathing failed")
			bot.pathResultAcknowledged = true
			
			local failedPath = retrievePath()
			local lastPathPos = CopyVec(Last(failedPath))
			if
				lastPathPos
				and (targetPos[2] - lastPathPos[2] > 0.25) -- target pos is 0.25 higher than last pos
				and (lastPathPos[2] - bot.position[2] > 0.75) -- last pos is 0.75 higher than bot pos
			then
				--DebugPrint("continuing path (B)")
				setPath(bot, failedPath)
				bot.pathWillContinue = true
				startPathQuery(bot, lastPathPos, targetPos)
				return
			end
			
			bot.pathWillContinue = false
			bot.functions.onPathingFailed()
			
		end
		
		
		if
			(pathState ~= "busy" and (#bot.currentPath < 2 or GetDist(bot.pathQueryEnd, targetPos) > 3))
			or (GetHorizDist(bot.position, bot.pathQueryStart or bot.currentPath[1] or bot.position) > 4)
			and not bot.pathWillContinue
		then
			--DebugPrint("restarting pathing")
			bot.pathWillContinue = false
			startPathQuery(bot, bot.position, targetPos)
		end
		
		
	end
end



function startPathQuery (bot, startingPos, targetPos)
	AbortPath()
	QueryRequire("physical static")
	QueryPath(startingPos, targetPos, 20, 0.75, "standard")
	bot.pathComputeTime = 0
	bot.pathQueryStart = bot.position
	bot.pathQueryEnd = targetPos
	bot.pathResultAcknowledged = false
end



function retrievePath()
	local pathLength = GetPathLength()
	local newPath = {}
	for i=1, pathLength do
		table.insert(newPath, GetPathPoint(i))
	end
	return newPath
end



function setPath (bot, newPath)
	newPath = WidenCurves(newPath)
	if not bot.pathWillContinue then bot.currentPath = {} end
	Append(bot.currentPath, newPath)
	bot.lastPathPos = CopyVec(Last(bot.currentPath))
end



function bot_move (bot)
	function bot:move (dt)
		
		setIsPathingMode(bot)
		
		
		-- get point to move to
		local alternateTarget = CopyVec(bot.pathWillContinue and bot.lastPathPos or bot.functions.getTarget())
		alternateTarget[2] = bot.position[2]
		
		if #bot.currentPath > 0 and bot.currentPath[1][2] - bot.position[2] > 3 then
			AbortPath()
			bot.currentPath = {}
			bot.pathWillContinue = false
		end
		
		trimPath(bot)
		local currentTarget = bot.currentPath[1] or alternateTarget
		currentTarget = VecAdd(currentTarget, Vec(0, 0.4, 0))
		
		
		-- update velocity
		local position_to_target = VecSub(currentTarget, bot.position)
		local velocity_dot_targetVec = VecDot(VecNormalize(bot.velocity), VecNormalize(position_to_target))
		local lerpAmount = FitInRange(velocity_dot_targetVec * 10, 0, 1)
		local dragCoef = Lerp(bot.backwardDragCoef, bot.forwardDragCoef, lerpAmount)
		dragCoef = dragCoef * (bot.isPathingMode and bot.isPathingModeDragCoefMult or 1)
		bot.velocity[1] = bot.velocity[1] * pow(dragCoef, dt)
		bot.velocity[2] = bot.velocity[2] * pow(0.9, dt)
		bot.velocity[3] = bot.velocity[3] * pow(dragCoef, dt)
		
		local wantedVelocity = VecSetSacle(position_to_target, bot.speed * dt * (bot.isPathingMode and bot.isPathingModeSpeedMult or 1))
		bot.velocity[1] = bot.velocity[1] + wantedVelocity[1]
		bot.velocity[2] = bot.velocity[2] + (IsPointInWater(bot.position) and 5 * dt or - 9.8 * dt)
		bot.velocity[3] = bot.velocity[3] + wantedVelocity[3]
		
		-- hopefully stops nan positions
		if VecLength(bot.velocity) ~= VecLength(bot.velocity) then
			bot.velocity = Vec(0, 0, 0)
			bot.functions.onNanVelocity()
		end
		
		
		-- move
		applyVelocity(bot, dt)
		
		
		-- move to top of ground
		QueryRequire("physical")
		local groundTestLift = 0.5
		local groundHit, groundDist = QueryRaycast(bot.position, Vec(0, -1, 0), 0.4 + groundTestLift, 0.1)
		bot.isOnGround = groundHit
		if groundHit then
			groundDist = groundDist - 0.4 - groundTestLift
			bot.position[2] = bot.position[2] - groundDist
			bot.velocity[2] = math.max(bot.velocity[2], 0)
		end
		
		
	end
end



function trimPath (bot)
	if #bot.currentPath == 0 then return nil end
	
	-- if the bot has reached a point ('point A') that's further into the path, trim the path to 'point A'
	for i=#bot.currentPath, 1, -1 do
		if GetDist(bot.position, bot.currentPath[i]) < (bot.isPathingMode and 0.5 or 1) then
			for j=1, i do
				table.remove(bot.currentPath, 1)
			end
			return
		end
	end
	
	-- if the bot has reached the next point, remove the point
	if GetDist(bot.position, bot.currentPath[1]) < (bot.isPathingMode and 1 or 1.5) then
		table.remove(bot.currentPath, 1)
	end
	
end



function applyVelocity (bot, dt)
	bot.isStuck = false
	
	-- move forward
	local newPosition = VecAdd(bot.position, VecScale(bot.velocity, dt))
	QueryRequire("physical static")
	--local hit = QueryRaycast(bot.position, bot.velocity, 0.1, 0.2)
	local hit = QueryClosestPoint(newPosition, 0.4)
	if not hit then
		bot.position = newPosition
		return
	end
	
	-- move forward and up
	local newPositionLifted = CopyVec(newPosition)
	newPositionLifted[2] = newPositionLifted[2] + 0.3
	QueryRequire("physical static")
	--hit = QueryRaycast(VecAdd(bot.position, Vec(0, 0.3, 0)), bot.velocity, 0.1, 0.3)
	hit = QueryClosestPoint(newPositionLifted, 0.5)
	if not hit then
		bot.position = newPositionLifted
		return
	end
	
	if not simplifiedCollisionLogic then
		
		-- move only x
		local newPositionX = CopyVec(newPosition)
		newPositionX[2] = bot.position[2]
		newPositionX[3] = bot.position[3]
		QueryRequire("physical static")
		--hit = QueryRaycast(VecAdd(bot.position, Vec(0, 0.3, 0)), bot.velocity, 0.1, 0.3)
		hit = QueryClosestPoint(newPositionX, 0.35)
		if not hit then
			bot.position = newPositionX
			bot.velocity[2] = bot.velocity[2] * 0.1
			bot.velocity[3] = bot.velocity[3] * 0.1
			return
		end
		
		-- move only z
		local newPositionZ = CopyVec(newPosition)
		newPositionZ[1] = bot.position[1]
		newPositionZ[2] = bot.position[2]
		QueryRequire("physical static")
		--hit = QueryRaycast(VecAdd(bot.position, Vec(0, 0.3, 0)), bot.velocity, 0.1, 0.3)
		hit = QueryClosestPoint(newPositionZ, 0.35)
		if not hit then
			bot.position = newPositionZ
			bot.velocity[1] = bot.velocity[1] * 0.1
			bot.velocity[2] = bot.velocity[2] * 0.1
			return
		end
		
		-- move only y
		local newPositionY = CopyVec(newPosition)
		newPositionY[1] = bot.position[1]
		newPositionY[3] = bot.position[3]
		QueryRequire("physical static")
		--hit = QueryRaycast(VecAdd(bot.position, Vec(0, 0.3, 0)), bot.velocity, 0.1, 0.3)
		hit = QueryClosestPoint(newPositionY, 0.35)
		if not hit then
			bot.position = newPositionY
			bot.velocity[1] = bot.velocity[1] * 0.1
			bot.velocity[3] = bot.velocity[3] * 0.1
			return
		end
		
	end
	
	bot.isStuck = true
	bot.position = VecAdd(bot.position, VecScale(bot.velocity, dt * -0.1))
	bot.velocity[1] = bot.velocity[1] * 0.1
	bot.velocity[2] = bot.velocity[2] * 0.1
	bot.velocity[3] = bot.velocity[3] * 0.1
	
end



function setIsPathingMode (bot)
	
	local forcedPathingMode = bot.functions.forceSetPathingMode()
	if type(forcedPathingMode) == "boolean" then
		bot.isPathingMode = forcedPathingMode
		return
	end
	
	local botTarget = bot.functions.getTarget()
	bot.isPathingMode =
		(botTarget[2] - bot.position[2] > 3) -- if player is above bot
		or (GetDist(botTarget, bot.position) > 50) -- or player is far from bot
	
end





function bot_jump (bot)
	function bot:jump (height)
		if not bot.isOnGround then return end
		local dy = height - bot.position[2]
		bot.velocity[2] = 4.42718872424 * math.sqrt(dy) -- = 9.8 * sqrt(dy / 4.9)
	end
end
