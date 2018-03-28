#import "ConfigVPN.h"
#import <NetworkExtension/NetworkExtension.h>
#import <UIKit/UIKit.h>
#import "VPNHeader.h"

#define kSetupIPSec 1

NSString *ConfigVPNStatusChangeNotification = @"ConfigVPNStatusChangeNotification";

@implementation ConfigVPN

//Keychain
#define kPasswordReference @"PWDReferencess"
#define kSharedSecretReference @"PSKReferencess"

+ (instancetype)shareManager
{
    static ConfigVPN *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ConfigVPN alloc] init];
    });
    
    return manager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(VPNStatusDidChangeNotification) name:NEVPNStatusDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)configVPNKeychain
{
    if (![self searchKeychainCopyMatching:kPasswordReference])
    {
        [self deleteKeychainItem:kPasswordReference];
        [self addKeychainItem:kPasswordReference password:@"ihope987"];
    }
    
    if (![self searchKeychainCopyMatching:kSharedSecretReference])
    {
        [self deleteKeychainItem:kSharedSecretReference];
        [self addKeychainItem:kSharedSecretReference password:@"ihope987"];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEVPNStatusDidChangeNotification object:nil];
}

#pragma mark - Keychain
//从Keychain获取密码
- (NSData *)searchKeychainCopyMatching:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    searchDictionary[(__bridge id)kSecReturnPersistentRef] = @YES;//这很重要
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    return (__bridge NSData *)result;
}

//插入密码到Keychain
- (void)addKeychainItem:(NSString *)identifier password:(NSString*)password
{
    NSData *passData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecValueData] = passData;
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    ;
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)(searchDictionary), &result);
    if (status != noErr)
    {
        NSLog(@"addKeychainItem Error");
    }
}

//从Keychain删除密码
- (void)deleteKeychainItem:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
    if (status != noErr)
    {
        NSLog(@"deleteKeychainItem Error");
    }
}

#pragma mark - VPNConfig
- (void)setupIPSec
{
    [self configVPNKeychain];

    NEVPNProtocolIPSec *p = [[NEVPNProtocolIPSec alloc] init];
    p.username = kVPNUserName;
    p.serverAddress = kVPNServerAddress;
    p.passwordReference = [self searchKeychainCopyMatching:kPasswordReference];
    p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
    p.sharedSecretReference = [self searchKeychainCopyMatching:kSharedSecretReference];
    
    p.remoteIdentifier = kVPNRemoteIdentifier;
    p.useExtendedAuthentication = YES;
    p.disconnectOnSleep = NO;
    
    [[NEVPNManager sharedManager] setProtocolConfiguration:p];
    [[NEVPNManager sharedManager] setOnDemandEnabled:YES];
    [[NEVPNManager sharedManager] setLocalizedDescription:@"Love and Peace"];//VPN自定义名字
    [[NEVPNManager sharedManager] setEnabled:YES];
}

-(void)setupIKEv2
{
    [self configVPNKeychain];

    NEVPNProtocolIKEv2 *p = [[NEVPNProtocolIKEv2 alloc] init];
    p.username = kVPNUserName;
    p.serverAddress = kVPNServerAddress;

    p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
    p.passwordReference = [self searchKeychainCopyMatching:kPasswordReference];
    p.sharedSecretReference = [self searchKeychainCopyMatching:kSharedSecretReference];
    
    p.remoteIdentifier = kVPNRemoteIdentifier;
    p.useExtendedAuthentication = YES;
    p.disconnectOnSleep = NO;
    
    [[NEVPNManager sharedManager] setProtocolConfiguration:p];
    [[NEVPNManager sharedManager] setOnDemandEnabled:YES];
    [[NEVPNManager sharedManager] setLocalizedDescription:@"Love and Peace"];//VPN自定义名字
    [[NEVPNManager sharedManager] setEnabled:YES];
}

- (void)creatVPNProfile
{
    [self creatVPNProfileConnect:NO];
}

- (void)creatVPNProfileConnect:(BOOL)connect
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if(error)
        {
            NSLog(@"creatVPNProfileConnect Load error: %@", error);
        }
        else
        {
#if kSetupIPSec == 1
            [self setupIPSec];
#else
            [self setupIKEv2];
#endif
            //保存VPN到系统->通用->VPN->个人VPN
            [[NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *error){
                if(error)
                {
                    NSLog(@"creatVPNProfileConnect Save Error %@", error);
                    self.status = ConfigVpnInvalid;
                    [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
                }
                else
                {
                    NSLog(@"creatVPNProfileConnect Saved");
                    if (connect && iGetSystemVersion() > 8)
                    {
                        [self performSelector:@selector(connectVPNfixProfile:) withObject:0 afterDelay:0];
                    }
                }
            }];
        }
    }];
    
}

float iGetSystemVersion()
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}


- (void)connectVPN
{
    [self connectVPNfixProfile:YES];
}

- (void)connectVPNfixProfile:(BOOL)fix
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
#if kSetupIPSec == 1
            [self setupIPSec];
#else
            [self setupIKEv2];
#endif
            NSError *intererror = nil;
            [[NEVPNManager sharedManager].connection startVPNTunnelAndReturnError:&intererror];
            if (intererror && fix)
            {
                [self creatVPNProfileConnect:YES];
            }
        }
    }];
}

- (void)disconnectVPN
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            [[NEVPNManager sharedManager].connection stopVPNTunnel];
        }
    }];
}

- (void)removeVPNProfile
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            [[NEVPNManager sharedManager] removeFromPreferencesWithCompletionHandler:^(NSError *error){
                if(error)
                {
                    NSLog(@"removeVPNProfile %@", error);
                }
                else
                {
                    NSLog(@"removeVPNProfile Success");
                }
            }];
        }
    }];
}

- (void)connected:(void (^)(BOOL))completion
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
#if kSetupIPSec == 1
            [self setupIPSec];
#else
            [self setupIKEv2];
#endif
            completion([self isconnected]);
        }
        else
        {
            completion(NO);
        }
    }];
}

- (BOOL)isconnected
{
    return (NEVPNStatusConnected == [[NEVPNManager sharedManager] connection].status);
}

- (void)VPNStatusDidChangeNotification
{
    switch ([NEVPNManager sharedManager].connection.status)
    {
        case NEVPNStatusInvalid:
        {
            NSLog(@"NEVPNStatusInvalid");
            self.status = ConfigVpnInvalid;
            break;
        }
        case NEVPNStatusDisconnected:
        {
            NSLog(@"NEVPNStatusDisconnected");
            self.status = ConfigVpnDisconnected;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusConnecting:
        {
            NSLog(@"NEVPNStatusConnecting");
            self.status = ConfigVpnConnecting;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        case NEVPNStatusConnected:
        {
            NSLog(@"NEVPNStatusConnected");
            self.status = ConfigVpnConneced;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusReasserting:
        {
            NSLog(@"NEVPNStatusReasserting");
            self.status = ConfigVpnReasserting;
            break;
        }
        case NEVPNStatusDisconnecting:
        {
            NSLog(@"NEVPNStatusDisconnecting");
            self.status = ConfigVpnDisconnecting;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
            
        default:
            break;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
}
@end
