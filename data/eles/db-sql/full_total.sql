--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: main; Type: SCHEMA; Schema: -; Owner: tdc
--

CREATE SCHEMA main;


ALTER SCHEMA main OWNER TO tdc;

--
-- Name: SCHEMA main; Type: COMMENT; Schema: -; Owner: tdc
--

COMMENT ON SCHEMA main IS 'Itt helyezkednek el a saját
-Tábláim
-Függvényeim
-Triggereim';


SET search_path = main, pg_catalog;

--
-- Name: geod_position; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE geod_position AS (
x double precision,
y double precision,
h double precision
);


ALTER TYPE main.geod_position OWNER TO tdc;

--
-- Name: parcel_with_data; Type: TYPE; Schema: main; Owner: tdc
--

CREATE TYPE parcel_with_data AS (
selected_projection bigint,
selected_name text,
selected_nid bigint,
immovable_type integer
);


ALTER TYPE main.parcel_with_data OWNER TO tdc;

--
-- Name: hrsz_concat(integer, integer); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION hrsz_concat(hrsz_main integer, hrsz_fraction integer) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
  output text;
BEGIN
  output := hrsz_main::text||CASE (hrsz_fraction IS NULL) WHEN TRUE THEN $$ $$ ELSE $$/$$ || hrsz_fraction::text END;
  return output;
END;
$_$;


ALTER FUNCTION main.hrsz_concat(hrsz_main integer, hrsz_fraction integer) OWNER TO tdc;

--
-- Name: parcels_with_data(); Type: FUNCTION; Schema: main; Owner: tdc
--

CREATE FUNCTION parcels_with_data() RETURNS SETOF parcel_with_data
    LANGUAGE plpgsql
    AS $$
DECLARE
  output main.parcel_with_data%rowtype;
BEGIN


  ---------------------
  -- 1. Foldreszlet ---
  ---------------------
  --
  -- Van tulajdonjog az im_parcel-en, de nincs az im_parcel-nek kapcsolata im_building-gel
  --
  FOR output IN
    SELECT DISTINCT
      parcel.projection AS selected_projection,
      'im_parcel' AS selected_name, 
      parcel.nid AS selected_nid,
      1 AS immovable_type
    FROM 
      main.im_parcel parcel, 
      main.rt_right r
    WHERE 
       parcel.nid=r.im_parcel AND      
       r.rt_type=1 AND
       coalesce(parcel.im_settlement,'')||main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) NOT IN (SELECT coalesce(im_settlement,'')||main.hrsz_concat(hrsz_main,hrsz_fraction) FROM main.im_building) LOOP
    RETURN NEXT output;
  END LOOP;


  --------------------------------
  --2. Foldreszlet az epulettel --
  --------------------------------
  --
  -- Van tualjdonjog az im_parcel-en, van im_building kapcsolata, de az im_building-en nincsen tulajdonjog
  --
  FOR output IN
     SELECT DISTINCT
      parcel.projection AS selected_projection,
      'im_parcel' AS selected_name, 
      parcel.nid AS selected_nid,
      2 AS immovable_type
    FROM main.im_parcel parcel, main.rt_right r, main.im_building building
    WHERE 
      parcel.nid=r.im_parcel AND 
      r.rt_type=1 AND
      building.im_settlement=parcel.im_settlement AND 
      main.hrsz_concat(building.hrsz_main, building.hrsz_fraction)=main.hrsz_concat(parcel.hrsz_main,parcel.hrsz_fraction) AND
      building.nid NOT IN (SELECT coalesce(im_building, -1) FROM main.rt_right WHERE rt_type=1 ) LOOP
    RETURN NEXT output;
  END LOOP;


  RETURN;
END;
$$;


ALTER FUNCTION main.parcels_with_data() OWNER TO tdc;

--
-- Name: sv_point_after(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.sv_point_after() OWNER TO tdc;

--
-- Name: sv_point_before(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.sv_point_before() OWNER TO tdc;

--
-- Name: tp_face_after(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.tp_face_after() OWNER TO tdc;

--
-- Name: tp_face_before(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.tp_face_before() OWNER TO tdc;

--
-- Name: tp_node_after(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.tp_node_after() OWNER TO tdc;

--
-- Name: tp_node_before(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.tp_node_before() OWNER TO tdc;

--
-- Name: tp_volume_before(); Type: FUNCTION; Schema: main; Owner: tdc
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


ALTER FUNCTION main.tp_volume_before() OWNER TO tdc;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: im_building; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
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
    hrsz_fraction integer,
    title_angle numeric(4,2)
);


ALTER TABLE main.im_building OWNER TO tdc;

--
-- Name: TABLE im_building; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building IS 'Az épületeket reprezentáló tábla';


--
-- Name: im_building_individual_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit (
    nid bigint NOT NULL,
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL
);


ALTER TABLE main.im_building_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit IS 'A társasházakban elhelyezkedő önállóan forgalomképes ingatlanok, lakások, üzlethelyiségek';


--
-- Name: im_building_individual_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_individual_unit_level (
    im_building bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    projection bigint,
    im_levels bigint NOT NULL,
    area integer,
    volume integer
);


ALTER TABLE main.im_building_individual_unit_level OWNER TO tdc;

--
-- Name: TABLE im_building_individual_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_individual_unit_level IS 'Társasházban található önálóan forgalomképes helyiségek szintjeit határozza meg. (mivel egy helyiség akár több szinten is elhelyezkedhet)';


--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_individual_unit_nid_seq OWNED BY im_building_individual_unit.nid;


--
-- Name: im_building_individual_unit_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_individual_unit_nid_seq', 1, false);


--
-- Name: im_building_level_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_level_unit (
    im_building bigint NOT NULL,
    im_levels bigint NOT NULL,
    area integer,
    volume integer,
    model bigint
);


ALTER TABLE main.im_building_level_unit OWNER TO tdc;

--
-- Name: TABLE im_building_level_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_level_unit IS 'Egy szintet képvisel egy családi háznál';


--
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_level_unig_volume_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_level_unig_volume_seq OWNER TO tdc;

--
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_level_unig_volume_seq OWNED BY im_building_level_unit.volume;


--
-- Name: im_building_level_unig_volume_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_level_unig_volume_seq', 1, false);


--
-- Name: im_building_levels; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_levels (
    im_building bigint NOT NULL,
    im_levels bigint NOT NULL
);


ALTER TABLE main.im_building_levels OWNER TO tdc;

--
-- Name: TABLE im_building_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_levels IS 'Egy adott épületen belül előforduló szintek';


--
-- Name: im_building_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_building_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_building_nid_seq OWNER TO tdc;

--
-- Name: im_building_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_building_nid_seq OWNED BY im_building.nid;


--
-- Name: im_building_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_building_nid_seq', 1, false);


--
-- Name: im_building_shared_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_building_shared_unit (
    im_building bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.im_building_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_building_shared_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_building_shared_unit IS 'A társasházak közös helyiségei';


--
-- Name: im_levels; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_levels (
    name text NOT NULL,
    nid bigint NOT NULL
);


ALTER TABLE main.im_levels OWNER TO tdc;

--
-- Name: TABLE im_levels; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_levels IS 'Az összes előforduló szint megnevezése az épületekben';


--
-- Name: im_levels_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_levels_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_levels_nid_seq OWNER TO tdc;

--
-- Name: im_levels_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_levels_nid_seq OWNED BY im_levels.nid;


--
-- Name: im_levels_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_levels_nid_seq', 17, true);


--
-- Name: im_parcel; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_parcel (
    nid bigint NOT NULL,
    area integer NOT NULL,
    im_settlement text NOT NULL,
    hrsz_main integer NOT NULL,
    hrsz_fraction integer,
    projection bigint NOT NULL,
    model bigint,
    title_angle numeric(4,2) DEFAULT 0
);


ALTER TABLE main.im_parcel OWNER TO tdc;

--
-- Name: TABLE im_parcel; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_parcel IS 'Ez az ugynevezett földrészlet.
Az im_parcel-ek topologiát alkotnak';


--
-- Name: COLUMN im_parcel.title_angle; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON COLUMN im_parcel.title_angle IS 'A helyrajziszám dőlésszöge';


--
-- Name: im_settlement; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_settlement (
    name text NOT NULL
);


ALTER TABLE main.im_settlement OWNER TO tdc;

--
-- Name: TABLE im_settlement; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_settlement IS 'Magyarorszag településeinek neve';


--
-- Name: im_shared_unit_level; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_shared_unit_level (
    im_building bigint NOT NULL,
    im_levels text NOT NULL,
    shared_unit_name text NOT NULL
);


ALTER TABLE main.im_shared_unit_level OWNER TO tdc;

--
-- Name: TABLE im_shared_unit_level; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_shared_unit_level IS 'Társasházakban a közös helyiségek, fő épületszerkezeti elemek szintjeit határozza meg. (mivel a közös helyiségek akár több szinten is elhelyezkedhetnek)';


--
-- Name: im_underpass; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
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


ALTER TABLE main.im_underpass OWNER TO tdc;

--
-- Name: TABLE im_underpass; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass IS 'Aluljárók tábla.
EÖI tehát település+fő/alátört helyrajzi szám az azonosítója.
Rendelkeznie kell vetülettel és lehetőség szerint 3D modellel is';


--
-- Name: im_underpass_block; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_block (
    nid bigint NOT NULL,
    hrsz_eoi text NOT NULL,
    im_underpass bigint NOT NULL
);


ALTER TABLE main.im_underpass_block OWNER TO tdc;

--
-- Name: TABLE im_underpass_block; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_block IS 'Ezek az objektumok foglaljak egybe az aluljáróban található üzleteket. Tulajdonképpen analógok a Building-gel társasház esetén';


--
-- Name: im_underpass_individual_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_individual_unit (
    nid bigint NOT NULL,
    im_underpass_block bigint NOT NULL,
    hrsz_unit integer NOT NULL,
    area integer,
    volume integer
);


ALTER TABLE main.im_underpass_individual_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_individual_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_individual_unit IS 'Ezek az ingatlantípusok az aluljárókban lévő üzletek. 
EÖI';


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE im_underpass_individual_unit_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.im_underpass_individual_unit_nid_seq OWNER TO tdc;

--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE im_underpass_individual_unit_nid_seq OWNED BY im_underpass_individual_unit.nid;


--
-- Name: im_underpass_individual_unit_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('im_underpass_individual_unit_nid_seq', 1, false);


--
-- Name: im_underpass_shared_unit; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE im_underpass_shared_unit (
    im_underpass_block bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.im_underpass_shared_unit OWNER TO tdc;

--
-- Name: TABLE im_underpass_shared_unit; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE im_underpass_shared_unit IS 'Ez az egység reprezentálja az aluljáróban lévő üzletek közös részét -ami mindenkihez tartozik és közösen fizetik a fenntartási költségeit';


--
-- Name: pn_person; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE pn_person (
    nid bigint NOT NULL,
    name text NOT NULL
);


ALTER TABLE main.pn_person OWNER TO tdc;

--
-- Name: TABLE pn_person; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE pn_person IS 'Ez a személyeket tartalmazó tábla. Ide tartoznak természtes és jogi személyek is';


--
-- Name: rt_legal_document; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_legal_document (
    nid bigint NOT NULL,
    content text NOT NULL,
    date date NOT NULL,
    sale_price numeric(12,2)
);


ALTER TABLE main.rt_legal_document OWNER TO tdc;

--
-- Name: TABLE rt_legal_document; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_legal_document IS 'Azon dokumentumok, melyek alapján egy személy valamilyen jogi kapcsolatba került egy ingatlannal';


--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE rt_legal_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.rt_legal_document_nid_seq OWNER TO tdc;

--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE rt_legal_document_nid_seq OWNED BY rt_legal_document.nid;


--
-- Name: rt_legal_document_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('rt_legal_document_nid_seq', 1, false);


--
-- Name: rt_right; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
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


ALTER TABLE main.rt_right OWNER TO tdc;

--
-- Name: TABLE rt_right; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_right IS 'Jogok. Ez a tábla köti össze a személyt egy ingatlannal valamilyen jogi dokumentum alapján. ';


--
-- Name: rt_type; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE rt_type (
    name text NOT NULL,
    nid bigint NOT NULL
);


ALTER TABLE main.rt_type OWNER TO tdc;

--
-- Name: TABLE rt_type; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE rt_type IS 'Itt szerepelnek azok a jogok, melyek alapján egy személy kapcsolatba kerülhet egy ingatlannal';


--
-- Name: sv_point; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
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


ALTER TABLE main.sv_point OWNER TO tdc;

--
-- Name: TABLE sv_point; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_point IS 'Mért pont. Lehet 2 és 3 dimenziós is';


--
-- Name: sv_point_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_point_nid_seq OWNER TO tdc;

--
-- Name: sv_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_point_nid_seq OWNED BY sv_point.nid;


--
-- Name: sv_point_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_point_nid_seq', 2, true);


--
-- Name: sv_survey_document; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_document (
    nid bigint NOT NULL,
    date date DEFAULT ('now'::text)::date NOT NULL,
    data text
);


ALTER TABLE main.sv_survey_document OWNER TO tdc;

--
-- Name: TABLE sv_survey_document; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_survey_document IS 'Mérési jegyzőkönyv a felmért pontok számára';


--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_survey_document_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_survey_document_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_survey_document_nid_seq OWNED BY sv_survey_document.nid;


--
-- Name: sv_survey_document_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_document_nid_seq', 5, true);


--
-- Name: sv_survey_point; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE sv_survey_point (
    nid bigint NOT NULL,
    description text,
    name text NOT NULL
);


ALTER TABLE main.sv_survey_point OWNER TO tdc;

--
-- Name: TABLE sv_survey_point; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE sv_survey_point IS 'Mérési pont azonosítása és leírása';


--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE sv_survey_point_nid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.sv_survey_point_nid_seq OWNER TO tdc;

--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE sv_survey_point_nid_seq OWNED BY sv_survey_point.nid;


--
-- Name: sv_survey_point_nid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('sv_survey_point_nid_seq', 20, true);


SET default_with_oids = true;

--
-- Name: tp_face; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_face (
    gid bigint NOT NULL,
    nodelist bigint[] NOT NULL,
    geom public.geometry(PolygonZ),
    holelist bigint[],
    note text
);


ALTER TABLE main.tp_face OWNER TO tdc;

--
-- Name: TABLE tp_face; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_face IS 'Felület. Pontjait a tp_node elemei alkotják';


--
-- Name: tp_face_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_face_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_face_gid_seq OWNER TO tdc;

--
-- Name: tp_face_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_face_gid_seq OWNED BY tp_face.gid;


--
-- Name: tp_face_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_face_gid_seq', 2, true);


--
-- Name: tp_node; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_node (
    gid bigint NOT NULL,
    geom public.geometry(PointZ),
    note text
);


ALTER TABLE main.tp_node OWNER TO tdc;

--
-- Name: TABLE tp_node; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_node IS 'Csomópont. Egy sv_survey_point-ot azonosít. Van geometriája, mely mindig a dátum szerinti aktuális sv_point adatait tartalmazza.';


--
-- Name: tp_node_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_node_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_node_gid_seq OWNER TO tdc;

--
-- Name: tp_node_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_node_gid_seq OWNED BY tp_node.gid;


--
-- Name: tp_node_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_node_gid_seq', 22, true);


--
-- Name: tp_volume; Type: TABLE; Schema: main; Owner: tdc; Tablespace: 
--

CREATE TABLE tp_volume (
    gid bigint NOT NULL,
    facelist bigint[] NOT NULL,
    note text,
    geom public.geometry(PolyhedralSurfaceZ)
);


ALTER TABLE main.tp_volume OWNER TO tdc;

--
-- Name: TABLE tp_volume; Type: COMMENT; Schema: main; Owner: tdc
--

COMMENT ON TABLE tp_volume IS '3D-s térfogati elem. tp_face-ek írják le';


--
-- Name: tp_volume_gid_seq; Type: SEQUENCE; Schema: main; Owner: tdc
--

CREATE SEQUENCE tp_volume_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE main.tp_volume_gid_seq OWNER TO tdc;

--
-- Name: tp_volume_gid_seq; Type: SEQUENCE OWNED BY; Schema: main; Owner: tdc
--

ALTER SEQUENCE tp_volume_gid_seq OWNED BY tp_volume.gid;


--
-- Name: tp_volume_gid_seq; Type: SEQUENCE SET; Schema: main; Owner: tdc
--

SELECT pg_catalog.setval('tp_volume_gid_seq', 1, true);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building ALTER COLUMN nid SET DEFAULT nextval('im_building_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_building_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_levels ALTER COLUMN nid SET DEFAULT nextval('im_levels_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit ALTER COLUMN nid SET DEFAULT nextval('im_underpass_individual_unit_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_legal_document ALTER COLUMN nid SET DEFAULT nextval('rt_legal_document_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point ALTER COLUMN nid SET DEFAULT nextval('sv_point_nid_seq'::regclass);


--
-- Name: nid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_survey_document ALTER COLUMN nid SET DEFAULT nextval('sv_survey_document_nid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_face ALTER COLUMN gid SET DEFAULT nextval('tp_face_gid_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_volume ALTER COLUMN gid SET DEFAULT nextval('tp_volume_gid_seq'::regclass);


--
-- Data for Name: im_building; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building VALUES (1, NULL, NULL, 'A', 51, 40, 'Budapest', 211, 1, 30.00);
INSERT INTO im_building VALUES (2, NULL, NULL, NULL, 57, 43, 'Budapest', 124, NULL, 30.00);
INSERT INTO im_building VALUES (3, NULL, NULL, NULL, 63, 44, 'Budapest', 124, NULL, 30.00);


--
-- Data for Name: im_building_individual_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_building_individual_unit_level; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_building_level_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_level_unit VALUES (1, 0, 149, NULL, 42);
INSERT INTO im_building_level_unit VALUES (1, 1, 149, NULL, 41);
INSERT INTO im_building_level_unit VALUES (3, 0, 58, NULL, 44);
INSERT INTO im_building_level_unit VALUES (2, 0, 58, NULL, 43);


--
-- Data for Name: im_building_levels; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_building_levels VALUES (1, 0);
INSERT INTO im_building_levels VALUES (1, 1);
INSERT INTO im_building_levels VALUES (2, 0);
INSERT INTO im_building_levels VALUES (3, 0);


--
-- Data for Name: im_building_shared_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_levels; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_levels VALUES ('Földszint', 0);
INSERT INTO im_levels VALUES ('1. emelet', 1);
INSERT INTO im_levels VALUES ('3. emelet', 3);
INSERT INTO im_levels VALUES ('Magasföldszint', -1);
INSERT INTO im_levels VALUES ('2. emelet', 2);
INSERT INTO im_levels VALUES ('4. emelet', 4);
INSERT INTO im_levels VALUES ('5. emelet', 5);
INSERT INTO im_levels VALUES ('6. emelet', 6);
INSERT INTO im_levels VALUES ('7. emelet', 7);
INSERT INTO im_levels VALUES ('8. emelet', 8);
INSERT INTO im_levels VALUES ('9. emelet', 9);
INSERT INTO im_levels VALUES ('10. emelet', 10);


--
-- Data for Name: im_parcel; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_parcel VALUES (1, 1264, 'Budapest', 213, NULL, 14, 14, 30.00);
INSERT INTO im_parcel VALUES (2, 1285, 'Budapest', 212, NULL, 13, 13, 30.00);
INSERT INTO im_parcel VALUES (3, 1325, 'Budapest', 211, 1, 11, 11, 30.00);
INSERT INTO im_parcel VALUES (4, 1268, 'Budapest', 124, NULL, 2, 2, 30.00);


--
-- Data for Name: im_settlement; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO im_settlement VALUES ('Budapest');


--
-- Data for Name: im_shared_unit_level; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_block; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_individual_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: im_underpass_shared_unit; Type: TABLE DATA; Schema: main; Owner: tdc
--



--
-- Data for Name: pn_person; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO pn_person VALUES (1, 'Magyar Állam');
INSERT INTO pn_person VALUES (2, 'Kerületi önkormányzat');
INSERT INTO pn_person VALUES (3, 'Kovács János');
INSERT INTO pn_person VALUES (4, 'Kiss Tibor');
INSERT INTO pn_person VALUES (5, 'Nagy Tibor');
INSERT INTO pn_person VALUES (6, 'Tóth Béla');
INSERT INTO pn_person VALUES (7, 'Balogh János');
INSERT INTO pn_person VALUES (8, 'Nagy János');
INSERT INTO pn_person VALUES (9, 'Nagy Jánosné');
INSERT INTO pn_person VALUES (10, 'Varga Katalin');


--
-- Data for Name: rt_legal_document; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_legal_document VALUES (1, 'Adás-vételi szerződés

Kovács János mint vevő...
...', '1980-03-04', 1000000.00);
INSERT INTO rt_legal_document VALUES (3, 'Adás-vételi szerződés

Vevő: Tóth Béla, Balogh János', '1993-12-04', 4300000.00);
INSERT INTO rt_legal_document VALUES (2, 'Adás-vételi szerződés

Mely létrejött Nagy Tibor és Kiss Tibor mint vevő ...', '1979-10-23', 1320000.00);
INSERT INTO rt_legal_document VALUES (4, 'Adás-vételi szerződés

Vevők: Nagy János, Nagy Jánosné, Varga Katalin', '2002-05-17', 8540000.00);


--
-- Data for Name: rt_right; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_right VALUES (3, 1, 1, NULL, NULL, NULL, NULL, 1, 1, 1);
INSERT INTO rt_right VALUES (4, 2, 2, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (5, 2, 2, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (6, 3, 3, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (7, 3, 3, NULL, NULL, NULL, NULL, 1, 2, 1);
INSERT INTO rt_right VALUES (9, 4, 4, NULL, NULL, NULL, NULL, 2, 6, 1);
INSERT INTO rt_right VALUES (10, 4, 4, NULL, NULL, NULL, NULL, 1, 6, 1);
INSERT INTO rt_right VALUES (8, 4, 4, NULL, NULL, NULL, NULL, 3, 6, 1);


--
-- Data for Name: rt_type; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO rt_type VALUES ('Tulajdonjog', 1);
INSERT INTO rt_type VALUES ('Kezelői jog', 2);


--
-- Data for Name: sv_point; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_point VALUES (57, 57, 1, 645534.66, 227926.73, 101.20, 3, 1);
INSERT INTO sv_point VALUES (54, 54, 1, 645471.90, 227916.06, 101.18, 3, 1);
INSERT INTO sv_point VALUES (68, 68, 2, 645427.16, 227950.39, 101.53, 3, 2);
INSERT INTO sv_point VALUES (69, 69, 2, 645436.79, 227956.07, 101.59, 3, 2);
INSERT INTO sv_point VALUES (1, 1, 1, 645415.99, 227907.82, 101.35, 3, 1);
INSERT INTO sv_point VALUES (2, 2, 1, 645393.58, 227894.87, 101.30, 3, 1);
INSERT INTO sv_point VALUES (3, 3, 1, 645388.42, 227902.87, 101.37, 3, 1);
INSERT INTO sv_point VALUES (4, 4, 1, 645382.45, 227912.26, 101.47, 3, 1);
INSERT INTO sv_point VALUES (5, 5, 1, 645405.13, 227925.69, 101.52, 3, 1);
INSERT INTO sv_point VALUES (70, 70, 2, 645429.72, 227967.50, 102.17, 3, 2);
INSERT INTO sv_point VALUES (71, 71, 2, 645420.21, 227961.70, 102.11, 3, 2);
INSERT INTO sv_point VALUES (6, 6, 1, 645392.30, 227946.23, 102.00, 3, 1);
INSERT INTO sv_point VALUES (7, 7, 1, 645361.32, 227927.08, 101.95, 3, 1);
INSERT INTO sv_point VALUES (8, 8, 1, 645347.19, 227918.95, 101.75, 3, 1);
INSERT INTO sv_point VALUES (9, 9, 1, 645358.91, 227898.19, 101.27, 3, 1);
INSERT INTO sv_point VALUES (10, 10, 1, 645374.75, 227974.91, 102.61, 3, 1);
INSERT INTO sv_point VALUES (11, 11, 1, 645344.79, 227956.34, 102.56, 3, 1);
INSERT INTO sv_point VALUES (12, 12, 1, 645368.90, 227879.87, 101.20, 3, 1);
INSERT INTO sv_point VALUES (13, 13, 1, 645363.86, 227889.01, 101.27, 3, 1);
INSERT INTO sv_point VALUES (14, 14, 1, 645332.38, 227857.64, 101.03, 3, 1);
INSERT INTO sv_point VALUES (15, 15, 1, 645322.10, 227875.13, 101.20, 3, 1);
INSERT INTO sv_point VALUES (16, 16, 1, 645309.53, 227896.26, 101.58, 3, 1);
INSERT INTO sv_point VALUES (17, 17, 1, 645333.93, 227909.96, 101.68, 3, 1);
INSERT INTO sv_point VALUES (18, 18, 1, 645316.54, 227939.65, 102.30, 3, 1);
INSERT INTO sv_point VALUES (19, 19, 1, 645292.57, 227925.10, 101.98, 3, 1);
INSERT INTO sv_point VALUES (20, 20, 1, 645434.87, 227919.23, 101.45, 3, 1);
INSERT INTO sv_point VALUES (21, 21, 1, 645422.90, 227939.17, 101.53, 3, 1);
INSERT INTO sv_point VALUES (22, 22, 1, 645446.22, 227952.49, 101.56, 3, 1);
INSERT INTO sv_point VALUES (23, 23, 1, 645457.56, 227933.18, 101.48, 3, 1);
INSERT INTO sv_point VALUES (24, 24, 1, 645500.58, 227983.31, 101.66, 3, 1);
INSERT INTO sv_point VALUES (25, 25, 1, 645511.06, 227965.28, 101.58, 3, 1);
INSERT INTO sv_point VALUES (26, 26, 1, 645408.88, 227961.85, 102.11, 3, 1);
INSERT INTO sv_point VALUES (27, 27, 1, 645450.93, 227987.59, 102.17, 3, 1);
INSERT INTO sv_point VALUES (28, 28, 1, 645487.31, 228009.41, 102.24, 3, 1);
INSERT INTO sv_point VALUES (29, 29, 1, 645464.20, 227963.62, 101.59, 3, 1);
INSERT INTO sv_point VALUES (30, 30, 1, 645401.28, 227973.89, 102.33, 3, 1);
INSERT INTO sv_point VALUES (31, 31, 1, 645479.18, 228020.97, 102.46, 3, 1);
INSERT INTO sv_point VALUES (32, 32, 1, 645394.01, 227985.02, 102.70, 3, 1);
INSERT INTO sv_point VALUES (33, 33, 1, 645471.90, 228033.38, 102.83, 3, 1);
INSERT INTO sv_point VALUES (34, 34, 1, 645427.05, 227889.75, 101.23, 3, 1);
INSERT INTO sv_point VALUES (35, 35, 1, 645435.42, 227876.15, 101.07, 3, 1);
INSERT INTO sv_point VALUES (36, 36, 1, 645424.50, 227869.94, 100.99, 3, 1);
INSERT INTO sv_point VALUES (37, 37, 1, 645416.80, 227883.53, 101.20, 3, 1);
INSERT INTO sv_point VALUES (38, 38, 1, 645393.18, 227849.68, 100.95, 3, 1);
INSERT INTO sv_point VALUES (39, 39, 1, 645384.00, 227863.73, 101.12, 3, 1);
INSERT INTO sv_point VALUES (40, 40, 1, 645352.21, 227824.95, 100.84, 3, 1);
INSERT INTO sv_point VALUES (41, 41, 1, 645343.50, 227839.23, 101.00, 3, 1);
INSERT INTO sv_point VALUES (42, 42, 1, 645444.51, 227861.27, 100.99, 3, 1);
INSERT INTO sv_point VALUES (43, 43, 1, 645409.87, 227840.03, 100.88, 3, 1);
INSERT INTO sv_point VALUES (44, 44, 1, 645401.71, 227835.29, 100.87, 3, 1);
INSERT INTO sv_point VALUES (45, 45, 1, 645360.93, 227810.74, 100.76, 3, 1);
INSERT INTO sv_point VALUES (46, 46, 1, 645457.35, 227840.52, 100.98, 3, 1);
INSERT INTO sv_point VALUES (47, 47, 1, 645422.71, 227818.63, 100.87, 3, 1);
INSERT INTO sv_point VALUES (48, 48, 1, 645374.13, 227789.95, 100.75, 3, 1);
INSERT INTO sv_point VALUES (49, 49, 1, 645465.91, 227826.18, 100.92, 3, 1);
INSERT INTO sv_point VALUES (50, 50, 1, 645382.73, 227775.01, 100.69, 3, 1);
INSERT INTO sv_point VALUES (51, 51, 1, 645415.95, 227864.44, 100.98, 3, 1);
INSERT INTO sv_point VALUES (52, 52, 1, 645424.84, 227849.22, 100.89, 3, 1);
INSERT INTO sv_point VALUES (53, 53, 1, 645445.97, 227901.19, 101.13, 3, 1);
INSERT INTO sv_point VALUES (55, 55, 1, 645483.08, 227896.34, 101.03, 3, 1);
INSERT INTO sv_point VALUES (56, 56, 1, 645458.31, 227880.85, 100.97, 3, 1);
INSERT INTO sv_point VALUES (58, 58, 1, 645503.03, 227908.09, 101.10, 3, 1);
INSERT INTO sv_point VALUES (59, 59, 1, 645513.52, 227890.65, 101.04, 3, 1);
INSERT INTO sv_point VALUES (60, 60, 1, 645468.69, 227864.06, 100.91, 3, 1);
INSERT INTO sv_point VALUES (61, 61, 1, 645544.31, 227911.40, 101.10, 3, 1);
INSERT INTO sv_point VALUES (62, 62, 1, 645519.92, 227880.80, 101.01, 3, 1);
INSERT INTO sv_point VALUES (63, 63, 1, 645474.90, 227854.21, 100.88, 3, 1);
INSERT INTO sv_point VALUES (64, 64, 1, 645552.02, 227900.27, 101.07, 3, 1);
INSERT INTO sv_point VALUES (65, 65, 1, 645485.60, 227836.66, 100.82, 3, 1);
INSERT INTO sv_point VALUES (66, 66, 1, 645561.63, 227882.87, 100.02, 3, 1);
INSERT INTO sv_point VALUES (67, 67, 1, 645521.34, 227947.30, 101.38, 3, 1);
INSERT INTO sv_point VALUES (72, 72, 2, 645427.16, 227950.39, 108.11, 3, 2);
INSERT INTO sv_point VALUES (75, 75, 2, 645420.21, 227961.70, 108.11, 3, 2);
INSERT INTO sv_point VALUES (74, 74, 2, 645429.72, 227967.50, 108.11, 3, 2);
INSERT INTO sv_point VALUES (73, 73, 2, 645436.79, 227956.07, 108.11, 3, 2);
INSERT INTO sv_point VALUES (77, 77, 2, 645436.79, 227956.07, 105.11, 3, 2);
INSERT INTO sv_point VALUES (78, 78, 2, 645429.72, 227967.50, 105.11, 3, 2);
INSERT INTO sv_point VALUES (79, 79, 2, 645420.21, 227961.70, 105.11, 3, 2);
INSERT INTO sv_point VALUES (76, 76, 2, 645427.16, 227950.39, 105.11, 3, 2);
INSERT INTO sv_point VALUES (80, 80, 2, 645388.63, 227938.68, 101.90, 3, 2);
INSERT INTO sv_point VALUES (81, 81, 2, 645379.97, 227933.54, 101.90, 3, 2);
INSERT INTO sv_point VALUES (83, 83, 2, 645396.66, 227926.16, 101.85, 3, 2);
INSERT INTO sv_point VALUES (84, 84, 2, 645359.01, 227921.36, 101.30, 3, 2);
INSERT INTO sv_point VALUES (85, 85, 2, 645366.36, 227925.28, 101.50, 3, 2);
INSERT INTO sv_point VALUES (86, 86, 2, 645369.69, 227919.22, 101.50, 3, 2);
INSERT INTO sv_point VALUES (87, 87, 2, 645362.52, 227915.10, 101.30, 3, 2);
INSERT INTO sv_point VALUES (88, 88, 2, 645388.63, 227938.68, 104.80, 3, 2);
INSERT INTO sv_point VALUES (89, 89, 2, 645379.97, 227933.54, 104.80, 3, 2);
INSERT INTO sv_point VALUES (90, 90, 2, 645387.78, 227920.91, 104.80, 3, 2);
INSERT INTO sv_point VALUES (82, 82, 2, 645387.78, 227920.91, 101.80, 3, 2);
INSERT INTO sv_point VALUES (91, 91, 2, 645396.66, 227926.16, 104.80, 3, 2);
INSERT INTO sv_point VALUES (92, 92, 2, 645359.01, 227921.36, 104.30, 3, 2);
INSERT INTO sv_point VALUES (93, 93, 2, 645366.36, 227925.28, 104.30, 3, 2);
INSERT INTO sv_point VALUES (94, 94, 2, 645369.69, 227919.22, 104.30, 3, 2);
INSERT INTO sv_point VALUES (95, 95, 2, 645362.52, 227915.10, 104.30, 3, 2);


--
-- Data for Name: sv_survey_document; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_survey_document VALUES (1, '2012-10-23', 'Mérési jegyzőkönyv

1. földrészlet felmérés');
INSERT INTO sv_survey_document VALUES (2, '2012-10-23', 'Mérési jegyzőkönyv

Épület sarokpontok felmérése');


--
-- Data for Name: sv_survey_point; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO sv_survey_point VALUES (1, '123 hrsz-ú telek térre néző sarokpontja', '1');
INSERT INTO sv_survey_point VALUES (3, '122 és 123 hrsz-ú telkek közös épületsarokpontja', '3');
INSERT INTO sv_survey_point VALUES (4, '122 és 123 hrsz-ú telkek belső közös sarokpontja', '4');
INSERT INTO sv_survey_point VALUES (8, '124, 125, 127 hrsz-ú telkek közös sarokpontja', '8');
INSERT INTO sv_survey_point VALUES (9, '121,122, 124, 125 hrsz-ú telkek közös sarokpontja', '9');
INSERT INTO sv_survey_point VALUES (7, '124, 126, 127 hrsz-ú telkek közös sarokpontja', '7');
INSERT INTO sv_survey_point VALUES (10, '126 hrsz-ú telek tér felöli sarokpontja', '10');
INSERT INTO sv_survey_point VALUES (11, '126 és 127 hrsz-ú telkek közös utcafronti sarokpontja', '11');
INSERT INTO sv_survey_point VALUES (12, '121, 122 hrsz-ú telkek közös utcafronti sarokpontja', '12');
INSERT INTO sv_survey_point VALUES (13, '122 hrsz-ú telek 121 hrsz-ú telekkel szomszédos épületsarokpontja', '13');
INSERT INTO sv_survey_point VALUES (14, '121 hrsz-ú telek térre néző sarokpontja', '14');
INSERT INTO sv_survey_point VALUES (15, '121 és 125 hrsz-ú telkek közös utcafronti sarokpontja', '15');
INSERT INTO sv_survey_point VALUES (16, '125 és 126/1 hrsz-ú telkek közös utcafronti sarokpontja', '16');
INSERT INTO sv_survey_point VALUES (17, '125, 126/2, 126/3 hrsz-ú ingatlanok közös sarokpontja', '17');
INSERT INTO sv_survey_point VALUES (18, '126/2 és 126/3 hrsz-ú ingatlanok közös utcafronti sarokpontja', '18');
INSERT INTO sv_survey_point VALUES (19, '126/3 hrsz-ú ingatlan tér felöli sarokpontja', '19');
INSERT INTO sv_survey_point VALUES (20, '210/1 hrsz-ú ingatlan tér felöli sarokpontja', '20');
INSERT INTO sv_survey_point VALUES (21, '210/1 és 211/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '21');
INSERT INTO sv_survey_point VALUES (22, '210/1, 210/2, 211/1 hrsz-ú ingatlanok közös sarokpontja', '22');
INSERT INTO sv_survey_point VALUES (23, '210/1 és 210/2 ingatlanok közös utcafronti sarokpontja', '23');
INSERT INTO sv_survey_point VALUES (24, '210/2 és 211/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '24');
INSERT INTO sv_survey_point VALUES (25, '210/2 hrsz-ú ingatlan tér felüli sarokpontja', '25');
INSERT INTO sv_survey_point VALUES (28, '211/2 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '28');
INSERT INTO sv_survey_point VALUES (29, '210/2, 211/1, 211/2 hrsz-ú ingatlanok közös sarokpontja', '29');
INSERT INTO sv_survey_point VALUES (30, '212 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '30');
INSERT INTO sv_survey_point VALUES (31, '212 és 213 hrsz-ú ingatlanok közös utcafronti sarokpontja', '31');
INSERT INTO sv_survey_point VALUES (32, '213 hrsz-ú ingatlan tér felüli sarokpontja', '32');
INSERT INTO sv_survey_point VALUES (33, '213 hrsz-ú ingatlan tér felüli sarokpontja', '33');
INSERT INTO sv_survey_point VALUES (27, '211/1, 211/2, 212 hrsz-ú ingatlanok közös sarokpontja', '27');
INSERT INTO sv_survey_point VALUES (26, '211/1 és 212 hrsz-ú ingatlanok közös utcafronti sarokpontja', '26');
INSERT INTO sv_survey_point VALUES (34, '325/5 hrsz-ú ingatlan tér felöli sarokpontja', '34');
INSERT INTO sv_survey_point VALUES (35, '325/2, 325/5 hrsz-ú ingatlanok közös utcafronti sarokpontja', '35');
INSERT INTO sv_survey_point VALUES (36, '352/2, 352/4, 352/5 hrsz-ú ingatlanok közös sarokpontja', '36');
INSERT INTO sv_survey_point VALUES (37, '252/4, 252/5 hrsz-ú ingatlanok közös utcafronti sarokpontja', '37');
INSERT INTO sv_survey_point VALUES (39, '352/3, 352/4 hrsz-ú ingatlan közös utcafronti sarokpontja', '39');
INSERT INTO sv_survey_point VALUES (40, '352/1, 352/3 hrsz-ú ingatlan közös utcafronti sarokpontja', '40');
INSERT INTO sv_survey_point VALUES (41, '253/3 hrsz-ú ingatlan tér felöli sarokpontja', '41');
INSERT INTO sv_survey_point VALUES (42, '252/2, 251/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '42');
INSERT INTO sv_survey_point VALUES (43, '251/1, 251/2, 252/2 hrsz-ú ingatlanok közös sarokpontja', '43');
INSERT INTO sv_survey_point VALUES (44, '351/1, 351/2, 352/1 hrsz-ú ingatlanok közös sarokpontja', '44');
INSERT INTO sv_survey_point VALUES (45, '351/1, 352/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '45');
INSERT INTO sv_survey_point VALUES (46, '351/2, 350 hrsz-ú ingatlanok közös utcafronti sarokpontja', '46');
INSERT INTO sv_survey_point VALUES (47, '350, 351/1, 351/2 hrsz-ú ingatlanok közös sarokpontja', '47');
INSERT INTO sv_survey_point VALUES (2, '123 és 122 hrsz-ú telkek közös utcafronti sarokpontja', '2');
INSERT INTO sv_survey_point VALUES (5, '123 és 124 hrsz-ú telkek közös utcafronti sarokpontja', '5');
INSERT INTO sv_survey_point VALUES (6, '124 és a 126 hrsz-ú telkek közös utcafronti sarokpontja', '6');
INSERT INTO sv_survey_point VALUES (48, '350, 351/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '48');
INSERT INTO sv_survey_point VALUES (49, '350 hrsz-ú ingatlan térre néző sarokpontja', '49');
INSERT INTO sv_survey_point VALUES (50, '350 hrsz-ú ingatlan térre néző sarokpontja', '50');
INSERT INTO sv_survey_point VALUES (38, '352/1, 352/2, 352/3, 352/4 hrsz-ú ingatlanok közös sarokpontja', '38');
INSERT INTO sv_survey_point VALUES (51, '352/2 hrsz-on lévő épület sarokpontja és a 352/4 hrsz-ú ingatlan határpontja', '51');
INSERT INTO sv_survey_point VALUES (52, '352/2 hrsz-on lévő épület sarokpontja és a 351/2 hrsz-ú ingatlan határpontja', '52');
INSERT INTO sv_survey_point VALUES (53, '474/1 hrsz-ú ingatlan tér felüli sarokpontja', '53');
INSERT INTO sv_survey_point VALUES (54, '474/1, 474/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '54');
INSERT INTO sv_survey_point VALUES (55, '474/1, 474/2, 473/1 hrsz-ú ingatlanok közös sarokpontja', '55');
INSERT INTO sv_survey_point VALUES (56, '474/1, 473/1 hrsz-ú ingatlanok közös sarokpontja', '56');
INSERT INTO sv_survey_point VALUES (57, '474/2, 473/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '57');
INSERT INTO sv_survey_point VALUES (58, '474/2, 473/1, 373/2 hrsz-ú ingatlanok közös sarokpontja', '58');
INSERT INTO sv_survey_point VALUES (59, '473/1, 473/2, 472/1, 472/2 hrsz-ú ingatlanok közös sarokpontja', '59');
INSERT INTO sv_survey_point VALUES (60, '472/1, 473/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '60');
INSERT INTO sv_survey_point VALUES (61, '472/2, 473/3 hrsz-ú ingatlanok közös utcafronti sarokpontja', '61');
INSERT INTO sv_survey_point VALUES (62, '472/, 472/2 hrsz-ú ingatlanok közös sarok- 471 hrsz-ú ingatlan közös határpontja', '62');
INSERT INTO sv_survey_point VALUES (63, '471, 472/1 hrsz-ú ingatlanok közös utcafronti sarokpontja', '63');
INSERT INTO sv_survey_point VALUES (64, '471, 472/2 hrsz-ú ingatlanok közös utcafronti sarokpontja', '64');
INSERT INTO sv_survey_point VALUES (65, '471 hrsz-ú ingatlan tér felöli sarokpontja', '65');
INSERT INTO sv_survey_point VALUES (66, '471 hrsz-ú ingatlan tér felöli sarokpontja', '66');
INSERT INTO sv_survey_point VALUES (67, '474/2 hrsz-ú ingatlan térre néző sarokpontja', '67');
INSERT INTO sv_survey_point VALUES (75, '211/1 hrsz-ú épület NY-i felső sarokpontja', '75');
INSERT INTO sv_survey_point VALUES (74, '211/1 hrsz-ú épület É-i felső sarokpontja', '74');
INSERT INTO sv_survey_point VALUES (73, '211/1 hrsz-ú épület K-i felső sarokpontja', '73');
INSERT INTO sv_survey_point VALUES (72, '211/1 hrsz-ú épület D-i felső sarokpontja', '72');
INSERT INTO sv_survey_point VALUES (71, '211/1 hrsz-ú épület NY-i alsó sarokpontja', '71');
INSERT INTO sv_survey_point VALUES (70, '211/1 hrsz-ú épület É-i alsó sarokpontja', '70');
INSERT INTO sv_survey_point VALUES (69, '211/1 hrsz-ú épület K-i alsó sarokpontja', '69');
INSERT INTO sv_survey_point VALUES (68, '211/1 hrsz-ú épület D-i alsó sarokpontja', '68');
INSERT INTO sv_survey_point VALUES (76, '211/1 hrsz-ú épület D-i emeleti sarokpontja', '76');
INSERT INTO sv_survey_point VALUES (77, '211/1 hrsz-ú épület K-i emeleti sarokpontja', '77');
INSERT INTO sv_survey_point VALUES (78, '211/1 hrsz-ú épület É-i emeleti sarokpontja', '78');
INSERT INTO sv_survey_point VALUES (79, '211/1 hrsz-ú épület NY-i emeleti sarokpontja', '79');
INSERT INTO sv_survey_point VALUES (80, '124 hrsz-ú épület É-i sarokpontja', '80');
INSERT INTO sv_survey_point VALUES (81, '124 hrsz-ú épület NY-i sarokpontja', '81');
INSERT INTO sv_survey_point VALUES (82, '124 hrsz-ú épület D-i sarokpontja', '82');
INSERT INTO sv_survey_point VALUES (83, '124 hrsz-ú épület K-i sarokpontja', '83');
INSERT INTO sv_survey_point VALUES (85, '124 hrsz-ú Belső épület É-i sarokpontja', '85');
INSERT INTO sv_survey_point VALUES (84, '124 hrsz-ú Belső épület NY-i sarokpontja', '84');
INSERT INTO sv_survey_point VALUES (87, '124 hrsz-ú Belső épület D-i sarokpontja', '87');
INSERT INTO sv_survey_point VALUES (86, '124 hrsz-ú Belső épület K-i sarokpontja', '86');
INSERT INTO sv_survey_point VALUES (88, '124 hrsz-ú épület É-i tető sarokpontja', '88');
INSERT INTO sv_survey_point VALUES (89, '124 hrsz-ú épület NY-i tető sarokpontja', '89');
INSERT INTO sv_survey_point VALUES (90, '124 hrsz-ú épület D-i tető sarokpontja', '90');
INSERT INTO sv_survey_point VALUES (91, '124 hrsz-ú épület K-i tető sarokpontja', '91');
INSERT INTO sv_survey_point VALUES (92, '124 hrsz-ú Beslő épület NY-i tető sarokpontja', '92');
INSERT INTO sv_survey_point VALUES (93, '124 hrsz-ú Beslő épület É-i tető sarokpontja', '93');
INSERT INTO sv_survey_point VALUES (94, '124 hrsz-ú Beslő épület K-i tető sarokpontja', '94');
INSERT INTO sv_survey_point VALUES (95, '124 hrsz-ú Beslő épület D-i tető sarokpontja', '95');


--
-- Data for Name: tp_face; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_face VALUES (26, '{60,56,55,58,59}', '0103000080010000000600000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E59408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940F6285C0FFEB2234185EB51B820D20B416666666666465940A4703D0A13B323413333333395D10B41C3F5285C8F42594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL, 'VETÜLET- PARCEL - 473/1');
INSERT INTO tp_face VALUES (25, '{59,61,64,62}', '01030000800100000005000000A4703D0A13B323413333333395D10B41C3F5285C8F425940EC51B89E50B32341333333333BD20B416666666666465940A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940713D0AD71FB323416666666646D10B41713D0AD7A3405940A4703D0A13B323413333333395D10B41C3F5285C8F425940', NULL, 'VETÜLET- PARCEL - 472/2');
INSERT INTO tp_face VALUES (24, '{60,59,62,63}', '0103000080010000000500000014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940A4703D0A13B323413333333395D10B41C3F5285C8F425940713D0AD71FB323416666666646D10B41713D0AD7A3405940CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB5138594014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL, 'VETÜLET- PARCEL - 472/1');
INSERT INTO tp_face VALUES (23, '{63,62,64,66,65}', '01030000800100000006000000CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940713D0AD71FB323416666666646D10B41713D0AD7A3405940A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940295C8F4273B323415C8FC2F556D10B41E17A14AE4701594033333333DBB223417B14AE47E5CF0B4114AE47E17A345940CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940', NULL, 'VETÜLET- PARCEL - 471');
INSERT INTO tp_face VALUES (22, '{40,41,39,38}', '01030000800100000005000000B81E856BD0B123419A99999987CF0B41F6285C8FC235594000000000BFB12341713D0AD7F9CF0B4100000000004059400000000010B22341713D0AD7BDD00B4148E17A14AE475940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940B81E856BD0B123419A99999987CF0B41F6285C8FC2355940', NULL, 'VETÜLET- PARCEL - 352/3');
INSERT INTO tp_face VALUES (21, '{36,51,38,39,37}', '010300008001000000060000000000000061B2234152B81E85EFD00B418FC2F5285C3F5940666666E64FB2234152B81E85C3D00B411F85EB51B83E5940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C59400000000010B22341713D0AD7BDD00B4148E17A14AE4759409A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C59400000000061B2234152B81E85EFD00B418FC2F5285C3F5940', NULL, 'VETÜLET- PARCEL - 352/4');
INSERT INTO tp_face VALUES (20, '{34,35,36,37}', '010300008001000000050000009A99991966B22341000000008ED10B411F85EB51B84E5940713D0AD776B223413333333321D10B4114AE47E17A4459400000000061B2234152B81E85EFD00B418FC2F5285C3F59409A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C59409A99991966B22341000000008ED10B411F85EB51B84E5940', NULL, 'VETÜLET- PARCEL - 352/5');
INSERT INTO tp_face VALUES (19, '{45,40,38,44}', '01030000800100000005000000C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940B81E856BD0B123419A99999987CF0B41F6285C8FC2355940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940', NULL, 'VETÜLET- PARCEL - 352/1');
INSERT INTO tp_face VALUES (17, '{48,45,44,43,47}', '01030000800100000006000000295C8F42FCB123419A9999996FCE0B410000000000305940C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940295C8F42FCB123419A9999996FCE0B410000000000305940', NULL, 'VETÜLET- PARCEL - 351/1');
INSERT INTO tp_face VALUES (16, '{47,43,52,42,46}', '01030000800100000006000000B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940E17A14AE61B22341295C8FC249D00B41295C8FC2F538594052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940333333B3A2B223418FC2F52804D00B411F85EB51B83E5940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940', NULL, 'VETÜLET- PARCEL - 351/2');
INSERT INTO tp_face VALUES (15, '{48,47,46,49,50}', '01030000800100000006000000295C8F42FCB123419A9999996FCE0B410000000000305940B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940333333B3A2B223418FC2F52804D00B411F85EB51B83E59401F85EBD1B3B223410AD7A37091CF0B417B14AE47E13A59405C8FC2750DB2234148E17A14F8CD0B415C8FC2F5282C5940295C8F42FCB123419A9999996FCE0B410000000000305940', NULL, 'VETÜLET- PARCEL - 350');
INSERT INTO tp_face VALUES (14, '{30,32,33,31}', '01030000800100000005000000F6285C8F32B22341EC51B81E2FD40B4185EB51B81E95594052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940', NULL, 'VETÜLET- PARCEL - 213');
INSERT INTO tp_face VALUES (13, '{26,30,31,28,27}', '01030000800100000006000000295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940', NULL, 'VETÜLET- PARCEL - 212');
INSERT INTO tp_face VALUES (12, '{29,27,28,24}', '0103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F59408FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL, 'VETÜLET- PARCEL - 211/2');
INSERT INTO tp_face VALUES (11, '{21,26,27,29,22}', '01030000800100000006000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A594066666666B0B223415C8FC2F5DCD30B41F6285C8FC26559400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'VETÜLET- PARCEL - 211/1');
INSERT INTO tp_face VALUES (10, '{23,22,29,24,25}', '01030000800100000006000000EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E59400AD7A3708CB22341B81E85EB83D30B41A4703D0AD763594066666666B0B223415C8FC2F5DCD30B41F6285C8FC26559408FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A5940EC51B81E0EB32341D7A3703DEAD30B4185EB51B81E655940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940', NULL, 'VETÜLET- PARCEL - 210/2');
INSERT INTO tp_face VALUES (9, '{20,21,22,23}', '01030000800100000005000000D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940', NULL, 'VETÜLET- PARCEL - 210/1');
INSERT INTO tp_face VALUES (8, '{16,19,18,17}', '01030000800100000005000000F6285C0F7BB1234148E17A14C2D10B4185EB51B81E6559403D0AD72359B12341CDCCCCCCA8D20B411F85EB51B87E594048E17A1489B12341333333331DD30B413333333333935940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940', NULL, 'VETÜLET- PARCEL - 126/3');
INSERT INTO tp_face VALUES (7, '{17,18,11,7}', '01030000800100000005000000C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B594048E17A1489B12341333333331DD30B41333333333393594048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A359403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940', NULL, 'VETÜLET- PARCEL - 126/2');
INSERT INTO tp_face VALUES (6, '{15,16,17,8,9}', '010300008001000000060000003333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B594014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE475159403333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940', NULL, 'VETÜLET- PARCEL - 125');
INSERT INTO tp_face VALUES (5, '{14,15,9,13,12}', '01030000800100000006000000295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB4159403333333394B12341A4703D0A19D10B41CDCCCCCCCC4C59401F85EBD1DDB1234152B81E85D1D10B41E17A14AE4751594085EB51B8E7B1234148E17A1488D10B41E17A14AE47515940CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB415940', NULL, 'VETÜLET- PARCEL - 121');
INSERT INTO tp_face VALUES (4, '{12,13,9,4,3,2}', '01030000800100000007000000CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C594085EB51B8E7B1234148E17A1488D10B41E17A14AE475159401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E5940713D0AD718B223415C8FC2F5F6D10B4148E17A14AE5759408FC2F52823B223415C8FC2F5B6D10B413333333333535940CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940', NULL, 'VETÜLET- PARCEL - 122');
INSERT INTO tp_face VALUES (3, '{7,11,10,6}', '010300008001000000050000003D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A3594000000080FDB123417B14AE4737D40B41D7A3703D0AA759409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940', NULL, 'VETÜLET- PARCEL - 126/1');
INSERT INTO tp_face VALUES (1, '{1,2,3,4,5}', '01030000800100000006000000AE47E1FA4FB22341F6285C8F1ED20B4166666666665659408FC2F52823B223415C8FC2F5B6D10B413333333333535940713D0AD718B223415C8FC2F5F6D10B4148E17A14AE575940666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE47615940AE47E1FA4FB22341F6285C8F1ED20B416666666666565940', NULL, 'VETÜLET- PARCEL - 123');
INSERT INTO tp_face VALUES (42, '{75,74,78,79}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Emelet É-i fala-211/1');
INSERT INTO tp_face VALUES (41, '{73,77,78,74}', '0103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Emelet K-i fala-211/1');
INSERT INTO tp_face VALUES (31, '{21,29,69,68}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594066666666B0B223415C8FC2F5DCD30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - D-i negyed');
INSERT INTO tp_face VALUES (29, '{55,54,67,57,58}', '010300008001000000060000008FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B5940E17A14AE22B32341666666665AD30B41B81E85EB515859401F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940F6285C0FFEB2234185EB51B820D20B4166666666664659408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940', NULL, 'VETÜLET- PARCEL - 474/2');
INSERT INTO tp_face VALUES (28, '{56,53,54,55}', '01030000800100000005000000EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E59400AD7A3F08BB2234152B81E85E9D10B41B81E85EB51485940CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B59408FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL, 'VETÜLET- PARCEL - 474/1');
INSERT INTO tp_face VALUES (27, '{58,57,61,59}', '01030000800100000005000000F6285C0FFEB2234185EB51B820D20B4166666666664659401F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940EC51B89E50B32341333333333BD20B416666666666465940A4703D0A13B323413333333395D10B41C3F5285C8F425940F6285C0FFEB2234185EB51B820D20B416666666666465940', NULL, 'VETÜLET- PARCEL - 473/2');
INSERT INTO tp_face VALUES (18, '{44,38,51,36,35,42,52,43}', '01030000800100000009000000B81E856B33B223411F85EB51DACF0B4148E17A14AE375940C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940666666E64FB2234152B81E85C3D00B411F85EB51B83E59400000000061B2234152B81E85EFD00B418FC2F5285C3F5940713D0AD776B223413333333321D10B4114AE47E17A44594052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940E17A14AE61B22341295C8FC249D00B41295C8FC2F5385940D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940B81E856B33B223411F85EB51DACF0B4148E17A14AE375940', NULL, 'VETÜLET- PARCEL - 352/2');
INSERT INTO tp_face VALUES (2, '{9,4,5,6,7,8}', '010300008001000000070000001F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE476159409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940', NULL, 'VETÜLET- PARCEL - 124');
INSERT INTO tp_face VALUES (32, '{29,27,70,69}', '0103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B417B14AE47E18A594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL, 'MODEL- PARCEL - NY-i negyed');
INSERT INTO tp_face VALUES (33, '{71,70,27,26}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A8759400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A875940', NULL, 'MODEL- PARCEL - É-i negyed');
INSERT INTO tp_face VALUES (39, '{75,72,73,74}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Ház felső lapja-211/1');
INSERT INTO tp_face VALUES (30, '{21,68,71,26}', '01030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940B81E856B58B223419A999999CDD30B41D7A3703D0A875940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - K-i negyed');
INSERT INTO tp_face VALUES (37, '{75,74,70,71}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Ház É-i fala-211/1');
INSERT INTO tp_face VALUES (38, '{72,75,71,68}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Ház NY-i fala-211/1');
INSERT INTO tp_face VALUES (36, '{69,70,74,73}', '0103000080010000000500000048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41F6285C8FC2655940', NULL, 'MODEL- BUILDING - Ház K-i fala-211/1');
INSERT INTO tp_face VALUES (35, '{72,68,69,73}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Ház D-i fala-211/1');
INSERT INTO tp_face VALUES (44, '{72,73,74,75}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Emelet teteje-211/1');
INSERT INTO tp_face VALUES (47, '{77,69,70,78}', '0103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - földszint K-i fala-211/1');
INSERT INTO tp_face VALUES (48, '{79,78,70,71}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint É-i fala-211/1');
INSERT INTO tp_face VALUES (34, '{68,71,70,69}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B4152B81E85EB615940B81E856B58B223419A999999CDD30B41D7A3703D0A8759400AD7A3706BB2234100000000FCD30B417B14AE47E18A594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940', NULL, 'MODEL- PARCEL - Ház alja');
INSERT INTO tp_face VALUES (51, '{71,68,69,70}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940', NULL, 'MODELL - PARCELLA - 211/1');
INSERT INTO tp_face VALUES (61, '{95,92,84,87}', '01030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház K-i fala-124');
INSERT INTO tp_face VALUES (43, '{72,75,79,76}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40', NULL, 'MODEL- BUILDING - Emelet NY-i fala-211/1');
INSERT INTO tp_face VALUES (40, '{76,77,73,72}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Emelet D-i fala-211/1');
INSERT INTO tp_face VALUES (45, '{76,79,78,77}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Emelet alja-211/1');
INSERT INTO tp_face VALUES (46, '{76,68,69,77}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint D-i fala-211/1');
INSERT INTO tp_face VALUES (49, '{76,79,71,68}', '010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint NY-i fala-211/1');
INSERT INTO tp_face VALUES (50, '{79,76,77,78}', '01030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL, 'MODEL- BUILDING - Földszint teteje-211/1');
INSERT INTO tp_face VALUES (53, '{88,91,83,80}', '01030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A99999999795940295C8F4219B223410AD7A37015D30B413333333333335A40', NULL, 'MODEL- BUILDING - Ház K-i fala-124');
INSERT INTO tp_face VALUES (55, '{89,88,80,81}', '010300008001000000050000000AD7A3F007B223411F85EB51ECD20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A999999997959400AD7A3F007B223411F85EB51ECD20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház É-i fala-124');
INSERT INTO tp_face VALUES (56, '{88,89,90,91}', '01030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40', NULL, 'MODEL- BUILDING - Ház teteje-124');
INSERT INTO tp_face VALUES (58, '{86,94,95,87}', '0103000080010000000500000014AE4761F3B12341295C8FC279D20B41000000000060594014AE4761F3B12341295C8FC279D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B410000000000605940', NULL, 'MODEL- BUILDING - Belső Ház D-i fala-124');
INSERT INTO tp_face VALUES (59, '{85,93,94,86}', '0103000080010000000500000085EB51B8ECB12341D7A3703DAAD20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B410000000000605940', NULL, 'MODEL- BUILDING - Belső Ház K-i fala-124');
INSERT INTO tp_face VALUES (60, '{92,93,85,84}', '0103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház É-i fala-124');
INSERT INTO tp_face VALUES (63, '{84,85,86,87}', '0103000080010000000500000052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333535940', NULL, 'MODEL- BUILDING - Belső Ház alső födém-124');
INSERT INTO tp_face VALUES (62, '{95,94,93,92}', '01030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL, 'MODEL- BUILDING - Belső Ház tető fala-124');
INSERT INTO tp_face VALUES (52, '{90,82,83,91}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A40F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B4166666666667659401F85EB5129B223417B14AE47B1D20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház D-i fala-124');
INSERT INTO tp_face VALUES (54, '{90,89,81,82}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A400AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B413333333333735940F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL, 'MODEL- BUILDING - Ház É-i fala-124');
INSERT INTO tp_face VALUES (57, '{82,81,80,83}', '01030000800100000005000000F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940', NULL, 'MODEL- BUILDING - Ház alsó födém-124');


--
-- Data for Name: tp_node; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_node VALUES (65, '010100008033333333DBB223417B14AE47E5CF0B4114AE47E17A345940', NULL);
INSERT INTO tp_node VALUES (66, '0101000080295C8F4273B323415C8FC2F556D10B41E17A14AE47015940', NULL);
INSERT INTO tp_node VALUES (67, '0101000080E17A14AE22B32341666666665AD30B41B81E85EB51585940', NULL);
INSERT INTO tp_node VALUES (81, '01010000800AD7A3F007B223411F85EB51ECD20B419A99999999795940', NULL);
INSERT INTO tp_node VALUES (57, '01010000801F85EB513DB32341713D0AD7B5D20B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (75, '0101000080B81E856B58B223419A999999CDD30B41D7A3703D0A075B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (54, '0101000080CDCCCCCCBFB22341AE47E17A60D20B41EC51B81E854B5940', NULL);
INSERT INTO tp_node VALUES (1, '0101000080AE47E1FA4FB22341F6285C8F1ED20B416666666666565940', NULL);
INSERT INTO tp_node VALUES (2, '01010000808FC2F52823B223415C8FC2F5B6D10B413333333333535940', NULL);
INSERT INTO tp_node VALUES (3, '0101000080713D0AD718B223415C8FC2F5F6D10B4148E17A14AE575940', NULL);
INSERT INTO tp_node VALUES (4, '0101000080666666E60CB2234148E17A1442D20B41AE47E17A145E5940', NULL);
INSERT INTO tp_node VALUES (5, '0101000080295C8F423AB2234152B81E85ADD20B41E17A14AE47615940', NULL);
INSERT INTO tp_node VALUES (6, '01010000809A99999920B22341713D0AD751D30B410000000000805940', NULL);
INSERT INTO tp_node VALUES (7, '01010000803D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C5940', NULL);
INSERT INTO tp_node VALUES (8, '010100008014AE4761C6B123419A99999977D20B410000000000705940', NULL);
INSERT INTO tp_node VALUES (9, '01010000801F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940', NULL);
INSERT INTO tp_node VALUES (10, '010100008000000080FDB123417B14AE4737D40B41D7A3703D0AA75940', NULL);
INSERT INTO tp_node VALUES (11, '010100008048E17A94C1B1234185EB51B8A2D30B41A4703D0AD7A35940', NULL);
INSERT INTO tp_node VALUES (12, '0101000080CDCCCCCCF1B123415C8FC2F53ED10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (13, '010100008085EB51B8E7B1234148E17A1488D10B41E17A14AE47515940', NULL);
INSERT INTO tp_node VALUES (14, '0101000080295C8FC2A8B12341EC51B81E8DD00B4152B81E85EB415940', NULL);
INSERT INTO tp_node VALUES (15, '01010000803333333394B12341A4703D0A19D10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (16, '0101000080F6285C0F7BB1234148E17A14C2D10B4185EB51B81E655940', NULL);
INSERT INTO tp_node VALUES (17, '0101000080C3F528DCABB12341E17A14AE2FD20B41EC51B81E856B5940', NULL);
INSERT INTO tp_node VALUES (18, '010100008048E17A1489B12341333333331DD30B413333333333935940', NULL);
INSERT INTO tp_node VALUES (19, '01010000803D0AD72359B12341CDCCCCCCA8D20B411F85EB51B87E5940', NULL);
INSERT INTO tp_node VALUES (20, '0101000080D7A370BD75B22341713D0AD779D20B41CDCCCCCCCC5C5940', NULL);
INSERT INTO tp_node VALUES (21, '0101000080CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB615940', NULL);
INSERT INTO tp_node VALUES (22, '01010000800AD7A3708CB22341B81E85EB83D30B41A4703D0AD7635940', NULL);
INSERT INTO tp_node VALUES (23, '0101000080EC51B81EA3B223410AD7A370E9D20B411F85EB51B85E5940', NULL);
INSERT INTO tp_node VALUES (24, '01010000808FC2F528F9B22341AE47E17A7AD40B410AD7A3703D6A5940', NULL);
INSERT INTO tp_node VALUES (25, '0101000080EC51B81E0EB32341D7A3703DEAD30B4185EB51B81E655940', NULL);
INSERT INTO tp_node VALUES (26, '0101000080295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940', NULL);
INSERT INTO tp_node VALUES (27, '0101000080C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940', NULL);
INSERT INTO tp_node VALUES (28, '0101000080EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940', NULL);
INSERT INTO tp_node VALUES (29, '010100008066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940', NULL);
INSERT INTO tp_node VALUES (30, '0101000080F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940', NULL);
INSERT INTO tp_node VALUES (31, '0101000080C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940', NULL);
INSERT INTO tp_node VALUES (32, '010100008052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940', NULL);
INSERT INTO tp_node VALUES (33, '0101000080CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940', NULL);
INSERT INTO tp_node VALUES (34, '01010000809A99991966B22341000000008ED10B411F85EB51B84E5940', NULL);
INSERT INTO tp_node VALUES (35, '0101000080713D0AD776B223413333333321D10B4114AE47E17A445940', NULL);
INSERT INTO tp_node VALUES (36, '01010000800000000061B2234152B81E85EFD00B418FC2F5285C3F5940', NULL);
INSERT INTO tp_node VALUES (37, '01010000809A99999951B22341D7A3703D5CD10B41CDCCCCCCCC4C5940', NULL);
INSERT INTO tp_node VALUES (38, '0101000080C3F5285C22B223410AD7A3704DD00B41CDCCCCCCCC3C5940', NULL);
INSERT INTO tp_node VALUES (39, '01010000800000000010B22341713D0AD7BDD00B4148E17A14AE475940', NULL);
INSERT INTO tp_node VALUES (40, '0101000080B81E856BD0B123419A99999987CF0B41F6285C8FC2355940', NULL);
INSERT INTO tp_node VALUES (41, '010100008000000000BFB12341713D0AD7F9CF0B410000000000405940', NULL);
INSERT INTO tp_node VALUES (42, '010100008052B81E0589B223418FC2F528AAD00B418FC2F5285C3F5940', NULL);
INSERT INTO tp_node VALUES (43, '0101000080D7A370BD43B22341D7A3703D00D00B41B81E85EB51385940', NULL);
INSERT INTO tp_node VALUES (44, '0101000080B81E856B33B223411F85EB51DACF0B4148E17A14AE375940', NULL);
INSERT INTO tp_node VALUES (45, '0101000080C3F528DCE1B12341B81E85EB15CF0B41713D0AD7A3305940', NULL);
INSERT INTO tp_node VALUES (46, '0101000080333333B3A2B223418FC2F52804D00B411F85EB51B83E5940', NULL);
INSERT INTO tp_node VALUES (47, '0101000080B81E856B5DB22341A4703D0A55CF0B4148E17A14AE375940', NULL);
INSERT INTO tp_node VALUES (48, '0101000080295C8F42FCB123419A9999996FCE0B410000000000305940', NULL);
INSERT INTO tp_node VALUES (49, '01010000801F85EBD1B3B223410AD7A37091CF0B417B14AE47E13A5940', NULL);
INSERT INTO tp_node VALUES (50, '01010000805C8FC2750DB2234148E17A14F8CD0B415C8FC2F5282C5940', NULL);
INSERT INTO tp_node VALUES (51, '0101000080666666E64FB2234152B81E85C3D00B411F85EB51B83E5940', NULL);
INSERT INTO tp_node VALUES (52, '0101000080E17A14AE61B22341295C8FC249D00B41295C8FC2F5385940', NULL);
INSERT INTO tp_node VALUES (53, '01010000800AD7A3F08BB2234152B81E85E9D10B41B81E85EB51485940', NULL);
INSERT INTO tp_node VALUES (55, '01010000808FC2F528D6B2234185EB51B8C2D10B4152B81E85EB415940', NULL);
INSERT INTO tp_node VALUES (56, '0101000080EC51B89EA4B22341CDCCCCCC46D10B41AE47E17A143E5940', NULL);
INSERT INTO tp_node VALUES (58, '0101000080F6285C0FFEB2234185EB51B820D20B416666666666465940', NULL);
INSERT INTO tp_node VALUES (59, '0101000080A4703D0A13B323413333333395D10B41C3F5285C8F425940', NULL);
INSERT INTO tp_node VALUES (60, '010100008014AE4761B9B22341AE47E17AC0D00B410AD7A3703D3A5940', NULL);
INSERT INTO tp_node VALUES (61, '0101000080EC51B89E50B32341333333333BD20B416666666666465940', NULL);
INSERT INTO tp_node VALUES (62, '0101000080713D0AD71FB323416666666646D10B41713D0AD7A3405940', NULL);
INSERT INTO tp_node VALUES (63, '0101000080CDCCCCCCC5B22341E17A14AE71D00B41B81E85EB51385940', NULL);
INSERT INTO tp_node VALUES (64, '0101000080A4703D0A60B323418FC2F528E2D10B4114AE47E17A445940', NULL);
INSERT INTO tp_node VALUES (83, '01010000801F85EB5129B223417B14AE47B1D20B416666666666765940', NULL);
INSERT INTO tp_node VALUES (84, '010100008052B81E05DEB1234114AE47E18AD20B413333333333535940', NULL);
INSERT INTO tp_node VALUES (85, '010100008085EB51B8ECB12341D7A3703DAAD20B410000000000605940', NULL);
INSERT INTO tp_node VALUES (71, '0101000080B81E856B58B223419A999999CDD30B41D7A3703D0A875940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (70, '01010000800AD7A3706BB2234100000000FCD30B417B14AE47E18A5940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (69, '010100008048E17A9479B22341F6285C8FA0D30B41F6285C8FC2655940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (68, '01010000801F85EB5166B22341EC51B81E73D30B4152B81E85EB615940', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (74, '01010000800AD7A3706BB2234100000000FCD30B41D7A3703D0A075B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (72, '01010000801F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (86, '010100008014AE4761F3B12341295C8FC279D20B410000000000605940', NULL);
INSERT INTO tp_node VALUES (73, '010100008048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B40', 'BUILDING - 211/1');
INSERT INTO tp_node VALUES (77, '010100008048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (78, '01010000800AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (79, '0101000080B81E856B58B223419A999999CDD30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (87, '0101000080A4703D0AE5B12341CDCCCCCC58D20B413333333333535940', NULL);
INSERT INTO tp_node VALUES (76, '01010000801F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40', NULL);
INSERT INTO tp_node VALUES (80, '0101000080295C8F4219B223410AD7A37015D30B419A99999999795940', NULL);
INSERT INTO tp_node VALUES (88, '0101000080295C8F4219B223410AD7A37015D30B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (89, '01010000800AD7A3F007B223411F85EB51ECD20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (91, '01010000801F85EB5129B223417B14AE47B1D20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (92, '010100008052B81E05DEB1234114AE47E18AD20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (94, '010100008014AE4761F3B12341295C8FC279D20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (90, '0101000080F6285C8F17B223417B14AE4787D20B413333333333335A40', NULL);
INSERT INTO tp_node VALUES (93, '010100008085EB51B8ECB12341D7A3703DAAD20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (95, '0101000080A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40', NULL);
INSERT INTO tp_node VALUES (82, '0101000080F6285C8F17B223417B14AE4787D20B413333333333735940', NULL);


--
-- Data for Name: tp_volume; Type: TABLE DATA; Schema: main; Owner: tdc
--

INSERT INTO tp_volume VALUES (14, '{14}', 'PARCELL - 213 hrsz', '010F0000800100000001030000800100000005000000F6285C8F32B22341EC51B81E2FD40B4185EB51B81E95594052B81E0524B223418FC2F52888D40B41CDCCCCCCCCAC5940CDCCCCCCBFB22341A4703D0A0BD60B4185EB51B81EB55940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940');
INSERT INTO tp_volume VALUES (13, '{13}', 'PARCELL - 212 hrsz', '010F0000800100000001030000800100000006000000295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940F6285C8F32B22341EC51B81E2FD40B4185EB51B81E955940C3F5285CCEB22341295C8FC2A7D50B413D0AD7A3709D5940EC51B89EDEB223417B14AE474BD50B418FC2F5285C8F5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940');
INSERT INTO tp_volume VALUES (11, '{30,31,32,33,51}', 'PARCELL - 211/1 hrsz', '010F0000800500000001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940B81E856B58B223419A999999CDD30B41D7A3703D0A875940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594001030000800100000005000000CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB61594066666666B0B223415C8FC2F5DCD30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940CDCCCCCC5DB22341C3F5285C19D30B4152B81E85EB6159400103000080010000000500000066666666B0B223415C8FC2F5DCD30B41F6285C8FC2655940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B417B14AE47E18A594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594066666666B0B223415C8FC2F5DCD30B41F6285C8FC265594001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A8759400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940C3F528DC95B2234185EB51B89CD40B417B14AE47E18A5940295C8FC241B22341CDCCCCCCCED30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A87594001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940');
INSERT INTO tp_volume VALUES (40, '{35,36,37,38,39}', 'BUILDING - 211/1 hrsz-on', '010F00008005000000010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B400103000080010000000500000048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A075B40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40');
INSERT INTO tp_volume VALUES (41, '{40,41,42,43,44,45}', 'BUILDING - EMELET - 211/1 hrsz', '010F00008006000000010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A400103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A075B400AD7A3706BB2234100000000FCD30B41D7A3703D0A075B40B81E856B58B223419A999999CDD30B41D7A3703D0A075B401F85EB5166B22341EC51B81E73D30B41D7A3703D0A075B40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40');
INSERT INTO tp_volume VALUES (42, '{46,47,48,49,50,34}', 'BUILDING - FÖLDSZINT - 211/1 hrsz', '010F00008006000000010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B4152B81E85EB61594048E17A9479B22341F6285C8FA0D30B41F6285C8FC265594048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A400103000080010000000500000048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559400AD7A3706BB2234100000000FCD30B417B14AE47E18A59400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B417B14AE47E18A5940B81E856B58B223419A999999CDD30B41D7A3703D0A875940B81E856B58B223419A999999CDD30B41D7A3703D0A475A40010300008001000000050000001F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A8759401F85EB5166B22341EC51B81E73D30B4152B81E85EB6159401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4001030000800100000005000000B81E856B58B223419A999999CDD30B41D7A3703D0A475A401F85EB5166B22341EC51B81E73D30B41D7A3703D0A475A4048E17A9479B22341F6285C8FA0D30B41D7A3703D0A475A400AD7A3706BB2234100000000FCD30B41D7A3703D0A475A40B81E856B58B223419A999999CDD30B41D7A3703D0A475A40010300008001000000050000001F85EB5166B22341EC51B81E73D30B4152B81E85EB615940B81E856B58B223419A999999CDD30B41D7A3703D0A8759400AD7A3706BB2234100000000FCD30B417B14AE47E18A594048E17A9479B22341F6285C8FA0D30B41F6285C8FC26559401F85EB5166B22341EC51B81E73D30B4152B81E85EB615940');
INSERT INTO tp_volume VALUES (2, '{2}', 'PARCELL - 124 hrsz', '010F00008001000000010300008001000000070000001F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940666666E60CB2234148E17A1442D20B41AE47E17A145E5940295C8F423AB2234152B81E85ADD20B41E17A14AE476159409A99999920B22341713D0AD751D30B4100000000008059403D0AD7A3E2B123413D0AD7A3B8D20B41CDCCCCCCCC7C594014AE4761C6B123419A99999977D20B4100000000007059401F85EBD1DDB1234152B81E85D1D10B41E17A14AE47515940');
INSERT INTO tp_volume VALUES (44, '{58,59,60,61,62,63}', 'BUILDING - 124 hrsz-on Beső épület', '010F000080060000000103000080010000000500000014AE4761F3B12341295C8FC279D20B41000000000060594014AE4761F3B12341295C8FC279D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B41333333333353594014AE4761F3B12341295C8FC279D20B4100000000006059400103000080010000000500000085EB51B8ECB12341D7A3703DAAD20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4014AE4761F3B12341295C8FC279D20B41000000000060594085EB51B8ECB12341D7A3703DAAD20B4100000000006059400103000080010000000500000052B81E05DEB1234114AE47E18AD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B41000000000060594052B81E05DEB1234114AE47E18AD20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333135A4001030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333535940A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4001030000800100000005000000A4703D0AE5B12341CDCCCCCC58D20B413333333333135A4014AE4761F3B12341295C8FC279D20B413333333333135A4085EB51B8ECB12341D7A3703DAAD20B413333333333135A4052B81E05DEB1234114AE47E18AD20B413333333333135A40A4703D0AE5B12341CDCCCCCC58D20B413333333333135A400103000080010000000500000052B81E05DEB1234114AE47E18AD20B41333333333353594085EB51B8ECB12341D7A3703DAAD20B41000000000060594014AE4761F3B12341295C8FC279D20B410000000000605940A4703D0AE5B12341CDCCCCCC58D20B41333333333353594052B81E05DEB1234114AE47E18AD20B413333333333535940');
INSERT INTO tp_volume VALUES (43, '{52,53,55,54,56,57}', 'BUILDING - 124 hrsz-on Külső épület', '010F0000800600000001030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A40F6285C8F17B223417B14AE4787D20B4133333333337359401F85EB5129B223417B14AE47B1D20B4166666666667659401F85EB5129B223417B14AE47B1D20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A4001030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A401F85EB5129B223417B14AE47B1D20B416666666666765940295C8F4219B223410AD7A37015D30B419A99999999795940295C8F4219B223410AD7A37015D30B413333333333335A40010300008001000000050000000AD7A3F007B223411F85EB51ECD20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A40295C8F4219B223410AD7A37015D30B419A999999997959400AD7A3F007B223411F85EB51ECD20B419A999999997959400AD7A3F007B223411F85EB51ECD20B413333333333335A4001030000800100000005000000F6285C8F17B223417B14AE4787D20B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A400AD7A3F007B223411F85EB51ECD20B419A99999999795940F6285C8F17B223417B14AE4787D20B413333333333735940F6285C8F17B223417B14AE4787D20B413333333333335A4001030000800100000005000000295C8F4219B223410AD7A37015D30B413333333333335A400AD7A3F007B223411F85EB51ECD20B413333333333335A40F6285C8F17B223417B14AE4787D20B413333333333335A401F85EB5129B223417B14AE47B1D20B413333333333335A40295C8F4219B223410AD7A37015D30B413333333333335A4001030000800100000005000000F6285C8F17B223417B14AE4787D20B4133333333337359400AD7A3F007B223411F85EB51ECD20B419A99999999795940295C8F4219B223410AD7A37015D30B419A999999997959401F85EB5129B223417B14AE47B1D20B416666666666765940F6285C8F17B223417B14AE4787D20B413333333333735940');


--
-- Name: Tableim_building_individual_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT "Tableim_building_individual_unit_level_pkey" PRIMARY KEY (im_building, hrsz_unit, im_levels);


--
-- Name: im_building_individual_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_building_individual_unit_unique_im_building_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_unique_im_building_hrsz_unit UNIQUE (im_building, hrsz_unit);


--
-- Name: im_building_level_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_pkey PRIMARY KEY (im_building, im_levels);


--
-- Name: im_building_levels_fkey_im_building_im_levels; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_building_im_levels PRIMARY KEY (im_building, im_levels);


--
-- Name: im_building_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_pkey PRIMARY KEY (nid);


--
-- Name: im_building_shared_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_pkey PRIMARY KEY (im_building, name);


--
-- Name: im_building_unique_im_settlement_hrsz_main_hrsz_fraction; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_im_settlement_hrsz_main_hrsz_fraction UNIQUE (im_settlement, hrsz_main, hrsz_fraction);


--
-- Name: im_building_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_model UNIQUE (model);


--
-- Name: im_building_unique_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_building
    ADD CONSTRAINT im_building_unique_projection UNIQUE (projection);


--
-- Name: im_levels_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_levels
    ADD CONSTRAINT im_levels_pkey PRIMARY KEY (nid);


--
-- Name: im_levels_unique_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_levels
    ADD CONSTRAINT im_levels_unique_name UNIQUE (name);


--
-- Name: im_parcel_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_pkey PRIMARY KEY (nid);


--
-- Name: im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_hrsz_settlement_hrsz_main_hrsz_partial UNIQUE (im_settlement, hrsz_main, hrsz_fraction);


--
-- Name: im_parcel_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_model UNIQUE (model);


--
-- Name: im_parcel_unique_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_unique_projection UNIQUE (projection);


--
-- Name: im_settlement_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_settlement
    ADD CONSTRAINT im_settlement_pkey PRIMARY KEY (name);


--
-- Name: im_shared_unit_level_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_pkey PRIMARY KEY (im_building, im_levels, shared_unit_name);


--
-- Name: im_underpass_individual_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_unique_im_underpass_unit_hrsz_unit UNIQUE (im_underpass_block, hrsz_unit);


--
-- Name: im_underpass_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_shared_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_pkey PRIMARY KEY (im_underpass_block);


--
-- Name: im_underpass_shared_unit_unique_im_underpass_unit_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_unique_im_underpass_unit_name UNIQUE (im_underpass_block, name);


--
-- Name: im_underpass_unigue_projection; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unigue_projection UNIQUE (projection);


--
-- Name: im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_hrsz_settlement_hrsz_main_hrsz_parcial UNIQUE (hrsz_settlement, hrsz_main, hrsz_parcial);


--
-- Name: im_underpass_unique_model; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_unique_model UNIQUE (model);


--
-- Name: im_underpass_unit_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_pkey PRIMARY KEY (nid);


--
-- Name: im_underpass_unit_unique_im_underpass_hrsz_eoi; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_unique_im_underpass_hrsz_eoi UNIQUE (im_underpass, hrsz_eoi);


--
-- Name: pn_person_name_key; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_name_key UNIQUE (name);


--
-- Name: pn_person_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY pn_person
    ADD CONSTRAINT pn_person_pkey PRIMARY KEY (nid);


--
-- Name: rt_legal_document_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_legal_document
    ADD CONSTRAINT rt_legal_document_pkey PRIMARY KEY (nid);


--
-- Name: rt_type_pkey_nid; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_pkey_nid PRIMARY KEY (nid);


--
-- Name: rt_type_unique_name; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY rt_type
    ADD CONSTRAINT rt_type_unique_name UNIQUE (name);


--
-- Name: sv_point_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_pkey PRIMARY KEY (nid);


--
-- Name: sv_point_unique_sv_survey_point_sv_survey_document; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_unique_sv_survey_point_sv_survey_document UNIQUE (sv_survey_point, sv_survey_document);


--
-- Name: sv_survey_document_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_document
    ADD CONSTRAINT sv_survey_document_pkey PRIMARY KEY (nid);


--
-- Name: sv_survey_point_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY sv_survey_point
    ADD CONSTRAINT sv_survey_point_pkey PRIMARY KEY (nid);


--
-- Name: tp_face_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_unique_nodelist; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_face
    ADD CONSTRAINT tp_face_unique_nodelist UNIQUE (nodelist);


--
-- Name: tp_node_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_pkey PRIMARY KEY (gid);


--
-- Name: tp_volume_facelist_key; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_facelist_key UNIQUE (facelist);


--
-- Name: tp_volume_pkey; Type: CONSTRAINT; Schema: main; Owner: tdc; Tablespace: 
--

ALTER TABLE ONLY tp_volume
    ADD CONSTRAINT tp_volume_pkey PRIMARY KEY (gid);


--
-- Name: tp_face_idx_holelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_idx_holelist ON tp_face USING gin (holelist);


--
-- Name: tp_face_idx_nodelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_face_idx_nodelist ON tp_face USING gin (nodelist);


--
-- Name: tp_volume_idx_facelist; Type: INDEX; Schema: main; Owner: tdc; Tablespace: 
--

CREATE INDEX tp_volume_idx_facelist ON tp_volume USING gin (facelist);


--
-- Name: sv_point_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER sv_point_after_trigger AFTER INSERT OR DELETE OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_after();


--
-- Name: sv_point_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER sv_point_before_trigger BEFORE INSERT OR UPDATE ON sv_point FOR EACH ROW EXECUTE PROCEDURE sv_point_before();


--
-- Name: tp_face_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_face_after_trigger AFTER INSERT OR DELETE OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_after();


--
-- Name: tp_face_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_face_before_trigger BEFORE INSERT OR UPDATE ON tp_face FOR EACH ROW EXECUTE PROCEDURE tp_face_before();


--
-- Name: tp_node_after_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_node_after_trigger BEFORE INSERT OR DELETE OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_after();


--
-- Name: tp_node_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_node_before_trigger BEFORE INSERT OR UPDATE ON tp_node FOR EACH ROW EXECUTE PROCEDURE tp_node_before();


--
-- Name: tp_volume_before_trigger; Type: TRIGGER; Schema: main; Owner: tdc
--

CREATE TRIGGER tp_volume_before_trigger BEFORE INSERT OR UPDATE ON tp_volume FOR EACH ROW EXECUTE PROCEDURE tp_volume_before();


--
-- Name: Tableim_building_individual_unit_level_fkey_im_levles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT "Tableim_building_individual_unit_level_fkey_im_levles" FOREIGN KEY (im_levels) REFERENCES im_levels(nid);


--
-- Name: Tableim_building_level_unit_fkey_im_building_im_levels; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT "Tableim_building_level_unit_fkey_im_building_im_levels" FOREIGN KEY (im_building, im_levels) REFERENCES im_building_levels(im_building, im_levels);


--
-- Name: im_building_individual_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit
    ADD CONSTRAINT im_building_individual_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_individual_unit_level_fkey_projection; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_building_individual_unit_level_fkey_projection FOREIGN KEY (projection) REFERENCES tp_face(gid);


--
-- Name: im_building_level_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_level_unit_fkey_model; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_level_unit
    ADD CONSTRAINT im_building_level_unit_fkey_model FOREIGN KEY (model) REFERENCES tp_volume(gid);


--
-- Name: im_building_levels_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levels_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_building_levles_fkey_im_levles; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_levels
    ADD CONSTRAINT im_building_levles_fkey_im_levles FOREIGN KEY (im_levels) REFERENCES im_levels(nid);


--
-- Name: im_building_shared_unit_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_shared_unit
    ADD CONSTRAINT im_building_shared_unit_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: im_individual_unit_level_fkey_im_building_hrsz_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_building_individual_unit_level
    ADD CONSTRAINT im_individual_unit_level_fkey_im_building_hrsz_unit FOREIGN KEY (im_building, hrsz_unit) REFERENCES im_building_individual_unit(im_building, hrsz_unit);


--
-- Name: im_parcel_fkey_settlement; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_parcel
    ADD CONSTRAINT im_parcel_fkey_settlement FOREIGN KEY (im_settlement) REFERENCES im_settlement(name);


--
-- Name: im_shared_unit_level_fkey_im_building_name; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_shared_unit_level
    ADD CONSTRAINT im_shared_unit_level_fkey_im_building_name FOREIGN KEY (im_building, shared_unit_name) REFERENCES im_building_shared_unit(im_building, name);


--
-- Name: im_underpass_fkey_settlement; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass
    ADD CONSTRAINT im_underpass_fkey_settlement FOREIGN KEY (hrsz_settlement) REFERENCES im_settlement(name);


--
-- Name: im_underpass_individual_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_individual_unit
    ADD CONSTRAINT im_underpass_individual_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_shared_unit_fkey_im_underpass_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_shared_unit
    ADD CONSTRAINT im_underpass_shared_unit_fkey_im_underpass_unit FOREIGN KEY (im_underpass_block) REFERENCES im_underpass_block(nid);


--
-- Name: im_underpass_unit_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY im_underpass_block
    ADD CONSTRAINT im_underpass_unit_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_building; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building FOREIGN KEY (im_building) REFERENCES im_building(nid);


--
-- Name: rt_right_fkey_im_building_individual_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_building_individual_unit FOREIGN KEY (im_building_individual_unit) REFERENCES im_building_individual_unit(nid);


--
-- Name: rt_right_fkey_im_parcel; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_parcel FOREIGN KEY (im_parcel) REFERENCES im_parcel(nid);


--
-- Name: rt_right_fkey_im_underpass; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass FOREIGN KEY (im_underpass) REFERENCES im_underpass(nid);


--
-- Name: rt_right_fkey_im_underpass_individual_unit; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_im_underpass_individual_unit FOREIGN KEY (im_underpass_individual_unit) REFERENCES im_underpass_individual_unit(nid);


--
-- Name: rt_right_fkey_pn_person; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_pn_person FOREIGN KEY (pn_person) REFERENCES pn_person(nid);


--
-- Name: rt_right_fkey_rt_legal_document; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_legal_document FOREIGN KEY (rt_legal_document) REFERENCES rt_legal_document(nid);


--
-- Name: rt_right_fkey_rt_type; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY rt_right
    ADD CONSTRAINT rt_right_fkey_rt_type FOREIGN KEY (rt_type) REFERENCES rt_type(nid);


--
-- Name: sv_point_fkey_sv_survey_document; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_document FOREIGN KEY (sv_survey_document) REFERENCES sv_survey_document(nid);


--
-- Name: sv_point_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY sv_point
    ADD CONSTRAINT sv_point_fkey_sv_survey_point FOREIGN KEY (sv_survey_point) REFERENCES sv_survey_point(nid);


--
-- Name: tp_node_fkey_sv_survey_point; Type: FK CONSTRAINT; Schema: main; Owner: tdc
--

ALTER TABLE ONLY tp_node
    ADD CONSTRAINT tp_node_fkey_sv_survey_point FOREIGN KEY (gid) REFERENCES sv_survey_point(nid);


--
-- PostgreSQL database dump complete
--

