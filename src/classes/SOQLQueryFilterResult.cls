public with sharing class SOQLQueryFilterResult {

	/*
		11/29/2012 TC - This wrapper class exists to allow data
		to be returned from the component named "SQLQueryFilter".
		
		As of this date, salesforce only allows values to be returned from component's
		by changing the properties of objects (i.e. primitives like strings, integers, etc).
	*/

	// this is the sting that will be plugged into your SOQL where clause
	public string WhereConditionString {get;set;}
	
	// this is a list of the fields that exist in the where clause
	public List<String> FieldsList {get; set;}	
	
	// this will translate the list into a comma delimited string
	public string FieldsListString {
		get {
			string returnValue = '';
			
			// build our comma+space delimited string
			for (string CurrentField: FieldsList) {
				returnValue += CurrentField + ', ';
			} // loop thru FieldsList
			
			// trim any trailing delimiters
			returnValue = returnValue.removeEnd(', ');
			
			return ReturnValue;
		} // get
	} // FieldsListString
} // SOQLQueryFilterResult