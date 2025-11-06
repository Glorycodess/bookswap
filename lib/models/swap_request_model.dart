class SwapRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterBookId;
  final String requesterBookTitle;
  final String recipientId;
  final String recipientName;
  final String recipientBookId;
  final String recipientBookTitle;
  final String status; // "pending", "accepted", "rejected", "cancelled"
  final String chatId;
  final DateTime createdAt;
  final DateTime updatedAt;

  SwapRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterBookId,
    required this.requesterBookTitle,
    required this.recipientId,
    required this.recipientName,
    required this.recipientBookId,
    required this.recipientBookTitle,
    required this.status,
    required this.chatId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SwapRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return SwapRequestModel(
      id: id,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterBookId: map['requesterBookId'] ?? '',
      requesterBookTitle: map['requesterBookTitle'] ?? '',
      recipientId: map['recipientId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientBookId: map['recipientBookId'] ?? '',
      recipientBookTitle: map['recipientBookTitle'] ?? '',
      status: map['status'] ?? 'pending',
      chatId: map['chatId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterBookId': requesterBookId,
      'requesterBookTitle': requesterBookTitle,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'recipientBookId': recipientBookId,
      'recipientBookTitle': recipientBookTitle,
      'status': status,
      'chatId': chatId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}