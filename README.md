# BundleBus client #
BundleBus client library. This library will download the newest bundle from BundleBus backend.

## How to install ##
~~~~
> npm install BundleBus-client --save
~~~~

## Usage ##
### Notice ###
Accessing the library from the javascript layer is not supported.

### Linking this library ###
#### iOS ####
will be updated soon


#### Android ####
- In `android/settings.gradle`
~~~~
...
include ':bundlebus-client'
project(':bundlebus-client').projectDir = new File(rootProject.projectDir, '../node_modules/bundlebus-client/android/app')
~~~~
- In `android/app/build.gradle`

~~~~
...
dependencies {
   ...
   // From node_modules
   compile project(':bundlebus-client')
}
~~~~

- You have to do three things in `android/app/src/main/java/com/your_app/MainApplication.java`
   - Initialize BundleBus
   - Set `AppKey` and `Server Address`
    -You can take a `AppKey` from `bundlebus register` in a terminal. Check our [bundlebus-cli](https://github.com/zenome/BundleBus-cli)
   - Return a JSBundleFile location.
  How to? Here's an example.
~~~~
  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    public ReactInstanceManager getReactInstanceManager() {
      if (!BundleBus.Get().isInitialized()) {
        BundleBus.Get().init(this.getApplication().getApplicationContext(), "0", "my_bus_ticket", "http://localhost:3000");
      }

      return super.getReactInstanceManager();
    }

    @Override
    protected boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected String getJSBundleFile() {
      return BundleBus.Get().getValidBundlePath("my_bus_ticket");
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new BundleBusPackage("my_bus_ticket", "http://localhost:3000")
      );
    }
  };
~~~~
- Finally, your first react-native app(bundle) should be located in `android/app/src/main/assets`
   - This bundle will be loaded at first time.
   - From then, your app will be updated based on this bundle.
   - Updated app will be located in other place. So, this bundle will not be dirty.
   

## License
The MIT License (MIT)

Copyright (c) 2016-present ZENOME, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
