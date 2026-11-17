package com.excellencecoachinghub.app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    companion object {
        private const val LABS_CHANNEL = "ech/labs"
        private const val LAB_REQUEST = 4242
        private const val UNITY_ACTIVITY = "com.unity3d.player.UnityPlayerActivity"
        // CPU architectures the embedded ECH Labs (Unity) build ships for.
        // (x86_64 emulators on Android 11+ run arm64 apps through translation and report arm64-v8a too.)
        private val UNITY_ABIS = setOf("arm64-v8a")
    }

    private var pendingLabResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // ECH Labs: the native 3D lab (Unity as a Library) runs in its own ":unity" process.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LABS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNativeAvailable" -> result.success(isUnityAvailable())
                "launch" -> {
                    if (!isUnityAvailable()) {
                        result.error("unavailable", "The 3D lab is not installed on this device", null)
                        return@setMethodCallHandler
                    }
                    if (pendingLabResult != null) {
                        result.error("busy", "A lab is already open", null)
                        return@setMethodCallHandler
                    }
                    val intent = Intent().setClassName(this, UNITY_ACTIVITY)
                    @Suppress("UNCHECKED_CAST")
                    val params = (call.arguments as? Map<String, Any?>) ?: emptyMap()
                    for ((key, value) in params) if (value != null) intent.putExtra("ech_$key", value.toString())
                    pendingLabResult = result
                    @Suppress("DEPRECATION")
                    startActivityForResult(intent, LAB_REQUEST)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isUnityAvailable(): Boolean {
        val classPresent = try { Class.forName(UNITY_ACTIVITY); true } catch (e: ClassNotFoundException) { false }
        val abiSupported = Build.SUPPORTED_ABIS.any { it in UNITY_ABIS }
        // The Unity engine must be packaged for the ABI this app process runs as. Native libraries are
        // usually loaded straight from the APK (not extracted), so look inside the installed APK(s).
        val runsArm64 = applicationInfo.nativeLibraryDir?.endsWith("arm64") == true
        val enginePresent = runsArm64 && apkContains("lib/arm64-v8a/libunity.so")
        // Unity 6.6 needs Android 8.0+; older phones use the in-app web lab instead.
        return classPresent && abiSupported && enginePresent && Build.VERSION.SDK_INT >= 26
    }

    private fun apkContains(entry: String): Boolean {
        val apks = listOfNotNull(applicationInfo.sourceDir) + (applicationInfo.splitSourceDirs?.toList() ?: emptyList())
        return apks.any { path ->
            try { java.util.zip.ZipFile(path).use { it.getEntry(entry) != null } } catch (e: Exception) { false }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == LAB_REQUEST) {
            // The lab saves results to the server itself; this is only for an instant UI update.
            pendingLabResult?.success(data?.getStringExtra("ech_result"))
            pendingLabResult = null
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Ensure the app can receive notifications when in background
    }
}
