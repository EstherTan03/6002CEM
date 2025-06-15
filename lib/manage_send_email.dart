// manage_user_dialog
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

Future<void> sendEmail(String request_username, String admin_email, String request_email,) async {
  final body = "Hello, your account has been approved.\n"
      "Username: $request_username\n"
      "Password: 123\n"
      "You can now log in to the app.";final subject = 'Welcome';

  final app_password = 'kevw ulbk gfjx xrnr';
  final smtpServer = gmail(admin_email, app_password);

  print('admin email : $admin_email');
  print('request email : $request_email');
  print('request username : $request_username');


  final message = Message()
    ..from = Address(admin_email, 'ISST')
    ..recipients.add(request_email)
    ..subject = subject
    ..text = body;

  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Email failed to send: $e');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}
