import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
          'Términos de Servicio',
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
                        Icons.store,
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
              'Términos de Servicio',
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

            // Contenido de términos de servicio
            _buildSection(
              '1. ACEPTACIÓN DE LOS TÉRMINOS',
              'Al acceder y utilizar nuestra aplicación móvil de comercio electrónico, usted acepta cumplir con estos términos de servicio. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestros servicios.',
            ),

            _buildSection(
              '2. DESCRIPCIÓN DEL SERVICIO',
              'Nuestra aplicación es una plataforma de comercio electrónico que permite a los usuarios navegar, seleccionar y comprar productos de moda y accesorios. Ofrecemos una experiencia de compra segura y conveniente desde dispositivos móviles.',
            ),

            _buildSection(
              '3. REGISTRO Y CUENTA DE USUARIO',
              'Para realizar compras, debe crear una cuenta proporcionando información precisa y actualizada. Es responsable de mantener la confidencialidad de sus credenciales de acceso y de todas las actividades que ocurran bajo su cuenta.',
            ),

            _buildSection(
              '4. USO APROPIADO DEL SERVICIO',
              'Usted se compromete a utilizar nuestros servicios únicamente para fines legales y apropiados. No debe usar la aplicación para actividades fraudulentas, spam, o cualquier comportamiento que pueda dañar la funcionalidad del servicio.',
            ),

            _buildSection(
              '5. PRODUCTOS Y DISPONIBILIDAD',
              'Los productos mostrados están sujetos a disponibilidad. Nos esforzamos por mantener información precisa sobre nuestros productos, pero no podemos garantizar que todas las descripciones, imágenes o especificaciones estén completamente actualizadas.',
            ),

            _buildSection(
              '6. PRECIOS Y FACTURACIÓN',
              'Todos los precios están expresados en la moneda local y pueden cambiar sin previo aviso. Los precios finales incluyen impuestos aplicables. Nos reservamos el derecho de corregir errores de precio en cualquier momento.',
            ),

            _buildSection(
              '7. PROCESO DE PEDIDOS',
              'Al realizar un pedido, usted hace una oferta para comprar los productos seleccionados. Nos reservamos el derecho de aceptar o rechazar cualquier pedido por razones de disponibilidad, errores en la información del producto, o problemas de verificación de pago.',
            ),

            _buildSection(
              '8. LIMITACIÓN DE RESPONSABILIDAD',
              'En la medida permitida por la ley, no seremos responsables por daños indirectos, incidentales, especiales o consecuentes que puedan surgir del uso de nuestros servicios o de la imposibilidad de utilizarlos.',
            ),

            _buildSection(
              '9. PROPIEDAD INTELECTUAL',
              'Todo el contenido de la aplicación, incluyendo pero no limitado a textos, gráficos, logos, iconos, imágenes, clips de audio, descargas digitales y compilaciones de datos, es propiedad de la empresa y está protegido por las leyes de derechos de autor.',
            ),

            _buildSection(
              '10. TERMINACIÓN DEL SERVICIO',
              'Podemos terminar o suspender su cuenta y acceso al servicio inmediatamente, sin previo aviso o responsabilidad, por cualquier razón, incluyendo sin limitación si usted incumple los términos de servicio.',
            ),

            _buildSection(
              '11. MODIFICACIONES A LOS TÉRMINOS',
              'Nos reservamos el derecho, a nuestra sola discreción, de modificar o reemplazar estos términos en cualquier momento. Si una revisión es material, intentaremos proporcionar al menos 30 días de aviso antes de que los nuevos términos entren en vigencia.',
            ),

            _buildSection(
              '12. CONTACTO',
              'Si tiene preguntas sobre estos términos de servicio, puede contactarnos a través de los canales de soporte disponibles en la aplicación o mediante nuestro correo electrónico de atención al cliente.',
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
