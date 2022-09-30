<?
namespace VPN;

class User{
   public $app;
   public $model;

  function __construct($app,$model=null) {
      $this->app = $app;
      $this->model = 'MyApp\Models\Users';
  }

  function getUsers() {
    $phql = "SELECT * FROM ".$this->model." ORDER BY id DESC";
    return $this->app->modelsManager->executeQuery($phql)->toArray();
  }

  function removeVerificationCodes() {
    $phql = "UPDATE ".$this->model." SET verificationCodeExpiration = NULL, verificationCode = NULL WHERE verificationCodeExpiration < NOW()";
    $res = $this->app->modelsManager->executeQuery($phql);
    return $res;
  }

  function removeSubscription() {
    $phql = "UPDATE ".$this->model." SET isPremium = 0, subscriptionEndDate = NULL WHERE subscriptionEndDate < NOW()";
    $res = $this->app->modelsManager->executeQuery($phql);
    return $res;
  }

  function getUserById($id){
    $phql = "SELECT * FROM ".$this->model." WHERE id=:id:";
    return $this->app->modelsManager->executeQuery($phql,['id'=>$id])->toArray();
  }

  function getUserByEmail($email){
    $phql = "SELECT * FROM ".$this->model." WHERE email=:email:";
    return $this->app->modelsManager->executeQuery($phql,['email'=>$email])->toArray();
  }

  function getUserByAppStorePurchaseId($purchaseID){
    $phql = "SELECT * FROM ".$this->model." WHERE appStorePurchaseId=:appStorePurchaseId:";
    return $this->app->modelsManager->executeQuery($phql,['appStorePurchaseId'=>$purchaseID])->toArray();
  }

  function getUserByPlayStorePurchaseId($purchaseID){
    $phql = "SELECT * FROM ".$this->model." WHERE googlePlayPurchaseId=:googlePlayPurchaseId:";
    return $this->app->modelsManager->executeQuery($phql,['googlePlayPurchaseId'=>$purchaseID])->toArray();
  }

  function getUserByToken($token){
    $phql = "SELECT * FROM ".$this->model." WHERE token=:token:";
    return $this->app->modelsManager->executeQuery($phql,['token'=>$token])->toArray();
  }

  function deleteUser($id){
    $phql  = "DELETE FROM ".$this->model." WHERE id = :id:";
    $res = $this->app->modelsManager->executeQuery($phql,['id'=>$id]);
    return $res;
  }

  function getLastUserId(){
    $phql = "SELECT MAX(id) FROM ".$this->model."";
    return $this->app->modelsManager->executeQuery($phql)->toArray()[0]["0"];
  }

  function insertUser($fields){
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

  function updateUser($fields,$id=0,$upd=false){
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