// Disconnect one paired radio's existing Bluetooth link; do not remove pairing.
#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            fprintf(stderr, "Usage: reset-radio-link AA:BB:CC:DD:EE:FF\n");
            return 2;
        }
        NSString *address = [NSString stringWithUTF8String:argv[1]];
        NSPredicate *valid = [NSPredicate predicateWithFormat:
            @"SELF MATCHES %@", @"([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}"];
        if (![valid evaluateWithObject:address]) {
            fprintf(stderr, "Invalid Bluetooth address.\n");
            return 2;
        }
        IOBluetoothDevice *device = [IOBluetoothDevice deviceWithAddressString:
            [address stringByReplacingOccurrencesOfString:@":" withString:@"-"]];
        if (!device) return 1;
        if (![device isConnected]) {
            puts("Radio link is already disconnected.");
            return 0;
        }
        IOReturn result = [device closeConnection];
        printf("Radio closeConnection: 0x%x\n", result);
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:2];
        while ([end timeIntervalSinceNow] > 0) {
            [[NSRunLoop currentRunLoop] runUntilDate:
                [NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        return result == kIOReturnSuccess ? 0 : 1;
    }
}
