<?php
	
	try{
	$sClient = new SoapClient('http://localhost:8080/hu.akoel.tdc/CalculatorService?wsdl' );
	$response = $sClient->echo( array( 'name' => $_REQUEST[ 'name' ],  'title' => $_REQUEST[ 'title' ]  ) );

//	$response = $sClient->sum(array('arg0' => 1.1, 'arg1' => 2.2   ) );  //Ez jo, nehogy kitorold
//	$response = $sClient->echo( array( 'name' => 'Kovacs',  'title' => 'dr' ) );  //Ez jo, nehogy kitorold	
//	$response = $sClient->print( array( ) );  //Ez jo, nehogy kitorold

echo $response->return;

} catch(SoapFault $e){
	var_dump($e);
}
?>
