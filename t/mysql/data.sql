INSERT INTO `t1`
    ( `id`, `c_01`, `c_02`, `c_03`, `c_04`, `c_05`, `c_06`, `c_07`, `c_08`, `c_09`, `c_10`, `c_11`, `c_12`, `c_13`, `c_14`, `c_15`, `c_16`, `c_17`, `c_18` )
VALUES
    -- main 
    ( 1, 'a', 'a', 'a', 'a', 'a', 'a', -1, 1, 1, 1, 18446744073709551615, 1.1, -1/3, 1/3, unhex( '00' ), unhex( '00' ), unhex( '00' ), unhex( '00' ) ),
    ( 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL );

INSERT INTO `t2`
    ( `id`, `t1_id` )
VALUES
    ( 1, 1 ),
    ( 2, 1 ),
    -- only row that belongs to id = 2 root tree
    ( 3, 2 );

INSERT INTO `t3`
    ( `id`, `t1_id`, `t2_id` )
VALUES
    ( 1, 1, 1 ),
    ( 2, 1, 2 );
