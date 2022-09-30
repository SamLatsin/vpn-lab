<?
namespace VPN;

class App{
   public $app;

  function __construct($app,$token=null,$admin=true,$ip=false) {
      $this->app = $app; 
  }
}