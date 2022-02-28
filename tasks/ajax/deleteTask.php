<?php
require_once '../includes/db.php'; // The mysql database connection script
if(isset($_GET['taskID'])){
  $taskID = intval($_GET['taskID']);

  $query="delete from Tasks_1234 where id='$taskID'";
  $result = $mysqli->query($query) or die($mysqli->error.__LINE__);

  $result = $mysqli->affected_rows;

  echo $json_response = json_encode($result);
}
