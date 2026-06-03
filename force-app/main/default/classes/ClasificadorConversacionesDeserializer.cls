public class ClasificadorConversacionesDeserializer {
    
    public class FlowInput {
        @InvocableVariable(required=true label='JSON de la IA (Conversacional)' description='El JSON string retornado por el prompt Flex de Agentforce')
        public String jsonString;
    }
    
    public class FlowOutput {
        @InvocableVariable(label='Subject' description='Asunto generado por la IA')
        public String Subject;
        
        @InvocableVariable(label='Description' description='Descripción detallada generada por la IA')
        public String Description;
        
        @InvocableVariable(label='Summary' description='Resumen de la interacción y motivo de escalación')
        public String Summary;
        
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
        label='Deserializar Tipificación Conversacional (IA)' 
        description='Parsea el JSON de tipificación de conversaciones de Agentforce a variables de Flow, incluyendo Asunto y Resumen.'
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
                    
                    // Mapeo de las variables de contexto conversacional
                    out.Subject = (String) rawMap.get('Subject');
                    out.Description = (String) rawMap.get('Description');
                    out.Summary = (String) rawMap.get('Summary');
                    
                    // Mapeo de la tipificación
                    out.Area = (String) rawMap.get('Area');
                    out.TipoServicio = (String) rawMap.get('TipoServicio');
                    out.Opcion = (String) rawMap.get('Opcion');
                    out.Subcategoria = (String) rawMap.get('Subcategoria');
                }
            } catch (Exception e) {
                // Control preventivo ante JSONs malformados para asegurar la escalación
                out.Subject = 'Escalación desde Asistente Virtual';
                out.Description = 'No se pudo procesar la descripción automática por un error de formato. Favor de leer la transcripción adjunta.';
                out.Summary = 'Error de procesamiento en la IA durante la escalación.';
                out.Area = 'Atención a clientes';
                out.TipoServicio = 'Otros';
                out.Opcion = 'Comentarios generales no clasificados en las categorías anteriores';
                out.Subcategoria = '';
                
                System.debug('Error al deserializar JSON conversacional de IA: ' + e.getMessage());
            }
            outputs.add(out);
        }
        return outputs;
    }
}