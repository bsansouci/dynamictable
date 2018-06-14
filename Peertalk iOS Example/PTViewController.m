#import "PTExampleProtocol.h"
#import "PTViewController.h"

#import <ARKit/ARKit.h>
#import <CoreVideo/CoreVideo.h>
#import "Endian.h"

#define clamp(a) (a>255?255:(a<0?0:a));

@interface PTViewController () <ARSessionDelegate> {
  __weak PTChannel *serverChannel_;
  __weak PTChannel *peerChannel_;
}
- (void)appendOutputMessage:(NSString*)message;
- (void)sendDeviceInfo;
@end

@implementation PTViewController {
  ARSession *_session;
}

@synthesize outputTextView = outputTextView_;
@synthesize inputTextField = inputTextField_;
@synthesize imageView = imageView_;

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // Setup UI
  inputTextField_.delegate = self;
  inputTextField_.enablesReturnKeyAutomatically = NO;
  [inputTextField_ becomeFirstResponder];
  outputTextView_.text = @"";
  
  // Create a new channel that is listening on our IPv4 port
  PTChannel *channel = [PTChannel channelWithDelegate:self];
  [channel listenOnPort:PTExampleProtocolIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error) {
    if (error) {
      [self appendOutputMessage:[NSString stringWithFormat:@"Failed to listen on 127.0.0.1:%d: %@", PTExampleProtocolIPv4PortNumber, error]];
    } else {
      [self appendOutputMessage:[NSString stringWithFormat:@"Listening on 127.0.0.1:%d", PTExampleProtocolIPv4PortNumber]];
      serverChannel_ = channel;
    }
  }];

  _session = [[ARSession alloc] init];
  _session.delegate = self;
  [_session runWithConfiguration:[[ARWorldTrackingConfiguration alloc] init]];
}

- (void)viewDidUnload {
  if (serverChannel_) {
    [serverChannel_ close];
  }
  [super viewDidUnload];
}

- (void)session:(ARSession *)session
 didUpdateFrame:(ARFrame *)frame {
  NSLog(@"width: %ld, height: %ld", CVPixelBufferGetWidth(frame.capturedImage),CVPixelBufferGetHeight(frame.capturedImage));

  CVPixelBufferRef buffer = frame.capturedImage;
//
//  CVPixelBufferRetain(buffer);
//
//  size_t w = CVPixelBufferGetWidth(buffer);
//  size_t h = CVPixelBufferGetHeight(buffer);
//  size_t r = CVPixelBufferGetBytesPerRow(buffer);
//  size_t length = 4 * w * h;
////  size_t bytesPerPixel = r/w;
//  int32_t fourChars = CVPixelBufferGetPixelFormatType(buffer);
//  NSLog(@"CVPixelBufferGetPixelFormatType: %c%c%c%c", fourChars >> 24, fourChars >> 16, fourChars >> 8, fourChars);
//  PTExampleARFrame *arFrame = CFAllocatorAllocate(nil, sizeof(PTExampleARFrame) + length, 0);
//
//  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
//  CVPlanarPixelBufferInfo_YCbCrBiPlanar* ptr = (CVPlanarPixelBufferInfo_YCbCrBiPlanar *)CVPixelBufferGetBaseAddress(buffer);
//  NSLog(@"CVPixelBufferIsPlanar: %d, componentInfoY: %d", CVPixelBufferIsPlanar(buffer), EndianU32_BtoN(ptr->componentInfoY.rowBytes));
//
//  NSUInteger yPitch = EndianU32_BtoN(ptr->componentInfoY.rowBytes);
////  NSUInteger cbCrOffset = EndianU32_BtoN(ptr->componentInfoCbCr.offset);
////  uint8_t *rgbBuffer = (uint8_t *)malloc(w * h * 4);
//  NSUInteger cbCrPitch = EndianU32_BtoN(ptr->componentInfoCbCr.rowBytes);
//  uint8_t *yBuffer = (uint8_t *)ptr;
//
//  uint8_t* cbCrBuffer = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 1);
//  // This just moved the pointer past the offset
////  uint8_t* inBaseAddress = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
//
//  //uint8_t *cbCrBuffer = inBaseAddress + cbCrOffset;
////  uint8_t val;
//  int bytesPerPixel = 4;
//
//  for(int y = 0; y < h; y++)
//  {
//    uint8_t *rgbBufferLine = &arFrame->bufferData[y * w * bytesPerPixel];
//    uint8_t *yBufferLine = &yBuffer[y * yPitch];
//    uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
//
//    for(int x = 0; x < w; x++)
//    {
//      int16_t y = yBufferLine[x];
//      int16_t cb = cbCrBufferLine[x & ~1] - 128;
//      int16_t cr = cbCrBufferLine[x | 1] - 128;
//
//      uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
//
//      int16_t r = (int16_t)roundf( y + cr *  1.4 );
//      int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
//      int16_t b = (int16_t)roundf( y + cb *  1.765);
//
//      //ABGR
//      rgbOutput[0] = 0xff;
//      rgbOutput[1] = clamp(b);
//      rgbOutput[2] = clamp(g);
//      rgbOutput[3] = clamp(r);
//    }
//  }
//
//  // Create a device-dependent RGB color space
//  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//  NSLog(@"ypitch:%lu inHeight:%zu bytesPerPixel:%d",(unsigned long)yPitch,h,bytesPerPixel);
//  NSLog(@"cbcrPitch:%lu",cbCrPitch);
//  CGContextRef context = CGBitmapContextCreate(arFrame->bufferData, w, h, 8,
//                                               w*bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
//
//  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
//
//  CGContextRelease(context);
//  CGColorSpaceRelease(colorSpace);
//
//  UIImage *image = [UIImage imageWithCGImage:quartzImage];
//
//  CGImageRelease(quartzImage);
//
//  imageView_.image = image;
//
////  for(int y = 0; y<h; y++) {
////    for(int x = 0; x<w; x++) {
////      size_t offset = bytesPerPixel*((w*y)+x);
////      arFrame->bufferData[offset] = ptr[offset];     // R
////      arFrame->bufferData[offset+1] = ptr[offset+1]; // G
////      arFrame->bufferData[offset+2] = ptr[offset+2]; // B
////      arFrame->bufferData[offset+3] = ptr[offset+3]; // A
////    }
////  }
//  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
//  CVPixelBufferRelease(buffer);
//
////  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
////  CGContextRef gtx = CGBitmapContextCreate(arFrame->bufferData, w, h, 8, w * 4, colorSpace, kCGImageAlphaPremultipliedLast);
////
////  // create the image:
////  CGImageRef toCGImage = CGBitmapContextCreateImage(gtx);
////  UIImage * uiimage = [[UIImage alloc] initWithCGImage:toCGImage];
////  imageView_.image = uiimage;
//
////  CIImage *image = [CIImage imageWithCVPixelBuffer:buffer];
////  CIContext *ctx = [[CIContext alloc] init];
////  CGImageRef imageRef = [ctx createCGImage:image fromRect:CGRectMake(0, 0, w, h)];
////  UIImage *uimage = [UIImage imageWithCGImage:imageRef];
////  imageView_.image = uimage;
//
////  NSData *byteData = [NSData dataWithBytes:pixelBuffer->bufferData length:length];
////  NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:byteData];
////  NSSize imageSize = NSMakeSize(w, h);
////  UIImage * image = [[UIImage alloc] initWithSize:imageSize];
////  [image addRepresentation:imageRep];
////  [imageView_ setImage:image];
//
//  arFrame->width = htonl(w);
//  arFrame->height = htonl(h);
//  arFrame->length = htonl(0); // Convert integer to network byte order
//
//
//
//  // Wrap the textFrame in a dispatch data object
//  dispatch_data_t data = dispatch_data_create((const void*)arFrame, sizeof(PTExampleARFrame) + length, nil, ^{
//    CFAllocatorDeallocate(nil, arFrame);
//  });
//
//  [peerChannel_ sendFrameOfType:PTExampleFrameTypeARFrame tag:PTFrameNoTag withPayload:data callback:^(NSError *error) {
//    if (error) {
//      NSLog(@"Failed to send message: %@", error);
//    }
//  }];
  [peerChannel_ sendFrameOfType:PTExampleFrameTypeARFrame tag:PTFrameNoTag withPayload:PTExampleARFrameDispatchData(buffer) callback:^(NSError *error) {
    if (error) {
      NSLog(@"Failed to send message: %@", error);
    }
  }];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (peerChannel_) {
    [self sendMessage:self.inputTextField.text];
    self.inputTextField.text = @"";
    return NO;
  } else {
    return YES;
  }
}

- (void)sendMessage:(NSString*)message {
  if (peerChannel_) {
    dispatch_data_t payload = PTExampleTextDispatchDataWithString(message);
    [peerChannel_ sendFrameOfType:PTExampleFrameTypeTextMessage tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
      if (error) {
        NSLog(@"Failed to send message: %@", error);
      }
    }];
    [self appendOutputMessage:[NSString stringWithFormat:@"[you]: %@", message]];
  } else {
    [self appendOutputMessage:@"Can not send message — not connected"];
  }
}

- (void)appendOutputMessage:(NSString*)message {
  NSLog(@">> %@", message);
  NSString *text = self.outputTextView.text;
  if (text.length == 0) {
    self.outputTextView.text = [text stringByAppendingString:message];
  } else {
    self.outputTextView.text = [text stringByAppendingFormat:@"\n%@", message];
    [self.outputTextView scrollRangeToVisible:NSMakeRange(self.outputTextView.text.length, 0)];
  }
}


#pragma mark - Communicating

- (void)sendDeviceInfo {
  if (!peerChannel_) {
    return;
  }
  
  NSLog(@"Sending device info over %@", peerChannel_);
  
  UIScreen *screen = [UIScreen mainScreen];
  CGSize screenSize = screen.bounds.size;
  NSDictionary *screenSizeDict = (__bridge_transfer NSDictionary*)CGSizeCreateDictionaryRepresentation(screenSize);
  UIDevice *device = [UIDevice currentDevice];
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                        device.localizedModel, @"localizedModel",
                        [NSNumber numberWithBool:device.multitaskingSupported], @"multitaskingSupported",
                        device.name, @"name",
                        (UIDeviceOrientationIsLandscape(device.orientation) ? @"landscape" : @"portrait"), @"orientation",
                        device.systemName, @"systemName",
                        device.systemVersion, @"systemVersion",
                        screenSizeDict, @"screenSize",
                        [NSNumber numberWithDouble:screen.scale], @"screenScale",
                        nil];
  dispatch_data_t payload = [info createReferencingDispatchData];
  [peerChannel_ sendFrameOfType:PTExampleFrameTypeDeviceInfo tag:PTFrameNoTag withPayload:payload callback:^(NSError *error) {
    if (error) {
      NSLog(@"Failed to send PTExampleFrameTypeDeviceInfo: %@", error);
    }
  }];
}


#pragma mark - PTChannelDelegate

// Invoked to accept an incoming frame on a channel. Reply NO ignore the
// incoming frame. If not implemented by the delegate, all frames are accepted.
//- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
//  if (channel != peerChannel_) {
//    // A previous channel that has been canceled but not yet ended. Ignore.
//    return NO;
//  } else if (type != PTExampleFrameTypeTextMessage && type != PTExampleFrameTypePing) {
//    NSLog(@"Unexpected frame of type %u", type);
//    [channel close];
//    return NO;
//  } else {
//    return YES;
//  }
//}

// Invoked when a new frame has arrived on a channel.
- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
  //NSLog(@"didReceiveFrameOfType: %u, %u, %@", type, tag, payload);
  if (type == PTExampleFrameTypeTextMessage) {
    PTExampleTextFrame *textFrame = (PTExampleTextFrame*)payload.data;
    textFrame->length = ntohl(textFrame->length);
    NSString *message = [[NSString alloc] initWithBytes:textFrame->utf8text length:textFrame->length encoding:NSUTF8StringEncoding];
    [self appendOutputMessage:[NSString stringWithFormat:@"[%@]: %@", channel.userInfo, message]];
  } else if (type == PTExampleFrameTypePing && peerChannel_) {
    [peerChannel_ sendFrameOfType:PTExampleFrameTypePong tag:tag withPayload:nil callback:nil];
  }
}

// Invoked when the channel closed. If it closed because of an error, *error* is
// a non-nil NSError object.
- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
  if (error) {
    [self appendOutputMessage:[NSString stringWithFormat:@"%@ ended with error: %@", channel, error]];
  } else {
    [self appendOutputMessage:[NSString stringWithFormat:@"Disconnected from %@", channel.userInfo]];
  }
}

// For listening channels, this method is invoked when a new connection has been
// accepted.
- (void)ioFrameChannel:(PTChannel*)channel didAcceptConnection:(PTChannel*)otherChannel fromAddress:(PTAddress*)address {
  // Cancel any other connection. We are FIFO, so the last connection
  // established will cancel any previous connection and "take its place".
  if (peerChannel_) {
    [peerChannel_ cancel];
  }
  
  // Weak pointer to current connection. Connection objects live by themselves
  // (owned by its parent dispatch queue) until they are closed.
  peerChannel_ = otherChannel;
  peerChannel_.userInfo = address;
  [self appendOutputMessage:[NSString stringWithFormat:@"Connected to %@", address]];
  
  // Send some information about ourselves to the other end
  [self sendDeviceInfo];
}


@end
