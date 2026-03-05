import 'package:flutter/material.dart';

///Custom UI Components for PEAK MAP

/// Loading Indicator with text
class PeakMapLoadingIndicator extends StatelessWidget {
  final String message;
  final Color color;

  const PeakMapLoadingIndicator({
    Key? key,
    this.message = "Loading...",
    this.color = const Color(0xFF355872),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                // Outer rotating ring
                Positioned.fill(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeWidth: 3,
                  ),
                ),
                // Center icon
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.map,
                      size: 40,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Action Button with icon
class PeakMapButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final double width;
  final double height;
  final bool isLoading;
  final bool isEnabled;

  const PeakMapButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF355872),
    this.foregroundColor = Colors.white,
    this.width = double.infinity,
    this.height = 48,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Icon(icon),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? backgroundColor : Colors.grey,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }
}

/// Fare Information Card
class FareInfoCard extends StatelessWidget {
  final String status;
  final String etaText;
  final String distanceText;
  final double? fareAmount;
  final String paymentMethod;
  final bool showPaymentButton;
  final VoidCallback? onPaymentPressed;
  final bool isPaymentLoading;

  const FareInfoCard({
    Key? key,
    required this.status,
    required this.etaText,
    required this.distanceText,
    this.fareAmount,
    this.paymentMethod = "Pending",
    this.showPaymentButton = false,
    this.onPaymentPressed,
    this.isPaymentLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor = _getStatusColor();
    IconData statusIcon = _getStatusIcon();

    return Card(
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status header with icon
            Row(
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etaText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (distanceText.isNotEmpty)
                        Text(
                          distanceText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Fare information when available
            if (fareAmount != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Fare Amount",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₱${fareAmount!.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Payment Method",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7AAACE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paymentMethod,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7AAACE),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Payment button when needed
            if (showPaymentButton && onPaymentPressed != null) ...[
              const SizedBox(height: 12),
              PeakMapButton(
                label: 'Pay ₱${fareAmount?.toStringAsFixed(2) ?? "0.00"}',
                icon: Icons.payment,
                onPressed: onPaymentPressed!,
                backgroundColor: const Color(0xFF7AAACE),
                isLoading: isPaymentLoading,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'ongoing':
        return const Color(0xFF355872);
      case 'dropped':
        return const Color(0xFF7AAACE);
      case 'missed':
        return const Color(0xFF9CD5FF);
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case 'ongoing':
        return Icons.directions_bus;
      case 'dropped':
        return Icons.check_circle;
      case 'missed':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'ongoing':
        return '🚍 On the way to your station';
      case 'dropped':
        return '🎉 You have arrived';
      case 'missed':
        return '⚠️ Ride completed';
      default:
        return 'Unknown status';
    }
  }
}

/// Map Pin Icon for bus location
class BusMapPin extends StatelessWidget {
  final Color color;

  const BusMapPin({
    Key? key,
    this.color = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Inner circle with icon
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}

/// Station Pin Icon for destination
class StationMapPin extends StatelessWidget {
  final Color color;

  const StationMapPin({
    Key? key,
    this.color = Colors.red,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pin shape
        CustomPaint(
          painter: MapPinPainter(color: color),
          size: const Size(40, 50),
        ),
        // Flag icon inside
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Icon(
            Icons.flag,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for station pin
class MapPinPainter extends CustomPainter {
  final Color color;

  MapPinPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.cubicTo(
      size.width / 2 + 15,
      0,
      size.width,
      size.height / 2,
      size.width / 2,
      size.height,
    );
    path.cubicTo(
      0,
      size.height / 2,
      size.width / 2 - 15,
      0,
      size.width / 2,
      0,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(MapPinPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Status Badge for ride information
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.color,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulse effect for real-time updates
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color pulseColor;

  const PulseAnimation({
    Key? key,
    required this.child,
    this.pulseColor = Colors.blue,
  }) : super(key: key);

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _sizeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        ScaleTransition(
          scale: _sizeAnimation,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.pulseColor.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
        ),
        // Child widget
        widget.child,
      ],
    );
  }
}
