local function BackSide( trace, margin )
	local tr = util.TraceLine( {
		start = trace.start + trace.dir * margin,
		endpos = trace.start + trace.dir * trace.distance,
		filter = trace.filter,
		mask = trace.mask
	} )
	return util.TraceLine( {
		start = tr.HitPos - trace.dir * margin,
		endpos = tr.HitPos - trace.dir * trace.distance,
		filter = trace.filter,
		mask = trace.mask
	} )
end

local function ParentHole( hole, ent, trace )
	if IsValid( ent ) and trace.HitNonWorld then
		if ent:IsRagdoll() then
			hole:SetParentPhysNum( trace.PhysicsBone )
		end
		hole:SetParent( ent )
		ent:DeleteOnRemove( hole )
	end
end

hook.Add( "EntityFireBullets", "BulletHoles", function( ply, info )

	local front = util.TraceLine( {
		start = info.Src,
		endpos = info.Src + info.Dir * info.Distance,
		mask = MASK_SHOT_HULL,
		filter = ply
	} )
	
	local frontEnt = front.Entity
	if IsValid( frontEnt ) and frontEnt:IsPlayer() or frontEnt:IsNPC() then return end

	local back = BackSide( {
		start = front.HitPos,
		dir = front.Normal,
		distance = info.Distance,
		mask = MASK_SHOT_HULL,
		filter = ply
	}, 50 )

	local backEnt = back.Entity
	if IsValid( backEnt ) and backEnt:IsPlayer() or backEnt:IsNPC() then return end

	if front.HitPos:Distance( back.HitPos ) > 200 then return end

	local size = math.random( 5, 10 )

	local frontHole = ents.Create( "bullet_hole" )
	frontHole:SetPos( front.HitPos )
	frontHole:SetAngles( front.HitNormal:Angle() )
	frontHole:SetSize( size )
	frontHole:Spawn()

	ParentHole( frontHole, frontEnt, front )

	local backHole = ents.Create( "bullet_hole" )
	backHole:SetPos( back.HitPos )
	backHole:SetAngles( back.HitNormal:Angle() )
	backHole:SetSize( size )
	backHole:Spawn()

	ParentHole( backHole, backEnt, back )

	frontHole:SetPartner( backHole )
	backHole:SetPartner( frontHole )

	info.Src = back.HitPos

	return true

end )

hook.Add( "SetupPlayerVisibility", "BulletHoles", function()
	for _, hole in ipairs( ents.FindByClass( "bullet_hole" ) ) do
		AddOriginToPVS( hole:GetPos() )
	end
end )