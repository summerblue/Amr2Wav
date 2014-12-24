Amr2Wav
==========

A library that convert audio file format from amr to wav .

## Thanks 

Modify from https://github.com/jxd001/amr-to-wav 

## Useage

### Install

```
pod 'Amr2Wav', :git => 'https://github.com/summerblue/Amr2Wav.git'
```

### Calling

```obj-c

#import "amrFileCodec.h"

NSString *mediaPath = @"http://oralmaster-ugc.qiniudn.com/user_1_2014-12-23_10:13:39-SmKxmA.amr";

NSURL *url = [[NSURL alloc] initWithString:mediaPath];
NSData * audioData = [NSData dataWithContentsOfURL:url];

// Conversion
NSData *data = DecodeAMRToWAVE(audioData);
```
