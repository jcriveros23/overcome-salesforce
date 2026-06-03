@IsTest
public class ClasificadorCasosDeserializerTest {

    @IsTest
    static void testSuccessfulDeserialization() {
        // Preparar JSON limpio
        String jsonInput = '{"Area":"Soporte","TipoServicio":"Bug en versión Web","Opcion":"Agenda","Subcategoria":"Error en sincronización con Google Calendar"}';
        
        ClasificadorCasosDeserializer.FlowInput input = new ClasificadorCasosDeserializer.FlowInput();
        input.jsonString = jsonInput;
        
        Test.startTest();
        List<ClasificadorCasosDeserializer.FlowOutput> outputs = ClasificadorCasosDeserializer.deserializeJson(new List<ClasificadorCasosDeserializer.FlowInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        System.assertEquals('Soporte', outputs[0].Area);
        System.assertEquals('Bug en versión Web', outputs[0].TipoServicio);
        System.assertEquals('Agenda', outputs[0].Opcion);
        System.assertEquals('Error en sincronización con Google Calendar', outputs[0].Subcategoria);
    }
    
    @IsTest
    static void testSanitizeMarkdownBlock() {
        // Preparar JSON con bloques markdown
        String jsonInput = '```json\n{"Area":"Atención a clientes","TipoServicio":"Dudas de funcionamiento del sistema","Opcion":"Facturación","Subcategoria":"Personalización de conceptos"}\n```';
        
        ClasificadorCasosDeserializer.FlowInput input = new ClasificadorCasosDeserializer.FlowInput();
        input.jsonString = jsonInput;
        
        Test.startTest();
        List<ClasificadorCasosDeserializer.FlowOutput> outputs = ClasificadorCasosDeserializer.deserializeJson(new List<ClasificadorCasosDeserializer.FlowInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        System.assertEquals('Atención a clientes', outputs[0].Area);
        System.assertEquals('Dudas de funcionamiento del sistema', outputs[0].TipoServicio);
        System.assertEquals('Facturación', outputs[0].Opcion);
        System.assertEquals('Personalización de conceptos', outputs[0].Subcategoria);
    }
    
    @IsTest
    static void testExceptionHandling() {
        // Preparar JSON malformado e inválido
        String jsonInput = '{invalid_json:';
        
        ClasificadorCasosDeserializer.FlowInput input = new ClasificadorCasosDeserializer.FlowInput();
        input.jsonString = jsonInput;
        
        Test.startTest();
        List<ClasificadorCasosDeserializer.FlowOutput> outputs = ClasificadorCasosDeserializer.deserializeJson(new List<ClasificadorCasosDeserializer.FlowInput>{input});
        Test.stopTest();
        
        System.assertEquals(1, outputs.size());
        // Debe rellenar con los valores de fallback por defecto ante errores
        System.assertEquals('Atención a clientes', outputs[0].Area);
        System.assertEquals('Otros', outputs[0].TipoServicio);
        System.assertEquals('Comentarios generales no clasificados en las categorías anteriores', outputs[0].Opcion);
        System.assertEquals('', outputs[0].Subcategoria);
    }
}
