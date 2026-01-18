import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/complaints_repository.dart';
import '../../../../shared/models/complaint_model.dart';

part 'complaints_event.dart';
part 'complaints_state.dart';

/// Complaints BLoC
class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  final ComplaintsRepository _repository;

  ComplaintsBloc({required ComplaintsRepository repository})
      : _repository = repository,
        super(ComplaintsInitial()) {
    on<ComplaintsLoad>(_onLoad);
    on<ComplaintsLoadNearby>(_onLoadNearby);
    on<ComplaintsLoadMy>(_onLoadMy);
    on<ComplaintsLoadDetail>(_onLoadDetail);
    on<ComplaintsCreate>(_onCreate);
    on<ComplaintsToggleUpvote>(_onToggleUpvote);
    on<ComplaintsAddComment>(_onAddComment);
  }

  Future<void> _onLoad(
    ComplaintsLoad event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    try {
      final response = await _repository.getComplaints(
        page: event.page,
        category: event.category,
        status: event.status,
      );
      final complaints = (response['complaints'] as List<dynamic>)
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(ComplaintsLoaded(
        complaints: complaints,
        total: response['total'] as int,
        page: response['page'] as int,
      ));
    } catch (e) {
      emit(ComplaintsError('Failed to load complaints'));
    }
  }

  Future<void> _onLoadNearby(
    ComplaintsLoadNearby event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    try {
      final response = await _repository.getNearbyComplaints(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        page: event.page,
      );
      final complaints = (response['complaints'] as List<dynamic>)
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(ComplaintsLoaded(
        complaints: complaints,
        total: response['total'] as int,
        page: response['page'] as int,
      ));
    } catch (e) {
      emit(ComplaintsError('Failed to load nearby complaints'));
    }
  }

  Future<void> _onLoadMy(
    ComplaintsLoadMy event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    try {
      final response = await _repository.getMyComplaints(
        page: event.page,
        status: event.status,
      );
      final complaints = (response['complaints'] as List<dynamic>)
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(ComplaintsLoaded(
        complaints: complaints,
        total: response['total'] as int,
        page: response['page'] as int,
      ));
    } catch (e) {
      emit(ComplaintsError('Failed to load my complaints'));
    }
  }

  Future<void> _onLoadDetail(
    ComplaintsLoadDetail event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsLoading());
    try {
      final response = await _repository.getComplaint(event.id);
      final complaint = Complaint.fromJson(response);
      emit(ComplaintDetailLoaded(complaint));
    } catch (e) {
      emit(ComplaintsError('Failed to load complaint details'));
    }
  }

  Future<void> _onCreate(
    ComplaintsCreate event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintsSubmitting());
    try {
      await _repository.createComplaint(
        title: event.title,
        description: event.description,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        landmark: event.landmark,
        city: event.city,
        state: event.state,
        pincode: event.pincode,
        mentionedAuthorities: event.mentionedAuthorities,
        imagePaths: event.imagePaths,
      );
      emit(ComplaintsSubmitted());
    } catch (e) {
      emit(ComplaintsError('Failed to create complaint'));
    }
  }

  Future<void> _onToggleUpvote(
    ComplaintsToggleUpvote event,
    Emitter<ComplaintsState> emit,
  ) async {
    try {
      await _repository.toggleUpvote(event.id);
      // Reload the complaint details
      add(ComplaintsLoadDetail(event.id));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onAddComment(
    ComplaintsAddComment event,
    Emitter<ComplaintsState> emit,
  ) async {
    try {
      await _repository.addComment(
        complaintId: event.complaintId,
        content: event.content,
      );
      // Reload the complaint details
      add(ComplaintsLoadDetail(event.complaintId));
    } catch (e) {
      emit(ComplaintsError('Failed to add comment'));
    }
  }
}
