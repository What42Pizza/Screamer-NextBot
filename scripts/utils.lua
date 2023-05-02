-- math

function min(...) return math.min(...) end
function max(...) return math.max(...) end
function abs(...) return math.abs(...) end
function pow(...) return math.pow(...) end
function atan(...) return math.atan(...) end
function sqrt(...) return math.sqrt(...) end



-- general

function GetIntOr (key, default)
	return (HasKey(key) and {GetInt(key)} or {default})[1]
end
function GetFloatOr (key, default)
	return (HasKey(key) and {GetFloat(key)} or {default})[1]
end
function GetBoolOr (key, default)
	return (HasKey(key) and {GetBool(key)} or {default})[1]
end
function GetStringOr (key, default)
	return (HasKey(key) and {GetString(key)} or {default})[1]
end

function print (message)
	DebugPrint(message)
end

function Copy (t)
	if type(v) ~= "table" then return t end
	local output = {}
	for k,v in pairs(t) do
		if type(v) == "table" then v = Copy(v) end
		output[k] = v
	end
	return output
end

function CopyVec (vec)
	if vec == nil then return nil end
	return Vec(vec[1], vec[2], vec[3])
end

function RemoveVerticalComponent (vec)
	if vec == nil then return nil end
	return Vec(vec[1], 0, vec[3])
end

function Last (t)
	return t[#t]
end

function Append (t1, t2)
	for _,v in pairs(t2) do
		table.insert(t1, v)
	end
end

function Map (x, a, b, c, d)
	return (x - a) / (b - a) * (d - c) + c
end

function Lerp (a, b, c)
	return a + (b - a) * c
end

function Sign (x)
	return x > 0 and 1 or (x == 0 and 0 or -1)
end

function SignedPow (x, e)
	return pow(abs(x), e) * Sign(x)
end

function FitInRange (x, a, b)
	return (atan(x*3)/math.pi+0.5)*(b-a)+a
end

function Chance (chance)
	return math.random() < chance / 100
end

function GetDist(v1, v2)
	return VecLength(VecSub(v1,v2))
end

function GetHorizDist(v1, v2)
	local xDist = v1[1] - v2[1]
	local zDist = v1[3] - v2[3]
	return sqrt(xDist * xDist + zDist * zDist)
end

function MinMag (a, b) -- return the value with the lower absolute value
	return abs(a) < abs(b) and a or b
end

function MaxMag (a, b) -- return the value with the higher absolute value
	return abs(a) > abs(b) and a or b
end

function VecNormalizedDot (a, b) -- I think this returns a value from -1 to 1
	return VecDot(a, b) / ((VecLengthSquared(a) + VecLengthSquared(b)) / 2)
end

function VecLengthSquared (vec)
	return vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3]
end

function VecSetSacle (vec, amount)
	return VecScale(VecNormalize(vec), amount)
end

function BlankFunction() end



-- vec2

function VecToVec2 (vec)
	return {x = vec[1], y = vec[3]}
end

function Vec2 (x, y)
	return {x = x, y = y}
end

function Vec2To (a, b)
	return {
		x = b.x - a.x,
		y = b.y - a.y
	}
end

function Vec2MagSquared (vec)
	return vec.x * vec.x + vec.y * vec.y
end

function Vec2Dot (a, b)
	return a.x * b.x + a.y * b.y
end

function Vec2Scale (a, amount)
	return {x = a.x * amount, y = a.y * amount}
end

function Vec2Lerp (a, b, amount)
	local AtoB = Vec2To(a, b)
	return {
		x = a.x + AtoB.x * amount,
		y = a.y + AtoB.y * amount
	}
end

function Vec2Add (a, b)
	return {
		x = a.x + b.x,
		y = a.y + b.y
	}
end



-- widen curves

function WidenCurves (path)
	if #path < 3 then return path end
	local output = {}
	
	-- copy / widen first two points
	table.insert(output, path[1])
	table.insert(output, WidenPointOnCurve(path[2], path[1], path[3]))
	
	-- widen middle points
	for i = 3, #path - 2 do
		table.insert(output, WidenPointOnCurve(path[i], path[i-2], path[i+2]))
	end
	
	-- copy / widen last two points
	local lastPoint = path[#path]
	local secondLastPoint = path[#path-1]
	local thirdLastPoint = path[#path-2]
	table.insert(output, WidenPointOnCurve(secondLastPoint, thirdLastPoint, lastPoint))
	table.insert(output, lastPoint)
	
	return output
end



function WidenPointOnCurve (P, A, B) -- P is the point to move, A and B define the line to move away from
	local yPos = P[2]
	P = VecToVec2(P)
	A = VecToVec2(A)
	B = VecToVec2(B)
	
	local AtoB = Vec2To(A, B)
	local AtoP = Vec2To(A, P)
	
	local ABdotAP = Vec2Dot(AtoB, AtoP)
	local lerpAmount = ABdotAP / Vec2MagSquared(AtoB)
	local linePoint = Vec2Lerp(A, B, lerpAmount)
	
	local lineToP = Vec2To(linePoint, P)
	local finalPoint = Vec2Add(linePoint, Vec2Scale(lineToP, 1.5)) -- WIDEN AMOUNT HERE
	
	return Vec(finalPoint.x, yPos, finalPoint.y)
	
end



--[[
-- get max speeds

function getMaxSpeeds (path)
	local output = {}
	table.insert(output, 1000)
	
	for i=2, #path - 1 do
		local currentPoint = path[i]
		local prevPoint = path[i-1]
		local nextPoint = path[i+2]
		local line1 = VecSub(nextPoint, currentPoint)
		local line2 = VecSub(currentPoint, prevPoint)
		local dot = VecNormalizedDot(line1, line2)
		local max = pow(400, dot - 0.5) -- both nums are adjustable
		table.insert(output, max)
	end
	
	table.insert(output, 1000)
	return output
end
--]]
