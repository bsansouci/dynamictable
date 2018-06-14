#import <UIKit/UIKit.h>
#import "PTChannel.h"

@interface PTViewController : UIViewController <PTChannelDelegate, UITextFieldDelegate>

@property (weak) IBOutlet UITextView *outputTextView;
@property (weak) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

- (void)sendMessage:(NSString*)message;

@end
