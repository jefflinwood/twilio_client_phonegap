# Twilio Client Phonegap plugins for iOS and Android

These are Phonegap plugins that expose the same JS API as Twilio Client for web as much as possible, meaning you should be able to use the same Twilio Client code from your web application inside of your Phonegap application with few if any modifications. 

# PhoneGap Overview

- Install the most recent version of the PhoneGap (as of this writing, 3.1.0) tools  - http://phonegap.com/ 
- Install plugman - https://github.com/apache/cordova-plugman

# iOS

##Instructions

```
 plugman install --platform ios --project platforms/ios --plugin https://github.com/jefflinwood/twilio_client_phonegap.git

```



# Android

## Instructions

```
plugman install --platform android --project platforms/android --plugin https://github.com/jefflinwood/twilio_client_phonegap.git

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

