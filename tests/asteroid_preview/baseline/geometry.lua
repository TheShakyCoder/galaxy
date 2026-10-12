-- Pure Lua geometry: no engine APIs or global random state. A system/index
-- pair always produces the same rock, including after respawn.
local M = { DURATION = 2, SUBDIVISIONS = 3 }
local sqrt, sin, cos, exp = math.sqrt, math.sin, math.cos, math.exp
local function add(a,b) return {a[1]+b[1],a[2]+b[2],a[3]+b[3]} end
local function sub(a,b) return {a[1]-b[1],a[2]-b[2],a[3]-b[3]} end
local function mul(a,s) return {a[1]*s,a[2]*s,a[3]*s} end
local function dot(a,b) return a[1]*b[1]+a[2]*b[2]+a[3]*b[3] end
local function cross(a,b) return {a[2]*b[3]-a[3]*b[2],a[3]*b[1]-a[1]*b[3],a[1]*b[2]-a[2]*b[1]} end
local function unit(a) return mul(a,1/sqrt(dot(a,a))) end

function M.seed(system, index)
	local h = 1
	for i = 1, #system do h = (h * 31 + system:byte(i)) % 2147483647 end
	return (h + index * 104729) % 2147483646 + 1
end

local function random(seed)
	local state = math.floor(seed) % 2147483646 + 1
	return function()
		state = state * 16807 % 2147483647 -- exact within Lua's double mantissa
		return (state - 1) / 2147483646
	end
end

local topology
local function sphere()
	if topology then return topology[1], topology[2] end
	local t = (1 + sqrt(5)) / 2
	local vertices = {{-1,t,0},{1,t,0},{-1,-t,0},{1,-t,0},{0,-1,t},{0,1,t},
		{0,-1,-t},{0,1,-t},{t,0,-1},{t,0,1},{-t,0,-1},{-t,0,1}}
	for i,p in ipairs(vertices) do vertices[i] = unit(p) end
	local faces = {{1,12,6},{1,6,2},{1,2,8},{1,8,11},{1,11,12},{2,6,10},
		{6,12,5},{12,11,3},{11,8,7},{8,2,9},{4,10,5},{4,5,3},{4,3,7},
		{4,7,9},{4,9,10},{5,10,6},{3,5,12},{7,3,11},{9,7,8},{10,9,2}}
	for i,f in ipairs(faces) do f[4] = i end
	for _ = 1, M.SUBDIVISIONS do
		local cache, next_faces = {}, {}
		local function midpoint(a,b)
			local key = math.min(a,b) .. ":" .. math.max(a,b)
			if not cache[key] then
				vertices[#vertices+1] = unit(add(vertices[a],vertices[b]))
				cache[key] = #vertices
			end
			return cache[key]
		end
		for _,f in ipairs(faces) do
			local a,b,c,g = f[1],f[2],f[3],f[4]
			local ab,bc,ca = midpoint(a,b),midpoint(b,c),midpoint(c,a)
			for _,v in ipairs({{a,ab,ca,g},{b,bc,ab,g},{c,ca,bc,g},{ab,bc,ca,g}}) do
				next_faces[#next_faces+1] = v
			end
		end
		faces = next_faces
	end
	topology = {vertices, faces}
	return vertices, faces
end

function M.generate(seed)
	local rand = random(seed)
	local directions, faces = sphere()
	local stretch = {0.65+rand()*0.5,0.65+rand()*0.5,0.65+rand()*0.5}
	local phase = {rand()*6.28,rand()*6.28,rand()*6.28}
	local craters = {}
	for i = 1, 9 do
		local y, angle = rand()*2-1, rand()*math.pi*2
		local r = sqrt(1-y*y)
		craters[i] = {dir={r*cos(angle),y,r*sin(angle)}, width=0.018+rand()*0.065, depth=0.08+rand()*0.14}
	end
	local points, shades, max_radius = {}, {}, 0
	for i,d in ipairs(directions) do
		local x,y,z = d[1],d[2],d[3]
		local broad = sin(x*3.1+phase[1])*cos(y*2.7+phase[2])*sin(z*3.3+phase[3])
		local grit = sin(x*19+phase[3])*sin(y*17+phase[1])*cos(z*21+phase[2])
		local radius, depression = 1+0.24*broad+0.035*grit, 0
		for _,c in ipairs(craters) do
			local q = (1-dot(d,c.dir))/c.width
			local bowl = c.depth*exp(-q*3)
			radius = radius-bowl+0.045*exp(-((q-0.95)*3)^2)
			depression = depression+bowl
		end
		local p = {x*radius*stretch[1],y*radius*stretch[2],z*radius*stretch[3]}
		points[i] = p
		shades[i] = 0.72+0.16*broad+0.08*grit-depression*0.7
		max_radius = math.max(max_radius,sqrt(dot(p,p)))
	end
	-- Entire surface remains inside the existing gameplay/targeting sphere.
	for i,p in ipairs(points) do points[i] = mul(p,0.5/max_radius) end
	local normals, groups = {}, {}
	for i = 1,#points do normals[i] = {0,0,0} end
	for i = 1,20 do groups[i] = {faces={}, edges={}, center={0,0,0}} end
	for _,f in ipairs(faces) do
		local n = cross(sub(points[f[2]],points[f[1]]),sub(points[f[3]],points[f[1]]))
		local group = groups[f[4]]
		group.faces[#group.faces+1] = f
		for k = 1,3 do
			local a,b = f[k],f[k%3+1]
			normals[a] = add(normals[a],n)
			group.center = add(group.center,points[a])
			local key = math.min(a,b)..":"..math.max(a,b)
			if group.edges[key] then group.edges[key] = nil else group.edges[key] = {a,b} end
		end
	end
	for i,n in ipairs(normals) do normals[i] = unit(n) end
	local streams = {position={},normal={},color={},fragment={},motion={}}
	local warm = rand()
	local base = {0.40+warm*0.09,0.39+warm*0.045,0.38}
	local function emit(p,n,shade,g,interior)
		local values = {position=p,normal=n,color={base[1]*shade,base[2]*shade,base[3]*shade,interior},
			fragment={g.center[1],g.center[2],g.center[3],g.delay},motion=g.motion}
		for name,v in pairs(values) do
			local out = streams[name]
			for _,value in ipairs(v) do out[#out+1] = value end
		end
	end
	for _,g in ipairs(groups) do
		g.center = mul(g.center,0.75/(#g.faces*3))
		g.delay = rand()*0.32
		g.motion = {rand()*2-1,rand()*2-1,rand()*2-1,0.35+rand()*0.4}
		for _,f in ipairs(g.faces) do
			for k = 1,3 do local i=f[k]; emit(points[i],normals[i],shades[i],g,0) end
		end
		-- Close each wedge with darker freshly fractured rock. Sorted edge keys
		-- make stream ordering deterministic across Lua implementations.
		local keys = {}
		for key in pairs(g.edges) do keys[#keys+1] = key end
		table.sort(keys)
		for _,key in ipairs(keys) do
			local edge = g.edges[key]
			local a,b = points[edge[2]],points[edge[1]]
			local n = unit(cross(sub(b,a),mul(a,-1)))
			emit(a,n,0.53,g,1); emit(b,n,0.53,g,1); emit({0,0,0},n,0.45,g,1)
		end
	end
	return streams
end

return M
