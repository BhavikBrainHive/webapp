import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:neon_widgets/neon_widgets.dart';

class ToastWidget extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const ToastWidget({
    super.key,
    required this.message,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return FlickerNeonContainer(
      containerColor: isSuccess ? Colors.greenAccent : Colors.redAccent,
      spreadColor: isSuccess ? Colors.greenAccent : Colors.redAccent,
      flickerTimeInMilliSeconds: 0,
      borderRadius: BorderRadius.circular(
        10.r,
      ),
      lightBlurRadius: 100,
      borderColor: Colors.white,
      borderWidth: 2.w,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 15.w,
          vertical: 7.w,
        ),
        child: FlickerNeonText(
          text: message,
          flickerTimeInMilliSeconds: 0,
          textColor: Colors.white,
          spreadColor: Colors.transparent,
          blurRadius: 010,
          textSize: 20.sp,
        ),
      ),
    );
  }
}
