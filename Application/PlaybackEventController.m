//
//  PlaybackEventController.m
//  Cog
//
//  Created by Vincent Spader on 3/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PlaybackEventController.h"
#import "AudioScrobbler.h"
#import "PlaybackController.h"
#import "PlaylistLoader.h"
#import "PlaylistEntry.h"

@implementation PlaybackEventController

- (void)initDefaults
{
	NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:YES], @"enableAudioScrobbler",
										[NSNumber numberWithBool:NO],  @"automaticallyLaunchLastFM",
										nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
}

- (id)init
{
	self = [super init];
	if (self)
	{
		[self initDefaults];
		
		queue = [[NSOperationQueue alloc] init];
		[queue setMaxConcurrentOperationCount:1];
		
		scrobbler = [[AudioScrobbler alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[queue release];
	
	[super dealloc];
}

- (void)performPlaybackDidBeginActions:(PlaylistEntry *)pe
{
	// Race here, but the worst that could happen is we re-read the data
	if ([pe metadataLoaded] != YES) {
		[pe performSelectorOnMainThread:@selector(setMetadata:) withObject:[playlistLoader readEntryInfo:pe] waitUntilDone:YES];
	}
	
	if (NO == [pe error]) {
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
			[scrobbler start:pe];
		}
		
		// Note: We don't want to send a user notification on resume.
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    NSUserNotification *un = [[NSUserNotification alloc] init];
    un.title = @"Cog";
    un.subtitle = [NSString stringWithFormat:@"%@ - %@", [pe artist], [pe title]];
    [unc deliverNotification:un];
	}
}

- (void)performPlaybackDidPauseActions
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler pause];
	}
}

- (void)performPlaybackDidResumeActions
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler resume];
	}
}

- (void)performPlaybackDidStopActions
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"enableAudioScrobbler"]) {
		[scrobbler stop];
	}
}


- (void)awakeFromNib
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidBegin:) name:CogPlaybackDidBeginNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidPause:) name:CogPlaybackDidPauseNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidResume:) name:CogPlaybackDidResumeNotficiation object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidStop:)  name:CogPlaybackDidStopNotficiation object:nil];
}

- (void)playbackDidBegin:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidBeginActions:) object:[notification object]];
	[queue addOperation:op];
	[op release];
}

- (void)playbackDidPause:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidPauseActions) object:nil];
	[queue addOperation:op];
	[op release];
}

- (void)playbackDidResume:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidResumeActions) object:nil];
	[queue addOperation:op];
	[op release];
}

- (void)playbackDidStop:(NSNotification *)notification
{
	NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performPlaybackDidStopActions) object:nil];
	[queue addOperation:op];
	[op release];
}

@end
