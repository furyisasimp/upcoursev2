// import 'package:flutter/material.dart';
// import 'package:career_roadmap/services/aws_service.dart';
// import 'profile_builder_screen.dart';

// class OtpVerificationScreen extends StatefulWidget {
//   final String email;

//   const OtpVerificationScreen({super.key, required this.email});

//   @override
//   OtpVerificationScreenState createState() => OtpVerificationScreenState();
// }

// class OtpVerificationScreenState extends State<OtpVerificationScreen> {
//   final _otpController = TextEditingController();
//   bool _isLoading = false; // Added loading state

//   void _verifyOtp() async {
//     final otp = _otpController.text.trim();

//     if (otp.isNotEmpty) {
//       setState(() => _isLoading = true); // Show loading indicator

//       try {
//         final response = await AwsService.verifyOtp(widget.email, otp);

//         if (mounted) {
//           setState(() => _isLoading = false); // Hide loading indicator

//           if (response['success']) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const ProfileBuilderScreen(),
//               ),
//             );
//           } else {
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text(response['message'])));
//           }
//         }
//       } catch (e) {
//         if (mounted) {
//           setState(() => _isLoading = false);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to verify OTP. Please try again.')),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('OTP Verification')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child:
//             _isLoading
//                 ? const Center(
//                   child: CircularProgressIndicator(),
//                 ) // Show loading spinner
//                 : Column(
//                   children: [
//                     TextField(
//                       controller: _otpController,
//                       decoration: const InputDecoration(labelText: 'Enter OTP'),
//                       keyboardType: TextInputType.number,
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _verifyOtp,
//                       child: const Text('Verify OTP'),
//                     ),
//                   ],
//                 ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _otpController.dispose();
//     super.dispose();
//   }
// }
