import 'package:flutter/material.dart';

class HistorialCompras extends StatelessWidget {
  const HistorialCompras({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> compras = [
      {
        "nombre": "Tenis Nike",
        "precio": "10,99 L",
        "fecha": "Compra el 7 septiembre",
        "imagen": "assets/img/shoes.jpg",
      },
      {
        "nombre": "Tenis Nike",
        "precio": "10,99 L",
        "fecha": "Compra el 7 septiembre",
        "imagen": "assets/img/shoes.jpg",
      },
      {
        "nombre": "Tenis Nike",
        "precio": "10,99 L",
        "fecha": "Compra el 7 septiembre",
        "imagen": "assets/img/shoes.jpg",
      },
      {
        "nombre": "Tenis Nike",
        "precio": "10,99 L",
        "fecha": "Compra el 7 septiembre",
        "imagen": "assets/img/shoes.jpg",
      },
      {
        "nombre": "Tenis Nike",
        "precio": "10,99 L",
        "fecha": "Compra el 7 septiembre",
        "imagen": "assets/img/shoes.jpg",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Historial de compras",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: compras.length,
              itemBuilder: (context, index) {
                final compra = compras[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      // Imagen producto
                      Container(
                        width: 100,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(compra["imagen"]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Nombre y fecha
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              compra["nombre"],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              compra["fecha"],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Precio
                      Text(
                        compra["precio"],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Total gastado
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerRight,
            child: const Text(
              "Total gastado: 54,95 L",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
        ],
      ),
    );
  }
}
