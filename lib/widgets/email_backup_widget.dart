// lib/widgets/email_backup_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../theme/app_styles.dart';

class EmailBackupWidget extends StatefulWidget {
  final String rutaArchivo;
  final String nombreArchivo;

  const EmailBackupWidget({
    Key? key,
    required this.rutaArchivo,
    required this.nombreArchivo,
  }) : super(key: key);

  @override
  _EmailBackupWidgetState createState() => _EmailBackupWidgetState();
}

class _EmailBackupWidgetState extends State<EmailBackupWidget>
    with TickerProviderStateMixin {
  final _destinatariosController = TextEditingController();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();

  bool _enviando = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Inicializar valores por defecto
    _asuntoController.text = 'Backup de Nómina - ${widget.nombreArchivo}';
    _mensajeController.text = 'Se adjunta el archivo de backup de la base de datos de nómina.';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _destinatariosController.dispose();
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildBody(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenDark, AppColors.greenDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.email,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enviar por Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Abre tu cliente de email con el archivo adjunto',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info del archivo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.attachment, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivo a enviar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.nombreArchivo,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Destinatarios
          TextField(
            controller: _destinatariosController,
            decoration: InputDecoration(
              labelText: 'Para (opcional)',
              hintText: 'email1@ejemplo.com, email2@ejemplo.com',
              prefixIcon: const Icon(Icons.people_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
              helperText: 'Puedes agregar destinatarios o dejarlo vacío',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Asunto
          TextField(
            controller: _asuntoController,
            decoration: InputDecoration(
              labelText: 'Asunto',
              prefixIcon: const Icon(Icons.subject),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mensaje
          TextField(
            controller: _mensajeController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Mensaje que aparecerá en el email...',
              prefixIcon: const Icon(Icons.message_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _enviando ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _enviando ? null : _abrirClienteEmail,
              icon: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.open_in_new),
              label: Text(_enviando ? 'Abriendo...' : 'Abrir Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirClienteEmail() async {
    setState(() => _enviando = true);

    try {
      // Convertir ruta relativa a absoluta si es necesario
      String rutaCompleta = widget.rutaArchivo;
      if (widget.rutaArchivo.startsWith('backups/') || widget.rutaArchivo.startsWith('backups\\')) {
        final directorioTrabajo = Directory.current.path;
        rutaCompleta = '$directorioTrabajo\\${widget.rutaArchivo}'.replaceAll('/', '\\');
      }

      // Crear el mailto URL
      final destinatarios = _destinatariosController.text.trim();
      final asunto = Uri.encodeComponent(_asuntoController.text);
      final mensaje = Uri.encodeComponent(_mensajeController.text);
      
      // Crear comando para abrir cliente de email con archivo adjunto
      String comando;
      if (Platform.isWindows) {
        // En Windows, intentar abrir con Outlook o cliente predeterminado
        comando = 'start "" "mailto:$destinatarios?subject=$asunto&body=$mensaje"';
        
        // También copiar el archivo al portapapeles para facilitar adjuntar
        await Process.run('powershell', [
          '-Command',
          'Set-Clipboard -Path "$rutaCompleta"'
        ]);
      } else {
        // En otros sistemas
        comando = 'xdg-open "mailto:$destinatarios?subject=$asunto&body=$mensaje"';
      }

      await Process.run('cmd', ['/c', comando], runInShell: true);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('✅ Cliente de email abierto'),
                      Text(
                        'Adjunta manualmente el archivo desde la ubicación copiada',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 5),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Copia manualmente: ${widget.rutaArchivo}')),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }
}