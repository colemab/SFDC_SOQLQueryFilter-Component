public with sharing class SOQLQueryFilter_Comp_Controller {

	// Vars for attrs
	public SObject ObjectToFilter {get;
		set {
			ObjectToFilter = value;
			// now that we know what we are going to filter, we can provide a list of fields . . .
			PopulateFieldsList();
		} // end set
	} // ObjectToFilter
		
	public SOQLQueryFilterResult FilterResult {set; get;}

	// ---------------------------------------
	// internal vars
	// ---------------------------------------

		// vars for describe / field list
		public Map<String, Schema.SObjectField> FieldsMap {get; set;}
		public List<SelectOption> FieldsSelectOptionList {get; set;}

		// vars for holding data from GUI
		public List<SOQLQueryFilterData> SOQLQueryFilterDataList {get; set;}
		
		
	// ---------------------------------------
			
	public SOQLQueryFilter_Comp_Controller() {
		
		FieldsSelectOptionList = new List<SelectOption>();
		SOQLQueryFilterDataList = new List<SOQLQueryFilterData>();
						
		// Make sure we have at least one option on the GUI . . . 		 		
		AddQueryFilterDataRow();
		
	} // SOQLQueryFilter_Comp_Controller Constructor
	
	public void AddQueryFilterDataRow() {
		// this is a reference to the parent controller and is being passed in
		// to prevent from having to make describe calls to the schema again.
		SOQLQueryFilterData Row = new SOQLQueryFilterData(this);
		SOQLQueryFilterDataList.add(Row);
		
		BuildQueryString();				
	} // AddQueryFilterDataRow

	public void RemoveQueryFilterDataRow() {
		
		if (SOQLQueryFilterDataList.size() > 1) {
			// remove the last row
			SOQLQueryFilterDataList.remove(SOQLQueryFilterDataList.size()-1);
		} // SOQLQueryFilterDataList.size > 1
		
		BuildQueryString();
					
	} // RemoveQueryFilterDataRow
	
	private void PopulateFieldsList() {
		// This function will look at the SObject that was passed in
		// and create a selectoption list of those fields for the GUI
	
		FieldsSelectOptionList.clear();
				
		// Returns a map of all sObject names (keys) to sObject tokens (values) for the standard and custom objects defined in your organization.
		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 

		// Get the Object Type from the Map dynamically by using the object type name		
		Schema.SObjectType CurrentType = gd.get(ObjectToFilter.getSObjectType().getDescribe().getName());

		// populate our map with names and labels		
		FieldsMap = CurrentType.getDescribe().fields.getMap();
	 	
	 	// Take that Map and populate a selectOption List with those that the user can access 	
		for(string CurrentKey : FieldsMap.keySet()) {
			
			// only show fields that the user can see
			if (FieldsMap.get(CurrentKey).getDescribe().isAccessible()) {			
			
				// only add fields that can be part of a WHERE clause
				if (FieldsMap.get(CurrentKey).getDescribe().isFilterable() == true) {
					String CurrentLabel = FieldsMap.get(CurrentKey).getDescribe().getLabel();														
					FieldsSelectOptionList.add(new SelectOption(CurrentKey,CurrentLabel));
				} // field is filterable
								
			} // field is accessible
						
		} // loop thru UpdateFieldsMap key set							
						
		// now sort the select list via label
		FieldsSelectOptionList = SortSelectOptions.selectOptionSortByLabel(FieldsSelectOptionList);
		
		// Add a none option to force the user to select a field
		// this is so the operator list can be filter by the field type
		// which will be set once the user makes a selection
		FieldsSelectOptionList.add(0,new SelectOption('','--None--'));
									
	} // PopulateFieldsList
	
	public void BuildQueryString() {
			string SOQLWhereClause = ' WHERE ';
			
			// loop thru our wrapper objects to build our WHERE clause
			for (SOQLQueryFilterData CurrentFilterData : SOQLQueryFilterDataList)
			{					
				
				if (CurrentFilterData.SOQLClause.length() > 0) {
					// Each wrapper class builds its own string, so we just assemble them here . . . 
					SOQLWhereClause += CurrentFilterData.SOQLClause + ' AND ';
				} // CurrentFilterData.SOQLClause != null
				
			} // loop thru SOQLQueryFilterDataList
			
			// remove any trailing and . . . 
			SOQLWhereClause = SOQLWhereClause.removeEnd(' AND ');
			
			system.debug('SOQLWhereClause = ' + SOQLWhereClause);
							
			// since components can only pass data back via objects and not primitives
			// put the string in a wrapper class instance so the object can send data back
											
			if (FilterResult != null) { // avoid nullpointer exception during init
				FilterResult.WhereConditionString = SOQLWhereClause;
			} // FilterResult != null
					
	} // BuildQueryString
	
	static testMethod Void TestSOQLQueryFilter_Comp_Controller()
	{
		// This object will hold the query string
		SOQLQueryFilterResult FilterResult = new SOQLQueryFilterResult();
		
		// instance of the component controller 
		SOQLQueryFilter_Comp_Controller MyController = new SOQLQueryFilter_Comp_Controller();
		
		// filter on the account object, once this is set the fields will get populated
		MyController.ObjectToFilter = new Account(); 
		
		// A new filter option was automatically created, get it to change the settings
		SOQLQueryFilterData FilterOption = MyController.SOQLQueryFilterDataList.get(0);
		
		integer TotalFields = MyController.FieldsSelectOptionList.size(); 
				
		// start this at 1 instead of zero so we don't select --none-- which is first and is invalid 
		for (integer x=1; x<TotalFields; x++ ) {
			// set the current field
			FilterOption.FieldName = MyController.FieldsSelectOptionList.get(1).getValue();
			
			system.debug('Current Field: ' + FilterOption.FieldName);
			
			FilterOption.Value = 'Test';
			
			integer TotalOperators = FilterOption.OperatorList.size();
						
			for (integer y=0; y<TotalOperators; y++) {

				FilterOption.Operator = FilterOption.OperatorList.get(y).getValue();
				
				system.debug('Current Operator: ' + FilterOption.Operator);
				
				// get the condition string				
				system.debug('Condition is: ' + MyController.FilterResult.WhereConditionString);						
			} // loop thru Operators
		} // loop thru fields
						
		system.debug('>>>> END TEST METHOD <<<<<<');
		
	} // TestSOQLQueryFilter_Comp_Controller
		
// ======================================================================================================
	private class SOQLQueryFilterData {
		
		// this wrapper class will hold the field, operator and value for each critera
		// this wrapper class will be held in an array in the main class for iteration
		
		// used to share (mainly schema) data between controller and this inner class
		private SOQLQueryFilter_Comp_Controller ParentController; 		
		
		public Schema.SObjectField CurrentField {get; set;} 
		public Schema.DisplayType CurrentFieldType {get; set;}
		
		public string FieldName {get; 
			
			set{ 
				// whenever the field gets set, we want to limit the operator list
				// to prevent errors and/or invalid SOQL from being returned

				FieldName = value;
				
				if (ParentController.FieldsMap != null) {
					// Pull the current field from the map
					CurrentField = ParentController.FieldsMap.get(value);
								
					// Use a describe call to get the type back (an enum value is returned)
					CurrentFieldType = CurrentField.getDescribe().getType();
					
					// Set the Operator List to valid options for the current type
					PopulateOperatorList();
				} // FieldsMap != null
			} // set method for Field Name
		} // Field Name
		
		public string Operator {get; set;}
		 
		public string Value  {get; 
			set {
				// escape our string to prevent SOQL injection
				this.Value = string.escapeSingleQuotes(value);
			} // set for value
		} // Value String 
		
		// each instance of the wrapper class builds its SOQL here
		public string SOQLClause {
			get {
				string ReturnValue = '';
				
				// If a user added a row but didn't give us a value, don't try to build a string
				// Also, if a user left the field defaulted to --None-- then don't try to build a string
				if (FieldName != null && Operator != null && value != null) {
				
					// This is a special operator that puts text before the field
					if (Operator == 'DOES NOT CONTAIN') {
						// be sure to wrap this operator in parentheses or you will have problems
						// when you have mutiple conditions
						ReturnValue += '( NOT ';
					} // DOES NOT CONTAIN
				
					ReturnValue += FieldName + ' ';
					
					// the like based operators need to be transformed into LIKE
					if (Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN' || Operator == 'STARTS WITH') {
						ReturnValue += 'LIKE ';
					} else {
						// all the other operators can be directly plugged in
						ReturnValue += Operator + ' ';
					} // check for operator being like based
				
					// now add in the value - adding quotes to those that require it
					if (
							CurrentFieldType == Schema.Displaytype.Email ||					
							CurrentFieldType == Schema.Displaytype.ID ||
							CurrentFieldType == Schema.Displaytype.MultiPickList ||
							CurrentFieldType == Schema.Displaytype.Phone ||
							CurrentFieldType == Schema.Displaytype.PickList ||
							CurrentFieldType == Schema.Displaytype.Reference ||
							CurrentFieldType == Schema.Displaytype.String ||
							CurrentFieldType == Schema.Displaytype.URL 
					   ) 
					{
						// the like based operators need to have the % added in
						if (Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN') {
							ReturnValue += '\'%' + value + '%\' ';
						} else if (Operator == 'STARTS WITH') {
							ReturnValue += '\'' + value + '%\' ';
						} else {
							// just add the quotes in
							ReturnValue += '\'' + value + '\' ';											
						}					
					} else {
						// for those that don't require a quote, just plug in the value
						ReturnValue += value + ' ';
					} // check to see if quotes are required

					if (Operator == 'DOES NOT CONTAIN') {
						// be sure to wrap this operator in parentheses or you will have problems
						// when you have mutiple conditions
						ReturnValue += ')';
					} // DOES NOT CONTAIN
								
				} // check for null values
				
				return ReturnValue;
			} // get 
		} // SOQL Clause
		
		// This list is in the wrapper class so that we can adjust
		// the list as needed for each row (i.e. no greater than for a picklist)
		public List<SelectOption> OperatorList {get; set;}
				
		public SOQLQueryFilterData(SOQLQueryFilter_Comp_Controller ParentController) {
						
			this.ParentController = ParentController;
			
			OperatorList = new List<SelectOption>();
			
			// fill the list with the default values ....
			PopulateOperatorList();
			
		} // constructor
		
		private void PopulateOperatorList() {
			
			// reset the list each time to prevent duplicates			
			OperatorList.Clear();
						
			// add our universal comparsion operators
			OperatorList.add(new SelectOption('=','equals'));
			OperatorList.add(new SelectOption('!=','not equal to'));
			OperatorList.add(new SelectOption('IN','in'));
			OperatorList.add(new SelectOption('NOT IN','not in'));
			
			// Now add our Double, Date, Date/Tme Operators						
			if (
					CurrentFieldType == Schema.Displaytype.Currency ||
					CurrentFieldType == Schema.Displaytype.Date ||
					CurrentFieldType == Schema.Displaytype.DateTime ||					
					CurrentFieldType == Schema.Displaytype.Double ||
					CurrentFieldType == Schema.Displaytype.Integer ||
					CurrentFieldType == Schema.Displaytype.Percent 
			   ) 
			{
				OperatorList.add(new SelectOption('<','less than'));
				OperatorList.add(new SelectOption('>','greater than'));		
				OperatorList.add(new SelectOption('<=','less or equal'));
				OperatorList.add(new SelectOption('>=','greater or equal'));
			} // Add Double, Date, Date/time Operators
			
			// Now add LIKE Operator for strings that support it
			if (
					CurrentFieldType == Schema.Displaytype.Email ||					
					CurrentFieldType == Schema.Displaytype.Phone ||
					CurrentFieldType == Schema.Displaytype.PickList ||
					CurrentFieldType == Schema.Displaytype.String ||
					CurrentFieldType == Schema.Displaytype.URL 
			   ) 
			{
				
				OperatorList.add(new SelectOption('CONTAINS','contains'));
				OperatorList.add(new SelectOption('DOES NOT CONTAIN','does not contain'));
				OperatorList.add(new SelectOption('STARTS WITH','starts with'));
				
			} // Add LIKE Operator
			
			/* TO BE IMPLEMENTED LATER:  
				Please note this will require modification of SOQLClause's getter method to implement
							
				//Now add EXCLUDES and INCLDUES for MultiPickLists
				if (CurrentFieldType == Schema.Displaytype.MultiPickList) 
				{
					// Note that EXCLUDES and INCLUDES require a comma delimited list wrapped in Parentheses
					OperatorList.add(new SelectOption('EXCLUDES','excludes'));
					OperatorList.add(new SelectOption('INCLUDES','includes'));				
				} // Add EXCLUDES & INCLUDES Operators
			
			*/
						
		} // RePopulateOperatorList
		
	} // SOQLQueryFilterData

} // end class SOQLQueryFilter_Comp_Controller