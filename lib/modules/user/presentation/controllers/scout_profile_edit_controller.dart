import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zuru/core/entities/profile_clip.entity.dart';
import 'package:zuru/core/entities/session_pricing.entity.dart';
import 'package:zuru/core/models/enums.dart';
import 'package:zuru/core/utils/loader.dart';
import 'package:zuru/core/utils/toast.dart';
import 'package:zuru/modules/user/data/models/scout_profile_edit.input.dart';
import 'package:zuru/modules/user/domain/usecases/add_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/delete_profile_clip.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/get_profile_clips.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/update_scout_profile.usecase.dart';
import 'package:zuru/modules/user/domain/usecases/upload_media.usecase.dart';
import 'package:zuru/modules/user/presentation/controllers/user_controller.dart';

class ScoutProfileEditController extends GetxController {
  final UpdateScoutProfileUseCase _updateScoutProfile;
  final UploadMediaUseCase _uploadMedia;
  final GetProfileClipsUseCase _getProfileClips;
  final AddProfileClipUseCase _addProfileClip;
  final DeleteProfileClipUseCase _deleteProfileClip;
  final UserController _userController;

  ScoutProfileEditController({
    required UpdateScoutProfileUseCase updateScoutProfile,
    required UploadMediaUseCase uploadMedia,
    required GetProfileClipsUseCase getProfileClips,
    required AddProfileClipUseCase addProfileClip,
    required DeleteProfileClipUseCase deleteProfileClip,
    required UserController userController,
  }) : _updateScoutProfile = updateScoutProfile,
       _uploadMedia = uploadMedia,
       _getProfileClips = getProfileClips,
       _addProfileClip = addProfileClip,
       _deleteProfileClip = deleteProfileClip,
       _userController = userController;

  static const int maxTags = 5;
  static const int maxBioChars = 280;
  static const int maxClips = 3;

  /// Duration options (minutes) offered when adding a session price tier.
  static const List<int> durationOptions = [10, 15, 20, 30, 45, 60];

  final _picker = ImagePicker();

  // ── Editable state ────────────────────────────────────────────────────────
  final bioCTRL = TextEditingController();
  final customTagCTRL = TextEditingController();
  final priceCTRL = TextEditingController();

  final RxList<String> selectedTags = <String>[].obs;
  final RxnString locality = RxnString();
  final Rx<ScoutAvailability> availability = ScoutAvailability.available.obs;
  final RxList<SessionPricing> sessionPricing = <SessionPricing>[].obs;
  final RxList<ProfileClip> clips = <ProfileClip>[].obs;

  /// Newly-picked avatar awaiting upload on save; null when unchanged.
  final Rx<File?> pickedAvatar = Rx<File?>(null);
  final RxnString avatarUrl = RxnString();

  // ── UI state ────────────────────────────────────────────────────────────
  final RxBool isSaving = false.obs;
  final RxBool isAddingClip = false.obs;
  final RxBool showAddPricing = false.obs;
  final RxnInt newDuration = RxnInt();

  String? get _profileId => _userController.currentUser.value?.scoutProfile?.id;

  /// Display name shown in the preview card.
  String get currentUserName {
    final name = _userController.currentUser.value?.scoutProfile?.fullName;
    return (name?.isNotEmpty ?? false) ? name! : 'Scout';
  }

  /// Formatted rating for the preview card.
  String get rating =>
      _userController.currentUser.value?.scoutProfile?.rating?.toStringAsFixed(
        1,
      ) ??
      '—';

  @override
  void onInit() {
    super.onInit();
    _hydrate();
  }

  @override
  void onClose() {
    bioCTRL.dispose();
    customTagCTRL.dispose();
    priceCTRL.dispose();
    super.onClose();
  }

  // ── Hydration ─────────────────────────────────────────────────────────────

  void _hydrate() {
    final profile = _userController.currentUser.value?.scoutProfile;
    if (profile == null) return;

    bioCTRL.text = profile.bio ?? '';
    selectedTags.assignAll(profile.tags.where((t) => t.isNotEmpty));
    locality.value = profile.locality;
    availability.value = profile.availability ?? ScoutAvailability.available;
    avatarUrl.value = profile.avatarUrl;
    sessionPricing.assignAll(profile.sessionPricing);

    if (profile.clips.isNotEmpty) {
      clips.assignAll(profile.clips);
    }
    _loadClips();
  }

  Future<void> _loadClips() async {
    final id = _profileId;
    if (id == null) return;
    final result = await _getProfileClips(id);
    result.fold((_) => null, clips.assignAll);
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────

  Future<void> pickAvatar() async {
    final file = await _pickImage();
    if (file != null) pickedAvatar.value = file;
  }

  // ── Locality ─────────────────────────────────────────────────────────────

  void setLocality(String value) => locality.value = value.trim();

  // ── Tags ─────────────────────────────────────────────────────────────────

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      if (selectedTags.length >= maxTags) {
        Toast.warning('You can add up to $maxTags tags');
        return;
      }
      selectedTags.add(tag);
    }
  }

  void addCustomTag() {
    final tag = customTagCTRL.text.trim();
    if (tag.isEmpty) return;
    if (selectedTags.contains(tag)) {
      customTagCTRL.clear();
      return;
    }
    if (selectedTags.length >= maxTags) {
      Toast.warning('You can add up to $maxTags tags');
      return;
    }
    selectedTags.add(tag);
    customTagCTRL.clear();
  }

  void removeTag(String tag) => selectedTags.remove(tag);

  // ── Availability ───────────────────────────────────────────────────────────

  void setAvailability(ScoutAvailability value) => availability.value = value;

  // ── Session pricing ────────────────────────────────────────────────────────

  /// Durations not yet used — drives the "Select Duration" dropdown options.
  List<int> get availableDurations {
    final used = sessionPricing.map((p) => p.durationMinutes).toSet();
    return durationOptions.where((d) => !used.contains(d)).toList();
  }

  void openAddPricing() {
    final options = availableDurations;
    if (options.isEmpty) {
      Toast.warning('All session durations have been added');
      return;
    }
    newDuration.value = options.first;
    priceCTRL.clear();
    showAddPricing.value = true;
  }

  void cancelAddPricing() {
    showAddPricing.value = false;
    newDuration.value = null;
    priceCTRL.clear();
  }

  void confirmAddPricing() {
    final duration = newDuration.value;
    final price = num.tryParse(priceCTRL.text.trim());

    if (duration == null) {
      Toast.error('Select a session duration');
      return;
    }
    if (price == null || price <= 0) {
      Toast.error('Enter a valid price');
      return;
    }
    if (sessionPricing.any((p) => p.durationMinutes == duration)) {
      Toast.error('That duration already has a price');
      return;
    }

    sessionPricing.add(SessionPricing(durationMinutes: duration, price: price));
    sessionPricing.sort(
      (a, b) => a.durationMinutes.compareTo(b.durationMinutes),
    );
    cancelAddPricing();
  }

  void removePricing(SessionPricing tier) => sessionPricing.remove(tier);

  // ── Clips ────────────────────────────────────────────────────────────────

  /// Whether another clip can still be added (cap at [maxClips]).
  bool get canAddClip => clips.length < maxClips;

  /// Picks an image, uploads it, and appends a new clip — up to [maxClips].
  Future<void> addClip() async {
    final id = _profileId;
    if (id == null) {
      Toast.error('Profile not ready yet, please retry');
      return;
    }
    if (!canAddClip) {
      Toast.warning('You can add up to $maxClips clips');
      return;
    }

    final file = await _pickImage();
    if (file == null) return;

    isAddingClip.value = true;

    final uploadResult = await _uploadMedia(
      UploadMediaParams(file: file, folder: 'clips'),
    );

    await uploadResult.fold(
      (err) async {
        isAddingClip.value = false;
        Toast.error(err.message);
      },
      (url) async {
        final result = await _addProfileClip(
          AddClipParams(profileId: id, mediaUrl: url),
        );
        isAddingClip.value = false;
        result.fold((err) => Toast.error(err.message), clips.add);
      },
    );
  }

  Future<void> removeClip(ProfileClip clip) async {
    if (clip.id == null) {
      clips.remove(clip);
      return;
    }

    Loader.show();
    final result = await _deleteProfileClip(clip.id!);
    Loader.dismiss();

    result.fold(
      (err) => Toast.error(err.message),
      (_) => clips.removeWhere((c) => c.id == clip.id),
    );
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> save() async {
    final bio = bioCTRL.text.trim();
    if (bio.isEmpty) {
      Toast.error('Please write a short bio');
      return;
    }

    isSaving.value = true;
    Loader.show(message: 'Saving profile…');

    // 1. Upload a freshly-picked avatar, if any.
    String? resolvedAvatarUrl = avatarUrl.value;
    final picked = pickedAvatar.value;
    if (picked != null) {
      final uploadResult = await _uploadMedia(
        UploadMediaParams(file: picked, folder: 'avatar'),
      );
      final failed = uploadResult.fold((err) {
        Toast.error(err.message);
        return true;
      }, (url) {
        resolvedAvatarUrl = url;
        return false;
      });
      if (failed) {
        Loader.dismiss();
        isSaving.value = false;
        return;
      }
    }

    // 2. Persist the profile row.
    final input = ScoutProfileEditInput(
      bio: bio,
      tags: selectedTags.toList(),
      locality: locality.value,
      availability: availability.value,
      avatarUrl: resolvedAvatarUrl,
      sessionPricing: sessionPricing.toList(),
    );

    final result = await _updateScoutProfile(input);

    Loader.dismiss();
    isSaving.value = false;

    result.fold((err) => Toast.error(err.message), (_) async {
      avatarUrl.value = resolvedAvatarUrl;
      pickedAvatar.value = null;
      // Refresh the shared user state so the profile tab reflects changes.
      await _userController.getUserDetails();
      Toast.success('Profile saved');
      Get.back();
    });
  }

  void previewAsClient() {
    Toast.info('Client preview is coming soon');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<File?> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }
}
