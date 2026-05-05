package inc.imalpha.eduforge

import android.content.Context
import android.util.Log
import com.myscript.certificate.MyCertificate
import com.myscript.iink.ContentPackage
import com.myscript.iink.Engine
import com.myscript.iink.MimeType
import com.myscript.iink.PointerType
import com.myscript.iink.IRenderTarget
import com.myscript.iink.Renderer
import com.myscript.iink.graphics.ICanvas
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray
import java.io.File
import java.util.EnumSet

class MyScriptBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "inc.imalpha.eduforge/myscript"
        private const val TAG = "MyScriptBridge"
    }

    private val scope = CoroutineScope(Dispatchers.Main)

    // Not lazy — initialise on first use and log any failure explicitly.
    private var _engine: Engine? = null

    private fun getEngine(): Engine {
        _engine?.let { return it }
        Log.d(TAG, "Initialising iink Engine…")
        val certBytes = MyCertificate.getBytes()
        Log.d(TAG, "Certificate: ${certBytes.size} bytes, first=${certBytes[0]}, last=${certBytes[certBytes.size-1]}")
        val eng = Engine.create(certBytes)
        val conf = eng.configuration
        val searchPath = "zip://${context.packageCodePath}!/assets/conf"
        Log.d(TAG, "configuration-manager.search-path = $searchPath")
        conf.setStringArray("configuration-manager.search-path", arrayOf(searchPath))
        val tmpDir = File(context.cacheDir, "iink_tmp").also { it.mkdirs() }
        conf.setString("content-package.temp-folder", tmpDir.path)
        Log.d(TAG, "Engine ready — tmpDir = ${tmpDir.path}")
        _engine = eng
        return eng
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "recognizeStrokes" -> {
                val strokesJson = call.argument<String>("strokes") ?: run {
                    result.error("INVALID_ARG", "strokes argument is required", null)
                    return
                }
                scope.launch {
                    try {
                        val text = withContext(Dispatchers.IO) {
                            recognizeStrokes(strokesJson)
                        }
                        result.success(text)
                    } catch (t: Throwable) {
                        // Catch Throwable, not just Exception, so Java Errors are visible too.
                        Log.e(TAG, "recognizeStrokes failed: ${t.javaClass.name}: ${t.message}", t)
                        result.error("MYSCRIPT_ERROR", "${t.javaClass.simpleName}: ${t.message}", null)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun recognizeStrokes(strokesJson: String): String {
        Log.d(TAG, "recognizeStrokes start")
        val eng = getEngine()
        val displayMetrics = context.resources.displayMetrics

        val renderTarget = object : IRenderTarget {
            override fun invalidate(renderer: Renderer, layers: EnumSet<IRenderTarget.LayerType>) {}
            override fun invalidate(renderer: Renderer, x: Int, y: Int, width: Int, height: Int, layers: EnumSet<IRenderTarget.LayerType>) {}
            override fun supportsOffscreenRendering(): Boolean = false
            override fun getPixelDensity(): Float = 1f
            override fun createOffscreenRenderSurface(width: Int, height: Int, alphaOnly: Boolean): Int = 0
            override fun releaseOffscreenRenderSurface(offscreenID: Int) {}
            override fun createOffscreenRenderCanvas(offscreenID: Int): ICanvas? = null
        }

        val renderer = eng.createRenderer(displayMetrics.xdpi, displayMetrics.ydpi, renderTarget)
        renderer.setViewOffset(0f, 0f)
        renderer.setViewScale(1f)

        val editor = eng.createEditor(renderer)
        editor.setViewSize(2000, 3000)

        val tempFile = File(context.cacheDir, "ms_ocr_${System.currentTimeMillis()}.iink")
        var pkg: ContentPackage? = null
        return try {
            pkg = eng.createPackage(tempFile)
            Log.d(TAG, "Package created")
            val part = pkg.createPart("Text")
            Log.d(TAG, "Part created")
            editor.setPart(part)
            Log.d(TAG, "Part set on editor")

            val strokes = JSONArray(strokesJson)
            var globalTime = 0L

            for (si in 0 until strokes.length()) {
                val stroke = strokes.getJSONObject(si)
                val points = stroke.getJSONArray("points")
                if (points.length() == 0) continue

                for (pi in 0 until points.length()) {
                    val pt = points.getJSONObject(pi)
                    val x = pt.getDouble("x").toFloat()
                    val y = pt.getDouble("y").toFloat()
                    val p = pt.getDouble("p").toFloat().coerceIn(0f, 1f)
                    val t = pt.getLong("t").let { if (it > 0L) it else globalTime }
                    globalTime = t + 15L

                    val isFirst = pi == 0
                    val isLast = pi == points.length() - 1
                    when {
                        // Single-point stroke: synthesise a tiny gap so pointerUp fires.
                        isFirst && isLast -> {
                            editor.pointerDown(x, y, t, p, PointerType.PEN, si)
                            editor.pointerUp(x, y, t + 15L, p, PointerType.PEN, si)
                        }
                        isFirst -> editor.pointerDown(x, y, t, p, PointerType.PEN, si)
                        isLast  -> editor.pointerUp(x, y, t, p, PointerType.PEN, si)
                        else    -> editor.pointerMove(x, y, t, p, PointerType.PEN, si)
                    }
                }
            }

            Log.d(TAG, "All strokes submitted — waiting for idle…")
            editor.waitForIdle()
            Log.d(TAG, "Idle, exporting text…")
            val text = editor.export_(null, MimeType.TEXT)?.trim() ?: ""
            Log.d(TAG, "Export done: '${text.take(80)}'")
            text
        } finally {
            editor.setPart(null)
            editor.close()
            renderer.close()
            pkg?.close()
            tempFile.delete()
        }
    }
}
