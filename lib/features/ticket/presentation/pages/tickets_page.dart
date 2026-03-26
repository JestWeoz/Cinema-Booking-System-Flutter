import 'package:flutter/material.dart';
import 'package:cinema_booking_system_app/core/theme/app_colors.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')]),
            Expanded(
              child: TabBarView(
                children: [
                  _TicketList(isEmpty: false),
                  _TicketList(isEmpty: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final bool isEmpty;
  const _TicketList({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No tickets found', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.dividerDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Icon(Icons.movie, color: Colors.grey)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Movie Title $i', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('CGV Aeon Mall • 2 Seats', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('01/04/2026 19:30', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Confirmed', style: TextStyle(color: AppColors.success, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
