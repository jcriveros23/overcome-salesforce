/**
 * @description Test class para IdentificarClientePorCorreo.
 *              Cubre los escenarios: cliente existente, cliente inexistente,
 *              email en blanco, y contact sin Account padre.
 */
@IsTest
private class IdentificarClientePorCorreoTest {

    // ─── Setup de datos ────────────────────────────────────────────────────────
    @TestSetup
    static void setupData() {
        // Crear Account de prueba
        Account testAccount = new Account(
            Name = 'Clínica Prueba S.A.S.',
            Type = 'Customer'
        );
        insert testAccount;

        // Crear Contact asociado a la Account
        Contact testContact = new Contact(
            FirstName = 'María',
            LastName  = 'González',
            Email     = 'maria.gonzalez@clinicaprueba.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Crear Contact SIN Account
        Contact contactSinAccount = new Contact(
            FirstName = 'Pedro',
            LastName  = 'Ramírez',
            Email     = 'pedro.ramirez@sinempresa.com'
        );
        insert contactSinAccount;
    }

    // ─── Tests ────────────────────────────────────────────────────────────────

    @IsTest
    static void testClienteExistenteConAccount() {
        IdentificarClientePorCorreo.ClienteRequest req = new IdentificarClientePorCorreo.ClienteRequest();
        req.emailAddress = 'maria.gonzalez@clinicaprueba.com';

        Test.startTest();
        List<IdentificarClientePorCorreo.ClienteResponse> resultados =
            IdentificarClientePorCorreo.identificarCliente(
                new List<IdentificarClientePorCorreo.ClienteRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, resultados.size(), 'Debe retornar exactamente una respuesta');
        IdentificarClientePorCorreo.ClienteResponse resp = resultados[0];

        System.assertEquals(true,  resp.contactFound,  'El cliente debe ser encontrado');
        System.assertNotEquals('', resp.contactId,     'El contactId no debe estar vacío');
        System.assertEquals('María González', resp.contactName, 'El nombre debe coincidir');
        System.assertNotEquals('', resp.accountId,    'El accountId no debe estar vacío');
        System.assertEquals('Clínica Prueba S.A.S.', resp.accountName, 'El nombre de la empresa debe coincidir');
        System.assert(resp.mensajeBienvenida.contains('María'), 'El saludo debe incluir el nombre');
        System.assert(resp.mensajeBienvenida.contains('Clínica Prueba S.A.S.'), 'El saludo debe incluir la empresa');
    }

    @IsTest
    static void testClienteExistenteSinAccount() {
        IdentificarClientePorCorreo.ClienteRequest req = new IdentificarClientePorCorreo.ClienteRequest();
        req.emailAddress = 'pedro.ramirez@sinempresa.com';

        Test.startTest();
        List<IdentificarClientePorCorreo.ClienteResponse> resultados =
            IdentificarClientePorCorreo.identificarCliente(
                new List<IdentificarClientePorCorreo.ClienteRequest>{ req }
            );
        Test.stopTest();

        IdentificarClientePorCorreo.ClienteResponse resp = resultados[0];
        System.assertEquals(true, resp.contactFound, 'El cliente debe ser encontrado');
        System.assertEquals(null, resp.accountId, 'El accountId debe ser null sin Account padre');
        System.assert(resp.mensajeBienvenida.contains('Pedro'), 'El saludo debe incluir el nombre');
    }

    @IsTest
    static void testClienteNoExistente() {
        IdentificarClientePorCorreo.ClienteRequest req = new IdentificarClientePorCorreo.ClienteRequest();
        req.emailAddress = 'noexiste@correo.com';

        Test.startTest();
        List<IdentificarClientePorCorreo.ClienteResponse> resultados =
            IdentificarClientePorCorreo.identificarCliente(
                new List<IdentificarClientePorCorreo.ClienteRequest>{ req }
            );
        Test.stopTest();

        IdentificarClientePorCorreo.ClienteResponse resp = resultados[0];
        System.assertEquals(false, resp.contactFound, 'El cliente NO debe ser encontrado');
        System.assertEquals('',    resp.contactId,    'El contactId debe estar vacío');
        System.assertEquals('',    resp.accountId,    'El accountId debe estar vacío');
    }

    @IsTest
    static void testEmailEnBlanco() {
        IdentificarClientePorCorreo.ClienteRequest req = new IdentificarClientePorCorreo.ClienteRequest();
        req.emailAddress = '';

        Test.startTest();
        List<IdentificarClientePorCorreo.ClienteResponse> resultados =
            IdentificarClientePorCorreo.identificarCliente(
                new List<IdentificarClientePorCorreo.ClienteRequest>{ req }
            );
        Test.stopTest();

        IdentificarClientePorCorreo.ClienteResponse resp = resultados[0];
        System.assertEquals(false, resp.contactFound, 'Con email en blanco debe retornar false');
    }

    @IsTest
    static void testEmailConMayusculas() {
        // Verificar que la búsqueda es case-insensitive
        IdentificarClientePorCorreo.ClienteRequest req = new IdentificarClientePorCorreo.ClienteRequest();
        req.emailAddress = 'MARIA.GONZALEZ@CLINICAPRUEBA.COM';

        Test.startTest();
        List<IdentificarClientePorCorreo.ClienteResponse> resultados =
            IdentificarClientePorCorreo.identificarCliente(
                new List<IdentificarClientePorCorreo.ClienteRequest>{ req }
            );
        Test.stopTest();

        IdentificarClientePorCorreo.ClienteResponse resp = resultados[0];
        System.assertEquals(true, resp.contactFound, 'La búsqueda debe ser case-insensitive');
    }
}