local function ShouldRender( hole, pos )
	if rendering then return false end
	if not hole:GetDrawNextFrame() then return false end
	if not IsValid( hole:GetPartner() ) then return false end
	if hole:GetForward():Dot( pos - hole:GetPos() ) < 0 then return false end
	return true
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