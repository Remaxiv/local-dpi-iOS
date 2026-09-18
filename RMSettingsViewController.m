#import <Foundation/Foundation.h>
#import "RMSettingsViewController.h"

@implementation RMSettingsViewController
+ (NSString *)defaultArguments {
	NSMutableString *fakeData = [NSMutableString stringWithString:@":@"];
	for (NSUInteger i = 0; i < 512; ++i)
	{
		[fakeData appendString:@"\\0"];
	}

	return [NSString stringWithFormat:
		@"--pf 443 --proto tls --disorder 1 --split -5+se --auto=none "
		"--pf 443 --proto udp --ttl 64 --udp-fake 20 --fake-data '%@' --auto=none",
		fakeData];
}

+ (NSString *)argumentsHelp {
	return @"Supported byedpi args in this build:\n"
		@"--auto, --auto-mode, --cache-ttl, --timeout\n"
		@"--proto, --pf, --hosts, --ipset\n"
		@"--split, --disorder, --fake, --oob, --disoob\n"
		@"--ipfrag, --tlsrec, --tlsrec-pos\n"
		@"--ttl, --def-ttl, --fake-data, --udp-fake\n"
		@"--mod-http, --drop-sack, --tls-sni, --tls-sni-pos";
}

+ (NSString *)tlsOnlyArguments {
	return @"--pf 443 --proto tls --disorder 1 --split -5+se --auto=none";
}

+ (NSString *)aggressiveArguments {
	NSMutableString *fakeData = [NSMutableString stringWithString:@":@"];
	for (NSUInteger i = 0; i < 512; ++i)
	{
		[fakeData appendString:@"\\0"];
	}

	return [NSString stringWithFormat:
		@"--pf 443 --proto tls --disorder 1 --split -5+se --tlsrec 1+s --auto=none "
		"--pf 443 --proto udp --ttl 64 --udp-fake 20 --fake-data '%@' --auto=none",
		fakeData];
}

+ (NSString *)diagnosticsSummary {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *args = [defaults stringForKey:@"Args"];
	NSString *dns = [defaults stringForKey:@"DNSServer"];
	NSString *status = [defaults stringForKey:@"LastVPNStatus"];
	NSString *lastStart = [defaults stringForKey:@"LastStartArguments"];
	NSString *lastError = [defaults stringForKey:@"LastVPNError"];

	return [NSString stringWithFormat:
		@"DNS: %@\nIPv6: %@\nSaved Args: %@\nLast Status: %@\nLast Start Args: %@\nLast Error: %@",
		dns ?: @"not set",
		[defaults boolForKey:@"IPv6"] ? @"on" : @"off",
		args ?: @"not set",
		status ?: @"never started",
		lastStart ?: @"never started",
		lastError ?: @"none"];
}

- (void)loadView {
	[super loadView];

	self.navigationItem.title = @"Settings";

	self->settings = @[
		@{@"display": @"Author", @"value": @"Remaxiv", @"type": @"INFO"},
		@{@"display": @"Version", @"value": @"0.0.6", @"type": @"INFO"},
		@{@"display": @"GitHub", @"value": @"github.com/Remaxiv/local-dpi-ios",
		  @"url": @"https://github.com/Remaxiv/local-dpi-ios", @"type": @"URL"},

		@{@"name": @"IPv6", @"display": @"Use IPv6", @"type": @"BOOL"},

		@{@"name": @"DNSServer", @"display": @"DNS Server",
		  @"type": NSStringFromClass([NSString class]), @"default": @"1.1.1.1"},

		@{@"name": @"Args", @"display": @"Arguments",
		  @"type": NSStringFromClass([NSString class]), @"default": [RMSettingsViewController defaultArguments]},

		@{@"display": @"Preset: Standard", @"action": @"presetStandard", @"type": @"ACTION"},
		@{@"display": @"Preset: TLS only", @"action": @"presetTLS", @"type": @"ACTION"},
		@{@"display": @"Preset: Aggressive", @"action": @"presetAggressive", @"type": @"ACTION"},
		@{@"display": @"Reset Arguments", @"action": @"resetArguments", @"type": @"ACTION"},
		@{@"display": @"Diagnostics", @"type": @"DIAGNOSTICS"},
		@{@"display": @"byedpi args", @"value": [RMSettingsViewController argumentsHelp], @"type": @"HELP"},
	];
}

- (void) viewDidLoad {
	for (NSDictionary *setting in self->settings) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *settingName = setting[@"name"];
		id defaultValue = setting[@"default"];
		if (defaultValue != nil
				&& settingName != nil
				&& [defaults objectForKey:settingName] == nil)
		{
			[defaults setObject:defaultValue forKey:settingName];
		}
	}

	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
	self.tableView.rowHeight = UITableViewAutomaticDimension;
	self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
}

#pragma mark - Table View Data Source
- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	if (self.tableView != tableView)
	{
		return 0;
	}

	return settings.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.tableView != tableView)
	{
		return nil;
	}

	NSDictionary *setting = self->settings[indexPath.row];
	if (setting == nil)
	{
		return nil;
	}

	NSString *typeName = setting[@"type"];
	if ([@"INFO" isEqualToString:typeName] || [@"URL" isEqualToString:typeName])
	{
		UITableViewCell *infoCell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell"];
		if (infoCell == nil)
		{
			infoCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"InfoCell"];
		}
		infoCell.selectionStyle = UITableViewCellSelectionStyleNone;
		infoCell.textLabel.text = setting[@"display"];
		infoCell.detailTextLabel.text = setting[@"value"];
		infoCell.detailTextLabel.textColor = [@"URL" isEqualToString:typeName] ? [UIColor blueColor] : nil;
		infoCell.accessoryType = [@"URL" isEqualToString:typeName] ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
		return infoCell;
	}
	else if ([@"ACTION" isEqualToString:typeName])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionCell"];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleDefault;
		cell.textLabel.text = setting[@"display"];
		cell.textLabel.textColor = [UIColor blueColor];
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
		return cell;
	}
	else if ([@"HELP" isEqualToString:typeName])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HelpCell"];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"HelpCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

		UILabel *configLabel = [[UILabel alloc] init];
		configLabel.text = setting[@"display"];

		UITextView *textView = [[UITextView alloc] init];
		textView.text = setting[@"value"];
		textView.font = [UIFont fontWithName:@"Courier New" size:[UIFont systemFontSize]];
		textView.textAlignment = NSTextAlignmentLeft;
		textView.editable = NO;
		textView.selectable = YES;
		textView.scrollEnabled = NO;
		textView.backgroundColor = [UIColor clearColor];
		textView.translatesAutoresizingMaskIntoConstraints = NO;
		[textView setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
		[textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

		UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[configLabel, textView]];
		[cell.contentView addSubview:stackView];
		stackView.axis = UILayoutConstraintAxisVertical;
		stackView.distribution = UIStackViewDistributionFill;
		stackView.alignment = UIStackViewAlignmentLeading;
		stackView.spacing = 8;
		stackView.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[
			[stackView.leftAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leftAnchor],
			[stackView.rightAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.rightAnchor],
			[stackView.topAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.topAnchor],
			[stackView.bottomAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.bottomAnchor],
		]];
		return cell;
	}
	else if ([@"DIAGNOSTICS" isEqualToString:typeName])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiagnosticsCell"];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DiagnosticsCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

		UILabel *configLabel = [[UILabel alloc] init];
		configLabel.text = setting[@"display"];

		UITextView *textView = [[UITextView alloc] init];
		textView.text = [RMSettingsViewController diagnosticsSummary];
		textView.font = [UIFont fontWithName:@"Courier New" size:[UIFont systemFontSize]];
		textView.textAlignment = NSTextAlignmentLeft;
		textView.editable = NO;
		textView.selectable = YES;
		textView.scrollEnabled = NO;
		textView.backgroundColor = [UIColor clearColor];
		textView.translatesAutoresizingMaskIntoConstraints = NO;

		UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[configLabel, textView]];
		[cell.contentView addSubview:stackView];
		stackView.axis = UILayoutConstraintAxisVertical;
		stackView.distribution = UIStackViewDistributionFill;
		stackView.alignment = UIStackViewAlignmentLeading;
		stackView.spacing = 8;
		stackView.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[
			[stackView.leftAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leftAnchor],
			[stackView.rightAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.rightAnchor],
			[stackView.topAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.topAnchor],
			[stackView.bottomAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.bottomAnchor],
		]];
		return cell;
	}
	else if ([@"BOOL" isEqualToString:typeName])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BoolCell"];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BoolCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.textLabel.text = setting[@"display"];

		BOOL value = [[NSUserDefaults standardUserDefaults] boolForKey:setting[@"name"]];
		UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
		[switchView setOn:value animated:NO];
		[switchView setTag:indexPath.row];
		[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
		cell.accessoryView = switchView;
		return cell;
	}
	else if ([NSStringFromClass([NSString class]) isEqualToString:typeName])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextCell"];
		if (cell == nil)
		{
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TextCell"];
		}
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		cell.textLabel.text = nil;
		NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:setting[@"name"]];

		UITextView *textView = [[UITextView alloc] init];
		textView.text = value;
		textView.tag = indexPath.row;
		textView.delegate = self;
		textView.font = [UIFont fontWithName:@"Courier New" size:[UIFont systemFontSize]];
		textView.textAlignment = NSTextAlignmentLeft;
		textView.autocorrectionType = UITextAutocorrectionTypeNo;
		textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textView.spellCheckingType = UITextSpellCheckingTypeNo;
		textView.keyboardType = UIKeyboardTypeWebSearch;
		textView.returnKeyType = UIReturnKeyDone;
		textView.editable = YES;
		textView.selectable = YES;
		textView.scrollEnabled = NO;                   // Critical for auto-sizing - height follows content
		textView.translatesAutoresizingMaskIntoConstraints = NO;
		[textView setContentHuggingPriority:UILayoutPriorityFittingSizeLevel forAxis:UILayoutConstraintAxisVertical];
		[textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

		UILabel *configLabel = [[UILabel alloc] init];
		configLabel.text = setting[@"display"];

		UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[configLabel, textView]];
		[cell.contentView addSubview:stackView];
		stackView.axis = UILayoutConstraintAxisVertical;
		stackView.distribution = UIStackViewDistributionFill;
		stackView.alignment = UIStackViewAlignmentLeading;
		stackView.spacing = 8;
		[stackView layoutSubviews];

		stackView.translatesAutoresizingMaskIntoConstraints = NO;
		[NSLayoutConstraint activateConstraints:@[
			[stackView.leftAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.leftAnchor],
			[stackView.rightAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.rightAnchor],
			[stackView.topAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.topAnchor],
			[stackView.bottomAnchor constraintEqualToAnchor:cell.contentView.layoutMarginsGuide.bottomAnchor],
		]]; 
		return cell;
	}
	return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"EmptyCell"];
}


- (void)switchChanged:(UISwitch*)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:settings[sender.tag][@"name"]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)textFieldEditingDidEnd:(UITextField*)sender {
	[[NSUserDefaults standardUserDefaults] setObject:sender.text forKey:settings[sender.tag][@"name"]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[sender resignFirstResponder];
}

#pragma mark - Table View Delegate
- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	if (self.tableView != tableView)
	{
		return;
	}

	NSDictionary *setting = self->settings[indexPath.row];
	if ([@"URL" isEqualToString:setting[@"type"]])
	{
		NSURL *url = [NSURL URLWithString:setting[@"url"]];
		if (url)
		{
			[[UIApplication sharedApplication] openURL:url];
		}
	}
	else if ([@"ACTION" isEqualToString:setting[@"type"]])
	{
		NSString *action = setting[@"action"];
		NSString *args = nil;
		if ([@"presetStandard" isEqualToString:action] || [@"resetArguments" isEqualToString:action])
		{
			args = [RMSettingsViewController defaultArguments];
		}
		else if ([@"presetTLS" isEqualToString:action])
		{
			args = [RMSettingsViewController tlsOnlyArguments];
		}
		else if ([@"presetAggressive" isEqualToString:action])
		{
			args = [RMSettingsViewController aggressiveArguments];
		}

		if (args)
		{
			[[NSUserDefaults standardUserDefaults] setObject:args forKey:@"Args"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			[self.tableView reloadData];
		}
	}
}

#pragma mark - Text View Delegate
- (void)textViewDidChange:(UITextView *)textView {
	NSDictionary *setting = settings[textView.tag];
	NSString *settingName = setting[@"name"];
	if (settingName)
	{
		[[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:settingName];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}

    // Invalidate the intrinsic content size so the text view reports its new height
    [textView invalidateIntrinsicContentSize];

    // Tell the table view to recalculate cell heights
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
	[[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:settings[textView.tag][@"name"]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


@end
