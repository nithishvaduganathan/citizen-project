import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../bloc/complaints_bloc.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/models/complaint_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/injection.dart';

/// Create complaint page
class CreateComplaintPage extends StatefulWidget {
  const CreateComplaintPage({super.key});

  @override
  State<CreateComplaintPage> createState() => _CreateComplaintPageState();
}

class _CreateComplaintPageState extends State<CreateComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();

  ComplaintCategory _selectedCategory = ComplaintCategory.other;
  final List<String> _selectedAuthorities = [];
  final List<XFile> _selectedImages = [];
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  final List<String> _authorityOptions = [
    '@police',
    '@municipality',
    '@electricity',
    '@water',
    '@health',
    '@transport',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for location to be captured')),
      );
      return;
    }

    context.read<ComplaintsBloc>().add(
          ComplaintsCreate(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory.value,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            address: _addressController.text.trim().isNotEmpty
                ? _addressController.text.trim()
                : null,
            landmark: _landmarkController.text.trim().isNotEmpty
                ? _landmarkController.text.trim()
                : null,
            mentionedAuthorities: _selectedAuthorities,
            imagePaths: _selectedImages.map((e) => e.path).toList(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ComplaintsBloc>(),
      child: BlocConsumer<ComplaintsBloc, ComplaintsState>(
        listener: (context, state) {
          if (state is ComplaintsSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complaint submitted successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          } else if (state is ComplaintsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Report Issue'),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location indicator
                    Card(
                      child: ListTile(
                        leading: _isLoadingLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _currentPosition != null
                                    ? Icons.location_on
                                    : Icons.location_off,
                                color: _currentPosition != null
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                        title: Text(
                          _currentPosition != null
                              ? 'Location captured'
                              : 'Capturing location...',
                        ),
                        subtitle: _currentPosition != null
                            ? Text(
                                '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _getCurrentLocation,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category selection
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ComplaintCategory.values.map((category) {
                        final isSelected = _selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Brief description of the issue',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        if (value.length < 5) {
                          return 'Title must be at least 5 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Provide details about the issue',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.length < 10) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        hintText: 'Street address of the issue',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Landmark
                    TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark (optional)',
                        hintText: 'Nearby landmark for reference',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tag authorities
                    Text(
                      'Tag Authorities',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _authorityOptions.map((authority) {
                        final isSelected = _selectedAuthorities.contains(authority);
                        return FilterChip(
                          label: Text(authority),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAuthorities.add(authority);
                              } else {
                                _selectedAuthorities.remove(authority);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Images
                    Text(
                      'Photos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_selectedImages[index].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit button
                    PrimaryButton(
                      text: 'Submit Report',
                      isLoading: state is ComplaintsSubmitting,
                      onPressed: _submitComplaint,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
