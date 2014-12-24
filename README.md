Amr2Wav
==========

A library that can convert amr to wav 

## Useage

```obj-c
    NSString *mediaPath = [NSString stringWithFormat:@"%@%@",HOST_VOICE,order.sound];
    
    NSURL *url = [[NSURL alloc]initWithString:mediaPath];
    NSData * audioData = [NSData dataWithContentsOfURL:url];
    
    //将数据保存到本地指定位置
    NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@.amr", docDirPath , @"temp"];
    [audioData writeToFile:filePath atomically:YES];
    
    //播放本地音乐
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    //amr 转 wav
    [Tool initPlayer];
    NSData *data = [NSData dataWithContentsOfURL:fileURL];
    
    NSError *error;
    player = [[AVAudioPlayer alloc]initWithData:DecodeAMRToWAVE(data) error:&error];
    NSLog(@"error:%@",error);
    
    [player play];

```
