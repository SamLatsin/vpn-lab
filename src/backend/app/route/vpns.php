<?php

$app->post('/cron/vpn/parse/vpngate', function () use ($app) {
    header('Content-Type: application/json; charset=utf-8');
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "http://www.vpngate.net/api/iphone/");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $output = curl_exec($ch);
    curl_close($ch);  
    if ($output) {
      // $app["Server"]->deleteServerByDonor("vpngate");
      $lines = preg_split("/\r\n|\n|\r/", $output);
      $keys = str_getcsv($lines[1]);
      $lines = array_slice($lines, 2, -2);
      $json = array();
      foreach ($lines as $key1 => $line) {
        $json[] = array_combine($keys, str_getcsv($line));
      }
      $countriesCounts = [];
      usort($json, fn($a, $b) => strcmp($a["CountryShort"], $b["CountryShort"]));
      $max_ping = 0;
      $ping_sum = 0;

      foreach ($json as $key => $server) {
        $server["Ping"] = intval($server["Ping"]);
        if ($server["Ping"] > $max_ping) {
          $max_ping = $server["Ping"];
        }
        $ping_sum += $server["Ping"];
      }
      $medium_ping = $ping_sum / count($json);
      // $max_ping *= 0.5;
      foreach ($json as $key => $server) {
        // $server_local = null;
        if (strtolower($server["CountryShort"]) != "us") {
          $server_local = $app['Server']->getServerByIp($server["IP"]);
          if (!$server_local) {
            $server["Ping"] = intval($server["Ping"]);
            if (array_key_exists($server["CountryLong"], $countriesCounts)) {
              $countriesCounts[$server["CountryLong"]] += 1;
            }
            else {
              $countriesCounts[$server["CountryLong"]] = 1;
            }
            if ($server["Ping"] > $medium_ping) {
              $load = 1 - ($medium_ping / $server["Ping"]);
            }
            else {
              $load = 1 - ($server["Ping"] / $medium_ping);
            }
            $premium = 0;
            if ($load > 0.75) {
              $premium = 1;
            }
            // $name = $server["CountryLong"]."#".$countriesCounts[$server["CountryLong"]];
            $name = $server["CountryLong"];
            $temp_server = [
              "name"=>substr($name, 0, 20),
              "abbreviation"=>strtolower($server["CountryShort"]),
              "premium"=>$premium,
              "load"=>$load,
              "type"=>"openvpn",
              "donor"=>"vpngate",
              "config"=>$server["OpenVPN_ConfigData_Base64"],
              "ping"=>$server["Ping"],
              "ip"=>$server["IP"],
            ];
            $app["Server"]->insertServer($temp_server);
          }
        }
      }
      $result = [
        'error'=>false,
        'result'=>true,
        // 'test'=>$json,
      ];
      return json_encode($result);
    }
    $result = [
        'error'=>true,
        'result'=>curl_error($ch),
      ];
    return json_encode($result);
    
});

$app->post('/api/vpn/get/servers', function () use ($app) {
    $token = $app['request']->get('token', null);
    $user = $app["User"]->getUserByToken($token);
    $is_premium = false;
    if ($user) {
      if ($user[0]["isPremium"] == 1) {
        $is_premium = true;
      }
    }
    $servers = $app['Server']->getSyncedServers();
    $countriesCounts = [];
    usort($servers, fn($a, $b) => strcmp($a["name"], $b["name"]));
    $id = 0;

    foreach ($servers as $key => $server) {
      if (array_key_exists($server["name"], $countriesCounts)) {
        $countriesCounts[$server["name"]] += 1;
      }
      else {
        $countriesCounts[$server["name"]] = 1;
      }
      $servers[$key]["name"] = $server["name"]."#".$countriesCounts[$server["name"]];
      if ($server["premium"] == 1 and !$is_premium) {
          $servers[$key]["config"] = "";
      }
      if ($server["premium"] == 1) {
        $servers[$key]["premium"] = true;
      }
      else {
        $servers[$key]["premium"] = false;
      }
      $servers[$key]["id"] = $id;
      $id += 1;
      unset($servers[$key]["donor"]);
    }
    $result = [
      'error'=>false,
      'result'=>$servers,
    ];
    header('Content-Type: application/json; charset=utf-8');
    return json_encode($result);
});

$app->post('/cron/vpn/sync', function () use ($app) {
  $servers = $app['Server']->getServers();
  $synced_servers = [];
  $servers_to_delete = [];
  foreach ($servers as $key => $server) {
    $ping = ping($server["ip"]);
    if ($ping) {
      $server["ping"] = $ping;
      array_push($synced_servers, $server);
    }
    else {
      array_push($servers_to_delete, $server);
    }
  }
  foreach ($servers_to_delete as $key => $server) {
    if ($server["donor"] == "vpngate") {
      $app["Server"]->deleteServerByIp($server["ip"]);
    }
  }
  $max_ping = 0;
  $ping_sum = 0;
  foreach ($synced_servers as $key => $server) {
    $server["ping"] = intval($server["ping"]);
    if ($server["abbreviation"] == "ru") {
      $server["ping"] = $server["ping"] + 150;
    }
    if ($server["ping"] > $max_ping) {
      $max_ping = $server["ping"];
    }
    $ping_sum += $server["ping"];
  }
  $medium_ping = $ping_sum / count($synced_servers);
  foreach ($synced_servers as $key => $server) {
    if ($server["abbreviation"] == "ru") {
      $server["ping"] = $server["ping"] + 150;
    }
    if ($server["ping"] < 500) {
      $load = 1 - ($server["ping"] / 500);
    }
    $premium = 0;
    if ($load > 0.6) {
      $premium = 1;
    }
    if ($server["synced"] == 0) {
      $fields = [
        "premium"=>$premium,
        "load"=>$load,
        "ping"=>$server["ping"],
        "synced"=>1,
      ];
    }
    else {
      $fields = [
        "premium"=>$premium,
        "load"=>$load,
        "ping"=>$server["ping"],
      ];
    }
    $app["Server"]->updateServer($fields, $server["id"]);
  }
  $result = [
    'error'=>false,
    'result'=>"synced",
  ];
  header('Content-Type: application/json; charset=utf-8');
  return json_encode($result);
});

$app->post('/cron/vpn/sync_openvpn', function () use ($app) {
  $two_factor_sync = true;
  if ($two_factor_sync) {
    $task = $app["CronJob"]->getCronJobByName("isCheckingOpenVPNConfigs");
    if ($task[0]["status"] == 0) {
      $fields = [
        "status"=>1,
      ];
      $app["CronJob"]->updateCronJob($fields, $task[0]['id']);

      $servers = $app['Server']->getPingedOpenVPNServers();
      $servers_to_delete = [];

      foreach ($servers as $key => $server) {
        $status = checkOpenVPNConfig($server["config"]);
        if ($status) {
          $fields = [
            'synced'=>2,
          ];
          $app["Server"]->updateServer($fields, $server["id"]);
        }
        else {
          array_push($servers_to_delete, $server);
        }
      }

      foreach ($servers_to_delete as $key => $server) {
        if ($server["donor"] == "vpngate") {
          $app["Server"]->deleteServerByIp($server["ip"]);
        }
      }

      $fields = [
        "status"=>0,
      ];
      $app["CronJob"]->updateCronJob($fields, $task[0]['id']);

      $result = [
        'error'=>false,
        'result'=>"synced",
      ];
      header('Content-Type: application/json; charset=utf-8');
      return json_encode($result);
    }
  }
  $result = [
    'error'=>true,
    'result'=>"syncing",
  ];
  header('Content-Type: application/json; charset=utf-8');
  return json_encode($result);
});

$app->post('/api/vpn/ping', function () use ($app) {
    $ip = $app['request']->get('ip', null);
    $ping = ping($ip);
    if ($ping) {
      $result = [
        'error'=>false,
        'result'=>$ping,
      ];
      header('Content-Type: application/json; charset=utf-8');
      return json_encode($result);
    }
    $result = [
      'error'=>true,
      'result'=>"host unreachable",
    ];
    header('Content-Type: application/json; charset=utf-8');
    return json_encode($result);
});

$app->post('/api/vpn/check_openvpn_config', function () use ($app) {
    $config = $app['request']->get('config', null);
    $status = checkOpenVPNConfig($config);
    if ($status) {
      $result = [
        'error'=>false,
        'result'=>$status,
      ];
      header('Content-Type: application/json; charset=utf-8');
      return json_encode($result);
    }
    $result = [
      'error'=>true,
      'result'=>"No openVPN service running",
    ];
    header('Content-Type: application/json; charset=utf-8');
    return json_encode($result);
});





