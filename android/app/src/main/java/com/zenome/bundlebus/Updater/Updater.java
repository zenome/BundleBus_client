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

package com.zenome.bundlebus.Updater;

import android.content.Context;

import com.zenome.bundlebus.NetAPI.BundleInfo;
import com.zenome.bundlebus.Util;

import java.io.File;
import java.util.List;

public abstract class Updater {
    private static final String TAG = "Updater";

    private Context mContext = null;
    private BundleInfo mBundleInfo = null;
    private String mAppKey = "";
    private String mSourceFolder = "";
    private String mTargetFolder = "";

    public Updater(Context aContext, String aDeliveredFilename, String aAppKey, BundleInfo aInfo) {
        mContext = aContext;
        mBundleInfo = aInfo;
        mAppKey = aAppKey;

        mSourceFolder = generateSourceFolder(mAppKey, aDeliveredFilename);
        mTargetFolder = generateTargetFolder(mAppKey, aDeliveredFilename);
    }

    protected String getSourceFolder() {
        return mSourceFolder;
    }

    protected String getTargetFolder() {
        return mTargetFolder;
    }

    protected String getAppKey() {
        return mAppKey;
    }

    protected BundleInfo getBundleInfo() {
        return mBundleInfo;
    }

    protected Context getContext() {
        return mContext;
    }

    protected String generateSourceFolder(String aAppKey, String aDelveredFileName) {
        return Util.getAppDownloadFolder(getContext(), aAppKey);
    }

    protected String generateTargetFolder(String aAppKey, String aDelveredFileName) {
        return Util.getAppReadyFolder(getContext(), aAppKey);
    }

    public abstract boolean doUpdate();
}
