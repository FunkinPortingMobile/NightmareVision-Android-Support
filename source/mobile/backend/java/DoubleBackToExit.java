package mobile.backend.java;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.view.Gravity;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import org.haxe.extension.Extension;

public class DoubleBackToExit extends Extension {
    
    private static long backPressedTime = 0;
    private static Toast backToast;

    public static boolean checkDoubleBack(String localizedMessage) {
        if (backPressedTime + 2000 > System.currentTimeMillis()) {
            if (backToast != null) {
                backToast.cancel();
            }
            return true;
        } else {
            if (backToast != null) {
                backToast.cancel();
            }
            
            Context context = Extension.mainContext;
            
            if (Build.VERSION.SDK_INT >= 31) {
                backToast = Toast.makeText(context, localizedMessage, Toast.LENGTH_SHORT);
            } 
            else {
                backToast = new Toast(context);
                
                LinearLayout layout = new LinearLayout(context);
                layout.setOrientation(LinearLayout.HORIZONTAL);
                layout.setGravity(Gravity.CENTER_VERTICAL);
                
                GradientDrawable shape = new GradientDrawable();
                shape.setCornerRadius(100);
                shape.setColor(Color.parseColor("#F5F5F5"));
                layout.setBackground(shape);
                layout.setPadding(40, 25, 40, 25);
                
                ImageView icon = new ImageView(context);
                try {
                    PackageManager pm = context.getPackageManager();
                    ApplicationInfo appInfo = context.getApplicationInfo();
                    Drawable appIcon = pm.getApplicationIcon(appInfo);
                    icon.setImageDrawable(appIcon);
                } catch (Exception e) {
                    e.printStackTrace();
                }
                
                LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(60, 60);
                iconParams.setMargins(0, 0, 25, 0);
                icon.setLayoutParams(iconParams);
                
                TextView text = new TextView(context);
                text.setText(localizedMessage);
                text.setTextColor(Color.parseColor("#1A1A1A"));
                text.setTextSize(15);
                
                layout.addView(icon);
                layout.addView(text);
                
                backToast.setView(layout);
                backToast.setDuration(Toast.LENGTH_SHORT);
            }
            
            backToast.show();
            backPressedTime = System.currentTimeMillis();
            return false;
        }
    }
}
