import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source.dart';
import 'package:conet_app/feature/profile/data/models/user_profile_model.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileDataSource implements ProfileDataSource {
  final SupabaseClient supabaseClient;
  final FileUploadDataSource fileUploadDataSource;

  SupabaseProfileDataSource({
    required this.supabaseClient,
    required this.fileUploadDataSource,
  });

  @override
  Future<UserModel> updatePictures({
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      final updates = <String, dynamic>{};

      if (profilePic != null) {
        final profileUrls = await fileUploadDataSource.uploadFiles(
          files: [profilePic],
          bucket: 'profiles',
          folder: session.user.id,
        );
        updates['profile_pic_url'] = profileUrls.first;
      }

      if (bannerImage != null) {
        final bannerUrls = await fileUploadDataSource.uploadFiles(
          files: [bannerImage],
          bucket: 'banners',
          folder: session.user.id,
        );
        updates['banner_url'] = bannerUrls.first;
      }

      if (updates.isNotEmpty) {
        await supabaseClient
            .from('users')
            .update(updates)
            .eq('id', session.user.id);
      }

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error updating pictures: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updatePersonalInfo({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      final updates = <String, dynamic>{
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
      };

      if (updates.isNotEmpty) {
        await supabaseClient
            .from('users')
            .update(updates)
            .eq('id', session.user.id);
      }

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error updating personal info: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateAboutMe(String aboutMe) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      await supabaseClient
          .from('users')
          .update({'about_me': aboutMe})
          .eq('id', session.user.id);

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error updating about me: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateInterests(List<String> interests) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      await supabaseClient
          .from('users')
          .update({'interests': interests})
          .eq('id', session.user.id);

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error updating interests: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateAcademicInfo({
    required String collegeName,
    required String course,
    String? major,
    int? startYear,
    int? endYear,
  }) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      final userId = session.user.id;
      final data = {
        'college_name': collegeName,
        'course': course,
        'major': major,
        'start_year': startYear,
        'end_year': endYear,
      };

      // Check if an academic record already exists for this user
      final existing = await supabaseClient
          .from('user_academics')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing record by its primary key
        await supabaseClient
            .from('user_academics')
            .update(data)
            .eq('id', existing['id']);
      } else {
        // Insert new record
        await supabaseClient
            .from('user_academics')
            .insert({...data, 'user_id': userId});
      }

      return _getUserModel(userId);
    } catch (e) {
      logger.e("Error updating academic info: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> updateSocialLinks(List<SocialLinks> socialLinks) async {
    try {
      final session = supabaseClient.auth.currentSession;
      if (session == null) {
        throw ServerException('User not logged in');
      }

      await supabaseClient
          .from('users')
          .update({'social_links': socialLinks.map((e) => e.toJson()).toList()})
          .eq('id', session.user.id);

      return _getUserModel(session.user.id);
    } catch (e) {
      logger.e("Error updating social links: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final userData = await supabaseClient
          .from('users')
          .select('*, user_academics(*)')
          .eq('id', uid)
          .single();

      return UserProfileModel.fromJson(userData);
    } catch (e) {
      logger.e("Error fetching user profile: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> _getUserModel(String id) async {
    try {
      final userData = await supabaseClient
          .from('users')
          .select()
          .eq('id', id)
          .single();
      return UserModel.fromJson(
        userData,
      ).copyWith(email: supabaseClient.auth.currentUser?.email);
    } catch (e) {
      logger.e("Error fetching user model: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }
}
