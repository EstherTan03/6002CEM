// manage_user_dialog
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

Future<void> sendEmail(String request_username, String request_email,) async {
  final body = "Hello, your account has been approved.\n"
      "Username: $request_username\n"
      "Password: Sample123@\n"
      "You can now log in to the app.";final subject = 'Welcome';


  final app_password = 'vwoy gmij xzdx mzyr';
  final send_out_email = 'laohenry2@gmail.com';
  final smtpServer = gmail(send_out_email, app_password);

  // print('admin email : $admin_email');
  print('request email : $request_email');
  print('request username : $request_username');


  final message = Message()
    ..from = Address(send_out_email, 'ISST')
    ..recipients.add(request_email)
    ..subject = subject
    ..text = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: $sendReport');
  } on MailerException catch (e) {
    print('Email failed to send: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}
