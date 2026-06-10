#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import <NotificationCenter/NotificationCenter.h>

#import "RMRootViewController.h"
#import "RMSettingsViewController.h"

static NSString * const RMLocalDPIProviderBundleIdentifier = @"com.localdpi.tunnel.ext";
static NSString * const RMLocalDPIProfileName = @"LocalDPI";

@implementation RMRootViewController
+ (NSArray<NSString *> *)shellSplit:(NSString *)string {
	NSMutableArray<NSString *> * tokens = [NSMutableArray<NSString *> array];
	BOOL escaping = NO;
	char quoteChar = ' ';
	BOOL quoting = false;
	NSInteger lastCloseQuoteIndex = NSIntegerMin;
	NSMutableString * current = [[NSMutableString alloc] init];
	unichar * chars = malloc(sizeof(unichar) * (string.length + 1));
	[string getCharacters:chars range:NSMakeRange(0, string.length)];
	chars[string.length] = L'\0';
	NSLog(@"shellSplit: %@", string);

	for (NSUInteger i = 0; i < string.length; ++i)
	{
		unichar c = chars[i];

		if (escaping)
		{
			[current appendString:[NSString stringWithCharacters:&c length:1]];
			escaping = NO;
		}
		else if (c == L'\\' && (!quoting || quoteChar != L'\''))
		{
			escaping = YES;
		}
		else if (quoting && c == quoteChar)
		{
			quoting = NO;
			lastCloseQuoteIndex = i;
		}
		else if (!quoting && (c == L'\'' || c == L'"'))
		{
			quoting = YES;
			quoteChar = c;
		}
		else if (!quoting && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:c])
		{
			if (current.length != 0 || lastCloseQuoteIndex == i - 1)
			{
				[tokens addObject:current];
				current = [[NSMutableString alloc] init];
			}
		}
		else
		{
			[current appendString:[NSString stringWithCharacters:&c length:1]];
		}
	}
	free(chars);

	if (current.length != 0 || lastCloseQuoteIndex == string.length - 1)
	{
		[tokens addObject:current];
	}

	NSLog(@"shellSplit result: %@", tokens);
	return tokens;
}

- (void)showError:(NSString *)message {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController *alert = [UIAlertController
			alertControllerWithTitle:@"LocalDPI"
			message:message
			preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
		[self presentViewController:alert animated:YES completion:nil];
	});
}

- (void)loadView {
	// [super loadView];
	self.view = [[UIView alloc] init];
	if ([UIColor respondsToSelector:@selector(systemBackgroundColor)])
	{
		// Use 'class' to bypass compiler API check
		self.view.backgroundColor = [[UIColor class] systemBackgroundColor];
	}
	else
	{
		self.view.backgroundColor = [UIColor whiteColor];
	}

	self->_connectButton = [RMStartStopButton buttonWithType:UIButtonTypeCustom];
	self->_connectButton.translatesAutoresizingMaskIntoConstraints = NO;
	[self->_connectButton addTarget:self action:@selector(connectButtonTapped:) forControlEvents:UIControlEventPrimaryActionTriggered];
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(vpnStatusDidChange:)
		       name:NEVPNStatusDidChangeNotification
		     object:nil];
	[self.view addSubview:self->_connectButton];

	NSLayoutConstraint *buttonSizeConstraint_Width = [self->_connectButton.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.5];
	buttonSizeConstraint_Width.priority = UILayoutPriorityDefaultHigh;
	NSLayoutConstraint *buttonSizeConstraint_Height = [self->_connectButton.widthAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.5];
	buttonSizeConstraint_Height.priority = UILayoutPriorityDefaultHigh;
	[NSLayoutConstraint activateConstraints:@[
		[self->_connectButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
		[self->_connectButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
		buttonSizeConstraint_Width,
		buttonSizeConstraint_Height,
		[self->_connectButton.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.5],
		[self->_connectButton.widthAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.5],
	]];
}

- (void)loadManager:(void (^)(NETunnelProviderManager *))withManager {
	[NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:
		^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
		if (error)
		{
			NSLog(@"loadAllFromPreferences error: %@", error);
			[self showError:error.localizedDescription];
			return;
		}

		NETunnelProviderManager *mgr = nil;
		for (NETunnelProviderManager *candidate in managers)
		{
			NETunnelProviderProtocol *candidateProtocol = (NETunnelProviderProtocol *)candidate.protocolConfiguration;
			if ([candidateProtocol isKindOfClass:[NETunnelProviderProtocol class]]
					&& [candidateProtocol.providerBundleIdentifier isEqualToString:RMLocalDPIProviderBundleIdentifier])
			{
				mgr = candidate;
				break;
			}
		}

		if (!mgr)
		{
			mgr = [[NETunnelProviderManager alloc] init];
		}

		NETunnelProviderProtocol *prot = [[NETunnelProviderProtocol alloc] init];
		prot.providerBundleIdentifier = RMLocalDPIProviderBundleIdentifier;
		prot.serverAddress = @"LocalDPI";
		prot.disconnectOnSleep = NO;
		mgr.localizedDescription = RMLocalDPIProfileName;
		mgr.protocolConfiguration = prot;
		mgr.enabled = YES;

		[mgr saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {

			if (error)
			{
				NSLog(@"saveToPreferences error: %@", error);
				[self showError:error.localizedDescription];
				return;
			}

			[mgr loadFromPreferencesWithCompletionHandler:
				^(NSError * _Nullable error) {
					if (error)
					{
						NSLog(@"loadFromPreferences error: %@", error);
						[self showError:error.localizedDescription];
						return;
					}

					withManager(mgr);
				}];
		}];

	}];
}

- (void)connectButtonTapped:(id)sender {
      [self loadManager: ^(NETunnelProviderManager *mgr)
      {
	      NEVPNStatus status = mgr.connection.status;
	      NSLog(@"connectButton: VPN status is: %ld", (long)status);
	      if (status != NEVPNStatusConnected)
	      {
		      NSLog(@"Starting VPN tunnel...");
		      NSError *startError;
		      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		      NSString *args = [defaults objectForKey:@"Args"];
		      if (!args)
		      {
			      args = [RMSettingsViewController defaultArguments];
		      }
		      NSDictionary * options = @{
			      @"Args": [RMRootViewController shellSplit:
			[@"ciadpi -i ::1 -p 8080 -x 2 " stringByAppendingString:args]],
			      @"IPv6": [NSNumber numberWithBool:[defaults boolForKey:@"IPv6"]],
			      @"DNSServer": [defaults objectForKey:@"DNSServer"],
		      };
		      [mgr.connection startVPNTunnelWithOptions:options andReturnError:&startError];
		      if (startError) {
			      NSLog(@"startVPNTunnel error: %@", startError.localizedDescription);
			      [self showError:startError.localizedDescription];
		      }
		      /* Prevent connections from leaking */
		      [[NSNotificationCenter defaultCenter]
			      removeObserver:self];
		      [[NSNotificationCenter defaultCenter]
			      addObserver:self
				 selector:@selector(vpnStatusDidChange:)
				     name:NEVPNStatusDidChangeNotification
				   object:mgr.connection];
	      }
	      else
	      {
		      NSLog(@"Stopping VPN tunnel...");
		      [mgr.connection stopVPNTunnel];
	      }
      }];
}

- (void)vpnStatusDidChange:(NSNotification *)notification {
	NETunnelProviderSession *session = (NETunnelProviderSession *)[notification object];
	if (!session)
	{
		return;
	}

	NEVPNStatus status = session.status;

	NSLog(@"vpnStatusDidChange: %ld, object: %@", (long)status, [notification object]);
	switch (status)
	{
	    case NEVPNStatusInvalid:
	    case NEVPNStatusDisconnected:
		[self->_connectButton setEnabled:YES];
		[self->_connectButton setActivated:NO];
		break;
	    case NEVPNStatusConnecting:
		[self->_connectButton setEnabled:NO];
		break;
	    case NEVPNStatusConnected:
		[self->_connectButton setEnabled:YES];
		[self->_connectButton setActivated:YES];
		break;
	    case NEVPNStatusReasserting:
		[self->_connectButton setEnabled:NO];
		break;
	    case NEVPNStatusDisconnecting:
		[self->_connectButton setEnabled:NO];
		break;
	    default:
		break;
	}
}

@end
