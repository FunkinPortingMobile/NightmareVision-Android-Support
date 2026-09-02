package funkin.backend;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.Assets;
import openfl.display.Sprite;

import funkin.input.Controls;

import flixel.util.FlxStringUtil;
import flixel.FlxG;

#if cpp
@:cppInclude("sys/utsname.h")
#end
	
/**
 * enum that handles the display type of the FPS counter.
 */
class FpsDisplayMode
{
	// if we wanna abuse the abstract part more go back to a abstract
	// inline static finals get inlined with less garbage than abstract inlines for whatever reason so consider this the most minute optimization ever
	
	/**
	 * The Fps counter will not be shown.
	 */
	public static inline final DISABLED:Int = 0;
	
	/**
	 * The Fps counter will show Fps and Memory.
	 */
	public static inline final SIMPLE:Int = 1;
	
	/**
	 * The Fps counter will additional info per state.
	 */
	public static inline final ADVANCED:Int = 2;
	
	public static inline function fromString(str:String):Int
	{
		return switch (str)
		{
			case 'Advanced': ADVANCED;
			case 'Simple': SIMPLE;
			default: DISABLED;
		}
	}
}

// /**
//  * enum that handles the display type of the FPS counter.
//  */
// enum abstract FpsDisplayMode(Int) from Int to Int
// {
// 	var DISABLED;
// 	var SIMPLE;
// 	var ADVANCED;
// }

/**
 * A FL Sprite that displays the current FPS and GC memory
 */
@:nullSafety
class DebugDisplay extends Sprite
{
	public static var instance:Null<DebugDisplay> = null;
	
	/**
	 * Creates a DebugDisplay instance
	 * 
	 * Use after your FlxGame is initiated.
	 */
	public static function init()
	{
		if (FlxG.game?.parent == null || instance != null) return;
		
		instance = new DebugDisplay(10, 3, 0xFFFFFF);
		instance.visible = instance.displayType != FpsDisplayMode.DISABLED;
		
		FlxG.game.parent.addChild(instance);
	}
	
	/**
	 * The visualized text showing the current fps
	 */
	final textField:TextField;
	
	/**
	 * The bg for the text
	 */
	public final textUnderlay:Bitmap;
	
	/**
	 * If disabled, the fps counter will no longer update visually
	 */
	var canUpdate:Bool = true;
	
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int = 0;
	
	/**
		The current memory usage of the garbage collector.
	**/
	public var gcMemory(get, never):Float;
	
	/**
	 * The current memory usage of the entire program.
	 * 
	 * Only supported on `Windows` currently
	 */
	public var taskMemory(get, never):Float;
	
	public var displayType:Int = FpsDisplayMode.SIMPLE;
	
	public var plugins:Array<Void->Null<String>> = [];
	
	var times:Array<Float> = [];
	
	var deltaTimeout:Float = 0.0;
	
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		
		textUnderlay = new Bitmap();
		textUnderlay.bitmapData = new BitmapData(1, 1, true, 0x6F000000);
		
		final textFormat = new TextFormat(Assets.getFont("assets/fonts/aller.ttf").fontName, 14, color);
		textFormat.leading = 5;
		
		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.defaultTextFormat = textFormat;
		textField.autoSize = LEFT;
		textField.multiline = true;
		textField.text = "FPS: ";
		
		displayType = FpsDisplayMode.fromString(ClientPrefs.fpsDisplayType);
		
		addChild(textUnderlay);
		addChild(textField);
		
		this.x = x #if mobile + 50 #end;
		this.y = y;
	}
	
	public static function addPlugin(fun:Void->String):Void->Null<String>
	{
		if (instance == null || instance.plugins.contains(fun)) return fun;
		
		instance.plugins.push(fun);
		
		return fun;
	}
	
	// Event Handlers
	override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
			
		if (Controls.instance.SWITCH_DEBUG_DISPLAY)
		{
			final fpsTypeArray:Array<String> = ['Simple', 'Advanced', 'Disabled'];
			ClientPrefs.fpsDisplayType = fpsTypeArray[FlxMath.wrap(fpsTypeArray.indexOf(ClientPrefs.fpsDisplayType) + 1, 0, fpsTypeArray.length - 1)];
		}
		
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}
		
		currentFPS = times.length;
		updateText();
		textUnderlay.width = textField.width + 3;
		textUnderlay.height = textField.height + (displayType == FpsDisplayMode.ADVANCED ? 0 : -5);
		
		deltaTimeout = 0.0;
	}
	
	// rebind this function to set a custom fps counter
	public dynamic function updateText():Void
	{
		__updateText();
        #if mobile setScale(); #end
	}
	
	function __updateText()
	{
		displayType = FpsDisplayMode.fromString(ClientPrefs.fpsDisplayType);
		
		visible = displayType != FpsDisplayMode.DISABLED;
		
		if (!canUpdate || !visible)
		{
			return;
		}
		
		#if cpp
		var str = 'FPS: $currentFPS • [GC: ${FlxStringUtil.formatBytes(gcMemory)} | Task: ${FlxStringUtil.formatBytes(taskMemory)}]';
		#else
		var str = 'FPS: $currentFPS • GC: ${FlxStringUtil.formatBytes(gcMemory)}';
		#end

        #if mobile
		str += ' • Arch: ${get_arch()}';
		#end
		
		if (displayType == FpsDisplayMode.ADVANCED)
		{
			var className = Type.getClassName(Type.getClass(FlxG.state));
			if (className.indexOf("ScriptedState") != -1)
			{
				var scripted:funkin.scripting.ScriptedState = cast FlxG.state;
				var path = funkin.scripts.FunkinScript.getPath('scripts/states/${scripted.scriptName}');
				className = 'ScriptedState • (${path.replace('scripts/states/', '../../')})';
			}
			
			str += '\nState: $className';
			
			for (fun in plugins)
			{
				try
				{
					final pluginStr:Null<String> = fun();
					
					if (pluginStr != null && pluginStr.length > 0) str += '\n$pluginStr';
				}
				catch (e)
				{
					Logger.log('Error on debug display plugin: $e', WARN);
					
					plugins.remove(fun);
				}
			}
		}
		
		textField.text = str;
	}

    #if mobile
	public inline function setScale(?scale:Float):Void {
	    if (scale == null) {
	        var screenW:Float = FlxG.stage.window.width;
	        var screenH:Float = FlxG.stage.window.height;
	        scale = Math.min(screenW / FlxG.width, screenH / FlxG.height);
	    }
	
	    #if android
	        var finalScale:Float = (scale > 1) ? scale : 1;
	    #else
	        var finalScale:Float = (scale < 1 ? scale : 1);
	    #end
	
	    scaleX = scaleY = finalScale;
	}
	#end
	
	inline function get_gcMemory():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif hl
		return hl.Gc.stats().currentMemory;
		#else
		return (cast openfl.system.System.totalMemoryNumber : UInt);
		#end
	}

    inline function get_arch():String
    {
    	#if cpp
    	return untyped __cpp__('[]() -> String {
		#if defined(__ANDROID__) || defined(__APPLE__) || defined(__linux__)
		#include <sys/utsname.h>
		struct utsname sysinfo;
		if (uname(&sysinfo) == 0) {
			return String(sysinfo.machine);
		}
		#endif

		#if defined(__aarch64__) || defined(_M_ARM64)
			return String("ARM64");
		#elif defined(__arm__) || defined(_M_ARM)
			return String("ARMv7");
		#elif defined(__x86_64__) || defined(_M_X64)
			return String("x86_64");
		#elif defined(__i386__) || defined(_M_IX86)
			return String("x86");
		#else
			return String("Unknown Arch");
		#endif
	    }()');
	     #else
	     return "Unknown Arch";
	     #end
    }
	
	inline function get_taskMemory():Float
	{
		return external.Native.getTaskMemory();
	}
}
