// manage_user_dialog
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart'; 

Future<void> sendEmail(String request_username, String admin_email, String request_email) async {
  final body = "Hello, your account has been approved.\n"
      "Username: $request_username\n"
      "Password: 123\n"
      "You can now log in to the app.";
  final subject = 'Welcome';

  final sendgridUsername = 'apikey';
  final sendgridPassword = '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'; 
  
  final smtpServer = SmtpServer(
    'smtp.sendgrid.net',
    port: 587,
    username: sendgridUsername,
    password: sendgridPassword,
    ignoreBadCertificate: false,
  );

  final message = Message()
    ..from = Address(admin_email, 'ISST')
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
