package;

import scripting.HScript;
import stages.data.PhillyStreets;

#if sys
import sys.FileSystem;
#end

import config.*;
import debug.*;
import title.*;
import transition.data.*;
import stages.*;
import stages.elements.*;
import cutscenes.*;
import cutscenes.data.*;
import events.*;
import note.*;

import flixel.FlxBasic;
import flixel.math.FlxAngle;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
import results.ResultsState;
import freeplay.FreeplayState;
import Highscore.SongStats;
import flixel.FlxState;
import openfl.utils.Assets;
import flixel.math.FlxRect;
import openfl.system.System;
import Section.SwagSection;
import Song.SwagSong;
import Song.SongEvents;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import extensions.flixel.FlxTextExt;

using StringTools;

class PlayState extends MusicBeatState
{

	public static var instance:PlayState = null;

	public static var curStage:String = '';
	public static var curUiType:String = '';
	public static var SONG:SwagSong;
	public static var EVENTS:SongEvents;
	public static var loadEvents:Bool = true;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var fromChartEditor:Bool = false;
	public static var fceForLilBuddies:Bool = false;
	
	public static var returnLocation:String = "main";

	public var scripts:Array<HScript> = new Array();
	
	private var canHit:Bool = false;
	private var missTime:Float = 0;

	private var invuln:Bool = false;
	private var invulnTime:Float = 0;

	private var releaseTimes:Array<Float> = [-1, -1, -1, -1];
	private final releaseBufferTime = (2/60);

	public var forceMissNextNote:Bool = false;

	public var camFocus:String = "";
	private var camTween:FlxTween;
	private var camZoomTween:FlxTween;
	private var camZoomAdjustTween:FlxTween;
	private var uiZoomTween:FlxTween;

	public var camFollow:FlxPoint;
	public var camFollowFinal:FlxObject;

	public var camFollowOffset:FlxPoint;
	private var offsetTween:FlxTween;

	public var camFollowShake:FlxPoint;
	private var shakeTween:FlxTween;
	private var shakeReturnTween:FlxTween;
	
	public var camOffsetAmount:Float = 20;

	public var autoCam:Bool = true;
	public var autoZoom:Bool = true;
	public var autoUi:Bool = true;
	public var autoCamBop:Bool = true;

	public var gfBopFrequency:Int = 1;
	public var iconBopFrequency:Int = 1;
	public var camBopFrequency:Int = 4;

	public var tweenManager:FlxTweenManager = new FlxTweenManager();

	private var vocals:FlxSound;
	private var vocalsOther:FlxSound;
	private var vocalType:VocalType = combinedVocalTrack;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	var gfCheck:String;

	public var backgroundLayer:FlxGroup = new FlxGroup();
	public var gfLayer:FlxGroup = new FlxGroup();
	public var middleLayer:FlxGroup = new FlxGroup();
	public var characterLayer:FlxGroup = new FlxGroup();
	public var foregroundLayer:FlxGroup = new FlxGroup();

	//Wacky input stuff=========================

	//private var skipListener:Bool = false;

	private var upTime:Int = 0;
	private var downTime:Int = 0;
	private var leftTime:Int = 0;
	private var rightTime:Int = 0;

	private var upPress:Bool = false;
	private var downPress:Bool = false;
	private var leftPress:Bool = false;
	private var rightPress:Bool = false;
	
	private var upRelease:Bool = false;
	private var downRelease:Bool = false;
	private var leftRelease:Bool = false;
	private var rightRelease:Bool = false;

	private var upHold:Bool = false;
	private var downHold:Bool = false;
	private var leftHold:Bool = false;
	private var rightHold:Bool = false;

	//End of wacky input stuff===================

	private var autoplay:Bool = false;
	public var preventScoreSaving:Bool = false;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private static var prevCamFollow:FlxObject;

	public var playerStrums:FlxTypedGroup<FlxSprite>;
	public var enemyStrums:FlxTypedGroup<FlxSprite>;

	private var playerCovers:FlxTypedGroup<NoteHoldCover>;
	private var enemyCovers:FlxTypedGroup<NoteHoldCover>;

	private var curSong:String = "";

	public var health:Float = 1;
	public var healthLerp:Float = 1;

	public var combo:Int = 0;
	public var totalPlayed:Int = 0;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar;

	public var generatedMusic:Bool = false;
	public var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOverlay:FlxCamera;
	private var camGameZoomAdjust:Float = 0;

	private var eventList:Array<Dynamic> = [];

	private var comboUI:ComboPopup;
	public static final minCombo:Int = 10;

	public var stage:BaseStage;

	public var scoreTxt:FlxTextExt;

	public var ccText:SongCaptions;

	public var songStats:ScoreStats = {
		score: 0,
		highestCombo: 0,
		accuracy: 0.0,
		sickCount: 0,
		goodCount: 0,
		badCount: 0,
		shitCount: 0,
		susCount: 0,
		missCount: 0,
		comboBreakCount: 0,
	};

	public static var weekStats:ScoreStats = {
		score: 0,
		highestCombo: 0,
		accuracy: 0.0,
		sickCount: 0,
		goodCount: 0,
		badCount: 0,
		shitCount: 0,
		susCount: 0,
		missCount: 0,
		comboBreakCount: 0,
	};

	public var defaultCamZoom:Float = 1.05;

	public var inCutscene:Bool = false;
	public var inVideoCutscene:Bool = false;
	public var inEndingCutscene:Bool = false;

	var songEnded:Bool = false;

	var startCutscene:Dynamic = null;
	var startCutsceneStoryOnly:Bool = false;
	var startCutscenePlayOnce:Bool = false;
	var endCutscene:Dynamic = null;
	var endCutsceneStoryOnly:Bool = false;
	var endCutscenePlayOnce:Bool = false;

	public static var replayStartCutscene:Bool = true;
	public static var replayEndCutscene:Bool = true;

	public var dadBeats:Array<Int> = [0, 2];
	public var bfBeats:Array<Int> = [1, 3];

	public static var sectionStart:Bool =  false;
	public static var sectionStartPoint:Int =  0;
	public static var sectionStartTime:Float =  0;

	var endingSong:Bool = false;

	var forceCenteredNotes:Bool = false;

	private var meta:SongMetaTags;

	public var metadata:Dynamic = null;

	public var arbitraryData:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	override public function create(){

		instance = this;
		FlxG.mouse.visible = false;
		add(tweenManager);

		customTransIn = new ScreenWipeIn(1.2);
		customTransOut = new ScreenWipeOut(0.6);

		if(loadEvents){
			if(Utils.exists("assets/data/" + SONG.song.toLowerCase() + "/events.json")){
				trace("loaded events");
				trace(Paths.json(SONG.song.toLowerCase() + "/events"));
				EVENTS = Song.parseEventJSON(Utils.getText(Paths.json(SONG.song.toLowerCase() + "/events")));
			}
			else{
				trace("No events found");
				EVENTS = {
					events: []
				};
			}
		}

		if(Utils.exists(Paths.json(SONG.song.toLowerCase() + "/meta"))){
			metadata = Json.parse(Utils.getText(Paths.json(SONG.song.toLowerCase() + "/meta")));
		}

		for(i in EVENTS.events){
			eventList.push([i[1], i[3]]);
		}

		eventList.sort(sortByEventStuff);

		inCutscene = false;

		songPreload();

		for(i in 1...4){
			FlxG.sound.cache(Paths.sound("missnote" + i));
		}
		
		Config.setFramerate(999);

		camTween = tweenManager.tween(this, {}, 0);
		camZoomTween = tweenManager.tween(this, {}, 0);
		uiZoomTween = tweenManager.tween(this, {}, 0);
		offsetTween = tweenManager.tween(this, {}, 0);
		shakeTween = tweenManager.tween(this, {}, 0);
		shakeReturnTween = tweenManager.tween(this, {}, 0);
		camZoomAdjustTween = tweenManager.tween(this, {}, 0);
		
		canHit = !(Config.ghostTapType > 0);

		camGame = new FlxCamera();

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		camOverlay = new FlxCamera();
		camOverlay.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOverlay, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = false;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.changeBPM(SONG.bpm);
		Conductor.mapBPMChanges(SONG);

		gfCheck = "Gf";

		if (SONG.gf != null) {
			gfCheck = SONG.gf;
		}

		gf = new Character(400, 130, gfCheck, false, true);
		gf.scrollFactor.set(0.95, 0.95);

		var dadChar = SONG.player2;

		dad = new Character(100, 100, dadChar);

		var bfChar = SONG.player1;

		boyfriend = new Character(770, 450, bfChar, true);

		var stageCheck:String = 'Stage';
		if (SONG.stage != null) {
			stageCheck = SONG.stage;
		}

		var stageClass = Type.resolveClass("stages.data." + stageCheck);
		if(stageClass == null){
			stageClass = BaseStage;
		}

		stage = Type.createInstance(stageClass, []);

		curStage = stage.name;
		curUiType = stage.uiType;

		//Set the start point of the characters.
		if((stage.useStartPoints && !stage.overrideBfStartPoints) || (!stage.useStartPoints && stage.overrideBfStartPoints)){
			boyfriend.setPosition(stage.bfStart.x - ((boyfriend.getFrameWidth() * boyfriend.getScale().x)/2), stage.bfStart.y - (boyfriend.getFrameHeight() * boyfriend.getScale().y));
			//trace("doing boyfriend start point");
		}
		if((stage.useStartPoints && !stage.overrideDadStartPoints) || (!stage.useStartPoints && stage.overrideDadStartPoints)){
			dad.setPosition(stage.dadStart.x - ((dad.getFrameWidth() * dad.getScale().x)/2), stage.dadStart.y - (dad.getFrameHeight() * dad.getScale().y));
			//trace("doing dad start point");
		}
		if((stage.useStartPoints && !stage.overrideGfStartPoints) || (!stage.useStartPoints && stage.overrideGfStartPoints)){
			gf.setPosition(stage.gfStart.x - ((gf.getFrameWidth() * gf.getScale().x)/2), stage.gfStart.y - (gf.getFrameHeight() * gf.getScale().y));
			//trace("doing gf start point");
		}
		
		dad.x += dad.reposition.x;
		dad.y += dad.reposition.y;
		boyfriend.x += boyfriend.reposition.x;
		boyfriend.y += boyfriend.reposition.y;
		gf.x += gf.reposition.x;
		gf.y += gf.reposition.y;

		if(metadata != null){
			if(metadata.bfBeats != null){
				bfBeats = metadata.bfBeats;
			}
			if(metadata.dadBeats != null){
				dadBeats = metadata.dadBeats;
			}
		}


		/*
			Moving the onAdd to PlayState since the old way I did it relied on update being called at least once which meant
			it wasn't really an "on add" it was more of a "first update" and it was causing a few issues (namely the camera
			position at the begining of Tutorial wasn't correct becuase the move happened after the camera position was set)
		*/

		characterLayer.memberAdded.add(function(obj:FlxBasic) {
			var char = cast(obj, Character);
			if(!char.debugMode && char.characterInfo.info.functions.add != null){
				char.characterInfo.info.functions.add(char);
			}
		});

		gfLayer.memberAdded.add(function(obj:FlxBasic) {
			var char = cast(obj, Character);
			if(!char.debugMode && char.characterInfo.info.functions.add != null){
				char.characterInfo.info.functions.add(char);
			}
		});
		
		if(stage.extraCameraMovementAmount != null){
			camOffsetAmount = stage.extraCameraMovementAmount;
		}

		for(i in 0...stage.backgroundElements.length){
			backgroundLayer.add(stage.backgroundElements[i]);
		}

		gfLayer.add(gf);

		for(i in 0...stage.middleElements.length){
			middleLayer.add(stage.middleElements[i]);
		}
		
		characterLayer.add(dad);
		characterLayer.add(boyfriend);

		for(i in 0...stage.foregroundElements.length){
			foregroundLayer.add(stage.foregroundElements[i]);
		}

		add(backgroundLayer);
		add(gfLayer);
		add(middleLayer);
		add(characterLayer);
		add(foregroundLayer);

		characterLayer.memberAdded.removeAll();
		gfLayer.memberAdded.removeAll();

		var camPos:FlxPoint = new FlxPoint(FlxMath.lerp(getOpponentFocusPosition().x, getBfFocusPostion().x, 0.5), FlxMath.lerp(getOpponentFocusPosition().y, getBfFocusPostion().y, 0.5));

		autoCam = stage.cameraMovementEnabled;

		if(stage.cameraStartPosition != null){
			camPos.set(stage.cameraStartPosition.x, stage.cameraStartPosition.y);
		}

		/*//Start pos debug shit. I'll leave it in for now incase everything breaks.
		var dadPos = new FlxSprite(Utils.getGraphicMidpoint(dad).x, dad.y + (dad.frameHeight * dad.scale.y)).makeGraphic(24, 24, 0xFFFF00FF);
		var bfPos = new FlxSprite(Utils.getGraphicMidpoint(boyfriend).x, boyfriend.y + (boyfriend.frameHeight * boyfriend.scale.y)).makeGraphic(24, 24, 0xFF00FFFF);
		var gfPos = new FlxSprite(Utils.getGraphicMidpoint(gf).x, gf.y + (gf.frameHeight * gf.scale.y)).makeGraphic(24, 24, 0xFFFF0000);

		add(dadPos);
		add(bfPos);
		add(gfPos);

		trace("dad: " + dadPos.x + ", " + dadPos.y);
		trace("bf: " + bfPos.x + ", " + bfPos.y);
		trace("gf: " + gfPos.x + ", " + gfPos.y);*/

		for(type => data in stage.extraData){
			switch(type){
				case "forceCenteredNotes":
					forceCenteredNotes = data;
				default:
					//Do nothing by default.
			}
		}

		switch(curUiType){

			default:
				comboUI = new ComboPopup(boyfriend.x + boyfriend.worldPopupOffset.x, boyfriend.y + boyfriend.worldPopupOffset.y,
				{
					path: "ui/ratings",
					position: new FlxPoint(0, -50),
					aa: true,
					scale: 0.7
				}, 
				{
					path: "ui/numbers",
					position: new FlxPoint(-175, 5),
					aa: true,
					scale: 0.6
				}, 
				{
					path: "ui/comboBreak",
					position: new FlxPoint(0, -50),
					aa: true,
					scale: 0.6
				});
				NoteSplash.splashPath = "ui/noteSplashes";

			case "pixel":
				comboUI = new ComboPopup(boyfriend.x + boyfriend.worldPopupOffset.x, boyfriend.y + boyfriend.worldPopupOffset.y,
				{
					path: "week6/weeb/pixelUI/ratings",
					position: new FlxPoint(0, -50),
					aa: false,
					scale: 6 * 0.7
				}, 
				{
					path: "week6/weeb/pixelUI/numbers",
					position: new FlxPoint(-175, 5),
					aa: false,
					scale: 6 * 0.8
				}, 
				{
					path: "week6/weeb/pixelUI/comboBreak-pixel",
					position: new FlxPoint(0, -50),
					aa: false,
					scale: 6 * 0.7
				});
				NoteSplash.splashPath = "week6/weeb/pixelUI/noteSplashes-pixel";

		}

		//Prevents the game from lagging at first note splash.
		var preloadSplash = new NoteSplash(-2000, -2000, 0);

		if(Config.comboType == 1){

			comboUI.cameras = [camHUD];
			comboUI.setPosition(0, 0);
			comboUI.scrollFactor.set(0, 0);
			comboUI.accelScale = 0.3;
			comboUI.velocityScale = 0.3;
			comboUI.limitSprites = true;

			if(!Config.downscroll){
				comboUI.ratingInfo.position.set(844, 580);
				comboUI.numberInfo.position.set(340, 505);
				comboUI.comboBreakInfo.position.set(844, 580);
			}
			else{
				comboUI.ratingInfo.position.set(844, 150);
				comboUI.numberInfo.position.set(340, 125);
				comboUI.comboBreakInfo.position.set(844, 150);
			}

			switch(curUiType){
				case "pixel":
					comboUI.ratingInfo.scale *= 0.9;
					comboUI.comboBreakInfo.scale *= 0.9;
					
				default:
					comboUI.ratingInfo.scale *= 0.8;
					comboUI.comboBreakInfo.scale *= 0.8;
			}

		}

		if(Config.comboType < 2){
			add(comboUI);
		}

		Conductor.songPosition = -5000;

		if(Config.downscroll){
			strumLine = new FlxSprite(0, 570).makeGraphic(FlxG.width, 10);
		}
		else {
			strumLine = new FlxSprite(0, 30).makeGraphic(FlxG.width, 10);
		}
		strumLine.scrollFactor.set();

		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();
		add(playerStrums);
		add(enemyStrums);

		playerCovers = new FlxTypedGroup<NoteHoldCover>();
		enemyCovers = new FlxTypedGroup<NoteHoldCover>();

		generateSong(SONG.song);

		add(playerCovers);
		add(enemyCovers);

		camFollow = new FlxPoint();
		camFollowOffset = new FlxPoint();
		camFollowShake = new FlxPoint();
		camFollowFinal = new FlxObject(0, 0, 1, 1);

		camFollow.set(camPos.x, camPos.y);
		camFollowFinal.setPosition(camPos.x, camPos.y);

		add(camFollowFinal);

		FlxG.camera.follow(camFollowFinal, LOCKON);

		defaultCamZoom = stage.startingZoom;
		
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = defaultCamZoom;

		FlxG.camera.focusOn(camFollowFinal.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		if(Utils.exists(Paths.text(SONG.song.toLowerCase() + "/meta"))){
			meta = new SongMetaTags(0, 144, SONG.song.toLowerCase());
			meta.cameras = [camHUD];
			add(meta);
		}

		healthBarBG = new FlxSprite(0, Config.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.875).loadGraphic(Paths.image("ui/healthBar"));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.antialiasing = true;
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this, 'healthLerp', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(dad.characterColor, boyfriend.characterColor);
		healthBar.antialiasing = true;
		// healthBar
		
		scoreTxt = new FlxTextExt(healthBarBG.x - 105, (FlxG.height * 0.9) + 36, 800, "", 22);
		scoreTxt.setFormat(Paths.font("vcr"), 22, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();

		iconP1 = new HealthIcon(boyfriend.iconName, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		

		iconP2 = new HealthIcon(dad.iconName, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		ccText = new SongCaptions(Config.downscroll);
		ccText.scrollFactor.set();
		
		add(healthBar);
		add(iconP2);
		add(iconP1);
		add(scoreTxt);
		if(Config.showCaptions){ add(ccText); } 

		playerStrums.cameras = [camHUD];
		enemyStrums.cameras = [camHUD];
		playerCovers.cameras = [camHUD];
		enemyCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		ccText.cameras = [camHUD];

		healthBar.visible = false;
		healthBarBG.visible = false;
		iconP1.visible = false;
		iconP2.visible = false;
		scoreTxt.visible = false;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		//Get and run cutscene stuff
		if(Utils.exists("assets/data/" + SONG.song.toLowerCase() + "/cutscene.json")){
			trace("song has cutscene info");
			var cutsceneJson = Json.parse(Utils.getText("assets/data/" + SONG.song.toLowerCase() + "/cutscene.json"));
			//trace(cutsceneJson);
			if(Type.typeof(cutsceneJson.startCutscene) == TObject){
				if(cutsceneJson.startCutscene.storyOnly != null) {startCutsceneStoryOnly = cutsceneJson.startCutscene.storyOnly;}
				if((!startCutsceneStoryOnly || (startCutsceneStoryOnly && isStoryMode)) ){
					var startCutsceneClass = Type.resolveClass("cutscenes.data." + cutsceneJson.startCutscene.name);
					var startCutsceneArgs = [];
					if(cutsceneJson.startCutscene.args != null) {startCutsceneArgs = cutsceneJson.startCutscene.args;}
					if(cutsceneJson.startCutscene.playOnce != null) {startCutscenePlayOnce = cutsceneJson.startCutscene.playOnce;}
					startCutscene = Type.createInstance(startCutsceneClass, startCutsceneArgs);
				}
			}
			//trace(startCutscene);
			//trace(startCutsceneStoryOnly);

			if(Type.typeof(cutsceneJson.endCutscene) == TObject){
				if(cutsceneJson.endCutscene.storyOnly != null) {endCutsceneStoryOnly = cutsceneJson.endCutscene.storyOnly;}
				if((!endCutsceneStoryOnly || (endCutsceneStoryOnly && isStoryMode)) ){
					var endCutsceneClass = Type.resolveClass("cutscenes.data." + cutsceneJson.endCutscene.name);
					var endCutsceneArgs = [];
					if(cutsceneJson.endCutscene.args != null) {endCutsceneArgs = cutsceneJson.endCutscene.args;}
					if(cutsceneJson.endCutscene.playOnce != null) {endCutscenePlayOnce = cutsceneJson.endCutscene.playOnce;}
					endCutscene = Type.createInstance(endCutsceneClass, endCutsceneArgs);
				}
			}
			//trace(endCutscene);
			//trace(endCutsceneStoryOnly);
		}

		var bgDim = new FlxSprite(1280 / -2, 720 / -2).makeGraphic(1, 1, FlxColor.BLACK);
		bgDim.scale.set(1280*2, 720*2);
		bgDim.updateHitbox();
		bgDim.cameras = [camOverlay];
		bgDim.alpha = Config.bgDim/10;
		add(bgDim);

		cutsceneCheck();

		if(fromChartEditor && !fceForLilBuddies){
			preventScoreSaving = true;
		}
		fromChartEditor = false;
		fceForLilBuddies = false;

		//Global script
		for(file in sys.FileSystem.readDirectory('assets/data/${SONG.song.toLowerCase()}/')) {
			trace(file);
			if(file.endsWith('.hx')) {
				var script:HScript = HScript.buildScript(Paths.file(haxe.io.Path.withoutExtension(file), 'data/${SONG.song.toLowerCase()}', 'hx'), this);
				scripts.push(script);
			}
		}

		set('SONG', SONG);
		loadScripts();
		call('onCreate');

		super.create();

		call('onPostCreate');
	}

	function cutsceneCheck():Void{
		//trace("in cutsceneCheck");
		if(startCutscene != null && (startCutscenePlayOnce ? replayStartCutscene : true)){
			add(startCutscene);
			inCutscene = true;
			startCutscene.start();
		}
		else{
			startCountdown();
		}
		replayStartCutscene = true;
	}

	function updateAccuracy(){
		var total:Float = (songStats.sickCount) + (songStats.goodCount) + (songStats.badCount) + (songStats.shitCount) + (songStats.missCount);
		songStats.accuracy = total == 0 ? 0 : (((songStats.sickCount + songStats.goodCount) / total) * 100);
		songStats.accuracy = Utils.clamp(songStats.accuracy, 0, 100);
	}

	var startTimer:FlxTimer;

	public function startCountdown():Void {
		inCutscene = false;

		healthBar.visible = true;
		healthBarBG.visible = true;
		iconP1.visible = true;
		iconP2.visible = true;
		scoreTxt.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ui/ready', "ui/set", "ui/go", "", ""]);
			introAssets.set('pixel', [
				"week6/weeb/pixelUI/ready-pixel",
				"week6/weeb/pixelUI/set-pixel",
				"week6/weeb/pixelUI/date-pixel",
				"-pixel",
				"week6/"
			]);

		var introAlts:Array<String> = introAssets.get(curUiType);
		var altSuffix = introAlts[3];
		var altPrefix = introAlts[4];

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{

			if(swagCounter != 4) { gf.dance(); }

			if(dadBeats.contains((swagCounter % 4)))
				if(swagCounter != 4) { dad.dance(); }

			if(bfBeats.contains((swagCounter % 4)))
				if(swagCounter != 4) { boyfriend.dance(); }

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound(altPrefix + 'intro3' + altSuffix), 0.6);
					if(meta != null){
						meta.start();
					}
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.antialiasing = !(curUiType == "pixel");

					if (curUiType == "pixel")
						ready.setGraphicSize(Std.int(ready.width * 6 * 0.8));
					else
						ready.setGraphicSize(Std.int(ready.width * 0.5));

					ready.updateHitbox();

					ready.screenCenter();
					ready.y -= 120;
					ready.cameras = [camHUD];
					add(ready);
					tweenManager.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound(altPrefix + 'intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();
					set.antialiasing = !(curUiType == "pixel");

					if (curUiType == "pixel")
						set.setGraphicSize(Std.int(set.width * 6 * 0.8));
					else
						set.setGraphicSize(Std.int(set.width * 0.5));

					set.updateHitbox();

					set.screenCenter();
					set.y -= 120;
					set.cameras = [camHUD];
					add(set);
					tweenManager.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound(altPrefix + 'intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();
					go.antialiasing = !(curUiType == "pixel");

					if (curUiType == "pixel")
						go.setGraphicSize(Std.int(go.width * 6 * 0.8));
					else
						go.setGraphicSize(Std.int(go.width * 0.8));

					go.updateHitbox();

					go.screenCenter();
					go.y -= 120;
					go.cameras = [camHUD];
					add(go);
					tweenManager.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound(altPrefix + 'introGo' + altSuffix), 0.6);
				case 4:
					beatHit();
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	public function instantStart():Void {
		inCutscene = false;

		healthBar.visible = true;
		healthBarBG.visible = true;
		iconP1.visible = true;
		iconP2.visible = true;
		scoreTxt.visible = true;

		generateStaticArrows(0, true);
		generateStaticArrows(1, true);

		startedCountdown = true;
		Conductor.songPosition = 0;

		beatHit();
	}

	function startSong():Void{
		startingSong = false;

		if (!paused)
			FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);

		FlxG.sound.music.onComplete = endSongCutsceneCheck;
		vocals.play();
		if(vocalType == splitVocalTrack){ vocalsOther.play(); }

		if(sectionStart){
			FlxG.sound.music.time = sectionStartTime;
			Conductor.songPosition = sectionStartTime;
			vocals.time = sectionStartTime;
			if(vocalType == splitVocalTrack){ vocalsOther.time = sectionStartTime; }
			curSection = sectionStartPoint;
		}

		stage.songStart();
	}

	private function generateSong(dataPath:String):Void {

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		switch(vocalType){
			case splitVocalTrack:
				vocals = new FlxSound().loadEmbedded(Paths.voices(curSong, "Player"));
				vocalsOther = new FlxSound().loadEmbedded(Paths.voices(curSong, "Opponent"));
				FlxG.sound.list.add(vocalsOther);
			case combinedVocalTrack:
				vocals = new FlxSound().loadEmbedded(Paths.voices(curSong));
			case noVocalTrack:
				vocals = new FlxSound();
		}

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			if(sectionStart && daBeats < sectionStartPoint){
				daBeats++;
				continue;
			}

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = songNotes[3];

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3){
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0){
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				}
				else{
					oldNote = null;
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, daNoteType, false, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;

				swagNote.mustPress = gottaHitNote;

				setNoteHitCallback(swagNote);
				
				unspawnNotes.push(swagNote);

				if(Math.round(susLength) > 0){
					for (susNote in 0...(Math.round(susLength) + 1)){
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
	
						var makeFake = false;
						var timeAdd = 0.0;
						if(susNote == 0){ 
							makeFake = true; 
							timeAdd = 0.1; 
						}
	
						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + timeAdd, daNoteData, daNoteType, false, oldNote, true);
						sustainNote.isFake = makeFake;
						sustainNote.scrollFactor.set();
						sustainNote.mustPress = gottaHitNote;

						setNoteHitCallback(sustainNote);

						unspawnNotes.push(sustainNote);
					}
				}

			}
			daBeats++;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByEventStuff(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	private function generateStaticArrows(player:Int, ?instant:Bool = false):Void {

		for (i in 0...4)
		{
			var babyArrow:FlxSprite = new FlxSprite(50, strumLine.y);

			switch (curUiType) {
				case "pixel":
					NoteHoldCover.coverPath = "week6/weeb/pixelUI/noteHoldCovers-pixel";

					babyArrow.loadGraphic(Paths.image('week6/weeb/pixelUI/arrows-pixels'), true, 19, 19);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * 6));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [26, 10], 12, false);
							babyArrow.animation.add('confirm', [30, 14, 18], 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [27, 11], 12, false);
							babyArrow.animation.add('confirm', [31, 15, 19], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [25, 9], 12, false);
							babyArrow.animation.add('confirm', [29, 13, 17], 24, false);
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [24, 8], 12, false);
							babyArrow.animation.add('confirm', [28, 12, 16], 24, false);
					}

				default:
					NoteHoldCover.coverPath = "ui/noteHoldCovers";

					babyArrow.frames = Paths.getSparrowAtlas('ui/NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
					}
			}

			var noteCover:NoteHoldCover = new NoteHoldCover(babyArrow, i);

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.ID = i;

			babyArrow.x += 50;

			if (player == 1) {
				playerStrums.add(babyArrow);
				babyArrow.animation.finishCallback = function(name:String){
					if(autoplay){
						if(name == "confirm"){
							babyArrow.animation.play('static', true);
							babyArrow.centerOffsets();
						}
					}
				}

				if(!Config.centeredNotes && !forceCenteredNotes){
					babyArrow.x += ((FlxG.width / 2));
				}
				else{
					babyArrow.x += ((FlxG.width / 4));
				}

				playerCovers.add(noteCover);

			}
			else {
				enemyStrums.add(babyArrow);
				babyArrow.animation.finishCallback = function(name:String){
					if(name == "confirm"){
						babyArrow.animation.play('static', true);
						babyArrow.centerOffsets();
					}
				}

				if(Config.centeredNotes || forceCenteredNotes){
					babyArrow.x -= 1280;
				}

				enemyCovers.add(noteCover);
			}

			if(!instant){
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				tweenManager.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.animation.play('static');
		}
	}

	override function openSubState(SubState:FlxSubState) {

		if (paused){

			if (FlxG.sound.music != null){
				FlxG.sound.music.pause();
				vocals.pause();
				if(vocalType == splitVocalTrack){ vocalsOther.pause(); }
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;

			stage.pause();
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		
		if (paused){

			if (FlxG.sound.music != null && !startingSong){
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished){
				startTimer.active = true;
			}
				
			paused = false;

			stage.unpause();
		}

		setBoyfriendInvuln(1/60);

		super.closeSubState();
	}

	function resyncVocals():Void {
		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length){
			vocals.time = Conductor.songPosition;
			vocals.play();
		}

		if(vocalType == splitVocalTrack){
			vocalsOther.pause();
			if (Conductor.songPosition <= vocalsOther.length){
				vocalsOther.time = Conductor.songPosition;
				vocalsOther.play();
			}
		}
		//trace("resyncing vocals");
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function truncateFloat( number:Float, precision:Int):Float{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num)/Math.pow(10, precision);
		return num;
	}


	override public function update(elapsed:Float) {
		if(invulnTime > 0){
			invulnTime -= elapsed;
			//trace(invulnTime);
			if(invulnTime <= 0){
				invuln = false;
			}
		}

		if(missTime > 0){
			missTime -= elapsed;
			//trace(missTime);
			if(missTime <= 0){
				canHit = false;
			}
		}

		keyCheck();

		for(i in 0...releaseTimes.length){
			if(releaseTimes[i] != -1){
				releaseTimes[i] += elapsed;
				//trace(i + ": " + releaseTimes[i]);
			}
		}

		if (!inCutscene && !endingSong){
		 	if(!autoplay){
		 		keyShit();
			}
		 	else{
				keyShitAuto();
		 	}
		}
		
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.TAB && !isStoryMode){
			autoplay = !autoplay;
			preventScoreSaving = true;
		}

		updateAccuracy();
		updateScoreText();

		call('onUpdate', [elapsed]);

		super.update(elapsed);

		stage.update(elapsed);

		if(!startingSong){
			for(i in eventList){
				if(i[0] > Conductor.songPosition){
					break;
				}
				else{
					executeEvent(i[1]);
					eventList.remove(i);
				}
			}
		}

		if (Binds.justPressed("pause") && startedCountdown && canPause){
			paused = true;
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN && !isStoryMode){

			if(!FlxG.keys.pressed.SHIFT){
				ChartingState.startSection = curSection;
			}

			switchState(new ChartingState());
			sectionStart = false;
		}

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2){
			health = 2;
		}

		if(healthLerp != health){
			healthLerp = Utils.fpsAdjsutedLerp(healthLerp, health, 0.7);
		}
		if(inRange(healthLerp, 2, 0.001)){
			healthLerp = 2;
		}

		//Health Icons
		if (healthBar.percent < 20){
			iconP1.animation.curAnim.curFrame = 1;
			iconP2.animation.curAnim.curFrame = 2;
		}
		else if (healthBar.percent > 80){
			iconP1.animation.curAnim.curFrame = 2;
			iconP2.animation.curAnim.curFrame = 1;
		}
		else{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}

		if (FlxG.keys.justPressed.EIGHT && !isStoryMode){

			sectionStart = false;

			if(FlxG.keys.pressed.SHIFT){
				switchState(new AnimationDebug(SONG.player1));
			}
			else if(FlxG.keys.pressed.CONTROL){
				switchState(new AnimationDebug(gfCheck));
			}
			else{
				switchState(new AnimationDebug(SONG.player2));
			}
		}
			

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		/*else if(inEndingCutscene){

		}*/
		else{
			Conductor.songPosition += FlxG.elapsed * 1000;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong) {

			if (camFocus != "dad" && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && autoCam){
				camFocusOpponent();
			}

			if (camFocus != "bf" && PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && autoCam){
				camFocusBF();
			}
		}

		camFollowFinal.setPosition(camFollow.x + camFollowOffset.x + camFollowShake.x + stage.globalCameraOffset.x, camFollow.y + camFollowOffset.y + camFollowShake.y + stage.globalCameraOffset.y);

		if(!inVideoCutscene){
			camGame.zoom = defaultCamZoom + camGameZoomAdjust;
		}

		//FlxG.watch.addQuick("totalBeats: ", totalBeats);

		// RESET = Quick Game Over Screen
		if (Binds.justPressed("killbind") && !startingSong) {
			health = 0;
		}

		if (health <= 0){ openGameOver(); }

		if (unspawnNotes[0] != null){
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3000){
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);

				sortNotes();
			}
		}

		if (generatedMusic){
			updateNote();
			opponentNoteCheck();
		}

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSongCutsceneCheck();
		#end
		
		leftPress = false;
		leftRelease = false;
		downPress = false;
		downRelease = false;
		upPress = false;
		upRelease = false;
		rightPress = false;
		rightRelease = false;

		for(i in 0...releaseTimes.length){
			if(releaseTimes[i] >= releaseBufferTime){
				releaseTimes[i] = -1;
			}
		}

		call('onPostUpdate', [elapsed]);
	}

	public function openGameOver(?character:String):Void{
		if(character == null){
			character = boyfriend.deathCharacter;
		}

		persistentDraw = false;
		paused = true;

		vocals.stop();
		if(vocalType == splitVocalTrack){ vocalsOther.stop(); }
		FlxG.sound.music.stop();

		camGame.filters = [];

		openSubState(new GameOverSubstate(boyfriend.getSprite().getScreenPosition().x, boyfriend.getSprite().getScreenPosition().y, camFollowFinal.getScreenPosition().x, camFollowFinal.getScreenPosition().y, character));
		sectionStart = false;
	}

	function updateNote(){
		notes.forEachAlive(function(daNote:Note)
		{
			var targetY:Float;
			var targetX:Float;

			var scrollSpeed:Float;

			if(daNote.mustPress){
				targetY = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y;
				targetX = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			}
			else{
				targetY = enemyStrums.members[Math.floor(Math.abs(daNote.noteData))].y;
				targetX = enemyStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			}

			if(Config.scrollSpeedOverride > 0){
				scrollSpeed = Config.scrollSpeedOverride;
			}
			else{
				scrollSpeed = FlxMath.roundDecimal(PlayState.SONG.speed, 2);
			}

			if(Config.downscroll){
				daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * scrollSpeed)) - daNote.yOffset;	
				if(daNote.isSustainNote){
					daNote.y -= daNote.height;
					daNote.y += 125;

					if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
						&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2)){
						// Clip to strumline
						var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
						swagRect.height = (targetY + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
	
						daNote.clipRect = swagRect;
					}
				}
			}
			else {
				daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * scrollSpeed)) + daNote.yOffset;
				if(daNote.isSustainNote){
					if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
						&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2)){
						// Clip to strumline
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (targetY + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}
			}

			daNote.x = targetX + daNote.xOffset;

			if(daNote.tooLate){
				if (!daNote.didTooLateAction && !daNote.isFake){
					noteMiss(daNote.noteData, daNote.missCallback, Scoring.MISS_DAMAGE_AMMOUNT, true, true);
					vocals.volume = 0;
					daNote.didTooLateAction = true;
				}
			}

			if (Config.downscroll ? (daNote.y > strumLine.y + daNote.height + 50) : (daNote.y < strumLine.y - daNote.height - 50)){
				if (daNote.tooLate || daNote.wasGoodHit){
								
					daNote.active = false;
					daNote.visible = false;
					daNote.destroy();
				}
			}
		});
	}

	function opponentNoteCheck(){
		notes.forEachAlive(function(daNote:Note)
		{
			if (!daNote.mustPress && daNote.canBeHit && !daNote.wasGoodHit)
			{
				daNote.wasGoodHit = true;

				if((Character.LOOP_ANIM_ON_HOLD ? (daNote.isSustainNote ? (Character.HOLD_LOOP_WAIT ? (!dad.curAnim.contains("sing") || (dad.curAnimFrame() >= 3 || dad.curAnimFinished())) : true) : true) : !daNote.isSustainNote)){
					daNote.hitCallback(daNote, dad);
				}

				enemyStrums.forEach(function(spr:FlxSprite)
				{
					if (Math.abs(daNote.noteData) == spr.ID)
					{
						spr.animation.play('confirm', true);
						if (spr.animation.curAnim.name == 'confirm' && !(curUiType == "pixel"))
						{
							spr.centerOffsets();
							spr.offset.x -= 14;
							spr.offset.y -= 14;
						}
						else
							spr.centerOffsets();
					}
				});

				dad.holdTimer = 0;

				switch(vocalType){
					case splitVocalTrack:
						vocalsOther.volume = 1;
					case combinedVocalTrack:
						vocals.volume = 1;
					default:
				}
					

				if(!daNote.isSustainNote){
					daNote.destroy();
				}
				else{
					if(daNote.prevNote == null || !daNote.prevNote.isSustainNote){
						enemyCovers.forEach(function(cover:NoteHoldCover) {
							if (Math.abs(daNote.noteData) == cover.noteDirection) {
								cover.start();
							}
						});
					}
					else if(daNote.isSustainEnd){
						enemyCovers.forEach(function(cover:NoteHoldCover) {
							if (Math.abs(daNote.noteData) == cover.noteDirection) {
								cover.end(false);
							}
						});
					}
				}

			}
		});
	}

	function endSongCutsceneCheck():Void{
		//trace("in cutsceneCheck");
		stopMusic();

		if(endCutscene != null){
			add(endCutscene);
			inCutscene = true;
			inEndingCutscene = true;
			endCutscene.start();
		}
		else{
			endSong();
		}
	}

	function stopMusic():Void{
		songEnded = true;
		canPause = false;
		endingSong = true;
		FlxG.sound.music.volume = 0;
		FlxG.sound.music.pause();
		vocals.volume = 0;
		vocals.pause();
		if(vocalType == splitVocalTrack) { 
			vocalsOther.volume = 0; 
			vocalsOther.pause();
		}
	}

	public function endSong():Void{
		
		inEndingCutscene = false;

		if(!songEnded){ stopMusic(); }

		if (isStoryMode){

			storyPlaylist.remove(storyPlaylist[0]);

			if (!preventScoreSaving){
				Highscore.saveScore(SONG.song, songStats.score, songStats.accuracy, storyDifficulty, Highscore.calculateRank(songStats));
				weekStats.score += songStats.score;
				if(songStats.highestCombo > weekStats.highestCombo) {weekStats.highestCombo = songStats.highestCombo;}
				weekStats.accuracy += songStats.accuracy;
				weekStats.sickCount += songStats.sickCount;
				weekStats.goodCount += songStats.goodCount;
				weekStats.badCount += songStats.badCount;
				weekStats.shitCount += songStats.shitCount;
				weekStats.susCount += songStats.susCount;
				weekStats.missCount += songStats.missCount;
				weekStats.comboBreakCount += songStats.comboBreakCount;
			}

			//CODE FOR ENDING A WEEK
			if (storyPlaylist.length <= 0)
			{
				//FlxG.sound.playMusic(Paths.music(TitleScreen.titleMusic), TitleScreen.titleMusicVolume);

				StoryMenuState.fromPlayState = true;
				//returnToMenu();
				sectionStart = false;

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				weekStats.accuracy / StoryMenuState.weekData[storyWeek].length;

				//Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				var songSaveStuff:SaveInfo = null;
				if(!preventScoreSaving){
					songSaveStuff = {
						song: null,
						week: storyWeek,
						diff: storyDifficulty
					}
				}
				switchState(new ResultsState(weekStats, StoryMenuState.weekNamesShort[storyWeek], "bf", songSaveStuff));

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			//CODE FOR CONTINUING A WEEK
			else{

				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				switchState(new PlayState());

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;
			}
		}
		//CODE FOR ENDING A FREEPLAY SONG
		else{

			sectionStart = false;
			//returnToMenu();

			var songName = SONG.song.replace("-", " ");
			if(metadata != null){
				songName = metadata.name;
			}

			var songSaveStuff:SaveInfo = null;
			if(!preventScoreSaving){
				songSaveStuff = {
					song: SONG.song,
					week: null,
					diff: storyDifficulty
				}
			}
			switchState(new ResultsState(songStats, songName, "bf", songSaveStuff));
		}
	}

	public function returnToMenu():Void{
		switch(returnLocation){
			case "story":
				switchState(new StoryMenuState());
			case "freeplay":
				switchState(new FreeplayState(false));
			default:
				switchState(new MainMenuState());
		}
	}

	private function popUpScore(note:Note):Void{

		var noteDiff:Float = note.strumTime - Conductor.songPosition;

		songStats.score += Scoring.scoreNote(noteDiff);
		var rating:String = Scoring.rateNote(noteDiff);

		switch(rating){
			case "sick":
				health += Scoring.SICK_HEAL_AMMOUNT * Config.healthMultiplier;
				songStats.sickCount++;
				if(Config.noteSplashType >= 1 && Config.noteSplashType < 4){
					createNoteSplash(note.noteData);
				}
			case "good":
				health += Scoring.GOOD_HEAL_AMMOUNT * Config.healthMultiplier;
				songStats.goodCount++;
			case "bad":
				health += Scoring.BAD_HEAL_AMMOUNT * Config.healthMultiplier;
				songStats.badCount++;
				comboBreak();
			case "shit":
				health += Scoring.SHIT_HEAL_AMMOUNT * Config.healthMultiplier;
				songStats.shitCount++;
				comboBreak();
		}

		comboUI.ratingPopup(rating);

		if(combo >= minCombo)
			comboUI.comboPopup(combo);

	}

	private function createNoteSplash(note:Int){
		var bigSplashy = new NoteSplash(Utils.getGraphicMidpoint(playerStrums.members[note]).x, Utils.getGraphicMidpoint(playerStrums.members[note]).y, note);
		bigSplashy.cameras = [camHUD];
		add(bigSplashy);
	}

	private function keyCheck():Void{

		upTime = Binds.pressed("gameplayUp") ? upTime + 1 : 0;
		downTime = Binds.pressed("gameplayDown") ? downTime + 1 : 0;
		leftTime = Binds.pressed("gameplayLeft") ? leftTime + 1 : 0;
		rightTime = Binds.pressed("gameplayRight") ? rightTime + 1 : 0;

		upPress = upTime == 1;
		downPress = downTime == 1;
		leftPress = leftTime == 1;
		rightPress = rightTime == 1;

		upRelease = upHold && upTime == 0;
		downRelease = downHold && downTime == 0;
		leftRelease = leftHold && leftTime == 0;
		rightRelease = rightHold && rightTime == 0;

		upHold = upTime > 0;
		downHold = downTime > 0;
		leftHold = leftTime > 0;
		rightHold = rightTime > 0;

		if(leftRelease){ releaseTimes[0] = 0; }
		else if(leftPress){ releaseTimes[0] = -1; }

		if(downRelease){ releaseTimes[1] = 0; }
		else if(downPress){ releaseTimes[1] = -1; }

		if(upRelease){ releaseTimes[2] = 0; }
		else if(upPress){ releaseTimes[2] = -1; }

		if(rightRelease){ releaseTimes[3] = 0; }
		else if(rightPress){ releaseTimes[3] = -1; }

		/*THE FUNNY 4AM CODE! [bro what was i doin????]
		trace((leftHold?(leftPress?"^":"|"):(leftRelease?"^":" "))+(downHold?(downPress?"^":"|"):(downRelease?"^":" "))+(upHold?(upPress?"^":"|"):(upRelease?"^":" "))+(rightHold?(rightPress?"^":"|"):(rightRelease?"^":" ")));
		I should probably remove this from the code because it literally serves no purpose, but I'm gonna keep it in because I think it's funny.
		It just sorta prints 4 lines in the console that look like the arrows being pressed. Looks something like this:
		====
		^  | 
		| ^|
		| |^
		^ |
		====*/

	}

	private function keyShit():Void
	{

		var controlArray:Array<Bool> = [leftPress, downPress, upPress, rightPress];

		if ((upPress || rightPress || downPress || leftPress) && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					ignoreList.push(daNote.noteData);

					if(Config.ghostTapType == 1){
						setCanMiss();
					}
				}

			});

			var directionsAccounted = [false,false,false,false];

			if (possibleNotes.length > 0 && !forceMissNextNote){
				for(note in possibleNotes){
					if (controlArray[note.noteData] && !directionsAccounted[note.noteData]){
						goodNoteHit(note);
						directionsAccounted[note.noteData] = true;
					}
				}
				for(i in 0...4){
					if(!ignoreList.contains(i) && controlArray[i]){
						badNoteCheck(i);
					}
				}
			}
			else{
				badNoteCheck();
			}
		}
		
		notes.forEachAlive(function(daNote:Note) {
			if ((upHold || rightHold || downHold || leftHold) && generatedMusic){
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote && !daNote.wasGoodHit)
				{

					boyfriend.holdTimer = 0;

					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 2:
							if (upHold)
								goodNoteHit(daNote);
						case 3:
							if (rightHold)
								goodNoteHit(daNote);
						case 1:
							if (downHold)
								goodNoteHit(daNote);
						case 0:
							if (leftHold)
								goodNoteHit(daNote);
					}
				}
			}

			//Guitar Hero Type Held Notes
			if(daNote.isSustainNote && daNote.mustPress){

				//This is for all subsequent released notes.
				if(daNote.prevNote.tooLate && !daNote.prevNote.wasGoodHit){
					daNote.tooLate = true;
					daNote.destroy();
					noteMiss(daNote.noteData, daNote.missCallback, Scoring.HOLD_DROP_DMAMGE_PER_NOTE * (daNote.isFake ? 0 : 1), false, true, false, Scoring.HOLD_DROP_PENALTY);
					//updateAccuracyOld();
				}

				//This is for the first released note.
				if(daNote.prevNote.wasGoodHit && !daNote.wasGoodHit){

					if(releaseTimes[daNote.noteData] >= releaseBufferTime){
						noteMiss(daNote.noteData, daNote.missCallback, Scoring.HOLD_DROP_INITAL_DAMAGE, true, true, false, Scoring.HOLD_DROP_INITIAL_PENALTY);
						vocals.volume = 0;
						daNote.tooLate = true;
						daNote.destroy();
						boyfriend.holdTimer = 0;
						//updateAccuracyOld();

						playerCovers.forEach(function(cover:NoteHoldCover) {
							if (Math.abs(daNote.noteData) == cover.noteDirection) {
								cover.end(false);
							}
						});

						var recursiveNote = daNote;
						while(recursiveNote.prevNote != null && recursiveNote.prevNote.exists && recursiveNote.prevNote.isSustainNote){
							recursiveNote.prevNote.visible = false;
							recursiveNote = recursiveNote.prevNote;
						}
					}
					
				}
			}
		});

		if (boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.stepsUntilRelease * 0.001 && !upHold && !downHold && !rightHold && !leftHold && boyfriend.canAutoAnim)
		{
			if (boyfriend.curAnim.startsWith('sing')){
				if(Character.USE_IDLE_END){ 
					boyfriend.idleEnd(); 
				}
				else{ 
					boyfriend.dance(); 
					boyfriend.danceLockout = true;
				}
			}	
		}

		playerStrums.forEach(function(spr:FlxSprite){
			switch (spr.ID){
				case 2:
					if (upPress && spr.animation.curAnim.name != 'confirm'){
						spr.animation.play('pressed');
					}
					if (!upHold){
						spr.animation.play('static');
					}
				case 3:
					if (rightPress && spr.animation.curAnim.name != 'confirm'){
						spr.animation.play('pressed');
					}
					if (!rightHold){
						spr.animation.play('static');
					}
				case 1:
					if (downPress && spr.animation.curAnim.name != 'confirm'){
						spr.animation.play('pressed');
					}
					if (!downHold){
						spr.animation.play('static');
					}
				case 0:
					if (leftPress && spr.animation.curAnim.name != 'confirm'){
						spr.animation.play('pressed');
					}
					if (!leftHold){
						spr.animation.play('static');
					}
			}

			switch(spr.animation.curAnim.name){

				case "confirm":

					//spr.alpha = 1;
					spr.centerOffsets();

					if(!(curUiType == "pixel")){
						spr.offset.x -= 14;
						spr.offset.y -= 14;
					}

					//i'm bored lol
					/*if(spr.animation.curAnim.curFrame == 0){
						tweenManager.cancelTweensOf(spr.scale);
						spr.centerOrigin();
						spr.scale.set(1.4, 1.4);
						tweenManager.tween(spr.scale, {x: 0.7, y: 0.7}, 1, {ease: FlxEase.elasticOut});
					}*/

				/*case "static":
					spr.alpha = 0.5; //Might mess around with strum transparency in the future or something.
					spr.centerOffsets();*/

				default:
					//spr.alpha = 1;
					spr.centerOffsets();

			}

		});
	}

	private function keyShitAuto():Void{

		var hitNotes:Array<Note> = [];

		notes.forEachAlive(function(daNote:Note){
			if (!forceMissNextNote && !daNote.wasGoodHit && daNote.mustPress && daNote.strumTime < Conductor.songPosition + Conductor.safeZoneOffset * (!daNote.isSustainNote ? 0.125 : (daNote.prevNote.wasGoodHit ? 1 : 0))){
				hitNotes.push(daNote);
			}
		});

		if (boyfriend.holdTimer > Conductor.stepCrochet * boyfriend.stepsUntilRelease * 0.001 && !upHold && !downHold && !rightHold && !leftHold && boyfriend.canAutoAnim){
			if (boyfriend.curAnim.startsWith('sing')){
				if(Character.USE_IDLE_END){ 
					boyfriend.idleEnd(); 
				}
				else{ 
					boyfriend.dance(); 
					boyfriend.danceLockout = true;
				}
			}
		}

		for(x in hitNotes){

			boyfriend.holdTimer = 0;

			goodNoteHit(x);
			
			playerStrums.forEach(function(spr:FlxSprite){
				if (Math.abs(x.noteData) == spr.ID){
					spr.animation.play('confirm', true);
					if (spr.animation.curAnim.name == 'confirm' && !(curUiType == "pixel")){
						spr.centerOffsets();
						spr.offset.x -= 14;
						spr.offset.y -= 14;
					}
					else{
						spr.centerOffsets();
					}
				}
			});

		}

	}

	function noteMiss(direction:Int = 1, callback:(Int, Character)->Void, ?healthLoss:Float, ?playAudio:Bool = true, ?countMiss:Bool = true, ?dropCombo:Bool = true, ?scoreAdjust:Null<Int>):Void{

		if(scoreAdjust == null){
			scoreAdjust = Scoring.MISS_PENALTY;
		}

		if (!startingSong){

			health -= healthLoss * Config.healthDrainMultiplier;

			if(dropCombo){
				comboBreak();
			}

			if(countMiss){
				songStats.missCount++;
			}

			songStats.score -= scoreAdjust;
			
			if(playAudio){
				FlxG.sound.play(Paths.sound('missnote' + FlxG.random.int(1, 3)), 0.2);
			}

			forceMissNextNote = false;

			callback(direction, boyfriend);
			
		}

		if(Main.flippymode) { System.exit(0); }

	}

	inline function noteMissWrongPress(direction:Int = 1):Void{
		var forceMissNextNoteState = forceMissNextNote;
		noteMiss(direction, defaultNoteMiss, Scoring.WRONG_TAP_DAMAGE_AMMOUNT, true, false, false, Scoring.WRONG_PRESS_PENALTY);
		setBoyfriendInvuln(4/60);
		forceMissNextNote = forceMissNextNoteState;
	}

	function badNoteCheck(direction:Int = -1){
		if((Config.ghostTapType == 0 || canHit) && !invuln){
			if (leftPress && (direction == -1 || direction == 0))
				noteMissWrongPress(0);
			else if (upPress && (direction == -1 || direction == 2))
				noteMissWrongPress(2);
			else if (rightPress && (direction == -1 || direction == 3))
				noteMissWrongPress(3);
			else if (downPress && (direction == -1 || direction == 1))
				noteMissWrongPress(1);
		}
	}

	function setBoyfriendInvuln(time:Float = 5/60){
		if(time > invulnTime){
			invulnTime = time;
			invuln = true;
		}
	}

	function setCanMiss(time:Float = 10/60){
		if(time > missTime){
			missTime = time;
			canHit = true;
		}
		
	}

	function goodNoteHit(note:Note):Void{
		if (!note.wasGoodHit){

			if(note.isFake){
				note.wasGoodHit = true;
				if(note.prevNote == null || !note.prevNote.isSustainNote){
					playerCovers.forEach(function(cover:NoteHoldCover) {
						if (Math.abs(note.noteData) == cover.noteDirection) {
							cover.start();
						}
					});
				}
				return;
			}

			if (!note.isSustainNote){
				popUpScore(note);
				combo++;
				if(combo > songStats.highestCombo) { songStats.highestCombo = combo; }
			}
			else{
				health += Scoring.HOLD_HEAL_AMMOUNT * Config.healthMultiplier;
				songStats.score += Std.int(Scoring.HOLD_SCORE_PER_SECOND * (Conductor.stepCrochet/1000));
				songStats.susCount++;
			}
				
			if((Character.LOOP_ANIM_ON_HOLD ? (note.isSustainNote ? (Character.HOLD_LOOP_WAIT ? (!boyfriend.curAnim.contains("sing") || (boyfriend.curAnimFrame() >= 3 || boyfriend.curAnimFinished())) : true) : true) : !note.isSustainNote)){
				note.hitCallback(note, boyfriend);
			}

			playerStrums.forEach(function(spr:FlxSprite) {
				if (Math.abs(note.noteData) == spr.ID) {
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if(!note.isSustainNote){
				note.destroy();
			}
			else{
				if(note.prevNote == null || !note.prevNote.isSustainNote){
					playerCovers.forEach(function(cover:NoteHoldCover) {
						if (Math.abs(note.noteData) == cover.noteDirection) {
							cover.start();
						}
					});
				}
				else if(note.isSustainEnd){
					playerCovers.forEach(function(cover:NoteHoldCover) {
						if (Math.abs(note.noteData) == cover.noteDirection) {
							cover.end(true);
						}
					});
				}
			}
		}
	}

	override function stepHit()
	{

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition)) > 20 || (vocalType != noVocalTrack && Math.abs(vocals.time - (Conductor.songPosition)) > 20)){
			resyncVocals();
		}

		if(vocalType == splitVocalTrack){
			if (Math.abs(vocalsOther.time - (Conductor.songPosition)) > 20){
				resyncVocals();
			}
		}

		if(curStep > 0 && curStep % 16 == 0){
			curSection++;
		}

		boyfriend.step(curStep);
		dad.step(curStep);
		gf.step(curStep);
		stage.step(curStep);

		super.stepHit();

		call('onStepHit', [curStep]);
	}

	override function beatHit()
	{
		//wiggleShit.update(Conductor.crochet);
		super.beatHit();

		//sortNotes();

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM){
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}

			// Dad doesnt interupt his own notes
			if(dadBeats.contains(curBeat % 4) && dad.canAutoAnim && dad.holdTimer == 0 && !dad.curAnim.startsWith('sing')){
				dad.dance();
			}
			
		}
		else{
			if(dadBeats.contains(curBeat % 4))
				dad.dance();
		}

		if(curBeat % camBopFrequency == 0 && autoCamBop){
			uiBop(0.0175, 0.03, 0.8);
		}

		if (curBeat % iconBopFrequency == 0){
			iconP1.iconScale = iconP1.defualtIconScale * 1.25;
			iconP2.iconScale = iconP2.defualtIconScale * 1.25;

			iconP1.tweenToDefaultScale(0.2, FlxEase.quintOut);
			iconP2.tweenToDefaultScale(0.2, FlxEase.quintOut);
		}
		
		if (curBeat % gfBopFrequency == 0){
			gf.dance();
		}

		if(bfBeats.contains(curBeat % 4) && boyfriend.canAutoAnim && !boyfriend.curAnim.startsWith('sing')){
			boyfriend.dance();
		}

		boyfriend.beat(curBeat);
		dad.beat(curBeat);
		gf.beat(curBeat);
		stage.beat(curBeat);
		
		call('onBeatHit', [curBeat]);
	}

	public function executeEvent(tag:String):Void{

		var prefix = tag.split(";")[0];

		if(Events.events.exists(prefix)){
			Events.events.get(prefix)(tag);
		}
		else if(stage.events.exists(tag)){
			stage.events.get(prefix)(tag);
		}
		else{
			trace("No event found for: " + tag);
			call('onEvent', [tag]);
		}

		return;
	}

	public function defaultNoteHit(note:Note, character:Character):Void{
		if(character.canAutoAnim){
			switch (note.noteData){
				case 0:
					character.playAnim('singLEFT', true);
				case 1:
					character.playAnim('singDOWN', true);
				case 2:
					character.playAnim('singUP', true);
				case 3:
					character.playAnim('singRIGHT', true);
			}
		}
		getExtraCamMovement(note);
	}

	public function defaultNoteMiss(direction:Int, character:Character):Void{
		if(character.canAutoAnim){
			switch (direction){
				case 0:
					character.playAnim('singLEFTmiss', true);
				case 1:
					character.playAnim('singDOWNmiss', true);
				case 2:
					character.playAnim('singUPmiss', true);
				case 3:
					character.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function setNoteHitCallback(note:Note):Void{

		if(!note.isSustainNote){ //Normal notes
			if(NoteType.types.exists(note.type)){
				var callbacks = NoteType.types.get(note.type);
				if(callbacks[0] != null){ note.hitCallback = callbacks[0]; }
				else{ note.hitCallback = defaultNoteHit; }
				if(callbacks[1] != null){ note.missCallback = callbacks[1]; }
				else{ note.missCallback = defaultNoteMiss; }
			}
			else{
				note.hitCallback = defaultNoteHit;
				note.missCallback = defaultNoteMiss;
			}
		}
		else{ //sustain notes
			if(NoteType.sustainTypes.exists(note.type)){
				var callbacks = NoteType.sustainTypes.get(note.type);
				if(callbacks[0] != null){ note.hitCallback = callbacks[0]; }
				else{ note.hitCallback = defaultNoteHit; }
				if(callbacks[1] != null){ note.missCallback = callbacks[1]; }
				else{ note.missCallback = defaultNoteMiss; }
			}
			else{
				note.hitCallback = defaultNoteHit;
				note.missCallback = defaultNoteMiss;
			}
		}
		
	}

	var bfOnTop:Bool = true;
	public function setBfOnTop():Void{
		if(bfOnTop){ return; }
		bfOnTop = true;
		characterLayer.remove(boyfriend);
		characterLayer.remove(dad);
		characterLayer.add(dad);
		characterLayer.add(boyfriend);
	}
	public function setOppOnTop():Void{
		if(!bfOnTop){ return; }
		bfOnTop = false;
		characterLayer.remove(boyfriend);
		characterLayer.remove(dad);
		characterLayer.add(boyfriend);
		characterLayer.add(dad);
	}

	public function getExtraCamMovement(note:Note):Void{
		switch (note.noteData){
			case 0:
				if(!note.isSustainNote){ changeCamOffset(-1 * camOffsetAmount, 0); }
			case 1:
				if(!note.isSustainNote){ changeCamOffset(0, camOffsetAmount); }
			case 2:
				if(!note.isSustainNote){ changeCamOffset(0, -1 * camOffsetAmount); }
			case 3:
				if(!note.isSustainNote){ changeCamOffset(camOffsetAmount, 0); }
		}
	}

	function sectionContainsBfNotes(section:Int):Bool{
		var notes = SONG.notes[section].sectionNotes;
		var mustHit = SONG.notes[section].mustHitSection;

		for(x in notes){
			if(mustHit) { if(x[1] < 4) { return true; } }
			else { if(x[1] > 3) { return true; } }
		}

		return false;
	}

	function sectionContainsOppNotes(section:Int):Bool{
		var notes = SONG.notes[section].sectionNotes;
		var mustHit = SONG.notes[section].mustHitSection;

		for(x in notes){
			if(mustHit) { if(x[1] > 3) { return true; } }
			else { if(x[1] < 4) { return true; } }
		}

		return false;
	}

	public function camFocusOpponent(?offsetX:Float = 0, ?offsetY:Float = 0, ?_time:Float = 1.9, ?_ease:Null<flixel.tweens.EaseFunction>){
		if(_ease == null){_ease = FlxEase.expoOut;}
		
		var pos = getOpponentFocusPosition();
		camMove(pos.x + offsetX, pos.y + offsetY, _time, _ease, "dad");
		changeCamOffset(0, 0);
	}

	public inline function getOpponentFocusPosition():FlxPoint{
		return new FlxPoint(dad.getMidpoint().x + dad.focusOffset.x + stage.dadCameraOffset.x, dad.getMidpoint().y + dad.focusOffset.y + stage.dadCameraOffset.y);
	}

	public function camFocusBF(?offsetX:Float = 0, ?offsetY:Float = 0, ?_time:Float = 1.9, ?_ease:Null<flixel.tweens.EaseFunction>){
		if(_ease == null){_ease = FlxEase.expoOut;}

		var pos = getBfFocusPostion();
		camMove(pos.x + offsetX, pos.y + offsetY, _time, _ease, "bf");
		changeCamOffset(0, 0);
	}

	public inline function getBfFocusPostion():FlxPoint{
		return new FlxPoint(boyfriend.getMidpoint().x + boyfriend.focusOffset.x + stage.bfCameraOffset.x, boyfriend.getMidpoint().y + boyfriend.focusOffset.y + stage.bfCameraOffset.y);
	}

	public function camFocusGF(?offsetX:Float = 0, ?offsetY:Float = 0, ?_time:Float = 1.9, ?_ease:Null<flixel.tweens.EaseFunction>){
		if(_ease == null){_ease = FlxEase.expoOut;}

		var pos = getGfFocusPosition();
		camMove(pos.x + offsetX, pos.y + offsetY, _time, _ease, "gf");
		changeCamOffset(0, 0);
	}

	public inline function getGfFocusPosition():FlxPoint{
		return new FlxPoint(gf.getMidpoint().x + gf.focusOffset.x + stage.gfCameraOffset.x, gf.getMidpoint().y + gf.focusOffset.y + stage.gfCameraOffset.y);
	}

	public function camMove(_x:Float, _y:Float, _time:Float, ?_ease:Null<flixel.tweens.EaseFunction>, ?_focus:String = "", ?_onComplete:Null<TweenCallback> = null):Void{

		if(_onComplete == null){
			_onComplete = function(tween:FlxTween){};
		}

		camTween.cancel();
		if(_time > 0){
			camTween = tweenManager.tween(camFollow, {x: _x, y: _y}, _time, {ease: _ease, onComplete: _onComplete});
		}
		else{
			camFollow.set(_x, _y);
		}
		
		camFocus = _focus;

	}

	public function camChangeZoom(_zoom:Float, _time:Float, ?_ease:Null<flixel.tweens.EaseFunction>, ?_onComplete:Null<TweenCallback> = null):Void{

		if(_onComplete == null){
			_onComplete = function(tween:FlxTween){};
		}

		camZoomTween.cancel();
		if(_time > 0){
			camZoomTween = tweenManager.tween(this, {defaultCamZoom: _zoom}, _time, {ease: _ease, onComplete: _onComplete});
		}
		else{
			defaultCamZoom = _zoom;
		}

	}

	public function camChangeZoomAdjust(_zoom:Float, _time:Float, ?_ease:Null<flixel.tweens.EaseFunction>, ?_onComplete:Null<TweenCallback> = null):Void{

		if(_onComplete == null){
			_onComplete = function(tween:FlxTween){};
		}

		camZoomAdjustTween.cancel();
		if(_time > 0){
			camZoomAdjustTween = tweenManager.tween(this, {camGameZoomAdjust: _zoom}, _time, {ease: _ease, onComplete: _onComplete});
		}
		else{
			camGameZoomAdjust = _zoom;
		}

	}

	public function uiChangeZoom(_zoom:Float, _time:Float, ?_ease:Null<flixel.tweens.EaseFunction>, ?_onComplete:Null<TweenCallback> = null):Void{

		if(_onComplete == null){
			_onComplete = function(tween:FlxTween){};
		}

		uiZoomTween.cancel();
		if(_time > 0){
			uiZoomTween = tweenManager.tween(camHUD, {zoom: _zoom}, _time, {ease: _ease, onComplete: _onComplete});
		}
		else{
			camHUD.zoom = _zoom;
		}

	}

	public function uiBop(?_camZoom:Float = 0.01, ?_uiZoom:Float = 0.02, ?_time:Float = 0.6, ?_ease:Null<flixel.tweens.EaseFunction>){

		if(Config.camBopAmount == 2){ return; }
		else if(Config.camBopAmount == 1){
			_camZoom /= 2;
			_uiZoom /= 2;
		}

		if(_ease == null){
			_ease = FlxEase.quintOut;
		}

		if(autoZoom){
			camZoomAdjustTween.cancel();
			camGameZoomAdjust = _camZoom;
			camChangeZoomAdjust(0, _time, _ease);
		}

		if(autoUi){
			uiZoomTween.cancel();
			camHUD.zoom = 1 + _uiZoom;
			uiChangeZoom(1, _time, _ease);
		}

	}

	public function changeCamOffset(_x:Float, _y:Float, ?_time:Float = 1.4, ?_ease:Null<flixel.tweens.EaseFunction>){

		//Don't allow for extra camera offsets if it's disabled in the config.
		if(!Config.extraCamMovement){ return; }

		if(_ease == null){
			_ease = FlxEase.expoOut;
		}

		offsetTween.cancel();
		if(_time > 0){
			offsetTween = tweenManager.tween(camFollowOffset, {x: _x, y: _y}, _time, {ease: _ease});
		}
		else{
			camFollowOffset.set(_x, _y);
		}

	}

	public function startCamShake(_intensity:Float, ?_period:Float = 1/24, ?_ease:Null<flixel.tweens.EaseFunction>, ?_notFirstCall:Bool = false){

		if(_ease == null){
			_ease = FlxEase.linear;
		}
		if(_period < 1/60){
			_period = 1/60;
		}

		shakeTween.cancel();
		if(!_notFirstCall){ shakeReturnTween.cancel(); }
		shakeTween = tweenManager.tween(camFollowShake, {x: FlxG.random.float(-1, 1) * _intensity * 1280, y: FlxG.random.float(-1, 1) * _intensity * 720}, _period, {ease: _ease, onComplete: function(t){
			startCamShake(_intensity, _period, _ease, true);
		}});

	}

	public function endCamShake(?_time:Float = 1/24, ?_ease:Null<flixel.tweens.EaseFunction>, ?_startDelay:Float = 0){

		if(_ease == null){
			_ease = FlxEase.linear;
		}
		if(_time < 1/60){
			_time = 1/60;
		}

		shakeReturnTween.cancel();
		shakeReturnTween = tweenManager.tween(camFollowShake, {x: 0, y: 0}, _time, {ease: _ease, startDelay: _startDelay, onStart: function(t) {
			shakeTween.cancel();
		}});
	}

	public function camShake(_intensity:Float, ?_period:Float = 1/24, ?_time:Float = 1, ?_returnTime:Null<Float>, ?_ease:Null<flixel.tweens.EaseFunction>):Void{
		if(_returnTime == null){ _returnTime = _period; }
		startCamShake(_intensity, _period, _ease);
		endCamShake(_returnTime, _ease, _time);
	}

	function updateScoreText(){

		scoreTxt.text = "Score:" + songStats.score;

		if(Config.showMisses == 1){
			scoreTxt.text += " | Misses:" + songStats.missCount;
		}
		else if(Config.showMisses == 2){
			scoreTxt.text += " | Combo Breaks:" + songStats.comboBreakCount;
		}

		if(Config.showAccuracy){
			scoreTxt.text += " | Accuracy:" + truncateFloat(songStats.accuracy, 2) + "%";
		}

	}

	function comboBreak():Void{
		if (combo > minCombo){
			gf.playAnim('sad');
			comboUI.breakPopup();
		}
		combo = 0;
		songStats.comboBreakCount++;
	}

	function inRange(a:Float, b:Float, tolerance:Float){
		return (a <= b + tolerance && a >= b - tolerance);
	}

	function sortNotes(){
		if (generatedMusic){
			notes.sort(noteSortThing, FlxSort.DESCENDING);
		}
	}

	public static inline function noteSortThing(Order:Int, Obj1:Note, Obj2:Note):Int{
		return FlxSort.byValues(Order, Obj1.strumTime, Obj2.strumTime);
	}

	function songPreload():Void {
		FlxG.sound.cache(Paths.inst(SONG.song));
		
		if(Utils.exists(Paths.voices(SONG.song, "Player"))){
			FlxG.sound.cache(Paths.voices(SONG.song, "Player"));
			FlxG.sound.cache(Paths.voices(SONG.song, "Opponent"));
			vocalType = splitVocalTrack;
		}
		else if(Utils.exists(Paths.voices(SONG.song))){
			FlxG.sound.cache(Paths.voices(SONG.song));
		}
		else{
			vocalType = noVocalTrack;
		}
	}

	override function switchState(_state:FlxState) {
		if(Utils.exists(Paths.voices(SONG.song, "Player"))){
			Assets.cache.removeSound(Paths.voices(SONG.song, "Player"));
			Assets.cache.removeSound(Paths.voices(SONG.song, "Opponent"));
		}
		else if(Utils.exists(Paths.voices(SONG.song))){
			Assets.cache.removeSound(Paths.voices(SONG.song));
		}

		if(!CacheConfig.music){
			Assets.cache.removeSound(Paths.inst(SONG.song));
		}

		super.switchState(_state);
	}

	function call(func:String, ?args:Array<Dynamic>) {
		for(script in scripts)
			script.call(func, args);
	}

	function set(varName:String, variable:Dynamic) {
		for(script in scripts)
			script.set(varName, variable);
	}

	function loadScripts() {
		for(script in scripts)
			script.load();
	}

}

enum VocalType {
	noVocalTrack;
	combinedVocalTrack;
	splitVocalTrack;
}

typedef ScoreStats = {
	score:Int,
	highestCombo:Int,
	accuracy:Float,
	sickCount:Int,
	goodCount:Int,
	badCount:Int,
	shitCount:Int,
	susCount:Int,
	missCount:Int,
	comboBreakCount:Int,
}