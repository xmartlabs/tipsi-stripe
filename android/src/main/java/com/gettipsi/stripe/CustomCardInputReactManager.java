package com.gettipsi.stripe;

import java.text.SimpleDateFormat;
import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.UIManagerModule;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.stripe.android.model.Card;
import com.stripe.android.view.CardInputWidget;
import com.gettipsi.stripe.util.CardUtils;

import java.text.ParseException;
import java.util.Calendar;
import java.util.Date;

/**
 * Created by dmitriy on 11/15/16
 */
public class CustomCardInputReactManager extends SimpleViewManager<CardInputWidget> {

  public static final String REACT_CLASS = "CardInputWidget";
  private static final String TAG = CustomCardInputReactManager.class.getSimpleName();

  private ThemedReactContext reactContext;
  private WritableMap currentParams;

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  protected CardInputWidget createViewInstance(ThemedReactContext reactContext) {
    final CardInputWidget creditCardForm = new CardInputWidget(reactContext);
    creditCardForm.setCardInputListener(new CardInputWidget.CardInputListener() {
      @Override
      public void onFocusChange(String focusField) {
      }

      @Override
      public void onCardComplete() {
        postEvent(creditCardForm);
      }

      @Override
      public void onExpirationComplete() {
        postEvent(creditCardForm);
      }

      @Override
      public void onCvcComplete() {
        postEvent(creditCardForm);
      }
    });
    this.reactContext = reactContext;
    return creditCardForm;
  }

  @ReactProp(name = "enabled")
  public void setEnabled(CardInputWidget view, boolean enabled) {
    view.setEnabled(enabled);
  }

  @ReactProp(name = "backgroundColor")
  public void setBackgroundColor(CardInputWidget view, int color) {
    Log.d("TAG", "setBackgroundColor: "+color);
    view.setBackgroundColor(color);
  }

  @ReactProp(name = "cardNumber")
  public void setCardNumber(CardInputWidget view, String cardNumber) {
    view.setCardNumber(cardNumber);
  }

  @ReactProp(name = "expDate")
  public void setExpDate(CardInputWidget view, String expDate) {
    Date date = convertDate(expDate);
    Calendar cal = Calendar.getInstance();
    cal.setTime(date);
    int month = cal.get(Calendar.MONTH);
    int year = cal.get(Calendar.YEAR);
    view.setExpiryDate(month, year);
  }

  @ReactProp(name = "securityCode")
  public void setSecurityCode(CardInputWidget view, String securityCode) {
    view.setCvcCode(securityCode);
  }

  private Date convertDate(String dateString){
    SimpleDateFormat dateFormat = new SimpleDateFormat("MMyy");
    Date convertedDate = new Date();
    try {
      convertedDate = dateFormat.parse(dateString);
    } catch (ParseException e) {
      e.printStackTrace();
    }
    return convertedDate;
  }

  private void postEvent(CardInputWidget cardView){
    if (cardView == null || cardView.getCard() == null) {
      Log.d(TAG, "### Error, getCard == null"); // FIXME: 01.06.17 don`t forget to remove logs
      return;
    }

    Card card = cardView.getCard();
    currentParams = Arguments.createMap();
    currentParams.putString(CardUtils.NUMBER, card.getNumber());
    currentParams.putInt(CardUtils.EXP_MONTH, card.getExpMonth());
    currentParams.putInt(CardUtils.EXP_YEAR, card.getExpYear());
    currentParams.putString(CardUtils.CVC, card.getCVC());
    reactContext.getNativeModule(UIManagerModule.class)
      .getEventDispatcher().dispatchEvent(
      new CreditCardFormOnChangeEvent(cardView.getId(), currentParams, cardView.getCard().validateCard()));
  }
}
