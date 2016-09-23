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
import android.content.SharedPreferences;

public class Settings {
    private SharedPreferences mSetting = null;
    private static Settings instance = new Settings();

    public static Settings Get() {
        return instance;
    }

    public Settings init(Context aContext) {
        mSetting = aContext.getSharedPreferences(BundleBusConstants.PREFERENCES, 0);
        return instance;
    }

    public void clear() {
        mSetting.edit().clear().commit();
    }

    public String getBundleVersion() {
        return mSetting.getString(BundleBusConstants.BUNDLE_VERSION, "0");
    }

    public Settings setBundleVersion(String aBundleVersion) {
        mSetting.edit().putString(BundleBusConstants.BUNDLE_VERSION, aBundleVersion).commit();
        return instance;
    }

    public String getBuildID() {
        return mSetting.getString(BundleBusConstants.BUILD_ID, "0");
    }

    public Settings setBuildID(String aBuildID) {
        mSetting.edit().putString(BundleBusConstants.BUILD_ID, aBuildID).commit();
        return instance;
    }

    public String getVersionKey() {
        return mSetting.getString(BundleBusConstants.BUNDLE_VERSION_KEY, "0");
    }

    public Settings setVersionKey(String aVersionKey) {
        mSetting.edit().putString(BundleBusConstants.BUNDLE_VERSION_KEY, aVersionKey).commit();
        return instance;
    }

    public long getTimeStamp() {
        return mSetting.getLong(BundleBusConstants.TIMESTAMP, 0L);
    }

    public Settings setTimeStamp(long aTimeStamp) {
        mSetting.edit().putLong(BundleBusConstants.TIMESTAMP, aTimeStamp).commit();
        return instance;
    }

    public String getBundleUpdateState() {
        return mSetting.getString(BundleBusConstants.BUNDLE_UPDATE_STATE, "");
    }

    public Settings setBundleUpdateState(String aState) {
        mSetting.edit().putString(BundleBusConstants.BUNDLE_UPDATE_STATE, aState).commit();
        return instance;
    }

    public Settings setBundleName(String aBundleName) {
        mSetting.edit().putString(BundleBusConstants.INSTALLED_BUNDLE_NAME, aBundleName).commit();
        return instance;
    }

    public String getBundleName() {
        return mSetting.getString(BundleBusConstants.INSTALLED_BUNDLE_NAME, "");
    }
}
