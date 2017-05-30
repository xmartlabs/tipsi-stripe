package com.gettipsi.stripe;

import android.icu.text.SimpleDateFormat;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.AttributeSet;
import android.util.Log;
import android.util.Xml;
import android.widget.EditText;

//import com.devmarvel.creditcardentry.library.CreditCardForm;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.UIManagerModule;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.stripe.android.view.CardInputWidget;

import org.xmlpull.v1.XmlPullParser;

/**
 * Created by dmitriy on 11/15/16
 */

public class CustomCardInputReactManager extends SimpleViewManager<CardInputWidget> {

  public static final String REACT_CLASS = "CreditCardForm";
  private static final String TAG = CustomCardInputReactManager.class.getSimpleName();
  private static final String NUMBER = "number";
  private static final String EXP_MONTH = "expMonth";
  private static final String EXP_YEAR = "expYear";
  private static final String CCV = "cvc";

  private ThemedReactContext reactContext;
  private WritableMap currentParams;

  private String currentNumber;
  private int currentMonth;
  private int currentYear;
  private String currentCCV;

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
    setListeners(creditCardForm); // FIXME: 30.05.17 fix listeners
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
//   Integer month = Integer.parseInt(expDate.)
//    sdf.get
//    view.setExpiryDate(expDate, true); // FIXME: 30.05.17
    Log.e("### setExpDate:", expDate);
  }

  @ReactProp(name = "securityCode")
  public void setSecurityCode(CardInputWidget view, String securityCode) {
    view.setCvcCode(securityCode);
  }

  @ReactProp(name = "numberPlaceholder")
  public void setCreditCardTextHint(CardInputWidget view, String creditCardTextHint) {
//    view.set(creditCardTextHint); // FIXME: 30.05.17
  }

  @ReactProp(name = "expirationPlaceholder")
  public void setExpDateTextHint(CardInputWidget view, String expDateTextHint) {
//    view.setExpDateTextHint(expDateTextHint); // FIXME: 30.05.17
  }

  @ReactProp(name = "cvcPlaceholder")
  public void setSecurityCodeTextHint(CardInputWidget view, String securityCodeTextHint) {
//    view.setSecurityCodeTextHint(securityCodeTextHint); // FIXME: 30.05.17
  }

  private void setListeners(final CardInputWidget view){

    final EditText ccNumberEdit = (EditText) view.findViewById(R.id.cc_card);
    final EditText ccExpEdit = (EditText) view.findViewById(R.id.cc_exp);
    final EditText ccCcvEdit = (EditText) view.findViewById(R.id.cc_ccv);

    ccNumberEdit.addTextChangedListener(new TextWatcher() {
      @Override
      public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
      }

      @Override
      public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        Log.d(TAG, "onTextChanged: cardNumber = "+charSequence);
        currentNumber = charSequence.toString().replaceAll(" ", "");
        postEvent(view);
      }

      @Override
      public void afterTextChanged(Editable editable) {
      }
    });

    ccExpEdit.addTextChangedListener(new TextWatcher() {
      @Override
      public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
      }

      @Override
      public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        Log.d(TAG, "onTextChanged: EXP_YEAR = "+charSequence);
        try {
          currentMonth = view.getCreditCard().getExpMonth();
        }catch (Exception e){
          if(charSequence.length() == 0)
            currentMonth = 0;
        }
        try {
          currentYear = view.getCreditCard().getExpYear();
        }catch (Exception e){
          currentYear = 0;
        }
        postEvent(view);
      }

      @Override
      public void afterTextChanged(Editable editable) {
      }
    });

    ccCcvEdit.addTextChangedListener(new TextWatcher() {
      @Override
      public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
      }

      @Override
      public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        Log.d(TAG, "onTextChanged: CCV = "+charSequence);
        currentCCV = charSequence.toString();
        postEvent(view);
      }

      @Override
      public void afterTextChanged(Editable editable) {
      }
    });
  }

  private void postEvent(CardInputWidget view){
    currentParams = Arguments.createMap();
    currentParams.putString(NUMBER, currentNumber);
    currentParams.putInt(EXP_MONTH, currentMonth);
    currentParams.putInt(EXP_YEAR, currentYear);
    currentParams.putString(CCV, currentCCV);
//    reactContext.getNativeModule(UIManagerModule.class) // FIXME: 30.05.17
//      .getEventDispatcher().dispatchEvent(
//      new CreditCardFormOnChangeEvent(view.getId(), currentParams, view.isCreditCardValid()));
  }

  private void updateView(CardInputWidget view){

  }
}
