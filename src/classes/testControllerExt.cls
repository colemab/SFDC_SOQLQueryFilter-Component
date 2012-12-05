public with sharing class testControllerExt {

	public SOQLQueryFilterResult FilterResult {get; set;}
	public SObject Object2Filter {get; set;}
		
	public testControllerExt () {
	
		// be sure to initialize your SOQLQueryFilterResult and
		// default WhereConditionString in your page's constructor
			
		FilterResult = new SOQLQueryFilterResult();
		FilterResult.WhereConditionString = '';
		
		Account MyAccount = new Account(); 
		Object2Filter = MyAccount;
		
	} // testControllerExt constructor

} // main class