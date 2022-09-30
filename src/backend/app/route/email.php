<?php

function sendMail($to, $subject, $body) {
	$from_email = "support@digital-gang.com";
	$sendmail_params  = "-f$from_email";
	$headers = "From: VPN Lab Support <".$from_email.">" . "\r\n";
	$headers .= "MIME-Version: 1.0" . "\r\n"; 
	$headers .= "Content-type:text/html;charset=UTF-8" . "\r\n"; 
	return mail($to,$subject,$body,$headers,$sendmail_params); 
}

function sendAutentificationCode($email, $code) {
	$subject = "Verification Code";
	$body = ' 
    <html> 
    <head> 
        <title>Hello</title> 
    </head> 
    <body> 
        <h1>Here’s your verification code:</h1> 
        <b>'.$code.'</b>
        <p>This code will expire 30 minutes after this email was sent. If you did not make this request, please ignore this email.</p>
        <p>VPN Lab Team</p>
    </body> 
    </html>'; 
	sendMail($email, $subject, $body);
}