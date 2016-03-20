//
//  TCPlugin.h
//  Twilio Client plugin for PhoneGap
//
//  Copyright 2012 Stevie Graham.
//

#import <Foundation/Foundation.h>
#import "TwilioClient.h"

#import <Cordova/CDV.h>


@interface TCPlugin : CDVPlugin <TCDeviceDelegate, TCConnectionDelegate> { }

# pragma mark device delegate method
-(void)device:(TCDevice *)device didStopListeningForIncomingConnections:(NSError *)error;
-(void)device:(TCDevice*)device didReceiveIncomingConnection:(TCConnection*)connection;
-(void)device:(TCDevice *)device didReceivePresenceUpdate:(TCPresenceEvent *)presenceEvent;
-(void)deviceDidStartListeningForIncomingConnections:(TCDevice*)device;
-(void)deviceStatus:(CDVInvokedUrlCommand*)command;

# pragma mark connection delegate methods
-(void)connection:(TCConnection*)connection didFailWithError:(NSError*)error;
-(void)connectionDidStartConnecting:(TCConnection*)connection;
-(void)connectionDidConnect:(TCConnection*)connection;
-(void)connectionDidDisconnect:(TCConnection*)connection;
-(void)connectionStatus:(CDVInvokedUrlCommand*)command;
-(void)connectionParameters:(CDVInvokedUrlCommand*)command;

# pragma mark javascript mapper methods
-(void)deviceSetup:(CDVInvokedUrlCommand*)command;
-(void)connect:(CDVInvokedUrlCommand*)command;
-(void)disconnectAll:(CDVInvokedUrlCommand*)command;
-(void)acceptConnection:(CDVInvokedUrlCommand*)command;
-(void)disconnectConnection:(CDVInvokedUrlCommand*)command;
-(void)rejectConnection:(CDVInvokedUrlCommand*)command;
-(void)muteConnection:(CDVInvokedUrlCommand*)command;
-(void)sendDigits:(CDVInvokedUrlCommand*)command;
-(void)hasNotificationPermission:(CDVInvokedUrlCommand*)command;
-(void)promptForNotificationPermission:(CDVInvokedUrlCommand*)command;
-(void)showNotification:(CDVInvokedUrlCommand*)command;
-(void)cancelNotification:(CDVInvokedUrlCommand*)command;
-(void)setSpeaker:(CDVInvokedUrlCommand*)command;

@end