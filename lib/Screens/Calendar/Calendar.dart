import 'package:dantotsu/Screens/Calendar/CalendarTabs.dart';
import 'package:dantotsu/Screens/Calendar/CalendarViewModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final _viewModel = Get.put(CalendarViewModel());

  @override
  void initState() {
    super.initState();
    _viewModel.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Calendar",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16.0,
            color: theme.primary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: theme.primary),
      ),

      body: Obx((){
        if (_viewModel.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.calendarData.value == null || _viewModel.calendarData.value!.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        return CalendarTabs(viewModel: _viewModel);
      }),
    );
  }
}
