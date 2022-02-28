DROP DATABASE IF EXISTS payjoy;
CREATE DATABASE payjoy;

CREATE USER 'payjoy'@'%' IDENTIFIED BY 'psswrd' ;
GRANT ALL ON *.* TO 'payjoy'@'%' WITH GRANT OPTION ;

USE `payjoy`;

-- add "_1234" to all tables to keep things separate

DROP TABLE IF EXISTS `Tasks_1234`;

CREATE TABLE `Tasks_1234` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task` varchar(200) NOT NULL,
  `status` int(11) NOT NULL,
  `created_at` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1  ;

--
-- Dumping data for table `tasks`
--

INSERT INTO `Tasks_1234` (`id`, `task`, `status`, `created_at`) VALUES
(1, 'My first task', 0, 1390815970),
(2, 'Perform unit testing', 2, 1390815993),
(3, 'Find bugs', 2, 1390817659),
(4, 'Test in small devices', 2, 1390818389);
