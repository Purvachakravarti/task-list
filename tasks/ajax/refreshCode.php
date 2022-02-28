<?php
require_once '../includes/db.php'; // The mysql database connection script



// checkout the right branch
$command = "git checkout master";
$output = shell_exec($command);

$command = "./../scripts/git-pull.sh";
$output = shell_exec($command);

// run tasks.sql
$command = "mysql --user={$mysql_user} --password='{$mysql_pw}' "
  . "-h {$mysql_host} -D {$mysql_db} < '" . __DIR__ . "/../tasks.sql'";

$output = shell_exec($command);

