#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#import <hev-socks5-tunnel.h>
#import "PacketTunnelProvider.h"
extern int ciadpi_main(int argc, char **argv);

void debug(const char *message,...)
{
    va_list args;
    va_start(args, message);
    NSLog(@"%@",[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:message] arguments:args]);
    va_end(args);
}

@interface PacketTunnelProvider ()
{
	NSThread * _tun2SocksThread;
	NSThread * _ciadpiThread;
}

@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
	// Add code here to start the process of connecting the tunnel.
	if (![self.protocolConfiguration
			isKindOfClass:[NETunnelProviderProtocol class]])
	{
		completionHandler([NSError
				errorWithDomain:NEVPNErrorDomain
					   code:NEVPNErrorConfigurationInvalid
				       userInfo:nil]);
		return;
	}

	id argsObject = options[@"Args"];
	if (![argsObject isKindOfClass:[NSArray<NSString *> class]])
	{
		completionHandler([NSError
				errorWithDomain:NEVPNErrorDomain
					   code:NEVPNErrorConfigurationInvalid
				       userInfo:nil]);
		return;
	}
	NSArray<NSString *> * args = (NSArray<NSString *> *)argsObject;

	id isIPv6Object = options[@"IPv6"];
	if (![isIPv6Object isKindOfClass:[NSNumber class]])
	{
		completionHandler([NSError
				errorWithDomain:NEVPNErrorDomain
					   code:NEVPNErrorConfigurationInvalid
				       userInfo:nil]);
		return;
	}
	BOOL isIPv6 = [(NSNumber *)isIPv6Object boolValue];

	id dnsObject = options[@"DNSServer"];
	if (![dnsObject isKindOfClass:[NSString class]])
	{
		completionHandler([NSError
				errorWithDomain:NEVPNErrorDomain
					   code:NEVPNErrorConfigurationInvalid
				       userInfo:nil]);
		return;
	}

	NEPacketTunnelNetworkSettings * tunConf = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"254.1.1.1"];

	NEIPv4Settings *v4Conf = [[NEIPv4Settings alloc] initWithAddresses:@[@"198.18.0.1"] subnetMasks:@[@"255.255.0.0"]];
	v4Conf.includedRoutes = @[[NEIPv4Route defaultRoute]];
	tunConf.IPv4Settings = v4Conf;
	if (isIPv6)
	{
		NEIPv6Settings *v6Conf = [[NEIPv6Settings alloc] initWithAddresses:@[@"fd6e:a81b:704f:1211::1"] networkPrefixLengths:@[@64]];
		v6Conf.includedRoutes = @[[NEIPv6Route defaultRoute]];
		tunConf.IPv6Settings = v6Conf;
	}

	tunConf.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[dnsObject]];
	tunConf.MTU = @9000;
	// tunConf.DNSSettings.matchDomains = @[@""];

	__unsafe_unretained typeof(self) weakSelf = self;
	[self setTunnelNetworkSettings:tunConf completionHandler:^(NSError * _Nullable error) {
		if (error)
		{
			NSLog(@"setTunnelNetworkSettings error: %@", error);
			return;
		}

		/* XXX: start tun2socks + byedpi */
		weakSelf->_ciadpiThread = [[NSThread alloc]
			initWithTarget:self
			selector:@selector(startCIADPI:)
			object:args];
		[weakSelf->_ciadpiThread start];

		NSString * config = @""
			"    tunnel:\n"
			"      mtu: 9000\n"
			"      ipv4:\n"
			"        address: 198.18.0.1\n"
			"        gateway: 198.18.0.1\n"
			"        prefix: 24\n"
			"    socks5:\n"
			"      port: 8080\n"
			"      address: ::1\n"
			"      udp: 'udp'\n"
			"    misc:\n"
			"      limit-nofile: 65535\n"
			"      task-stack-size: 20480\n";
		weakSelf->_tun2SocksThread = [[NSThread alloc]
			initWithTarget:self
			      selector:@selector(startTun2Socks:)
				object:@[config, [NSNumber numberWithInt:[self getTunFd]]] ];
		[weakSelf->_tun2SocksThread start];

		completionHandler(nil);
	}];
}

- (int)getTunFd {
	/* From <sys/kern_control.h> */
#define CTLIOCGINFO 0xc0644e03UL
	struct ctl_info {
	    u_int32_t   ctl_id;
	    char        ctl_name[96];
	};
	struct sockaddr_ctl {
	    u_char      sc_len;
	    u_char      sc_family;
	    u_int16_t   ss_sysaddr;
	    u_int32_t   sc_id;
	    u_int32_t   sc_unit;
	    u_int32_t   sc_reserved[5];
	};

	struct ctl_info ctlInfo = {};
	strncpy(ctlInfo.ctl_name, "com.apple.net.utun_control", sizeof(ctlInfo.ctl_name));
	for (int fd = 0; fd < 1024; ++fd)
	{
		struct sockaddr_ctl sc = {};
		socklen_t size = sizeof(sc);

		int ret = getpeername(fd, (struct sockaddr *)&sc, &size);
		if (ret != 0 || sc.sc_family != AF_SYSTEM)
		{
			continue;
		}

		if (ctlInfo.ctl_id == 0)
		{
			ret = ioctl(fd, CTLIOCGINFO, &ctlInfo);
			if (ret != 0)
			{
				return -1;
			}
		}

		if (sc.sc_id == ctlInfo.ctl_id)
		{
			return fd;
		}

		return fd;
	}

	return -1;
}

- (void)startTun2Socks:(NSArray *)params {
	NSString * config = params[0];
	NSNumber * fd = params[1];

	NSLog(@"startTun2Socks: fd: %@ config: %@", fd, config);
	char * configChars = strdup([config UTF8String]);
	unsigned int configLen = strlen(configChars);
	int ret = hev_socks5_tunnel_main_from_str((const unsigned char *)configChars, configLen, fd.intValue);
	if (ret < 0)
	{
		NSLog(@"hev_socks5_tunnel_main_from_str error: %d", ret);
	}
	free(configChars);
}

- (char**)prepareArgV:(NSArray<NSString *> *)params {
	char **argv = malloc(sizeof(char*) * (params.count + 1));
	argv[params.count] = NULL;

	for (NSUInteger i = 0; i < params.count; ++i)
	{
		argv[i] = strdup([params[i] UTF8String]);
	}

	return argv;
}

- (void)freeArgV:(int)argc :(char**)argv
{
	for (int i = 0; i < argc; ++i)
	{
		free(argv[i]);
	}
	free(argv);
}

- (void)startCIADPI:(NSArray<NSString *> *)params {
	NSLog(@"startCIADPI: arguments are: %@", params);
	char **argv = [self prepareArgV:params];
	int argc = params.count;

	// volatile BOOL loop = YES;
	// while (loop) [NSThread sleepForTimeInterval:1];
	int ret = ciadpi_main(argc, argv);
	NSLog(@"ciadpi_main: returned %d", ret);

	[self freeArgV:argc:argv];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
	/* XXX: stop tun2socks + byedpi */
	// Add code here to start the process of stopping the tunnel.
	[self->_ciadpiThread cancel];
	[self->_tun2SocksThread cancel];
	completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
	// Add code here to handle the message.
	completionHandler(nil);
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
	// Add code here to get ready to sleep.
	completionHandler();
}

- (void)wake {
	// Add code here to wake up.
}

@end
