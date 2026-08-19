import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta y estilos de Casa Oscar. Base nocturna cálida con acentos por
/// categoría de dispositivo, pensada para leerse bien en una pantalla
/// que se va a mirar de noche (control de casa) sin resultar fría.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0A0D16);
  static const bgGlowTop = Color(0xFF141B30);
  static const surface = Color(0xFF131828);
  static const surfaceElevated = Color(0xFF1A2036);
  static const border = Color(0x1AFFFFFF);
  static const borderStrong = Color(0x33FFFFFF);

  static const textPrimary = Color(0xFFF4F6FB);
  static const textSecondary = Color(0xFF9AA3B8);
  static const textFaint = Color(0xFF636D85);

  static const primary = Color(0xFF6E82F7);
  static const primaryDeep = Color(0xFF4B57D6);
  static const primaryLight = Color(0xFFA9B6FF);

  static const amber = Color(0xFFF2A93B);
  static const cyan = Color(0xFF44C6E8);
  static const violet = Color(0xFFAE8CF5);
  static const green = Color(0xFF3FCF8E);
  static const rose = Color(0xFFF17099);
  static const fuchsia = Color(0xFFE283E8);

  static const success = green;
  static const danger = rose;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDeep, primary],
  );

  static Color forDeviceType(String type) => switch (type) {
        'light' => amber,
        'climate' => cyan,
        'cover' => violet,
        'switch' => green,
        'camera' => rose,
        'media_player' => fuchsia,
        _ => primary,
      };

  static Color forRoomIcon(String icon) => switch (icon) {
        'living' => amber,
        'kitchen' => green,
        'deck' => cyan,
        'bed' => violet,
        _ => primary,
      };

  static Color forScene(String id) => switch (id) {
        'llegar' => green,
        'salir' => amber,
        'cine' => violet,
        'buenas_noches' => cyan,
        _ => primary,
      };
}

/// Ancho máximo de contenido. La app está pensada para celular; esto evita
/// que las tarjetas se vean "infladas" al probar en una ventana de escritorio
/// ancha, y no afecta a un teléfono real (siempre es más angosto que esto).
const double kMaxContentWidth = 440;

class MobileFrame extends StatelessWidget {
  final Widget child;
  const MobileFrame({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: child,
      ),
    );
  }
}

class AppRadius {
  AppRadius._();
  static const sm = 14.0;
  static const md = 20.0;
  static const lg = 26.0;
  static const xl = 32.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.primary,
      secondary: AppColors.violet,
      onSurface: AppColors.textPrimary,
    ),
    fontFamily: GoogleFonts.manrope().fontFamily,
    textTheme: GoogleFonts.manropeTextTheme(ThemeData(brightness: Brightness.dark).textTheme)
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    splashFactory: InkRipple.splashFactory,
  );
  return base.copyWith(
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.border,
      thumbColor: Colors.white,
      overlayColor: AppColors.primary.withOpacity(0.15),
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : AppColors.border),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}

/// Contenedor base para tarjetas: fondo elevado sutil, borde de 1px casi
/// invisible y sombra suave. Todo lo demás en la app se construye sobre esto.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = AppRadius.md,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return Padding(padding: EdgeInsets.zero, child: card);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Padding(padding: EdgeInsets.zero, child: card),
      ),
    );
  }
}

/// Círculo blur decorativo ("blob") para dar textura orgánica a fondos
/// de tarjetas destacadas, sin depender de imágenes externas.
class Blob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  const Blob({super.key, required this.size, required this.color, this.opacity = 0.25});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}

Widget sectionTitle(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                fontSize: 12.5,
                color: AppColors.textFaint,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge({super.key, required this.icon, required this.color, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.28), color.withOpacity(0.14)],
        ),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}
