package hu.akoel.tdc;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

@WebService(name = "Calculator", serviceName ="CalculatorService", portName ="CalculatorPort", targetNamespace="http://tempuri.org")
public class Calculator {

	@WebMethod()
	public double sum( @WebParam(name="arg0") double num1, @WebParam(name="arg1") double num2){
		return num1 + num2;
	}
	
	@WebMethod()
	public String echo( @WebParam(name="name") String name, @WebParam(name="title") String title ){
		return "Hello: " + name + "-" + title;
	}
	
	@WebMethod()
	public String print(){
		return "Legyen mar valami";
	}
}
