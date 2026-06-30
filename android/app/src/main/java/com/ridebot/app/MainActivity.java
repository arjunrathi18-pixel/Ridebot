package com.ridebot.app;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.view.accessibility.AccessibilityManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MainActivity extends FlutterActivity {

    private static final String MC = "com.ridebot/control";
    private static final String EC = "com.ridebot/logs";
    private static final String P  = "ridebot_prefs";

    private EventChannel.EventSink logSink;
    private BroadcastReceiver logReceiver;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine fe) {
        super.configureFlutterEngine(fe);

        new MethodChannel(fe.getDartExecutor().getBinaryMessenger(), MC)
            .setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "setEnabled":
                        pref().edit().putBoolean("automation_enabled",
                                (Boolean) call.argument("enabled")).apply();
                        result.success(null);
                        break;

                    case "savePlatformConfig":
                        String plat = call.argument("platform");
                        SharedPreferences.Editor e = pref().edit();
                        e.putBoolean(plat + "_enabled",   (Boolean) call.argument("enabled"));
                        e.putFloat (plat + "_min_price",  ((Number) call.argument("minPrice")).floatValue());
                        e.putFloat (plat + "_max_price",  ((Number) call.argument("maxPrice")).floatValue());
                        e.putFloat (plat + "_min_km",     ((Number) call.argument("minKm")).floatValue());
                        e.putFloat (plat + "_max_km",     ((Number) call.argument("maxKm")).floatValue());
                        e.putString(plat + "_ride_types", call.argument("rideTypes") != null
                                ? (String) call.argument("rideTypes") : "");
                        e.apply();
                        result.success(null);
                        break;

                    case "saveGlobalSettings":
                        SharedPreferences.Editor ge = pref().edit();
                        ge.putBoolean("auto_start_on_boot", (Boolean) call.argument("autoStart"));
                        ge.putBoolean("night_mode",         (Boolean) call.argument("nightMode"));
                        ge.putBoolean("sound_on_accept",    (Boolean) call.argument("soundOnAccept"));
                        ge.putBoolean("surge_auto_accept",  (Boolean) call.argument("surgeAccept"));
                        ge.apply();
                        result.success(null);
                        break;

                    case "saveLocations":
                        pref().edit()
                            .putString ("saved_locations",         (String)  call.argument("locations"))
                            .putBoolean("location_filter_enabled", (Boolean) call.argument("locationFilterEnabled"))
                            .apply();
                        result.success(null);
                        break;

                    case "updateDriverLocation":
                        pref().edit()
                            .putFloat("driver_lat", ((Number) call.argument("lat")).floatValue())
                            .putFloat("driver_lng", ((Number) call.argument("lng")).floatValue())
                            .apply();
                        result.success(null);
                        break;

                    case "isAccessibilityEnabled":
                        result.success(isAccessibilityOn());
                        break;

                    case "hasOverlayPermission":
                        result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.M
                                || Settings.canDrawOverlays(this));
                        break;

                    case "openAccessibilitySettings":
                        startActivity(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS));
                        result.success(null);
                        break;

                    case "openOverlayPermission":
                        startActivity(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:" + getPackageName())));
                        result.success(null);
                        break;

                    case "getSettings":
                        result.success(buildSettingsMap());
                        break;

                    default:
                        result.notImplemented();
                }
            });

        new EventChannel(fe.getDartExecutor().getBinaryMessenger(), EC)
            .setStreamHandler(new EventChannel.StreamHandler() {
                @Override public void onListen(Object a, EventChannel.EventSink sink) {
                    logSink = sink;
                    IntentFilter f = new IntentFilter();
                    f.addAction("com.ridebot.LOG_UPDATE");
                    f.addAction("com.ridebot.SERVICE_STATUS");
                    logReceiver = new BroadcastReceiver() {
                        @Override public void onReceive(Context c, Intent i) {
                            if (logSink == null) return;
                            Map<String, Object> ev = new HashMap<>();
                            ev.put("type", i.getStringExtra("type") != null ? i.getStringExtra("type") : "info");
                            ev.put("msg",  i.getStringExtra("msg")  != null ? i.getStringExtra("msg")  : "");
                            ev.put("time", i.getLongExtra("time", 0));
                            logSink.success(ev);
                        }
                    };
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(logReceiver, f, Context.RECEIVER_NOT_EXPORTED);
                    } else {
                        registerReceiver(logReceiver, f);
                    }
                }
                @Override public void onCancel(Object a) {
                    logSink = null;
                    try { if (logReceiver != null) unregisterReceiver(logReceiver); } catch (Exception ignored) {}
                }
            });
    }

    private boolean isAccessibilityOn() {
        AccessibilityManager am = (AccessibilityManager) getSystemService(ACCESSIBILITY_SERVICE);
        List<AccessibilityServiceInfo> list = am.getEnabledAccessibilityServiceList(
                AccessibilityServiceInfo.FEEDBACK_ALL_MASK);
        for (AccessibilityServiceInfo info : list)
            if (info.getId().contains("ridebot")) return true;
        return false;
    }

    private SharedPreferences pref() {
        return getSharedPreferences(P, MODE_PRIVATE);
    }

    private Map<String, Object> buildSettingsMap() {
        SharedPreferences p = pref();
        Map<String, Object> m = new HashMap<>();
        m.put("automation_enabled",      p.getBoolean("automation_enabled", false));
        m.put("auto_start_on_boot",      p.getBoolean("auto_start_on_boot", false));
        m.put("night_mode",              p.getBoolean("night_mode", false));
        m.put("sound_on_accept",         p.getBoolean("sound_on_accept", true));
        m.put("surge_auto_accept",       p.getBoolean("surge_auto_accept", true));
        m.put("location_filter_enabled", p.getBoolean("location_filter_enabled", false));
        m.put("saved_locations",         p.getString ("saved_locations", "[]"));
        for (String pl : new String[]{"rapido","ola","uber"}) {
            m.put(pl+"_enabled",    p.getBoolean(pl+"_enabled",   false));
            m.put(pl+"_min_price",  p.getFloat  (pl+"_min_price", 50f));
            m.put(pl+"_max_price",  p.getFloat  (pl+"_max_price", 3000f));
            m.put(pl+"_min_km",     p.getFloat  (pl+"_min_km",    0f));
            m.put(pl+"_max_km",     p.getFloat  (pl+"_max_km",    200f));
            m.put(pl+"_ride_types", p.getString (pl+"_ride_types",""));
        }
        return m;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try { if (logReceiver != null) unregisterReceiver(logReceiver); } catch (Exception ignored) {}
    }
}
