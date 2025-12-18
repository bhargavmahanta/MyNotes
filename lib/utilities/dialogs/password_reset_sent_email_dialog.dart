import 'package:flutter/material.dart';
import 'package:learningfirebase/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetSentEmailDialog(
    BuildContext context,
  ) {
    return showGenericDialog(
      context: context,
      title: "Password Reset",
      content:
          "We have sent you an email with instructions to reset your password.",
      optionsBuilder: () => {
        "OK": null,
      },
    );
  }