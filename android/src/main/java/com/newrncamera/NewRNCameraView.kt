package com.newrncamera

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.provider.MediaStore
import android.util.DisplayMetrics
import android.util.Log
import android.view.*
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleObserver
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.uimanager.ThemedReactContext
import java.util.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min


class NewRNCameraView(context: ThemedReactContext) : FrameLayout(context), LifecycleObserver {

  companion object {
    private const val TAG = "NewRNCameraView"
    private const val RATIO_4_3_VALUE = 4.0 / 3.0
    private const val RATIO_16_9_VALUE = 16.0 / 9.0
  }

  private val currentContext: ThemedReactContext = context

  private var camera: Camera? = null
  private var preview: Preview? = null
  private var imageCapture: ImageCapture? = null
  private var viewFinder: PreviewView = PreviewView(context)
  private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
  private var cameraProvider: ProcessCameraProvider? = null
  private var currentCameraType = CameraSelector.LENS_FACING_BACK

  private fun getCurrentActivity() : Activity {
    return currentContext.currentActivity!!
  }

  init {
    viewFinder.layoutParams = LinearLayout.LayoutParams(
      LayoutParams.MATCH_PARENT,
      LayoutParams.MATCH_PARENT
    )
    installHierarchyFitter(viewFinder)
    addView(viewFinder)
  }

  override fun onAttachedToWindow() {
    super.onAttachedToWindow()
    if (hasPermissions()) {
      viewFinder.post { setupCamera() }
    }
  }

  override fun onDetachedFromWindow() {
    super.onDetachedFromWindow()
    cameraExecutor.shutdown()
    cameraProvider?.unbindAll()
  }

  // Without this, all we will see is a black view- https://github.com/facebook/react-native/issues/17968
  private fun installHierarchyFitter(view: ViewGroup) {
    if (context is ThemedReactContext) { // only react-native setup
      view.setOnHierarchyChangeListener(object : OnHierarchyChangeListener {
        override fun onChildViewRemoved(parent: View?, child: View?) = Unit
        override fun onChildViewAdded(parent: View?, child: View?) {
          parent?.measure(
            MeasureSpec.makeMeasureSpec(measuredWidth, MeasureSpec.EXACTLY),
            MeasureSpec.makeMeasureSpec(measuredHeight, MeasureSpec.EXACTLY)
          )
          parent?.layout(0, 0, parent.measuredWidth, parent.measuredHeight)
        }
      })
    }
  }

  private fun setupCamera() {
    val cameraProviderFuture = ProcessCameraProvider.getInstance(getCurrentActivity())
    cameraProviderFuture.addListener(Runnable {
      cameraProvider = cameraProviderFuture.get()

      addTouchListeners()
      bindCameraUseCases()
    }, ContextCompat.getMainExecutor(getCurrentActivity()))
  }

  @SuppressLint("ClickableViewAccessibility")
  private fun addTouchListeners() {
    // Pinch to zoom
    val scaleGestureDetector = ScaleGestureDetector(context,
      object : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
          val scale = camera?.cameraInfo?.zoomState?.value!!.zoomRatio * detector.scaleFactor
          camera?.cameraControl?.setZoomRatio(scale)
          return true
        }
      })

    viewFinder.setOnTouchListener { view, event ->
      if (isPinchGesture(event)) {
        return@setOnTouchListener scaleGestureDetector.onTouchEvent(event)
      }
      focusOnTouchPoint(event.x, event.y)
      return@setOnTouchListener true
    }

  }

  // Quick and dirty way to determine pinch action:
  private fun isPinchGesture(event: MotionEvent): Boolean {
    return event.action != MotionEvent.ACTION_UP
  }

  private fun focusOnTouchPoint(x: Float?, y: Float?) {
    if (x === null || y === null) {
      camera?.cameraControl?.cancelFocusAndMetering()
      return
    }
    val factory = viewFinder.meteringPointFactory
    val builder = FocusMeteringAction.Builder(factory.createPoint(x, y), FocusMeteringAction.FLAG_AF or FocusMeteringAction.FLAG_AE )
    camera?.cameraControl?.startFocusAndMetering(builder.build())
  }

  // Majority of this function comes straight from Google's guide
  @SuppressLint("UnsafeOptInUsageError")
  private fun bindCameraUseCases() {
    // Get screen metrics used to setup camera for full screen resolution
    val metrics = DisplayMetrics().also { viewFinder.display.getRealMetrics(it) }
    Log.d(TAG, "Screen metrics: ${metrics.widthPixels} x ${metrics.heightPixels}")

    val screenAspectRatio = aspectRatio(metrics.widthPixels, metrics.heightPixels)
    Log.d(TAG, "Preview aspect ratio: $screenAspectRatio")

    val rotation = viewFinder.display.rotation

    // CameraProvider
    val cameraProvider = cameraProvider
      ?: throw IllegalStateException("Camera initialization failed.")

    // CameraSelector
    val cameraSelector = CameraSelector.Builder().requireLensFacing(currentCameraType).build()

    // Preview
    preview = Preview.Builder()
      // We request aspect ratio but no resolution
      .setTargetAspectRatio(screenAspectRatio)
      // Set initial target rotation
      .setTargetRotation(rotation)
      .build()

    // ImageCapture
    imageCapture = ImageCapture.Builder()
      .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
       //We request aspect ratio but no resolution to match preview config, but letting
      // CameraX optimize for whatever specific resolution best fits our use cases
      .setTargetAspectRatio(screenAspectRatio)
      // Set initial target rotation, we will have to call this again if rotation changes
      // during the lifecycle of this use case
      .setTargetRotation(rotation)
      .build()


    // Must unbind the use-cases before rebinding them
    cameraProvider.unbindAll()

    try {
      // A variable number of use-cases can be passed here -
      // camera provides access to CameraControl & CameraInfo
      val useCases = mutableListOf(preview, imageCapture)
      camera = cameraProvider.bindToLifecycle(getCurrentActivity() as AppCompatActivity, cameraSelector, *useCases.toTypedArray())
      // Attach the viewfinder's surface provider to preview use case
      preview?.setSurfaceProvider(viewFinder.surfaceProvider)
    } catch (exc: Exception) {
      Log.e(TAG, "Use case binding failed", exc)
    }
  }

  /**
   *  [androidx.camera.core.ImageAnalysisConfig] requires enum value of
   *  [androidx.camera.core.AspectRatio]. Currently it has values of 4:3 & 16:9.
   *
   *  Detecting the most suitable ratio for dimensions provided in @params by counting absolute
   *  of preview ratio to one of the provided values.
   *
   *  @param width - preview width
   *  @param height - preview height
   *  @return suitable aspect ratio
   */
  private fun aspectRatio(width: Int, height: Int): Int {
    val previewRatio = max(width, height).toDouble() / min(width, height)
    if (abs(previewRatio - RATIO_4_3_VALUE) <= abs(previewRatio - RATIO_16_9_VALUE)) {
      return AspectRatio.RATIO_4_3
    }
    return AspectRatio.RATIO_16_9
  }


  fun capture(promise: Promise) {
    // Create output options object which contains file + metadata
    val contentValues = ContentValues().apply {
      put(MediaStore.MediaColumns.DISPLAY_NAME, "IMG_" + System.currentTimeMillis())
      put(MediaStore.MediaColumns.MIME_TYPE, "image/jpg")
    }

    // Create the output file option to store the captured image in MediaStore
    val outputOptions = ImageCapture.OutputFileOptions
        .Builder(
          context.contentResolver,
          MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
          contentValues
        )
        .build()

    // Setup image capture listener which is triggered after photo has
    // been taken
    imageCapture?.takePicture(
      outputOptions, ContextCompat.getMainExecutor(getCurrentActivity()), object : ImageCapture.OnImageSavedCallback {
      override fun onError(ex: ImageCaptureException) {
        promise.reject(TAG, "takePicture failed: ${ex.message}")
      }

      override fun onImageSaved(output: ImageCapture.OutputFileResults) {
        try {
          val savedUri = output.savedUri.toString()

          val imageInfo = Arguments.createMap()
          imageInfo.putString("uri", savedUri)
          imageInfo.putInt("width", width)
          imageInfo.putInt("height", height)

          promise.resolve(imageInfo)
        } catch (ex: Exception) {
          promise.reject(TAG, "Error while reading saved photo: ${ex.message}")
        }
      }
    })
  }

  // Begin: methods exposed via manager

  fun setTorch(mode: String?) {
    val camera = camera ?: return
    when (mode) {
      "on" -> {
        camera.cameraControl.enableTorch(true)
      }
      "off" -> {
        camera.cameraControl.enableTorch(false)
      }
      else -> { // default to off
        camera.cameraControl.enableTorch(false)
      }
    }
  }

  fun setZoom(value: Float) {
    camera?.cameraControl?.setLinearZoom(min(1.0f, value))
  }

  fun setCameraType(type: String) {
    val newCameraType = when (type) {
      "front" -> CameraSelector.LENS_FACING_FRONT
      // If they try any other value, just fall back to the back camera
      else -> CameraSelector.LENS_FACING_BACK
    }
    val shouldRebindCamera = currentCameraType != newCameraType
    currentCameraType = newCameraType
    if (shouldRebindCamera) {
      bindCameraUseCases()
    }
  }

  // End: methods exposed via manager

  private fun hasPermissions(): Boolean {
    val requiredPermissions = arrayOf(Manifest.permission.CAMERA, Manifest.permission.WRITE_EXTERNAL_STORAGE)
    if (requiredPermissions.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
      }) {
      return true
    }
    return false
  }
}
