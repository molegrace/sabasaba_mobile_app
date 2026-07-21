part of '../../../main.dart';

class VisitorInquiry {
  const VisitorInquiry({
    required this.visitor,
    required this.message,
    this.response,
  });

  final String visitor;
  final String message;
  final String? response;

  VisitorInquiry copyWith({String? response}) {
    return VisitorInquiry(
      visitor: visitor,
      message: message,
      response: response ?? this.response,
    );
  }
}
