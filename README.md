# Twilio Client Phonegap plugins for iOS and Android

These are Phonegap plugins that expose the same JS API as Twilio Client for web as much as possible, meaning you should be able to use the same Twilio Client code from your web application inside of your Phonegap application with few if any modifications. 

# iOS

##Instructions

- Follow the directions to create a new PhoneGap/Cordova iOS application.

- Follow the instructions in the Twilio iOS client quickstart, e.g. copy headers and static lib into your xcode project, link required frameworks, linker flags, etc.

- Copy the Objective-C files into the `plugins` directory of your Phonegap project, and the JavaScript file into the `www` directory.

- Add a new plugin XML item in config.xml:
    <feature name="TCPlugin">
        <param name="ios-package" value="TCPlugin" />
    </feature>

# Android

## Instructions

- Follow the directions to create a new PhoneGap/Cordova Android application.
- Download and install the Twilio Client Android SDK into your Android application project. Follow the directions in the Twilio Client for Android documentation, with two particular things to keep in mind - you will need the ACCESS_WIFI_STATE permission in your AndroidManifest.xml (the other permissions come with the PhoneGap Android starter app), and you will need to add the Twilio Service to the AndroidManifest.xml file. 
- To handle incoming calls, the Twilio Android Client SDK requires another activity (that is bundled with this plugin) be added to the AndroidManifest.xml inside the <application> tag. Add this line of code:

```
    <application>
    ....
        <activity android:name="com.phonegap.plugins.twilioclient.IncomingConnectionActivity"  android:theme="@android:style/Theme.NoDisplay"/>
    ....
    </application>
```
- Add tcPlugin.js to your application's www folder (in the assets directory)
- You need to add a notification.png file to your applications res/drawable-ldpi, res/drawable-mdpi & res/drawable-hdpi or res/drawable-xhdpi directories (depending on what resolutions you want to support).
- Copy the two plugin .java files into your application's src folder, keeping the com/phonegap/plugins/twilioclient directory structure
- Last, add the plugin to config.xml (in res/xml)

```
    <feature name="TCPlugin">
      <param name="android-package" value="com.phonegap.plugins.twilioclient.TCPlugin"/>
    </feature>
```

## Additional Features

In addition to the standard features of the Twilio Client JS Library, you can also use the included showNotification and cancelNotification functions to display a UILocalNotifcation to the user when during an incoming call while the app is running in the background:

```javascript
Twilio.Connection.showNotification("Notification Text", "notification_sound.wav");
```

```javascript
Twilio.Connection.cancelNotification();
```

You can also turn the device's speaker phone on or off during a call using the following method:

```javascript
Twilio.Connection.setSpeaker("on");
```

## Limitations

This is plugin is a first cut and should be considered alpha. Please use it and break it :) Report any issues using the Github issue tracker.

Some of the event handlers are currently no-ops because of differences between the web SDK and the iOS SDK, i.e. they both expose events the other does not, e.g. Twilio.Device.cancel is a no-op and there is no JS SDK notion of `-(void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device`, etc. 

Twilio.Connection objects are just proxy objects that delegate to the Objective-C layer.

Sounds are currently disabled and the JS methods that control them are no-ops because enabling them causes `EXC_BAD_ACCESS` errors. Will fix.

Methods that interrogate the client device or connection and return a result e.g. `Twilio.Device.status()` take a callback function with the response as the argument. Unfortunately I think this is unavoidable due to communication between the Phonegap JS and iOS layers being strictly asynchronous, e.g.

```javascript
Twilio.Device.connect(function(connection) {
    alert(connection.status());
})
```

becomes:

```javascript
Twilio.Device.connect(function(connection) {
    connection.status(function(status) { alert(status) });
})
```

Twilio Client documentation: http://www.twilio.com/docs/client/twilio-js

