include( "shared.lua" )

AccessorFunc( ENT, "texture", "Texture" )
AccessorFunc( ENT, "drawNextFrame", "DrawNextFrame" )

local rendering = false
local mat = CreateMaterial( "UnlitGeneric", "GMODScreenspace", {
	[ "$basetexturetransform" ] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
	[ "$texturealpha" ] = "0",
	[ "$vertexalpha" ] = "1"
} )

function ENT:DrawCircle( x, y, radius, seg )
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
			self:DrawCircle( 0, 0, self:GetSize(), self:GetSize() )
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
			partner:DrawCircle( 0, 0, partner:GetSize(), partner:GetSize() )
			cam.IgnoreZ( false )
		cam.End3D2D()

		render.SetStencilReferenceValue( 2 )
		render.SetStencilPassOperation( STENCIL_KEEP )

		mat:SetTexture( "$basetexture", self:GetTexture() )
		render.SetMaterial( mat )
		render.DrawScreenQuad()

		if IsValid( self:GetCaptive() ) then
			cam.Start3D()
				cam.IgnoreZ( true )
				self:GetCaptive():DrawModel()
				cam.IgnoreZ( false )
			cam.End3D()
		end

	render.SetStencilEnable( false )

end