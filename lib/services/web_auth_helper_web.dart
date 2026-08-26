import 'dart:html' as html;

void openGoogleAuthPopup(String url) {
  html.window.open(url, 'Google Auth', 'width=500,height=600');
}

void closePopupIfOpen() {
  if (html.window.opener != null && html.window.location.hash.contains('access_token=')) {
    Future.delayed(const Duration(seconds: 1), () {
      html.window.close();
    });
  }
}
