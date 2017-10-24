ENT.Type = "anim"

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Editable = false

ENT.PrintName = "Bullet Hole"
ENT.Author = "MysteryPancake"
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar( "Entity", 0, "Partner" )
	self:NetworkVar( "Entity", 1, "Captive" )
	self:NetworkVar( "Int", 1, "Size" )
end

function ENT:Initialize()

	local mins = Vector( 0, -self:GetSize(), -self:GetSize() )
	local maxs = Vector( 10, self:GetSize(), self:GetSize() )

	if CLIENT then
		self:SetTexture( GetRenderTarget( "BulletHole" .. self:EntIndex(), ScrW(), ScrH(), false ) )
		self:SetRenderBounds( mins, maxs )
	else
		self:SetTrigger( true )
		self:SetUnFreezable( true )
	end

	self:SetSolid( SOLID_OBB )
	self:SetMoveType( MOVETYPE_NONE )
	--self:EnableCustomCollisions( true )
	self:SetCollisionBounds( mins, maxs )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )

	self:SetNotSolid( true )
	self:DrawShadow( false )

end

--function ENT:TestCollision() return end -- Should stop hits from hitting it