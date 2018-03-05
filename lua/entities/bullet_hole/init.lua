AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

function ENT:TransformPosition( pos )
	local lPos = self:WorldToLocal( pos )
	lPos:Rotate( Angle( 0, 180, 0 ) )
	local wPos = self:GetPartner():LocalToWorld( lPos )
	return wPos
end

function ENT:StartTouch( ent )

	if ent.BulletHole or not IsValid( self:GetPartner() ) or ent:IsPlayer() then return end
	if ent:BoundingRadius() > self:GetSize() * 2 then return end
	local normal = ent:GetVelocity():GetNormalized()
	if normal:Dot( self:GetForward() ) > 0 then return end

	if ent.SetCollisionGroup then
		ent.OldCollisionGroup = ent:GetCollisionGroup()
		ent:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
	elseif ent.SetMoveType then
		ent.OldMoveType = ent:GetMoveType()
		ent:SetMoveType( MOVETYPE_NOCLIP )
	else
		ent:SetPos( self:TransformPosition( ent:GetPos() ) )
	end

	ent.BulletHole = self
	self:SetCaptive( ent )

end

function ENT:DropCaptive( ent )

	timer.Simple( 0.05, function()

		if ent.OldCollisionGroup then
			ent:SetCollisionGroup( ent.OldCollisionGroup )
			ent.OldCollisionGroup = nil
		end

		if ent.OldMoveType then
			ent:SetMoveType( ent.OldMoveType )
			ent.OldMoveType = nil
		end

		ent.BulletHole = nil

	end )

	self:SetCaptive( nil )

end

function ENT:EndTouch( ent )

	if not ent.BulletHole or ent.BulletHole == self then return end

	self:DropCaptive( ent )

end

function ENT:Think()

	local captive = self:GetCaptive()
	if not IsValid( captive ) then return end

	local partner = self:GetPartner()
	if not IsValid( partner ) then return end

	if captive:GetPos():Distance( self:GetPos() ) > self:GetPos():Distance( partner:GetPos() ) then
		self:DropCaptive( captive )
	end

end

function ENT:OnTakeDamage()
	return true
end