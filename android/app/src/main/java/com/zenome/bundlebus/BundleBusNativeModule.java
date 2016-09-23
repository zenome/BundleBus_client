/*
 * Copyright (c) 2016-present ZENOME, Inc.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

package com.zenome.bundlebus;

import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class BundleBusNativeModule extends ReactContextBaseJavaModule {
  private final static String TAG = "BundleBusNativeModule";
  private String mNativeVersion = "0";
  private String mAppKey = "";
  private BundleBus mBundleBus = BundleBus.Get();

  public BundleBusNativeModule(ReactApplicationContext aReactContext, String aAppKey, String aServer) {
    super(aReactContext);
    mAppKey = aAppKey;
    init(aAppKey, aServer);

    mBundleBus.silentUpdate(aAppKey, new IUpdateListener() {
      @Override
      public void onUpdateSuccess(String aActionType) {
//        aSuccCallback.invoke(aActionType);
      }

      @Override
      public void onUpdateFailed(int aErrorCode, String aReason) {
//        aFailedCallback.invoke(aErrorCode, aReason);
      }
    });
  }

  @Override
  public String getName() {
    return "BundleBus";
  }

  @ReactMethod
  public void init(String aAppKey, String aServerUrl) {
    if (!mBundleBus.isInitialized()) {
      try {
        PackageInfo pInfo = this.getReactApplicationContext().getPackageManager().getPackageInfo(this.getReactApplicationContext().getPackageName(), 0);
        mNativeVersion = pInfo.versionName;
      } catch (PackageManager.NameNotFoundException e) {
        e.printStackTrace();
      }

      mBundleBus.init(this.getReactApplicationContext(), mNativeVersion, aAppKey, aServerUrl);
    }
  }

  @ReactMethod
  public boolean checkUpdate(String aAppKey, final Callback aSuccCallback, final Callback aFailedCallback) {
    return mBundleBus.checkForUpdates(aAppKey, new ICheckUpdateListener() {
      @Override
      public void onCheckUpdateSuccess(String aActionType) {
        aSuccCallback.invoke(aActionType);
      }

      @Override
      public void onCheckUpdateFailed(int aErrorCode, String aReason) {
        aFailedCallback.invoke(aErrorCode, aReason);
      }
    });
  }

  @ReactMethod
  public boolean update(String aAppKey, final Callback aSuccCallback, final Callback aFailedCallback) {
    return mBundleBus.update(aAppKey, new IUpdateListener() {
      @Override
      public void onUpdateSuccess(String aActionType) {
        aSuccCallback.invoke(aActionType);
      }

      @Override
      public void onUpdateFailed(int aErrorCode, String aReason) {
        aFailedCallback.invoke(aErrorCode, aReason);
      }
    });
  }

  @ReactMethod
  public void silentUpdate(String aAppKey, final Callback aSuccCallback, final Callback aFailedCallback) {
    mBundleBus.silentUpdate(aAppKey, new IUpdateListener() {
      @Override
      public void onUpdateSuccess(String aActionType) {
        aSuccCallback.invoke(aActionType);
      }

      @Override
      public void onUpdateFailed(int aErrorCode, String aReason) {
        aFailedCallback.invoke(aErrorCode, aReason);
      }
    });
  }
}
