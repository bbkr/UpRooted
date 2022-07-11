-- root table
CREATE TABLE `t1` (
    `id` bigint unsigned not null,
    `c1` char( 1 ),
    PRIMARY KEY ( `id` )
) Engine = InnoDB;

-- not nullable single column relation
CREATE TABLE `t2` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` )
) Engine = InnoDB;

-- not nullable relations of different lengths,
-- shorter one should be chosen
CREATE TABLE `t3` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned not null,
    `t2_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` ),
    FOREIGN KEY ( `t2_id` ) REFERENCES `t2` ( `id` )
) Engine = InnoDB;

-- not nullable relations longer than nullable one,
-- not nullable one should be chosen
CREATE TABLE `t4` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned null,
    `t2_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` ),
    FOREIGN KEY ( `t2_id` ) REFERENCES `t2` ( `id` ),
    KEY( `t1_id`, `t2_id` )
) Engine = InnoDB;

-- multi column relation
CREATE TABLE `t5` (
    `id` bigint unsigned not null,
    `t4_t1_id` bigint unsigned not null,
    `t4_t2_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t4_t1_id`, `t4_t2_id` ) REFERENCES `t4` ( `t1_id`, `t2_id` )
) Engine = InnoDB;

-- self loop
CREATE TABLE `t6` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned not null,
    `t6_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` ),
    FOREIGN KEY ( `t6_id` ) REFERENCES `t6` ( `id` )
) Engine = InnoDB;

-- long loop
CREATE TABLE `t7` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned not null,
    `t8_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` )
) Engine = InnoDB;
CREATE TABLE `t8` (
    `id` bigint unsigned not null,
    `t1_id` bigint unsigned not null,
    `t7_id` bigint unsigned not null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_id` ) REFERENCES `t1` ( `id` ),
    FOREIGN KEY ( `t7_id` ) REFERENCES `t7` ( `id` )
) Engine = InnoDB;
ALTER TABLE `t7` ADD FOREIGN KEY ( `t8_id` ) REFERENCES `t8` ( `id` );

-- horse riddle
CREATE TABLE `t9` (
    `id` bigint unsigned not null,
    `t1_1_id` bigint unsigned null,
    `t1_2_id` bigint unsigned null,
    PRIMARY KEY ( `id` ),
    FOREIGN KEY ( `t1_1_id` ) REFERENCES `t1` ( `id` ),
    FOREIGN KEY ( `t1_2_id` ) REFERENCES `t1` ( `id` )
) Engine = InnoDB;

CREATE VIEW `v1` AS SELECT * FROM `t1`;
