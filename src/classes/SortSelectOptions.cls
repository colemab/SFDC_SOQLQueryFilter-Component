/*

    @Author: Mohammad Usman
    @Description: Class is used to sort selectOptions by Label and value
    @version:1.0
    
    This class is used with permission from Mohammad.  You can see this class on his
    blog at this address:
    
    http://sfdchack.blogspot.com/2012/10/sort-selectoptions-list-in-apex.html
    
    I have modified the class only to add some very minor comments and test code. 

*/
public with sharing class SortSelectOptions {

    public static list<selectOption> selectOptionSortByLabel(list<selectOption>
                                                            selectOptionsToSort) {
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
        
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot];
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getLabel() <= pivotValue.getLabel()){
                lessSelectOption.add(SO);
            }else if(SO.getLabel() > pivotValue.getLabel()){
                greaterSelectOption.add(SO);   
            }
        }
        list<selectOption> sortedSelectOptions = new list<selectOption>(); 
        sortedSelectOptions.addAll(selectOptionSortByLabel(lessSelectOption));
        sortedSelectOptions.add(pivotValue);
        sortedSelectOptions.addAll(selectOptionSortByLabel(greaterSelectOption));
        return SortedSelectOptions;
    } // selectOptionSortByLabel

    public static list<selectOption> selectOptionSortByValue(list<selectOption>
                                                            selectOptionsToSort){
        if(selectOptionsToSort == null || selectOptionsToSort.size() <= 1){
            return selectOptionsToSort;
        }       
        List<SelectOption> lessSelectOption = new List<SelectOption>();
        List<SelectOption> greaterSelectOption = new List<SelectOption>();
        integer pivot = selectOptionsToSort.size() / 2;
         
        //save the pivot and remove it from the selectOption list
        SelectOption pivotValue = selectOptionsToSort[pivot]; 
        selectOptionsToSort.remove(pivot);
        for(selectOption SO : selectOptionsToSort){
            if(SO.getValue() <= pivotValue.getValue()){
                lessSelectOption.add(SO);
            }else if(SO.getValue() > pivotValue.getValue()){
                greaterSelectOption.add(SO);   
            }
        }
        list<selectOption> SortedSelectOptions = new list<selectOption>(); 
        SortedSelectOptions.addAll(selectOptionSortByValue(lessSelectOption));
        SortedSelectOptions.add(pivotValue);
        SortedSelectOptions.addAll(selectOptionSortByValue(greaterSelectOption));
        return SortedSelectOptions;
    } // selectOptionSortByValue
    
    static testMethod Void TestSortSelectOptions() {
    	
    	// Create a select Option to use as test data
    	List<SelectOption> AlphaSelectOption = new List<SelectOption>();
    	AlphaSelectOption.add(new SelectOption('C','1'));
    	AlphaSelectOption.add(new SelectOption('B','2'));
    	AlphaSelectOption.add(new SelectOption('A','3'));
    	
		AlphaSelectOption = SortSelectOptions.selectOptionSortByValue(AlphaSelectOption);		
		system.assert(AlphaSelectOption.get(0).getValue() == 'A');
		
		AlphaSelectOption =SortSelectOptions.selectOptionSortByLabel(AlphaSelectOption);
		system.assert(AlphaSelectOption.get(0).getLabel() == '1');
		
    } // TestSortSelectOptions
    
} // end class