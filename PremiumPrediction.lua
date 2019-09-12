--[[
	   ___                _            ___             ___     __  _         
	  / _ \_______ __ _  (_)_ ____ _  / _ \_______ ___/ (_)___/ /_(_)__  ___ 
	 / ___/ __/ -_)  ' \/ / // /  ' \/ ___/ __/ -_) _  / / __/ __/ / _ \/ _ \
	/_/  /_/  \__/_/_/_/_/\_,_/_/_/_/_/  /_/  \__/\_,_/_/\__/\__/_/\___/_//_/
                                                             Powered by GoS!

	-> Generic API

	* GetPrediction(source, unit, speed, range, delay, radius, angle, collision)
	> returns: CastPos, PredPos, HitChance, TimeToHit

	* GetDashPrediction(source, unit, speed, delay, radius)
	> returns: CastPos, TimeToHit

	* GetHitChance(source, unit, predPos, timeToHit, speed, range, delay, radius, angle, collision)
	> returns: HitChance

	* PredictTargetPosition(source, minion, speed, delay, radius)
	> returns: CastPos, PredPos, TimeToHit

	-> Hitchances

	-1             Minion or wall collision
	0              Unit is out of range
	0.1 - 0.24     Low accuracy
	0.25 - 0.49    Medium accuracy
	0.50 - 0.74    High accuracy
	0.75 - 0.99    Very high accuracy
	1              Unit is immobile or dashing

--]]

local Version = "2.04"; require 'MapPositionGOS'
local GameLatency, GameTimer, GameHeroCount, GameHero, GameMinionCount, GameMinion = Game.Latency, Game.Timer, Game.HeroCount, Game.Hero, Game.MinionCount, Game.Minion
local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local TableInsert, TableRemove = table.insert, table.remove
local VerSite = "https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/PremiumPrediction.version"
local LuaSite = "https://raw.githubusercontent.com/Ark223/GoS-Scripts/master/PremiumPrediction.lua"
local CCBuffs, CustomData, Enemies = {5, 8, 11, 18, 21, 22, 24, 28, 29}, {}, {}

function DownloadFile(site, file)
	DownloadFileAsync(site, file, function() end)
	while not FileExist(file) do end
end

function ReadFile(file)
	local txt = io.open(file, "r")
	local result = txt:read()
	txt:close(); return result
end

function AutoUpdate()
	DownloadFile(VerSite, COMMON_PATH .. "PremiumPrediction.version", function() end)
	if tonumber(ReadFile(COMMON_PATH .. "PremiumPrediction.version")) > tonumber(Version) then
		print("PremiumPrediction: Downloading update...")
		DownloadFile(LuaSite, COMMON_PATH .. "PremiumPrediction.lua", function() end)
		print("PremiumPrediction: Successfully updated. 2xF6!")
	end
end

--[[
	┬  ┌─┐┌─┐┌┬┐
	│  │ │├─┤ ││
	┴─┘└─┘┴ ┴─┴┘
--]]

class "PremiumPrediction"

function PremiumPrediction:__init()
	self.Debug = false
	for i = 1, GameHeroCount() do
		local unit = GameHero(i)
		if unit and unit.team ~= myHero.team then TableInsert(Enemies, unit) end
	end
	Callback.Add("Tick", function() self:Tick() end)
	if self.Debug then Callback.Add("Draw", function() self:Draw() end) end
end

--[[
	┌─┐┌─┐┌─┐┌┬┐┌─┐┌┬┐┬─┐┬ ┬
	│ ┬├┤ │ ││││├┤  │ ├┬┘└┬┘
	└─┘└─┘└─┘┴ ┴└─┘ ┴ ┴└─ ┴ 
--]]

function PremiumPrediction:AngleBetween(pos1, pos2, pos3)
	local pos1, pos2 = pos1, pos2
	if pos3 then pos1, pos2 = Vector(-pos3 + pos1), Vector(-pos3 + pos2) end
	local theta = self:Polar(pos1) - self:Polar(pos2)
	if theta < 0 then theta = theta + 360 end
	if theta > 180 then theta = 360 - theta end
	return theta
end

function PremiumPrediction:CalculateInterceptionTime(source, unit, path, speed, moveSpeed)
	local dir = {x = path.x - unit.x, z = path.z - unit.z}
	local magnitude = MathSqrt(dir.x * dir.x + dir.z * dir.z)
	dir = {x = dir.x / magnitude * moveSpeed, z = dir.z / magnitude * moveSpeed}
	local a = (dir.x * dir.x) + (dir.z * dir.z) - (speed * speed)
	local b = 2 * ((unit.x * dir.x) + (unit.z * dir.z) - (source.x * dir.x) - (source.z * dir.z))
	local c = (unit.x * unit.x) + (unit.z * unit.z) + (source.x * source.x) + (source.z * source.z) - (2 * source.x * unit.x) - (2 * source.z * unit.z)
	local delta = b * b - 4 * a * c
	if delta >= 0 then
		local t1, t2 = (-b + MathSqrt(delta)) / (2 * a), (-b - MathSqrt(delta)) / (2 * a)
		return MathMax(t1, t2)
	end
	return 0
end

function PremiumPrediction:Center(pos1, pos2)
	return Vector((pos1 + pos2) / 2)
end

function PremiumPrediction:CircleCircleIntersection(c1, c2, r1, r2)
	local d = self:GetDistance(c1, c2)
	local a = (r1 * r1 - r2 * r2 + d * d) / (2 * d); local h = MathSqrt(r1 * r1 - a * a)
	local dir = Vector(c2 - c1):Normalized(); local pa = Vector(c1) + a * dir
	local s1, s2 = pa + h * dir:Perpendicular(), pa - h * dir:Perpendicular()
	return s1, s2
end

function PremiumPrediction:CutWaypoints(waypoints, distance)
	local remaining, result = distance, {}
	if distance < 0 then
		waypoints[1] = waypoints[1] + distance * Vector(waypoints[2] - waypoints[1]):Normalized()
		return waypoints
	end
	for i = 1, #waypoints - 1 do
		local dist = self:GetDistance(waypoints[i], waypoints[i + 1])
		if dist > remaining then
			TableInsert(result, waypoints[i] + remaining * (waypoints[i + 1] - waypoints[i]):Normalized())
			for j = i + 1, #waypoints do TableInsert(result, waypoints[j]) end; break
		end
		remaining = remaining - dist
	end
	return (#result > 0 and result or {waypoints[#waypoints]})
end

function PremiumPrediction:IsClose(a, b, eps)
	local eps = eps or 1e-9
	return MathAbs(a - b) <= eps
end

function PremiumPrediction:GenerateCastPos(source, predPos, path1, path2, time, radius)
	local alpha = (MathAtan2(path2.z - path1.z, path2.x - path1.x) - MathAtan2(source.z - predPos.z, source.x - predPos.x)) % (2 * MathPi)
	local total = 1 - (MathAbs((alpha % MathPi) - MathPi / 2) / (MathPi / 2))
	local phi = alpha < MathPi and MathAtan((radius / 2) / time) or -MathAtan((radius / 2) / time)
	local dx, dz, angle = predPos.x - source.x, predPos.z - source.z, phi * total
	return Vector(MathCos(angle) * dx - MathSin(angle) * dz + source.x, predPos.y, MathSin(angle) * dx + MathCos(angle) * dz + source.z)
end

function PremiumPrediction:GetDistance(pos1, pos2)
	return MathSqrt(self:GetDistanceSqr(pos1, pos2))
end

function PremiumPrediction:GetDistanceSqr(pos1, pos2)
	local pos2 = pos2 and pos2 or myHero.pos; local dx = pos1.x - pos2.x
	local dz = (pos1.z and pos1.z or pos1.y) - (pos2.z and pos2.z or pos2.y)
	return dx * dx + dz * dz
end

function PremiumPrediction:GetLength(pos1, pos2)
	local pos2 = pos2 and pos2 or pos1
	return MathSqrt(pos1.x * pos2.x + (pos1.y and pos1.y * pos2.y or 0) + (pos1.z and pos1.z * pos2.z or 0))
end

function PremiumPrediction:GetPathLength(waypoints)
	local distance = 0
	for i = 1, #waypoints -1 do
		distance = distance + self:GetDistance(waypoints[i], waypoints[i + 1])
	end
	return distance
end

function PremiumPrediction:GetWaypointChangeCount(unit)
	local NID = unit.networkID
	if CustomData[NID] then
		local changes = CustomData[NID].pathChanges
		if changes then return #changes end
	end
	return 0
end

function PremiumPrediction:GetWaypoints(unit)
	local waypoints = {}
	if unit.visible then TableInsert(waypoints, unit.pos)
		if self:IsDashing(unit) then
			TableInsert(waypoints, unit.posTo)
		else
			for i = unit.pathing.pathIndex, unit.pathing.pathCount do
				TableInsert(waypoints, Vector(unit:GetPath(i).x, unit:GetPath(i).y, unit:GetPath(i).z))
			end
		end
	end
	return waypoints
end

function PremiumPrediction:IsMinionCollision(source, position, speed, range, delay, radius)
	local sourcePos = self:IsVector(source) and source or source.pos
	for i = 1, GameMinionCount() do
		local minion = GameMinion(i)
		if minion and minion.isEnemy and minion.health > 0 and minion.maxHealth > 5 then
			local predPos, timeToHit = self:GetFastPrediction(source, minion, speed, delay)
			if predPos and self:GetDistanceSqr(sourcePos, predPos) <= (range + radius) * (range + radius) then
				local pointSegment, pointLine, isOnSegment = self:VectorPointProjectionOnLineSegment(sourcePos, position, predPos)
				if self:GetDistanceSqr(pointSegment, predPos) <= (radius + minion.boundingRadius * 1.5) ^ 2 or self:GetDistance(position, predPos) < minion.boundingRadius or self:GetDistance(sourcePos, predPos) < minion.boundingRadius then 
					return true
				end
			end
		end
	end
	return false
end

function PremiumPrediction:IsVector(vec)
	return vec and vec.x and type(vec.x) == "number" and ((vec.y and type(vec.y) == "number") or (vec.z and type(vec.z) == "number"))
end

function PremiumPrediction:Polar(pos)
	if self:IsClose(pos.x, 0) then
		if (pos.z or pos.y) > 0 then return 90
		elseif (pos.z or pos.y) < 0 then return 270
		else return 0 end
	else
		local theta = MathDeg(MathAtan((pos.z or pos.y) / pos.x))
		if pos.x < 0 then theta = theta + 180 end
		if theta < 0 then theta = theta + 360 end
		return theta
	end
end

function PremiumPrediction:VectorPointProjectionOnLineSegment(v1, v2, v)
	local cx, cy, ax, ay, bx, by = v.x, (v.z or v.y), v1.x, (v1.z or v1.y), v2.x, (v2.z or v2.y)
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local pointLine = { x = ax + rL * (bx - ax), y = ay + rL * (by - ay) }
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	local isOnSegment = rS == rL
	local pointSegment = isOnSegment and pointLine or {x = ax + rS * (bx - ax), y = ay + rS * (by - ay)}
	return pointSegment, pointLine, isOnSegment
end

--[[
	┌┬┐┌─┐┌┐┌┌─┐┌─┐┌─┐┬─┐
	│││├─┤│││├─┤│ ┬├┤ ├┬┘
	┴ ┴┴ ┴┘└┘┴ ┴└─┘└─┘┴└─
--]]

function PremiumPrediction:GetImmobileDuration(unit)
	if unit.activeSpell.isChanneling or unit.activeSpell.isAutoAttack then
		return (unit.activeSpell.castEndTime - GameTimer())
	end
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		for i = 1, #CCBuffs do
			if buff and buff.type == CCBuffs[i] and buff.duration > 0 then
				return buff.duration
			end
		end
	end
	return 0
end

function PremiumPrediction:IsDashing(unit)
	return unit.pathing.isDashing
end

function PremiumPrediction:IsMoving(unit)
	return unit.pathing.hasMovePath
end

function PremiumPrediction:IsSlowed(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and buff.type == 10 and buff.duration > 0 then
			return true
		end
	end
	return false
end

function PremiumPrediction:ValidTarget(target, range)
	local range = range or MathHuge
	return target and target.valid and target.visible and target.health > 0 and self:GetDistanceSqr(myHero.pos, target.pos) <= range
end

--[[
	┌─┐┬─┐┌─┐┌┬┐┬┌─┐┌┬┐┬┌─┐┌┐┌
	├─┘├┬┘├┤  ││││   │ ││ ││││
	┴  ┴└─└─┘─┴┘┴└─┘ ┴ ┴└─┘┘└┘
--]]

--require 'GamsteronPrediction'
local Q = {speed = 1600, range = 900, delay = 0.25, radius = 70, angle = nil, collision = true}
--local GQ = {Type = _G.SPELLTYPE_LINE, Delay = 0.25, Radius = 70, Range = 1175, Speed = 1250, Collision = true, MaxCollision = 0, CollisionTypes = {_G.COLLISION_MINION, _G.COLLISION_YASUOWALL}}

function PremiumPrediction:Draw()
	for i = 1, #Enemies do
		local target = Enemies[i]
		if self:ValidTarget(target, 3000) then
			local CP, P, H, T = self:GetPrediction(myHero, target, Q.speed, Q.range, Q.delay, Q.radius, Q.angle, Q.collision)
			--local Pred = GetGamsteronPrediction(target, GQ, myHero); local CastPos, PredPos = Pred.CastPosition, Pred.UnitPosition
			--if CastPos and PredPos and Pred.Hitchance >= 0 and CP and P then
			if CP and P then
				--Draw.Line(Vector(CastPos):To2D(), Vector(myHero.pos):To2D(), 1, Draw.Color(128, 255, 69, 255))
				--Draw.Circle(CastPos, 70, 1, Draw.Color(128, 255, 69, 255))
				Draw.Line(Vector(P):To2D(), Vector(myHero.pos):To2D(), 1, Draw.Color(128, 255, 255, 255))
				Draw.Circle(P, 70, 1, Draw.Color(128, 255, 255, 255))
				Draw.Line(Vector(CP):To2D(), Vector(myHero.pos):To2D(), 1, Draw.Color(128, 255, 255, 192))
				Draw.Circle(CP, 70, 1, Draw.Color(128, 255, 255, 192))
				--print(Pred.Hitchance)
				print(H)
			end
		end
	end
end

function PremiumPrediction:Tick()
	for i = 1, #Enemies do
		local unit = Enemies[i]; local NID = unit.networkID
		if not CustomData[NID] then
			CustomData[NID] = {isVisible = unit.visible, visionTimer = 0, pathPositions = {}, pathTimers = {}, predictedPaths = {}}
		else
			if CustomData[NID].isVisible ~= unit.visible then
				if not unit.visible then self:OnLoseVision(unit); CustomData[NID].visionTimer = GameTimer()
				else self:OnGainVision(unit); CustomData[NID].visionTimer = 0 end
				CustomData[NID].isVisible = unit.visible
			end
			if self:IsMoving(unit) then
				local paths = CustomData[NID].pathPositions
				if #paths > 0 and paths[#paths].endPos ~= unit.pathing.endPos or #paths == 0 then
					self:OnProcessWaypoint(unit, unit.pos, unit.posTo)
					TableInsert(paths, {startPos = unit.pos, endPos = unit.posTo})
					TableInsert(CustomData[NID].pathTimers, GameTimer())
				end
			end
		end
		local timers = CustomData[NID].pathTimers
		for i = #timers, 1, -1 do
			local timer = timers[i]
			if timer and timer + 1 < GameTimer() then
				TableRemove(timers, i); TableRemove(CustomData[NID].pathPositions, i)
			end
		end
	end
end

function PremiumPrediction:OnGainVision(unit)
	return
end

function PremiumPrediction:OnLoseVision(unit)
	return
end

function PremiumPrediction:OnProcessWaypoint(unit, startPos, endPos)
	return
end

function PremiumPrediction:GetHitChance(source, unit, predPos, timeToHit, speed, range, delay, radius, angle, collision)
	local sourcePos = self:IsVector(source) and source or source.pos
	local moveSpeed = self:IsDashing(unit) and unit.pathing.dashSpeed or unit.ms
	local HitChance, disp, timer = 0, timeToHit * moveSpeed, self:GetImmobileDuration(unit)
	if angle and angle > 0 then radius = MathSqrt(2 * (disp * disp) - 2 * disp * disp * MathCos(angle)) end
	HitChance = MathMin(1, radius * 2 / moveSpeed / MathMax(0.01, timeToHit - timer))
	if self:IsSlowed(unit) then HitChance = MathMin(1, HitChance * 1.5) end
	local count = self:GetWaypointChangeCount(unit); if HitChance ~= 1 then HitChance = MathMax(0, HitChance - (count / 30)) end
	if not unit.visible then HitChance = HitChance / 2 end
	if collision and self:IsMinionCollision(source, predPos, speed, range, delay, radius) or MapPosition:inWall(predPos) then
		HitChance = -1
	elseif self:GetDistanceSqr(sourcePos, predPos) > range * range then
		HitChance = 0
	end
	return HitChance
end

function PremiumPrediction:GetPrediction(source, unit, speed, range, delay, radius, angle, collision)
	if not self:IsMoving(unit) then
		local sourcePos, unitPos = self:IsVector(source) and source or source.pos, unit.pos
		local time = self:GetDistance(sourcePos, unitPos) / speed + delay
		return unit.pos, unit.pos, self:GetHitChance(source, unit, unit.pos, time, speed, range, delay, radius, angle, collision), time
	elseif self:IsDashing(unit) and self:GetPathLength(self:GetWaypoints(unit)) > 200 then
		local CP, T = self:GetDashPrediction(source, unit, speed, delay, radius)
		local col = CP and collision and self:IsMinionCollision(source, CP, speed, range, delay, radius)
		return CP and col == false and CP, CP, 1, T or self:GetPrediction(source, unit, speed, range, delay, radius, angle, collision)
	end
	local CP, P, T = self:PredictTargetPosition(source, unit, speed, delay, radius)
	return CP, P, self:GetHitChance(source, unit, CP, T, speed, range, delay, radius, angle, collision), T
end

function PremiumPrediction:GetDashPrediction(source, unit, speed, delay, radius)
	if not self:IsDashing(unit) then return nil, 0 end
	local sourcePos, unitPos, moveSpeed = self:IsVector(source) and source or source.pos, unit.pos, unit.pathing.dashSpeed
	local radius, waypoints = radius or 1, self:GetWaypoints(unit)
	local CastPos, TimeToHit = nil, self:GetDistance(sourcePos, waypoints[2]) / speed + delay
	local tT = self:GetDistance(unitPos, waypoints[2]) / moveSpeed + radius / unit.ms
	if TimeToHit - 0.25 <= tT then CastPos = waypoints[2] end
	return CastPos, TimeToHit
end

function PremiumPrediction:GetFastPrediction(source, unit, speed, delay)
	local sourcePos, unitPos = self:IsVector(source) and source or source.pos, unit.pos
	local PredPos = self:IsMoving(unit) and unit:GetPrediction(speed, delay) or unitPos
	local TimeToHit = self:GetDistance(sourcePos, PredPos) / speed + delay
	return PredPos, TimeToHit
end

function PremiumPrediction:PredictTargetPosition(source, unit, speed, delay, radius)
	local sourcePos, unitPos, moveSpeed = self:IsVector(source) and source or source.pos, unit.pos, unit.ms
	if self:GetDistanceSqr(sourcePos, unitPos) < 250 * 250 then moveSpeed = moveSpeed / 1.5 end
	local radius, waypoints = radius or 1, self:GetWaypoints(unit)
	local PredPos, CastPos, TimeToHit = unitPos, unitPos, delay
	if speed == MathHuge then
		local sA = TimeToHit * moveSpeed; local sB = sA - radius
		PredPos, CastPos = self:CutWaypoints(waypoints, sA)[1], self:CutWaypoints(waypoints, MathMax(1, sB))[1]
	else
		local A, B = unitPos, waypoints[#waypoints]
		local time = delay + self:CalculateInterceptionTime(sourcePos, A, B, speed, moveSpeed)
		local dist = time * moveSpeed; PredPos = self:CutWaypoints(waypoints, MathMax(1, dist))[1]
		local tempPos = self:CutWaypoints(waypoints, MathMax(1, dist - radius / 2))[1]
		CastPos = self:GenerateCastPos(sourcePos, tempPos, A, B, speed * TimeToHit, radius)
		TimeToHit = self:GetDistance(sourcePos, CastPos) / speed + delay
	end
	return CastPos, PredPos, TimeToHit
end

PremiumPrediction()
