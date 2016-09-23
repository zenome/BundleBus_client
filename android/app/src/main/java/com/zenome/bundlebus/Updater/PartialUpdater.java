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
import android.support.annotation.NonNull;
import android.util.Log;

import com.zenome.bundlebus.BundleBus;
import com.zenome.bundlebus.BundleBusConstants;
import com.zenome.bundlebus.NetAPI.BundleInfo;
import com.zenome.bundlebus.Settings;
import com.zenome.bundlebus.Util;

import org.bitbucket.cowwoc.diffmatchpatch.DiffMatchPatch;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.LinkedList;
import java.util.List;

public class PartialUpdater extends Updater {
    private static final String TAG = "PartialUpdater";

    private static final String RESOURCE_JSON = "resources.json";
    private static final String DATA_PATCH = "data.patch";
    private static final String RESOURCE_ADD = "add";
    private static final String RESOURCE_REMOVE = "remove";

    private String mCurrentFolder = "";

    public PartialUpdater(Context aContext, String aDeliveredFileName, String aAppKey, BundleInfo aInfo) {
        super(aContext, aDeliveredFileName, aAppKey, aInfo);
        mCurrentFolder = Util.getAppUseFolder(getContext(), this.getAppKey());
    }

    @Override
    protected String generateSourceFolder(String aAppKey, String aDeliveredFileName) {
        String appPath = aDeliveredFileName.substring(0, aDeliveredFileName.lastIndexOf(".update")) + File.separator;
        return Util.getAppDownloadFolder(this.getContext(), getAppKey()) + appPath;
    }

    @Override
    public boolean doUpdate() {
        // SourceFolder에서 bundle을 merge해야 한다
        // Resource들을 update 한다
        // download folder structure
        // {app key}
        //   ㄴ download
        //        ㄴ patch-from-.....
        //             ㅏ build_{timestamp}
        //             ㅣ  ㄴ resources
        //             ㅣ       ㄴ aaa.jpg
        //             ㅏ resource.json = {add, remove}
        //             ㄴ data.patch = diff file
        Log.d(TAG, "SourceFolder = " + this.getSourceFolder());
        Log.d(TAG, "TargetFolder = " + this.getTargetFolder());

        try {
            Util.copyFileFolder(mCurrentFolder, this.getTargetFolder());
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        ResourceInfo[] resourceInfos = null;
        String patchData = "";
        try {
            resourceInfos = (ResourceInfo[])Util.readJsonFromFile(this.getSourceFolder() + RESOURCE_JSON, ResourceInfo[].class);
            patchData = Util.readAsStringFromFile(this.getSourceFolder() + DATA_PATCH);
            manageResources(resourceInfos);
            mergePatchData(patchData);
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return false;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }

    private boolean manageResources(@NonNull ResourceInfo[] aResourceInfo) {
        if (aResourceInfo.length == 0) {
            return true;
        }

        for(int i = 0; i < aResourceInfo.length; i++) {
            try {
                if (aResourceInfo[i].getState().equals(RESOURCE_ADD)) {
                    // copy
                    Util.copyFileFolder(this.getSourceFolder() + aResourceInfo[i].contenturi,
                            this.getTargetFolder() + aResourceInfo[i].contenturi);
                } else if (aResourceInfo[i].getState().equals(RESOURCE_REMOVE)) {
                    // remove
                    Util.removeFileFolderRecursive(this.getTargetFolder() + aResourceInfo[i].contenturi);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        return true;
    }

    private boolean mergePatchData(@NonNull String aPatchData) {
        if (aPatchData.length() == 0) {
            return false;
        }

        String original = "";
        try {
            original = Util.readAsStringFromFile(mCurrentFolder + Settings.Get().getBundleName());
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        DiffMatchPatch dmp = new DiffMatchPatch();
        List<DiffMatchPatch.Patch> patch = dmp.patchFromText(aPatchData);
        Object[] patchResult = dmp.patchApply((LinkedList<DiffMatchPatch.Patch>) patch, original);
        boolean[] boolArray = (boolean[]) patchResult[1];
        if (!boolArray[0]) {
            Log.d(TAG, "Merge failed");
            return false;
        }

        try {
            Util.writeStringToFile(this.getTargetFolder() + getBundleInfo().getKey() + ".bundle", (String)patchResult[0]);
            Util.removeFileFolderRecursive(this.getTargetFolder() + Settings.Get().getBundleName());
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }

        return true;
    }
}
