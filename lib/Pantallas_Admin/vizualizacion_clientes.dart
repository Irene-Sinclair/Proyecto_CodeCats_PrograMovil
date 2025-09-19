import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisualizacionClientesScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientCode;
  final String clientPhone;
  final String clientCity;
  final String clientAddress;
  final String clientProfileImage;

  const VisualizacionClientesScreen({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientCode,
    required this.clientPhone,
    required this.clientCity,
    required this.clientAddress,
    required this.clientProfileImage,
  }) : super(key: key);

  @override
  _VisualizacionClientesScreenState createState() =>
      _VisualizacionClientesScreenState();
}

class _VisualizacionClientesScreenState
    extends State<VisualizacionClientesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Sección del avatar y nombre
            _buildProfileHeader(),

            // Sección de información personal
            _buildPersonalInfoSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Perfil del Cliente',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: widget.clientProfileImage.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.clientProfileImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        );
                      },
                    ),
                  )
                : Icon(Icons.person, size: 40, color: Colors.black),
          ),

          SizedBox(height: 16),

          // Nombre del cliente
          Text(
            widget.clientName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.black, size: 20),
              SizedBox(width: 8),
              Text(
                'Información del Cliente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Nombre
          _buildInfoItem(
            icon: Icons.person_outline,
            title: 'Nombre',
            value: widget.clientName.isNotEmpty
                ? widget.clientName
                : 'Sin nombre',
          ),

          SizedBox(height: 20),

          // Email
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: widget.clientEmail.isNotEmpty
                ? widget.clientEmail
                : 'Sin email',
          ),

          SizedBox(height: 20),

          // Teléfono
          _buildInfoItem(
            icon: Icons.phone_outlined,
            title: 'Teléfono',
            value: widget.clientPhone.isNotEmpty
                ? widget.clientPhone
                : 'Sin teléfono',
          ),

          SizedBox(height: 20),

          // Ciudad
          _buildInfoItem(
            icon: Icons.location_city_outlined,
            title: 'Ciudad',
            value: widget.clientCity,
          ),

          SizedBox(height: 20),

          // Dirección
          _buildInfoItem(
            icon: Icons.home_outlined,
            title: 'Dirección',
            value: widget.clientAddress,
          ),
          SizedBox(height: 20),
          _buildInfoItem(
            icon: Icons.qr_code_outlined,
            title: 'Código',
            value: widget.clientCode,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
