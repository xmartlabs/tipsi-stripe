//
//  TPSStripeManager.m
//  TPSStripe
//
//  Created by Anton Petrov on 28.10.16.
//  Copyright © 2016 Tipsi. All rights reserved.
//

#import "TPSStripeManager.h"
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>

@implementation RCTConvert (STPBankAccountHolderType)

RCT_ENUM_CONVERTER(STPBankAccountHolderType,
                   (@{
                      @"individual": @(STPBankAccountHolderTypeIndividual),
                      @"company": @(STPBankAccountHolderTypeCompany),
                      }),
                   STPBankAccountHolderTypeCompany,
                   integerValue)

+ (NSString *)STPBankAccountHolderTypeString:(STPBankAccountHolderType)type {
    NSString *string = nil;
    switch (type) {
        case STPBankAccountHolderTypeCompany: {
            string = @"company";
        }
            break;
        case STPBankAccountHolderTypeIndividual:
        default: {
            string = @"individual";
        }
            break;
    }
    return string;
}

@end

@implementation RCTConvert (STPBankAccountStatus)

RCT_ENUM_CONVERTER(STPBankAccountStatus,
                   (@{
                      @"new": @(STPBankAccountStatusNew),
                      @"validated": @(STPBankAccountStatusValidated),
                      @"verified": @(STPBankAccountStatusVerified),
                      @"errored": @(STPBankAccountStatusErrored),
                      }),
                   STPBankAccountStatusNew,
                   integerValue)

+ (NSString *)STPBankAccountStatusString:(STPBankAccountStatus)status {
    NSString *string = nil;
    switch (status) {
        case STPBankAccountStatusValidated: {
            string = @"validated";
        }
            break;
        case STPBankAccountStatusVerified: {
            string = @"verified";
        }
            break;
        case STPBankAccountStatusErrored: {
            string = @"errored";
        }
            break;
        case STPBankAccountStatusNew:
        default: {
            string = @"new";
        }
            break;
    }
    return string;
}

@end

NSString * const TPSPaymentNetworkAmex = @"american_express";
NSString * const TPSPaymentNetworkDiscover = @"discover";
NSString * const TPSPaymentNetworkMasterCard = @"master_card";
NSString * const TPSPaymentNetworkVisa = @"visa";

@implementation TPSStripeManager
{
    NSString *publishableKey;
    NSString *merchantId;

    RCTPromiseResolveBlock promiseResolver;
    RCTPromiseRejectBlock promiseRejector;

    BOOL requestIsCompleted;

    void (^applePayCompletion)(PKPaymentAuthorizationStatus);
}

- (instancetype)init {
    if ((self = [super init])) {
        requestIsCompleted = YES;
    }
    return self;
}

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(init:(NSDictionary *)options) {
    publishableKey = options[@"publishableKey"];
    merchantId = options[@"merchantId"];
    [Stripe setDefaultPublishableKey:publishableKey];
}

RCT_EXPORT_METHOD(deviceSupportsApplePay:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve(@([PKPaymentAuthorizationViewController canMakePayments]));
}

RCT_EXPORT_METHOD(canMakeApplePayPayments:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSArray <NSString *> *paymentNetworksStrings =
    options[@"networks"] ?: [TPSStripeManager supportedPaymentNetworksStrings];
    
    NSArray <PKPaymentNetwork> *networks = [self paymentNetworks:paymentNetworksStrings];
    resolve(@([PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:networks]));
}

RCT_EXPORT_METHOD(completeApplePayRequest:(RCTPromiseResolveBlock)resolve
                                 rejecter:(RCTPromiseRejectBlock)reject) {
    if (applePayCompletion) {
        applePayCompletion(PKPaymentAuthorizationStatusSuccess);
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(cancelApplePayRequest:(RCTPromiseResolveBlock)resolve
                               rejecter:(RCTPromiseRejectBlock)reject) {
    if (applePayCompletion) {
        applePayCompletion(PKPaymentAuthorizationStatusFailure);
    }
    resolve(nil);
}

RCT_EXPORT_METHOD(createTokenWithCard:(NSDictionary *)params
                             resolver:(RCTPromiseResolveBlock)resolve
                             rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        reject(
            [NSString stringWithFormat:@"%ld", (long)3],
            @"Previous request is not completed",
            [[NSError alloc] initWithDomain:@"StripeNative" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Previous request is not completed"}]
        );
        return;
    }

    requestIsCompleted = NO;

    STPCardParams *cardParams = [[STPCardParams alloc] init];

    [cardParams setNumber: params[@"number"]];
    [cardParams setExpMonth: [params[@"expMonth"] integerValue]];
    [cardParams setExpYear: [params[@"expYear"] integerValue]];
    [cardParams setCvc: params[@"cvc"]];

    [cardParams setCurrency: params[@"currency"]];
    [cardParams setName: params[@"name"]];
    [cardParams setAddressLine1: params[@"addressLine1"]];
    [cardParams setAddressLine2: params[@"addressLine2"]];
    [cardParams setAddressCity: params[@"addressCity"]];
    [cardParams setAddressState: params[@"addressState"]];
    [cardParams setAddressCountry: params[@"addressCountry"]];
    [cardParams setAddressZip: params[@"addressZip"]];

    [[STPAPIClient sharedClient] createTokenWithCard:cardParams completion:^(STPToken *token, NSError *error) {
        requestIsCompleted = YES;

        if (error) {
            reject(nil, nil, error);
        } else {
            resolve([self convertTokenObject:token]);
        }
    }];
}

RCT_EXPORT_METHOD(createTokenWithBankAccount:(NSDictionary *)params
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        reject(
               [NSString stringWithFormat:@"%ld", (long)3],
               @"Previous request is not completed",
               [[NSError alloc] initWithDomain:@"StripeNative" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Previous request is not completed"}]
               );
        return;
    }
    
    requestIsCompleted = NO;
    
    STPBankAccountParams *bankAccount = [[STPBankAccountParams alloc] init];
    
    [bankAccount setAccountNumber: params[@"accountNumber"]];
    [bankAccount setCountry: params[@"countryCode"]];
    [bankAccount setCurrency: params[@"currency"]];
    [bankAccount setRoutingNumber: params[@"routingNumber"]];
    [bankAccount setAccountHolderName: params[@"accountHolderName"]];
    STPBankAccountHolderType accountHolderType =
    [RCTConvert STPBankAccountHolderType:params[@"accountHolderType"]];
    [bankAccount setAccountHolderType: accountHolderType];
    
    [[STPAPIClient sharedClient] createTokenWithBankAccount:bankAccount completion:^(STPToken *token, NSError *error) {
        requestIsCompleted = YES;
        
        if (error) {
            reject(nil, nil, error);
        } else {
            resolve([self convertTokenObject:token]);
        }
    }];
}

RCT_EXPORT_METHOD(paymentRequestWithCardForm:(NSDictionary *)options
                                    resolver:(RCTPromiseResolveBlock)resolve
                                    rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        reject(
            [NSString stringWithFormat:@"%ld", (long)3],
            @"Previous request is not completed",
            [[NSError alloc] initWithDomain:@"StripeNative" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Previous request is not completed"}]
        );
        return;
    }

    requestIsCompleted = NO;
    // Save promise handlers to use in `paymentAuthorizationViewController`
    promiseResolver = resolve;
    promiseRejector = reject;

    NSUInteger requiredBillingAddressFields = [self billingType:options[@"requiredBillingAddressFields"]];
    NSString *companyName = options[@"companyName"] ? options[@"companyName"] : @"";
    STPUserInformation *prefilledInformation = [self userInformation:options[@"prefilledInformation"]];
    NSString *managedAccountCurrency = options[@"managedAccountCurrency"];
    NSString *nextPublishableKey = options[@"publishableKey"] ? options[@"publishableKey"] : publishableKey;
    UIModalPresentationStyle formPresentation = [self formPresentation:options[@"presentation"]];
    STPTheme *theme = [self formTheme:options[@"theme"]];

    STPPaymentConfiguration *configuration = [[STPPaymentConfiguration alloc] init];
    [configuration setRequiredBillingAddressFields:requiredBillingAddressFields];
    [configuration setCompanyName:companyName];
    [configuration setPublishableKey:nextPublishableKey];


    STPAddCardViewController *addCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:configuration theme:theme];
    [addCardViewController setDelegate:self];
    [addCardViewController setPrefilledInformation:prefilledInformation];
    [addCardViewController setManagedAccountCurrency:managedAccountCurrency];
    // STPAddCardViewController must be shown inside a UINavigationController.
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:addCardViewController];
    [navigationController setModalPresentationStyle:formPresentation];
    [RCTPresentedViewController() presentViewController:navigationController animated:YES completion:nil];
}

RCT_EXPORT_METHOD(paymentRequestWithApplePay:(NSArray *)items
                                 withOptions:(NSDictionary *)options
                                    resolver:(RCTPromiseResolveBlock)resolve
                                    rejecter:(RCTPromiseRejectBlock)reject) {
    if(!requestIsCompleted) {
        reject(
           [NSString stringWithFormat:@"%ld", (long)3],
           @"Previous request is not completed",
           [[NSError alloc] initWithDomain:@"StripeNative" code:3 userInfo:@{NSLocalizedDescriptionKey:@"Previous request is not completed"}]
        );
        return;
    }

    requestIsCompleted = NO;
    // Save promise handlers to use in `paymentAuthorizationViewController`
    promiseResolver = resolve;
    promiseRejector = reject;

    NSUInteger requiredShippingAddressFields = [self applePayAddressFields:options[@"requiredShippingAddressFields"]];
    NSUInteger requiredBillingAddressFields = [self applePayAddressFields:options[@"requiredBillingAddressFields"]];
    PKShippingType shippingType = [self applePayShippingType:options[@"shippingType"]];
    NSMutableArray *shippingMethodsItems = options[@"shippingMethods"] ? options[@"shippingMethods"] : [NSMutableArray array];
    NSString* currencyCode = options[@"currencyCode"] ? options[@"currencyCode"] : @"USD";

    NSMutableArray *shippingMethods = [NSMutableArray array];

    for (NSDictionary *item in shippingMethodsItems) {
        PKShippingMethod *shippingItem = [[PKShippingMethod alloc] init];
        shippingItem.label = item[@"label"];
        shippingItem.detail = item[@"detail"];
        shippingItem.amount = [NSDecimalNumber decimalNumberWithString:item[@"amount"]];
        shippingItem.identifier = item[@"id"];
        [shippingMethods addObject:shippingItem];
    }

    NSMutableArray *summaryItems = [NSMutableArray array];

    for (NSDictionary *item in items) {
        PKPaymentSummaryItem *summaryItem = [[PKPaymentSummaryItem alloc] init];
        summaryItem.label = item[@"label"];
        summaryItem.amount = [NSDecimalNumber decimalNumberWithString:item[@"amount"]];
        [summaryItems addObject:summaryItem];
    }

    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId];

    [paymentRequest setRequiredShippingAddressFields:requiredShippingAddressFields];
    [paymentRequest setRequiredBillingAddressFields:requiredBillingAddressFields];
    [paymentRequest setPaymentSummaryItems:summaryItems];
    [paymentRequest setShippingMethods:shippingMethods];
    [paymentRequest setShippingType:shippingType];
    [paymentRequest setCurrencyCode:currencyCode];

    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
        PKPaymentAuthorizationViewController *paymentAuthorizationVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        paymentAuthorizationVC.delegate = self;
        [RCTPresentedViewController() presentViewController:paymentAuthorizationVC animated:YES completion:nil];
    } else {
        // There is a problem with your Apple Pay configuration.
        promiseRejector = nil;
        promiseResolver = nil;
        requestIsCompleted = YES;
        reject(
            [NSString stringWithFormat:@"%ld", (long)1],
            @"Apple Pay configuration error",
            [NSError errorWithDomain:@"StipeNative" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Apple Pay configuration error"}]
        );
    }
}

RCT_EXPORT_METHOD(openApplePaySetup) {
    PKPassLibrary *library = [[PKPassLibrary alloc] init];

    // Here we should check, if openPaymentSetup selector exist
    if ([library respondsToSelector:NSSelectorFromString(@"openPaymentSetup")]) {
        [library openPaymentSetup];
    }
}

RCT_EXPORT_METHOD(createSourceWithBitcoin:(NSDictionary *)options
                                 resolver:(RCTPromiseResolveBlock)resolve
                                 rejecter:(RCTPromiseRejectBlock)reject) {
    NSUInteger amount = [options[@"amount"] integerValue];
    NSString *email = options[@"email"];
    NSString *currency = @"USD";
    
    STPSourceParams *params = [STPSourceParams bitcoinParamsWithAmount:amount
                                                              currency:currency
                                                                 email:email];
    [[STPAPIClient sharedClient] createSourceWithParams:params
                                             completion:^(STPSource *source, NSError *error) {
        if (error) {
            reject(nil, nil, error);
            return;
        }
        
        resolve([self convertSourceObject:source]);
    }];
}

RCT_EXPORT_METHOD(createSourceWithAliPay:(NSDictionary *)options
                                resolver:(RCTPromiseResolveBlock)resolve
                                rejecter:(RCTPromiseRejectBlock)reject) {
    NSUInteger amount = [options[@"amount"] integerValue];
    NSString *currency = options[@"currency"] ?: @"usd";
    NSString *returnURL = options[@"returnURL"];
    
    STPSourceParams *params = [STPSourceParams alipayParamsWithAmount:amount
                                                             currency:currency
                                                            returnURL:returnURL];
    [[STPAPIClient sharedClient] createSourceWithParams:params
                                             completion:^(STPSource *source, NSError *error) {
        if (error) {
            reject(nil, nil, error);
            return;
        }
        
        if (source.flow == STPSourceFlowRedirect) {
            STPRedirectContextCompletionBlock completionBlock = ^(NSString *sourceID, NSString *clientSecret, NSError *error) {
                if (error) {
                    reject(nil, nil, error);
                    return;
                }
                
                NSMutableDictionary *result = [NSMutableDictionary new];
                [result setValue:sourceID forKey:@"sourceId"];
                [result setValue:clientSecret forKey:@"clientSecret"];
                
                resolve(result);
            };
            
            STPRedirectContext *redirectContext = [[STPRedirectContext alloc] initWithSource:source
                                                                                  completion:completionBlock];
            [redirectContext startSafariAppRedirectFlow];
        } else {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Unexpected source flow type, expected to be STPSourceFlowRedirect"};
            NSError *error = [NSError errorWithDomain:StripeDomain code:STPInvalidRequestError userInfo:userInfo];
            reject(nil, nil, error);
        }
     }];
}

#pragma mark STPAddCardViewControllerDelegate

- (void)addCardViewController:(STPAddCardViewController *)controller
               didCreateToken:(STPToken *)token
                   completion:(STPErrorBlock)completion {
    [RCTPresentedViewController() dismissViewControllerAnimated:YES completion:nil];

    requestIsCompleted = YES;
    completion(nil);
    promiseResolver([self convertTokenObject:token]);
}

- (void)addCardViewControllerDidCancel:(STPAddCardViewController *)addCardViewController {
    [RCTPresentedViewController() dismissViewControllerAnimated:YES completion:nil];

    if (!requestIsCompleted) {
        requestIsCompleted = YES;
        promiseRejector(
            [NSString stringWithFormat:@"%ld", (long)2],
            @"User canceled payment via card",
            [[NSError alloc] initWithDomain:@"StripeNative" code:2 userInfo:@{NSLocalizedDescriptionKey:@"User canceled payment via card"}]
        );
    }

}

#pragma mark PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    // Save for deffered call
    applePayCompletion = completion;

    [[STPAPIClient sharedClient] createTokenWithPayment:payment completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        requestIsCompleted = YES;

        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            promiseRejector(nil, nil, error);
        } else {
            NSDictionary *result = [self convertTokenObject:token];
            NSDictionary *extra = @{
                @"billingContact": [self contactDetails:payment.billingContact] ?: [NSNull null],
                @"shippingContact": [self contactDetails:payment.shippingContact] ?: [NSNull null],
                @"shippingMethod": [self shippingDetails:payment.shippingMethod] ?: [NSNull null]
            };

            [result setValue:extra forKey:@"extra"];

            promiseResolver(result);
        }
    }];
}


- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [RCTPresentedViewController() dismissViewControllerAnimated:YES completion:nil];

    if (!requestIsCompleted) {
        requestIsCompleted = YES;
        promiseRejector(
            [NSString stringWithFormat:@"%ld", (long)2],
            @"User canceled Apple Pay",
            [[NSError alloc] initWithDomain:@"StripeNative" code:2 userInfo:@{NSLocalizedDescriptionKey:@"User canceled Apple Pay"}]
        );
    }
}

- (NSDictionary *)convertAddressObject:(STPAddress *)address {
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    [result setValue:address.name forKey:@"name"];
    [result setValue:address.line1 forKey:@"line1"];
    [result setValue:address.line2 forKey:@"line2"];
    [result setValue:address.city forKey:@"city"];
    [result setValue:address.state forKey:@"state"];
    [result setValue:address.postalCode forKey:@"postalCode"];
    [result setValue:address.country forKey:@"country"];
    [result setValue:address.phone forKey:@"phone"];
    [result setValue:address.email forKey:@"email"];
    
    return result;
}

- (NSDictionary *)convertSourceObject:(STPSource *)source {
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    // Source
    [result setValue:source.stripeID forKey:@"sourceId"];
    [result setValue:source.amount forKey:@"amount"];
    [result setValue:source.created forKey:@"created"];
    [result setValue:source.currency forKey:@"currency"];
    [result setValue:source.metadata forKey:@"metadata"];
    [result setValue:source.details forKey:@"details"];
    [result setValue:@(source.livemode) forKey:@"livemode"];
    [result setValue:[self sourceFlow:source.flow] forKey:@"flow"];
    [result setValue:[self sourceStatus:source.status] forKey:@"status"];
    [result setValue:[self sourceType:source.type] forKey:@"type"];
    [result setValue:[self sourceUsage:source.usage] forKey:@"usage"];
    
    // Owner
    if (source.owner) {
        NSMutableDictionary *owner = [NSMutableDictionary new];
        [result setValue:owner forKey:@"owner"];
        
        [owner setValue:source.owner.email forKey:@"email"];
        [owner setValue:source.owner.name forKey:@"name"];
        [owner setValue:source.owner.phone forKey:@"phone"];
        [owner setValue:source.owner.verifiedEmail forKey:@"verifiedEmail"];
        [owner setValue:source.owner.verifiedName forKey:@"verifiedName"];
        [owner setValue:source.owner.verifiedPhone forKey:@"verifiedPhone"];
        
        // Address
        if (source.owner.address) {
            NSDictionary *address = [self convertAddressObject:source.owner.address];
            [result setValue:address forKey:@"address"];
        }
        
        // Verified address
        if (source.owner.verifiedAddress) {
            NSDictionary *address = [self convertAddressObject:source.owner.verifiedAddress];
            [result setValue:address forKey:@"verifiedAddress"];
        }
    }
    
    // Receiver
    if (source.receiver) {
        NSMutableDictionary *receiver = [NSMutableDictionary new];
        [result setValue:receiver forKey:@"receiver"];
        
        [receiver setValue:source.receiver.address forKey:@"address"];
        [receiver setValue:source.receiver.amountCharged forKey:@"amountCharged"];
        [receiver setValue:source.receiver.amountReceived forKey:@"amountReceived"];
        [receiver setValue:source.receiver.amountReturned forKey:@"amountReturned"];
    }
    
    // Redirect
    if (source.redirect) {
        NSMutableDictionary *redirect = [NSMutableDictionary new];
        [result setValue:redirect forKey:@"redirect"];
        
        [redirect setValue:[source.redirect.returnURL absoluteString] forKey:@"returnURL"];
        [redirect setValue:[source.redirect.url absoluteString] forKey:@"url"];
        [redirect setValue:[self redirectStatus:source.redirect.status] forKey:@"status"];
    }
    
    // Verification
    if (source.verification) {
        NSMutableDictionary *verification = [NSMutableDictionary new];
        [result setValue:verification forKey:@"verification"];
        
        [verification setValue:source.verification.attemptsRemaining forKey:@"attemptsRemaining"];
        [verification setValue:[self sourceVerificationStatus:source.verification.status] forKey:@"status"];
    }
    
    // Card details
    if (source.cardDetails) {
        NSMutableDictionary *cardDetails = [NSMutableDictionary new];
        [result setValue:cardDetails forKey:@"cardDetails"];
        
        [cardDetails setValue:source.cardDetails.last4 forKey:@"last4"];
        [cardDetails setValue:@(source.cardDetails.expMonth) forKey:@"expMonth"];
        [cardDetails setValue:@(source.cardDetails.expYear) forKey:@"expYear"];
        [cardDetails setValue:source.cardDetails.country forKey:@"country"];
        [cardDetails setValue:[self cardBrand:source.cardDetails.brand] forKey:@"brand"];
        [cardDetails setValue:[self sourceCardDetail3DSecureStatus:source.cardDetails.threeDSecure] forKey:@"threeDSecure"];
    }
    
    // SEPA debit details
    if (source.sepaDebitDetails) {
        NSMutableDictionary *sepaDebitDetails = [NSMutableDictionary new];
        [result setValue:sepaDebitDetails forKey:@"sepaDebitDetails"];
        
        [sepaDebitDetails setValue:source.sepaDebitDetails.last4 forKey:@"last4"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.bankCode forKey:@"bankCode"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.country forKey:@"country"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.fingerprint forKey:@"fingerprint"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.mandateReference forKey:@"mandateReference"];
        [sepaDebitDetails setValue:source.sepaDebitDetails.mandateURL forKey:@"mandateURL"];
    }
    
    return result;
}

- (NSString *)sourceCardDetail3DSecureStatus:(STPSourceCard3DSecureStatus)status {
    switch (status) {
        case STPSourceCard3DSecureStatusRequired:
            return @"required";
        case STPSourceCard3DSecureStatusOptional:
            return @"optional";
        case STPSourceCard3DSecureStatusNotSupported:
            return @"supported";
        case STPSourceCard3DSecureStatusUnknown:
            return @"unknown";
    }
}

- (NSString *)sourceVerificationStatus:(STPSourceVerificationStatus)status {
    switch (status) {
        case STPSourceVerificationStatusPending:
            return @"pending";
        case STPSourceVerificationStatusSucceeded:
            return @"succeeded";
        case STPSourceVerificationStatusFailed:
            return @"failed";
        case STPSourceVerificationStatusUnknown:
            return @"uknown";
    }
}

- (NSString *)sourceUsage:(STPSourceUsage)usage {
    switch (usage) {
        case STPSourceUsageSingleUse:
            return @"single";
        case STPSourceUsageReusable:
            return @"reusable";
        case STPSourceUsageUnknown:
            return @"uknown";
    }
}

- (NSString *)sourceType:(STPSourceType)type {
    switch (type) {
        case STPSourceTypeBancontact:
            return @"bancontact";
        case STPSourceTypeBitcoin:
            return @"bitcoin";
        case STPSourceTypeCard:
            return @"card";
        case STPSourceTypeGiropay:
            return @"giropay";
        case STPSourceTypeIDEAL:
            return @"ideal";
        case STPSourceTypeSEPADebit:
            return @"sepadebit";
        case STPSourceTypeSofort:
            return @"sofort";
        case STPSourceTypeThreeDSecure:
            return @"3dsecure";
        case STPSourceTypeAlipay:
            return @"alipay";
        case STPSourceTypeUnknown:
            return @"unknown";
        default:
            break;
    }
}

- (NSString *)redirectStatus:(STPSourceRedirectStatus)status {
    switch (status) {
        case STPSourceRedirectStatusSucceeded:
            return @"success";
        case STPSourceRedirectStatusPending:
            return @"pending";
        case STPSourceRedirectStatusFailed:
            return @"failed";
        case STPSourceRedirectStatusUnknown:
            return @"unknown";
        default:
            break;
    }
}

- (NSString *)sourceStatus:(STPSourceStatus)status {
    switch (status) {
        case STPSourceStatusPending:
            return @"pending";
        case STPSourceStatusChargeable:
            return @"chargeable";
        case STPSourceStatusConsumed:
            return @"consumed";
        case STPSourceStatusCanceled:
            return @"canceled";
        case STPSourceStatusFailed:
            return @"failed";
        case STPSourceStatusUnknown:
            return @"unknown";
        default:
            break;
    }
}

- (NSString *)sourceFlow:(STPSourceFlow)flow {
    switch (flow) {
        case STPSourceFlowNone:
            return @"none";
        case STPSourceFlowReceiver:
            return @"receiver";
        case STPSourceFlowRedirect:
            return @"redirect";
        case STPSourceFlowCodeVerification:
            return @"codeVerification";
        case STPSourceFlowUnknown:
            return @"unknown";
        default:
            break;
    }
}

- (NSDictionary *)convertTokenObject:(STPToken*)token {
    NSMutableDictionary *result = [@{} mutableCopy];

    // Token
    [result setValue:token.tokenId forKey:@"tokenId"];
    [result setValue:@([token.created timeIntervalSince1970]) forKey:@"created"];
    [result setValue:@(token.livemode) forKey:@"livemode"];

    // Card
    if (token.card) {
        NSMutableDictionary *card = [@{} mutableCopy];
        [result setValue:card forKey:@"card"];

        [card setValue:token.card.cardId forKey:@"cardId"];

        [card setValue:[self cardBrand:token.card.brand] forKey:@"brand"];
        [card setValue:[self cardFunding:token.card.funding] forKey:@"funding"];
        [card setValue:token.card.last4 forKey:@"last4"];
        [card setValue:token.card.dynamicLast4 forKey:@"dynamicLast4"];
        [card setValue:@(token.card.isApplePayCard) forKey:@"isApplePayCard"];
        [card setValue:@(token.card.expMonth) forKey:@"expMonth"];
        [card setValue:@(token.card.expYear) forKey:@"expYear"];
        [card setValue:token.card.country forKey:@"country"];
        [card setValue:token.card.currency forKey:@"currency"];

        [card setValue:token.card.name forKey:@"name"];
        [card setValue:token.card.addressLine1 forKey:@"addressLine1"];
        [card setValue:token.card.addressLine2 forKey:@"addressLine2"];
        [card setValue:token.card.addressCity forKey:@"addressCity"];
        [card setValue:token.card.addressState forKey:@"addressState"];
        [card setValue:token.card.addressCountry forKey:@"addressCountry"];
        [card setValue:token.card.addressZip forKey:@"addressZip"];
    }

    // Bank Account
    if (token.bankAccount) {
        NSMutableDictionary *bankAccount = [@{} mutableCopy];
        [result setValue:bankAccount forKey:@"bankAccount"];

        NSString *bankAccountStatusString =
        [RCTConvert STPBankAccountStatusString:token.bankAccount.status];
        [bankAccount setValue:bankAccountStatusString forKey:@"status"];
        [bankAccount setValue:token.bankAccount.country forKey:@"countryCode"];
        [bankAccount setValue:token.bankAccount.currency forKey:@"currency"];
        [bankAccount setValue:token.bankAccount.bankAccountId forKey:@"bankAccountId"];
        [bankAccount setValue:token.bankAccount.bankName forKey:@"bankName"];
        [bankAccount setValue:token.bankAccount.last4 forKey:@"last4"];
        [bankAccount setValue:token.bankAccount.accountHolderName forKey:@"accountHolderName"];
        NSString *bankAccountHolderTypeString =
        [RCTConvert STPBankAccountHolderTypeString:token.bankAccount.accountHolderType];
        [bankAccount setValue:bankAccountHolderTypeString forKey:@"accountHolderType"];
    }

    return result;
}

- (NSString *)cardBrand:(STPCardBrand)inputBrand {
    switch (inputBrand) {
        case STPCardBrandJCB:
            return @"JCB";
        case STPCardBrandAmex:
            return @"American Express";
        case STPCardBrandVisa:
            return @"Visa";
        case STPCardBrandDiscover:
            return @"Discover";
        case STPCardBrandDinersClub:
            return @"Diners Club";
        case STPCardBrandMasterCard:
            return @"MasterCard";
        case STPCardBrandUnknown:
        default:
            return @"Unknown";
    }
}

- (NSString *)cardFunding:(STPCardFundingType)inputFunding {
    switch (inputFunding) {
        case STPCardFundingTypeDebit:
            return @"debit";
        case STPCardFundingTypeCredit:
            return @"credit";
        case STPCardFundingTypePrepaid:
            return @"prepaid";
        case STPCardFundingTypeOther:
        default:
            return @"unknown";
    }
}

- (NSDictionary *)contactDetails:(PKContact*)inputContact {
    NSMutableDictionary *contactDetails = [[NSMutableDictionary alloc] init];

    if (inputContact.name) {
        [contactDetails setValue:[NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:inputContact.name style:NSPersonNameComponentsFormatterStyleDefault options:0] forKey:@"name"];
    }

    if (inputContact.phoneNumber) {
        [contactDetails setValue:[inputContact.phoneNumber stringValue] forKey:@"phoneNumber"];
    }

    if (inputContact.emailAddress) {
        [contactDetails setValue:inputContact.emailAddress forKey:@"emailAddress"];
    }

    if (inputContact.supplementarySubLocality) {
        [contactDetails setValue:inputContact.supplementarySubLocality forKey:@"supplementarySubLocality"];
    }

    for (NSString *elem in @[@"street", @"city", @"state", @"country", @"ISOCountryCode", @"postalCode"]) {
        if ([inputContact.postalAddress respondsToSelector:NSSelectorFromString(elem)]) {
            [contactDetails setValue:[inputContact.postalAddress valueForKey:elem] forKey:elem];
        }
    }
    if ([contactDetails count] == 0) {
        return nil;
    }

    return contactDetails;
}

- (NSDictionary *)shippingDetails:(PKShippingMethod*)inputShipping {
    NSMutableDictionary *shippingDetails = [[NSMutableDictionary alloc] init];

    if (inputShipping.label) {
        [shippingDetails setValue:inputShipping.label forKey:@"label"];
    }

    if (inputShipping.amount) {
        [shippingDetails setValue:[[self numberFormatter] stringFromNumber: inputShipping.amount] forKey:@"amount"];
    }

    if (inputShipping.detail) {
        [shippingDetails setValue:inputShipping.detail forKey:@"detail"];
    }

    if (inputShipping.identifier) {
        [shippingDetails setValue:inputShipping.identifier forKey:@"id"];
    }

    if ([shippingDetails count] == 0) {
        return nil;
    }

    return shippingDetails;
}

- (PKAddressField)applePayAddressFields:(NSString*)inputType {
    PKAddressField addressField = PKAddressFieldNone;
    if ([inputType isEqualToString:@"postal_address"]) {
        addressField = PKAddressFieldPostalAddress;
    }
    if ([inputType isEqualToString:@"phone"]) {
        addressField = PKAddressFieldPhone;
    }
    if ([inputType isEqualToString:@"email"]) {
        addressField = PKAddressFieldEmail;
    }
    if ([inputType isEqualToString:@"name"]) {
        addressField = PKAddressFieldName;
    }
    if ([inputType isEqualToString:@"all"]) {
        addressField = PKAddressFieldAll;
    }
    return addressField;
}

- (PKShippingType)applePayShippingType:(NSString*)inputType {
    PKShippingType shippingType = PKShippingTypeShipping;
    if ([inputType isEqualToString:@"delivery"]) {
        shippingType = PKShippingTypeDelivery;
    }
    if ([inputType isEqualToString:@"store_pickup"]) {
        shippingType = PKShippingTypeStorePickup;
    }
    if ([inputType isEqualToString:@"service_pickup"]) {
        shippingType = PKShippingTypeServicePickup;
    }

    return shippingType;
}

- (STPBillingAddressFields)billingType:(NSString*)inputType {
    if ([inputType isEqualToString:@"zip"]) {
        return STPBillingAddressFieldsZip;
    }
    if ([inputType isEqualToString:@"full"]) {
        return STPBillingAddressFieldsFull;
    }
    return STPBillingAddressFieldsNone;
}

- (STPUserInformation *)userInformation:(NSDictionary*)inputInformation {
    STPUserInformation *userInformation = [[STPUserInformation alloc] init];

    [userInformation setBillingAddress: [self address:inputInformation[@"billingAddress"]]];

    return userInformation;
}

- (STPAddress *)address:(NSDictionary*)inputAddress {
    STPAddress *address = [[STPAddress alloc] init];

    [address setName:inputAddress[@"name"]];
    [address setLine1:inputAddress[@"line1"]];
    [address setLine2:inputAddress[@"line2"]];
    [address setCity:inputAddress[@"city"]];
    [address setState:inputAddress[@"state"]];
    [address setPostalCode:inputAddress[@"postalCode"]];
    [address setCountry:inputAddress[@"country"]];
    [address setPhone:inputAddress[@"phone"]];
    [address setEmail:inputAddress[@"email"]];

    return address;
}

- (STPTheme *)formTheme:(NSDictionary*)options {
    STPTheme *theme = [[STPTheme alloc] init];

    [theme setPrimaryBackgroundColor:[RCTConvert UIColor:options[@"primaryBackgroundColor"]]];
    [theme setSecondaryBackgroundColor:[RCTConvert UIColor:options[@"secondaryBackgroundColor"]]];
    [theme setPrimaryForegroundColor:[RCTConvert UIColor:options[@"primaryForegroundColor"]]];
    [theme setSecondaryForegroundColor:[RCTConvert UIColor:options[@"secondaryForegroundColor"]]];
    [theme setAccentColor:[RCTConvert UIColor:options[@"accentColor"]]];
    [theme setErrorColor:[RCTConvert UIColor:options[@"errorColor"]]];
    [theme setErrorColor:[RCTConvert UIColor:options[@"errorColor"]]];
    // TODO: process font vars

    return theme;
}

- (UIModalPresentationStyle)formPresentation:(NSString*)inputType {
    if ([inputType isEqualToString:@"pageSheet"])
        return UIModalPresentationPageSheet;
    if ([inputType isEqualToString:@"formSheet"])
        return UIModalPresentationFormSheet;

    return UIModalPresentationFullScreen;
}

+ (NSArray <NSString *> *)supportedPaymentNetworksStrings {
    return @[
             TPSPaymentNetworkAmex,
             TPSPaymentNetworkDiscover,
             TPSPaymentNetworkMasterCard,
             TPSPaymentNetworkVisa,
             ];
}

- (NSArray <PKPaymentNetwork> *)paymentNetworks:(NSArray <NSString *> *)paymentNetworkStrings {
    NSMutableArray <PKPaymentNetwork> *results = [@[] mutableCopy];
    
    for (NSString *paymentNetworkString in paymentNetworkStrings) {
        PKPaymentNetwork paymentNetwork = [self paymentNetwork:paymentNetworkString];
        if (paymentNetwork) {
            [results addObject:paymentNetwork];
        }
    }
    
    return [results copy];
}

- (PKPaymentNetwork)paymentNetwork:(NSString *)paymentNetworkString {
    static NSDictionary *paymentNetworksMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *mutableMap = [@{} mutableCopy];
        
        if ((&PKPaymentNetworkAmex) != NULL) {
            mutableMap[TPSPaymentNetworkAmex] = PKPaymentNetworkAmex;
        }
        
        if ((&PKPaymentNetworkDiscover) != NULL) {
            mutableMap[TPSPaymentNetworkDiscover] = PKPaymentNetworkDiscover;
        }
        
        if ((&PKPaymentNetworkMasterCard) != NULL) {
            mutableMap[TPSPaymentNetworkMasterCard] = PKPaymentNetworkMasterCard;
        }
        
        if ((&PKPaymentNetworkVisa) != NULL) {
            mutableMap[TPSPaymentNetworkVisa] = PKPaymentNetworkVisa;
        }
        
        paymentNetworksMap = [mutableMap copy];
    });
    
    return paymentNetworksMap[paymentNetworkString];
}

- (NSNumberFormatter *)numberFormatter {
    static NSNumberFormatter *kSharedFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kSharedFormatter = [[NSNumberFormatter alloc] init];
        [kSharedFormatter setPositiveFormat:@"$0.00"];
    });
    return kSharedFormatter;
}

@end
