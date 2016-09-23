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

import com.zenome.bundlebus.BundleBusConstants;
import com.zenome.bundlebus.NetAPI.BundleInfo;
import com.zenome.bundlebus.Util;

import java.io.File;
import java.io.IOException;

public class UpdaterFactory {
    public static Updater create(Context aContext,
                                 String aDeliveredFileName,
                                 String aAppKey,
                                 BundleInfo aInfo) {
        if(aInfo.getAction().toLowerCase().equals("download")) {
            return new FullUpdater(aContext, aDeliveredFileName, aAppKey, aInfo);
        } else if (aInfo.getAction().toLowerCase().equals("patch")) {
            return new PartialUpdater(aContext, aDeliveredFileName, aAppKey, aInfo);
        } else if (aInfo.getAction().toLowerCase().equals("noupdate")) {
            return new NoUpdater(aContext, aDeliveredFileName, aAppKey, aInfo);
        }

        return null;
    }
}
