-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
local gameNetwork = require("gameNetwork")

-- include Corona's "widget" library
local widget = require "widget"

--------------------------------------------

-- forward declarations and other locals
local playBtn
math.randomseed(os.date("%j"))

local ads = require "plugin.inMobi"
local appID = "263e6b566523449f8a3f934233bedfe1"
if ( system.getInfo( "platformName" ) == "Android" ) then
    appID = "263e6b566523449f8a3f934233bedfe1"
end
 
local adProvider = "inMobi"
function adListener( event )
    if ( event.isError ) then
        -- Failed to receive an ad
    else
        ads.show( "1470891557110" )
    end

end
ads.init(adListener,{accountId=appID} )
ads.load( "interstitial", "1470891557110")

-- 'onRelease' event listener for playBtn
local function onPlayBtnRelease()
	
	-- go to level1.lua scene
	local options =
	{
	    effect = "fade",
	    time = 400,
	}
	composer.gotoScene( "level1", options)
	
	return true	-- indicates successful touch
end

local function instructionsLtn()
	
	native.showAlert( "Controls", "Touch the left or right side of the screen.")
	
	return true	-- indicates successful touch
end

function scene:create( event )
	local sceneGroup = self.view

	-- Called when the scene's view does not exist.
	-- 
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	-- display a background image
	local backgroundImg = {type="image", filename="background.png"}

	local background = display.newGroup()

	local graphics = display.newRect(0,0, display.contentWidth, display.contentHeight)
	graphics.anchorX = 0
	graphics.anchorY = 0
	graphics.fill = backgroundImg

	local backgroundColor = display.newRect(display.contentWidth/2, display.contentHeight/2, display.contentWidth, display.contentHeight)
	backgroundColor:setFillColor(math.random(), math.random(), math.random(), .5)

	background:insert(backgroundColor)
	background:insert(graphics)
	

	local playBtn = display.newRect(display.contentWidth/2, display.contentHeight - 140,220,32)
	playBtn:setFillColor(0,0,0,0.01)
	playBtn:addEventListener("touch", onPlayBtnRelease)

	local function showAchievements( event )
	   gameNetwork.show( "leaderboards" )
	   return true
	end

	local showLeaderBoard = display.newRect(display.contentWidth/2, display.contentHeight - 100,220,32)
	showLeaderBoard:setFillColor(0,0,0,0.01)
	showLeaderBoard:addEventListener("touch", showAchievements)

	local instructions = display.newRect(display.contentWidth/2, display.contentHeight - 60,220,32)
	instructions:setFillColor(0,0,0,0.01)
	instructions:addEventListener("touch", instructionsLtn)

	
	-- all display objects must be inserted into group
	sceneGroup:insert( background )
	sceneGroup:insert( playBtn )
	sceneGroup:insert(showLeaderBoard)
	sceneGroup:insert(instructions)
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
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
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
end

function scene:destroy( event )
	local sceneGroup = self.view
	
	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	
	if playBtn then
		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene