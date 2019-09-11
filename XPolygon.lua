--[[

	____  _____________      .__                              
	\   \/  /\______   \____ |  | ___.__. ____   ____   ____  
	 \     /  |     ___/  _ \|  |<   |  |/ ___\ /  _ \ /    \ 
	 /     \  |    |  (  <_> )  |_\___  / /_/  >  <_> )   |  \
	/___/\  \ |____|   \____/|____/ ____\___  / \____/|___|  /
		  \_/                     \/   /_____/             \/ 
	                                  -= Ark223 & Maxxxel =-
	Polygon functions:
	
	[1] AreaOfPolygon(<list, points> poly) - returns number
	[2] CentroidOfPolygon(<list, points> poly) - returns point
	[3] ClipPolygons(<list, points> poly1, <list, points> poly2, <string> operation) - returns list(s) of points
	> operation = {"union", "intersection", "difference"}
	[4] MovePolygon(<list, points> poly, <point> direction) - returns list of points
	[5] GetPolygonSegments(<list, points> poly) - returns list of polygon segments
	[6] IsPointInPolygon(<list, points> poly, <point> point) - returns boolean
	[7] OffsetPolygon(<list, points> poly, <number> offset) - returns list of points
	[8] PolygonContainsPolygon(<list, points> poly1, <list, points> poly2) - returns boolean
	[9] PolygonIntersection(<list, points> poly1, <list, points> poly2) - returns list of points
	[10] RotatePolygon(<list, points> poly, <number> angle) - returns list of points
	
	Standard functions:
	
	[1] Closest(<list, points> points, <point> point) - returns point
	[2] ClosestPointOnSegment(<point> segment1, <point> segment2, <point> point) - returns point
	[3] CrossProduct(<point> point1, <point> point2) - returns number
	[4] Direction(<point> point1, <point> point2) - returns number
	[5] Distance(<point> point1, <point> point2) - returns number
	[6] DistanceSquared(<point> point1, <point> point2) - returns number
	[7] DotProduct(<point> point1, <point> point2) - returns number
	[8] Magnitude(<point> point1, <point> point2) - returns number
	[9] MagnitudeSquared(<point> point1, <point> point2) - returns number
	[10] Normalize(<point> point) - returns point
	[11] Intersection(<point> point1, <point> point2, <point> point3, <point> point4) - returns point & boolean
	> boolean - returns true if intersection exists for line segments
	[12] IsPointOnSegment(<point> segment1, <point> segment2, <point> point) - returns boolean
	
	Example usage:
	
	local path1 = {
		{x = 40, y = 40},
		{x = 100, y = 200},
		{x = 320, y = 160},
		{x = 140, y = 60},
	}
	local path2 = {
		{x = 230, y = 280},
		{x = 260, y = 80},
		{x = 400, y = 120},
		{x = 360, y = 240},
	}
	local res1, res2 = XPolygon:ClipPolygons(path1, path2, "union")
	local new = XPolygon:OffsetPolygon(res1, 15)
	for i, point in ipairs(new) do print(point) end
	print(XPolygon:AreaOfPolygon(new))
	
--]]

local Ver = 1.02
local MathAbs, MathAtan, MathAtan2, MathAcos, MathCeil, MathCos, MathDeg, MathFloor, MathHuge, MathMax, MathMin, MathPi, MathRad, MathSin, MathSqrt = math.abs, math.atan, math.atan2, math.acos, math.ceil, math.cos, math.deg, math.floor, math.huge, math.max, math.min, math.pi, math.rad, math.sin, math.sqrt
local TableInsert, TableRemove, TableSort = table.insert, table.remove, table.sort

local function Class()
	local cls = {}; cls.__index = cls
	return setmetatable(cls, {__call = function (c, ...)
		local instance = setmetatable({}, cls)
		if cls.__init then cls.__init(instance, ...) end
		return instance
	end})
end

--[[
	┌─┐┌─┐┬┌┐┌┌┬┐
	├─┘│ │││││ │ 
	┴  └─┘┴┘└┘ ┴ 
--]]

local function IsPoint(p)
	return p and p.x and type(p.x) == "number" and (p.y and type(p.y) == "number")
end

Point = Class()

function Point:__init(x, y)
	if not x then self.x, self.y = 0, 0
	elseif not y then self.x, self.y = x.x, x.y
	else self.x = x; if y and type(y) == "number" then self.y = y end end
end

function Point:__type()
	return "Point"
end

function Point:__eq(p)
	return (self.x == p.x and self.y == p.y)
end

function Point:__add(p)
	return Point(self.x + p.x, (p.y and self.y) and self.y + p.y)
end

function Point:__sub(p)
	return Point(self.x - p.x, (p.y and self.y) and self.y - p.y)
end

function Point.__mul(a, b)
	if type(a) == "number" and IsPoint(b) then
		return Point(b.x * a, b.y * a)
	elseif type(b) == "number" and IsPoint(a) then
		return Point(a.x * b, a.y * b)
	end
end

function Point:__tostring()
	return "("..self.x..", "..self.y..")"
end

function Point:Clone()
	return Point(self)
end

function Point:Magnitude()
	return MathSqrt(self:MagnitudeSquared())
end

function Point:MagnitudeSquared(p)
	local p = p and Point(p) or self
	return self.x * self.x + self.y * self.y
end

function Point:Normalize()
	local dist = self:Magnitude()
	self.x, self.y = self.x / dist, self.y / dist
end

function Point:Normalized()
	local p = self:Clone()
	p:Normalize(); return p
end

function Point:Perpendicular()
	return Point(-self.y, self.x)
end

function Point:Perpendicular2()
	return Point(self.y, -self.x)
end

--[[
	┬  ┬┌─┐┬─┐┌┬┐┌─┐─┐ ┬
	└┐┌┘├┤ ├┬┘ │ ├┤ ┌┴┬┘
	 └┘ └─┘┴└─ ┴ └─┘┴ └─
 --]]

local Vertex = {}

function Vertex:New(x, y, alpha, intersection)
	local new = {x = x, y = y, next = nil, prev = nil, nextPoly = nil, neighbor = nil, intersection = intersection, entry = nil, visited = false, alpha = alpha or 0}
	setmetatable(new, self)
	self.__index = self
	return new
end

function Vertex:InitLoop()
	local last = self:GetLast()
	last.prev.next = self
	self.prev = last.prev
end

function Vertex:Insert(first, last)
	local res = first
	while res ~= last and res.alpha < self.alpha do res = res.next end
	self.next = res
	self.prev = res.prev
	if self.prev then self.prev.next = self end
	self.next.prev = self
end

function Vertex:GetLast()
	local res = self
	while res.next and res.next ~= self do res = res.next end
	return res
end

function Vertex:GetNextNonIntersection()
	local res = self
	while res and res.intersection do res = res.next end
	return res
end

function Vertex:GetFirstVertexOfIntersection()
	local res = self
	while true do
		res = res.next
		if not res then break end
		if res == self then break end
		if res.intersection and not res.visited then break end
	end
	return res
end

--[[
	┌─┐┌─┐┬─┐┌─┐
	│  │ │├┬┘├┤ 
	└─┘└─┘┴└─└─┘
--]]

XPolygon = Class()

function XPolygon:__init()
end

function XPolygon:InitVertices(poly)
	local first, current = nil, nil
	for i = 1, #poly do
		if current then
			current.next = Vertex:New(poly[i].x, poly[i].y)
			current.next.prev = current
			current = current.next
		else
			current = Vertex:New(poly[i].x, poly[i].y)
			first = current
		end
	end
	local next = Vertex:New(first.x, first.y, 1)
	current.next = next
	next.prev = current
	return first, current
end

function XPolygon:FindIntersectionsForClip(subjPoly, clipPoly)
	local found, subject = false, subjPoly
	while subject.next do
		if not subject.intersection then
			local clip = clipPoly
			while clip.next do
				if not clip.intersection then
					local subjNext = subject.next:GetNextNonIntersection()
					local clipNext = clip.next:GetNextNonIntersection()
					local int, segs = self:Intersection(subject, subjNext, clip, clipNext)
					if int and segs then
						found = true
						local alpha1 = self:Distance(subject, int) / self:Distance(subject, subjNext)
						local alpha2 = self:Distance(clip, int) / self:Distance(clip, clipNext)
						local subjectInter = Vertex:New(int.x, int.y, alpha1, true)
						local clipInter = Vertex:New(int.x, int.y, alpha2, true)
						subjectInter.neighbor = clipInter
						clipInter.neighbor = subjectInter
						subjectInter:Insert(subject, subjNext)
						clipInter:Insert(clip, clipNext)
					end
				end
				clip = clip.next
			end
		end
		subject = subject.next
	end
	return found
end

function XPolygon:IdentifyIntersectionType(subjList, clipList, clipPoly, subjPoly, operation)
	local se = self:IsPointInPolygon(clipPoly, subjList)
	if operation == "intersection" then se = not se end
	local subject = subjList
	while subject do
		if subject.intersection then
			subject.entry = se
			se = not se
		end
		subject = subject.next
	end
	local ce = not self:IsPointInPolygon(subjPoly, clipList)
	if operation == "union" then ce = not ce end
	local clip = clipList
	while clip do
		if clip.intersection then
			clip.entry = ce
			ce = not ce
		end
		clip = clip.next
	end
end

function XPolygon:GetClipResult(subjList, clipList)
	subjList:InitLoop(); clipList:InitLoop()
	local walker, result = nil, {}
	while true do
		walker = subjList:GetFirstVertexOfIntersection()
		if walker == subjList then break end
		while true do
			if walker.visited then break end
			walker.visited = true
			walker = walker.neighbor
			TableInsert(result, Point(walker.x, walker.y))
			local forward = walker.entry
			while true do
				walker.visited = true
				walker = forward and walker.next or walker.prev
				if walker.intersection then break
				else TableInsert(result, Point(walker.x, walker.y)) end
			end
		end
	end
	return result
end

--[[
	┌─┐┬ ┬┌┐ ┬  ┬┌─┐
	├─┘│ │├┴┐│  ││  
	┴  └─┘└─┘┴─┘┴└─┘
--]]

function XPolygon:AreaOfPolygon(poly)
	assert(#poly > 2, "AreaOfPolygon: insufficient number of segments (minimum 3 required)")
	local area = self:CrossProduct(poly[#poly], poly[1])
	for i = 2, #poly do area = area + self:CrossProduct(poly[i - 1], poly[i]) end
	return MathAbs(area / 2)
end

function XPolygon:CentroidOfPolygon(poly)
	assert(#poly > 2, "CentroidOfPolygon: insufficient number of segments (minimum 3 required)")
	local cx, cy, points = 0, 0, #poly
	for i, point in ipairs(poly) do cx, cy = cx + point.x, cy + point.y end
	return Point(cx / points, cy / points)
end

function XPolygon:Closest(points, main)
	assert(IsPoint(main), "Closest: wrong input values (number expected)")
	TableSort(points, function(a, b) return self:DistanceSquared(a, main) < self:DistanceSquared(b, main) end)
	return #points > 0 and points[1] or nil
end

function XPolygon:ClosestPointOnSegment(s1, s2, point)
	assert(IsPoint(s1) and IsPoint(s2) and IsPoint(point), "ClosestPointOnSegment: wrong input values (number expected)")
	local ap, ab = Point(point - s1), Point(s2 - s1)
	local dist = self:DotProduct(ap, ab) / self:MagnitudeSquared(ap, ab)
	if dist < 0 then return s1
	elseif dist > 1 then return s2
	else return Point(s1 + ab * dist) end
end

function XPolygon:ClipPolygons(subj, clip, op)
	assert(#subj > 2 and #clip > 2, "ClipPolygons: insufficient number of segments (minimum 3 required)")
	assert(op == "union" or op == "intersection" or op == "difference", "ClipPolygons: wrong operation type (possible: union, intersection, difference)")
	local result = {}
	local subjList, l1 = self:InitVertices(subj)
	local clipList, l2 = self:InitVertices(clip)
    local ints = self:FindIntersectionsForClip(subjList, clipList)
	if ints then
		self:IdentifyIntersectionType(subjList, clipList, clip, subj, op)
		result = self:GetClipResult(subjList, clipList)
	else
		local inside = self:IsPointInPolygon(clip, subj[1])
		local outside = self:IsPointInPolygon(subj, clip[1])
		if op == "union" then
			if inside then return clip, nil
			elseif outside then return subj, nil end
		elseif op == "intersection" then
			if inside then return subj, nil
			elseif outside then return clip, nil end
		end
		return subj, clip
	end
	return result, nil
end

function XPolygon:CrossProduct(p1, p2)
	assert(IsPoint(p1) and IsPoint(p2), "CrossProduct: wrong input values (number expected)")
	return p1.x * p2.y - p1.y * p2.x
end

function XPolygon:Direction(p1, p2)
	assert(IsPoint(p1) and IsPoint(p2), "Direction: wrong input values (number expected)")
	return p1.y == p2.y and "horizontal" or (p2.x - p1.x) / (p2.y - p1.y)
end

function XPolygon:Distance(p1, p2)
	assert(IsPoint(p1) and IsPoint(p2), "Distance: wrong input values (number expected)")
	return MathSqrt(self:DistanceSquared(p1, p2))
end

function XPolygon:DistanceSquared(p1, p2)
	assert(IsPoint(p1) and IsPoint(p2), "DistanceSquared: wrong input values (number expected)")
	return (p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2
end

function XPolygon:DotProduct(p1, p2)
	assert(IsPoint(p1) and IsPoint(p2), "DotProduct: wrong input values (number expected)")
	return p1.x * p2.x + p1.y * p2.y
end

function XPolygon:GetPolygonSegments(poly)
	assert(#poly > 2, "GetPolygonSegments: insufficient number of segments (minimum 3 required)")
	local segments = {}
	for i = 1, #poly do TableInsert(segments, {poly[i], poly[(i % #poly) + 1]}) end
	return segments
end

function XPolygon:Intersection(a1, b1, a2, b2)
	local a1, b1, a2, b2 = Point(a1), Point(b1), Point(a2), Point(b2)
	local r, s = Point(b1 - a1), Point(b2 - a2); local x = self:CrossProduct(r, s)
	local t, u = self:CrossProduct(a2 - a1, s) / x, self:CrossProduct(a2 - a1, r) / x
	if x ~= 0 then return Point(a1 + t * r), t >= 0 and t <= 1 and u >= 0 and u <= 1 end
	return nil, nil
end

function XPolygon:IsPointOnSegment(s1, s2, main)
	assert(IsPoint(s1) and IsPoint(s2) and IsPoint(main), "IsPointOnSegment: wrong input values (number expected)")
	local cx, cy, ax, ay, bx, by = main.x, main.y, s1.x, s1.y, s2.x, s2.y
	local rL = ((cx - ax) * (bx - ax) + (cy - ay) * (by - ay)) / ((bx - ax) ^ 2 + (by - ay) ^ 2)
	local rS = rL < 0 and 0 or (rL > 1 and 1 or rL)
	return rS == rL
end

function XPolygon:IsPointInPolygon(poly, point)
	assert(#poly > 2, "IsPointInPolygon: insufficient number of segments (minimum 3 required)")
	assert(IsPoint(point), "IsPointInPolygon: wrong input values (number expected)")
	local result, j = false, #poly
	for i = 1, #poly do
		if poly[i].y < point.y and poly[j].y >= point.y or poly[j].y < point.y and poly[i].y >= point.y then
			if poly[i].x + (point.y - poly[i].y) / (poly[j].y - poly[i].y) * (poly[j].x - poly[i].x) < point.x then
				result = not result
			end
		end
		j = i
	end
	return result
end

function XPolygon:Magnitude(pt)
	assert(IsPoint(pt), "Magnitude: wrong input values (number expected)")
	return MathSqrt(self:MagnitudeSquared(pt))
end

function XPolygon:MagnitudeSquared(pt)
	assert(IsPoint(pt), "MagnitudeSquared: wrong input values (number expected)")
	return pt.x * pt.x + pt.y * pt.y
end

function XPolygon:MovePolygon(poly, dir)
	assert(#poly > 2, "MovePolygon: insufficient number of segments (minimum 3 required)")
	assert(IsPoint(dir), "MovePolygon: wrong input values (number expected)")
	local result = {}
	for i, point in ipairs(poly) do
		local new = Point(poly[i] + dir)
		TableInsert(result, new)
	end
	return result
end

function XPolygon:Normalize(pt)
	assert(IsPoint(pt), "Normalize: wrong input values (number expected)")
	local dist = self:Magnitude(pt)
	return Point(pt.x / dist, pt.y / dist)
end

function XPolygon:OffsetPolygon(poly, offset)
	assert(#poly > 2, "OffsetPolygon: insufficient number of segments (minimum 3 required)")
	assert(type(offset) == "number", "OffsetPolygon: wrong input values (number expected)")
	local result = {}
	for i, point in ipairs(poly) do
		local j, k = i - 1, i + 1
		if j < 1 then j = #poly end; if k > #poly then k = 1 end
		local p1, p2, p3 = poly[j], poly[i], poly[k]
		local n1 = Point(p2 - p1):Normalized():Perpendicular() * offset
		local a, b = Point(p1 + n1), Point(p2 + n1)
		local n2 = Point(p3 - p2):Normalized():Perpendicular() * offset
		local c, d = Point(p2 + n2), Point(p3 + n2)
		local int = self:Intersection(a, b, c, d)
		local dist = self:Distance(p2, int)
		local dot = (p1.x - p2.x) * (p3.x - p2.x) + (p1.y - p2.y) * (p3.y - p2.y)
		local cross = (p1.x - p2.x) * (p3.y - p2.y) - (p1.y - p2.y) * (p3.x - p2.x)
		local angle = MathAtan2(cross, dot)
		if dist > offset and angle > 0 then
			local ex = p2 + Point(int - p2):Normalized() * offset
			local dir = Point(ex - p2):Perpendicular()
			dir = self:Normalize(dir) * dist
			local e, f = Point(ex - dir), Point(ex + dir)
			local i1 = self:Intersection(e, f, a, b); local i2 = self:Intersection(e, f, c, d)
			TableInsert(result, i1); TableInsert(result, i2)
		else
			TableInsert(result, int)
		end
    end
    return result
end

function XPolygon:PolygonContainsPolygon(poly1, poly2)
	assert(#poly1 > 2 and #poly2 > 2, "PolygonContainsPolygon: insufficient number of segments (minimum 3 required)")
	for i = 1, #poly1 do
		if self:IsPointInPolygon(poly2, poly1[i]) then return true end
	end
	return false
end

function XPolygon:PolygonIntersection(poly1, poly2)
	assert(#poly1 > 2 and #poly2 > 2, "PolygonIntersection: insufficient number of segments (minimum 3 required)")
	local points = {}
	local segs1, segs2 = self:GetPolygonSegments(poly1), self:GetPolygonSegments(poly2)
	for i, seg1 in ipairs(segs1) do
		for j, seg2 in ipairs(segs2) do
			local point, segs = self:Intersection(seg1, seg2)
			if point and segs then TableInsert(points, point) end
		end
	end
	return points
end

function XPolygon:RotatePolygon(poly, angle)
	assert(#poly > 2, "RotatePolygon: insufficient number of segments (minimum 3 required)")
	assert(type(angle) == "number", "RotatePolygon: wrong input values (number expected)")
	local result, angle = {}, MathRad(angle)
	for i, point in ipairs(poly) do
		local x = point.x * MathCos(angle) - point.y * MathSin(angle)
		local y = point.x * MathSin(angle) + point.y * MathCos(angle)
		TableInsert(result, Point(x, y))
	end
	return result
end
