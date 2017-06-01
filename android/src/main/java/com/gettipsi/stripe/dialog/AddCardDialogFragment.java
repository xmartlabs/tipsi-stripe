package com.gettipsi.stripe.dialog;

import android.app.AlertDialog;
import android.app.Dialog;
import android.app.DialogFragment;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.content.ContextCompat;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.WritableMap;
import com.gettipsi.stripe.R;
import com.gettipsi.stripe.util.CardFlipAnimator;
import com.gettipsi.stripe.util.CardUtils;
import com.stripe.android.Stripe;
import com.stripe.android.TokenCallback;
import com.stripe.android.model.Card;
import com.stripe.android.model.Token;
import com.stripe.android.view.CardInputWidget;

/**
 * Created by dmitriy on 11/13/16
 */
public class AddCardDialogFragment extends DialogFragment {

  private static final String KEY = "KEY";
  private static final String TAG = AddCardDialogFragment.class.getSimpleName();
  private String PUBLISHABLE_KEY;

  private ProgressBar progressBar;
  private CardInputWidget form;
  private ImageView imageFlipedCard;
  private ImageView imageFlipedCardBack;

  private volatile Promise promise;
  private boolean successful;
  private CardFlipAnimator cardFlipAnimator;
  private Button doneButton;

  public static AddCardDialogFragment newInstance(final String PUBLISHABLE_KEY) {
    Bundle args = new Bundle();
    args.putString(KEY, PUBLISHABLE_KEY);
    AddCardDialogFragment fragment = new AddCardDialogFragment();
    fragment.setArguments(args);
    return fragment;
  }


  public void setPromise(Promise promise) {
    this.promise = promise;
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    if (getArguments() != null)
      PUBLISHABLE_KEY = getArguments().getString(KEY);
  }

  @Override
  public Dialog onCreateDialog(Bundle savedInstanceState) {
    final View view = View.inflate(getActivity(), R.layout.payment_form_fragment_two, null);
    final AlertDialog dialog = new AlertDialog.Builder(getActivity())
      .setView(view)
      .setTitle("Enter your card")
      .setPositiveButton("Done", new DialogInterface.OnClickListener() {
        @Override
        public void onClick(DialogInterface dialogInterface, int i) {
          onSaveCLick();
        }
      })
      .setNegativeButton(android.R.string.cancel, null).create();
    dialog.show();

    doneButton = dialog.getButton(AlertDialog.BUTTON_POSITIVE);
    doneButton.setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View view) {
        onSaveCLick();
      }
    });
    doneButton.setTextColor(ContextCompat.getColor(getActivity(), R.color.colorAccent));
    dialog.getButton(AlertDialog.BUTTON_NEGATIVE).setTextColor(ContextCompat.getColor(getActivity(), R.color.colorAccent));
    doneButton.setEnabled(false);

    bindViews(view);
    init();

    return dialog;
  }

  @Override
  public void onDismiss(DialogInterface dialog) {
    if (!successful && promise != null) {
      promise.reject(TAG, getString(R.string.user_cancel_dialog));
      promise = null;
    }
    super.onDismiss(dialog);
  }

  private void bindViews(final View view) {
    progressBar = (ProgressBar) view.findViewById(R.id.buttonProgress);
    form = (CardInputWidget) view.findViewById(R.id.card_input_widget);
    imageFlipedCard = (ImageView) view.findViewById(R.id.imageFlippedCard);
    imageFlipedCardBack = (ImageView) view.findViewById(R.id.imageFlippedCardBack);
  }


  private void init() {
    form.setCardInputListener(new CardInputWidget.CardInputListener() {
      @Override
      public void onFocusChange(String focusField) {
        if(focusField.equals(CardInputWidget.FOCUS_CVC)){
          cardFlipAnimator.showBack();
        }else {
          cardFlipAnimator.showFront();
        }
      }

      @Override
      public void onCardComplete() {
      }

      @Override
      public void onExpirationComplete() {
      }

      @Override
      public void onCvcComplete() {
        cardFlipAnimator.showFront();
        doneButton.setEnabled(true);
      }
    });

    cardFlipAnimator = new CardFlipAnimator(getActivity(), imageFlipedCard, imageFlipedCardBack);
    successful = false;
  }

  public void onSaveCLick() {
    doneButton.setEnabled(false);
    progressBar.setVisibility(View.VISIBLE);
    final Card card = form.getCard(); // getCard returns null if some input invalid
    String errorMessage = CardUtils.validateCard(card); // additional validation for errorMessage
    if (card != null && errorMessage == null) {
      new Stripe(this.getActivity()).createToken(
        card,
        PUBLISHABLE_KEY,
        new TokenCallback() {
          public void onSuccess(Token token) {
            final WritableMap newToken = CardUtils.createMapFromToken(token);
            newToken.putMap("card", CardUtils.createMapFromCard(token.getCard()));
            if (promise != null) {
              promise.resolve(newToken);
              promise = null;
            }
            successful = true;
            dismiss();
          }

          public void onError(Exception error) {
            doneButton.setEnabled(true);
            progressBar.setVisibility(View.GONE);
            Toast.makeText(getActivity(), error.getLocalizedMessage(), Toast.LENGTH_LONG).show();
          }
        });
    } else {
      doneButton.setEnabled(true);
      progressBar.setVisibility(View.GONE);
      Toast.makeText(getActivity(), errorMessage, Toast.LENGTH_LONG).show();
    }
  }
}
