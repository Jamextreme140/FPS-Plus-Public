package util;

using StringTools;

class JavaString {
	/**
		Tells if the character in the string `s` is Blank.

		Return `true` if the string is blank (no whitespaces)
	**/
    public static function isBlank(string:String) {
        return string.trim() == "";
    }

    /**
		Tells if the character in the string `s` is Empty.

		Return `true` if the string is empty, `false` otherwise (including whitespaces)
	**/
    public static function isEmpty(string:String) {
        for(c in 0...string.length) {
            if(!string.isSpace(c)) return false;
        }
        return true;
    }
}