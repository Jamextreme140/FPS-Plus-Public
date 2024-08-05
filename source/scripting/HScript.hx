package scripting;

import haxe.io.Path;
import openfl.Assets;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.FlxBasic;
import hscript.Expr.Error;
import hscript.Parser;
import hscript.*;

using util.JavaString;

class HScript extends FlxBasic implements IFlxDestroyable{
    var parser:Parser;
    var interp:Interp;
    var expr:Expr;
    var code:String = null;

    var file:String;
    var filename:String;
    var staticVars:Map<String, Dynamic> = [];

    public static function buildScript(file:String, ?parent:Dynamic) {
        return new HScript(file, parent);
    }

    public function new(file:String, ?parent:Dynamic) {
        super();
        this.file = file;
        this.filename = Path.withoutDirectory(file);
        trace(file);
        init();
        if(parent != null) {
            interp.scriptObject = parent;
        }
        setVars();
        set("this", this);
    }

    public function init() {
        interp = new Interp();

        try {
            if(Assets.exists(file)) code = Assets.getText(file);
        }
        catch(e) {
            trace('Error: ${e.message}');
        }

        parser = new Parser();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;

        interp.errorHandler = (e:Error) -> {
            trace(e.toString());
        };
        interp.allowStaticVariables = interp.allowPublicVariables = true;
        interp.staticVariables = staticVars;

        // Taken from Codename
        interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args) v += ", " + Std.string(a);
			trace('${this.filename}:${interp.posInfos().lineNumber} -> ${v}');
		}));
        loadCode(code);
    }

    public function setVars() {
        set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
        set('PlayState', PlayState);
        set('Paths', Paths);
        set('Conductor', Conductor);
        set('Config', config.Config);
        set('Character', Character);
		set('Alphabet', Alphabet);
        set('Note', note.Note);
        set('StringTools', StringTools);
        #if flxanimate
		set('FlxAnimate', flxanimate.FlxAnimate);
		#end
    }

    // Taken from Codename
    public function load() {
        @:privateAccess
        interp.execute(parser.mk(EBlock([]), 0, 0));
        if (expr != null) {
			interp.execute(expr);
			call("new", []);
		}
    }

    public function loadCode(code:String) {
        try {
            if(code != null && !code.isBlank()) 
                expr = parser.parseString(code, filename);
        }
        catch(e:Error) {
            trace(e.toString());
        }
        catch(e) {
            trace(e.message);
        }
    }
    // Taken from Codename
    public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        if (interp == null) return null;
		if (!interp.variables.exists(func)) return null;

		var func = interp.variables.get(func);
		if (func != null && Reflect.isFunction(func))
			return Reflect.callMethod(null, func, args == null ? [] : args);

		return null;
    }

    public function get(variable:String):Dynamic {
        return interp.variables.get(variable);
    }

    public function set(variable:String, value:Dynamic) {
        interp.variables.set(variable, value);
    }

    public function setPublicVariables(map:Map<String, Dynamic>) {
        interp.publicVariables = map;
    }

    public override function destroy() {
        call('onDestroy');
        super.destroy();
    }
}