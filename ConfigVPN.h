#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ConfigVpnSTatus) {
    ConfigVpnConnecting,
    ConfigVpnConneced,
    ConfigVpnDisconnecting,
    ConfigVpnDisconnected,
    ConfigVpnInvalid,
    ConfigVpnReasserting,
};

extern NSString *ConfigVPNStatusChangeNotification;

@interface ConfigVPN : NSObject

@property (nonatomic, assign) ConfigVpnSTatus status;

+ (instancetype)shareManager;
- (void)connectVPN;
- (void)disconnectVPN;
- (void)creatVPNProfile;
- (void)removeVPNProfile;
- (void)connected:(void (^)(BOOL connected))completion;
@end
