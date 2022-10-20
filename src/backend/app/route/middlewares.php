<?php

setlocale(LC_ALL, 'ru_RU.UTF-8');

 // Encrypt Function
function mc_encrypt($encrypt, $key) {
  $ciphering = "AES-256-CTR";
  $iv_length = openssl_cipher_iv_length($ciphering);
  $options = 0;
  $encryption_iv = '1234561891011121';
  $encoded = openssl_encrypt($encrypt, $ciphering,
            $key, $options, $encryption_iv);
  return $encoded;
}
 
// Decrypt Function
function mc_decrypt($decrypt, $key) {
$ciphering = "AES-256-CTR";
$decryption_iv = '1234561891011121';
$options = 0;
$decrypted=openssl_decrypt ($decrypt, $ciphering, 
        $key, $options, $decryption_iv);
  return $decrypted;
}

function ping($ip) {
  exec("fping -c1 -t500 $ip", $output, $status);
    if ($status == "0") {
      $output = explode(",", $output[0]);
      $output = explode("(", $output[2])[0];
      preg_match_all('!\d+!', $output, $ping);
      $ping = $ping[0][0];
      return $ping;
    }
    return null;
}

function checkOpenVPNConfig($config) {
  $config = base64_decode($config);
  file_put_contents(getcwd()."/temp.ovpn", $config);

  $command = "sudo openvpn --config ".getcwd()."/temp.ovpn"." --route-nopull";
  exec("sudo timeout 5 openvpn --config ".getcwd()."/temp.ovpn"." --route-nopull", $output, $result_code);
  $status = false;
  foreach ($output as $key => $line) {
    if (str_contains($line, "Initialization Sequence Completed")) {
      $status = true;
    }
  }
  return $status;
}

function on_debug(){
    ini_set('error_reporting', E_ALL ^ E_WARNING);
    ini_set('display_errors', 1);
    ini_set('display_startup_errors', 1); 
}

function clearText($text){
  return htmlspecialchars(stripslashes($text));
}

function getFloat($str){
  return (float)str_replace(',', '.', $str);
}

function dump($var){
  echo "<pre>";
  var_dump($var) ;
  echo "</pre>";
}