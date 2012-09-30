--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = own, pg_catalog;

ALTER TABLE ONLY own.tp_point_2d DROP CONSTRAINT tp_point_2d_fkey_sv_survey_point;
ALTER TABLE ONLY own.tp_point_2d DROP CONSTRAINT tp_point_2d_fkey_sv_survey_document;
ALTER TABLE ONLY own.tp_node_2d DROP CONSTRAINT tp_node_2d_fkey_sv_survery_point;
ALTER TABLE ONLY own.im_parcel DROP CONSTRAINT im_parcel_fkey_tp_face_ed;
DROP TRIGGER check_position_for_point_2d_after_trigger ON own.tp_point_2d;
DROP TRIGGER check_point_for_node_2d_before_trigger ON own.tp_node_2d;
DROP TRIGGER check_point_for_node_2d_after_trigger ON own.tp_node_2d;
DROP TRIGGER check_nodelist_for_face_2d_before_trigger ON own.tp_face_2d;
DROP INDEX own.tp_point_2d_idx_tp_node_2d;
DROP INDEX own.tp_face_2d_idx_nodelist;
ALTER TABLE ONLY own.tp_point_2d DROP CONSTRAINT tp_point_2d_pkey;
ALTER TABLE ONLY own.tp_node_2d DROP CONSTRAINT tp_node_2d_unique_sv_survey_point;
ALTER TABLE ONLY own.tp_node_2d DROP CONSTRAINT tp_node_2d_pkey;
ALTER TABLE ONLY own.tp_face_2d DROP CONSTRAINT tp_face_2d_pkey;
ALTER TABLE ONLY own.sv_survey_point DROP CONSTRAINT sv_survey_point_pkey;
ALTER TABLE ONLY own.sv_survey_document DROP CONSTRAINT sv_survey_document_pkey;
ALTER TABLE ONLY own.im_parcel DROP CONSTRAINT im_parcel_tp_face_2d_key;
ALTER TABLE ONLY own.im_parcel DROP CONSTRAINT im_parcel_pkey;
ALTER TABLE own.tp_point_2d ALTER COLUMN nid DROP DEFAULT;
ALTER TABLE own.tp_node_2d ALTER COLUMN gid DROP DEFAULT;
ALTER TABLE own.tp_face_2d ALTER COLUMN gid DROP DEFAULT;
ALTER TABLE own.sv_survey_point ALTER COLUMN nid DROP DEFAULT;
ALTER TABLE own.sv_survey_document ALTER COLUMN nid DROP DEFAULT;
DROP SEQUENCE own.tp_point_2d_tp_node_2d_seq;
DROP SEQUENCE own.tp_point_2d_nid_seq;
DROP TABLE own.tp_point_2d;
DROP SEQUENCE own.tp_node_2d_sv_survey_point_seq;
DROP SEQUENCE own.tp_node_2d_gid_seq;
DROP TABLE own.tp_node_2d;
DROP SEQUENCE own.tp_face_2d_gid_seq;
DROP TABLE own.tp_face_2d;
DROP SEQUENCE own.sv_survey_point_nid_seq;
DROP TABLE own.sv_survey_point;
DROP SEQUENCE own.sv_survey_document_nid_seq;
DROP TABLE own.sv_survey_document;
DROP TABLE own.im_parcel;
DROP FUNCTION own.check_position_for_point_2d_after();
DROP FUNCTION own.check_point_for_node_2d_before();
DROP FUNCTION own.check_point_for_node_2d_after();
DROP FUNCTION own.check_nodelist_for_face_2d_before();
DROP TYPE own.position_2d;
DROP SCHEMA own;
--
-- Name: own; Type: SCHEMA; Schema: -; Owner: tdc
--

CREATE SCHEMA own;


ALTER SCHEMA own OWNER TO tdc;

SET search_path = own, pg_catalog;

--
-- Name: position_2d; Type: TYPE; Schema: own; Owner: tdc
--

CREATE TYPE position_2d AS (
x double precision,
y double precision
);


ALTER TYPE own.position_2d OWNER TO tdc;

--
-- Name: check_nodelist_for_face_2d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_nodelist_for_face_2d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  result boolean;
  geomtext text = 'POLYGON((';
  geomtextend text = '))';
  position position_2d%rowtype;
  isfirst boolean = true;
  actualnode bigint;
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    select count(1)=array_upper(NEW.nodelist,1) INTO result FROM tp_node_2d AS n WHERE ARRAY[n.gid] <@ NEW.nodelist;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face_2d INSERT/UPDATE. Rossz a lista: %', NEW.nodelist;
    END IF;
   
    --Vegig a csomopontokon
    FOREACH actualnode IN ARRAY NEW.nodelist LOOP

      --csomopontok koordinatainak kideritese
      SELECT p.x, p.y INTO position FROM sv_survey_point AS sp, tp_point_2d AS p, sv_survey_document AS sd, tp_node_2d AS n WHERE n.gid=actualnode AND n.sv_survey_point=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
      --Veszem a kovetkezo pontot
      geomtext = geomtext || position.x || ' ' || position.y || ',';

      IF isfirst THEN

        --Zarnom kell a poligont az elso ponttal
        geomtextend = position.x || ' ' || position.y || geomtextend;

      END IF;

      isfirst=false;

    END LOOP;

    --Most irom at a geometriat az uj ertekekre
    geomtext = geomtext || geomtextend;

--RAISE EXCEPTION' %', geomtext;
    NEW.geom := public.ST_GeomFromText( geomtext, -1 ); 

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_nodelist_for_face_2d_before() OWNER TO tdc;

--
-- Name: check_point_for_node_2d_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_point_for_node_2d_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  faces tp_face_2d%rowtype;
  facenumber integer;
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    --Csak azert hogy aktivalodjon a tp_face_2d trigger-e. Azok a face-ek amik tartalmazzak ezt a node-ot
    UPDATE tp_face_2d AS f set nodelist=nodelist WHERE ARRAY[NEW.gid] <@ f.nodelist;

  ELSIF(TG_OP='DELETE') THEN

    SELECT * INTO faces FROM tp_face_2d AS f WHERE ARRAY[OLD.gid] <@ f.nodelist;
    IF FOUND THEN

      RAISE EXCEPTION 'Nem törölhetem ki a csomópontot mert van legalabb 1 Face ami tartalmazza. gid: %, nodelist: %', face.gid, faces.nodelist;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_point_for_node_2d_after() OWNER TO tdc;

--
-- Name: check_point_for_node_2d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_point_for_node_2d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  geomtext text = 'POINT(';
  geomtextend text = ')';
  position position_2d%rowtype;
--  valt tp_point_2d%rowtype;
BEGIN

  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Megnezem az uj tp_node_2d-bez tartozo aktualis pont kooridinatait
    SELECT p.x, p.y INTO position FROM tp_point_2d AS p, sv_survey_point AS sp, sv_survey_document AS sd WHERE NEW.sv_survey_point=sp.nid AND sp.nid=p.sv_survey_point AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   

--select * into valt from tp_point_2d LIMIT 1;

    --Ha rendben van
    IF( position.x IS NOT NULL AND position.y IS NOT NULL ) THEN
      
      -- akkor a node geometriajat aktualizalja
      geomtext := geomtext || position.x || ' ' || position.y || geomtextend;
      NEW.geom := public.ST_GeomFromText( geomtext, -1 );
    ELSE

      RAISE EXCEPTION 'Nem vegrehajthato muvelet, mert a node-nak nem letezne akkor koordinataja.';

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_point_for_node_2d_before() OWNER TO tdc;

--
-- Name: check_position_for_point_2d_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_position_for_point_2d_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  nodegid bigint = NULL;
  spnid bigint = NULL;
BEGIN

  --Ha megvaltoztatok torlok vagy beszurok egy tp_point_2d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' OR TG_OP='DELETE' ) THEN

    --Ha ujat rogzitek vagy regit modositok
    IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

      --Akkor megnezi, hogy az uj-hoz van-e tp_node_2d
      SELECT n.gid INTO nodegid FROM tp_node_2d AS n, sv_survey_point AS sp, tp_point_2d as p WHERE NEW.nid=p.nid AND p.sv_survey_point=sp.nid AND sp.nid=n.sv_survey_point;

      --Ha van
      IF( nodegid IS NOT NULL ) THEN

        --Akkor update-elem, hogy aktivaljam a TRIGGER-et
        UPDATE tp_node_2d SET sv_survey_point=sv_survey_point WHERE gid=nodegid; 
  
      --Nincs
      ELSE 

        --Megkeresi a ponthoz tartozo survey point-ot
        SELECT sp.nid INTO spnid FROM sv_survey_point AS sp WHERE sp.nid=NEW.sv_survey_point;

        --Letre hozok egy uj tp_node_2d-t
        INSERT INTO tp_node_2d (sv_survey_point) VALUES ( spnid );

      END IF;

    END IF;

    --Ha torlok vagy modositok
    IF(TG_OP='UPDATE' OR TG_OP='DELETE') THEN

      UPDATE tp_node_2d AS n SET gid=gid from sv_survey_point AS sp WHERE OLD.sv_survey_point=sp.nid AND n.sv_survey_point=sp.nid;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_position_for_point_2d_after() OWNER TO tdc;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: im_parcel; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_parcel (
    tp_face_2d bigint NOT NULL,
    hrsz_main character varying(20) NOT NULL,
    hrsz_fraction character varying(3) NOT NULL
);


ALTER TABLE own.im_parcel OWNER TO tdc;

SET default_with_oids = false;

--
-- Name: sv_survey_document; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_document (
    nid bigint NOT NULL,
    date date DEFAULT ('now'::text)::date NOT NULL,
    data text
);


ALTER TABLE own.sv_survey_document OWNER TO tdc;

--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE sv_survey_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.sv_survey_document_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE sv_survey_document_nid_seq OWNED BY sv_survey_document.nid;


--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_document_nid_seq', 4, true);


--
-- Name: sv_survey_point; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_point (
    nid bigint NOT NULL,
    dimension integer DEFAULT 2,
    description text
);


ALTER TABLE own.sv_survey_point OWNER TO tdc;

--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE sv_survey_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.sv_survey_point_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE sv_survey_point_nid_seq OWNED BY sv_survey_point.nid;


--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_point_nid_seq', 11, true);


SET default_with_oids = true;

--
-- Name: tp_face_2d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_face_2d (
    gid bigint NOT NULL,
    nodelist bigint[] NOT NULL,
    geom public.geometry(Polygon)
);


ALTER TABLE own.tp_face_2d OWNER TO tdc;

--
-- Name: tp_face_2d_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_face_2d_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_face_2d_gid_seq OWNER TO tdc;

--
-- Name: tp_face_2d_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_face_2d_gid_seq OWNED BY tp_face_2d.gid;


--
-- Name: tp_face_2d_gid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_face_2d_gid_seq', 2, true);


SET default_with_oids = false;

--
-- Name: tp_node_2d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_node_2d (
    gid bigint NOT NULL,
    geom public.geometry(Point),
    sv_survey_point bigint NOT NULL
);


ALTER TABLE own.tp_node_2d OWNER TO tdc;

--
-- Name: tp_node_2d_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_node_2d_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_node_2d_gid_seq OWNER TO tdc;

--
-- Name: tp_node_2d_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_node_2d_gid_seq OWNED BY tp_node_2d.gid;


--
-- Name: tp_node_2d_gid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_2d_gid_seq', 43, true);


--
-- Name: tp_node_2d_sv_survey_point_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_node_2d_sv_survey_point_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_node_2d_sv_survey_point_seq OWNER TO tdc;

--
-- Name: tp_node_2d_sv_survey_point_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_node_2d_sv_survey_point_seq OWNED BY tp_node_2d.sv_survey_point;


--
-- Name: tp_node_2d_sv_survey_point_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_2d_sv_survey_point_seq', 1, false);


--
-- Name: tp_point_2d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_point_2d (
    nid bigint NOT NULL,
    x numeric(8,2) NOT NULL,
    y numeric(8,2) NOT NULL,
    quality integer,
    sv_survey_document bigint NOT NULL,
    sv_survey_point bigint NOT NULL
);


ALTER TABLE own.tp_point_2d OWNER TO tdc;

--
-- Name: tp_point_2d_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_point_2d_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_point_2d_nid_seq OWNER TO tdc;

--
-- Name: tp_point_2d_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_point_2d_nid_seq OWNED BY tp_point_2d.nid;


--
-- Name: tp_point_2d_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_point_2d_nid_seq', 18, true);


--
-- Name: tp_point_2d_tp_node_2d_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_point_2d_tp_node_2d_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_point_2d_tp_node_2d_seq OWNER TO tdc;

--
-- Name: tp_point_2d_tp_node_2d_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_point_2d_tp_node_2d_seq OWNED BY tp_point_2d.sv_survey_point;


--
-- Name: tp_point_2d_tp_node_2d_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_point_2d_tp_node_2d_seq', 11, true);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY sv_survey_document ALTER COLUMN nid SET DEFAULT nextval('sv_survey_document_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY sv_survey_point ALTER COLUMN nid SET DEFAULT nextval('sv_survey_point_nid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_face_2d ALTER COLUMN gid SET DEFAULT nextval('tp_face_2d_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_2d ALTER COLUMN gid SET DEFAULT nextval('tp_node_2d_gid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_2d ALTER COLUMN nid SET DEFAULT nextval('tp_point_2d_nid_seq'::regclass);


--
-- Data for Name: im_parcel; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO im_parcel VALUES (1, '4523', '1');
INSERT INTO im_parcel VALUES (2, '4523', '2');
INSERT INTO im_parcel VALUES (3, '4523', '3');
INSERT INTO im_parcel VALUES (4, '4526', '');


--
-- Data for Name: sv_survey_document; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO sv_survey_document VALUES (1, '2012-09-29', 'A következő pontok felmérése történt meg:
1,2,3,4,5,6,7,8,9,10,11');
INSERT INTO sv_survey_document VALUES (2, '2012-09-30', 'ezt majd toroljuk');
INSERT INTO sv_survey_document VALUES (3, '2012-10-01', 'harmadik');
INSERT INTO sv_survey_document VALUES (4, '2012-09-28', 'negyedik');


--
-- Data for Name: sv_survey_point; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO sv_survey_point VALUES (1, 2, '');
INSERT INTO sv_survey_point VALUES (2, 2, '');
INSERT INTO sv_survey_point VALUES (3, 2, '');
INSERT INTO sv_survey_point VALUES (4, 2, '');
INSERT INTO sv_survey_point VALUES (5, 2, '');
INSERT INTO sv_survey_point VALUES (6, 2, '');
INSERT INTO sv_survey_point VALUES (7, 2, '');
INSERT INTO sv_survey_point VALUES (8, 2, '');
INSERT INTO sv_survey_point VALUES (9, 2, '');
INSERT INTO sv_survey_point VALUES (10, 2, '');
INSERT INTO sv_survey_point VALUES (11, 2, '');


--
-- Data for Name: tp_face_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO tp_face_2d VALUES (1, '{1,2,4,3}', '010300000001000000050000000AD7A3708CB22341F6285C8FE4D10B41D7A370BDADB2234114AE47E134D20B418FC2F5A8C0B223417B14AE47B7D10B4100000000A0B22341C3F5285C65D10B410AD7A3708CB22341F6285C8FE4D10B41');
INSERT INTO tp_face_2d VALUES (4, '{3,4,6,9,10,11}', '0103000000010000000700000000000000A0B22341C3F5285C65D10B418FC2F5A8C0B223417B14AE47B7D10B41AE47E17AE2B22341000000000AD20B41E17A142E09B323413D0AD7A36ED20B4185EB513813B32341AE47E17A32D20B413D0AD723A9B22341713D0AD729D10B4100000000A0B22341C3F5285C65D10B41');
INSERT INTO tp_face_2d VALUES (2, '{2,5,6,4}', '01030000000100000005000000D7A370BDADB2234114AE47E134D20B41295C8F42CFB22341295C8FC285D20B41AE47E17AE2B22341000000000AD20B418FC2F5A8C0B223417B14AE47B7D10B41D7A370BDADB2234114AE47E134D20B41');
INSERT INTO tp_face_2d VALUES (3, '{5,7,8,9,6}', '01030000000100000006000000295C8F42CFB22341295C8FC285D20B41B81E856BDFB223410AD7A370ADD20B41AE47E17AF6B22341295C8FC2E5D20B41E17A142E09B323413D0AD7A36ED20B41AE47E17AE2B22341000000000AD20B41295C8F42CFB22341295C8FC285D20B41');


--
-- Data for Name: tp_node_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO tp_node_2d VALUES (6, '0101000000AE47E17AE2B22341000000000AD20B41', 6);
INSERT INTO tp_node_2d VALUES (7, '0101000000B81E856BDFB223410AD7A370ADD20B41', 7);
INSERT INTO tp_node_2d VALUES (8, '0101000000AE47E17AF6B22341295C8FC2E5D20B41', 8);
INSERT INTO tp_node_2d VALUES (9, '0101000000E17A142E09B323413D0AD7A36ED20B41', 9);
INSERT INTO tp_node_2d VALUES (10, '010100000085EB513813B32341AE47E17A32D20B41', 10);
INSERT INTO tp_node_2d VALUES (11, '01010000003D0AD723A9B22341713D0AD729D10B41', 11);
INSERT INTO tp_node_2d VALUES (5, '0101000000295C8F42CFB22341295C8FC285D20B41', 5);
INSERT INTO tp_node_2d VALUES (1, '01010000000AD7A3708CB22341F6285C8FE4D10B41', 1);
INSERT INTO tp_node_2d VALUES (2, '0101000000D7A370BDADB2234114AE47E134D20B41', 2);
INSERT INTO tp_node_2d VALUES (3, '010100000000000000A0B22341C3F5285C65D10B41', 3);
INSERT INTO tp_node_2d VALUES (4, '01010000008FC2F5A8C0B223417B14AE47B7D10B41', 4);


--
-- Data for Name: tp_point_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--

INSERT INTO tp_point_2d VALUES (1, 645446.22, 227900.57, 1, 1, 1);
INSERT INTO tp_point_2d VALUES (2, 645462.87, 227910.61, 1, 1, 2);
INSERT INTO tp_point_2d VALUES (3, 645456.00, 227884.67, 1, 1, 3);
INSERT INTO tp_point_2d VALUES (4, 645472.33, 227894.91, 1, 1, 4);
INSERT INTO tp_point_2d VALUES (6, 645489.24, 227905.25, 1, 1, 6);
INSERT INTO tp_point_2d VALUES (7, 645487.71, 227925.68, 1, 1, 7);
INSERT INTO tp_point_2d VALUES (8, 645499.24, 227932.72, 1, 1, 8);
INSERT INTO tp_point_2d VALUES (9, 645508.59, 227917.83, 1, 1, 9);
INSERT INTO tp_point_2d VALUES (10, 645513.61, 227910.31, 1, 1, 10);
INSERT INTO tp_point_2d VALUES (11, 645460.57, 227877.23, 1, 1, 11);
INSERT INTO tp_point_2d VALUES (5, 645479.63, 227920.72, 1, 1, 5);


--
-- Name: im_parcel_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_pkey PRIMARY KEY (hrsz_main, hrsz_fraction);


--
-- Name: im_parcel_tp_face_2d_key; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_tp_face_2d_key UNIQUE (tp_face_2d);


--
-- Name: sv_survey_document_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_document
    ADD CONSTRAINT sv_survey_document_pkey PRIMARY KEY (nid);


--
-- Name: sv_survey_point_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_point
    ADD CONSTRAINT sv_survey_point_pkey PRIMARY KEY (nid);


--
-- Name: tp_face_2d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face_2d
    ADD CONSTRAINT tp_face_2d_pkey PRIMARY KEY (gid);


--
-- Name: tp_node_2d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node_2d
    ADD CONSTRAINT tp_node_2d_pkey PRIMARY KEY (gid);


--
-- Name: tp_node_2d_unique_sv_survey_point; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node_2d
    ADD CONSTRAINT tp_node_2d_unique_sv_survey_point UNIQUE (sv_survey_point);


--
-- Name: tp_point_2d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_point_2d
    ADD CONSTRAINT tp_point_2d_pkey PRIMARY KEY (nid);


--
-- Name: tp_face_2d_idx_nodelist; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_2d_idx_nodelist ON tp_face_2d USING gin (nodelist);


--
-- Name: tp_point_2d_idx_tp_node_2d; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_point_2d_idx_tp_node_2d ON tp_point_2d USING btree (sv_survey_point);


--
-- Name: check_nodelist_for_face_2d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_nodelist_for_face_2d_before_trigger BEFORE INSERT OR UPDATE ON tp_face_2d FOR EACH ROW EXECUTE PROCEDURE check_nodelist_for_face_2d_before();


--
-- Name: check_point_for_node_2d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_2d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_node_2d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_2d_after();


--
-- Name: check_point_for_node_2d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_2d_before_trigger BEFORE INSERT OR UPDATE ON tp_node_2d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_2d_before();


--
-- Name: check_position_for_point_2d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_position_for_point_2d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_point_2d FOR EACH ROW EXECUTE PROCEDURE check_position_for_point_2d_after();


--
-- Name: im_parcel_fkey_tp_face_ed; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_fkey_tp_face_ed FOREIGN KEY (tp_face_2d) REFERENCES tp_face_2d(gid);


--
-- Name: tp_node_2d_fkey_sv_survery_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_2d
    ADD CONSTRAINT tp_node_2d_fkey_sv_survery_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- Name: tp_point_2d_fkey_sv_survey_document; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_2d
    ADD CONSTRAINT tp_point_2d_fkey_sv_survey_document FOREIGN KEY (sv_survey_document) REFERENCES sv_survey_document(nid);


--
-- Name: tp_point_2d_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_2d
    ADD CONSTRAINT tp_point_2d_fkey_sv_survey_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- PostgreSQL database dump complete
--