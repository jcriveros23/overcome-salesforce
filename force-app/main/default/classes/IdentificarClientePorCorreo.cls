/**
 * @description Invocable Apex para identificar un cliente existente en Salesforce
 *              por su correo electrónico. Busca el Contact y retorna los datos
 *              de la Account padre para personalizar el saludo del agente.
 *
 * @author      Overcome Agent
 * @version     1.0
 */
public with sharing class IdentificarClientePorCorreo {

    /**
     * @description Método invocable principal llamado desde el Flow / Agentforce.
     * @param requests Lista de solicitudes (Agentforce siempre envía una lista).
     * @return Lista de respuestas con los datos del cliente.
     */
    @InvocableMethod(
        label='Identificar Cliente por Correo'
        description='Busca un Contact en Salesforce por su correo electrónico y retorna sus datos y los de su empresa para personalizar el saludo del agente.'
        category='Overcome Agent'
    )
    public static List<ClienteResponse> identificarCliente(List<ClienteRequest> requests) {
        ClienteRequest req = requests[0];
        ClienteResponse resp = new ClienteResponse();

        if (String.isBlank(req.emailAddress)) {
            resp.contactFound = false;
            resp.mensajeBienvenida = 'No se proporcionó un correo electrónico.';
            return new List<ClienteResponse>{ resp };
        }

        String emailNormalizado = req.emailAddress.trim().toLowerCase();

        // Buscar Contact por Email (campo estándar)
        List<Contact> contactos = [
            SELECT
                Id,
                FirstName,
                LastName,
                Name,
                Email,
                Account.Id,
                Account.Name,
                Account.Type
            FROM Contact
            WHERE Email = :emailNormalizado
              AND IsDeleted = false
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!contactos.isEmpty()) {
            Contact c = contactos[0];
            resp.contactFound = true;
            resp.contactId    = c.Id;
            resp.contactName  = c.Name;
            resp.accountId    = c.Account != null ? String.valueOf(c.Account.Id) : null;
            resp.accountName  = c.Account != null ? c.Account.Name : null;

            // Construir mensaje de bienvenida personalizado
            String saludo = '¡Hola, ' + c.FirstName + '! ';
            if (c.Account != null && String.isNotBlank(c.Account.Name)) {
                saludo += 'Es un gusto verte de nuevo. Te damos la bienvenida de parte de ' + c.Account.Name + '.';
            } else {
                saludo += 'Es un gusto verte de nuevo. ¿En qué te puedo ayudar hoy?';
            }
            resp.mensajeBienvenida = saludo;

        } else {
            resp.contactFound      = false;
            resp.contactId         = '';
            resp.contactName       = '';
            resp.accountId         = '';
            resp.accountName       = '';
            resp.mensajeBienvenida = 'No encontré ningún registro asociado a ese correo electrónico.';
        }

        return new List<ClienteResponse>{ resp };
    }

    // ─── Clases de Request / Response ────────────────────────────────────────

    public class ClienteRequest {
        @InvocableVariable(
            required=true
            label='Correo Electrónico'
            description='Correo electrónico proporcionado por el usuario para identificarlo en el CRM.'
        )
        public String emailAddress;
    }

    public class ClienteResponse {
        @InvocableVariable(
            label='Cliente Encontrado'
            description='Indica si se encontró un registro de Contact con el correo proporcionado.'
        )
        public Boolean contactFound;

        @InvocableVariable(
            label='ID del Contacto'
            description='Salesforce Record ID del Contact encontrado.'
        )
        public String contactId;

        @InvocableVariable(
            label='Nombre del Contacto'
            description='Nombre completo del Contact (FirstName + LastName).'
        )
        public String contactName;

        @InvocableVariable(
            label='ID de la Cuenta'
            description='Salesforce Record ID de la Account a la que pertenece el Contact.'
        )
        public String accountId;

        @InvocableVariable(
            label='Nombre de la Empresa'
            description='Nombre de la Account (empresa o centro médico) asociada al Contact.'
        )
        public String accountName;

        @InvocableVariable(
            label='Mensaje de Bienvenida'
            description='Mensaje personalizado generado para saludar al cliente o informar que no existe.'
        )
        public String mensajeBienvenida;
    }
}