//
//  ViewController.m
//  OpusTest
//
//  Created by Patrick Lin on 6/7/16.
//  Copyright © 2016 Patrick Lin. All rights reserved.
//

#import "ViewController.h"
#import <EZAudio/EZAudio.h>
#import <libopus/opus.h>
#import <TPCircularBuffer/TPCircularBuffer+AudioBufferList.h>

@interface ViewController () <EZMicrophoneDelegate, EZOutputDataSource>

@property (nonatomic, strong) EZMicrophone* microphone;

@property (nonatomic, strong) EZOutput* speaker;

@property (nonatomic) TPCircularBuffer* circularBuffer;

@property (nonatomic) OpusEncoder* encoder;

@property (nonatomic) OpusDecoder* decoder;

@property (nonatomic) AudioStreamBasicDescription audioDesc;

@property (nonatomic) uint8_t* encodeBuffer;

@property (nonatomic) uint8_t* decodeBuffer;

@end

@implementation ViewController

#pragma mark - Microphone Delegate Methods

- (void)microphone:(EZMicrophone *)microphone hasBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize withNumberOfChannels:(UInt32)numberOfChannels
{
    AudioStreamBasicDescription desc = microphone.audioStreamBasicDescription;
    
    int len = opus_encode(self.encoder, bufferList->mBuffers->mData, bufferList->mBuffers->mDataByteSize / self.audioDesc.mBytesPerFrame, self.encodeBuffer, 2048);
    
    
    
    //TPCircularBufferCopyAudioBufferList(self.circularBuffer, bufferList, NULL, kTPCircularBufferCopyAll, &desc);
}

#pragma mark - Output Delegate Methods

- (OSStatus)output:(EZOutput *)output shouldFillAudioBufferList:(AudioBufferList *)audioBufferList withNumberOfFrames:(UInt32)frames timestamp:(const AudioTimeStamp *)timestamp
{
    int32_t availableBytes = 0;
    
    void* data = (void *)TPCircularBufferTail(_circularBuffer, &availableBytes);
    
    if (audioBufferList->mBuffers->mDataByteSize < availableBytes) {
        
        memcpy(audioBufferList->mBuffers->mData, data, audioBufferList->mBuffers->mDataByteSize);
        
        TPCircularBufferConsume(self.circularBuffer, audioBufferList->mBuffers->mDataByteSize);
        
    }
    
    return 0;
}

#pragma mark - Opus Methods

- (void)initEncoder
{
    int error;
    
    self.encoder = opus_encoder_create(self.audioDesc.mSampleRate, self.audioDesc.mChannelsPerFrame, OPUS_APPLICATION_VOIP, &error);
    
    self.encodeBuffer = malloc(4096 * sizeof(uint8_t));
}

- (void)initDecoder
{
    int error;
    
    self.decoder = opus_decoder_create(self.audioDesc.mSampleRate, self.audioDesc.mChannelsPerFrame, &error);
    
    self.decodeBuffer = malloc(4096 * sizeof(uint8_t));
}

#pragma mark - Internal Methods

- (void)initAudioDesc
{
    AudioStreamBasicDescription desc;
    
    desc.mBitsPerChannel = 16;
    
    desc.mBytesPerFrame = 2;
    
    desc.mBytesPerPacket = 2;
    
    desc.mChannelsPerFrame = 1;
    
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    
    desc.mFormatID = kAudioFormatLinearPCM;
    
    desc.mSampleRate = 8000;
    
    self.audioDesc = desc;
}

- (void)initCircularBuffer
{
    self.circularBuffer = malloc(sizeof(TPCircularBuffer));
    
    TPCircularBufferInit(self.circularBuffer, 20480);
}

- (void)initMicrophone
{
    self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:self.audioDesc startsImmediately:YES];
}

- (void)initSpeaker
{
    self.speaker = [EZOutput outputWithDataSource:self inputFormat:self.audioDesc];
    
    [self.speaker startPlayback];
}

#pragma mark - Init Methods

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initCircularBuffer];
    
    [self initAudioDesc];
    
    [self initEncoder];
    
    [self initDecoder];
    
    [self initMicrophone];
    
    [self initSpeaker];
}

@end
