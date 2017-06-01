package com.gettipsi.stripe.util;

import android.support.annotation.NonNull;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.stripe.android.model.BankAccount;
import com.stripe.android.model.Card;
import com.stripe.android.model.Token;

public class CardUtils {
    // Stripe parameter`s names constants
    public static final String TOKEN_ID = "tokenId";
    public static final String LIVEMODE = "livemode";
    public static final String CREATED = "created";
    public static final String USER = "user";
    public static final String CARD = "card";
    public static final String BANK_ACCOUNT = "bankAccount";
    public static final String NUMBER = "number";
    public static final String EXP_MONTH = "expMonth";
    public static final String EXP_YEAR = "expYear";
    public static final String CVC = "cvc";
    public static final String NAME = "name";
    public static final String ADDRESS_LINE1 = "addressLine1";
    public static final String ADDRESS_LINE2 = "addressLine2";
    public static final String ADDRESS_CITY = "addressCity";
    public static final String ADDRESS_STATE = "addressState";
    public static final String ADDRESS_ZIP = "addressZip";
    public static final String ADDRESS_COUNTRY = "addressCountry";
    public static final String BRAND = "brand";
    public static final String LAST4 = "last4";
    public static final String FINGERPRINT = "fingerprint";
    public static final String FUNDING = "funding";
    public static final String COUNTRY = "country";
    public static final String CURRENCY = "currency";
    public static final String CARD_ID = "cardId";
    public static final String ACCOUNT_NUMBER = "accountNumber";
    public static final String COUNTRY_CODE = "countryCode";
    public static final String ROUTING_NUMBER = "routingNumber";
    public static final String ACCOUNT_HOLDER_TYPE = "accountHolderName";
    public static final String ACCOUNT_HOLDER_NAME = "accountHolderType";
    public static final String BANK_NAME = "bankName";


    public static String validateCard(@NonNull Card card) {
        if (!card.validateNumber()) {
            return "The card number that you entered is invalid";
        } else if (!card.validateExpiryDate()) {
            return "The expiration date that you entered is invalid";
        } else if (!card.validateCVC()) {
            return "The CVC code that you entered is invalid";
        }
        return null;
    }

    public static WritableMap createMapFromToken(@NonNull Token token) {
        final WritableMap writableMap = Arguments.createMap();

        writableMap.putString(TOKEN_ID, token.getId());
        writableMap.putBoolean(LIVEMODE, token.getLivemode());
        writableMap.putDouble(CREATED, token.getCreated().getTime());
        writableMap.putBoolean(USER, token.getUsed());

        if (token.getCard() != null) {
            writableMap.putMap(CARD, createMapFromCard(token.getCard()));
        }
        if (token.getBankAccount() != null) {
            writableMap.putMap(BANK_ACCOUNT, createMapFromBankAccount(token.getBankAccount()));
        }

        return writableMap;
    }

    public static Card createCardFromMap(@NonNull ReadableMap cardData) {
        Card.Builder builder = new Card.Builder(
            cardData.getString(NUMBER),
            cardData.getInt(EXP_MONTH),
            cardData.getInt(EXP_YEAR),
            exist(cardData, CVC));

        return builder.name(exist(cardData, NAME))
            .addressLine1(exist(cardData, ADDRESS_LINE1))
            .addressLine2(exist(cardData, ADDRESS_LINE2))
            .addressCity(exist(cardData, ADDRESS_CITY))
            .addressState(exist(cardData, ADDRESS_STATE))
            .addressState(exist(cardData, ADDRESS_ZIP))
            .addressCountry(exist(cardData, ADDRESS_COUNTRY))
            .brand(exist(cardData, BRAND))
            .last4(exist(cardData, LAST4))
            .fingerprint(exist(cardData, FINGERPRINT))
            .funding(exist(cardData, FUNDING))
            .country(exist(cardData, COUNTRY))
            .currency(exist(cardData, CURRENCY)).build();
    }

    public static WritableMap createMapFromCard(@NonNull Card card) {
        WritableMap result = Arguments.createMap();

        if (card == null) return result;

        result.putString(CARD_ID, card.getId());
        result.putString(NUMBER, card.getNumber());
        result.putString(CVC, card.getCVC());
        result.putInt(EXP_MONTH, card.getExpMonth());
        result.putInt(EXP_YEAR, card.getExpYear());
        result.putString(NAME, card.getName());
        result.putString(ADDRESS_LINE1, card.getAddressLine1());
        result.putString(ADDRESS_LINE2, card.getAddressLine2());
        result.putString(ADDRESS_CITY, card.getAddressCity());
        result.putString(ADDRESS_STATE, card.getAddressState());
        result.putString(ADDRESS_ZIP, card.getAddressZip());
        result.putString(ADDRESS_COUNTRY, card.getAddressCountry());
        result.putString(LAST4, card.getLast4());
        result.putString(BRAND, card.getBrand());
        result.putString(FUNDING, card.getFunding());
        result.putString(FINGERPRINT, card.getFingerprint());
        result.putString(COUNTRY, card.getCountry());
        result.putString(CURRENCY, card.getCurrency());

        return result;
    }

    public static BankAccount createBankAccountFromMap(@NonNull ReadableMap accountData) {
        BankAccount account = new BankAccount(
            // required fields only
            accountData.getString(ACCOUNT_NUMBER),
            accountData.getString(COUNTRY_CODE),
            accountData.getString(CURRENCY),
            exist(accountData, ROUTING_NUMBER, "")
        );
        account.setAccountHolderName(exist(accountData, ACCOUNT_HOLDER_TYPE));
        account.setAccountHolderType(exist(accountData, ACCOUNT_HOLDER_NAME));

        return account;
    }

    private static WritableMap createMapFromBankAccount(@NonNull BankAccount account) {
        WritableMap result = Arguments.createMap();

        if (account == null) return result;

        result.putString(ROUTING_NUMBER, account.getRoutingNumber());
        result.putString(ACCOUNT_NUMBER, account.getAccountNumber());
        result.putString(COUNTRY_CODE, account.getCountryCode());
        result.putString(CURRENCY, account.getCurrency());
        result.putString(ACCOUNT_HOLDER_NAME, account.getAccountHolderName());
        result.putString(ACCOUNT_HOLDER_TYPE, account.getAccountHolderType());
        result.putString(FINGERPRINT, account.getFingerprint());
        result.putString(BANK_NAME, account.getBankName());
        result.putString(LAST4, account.getLast4());

        return result;
    }

    private static String exist(ReadableMap map, String key, String def) {
        if (map.hasKey(key)) {
            return map.getString(key);
        } else {
            // If map don't have some key - we must pass to constructor default value.
            return def;
        }
    }

    private static String exist(ReadableMap map, String key) {
        return exist(map, key, null);
    }

}
