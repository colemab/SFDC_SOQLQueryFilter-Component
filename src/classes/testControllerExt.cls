public with sharing class testControllerExt {

	public SOQLQueryFilterResult FilterResult {get; set;}
	public SObject Object2Filter {get; set;}
	
	
	public testControllerExt () {
		FilterResult = new SOQLQueryFilterResult();
		Account MyAccount = new Account(); 
		Object2Filter = MyAccount;
	} // testControllerExt constructor

} // main class