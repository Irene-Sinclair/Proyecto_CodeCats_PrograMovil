import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
        title: const Text(
          'Política de Privacidad',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/img/logo.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),

            // Título principal
            const Text(
              'Política de Privacidad',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Contenido de política de privacidad
            _buildSection(
              '1. INTRODUCCIÓN',
              'Esta Política de Privacidad describe cómo recopilamos, utilizamos, almacenamos y protegemos su información personal cuando utiliza nuestra aplicación móvil de comercio electrónico. Su privacidad es importante para nosotros y nos comprometemos a proteger sus datos personales.',
            ),

            _buildSection(
              '2. INFORMACIÓN QUE RECOPILAMOS',
              'Recopilamos información que usted nos proporciona directamente, como:\n\n• Nombre completo y datos de contacto\n• Dirección de correo electrónico\n• Número de teléfono\n• Dirección de envío y facturación\n• Información de pago (procesada de forma segura)\n• Historial de pedidos y preferencias de compra',
            ),

            _buildSection(
              '3. INFORMACIÓN AUTOMÁTICA',
              'También recopilamos automáticamente cierta información cuando utiliza nuestra aplicación:\n\n• Información del dispositivo (tipo, sistema operativo, versión)\n• Dirección IP y ubicación aproximada\n• Datos de uso de la aplicación\n• Cookies y tecnologías similares\n• Información de análisis y rendimiento',
            ),

            _buildSection(
              '4. CÓMO UTILIZAMOS SU INFORMACIÓN',
              'Utilizamos su información personal para:\n\n• Procesar y completar sus pedidos\n• Proporcionar atención al cliente\n• Personalizar su experiencia de compra\n• Enviar confirmaciones y actualizaciones de pedidos\n• Mejorar nuestros productos y servicios\n• Cumplir con obligaciones legales y regulatorias',
            ),

            _buildSection(
              '5. COMPARTIR INFORMACIÓN',
              'No vendemos, alquilamos ni compartimos su información personal con terceros, excepto en las siguientes circunstancias:\n\n• Con proveedores de servicios que nos ayudan a operar la aplicación\n• Para procesar pagos de forma segura\n• Cuando sea requerido por ley o autoridades competentes\n• Para proteger nuestros derechos y seguridad',
            ),

            _buildSection(
              '6. SEGURIDAD DE DATOS',
              'Implementamos medidas de seguridad técnicas, administrativas y físicas apropiadas para proteger su información personal contra acceso no autorizado, alteración, divulgación o destrucción. Utilizamos encriptación SSL para todas las transacciones sensibles.',
            ),

            _buildSection(
              '7. RETENCIÓN DE DATOS',
              'Conservamos su información personal solo durante el tiempo necesario para cumplir con los propósitos descritos en esta política, a menos que la ley requiera un período de retención más largo. Los datos de transacciones se conservan según los requisitos legales aplicables.',
            ),

            _buildSection(
              '8. SUS DERECHOS',
              'Dependiendo de su ubicación, puede tener los siguientes derechos:\n\n• Acceso a sus datos personales\n• Corrección de información inexacta\n• Eliminación de sus datos personales\n• Portabilidad de datos\n• Oposición al procesamiento\n• Limitación del procesamiento',
            ),

            _buildSection(
              '9. COOKIES Y TECNOLOGÍAS DE SEGUIMIENTO',
              'Utilizamos cookies y tecnologías similares para mejorar la funcionalidad de la aplicación, analizar el uso y personalizar contenido. Puede gestionar las preferencias de cookies a través de la configuración de su dispositivo.',
            ),

            _buildSection(
              '10. TRANSFERENCIAS INTERNACIONALES',
              'Sus datos pueden ser transferidos y procesados en países diferentes al suyo. Cuando esto ocurra, nos aseguramos de que se implementen las salvaguardas adecuadas para proteger su información personal.',
            ),

            _buildSection(
              '11. MENORES DE EDAD',
              'Nuestros servicios no están dirigidos a menores de 18 años. No recopilamos conscientemente información personal de menores. Si descubrimos que hemos recopilado información de un menor, la eliminaremos inmediatamente.',
            ),

            _buildSection(
              '12. CAMBIOS A ESTA POLÍTICA',
              'Podemos actualizar esta Política de Privacidad ocasionalmente. Le notificaremos sobre cambios significativos mediante un aviso en la aplicación o por correo electrónico. Le recomendamos revisar esta política periódicamente.',
            ),

            _buildSection(
              '13. CONTACTO',
              'Si tiene preguntas, inquietudes o solicitudes relacionadas con esta Política de Privacidad o el manejo de sus datos personales, puede contactarnos a través de los canales de atención disponibles en la aplicación.',
            ),

            const SizedBox(height: 30),

            // Botón de aceptar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}
