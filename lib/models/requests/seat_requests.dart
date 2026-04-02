// Seat Requests — khớp với backend DTO/Request/Seat/

class LockSeatRequest {
  final List<String> seatIds;

  const LockSeatRequest({required this.seatIds});

  Map<String, dynamic> toJson() => {'seatIds': seatIds};
}

class UnlockSeatRequest {
  final List<String> seatIds;

  const UnlockSeatRequest({required this.seatIds});

  Map<String, dynamic> toJson() => {'seatIds': seatIds};
}
