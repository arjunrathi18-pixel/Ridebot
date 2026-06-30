package com.ridebot.app;
import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Intent;
import android.content.SharedPreferences;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import java.util.List;

public class RideBotAccessibilityService extends AccessibilityService {
    private static final String PREFS = "ridebot_prefs";

    @Override public void onServiceConnected() {
        super.onServiceConnected();
        AccessibilityServiceInfo info = getServiceInfo();
        if (info != null) { info.notificationTimeout = 0; setServiceInfo(info); }
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent event) {
        SharedPreferences p = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (!p.getBoolean("automation_enabled", false)) return;
        int type = event.getEventType();
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && type != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) return;
        String pkg = event.getPackageName() != null ? event.getPackageName().toString() : "";
        if (pkg.contains("rapido") && p.getBoolean("rapido_enabled", false)) tryAccept("rapido", new String[]{"ACCEPT","Accept Ride","Accept Now"}, p);
        else if ((pkg.contains("olacabs") || pkg.contains("juspay")) && p.getBoolean("ola_enabled", false)) tryAccept("ola", new String[]{"Accept","ACCEPT","Accept Booking"}, p);
        else if (pkg.contains("ubercab") && p.getBoolean("uber_enabled", false)) tryAccept("uber", new String[]{"Accept","ACCEPT","Accept trip"}, p);
    }

    private void tryAccept(String plat, String[] acceptTexts, SharedPreferences p) {
        AccessibilityNodeInfo root = getRootInActiveWindow();
        if (root == null) return;
        try {
            AccessibilityNodeInfo btn = null;
            for (String t : acceptTexts) {
                List<AccessibilityNodeInfo> nodes = root.findAccessibilityNodeInfosByText(t);
                if (nodes != null && !nodes.isEmpty()) { btn = nodes.get(0); break; }
            }
            if (btn == null) return;

            double price = scanPrice(root);
            double km = scanDist(root);
            String pickup = scanAddress(root);

            float minP = p.getFloat(plat + "_min_price", 50f);
            float maxK = p.getFloat(plat + "_max_km", 200f);
            if (price > 0 && price < minP) { log("reject", plat + " ₹"+(int)price+" < min ₹"+(int)minP); return; }
            if (km > 0 && km > maxK) { log("reject", plat + " "+km+"km > max "+maxK+"km"); return; }

            if (p.getBoolean("location_filter_enabled", false)) {
                int cnt = p.getInt("loc_count", 0);
                if (cnt > 0) {
                    boolean match = false;
                    for (int i = 0; i < cnt; i++) {
                        String key = p.getString("loc_key_" + i, "").toLowerCase().trim();
                        if (!key.isEmpty() && pickup.toLowerCase().contains(key)) { match = true; break; }
                    }
                    if (!match) { log("reject", plat + " location mismatch"); return; }
                }
            }

            if (!btn.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                AccessibilityNodeInfo par = btn.getParent();
                if (par != null) par.performAction(AccessibilityNodeInfo.ACTION_CLICK);
            }
            String name = plat.substring(0,1).toUpperCase() + plat.substring(1);
            log("accept", name + " ₹"+(int)price+" "+km+"km → ✅ ACCEPTED");
        } finally { root.recycle(); }
    }

    private double scanPrice(AccessibilityNodeInfo n) {
        if (n == null) return 0;
        CharSequence t = n.getText();
        if (t != null && t.toString().contains("₹")) return parseNum(t.toString());
        for (int i = 0; i < n.getChildCount(); i++) { double v = scanPrice(n.getChild(i)); if (v > 0) return v; }
        return 0;
    }
    private double scanDist(AccessibilityNodeInfo n) {
        if (n == null) return 0;
        CharSequence t = n.getText();
        if (t != null && t.toString().toLowerCase().endsWith("km")) return parseNum(t.toString());
        for (int i = 0; i < n.getChildCount(); i++) { double v = scanDist(n.getChild(i)); if (v > 0) return v; }
        return 0;
    }
    private String scanAddress(AccessibilityNodeInfo n) {
        if (n == null) return "";
        CharSequence t = n.getText();
        if (t != null && t.length() > 8 && t.toString().contains(",")) return t.toString();
        for (int i = 0; i < n.getChildCount(); i++) { String v = scanAddress(n.getChild(i)); if (!v.isEmpty()) return v; }
        return "";
    }
    private double parseNum(String s) {
        try { return Double.parseDouble(s.replaceAll("[^0-9.]", "")); } catch (Exception e) { return 0; }
    }
    private void log(String type, String msg) {
        Intent i = new Intent("com.ridebot.LOG_UPDATE");
        i.putExtra("type", type); i.putExtra("msg", msg); i.putExtra("time", System.currentTimeMillis());
        sendBroadcast(i);
    }
    @Override public void onInterrupt() {}
}
