package mobile.backend.utils;

import lime.app.Application;
import lime.system.JNI;
import lime.system.System;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;

class ExitManager {

    #if android
    private static var javaCheckDoubleBack:Dynamic;
    #end

    /**
     * Initializes the double-back-to-exit functionality.
     * Call `ExitManager.init();` once in your Main.hx constructor.
     */
    public static function init():Void {
        #if android
        javaCheckDoubleBack = JNI.createStaticMethod(
            "mobile/backend/java/DoubleBackToExit",
            "checkDoubleBack", 
            "(Ljava/lang/String;)Z"
        );
        #end

        if (Application.current != null && Application.current.window != null) {
            Application.current.window.onKeyUp.add(onKeyUp);
        }
    }

    /**
     * Internal event listener for keyboard input.
     */
    private static function onKeyUp(keyCode:KeyCode, modifier:KeyModifier):Void {
        if (keyCode == KeyCode.APP_CONTROL_BACK) {
            #if android
            var message:String = getLocalizedMessage();
            var shouldExit:Bool = javaCheckDoubleBack(message);
            
            if (shouldExit) {
                System.exit(0);
            }
            #end
        }
    }

    /**
     * Retrieves the correct toast message based on the current language.
     * TODO: to find the best way to make this system work
     */
    private static function getLocalizedMessage():String {
        var currentLanguage:String = "en"; 
        
        if (currentLanguage == "pt") {
            return "Clique em Voltar para sair"; 
        } else if (currentLanguage == "es") {
            return "Presione atrás nuevamente para salir";
        }
        
        // Default language fallback (English)
        return "Press back again to exit"; 
    }
}
