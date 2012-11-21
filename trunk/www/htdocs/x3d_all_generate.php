<?php

@trigger_error("");

	//
	//  Változók
	//
	$parcel_normal_color = "<Material transparency='0.1' diffuseColor='0.0 0.4 0.0' emissiveColor='0.0 0.4 0.0'/>";
	$parcel_normal_color = "<Material transparency='0.1' diffuseColor='0.0 0.6 0.0' emissiveColor='0.0 0.6 0.1'/>";

	$parcel_street_normal_color = "<Material transparency='0.1' diffuseColor='0.4 0.4 0.4' emissiveColor='0.4 0.4 0.4'/>";
	$parcel_street_normal_color = "<Material transparency='0.1' diffuseColor='0.6 0.6 0.6' emissiveColor='0.6 0.6 0.6'/>";

	$building_normal_color =  "<Material transparency='0.6' diffuseColor='0.0 0.2 0.6' emissiveColor='0.0 0.2 0.6'/>";
	$building_selected_color = "<Material transparency='0.6' diffuseColor='0.1 0.4 0.6' emissiveColor='0.1 0.4 0.6'/>";

	$building_individual_unit_normal_color = " <Material transparency='0' diffuseColor='0.2 0 0' emissiveColor='0.4 0 0'/>";
	$building_individual_unit_selected_color = " <Material transparency='0' diffuseColor='0.4 0 0' emissiveColor='0.8 0 0'/>";

	$building_shared_unit_normal_color = "<Material  diffuseColor='0.2 0.4 0.3' emissiveColor='0.2 0.4 0.3'/>";
	$building_shared_unit_selected_color = "<Material diffuseColor='0.4 0.8 0.6' emissiveColor='0.4 0.8 0.6'/>";

	$point_normal_color = "<Material diffuseColor='1.0 1.0 0.0' emissiveColor='1.0 1.0 0.0'/>";
	$point_selected_color = "<Material diffuseColor='2.0 2.0 0.0' emissiveColor='2.0 2.0 0.0'/>";

	$point_text_normal_color = "<Material diffuseColor='1.0 1.0 1.0' emissiveColor='1.0 1.0 1.0'/>";

	$underpass_normal_color =  "<Material transparency='0.6' diffuseColor='0.4 0.6 1.0' emissiveColor='0.4 0.6 1.0'/>";
	$underpass_selected_color = "<Material transparency='0.6' diffuseColor='0.5 0.5 0.0' emissiveColor='0.5 0.5 0.0'/>";

	$underpass_individual_unit_normal_color =  "<Material transparency='0' diffuseColor='0.1 0.2 0.8' emissiveColor='0.1 0.2 0.8'/>";
	$underpass_individual_unit_selected_color = "<Material transparency='0' diffuseColor='0.5 0.5 0.0' emissiveColor='0.5 0.5 0.0'/>";

	$underpass_shared_unit_normal_color =  "<Material transparency='0' diffuseColor='0.0 0.4 0.4' emissiveColor='0.0 0.4 0.4'/>";
	$underpass_shared_unit_selected_color = "<Material transparency='0' diffuseColor='0.5 0.5 0.0' emissiveColor='0.5 0.5 0.0'/>";

	//
	// Paraméterek átvétele
	//
	$radius = $_REQUEST['radius'];
	$lon = $_REQUEST['lon'];
	$lat = $_REQUEST['lat'];

	//Uj map objektum letrehozasa	a map file alapján
	$map_path="";
	$map_file="tdc.map";	
	$map = ms_newMapObj( $map_path.$map_file );		

	//Paraméterek átadása a MAP fájlnak
	$selected_layer=$map->getLayerByName( "query_all_x3d" );

	//DATA változó kiolvasása a MAP fájlból és a paraméterek behelyettesítése
	$data = str_replace( "%selected_radius%", $radius, $selected_layer->data );
    $data = str_replace( "%selected_x%", $lon, $data );
    $data = str_replace( "%selected_y%", $lat, $data );
	$selected_layer->data = $data;

	//aktuális pozició elõállítása
	$search_point = ms_newpointObj();
	$search_point->setXY(	$lon, $lat );

	//Lekérdezés az adott pontban
	$result = $selected_layer->queryByPoint( $search_point, MS_MULTIPLE, -1 );

	$x3d_string = "";


	//Ha volt találat
	if( $result == MS_SUCCESS ){

		//Template végrehajtása és az eredmény szétdarabolása
		$result_xml_string = "<block>" . $map->processquerytemplate( array(), MS_FALSE ) . "</block>";
	
		//XMLSimple objektumot készít a megkapott XML stringből
		$result_xml_object = simplexml_load_string( $result_xml_string );

		//Végig megyek az egyes objektumokon és legyártom hozzá a megfelelő X3D <Translation> tag-eket
		foreach ( $result_xml_object as $object_tag ):
			
			//Egy objektum adatainak begyüjtése
			$query_object_name = $object_tag -> query_object_name;
			$query_object_nid = $object_tag -> query_object_nid;
			$query_object_title = $object_tag -> query_object_title;
			$query_object_x3d = $object_tag -> query_object_x3d;

			// -----------------------------------
			// -- Pontok                                 --
			//------------------------------------
			if( $query_object_name == "sv_survey_point" ){

				$x3d_string .= "\n" .
					"				<!-- Point: ".$query_object_nid." -->\n" .
					"				<Transform translation='" . $query_object_x3d . "'>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n" .
					"							" . $point_normal_color . "\n" .
					"						</Appearance>\n" .
					"						<Sphere radius='0.1'></Sphere>\n" .
					"					</Shape>\n" .
					"				</Transform>\n". 

					"				<!-- Point Text: ".$query_object_nid." -->\n" .
					"				<Transform translation='" . $query_object_x3d . "'>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n" .
					"							" . $point_text_normal_color . "\n" .
					"						</Appearance>\n" .
					"						<Text string='" .  $query_object_title . "' solid='false'>\n" .
					"							<FontStyle size='0.5' spacing='0.8' style='BOLD'/>\n" .
					"						</Text>\n" .
					"					</Shape>\n" .
					"				</Transform>";

			//-------------------------------------
			//--  Parcellák                              --
			//------------------------------------
			}else if( $query_object_name == "im_parcel" ){

				$x3d_string .= "\n" .
					"				<!-- Parcel: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" . 
					"						<Appearance>\n" .
					"							" . $parcel_normal_color . "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>";

			//-----------------------------------------------
			//-- Épületek                                              --
			//----------------------------------------------  
			}else if( $query_object_name == 'im_building' ){

				$x3d_string .= "\n" .
					"				<!-- Building: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n".
					"							". ( ( $query_object_selected == 't' ) ? $building_selected_color : $building_normal_color ) .  "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>" ;

			//-----------------------------------------------------------------
			//-- Épületek individual unitjai                                              --
			//-=---------------------------------------------------------------
			}else if( $query_object_name == 'im_building_individual_unit' ){

				$x3d_string .= "\n" .
					"				<!-- Building individual unit: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n".
					"							". ( ( $query_object_selected == 't' ) ? $building_individual_unit_selected_color : $building_individual_unit_normal_color ) .  "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>" ;

			//-----------------------------------------------
			//-- Aluljáró                                               --
			//-----------------------------------------------  
			}else if( $query_object_name == 'im_underpass' ){

				$x3d_string .= "\n" .
					"				<!-- Underpass: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n".
					"							". ( ( $query_object_selected == 't' ) ? $underpass_selected_color : $underpass_normal_color ) .  "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>" ;

			//-----------------------------------------------------------------
			//-- Aluljáró individual unitjai                                               --
			//-=---------------------------------------------------------------
			}else if( $query_object_name == 'im_underpass_individual_unit' ){

				$x3d_string .= "\n" .
					"				<!-- Underpass individual unit: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n".
					"							". ( ( $query_object_selected == 't' ) ? $underpass_individual_unit_selected_color : $underpass_individual_unit_normal_color ) .  "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>" ;

			//-----------------------------------------------------------------
			//-- Aluljáró shared unitjai                                                   --
			//-=---------------------------------------------------------------
			}else if( $query_object_name == 'im_underpass_shared_unit' ){

				$x3d_string .= "\n" .
					"				<!-- Underpass shared unit: ".$query_object_nid." -->\n" .
					"				<Transform>\n" .
					"					<Shape>\n" .
					"						<Appearance>\n".
					"							". ( ( $query_object_selected == 't' ) ? $underpass_shared_unit_selected_color : $underpass_shared_unit_normal_color ) .  "\n" .
					"						</Appearance>\n" .
					"						" .  $query_object_x3d . "\n" .
					"					</Shape>\n" .
					"				</Transform>" ;

			}// if

		endforeach;

		//-----------------------------------------------
		//-- x3d kiegészítése, hogy valid legyen  ------
		//----------------------------------------------  
		$x3d_string = "" .
			"<?xml version='1.0' encoding='UTF-8'?>\n" .
			"<!DOCTYPE X3D PUBLIC 'ISO//Web3D//DTD X3D 3.0//EN' 'http://www.web3d.org/specifications/x3d-3.0.dtd'>\n" .
			"<X3D profile='Immersive' version='3.0'  xmlns:xsd='http://www.w3.org/2001/XMLSchema-instance' xsd:noNamespaceSchemaLocation =' http://www.web3d.org/specifications/x3d-3.0.xsd '>\n" .
			"	<head>\n" .
			"		<component name='Lighting' level='3'></component>\n" .
			"	</head>\n" .
			"	<Scene>\n" . 
			"		<Transform rotation='1 0 0 -1.57'> \n" .
			"			<Group> \n". $x3d_string;

		$x3d_string .= "\n" .
			"			</Group>\n" .
			"		</Transform>\n" .
			"		<Viewpoint centerOfRotation='" .  $lon . " 530 -" . $lat  . "' orientation='1 0 0 -1.57' position='" . $lon . " 530 -" . $lat . "' />\n" .
			"		<Background DEF='SandyShallowBottom' groundAngle='0.05 1.52 1.56 1.5707' groundColor='0.2 0.2 0 0.3 0.3 0 0.5 0.5 0.3 0.1 0.3 0.4 0 0.2 0.4' skyAngle='0.04 0.05 0.1 1.309 1.570' skyColor='0.8 0.8 0.2 0.8 0.8 0.2 0.1 0.1 0.6 0.1 0.1 0.6 0.1 0.25 0.8 0.6 0.6 0.9'/>\n" .
			"		<NavigationInfo speed='10' type='\"EXAMINE\" \"PAN\" \"WALK\"'  transitionType='ANIMATE' transitionTime='1.0'/> \n" .
			"	</Scene>\n" .
			"</X3D>";

	}else{

		$x3d_string = "Hiba történt.\nNem volt találat.\n" . $result."\n".$data;

	}

	$myFile = "tmp/tdc_all.x3d";
	$fh = fopen( $myFile, 'w' ) or die( "can't open file" );

	//fwrite(  $fh,    implode(",", error_get_last() ) ."--------------------" . $x3d_string );

	//Belehelyezem a létrehozott fájlba az X3D modelt
	fwrite(  $fh, $x3d_string );
	fclose( $fh );

	echo $myFile;

?>
