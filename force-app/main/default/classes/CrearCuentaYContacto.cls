/**
 * @description Invocable Apex para crear una nueva Account (empresa o centro médico)
 *              y un Contact asociado a ella cuando el agente detecta que el usuario
 *              no existe en el CRM.
 *
 * @author      Overcome Agent
 * @version     1.0
 */
public with sharing class CrearCuentaYContacto {

    /**
     * @description Método invocable principal llamado desde el Flow / Agentforce.
     * @param requests Lista de solicitudes con los datos del nuevo cliente.
     * @return Lista de respuestas con los IDs creados y mensaje de confirmación.
     */
    @InvocableMethod(
        label='Crear Cuenta y Contacto'
        description='Crea una nueva Account (empresa o centro médico) y un Contact asociado en Salesforce cuando el cliente no existe en el CRM. Evita duplicados verificando el nombre de la empresa y el correo electrónico.'
        category='Overcome Agent'
    )
    public static List<CreacionResponse> crearCuentaYContacto(List<CreacionRequest> requests) {
        CreacionRequest req = requests[0];
        CreacionResponse resp = new CreacionResponse();

        // ── Validaciones básicas ────────────────────────────────────────────
        if (String.isBlank(req.tipoUsuario)) {
            resp.exitoso       = false;
            resp.mensajeResult = 'El tipo de usuario (Médico o Asistente) es requerido.';
            return new List<CreacionResponse>{ resp };
        }
        if (String.isBlank(req.contactEmail)) {
            resp.exitoso       = false;
            resp.mensajeResult = 'El correo electrónico es requerido.';
            return new List<CreacionResponse>{ resp };
        }
        if (String.isBlank(req.contactFirstName) && String.isBlank(req.contactLastName)) {
            resp.exitoso       = false;
            resp.mensajeResult = 'El nombre del contacto es requerido.';
            return new List<CreacionResponse>{ resp };
        }
        if (String.isBlank(req.contactPhone)) {
            resp.exitoso       = false;
            resp.mensajeResult = 'El número de teléfono es requerido.';
            return new List<CreacionResponse>{ resp };
        }

        String emailNormalizado = req.contactEmail.trim().toLowerCase();

        // ── Verificar duplicados ────────────────────────────────────────────
        // 1. ¿Ya existe un Contact con ese email?
        List<Contact> contactoExistente = [
            SELECT Id, Name FROM Contact
            WHERE Email = :emailNormalizado
            LIMIT 1
        ];
        if (!contactoExistente.isEmpty()) {
            resp.exitoso       = false;
            resp.contactId     = contactoExistente[0].Id;
            resp.mensajeResult = 'Ya existe un registro con el correo ' + req.contactEmail + '. El contacto ya está registrado en el sistema.';
            return new List<CreacionResponse>{ resp };
        }

        // 2. Determinar el nombre de la Account según el rol
        String nombreCuenta = '';
        if (req.tipoUsuario == 'Asistente') {
            nombreCuenta = 'Asistentes por Asignar';
        } else {
            // Médico
            if (String.isBlank(req.accountName)) {
                resp.exitoso       = false;
                resp.mensajeResult = 'El nombre de la empresa o consultorio es requerido para los médicos.';
                return new List<CreacionResponse>{ resp };
            }
            if (String.isBlank(req.sexo)) {
                resp.exitoso       = false;
                resp.mensajeResult = 'El sexo es requerido para los médicos.';
                return new List<CreacionResponse>{ resp };
            }
            if (String.isBlank(req.especialidad)) {
                resp.exitoso       = false;
                resp.mensajeResult = 'La especialidad es requerida para los médicos.';
                return new List<CreacionResponse>{ resp };
            }
            nombreCuenta = req.accountName.trim();
        }

        // 3. ¿Ya existe una Account con ese nombre?
        List<Account> cuentaExistente = [
            SELECT Id, Name FROM Account
            WHERE Name = :nombreCuenta
            LIMIT 1
        ];

        Account cuenta;
        if (!cuentaExistente.isEmpty()) {
            // Reutilizar la Account existente
            cuenta = cuentaExistente[0];
        } else {
            // Crear nueva Account
            cuenta = new Account(
                Name        = nombreCuenta,
                Type        = 'Customer',
                Description = 'Cuenta creada a través del Agente Virtual Overcome.'
            );
            insert cuenta;
        }

        // ── Crear Contact ────────────────────────────────────────────────────
        Contact nuevoContacto = new Contact(
            AccountId = cuenta.Id,
            FirstName = String.isNotBlank(req.contactFirstName) ? req.contactFirstName.trim() : '',
            LastName  = String.isNotBlank(req.contactLastName)  ? req.contactLastName.trim()  : nombreCuenta,
            Email     = emailNormalizado,
            Phone     = String.isNotBlank(req.contactPhone) ? req.contactPhone.trim() : '',
            Tipo_de_Usuario__c = req.tipoUsuario,
            Sexo__c = req.sexo,
            Especialidad__c = req.especialidad,
            Pin_Clinica__c = req.pinClinica,
            Acepta_Tratamiento_Datos__c = true,
            Fecha_Aceptacion_Datos__c = System.now()
        );
        insert nuevoContacto;

        // ── Construir respuesta ──────────────────────────────────────────────
        resp.exitoso    = true;
        resp.accountId  = cuenta.Id;
        resp.contactId  = nuevoContacto.Id;
        resp.mensajeResult =
            '¡Perfecto! He registrado a ' + nuevoContacto.FirstName +
            ' de ' + cuenta.Name +
            ' en nuestro sistema. A partir de ahora podrás acceder fácilmente con tu correo ' +
            req.contactEmail + '. ¿En qué más te puedo ayudar?';

        return new List<CreacionResponse>{ resp };
    }

    // ─── Clases de Request / Response ────────────────────────────────────────

    public class CreacionRequest {
        @InvocableVariable(
            required=false
            label='Tipo de Usuario'
            description='Ruta de registro: "Médico" o "Asistente".'
        )
        public String tipoUsuario;

        @InvocableVariable(
            required=false
            label='Nombre de la Empresa o Centro Médico'
            description='Razón social o nombre comercial de la empresa o centro médico a registrar como Account en Salesforce.'
        )
        public String accountName;

        @InvocableVariable(
            required=false
            label='Nombre del Contacto'
            description='Primer nombre de la persona de contacto a registrar.'
        )
        public String contactFirstName;

        @InvocableVariable(
            required=false
            label='Apellido del Contacto'
            description='Apellido de la persona de contacto a registrar.'
        )
        public String contactLastName;

        @InvocableVariable(
            required=true
            label='Correo Electrónico del Contacto'
            description='Dirección de correo electrónico del contacto. Debe ser única en el sistema.'
        )
        public String contactEmail;

        @InvocableVariable(
            required=true
            label='Número de Teléfono'
            description='Número de teléfono de la persona de contacto a registrar.'
        )
        public String contactPhone;

        @InvocableVariable(
            required=false
            label='Sexo'
            description='Sexo del contacto (requerido para médicos).'
        )
        public String sexo;

        @InvocableVariable(
            required=false
            label='Especialidad'
            description='Especialidad médica del contacto (requerido para médicos).'
        )
        public String especialidad;

        @InvocableVariable(
            required=false
            label='PIN de la Clínica'
            description='PIN de la clínica para asociar a los asistentes.'
        )
        public String pinClinica;
    }

    public class CreacionResponse {
        @InvocableVariable(
            label='Registro Exitoso'
            description='Indica si la creación de la cuenta y contacto fue exitosa.'
        )
        public Boolean exitoso;

        @InvocableVariable(
            label='ID de la Cuenta Creada'
            description='Salesforce Record ID de la Account creada o encontrada.'
        )
        public String accountId;

        @InvocableVariable(
            label='ID del Contacto Creado'
            description='Salesforce Record ID del Contact creado.'
        )
        public String contactId;

        @InvocableVariable(
            label='Mensaje de Resultado'
            description='Mensaje de confirmación o error para mostrar al usuario a través del agente.'
        )
        public String mensajeResult;
    }
}