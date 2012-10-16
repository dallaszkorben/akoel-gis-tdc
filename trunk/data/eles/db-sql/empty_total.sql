--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

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
-- Name: position_3d; Type: TYPE; Schema: own; Owner: tdc
--

CREATE TYPE position_3d AS (
x double precision,
y double precision,
z double precision
);


ALTER TYPE own.position_3d OWNER TO tdc;

--
-- Name: check_facelist_for_volume_3d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_facelist_for_volume_3d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  result boolean;
  geomtext text = 'POLYHEDRALSURFACE((';
  position position_3d%rowtype;
  isfirstnode boolean;
  isfirstface boolean;
  actualface bigint;
  actualnode bigint;
  ndlist bigint[];
  face_base text;
  face_end text;
  face text;
  polyhedral_base text;
  polyhedral text;
BEGIN

  --Ha modositom, vagy ujat szurok be
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --akkor megnezem, hogy a lista helyes-e. Letezo face-ek szerepelnek-e benne megfelelo szamban
    select count(1)=array_upper(NEW.facelist,1) INTO result FROM tp_face_3d AS f WHERE ARRAY[f.gid] <@ NEW.facelist;

   --Ha nem megfelelo meretu a lista
    if( NOT result  ) THEN

        --akkor nem vegrehajthato a muvelet
        RAISE EXCEPTION 'Nem vegrehajthato a tp_volume_3d INSERT/UPDATE. Rossz a lista: %', NEW.facelist;
    END IF;

    isfirstface=true;
    polyhedral_base='';

    --Vegig a face-eken
    FOREACH actualface IN ARRAY NEW.facelist LOOP

      --A face csomopontjainak osszegyujtese
      SELECT f.nodelist INTO ndlist FROM tp_face_3d as f WHERE f.gid=actualface;

      --valtozok elokeszitese a face osszeallitasahoz csomopontok alapjan
      face_base='((';
      face_end='))';
      isfirstnode=true;

      --Vegig a face csomopontjain
      FOREACH actualnode IN ARRAY ndlist LOOP

        --csomopontok koordinatainak kideritese
        SELECT p.x, p.y, p.z INTO position FROM sv_survey_point AS sp, tp_point_3d AS p, sv_survey_document AS sd, tp_node_3d AS n WHERE n.gid=actualnode AND n.sv_survey_point=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
        --Veszem a kovetkezo pontot
        face_base = face_base || position.x || ' ' || position.y || ' ' || position.z || ',';

        IF isfirstnode THEN

          --Zarnom kell a poligont az elso ponttal
          face_end = position.x || ' ' || position.y || ' ' || position.z || face_end;

          --jelzem, hogy a kovetkezo pont mar nem az elso lesz
          isfirstnode=false;

        END IF;

      END LOOP;  --csomopont gyujto ciklus zarasa

      --Itt rendelkezesemre all egy (x1 y1 z1, x2 y2 z2, ... ) formatumu string
      face = face_base || face_end;

      --Ha ez az elso face
      IF isfirstface THEN

        --akkor jelzem, hogy a kovetkezo mar nem az elso
        isfirstface=false;

      --Ha mar volt face
      ELSE

        --akkor az elejere kell egy vesszo
        polyhedral_base = polyhedral_base || ', ';

      END IF;

      polyhedral_base = polyhedral_base || face;

    END LOOP;   --face gyujto ciklus zarasa

    polyhedral='POLYHEDRALSURFACE(' || polyhedral_base || ')';

    NEW.geom := public.ST_GeomFromText( polyhedral, -1 );
   
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_facelist_for_volume_3d_before() OWNER TO tdc;

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
-- Name: check_nodelist_for_face_3d_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_nodelist_for_face_3d_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  volume tp_volume_3d%rowtype;
  facenumber integer;
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    --Csak azert hogy aktivalodjon a tp_volume_3d trigger-e. Azok a volume-k amik tartalmazzak ezt a face-t
    UPDATE tp_volume_3d AS v set facelist=facelist WHERE ARRAY[NEW.gid] <@ v.facelist;

  ELSIF(TG_OP='DELETE') THEN

    SELECT * INTO volume FROM tp_volume_3d AS v WHERE ARRAY[OLD.gid] <@ v.facelist;
    IF FOUND THEN

      RAISE EXCEPTION 'Nem törölhetem ki a tp_face_3d.gid: % Face-t mert van legalabb 1 tp_volume_3d.gid: % Volume, ami tartalmazza. Facelist: %', OLD.gid, volume.gid, volume.facelist;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_nodelist_for_face_3d_after() OWNER TO tdc;

--
-- Name: check_nodelist_for_face_3d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_nodelist_for_face_3d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  result boolean;
  geomtext text = 'POLYGON((';
  geomtextend text = '))';
  position position_3d%rowtype;
  isfirst boolean = true;
  actualnode bigint;
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    select count(1)=array_upper(NEW.nodelist,1) INTO result FROM tp_node_3d AS n WHERE ARRAY[n.gid] <@ NEW.nodelist;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face_3d INSERT/UPDATE. Rossz a lista: %', NEW.nodelist;
    END IF;
   
    --Vegig a csomopontokon
    FOREACH actualnode IN ARRAY NEW.nodelist LOOP

      --csomopontok koordinatainak kideritese
      SELECT p.x, p.y, p.z INTO position FROM sv_survey_point AS sp, tp_point_3d AS p, sv_survey_document AS sd, tp_node_3d AS n WHERE n.gid=actualnode AND n.sv_survey_point=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
      --Veszem a kovetkezo pontot
      geomtext = geomtext || position.x || ' ' || position.y || ' ' || position.z || ',';

      IF isfirst THEN

        --Zarnom kell a poligont az elso ponttal
        geomtextend = position.x || ' ' || position.y || ' ' || position.z || geomtextend;

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


ALTER FUNCTION own.check_nodelist_for_face_3d_before() OWNER TO tdc;

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
-- Name: check_point_for_node_3d_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_point_for_node_3d_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  faces tp_face_3d%rowtype;
  facenumber integer;
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    --Csak azert hogy aktivalodjon a tp_face_3d trigger-e. Azok a face-ek amik tartalmazzak ezt a node-ot
    UPDATE tp_face_3d AS f set nodelist=nodelist WHERE ARRAY[NEW.gid] <@ f.nodelist;

  ELSIF(TG_OP='DELETE') THEN

    SELECT * INTO faces FROM tp_face_3d AS f WHERE ARRAY[OLD.gid] <@ f.nodelist;
    IF FOUND THEN

      RAISE EXCEPTION 'Nem törölhetem ki a csomópontot mert van legalabb 1 Face ami tartalmazza. gid: %, nodelist: %', face.gid, faces.nodelist;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_point_for_node_3d_after() OWNER TO tdc;

--
-- Name: check_point_for_node_3d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_point_for_node_3d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  geomtext text = 'POINT(';
  geomtextend text = ')';
  position position_3d%rowtype;
--  valt tp_point_3d%rowtype;
BEGIN

  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Megnezem az uj tp_node_3d-bez tartozo aktualis pont kooridinatait
    SELECT p.x, p.y, p.z INTO position FROM tp_point_3d AS p, sv_survey_point AS sp, sv_survey_document AS sd WHERE NEW.sv_survey_point=sp.nid AND sp.nid=p.sv_survey_point AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   

    --Ha rendben van
    IF( position.x IS NOT NULL AND position.y IS NOT NULL AND position.z IS NOT NULL) THEN
      
      -- akkor a node geometriajat aktualizalja
      geomtext := geomtext || position.x || ' ' || position.y || ' ' || position.z || geomtextend;
      NEW.geom := public.ST_GeomFromText( geomtext, -1 );
    ELSE

      RAISE EXCEPTION 'Nem vegrehajthato muvelet, mert a node-nak nem letezne akkor koordinataja.';

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_point_for_node_3d_before() OWNER TO tdc;

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

--
-- Name: check_position_for_point_2d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_position_for_point_2d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  pointnid bigint = NULL;
BEGIN

  --Ha megvaltoztatok vagy beszurok egy tp_point_2d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN


      --Akkor megnezi, hogy az uj egy 2D-s survey_point-hoz csatlakozik-e
      SELECT sp.nid INTO pointnid FROM sv_survey_point AS sp WHERE NEW.sv_survey_point=sp.nid AND sp.dimension=3;

      --Ha nem
      IF( pointnid IS NULL ) THEN

        RAISE EXCEPTION 'Nem vegrehajthato muvelet. A tp_point_2d NEM 2d-s sv_survey_point-hoz csatlakozik';
        RETURN NULL;

      END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_position_for_point_2d_before() OWNER TO tdc;

--
-- Name: check_position_for_point_3d_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_position_for_point_3d_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  nodegid bigint = NULL;
  spnid bigint = NULL;
BEGIN

  --Ha megvaltoztatok torlok vagy beszurok egy tp_point_3d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' OR TG_OP='DELETE' ) THEN

    --Ha ujat rogzitek vagy regit modositok
    IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

      --Akkor megnezi, hogy az uj-hoz van-e tp_node_3d
      SELECT n.gid INTO nodegid FROM tp_node_3d AS n, sv_survey_point AS sp, tp_point_3d as p WHERE NEW.nid=p.nid AND p.sv_survey_point=sp.nid AND sp.nid=n.sv_survey_point;

      --Ha van
      IF( nodegid IS NOT NULL ) THEN

        --Akkor update-elem, hogy aktivaljam a TRIGGER-et
        UPDATE tp_node_3d SET sv_survey_point=sv_survey_point WHERE gid=nodegid; 
  
      --Nincs
      ELSE 

        --Megkeresi a ponthoz tartozo survey point-ot
        SELECT sp.nid INTO spnid FROM sv_survey_point AS sp WHERE sp.nid=NEW.sv_survey_point;

        --Letre hozok egy uj tp_node_3d-t
        INSERT INTO tp_node_3d (sv_survey_point) VALUES ( spnid );

      END IF;

    END IF;

    --Ha torlok vagy modositok
    IF(TG_OP='UPDATE' OR TG_OP='DELETE') THEN

      UPDATE tp_node_3d AS n SET gid=gid from sv_survey_point AS sp WHERE OLD.sv_survey_point=sp.nid AND n.sv_survey_point=sp.nid;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_position_for_point_3d_after() OWNER TO tdc;

--
-- Name: check_position_for_point_3d_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION check_position_for_point_3d_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  pointnid bigint = NULL;
BEGIN

  --Ha megvaltoztatok vagy beszurok egy tp_point_3d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN


      --Akkor megnezi, hogy az uj egy 3D-s survey_point-hoz csatlakozik-e
      SELECT sp.nid INTO pointnid FROM sv_survey_point AS sp WHERE NEW.sv_survey_point=sp.nid AND sp.dimension=3;

      --Ha nem
      IF( pointnid IS NULL ) THEN

        RAISE EXCEPTION 'Nem vegrehajthato muvelet. A tp_point_3d NEM 3d-s sv_survey_point-hoz csatlakozik';
        RETURN NULL;

      END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.check_position_for_point_3d_before() OWNER TO tdc;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: im_building; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building (
    nid bigint NOT NULL,
    area integer,
    volume integer,
    hrsz_eoi text,
    projection bigint NOT NULL,
    model bigint,
    im_parcel bigint NOT NULL
);


ALTER TABLE own.im_building OWNER TO tdc;

--
-- Name: TABLE im_building; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building IS 'Az épületeket reprezentáló tábla';


--
-- Name: im_building_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE im_building_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.im_building_nid_seq OWNER TO tdc;

--
-- Name: im_building_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE im_building_nid_seq OWNED BY im_building.nid;


--
-- Name: im_building_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('im_building_nid_seq', 1, false);


--
-- Name: im_parcel; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_parcel (
    nid bigint NOT NULL,
    area integer NOT NULL,
    hrsz_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_partial integer,
    projection bigint NOT NULL,
    model bigint
);


ALTER TABLE own.im_parcel OWNER TO tdc;

--
-- Name: TABLE im_parcel; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_parcel IS 'Ez az ugynevezett földrészlet.
Az im_parcel-ek topologiát alkotnak';


--
-- Name: im_settlement; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_settlement (
    name text NOT NULL
);


ALTER TABLE own.im_settlement OWNER TO tdc;

--
-- Name: TABLE im_settlement; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_settlement IS 'Magyarorszag településeinek neve';


--
-- Name: im_underpass; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass (
    nid bigint NOT NULL,
    volume integer,
    area integer,
    hrsz_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_parcial integer,
    projection bigint NOT NULL,
    model bigint
);


ALTER TABLE own.im_underpass OWNER TO tdc;

--
-- Name: TABLE im_underpass; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass IS 'Aluljárók tábla.
EÖI tehát település+fő/alátört helyrajzi szám az azonosítója.
Rendelkeznie kell vetülettel és lehetőség szerint 3D modellel is';


--
-- Name: im_underpass_individual_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit (
    nid bigint NOT NULL,
    im_underpass_unit bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    area integer,
    volume integer
);


ALTER TABLE own.im_underpass_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_individual_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass_individual_unit IS 'Ezek az ingatlantípusok az aluljárókban lévő üzletek. 
EÖI';


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE im_underpass_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.im_underpass_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE im_underpass_individual_unit_nid_seq OWNED BY im_underpass_individual_unit.nid;


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('im_underpass_individual_unit_nid_seq', 1, false);


--
-- Name: im_underpass_shared_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit (
    im_underpass_unit bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE own.im_underpass_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit IS 'Ez az egység reprezentálja az aluljáróban lévő üzletek közös részét -ami mindenkihez tartozik és közösen fizetik a fenntartási költségeit';


--
-- Name: im_underpass_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_unit (
    nid bigint NOT NULL,
    hrsz_eoi text NOT NULL,
    im_underpass bigint NOT NULL
);


ALTER TABLE own.im_underpass_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass_unit IS 'Ezek az objektumok foglaljak egybe az aluljáróban található üzleteket. Tulajdonképpen analógok a Building-gel társasház esetén';


--
-- Name: pn_person; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE pn_person (
    nid bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE own.pn_person OWNER TO tdc;

--
-- Name: TABLE pn_person; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE pn_person IS 'Ez a személyeket tartalmazó tábla. Ide tartoznak természtes és jogi személyek is';


--
-- Name: rt_legal_document; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_legal_document (
    nid bigint NOT NULL,
    content text NOT NULL,
    date date NOT NULL
);


ALTER TABLE own.rt_legal_document OWNER TO tdc;

--
-- Name: TABLE rt_legal_document; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE rt_legal_document IS 'Azon dokumentumok, melyek alapján egy személy valamilyen jogi kapcsolatba került egy ingatlannal';


--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE rt_legal_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.rt_legal_document_nid_seq OWNER TO tdc;

--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE rt_legal_document_nid_seq OWNED BY rt_legal_document.nid;


--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('rt_legal_document_nid_seq', 1, false);


--
-- Name: rt_right; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_right (
    pn_person bigint NOT NULL,
    rt_legal_document bigint NOT NULL,
    rt_type text NOT NULL,
    im_parcel bigint,
    im_building bigint,
    im_building_individual_unit bigint,
    im_underpass_individual_unit bigint,
    im_underpass bigint,
    share_numerator integer,
    share_denominator integer
);


ALTER TABLE own.rt_right OWNER TO tdc;

--
-- Name: TABLE rt_right; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE rt_right IS 'Jogok. Ez a tábla köti össze a személyt egy ingatlannal valamilyen jogi dokumentum alapján. ';


--
-- Name: rt_type; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_type (
    name text NOT NULL
);


ALTER TABLE own.rt_type OWNER TO tdc;

--
-- Name: TABLE rt_type; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE rt_type IS 'Itt szerepelnek azok a jogok, melyek alapján egy személy kapcsolatba kerülhet egy ingatlannal';


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

SELECT pg_catalog.setval('sv_survey_document_nid_seq', 5, true);


--
-- Name: sv_survey_point; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_point (
    nid bigint NOT NULL,
    dimension integer NOT NULL,
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

SELECT pg_catalog.setval('sv_survey_point_nid_seq', 19, true);


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

SELECT pg_catalog.setval('tp_face_2d_gid_seq', 5, true);


--
-- Name: tp_face_3d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_face_3d (
    gid bigint NOT NULL,
    nodelist bigint[] NOT NULL,
    geom public.geometry(PolygonZ)
);


ALTER TABLE own.tp_face_3d OWNER TO tdc;

--
-- Name: tp_face_3d_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_face_3d_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_face_3d_gid_seq OWNER TO tdc;

--
-- Name: tp_face_3d_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_face_3d_gid_seq OWNED BY tp_face_3d.gid;


--
-- Name: tp_face_3d_gid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_face_3d_gid_seq', 3, true);


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
-- Name: tp_node_3d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_node_3d (
    gid bigint NOT NULL,
    sv_survey_point bigint NOT NULL,
    geom public.geometry(PointZ)
);


ALTER TABLE own.tp_node_3d OWNER TO tdc;

--
-- Name: tp_node_3d_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_node_3d_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_node_3d_gid_seq OWNER TO tdc;

--
-- Name: tp_node_3d_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_node_3d_gid_seq OWNED BY tp_node_3d.gid;


--
-- Name: tp_node_3d_gid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_3d_gid_seq', 12, true);


--
-- Name: tp_node_3d_sv_survey_point_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_node_3d_sv_survey_point_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_node_3d_sv_survey_point_seq OWNER TO tdc;

--
-- Name: tp_node_3d_sv_survey_point_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_node_3d_sv_survey_point_seq OWNED BY tp_node_3d.sv_survey_point;


--
-- Name: tp_node_3d_sv_survey_point_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_3d_sv_survey_point_seq', 1, false);


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
-- Name: tp_point_3d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_point_3d (
    nid bigint NOT NULL,
    x numeric(8,2) NOT NULL,
    y numeric(8,2) NOT NULL,
    z numeric(8,2) NOT NULL,
    quality integer,
    sv_survey_document bigint NOT NULL,
    sv_survey_point bigint NOT NULL
);


ALTER TABLE own.tp_point_3d OWNER TO tdc;

--
-- Name: tp_point_3d_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_point_3d_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_point_3d_nid_seq OWNER TO tdc;

--
-- Name: tp_point_3d_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_point_3d_nid_seq OWNED BY tp_point_3d.nid;


--
-- Name: tp_point_3d_nid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_point_3d_nid_seq', 5, true);


--
-- Name: tp_point_3d_tp_node_3d_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_point_3d_tp_node_3d_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_point_3d_tp_node_3d_seq OWNER TO tdc;

--
-- Name: tp_point_3d_tp_node_3d_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_point_3d_tp_node_3d_seq OWNED BY tp_point_3d.sv_survey_point;


--
-- Name: tp_point_3d_tp_node_3d_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_point_3d_tp_node_3d_seq', 1, true);


SET default_with_oids = true;

--
-- Name: tp_volume_3d; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_volume_3d (
    gid integer NOT NULL,
    facelist bigint[] NOT NULL,
    geom public.geometry(PolyhedralSurfaceZ)
);


ALTER TABLE own.tp_volume_3d OWNER TO tdc;

--
-- Name: tp_volume_3d_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_volume_3d_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_volume_3d_gid_seq OWNER TO tdc;

--
-- Name: tp_volume_3d_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_volume_3d_gid_seq OWNED BY tp_volume_3d.gid;


--
-- Name: tp_volume_3d_gid_seq; Type: SEQUENCE SET; Schema: own; Owner: tdc
--

SELECT pg_catalog.setval('tp_volume_3d_gid_seq', 12, true);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building ALTER COLUMN nid SET DEFAULT nextval('im_building_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_underpass_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_legal_document ALTER COLUMN nid SET DEFAULT nextval('rt_legal_document_nid_seq'::regclass);


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

ALTER TABLE ONLY tp_face_3d ALTER COLUMN gid SET DEFAULT nextval('tp_face_3d_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_2d ALTER COLUMN gid SET DEFAULT nextval('tp_node_2d_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_3d ALTER COLUMN gid SET DEFAULT nextval('tp_node_3d_gid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_2d ALTER COLUMN nid SET DEFAULT nextval('tp_point_2d_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_3d ALTER COLUMN nid SET DEFAULT nextval('tp_point_3d_nid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_volume_3d ALTER COLUMN gid SET DEFAULT nextval('tp_volume_3d_gid_seq'::regclass);


--
-- Data for Name: im_building; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_parcel; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_settlement; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_underpass; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_underpass_individual_unit; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_underpass_shared_unit; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: im_underpass_unit; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: pn_person; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: rt_legal_document; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: rt_right; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: rt_type; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: sv_survey_document; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: sv_survey_point; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_face_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_face_3d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_node_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_node_3d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_point_2d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_point_3d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Data for Name: tp_volume_3d; Type: TABLE DATA; Schema: own; Owner: tdc
--



--
-- Name: im_building_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_pkey PRIMARY KEY (nid);


--
-- Name: im_building_unique_im_parcel_hrsz_eoi; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_im_parcel_hrsz_eoi UNIQUE (im_parcel, hrsz_eoi);


--
-- Name: im_building_unique_model; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_model UNIQUE (model);


--
-- Name: im_building_unique_projection; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_projection UNIQUE (projection);


--
-- Name: im_parcel_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_pkey PRIMARY KEY (nid);


--
-- Name: im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial UNIQUE (hrsz_settlement, hrsz_main, hrsz_partial);


--
-- Name: im_parcel_unique_model; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_model UNIQUE (model);


--
-- Name: im_parcel_unique_projection; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_projection UNIQUE (projection);


--
-- Name: im_settlement_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_settlement
    ADD CONSTRAINT im_settlement_pkey PRIMARY KEY (name);


--
-- Name: im_underpass_individual_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit UNIQUE (im_underpass_unit, hrsz_unit);


--
-- Name: im_underpass_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_pkey PRIMARY KEY (im_underpass_unit);


--
-- Name: im_underpass_shared_unit_unique_im_underpass_unit_name; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_unique_im_underpass_unit_name UNIQUE (im_underpass_unit, name);


--
-- Name: im_underpass_unigue_projection; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unigue_projection UNIQUE (projection);


--
-- Name: im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial UNIQUE (hrsz_settlement, hrsz_main, hrsz_parcial);


--
-- Name: im_underpass_unique_model; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_model UNIQUE (model);


--
-- Name: im_underpass_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_unit
    ADD CONSTRAINT im_underpass_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_unit_unique_im_underpass_hrsz_eoi; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_unit
    ADD CONSTRAINT im_underpass_unit_unique_im_underpass_hrsz_eoi UNIQUE (im_underpass, hrsz_eoi);


--
-- Name: pn_person_name_key; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_name_key UNIQUE (name);


--
-- Name: pn_person_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_pkey PRIMARY KEY (nid);


--
-- Name: rt_legal_document_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_legal_document
    ADD CONSTRAINT rt_legal_document_pkey PRIMARY KEY (nid);


--
-- Name: rt_type_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_pkey PRIMARY KEY (name);


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
-- Name: tp_face_3d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face_3d
    ADD CONSTRAINT tp_face_3d_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_3d_unique_nodelist; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face_3d
    ADD CONSTRAINT tp_face_3d_unique_nodelist UNIQUE (nodelist);


--
-- Name: tp_face_ed_unique_nodelist; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face_2d
    ADD CONSTRAINT tp_face_ed_unique_nodelist UNIQUE (nodelist);


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
-- Name: tp_node_3d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node_3d
    ADD CONSTRAINT tp_node_3d_pkey PRIMARY KEY (gid);


--
-- Name: tp_node_3d_unique_sv_survey_point; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node_3d
    ADD CONSTRAINT tp_node_3d_unique_sv_survey_point UNIQUE (sv_survey_point);


--
-- Name: tp_point_2d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_point_2d
    ADD CONSTRAINT tp_point_2d_pkey PRIMARY KEY (nid);


--
-- Name: tp_point_2d_unique_sv_survey_docoument_sv_survey_point; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_point_2d
    ADD CONSTRAINT tp_point_2d_unique_sv_survey_docoument_sv_survey_point UNIQUE (sv_survey_document, sv_survey_point);


--
-- Name: tp_point_3d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_point_3d
    ADD CONSTRAINT tp_point_3d_pkey PRIMARY KEY (nid);


--
-- Name: tp_point_3d_unique_sv_survey_document_sv_survey_point; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_point_3d
    ADD CONSTRAINT tp_point_3d_unique_sv_survey_document_sv_survey_point UNIQUE (sv_survey_document, sv_survey_point);


--
-- Name: tp_volume_3d_facelist_key; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume_3d
    ADD CONSTRAINT tp_volume_3d_facelist_key UNIQUE (facelist);


--
-- Name: tp_volume_3d_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume_3d
    ADD CONSTRAINT tp_volume_3d_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_2d_idx_nodelist; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_2d_idx_nodelist ON tp_face_2d USING gin (nodelist);


--
-- Name: tp_face_3d_idx_nodelist; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_3d_idx_nodelist ON tp_face_3d USING gin (nodelist);


--
-- Name: tp_point_2d_idx_tp_node_2d; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_point_2d_idx_tp_node_2d ON tp_point_2d USING btree (sv_survey_point);


--
-- Name: tp_point_3d_idx_tp_node_3d; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_point_3d_idx_tp_node_3d ON tp_point_3d USING btree (sv_survey_point);


--
-- Name: tp_volume_3d_idx_facelist; Type: INDEX; Schema: own; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_volume_3d_idx_facelist ON tp_volume_3d USING gin (facelist);


--
-- Name: check_facelist_for_volume_3d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_facelist_for_volume_3d_before_trigger BEFORE INSERT OR UPDATE ON tp_volume_3d FOR EACH ROW EXECUTE PROCEDURE check_facelist_for_volume_3d_before();


--
-- Name: check_nodelist_for_face_2d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_nodelist_for_face_2d_before_trigger BEFORE INSERT OR UPDATE ON tp_face_2d FOR EACH ROW EXECUTE PROCEDURE check_nodelist_for_face_2d_before();


--
-- Name: check_nodelist_for_face_3d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_nodelist_for_face_3d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_face_3d FOR EACH ROW EXECUTE PROCEDURE check_nodelist_for_face_3d_after();


--
-- Name: check_nodelist_for_face_3d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_nodelist_for_face_3d_before_trigger BEFORE INSERT OR UPDATE ON tp_face_3d FOR EACH ROW EXECUTE PROCEDURE check_nodelist_for_face_3d_before();


--
-- Name: check_point_for_node_2d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_2d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_node_2d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_2d_after();


--
-- Name: check_point_for_node_2d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_2d_before_trigger BEFORE INSERT OR UPDATE ON tp_node_2d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_2d_before();


--
-- Name: check_point_for_node_3d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_3d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_node_3d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_3d_after();


--
-- Name: check_point_for_node_3d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_point_for_node_3d_before_trigger BEFORE INSERT OR UPDATE ON tp_node_3d FOR EACH ROW EXECUTE PROCEDURE check_point_for_node_3d_before();


--
-- Name: check_position_for_point_2d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_position_for_point_2d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_point_2d FOR EACH ROW EXECUTE PROCEDURE check_position_for_point_2d_after();


--
-- Name: check_position_for_point_2d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_position_for_point_2d_before_trigger BEFORE INSERT OR UPDATE ON tp_point_2d FOR EACH ROW EXECUTE PROCEDURE check_position_for_point_2d_before();


--
-- Name: check_position_for_point_3d_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_position_for_point_3d_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_point_3d FOR EACH ROW EXECUTE PROCEDURE check_position_for_point_3d_after();


--
-- Name: check_position_for_point_3d_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER check_position_for_point_3d_before_trigger BEFORE INSERT OR UPDATE ON tp_point_3d FOR EACH ROW EXECUTE PROCEDURE check_position_for_point_3d_before();


--
-- Name: im_building_fkey_im_parcel; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_fkey_im_parcel FOREIGN KEY (im_parcel) REFERENCES im_parcel(nid);


--
-- Name: im_underpass_fkey_settlement; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_fkey_settlement FOREIGN KEY (hrsz_settlement) REFERENCES im_settlement(name);


--
-- Name: im_underpass_individual_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_unit) REFERENCES im_underpass_unit(nid);


--
-- Name: im_underpass_shared_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_unit) REFERENCES im_underpass_unit(nid);


--
-- Name: im_underpass_unit_fkey_im_underpass; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_unit
    ADD CONSTRAINT im_underpass_unit_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_pn_person; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_pn_person FOREIGN KEY (pn_person) REFERENCES pn_person(nid);


--
-- Name: rt_right_fkey_rt_legal_document; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_legal_document FOREIGN KEY (rt_legal_document) REFERENCES rt_legal_document(nid);


--
-- Name: rt_right_fkey_rt_type; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_type FOREIGN KEY (rt_type) REFERENCES rt_type(name);


--
-- Name: tp_node_2d_fkey_sv_survery_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_2d
    ADD CONSTRAINT tp_node_2d_fkey_sv_survery_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- Name: tp_node_3d_fkey_sv_survery_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node_3d
    ADD CONSTRAINT tp_node_3d_fkey_sv_survery_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


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
-- Name: tp_point_3d_fkey_sv_survey_document; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_3d
    ADD CONSTRAINT tp_point_3d_fkey_sv_survey_document FOREIGN KEY (sv_survey_document) REFERENCES sv_survey_document(nid);


--
-- Name: tp_point_3d_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_point_3d
    ADD CONSTRAINT tp_point_3d_fkey_sv_survey_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- PostgreSQL database dump complete
--

