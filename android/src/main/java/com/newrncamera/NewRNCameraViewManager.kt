package com.newrncamera

import android.content.Context
import com.facebook.react.uimanager.ViewGroupManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp


class NewRNCameraViewManager(context: Context) : ViewGroupManager<NewRNCameraView>() {
  override fun getName() = "NewRNCameraView"

  override fun createViewInstance(reactContext: ThemedReactContext): NewRNCameraView {
    return NewRNCameraView(reactContext)
  }

  @ReactProp(name = "cameraFacing")
  fun setCameraType(view: NewRNCameraView?, type: String) {
    view?.setCameraType(type);
  }

  @ReactProp(name = "torch")
  fun setTorchMode(view: NewRNCameraView?, flashMode: String) {
    view?.setTorch(flashMode);
  }

  @ReactProp(name = "zoom")
  fun setZoom(view: NewRNCameraView?, zoom: Float) {
    view?.setZoom(zoom);
  }

}
