@isTest
private class ClasificadorConversacionesTest {

    @isTest
    static void testValidJson() {
        String jsonString = '{"Subject": "Consulta", "Description": "Desc", "Summary": "Sum", "Area": "Soporte", "TipoServicio": "Técnico", "Opcion": "Red", "Subcategoria": "WiFi"}';
        
        ClasificadorConversacionesDeserializer.FlowInput input = new ClasificadorConversacionesDeserializer.FlowInput();
        input.jsonString = jsonString;
        
        List<ClasificadorConversacionesDeserializer.FlowInput> inputs = new List<ClasificadorConversacionesDeserializer.FlowInput>{input};
        
        Test.startTest();
        List<ClasificadorConversacionesDeserializer.FlowOutput> outputs = ClasificadorConversacionesDeserializer.deserializeJson(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Debe retornar 1 output');
        System.assertEquals('Consulta', outputs[0].Subject);
        System.assertEquals('Desc', outputs[0].Description);
        System.assertEquals('Sum', outputs[0].Summary);
        System.assertEquals('Soporte', outputs[0].Area);
        System.assertEquals('Técnico', outputs[0].TipoServicio);
        System.assertEquals('Red', outputs[0].Opcion);
        System.assertEquals('WiFi', outputs[0].Subcategoria);
    }

    @isTest
    static void testMarkdownJson() {
        String jsonString = '```json\n{"Subject": "Consulta Markdown", "Area": "Ventas"}\n```';
        
        ClasificadorConversacionesDeserializer.FlowInput input = new ClasificadorConversacionesDeserializer.FlowInput();
        input.jsonString = jsonString;
        
        List<ClasificadorConversacionesDeserializer.FlowInput> inputs = new List<ClasificadorConversacionesDeserializer.FlowInput>{input};
        
        Test.startTest();
        List<ClasificadorConversacionesDeserializer.FlowOutput> outputs = ClasificadorConversacionesDeserializer.deserializeJson(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Debe retornar 1 output');
        System.assertEquals('Consulta Markdown', outputs[0].Subject);
        System.assertEquals('Ventas', outputs[0].Area);
    }

    @isTest
    static void testInvalidJson() {
        String jsonString = '{invalid_json}';
        
        ClasificadorConversacionesDeserializer.FlowInput input = new ClasificadorConversacionesDeserializer.FlowInput();
        input.jsonString = jsonString;
        
        List<ClasificadorConversacionesDeserializer.FlowInput> inputs = new List<ClasificadorConversacionesDeserializer.FlowInput>{input};
        
        Test.startTest();
        List<ClasificadorConversacionesDeserializer.FlowOutput> outputs = ClasificadorConversacionesDeserializer.deserializeJson(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Debe retornar 1 output');
        System.assertEquals('Escalación desde Asistente Virtual', outputs[0].Subject);
        System.assertEquals('Error de procesamiento en la IA durante la escalación.', outputs[0].Summary);
        System.assertEquals('Atención a clientes', outputs[0].Area);
        System.assertEquals('Otros', outputs[0].TipoServicio);
    }
    
    @isTest
    static void testEmptyJson() {
        ClasificadorConversacionesDeserializer.FlowInput input = new ClasificadorConversacionesDeserializer.FlowInput();
        input.jsonString = '';
        
        List<ClasificadorConversacionesDeserializer.FlowInput> inputs = new List<ClasificadorConversacionesDeserializer.FlowInput>{input};
        
        Test.startTest();
        List<ClasificadorConversacionesDeserializer.FlowOutput> outputs = ClasificadorConversacionesDeserializer.deserializeJson(inputs);
        Test.stopTest();
        
        System.assertEquals(1, outputs.size(), 'Debe retornar 1 output');
        System.assertEquals(null, outputs[0].Subject);
    }
}