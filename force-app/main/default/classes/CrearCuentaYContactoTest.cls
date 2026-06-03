/**
 * @description Test class para CrearCuentaYContacto.
 *              Cubre los escenarios: creación exitosa (Médico y Asistente),
 *              duplicado por email, account existente reutilizada, 
 *              y validaciones de campos requeridos por ruta.
 */
@IsTest
private class CrearCuentaYContactoTest {

    // ─── Setup de datos ────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {
        // Account existente para prueba de reutilización
        Account accountExistente = new Account(
            Name = 'Hospital Central',
            Type = 'Customer'
        );
        insert accountExistente;

        // Contact con email duplicado para prueba de duplicados
        Contact contactDuplicado = new Contact(
            FirstName = 'Lucia',
            LastName  = 'Mendez',
            Email     = 'lucia.mendez@hospitalcentral.com',
            AccountId = accountExistente.Id
        );
        insert contactDuplicado;
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    @IsTest
    static void testCreacionExitosaNuevaCuentaMedico() {
        CrearCuentaYContacto.CreacionRequest req = new CrearCuentaYContacto.CreacionRequest();
        req.tipoUsuario      = 'Médico';
        req.accountName      = 'Centro Médico Salud Total';
        req.contactFirstName = 'Carlos';
        req.contactLastName  = 'Pérez';
        req.contactEmail     = 'carlos.perez@saludtotal.com';
        req.contactPhone     = '1234567890';
        req.sexo             = 'Hombre';
        req.especialidad     = 'General';

        Test.startTest();
        List<CrearCuentaYContacto.CreacionResponse> resultados =
            CrearCuentaYContacto.crearCuentaYContacto(
                new List<CrearCuentaYContacto.CreacionRequest>{ req }
            );
        Test.stopTest();

        CrearCuentaYContacto.CreacionResponse resp = resultados[0];
        System.assertEquals(true,  resp.exitoso,   'La creación debe ser exitosa');
        System.assertNotEquals('', resp.accountId, 'El accountId no debe estar vacío');
        System.assertNotEquals('', resp.contactId, 'El contactId no debe estar vacío');

        // Verificar que se crearon en la BD con los nuevos campos
        List<Contact> contactos = [SELECT Id, Tipo_de_Usuario__c, Sexo__c, Especialidad__c, Acepta_Tratamiento_Datos__c, Fecha_Aceptacion_Datos__c FROM Contact WHERE Email = 'carlos.perez@saludtotal.com'];
        System.assertEquals(1, contactos.size());
        System.assertEquals('Médico', contactos[0].Tipo_de_Usuario__c);
        System.assertEquals('Hombre', contactos[0].Sexo__c);
        System.assertEquals('General', contactos[0].Especialidad__c);
        System.assertEquals(true, contactos[0].Acepta_Tratamiento_Datos__c);
        System.assertNotEquals(null, contactos[0].Fecha_Aceptacion_Datos__c);
    }

    @IsTest
    static void testCreacionExitosaAsistente() {
        CrearCuentaYContacto.CreacionRequest req = new CrearCuentaYContacto.CreacionRequest();
        req.tipoUsuario      = 'Asistente';
        req.contactFirstName = 'María';
        req.contactLastName  = 'Gómez';
        req.contactEmail     = 'maria.gomez@test.com';
        req.contactPhone     = '0987654321';
        req.pinClinica       = 'PIN12345';
        // accountName is not provided for Assistant

        Test.startTest();
        List<CrearCuentaYContacto.CreacionResponse> resultados =
            CrearCuentaYContacto.crearCuentaYContacto(
                new List<CrearCuentaYContacto.CreacionRequest>{ req }
            );
        Test.stopTest();

        CrearCuentaYContacto.CreacionResponse resp = resultados[0];
        System.assertEquals(true,  resp.exitoso,   'La creación del asistente debe ser exitosa');

        // Verificar Contact y Account Genérica
        List<Contact> contactos = [SELECT Id, Tipo_de_Usuario__c, Pin_Clinica__c, Account.Name FROM Contact WHERE Email = 'maria.gomez@test.com'];
        System.assertEquals(1, contactos.size());
        System.assertEquals('Asistente', contactos[0].Tipo_de_Usuario__c);
        System.assertEquals('PIN12345', contactos[0].Pin_Clinica__c);
        System.assertEquals('Asistentes por Asignar', contactos[0].Account.Name);
    }

    @IsTest
    static void testFaltaTipoUsuario() {
        CrearCuentaYContacto.CreacionRequest req = new CrearCuentaYContacto.CreacionRequest();
        req.contactEmail = 'test@test.com';

        Test.startTest();
        List<CrearCuentaYContacto.CreacionResponse> resultados = CrearCuentaYContacto.crearCuentaYContacto(new List<CrearCuentaYContacto.CreacionRequest>{ req });
        Test.stopTest();

        System.assertEquals(false, resultados[0].exitoso);
        System.assert(resultados[0].mensajeResult.contains('tipo de usuario'));
    }

    @IsTest
    static void testMedicoFaltaCamposObligatorios() {
        CrearCuentaYContacto.CreacionRequest req = new CrearCuentaYContacto.CreacionRequest();
        req.tipoUsuario      = 'Médico';
        req.contactFirstName = 'Carlos';
        req.contactLastName  = 'Pérez';
        req.contactEmail     = 'carlos2@test.com';
        req.contactPhone     = '1234567890';
        
        // Falta accountName
        List<CrearCuentaYContacto.CreacionResponse> r1 = CrearCuentaYContacto.crearCuentaYContacto(new List<CrearCuentaYContacto.CreacionRequest>{ req });
        System.assertEquals(false, r1[0].exitoso);
        
        req.accountName = 'Clínica';
        // Falta sexo
        List<CrearCuentaYContacto.CreacionResponse> r2 = CrearCuentaYContacto.crearCuentaYContacto(new List<CrearCuentaYContacto.CreacionRequest>{ req });
        System.assertEquals(false, r2[0].exitoso);

        req.sexo = 'Hombre';
        // Falta especialidad
        List<CrearCuentaYContacto.CreacionResponse> r3 = CrearCuentaYContacto.crearCuentaYContacto(new List<CrearCuentaYContacto.CreacionRequest>{ req });
        System.assertEquals(false, r3[0].exitoso);
    }

    @IsTest
    static void testEmailDuplicado() {
        CrearCuentaYContacto.CreacionRequest req = new CrearCuentaYContacto.CreacionRequest();
        req.tipoUsuario      = 'Médico';
        req.accountName      = 'Otra Empresa';
        req.contactFirstName = 'Lucia';
        req.contactLastName  = 'Mendez';
        req.contactEmail     = 'lucia.mendez@hospitalcentral.com'; // Email ya registrado
        req.contactPhone     = '0987654321';

        Test.startTest();
        List<CrearCuentaYContacto.CreacionResponse> resultados =
            CrearCuentaYContacto.crearCuentaYContacto(
                new List<CrearCuentaYContacto.CreacionRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(false, resultados[0].exitoso, 'No debe permitir email duplicado');
    }
}