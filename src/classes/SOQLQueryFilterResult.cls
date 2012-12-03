public with sharing class SOQLQueryFilterResult {

/*
	11/29/2012 TC - This wrapper class exists to allow data
	to be returned from the component named "SQLQueryFilter".
	
	As of this date, salesforce only allows values to be returned from component's
	by changing the properties of objects (i.e. primitives like strings, integers, etc).
*/

	public string WhereConditionString {get;set;}
		
} // SOQLQueryFilterResult