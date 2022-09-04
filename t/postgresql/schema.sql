-- root table
CREATE TABLE "t1" (
    "id" bigint not null,
    "c_01" char( 1 ),
    "c_02" varchar( 8 ),
    "c_03" text,
    "c_04" smallint,
    "c_05" int,
    "c_06" bigint,
    "c_07" numeric( 8, 2 ),
    "c_08" real,
    "c_09" double precision,
    "c_10" bytea,
    "c_11" boolean,
    "c_12" int[],
    PRIMARY KEY ( "id" )
);

-- not nullable single column relation
CREATE TABLE "t2" (
    "id" bigint not null,
    "t1_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" )
);

-- not nullable relations of different lengths,
-- shorter one should be chosen
CREATE TABLE "t3" (
    "id" bigint not null,
    "t1_id" bigint not null,
    "t2_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" ),
    FOREIGN KEY ( "t2_id" ) REFERENCES "t2" ( "id" )
);

-- not nullable relations longer than nullable one,
-- not nullable one should be chosen
CREATE TABLE "t4" (
    "id" bigint not null,
    "t1_id" bigint null,
    "t2_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" ),
    FOREIGN KEY ( "t2_id" ) REFERENCES "t2" ( "id" ),
    UNIQUE ( "t1_id", "t2_id" )
);

-- multi column relation
CREATE TABLE "t5" (
    "id" bigint not null,
    "t4_t1_id" bigint not null,
    "t4_t2_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t4_t1_id", "t4_t2_id" ) REFERENCES "t4" ( "t1_id", "t2_id" )
);

-- self loop
CREATE TABLE "t6" (
    "id" bigint not null,
    "t1_id" bigint not null,
    "t6_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" ),
    FOREIGN KEY ( "t6_id" ) REFERENCES "t6" ( "id" )
);

-- long loop
CREATE TABLE "t7" (
    "id" bigint not null,
    "t1_id" bigint not null,
    "t8_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" )
);
CREATE TABLE "t8" (
    "id" bigint not null,
    "t1_id" bigint not null,
    "t7_id" bigint not null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_id" ) REFERENCES "t1" ( "id" ),
    FOREIGN KEY ( "t7_id" ) REFERENCES "t7" ( "id" )
);
ALTER TABLE "t7" ADD FOREIGN KEY ( "t8_id" ) REFERENCES "t8" ( "id" );

-- horse riddle
CREATE TABLE "t9" (
    "id" bigint not null,
    "t1_1_id" bigint null,
    "t1_2_id" bigint null,
    PRIMARY KEY ( "id" ),
    FOREIGN KEY ( "t1_1_id" ) REFERENCES "t1" ( "id" ),
    FOREIGN KEY ( "t1_2_id" ) REFERENCES "t1" ( "id" )
);

CREATE VIEW "v1" AS SELECT * FROM "t1";
