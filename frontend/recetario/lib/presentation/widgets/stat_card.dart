import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget: Tarjeta de estadística reutilizable (Responsivo)
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
        child: Padding(
          padding: EdgeInsets.all(kIsWeb ? (isMobile ? 12 : 16) : 12.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(kIsWeb ? (isMobile ? 8 : 10) : 8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kIsWeb ? 12 : 12.r),
                ),
                child: Icon(
                  icon,
                  size: kIsWeb ? (isMobile ? 24 : 28) : 24.sp,
                  color: color,
                ),
              ),
              SizedBox(height: kIsWeb ? (isMobile ? 8 : 10) : 8.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: kIsWeb ? (isMobile ? 22 : 26) : 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: kIsWeb ? 4 : 4.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: kIsWeb ? (isMobile ? 12 : 13) : 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                SizedBox(height: kIsWeb ? 2 : 2.h),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: kIsWeb ? (isMobile ? 9 : 10) : 9.sp,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}