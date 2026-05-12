#!/bin/bash
set -e

rm -rf appapp

mkdir -p app/src/main/java/com/lockgesture
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/xml
mkdir -p gradle/wrapper

# gradle wrapper
cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

curl -sL "https://raw.githubusercontent.com/gradle/gradle/v8.4.0/gradle/wrapper/gradle-wrapper.jar" \
  -o gradle/wrapper/gradle-wrapper.jar

cat > gradlew << 'EOF'
#!/bin/sh
exec java -classpath "$0/../gradle/wrapper/gradle-wrapper.jar" org.gradle.wrapper.GradleWrapperMain "$@"
EOF
chmod +x gradlew

cat > build.gradle << 'EOF'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.2.2'
        classpath 'org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.22'
    }
}
allprojects { repositories { google(); mavenCentral() } }
EOF

cat > settings.gradle << 'EOF'
rootProject.name = "LockGesture"
include ':app'
EOF

cat > app/build.gradle << 'EOF'
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
android {
    namespace 'com.lockgesture'
    compileSdkVersion 34
    defaultConfig {
        applicationId "com.lockgesture"
        minSdkVersion 29
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions { jvmTarget = '1.8' }
}
dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
}
EOF

cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.FLASHLIGHT"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <application android:allowBackup="true" android:label="LockGesture" android:theme="@style/Theme.LockGesture">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <service android:name=".OverlayService" android:foregroundServiceType="specialUse" android:exported="false"/>
        <service android:name=".GestureAccessibilityService" android:exported="true"
            android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService"/>
            </intent-filter>
            <meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_service_config"/>
        </service>
        <receiver android:name=".BootReceiver" android:exported="true">
            <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter>
        </receiver>
    </application>
</manifest>
EOF

cat > app/src/main/res/xml/accessibility_service_config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeAllMask"
    android:accessibilityFlags="flagDefault"
    android:canPerformGestures="true"
    android:description="@string/accessibility_description"
    android:notificationTimeout="100"
    android:settingsActivity=".MainActivity"/>
EOF

cat > app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">LockGesture</string>
    <string name="accessibility_description">LockGesture cần trợ năng để thực hiện hành động trên màn hình khoá</string>
</resources>
EOF

cat > app/src/main/res/values/themes.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.LockGesture" parent="Theme.MaterialComponents.DayNight.DarkActionBar"/>
</resources>
EOF

cat > app/src/main/res/values/arrays.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="actions">
        <item>Không làm gì</item>
        <item>Tắt màn hình</item>
        <item>Mở Camera</item>
        <item>Bật/Tắt Flash</item>
    </string-array>
</resources>
EOF

cat > app/src/main/res/layout/activity_main.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<ScrollView xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent" android:layout_height="match_parent" android:background="#1a1a2e">
    <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
        android:orientation="vertical" android:padding="16dp">
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="LockGesture" android:textSize="26sp" android:textColor="#e0e0e0"
            android:textStyle="bold" android:layout_marginBottom="4dp"/>
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="Gesture overlay cho màn hình khoá" android:textSize="13sp"
            android:textColor="#888" android:layout_marginBottom="20dp"/>
        <Button android:id="@+id/btnOverlay" android:layout_width="match_parent"
            android:layout_height="wrap_content" android:text="1. Cấp quyền Overlay" android:layout_marginBottom="8dp"/>
        <Button android:id="@+id/btnAccess" android:layout_width="match_parent"
            android:layout_height="wrap_content" android:text="2. Bật Trợ năng" android:layout_marginBottom="8dp"/>
        <Button android:id="@+id/btnToggle" android:layout_width="match_parent"
            android:layout_height="wrap_content" android:text="3. BẬT OVERLAY"
            android:backgroundTint="#4CAF50" android:layout_marginBottom="20dp"/>
        <TextView android:layout_width="match_parent" android:layout_height="wrap_content"
            android:text="GÁN GESTURE" android:textColor="#aaa" android:textSize="12sp" android:layout_marginBottom="12dp"/>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Double Tap" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp0" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Long Press" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp1" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Swipe Up" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp2" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Swipe Down" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp3" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Swipe Left" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp4" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
        <LinearLayout android:layout_width="match_parent" android:layout_height="wrap_content"
            android:orientation="horizontal" android:layout_marginBottom="10dp">
            <TextView android:layout_width="0dp" android:layout_height="wrap_content"
                android:layout_weight="1" android:text="Swipe Right" android:textColor="#e0e0e0"/>
            <Spinner android:id="@+id/sp5" android:layout_width="wrap_content"
                android:layout_height="wrap_content" android:entries="@array/actions"/>
        </LinearLayout>
    </LinearLayout>
</ScrollView>
EOF

cat > app/src/main/java/com/lockgesture/MainActivity.kt << 'EOF'
package com.lockgesture
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.Spinner
import androidx.appcompat.app.AppCompatActivity
class MainActivity : AppCompatActivity() {
    private val keys = listOf("double_tap","long_press","swipe_up","swipe_down","swipe_left","swipe_right")
    private val spIds = listOf(R.id.sp0,R.id.sp1,R.id.sp2,R.id.sp3,R.id.sp4,R.id.sp5)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val prefs = getSharedPreferences("gestures", MODE_PRIVATE)
        spIds.forEachIndexed { i, id ->
            val sp = findViewById<Spinner>(id)
            sp.setSelection(prefs.getInt(keys[i], 0))
            sp.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
                override fun onItemSelected(a: android.widget.AdapterView<*>?, v: android.view.View?, pos: Int, id: Long) {
                    prefs.edit().putInt(keys[i], pos).apply()
                }
                override fun onNothingSelected(a: android.widget.AdapterView<*>?) {}
            }
        }
        findViewById<Button>(R.id.btnOverlay).setOnClickListener {
            if (!Settings.canDrawOverlays(this))
                startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName")))
        }
        findViewById<Button>(R.id.btnAccess).setOnClickListener {
            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
        }
        val btn = findViewById<Button>(R.id.btnToggle)
        btn.setOnClickListener {
            if (OverlayService.isRunning) {
                stopService(Intent(this, OverlayService::class.java))
                btn.text = "3. BẬT OVERLAY"
                btn.backgroundTintList = android.content.res.ColorStateList.valueOf(0xFF4CAF50.toInt())
            } else {
                startForegroundService(Intent(this, OverlayService::class.java))
                btn.text = "3. TẮT OVERLAY"
                btn.backgroundTintList = android.content.res.ColorStateList.valueOf(0xFFF44336.toInt())
            }
        }
    }
    override fun onResume() {
        super.onResume()
        val btn = findViewById<Button>(R.id.btnToggle)
        if (OverlayService.isRunning) {
            btn.text = "3. TẮT OVERLAY"
            btn.backgroundTintList = android.content.res.ColorStateList.valueOf(0xFFF44336.toInt())
        }
    }
}
EOF

cat > app/src/main/java/com/lockgesture/OverlayService.kt << 'EOF'
package com.lockgesture
import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.*
import androidx.core.app.NotificationCompat
class OverlayService : Service() {
    companion object { var isRunning = false }
    private lateinit var wm: WindowManager
    private lateinit var ov: View
    private lateinit var gd: GestureDetector
    override fun onCreate() {
        super.onCreate(); isRunning = true
        val ch = NotificationChannel("lg","LockGesture",NotificationManager.IMPORTANCE_LOW)
        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(ch)
        startForeground(1, NotificationCompat.Builder(this,"lg")
            .setContentTitle("LockGesture đang chạy")
            .setSmallIcon(android.R.drawable.ic_menu_compass).build())
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val p = getSharedPreferences("gestures", Context.MODE_PRIVATE)
        ov = View(this).apply { setBackgroundColor(Color.TRANSPARENT) }
        gd = GestureDetector(this, object : GestureDetector.SimpleOnGestureListener() {
            override fun onDoubleTap(e: MotionEvent): Boolean {
                Actions.execute(this@OverlayService, p.getInt("double_tap",0)); return true
            }
            override fun onLongPress(e: MotionEvent) {
                Actions.execute(this@OverlayService, p.getInt("long_press",0))
            }
            override fun onFling(e1: MotionEvent?, e2: MotionEvent, vX: Float, vY: Float): Boolean {
                val dx=e2.x-(e1?.x?:0f); val dy=e2.y-(e1?.y?:0f)
                if (Math.abs(dx)>Math.abs(dy)) {
                    if(dx>0) Actions.execute(this@OverlayService,p.getInt("swipe_right",0))
                    else Actions.execute(this@OverlayService,p.getInt("swipe_left",0))
                } else {
                    if(dy>0) Actions.execute(this@OverlayService,p.getInt("swipe_down",0))
                    else Actions.execute(this@OverlayService,p.getInt("swipe_up",0))
                }
                return true
            }
        })
        ov.setOnTouchListener { _,e -> gd.onTouchEvent(e); true }
        wm.addView(ov, WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT, 160,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT).apply { gravity=Gravity.BOTTOM })
    }
    override fun onDestroy() {
        super.onDestroy(); isRunning=false
        if(::ov.isInitialized) wm.removeView(ov)
    }
    override fun onBind(i: Intent?): IBinder? = null
}
EOF

cat > app/src/main/java/com/lockgesture/Actions.kt << 'EOF'
package com.lockgesture
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.provider.MediaStore
object Actions {
    private var flashOn = false
    fun execute(ctx: Context, action: Int) = when(action) {
        1 -> GestureAccessibilityService.instance?.performGlobalAction(
                android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_LOCK_SCREEN)
        2 -> ctx.startActivity(Intent(MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA_SECURE)
                .apply { flags=Intent.FLAG_ACTIVITY_NEW_TASK })
        3 -> { val cm=ctx.getSystemService(Context.CAMERA_SERVICE) as CameraManager
               flashOn=!flashOn; cm.setTorchMode(cm.cameraIdList[0],flashOn) }
        else -> null
    }
}
EOF

cat > app/src/main/java/com/lockgesture/GestureAccessibilityService.kt << 'EOF'
package com.lockgesture
import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
class GestureAccessibilityService : AccessibilityService() {
    companion object { var instance: GestureAccessibilityService? = null }
    override fun onServiceConnected() { instance=this }
    override fun onAccessibilityEvent(e: AccessibilityEvent?) {}
    override fun onInterrupt() {}
    override fun onDestroy() { super.onDestroy(); instance=null }
}
EOF

cat > app/src/main/java/com/lockgesture/BootReceiver.kt << 'EOF'
package com.lockgesture
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, i: Intent) {
        if(i.action==Intent.ACTION_BOOT_COMPLETED)
            ctx.startForegroundService(Intent(ctx,OverlayService::class.java))
    }
}
EOF

./gradlew assembleDebug --stacktrace
