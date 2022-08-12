-- root table
INSERT INTO `t1`
    ( `id`, `c_01`, `c_02`, `c_03`, `c_04`, `c_05`, `c_06`, `c_07`, `c_08`, `c_09`, `c_10`, `c_11`, `c_12`, `c_13`, `c_14`, `c_15`, `c_16`, `c_17`, `c_18` )
VALUES
    -- main 
    ( 1, 'a', '😀😔', 'a', 'a', 'a', '😀😔', -1, 1, 1, 1, 18446744073709551615, 1.1, -1/3, 1/3, unhex( '00' ), unhex( '00' ), unhex( '00' ), unhex( '00' ) ),
    ( 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL );

-- not nullable single column relation
INSERT INTO `t2`
    ( `id`, `t1_id` )
VALUES
    ( 1, 1 ),
    ( 2, 1 ),
    -- only row that belongs to id = 2 root tree
    ( 3, 2 );

-- not nullable relations of different lengths
INSERT INTO `t3`
    ( `id`, `t1_id`, `t2_id` )
VALUES
    ( 1, 1, 1 ),
    ( 2, 1, 2 );

-- not nullable relations longer than nullable one
INSERT INTO `t4`
    ( `id`, `t1_id`, `t2_id` )
VALUES
    ( 1, 1, 1 );

-- multi column relation
INSERT INTO `t5`
    ( `id`, `t4_t1_id`, `t4_t2_id` )
VALUES
    ( 1, 1, 1 );

-- self loop
INSERT INTO `t6`
    ( `id`, `t1_id`, `t6_id` )
VALUES
    ( 1, 1, 1 );
    
-- long loop
SET foreign_key_checks = 0;
INSERT INTO `t7`
    ( `id`, `t1_id`, `t8_id` )
VALUES
    ( 1, 1, 1 );
INSERT INTO `t8`
    ( `id`, `t1_id`, `t7_id` )
VALUES
    ( 1, 1, 1 );
SET foreign_key_checks = 1;
