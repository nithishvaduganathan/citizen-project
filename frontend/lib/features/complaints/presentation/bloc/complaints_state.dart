part of 'complaints_bloc.dart';

abstract class ComplaintsState extends Equatable {
  const ComplaintsState();

  @override
  List<Object?> get props => [];
}

class ComplaintsInitial extends ComplaintsState {}

class ComplaintsLoading extends ComplaintsState {}

class ComplaintsSubmitting extends ComplaintsState {}

class ComplaintsSubmitted extends ComplaintsState {}

class ComplaintsLoaded extends ComplaintsState {
  final List<Complaint> complaints;
  final int total;
  final int page;

  const ComplaintsLoaded({
    required this.complaints,
    required this.total,
    required this.page,
  });

  @override
  List<Object?> get props => [complaints, total, page];
}

class ComplaintDetailLoaded extends ComplaintsState {
  final Complaint complaint;

  const ComplaintDetailLoaded(this.complaint);

  @override
  List<Object?> get props => [complaint];
}

class ComplaintsError extends ComplaintsState {
  final String message;

  const ComplaintsError(this.message);

  @override
  List<Object?> get props => [message];
}
