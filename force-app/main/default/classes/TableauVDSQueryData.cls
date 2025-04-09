public with sharing class TableauVDSQueryData {
    
    /**
     * Invocable method to query metadata from Tableau's Virtual Data Source API.
     * This method is structured for Prompt Builder.
     */
    
    // Wrapper classes for structured input and output
    // 
    
    
    public class RequestWrapper {
        @InvocableVariable
        public String vdsPayload;  // Assumes vdsPayload is a valid JSON string in the specified format, but will accommodate extra characters before first bracket and after last bracket
        
        @InvocableVariable
        public String token;
        
        @InvocableVariable
        public String dataSourceLUID;
        
        @InvocableVariable
        public String vdsQueryURL;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public String resultText; // Returns the API response as resultText
        
        @InvocableVariable
        public String status; // Indicates success or error status
    }
    
    public static String extractContentBetweenFirstAndLastAccolades(String inputString) {
        if (String.isBlank(inputString)) {
            return null;
        }
        
        Integer firstOpenAccoladeIndex = inputString.indexOf('{');
        Integer lastCloseAccoladeIndex = inputString.lastIndexOf('}');
        
        if (firstOpenAccoladeIndex == -1 || lastCloseAccoladeIndex == -1 || lastCloseAccoladeIndex <= firstOpenAccoladeIndex) {
            return inputString; // No valid accolades or invalid order.
        }
        
        return inputString.substring(firstOpenAccoladeIndex, lastCloseAccoladeIndex +1);
    }
    
    @InvocableMethod(label='Query Tableau Metadata' description='Queries metadata from Tableau Virtual Data Source')
    public static List<ResponseWrapper> queryMetadata(List<RequestWrapper> requestList) {
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
        
        for (RequestWrapper request : requestList) {
            
            ResponseWrapper responseWrapper = new ResponseWrapper();
            
            try {
                //
                // call the headless-bi endpoint
                //
                
                Http http = new Http();
                HttpRequest httpRequest = new HttpRequest();
                httpRequest.setEndpoint(request.vdsQueryURL);
                httpRequest.setMethod('POST');
                httpRequest.setHeader('Content-Type', 'application/json');
                
                // Directly use the provided vdsPayload as the payload for the API request
                String extractedPayload = request.vdsPayload;
                
                // Set headers
                httpRequest.setHeader('X-Tableau-Auth', request.token );
                httpRequest.setTimeout(120000);
                
                Map<String, Object> datasourceLuid = new Map<String, Object>{
                    'datasourceLuid' => request.dataSourceLUID
                        };
                            
                            Map<String, Object> payload = new Map<String, Object>{ 'datasource' => datasourceLuid };
                                
                                // extracting the query from the payload
                                Object result = JSON.deserializeUntyped(extractContentBetweenFirstAndLastAccolades(extractedPayload));
                
                if (result instanceof Map<String, Object>) {
                    Map<String, Object> resultMap = (Map<String, Object>)result;
                    payload.put('query', resultMap.get('query'));
                } else {
                    // handle error
                }
                
                httpRequest.setBody(JSON.serialize(payload));
                
                try {
                    // Execute the callout
                    HttpResponse httpResponse = http.send(httpRequest);
                    
                    if (httpResponse.getStatusCode() == 200) {
                        // Set the API response content as resultText
                        // Parse the response data
                        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(httpResponse.getBody());
                        
                        if (responseData.containsKey('data')) {
                            responseWrapper.resultText = JSON.serialize(responseData.get('data'));
                            responseWrapper.status = 'Success';
                        } else {
                            responseWrapper.resultText = 'Error: Data key not found in the response';
                        }
                    } else {
                        responseWrapper.resultText = 'Failed getting data with status code: ' + httpResponse.getStatusCode() + ' body:' + httpResponse.getBody();
                        responseWrapper.status = 'Failed';
                    }
                    responseList.add(responseWrapper);
                    
                } catch (Exception e) {
                    // Handle exceptions and set response as failed
                    responseWrapper.resultText = 'Exception getting data: ' + e.getMessage();
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