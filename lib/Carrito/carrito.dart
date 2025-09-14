import 'package:flutter/material.dart';

class Carrito extends StatelessWidget {
  const Carrito({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carrito", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Sección de Envío y Pago
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: const Text("ENVÍO"),
                  subtitle: const Text("Añadir dirección de envío"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text("PAGO"),
                  subtitle: const Text("Transferencia"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Lista de artículos
          Expanded(
            child: ListView(
              children: [
                _buildCartItem(
                  imageUrl:
                      "https://via.placeholder.com/80", // cambia por tu imagen
                  title: "Zapatos",
                  subtitle: "Talla 32\nCantidad: 01",
                  price: "10,99 L",
                ),
                _buildCartItem(
                  imageUrl:
                      "https://via.placeholder.com/80", // cambia por tu imagen
                  title: "Camisa",
                  subtitle: "Talla M\nCantidad: 01",
                  price: "8,99 L",
                ),
              ],
            ),
          ),

          // Total y Botón
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total", style: TextStyle(fontSize: 16)),
                    Text("19,98 L", style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    // 👉 Aquí puedes poner la acción al presionar el botón
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Pedido realizado ✅")),
                    );
                  },
                  child: const Text(
                    "Realizar pedido",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Icon(Icons.delete, size: 20, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}
