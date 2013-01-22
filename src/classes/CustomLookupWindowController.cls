public with sharing class CustomLookupWindowController {
	
	// List search is used for limited lists (like picklists) in a field on an object
	// Text search is used for google type searching of records on an object.	
	public boolean RenderListSearch {get; set;}
	public boolean RenderTextSearch {get; set;}
	
	// used to select all entries in the GUI
	public boolean SelectAllList {get; set;}
	
	// When in List mode, this is a list of options to choose from.
	// the wrapper class below is used to determine which items were selected.
	public List<SelectedListWrapper> ListModeOptionsList  {
		get {
			if (ListModeOptionsList == null) ListModeOptionsList = new List<SelectedListWrapper>();
			return ListModeOptionsList;
		}
		set;
	} // ListModeOptionsList
	
	// the user's search input from the GUI
	public string TextSearchInput {get; set;}
	
	public List<String> TextOptionsList  {
		get {
			if (TextOptionsList == null) TextOptionsList = new List<String>();
			return TextOptionsList;
		}
		set;
	} // ListModeOptionsList 
		
	// this is a list of items that were selected in the GUI
	public string SelectedString {get; set;}
		
	public CustomLookupWindowController() {
		
		RenderListSearch = false;
		RenderTextSearch = false;
		SelectAllList = false;
		TextSearchInput = '';
				
		string CurrentObjectName = getObjectName(); 
		string CurrentFieldName = getFieldName();
		string CurrentFormInputDOMName = getFormDOMName();
		
		if (CurrentObjectName != null) {						
			// Use the Summer'12 reflection to generate our type
			Type CurrentType = Type.forName(CurrentObjectName);
			
			// Create an object from the type
			object CurrentObject = CurrentType.newInstance();
			
			if (CurrentObject != null) {
				// Returns a map of all sObject names (keys) to sObject tokens (values) for the standard and custom objects defined in your organization.
				Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
				
				// Schema.SObjectType is needed to get our map of fields, so lets create it from our object name
				Schema.SObjectType CurrentSObjectType = gd.get(CurrentObjectName);
				
				if (CurrentSObjectType != null) {
					// Create a map of fields
					Map<String, Schema.SObjectField> FieldsMap = CurrentSObjectType.getDescribe().fields.getMap();
					
					// get the current field (Mocked up for Type field on account object)
					Schema.SObjectField CurrentField = FieldsMap.get(CurrentFieldName);
					
					// cache out the current field type so that only one describe call is made to get it
					Schema.DisplayType CurrentFieldType = CurrentField.getDescribe().getType();
					
					
					if (CurrentFieldType == Schema.Displaytype.PickList || CurrentFieldType == Schema.Displaytype.MultiPickList) {
						// If the field is a pick list or multi pick list, we are going to use the wrapper class and a list of known values
						PopulateListModeOptionsList(CurrentField);
						RenderListSearch = true;
					} else {
						// otherwise we are going to use a generic search screen
						RenderTextSearch = true;
					} // check for pick list
				
				} // CurrentSObjectType != null
				
			} // CurrentObject != null
			
		} // CurrentObjectName != null
		
	} // CustomLookupWindowController constructor
	
	
	// this method runs the SOSL search
	public void TextSearch() {
		string ObjectName = string.escapeSingleQuotes(getObjectName());
		
		string SOQLQueryString = 'SELECT ID, NAME FROM ' + ObjectName + ' WHERE NAME LIKE \'%' + TextSearchInput + '%\'';
		
		List<sObject> SearchResults = Database.query(SOQLQueryString);
		
		TextOptionsList.clear();
		
		for (sObject R: SearchResults) {
			TextOptionsList.add(string.valueof(R.get('Name')));
		} // loop thru TextOptionsList
				
	} // TextSearch
	
	private void PopulateListModeOptionsList(Schema.SObjectField CurrentField) {
		
		List <Schema.PicklistEntry> CurrentListValues = CurrentField.getDescribe().getPicklistValues(); 
		List <String> OptionsList = new List<String>();
		
		// since the picklist values come back as a list of Schema.PicklistEntry but we need a list of strings 
		// and we want to sort those strings, a second list is required
		for (Schema.PicklistEntry P : CurrentListValues) {
			OptionsList.add(P.getValue());
		} // loop thru CurrentListValues

		// sort the list since they aren't always in alpha order
		OptionsList.sort();

		ListModeOptionsList.clear();
			
		// a wrapper class is used to determine which checkboxes are selected (via boolean var)
		for (String V: OptionsList) {
			SelectedListWrapper CurrentSelectedListWrapper = new SelectedListWrapper();
			CurrentSelectedListWrapper.Value = V;
			CurrentSelectedListWrapper.Selected = false; // defaulted to false
			ListModeOptionsList.add(CurrentSelectedListWrapper);
		} // loop thru OptionsList
		
	} // PopulateListModeOptionsList
	
	// this function is used to select or deselect all instead of javascript	
	public void SetCurrentSelectedListWrapperSelected() {
		// toggle the boolean because the value won't get updated until the form has been submitted
		SelectAllList = !SelectAllList;
		
		for (SelectedListWrapper S: ListModeOptionsList) {
			S.Selected = SelectAllList; // defaulted to false
		} // loop thru OptionsList		
	} // SetCurrentSelectedListWrapperSelectedTo
	
	// this method is used to generate the text of the options that the user has selected
	public void BuildSelectedString() {
		
		SelectedString = '';
				
		for (SelectedListWrapper S: ListModeOptionsList) {
			if (S.Selected == true) {				
				if(S.Value.containsAny(',') == true) {
					// Since Commas are used for delimiting, put double quotes around any values that have commas
					SelectedString += '\"' + S.Value + '\"' + ', '; 	
				} else {
					// otherwise just use the comma and a space
					SelectedString += S.value + ', ';
				} //S.Value.containsAny(',') == true
			} // S.Selected == true
		} // loop thru OptionsList
			
		// remove any trailing commas
		if (SelectedString.endsWith(',')) SelectedString = SelectedString.removeEnd(','); 
			
	} // BuildSelectedString
		
	// this is the form DOM Name / Tag from the calling page
	public string getFormDOMName() {
		return System.currentPageReference().getParameters().get('form');
	} // getFormDOMName
	
	// this is the input/text box DOM Name / Tag from the calling page
	public string getInputDOMName() {
		return System.currentPageReference().getParameters().get('input');
	} // getInputDOMName
	
	// this is the name of the object being searched
	public string getObjectName() {
		return System.currentPageReference().getParameters().get('object');
	} // getObjectName
	
	// this is the field name being searched (in list search mode)
	public string getFieldName() {
		return System.currentPageReference().getParameters().get('field');
	} // getFieldName
	
	// this class tracks the value and if it was selected.
	private class SelectedListWrapper  {
		public boolean Selected {get; set;}
		public string Value {get; set;}
	} // end class SelectedListWrapper
	
	static testMethod Void TestCustomLookupWindowController() {
		
		Account MyAccount = new Account();
		MyAccount.Name = 'Acme, Inc.';
		MyAccount.BillingState = 'AL';
		insert MyAccount;
		
		PageReference CurrentPage = Page.CustomLookupWindow;
		Test.setCurrentPageReference(CurrentPage);
		
		ApexPages.currentPage().getParameters().put('object', 'Account');
		ApexPages.currentPage().getParameters().put('field', 'type');		
		CustomLookupWindowController MyController = new CustomLookupWindowController();
		system.assert(MyController.RenderTextSearch == false);
		system.assert(MyController.RenderListSearch == true);
		
		// this will select or deselect all options
		MyController.SetCurrentSelectedListWrapperSelected();
		// this will build a comma delimited list of all selected options
		MyController.BuildSelectedString();
		
		ApexPages.currentPage().getParameters().put('input', 'test');
		system.assert(MyController.getInputDOMName() == 'test');
		
		ApexPages.currentPage().getParameters().put('object', 'Account');
		ApexPages.currentPage().getParameters().put('field', 'name');
		MyController = new CustomLookupWindowController();
		system.assert(MyController.RenderTextSearch == true);
		system.assert(MyController.RenderListSearch == false);
		
		MyController.TextSearchInput = 'a';
		MyController.TextSearch();
				
	} // TestCustomLookupWindowController	
	
} // end class CustomLookupWindowController