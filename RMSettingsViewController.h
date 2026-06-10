#import <UIKit/UIKit.h>

@interface RMSettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
	NSArray *settings;
}

+ (NSString *)defaultArguments;

@end
