#include "scripts/utils.lua"



local loaded = false

local defaultSpeed = 75
local defaultMaxPathComputeTime = 5
local defaultCanPlaySounds = true
local defaultCanJump = true
local defaultCanPushObjects = true
local defaultCanExplode = true
local defaultCanExplodeVehicles = true
local defaultDisableOnKill = true
local defaultResetBadPositions = true
local defaultSimplifiedCollisionLogic = false
local defaultDebugMode = false

local speed
local maxPathComputeTime
local canPlaySounds
local canJump
local canPushObjects
local canExplode
local canExplodeVehicles
local disableOnKill
local resetBadPositions
local simplifiedCollisionLogic
local debugMode



function init()
	
	if not HasKey("savegame.mod.ScreamerNextBot.savedOptionsVersion") then
		reset()
		SetInt("savegame.mod.ScreamerNextBot.savedOptionsVersion", 2)
	end
	
	speed                    = GetFloatOr("savegame.mod.ScreamerNextBot.speed"                  , defaultSpeed                   )
	maxPathComputeTime       = GetFloatOr("savegame.mod.ScreamerNextBot.maxPathComputeTime"     , defaultMaxPathComputeTime      )
	canPlaySounds            = GetBoolOr("savegame.mod.ScreamerNextBot.canPlaySounds"           , defaultCanPlaySounds           )
	canJump                  = GetBoolOr("savegame.mod.ScreamerNextBot.canJump"                 , defaultCanJump                 )
	canPushObjects           = GetBoolOr("savegame.mod.ScreamerNextBot.canPushObjects"          , defaultCanPushObjects          )
	canExplode               = GetBoolOr("savegame.mod.ScreamerNextBot.canExplode"              , defaultCanExplode              )
	canExplodeVehicles       = GetBoolOr("savegame.mod.ScreamerNextBot.canExplodeVehicles"      , defaultCanExplodeVehicles      )
	disableOnKill            = GetBoolOr("savegame.mod.ScreamerNextBot.disableOnKill"           , defaultDisableOnKill           )
	resetBadPositions        = GetBoolOr("savegame.mod.ScreamerNextBot.resetBadPositions"       , defaultResetBadPositions       )
	simplifiedCollisionLogic = GetBoolOr("savegame.mod.ScreamerNextBot.simplifiedCollisionLogic", defaultSimplifiedCollisionLogic)
	debugMode                = GetBoolOr("savegame.mod.ScreamerNextBot.debugMode"               , defaultDebugMode               )
	
	loaded = true
end





function draw()
	
	if not loaded then
		init()
	end
	
	UiFont("regular.ttf", 24)
	
	UiPush()
		local text = "Option explanations are on the steam page"
		UiTranslate(UiCenter() - UiGetTextSize(text)/2, UiMiddle()-200)
		UiText(text)
	UiPop()
	
	UiPush()
		UiAlign("right middle")
		UiTranslate(UiCenter()-150, UiMiddle()-150)
		UiText("Speed:")
		UiTranslate(30, 0)
		UiAlign("left middle")
		UiColor(1, 1, 1,0.5)
		UiRect(300, 3)
		UiColor(1, 1, 1,1)
		UiAlign("center middle")
		speed = math.floor(UiSlider("ui/common/dot.png", "x", speed, 1, 300))
		UiAlign("left middle")
		UiTranslate(310, 0)
		UiText(speed .. "")
		SetFloat("savegame.mod.ScreamerNextBot.speed", speed)
	UiPop()
	
	UiPush()
		UiAlign("right middle")
		UiTranslate(UiCenter()-150, UiMiddle()-100)
		UiText("Max path compute time:")
		UiTranslate(30, 0)
		UiAlign("left middle")
		UiColor(1, 1, 1,0.5)
		UiRect(300, 3)
		UiColor(1, 1, 1,1)
		UiAlign("center middle")
		maxPathComputeTime = math.floor(UiSlider("ui/common/dot.png", "x", maxPathComputeTime * 3, 1, 300) / 3)
		UiAlign("left middle")
		UiTranslate(310, 0)
		UiText(maxPathComputeTime)
		SetFloat("savegame.mod.ScreamerNextBot.maxPathComputeTime", maxPathComputeTime)
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()-50)
		if UiTextButton("Play sounds: " .. tostring(canPlaySounds)) then
			canPlaySounds = not canPlaySounds
			SetBool("savegame.mod.ScreamerNextBot.canPlaySounds", canPlaySounds)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle())
		if UiTextButton("Can jump: " .. tostring(canJump)) then
			canJump = not canJump
			SetBool("savegame.mod.ScreamerNextBot.canJump", canJump)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+50)
		if UiTextButton("Can push objects: " .. tostring(canPushObjects)) then
			canPushObjects = not canPushObjects
			SetBool("savegame.mod.ScreamerNextBot.canPushObjects", canPushObjects)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+100)
		if UiTextButton("Can explode: " .. tostring(canExplode)) then
			canExplode = not canExplode
			SetBool("savegame.mod.ScreamerNextBot.canExplode", canExplode)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+150)
		if UiTextButton("Can explode vehicles: " .. tostring(canExplodeVehicles)) then
			canExplodeVehicles = not canExplodeVehicles
			SetBool("savegame.mod.ScreamerNextBot.canExplodeVehicles", canExplodeVehicles)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+200)
		if UiTextButton("Disable on kill: " .. tostring(disableOnKill)) then
			disableOnKill = not disableOnKill
			SetBool("savegame.mod.ScreamerNextBot.disableOnKill", disableOnKill)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+250)
		if UiTextButton("Reset bad positions: " .. tostring(resetBadPositions)) then
			resetBadPositions = not resetBadPositions
			SetBool("savegame.mod.ScreamerNextBot.resetBadPositions", resetBadPositions)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+300)
		if UiTextButton("Simplified collision logic: " .. tostring(simplifiedCollisionLogic)) then
			simplifiedCollisionLogic = not simplifiedCollisionLogic
			SetBool("savegame.mod.ScreamerNextBot.simplifiedCollisionLogic", simplifiedCollisionLogic)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiTranslate(UiCenter(), UiMiddle()+350)
		if UiTextButton("Debug mode: " .. tostring(debugMode)) then
			debugMode = not debugMode
			SetBool("savegame.mod.ScreamerNextBot.debugMode", debugMode)
		end
	UiPop()
	
	UiPush()
		UiAlign("center middle")
		UiColor(1, 0.5, 0.5,1)
		UiTranslate(UiCenter(), UiMiddle()+400)
		if UiTextButton("Reset") then
			reset()
		end
	UiPop()
	
end



function reset()
	speed = defaultSpeed
	SetBool("savegame.mod.ScreamerNextBot.speed", speed)
	maxPathComputeTime = defaultMaxPathComputeTime
	SetBool("savegame.mod.ScreamerNextBot.maxPathComputeTime", maxPathComputeTime)
	canPlaySounds = defaultCanPlaySounds
	SetBool("savegame.mod.ScreamerNextBot.canPlaySounds", canPlaySounds)
	canJump = defaultCanJump
	SetBool("savegame.mod.ScreamerNextBot.canJump", canJump)
	canPushObjects = defaultCanPushObjects
	SetBool("savegame.mod.ScreamerNextBot.canPushObjects", canPushObjects)
	canExplode = defaultCanExplode
	SetBool("savegame.mod.ScreamerNextBot.canExplode", canExplode)
	canExplodeVehicles = defaultCanExplodeVehicles
	SetBool("savegame.mod.ScreamerNextBot.canExplodeVehicles", canExplodeVehicles)
	disableOnKill = defaultDisableOnKill
	SetBool("savegame.mod.ScreamerNextBot.disableOnKill", disableOnKill)
	resetBadPositions = defaultResetBadPositions
	SetBool("savegame.mod.ScreamerNextBot.resetBadPositions", resetBadPositions)
	simplifiedCollisionLogic = defaultSimplifiedCollisionLogic
	SetBool("savegame.mod.ScreamerNextBot.simplifiedCollisionLogic", simplifiedCollisionLogic)
	debugMode = defaultDebugMode
	SetBool("savegame.mod.ScreamerNextBot.debugMode", debugMode)
end
