CREATE TABLE `locations` (
	`location_id` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`parent_id` INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`location` VARCHAR(100) NOT NULL DEFAULT '',
	`display_order` INT(10) NOT NULL DEFAULT '0',
	PRIMARY KEY (`location_id`),
	INDEX `location` (`location`),
	INDEX `parent_id` (`parent_id`),
	INDEX `display_order` (`display_order`)
);