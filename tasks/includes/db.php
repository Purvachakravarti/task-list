<?php
require_once('../../credentials/database.php');

global $mysql_host,
       $mysql_user,
       $mysql_pw,
       $mysql_db,
       $mysql_port,
       $mysql_ca_cert,
       $mysql_host_readonly,
       $mysql_user_readonly,
       $mysql_pw_readonly,
       $mysql_db_readonly,
       $mysql_ca_cert_readonly;

$mysql_host = "127.0.0.1";

class LazyMysqli
{

  protected $mysqli;
  protected $host;
  protected $db;
  protected $user;
  protected $pw;

  public function __construct($host, $user, $pw, $db, $port, $ca_cert = NULL)
  {
    $this->host = $host;
    $this->user = $user;
    $this->pw = $pw;
    $this->db = $db;
    $this->port = $port;
    $this->ca_cert = $ca_cert;
  }

  public function __call($method_name, $args)
  {
    if (!isset($this->mysqli)) {
      $this->init_mysqli();
    }
    return call_user_func_array([$this->mysqli, $method_name], $args);
  }

  public function __get($name)
  {
    if (!isset($this->mysqli)) {
      $this->init_mysqli();
    }
    return $this->mysqli->{$name};
  }

  private function init_mysqli()
  {

    // NOTE: 2019-08-28, Yunfan - For most use-cases, $MYSQL_USE_SSL is
    //       unnecessary, as we're almost always either in an AWS VPC, in the
    //       same subnet, or for test environments, on the same local machine.
    //
    //       At the time of writing, it is only for prod-india (read: Airtel)
    //       that we need this, because the database lives in their cloud,
    //       which we access through the public network.
    //
    //       It is set to TRUE in server-settings.php.credentials.india.
    //
    // WARNING: When $mysql_host="localhost" PHP will connect via Unix socket
    //          and SSL WILL ALWAYS BE IGNORED!!!
    //
    //          Source: https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_require_secure_transport
    //
    global $MYSQL_USE_SSL;

    if (!isset($MYSQL_USE_SSL) || !$MYSQL_USE_SSL) {

      $this->mysqli = new mysqli($this->host,
        $this->user,
        $this->pw,
        $this->db,
        $this->port)
      or die("Could not open mysql connection");

    } else {

      // Since we have the contents of the file in $this->ca_cert, using
      // php://memory allows us to skip the unnecessary intermediate step
      // of writing the contents to a file, only to read it back in the
      // ssl_set() call.
      //
      // See: https://stackoverflow.com/a/9018844
      //
      $fp = fopen("php://memory", "w");
      fwrite($fp, $this->ca_cert);
      rewind($fp);

      $this->mysqli = mysqli_init();
      $this->mysqli->ssl_set(NULL, NULL, "php://memory", NULL, NULL);
      $this->mysqli->real_connect($this->host,
        $this->user,
        $this->pw,
        $this->db,
        $this->port,
        null,
        MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT)
      or die("Could not open mysql connection");

    }

    $this->mysqli->set_charset("utf8");
  }
}


$mysqli = new LazyMysqli($mysql_host,
  $mysql_user,
  $mysql_pw,
  $mysql_db,
  $mysql_port,
  $mysql_ca_cert);
$mysqli_readonly = new LazyMysqli($mysql_host_readonly,
  $mysql_user_readonly,
  $mysql_pw_readonly,
  $mysql_db_readonly,
  $mysql_port,
  $mysql_ca_cert_readonly);
