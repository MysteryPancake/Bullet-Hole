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

hook.Add( "EntityFireBullets", "BulletHoles", function( ent, info )

	local front = util.TraceLine( {
		start = info.Src,
		endpos = info.Src + info.Dir * info.Distance,
		mask = MASK_SHOT_HULL,
		filter = ent
	} )
	
	local frontEnt = front.Entity
	if IsValid( frontEnt ) and frontEnt:IsPlayer() or frontEnt:IsNPC() then return end

	local back = BackSide( {
		start = front.HitPos,
		dir = front.Normal,
		distance = info.Distance,
		mask = MASK_SHOT_HULL,
		filter = ent
	}, 50 )

	local backEnt = back.Entity
	if IsValid( backEnt ) and backEnt:IsPlayer() or backEnt:IsNPC() then return end

	--if front.HitPos:Distance( back.HitPos ) > 200 then return end

	local size = math.random( 5, 10 )

	local frontHole = ents.Create( "bullet_hole" )

	if IsValid( frontEnt ) and front.HitNonWorld then
		frontHole:SetParent( frontEnt )
		frontEnt:DeleteOnRemove( frontHole )
	end

	frontHole:SetPos( front.HitPos )
	frontHole:SetAngles( front.HitNormal:Angle() )
	frontHole:SetSize( size )
	frontHole:Spawn()

	local backHole = ents.Create( "bullet_hole" )

	if IsValid( backEnt ) and back.HitNonWorld then
		backHole:SetParent( backEnt )
		backEnt:DeleteOnRemove( backHole )
	end

	backHole:SetPos( back.HitPos )
	backHole:SetAngles( back.HitNormal:Angle() )
	backHole:SetSize( size )
	backHole:Spawn()

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