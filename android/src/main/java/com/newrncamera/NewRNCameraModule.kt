package com.newrncamera

import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerModule

class NewRNCameraModule(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context)  {
  @ReactMethod
  fun capture(viewTag: Int, promise: Promise) {
    val uiManager = context.getNativeModule(UIManagerModule::class.java)
    context.runOnUiQueueThread {
      val view = uiManager?.resolveView(viewTag) as NewRNCameraView
      view.capture(promise)
    }
  }

  override fun getName(): String {
    return NAME
  }

  companion object {
    private val NAME = "NewRNCameraModule"
  }

}
