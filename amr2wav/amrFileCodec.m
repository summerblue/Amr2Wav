//
//  amrFileCodec.cpp
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/27/11.
//  Copyright 2011 test. All rights reserved.
//

#include "amrFileCodec.h"

typedef unsigned long long u64;
typedef long long s64;
typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;
int amrEncodeMode[] = {4750, 5150, 5900, 6700, 7400, 7950, 10200, 12200}; // amr 编码方式

static u16 readUInt16(char* bis) {
    u16 result = 0;
    result += ((u16)(bis[0])) << 8;
    result += (u8)(bis[1]);
    return result;
}

static u32 readUint32(char* bis) {
    u32 result = 0;
    result += ((u32) readUInt16(bis)) << 16;
    bis+=2;
    result += readUInt16(bis);
    return result;
}

static NSData * fuckAndroid3GP(NSData *data) {
    //http://android.amberfog.com/?p=181
    u32 size = 0; 
    u32 type =0;
    u32 boxSize =0;
    
    char AMR_MAGIC_HEADER[6] = {0x23, 0x21, 0x41, 0x4d, 0x52, 0x0a};

    //u32 *compatibleBrands;
    
    if (data.length<50) {
        NSLog(@"not android 3gp");
        return data;
    }
    char *bis = (char *)[data bytes];
    
    size = readUint32(bis);
    boxSize += 4;
    bis+=4;
    type = readUint32(bis);
    boxSize += 4;
    bis+=4;
    if (type!=0x66747970) {
        NSLog(@"not android 3gp");
        return data;
    }
    
    boxSize += 4;
    bis+=4;
    boxSize += 4;
    bis+=4;
    int remainSize = (int)(size - boxSize);
    if (remainSize > 0) {
        //compatibleBrands = new u32[remainSize / 4];
        for (int i = 0; i < remainSize / 4; i++) {
            //compatibleBrands[i] = 
            readUint32(bis);
            bis+=4;
        }
    }
    
    boxSize = 0;
    size = readUint32(bis);
    boxSize += 4;
    bis+=4;
    boxSize += 4;
    bis+=4;
    
    int rawAmrDataLength=(size - boxSize);
    int fullAmrDataLength = 6 + rawAmrDataLength;
    //char* amrData = new char[fullAmrDataLength];
    NSMutableData *amrData = [[NSMutableData alloc]initWithCapacity:fullAmrDataLength];
    //memcpy(amrData,AMR_MAGIC_HEADER,6);
    //memcpy(amrData+6,bis,rawAmrDataLength);
    [amrData appendBytes:AMR_MAGIC_HEADER length:6];
    [amrData appendBytes:bis length:rawAmrDataLength];
    
    return amrData;    
}


#pragma mark - Decode
//decode

static const int myround(const double x)
{
	return((int)(x+0.5));
} 

// 根据帧头计算当前帧大小
static int caclAMRFrameSize(unsigned char frameHeader)
{
	int mode;
	int temp1 = 0;
	int temp2 = 0;
	int frameSize;
	
	temp1 = frameHeader;
	
	// 编码方式编号 = 帧头的3-6位
	temp1 &= 0x78; // 0111-1000
	temp1 >>= 3;
	
	mode = amrEncodeMode[temp1];
	
	// 计算amr音频数据帧大小
	// 原理: amr 一帧对应20ms，那么一秒有50帧的音频数据
	temp2 = myround((double)(((double)mode / (double)AMR_FRAME_COUNT_PER_SECOND) / (double)8));
	
	frameSize = myround((double)temp2 + 0.5);
	return frameSize;
}

// 读第一个帧 - (参考帧)
// 返回值: 0-出错; 1-正确
static int ReadAMRFrameFirstData(char* fpamr,int pos,int maxLen, unsigned char frameBuffer[], int* stdFrameSize, unsigned char* stdFrameHeader)
{
    int nPos = 0;
	memset(frameBuffer, 0, sizeof(frameBuffer));
	
	// 先读帧头
	//fread(stdFrameHeader, 1, sizeof(unsigned char), fpamr);
    stdFrameHeader[0] = fpamr[pos];nPos++;
    if (pos+nPos >= maxLen) {
        return 0;
    }
	//if (feof(fpamr)) return 0;
	
	// 根据帧头计算帧大小
	*stdFrameSize = caclAMRFrameSize(*stdFrameHeader);
	
	// 读首帧
	frameBuffer[0] = *stdFrameHeader;
    if ((*stdFrameSize-1)*sizeof(unsigned char)<=0) {
        return 0;
    }
    
    memcpy(&(frameBuffer[1]), fpamr+pos+nPos, (*stdFrameSize-1)*sizeof(unsigned char));
	//fread(&(frameBuffer[1]), 1, (*stdFrameSize-1)*sizeof(unsigned char), fpamr);
	//if (feof(fpamr)) return 0;
    nPos += (*stdFrameSize-1)*sizeof(unsigned char);
    if (pos+nPos >= maxLen) {
        return 0;
    }
	
	return nPos;
}

// 返回值: 0-出错; 1-正确
static int ReadAMRFrameData(char* fpamr,int pos,int maxLen, unsigned char frameBuffer[], int stdFrameSize, unsigned char stdFrameHeader)
{
    int nPos = 0;
	unsigned char frameHeader; // 帧头
	
	memset(frameBuffer, 0, sizeof(frameBuffer));
	
	// 读帧头
	// 如果是坏帧(不是标准帧头)，则继续读下一个字节，直到读到标准帧头
	while(1)
        {
		//bytes = fread(&frameHeader, 1, sizeof(unsigned char), fpamr);
		//if (feof(fpamr)) return 0;
        if (pos+nPos >=maxLen) {
            return 0;
        }
        frameHeader = fpamr[pos+nPos]; nPos++;
		if (frameHeader == stdFrameHeader) break;
        }
	
	// 读该帧的语音数据(帧头已经读过)
	frameBuffer[0] = frameHeader;
	//bytes = fread(&(frameBuffer[1]), 1, (stdFrameSize-1)*sizeof(unsigned char), fpamr);
	//if (feof(fpamr)) return 0;
    if ((stdFrameSize-1)*sizeof(unsigned char)<=0) {
        return 0;
    }
	memcpy(&(frameBuffer[1]), fpamr+pos+nPos, (stdFrameSize-1)*sizeof(unsigned char));
    nPos += (stdFrameSize-1)*sizeof(unsigned char);
    if (pos+nPos >= maxLen) {
        return 0;
    }
    
	return nPos;
}

static void WriteWAVEHeader(NSMutableData* fpwave, int nFrame)
{
	char tag[10] = "";
	
	// 1. 写RIFF头
	RIFFHEADER riff;
	strcpy(tag, "RIFF");
	memcpy(riff.chRiffID, tag, 4);
	riff.nRiffSize = 4                                     // WAVE
	+ sizeof(XCHUNKHEADER)               // fmt 
	+ sizeof(WAVEFORMATX)           // WAVEFORMATX
	+ sizeof(XCHUNKHEADER)               // DATA
	+ nFrame*160*sizeof(short);    // 
	strcpy(tag, "WAVE");
	memcpy(riff.chRiffFormat, tag, 4);
	//fwrite(&riff, 1, sizeof(RIFFHEADER), fpwave);
    [fpwave appendBytes:&riff length:sizeof(RIFFHEADER)];
	
	// 2. 写FMT块
	XCHUNKHEADER chunk;
	WAVEFORMATX wfx;
	strcpy(tag, "fmt ");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = sizeof(WAVEFORMATX);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];
	memset(&wfx, 0, sizeof(WAVEFORMATX));
	wfx.nFormatTag = 1;
	wfx.nChannels = 1; // 单声道
	wfx.nSamplesPerSec = 8000; // 8khz
	wfx.nAvgBytesPerSec = 16000;
	wfx.nBlockAlign = 2;
	wfx.nBitsPerSample = 16; // 16位
    //fwrite(&wfx, 1, sizeof(WAVEFORMATX), fpwave);
    [fpwave appendBytes:&wfx length:sizeof(WAVEFORMATX)];
	
	// 3. 写data块头
	strcpy(tag, "data");
	memcpy(chunk.chChunkID, tag, 4);
	chunk.nChunkSize = nFrame*160*sizeof(short);
	//fwrite(&chunk, 1, sizeof(XCHUNKHEADER), fpwave);
    [fpwave appendBytes:&chunk length:sizeof(XCHUNKHEADER)];

}

NSData* DecodeAMRToWAVE(NSData* data) {
	NSMutableData* fpwave = nil;
	void * destate;
	int nFrameCount = 0;
	int stdFrameSize;
    int nTemp;
	unsigned char stdFrameHeader;
	
	unsigned char amrFrame[MAX_AMR_FRAME_SIZE];
	short pcmFrame[PCM_FRAME_SIZE];
	
	if (data.length<=0) {
        return nil;
    }
    
	const char* rfile = [data bytes];
    int maxLen = [data length];
    int pos = 0;
    
    //有可能是android 3gp格式
    if (strncmp(rfile, AMR_MAGIC_NUMBER, strlen(AMR_MAGIC_NUMBER)))
        {
		data = fuckAndroid3GP(data);
        }
    
    rfile = [data bytes];
	// 检查amr文件头
    if (strncmp(rfile, AMR_MAGIC_NUMBER, strlen(AMR_MAGIC_NUMBER)))
    {
    return nil;
    }
    
	pos += strlen(AMR_MAGIC_NUMBER);
	// 创建并初始化WAVE文件
	
	fpwave = [[NSMutableData alloc]init];
	//WriteWAVEHeader(fpwave, nFrameCount);
	
	/* init decoder */
	destate = Decoder_Interface_init();
	
	// 读第一帧 - 作为参考帧
	memset(amrFrame, 0, sizeof(amrFrame));
	memset(pcmFrame, 0, sizeof(pcmFrame));
	//ReadAMRFrameFirst(fpamr, amrFrame, &stdFrameSize, &stdFrameHeader);
    
    nTemp = ReadAMRFrameFirstData(rfile,pos,maxLen, amrFrame, &stdFrameSize, &stdFrameHeader);
    if (nTemp==0) {
        Decoder_Interface_exit(destate);
        return data;
    }
    pos += nTemp;
	
	// 解码一个AMR音频帧成PCM数据
	Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
	nFrameCount++;
	//fwrite(pcmFrame, sizeof(short), PCM_FRAME_SIZE, fpwave);
    [fpwave appendBytes:pcmFrame length:PCM_FRAME_SIZE*sizeof(short)];

	
	// 逐帧解码AMR并写到WAVE文件里
	while(1)
        {
		memset(amrFrame, 0, sizeof(amrFrame));
		memset(pcmFrame, 0, sizeof(pcmFrame));
		//if (!ReadAMRFrame(fpamr, amrFrame, stdFrameSize, stdFrameHeader)) break;
        nTemp = ReadAMRFrameData(rfile,pos,maxLen, amrFrame, stdFrameSize, stdFrameHeader);
        if (!nTemp) {
            break;
        }
        pos += nTemp;
		
		// 解码一个AMR音频帧成PCM数据 (8k-16b-单声道)
		Decoder_Interface_Decode(destate, amrFrame, pcmFrame, 0);
		nFrameCount++;
		//fwrite(pcmFrame, sizeof(short), PCM_FRAME_SIZE, fpwave);
        [fpwave appendBytes:pcmFrame length:PCM_FRAME_SIZE*sizeof(short)];
        }
	NSLog(@"frame = %d", nFrameCount);
	Decoder_Interface_exit(destate);
	
	//fclose(fpwave);
	
	// 重写WAVE文件头
	//fpwave = fopen([docFilePath cStringUsingEncoding:NSASCIIStringEncoding], "r+");
    //if (!bErr) {
        
    NSMutableData *out = [[NSMutableData alloc]init];
	WriteWAVEHeader(out, nFrameCount);
    [out appendData:fpwave];
	//fclose(fpwave);
	
	return out;
    //}
    
    // return data;
}

