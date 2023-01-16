package states;

import flixel.math.FlxPoint;
#if cpp
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.graphics.FlxGraphic;
import flixel.addons.display.FlxBackdrop;
import WeekData;

using StringTools;

class MainMenuState extends states.MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';

	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;

	// var bgSprite:FlxSprite;
	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		states.PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if (curWeek >= WeekData.weeksList.length)
			curWeek = 0;
		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("Source Sans Pro Bold", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("Source Sans Pro Regular", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("sanspro-regular.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bg = new FlxSprite().loadGraphic(Paths.image("menuBackgrond"));
		bg.scale.set(0.7, 0.7);
		bg.updateHitbox();
		bg.angle = -15;
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		bg.screenCenter();
		add(bg);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		// add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if cpp
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if (!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				var weekThing:MenuItem = new MenuItem(0, 56 + 450, WeekData.weeksList[i]);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.targetY = num; // hello hello
				grpWeekText.add(weekThing);

				weekThing.screenCenter(X);
				weekThing.antialiasing = ClientPrefs.globalAntialiasing;
				// weekThing.updateHitbox();

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					lock.antialiasing = ClientPrefs.globalAntialiasing;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		trace("its morbin time");

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);
		var charArray:Array<String> = loadedWeeks[0].weekCharacters;
		for (char in 0...3)
		{
			var charName = charArray[char];
			var weekCharacterThing:MenuCharacter = new MenuCharacter(0, charName);
			// weekCharacterThing.scale.set(0.5,0.5);
			weekCharacterThing.updateHitbox();
			weekCharacterThing.x = 455 / 2 - weekCharacterThing.width / 2 * (1 + char) - 180;
			weekCharacterThing.y = (FlxG.height * 0.25) * (1 + char) - 150;
			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		// add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		// difficultySelectors.add(leftArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if (lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		// difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		// difficultySelectors.add(rightArrow);

		var flopRight = new FlxBackdrop(Paths.image("flopSideways"), Y, 0, 5);
		// flopTop.y = barBottom.y + flopTop.height + 5;
		flopRight.screenCenter();
		flopRight.scale.set(0.6, 0.6);
		flopRight.updateHitbox();
		// flopTop.angle = 15;
		flopRight.velocity.set(0, 100);
		flopRight.x = FlxG.width - 186 - 12;
		flopRight.antialiasing = ClientPrefs.globalAntialiasing;
		add(flopRight);

		var barRight = new FlxSprite();
		barRight.makeGraphic(227, FlxG.height, 0xFFA2946F);
		barRight.x = FlxG.width - 300;
		barRight.antialiasing = ClientPrefs.globalAntialiasing;
		// barRight.angle = 90;
		add(barRight);

		var flopLeft = new FlxBackdrop(Paths.image("flopSideways"), Y, 0, 5);
		// flopTop.y = barBottom.y + flopTop.height + 5;
		flopLeft.screenCenter();
		flopLeft.scale.set(0.6, 0.6);
		flopLeft.updateHitbox();
		// flopTop.angle = 15;
		flopLeft.velocity.set(0, -100);
		flopLeft.x = 300 + 12;
		flopLeft.antialiasing = ClientPrefs.globalAntialiasing;
		add(flopLeft);

		var barLeft = new FlxSprite();
		barLeft.makeGraphic(300, FlxG.height, 0xFFA2946F);
		barLeft.x = 0;
		barLeft.antialiasing = ClientPrefs.globalAntialiasing;
		// barRight.angle = 90;
		add(barLeft);

		// add(bgYellow);
		// add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(967, 56 + 235).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(967, tracksSprite.y + 50, 0, "", 32);
		txtTracklist.setFormat(Paths.font("sanspro-bold.ttf"), 32, FlxColor.BLACK, RIGHT, OUTLINE, FlxColor.WHITE);
		txtTracklist.borderStyle = FlxTextBorderStyle.OUTLINE;
		txtTracklist.borderSize = 2;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10)
			lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (controls.UI_RIGHT)
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (controls.UI_LEFT)
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (controls.UI_RIGHT_P)
				changeDifficulty(1);
			else if (controls.UI_LEFT_P)
				changeDifficulty(-1);
			else if (upP || downP)
				changeDifficulty();

			if (FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new states.substates.GameplayChangersSubstate());
			}
			else if (controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new states.substate.ResetScoreState('', curDifficulty, '', curWeek));
				// FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			states.MusicBeatState.switchState(new states.MainMenuState());
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
			lock.visible = (lock.y > FlxG.height / 2);
		});
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();

				var bf:MenuCharacter = grpWeekCharacters.members[1];
				if (bf.character != '' && bf.hasConfirmAnimation)
					grpWeekCharacters.members[1].animation.play('confirm');
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length)
			{
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			states.PlayState.storyPlaylist = songArray;
			states.PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if (diffic == null)
				diffic = '';

			states.PlayState.storyDifficulty = curDifficulty;

			states.PlayState.SONG = Song.loadFromJson(states.PlayState.storyPlaylist[0].toLowerCase() + diffic, states.PlayState.storyPlaylist[0].toLowerCase());
			states.PlayState.campaignScore = 0;
			states.PlayState.campaignMisses = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				states.LoadingState.loadAndSwitchState(new states.PlayState(), true);
				states.Freestates.PlayState.destroyFreeplayVocals();
			});
		}
		else
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	var tweenDifficulty:FlxTween;

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length - 1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = CoolUtil.difficulties[curDifficulty];
		var newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
		// trace(Paths.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));

		if (sprDifficulty.graphic != newImage)
		{
			// sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if (tweenDifficulty != null)
				tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {
				onComplete: function(twn:FlxTween)
				{
					tweenDifficulty = null;
				}
			});
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && unlocked)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		// bgSprite.visible = true;
		var assetName:String = leWeek.weekBackground;
		// if(assetName == null || assetName.length < 1) {
		// bgSprite.visible = false;
		// } else {
		// bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
		// }
		states.PlayState.storyWeek = curWeek;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if (diffStr != null)
			diffStr = diffStr.trim(); // Fuck you HTML5
		difficultySelectors.visible = unlocked;

		if (diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if (diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if (diffs[i].length < 1)
						diffs.remove(diffs[i]);
				}
				--i;
			}

			if (diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}

		if (CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		// trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if (newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		var weekArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for (i in 0...grpWeekCharacters.length)
		{
			// var scale = new FlxPoint(grpWeekCharacters.members[i].scale.x, grpWeekCharacters.members[i].scale.y);
			grpWeekCharacters.members[i].changeCharacter(weekArray[i]);
			// grpWeekCharacters.members[i].scale.copyFrom(scale);
		}

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length)
		{
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		// txtTracklist.screenCenter(X);
		// txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}
}