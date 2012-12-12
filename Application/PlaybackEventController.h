//
//  PlaybackEventController.h
//  Cog
//
//  Created by Vincent Spader on 3/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import <Growl/GrowlApplicationBridge.h>
#import <Foundation/NSUserNotification.h>

@class PlaylistLoader;
@class AudioScrobbler;
@interface PlaybackEventController : NSObject <NSUserNotificationCenterDelegate> {
	NSOperationQueue *queue;
	
	AudioScrobbler *scrobbler;
	IBOutlet PlaylistLoader *playlistLoader;
}

@end
