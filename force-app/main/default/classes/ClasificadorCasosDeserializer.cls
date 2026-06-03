public class ClasificadorCasosDeserializer {
    
    public class FlowInput {
        @InvocableVariable(required=true label='JSON de la IA' description='El JSON string retornado por el prompt de la IA')
        public String jsonString;
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Area' description='Area extraída de la tipificación')
        public String Area;
        
        @InvocableVariable(label='TipoServicio' description='Tipo de Servicio extraído')
        public String TipoServicio;
        
        @InvocableVariable(label='Opcion' description='Opción de servicio extraída')
        public String Opcion;
        
        @InvocableVariable(label='Subcategoria' description='Subcategoría extraída')
        public String Subcategoria;
    }
    
    @InvocableMethod(
        label='Deserializar Tipificación JSON (IA)' 
        description='Parsea el JSON de tipificación de la IA a variables independientes de Salesforce Flow.'
        category='AI Triage'
    )
    public static List<FlowOutput> deserializeJson(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        
        for (FlowInput input : inputs) {
            FlowOutput out = new FlowOutput();
            try {
                if (String.isNotBlank(input.jsonString)) {
                    String cleanJson = input.jsonString.trim();
                    
                    // Eliminar bloques de código markdown (```json o ```) si el LLM los incluye
                    if (cleanJson.startsWith('```')) {
                        cleanJson = cleanJson.replaceAll('(?i)^```json\\s*', '');
                        cleanJson = cleanJson.replaceAll('^```\\s*', '');
                    }
                    if (cleanJson.endsWith('```')) {
                        cleanJson = cleanJson.substringBeforeLast('```');
                    }
                    cleanJson = cleanJson.trim();
                    
                    // Deserializar el JSON plano
                    Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
                    
                    out.Area = (String) rawMap.get('Area');
                    out.TipoServicio = (String) rawMap.get('TipoServicio');
                    out.Opcion = (String) rawMap.get('Opcion');
                    out.Subcategoria = (String) rawMap.get('Subcategoria');
                }
            } catch (Exception e) {
                // Control preventivo ante JSONs malformados para evitar caídas en el Omni-Flow
                out.Area = 'Atención a clientes';
                out.TipoServicio = 'Otros';
                out.Opcion = 'Comentarios generales no clasificados en las categorías anteriores';
                out.Subcategoria = 'N/A';
                System.debug('Error al deserializar JSON de IA: ' + e.getMessage());
            }
            outputs.add(out);
        }
        return outputs;
    }
}