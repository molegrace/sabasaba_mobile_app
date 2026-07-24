import 'package:flutter/material.dart';

class TicketsTab extends StatelessWidget {
  const TicketsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Tickets'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // TODO: integrate ticket purchasing flow
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ticket purchase not implemented.')),
            );
          },
          child: const Text('Buy Ticket'),
        ),
      ),
    );
  }
}
