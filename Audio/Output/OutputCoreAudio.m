//
//  OutputCoreAudio.m
//  Cog
//
//  Created by Vincent Spader on 8/2/05.
//  Copyright 2005 Vincent Spader. All rights reserved.
//

#import "OutputCoreAudio.h"
#import "OutputNode.h"

@implementation OutputCoreAudio

- (id)initWithController:(OutputNode *)c
{
	self = [super init];
	if (self)
	{
		outputController = c;
		outputUnit = NULL;

		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.outputDevice" options:0 context:NULL];
	}
	
	return self;
}

static OSStatus Sound_Renderer(void *inRefCon,  AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp  *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList  *ioData)
{
	OutputCoreAudio *output = (OutputCoreAudio *)inRefCon;
	OSStatus err = noErr;
	void *readPointer = ioData->mBuffers[0].mData;
	
	int amountToRead, amountRead;

	if ([output->outputController shouldContinue] == NO)
	{
        AudioOutputUnitStop(output->outputUnit);
//		[output stop];
		
		return err;
	}
	
	amountToRead = inNumberFrames*(output->deviceFormat.mBytesPerPacket);
	amountRead = [output->outputController readData:(readPointer) amount:amountToRead];

	if ((amountRead < amountToRead) && [output->outputController endOfStream] == NO) //Try one more time! for track changes!
	{
		int amountRead2; //Use this since return type of readdata isnt known...may want to fix then can do a simple += to readdata
		amountRead2 = [output->outputController readData:(readPointer+amountRead) amount:amountToRead-amountRead];
		amountRead += amountRead2;
	}
	
	ioData->mBuffers[0].mDataByteSize = amountRead;
	ioData->mBuffers[0].mNumberChannels = output->deviceFormat.mChannelsPerFrame;
	ioData->mNumberBuffers = 1;
	
	return err;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"values.outputDevice"]) {

		NSDictionary *device = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey:@"outputDevice"];

		NSNumber *deviceID = [device objectForKey:@"deviceID"];
		
		[self setOutputDevice:[deviceID longValue]];
	}
}

- (BOOL)setOutputDevice:(AudioDeviceID)outputDevice
{
//  OSStatus					err;
//	AudioDeviceID			audioDeviceID;
//	UInt32						audioValueTranslationSize = sizeof(AudioValueTranslation);
//  UInt32						audioDeviceIDSize = sizeof(AudioDeviceID);
//	
//	AudioValueTranslation		value;
//	
//	value.mInputData = &UniqueID;
//	value.mInputDataSize = sizeof(CFStringRef);
//	value.mOutputData = &audioDeviceID;
//	value.mOutputDataSize = audioDeviceIDSize;
//	
//  AudioObjectPropertyAddress	theAddress = {	kAudioHardwarePropertyDeviceForUID,
//    kAudioObjectPropertyScopeGlobal,
//    kAudioObjectPropertyElementMaster };
//	
//	audioValueTranslationSize = sizeof(AudioValueTranslation);
//	audioDeviceIDSize = sizeof(AudioDeviceID);
//	
//  err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &theAddress, audioValueTranslationSize, &value, &audioDeviceIDSize, &audioDeviceID);
//
//  if(err) {
//    NSLog(@"ERROR GETTING AUDIO OBJECT");
//    return NO;
//  }
//  else
//    return YES;

  
  
//  OSStatus result = noErr;
//	Float32 theVolume = 0.0;
//	UInt32	theMute = 0;
//	Boolean doSetMute = false, doPrintDeviceList = false;
//	const char* theNewDefaultDeviceString = NULL;
//	Boolean didFindNewDevice = false;
//	CFStringRef theNewDefaultDeviceName = 0;
//  UInt32 thePropSize;
//	AudioDeviceID *theDeviceList = NULL;
//	UInt32 theNumDevices = 0;
//  AudioObjectPropertyAddress thePropertyAddress = { kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
//  result = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &thePropSize);
//  if (result) {
//    //printf("Error in AudioObjectGetPropertyDataSize: %d\n", result);
//    return NO;
//  }
//
//  AudioDeviceID theDefaultOutputDeviceID;
//  thePropSize = sizeof(theDefaultOutputDeviceID);
//  CFStringRef theDefaultOutputDeviceName;
//  printf("DEVICE: %u", theDefaultOutputDeviceID);
//  AudioObjectPropertyAddress thePropertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
//  
//  // get the ID of the default output device
//  result = AudioObjectGetPropertyData(kAudioObjectSystemObject, &thePropertyAddress, 0, NULL, &thePropSize, &theDefaultOutputDeviceID);
//  if (result) {
//    //printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end;
//    return NO;
//  }
//  
//  thePropSize = sizeof(CFStringRef);
//  thePropertyAddress.mSelector = kAudioObjectPropertyName;
//  thePropertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
//  thePropertyAddress.mElement = kAudioObjectPropertyElementMaster;
//  
//  // get the name of the default output device
//  result = AudioObjectGetPropertyData(theDefaultOutputDeviceID, &thePropertyAddress, 0, NULL, &thePropSize, &theDefaultOutputDeviceName);
//  if (result) {
//    //printf("Error in AudioObjectGetPropertyData: %d\n", result); goto end;
//    return NO;
//  }
//  
//  const char* theDefaultOutputDeviceString = CFStringGetCStringPtr(theDefaultOutputDeviceName, CFStringGetSystemEncoding());
  
  return YES;
  // Set the output device
	AudioDeviceID deviceID = outputDevice; //XXX use default if null
	OSStatus err;
	
	if (outputDevice == -1) {
		NSLog(@"DEVICE IS -1");
		UInt32 size = sizeof(AudioDeviceID);
		err = AudioHardwareGetProperty(kAudioHardwarePropertyDefaultOutputDevice,
									  &size,
									  &deviceID);
								
		if (err != noErr) {
			NSLog(@"THERES NO DEFAULT OUTPUT DEVICE");
			
			return NO;
		}
	}

	printf("DEVICE: %i\n", deviceID);
	
	err = AudioUnitSetProperty(outputUnit,
							  kAudioOutputUnitProperty_CurrentDevice, 
							  kAudioUnitScope_Output, 
							  0, 
							  &deviceID, 
							  sizeof(AudioDeviceID));
	
	if (err != noErr) {
		NSLog(@"THERES NO OUTPUT DEVICE!!!!!! %i", err);
		
		return NO;
	}
	
	return YES;
}

- (BOOL)setup
{
	if (outputUnit)
		[self stop];
	
	ComponentDescription desc;  
	OSStatus err;
	
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_DefaultOutput;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	Component comp = FindNextComponent(NULL, &desc);  //Finds an component that meets the desc spec's
	if (comp == NULL)
		return NO;
	
	err = OpenAComponent(comp, &outputUnit);  //gains access to the services provided by the component
	if (err)
		return NO;
	
	// Initialize AudioUnit 
	err = AudioUnitInitialize(outputUnit);
	if (err != noErr)
		return NO;

	// Setup the output device before mucking with settings
	NSDictionary *device = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] objectForKey:@"outputDevice"];
	if (device) {
		BOOL ok = [self setOutputDevice:[[device objectForKey:@"deviceID"] longValue]];
		if (!ok) {
			//Ruh roh.
			[self setOutputDevice: -1];
			
			[[[NSUserDefaultsController sharedUserDefaultsController] defaults] removeObjectForKey:@"outputDevice"];
		}
	}
	else {
		[self setOutputDevice: -1];
	}
	
	UInt32 size = sizeof (AudioStreamBasicDescription);
	Boolean outWritable;
	//Gets the size of the Stream Format Property and if it is writable
	AudioUnitGetPropertyInfo(outputUnit,  
							 kAudioUnitProperty_StreamFormat,
							 kAudioUnitScope_Output, 
							 0, 
							 &size, 
							 &outWritable);
	//Get the current stream format of the output
	err = AudioUnitGetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Output,
								0,
								&deviceFormat,
								&size);
	
	if (err != noErr)
		return NO;
	
	// change output format...
	
	deviceFormat.mChannelsPerFrame = 2; // HACK: Force stereo. This breaks surround, but surround is likely busted anyways because there isn't a correct channel mapping.
	///Seems some 3rd party devices return incorrect stuff...or I just don't like noninterleaved data.
	deviceFormat.mFormatFlags &= ~kLinearPCMFormatFlagIsNonInterleaved;
//	deviceFormat.mFormatFlags &= ~kLinearPCMFormatFlagIsFloat;
//	deviceFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger;
	deviceFormat.mBytesPerFrame = deviceFormat.mChannelsPerFrame*(deviceFormat.mBitsPerChannel/8);
	deviceFormat.mBytesPerPacket = deviceFormat.mBytesPerFrame * deviceFormat.mFramesPerPacket;
	
	err = AudioUnitSetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Output,
								0,
								&deviceFormat,
								size);
	
	//Set the stream format of the output to match the input
	err = AudioUnitSetProperty (outputUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Input,
								0,
								&deviceFormat,
								size);
	
	//setup render callbacks
	renderCallback.inputProc = Sound_Renderer;
	renderCallback.inputProcRefCon = self;
	
	AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &renderCallback, sizeof(AURenderCallbackStruct));	
	
	[outputController setFormat:&deviceFormat];
	
	return (err == noErr);	
}

- (void)setVolume:(double)v
{
	AudioUnitSetParameter (outputUnit,
							kHALOutputParam_Volume,
							kAudioUnitScope_Global,
							0,
							v * 0.01f,
							0);
}	

- (void)start
{
	AudioOutputUnitStart(outputUnit);
}

- (void)stop
{
	if (outputUnit)
	{
        AudioOutputUnitStop(outputUnit);
		AudioUnitUninitialize (outputUnit);
		CloseComponent(outputUnit);
		outputUnit = NULL;
	}
}

- (void)dealloc
{
	[self stop];
	
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.outputDevice"];

	[super dealloc];
}

- (void)pause
{
	AudioOutputUnitStop(outputUnit);
}

- (void)resume
{
	OSStatus err = AudioOutputUnitStart(outputUnit);
}

@end
