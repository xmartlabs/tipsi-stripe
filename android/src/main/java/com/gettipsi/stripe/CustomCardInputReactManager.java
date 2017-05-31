package com.gettipsi.stripe;

import java.text.SimpleDateFormat;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.AttributeSet;
import android.util.Log;
import android.util.Xml;
import android.widget.EditText;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.UIManagerModule;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.stripe.android.model.Card;
import com.stripe.android.view.CardInputWidget;
import org.xmlpull.v1.XmlPullParser;
import java.text.ParseException;
import java.util.Date;

/**
 * Created by dmitriy on 11/15/16
 */

public class CustomCardInputReactManager extends SimpleViewManager<CardInputWidget> {

  public static final String REACT_CLASS = "CardInputWidget";
  private static final String TAG = CustomCardInputReactManager.class.getSimpleName();
  private static final String NUMBER = "number";
  private static final String EXP_MONTH = "expMonth";
  private static final String EXP_YEAR = "expYear";
  private static final String CCV = "cvc";

  private ThemedReactContext reactContext;
  private WritableMap currentParams;

  @Override
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  protected CardInputWidget createViewInstance(ThemedReactContext reactContext) {
    XmlPullParser parser = reactContext.getResources().getXml(R.xml.stub_material);
    try {
      parser.next();
      parser.nextTag();
    } catch (Exception e) {
      e.printStackTrace();
    }

    AttributeSet attr = Xml.asAttributeSet(parser);
    final CardInputWidget creditCardForm = new CardInputWidget(reactContext, attr);
    creditCardForm.setCardInputListener(new CardInputWidget.CardInputListener() {
      @Override
      public void onFocusChange(String focusField) {
        Log.d(TAG, "### onFocusChange: " + focusField);
        if (creditCardForm.getCard() != null){
          Log.d(TAG, "### onFocusChange: card: ");
        }
      }

      @Override
      public void onCardComplete() {
        postEvent(creditCardForm);
        Log.d(TAG, "### onCardComplete");
      }

      @Override
      public void onExpirationComplete() {
        postEvent(creditCardForm);
        Log.d(TAG, "### onExpirationComplete");
      }

      @Override
      public void onCvcComplete() {
        postEvent(creditCardForm);
        Log.d(TAG, "### onCvcComplete");
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
    view.setExpiryDate(date.getMonth(), date.getYear());
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
    currentParams.putString(NUMBER, card.getNumber());
    currentParams.putInt(EXP_MONTH, card.getExpMonth());
    currentParams.putInt(EXP_YEAR, card.getExpYear());
    currentParams.putString(CCV, card.getCVC());
    reactContext.getNativeModule(UIManagerModule.class)
      .getEventDispatcher().dispatchEvent(
      new CreditCardFormOnChangeEvent(cardView.getId(), currentParams, cardView.getCard().validateCard()));
  }
}
