package;

import flixel.math.FlxRandom;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import flixel.util.FlxCollision;
import flixel.util.FlxGradient;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * This code is based on the excelent HaxeRunner
 * which is authored by william.thompsonj
 * 
 * I've made few modifications from the original source
 * Thank you very much, William Thompson J.
 */
class PlayState extends FlxState
{
	private static inline var TILE_WIDTH:Int = 16;
	private static inline var TILE_HEIGHT:Int = 16;
	private static var random = new FlxRandom();
	
	// base speed for player, stands for xVelocity
	private static inline var BASE_SPEED:Int = 200;
	
	// how fast the player speeds up going to the right
	private static inline var xAcceleration:Int = 120;
	
	// force that pulls sprite to the right
	private static inline var xDrag:Int = 100;
	
	// represents how strong gravity pulls up or down
	private static inline var yAcceleration:Int = 1400;
	
	// maximum speed the player can fall
	private static inline var yVelocity:Int = 1400;
	
	// how long holding jump makes player jump in seconds
	private static inline var jumpDuration:Float = .25;
	
	// player object and related jump variable
	private var _player:FlxSprite;
	private var _hold:FlxSprite;
	private var _jump:Float;
	private var _playJump:Bool;
	private var _jumpPressed:Bool;
	private var _sfxDie:Bool;
	private var _auxX:Float = 0.0;
	private var _livesTotal = 5;
	private var _live0:FlxSprite;
	private var _live1:FlxSprite;
	private var _live2:FlxSprite;
	private var _live3:FlxSprite;
	private var _live4:FlxSprite;
	private var _amountOranges:Int=0;
	
	// used to help with tracking camera movement
	private var _ghost:FlxSprite;
	
	// where to start generating platforms
	private var _edge:Int;
	
	// background image
	private var _bgImgGrp:FlxGroup;
	private var _bgImg0:FlxSprite;
	private var _bgImg3:FlxSprite;
	private var _floor:FlxSprite;

	// collision group for generated platforms
	private var _collisions:FlxGroup;
	private var _books:FlxGroup;
	private var _oranges:FlxGroup;
	private var _orangesHud:FlxTiledSprite;
	
	// track all platform objects on screen
	private var _tiles:Array<FlxSprite>;
	
	// indicate whether the collision group has changed
	private var _change:Bool;
	
	// score counter and timer
	private var _score:Int;
	private var _startDistance:Int;
	private var _record:Int;
	
	// button to reset and some text
	private var _resetButton:FlxButton;
	private var _scoreText:FlxText;
	private var _helperText:FlxText;
		
	override public function create():Void
	{
		// make sure world is wide enough, 100,000 tiles should be enough...
		FlxG.worldBounds.setSize(TILE_WIDTH * 100000, 300);
		
		// background music
		FlxG.sound.playMusic("assets/music/We're the Resistors.mp3");
		
		setupBg();
		
		setupPlayer();
		
		// prepare player related variables
		initPlayer();
		
		setupUI();
		
		// prepare UI variables
		initUI();
		
		// setup platform logic
		setupPlatforms();
		
		// prepare platform variables
		initPlatforms();
	}
	
	
	private function setupBg():Void
	{
		_bgImg0 = new FlxBackdrop("assets/images/sky.png", 0.1, 0, true, false, 0, 0);
		_bgImg3 = new FlxBackdrop("assets/images/foreground.png", 0.4, 0, true, false, 0, 0);
		_bgImgGrp = new FlxGroup();

		_bgImgGrp.add(_bgImg0);
		_bgImgGrp.add(_bgImg3);
		
		this.add(_bgImgGrp);
	}
	
	private function setupPlayer():Void
	{
		// make a player sprite
		_player = new FlxSprite().loadGraphic("assets/images/Jair.png", true, 104, 122);
		_player.scale.set(0.4, 1);

        _player.updateHitbox();
		_player.setGraphicSize(104, 122);

		_hold = new FlxSprite().loadGraphic("assets/images/touch_and_hold_smaller.png", true, 50, 30, true);
		
		_startDistance = Std.int(_player.x);
		_record = Std.int(_player.x);
		
		// set animations to use this run
		setAnimations();
		
		// face player to the right
		_player.facing = FlxObject.RIGHT;
		
		// add player to FlxState
		add(_player);
		add(_hold);
		
		// something that follows player's x movement
		_ghost = new FlxSprite(_player.x+FlxG.width-TILE_WIDTH, FlxG.height / 2);
		
		// camera can follow player's x movement, not y (jump bobbing)
		FlxG.camera.follow(_ghost);
	}
	
	private function setupUI():Void
	{
		_resetButton = new FlxButton(0, 0, "Reiniciar", onReset);
		add(_resetButton);
		
		// add score counter 
		_scoreText = new FlxText(0, 0, TILE_WIDTH * 3, "");
		_scoreText.borderStyle = OUTLINE;
		_scoreText.alignment = "right";
		_scoreText.color = 0xFF0000; // red color
		add(_scoreText);
		
		// helper text. Tells player what controls are
		_helperText = new FlxText(0, 0, TILE_WIDTH*5, "touch p/ pular");
		_helperText.borderStyle = OUTLINE;
		add(_helperText);

		// add lives indicator
		_live0 = new FlxSprite(0, 260, "assets/images/coracao.png");
		add(_live0);

		_live1 = new FlxSprite(15, 260, "assets/images/coracao.png");
		add(_live1);

		_live2 = new FlxSprite(30, 260, "assets/images/coracao.png");
		add(_live2);

		_live3 = new FlxSprite(45, 260, "assets/images/coracao.png");
		add(_live3);

		_live4 = new FlxSprite(60, 260, "assets/images/coracao.png");
		add(_live4);

		_orangesHud = new FlxTiledSprite(AssetPaths.laranja__png, 0, 33, true, false);
		add(_orangesHud);
		_orangesHud.width = 30;
		_orangesHud.visible = false;

		_bgImg3.y -= 94;
	}
	
	private function setupPlatforms():Void
	{
		// pool to hold platform objects
		_floor = new FlxBackdrop("assets/images/groundtiles.png", 1, 0, true, false, 0, 0);
		_floor.y = 280;
		_floor.allowCollisions = FlxObject.ANY;
		_floor.collisonXDrag = false;
		_floor.immovable = true;
		_floor.width = 1000000;
		add(_floor);

		// keep track of objects currently in use
		_tiles = new Array<FlxSprite>();
		
		// holds all collision objects
		_collisions = new FlxGroup();
		_collisions.add(_floor);
		
		// add the collisions group to the screen so we can see it!
		add(_collisions);
		
		_books = new FlxGroup();
		add(_books);

		_oranges = new FlxGroup();
		add(_oranges);
		
	}
	
	private inline function initPlayer():Void
	{
		// setup jump height
		_jump = -1;
		_playJump = true;
		_jumpPressed = false;
		_sfxDie = true;
		
		// setup player position
		_player.setPosition(_startDistance*TILE_WIDTH, 0);
		
		// Basic player physics
		_player.drag.x = xDrag;
		_player.velocity.set(0, 0);
		_player.maxVelocity.set(BASE_SPEED, yVelocity);
		_player.acceleration.set(xAcceleration, yAcceleration);
		
		// setup player animations
		setAnimations();
		
		// move camera to match player
		_ghost.x = _player.x - (TILE_WIDTH * .2) + (FlxG.width * .5);
	}
	
	private inline function initUI():Void
	{
		_resetButton.setPosition(170, 0);
		_scoreText.y = 20;
		_helperText.y = 50;

		_score = _startDistance;
		positionText();
	}
	
	private inline function initPlatforms():Void
	{
		// collision group is up to date
		_change = false;
		
		// reset edge screen where we generate new platforms
		_edge = (_startDistance-1)*TILE_WIDTH;
	}
	
	private function onReset():Void
	{
		_livesTotal--;
		if (_livesTotal >= 1) {	
			switch (_livesTotal) {
				case 1:
					_live1.visible = false;
					remove(_resetButton);
				case 2:
					remove(_live2);
				case 3:
					remove(_live3);
				case 4:
					remove(_live4);
			}

			// re-initialize player physics and position
			initPlayer();
			
			// re-initialize UI
			initUI();
			
			// reset platforms and draw starting area
			initPlatforms();
		}
	}
	
	/*************************
	 * 
	 * Updaters
	 * 
	 * This is where the process spends most of it's time executing. Try to do
	 * as much optimizing on these functions as possible so the game runs fast
	 * and smooth. If possible, design updater functions to be inlined.
	 * 
	 *************************/
	
	override public function update(elapsed:Float):Void
	{
		#if !(android || blackberry || iphone || ios || mobile)
		// player hit keyboard reset key?
		if (FlxG.keys.anyJustReleased(["R", "ENTER"])) {
			onReset();
			return;
		}
		#end
		
		// platform garbage handling
		updatePlatforms();
		
		updatePlayer();
		
		// collision group changed?
		if (_change) {
			// update collision group so it doesn't freak out
			_collisions.update(FlxG.elapsed);
			_oranges.update(FlxG.elapsed);
			_books.update(FlxG.elapsed);
			
			// collision group is up to date
			_change = false;
		}

		if (FlxG.collide(_player, _oranges, (_obj1, _obj2) -> _obj2.destroy() )){
			_playJump = false;
			if(_amountOranges < 5) {
				_amountOranges += 1;
				if(_orangesHud.visible == false) _orangesHud.visible = true; 
				else _orangesHud.width += 30;

				if(_amountOranges == 1){
					_orangesHud.visible = true;
				}
			}
		}

		if(FlxG.collide(_player, _collisions)){
			_playJump = false;
			// player hit the floor?
			if (_player.velocity.x > 0 && !_jumpPressed) {
				// reset jump variable
				_jump = 0;
			}
		}
		
		// collision with books?
		if (FlxG.collide(_player, _books, (_obj1, _obj2) -> if (_amountOranges >= 1) _obj2.destroy() )) {
			_playJump = false;
			_jump = 0;

			if(_amountOranges >= 1) _amountOranges = _amountOranges - 1;
			
			if (_orangesHud.width == 30 && _amountOranges <= 1) {
				_orangesHud.visible = false;
			}

			if (_orangesHud.width >= 60) _orangesHud.width -= 30;
			
			if (_player.velocity.x <= 0) {
				if(_amountOranges <= 0) {
					// player went splat
					_jump = -1;
					_playJump = false;
					sfxDie();
				}
			}
		}
		
		playerAnimation();
		super.update(FlxG.elapsed);
		
		updateUI();
	}
	
	private inline function updateUI():Void
	{
		_score = Std.int(_player.x / (TILE_WIDTH));
		
		if (_score*.5 > _startDistance) {
			_startDistance = Std.int(_score * .5);
		}
		
		if (_player.x > (_record * TILE_WIDTH)) {
			_record = _score;
		}
		
		_scoreText.text = Std.string(_score + "m\n\nInício: " + _startDistance + "m\n\nRecorde: " + _record + "m");
		
		positionText();
		
		// camera tracks ghost, not player (prevent tracking jumps)
		_ghost.x = _player.x - (TILE_WIDTH * .2) + (FlxG.width * .5);
	}
	
	private inline function updatePlayer():Void
	{
		// make player go faster as they go farther in j curve
		_player.maxVelocity.x = BASE_SPEED + Std.int(_player.x*.03);
		
		_jumpPressed = FlxG.keys.anyPressed(["UP", "W", "SPACE"]);

		for (touch in FlxG.touches.list) {
        	if(touch.justReleased) {
				_jumpPressed = false;
			} else if (touch.justPressed || touch.pressed) {
				_jumpPressed = true;
            }
        }
		
		if (_jump != -1 && _jumpPressed)
		{
			// play jump sound just once
			if (_jump == 0) {
				sfxJump();
			}
			
			// Duration of jump
			_jump += FlxG.elapsed;
			
			if (_player.velocity.y >= 0) {
				// play jump animation
				_playJump = true;
				
				// get player off the platform
				_player.y -= 1;
				
				// set minimum velocity
				_player.velocity.y = -yAcceleration * .5;
				
				//The general acceleration of the jump
				_player.acceleration.y = -yAcceleration;
			}
			
			if (_jump > jumpDuration) {
				// set minimum velocity
				_player.velocity.y = -yAcceleration * .5;
				
				//You can't jump for more than 0.25 seconds
				_jump = -1;
				
				// make sure fall animation plays
				_playJump = true;
			}
		}
		else if (!_jumpPressed || _jump == -1) {
			if (_player.velocity.y < 0) {
				// set acceleration to pull to ground
				_player.acceleration.y = yAcceleration;
				
				// set minimum velocity
				_player.velocity.y = yAcceleration * .25;
				
				// stop jumping more than once, allows air jumps
				_jump = -1;
			}
		}
	}
	
	private inline function updatePlatforms():Void
	{		
		// check if we need to make more platforms
		while (( _player.x + FlxG.width) * 1.3 > _edge )
		{
			makePlatform();
		}
	}
	
	private function setObjAndAdd2Group(Path:FlxGraphicAsset, width:Int, height:Int, group:FlxGroup, isSolid:Bool=true, isMovable:Bool=true, positionCollide:Int=FlxObject.ANY):Void 
	{
		var obj = new AssetLoader(Path, width, height);
			obj.x = (_player.x + _edge) * random.int(0, 20) + random.int(300, 3000);
			obj.y = random.int(140, 250);
			obj.allowCollisions = positionCollide;
			obj.solid = isSolid;
			obj.immovable = isMovable;
			add(obj);
			group.add(obj);
	}
	
	private function makePlatform(wide:Int=0, high:Int=0):Void
	{		
		_edge += TILE_WIDTH*2;

		if (random.int(0, 2) / 2 == 0) {
			setObjAndAdd2Group(AssetPaths.livros__png, 46, 55, _books, true, true, FlxObject.RIGHT);
		}

		if (random.int(0, 4) / 4 == 0) {
			setObjAndAdd2Group(AssetPaths.laranja__png, 30, 32, _oranges, true, false);
		}

		_change = true;
	}
	
	private inline function playerAnimation():Void
	{
		if (_player.velocity.x == 0) {
			_player.animation.play("die");
		} else if (_playJump) {
			_player.animation.play("jump");
		} else if (_player.velocity.y != 0) {
			_player.animation.play("fall");
		} else {
			_player.animation.play("run");
		}
	}
	
	private inline function setAnimations():Void
	{	
		_player.animation.add("run", [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13], 30, true);
		_player.animation.add("jump",  [15, 14], 7, false);
		_player.animation.add("fall", [16, 17], 7, false);
		_player.animation.add("die", [22, 23], 15, false);

		_hold.animation.add("idle", [0, 1, 2, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11, 15], 30, true);
		_hold.animation.play("idle");
	}
	
	private inline function positionText():Void
	{
		_helperText.x = _player.x + TILE_WIDTH * 2 + 140;
		_helperText.y = 20;
		_scoreText.x = _player.x + FlxG.width - (4 * TILE_WIDTH);
		
		_hold.x = _player.x + TILE_WIDTH * 2 + 150;
		_hold.y = 30;
		
		_live0.x = _player.x - 20 + TILE_WIDTH * 2;
		_live1.x = _player.x + 5 + TILE_WIDTH * 2;
		_live2.x = _player.x + 30 + TILE_WIDTH * 2;
		_live3.x = _player.x + 55 + TILE_WIDTH * 2;
		_live4.x = _player.x + 80 + TILE_WIDTH * 2;
		
		_live0.y = 0;
		_live1.y = 0;
		_live2.y = 0;
		_live3.y = 0;
		_live4.y = 0;

		_orangesHud.x = _player.x - 20 + TILE_WIDTH * 2;
		_orangesHud.y = 30;
	}
	
	private inline function sfxDie():Void
	{
		if (_sfxDie) {
			FlxG.sound.play("assets/sounds/goblin-9.ogg");
			_sfxDie = false;
		}
	}
	
	private inline function sfxJump():Void
	{
		FlxG.sound.play("assets/sounds/goblin-1.ogg");
	}
}