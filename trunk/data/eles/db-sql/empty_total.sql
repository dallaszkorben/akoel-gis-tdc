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
-- Name: geod_position; Type: TYPE; Schema: own; Owner: tdc
--

CREATE TYPE geod_position AS (
x double precision,
y double precision,
h double precision
);


ALTER TYPE own.geod_position OWNER TO tdc;

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
-- Name: sv_point_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION sv_point_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  nodegid bigint = NULL;
  spnid bigint = NULL;
BEGIN

  --
  -- Ha a sv_point-ban valtozas tortent, akkor a valtozast atvezeti a tp_node-ba.
  -- Ha az uj sv_point-hoz nem volt meg tp_node, akkor azt letrehozza
  --

  --Ha megvaltoztatok torlok vagy beszurok egy tp_point_3d-t
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' OR TG_OP='DELETE' ) THEN

    --Ha ujat rogzitek vagy regit modositok
    IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

      --Akkor megnezi, hogy az uj sv_point-hoz van-e tp_node
      SELECT n.gid INTO nodegid FROM tp_node AS n, sv_survey_point AS sp, sv_point as p WHERE NEW.nid=p.nid AND p.sv_survey_point=sp.nid AND sp.nid=n.gid;

      --Ha van
      IF( nodegid IS NOT NULL ) THEN

        --Akkor update-elem, hogy aktivaljam a TRIGGER-et
        UPDATE tp_node SET gid=gid WHERE gid=nodegid; 
  
      --Nincs
      ELSE 

        --Megkeresi a ponthoz tartozo survey point-ot
        SELECT sp.nid INTO spnid FROM sv_survey_point AS sp WHERE sp.nid=NEW.sv_survey_point;

        --Letre hozok egy uj tp_node-ot
        INSERT INTO tp_node (gid) VALUES ( spnid );

      END IF;

    END IF;

    --Ha torlok vagy modositok
    IF(TG_OP='UPDATE' OR TG_OP='DELETE') THEN

      --Akkor frissitem a regi sv_point-hoz tartozo tp_node-ot. Es igy a tp_node triggerei aktivalodnak
      UPDATE tp_node AS n SET gid=gid from sv_survey_point AS sp WHERE OLD.sv_survey_point=sp.nid AND n.gid=sp.nid;

    END IF;

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.sv_point_after() OWNER TO tdc;

--
-- Name: sv_point_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION sv_point_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  pointnid bigint = NULL;
BEGIN

  --
  -- A dimenzio es az adatok konzisztenciajat vizsgalom
  --


  --Ha megvaltoztatok vagy beszurok egy sv_point-ot
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Ha 3 dimenzionak definialtam a pontot, de csak 2 koordinatat adtam meg
    IF(NEW.dimension = 3 AND NEW.h IS NULL) THEN
      RAISE EXCEPTION 'Hiányzik a H koordináta';
      RETURN NULL;

    --Ha 2 dimenzionak definialtam, akkor a H dimenzio erteke 0 lesz
    ELSIF(NEW.dimension = 2) THEN
      NEW.h := 0.0;

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.sv_point_before() OWNER TO tdc;

--
-- Name: tp_face_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION tp_face_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  volume tp_volume%rowtype;
  facenumber integer;
  face_list bigint[];
BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    --Csak azert hogy aktivalodjon a tp_volume trigger-e. Azok a volume-k amik tartalmazzak ezt a face-t
    UPDATE tp_volume AS v set facelist=facelist WHERE ARRAY[NEW.gid] <@ v.facelist;

  ELSIF(TG_OP='DELETE') THEN

    SELECT * INTO volume FROM tp_volume AS v WHERE ARRAY[OLD.gid] <@ v.facelist;

    IF FOUND THEN

      RAISE EXCEPTION 'Nem törölhetem ki a tp_face.gid: % Face-t mert van legalabb 1 tp_volume.gid: % Volume, ami tartalmazza. Facelist: %', OLD.gid, volume.gid, volume.facelist;

    END IF;

    -- Meg kell nezni, hogy a face-t tartalmazza-e egy masik face mint hole-t
    SELECT INTO face_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[OLD.gid] <@ f.holelist;

    IF face_list IS NOT NULL THEN

      RAISE EXCEPTION 'Nem törölhetem ki a tp_face-t: % Face-t mert a következő tp_face-ek tartalmazzák a holelist mezőjükben: %', OLD.gid, face_list;


    END IF;


  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.tp_face_after() OWNER TO tdc;

--
-- Name: tp_face_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION tp_face_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  result boolean;

  pointlisttext_start text = '(';
  pointlisttext_end text = ')';
  pointlisttext text = '';
  pointlisttext_close text = '';

  isfirstpoint boolean = true;

  geomtext_start text = 'POLYGON(';
  geomtext text = '';
  geomtext_end text = ')';

  solidfacetext text = '';
  holefacetext text = '';

  position geod_position%rowtype;

  actualnode_gid bigint;
  actualface_gid bigint;
  nodel bigint[];

BEGIN
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    -- --------------------------------------------
    -- Eloszor a POLYGON felderitese es elkeszitese 
    -- --------------------------------------------

    select count(1)=array_upper(NEW.nodelist,1) INTO result FROM tp_node AS n WHERE ARRAY[n.gid] <@ NEW.nodelist;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face INSERT/UPDATE. Rossz a nodelist lista: %', NEW.nodelist;
    END IF;

    isfirstpoint = true;
    pointlisttext = '';
    pointlisttext_close = '';

    --Vegig a csomopontokon
    FOREACH actualnode_gid IN ARRAY NEW.nodelist LOOP

      --csomopontok koordinatainak kideritese
      SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode_gid AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
      --Veszem a kovetkezo pontot
      pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

      IF isfirstpoint THEN

        --Zarnom kell a poligont az elso ponttal
        pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

      END IF;

      isfirstpoint=false;

    END LOOP;

    -- Itt rendelkezesemre all a polygon feluletet leiro koordinatasorozat (x1 y1 z1, ... x1 y1 z1) formaban
    solidfacetext = pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

    -- -------------------------------------------
    -- Majd a lyukak felderitese es elkeszitese 
    -- -------------------------------------------
    select count(1)=array_upper(NEW.holelist,1) INTO result FROM tp_face AS f WHERE ARRAY[f.gid] <@ NEW.holelist AND f.gid != NEW.gid;

    --Nem megfelelo meretu a lista
    if( NOT result  ) THEN
        RAISE EXCEPTION 'Nem vegrehajthato a tp_face INSERT/UPDATE. Rossz a holelist lista: %', NEW.holelist;
    END IF;

--raise exception 'hello %', coalesce( NEW.holelist, '{}' );

    --Vegig a lyukakat leiro feluleteken
    FOREACH actualface_gid IN ARRAY coalesce( NEW.holelist, '{}' ) LOOP

      --Elkerem az aktualis lyuk nodelist-jet 
      SELECT f.nodelist INTO nodel FROM tp_face AS f WHERE f.gid=actualface_gid;

      isfirstpoint = true;
      pointlisttext = '';
      pointlisttext_close = '';

      --Vegig a csomopontokon
      FOREACH actualnode_gid IN ARRAY nodel LOOP

        --csomopontok koordinatainak kideritese
        SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode_gid AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
-----      
        --Veszem a kovetkezo pontot
        pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

        IF isfirstpoint THEN

          --Zarnom kell a poligont az elso ponttal
          pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

        END IF;

        isfirstpoint=false;

      --Vege a csomopontnak
      END LOOP;

      holefacetext = holefacetext || ', ' || pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

    END LOOP;

    --Most irom at a geometriat az uj ertekekre
    geomtext = geomtext_start || solidfacetext || holefacetext || geomtext_end;

--raise exception 'hello %', geomtext;

    NEW.geom := public.ST_GeomFromText( geomtext, -1 ); 

  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.tp_face_before() OWNER TO tdc;

--
-- Name: tp_node_after(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION tp_node_after() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  face tp_face%rowtype;

  polygon_list bigint[];
  polygon_gid bigint;

  hole_list bigint[];
  hole_gid bigint;
BEGIN

  --
  -- Update-lem  a tp_face-t hogy aktivalodjon a tirggere es atvezesse a valtozasokat amiket itt vegeztem
  -- Torlest nem engedek, ha ez a node szerepel a tp_face-ben
  --

  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN
    
    -- Csak azert hogy aktivalodjon a tp_face trigger-e. Azok a face-ek amik tartalmazzak ezt a node-ot
    --UPDATE tp_face AS f set nodelist=nodelist WHERE ARRAY[NEW.gid] <@ f.nodelist;

    -- Osszegyujtom azokat a tp_face-eket melyekben a POLYGON zart felulet hasznalje azt a pontot
    SELECT INTO polygon_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[NEW.gid] <@ f.nodelist;

    FOREACH polygon_gid IN ARRAY coalesce( polygon_list, '{}' ) LOOP
 
      --Ezeket update-lem
      UPDATE tp_face SET gid=gid WHERE gid=polygon_gid;

      -- Osszegyujtom azokat a tp_face-eket melyekneka holelist-je tartalmazza ezt a polygont
      SELECT INTO hole_list array_agg(f.gid) FROM tp_face AS f WHERE ARRAY[polygon_gid] <@ f.holelist;
      FOREACH hole_gid IN ARRAY coalesce( hole_list, '{}' ) LOOP

        UPDATE tp_face SET gid=gid WHERE gid=hole_gid;

      END LOOP;

    END LOOP;

  ELSIF(TG_OP='DELETE') THEN

    --Megnezem, hogy a torlendo tp_node szerepel-e a tp_face-ben
    SELECT * INTO face FROM tp_face AS f WHERE ARRAY[OLD.gid] <@ f.nodelist;

    --Ha igen
    IF FOUND THEN

      --Akokr nem engedem torolni
      RAISE EXCEPTION 'Nem törölhetem ki a csomópontot mert van legalabb 1 Face ami tartalmazza. gid: %, nodelist: %', OLD.gid, face.nodelist;

    END IF;

    RETURN OLD;

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION own.tp_node_after() OWNER TO tdc;

--
-- Name: tp_node_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION tp_node_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  geomtext text = 'POINT(';
  geomtextend text = ')';
  position geod_position%rowtype;
BEGIN

  --
  -- Azt vizsgalom, hogy a megadott NODE ervenyes lehet-e
  --

  --Uj vagy modositas eseten
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --Megkeresem uj tp_node-boz tartozo datum szerinti legutolso aktualis pont kooridinatait
    SELECT p.x, p.y, p.h INTO position FROM sv_point AS p, sv_survey_point AS sp, sv_survey_document AS sd WHERE NEW.gid=sp.nid AND sp.nid=p.sv_survey_point AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   

    --Ha rendben van
    IF( position.x IS NOT NULL AND position.y IS NOT NULL AND position.h IS NOT NULL) THEN
      
      -- akkor a node geometriajat aktualizalja
      geomtext := geomtext || position.x || ' ' || position.y || ' ' || position.h || geomtextend;
      NEW.geom := public.ST_GeomFromText( geomtext, -1 );
    ELSE

      RAISE EXCEPTION 'Nem végrehajtható művelet. Ha végrehajtanám a % müveletetet, akkor nem letezne a tp_node-hoz sv_point.', TG_OP;

    END IF;
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.tp_node_before() OWNER TO tdc;

--
-- Name: tp_volume_before(); Type: FUNCTION; Schema: own; Owner: tdc
--

CREATE FUNCTION tp_volume_before() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$DECLARE
  result boolean;
  
  pointlisttext text = '';
  pointlisttext_start text = '((';
  pointlisttext_end text = '))';
  pointlisttext_close text = '';

  facelisttext text = '';

  geomtext_start text = 'POLYHEDRALSURFACE(';
  geomtext_end text = ')';
  geomtext text = '';

  position geod_position%rowtype;
  isfirstnode boolean;
  isfirstface boolean = true;
  actualface bigint;
  actualnode bigint;
  ndlist bigint[];

BEGIN

  --Ha modositom, vagy ujat szurok be
  IF(TG_OP='UPDATE' OR TG_OP='INSERT' ) THEN

    --akkor megnezem, hogy a lista helyes-e. Letezo face-ek szerepelnek-e benne megfelelo szamban
    select count(1)=array_upper(NEW.facelist,1) INTO result FROM tp_face AS f WHERE ARRAY[f.gid] <@ NEW.facelist;

   --Ha nem megfelelo meretu a lista
    if( NOT result  ) THEN

        --akkor nem vegrehajthato a muvelet
        RAISE EXCEPTION 'Nem vegrehajthato a tp_volume INSERT/UPDATE. Rossz a lista: %', NEW.facelist;

    END IF;



    --Vegig a face-eken
    FOREACH actualface IN ARRAY NEW.facelist LOOP

      --A face csomopontjainak osszegyujtese
      SELECT f.nodelist INTO ndlist FROM tp_face as f WHERE f.gid=actualface;

      --valtozok elokeszitese a face osszeallitasahoz csomopontok alapjan
      isfirstnode=true;
      pointlisttext = '';
      pointlisttext_close = '';

      --Vegig a face csomopontjain
      FOREACH actualnode IN ARRAY ndlist LOOP

        --csomopontok koordinatainak kideritese
        SELECT p.x, p.y, p.h INTO position FROM sv_survey_point AS sp, sv_point AS p, sv_survey_document AS sd, tp_node AS n WHERE n.gid=actualnode AND n.gid=sp.nid AND p.sv_survey_point=sp.nid AND p.sv_survey_document=sd.nid AND sd.date<=current_date ORDER BY sd.date DESC LIMIT 1;   
      
        --Veszem a kovetkezo pontot
        pointlisttext = pointlisttext || position.x || ' ' || position.y || ' ' || position.h || ',';

        IF isfirstnode THEN

          --Zarnom kell a poligont az elso ponttal
          pointlisttext_close = position.x || ' ' || position.y || ' ' || position.h;

          --jelzem, hogy a kovetkezo pont mar nem az elso lesz
          isfirstnode=false;

        END IF;

      END LOOP;  --csomopont gyujto ciklus zarasa

      --Itt rendelkezesemre all egy (x1 y1 z1, x2 y2 z2, ... ) formatumu string
      pointlisttext = pointlisttext_start || pointlisttext || pointlisttext_close || pointlisttext_end;

      --Ha ez az elso face
      IF isfirstface THEN

        --akkor jelzem, hogy a kovetkezo mar nem az elso
        isfirstface=false;

      --Ha mar volt face
      ELSE

        --akkor az elejere kell egy vesszo
        facelisttext = facelisttext || ', ';

      END IF;

      facelisttext = facelisttext || pointlisttext;

    END LOOP;   --face gyujto ciklus zarasa

    geomtext = geomtext_start || facelisttext || geomtext_end;

    NEW.geom := public.ST_GeomFromText( geomtext, -1 );
   
  END IF;
  RETURN NEW;
END;
$$;


ALTER FUNCTION own.tp_volume_before() OWNER TO tdc;

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
    im_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_fraction integer NOT NULL
);


ALTER TABLE own.im_building OWNER TO tdc;

--
-- Name: TABLE im_building; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building IS 'Az épületeket reprezentáló tábla';


--
-- Name: im_building_individual_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit (
    nid bigint NOT NULL,
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL
);


ALTER TABLE own.im_building_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit IS 'A társasházakban elhelyezkedő önállóan forgalomképes ingatlanok, lakások, üzlethelyiségek';


--
-- Name: im_building_individual_unit_level; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit_level (
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    im_levels text NOT NULL
);


ALTER TABLE own.im_building_individual_unit_level OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit_level; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit_level IS 'Társasházban található önálóan forgalomképes helyiségek szintjeit határozza meg. (mivel egy helyiség akár több szinten is elhelyezkedhet)';


--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE im_building_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.im_building_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE im_building_individual_unit_nid_seq OWNED BY im_building_individual_unit.nid;


--
-- Name: im_building_levels; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_levels (
    im_building bigint NOT NULL,
    im_levels text NOT NULL
);


ALTER TABLE own.im_building_levels OWNER TO tdc;

--
-- Name: TABLE im_building_levels; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building_levels IS 'Egy adott épületen belül előforduló szintek';


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
-- Name: im_building_shared_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_shared_unit (
    im_building bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE own.im_building_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_building_shared_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_building_shared_unit IS 'A társasházak közös helyiségei';


--
-- Name: im_levels; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_levels (
    name text NOT NULL
);


ALTER TABLE own.im_levels OWNER TO tdc;

--
-- Name: TABLE im_levels; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_levels IS 'Az összes előforduló szint megnevezése az épületekben';


--
-- Name: im_parcel; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_parcel (
    nid bigint NOT NULL,
    area integer NOT NULL,
    im_settlement text NOT NULL,
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
-- Name: im_shared_unit_level; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_shared_unit_level (
    im_building bigint NOT NULL,
    im_levels text NOT NULL,
    shared_unit_name text NOT NULL
);


ALTER TABLE own.im_shared_unit_level OWNER TO tdc;

--
-- Name: TABLE im_shared_unit_level; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_shared_unit_level IS 'Társasházakban a közös helyiségek, fő épületszerkezeti elemek szintjeit határozza meg. (mivel a közös helyiségek akár több szinten is elhelyezkedhetnek)';


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
-- Name: im_underpass_block; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_block (
    nid bigint NOT NULL,
    hrsz_eoi text NOT NULL,
    im_underpass bigint NOT NULL
);


ALTER TABLE own.im_underpass_block OWNER TO tdc;

--
-- Name: TABLE im_underpass_block; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass_block IS 'Ezek az objektumok foglaljak egybe az aluljáróban található üzleteket. Tulajdonképpen analógok a Building-gel társasház esetén';


--
-- Name: im_underpass_individual_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit (
    nid bigint NOT NULL,
    im_underpass_block bigint NOT NULL,
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
-- Name: im_underpass_shared_unit; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit (
    im_underpass_block bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE own.im_underpass_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit IS 'Ez az egység reprezentálja az aluljáróban lévő üzletek közös részét -ami mindenkihez tartozik és közösen fizetik a fenntartási költségeit';


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
-- Name: rt_right; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_right (
    pn_person bigint NOT NULL,
    rt_legal_document bigint NOT NULL,
    im_parcel bigint,
    im_building bigint,
    im_building_individual_unit bigint,
    im_underpass_individual_unit bigint,
    im_underpass bigint,
    share_numerator integer,
    share_denominator integer,
    rt_type bigint NOT NULL
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
    name text NOT NULL,
    nid bigint NOT NULL
);


ALTER TABLE own.rt_type OWNER TO tdc;

--
-- Name: TABLE rt_type; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE rt_type IS 'Itt szerepelnek azok a jogok, melyek alapján egy személy kapcsolatba kerülhet egy ingatlannal';


--
-- Name: sv_point; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_point (
    nid bigint NOT NULL,
    sv_survey_point bigint NOT NULL,
    sv_survey_document bigint NOT NULL,
    x numeric(8,2) NOT NULL,
    y numeric(8,2) NOT NULL,
    h numeric(8,2),
    dimension integer DEFAULT 3 NOT NULL,
    quality integer,
    CONSTRAINT sv_point_check_dimension CHECK ((dimension = ANY (ARRAY[2, 3])))
);


ALTER TABLE own.sv_point OWNER TO tdc;

--
-- Name: TABLE sv_point; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE sv_point IS 'Mért pont. Lehet 2 és 3 dimenziós is';


--
-- Name: sv_point_nid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE sv_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.sv_point_nid_seq OWNER TO tdc;

--
-- Name: sv_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE sv_point_nid_seq OWNED BY sv_point.nid;


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
-- Name: TABLE sv_survey_document; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE sv_survey_document IS 'Mérési jegyzőkönyv a felmért pontok számára';


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
-- Name: sv_survey_point; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_point (
    nid bigint NOT NULL,
    description text,
    name text
);


ALTER TABLE own.sv_survey_point OWNER TO tdc;

--
-- Name: TABLE sv_survey_point; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE sv_survey_point IS 'Mérési pont azonosítása és leírása';


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


SET default_with_oids = true;

--
-- Name: tp_face; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_face (
    gid bigint NOT NULL,
    nodelist bigint[] NOT NULL,
    geom public.geometry(PolygonZ),
    holelist bigint[],
    note text
);


ALTER TABLE own.tp_face OWNER TO tdc;

--
-- Name: TABLE tp_face; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE tp_face IS 'Felület. Pontjait a tp_node elemei alkotják';


--
-- Name: tp_face_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_face_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_face_gid_seq OWNER TO tdc;

--
-- Name: tp_face_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_face_gid_seq OWNED BY tp_face.gid;


--
-- Name: tp_node; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_node (
    gid bigint NOT NULL,
    geom public.geometry(PointZ),
    note text
);


ALTER TABLE own.tp_node OWNER TO tdc;

--
-- Name: TABLE tp_node; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE tp_node IS 'Csomópont. Egy sv_survey_point-ot azonosít. Van geometriája, mely mindig a dátum szerinti aktuális sv_point adatait tartalmazza.';


--
-- Name: tp_node_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_node_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_node_gid_seq OWNER TO tdc;

--
-- Name: tp_node_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_node_gid_seq OWNED BY tp_node.gid;


--
-- Name: tp_volume; Type: TABLE; Schema: own; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_volume (
    gid bigint NOT NULL,
    facelist bigint[],
    note text,
    geom public.geometry(PolyhedralSurfaceZ)
);


ALTER TABLE own.tp_volume OWNER TO tdc;

--
-- Name: TABLE tp_volume; Type: COMMENT; Schema: own; Owner: tdc
--

COMMENT ON TABLE tp_volume IS '3D-s térfogati elem. tp_face-ek írják le';


--
-- Name: tp_volume_gid_seq; Type: SEQUENCE; Schema: own; Owner: tdc
--

CREATE SEQUENCE tp_volume_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE own.tp_volume_gid_seq OWNER TO tdc;

--
-- Name: tp_volume_gid_seq; Type: SEQUENCE OWNED BY; Schema: own; Owner: tdc
--

ALTER SEQUENCE tp_volume_gid_seq OWNED BY tp_volume.gid;


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building ALTER COLUMN nid SET DEFAULT nextval('im_building_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_building_individual_unit_nid_seq'::regclass);


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

ALTER TABLE ONLY sv_point ALTER COLUMN nid SET DEFAULT nextval('sv_point_nid_seq'::regclass);


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

ALTER TABLE ONLY tp_face ALTER COLUMN gid SET DEFAULT nextval('tp_face_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_volume ALTER COLUMN gid SET DEFAULT nextval('tp_volume_gid_seq'::regclass);


--
-- Name: im_building_individual_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_building_individual_unit_unique_im_building_hrsz_unit; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_unique_im_building_hrsz_unit UNIQUE (im_building, hrsz_unit);


--
-- Name: im_building_levels_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_pkey PRIMARY KEY (im_building, im_levels);


--
-- Name: im_building_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_pkey PRIMARY KEY (nid);


--
-- Name: im_building_shared_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_pkey PRIMARY KEY (im_building, name);


--
-- Name: im_building_unique_im_settlement_hrsz_main_hrsz_fraction; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_im_settlement_hrsz_main_hrsz_fraction UNIQUE (im_settlement, hrsz_main, hrsz_fraction);


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
-- Name: im_individual_unit_level_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_pkey PRIMARY KEY (im_building, hrsz_unit, im_levels);


--
-- Name: im_levels_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_levels
    ADD CONSTRAINT im_levels_pkey PRIMARY KEY (name);


--
-- Name: im_parcel_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_pkey PRIMARY KEY (nid);


--
-- Name: im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial UNIQUE (im_settlement, hrsz_main, hrsz_partial);


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
-- Name: im_shared_unit_level_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_pkey PRIMARY KEY (im_building, im_levels, shared_unit_name);


--
-- Name: im_underpass_individual_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit UNIQUE (im_underpass_block, hrsz_unit);


--
-- Name: im_underpass_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_pkey PRIMARY KEY (im_underpass_block);


--
-- Name: im_underpass_shared_unit_unique_im_underpass_unit_name; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_unique_im_underpass_unit_name UNIQUE (im_underpass_block, name);


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

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_unit_unique_im_underpass_hrsz_eoi; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_block
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
-- Name: rt_type_pkey_nid; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_pkey_nid PRIMARY KEY (nid);


--
-- Name: rt_type_unique_name; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_unique_name UNIQUE (name);


--
-- Name: sv_point_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_pkey PRIMARY KEY (nid);


--
-- Name: sv_point_unique_sv_survey_point_sv_survey_document; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_unique_sv_survey_point_sv_survey_document UNIQUE (sv_survey_point, sv_survey_document);


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
-- Name: tp_face_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_unique_nodelist; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_unique_nodelist UNIQUE (nodelist);


--
-- Name: tp_node_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_pkey PRIMARY KEY (gid);


--
-- Name: tp_volume_facelist_key; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_facelist_key UNIQUE (facelist);


--
-- Name: tp_volume_pkey; Type: CONSTRAINT; Schema: own; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_pkey PRIMARY KEY (gid);


--
-- Name: sv_point_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER sv_point_after_trigger AFTER INSERT OR DELETE OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_after();


--
-- Name: sv_point_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER sv_point_before_trigger BEFORE INSERT OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_before();


--
-- Name: tp_face_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER tp_face_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_after();


--
-- Name: tp_face_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER tp_face_before_trigger BEFORE INSERT OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_before();


--
-- Name: tp_node_after_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER tp_node_after_trigger BEFORE INSERT OR DELETE OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_after();


--
-- Name: tp_node_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER tp_node_before_trigger BEFORE INSERT OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_before();


--
-- Name: tp_volume_before_trigger; Type: TRIGGER; Schema: own; Owner: tdc
--

CREATE TRIGGER tp_volume_before_trigger BEFORE INSERT OR UPDATE ON tp_volume FOR EACH ROW EXECUTE PROCEDURE tp_volume_before();


--
-- Name: im_building_individual_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_levels_fkey_im_building; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_levels_fkey_im_levels; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_levels FOREIGN KEY (im_levels) REFERENCES im_levels(name);


--
-- Name: im_building_shared_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_individual_unit_level_fkey_im_building_hrsz_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_fkey_im_building_hrsz_unit FOREIGN KEY (im_building, hrsz_unit) REFERENCES im_building_individual_unit(im_building, hrsz_unit);


--
-- Name: im_individual_unit_level_fkey_im_building_im_levels; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_fkey_im_building_im_levels FOREIGN KEY (im_building, im_levels) REFERENCES im_building_levels(im_building, im_levels);


--
-- Name: im_parcel_fkey_settlement; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_fkey_settlement FOREIGN KEY (im_settlement) REFERENCES im_settlement(name);


--
-- Name: im_shared_unit_level_fkey_im_building_im_levels; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_fkey_im_building_im_levels FOREIGN KEY (im_building, im_levels) REFERENCES im_building_levels(im_building, im_levels);


--
-- Name: im_shared_unit_level_fkey_im_building_name; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_fkey_im_building_name FOREIGN KEY (im_building, shared_unit_name) REFERENCES im_building_shared_unit(im_building, name);


--
-- Name: im_underpass_fkey_settlement; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_fkey_settlement FOREIGN KEY (hrsz_settlement) REFERENCES im_settlement(name);


--
-- Name: im_underpass_individual_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_shared_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_unit_fkey_im_underpass; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_building; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: rt_right_fkey_im_building_individual_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building_individual_unit FOREIGN KEY (im_building_individual_unit) REFERENCES im_building_individual_unit(nid);


--
-- Name: rt_right_fkey_im_parcel; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_parcel FOREIGN KEY (im_parcel) REFERENCES im_parcel(nid);


--
-- Name: rt_right_fkey_im_underpass; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_underpass_individual_unit; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass_individual_unit FOREIGN KEY (im_underpass_individual_unit) REFERENCES im_underpass_individual_unit(nid);


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
    ADD CONSTRAINT rt_right_fkey_rt_type FOREIGN KEY (rt_type) REFERENCES rt_type(nid);


--
-- Name: sv_point_fkey_sv_survey_document; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_document FOREIGN KEY (sv_survey_document) REFERENCES sv_survey_document(nid);


--
-- Name: sv_point_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- Name: tp_node_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: own; Owner: tdc
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_fkey_sv_survey_point FOREIGN KEY (gid) REFERENCES sv_survey_point(nid);


--
-- PostgreSQL database dump complete
--

