--[[
With entities, you can use  ENT:RenderOverride to not draw the holes in the first place, thereby not having to RenderView to draw the other side of holes (it would just be drawn as usual), and shaving off a huge part of the performance loss.

It can be tricky, especially if you want to see the same entity through the hole (like the dumpster in your video), but with clever use of clip planes it's 100% doable.
]]

AddCSLuaFile()

ENT.Type = "anim"

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Editable = false

ENT.PrintName = "Bullet Hole"
ENT.Author = "MysteryPancake"
ENT.RenderGroup = RENDERGROUP_BOTH

if CLIENT then
	AccessorFunc( ENT, "texture", "Texture" )
	AccessorFunc( ENT, "drawNextFrame", "DrawNextFrame" )
end

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

if SERVER then

	local function TransformPosition( pos, hole, partner )
		local lPos = hole:WorldToLocal( pos )
		lPos:Rotate( Angle( 0, 180, 0 ) )
		local wPos = partner:LocalToWorld( lPos )
		return wPos
	end

	function ENT:OnTakeDamage() return true end

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

end

if CLIENT then

	local function ShouldRender( hole, pos )
		if rendering then return false end
		if not hole:GetDrawNextFrame() then return false end
		if not IsValid( hole:GetPartner() ) then return false end
		if hole:GetForward():Dot( pos - hole:GetPos() ) < 0 then return false end
		return true
	end

	local function DrawCircle( x, y, radius, seg )
		local circle = {}
		table.insert( circle, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( i / seg ) * -360 )
			table.insert( circle, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) * 0.5 + 0.5, v = math.cos( a ) * 0.5 + 0.5 } )
		end
		local a = math.rad( 0 )
		table.insert( circle, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) * 0.5 + 0.5, v = math.cos( a ) * 0.5 + 0.5 } )
		surface.DrawPoly( circle )
	end

	local rendering = false
	local mat = CreateMaterial( "UnlitGeneric", "GMODScreenspace", {
		[ "$basetexturetransform" ] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
		[ "$texturealpha" ] = "0",
		[ "$vertexalpha" ] = "1"
	} )

	function ENT:Draw()

		local partner = self:GetPartner()
		if rendering or not IsValid( partner ) then return end

		self:SetDrawNextFrame( true )

		render.ClearStencil()
		render.SetStencilEnable( true )

			render.SetStencilWriteMask( 255 )
			render.SetStencilTestMask( 255 )
			render.SetStencilReferenceValue( 0 )

			render.SetStencilCompareFunction( STENCIL_ALWAYS )
			render.SetStencilPassOperation( STENCIL_INCR )
			render.SetStencilFailOperation( STENCIL_KEEP )
			render.SetStencilZFailOperation( STENCIL_KEEP )


			local selfAng = self:GetAngles()
			selfAng:RotateAroundAxis( selfAng:Right(), -90 )

			cam.Start3D2D( self:GetPos() + self:GetForward(), selfAng, 1 )
				draw.NoTexture()
				surface.SetDrawColor( 0, 0, 0, 255 )
				DrawCircle( 0, 0, self:GetSize(), self:GetSize() )
			cam.End3D2D()

			render.SetStencilReferenceValue( 1 )
			render.SetStencilCompareFunction( STENCIL_EQUAL )

			local partnerAng = partner:GetAngles()
			partnerAng:RotateAroundAxis( partnerAng:Right(), -90 )
			partnerAng:RotateAroundAxis( partnerAng:Forward(), 180 )

			cam.Start3D2D( partner:GetPos() + partner:GetForward(), partnerAng, 1 )
				draw.NoTexture()
				cam.IgnoreZ( true )
				surface.SetDrawColor( 255, 255, 255, 255 )
				DrawCircle( 0, 0, partner:GetSize(), partner:GetSize() )
				cam.IgnoreZ( false )
			cam.End3D2D()

			render.SetStencilReferenceValue( 2 )
			render.SetStencilPassOperation( STENCIL_KEEP )

			mat:SetTexture( "$basetexture", self:GetTexture() )
			render.SetMaterial( mat )
			render.DrawScreenQuad()

		render.SetStencilEnable( false )

		if IsValid( self:GetCaptive() ) then
			cam.Start3D()
				cam.IgnoreZ( true )
				self:GetCaptive():DrawModel()
				cam.IgnoreZ( false )
			cam.End3D()
		end

	end

	hook.Add( "RenderScene", "BulletHoles", function( pos, ang )

		if rendering then return end

		local holes = ents.FindByClass( "bullet_hole" )
		if not holes then return end

		for _, hole in ipairs( holes ) do

			if not ShouldRender( hole, pos ) then continue end

			hole:SetDrawNextFrame( false )

			render.PushRenderTarget( hole:GetTexture() )

				render.Clear( 0, 0, 0, 255, true, true )

				local oldClip = render.EnableClipping( true )

				local partner = hole:GetPartner()
				local normal = partner:GetForward()
				render.PushCustomClipPlane( normal, normal:Dot( partner:GetPos() ) )

					rendering = true
					render.RenderView( {
						x = 0, y = 0,
						w = ScrW(), h = ScrH(),
						origin = pos, angles = ang,
						dopostprocess = false,
						drawviewmodel = false,
						drawmonitors = false,
						bloomtone = true,
						drawhud = false
					} )
					rendering = false

				render.PopCustomClipPlane()
				render.EnableClipping( oldClip )

			render.PopRenderTarget()

		end

	end )

end
