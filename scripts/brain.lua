#inlcude "utils.lua"



local MODE_CHASING = 1
local MODE_RUNNING = 2
local MODE_WANDERING = 3



function initBrain()
	local brain = {
		
		excitement_boredom = 0.0,
		energy_tiredness = 0.5,
		calmness_anger = 0.5,
		humor_agitation = 0.25,
		
		prevHumor = 0.5,
		
		mode = MODE_WANDERING,
		modeDuration = 0,
		target = Vec(0, 0, 0),
		prevPlayerDist = getPlayerDist(),
		
	}
	brain_update(brain)
	return brain
end



local lastPrintTime = GetTime()

function brain_update (brain)
	function brain:update (position, dt)
		
		
		-- print stats
		if GetTime() - lastPrintTime > 2.5 then
			lastPrintTime = GetTime()
			print("excitement: " .. brain.excitement_boredom)
			print("energy:     " .. brain.energy_tiredness)
			print("calmness:   " .. brain.calmness_anger)
			print("humor:      " .. brain.humor_agitation)
			print("mode:       " .. brain.mode)
		end
		
		
		-- move towards default
		brain.excitement_boredom = Lerp(brain.excitement_boredom, 0.0, 1 - pow(0.99, dt))
		brain.energy_tiredness = Lerp(brain.energy_tiredness, 0.5, 1 - pow(0.99, dt))
		brain.calmness_anger = Lerp(brain.calmness_anger, 0.5, 1 - pow(0.98, dt))
		brain.humor_agitation = Lerp(brain.humor_agitation, 0.25, 1 - pow(0.98, dt))
		
		
		brain.modeDuration = brain.modeDuration + dt
		
		if brain.mode == MODE_CHASING then
			if brain.modeDuration > 60 then
				brain.calmness_anger = brain.calmness_anger - 0.02 * dt
				brain.excitement_boredom = brain.excitement_boredom - 0.05 * dt
			end
			brain.energy_tiredness = brain.energy_tiredness - 0.01 * dt
			local distIncrease = getPlayerDist(position) - brain.prevPlayerDist
			brain.humor_agitation = brain.humor_agitation - max(distIncrease, 0) / 200
			if brain.calmness_anger < 0.25 then
				brain.calmness_anger = brain.calmness_anger + max(-distIncrease, 0) / 200
			end
		end
		
		if brain.mode == MODE_RUNNING then
			
		end
		
		if brain.mode == MODE_WANDERING then
			brain.excitement_boredom = brain.excitement_boredom - 0.02 * dt
		end
		
		
		
		if getPlayerDist(position) < 6 and brain.humor_agitation < 0.5 then
			brain.humor_agitation = brain.humor_agitation + 0.05 * dt
		end
		
		if brain.humor_agitation < -0.5 and (brain.humor_agitation - brain.prevHumor) / dt < -0.1 then
			print((brain.humor_agitation - brain.prevHumor) / dt)
			for i=1,10 do
				print("LAUGH")
			end
			brain.humor_agitation = atan(brain.humor_agitation - 1) / 2.5 + 1 -- idk just look at desmos
		end
		
		if brain.humor_agitation < -0.5 and brain.energy_tiredness > -0.5 then
			brain.energy_tiredness = brain.energy_tiredness - 0.01 * dt
		end
		if brain.energy_tiredness < -0.5 and brain.humor_agitation > -0.5 then
			brain.humor_agitation = brain.humor_agitation - 0.01 * dt
		end
		
		if brain.excitement_boredom > 0.75 and brain.humor_agitation < 0.75 then
			brain.humor_agitation = brain.humor_agitation + 0.01 * dt
		end
		if brain.humor_agitation > 0.9 and brain.excitement_boredom < 0.75 then
			brain.excitement_boredom = brain.excitement_boredom + 0.01 * dt
		end
		
		if brain.calmness_anger < -0.5 and brain.energy_tiredness > -0.5 then
			brain.energy_tiredness = brain.energy_tiredness - 0.01 * dt
		end
		
		if brain.energy_tiredness > 0.75 and brain.excitement_boredom < 0.5 then
			brain.excitement_boredom = brain.excitement_boredom + 0.01 * dt
		end
		
		
		
		-- switch mode?
		if brain.excitement_boredom < 0.25 and brain.energy_tiredness > 0 then
			print("switched to chasing")
			brain.mode = MODE_CHASING
			brain.excitement_boredom = brain.excitement_boredom + 0.75
		end
		if brain.energy_tiredness < -0.5 then
			print("switched to running")
			brain.mode = MODE_RUNNING
			if math.random() < 0.5 then
				brain.humor_agitation = brain.humor_agitation + 0.75
			end
		end
		
		
		-- set target
		if brain.mode == MODE_CHASING then
			brain.target = GetPlayerPos()
		end
		
		
		brain.prevPlayerDist = getPlayerDist(position)
		brain.prevHumor = brain.humor_agitation
		
		
	end
end



function getPlayerDist (position)
	local playerPos = GetPlayerPos()
	return GetDist(position, playerPos)
end
