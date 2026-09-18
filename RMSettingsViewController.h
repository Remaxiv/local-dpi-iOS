#import <UIKit/UIKit.h>

@interface RMSettingsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
	NSArray *settings;
}

+ (NSString *)defaultArguments;
+ (NSString *)tlsOnlyArguments;
+ (NSString *)aggressiveArguments;
+ (NSString *)argumentsHelp;
+ (NSString *)diagnosticsSummary;

@end
