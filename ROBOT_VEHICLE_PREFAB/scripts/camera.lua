--> CAMERA
do
	initCamera = function()
		cameraX = 0
		cameraY = 0
		zoom = 2
	end
	manageCamera = function(disableRotation)
		local mx, my = InputValue("mousedx"), InputValue("mousedy")
		disableRotation = disableRotation or false
		if disableRotation then mx, my = 0,0 end
		cameraX = cameraX - mx / 10
		cameraY = cameraY - my / 10
		cameraY = clamp(cameraY, -75, 75)
		local cameraRot = QuatEuler(cameraY, cameraX, 0)
		local cameraT = Transform(VecAdd(GetBodyTransform(robot.body).pos, 5), cameraRot)
		zoom = zoom - InputValue("mousewheel") * 2.5
		zoom = clamp(zoom, 2, 20)
		local cameraPos = TransformToParentPoint(cameraT, Vec(0, 3, zoom))
		local camera = Transform(VecLerp(cameraPos, GetCameraTransform().pos, 0.5), cameraRot)
		SetCameraTransform(camera)
	end
	getOuterCrosshairWorldPos = function()

		local crosshairTr = getCrosshairTr()
		rejectAllBodies(robot.allBodies)
		local crosshairHit, crosshairHitPos = RaycastFromTransform(crosshairTr, 200)
		if crosshairHit then
			return crosshairHitPos
		else
			return nil
		end

	end
	getCrosshairTr = function(pos)

		pos = pos or GetCameraTransform()

		local crosshairDir = UiPixelToWorld(CAMERA.xy[1], CAMERA.xy[2])
		local crosshairQuat = DirToQuat(crosshairDir)
		local crosshairTr = Transform(GetCameraTransform().pos, crosshairQuat)

		return crosshairTr

	end
end