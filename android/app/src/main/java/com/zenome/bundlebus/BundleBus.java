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

import android.content.Context;
import android.content.res.AssetManager;
import android.support.annotation.NonNull;
import android.support.annotation.VisibleForTesting;
import android.util.Log;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.JavaScriptModule;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.zenome.bundlebus.NetAPI.BundleInfo;
import com.zenome.bundlebus.NetAPI.UpdateBundle;
import com.zenome.bundlebus.NetAPI.UpdateBundleResp;
import com.zenome.bundlebus.NetAPI.UpdateResp;
import com.zenome.bundlebus.NetAPI.UpdateService;
import com.zenome.bundlebus.NetAPI.UpdateUpdate;
import com.zenome.bundlebus.Updater.Updater;
import com.zenome.bundlebus.Updater.UpdaterFactory;

import org.apache.commons.compress.archivers.ArchiveException;
import org.apache.commons.compress.utils.IOUtils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import okhttp3.Headers;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.ResponseBody;
import okhttp3.logging.HttpLoggingInterceptor;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;
import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;
import retrofit2.converter.protobuf.ProtoConverterFactory;

public class BundleBus {
  private static final String TAG = "BundleBus";

  private static final String HEADER_FILENAME = "filename";

  private static BundleBus mInstance = new BundleBus();

  private Context mContext = null;
  private String mNativeAppVersion = "";
  private String mServerAddr = "http://localhost:3000";
  private String mAppKey = "";

  private Retrofit mRetrofit = null;
  private Map<String, BundleInfo> mBundleMap = null;

  public static synchronized BundleBus Get() {
    return mInstance;
  }

  public boolean isInitialized() {
    return (mContext != null);
  }

  public void init(@NonNull Context aContext,
                   @NonNull String aNativeAppVersion,
                   @NonNull String aAppKey,
                   @NonNull String aServerAddrWithPort) {
    mContext = aContext;
    Settings.Get().init(mContext);
    mAppKey = aAppKey;
    mNativeAppVersion = aNativeAppVersion;
    mServerAddr = aServerAddrWithPort;
    mBundleMap = new HashMap<>();

    // For http body log
    HttpLoggingInterceptor logging = new HttpLoggingInterceptor();
    logging.setLevel(HttpLoggingInterceptor.Level.BODY);
    OkHttpClient client = new OkHttpClient.Builder().addInterceptor(logging).build();

    mRetrofit = new Retrofit.Builder()
        .baseUrl(mServerAddr)
        .client(client)
        .addConverterFactory(ProtoConverterFactory.create())
        .addConverterFactory(GsonConverterFactory.create())
        .build();

    useDownloadedBundleIfExist(mAppKey);
  }

  public void useDownloadedBundleIfExist(String aAppKey) {
    String readyFilePath = Util.getAppReadyFolder(mContext, aAppKey) + Settings.Get().getBundleName();
    File readyBundle = new File(readyFilePath);
    if (readyBundle.exists()) {
      try {
        Util.moveFileFolder(Util.getAppReadyFolder(mContext, aAppKey), Util.getAppUseFolder(mContext, aAppKey));
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
  }

  public String getValidBundlePath(String aAppKey) {
    String bundlePath = getBundlePath(aAppKey);
    File bundle = new File(bundlePath);
    if (bundle.exists()) {
      Log.d(TAG, "ValidBundlePath : " + bundlePath);
      return bundlePath;
    }

    // Copy the initial asset://bundle files to bundlePath
    Log.d(TAG, "Nothing is in " + bundlePath);
    return null;
  }

  public String getBundlePath(String aAppKey) {
    return getAbsoluteBundlePath(aAppKey);// + Settings.Get().getBundleName(); // BundleBusConstants.INSTALLED_BUNDLE_NAME;
  }

  public void silentUpdate(final String aAppKey, final IUpdateListener aListener) {
    checkForUpdates(aAppKey, new ICheckUpdateListener() {
      @Override
      public void onCheckUpdateSuccess(String aActionType) {
        update(aAppKey, aListener);
      }

      @Override
      public void onCheckUpdateFailed(int aErrorCode, String aReason) {
        aListener.onUpdateFailed(aErrorCode, aReason);
      }
    });
  }

  public boolean checkForUpdates(final String aAppKey, final ICheckUpdateListener aListener) {
    if (aListener == null) {
      return false;
    }

    // SharedPreference에서 App 정보를 가져온다
    // 아무런 정보가 없다면 Default 값을 보내고 최신 버전을 받는다
    // Bundle Version
    // Native Version
    // Build ID
    // Timestamp
    UpdateService service = mRetrofit.create(UpdateService.class);
    UpdateUpdate updateUpdate = new UpdateUpdate(aAppKey,
        mNativeAppVersion,
        Settings.Get().getBundleVersion(),
        Settings.Get().getTimeStamp());
    Call<UpdateResp> call = service.update(updateUpdate);

    call.enqueue(new Callback<UpdateResp>() {
      @Override
      public void onResponse(Call<UpdateResp> call, Response<UpdateResp> response) {
        if (response.body() == null) {
          aListener.onCheckUpdateFailed(-1, "Body is null");
          return;
        }

        UpdateResp resp = response.body();
        if (resp.getStatus() != 0) {
          aListener.onCheckUpdateFailed(resp.getStatus(), resp.getMessage());
          return;
        }

        BundleInfo info = resp.getBundleInfo();
        mBundleMap.put(aAppKey, info);
        aListener.onCheckUpdateSuccess(info.getAction());
      }

      public void onFailure(Call<UpdateResp> call, Throwable t) {
        Log.d(TAG, "onFailure called");
        // Log.d(TAG, t.printStackTrace());
        t.printStackTrace();
        aListener.onCheckUpdateFailed(-1, t.getMessage());
      }
    });

    return true;
  }

  public boolean update(final String aAppKey, final IUpdateListener aListener) {
    if (mBundleMap.isEmpty()) {
      aListener.onUpdateFailed(-2, "It seems that you didn't run \"CheckUpdate\". Please do it first.");
      return false;
    }

    if (!mBundleMap.containsKey(aAppKey)) {
      aListener.onUpdateFailed(-3, "It seems that you didn't run \"CheckUpdate\" using this key(" + aAppKey + "). Please do it first.");
      return false;
    }

    final BundleInfo info = mBundleMap.get(aAppKey);
    UpdateService update = mRetrofit.create(UpdateService.class);
    UpdateBundle updateBundle = new UpdateBundle(aAppKey, info.getKey());
    Call<ResponseBody> call = update.bundle(updateBundle);
    call.enqueue(new Callback<ResponseBody>() {
      @Override
      public void onResponse(Call<ResponseBody> call, Response<ResponseBody> response) {
        if (response.body() == null) {
          aListener.onUpdateFailed(-1, "Body is null");
          return;
        }

        Log.d(TAG, "****** contentType : " + response.body().contentType());
        if (!response.body().contentType().toString().equals("application/octet-stream")) {
          // Error response as json type.
          aListener.onUpdateFailed(-4, "???");
          return;
        }

        if(!update(aAppKey, info, response)) {
          // Remove next folder
          try {
            Util.removeFileFolderRecursive(Util.getAppDownloadFolder(mContext, aAppKey));
          } catch (IOException e) {
            e.printStackTrace();
          }
          aListener.onUpdateFailed(-5, "Failed to update the bundle file.");
        }

        // Update sharedPreference
        Settings.Get().setTimeStamp(info.getKey());
        Settings.Get().setBundleVersion(info.getAppVersion());
        Settings.Get().setBundleName(info.getKey() + ".bundle");
        aListener.onUpdateSuccess(aAppKey);
      }

      public void onFailure(Call<ResponseBody> call, Throwable t) {
        Log.d(TAG, "onFailure called");
        // Log.d(TAG, t.printStackTrace());
        t.printStackTrace();
        aListener.onUpdateFailed(-1, t.getMessage());
      }
    });

    return true;
  }

  private String parseFileNameFromHeader(Headers aHeaders) {
    String filename = "";
    String disposition = aHeaders.get("Content-Disposition");
    if (disposition.length() == 0) {
      return filename;
    }

    int i = disposition.indexOf(HEADER_FILENAME);
    if (i == -1) {
      return filename;
    }

    filename = disposition.substring(i + HEADER_FILENAME.length()).replace("=", "").replace("\"", "");
    return filename;
  }

  private boolean update(String aAppKey, BundleInfo aInfo, Response<ResponseBody> aResponse) {
    String deliveredFileName = parseFileNameFromHeader(aResponse.headers());
    if (deliveredFileName.length() == 0) {
      Log.d(TAG, "Filename length is 0.");
      return false;
    }

    String filename = getAbsoluteDownloadPath(deliveredFileName);

    if (!downloadFile(aResponse.body(), filename)) {
      return false;
    }

    String readyDir = Util.getAppDownloadFolder(mContext, aAppKey);
    if (!unzipFile(filename, readyDir)) {
      return false;
    }

    Updater updater = UpdaterFactory.create(
        mContext,
        deliveredFileName,
        aAppKey,
        aInfo);

    return updater.doUpdate();
  }

  private boolean unzipFile(String aFilename, String aOutputDir) {
    File wholeTarFile = new File(aFilename);
    String unzipFilePath = aFilename.substring(0, aFilename.length() - 3);  // To remove .gz
    File unZipFile = new File(unzipFilePath);
    File outputDir = new File(aOutputDir);
    try {
      if (!Util.unZip(wholeTarFile, unZipFile)) {
        return false;
      }

      Util.unTar(unZipFile, outputDir);
    } catch (IOException e) {
      e.printStackTrace();
      return false;
    } catch (ArchiveException e) {
      e.printStackTrace();
      return false;
    }

    return true;
  }

  private boolean downloadFile(ResponseBody aBody, String aFilename) {
    File wholeTarFile = new File(aFilename);

    InputStream inputStream = null;
    OutputStream outputStream = null;

    try {
      byte[] fileReader = new byte[4096];

      long fileSize = aBody.contentLength();
      long fileSizeDownload = 0;

      inputStream = aBody.byteStream();
      outputStream = new FileOutputStream(wholeTarFile);

      while(true) {
        int read = inputStream.read(fileReader);

        if (read == -1) {
          break;
        }

        outputStream.write(fileReader, 0, read);
        fileSizeDownload += read;
        Log.d(TAG, "file download : " + ((float)fileSizeDownload / fileSize) * 100 + "%");
      }
    } catch (IOException e) {
      Log.e(TAG, "Error : " + e.getMessage());
      return false;
    }
    return true;
  }

  private String getAbsoluteDownloadPath(String aFilename) {
    return mContext.getExternalCacheDir() + File.separator + aFilename + ".tar.gz";
  }

  private String getAbsoluteBundlePath(String aAppKey) {
    String bundleName = Settings.Get().getBundleName();
    if (bundleName.isEmpty()) {
      return "";
    }

    return Util.getAppUseFolder(mContext, aAppKey) + bundleName;
//    return Util.getAppUseFolder(mContext, aAppKey);
  }
}
