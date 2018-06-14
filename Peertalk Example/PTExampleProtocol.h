#ifndef peertalk_PTExampleProtocol_h
#define peertalk_PTExampleProtocol_h

#import <Foundation/Foundation.h>
#include <stdint.h>
#import "Endian.h"

#define clamp(a) (a>255?255:(a<0?0:a));

static const int PTExampleProtocolIPv4PortNumber = 2345;

enum {
  PTExampleFrameTypeDeviceInfo = 100,
  PTExampleFrameTypeTextMessage = 101,
  PTExampleFrameTypePing = 102,
  PTExampleFrameTypePong = 103,
  PTExampleFrameTypeARFrame = 104,
};

typedef struct _PTExampleTextFrame {
  uint32_t length;
  uint8_t utf8text[0];
} PTExampleTextFrame;

typedef struct _PTExampleARFrame {
  uint32_t width;
  uint32_t height;
  uint32_t length;
  uint8_t bufferData[0];
} PTExampleARFrame;


static dispatch_data_t PTExampleARFrameDispatchData(CVPixelBufferRef buffer) {
  CVPixelBufferRetain(buffer);

  size_t w = CVPixelBufferGetWidth(buffer);
  size_t h = CVPixelBufferGetHeight(buffer);
  size_t r = CVPixelBufferGetBytesPerRow(buffer);

  size_t n = 4;
  size_t nh = h / n;
  size_t nw = w / n;
  size_t length = 4 * nw * nh;
  size_t bytesPerPixel = r / w;
  NSLog(@"bytesPerPixel: %ld, length: %ld", bytesPerPixel, length);
  PTExampleARFrame *arFrame = CFAllocatorAllocate(nil, sizeof(PTExampleARFrame) + length, 0);

  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);

  CVPlanarPixelBufferInfo_YCbCrBiPlanar* ptr = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)CVPixelBufferGetBaseAddress(buffer);
  NSUInteger cbCrPitch = EndianU32_BtoN(ptr->componentInfoCbCr.rowBytes);
  NSUInteger yPitch = EndianU32_BtoN(ptr->componentInfoY.rowBytes);
  uint8_t *yBuffer = (uint8_t *)ptr;

  uint8_t* cbCrBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 1);
//  for (int y = 0; y < nh; y++) {
//    for (int x = 0; x < nw; x++) {
//      size_t offset1 = bytesPerPixel * ((nw * y) + x);
//      size_t offset2 = bytesPerPixel * ((nw * y * n * n) + x * n);
//      arFrame->bufferData[offset1] = ptr[offset2];     // R
//      arFrame->bufferData[offset1+1] = ptr[offset2+1]; // G
//      arFrame->bufferData[offset1+2] = ptr[offset2+2]; // B
//      arFrame->bufferData[offset1+3] = ptr[offset2+3]; // A
//    }
//  }
  for (int y = 0; y < nh; y++) {
    uint8_t *rgbBufferLine = &arFrame->bufferData[y * nw * bytesPerPixel];
    uint8_t *yBufferLine = &yBuffer[y * n * yPitch];
    uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];

    for(int x = 0; x < nw; x++)
    {
      int16_t y = yBufferLine[x * n];
      int16_t cb = cbCrBufferLine[x & ~1] - 128;
      int16_t cr = cbCrBufferLine[x | 1] - 128;

      uint8_t *rgbOutput = &rgbBufferLine[x * bytesPerPixel];

      int16_t r = (int16_t)roundf( y + cr *  1.4 );
      int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
      int16_t b = (int16_t)roundf( y + cb *  1.765);

      //ABGR
      rgbOutput[0] = 0xff;
      rgbOutput[1] = clamp(b);
      rgbOutput[2] = clamp(g);
      rgbOutput[3] = clamp(r);
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
  CVPixelBufferRelease(buffer);

  arFrame->width = htonl(w);
  arFrame->height = htonl(h);
  arFrame->length = htonl(length); // Convert integer to network byte order

  // Wrap the textFrame in a dispatch data object
  return dispatch_data_create((const void*)arFrame, sizeof(PTExampleARFrame) + length, nil, ^{
    CFAllocatorDeallocate(nil, arFrame);
  });
}


static dispatch_data_t PTExampleTextDispatchDataWithString(NSString *message) {
  // Use a custom struct
  const char *utf8text = [message cStringUsingEncoding:NSUTF8StringEncoding];
  size_t length = strlen(utf8text);
  PTExampleTextFrame *textFrame = CFAllocatorAllocate(nil, sizeof(PTExampleTextFrame) + length, 0);
  memcpy(textFrame->utf8text, utf8text, length); // Copy bytes to utf8text array
  textFrame->length = htonl(length); // Convert integer to network byte order
  
  // Wrap the textFrame in a dispatch data object
  return dispatch_data_create((const void*)textFrame, sizeof(PTExampleTextFrame)+length, nil, ^{
    CFAllocatorDeallocate(nil, textFrame);
  });
}

#endif
