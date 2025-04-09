public with sharing class TableauVDSGetMetadata {
 
    /**
     * Invocable method to query metadata from Tableau's Virtual Data Source API.
     * This method is structured for Prompt Builder.
     */
    
    // Wrapper classes for structured input and output
    public class RequestWrapper {
        @InvocableVariable
        public String token;
        
        @InvocableVariable
        public String dataSourceLUID;
        
        @InvocableVariable
        public String vdsMetadataURL;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public String resultText; // Returns the API response as resultText
        
        @InvocableVariable
        public String status; // Indicates success or error status
    }
    
    @InvocableMethod(label='Query Tableau Metadata' description='Queries metadata from Tableau Virtual Data Source')
    public static List<ResponseWrapper> queryMetadata(List<RequestWrapper> requestList) {
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
        
        for (RequestWrapper request : requestList) {
            
            ResponseWrapper responseWrapper = new ResponseWrapper();
                    
            try {
                //
                // now call the headless-bi endpoint
                // 
                
                Http http = new Http();
                HttpRequest httpRequest = new HttpRequest();
                httpRequest.setEndpoint(request.vdsMetadataURL);
                httpRequest.setMethod('POST');
                httpRequest.setHeader('Content-Type', 'application/json');
                
                // Set headers
                httpRequest.setHeader('X-Tableau-Auth', request.token );
                
                Map<String, Object> datasourceLuid = new Map<String, Object>{
                    'datasourceLuid' => request.dataSourceLUID
                        };
                            
                            Map<String, Object> payload = new Map<String, Object>{ 'datasource' => datasourceLuid };
                                httpRequest.setBody(JSON.serialize(payload));
                
                try {
                    // Execute the callout
                    HttpResponse httpResponse = http.send(httpRequest);
                    
                    if (httpResponse.getStatusCode() == 200) {
                        // Set the API response content as resultText
                        responseWrapper.resultText = httpResponse.getBody();
                        responseWrapper.status = 'Success';
                    } else {
                        responseWrapper.resultText = 'Failed getting metadata with status code: ' + httpResponse.getStatusCode() + ' body:' + httpResponse.getBody();
                        responseWrapper.status = 'Failed';
                    }
                    responseList.add(responseWrapper);
                    
                } catch (Exception e) {
                    // Handle exceptions and set response as failed
                    responseWrapper.resultText = 'Exception getting metadata: ' + e.getMessage();
                    responseWrapper.status = 'Exception';
                    responseList.add(responseWrapper);
                }
            } catch ( Exception e ) {
                // Handle exceptions and set response as failed
                responseWrapper.resultText = 'Exception calling headless-bi: ' + e.getMessage();
                responseWrapper.status = 'Exception';
                responseList.add(responseWrapper);
            }
                  
        }
        
        return responseList;
    }
}