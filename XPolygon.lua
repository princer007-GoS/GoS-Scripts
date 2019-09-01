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

local a=1.02
local b,c,d,e,f,g,h,i,j,k,l,m,n,o,p=math.abs,math.atan,math.atan2,math.acos,math.ceil,math.cos,math.deg,math.floor,math.huge,math.max,math.min,math.pi,math.rad,math.sin,math.sqrt
local q,r,s=table.insert,table.remove,table.sort

local function t()
    local u={}u.__index=u
    return setmetatable(u,{__call=function(v,...)
        local w=setmetatable({},u)
        if u.__init then u.__init(w,...)
        end
        return w
    end})
end

--[[
	┌─┐┌─┐┬┌┐┌┌┬┐
	├─┘│ │││││ │ 
	┴  └─┘┴┘└┘ ┴ 
--]]

local function x(y)
    return y and y.x and type(y.x)=="number"and(y.y and type(y.y)=="number")
end

Point=t()

function Point:__init(z,A)
    if not z then self.x,self.y=0,0 elseif not A then self.x,self.y=z.x,z.y else self.x=z
        if A and type(A)=="number" then
			self.y=A
        end
    end
end

function Point:__type()
    return"Point"
end

function Point:__eq(y)
    return self.x==y.x and self.y==y.y
end

function Point:__add(y)
    return Point(self.x+y.x,y.y and self.y and self.y+y.y)
end

function Point:__sub(y)
    return Point(self.x-y.x,y.y and self.y and self.y-y.y)
end

function Point.__mul(B,C)
    if type(B)=="number"and x(C)then return Point(C.x*B,C.y*B)
    elseif type(C)=="number"and x(B)then return Point(B.x*C,B.y*C)
    end
end

function Point:__tostring()
    return"("..self.x..", "..self.y..")"
end

function Point:Clone()
    return Point(self)
end

function Point:Magnitude()
    return p(self:MagnitudeSquared())
end

function Point:MagnitudeSquared(y)
    local y=y and Point(y)or self
    return self.x*self.x+self.y*self.y
end

function Point:Normalize()
    local D=self:Magnitude()self.x,self.y=self.x/D,self.y/D
end

function Point:Normalized()
    local y=self:Clone()y:Normalize()
    return y
end

function Point:Perpendicular()
    return Point(-self.y,self.x)
end

function Point:Perpendicular2()
    return Point(self.y,-self.x)
end

--[[
	┬  ┬┌─┐┬─┐┌┬┐┌─┐─┐ ┬
	└┐┌┘├┤ ├┬┘ │ ├┤ ┌┴┬┘
	 └┘ └─┘┴└─ ┴ └─┘┴ └─
 --]]

local E={}function E:New(z,A,F,G)
    local H={x=z,y=A,next=nil,prev=nil,nextPoly=nil,neighbor=nil,intersection=G,entry=nil,visited=false,alpha=F or 0}setmetatable(H,self)self.__index=self
    return H
end

function E:InitLoop()
    local I=self:GetLast()I.prev.next=self
    self.prev=I.prev
end

function E:Insert(J,I)
    local K=J
    while K~=I and K.alpha<self.alpha do K=K.next
    end
    self.next=K
    self.prev=K.prev
    if self.prev then self.prev.next=self
    end
    self.next.prev=self
end

function E:GetLast()
    local K=self
    while K.next and K.next~=self do K=K.next
    end
    return K
end

function E:GetNextNonIntersection()
    local K=self
    while K and K.intersection do K=K.next
    end
    return K
end

function E:GetFirstVertexOfIntersection()
    local K=self
    while true do K=K.next
        if not K then break
        end
        if K==self then break
        end
        if K.intersection and not K.visited then break
        end
    end
    return K
end

--[[
	┌─┐┌─┐┬─┐┌─┐
	│  │ │├┬┘├┤ 
	└─┘└─┘┴└─└─┘
--]]

XPolygon=t()

function XPolygon:__init()
end

function XPolygon:InitVertices(L)
    local J,M=nil,nil
    for N=1,#L do if M then M.next=E:New(L[N].x,L[N].y)M.next.prev=M
        M=M.next else M=E:New(L[N].x,L[N].y)J=M
    end
    end
    local O=E:New(J.x,J.y,1)M.next=O
    O.prev=M
    return J,M
end

function XPolygon:FindIntersectionsForClip(P,Q)
    local R,S=false,P
    while S.next do if not S.intersection then local T=Q
        while T.next do if not T.intersection then local U=S.next:GetNextNonIntersection()
            local V=T.next:GetNextNonIntersection()
            local W,X=self:Intersection(S,U,T,V)
            if W and X then R=true
                local Y=self:Distance(S,W)/self:Distance(S,U)
                local Z=self:Distance(T,W)/self:Distance(T,V)
                local _=E:New(W.x,W.y,Y,true)
                local a0=E:New(W.x,W.y,Z,true)_.neighbor=a0
                a0.neighbor=_
                _:Insert(S,U)a0:Insert(T,V)
            end
        end
        T=T.next
        end
    end
    S=S.next
    end
    return R
end

function XPolygon:IdentifyIntersectionType(a1,a2,Q,P,a3)
    local a4=self:IsPointInPolygon(Q,a1)
    if a3=="intersection"then a4=not a4
    end
    local S=a1
    while S do if S.intersection then S.entry=a4
        a4=not a4
    end
    S=S.next
    end
    local a5=not self:IsPointInPolygon(P,a2)
    if a3=="union"then a5=not a5
    end
    local T=a2
    while T do if T.intersection then T.entry=a5
        a5=not a5
    end
    T=T.next
    end
end

function XPolygon:GetClipResult(a1,a2)a1:InitLoop()a2:InitLoop()
    local a6,a7=nil,{}while true do a6=a1:GetFirstVertexOfIntersection()
        if a6==a1 then break
        end
        while true do if a6.visited then break
            end
            a6.visited=true
            a6=a6.neighbor
            q(a7,Point(a6.x,a6.y))
            local a8=a6.entry
            while true do a6.visited=true
                a6=a8 and a6.next or a6.prev
                if a6.intersection then break else q(a7,Point(a6.x,a6.y))
                end
            end
        end
    end
    return a7
end

--[[
	┌─┐┬ ┬┌┐ ┬  ┬┌─┐
	├─┘│ │├┴┐│  ││  
	┴  └─┘└─┘┴─┘┴└─┘
--]]

function XPolygon:AreaOfPolygon(L)
    assert(#L>2,"AreaOfPolygon: insufficient number of segments (minimum 3 required)")
    local a9=self:CrossProduct(L[#L],L[1])for N=2,#L do a9=a9+self:CrossProduct(L[N-1],L[N])
    end
    return b(a9/2)
end

function XPolygon:CentroidOfPolygon(L)
    assert(#L>2,"CentroidOfPolygon: insufficient number of segments (minimum 3 required)")
    local aa,ab,ac=0,0,#L
    for N,ad in ipairs(L)do aa,ab=aa+ad.x,ab+ad.y
    end
    return Point(aa/ac,ab/ac)
end

function XPolygon:Closest(ac,ae)
    assert(x(ae),"Closest: wrong input values (number expected)")s(ac,function(B,C)
        return self:DistanceSquared(B,ae)<self:DistanceSquared(C,ae)
    end)
    return#ac>0 and ac[1]or nil
end

function XPolygon:ClosestPointOnSegment(af,ag,ad)
    assert(x(af)and x(ag)and x(ad),"ClosestPointOnSegment: wrong input values (number expected)")
    local ah,ai=Point(ad-af),Point(ag-af)
    local D=self:DotProduct(ah,ai)/self:MagnitudeSquared(ah,ai)
    if D<0 then return af elseif D>1 then return ag else return Point(af+ai*D)
    end
end

function XPolygon:ClipPolygons(aj,T,ak)
    assert(#aj>2 and#T>2,"ClipPolygons: insufficient number of segments (minimum 3 required)")
    assert(ak=="union"or ak=="intersection"or ak=="difference","ClipPolygons: wrong operation type (possible: union, intersection, difference)")
    local a7={}local a1,al=self:InitVertices(aj)
    local a2,am=self:InitVertices(T)
    local an=self:FindIntersectionsForClip(a1,a2)
    if an then self:IdentifyIntersectionType(a1,a2,T,aj,ak)a7=self:GetClipResult(a1,a2)
    else local ao=self:IsPointInPolygon(T,aj[1])
        local ap=self:IsPointInPolygon(aj,T[1])
        if ak=="union"then if ao then return T,nil elseif ap then return aj,nil
            end elseif ak=="intersection"then if ao then return aj,nil elseif ap then return T,nil
            end
        end
        return aj,T
    end
    return a7,nil
end

function XPolygon:CrossProduct(aq,ar)
    assert(x(aq)and x(ar),"CrossProduct: wrong input values (number expected)")
    return aq.x*ar.y-aq.y*ar.x
end

function XPolygon:Direction(aq,ar)
    assert(x(aq)and x(ar),"Direction: wrong input values (number expected)")
    return aq.y==ar.y and"horizontal"or(ar.x-aq.x)/(ar.y-aq.y)
end

function XPolygon:Distance(aq,ar)
    assert(x(aq)and x(ar),"Distance: wrong input values (number expected)")
    return p(self:DistanceSquared(aq,ar))
end

function XPolygon:DistanceSquared(aq,ar)
    assert(x(aq)and x(ar),"DistanceSquared: wrong input values (number expected)")
    return(aq.x-ar.x)^2+(aq.y-ar.y)^2
end

function XPolygon:DotProduct(aq,ar)
    assert(x(aq)and x(ar),"DotProduct: wrong input values (number expected)")
    return aq.x*ar.x+aq.y*ar.y
end

function XPolygon:GetPolygonSegments(L)
    assert(#L>2,"GetPolygonSegments: insufficient number of segments (minimum 3 required)")
    local as={}for N=1,#L do q(as,{L[N],L[N%#L+1]})
    end
    return as
end

function XPolygon:Intersection(at,au,av,aw)
    local at,au,av,aw=Point(at),Point(au),Point(av),Point(aw)
    local ax,ay=Point(au-at),Point(aw-av)
    local z=self:CrossProduct(ax,ay)
    local az,aA=self:CrossProduct(av-at,ay)/z,self:CrossProduct(av-at,ax)/z
    if z~=0 then return Point(at+az*ax),az>=0 and az<=1 and aA>=0 and aA<=1
    end
    return nil,nil
end

function XPolygon:IsPointOnSegment(af,ag,ae)
    assert(x(af)and x(ag)and x(ae),"IsPointOnSegment: wrong input values (number expected)")
    local aa,ab,aB,aC,aD,aE=ae.x,ae.y,af.x,af.y,ag.x,ag.y
    local aF=((aa-aB)*(aD-aB)+(ab-aC)*(aE-aC))/((aD-aB)^2+(aE-aC)^2)
    local aG=aF<0 and 0 or(aF>1 and 1 or aF)
    return aG==aF
end

function XPolygon:IsPointInPolygon(L,ad)
    assert(#L>2,"IsPointInPolygon: insufficient number of segments (minimum 3 required)")
    assert(x(ad),"IsPointInPolygon: wrong input values (number expected)")
    local a7,aH=false,#L
    for N=1,#L do if L[N].y<ad.y and L[aH].y>=ad.y or L[aH].y<ad.y and L[N].y>=ad.y then if L[N].x+(ad.y-L[N].y)/(L[aH].y-L[N].y)*(L[aH].x-L[N].x)<ad.x then a7=not a7
        end
    end
    aH=N
    end
    return a7
end

function XPolygon:Magnitude(aI)
    assert(x(aI),"Magnitude: wrong input values (number expected)")
    return p(self:MagnitudeSquared(aI))
end

function XPolygon:MagnitudeSquared(aI)
    assert(x(aI),"MagnitudeSquared: wrong input values (number expected)")
    return aI.x*aI.x+aI.y*aI.y
end

function XPolygon:MovePolygon(L,aJ)
    assert(#L>2,"MovePolygon: insufficient number of segments (minimum 3 required)")
    assert(x(aJ),"MovePolygon: wrong input values (number expected)")
    local a7={}for N,ad in ipairs(L)do local H=Point(L[N]+aJ)q(a7,H)
    end
    return a7
end

function XPolygon:Normalize(aI)
    assert(x(aI),"Normalize: wrong input values (number expected)")
    local D=self:Magnitude(aI)
    return Point(aI.x/D,aI.y/D)
end

function XPolygon:OffsetPolygon(L,aK)
    assert(#L>2,"OffsetPolygon: insufficient number of segments (minimum 3 required)")
    assert(type(aK)=="number","OffsetPolygon: wrong input values (number expected)")
    local a7={}for N,ad in ipairs(L)do local aH,aL=N-1,N+1
        if aH<1 then aH=#L
        end
        if aL>#L then aL=1
        end
        local aq,ar,aM=L[aH],L[N],L[aL]local aN=Point(ar-aq):Normalized():Perpendicular()*aK
        local B,C=Point(aq+aN),Point(ar+aN)
        local aO=Point(aM-ar):Normalized():Perpendicular()*aK
        local v,aP=Point(ar+aO),Point(aM+aO)
        local W=self:Intersection(B,C,v,aP)
        local D=self:Distance(ar,W)
        local aQ=(aq.x-ar.x)*(aM.x-ar.x)+(aq.y-ar.y)*(aM.y-ar.y)
        local aR=(aq.x-ar.x)*(aM.y-ar.y)-(aq.y-ar.y)*(aM.x-ar.x)
        local aS=d(aR,aQ)
        if D>aK and aS>0 then local aT=ar+Point(W-ar):Normalized()*aK
            local aJ=Point(aT-ar):Perpendicular()aJ=self:Normalize(aJ)*D
            local aU,aV=Point(aT-aJ),Point(aT+aJ)
            local aW=self:Intersection(aU,aV,B,C)
            local aX=self:Intersection(aU,aV,v,aP)q(a7,aW)q(a7,aX)
        else q(a7,W)
        end
    end
    return a7
end

function XPolygon:PolygonContainsPolygon(aY,aZ)
    assert(#aY>2 and#aZ>2,"PolygonContainsPolygon: insufficient number of segments (minimum 3 required)")for N=1,#aY do if self:IsPointInPolygon(aZ,aY[N])then return true
        end
    end
    return false
end

function XPolygon:PolygonIntersection(aY,aZ)
    assert(#aY>2 and#aZ>2,"PolygonIntersection: insufficient number of segments (minimum 3 required)")
    local ac={}local a_,b0=self:GetPolygonSegments(aY),self:GetPolygonSegments(aZ)for N,b1 in ipairs(a_)do for aH,b2 in ipairs(b0)do local ad,X=self:Intersection(b1,b2)
        if ad and X then q(ac,ad)
        end
    end
    end
    return ac
end

function XPolygon:RotatePolygon(L,aS)
    assert(#L>2,"RotatePolygon: insufficient number of segments (minimum 3 required)")
    assert(type(aS)=="number","RotatePolygon: wrong input values (number expected)")
    local a7,aS={},n(aS)for N,ad in ipairs(L)do local z=ad.x*g(aS)-ad.y*o(aS)
        local A=ad.x*o(aS)+ad.y*g(aS)q(a7,Point(z,A))
    end
    return a7
end
