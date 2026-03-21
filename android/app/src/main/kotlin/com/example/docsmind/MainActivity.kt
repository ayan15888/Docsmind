package com.example.docsmind

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.*
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import java.io.File

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "DocsMind_OpenCV"
        private const val CHANNEL = "docsmind/opencv_document"
    }

    private var opencvLoaded = false
    private var opencvVersion = "unknown"
    private var opencvLoadError: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Log.d(TAG, "========================================")
        Log.d(TAG, "  DocsMind: Initializing OpenCV...")
        Log.d(TAG, "========================================")

        val startTime = System.currentTimeMillis()

        // Step 1: Load the C++ shared runtime FIRST (required by OpenCV)
        try {
            System.loadLibrary("c++_shared")
            Log.d(TAG, "✅ libc++_shared loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "⚠️ libc++_shared manual load failed: ${e.message}")
        }

        // Step 2: Now load OpenCV
        try {
            System.loadLibrary("opencv_java4")
            opencvLoaded = true
            opencvVersion = "4.12.0"
            Log.d(TAG, "✅ libopencv_java4 loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "❌ libopencv_java4 load failed: ${e.message}", e)
            val ok = OpenCVLoader.initDebug()
            if (ok) {
                opencvLoaded = true
                opencvVersion = "4.12.0"
                Log.d(TAG, "✅ OpenCVLoader.initDebug() fallback succeeded")
            } else {
                opencvLoaded = false
                opencvLoadError = "Both manual and initDebug failed: ${e.message}"
                Log.e(TAG, "❌ All OpenCV loading methods failed")
            }
        }

        val elapsed = System.currentTimeMillis() - startTime
        Log.d(TAG, "  Initialization elapsed: ${elapsed}ms")
        Log.d(TAG, "  OpenCV Status: ${if (opencvLoaded) "CONNECTED" else "DISCONNECTED"}")
        Log.d(TAG, "========================================")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d(TAG, "[MethodChannel] Registering channel: $CHANNEL")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "[MethodChannel] Received call: ${call.method}")

                if (!opencvLoaded && call.method != "isOpenCVAvailable") {
                    result.error("OPENCV_NOT_LOADED", "OpenCV library was not loaded", null)
                    return@setMethodCallHandler
                }

                when (call.method) {
                    "isOpenCVAvailable" -> {
                        result.success(mapOf(
                            "isAvailable" to opencvLoaded,
                            "version" to if (opencvLoaded) opencvVersion else null,
                            "error" to opencvLoadError,
                            "timestamp" to System.currentTimeMillis()
                        ))
                    }

                    "detectDocumentEdges" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARG_ERROR", "path is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val t = System.currentTimeMillis()
                            val doc = detectDocument(path)
                            Log.d(TAG, "detectDocumentEdges completed in ${System.currentTimeMillis() - t}ms")
                            result.success(doc)
                        } catch (e: Exception) {
                            Log.e(TAG, "detectDocumentEdges failed", e)
                            result.error("DETECT_ERROR", e.message, null)
                        }
                    }

                    "processDocument" -> {
                        val path = call.argument<String>("path")
                        val corners = call.argument<List<List<Double>>>("corners")
                        val filter = call.argument<String>("filter") ?: "whiteboard"
                        if (path == null || corners == null || corners.size < 4) {
                            result.error("ARG_ERROR", "path or corners missing", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val t = System.currentTimeMillis()
                            val outputPath = processDocument(path, corners, filter)
                            Log.d(TAG, "processDocument completed in ${System.currentTimeMillis() - t}ms")
                            result.success(mapOf(
                                "outputPath" to outputPath,
                                "success" to true
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "processDocument failed", e)
                            result.error("PROCESS_ERROR", e.message, null)
                        }
                    }

                    "applyFilter" -> {
                        val path = call.argument<String>("path")
                        val filter = call.argument<String>("filter") ?: "color"
                        if (path == null) {
                            result.error("ARG_ERROR", "path is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val outputPath = applyImageFilter(path, filter)
                            result.success(mapOf("outputPath" to outputPath, "success" to true))
                        } catch (e: Exception) {
                            Log.e(TAG, "applyFilter failed", e)
                            result.error("FILTER_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ═══════════════════════════════════════════════
    //  1. DOCUMENT DETECTION (Canny + Contour)
    // ═══════════════════════════════════════════════

    private fun detectDocument(path: String): Map<String, Any?> {
        val src = Imgcodecs.imread(path)
        if (src.empty()) {
            Log.w(TAG, "[detect] Failed to read image: $path")
            return mapOf("isDetected" to false, "corners" to emptyList<List<Double>>())
        }
        val origW = src.cols().toDouble()
        val origH = src.rows().toDouble()
        Log.d(TAG, "[detect] Image: ${origW.toInt()}x${origH.toInt()}")

        // Work on a scaled-down copy for speed (max 1000px on longest side)
        val maxDim = 1000.0
        val scale = if (origW > origH) maxDim / origW else maxDim / origH
        val workMat = if (scale < 1.0) {
            val resized = Mat()
            Imgproc.resize(src, resized, Size(origW * scale, origH * scale))
            resized
        } else {
            src.clone()
        }
        val workW = workMat.cols().toDouble()
        val workH = workMat.rows().toDouble()

        val gray = Mat()
        Imgproc.cvtColor(workMat, gray, Imgproc.COLOR_BGR2GRAY)

        // CLAHE for better local contrast (handles shadows/uneven lighting)
        val clahe = Imgproc.createCLAHE(2.0, Size(8.0, 8.0))
        clahe.apply(gray, gray)

        // Gaussian blur to reduce noise
        Imgproc.GaussianBlur(gray, gray, Size(5.0, 5.0), 0.0)

        val imgArea = workW * workH

        // Try multiple Canny thresholds: tight → medium → loose
        val thresholds = listOf(
            Pair(75.0, 200.0),  // tight: strong edges only
            Pair(40.0, 120.0),  // medium
            Pair(20.0, 80.0),   // loose: catches faint edges
        )

        var bestQuad: MatOfPoint2f? = null
        var bestArea = 0.0

        for ((low, high) in thresholds) {
            val edges = Mat()
            Imgproc.Canny(gray, edges, low, high)

            // Morphological close to bridge small gaps in edges
            val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(5.0, 5.0))
            Imgproc.morphologyEx(edges, edges, Imgproc.MORPH_CLOSE, kernel)

            // Dilate slightly to connect nearby edges
            val dilateKernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))
            Imgproc.dilate(edges, edges, dilateKernel)

            val contours = ArrayList<MatOfPoint>()
            val hierarchy = Mat()
            Imgproc.findContours(edges, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)
            Log.d(TAG, "[detect] Threshold($low,$high): ${contours.size} contours")

            // Sort by area descending
            contours.sortByDescending { Imgproc.contourArea(it) }

            for (c in contours) {
                val area = Imgproc.contourArea(c)
                if (area < imgArea * 0.03) break // too small

                val pts2f = MatOfPoint2f(*c.toArray())
                val peri = Imgproc.arcLength(pts2f, true)
                val approx = MatOfPoint2f()
                Imgproc.approxPolyDP(pts2f, approx, 0.02 * peri, true)

                val numPts = approx.total().toInt()
                if (numPts == 4 && Imgproc.isContourConvex(MatOfPoint(*approx.toArray()))) {
                    if (area > bestArea) {
                        bestQuad = approx
                        bestArea = area
                        Log.d(TAG, "[detect] ✅ Quad at threshold($low,$high): area=${area.toInt()} (${(area/imgArea*100).toInt()}%)")
                    }
                    break // found best for this threshold
                }
            }

            edges.release()
            kernel.release()
            dilateKernel.release()
            hierarchy.release()

            if (bestQuad != null && bestArea > imgArea * 0.2) break // good enough
        }

        gray.release()
        workMat.release()

        if (bestQuad == null) {
            src.release()
            Log.d(TAG, "[detect] No quadrilateral found at any threshold")
            return mapOf("isDetected" to false, "corners" to emptyList<List<Double>>())
        }

        // Map corners back to original image coordinates
        val ordered = orderPoints(bestQuad.toArray())
        val scaleBack = if (scale < 1.0) 1.0 / scale else 1.0
        val normCorners = ordered.map { p ->
            listOf(
                (p.x * scaleBack / origW).coerceIn(0.0, 1.0),
                (p.y * scaleBack / origH).coerceIn(0.0, 1.0)
            )
        }
        Log.d(TAG, "[detect] Final corners: $normCorners")

        src.release()
        return mapOf("isDetected" to true, "corners" to normCorners)
    }

    // ═══════════════════════════════════════════════
    //  2. DOCUMENT PROCESSING (Perspective + Filter)
    // ═══════════════════════════════════════════════

    private fun processDocument(path: String, corners: List<List<Double>>, filter: String): String {
        val src = Imgcodecs.imread(path)
        if (src.empty()) throw Exception("Cannot read image: $path")

        val w = src.cols().toDouble()
        val h = src.rows().toDouble()
        Log.d(TAG, "[process] Image: ${src.cols()}x${src.rows()}, filter=$filter")

        // Convert normalized corners to pixel coordinates
        val pixelCorners = corners.map { c ->
            Point(
                (if (c[0] <= 1.0) c[0] * w else c[0]),
                (if (c[1] <= 1.0) c[1] * h else c[1])
            )
        }

        // Order points: TL, TR, BR, BL
        val ordered = orderPoints(pixelCorners.toTypedArray())

        // Compute output dimensions from the corner distances
        val widthA = distance(ordered[2], ordered[3]) // BR - BL
        val widthB = distance(ordered[1], ordered[0]) // TR - TL
        val maxWidth = maxOf(widthA, widthB).toInt().coerceAtLeast(100)

        val heightA = distance(ordered[1], ordered[2]) // TR - BR
        val heightB = distance(ordered[0], ordered[3]) // TL - BL
        val maxHeight = maxOf(heightA, heightB).toInt().coerceAtLeast(100)

        Log.d(TAG, "[process] Output size: ${maxWidth}x${maxHeight}")

        // Source points (from detected corners)
        val srcPts = MatOfPoint2f(ordered[0], ordered[1], ordered[2], ordered[3])

        // Destination points (top-down rectangle)
        val dstPts = MatOfPoint2f(
            Point(0.0, 0.0),
            Point(maxWidth.toDouble(), 0.0),
            Point(maxWidth.toDouble(), maxHeight.toDouble()),
            Point(0.0, maxHeight.toDouble())
        )

        // Perspective transform with high-quality interpolation
        val perspectiveMatrix = Imgproc.getPerspectiveTransform(srcPts, dstPts)
        val warped = Mat()
        Imgproc.warpPerspective(
            src, warped, perspectiveMatrix,
            Size(maxWidth.toDouble(), maxHeight.toDouble()),
            Imgproc.INTER_LANCZOS4  // Highest quality interpolation
        )
        Log.d(TAG, "[process] Perspective warp complete (LANCZOS4)")

        // Apply enhancement filter
        val enhanced = applyEnhancement(warped, filter)
        Log.d(TAG, "[process] Enhancement filter '$filter' applied")

        // Save output at high JPEG quality
        val outputFile = File(path).parentFile!!
        val timestamp = System.currentTimeMillis()
        val outputPath = "${outputFile.absolutePath}/scanned_${timestamp}.jpg"

        val params = MatOfInt(Imgcodecs.IMWRITE_JPEG_QUALITY, 98)
        Imgcodecs.imwrite(outputPath, enhanced, params)
        Log.d(TAG, "[process] Saved to: $outputPath (quality=98)")

        // Release
        src.release()
        warped.release()
        enhanced.release()
        perspectiveMatrix.release()
        srcPts.release()
        dstPts.release()

        return outputPath
    }

    // ═══════════════════════════════════════════════
    //  3. IMAGE FILTERS
    // ═══════════════════════════════════════════════

    private fun applyEnhancement(src: Mat, filter: String): Mat {
        return when (filter) {
            "whiteboard" -> applyWhiteboardFilter(src)
            "grayscale" -> applyGrayscaleFilter(src)
            "bw" -> applyBlackWhiteFilter(src)
            "color" -> src.clone() // return as-is (color)
            else -> src.clone()
        }
    }

    private fun applyWhiteboardFilter(src: Mat): Mat {
        // Division-based whiteboard enhancement
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

        // Create a blurred version (background model)
        val blurred = Mat()
        Imgproc.GaussianBlur(gray, blurred, Size(51.0, 51.0), 0.0)

        // Divide original by background to remove shadows
        val divided = Mat()
        Core.divide(gray, blurred, divided, 255.0)

        // Normalize contrast
        Core.normalize(divided, divided, 0.0, 255.0, Core.NORM_MINMAX)

        // Sharpen slightly
        val sharpened = Mat()
        val kernel = Mat(3, 3, CvType.CV_32F)
        kernel.put(0, 0,
            0.0, -0.5, 0.0,
            -0.5, 3.0, -0.5,
            0.0, -0.5, 0.0
        )
        Imgproc.filter2D(divided, sharpened, -1, kernel)

        // Convert back to BGR for saving
        val result = Mat()
        Imgproc.cvtColor(sharpened, result, Imgproc.COLOR_GRAY2BGR)

        gray.release()
        blurred.release()
        divided.release()
        sharpened.release()
        kernel.release()

        return result
    }

    private fun applyGrayscaleFilter(src: Mat): Mat {
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

        // Histogram equalization for better contrast
        Imgproc.equalizeHist(gray, gray)

        val result = Mat()
        Imgproc.cvtColor(gray, result, Imgproc.COLOR_GRAY2BGR)

        gray.release()
        return result
    }

    private fun applyBlackWhiteFilter(src: Mat): Mat {
        val gray = Mat()
        Imgproc.cvtColor(src, gray, Imgproc.COLOR_BGR2GRAY)

        // Adaptive thresholding for clean black & white
        val thresh = Mat()
        Imgproc.adaptiveThreshold(
            gray, thresh, 255.0,
            Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
            Imgproc.THRESH_BINARY, 21, 10.0
        )

        val result = Mat()
        Imgproc.cvtColor(thresh, result, Imgproc.COLOR_GRAY2BGR)

        gray.release()
        thresh.release()
        return result
    }

    private fun applyImageFilter(path: String, filter: String): String {
        val src = Imgcodecs.imread(path)
        if (src.empty()) throw Exception("Cannot read image: $path")

        val enhanced = applyEnhancement(src, filter)

        val outputFile = File(path).parentFile!!
        val outputPath = "${outputFile.absolutePath}/filtered_${System.currentTimeMillis()}.jpg"
        Imgcodecs.imwrite(outputPath, enhanced)

        src.release()
        enhanced.release()

        return outputPath
    }

    // ═══════════════════════════════════════════════
    //  UTILITIES
    // ═══════════════════════════════════════════════

    /**
     * Order 4 points as: Top-Left, Top-Right, Bottom-Right, Bottom-Left.
     * Uses sum (x+y) for TL/BR and difference (y-x) for TR/BL.
     */
    private fun orderPoints(pts: Array<Point>): Array<Point> {
        if (pts.size != 4) return pts

        val sorted = Array(4) { Point() }

        val sums = pts.map { it.x + it.y }
        val diffs = pts.map { it.y - it.x }

        sorted[0] = pts[sums.indexOf(sums.min())]   // TL: smallest sum
        sorted[2] = pts[sums.indexOf(sums.max())]   // BR: largest sum
        sorted[1] = pts[diffs.indexOf(diffs.min())]  // TR: smallest diff
        sorted[3] = pts[diffs.indexOf(diffs.max())]  // BL: largest diff

        return sorted
    }

    private fun distance(p1: Point, p2: Point): Double {
        val dx = p1.x - p2.x
        val dy = p1.y - p2.y
        return Math.sqrt(dx * dx + dy * dy)
    }
}
