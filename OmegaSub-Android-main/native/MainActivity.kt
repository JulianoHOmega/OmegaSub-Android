package com.omegasub.omegasub_android

import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val executor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "omegasub/python")
            .setMethodCallHandler { call, result ->
                if (call.method != "search" && call.method != "download") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val arg = call.arguments as? String
                if (arg == null) {
                    result.error("ARG", "Argumento inválido", null)
                    return@setMethodCallHandler
                }
                executor.execute {
                    try {
                        if (!Python.isStarted()) Python.start(AndroidPlatform(applicationContext))
                        val module = Python.getInstance().getModule("omegasub_local")
                        val value = if (call.method == "search") {
                            module.callAttr("search", arg).toString()
                        } else {
                            module.callAttr("download", arg).toJava(ByteArray::class.java)
                        }
                        runOnUiThread { result.success(value) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("PYTHON", e.message ?: e.javaClass.simpleName, null) }
                    }
                }
            }
    }

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}
