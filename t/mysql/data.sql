INSERT INTO `t1`
    ( `id`, `c1` )
VALUES
    -- main 
    ( 1, 'a' ),
    ( 2, NULL );

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
