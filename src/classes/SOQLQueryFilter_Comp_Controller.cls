public with sharing class SOQLQueryFilter_Comp_Controller {

	// Vars for attrs
	public SObject ObjectToFilter {get;
		set {
			ObjectToFilter = value;
			
			// This is used communicate with lookup window
			this.CurrentObjectName = EncodingUtil.urlEncode(ObjectToFilter.getSObjectType().getDescribe().getName(), 'UTF-8');
			
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
		
		// vars for advanced filter logic
		public boolean AdvancedFilterEnabled {get; set;} 
		public string AdvancedFilterCondition {get; set;}
		public string AdvancedFilterCondtionErrorMessage {get; set;}
		public boolean AdvancedFilterCondtionHasError {get; set;}
		
		// vars for custom lookup window - should be UTF-8 encoded to pass in the URL
		public string CurrentObjectName {get; set;}		
	// ---------------------------------------
			
	public SOQLQueryFilter_Comp_Controller() {
		
		FieldsSelectOptionList = new List<SelectOption>();
		SOQLQueryFilterDataList = new List<SOQLQueryFilterData>();
		
		AdvancedFilterEnabled = false;
		AdvancedFilterCondition = '';	
		AdvancedFilterCondtionErrorMessage = '';
		AdvancedFilterCondtionHasError = false;
					
		// Make sure we have at least one option on the GUI . . . 		 		
		AddQueryFilterDataRow();
		
	} // SOQLQueryFilter_Comp_Controller Constructor
	
	public void ToggleAdvancedFilter() {
								
		AdvancedFilterEnabled = !AdvancedFilterEnabled;
				
		if (AdvancedFilterEnabled == false) {
			AdvancedFilterCondition = '';
			BuildQueryString();
		} // AdvancedFilterEnabled == false
						
	} // ToggleAdvancedFilter
	
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


	public void ValidateAdvancedFilterString() {
		
		// assume we will have an error . . .
		AdvancedFilterCondtionHasError = true;
				
		if (AdvancedFilterEnabled == true) {
			// if the user didn't specify any condition then use the default 
			if (AdvancedFilterCondition == '') {
				AdvancedFilterCondtionErrorMessage = 'Filter logic is required when enabled.';
				return;				
			} // AdvancedFilterCondition == ''
			
			// someone forgot to close a parentheses or forgot to open one
			if (AdvancedFilterCondition.countMatches('(') != AdvancedFilterCondition.countMatches(')')) {
				AdvancedFilterCondtionErrorMessage = 'All parentheses must be closed and opened.';
				return;
			} // check for ( and ) count being equal
			
			// tokenize the AdvancedFilterCondition via spaces
			list<string> AdvancedFilterConditionTokens = AdvancedFilterCondition.split(' ');
			
			boolean LastTokenWasNumeric = true;
			
			for (integer x=0; x<AdvancedFilterConditionTokens.size(); x++) {
				string CurrentToken = AdvancedFilterConditionTokens.get(x);
				
				// if the user doesn't put a space between parentheses,
				// we need to remove parentheses to get a truley numeric value
				string CurrentTokenNumeric = CurrentToken.remove('(');
				CurrentTokenNumeric = CurrentTokenNumeric.remove(')');
								
				if (CurrentTokenNumeric.isNumeric()) {

					// filter logic is made up of field numbers and union statements AND, OR
					// if two field numbers are back to back, the logic is invalid					
					if (LastTokenWasNumeric == true && x!=0) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;												
					} // LastTokenWasNumeric == true
					
					// the tokens will start at 1 but the clause will start a 0
					integer CurrentClause = integer.valueof(CurrentTokenNumeric)-1;
					
					// the user tried to add a number but the array isn't that large					
					if (SOQLQueryFilterDataList.size() < CurrentClause) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic references an undefined filter: ' + CurrentTokenNumeric;
						return;
					} // SOQLQueryFilterDataList.size > CurrentClause
					
					LastTokenWasNumeric = true;																
				} else {
					// filter logic is made up of field numbers and union statements AND, OR
					// if two union statements are back to back, the logic is invalid
					if (LastTokenWasNumeric == false) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;						
					} // LastTokenWasNumeric == false
					
					// Check for invalid placement of NOT 
					if (CurrentTokenNumeric.toUpperCase() == 'NOT' && x!=0) {
						AdvancedFilterCondtionErrorMessage = 'The NOT operator is only valid at the start filter logic.';
						return;													
					} // check for NOT but not in first clause
					
					// AND/OR/NOT are the only valid operators
					if (CurrentTokenNumeric.toUpperCase() != 'OR' && CurrentTokenNumeric.toUpperCase() != 'AND' && CurrentTokenNumeric.toUpperCase() != 'NOT') {
						AdvancedFilterCondtionErrorMessage = 'Check the spelling in your filter logic.';
						return;																			
					} // check for AND/OR/NOT 

					// the filter logic cannot end with an operator					
					if (x+1==AdvancedFilterConditionTokens.size()) {
						AdvancedFilterCondtionErrorMessage = 'The filter logic is invalid.';
						return;												
					} // x==AdvancedFilterConditionTokens.size()
					
					LastTokenWasNumeric = false; 
				} // CurrentToken.isNumeric()
				
			} //CurrentToken: AdvancedFilterConditionTokens
						
		} // AdvancedFilterEnabled == true
		
		// clear any previous error messages on each run
		AdvancedFilterCondtionErrorMessage = '';		
		// this is used by the build string function to avoid building an invalid string
		AdvancedFilterCondtionHasError = false;
		
	} //ValidateAdvancedFilterString 
	
	public void PopulateFieldList() {
		
		FilterResult.FieldsList = new List<String>();
		
		for (SOQLQueryFilterData CurrentFilterData : SOQLQueryFilterDataList) {
			FilterResult.FieldsList.add(CurrentFilterData.FieldName);
		} // loop thru wrapper objects
		
	} // PopulateFieldList
	
	public void BuildQueryString() {
			string SOQLWhereClause = ' ';
			
			// if no advanced query, everything is AND
			if (AdvancedFilterEnabled == false) {
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
			} else {
								 
				// this call will set AdvancedFilterCondtionHasError 
				ValidateAdvancedFilterString();
				
				if (AdvancedFilterCondtionHasError == false) {
								
					// tokenize the AdvancedFilterCondition via spaces
					list<string> AdvancedFilterConditionTokens = AdvancedFilterCondition.split(' ');
					
					for (integer x=0; x<AdvancedFilterConditionTokens.size(); x++) {
						string CurrentToken = AdvancedFilterConditionTokens.get(x);
						
						// if the user doesn't put a space between parentheses,
						// we need to remove parentheses to get a truley numeric value
						string CurrentTokenNumeric = CurrentToken.remove('(');
						CurrentTokenNumeric = CurrentTokenNumeric.remove(')');
						
						if (CurrentTokenNumeric.isNumeric()) {
							// the tokens will start at 1 but the clause will start a 0
							integer CurrentClause = integer.valueof(CurrentTokenNumeric)-1;
							
							// Replace is used here so that any parentheses are kept
							CurrentToken = CurrentToken.replace(CurrentTokenNumeric,SOQLQueryFilterDataList.get(CurrentClause).SOQLClause); 
													
							AdvancedFilterConditionTokens.set(x,CurrentToken);
						} // CurrentToken.isNumeric()
					} //CurrentToken: AdvancedFilterConditionTokens
					
					// re-assemble our tokens
					SOQLWhereClause = string.join(AdvancedFilterConditionTokens, ' ');
				} // AdvancedFilterCondtionHasError == false
				 				
			} // if (AdvancedFilterEnabled == false) 						
							
			// since components can only pass data back via objects and not primitives
			// put the string in a wrapper class instance so the object can send data back
											
			if (FilterResult != null) { // avoid nullpointer exception during init
				FilterResult.WhereConditionString = SOQLWhereClause;
				PopulateFieldList();
			} // FilterResult != null
					
	} // BuildQueryString
	
	static testMethod Void TestSOQLQueryFilter_Comp_Controller()
	{
		// This object will hold the query string
		SOQLQueryFilterResult FilterResultObject = new SOQLQueryFilterResult();
		FilterResultObject.WhereConditionString = '';
		
		// instance of the component controller 
		SOQLQueryFilter_Comp_Controller MyController = new SOQLQueryFilter_Comp_Controller();
		MyController.FilterResult = FilterResultObject;
		
		// filter on the account object, once this is set the fields will get populated
		MyController.ObjectToFilter = new Account();
		
		// A new filter option was automatically created, get it to change the settings
		SOQLQueryFilterData FilterOption = MyController.SOQLQueryFilterDataList.get(0);
		
		integer TotalFields = MyController.FieldsSelectOptionList.size(); 
				
		// start this at 1 instead of zero so we don't select --none-- which is first and is invalid 
		for (integer x=1; x<TotalFields; x++ ) {
			// set the current field
			FilterOption.FieldName = MyController.FieldsSelectOptionList.get(x).getValue();			
			system.debug('Current Field: ' + FilterOption.FieldName);
									
			if (Schema.Displaytype.PickList == FilterOption.CurrentFieldType) {
				FilterOption.Value = 'A,B,C,D';
			} else if (Schema.Displaytype.Date == FilterOption.CurrentFieldType) {
				FilterOption.Value = '1/1/2013';
			} else {			
				FilterOption.Value = 'Test';
			}
						
			integer TotalOperators = FilterOption.OperatorList.size();
						
			for (integer y=0; y<TotalOperators; y++) {

				FilterOption.Operator = FilterOption.OperatorList.get(y).getValue();
				
				system.debug('Current Operator: ' + FilterOption.Operator);
								
				// get the condition string				
				system.debug('Condition is: ' + MyController.FilterResult.WhereConditionString);						
			} // loop thru Operators
		} // loop thru fields
		
		MyController.BuildQueryString();

		// increase code coverage by getting the UTF 8 name
		system.debug('UTF8 Name = ' + FilterOption.FieldNameUTF8);
		
		
		// increase code coverage by building differnt mutiple SOQL queries
			FilterOption.Value = '"A","B","C","D"';
			FilterOption.RenderLookupIcon  = true;
			MyController.BuildQueryString();
			
			FilterOption.Operator = 'NOT IN';
			FilterOption.Value = 'A,B,C,D';
			MyController.BuildQueryString();
	
			FilterOption.Operator = 'IN';
			FilterOption.Value = 'A,B,C,D';
			MyController.BuildQueryString();
			
			FilterOption.Operator = 'DOES NOT CONTAIN';
			FilterOption.Value = '"A","B","C","D"';
			MyController.BuildQueryString();
			
		// calls to GUI methods
		MyController.AddQueryFilterDataRow();
		MyController.RemoveQueryFilterDataRow();		
		MyController.ToggleAdvancedFilter();
		
		// code coverage for advanced filter error conditions
		
			// Filter logic is required when enabled.
			MyController.AdvancedFilterCondition  = '';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// All parentheses must be closed and opened.
			MyController.AdvancedFilterCondition  = '(';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// if two field numbers are back to back, the logic is invalid			
			MyController.AdvancedFilterCondition  = '1 2 3';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// The filter logic references an undefined filter			
			MyController.AdvancedFilterCondition  = '10000';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// if two union statements are back to back, the logic is invalid 
			MyController.AdvancedFilterCondition  = '1 AND AND';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// The NOT operator is only valid at the start filter logic
			MyController.AdvancedFilterCondition  = '1 NOT';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// unknown operator
			MyController.AdvancedFilterCondition  = 'BOB';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);

			// the filter logic cannot end with an operator
			MyController.AdvancedFilterCondition  = '1 AND';
			MyController.ValidateAdvancedFilterString();
			system.assert(MyController.AdvancedFilterCondtionHasError == true);
			
			// test a clean build of advanced query string
			MyController.AdvancedFilterEnabled = true;
			MyController.AdvancedFilterCondtionHasError = false;
			MyController.AdvancedFilterCondition  = '1 AND 1';
			MyController.BuildQueryString();
			system.debug('AdvancedFilterCondtionErrorMessage = ' + MyController.AdvancedFilterCondtionErrorMessage);
			system.assert(MyController.AdvancedFilterCondtionHasError == false);
									
			// test flipping the indicator back						
			MyController.AdvancedFilterEnabled = true;
			MyController.ToggleAdvancedFilter();
			
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
								
					if (CurrentField != null) {								
						// Use a describe call to get the type back (an enum value is returned)
						CurrentFieldType = CurrentField.getDescribe().getType();
					} // CurrentField != null
					
					// Set the Operator List to valid options for the current type
					PopulateOperatorList();
				} // FieldsMap != null
			} // set method for Field Name
		} // Field Name
		
		// the field name is UTF8 encoded for use with the lookupwindow
		public string FieldNameUTF8 {
			get {
				return EncodingUtil.urlEncode(FieldName,'UTF-8');
			} // get
		} // FieldNameUTF8
		
		public string Operator {get; set;}
		 
		public string Value  {
			get {
				if (value == null) value='';
				return value;
			} 
			set;
		} // Value String 
		
		// vars for use when time fields are used in the GUI
		public string Hour {get; set;}
		public string Minute {get; set;}
		public string AMPM {get; set;}
		
		public List<SelectOption> HourList {get; set;}
		public List<SelectOption> MinuteList {get; set;}
		public List<SelectOption> AMPMList {get; set;}
		
		// var for displaying CustomLookupWindow on fields that can use it
		public boolean RenderLookupIcon {get;set;}
		// var for displaying date picker icon on date fields
		public boolean RenderDatePickerIcon {get;set;}
		
		// Future Development: var for displaying date/time picker on date/time fields
		public boolean RenderDateTimePickerIcon {get;set;}
				
		// InputValue is passed in so that BuildMultipleSOQLSOQLClause can use this method too
		private string BuildSingleSingleClause(string InputValue) {
				string ReturnValue = '';
								
				// escape quotes here to prevent SOQL injection while hiding them from the GUI
				string EscapedValue = string.escapeSingleQuotes(InputValue);
				
				// If a user added a row but didn't give us a value, don't try to build a string
				// Also, if a user left the field defaulted to --None-- then don't try to build a string
				if (FieldName != null && Operator != null && EscapedValue != null) {
				
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
							ReturnValue += '\'%' + EscapedValue + '%\' ';
						} else if (Operator == 'STARTS WITH') {
							ReturnValue += '\'' + EscapedValue + '%\' ';
						} else {
							// just add the quotes in
							ReturnValue += '\'' + EscapedValue + '\' ';											
						} // Operator == 'CONTAINS' || Operator == 'DOES NOT CONTAIN'
					} else {												
						// for those that don't require a quote, just plug in the value
						ReturnValue += EscapedValue + ' ';
					} // check to see if quotes are required

					if (Operator == 'DOES NOT CONTAIN') {
						// be sure to wrap this operator in parentheses or you will have problems
						// when you have mutiple conditions
						ReturnValue += ')';
					} // DOES NOT CONTAIN
								
				} // check for null values
				
				return ReturnValue;
			
		} // BuildSingleSOQLSOQLClause
		
		// the input string is passed in to allow the value to be different from
		// the value on the row / data wrapper instance (i.e. reformat dates in the background)		
		private string BuildMultipleSOQLSOQLClause(string InputValue) {
			string ReturnValue = '';
			
			List<string> ParsedValuesList = new List<string>();
			
			if (InputValue.containsAny('"')) {
				// since values could contain double quotes and commas, we need to parse twice
				// once for the double quote and again for the comma
				List<string> QuoteParsedValuesList = InputValue.split('"');
				
				for (string S:QuoteParsedValuesList) {
					
					if (S.startsWith(', ') || S.endsWith(', ')) {
						S = S.removeStart(', ');
						S = S.removeEnd(', ');
					}	
					
					// escape the string to prevent SOQL injection
					S =  string.escapeSingleQuotes(S);
										
					ParsedValuesList.add(S);
					
				} // for (string S:QuoteParsedValuesList)
			} else {
				// this is a normal comma delimited parse
				ParsedValuesList = InputValue.split(', ');
			} // if InputValue.containsAny('"')
									
			if (Operator == '=' || Operator == 'IN' || Operator == '!=' || Operator == 'NOT IN') {

				if (Operator == '=' || Operator == 'IN') {
					ReturnValue = FieldName + ' IN (';
				}else if (Operator == '!=' || Operator == 'NOT IN') {
					ReturnValue = FieldName + ' NOT IN (';
				} // Operator == 'equals' || Operator == 'in'
			
				// add delimiters for the SOQL query
				for (string CurrentValue: ParsedValuesList) {			
					ReturnValue += '\'' + CurrentValue + '\',';					
				} // for (string CurrentValue: ParsedValuesList) 
				
				// remove any trailing commas
				if (ReturnValue.endsWith(',')) ReturnValue = ReturnValue.removeEnd(',');
			
				// add closing Parenthesis
				ReturnValue += ')'; 
			
			} else { 	// for contains, does not contain, and starts with

				// default to OR for Contains and starts with
				string CurrentCondition = ' OR ';

				// change to AND as needed (currently only for does not contain)
				if (Operator == 'DOES NOT CONTAIN') {
					CurrentCondition = ' AND ';
				} // if (Operator == 'DOES NOT CONTAIN') {

				for (string CurrentValue: ParsedValuesList) {
					ReturnValue += BuildSingleSingleClause(CurrentValue) + CurrentCondition;					
				} // for (string CurrentValue: ParsedValuesList) {

				// remove any trailing condition
				if (ReturnValue.endsWith(CurrentCondition)) ReturnValue = ReturnValue.removeEnd(CurrentCondition);

				// surround with Parentheses just in case this is parter of a larger expression					
				ReturnValue = ' (' + ReturnValue + ' )'; 
				
			} // Operator == '=' || Operator == 'IN' || Operator == '!=' || Operator == 'NOT IN'
						
			return ReturnValue; 
		} // BuildMultipleSOQLSOQLClause
		
		
		// each instance of the wrapper class builds its SOQL here
		public string SOQLClause {
			get {
				
				string FormatedValue = value;
				
				if (!String.isEmpty(value)) {
					try {
						if (CurrentFieldType == Schema.Displaytype.Date) {
							date InputDate = date.parse(value);
							// change the format for the query to standard YYYY-MM-DD format
							FormatedValue = String.valueOf(InputDate);
						} else if (CurrentFieldType == Schema.Displaytype.DateTime) {
							
							string TempDateTime = value + ' ' + Hour + ':' + Minute + ' ' + AMPM;							
							system.debug('>>>> TempDateTime = ' + TempDateTime);
							
							datetime InputDateTime = datetime.parse(TempDateTime);
							
							// change the format to the standard YYYY-MM-DDTHH.mm.ss.000Z format
							FormatedValue = InputDateTime.formatGMT('yyyy-MM-dd') + 'T' + InputDateTime.formatGMT('HH:mm:ss.SSS') + 'Z';
							
						} // check for values that need to be reformatted
					} catch (exception e) {
						FormatedValue = value;
					}					
				} // check for blank value
										
				// if the lookup icon was rendered AND the value contains a comma then process as mutiple values
				// when mutiple values are provided by the lookup window, they will be comma delimited
				// if an individual value contains a comma, it will be wrapped in double quotes
				if (RenderLookupIcon == true && value.containsAny(',')) {
					return BuildMultipleSOQLSOQLClause(FormatedValue);
				} else {						
					return BuildSingleSingleClause(FormatedValue);
				}
							
			} // get 
		} // SOQL Clause
		
		// This list is in the wrapper class so that we can adjust
		// the list as needed for each row (i.e. no greater than for a picklist)
		public List<SelectOption> OperatorList {get; set;}
				
		public SOQLQueryFilterData(SOQLQueryFilter_Comp_Controller ParentController) {
						
			this.ParentController = ParentController;
			
			OperatorList = new List<SelectOption>();
			
			HourList = new List<SelectOption>();
			MinuteList = new List<SelectOption>();
			AMPMList = new List<SelectOption>();
			
			RenderLookupIcon = false;
			RenderDatePickerIcon = false;
			RenderDateTimePickerIcon = false;
			
			// fill the list with the default values ....
			PopulateOperatorList();
			
		} // constructor
		
		private void UpdateRenderLookupIcon() {
			// for now, this only display's for picklist and Name Fields
			if (
				(CurrentFieldType == Schema.Displaytype.PickList) || 
					(CurrentFieldType == Schema.Displaytype.String) && (CurrentField.getDescribe().getName() == 'Name') 
				) 
			{
					
				RenderLookupIcon = true;
			} else {
				RenderLookupIcon = false;
			}
		} // UpdateRenderLookupIcon
		
		private void UpdateRenderDatePickerIcon() {
			// Only display this for date fields
			if (CurrentFieldType == Schema.Displaytype.Date) 				
			{					
				RenderDatePickerIcon = true;
			} else {
				RenderDatePickerIcon = false;
			}
			
		} // UpdateRenderDatePickerIcon

		// Future Development: Toggle javascript / icon for date / time picker
		private void UpdateRenderDateTimePickerIcon() {
			// Only display this for date/time fields
			if (CurrentFieldType == Schema.Displaytype.DateTime) 				
			{					
				RenderDateTimePickerIcon = RenderDatePickerIcon = true;
				PopulateTimesLists();
			} else {
				RenderDateTimePickerIcon = RenderDatePickerIcon = false;
			}			
		} // UpdateRenderDateTimePickerIcon
		
		private void PopulateTimesLists() {

			PopulateHoursList();
			PopulateMinutesList();
			PopulateAMPMList();

		} // PopulateTimesLists
		
		private void PopulateHoursList() {
			
			HourList.clear();
			
			for (integer x = 1; x <= 12; x++) {				
			
				HourList.add(new SelectOption(String.ValueOf(x), String.ValueOf(x)));
			
			} // loop to 12
												
		} // PopulateHoursList
		
		private void PopulateMinutesList() {
			
			MinuteList.clear();
			
			for (integer x = 0; x < 60; x++) {	
				
				// zero pad any single digits to be 2 digits
				string CurrentMinute = String.ValueOf(x);
				if (CurrentMinute.length() == 1) CurrentMinute = '0' + CurrentMinute;
				
				MinuteList.add(new SelectOption(CurrentMinute, CurrentMinute));
				
			} // loop to 59
			
		} // PopulateMinutesList
		
		private void PopulateAMPMList() {
			
			AMPMList.clear();
			
			AMPMList.add(new SelectOption('AM', 'AM'));
			
			AMPMList.add(new SelectOption('PM', 'PM'));
			
		} // PopulateAMPMList
				
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
					// Note that EXCLUDES and INCLUDES require a comma delimited list wrapped in Parentheses (much like in / not in)
					OperatorList.add(new SelectOption('EXCLUDES','excludes'));
					OperatorList.add(new SelectOption('INCLUDES','includes'));				
				} // Add EXCLUDES & INCLUDES Operators
			
			*/
			
			// display the lookup icon as needed
			UpdateRenderLookupIcon();
			
			// attach the date picker as needed
			UpdateRenderDatePickerIcon();		
			
			// attach the date/time picker as needed
			UpdateRenderDateTimePickerIcon();
				
		} // PopulateOperatorList
		
	} // SOQLQueryFilterData

} // end class SOQLQueryFilter_Comp_Controller