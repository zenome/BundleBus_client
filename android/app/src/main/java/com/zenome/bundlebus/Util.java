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
import android.os.Environment;
import android.support.annotation.NonNull;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.stream.JsonReader;

import org.apache.commons.compress.archivers.ArchiveException;
import org.apache.commons.compress.archivers.ArchiveStreamFactory;
import org.apache.commons.compress.archivers.tar.TarArchiveEntry;
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream;
import org.apache.commons.compress.archivers.zip.ParallelScatterZipCreator;
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream;
import org.apache.commons.compress.compressors.gzip.GzipUtils;
import org.apache.commons.compress.utils.IOUtils;
import org.json.JSONObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.LinkedList;
import java.util.List;

public class Util {
    private static final String TAG = "Util";

    public static boolean unZip(@NonNull final File aGzFile, @NonNull final File aOutputFile) throws FileNotFoundException, IOException {
        Log.d(TAG, "gz filename : " + aGzFile);
        Log.d(TAG, "output file : " + aOutputFile);

        if (!GzipUtils.isCompressedFilename(aGzFile.getAbsolutePath())) {
            Log.d(TAG, "This file is not compressed file : " + aGzFile.getAbsolutePath());
            return false;
        }

        final FileInputStream fis = new FileInputStream(aGzFile);
        BufferedInputStream in = new BufferedInputStream(fis);
        FileOutputStream out = new FileOutputStream(aOutputFile);

        GzipCompressorInputStream gzIn = new GzipCompressorInputStream(in);
        final byte[] buffer = new byte[4096];
        int n = 0;

        while(-1 != (n = gzIn.read(buffer))) {
            out.write(buffer, 0, n);
        }

        out.close();
        gzIn.close();

        return true;
    }

    public static List<File> unTar(@NonNull final File tarFile, @NonNull final File outputDir) throws FileNotFoundException, IOException, ArchiveException {
//        Log.d(TAG, "tar filename : " + tarFile);
//        Log.d(TAG, "output folder : " + outputDir);

        final List<File> untaredFiles = new LinkedList<File>();
        final InputStream is = new FileInputStream(tarFile);
        final TarArchiveInputStream debInputStream =
                (TarArchiveInputStream) new ArchiveStreamFactory().createArchiveInputStream("tar", is);

        TarArchiveEntry entry = null;
        while ((entry = (TarArchiveEntry) debInputStream.getNextEntry()) != null) {
            String name = entry.getName();
            if (name.startsWith("./")) {
                name = entry.getName().substring(2);
            }

            final File outputFile = new File(outputDir, name);
            if (entry.isDirectory()) {
//                Log.d(TAG, "Attempting to write output directory " + outputFile.getAbsolutePath());
                if (!outputFile.exists()) {
                    Log.d(TAG, "Attempting to create output directory " + outputFile.getAbsolutePath());
                    if (!outputFile.mkdirs()) {
                        throw new IllegalStateException("Couldn't create directory " + outputFile.getAbsolutePath());
                    }
                }
            } else {
//                Log.d(TAG, "Creating output file " + outputFile.getAbsolutePath());
                final OutputStream outputFileStream = new FileOutputStream(outputFile);
                Log.d(TAG, "IOUtils.copy : " + IOUtils.copy(debInputStream, outputFileStream));
                outputFileStream.close();
            }

//            Log.d(TAG, "Filename : " + outputFile);
//            Log.d(TAG, "is exist : " + outputFile.exists());
            untaredFiles.add(outputFile);
        }
        debInputStream.close();

        return untaredFiles;
    }

    public static void removeFileFolderRecursive(@NonNull File aPath) throws IOException {
        if (aPath.exists()) {
            String deleteCmd = "rm -r " + aPath.getAbsolutePath();
            Runtime runtime = Runtime.getRuntime();
            runtime.exec(deleteCmd);
        }
    }

    public static void removeFileFolderRecursive(@NonNull String aAbsoultePath) throws IOException {
        File aFolder = new File(aAbsoultePath);
        removeFileFolderRecursive(aFolder);
    }

    public static void copyFileFolder(@NonNull String aSourcePath, @NonNull String aTargetPath) throws IOException {
        File source = new File(aSourcePath);
        if (source.exists()) {
            String cpCmd = "cp -R " + aSourcePath + " " + aTargetPath;
            Log.d(TAG, cpCmd);
            Runtime runtime = Runtime.getRuntime();
            runtime.exec(cpCmd);
        }
    }
    public static void moveFileFolder(@NonNull String aSourceFolderPath, @NonNull String aTargetFolderPath) throws IOException {
        File source = new File(aSourceFolderPath);
        if (source.exists()) {
            String moveCmd = "mv " + aSourceFolderPath + " " + aTargetFolderPath;
            Log.d(TAG, moveCmd);
            Runtime runtime = Runtime.getRuntime();
            runtime.exec(moveCmd);
        }
    }

    public static Object readJsonFromFile(@NonNull String aAbsolutePath, @NonNull Class aClass) throws FileNotFoundException {
        Gson gson = new Gson();
        JsonReader reader = new JsonReader(new FileReader(aAbsolutePath));
        Object object = gson.fromJson(reader, aClass);
        return object;
    }

    public static String readAsStringFromFile(@NonNull String aAbsolutePath) throws FileNotFoundException, IOException {
        final InputStream is = new FileInputStream(aAbsolutePath);
        int size = is.available();
        byte[] buffer = new byte[size];
        is.read(buffer);
        is.close();
        return new String(buffer, "UTF-8");
    }

    public static void writeStringToFile(@NonNull String aAbsolutePath, @NonNull String aData) throws IOException {
        final OutputStream is = new FileOutputStream(aAbsolutePath);
        is.write(aData.getBytes());
        is.close();
    }

    public static String getAppUseFolder(Context aContext, String aAppKey) {
        return getFolderWithStr(aContext, aAppKey, "current");
    }

    public static String getAppDownloadFolder(Context aContext, String aAppKey) {
        return getFolderWithStr(aContext, aAppKey, "download");
    }

    public static String getAppReadyFolder(Context aContext, String aAppKey) {
        return getFolderWithStr(aContext, aAppKey, "ready");
    }

    public static String getFolderWithStr(Context aContext, String aAppKey, String aFolderName) {
        return aContext.getExternalFilesDir(null) + File.separator + aAppKey + File.separator + aFolderName + File.separator;
    }

}
