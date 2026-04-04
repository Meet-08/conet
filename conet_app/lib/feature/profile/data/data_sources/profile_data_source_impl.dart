import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/data_sources/file_upload_data_source.dart';
import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source.dart';
import 'package:conet_app/feature/profile/data/models/user_profile_model.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

class ProfileDataSourceImpl implements ProfileDataSource {
  final FileUploadDataSource fileUploadDataSource;
  final DioClient dioClient;

  ProfileDataSourceImpl({
    required this.fileUploadDataSource,
    required this.dioClient,
  });

  @override
  Future<UserProfile> getUserProfile(String uid) async {
    try {
      final res = await dioClient.dio.get("/profile/$uid");
      if (res.statusCode != 200) {
        throw ServerException("Failed to fetch user profile");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("User profile fetched $data");
      return UserProfileModel.fromJson(data['profile']);
    } catch (e) {
      logger.e("Failed to fetch user profile", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updateAboutMe(String aboutMe) async {
    try {
      final res = await dioClient.dio.put(
        "/profile/about-me",
        data: {"about_me": aboutMe},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update about me");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("About me updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update about me", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updateAcademicInfo({
    required String collegeName,
    required String degree,
    required String course,
    int? startYear,
    int? endYear,
  }) async {
    try {
      final res = await dioClient.dio.put(
        "/profile/academic-info",
        data: {
          "college_name": collegeName,
          "degree": degree,
          "course": course,
          "start_year": startYear,
          "end_year": endYear,
        },
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update academic info");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("Academic info updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update academic info", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updateInterests(List<String> interests) async {
    try {
      final res = await dioClient.dio.put(
        "/profile/interests",
        data: {"interests": interests},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update interests");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("Interests updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update interests", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updatePersonalInfo({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final res = await dioClient.dio.put(
        "/profile/personal-info",
        data: {
          "first_name": ?firstName,
          "last_name": ?lastName,
          if (dateOfBirth != null)
            "date_of_birth": dateOfBirth.toIso8601String(),
        },
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update personal info");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("Personal info updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update personal info", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updatePictures({
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  }) async {
    try {
      String? profilePicUrl;
      String? bannerUrl;

      await Future.wait([
        if (profilePic != null)
          fileUploadDataSource
              .uploadFiles(
                files: [profilePic],
                bucket: 'profile',
                folder: 'profile_${const Uuid().v4()}',
              )
              .then((urls) => profilePicUrl = urls.first),
        if (bannerImage != null)
          fileUploadDataSource
              .uploadFiles(
                files: [bannerImage],
                bucket: 'profile',
                folder: 'banner_${const Uuid().v4()}',
              )
              .then((urls) => bannerUrl = urls.first),
      ]);

      final res = await dioClient.dio.put(
        "/profile/pictures",
        data: {"profile_pic_url": ?profilePicUrl, "banner_url": ?bannerUrl},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update pictures");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("Pictures updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update pictures", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<UserModel> updateSocialLinks(List<SocialLinks> socialLinks) async {
    try {
      final res = await dioClient.dio.put(
        "/profile/social-links",
        data: {"social_links": socialLinks.map((e) => e.toJson()).toList()},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to update social links");
      }
      final data = res.data as Map<String, dynamic>;
      logger.i("Social links updated $data");
      return UserModel.fromJson(data['user']);
    } catch (e) {
      logger.e("Failed to update social links", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> followUser(String targetUid) async {
    try {
      final res = await dioClient.dio.post("/profile/$targetUid/follow");
      if (res.statusCode != 200) {
        throw ServerException("Failed to follow user");
      }
    } catch (e) {
      logger.e("Failed to follow user", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> unfollowUser(String targetUid) async {
    try {
      final res = await dioClient.dio.delete("/profile/$targetUid/follow");
      if (res.statusCode != 200) {
        throw ServerException("Failed to unfollow user");
      }
    } catch (e) {
      logger.e("Failed to unfollow user", error: e);
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
