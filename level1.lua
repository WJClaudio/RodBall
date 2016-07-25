-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local gameNetwork = require( "gameNetwork" )
local scene = composer.newScene()
local gameUI = require("gameUI")
local physics = require "physics"
local widget = require "widget"

local background
local ball 
local rod
local saviorRod
local walls
local controls
local pauseBtn
local soundBtn

local isGamePaused = false

-- include Corona's "physics" library
local physics 
local gravity

local timerGroup
local rightTimer
local leftTimer
local objectsTable = {}

local counter
local levelCounter
local level
local points
local pointsCounter
local rodVelocity
local angularVelocity
local targetWall
local healthCounter
local touchedRod
local saviorRodOnScreen
local feather -- Acounts for accidental and unfair rod touches that get anoying after a while
local soundIsOn
local rightPressed
local leftPressed

-- This is boolshit
local shrinkBallBool
local enlargeBallBool
local shrinkRodBool
local enlargeRodBool
local saviorRodCreationBool
local restoreRodBool
local restoreBallBool
-- End of boolshit

math.randomseed(os.date("%j"))
local r,g,b = .1,.1,.1
local aColor = {2,0,0}
local bColor = {6,0,0, .01}

local GameLoop = audio.loadSound("Synapsis_-_07_-_Pandora.mp3")
local loseSound = audio.loadSound("lose.wav")
local aHitSound = audio.loadSound("a-sound.mp3")
local bHitSound = audio.loadSound("b-sound.mp3")
local levelUpSound = audio.loadSound("levelup.wav")

local soundBtnImage = {type="image", filename="soundOn.png"}
local soundBtnImageOff = {type="image", filename="soundOff.png"}


--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW, halfH = display.contentWidth, display.contentHeight, display.contentWidth*0.5, display.contentHeight*0.5

function scene:create( event )

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	print("scene is created")
	system.activate( "multitouch" )

	local sceneGroup = self.view

	physics = require "physics"
	physics.start();physics.pause()

	points = 0
	pointsCounter = 0
	level = 1
	levelCounter = 4

	-- Boolshit
    shrinkBallBool = false
    enlargeBallBool = false
    shrinkRodBool = false
    enlargeRodBool = false
    saviorRodCreationBool = false
    restoreBallBool = false
    restoreRodBool = false

	score = display.newText(points, halfW, halfH*.5)

	-- create a gray rectangle as the backdrop
	background = display.newRect( 0, 0, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( .5 )

	-- Create mute button
	soundBtn = display.newRect(screenW*.3,screenH*.1, 16,16)
	soundBtn.fill = soundBtnImage

	soundIsOn = true

	function  muteSound(event)
		if (event.phase == "began") then
			if (soundIsOn == false) then
				audio.setVolume(1)
				soundBtn.fill = soundBtnImage
				soundIsOn = true
			elseif (soundIsOn) then
				audio.setVolume(0)
				soundBtn.fill = soundBtnImageOff
				soundIsOn = false
			end
		end
	end

	soundBtn:addEventListener("touch", muteSound)
	-- End of soundBtn

	-- Pause btn
	pauseBtn = display.newGroup()
	pauseBtn.x, pauseBtn.y = screenW*.1, screenH*.1
	local tapArea = display.newCircle(pauseBtn, 0,0, 32)
	tapArea:setFillColor(0,0,0,.01)
	local stick1 = display.newRect(pauseBtn, -4, 0, 4,16)
	local stick2 = display.newRect(pauseBtn, 4, 0, 4, 16)

	function pause(event)
		print("game is paused")
		if (event.phase == "began") then
			if (isGamePaused == true) then
				physics.start()
				isGamePaused = false
			elseif(isGamePaused == false) then
				isGamePaused = true
				physics.pause()
			end
		end
	end

	pauseBtn:addEventListener("touch", pause)
	-- End of Pause btn

	-- Game walls
	walls = display.newGroup()
	local leftWall = display.newRect(walls, 0, halfH, 16, screenH*2)
	leftWall.myName = "leftWall"
	leftWall:setFillColor(2,0,0, .0)
	local rightWall = display.newRect(walls, screenW+1, halfH, 16, screenH*2)
	rightWall.myName = "rightWall"
	rightWall:setFillColor(2,0,0)
	local topWall = display.newRect(walls, halfW, 0, screenW, 1)
	topWall.myName = "topWall"

	physics.addBody(leftWall, "static")
	physics.addBody(rightWall, "static")
	physics.addBody(topWall, "static")

	targetWall = "rightWall"
	-- End of walls

	-- make a rod (off-screen), position it, and rotate slightly
	rodGroup = display.newGroup()
	rodGroup.x, rodGroup.y = halfW, halfH
	rod = display.newRect(rodGroup,0,0,128, 16)
	rodGroup.x, rodGroup.y = halfW, screenH*.75
	rodGroup.myName = "rod"
	rodVelocity = 64
	physics.addBody( rodGroup,"kinematic", {bounce = 1})
	rodGroup.angularVelocity = rodVelocity

	function rodBounds() --Limits rod from going off-screen
		if rodGroup.x < 0 then 
			rodGroup:setLinearVelocity(0,0)
			rightPressed = true
		elseif rodGroup.x > screenW then
			rodGroup:setLinearVelocity(0,0)
			leftPressed = true
		end
	end

	Runtime:addEventListener("enterFrame", rodBounds)
	-- End of rod

	saviorRodOnScreen = false
	touchedRod = false

	-- make a ball (off-screen)
	ballGroup = display.newGroup()
	ballGroup.x, ballGroup.y = halfW, halfH *.5
	ball = display.newCircle(ballGroup,0, 0, 16)
	ballGroup.myName = "ball"
	physics.addBody( ballGroup, "dynamic", {radius = 16})

	local function ballCollision( self, event )
		local other = event.other.myName

		local function featheryTouch()
			feather = false
		end


	    if ( event.phase == "began" ) then
	        print( self.myName .. ": collision began with " .. event.other.myName )
	        if (other == targetWall) then
	        	audio.play(aHitSound)
	        	touchedRod = false
	        	if (targetWall == "rightWall") then
	        		targetWall = "leftWall"
	        		leftWall:setFillColor(unpack(aColor))
	        		rightWall:setFillColor(unpack(bColor), .01)
	        	elseif (targetWall == "leftWall") then
	        		targetWall = "rightWall"
	        		rightWall:setFillColor(unpack(aColor))
	        		leftWall:setFillColor(unpack(bColor), .01)
	        	end
	        	points = points + 1
	        	pointsCounter = pointsCounter + 1
	        elseif ( other == "rod") then
	        	audio.play(bHitSound)
	        	if (touchedRod == true and feather == false) then 
	        		setHealth(false)
	        	else
	        		feather = true
	        		touchTimer = timer.performWithDelay(64, featheryTouch)
	        		touchedRod = true
	        	end
	        end
	    elseif ( event.phase == "ended" ) then
		    if (other == "saviorRod") then
		    	saviorRodOnScreen = false
		    	Runtime:removeEventListener("enterFrame", moveSaviorRod)
		    	display.remove(saviorRodGroup)
		    	saviorRodGroup = nil
		    	saviorRod = nil
		        print( self.myName .. ": collision ended with " .. event.other.myName )
		    end
	    end
	end

	ballGroup.collision = ballCollision
	ballGroup:addEventListener("collision", ballGroup)
	-- End of ball

	-- controls group
	rightPressed = false
	leftPressed = false

	controls = display.newGroup()
	local left = display.newRect(controls, halfW/2, halfH, halfW, screenH)
	left.myName = "left"
	left:setFillColor(0,0,0, .01)
	local right = display.newRect(controls, halfW*1.5, halfH, halfW, screenH)
	right.myName = "right"
	right:setFillColor(0,0,0, .01)


	local function pressRight(event)
		if event.phase == "began" then
			if leftPressed == true then
				leftPressed = false
			end
			rightPressed = true
			rodGroup.angularVelocity = rodVelocity
			rightTimer = timer.performWithDelay(1, moveRight, 0)
			table.insert(timerGroup, rightTimer)
		elseif event.phase == "ended" then 
			rightPressed = false
			timer.cancel(rightTimer)
			rodGroup:setLinearVelocity(0,0)
			return
		end
	end

	local function pressLeft(event)
		if event.phase == "began" then
			if rightPressed == true then
				rightPressed = false
			end
			leftPressed = true
			rodGroup.angularVelocity = -1*rodVelocity
			leftTimer = timer.performWithDelay(1, moveLeft, 0)
			table.insert(timerGroup, leftTimer)
		elseif event.phase == "ended" then
			leftPressed = false	 
			timer.cancel(leftTimer)
			rodGroup:setLinearVelocity(0,0)
			return
		end
	end

	right:addEventListener("touch", pressRight)
	left:addEventListener("touch", pressLeft)

	function moveRight()
		if (rightPressed == true and leftPressed == false) then
			if rodGroup~= nil then
				rodGroup:setLinearVelocity(256,0)
			end
		else
			return
		end
	end

	function moveLeft()
		if (leftPressed == true and rightPressed == false) then
			if rodGroup~= nil then
				rodGroup:setLinearVelocity(-256,0)
			end
		else
			return
		end
	end

	local function onKeyEvent( event )

		if event.phase == "down" then
		    if ( event.keyName == "right" ) then
		    	rightPressed = true
		        moveRight()
		        rodGroup.angularVelocity = rodVelocity
		    end

		    if ( event.keyName == "left" ) then
		    	leftPressed = true
		        moveLeft()
		        rodGroup.angularVelocity = -1*rodVelocity
		    end
	    elseif event.phase == "up" then
	    	rodGroup:setLinearVelocity(0,0)
	    	 if ( event.keyName == "right" ) then
		    	rightPressed = false
		    end

		    if ( event.keyName == "left" ) then
		    	leftPressed = false
		    end
	    end

	    return false
	end 

	Runtime:addEventListener("key", onKeyEvent)
	-- End of controls

	-- health
	healthCounter = 3
	local healthsquares = display.newGroup()
	local healthsquare1 = display.newRect(healthsquares, screenW*.9, screenH*.1, 16,16)
	local healthsquare2 = display.newRect(healthsquares, screenW*.8, screenH*.1, 16,16)
	local healthsquare3 = display.newRect(healthsquares, screenW*.7, screenH*.1, 16,16)

	function setHealth(con)
		-- Add or take away health
		if (healthCounter == 0) then 
			return
		elseif con == true then
			print("setting health!")
			healthCounter = healthCounter + 1
			healthsquares[healthCounter] = display.newRect(healthsquares, screenW*((healthCounter + (math.abs(5-healthCounter) + math.abs(5-healthCounter))) * .1), screenH*.1, 16,16)
			print(healthsquares[healthCounter].x)
			print(screenW*((healthCounter + (math.abs(5-healthCounter) + math.abs(5-healthCounter))) * .1))
		elseif con ==  false then
			healthsquares[healthCounter]:setFillColor(0,0,0, .01)
			healthCounter = healthCounter - 1
		end
	end
	-- End of health

	function lose()
		local myCategory
		if (healthCounter < 1 or ballGroup.y > screenH) then

			function postScoreSubmit( event )
			   --whatever code you need following a score submission...
			   print("this worked!")
			   return true
			end

			if ( system.getInfo( "platformName" ) == "Android" ) then
			   --for GPGS, reset "myCategory" to the string provided from the leaderboard setup in Google
			   myCategory = "CgkI9-rJl7IbEAIQCw"
			end
			 
			gameNetwork.request( "setHighScore",
			{
			   localPlayerScore = { category=myCategory, value=tonumber(points) },
			   listener = postScoreSubmit
			})

			Runtime:removeEventListener("enterFrame", colorSaviorRodBall)
			Runtime:removeEventListener("enterFrame", moveSaviorRod)
			saviorRodOnScreen = false
			-- audio.play(loseSound, {channel = 2, loops = 0, fadein = 1000})
			scene:destroy()
			local options = {
                    effect = "fade",
                    time = 400,
                    params = {
                        score = points
                    }
                }
            composer.gotoScene( "lose", options)
        end
	end

	Runtime:addEventListener("enterFrame", lose)


	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert( rodGroup )
	sceneGroup:insert(ballGroup)
	sceneGroup:insert(controls)
	sceneGroup:insert(walls)
	sceneGroup:insert(healthsquares)
	sceneGroup:insert(score)
	sceneGroup:insert(pauseBtn)
	sceneGroup:insert(soundBtn)
    
    return true
end


function scene:show( event )

	print ("scene is showing")
	local phase = event.phase
	local sceneGroup = self.view
	Runtime:removeEventListener("enterFrame", colorSaviorRodBall)

	physics = require "physics"
	physics.start();physics.pause()
	-- physics.setDrawMode("hybrid")

	timerGroup = {}
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen

		print("phase show: will")
		soundIsOn = true
		audio.setVolume(1)
		audio.play(GameLoop, {channel = 1,loops = -1})
		gravity = 1
		physics.setGravity(0,1)

		local function levelUp()
			if (pointsCounter > levelCounter) then
				audio.play(levelUpSound)
				level = level + 1
				pointsCounter = 0
				rodVelocity = rodVelocity + 16
				changeColors()
				local maxTimer = timer.performWithDelay(math.random(20000,45000), Max(), 0)
			end
		end

		Runtime:addEventListener("enterFrame", levelUp)

		function sizeRod(r, velocity, val)
			physics.removeBody(r)
			r:remove(rod)
			rod = display.newRect(r,0,0,val, 16)
			rod:setFillColor(unpack(aColor))
			physics.addBody( r,"kinematic", {bounce = 1})
			r.angularVelocity = velocity
		end

		function sizeBall(b, val)
			physics.removeBody(b)
			b:remove(ball)
			ball = display.newCircle(b,0,0,val)
			ball:setFillColor(unpack(aColor))
			radius = val
			physics.addBody( b,"dynamic", {radius = val})
		end

		function setGravity(val)
			physics.setGravity(0,val)
		end

		-- fill a table with colors

		function changeColors()
		
			local r,g,b = math.random(),math.random(),math.random()

			aColor,bColor = {r,g,b}, {b,g,r, .5}
			background:setFillColor(unpack(bColor))
			rod:setFillColor(unpack(aColor))
			ball:setFillColor(unpack(aColor))
		end

		function createSaviorRod(b)
			print (saviorRodGroup)
			if b then
				return
			end
			saviorRodOnScreen = true
			saviorRodGroup = display.newGroup()
			sceneGroup:insert(saviorRodGroup)
			saviorRodGroup.myName = "saviorRod"
			saviorRodGroup.y = screenH*.9
			saviorRod = display.newRect(saviorRodGroup, 0,0, 96, 16)
			physics.addBody(saviorRodGroup, "kinematic", {bounce = 1.5})

			local function moveSaviorRod()
				if saviorRodGroup == nil then 
					return
				end
				saviorRodGroup.x = ballGroup.x
				while (saviorRodOnScreen and saviorRodGroup) do
					local r,g,b = math.random(),math.random(),math.random()
					saviorRod:setFillColor(r,g,b)
					break
				end
			end

			Runtime:addEventListener("enterFrame", moveSaviorRod)
		end

		function Max() -- Just wanted to be in the game somehow
			local Austin = math.random(0,8)
			-- local Austin = 7

			Runtime:addEventListener("enterFrame", update)

			if (Austin == 0 and ball.width > 31) then
				print(ball.width)
				badSizeBallGroup = display.newGroup()
				sceneGroup:insert(badSizeBallGroup)
				table.insert(objectsTable, badSizeBallGroup)
				badSizeBallGroup.myName = "badSizeBall"
				badSizeBallGroup.x, badSizeBallGroup.y = math.random(screenW), 4
				badSizeBall = display.newCircle(badSizeBallGroup, 0,0, 8)
				physics.addBody(badSizeBallGroup, "dynamic", {isSensor = true})
				badSizeBall:setFillColor(aColor)
				badSizeBallGroup:setLinearVelocity(0,64)

				local function badSizeBallCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("badSizeBall is colliding with" .. event.other.myName)
						display.remove(badSizeBall)
						shrinkBallBool = true
					end
				end

				badSizeBallGroup:addEventListener("collision", badSizeBallCollision)

			elseif (Austin == 1 and ball.width < 33) then
				goodSizeBallGroup = display.newGroup()
				sceneGroup:insert(goodSizeBallGroup)
				table.insert(objectsTable, goodSizeBallGroup)
				goodSizeBallGroup.myName = "goodSizeBall"
				goodSizeBallGroup.x, goodSizeBallGroup.y = math.random(screenW), 4
				goodSizeBall = display.newCircle(goodSizeBallGroup, 0,0, 8)
				physics.addBody(goodSizeBallGroup, "dynamic", {isSensor = true})
				goodSizeBall:setFillColor(aColor)
				goodSizeBallGroup:setLinearVelocity(0,64)

				local function goodSizeBallCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("goodSizeBall is colliding with" .. event.other.myName)
						display.remove(goodSizeBall)
						enlargeBallBool = true
					end
				end

				goodSizeBallGroup:addEventListener("collision", goodSizeBallCollision)

			elseif (Austin == 2 and rod.width > 127) then
				print(rod.width)
				badSizeRodGroup = display.newGroup()
				sceneGroup:insert(badSizeRodGroup)
				table.insert(objectsTable, badSizeRodGroup)
				badSizeRodGroup.myName = "badSizeRod"
				badSizeRodGroup.x, badSizeRodGroup.y = math.random(screenW), 4
				badSizeRod = display.newRect(badSizeRodGroup, 0,0, 28,8)
				physics.addBody(badSizeRodGroup, "dynamic", {isSensor = true})
				badSizeRodGroup.angularVelocity = rodVelocity
				badSizeRod:setFillColor(aColor)
				badSizeRodGroup:setLinearVelocity(0,64)

				local function badSizeRodCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("badSizeRod is colliding with" .. event.other.myName)
						display.remove(badSizeRod)
						shrinkRodBool = true
					end
				end

				badSizeRodGroup:addEventListener("collision", badSizeRodCollision)

			elseif Austin == 3 and rodGroup.contentWidth < 129 then
				print(rod.width)
				goodSizeRodGroup = display.newGroup()
				sceneGroup:insert(goodSizeRodGroup)
				table.insert(objectsTable, goodSizeRodGroup)
				goodSizeRodGroup.myName = "goodSizeRod"
				goodSizeRodGroup.x, goodSizeRodGroup.y = math.random(screenW), 4
				goodSizeRod = display.newRect(goodSizeRodGroup, 0,0, 28,8)
				physics.addBody(goodSizeRodGroup, "dynamic", {isSensor = true})
				goodSizeRodGroup.angularVelocity = rodVelocity
				goodSizeRod:setFillColor(bColor)
				goodSizeRodGroup:setLinearVelocity(0,64)

				local function goodSizeRodCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("goodSizeRod is colliding with " .. event.other.myName)
						display.remove(goodSizeRod)
						enlargeRodBool = true
					end
				end

				goodSizeRodGroup:addEventListener("collision", goodSizeRodCollision)

			elseif (Austin == 4 and saviorRodOnScreen == false) then
				saviorRodBallGroup = display.newGroup()
				sceneGroup:insert(saviorRodBallGroup)
				table.insert(objectsTable, saviorRodBallGroup)
				saviorRodBallGroup.myName = "saviorRodBall"
				saviorRodBallGroup.x, saviorRodBallGroup.y = math.random(screenW), 4
				saviorRodBall = display.newRect(saviorRodBallGroup, 0,0, 28,8)
				physics.addBody(saviorRodBallGroup, "dynamic", {isSensor = true})
				saviorRodBallGroup:setLinearVelocity(0,64)

				function colorSaviorRodBall()
					while (saviorRodBallGroup) do 
						local r,g,b = math.random(),math.random(),math.random()
						saviorRodBall:setFillColor(r,g,b)
						break
					end
				end

				Runtime:addEventListener("enterFrame", colorSaviorRodBall)

				local function saviorRodBallCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("saviorRodBall is colliding with" .. event.other.myName)
						Runtime:removeEventListener("enterFrame", colorSaviorRodBall)
						display.remove(saviorRodBall)
						saviorRodCreationBool = true
					end
				end

				saviorRodBallGroup:addEventListener("collision", saviorRodBallCollision)
			elseif Austin == 5 then
				extraLifeSquareGroup = display.newGroup()
				sceneGroup:insert(extraLifeSquareGroup)
				table.insert(objectsTable, extraLifeSquareGroup)
				extraLifeSquareGroup.myName = "extraLifeSquare"
				extraLifeSquareGroup.x, extraLifeSquareGroup.y = math.random(screenW), 4
				extraLifeSquare = display.newRect(extraLifeSquareGroup, 0,0, 16,16)
				physics.addBody(extraLifeSquareGroup, "dynamic", {isSensor = true})
				extraLifeSquare:setFillColor(bColor)
				extraLifeSquareGroup:setLinearVelocity(0,64)

				local function extraLifeSquareGroupCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("extraLifeSquare is colliding with " .. event.other.myName)
						display.remove(extraLifeSquare)
						setHealth(true)
					end
				end

				extraLifeSquareGroup:addEventListener("collision", extraLifeSquareGroupCollision)

			elseif (Austin == 6 and rod.width ~= 128) then
				restoreRodBallGroup = display.newGroup()
				sceneGroup:insert(restoreRodBallGroup)
				table.insert(objectsTable, restoreRodBallGroup)
				restoreRodBallGroup.myName = "restoreRodBall"
				restoreRodBallGroup.x, restoreRodBallGroup.y = math.random(screenW), 4
				restoreRodBall = display.newRect(restoreRodBallGroup, 0,0, 28,8)
				physics.addBody(restoreRodBallGroup, "dynamic", {isSensor = true})
				restoreRodBallGroup.angularVelocity = rodVelocity
				restoreRodBall:setFillColor(bColor)
				restoreRodBallGroup:setLinearVelocity(0,64)

				local function restoreRodBallCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("restoreRodBall is colliding with " .. event.other.myName)
						display.remove(restoreRodBall)
						restoreRodBool = true
					end
				end

				restoreRodBallGroup:addEventListener("collision", restoreRodBallCollision)

			elseif (Austin == 7 and ball.width ~= 32) then
				print(ball.width)
				restoreBallBallGroup = display.newGroup()
				sceneGroup:insert(restoreBallBallGroup)
				table.insert(objectsTable, restoreBallBallGroup)
				restoreBallBallGroup.myName = "restoreBallBall"
				restoreBallBallGroup.x, restoreBallBallGroup.y = math.random(screenW), 4
				restoreBallBall = display.newCircle(restoreBallBallGroup, 0,0,8)
				physics.addBody(restoreBallBallGroup, "dynamic", {isSensor = true})
				restoreBallBall:setFillColor(aColor)
				restoreBallBallGroup:setLinearVelocity(0,64)

				local function restoreBallBallCollision(event)
					if (event.phase == "ended" and event.other.myName == "rod") then
						print("restoreBallBall is colliding with" .. event.other.myName)
						display.remove(restoreBallBall)
						restoreBallBool = true
					end
				end

				restoreBallBallGroup:addEventListener("collision", restoreBallBallCollision)

			end
		end

		counter = 0
		function gameTimer()
			score.text = points
			counter = counter + 1
			if (shrinkBallBool) then
				sizeBall(ballGroup, 8)
				shrinkBallBool = false
			elseif (enlargeBallBool) then
				sizeBall(ballGroup, 32)
				enlargeBallBool = false
			elseif (shrinkRodBool) then
				sizeRod(rodGroup, rodVelocity, 64)
				shrinkRodBool = false
			elseif (enlargeRodBool) then
				sizeRod(rodGroup, rodVelocity, 160)
				enlargeRodBool = false
			elseif (saviorRodCreationBool) then
				saviorRodCreationBool = false
				createSaviorRod(saviorRodOnScreen)
			elseif (restoreRodBool) then
				sizeRod(rodGroup, rodVelocity, 128)
				restoreRodBool = false
			elseif (restoreBallBool) then
				sizeBall(ballGroup, 16)
				restoreBallBool = false
			end
		end

		Runtime:addEventListener("enterFrame", gameTimer)

		function update() -- NEEDS WORK 
			local maxY = screenH

			for key, val in pairs(objectsTable) do 
				if objectsTable[key] ~= nil then
					local objectY = objectsTable[key].y
					if (objectY > maxY) then
						Runtime:removeEventListener("enterFrame", colorSaviorRodBall)
						objectsTable[key]:removeSelf()
						objectsTable[key] = nil
						Runtime:removeEventListener("enterFrame", update)
					end
				end
			end
		end


	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
	end
end


function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		-- physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	print("destroy")
	audio.stop(1)

	--cancel all timers
    local function cancelAllTimers()
        for k, v in pairs(timerGroup) do
            timer.cancel(v)
        end
    end
    cancelAllTimers()


	Runtime:removeEventListener("key", onKeyEvent)
	Runtime:removeEventListener("enterFrame", update)
	Runtime:removeEventListener("enterFrame", lose)
	Runtime:removeEventListener("enterFrame", gameTimer)
	Runtime:removeEventListener("enterFrame", levelUp)
	Runtime:removeEventListener("enterFrame", rodBounds)
	Runtime:removeEventListener("enterFrame", colorSaviorRodBall)
	Runtime:removeEventListener("enterFrame", moveSaviorRod)
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene