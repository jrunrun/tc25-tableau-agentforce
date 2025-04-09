public with sharing class TableauGetSession {
 
    /**
     * Invocable method to query metadata from Tableau's Virtual Data Source API.
     * This method is structured for Prompt Builder.
     */
    
    // Wrapper classes for structured input and output
    // 
    
    public class RequestWrapper {
        @InvocableVariable
        public String patName;
        
        @InvocableVariable
        public String patSecret;
        
        @InvocableVariable
        public String getSessionURL;
        
        @InvocableVariable
        public String siteName;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public String token; // Returns the session token
        
        @InvocableVariable
        public String status; // Indicates success or error status
    }
    
    
    @InvocableMethod(label='Query Tableau Metadata' description='Queries metadata from Tableau Virtual Data Source')
    public static List<ResponseWrapper> queryMetadata(List<RequestWrapper> requestList) {
        List<ResponseWrapper> responseList = new List<ResponseWrapper>();
        
        for (RequestWrapper request : requestList) {
            
            // Alexis G 1/7/2024
            // first, obtaining a session from tableau cloud
            //
            
            Http httpAuth = new Http();
            HttpRequest httpRequestAuth = new HttpRequest();
            httpRequestAuth.setEndpoint( request.getSessionURL );
            httpRequestAuth.setMethod('POST');
            String authBody = '<tsRequest>' +
							  '   <credentials personalAccessTokenName="' + request.patName.escapeXml() + '" personalAccessTokenSecret="' + request.patSecret.escapeXml() + '">' +
                			  '     <site contentUrl="' + request.siteName.escapeXml() + '" />' +
            				  '  </credentials>' +
            				  '</tsRequest>';
            httpRequestAuth.setBody( authBody );
            httpRequestAuth.setHeader('content-type', 'application/xml;charset=utf-8');
            httpRequestAuth.setHeader('Accept', 'application/xml');
            
            try {
                
                //
                // authenticate
                //
                HttpResponse httpResponseAuth = httpAuth.send(httpRequestAuth);
                
                // Prepare the response
                ResponseWrapper responseWrapper = new ResponseWrapper();
                
                if (httpResponseAuth.getStatusCode() == 200) {
                
                    // <?xml version="1.0" encoding="UTF-8"?>
                    // <tsResponse version-and-namespace-settings>
                    //   <credentials token="HvZMqFFfQQmOM4L-AZNIQA|5fI6T54OPK1Gn1p4w0RtHv6EkojWRTwq|a946d998-2ead-4894-bb50-1054a91dcab3">
                    //     <site id="9a8b7c6d5-e4f3-a2b1-c0d9-e8f7a6b5c4d" contentUrl=""/>
                    //     <user id="9f9e9d9c-8b8a-8f8e-7d7c-7b7a6f6d6e6d" />
                    //   </credentials>
                    // </tsResponse>
                    
                    // extracting token
                    
                    Dom.Document doc = httpResponseAuth.getBodyDocument();
                    Dom.XmlNode root = doc.getRootElement();
                    
                    String token = 'none';
                    
                    if(root.getName()=='tsResponse') {
                        for(Dom.XmlNode node1: root.getChildElements()) {
                            if(node1.getName()=='credentials') {
                               // store token
                               token = node1.getAttribute( 'token', null );
                            }
                        }
                    }
                    
                    responseWrapper.token = token;
                    responseWrapper.status = 'Success';
                    responseList.add(responseWrapper);
                } else {
                   responseWrapper.token = 'Error getting token: ' + httpResponseAuth.getStatusCode();
                   responseWrapper.status = httpResponseAuth.getBody();
                   responseList.add(responseWrapper);
                }
             } catch (Exception e) {
                 // Handle exceptions and set response as failed
                 ResponseWrapper responseWrapper = new ResponseWrapper();
                 responseWrapper.token = 'Exception getting response is: ' + e.getMessage();
                 responseWrapper.status = 'Exception';
                 responseList.add(responseWrapper);
             }
        }
        
        return responseList;
    }
}