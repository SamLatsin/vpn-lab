<?
namespace VPN;

class Server{
   public $app;
   public $model;

  function __construct($app,$model=null) {
      $this->app = $app;
      $this->model = 'MyApp\Models\Servers';
  }

  function getServers() {
    $phql = "SELECT * FROM ".$this->model." ORDER BY name ASC";
    return $this->app->modelsManager->executeQuery($phql)->toArray();
  }

  function getSyncedServers() {
    $phql = "SELECT * FROM ".$this->model." WHERE synced = 2 ORDER BY name ASC";
    return $this->app->modelsManager->executeQuery($phql)->toArray();
  }

  function getPingedOpenVPNServers() {
    $phql = "SELECT * FROM ".$this->model." WHERE (synced = 1 or synced = 2) and type = 'openvpn' ORDER BY name ASC";
    return $this->app->modelsManager->executeQuery($phql)->toArray();
  }

  function getServerByIp($ip){
    $phql = "SELECT * FROM ".$this->model." WHERE ip=:ip:";
    return $this->app->modelsManager->executeQuery($phql,['ip'=>$ip])->toArray();
  }

  function deleteServerByDonor($donor){
    $phql  = "DELETE FROM ".$this->model." WHERE donor = :donor:";
    $res = $this->app->modelsManager->executeQuery($phql,['donor'=>$donor]);
    return $res;
  }

  function deleteServerByIp($ip){
    $phql  = "DELETE FROM ".$this->model." WHERE ip = :ip:";
    $res = $this->app->modelsManager->executeQuery($phql,['ip'=>$ip]);
    return $res;
  }

  function insertServer($fields){
    $phql = 'INSERT INTO '.$this->model;
    foreach ($fields as $key => $field) {
      $keys[] = $key;
      $values[] = ':'.$key.':';
    }
    $keyRes = implode(',',$keys);
    $valRes =  implode(',',$values);
    $phql = $phql.' ('.$keyRes.') VALUES ('.$valRes.')';
    $res = $this->app->modelsManager->executeQuery($phql,$fields);
    return  $res->getModel()->id;
  }

  function updateServer($fields,$id=0,$upd=false){
    $phql = 'UPDATE '.$this->model.' SET ';
    foreach ($fields as $key => $field) {
      if($upd!=$key){
        $values[] = $key.'=:'.$key.':';
      }
    }
    $valRes =  implode(', ',$values);
    if(!$upd){
      $phql = $phql.$valRes.' WHERE id='.$id;
    }else{
      $phql = $phql.$valRes.' WHERE '.$upd.'=:'.$upd.':';
    }
    $res = $this->app->modelsManager->executeQuery($phql,$fields);
    return $res;
  }
}