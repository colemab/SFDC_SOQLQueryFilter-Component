This is an example Visual Force component for use on the Salesforce.com platform.

This component can be used to generate the WHERE clause in a SOQL query.  You pass
an object to the component and it uses the schema to only add fields that are
accessible to the user and are filterable in SOQL.

12/05/2012 Update: I have replaced the externally referenced resources with static resources 
                   due to the cachedcommons not being a reliable CDN.  I have left the URL's
				   listed below just in-case you prefer to replace the static resources.

Externally referenced resources:

http://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js
http://cachedcommons.org/cache/jquery-blockui/2.3.3/javascripts/jquery-blockui-min.js
