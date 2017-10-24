AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

local function TransformPosition( pos, hole, partner )
	local lPos = hole:WorldToLocal( pos )
	lPos:Rotate( Angle( 0, 180, 0 ) )
	local wPos = partner:LocalToWorld( lPos )
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
		ent:SetPos( TransformPosition( ent:GetPos(), self, self:GetPartner() ) )
	end

	ent.BulletHole = self
	self:SetCaptive( ent )

end

function ENT:EndTouch( ent )

	if self:GetCaptive() == ent then
		self:SetCaptive( nil )
	end

	if not ent.BulletHole or ent.BulletHole == self then return end

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

end

function ENT:OnTakeDamage()
	return true
end