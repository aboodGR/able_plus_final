// ignore_for_file: non_constant_identifier_names
// GENERATED FILE — do not edit manually.
// Generated from app_en.arb and app_ar.arb

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  // ── App ──
  String get appName;

  // ── Settings ──
  String get settings;
  String get darkMode;
  String get language;
  String get textToSpeech;
  String get colorBlindMode;
  String get colorBlindModeDesc;
  String get privacySettings;
  String get appearance;
  String get accessibility;
  String get deuteranopiaFilter;
  String get howColorsAppear;
  String get normal;
  String get withFilter;

  // ── Navigation ──
  String get home;
  String get map;
  String get messages;
  String get profile;
  String get notifications;

  // ── Drawer ──
  String get myActivity;
  String get support;
  String get aboutUs;
  String get logOut;
  String get logOutConfirm;
  String get cancel;
  String get confirm;

  // ── Activity ──
  String get recentActivity;
  String get recentActivityDesc;
  String get noActivityYet;
  String get noCommentsYet;
  String get noLikesYet;
  String get noSavedYet;
  String get comments;
  String get likes;
  String get saved;
  String get youLikedAPost;
  String get youCommentedOnAPost;
  String get youSavedAPost;
  String get tapToViewPost;
  String get tapToOpenProfile;
  String youFollowed(String name);
  String get someone;
  String get postNoLongerAvailable;
  String get profileNotAvailable;
  String get couldNotLoadActivity;

  // ── About Us ──
  String get ourTeam;
  String get founderCeo;
  String get email;
  String get phone;
  String get couldNotOpenEmail;
  String get couldNotOpenPhone;
  String get ableTeam;
  String get aboutUsBody;

  // ── Messages ──
  String get sendMessage;
  String get typeMessage;
  String get noMessages;
  String get startConversation;

  // ── Post ──
  String get createPost;
  String get post;
  String get title;
  String get description;
  String get addImage;
  String get addVideo;

  // ── General ──
  String get search;
  String get filter;
  String get noResults;
  String get follow;
  String get unfollow;
  String get followers;
  String get following;
  String get like;
  String get comment;
  String get share;
  String get save;
  String get all;

  // ── Categories ──
  String get businesses;
  String get tutors;
  String get charities;

  // Home page category cards
  String get places;
  String get findandshare;
  String get findandsharePostNotice;
  String get postTofindandshare;
  String get postedToFindandshare;
  String get verifiedAccessibility;
  String get learningSupport;
  String get supportAndVolunteering;
  String get questionsAndUpdates;
  String get communityFeed;

  // Home feed copy
  String get latestPosts;
  String get postsFromFollowing;
  String get noPostsYet;
  String get noFollowingPostsYet;
  String get followToSeePosts;
  String get createFirstPost;

  // ── Auth ──
  String get login;
  String get signup;
  String get forgotPassword;
  String get enterEmail;
  String get enterPassword;
  String get dontHaveAccount;
  String get alreadyHaveAccount;
  String get resetPassword;
  String get sendOtp;
  String get verifyOtp;
  String get newPassword;
  String get confirmPassword;
  // ── Auth: login ──
  String get password;
  String get emailRequired;
  String get enterValidEmail;
  String get passwordRequired;
  String get passwordMin6;
  String get loginFailedTryAgain;
  String get emailNotVerified;
  String get incorrectEmailOrPassword;
  String get noAccountFound;
  String get somethingWentWrongColon;
  String get createAccount;
  String get backToLogin;

  // ── Auth: forgot password ──
  String get resetYourPassword;
  String get forgotPasswordSubtitle;
  String get emailHintExample;
  String get pleaseEnterEmail;
  String get pleaseEnterValidEmail;
  String get resetCodeSent;
  String get pleaseWaitBeforeAnotherCode;
  String get noAccountFoundForEmail;
  String get failedToSendResetCode;
  // ── Auth: OTP ──
  String get enterVerificationCode;
  String otpSentTo(String email);
  String get otpCodeLabel;
  String get pleaseEnterOtp;
  String get otpMustBe6Digits;
  String get invalidOrExpiredOtp;
  String get otpVerifiedSuccessfully;
  String get otpExpired;
  String get otpInvalid;
  String get failedToVerifyOtp;
  String get otpResentSuccessfully;
  String get failedToResendOtp;
  String get resendOtp;
  String get back;

  // ── Auth: reset password ──
  String get createNewPassword;
  String get setANewPassword;
  String createSecurePasswordFor(String email);
  String get newPasswordLabel;
  String get confirmPasswordLabel;
  String get enterYourNewPassword;
  String get reEnterYourPassword;
  String get pleaseEnterNewPassword;
  String get passwordMin8;
  String get passwordNeedsUppercase;
  String get passwordNeedsLowercase;
  String get passwordNeedsNumber;
  String get pleaseConfirmPassword;
  String get passwordsDoNotMatch;
  String get passwordRequirementsHint;
  String get sessionExpired;
  String get chooseDifferentPassword;
  String get enterStrongerPassword;
  String get passwordUpdatedSuccessfully;
  String get failedToResetPassword;
  // ── Auth: account type ──
  String get chooseAccountType;
  String get chooseAccountTypeSubtitle;
  String get accountTypeCharity;
  String get accountTypeBusinessOwner;
  String get accountTypeTutor;
  String get accountTypeUser;

  // ── Auth: general signup ──
  String get createYourAccount;
  String get signupRolesSubtitle;
  String get fullNameRequired;
  String get fullNameMin3;
  String get fullNameLettersOnly;
  String get usernameRequired;
  String get usernameMin3;
  String get usernameMax20;
  String get usernameAllowedChars;
  String get confirmPasswordRequired;
  String get locationRequiredForAccount;
  String get signupFailed;
  String get accountCreatedVerifyEmail;
  String unknownAccountType(String type);
  String get errorColon;
  String get locationNoticeUser;
  String get verificationNoticeOther;
  String get continueToVerification;
  // ── Auth: verification signups (business/charity/tutor) ──
  String get submitForApproval;
  String get useCurrentLocation;
  String get pleaseShareLocation;
  String get uploadIdImage;
  String get idImageFormats;
  String get couldNotReadFile;
  String get failedToPickFile;
  String get missingSignupInfo;
  // Business signup
  String get businessSignUp;
  String get businessVerificationNotice;
  String get uploadBusinessPhotos;
  String get accessibilityPhotosHint;
  String photosSelected(int count);
  String get uploadCommercialRegister;
  String get fileFormatsHint;
  String get businessDocumentsNotice;
  String get selectBetween3And5Photos;
  String get imageCouldNotBeRead;
  String get failedToPickPhotos;
  String get pleaseUpload3To5Photos;
  String get pleaseUploadCommercialRegister;
  String get pleaseUploadIdImage;
  String get couldNotCreateBusinessAccount;
  String get businessSubmittedVerifyEmail;
  String get failedToSubmitBusiness;
  // Charity signup
  String get charitySignUp;
  String get charityVerificationNotice;
  String get charityNameLabel;
  String get charityNameRequired;
  String get enterValidCharityName;
  String get uploadCharityProof;
  String get charityDocumentsNotice;
  String get pleaseUploadCharityProof;
  String get missingSignupDataStartOver;
  String get charitySubmittedVerifyEmail;
  String get failedToSubmitCharity;
  // ── Auth: tutor signup ──
  String get tutorSignUp;
  String get tutorVerificationNotice;
  String get yourBio;
  String get bioHint;
  String get bioRequired;
  String get bioMinChars;
  String get subjectsYouTeach;
  String get yourLocation;
  String get locationPrivateNote;
  String get uploadCertificateProof;
  String get certificateFormatsHint;
  String get uploadCvSpecialization;
  String get tutorDocumentsNotice;
  String get pleaseAddSubject;
  String get pleaseUploadCertificate;
  String get pleaseUploadCv;
  String get missingAccountInfo;
  String get passwordMissingGoBack;
  String get tutorSubmittedForVerification;
  String get failedToSubmitTutor;
  // ── Widgets: location picker & subject chips ──
  String get currentLocation;
  String get tapToDetectGps;
  String get locationSavedNote;
  String get addSubjectHint;
  String get addAnotherHint;
  String get suggestions;

  // ── Messages: conversation list ──
  String get noMessagesYet;
  String get unknown;
  String get deleteChat;
  String get youBothBlockedShort;
  String get youBlockedThisUser;
  String get thisUserBlockedYou;
  String get messagesHidden;
  String get timeNow;
  String minutesShort(int count);
  String hoursShort(int count);
  String daysShort(int count);

  // ── Messages: chat screen ──
  String get ableUser;
  String get cannotBlockMissingInfo;
  String get blockUserQuestion;
  String get blockUserBody;
  String get block;
  String get unblock;
  String get userBlocked;
  String blockFailed(String error);
  String get userUnblocked;
  String unblockFailed(String error);
  String get profileUnavailable;
  String get profileInfoMissing;
  String get edited;
  String get sendingStatus;
  String get seenStatus;
  String get startTheConversation;
  String get messageWillAppearAfterUnblock;
  String get messageHintDefault;
  String get messageWillAppearToThem;
  String sendFailed(String error);
  String get waitUntilSent;
  String get editMessage;
  String get messageDialogHint;
  String get messageUpdated;
  String editFailed(String error);
  String get deleteMessageQuestion;
  String get deleteMessageBody;
  String get delete;
  String get deleteMessageMenu;
  String get deleteForMe;       // ✅ NEW
  String get deleteForEveryone; // ✅ NEW

  // ── Notifications ──
  String get markAllRead;
  String get noNotificationsYet;
  String get postNoLongerAvailableNotif;
  String get userProfileNotAvailable;
  String get notifActionLiked;
  String get notifActionCommented;
  String get notifActionFollowed;
  String get notifActionMessaged;
  String get notifActionBooking;

  // ── Create post ──
  String get createPostTitle;
  String get createAPost;
  String get communityPostNotice;
  String get homePostNotice;
  String get accountLoading;
  String get addAPhoto;
  String get tapToChoose;
  String get cameraOrGallery;
  String get addAVideo;
  String get upTo2Minutes;
  String get recordVideo;
  String get galleryVideo;
  String get videoSelected;
  String get describeProduct;
  String get whatsOnYourMind;
  String get donationLinkHint;
  String get donationLinkNote;
  String get postToCommunity;
  String get postToHome;
  String get addDescriptionImageOrVideo;
  String get accountStillLoading;
  String get noUserLoggedIn;
  String get accountNotFound;
  String get postedToCommunity;
  String get postCreatedSuccess;
  String get tagUser;
  String get tagEducational;
  String get tagBusiness;
  String get tagCharity;

  // ── Post details ──
  String get postTitle;
  String couldNotLoadPost(String error);
  String get postDeletedByAuthor;
  // ── Post card ──
  String get postRoleClient;
  String get postRoleTutor;
  String get postRoleBusiness;
  String get postRoleCharity;
  String get removedFromSaved;
  String get postSavedSuccess;
  String saveFailedError(String error);
  String likeFailedError(String error);
  String get editPost;
  String get deletePost;
  String get reportPost;
  String get reportPostSubtitle;
  String get deletePostQuestion;
  String get deletePostBody;
  String get postDeleted;
  String deletePostFailedError(String error);
  String get reportPostReasonHint;
  String get reportPostBody;
  String get pleaseWriteShortReason;
  String get reportSentThanks;
  String get couldNotSendReportTryAgain;
  String get editYourPost;
  String newImageLabel(String name);
  String newVideoLabel(String name);
  String get noImageSelected;
  String get currentVideoAttached;
  String get imageLabel;
  String get videoLabel;
  String get postCannotBeEmpty;
  String get postUpdated;
  String editFailedError(String error);
  String get shareToFollowing;
  String get notFollowingAnyone;
  String get postShared;
  String shareFailedError(String error);
  String get seeTranslation;
  String get seeOriginal;
  String get translating;
  String get couldNotTranslate;
  String get commentsTitle;
  String get noCommentsYetPeriod;
  String get addACommentHint;
  String get editComment;
  String get commentDialogHint;
  String get commentUpdated;
  String editCommentFailedError(String error);
  String get deleteCommentQuestion;
  String get deleteCommentBody;
  String get commentDeleted;
  String deleteCommentFailedError(String error);
  String commentFailedError(String error);
  String get editCommentMenu;
  String get deleteCommentMenu;
  String get donateNow;
  String get invalidDonationLink;
  String get couldNotOpenDonationLink;
  // ── Map ──
  String get mapTitle;
  String get nearbyPlaces;
  String get youMarker;
  String get searchPlaces;
  String get noPlacesFound;
  String get noPlacesFoundYet;
  String get mapNearbyHeading;
  String get mapNearbySubtitle;
  String get suggestedPlaces;
  String get openMap;
  String get viewDetails;
  String get accessibilityInfoPending;

  // ── Place details ──
  String get placeKindCharity;
  String get placeKindBusiness;
  String get ratingNew;
  String get viewProfile;
  String get directionsComingSoon;
  String get shareComingSoon;
  String get reviews;
  String get writeReview;
  String get writeReviewShort;
  String get noReviewsYet;
  String get noReviewsBeFirst;
  String couldNotLoadReviews(String error);
  String get editYourReview;
  String get reviewCommentHint;
  String get thanksForReview;
  String couldNotSaveReview(String error);
  String weeksAgo(int count);
  String monthsAgo(int count);
  String yearsAgo(int count);
  // ── Connections ──
  String followsCountSubtitle(int count);
  String followersCountSubtitle(int count);
  String get notFollowingAnyoneProfile;
  String get noFollowersProfile;
  String get messageDeleted;
  String deleteFailed(String error);
  String get onlyEditOwnMessages;
  String get loadingPost;
  String get postUnavailable;
  String get sharedAPost;
  String get youBothBlocked;
  String get youBlockedAbleUser;
  String get ableUserBlockedYou;
  String get blockUserMenu;
  String get unblockUserMenu;
  // ── Find & Share ──
  String get findAndShare;
  String get findAndShareSubtitle;
  String get findAndSharePostDetails;
  String get somethingWentWrong;
  String get noPostsShareHint;
  String get videoBadge;
  String get couldNotLoadVideo;
  String get couldNotLoadImage;
  String get descriptionLabel;
  String get contactOwner;
  String get mustBeSignedInToMessage;
  String get ownerInfoMissing;
  String get cannotMessageOwnPost;
  String couldNotOpenChat(String error);
  String get deletePostQuestionFs;
  String get deletePostBodyFs;
  String get deletingPost;
  // ── Charities ──
  String get noLocation;
  String get supportACharity;
  String get charitiesWillShareHere;
  String campaignsSubtitle(int count);
  String get noCharityPostsYet;
  String get whenCharitiesPostHint;
  String couldNotLoadCharityPosts(String error);
  String get editCharityPost;
  String get donationLinkOptional;
  String get noImageAttached;
  String get changeImage;
  String get saveChanges;
  String get updateFailedTryAgain;
  String get noDonationLink;
  String get charityNoDonationLink;
  String get charityFallbackName;
  String get searchCharities;
  String get noCharitiesMatchSearch;

  // ── Tutors ──
  String get searchTutors;
  String tutorsAvailable(int count);
  String get noTutorsFound;
  String get unknownSubject;
  String get onlyClientsCanMessageTutors;
  String chatError(String error);
  String get openProfile;
  String get startChat;
  String get profileButton;
  String get chatButton;

  // ── Profile: role labels ──
  String get roleClient;
  String get roleTutor;
  String get roleBusiness;
  String get roleCharity;

  // ── Profile: header & stats ──
  String get posts;
  String get rating;
  String get message;
  String get more;
  String get noDescriptionYet;
  String get noPostsYetPeriod;
  String get profileNotFound;
  String get tryAgain;
  String get editProfile;
  String get saving;

  // ── Profile: edit sheet ──
  String get editProfileTitle;
  String get fullName;
  String get username;
  String get location;
  String get charityName;
  String get camera;
  String get gallery;

  // ── Profile: rating ──
  String rateName(String name);
  String get submitRating;
  String get rateOutOfFive;
  String yourRating(String value);
  String get ratingSaved;
  String get ratingFailed;

  // ── Profile: report ──
  String reportName(String name);
  String get reportUser;
  String get reportReasonHint;
  String get pleaseWriteReason;
  String get reportSubmitted;
  String get couldNotSendReport;
  String get sending;
  String get submitReport;

  // ── Profile: snackbars & validation ──
  String get profilePhotoUpdated;
  String get uploadFailed;
  String get saveFailed;
  String get profileUpdated;
  String get nameAndUsernameRequired;
  String get fullNameNoNumbers;
  String get charityNameNoNumbers;
  String get locationRequired;
  String get charityNameAndLocationRequired;
  String get pleaseLoginFirst;
  String get followFailed;
  String get openChatFailed;

  // ── Places (businesses screen) ──
  String get searchBusinesses;
  String get clear;
  String get filters;
  String get reset;
  String get sortBy;
  String get maximumDistance;
  String get anyDistance;
  String get enableLocationForDistance;
  String get applyFilters;
  String withinKm(String km);
  String get sortTopRated;
  String get sortMostReviewed;
  String get sortClosest;
  String get sortAlphabetical;
  String get requestABusiness;
  String get requestBusinessBody;
  String get close;
  String get submit;
  String get requestThanks;
  String get couldNotLoadBusinesses;
  String get noBusinessesMatch;
  String get noBusinessesMatchBody;
  String get noRatingsYet;
  String kmAway(String km);

  // ── Accessibility features ──
  String get featureWheelchairAccess;
  String get featureServiceAnimal;
  String get featureSignLanguage;
  String get featureBraille;
  String get featureSensoryFriendly;
  String get featureAccessibleParking;

  // ── Support ──
  String get pleaseLogInFirst;
  String get pleaseLogInToUseSupport;
  String get pleaseLogInToViewTicket;
  String get createSupportTicket;
  String get wellGetBackToYou;
  String get ticketTitle;
  String get ticketTitleHint;
  String get category;
  String get priority;
  String get messageLabel;
  String get messageHint;
  String get creating;
  String get createTicket;
  String get titleAndMessageRequired;
  String get supportTicketCreated;
  String get failedToCreateTicket;
  String get myTickets;
  String get noTicketsYet;
  String get couldNotLoadTickets;
  String get couldNotLoadMessages;
  String get supportTicketFallback;
  String lastMessageAt(String date);
  String get typeYourMessage;
  String get pleaseTypeMessage;
  String get failedToSendMessage;
  String get ticketClosedToast;
  String get failedToCloseTicket;
  String get ticketReopenedToast;
  String get failedToReopenTicket;
  String get iReopenedThisTicket;
  String get thisTicketIsClosed;
  String get reopen;
  String get closeTicket;
  // Ticket status labels
  String get statusWaitingForSupport;
  String get statusSupportReplied;
  String get statusClosed;
  String get statusOpen;
  // Category labels
  String get categoryGeneral;
  String get categoryAccount;
  String get categoryPayments;
  String get categoryBug;
  String get categorySafety;
  // Priority labels
  String get priorityLow;
  String get priorityNormal;
  String get priorityHigh;
  String get priorityUrgent;
  // Message bubble senders
  String senderSystem(String date);
  String senderYou(String date);
  String senderSupport(String date);

  // ── Misc ──
  String get error;
  String get retry;
  String get loading;
  String get success;

  // ── Time ──
  String get justNow;
  String minutesAgo(int count);
  String hoursAgo(int count);
  String daysAgo(int count);
}

// ──────────────────────────────────────────────
// ENGLISH
// ──────────────────────────────────────────────
class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn() : super('en');

  @override String get appName => 'Able+';

  @override String get settings => 'Settings';
  @override String get darkMode => 'Dark Mode';
  @override String get language => 'Language';
  @override String get textToSpeech => 'Text to Speech';
  @override String get colorBlindMode => 'Color Blind Mode';
  @override String get colorBlindModeDesc =>
      'Applies a Deuteranopia filter to help distinguish colors';
  @override String get privacySettings => 'Privacy Settings';
  @override String get appearance => 'Appearance';
  @override String get accessibility => 'Accessibility';
  @override String get deuteranopiaFilter => 'Deuteranopia filter';
  @override String get howColorsAppear => 'How colors appear with this filter:';
  @override String get normal => 'Normal';
  @override String get withFilter => 'With filter';

  @override String get home => 'Home';
  @override String get map => 'Map';
  @override String get messages => 'Messages';
  @override String get profile => 'Profile';
  @override String get notifications => 'Notifications';

  @override String get myActivity => 'My Activity';
  @override String get support => 'Support';
  @override String get aboutUs => 'About Us';
  @override String get logOut => 'Log out';
  @override String get logOutConfirm => 'Are you sure you want to log out?';
  @override String get cancel => 'Cancel';
  @override String get confirm => 'Confirm';

  @override String get recentActivity => 'Recent activity';
  @override String get recentActivityDesc =>
      'Your likes, comments and follows will show up here so you can pick up where you left off.';
  @override String get noActivityYet => 'No activity yet';
  @override String get noCommentsYet => 'No comments yet';
  @override String get noLikesYet => 'No likes yet';
  @override String get noSavedYet => 'No saved posts yet';
  @override String get comments => 'Comments';
  @override String get likes => 'Likes';
  @override String get saved => 'Saved';
  @override String get youLikedAPost => 'You liked a post';
  @override String get youCommentedOnAPost => 'You commented on a post';
  @override String get youSavedAPost => 'You saved a post';
  @override String get tapToViewPost => 'Tap to view the post';
  @override String get tapToOpenProfile => 'Tap to open profile';
  @override String youFollowed(String name) => 'You followed $name';
  @override String get someone => 'someone';
  @override String get postNoLongerAvailable => 'This post is no longer available.';
  @override String get profileNotAvailable => 'Profile not available.';
  @override String get couldNotLoadActivity => 'Could not load your activity.';

  @override String get ourTeam => 'Our Team';
  @override String get founderCeo => 'Founder & CEO';
  @override String get email => 'Email';
  @override String get phone => 'Phone';
  @override String get couldNotOpenEmail => 'Could not open email app';
  @override String get couldNotOpenPhone => 'Could not open phone app';
  @override String get ableTeam => 'Able+ Team';
  @override String get aboutUsBody =>
      'We are a team dedicated to providing the best services in a professional and simple way. Our goal is to create a great customer experience through quality, trust, and attention to detail.';

  @override String get sendMessage => 'Send a message';
  @override String get typeMessage => 'Type a message...';
  @override String get noMessages => 'No messages yet';
  @override String get startConversation => 'Start a conversation';

  @override String get createPost => 'Create Post';
  @override String get post => 'Post';
  @override String get title => 'Title';
  @override String get description => 'Description';
  @override String get addImage => 'Add Image';
  @override String get addVideo => 'Add Video';

  @override String get search => 'Search';
  @override String get filter => 'Filter';
  @override String get noResults => 'No results found';
  @override String get follow => 'Follow';
  @override String get unfollow => 'Unfollow';
  @override String get followers => 'Followers';
  @override String get following => 'Following';
  @override String get like => 'Like';
  @override String get comment => 'Comment';
  @override String get share => 'Share';
  @override String get save => 'Save';
  @override String get all => 'All';

  @override String get businesses => 'Businesses';
  @override String get tutors => 'Tutors';
  @override String get charities => 'Charities';

  @override String get places => 'Places';
  @override String get findandshare => 'Find and share';
  @override String get verifiedAccessibility => 'Verified accessibility';
  @override String get learningSupport => 'Learning support';
  @override String get supportAndVolunteering => 'Support & volunteering';
  @override String get questionsAndUpdates => 'Questions and updates';
  @override String get communityFeed => 'Community feed';

  @override String get latestPosts => 'Latest posts shared by users.';
  @override String get postsFromFollowing => 'Posts from people you follow.';
  @override String get noPostsYet => 'No posts yet';
  @override String get noFollowingPostsYet => 'No following posts yet';
  @override String get followToSeePosts =>
      'Follow users to see their posts here, or switch back to All.';
  @override String get createFirstPost =>
      'Create your first post to share with everyone.';

  @override String get login => 'Login';
  @override String get signup => 'Sign Up';
  @override String get forgotPassword => 'Forgot Password';
  @override String get enterEmail => 'Enter your email';
  @override String get enterPassword => 'Enter your password';
  @override String get dontHaveAccount => "Don't have an account?";
  @override String get alreadyHaveAccount => 'Already have an account?';
  @override String get resetPassword => 'Reset Password';
  @override String get sendOtp => 'Send OTP';
  @override String get verifyOtp => 'Verify OTP';
  @override String get newPassword => 'New Password';
  @override String get confirmPassword => 'Confirm Password';
  @override String get password => 'Password';
  @override String get emailRequired => 'Email is required';
  @override String get enterValidEmail => 'Enter a valid email';
  @override String get passwordRequired => 'Password is required';
  @override String get passwordMin6 => 'Password must be at least 6 characters';
  @override String get loginFailedTryAgain => 'Login failed. Please try again!';
  @override String get emailNotVerified =>
      'Your email is not verified yet. Please check your inbox and verify it first.';
  @override String get incorrectEmailOrPassword => 'Incorrect email or password.';
  @override String get noAccountFound =>
      'No account found for this email. Please sign up first.';
  @override String get somethingWentWrongColon => 'Something went wrong';
  @override String get createAccount => 'Create account';
  @override String get backToLogin => 'Back to Login';

  @override String get resetYourPassword => 'Reset your password';
  @override String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send a verification code (OTP).';
  @override String get emailHintExample => 'example@email.com';
  @override String get pleaseEnterEmail => 'Please enter your email';
  @override String get pleaseEnterValidEmail => 'Please enter a valid email';
  @override String get resetCodeSent => 'Reset code sent to your email';
  @override String get pleaseWaitBeforeAnotherCode =>
      'Please wait before requesting another code.';
  @override String get noAccountFoundForEmail => 'No account found for this email.';
  @override String get failedToSendResetCode => 'Failed to send reset code';
  @override String get enterVerificationCode => 'Enter verification code';
  @override String otpSentTo(String email) => 'We sent a 6-digit code to\n$email';
  @override String get otpCodeLabel => 'OTP Code';
  @override String get pleaseEnterOtp => 'Please enter the OTP';
  @override String get otpMustBe6Digits => 'OTP must be 6 digits';
  @override String get invalidOrExpiredOtp => 'Invalid or expired OTP';
  @override String get otpVerifiedSuccessfully => 'OTP verified successfully';
  @override String get otpExpired => 'The OTP has expired. Please request a new one.';
  @override String get otpInvalid =>
      'The OTP is invalid. Please check the code and try again.';
  @override String get failedToVerifyOtp => 'Failed to verify OTP';
  @override String get otpResentSuccessfully => 'OTP resent successfully';
  @override String get failedToResendOtp => 'Failed to resend OTP';
  @override String get resendOtp => 'Resend OTP';
  @override String get back => 'Back';

  @override String get createNewPassword => 'Create New Password';
  @override String get setANewPassword => 'Set a New Password';
  @override String createSecurePasswordFor(String email) =>
      'Create a secure new password for\n$email';
  @override String get newPasswordLabel => 'New Password';
  @override String get confirmPasswordLabel => 'Confirm Password';
  @override String get enterYourNewPassword => 'Enter your new password';
  @override String get reEnterYourPassword => 'Re-enter your password';
  @override String get pleaseEnterNewPassword => 'Please enter a new password';
  @override String get passwordMin8 => 'Password must be at least 8 characters';
  @override String get passwordNeedsUppercase =>
      'Password must contain at least one uppercase letter';
  @override String get passwordNeedsLowercase =>
      'Password must contain at least one lowercase letter';
  @override String get passwordNeedsNumber =>
      'Password must contain at least one number';
  @override String get pleaseConfirmPassword => 'Please confirm your password';
  @override String get passwordsDoNotMatch => 'Passwords do not match';
  @override String get passwordRequirementsHint =>
      'Your password should include uppercase and lowercase letters, plus at least one number.';
  @override String get sessionExpired =>
      'Session expired. Please login and try again.';
  @override String get chooseDifferentPassword =>
      'Please choose a different password from the old one.';
  @override String get enterStrongerPassword =>
      'Please enter a stronger password and try again.';
  @override String get passwordUpdatedSuccessfully => 'Password updated successfully';
  @override String get failedToResetPassword => 'Failed to reset password';
  @override String get chooseAccountType => 'Choose Account Type';
  @override String get chooseAccountTypeSubtitle =>
      'Select your account type to continue to sign up.';
  @override String get accountTypeCharity => 'Charity';
  @override String get accountTypeBusinessOwner => 'Business Owner';
  @override String get accountTypeTutor => 'Tutor';
  @override String get accountTypeUser => 'User';

  @override String get createYourAccount => 'Create your account';
  @override String get signupRolesSubtitle =>
      'Users can enter directly. Tutors, businesses, and charities will send an approval request to the admin.';
  @override String get fullNameRequired => 'Full Name is required';
  @override String get fullNameMin3 => 'Full Name must be at least 3 characters';
  @override String get fullNameLettersOnly => 'Full Name can contain letters only';
  @override String get usernameRequired => 'Username is required';
  @override String get usernameMin3 => 'Username must be at least 3 characters';
  @override String get usernameMax20 => 'Username must not exceed 20 characters';
  @override String get usernameAllowedChars =>
      'Username can contain letters, numbers, and underscore only';
  @override String get confirmPasswordRequired => 'Confirm Password is required';
  @override String get locationRequiredForAccount =>
      'Location is required to create an account.';
  @override String get signupFailed => 'Signup failed';
  @override String get accountCreatedVerifyEmail =>
      'Account created. Please verify your email.';
  @override String unknownAccountType(String type) => 'Unknown account type: $type';
  @override String get errorColon => 'Error';
  @override String get locationNoticeUser =>
      'After tapping the button, you will be asked to share your location so we can show you nearby places.';
  @override String get verificationNoticeOther =>
      'This account type requires document review before it becomes active.';
  @override String get continueToVerification => 'Continue to verification';
  @override String get submitForApproval => 'Submit for Approval';
  @override String get useCurrentLocation => 'Use current location';
  @override String get pleaseShareLocation =>
      'Please share your current location to continue.';
  @override String get uploadIdImage => 'Upload ID image';
  @override String get idImageFormats => 'JPG, JPEG, or PNG';
  @override String get couldNotReadFile => 'Could not read the selected file.';
  @override String get failedToPickFile => 'Failed to pick file';
  @override String get missingSignupInfo =>
      'Missing signup information. Please go back and sign up again.';

  @override String get businessSignUp => 'Business Sign Up';
  @override String get businessVerificationNotice =>
      'Additional verification is required for business accounts before approval.';
  @override String get uploadBusinessPhotos => 'Upload 3-5 business photos';
  @override String get accessibilityPhotosHint =>
      'Accessibility photos of the business';
  @override String photosSelected(int count) => '$count photos selected';
  @override String get uploadCommercialRegister => 'Upload commercial register';
  @override String get fileFormatsHint => 'PDF, image, or document';
  @override String get businessDocumentsNotice =>
      'These documents are required to verify your business account.';
  @override String get selectBetween3And5Photos =>
      'Please select between 3 and 5 business photos.';
  @override String get imageCouldNotBeRead =>
      'One of the selected images could not be read.';
  @override String get failedToPickPhotos => 'Failed to pick business photos';
  @override String get pleaseUpload3To5Photos =>
      'Please upload 3 to 5 business photos.';
  @override String get pleaseUploadCommercialRegister =>
      'Please upload the commercial register.';
  @override String get pleaseUploadIdImage => 'Please upload the ID image.';
  @override String get couldNotCreateBusinessAccount =>
      'Could not create business account.';
  @override String get businessSubmittedVerifyEmail =>
      'Business account submitted successfully. Please verify your email.';
  @override String get failedToSubmitBusiness => 'Failed to submit business signup';

  @override String get charitySignUp => 'Charity Sign Up';
  @override String get charityVerificationNotice =>
      'Additional verification is required for charity accounts before approval.';
  @override String get charityNameLabel => 'Charity name';
  @override String get charityNameRequired => 'Charity name is required';
  @override String get enterValidCharityName => 'Enter a valid charity name';
  @override String get uploadCharityProof => 'Upload charity proof';
  @override String get charityDocumentsNotice =>
      'These documents are required to verify your charity account.';
  @override String get pleaseUploadCharityProof => 'Please upload charity proof.';
  @override String get missingSignupDataStartOver =>
      'Missing signup data. Please start over.';
  @override String get charitySubmittedVerifyEmail =>
      'Charity account submitted successfully. Please verify your email.';
  @override String get failedToSubmitCharity => 'Failed to submit charity signup';

  @override String get tutorSignUp => 'Tutor Sign Up';
  @override String get tutorVerificationNotice =>
      'Additional verification is required for tutor accounts before approval.';
  @override String get yourBio => 'Your bio';
  @override String get bioHint =>
      'Tell students about your experience, teaching style, and what makes you a great tutor.';
  @override String get bioRequired => 'Bio is required';
  @override String get bioMinChars => 'Please write at least 20 characters';
  @override String get subjectsYouTeach => 'Subjects you teach';
  @override String get yourLocation => 'Your location';
  @override String get locationPrivateNote =>
      'Your location is private. It is only used to show you nearby places.';
  @override String get uploadCertificateProof => 'Upload certificate proof';
  @override String get certificateFormatsHint => 'PDF, Image or Document';
  @override String get uploadCvSpecialization => 'Upload CV / specialization';
  @override String get tutorDocumentsNotice =>
      'These documents are required to verify your tutor account.';
  @override String get pleaseAddSubject =>
      'Please add at least one subject you teach.';
  @override String get pleaseUploadCertificate =>
      'Please upload your certificate proof.';
  @override String get pleaseUploadCv =>
      'Please upload your CV or specialization file.';
  @override String get missingAccountInfo =>
      'Missing account information. Please go back and complete signup again.';
  @override String get passwordMissingGoBack =>
      'Password is missing. Please go back and complete signup again.';
  @override String get tutorSubmittedForVerification =>
      'Tutor account submitted successfully for verification.';
  @override String get failedToSubmitTutor => 'Failed to submit tutor signup';

  @override String get currentLocation => 'Current location';
  @override String get tapToDetectGps => 'Tap to detect using GPS';
  @override String get locationSavedNote =>
      'Location saved. You can add a city/area later from your profile.';
  @override String get addSubjectHint => 'Add a subject and press enter';
  @override String get addAnotherHint => 'Add another';
  @override String get suggestions => 'Suggestions';

  @override String get noMessagesYet => 'No messages yet.';
  @override String get unknown => 'Unknown';
  @override String get deleteChat => 'Delete Chat';
  @override String get youBothBlockedShort => 'You both blocked each other';
  @override String get youBlockedThisUser => 'You blocked this user';
  @override String get thisUserBlockedYou => 'This user blocked you';
  @override String get messagesHidden => 'Messages hidden';
  @override String get timeNow => 'now';
  @override String minutesShort(int count) => '${count}m';
  @override String hoursShort(int count) => '${count}h';
  @override String daysShort(int count) => '${count}d';

  @override String get ableUser => 'AbleUser';
  @override String get cannotBlockMissingInfo => 'Cannot block: missing user info.';
  @override String get blockUserQuestion => 'Block user?';
  @override String get blockUserBody =>
      'They will appear as AbleUser. New messages will be hidden until unblock.';
  @override String get block => 'Block';
  @override String get unblock => 'Unblock';
  @override String get userBlocked => 'User blocked.';
  @override String blockFailed(String error) => 'Block failed: $error';
  @override String get userUnblocked => 'User unblocked.';
  @override String unblockFailed(String error) => 'Unblock failed: $error';
  @override String get profileUnavailable => 'Profile unavailable.';
  @override String get profileInfoMissing => 'Profile info is missing.';
  @override String get edited => 'Edited';
  @override String get sendingStatus => 'Sending...';
  @override String get seenStatus => 'Seen';
  @override String get startTheConversation => 'Start the conversation.';
  @override String get messageWillAppearAfterUnblock =>
      'Message will appear after unblock...';
  @override String get messageHintDefault => 'Message...';
  @override String get messageWillAppearToThem =>
      'Message will appear to them after unblock.';
  @override String sendFailed(String error) => 'Send failed: $error';
  @override String get waitUntilSent => 'Wait until the message is sent.';
  @override String get editMessage => 'Edit message';
  @override String get messageDialogHint => 'Message...';
  @override String get messageUpdated => 'Message updated.';
  @override String editFailed(String error) => 'Edit failed: $error';
  @override String get deleteMessageQuestion => 'Delete message?';
  @override String get deleteMessageBody =>
      'Are you sure you want to delete this message?';
  @override String get delete => 'Delete';
  @override String get deleteMessageMenu => 'Delete message';
  @override String get deleteForMe => 'Delete for me';           // ✅ NEW
  @override String get deleteForEveryone => 'Delete for everyone'; // ✅ NEW

  @override String get markAllRead => 'Mark all read';
  @override String get noNotificationsYet => 'No notifications yet';
  @override String get postNoLongerAvailableNotif =>
      'This post is no longer available.';
  @override String get userProfileNotAvailable => 'User profile not available.';
  @override String get notifActionLiked => 'liked your post';
  @override String get notifActionCommented => 'commented on your post';
  @override String get notifActionFollowed => 'started following you';
  @override String get notifActionMessaged => 'sent you a message';
  @override String get notifActionBooking => 'sent you a booking';

  @override String get createPostTitle => 'Create Post';
  @override String get createAPost => 'Create a post';
  @override String get communityPostNotice => findandsharePostNotice;
  @override String get findandsharePostNotice =>
      'This post will be shared in the community.';
  @override String get homePostNotice =>
      'This post will appear on your home feed.';
  @override String get accountLoading => 'Loading...';
  @override String get addAPhoto => 'Add a photo';
  @override String get tapToChoose => 'Tap to choose';
  @override String get cameraOrGallery => 'Camera or gallery';
  @override String get addAVideo => 'Add a video';
  @override String get upTo2Minutes => 'Up to 2 minutes';
  @override String get recordVideo => 'Record video';
  @override String get galleryVideo => 'Gallery video';
  @override String get videoSelected => 'Video selected';
  @override String get describeProduct => 'Describe the product...';
  @override String get whatsOnYourMind => "What's on your mind?";
  @override String get donationLinkHint => 'Donation link (https://...)';
  @override String get donationLinkNote =>
      'Optional. A "Donate now" button will appear on your post and open this link.';
  @override String get postToCommunity => postTofindandshare;
  @override String get postTofindandshare => 'Post to Findandshare';
  @override String get postToHome => 'Post to home';
  @override String get addDescriptionImageOrVideo =>
      'Add a description, image, or video';
  @override String get accountStillLoading => 'Account is still loading';
  @override String get noUserLoggedIn => 'No user is logged in. Please login first.';
  @override String get accountNotFound => 'Account not found. Please login again.';
  @override String get postedToCommunity => postedToFindandshare;
  @override String get postedToFindandshare => 'Posted to Findandshare successfully';
  @override String get postCreatedSuccess => 'Post created successfully';
  @override String get tagUser => 'User';
  @override String get tagEducational => 'Educational';
  @override String get tagBusiness => 'Business';
  @override String get tagCharity => 'Charity';

  @override String get postTitle => 'Post';
  @override String couldNotLoadPost(String error) =>
      'Could not load this post.\n$error';
  @override String get postDeletedByAuthor =>
      'It may have been deleted by its author.';
  @override String get postRoleClient => 'Client';
  @override String get postRoleTutor => 'Tutor';
  @override String get postRoleBusiness => 'Business';
  @override String get postRoleCharity => 'Charity';
  @override String get removedFromSaved => 'Removed from saved posts.';
  @override String get postSavedSuccess => 'Post saved successfully.';
  @override String saveFailedError(String error) => 'Save failed: $error';
  @override String likeFailedError(String error) => 'Like failed: $error';
  @override String get editPost => 'Edit Post';
  @override String get deletePost => 'Delete Post';
  @override String get reportPost => 'Report Post';
  @override String get reportPostSubtitle =>
      'Send this post to the admin for review.';
  @override String get deletePostQuestion => 'Delete Post?';
  @override String get deletePostBody =>
      'Are you sure you want to delete this post?';
  @override String get postDeleted => 'Post deleted.';
  @override String deletePostFailedError(String error) => 'Delete failed: $error';
  @override String get reportPostReasonHint =>
      'Reason (e.g. spam, harassment, inappropriate…)';
  @override String get reportPostBody =>
      'Tell the admin why you think this post should be reviewed. Your report is private.';
  @override String get pleaseWriteShortReason => 'Please write a short reason.';
  @override String get reportSentThanks => 'Report sent to admin. Thank you.';
  @override String get couldNotSendReportTryAgain =>
      'Could not send report. Try again.';
  @override String get editYourPost => 'Edit your post...';
  @override String newImageLabel(String name) => 'New image: $name';
  @override String newVideoLabel(String name) => 'New video: $name';
  @override String get noImageSelected => 'No image selected.';
  @override String get currentVideoAttached => 'Current video attached';
  @override String get imageLabel => 'Image';
  @override String get videoLabel => 'Video';
  @override String get postCannotBeEmpty => 'Post cannot be empty.';
  @override String get postUpdated => 'Post updated.';
  @override String editFailedError(String error) => 'Edit failed: $error';
  @override String get shareToFollowing => 'Share to following';
  @override String get notFollowingAnyone => 'You are not following anyone yet.';
  @override String get postShared => 'Post shared.';
  @override String shareFailedError(String error) => 'Share failed: $error';
  @override String get seeTranslation => 'See translation';
  @override String get seeOriginal => 'See original';
  @override String get translating => 'Translating…';
  @override String get couldNotTranslate => 'Could not translate. Try again.';
  @override String get commentsTitle => 'Comments';
  @override String get noCommentsYetPeriod => 'No comments yet.';
  @override String get addACommentHint => 'Add a comment...';
  @override String get editComment => 'Edit comment';
  @override String get commentDialogHint => 'Comment...';
  @override String get commentUpdated => 'Comment updated.';
  @override String editCommentFailedError(String error) =>
      'Edit comment failed: $error';
  @override String get deleteCommentQuestion => 'Delete comment?';
  @override String get deleteCommentBody =>
      'Are you sure you want to delete this comment?';
  @override String get commentDeleted => 'Comment deleted.';
  @override String deleteCommentFailedError(String error) =>
      'Delete comment failed: $error';
  @override String commentFailedError(String error) => 'Comment failed: $error';
  @override String get editCommentMenu => 'Edit comment';
  @override String get deleteCommentMenu => 'Delete comment';
  @override String get donateNow => 'Donate now';
  @override String get invalidDonationLink => 'Invalid donation link.';
  @override String get couldNotOpenDonationLink =>
      'Could not open the donation link.';

  @override String get mapTitle => 'Map';
  @override String get nearbyPlaces => 'Nearby Places';
  @override String get youMarker => 'You';
  @override String get searchPlaces => 'Search places...';
  @override String get noPlacesFound => 'No places found.';
  @override String get noPlacesFoundYet => 'No places found yet.';
  @override String get mapNearbyHeading => 'Map & nearby accessibility spots';
  @override String get mapNearbySubtitle =>
      'Browse trusted locations and review key accessibility features before visiting.';
  @override String get suggestedPlaces => 'Suggested places';
  @override String get openMap => 'Open';
  @override String get viewDetails => 'View details';
  @override String get accessibilityInfoPending => 'Accessibility info pending';

  @override String get placeKindCharity => 'Charity';
  @override String get placeKindBusiness => 'Business';
  @override String get ratingNew => 'New';
  @override String get viewProfile => 'View Profile';
  @override String get directionsComingSoon =>
      'Directions will open in your map app soon.';
  @override String get shareComingSoon => 'Share coming soon.';
  @override String get reviews => 'Reviews';
  @override String get writeReview => 'Write a review';
  @override String get writeReviewShort => 'Write';
  @override String get noReviewsYet => 'No reviews yet.';
  @override String get noReviewsBeFirst =>
      'No reviews yet. Be the first to write one.';
  @override String couldNotLoadReviews(String error) =>
      'Could not load reviews: $error';
  @override String get editYourReview => 'Edit your review';
  @override String get reviewCommentHint =>
      'Share details about your visit (optional)';
  @override String get thanksForReview => 'Thanks for your review.';
  @override String couldNotSaveReview(String error) =>
      'Could not save review: $error';
  @override String weeksAgo(int count) => '${count}w ago';
  @override String monthsAgo(int count) => '${count}mo ago';
  @override String yearsAgo(int count) => '${count}y ago';
  @override String followsCountSubtitle(int count) =>
      '$count people this profile follows';
  @override String followersCountSubtitle(int count) =>
      '$count people follow this profile';
  @override String get notFollowingAnyoneProfile =>
      'This profile is not following anyone yet.';
  @override String get noFollowersProfile =>
      'No one is following this profile yet.';
  @override String get messageDeleted => 'Message deleted.';
  @override String deleteFailed(String error) => 'Delete failed: $error';
  @override String get onlyEditOwnMessages =>
      'You can only edit or delete your own messages.';
  @override String get loadingPost => 'Loading post...';
  @override String get postUnavailable => 'Post unavailable';
  @override String get sharedAPost => 'Shared a post';
  @override String get youBothBlocked =>
      'You both blocked each other. Messages are hidden until unblock.';
  @override String get youBlockedAbleUser =>
      'You blocked this user. New messages are hidden until unblock.';
  @override String get ableUserBlockedYou =>
      'This user blocked you. New messages are hidden until unblock.';
  @override String get blockUserMenu => 'Block user';
  @override String get unblockUserMenu => 'Unblock user';

  @override String get findAndShare => 'Find & Share';
  @override String get findAndShareSubtitle =>
      'Find useful products and share what can help others.';
  @override String get findAndSharePostDetails => 'Find & Share Post Details';
  @override String get somethingWentWrong => 'Something went wrong';
  @override String get noPostsShareHint =>
      'When users share products, they will appear here.';
  @override String get videoBadge => 'Video';
  @override String get couldNotLoadVideo => 'Could not load video';
  @override String get couldNotLoadImage => 'Could not load image';
  @override String get descriptionLabel => 'Description';
  @override String get contactOwner => 'Contact owner';
  @override String get mustBeSignedInToMessage =>
      'You must be signed in to send messages.';
  @override String get ownerInfoMissing => 'Owner info is missing.';
  @override String get cannotMessageOwnPost => "You can't message your own post.";
  @override String couldNotOpenChat(String error) =>
      'Could not open chat: $error';
  @override String get deletePostQuestionFs => 'Delete post?';
  @override String get deletePostBodyFs =>
      'This will permanently remove your post from Find & Share. This action cannot be undone.';
  @override String get deletingPost => 'Deleting...';

  @override String get noLocation => 'No location';
  @override String get supportACharity => 'Support a charity';
  @override String get charitiesWillShareHere =>
      'Charities will share their causes here.';
  @override String campaignsSubtitle(int count) =>
      'Posts from $count ${count == 1 ? "campaign" : "campaigns"} you can help.';
  @override String get noCharityPostsYet => 'No charity posts yet';
  @override String get whenCharitiesPostHint =>
      'When charities post their campaigns, they will show up here.';
  @override String couldNotLoadCharityPosts(String error) =>
      'Could not load charity posts.\n$error';
  @override String get editCharityPost => 'Edit Charity Post';
  @override String get donationLinkOptional => 'Donation link (optional)';
  @override String get noImageAttached => 'No image attached.';
  @override String get changeImage => 'Change image';
  @override String get saveChanges => 'Save changes';
  @override String get updateFailedTryAgain => 'Update failed. Try again.';
  @override String get noDonationLink => 'No donation link';
  @override String get charityNoDonationLink =>
      'This charity has not added a donation link.';
  @override String get charityFallbackName => 'Charity';
  @override String get searchCharities => 'Search for a charity';
  @override String get noCharitiesMatchSearch => 'No Charities Found';

  @override String get searchTutors => 'Search tutors...';
  @override String tutorsAvailable(int count) =>
      '$count ${count != 1 ? "tutors" : "tutor"} available';
  @override String get noTutorsFound => 'No tutors found';
  @override String get unknownSubject => 'Unknown Subject';
  @override String get onlyClientsCanMessageTutors =>
      'Only clients can message tutors';
  @override String chatError(String error) => 'Chat error: $error';
  @override String get openProfile => 'Open Profile';
  @override String get startChat => 'Start Chat';
  @override String get profileButton => 'Profile';
  @override String get chatButton => 'Chat';

  @override String get roleClient => 'User';
  @override String get roleTutor => 'Tutor';
  @override String get roleBusiness => 'Business';
  @override String get roleCharity => 'Charity';

  @override String get posts => 'Posts';
  @override String get rating => 'Rating';
  @override String get message => 'Message';
  @override String get more => 'More';
  @override String get noDescriptionYet => 'No description yet.';
  @override String get noPostsYetPeriod => 'No posts yet.';
  @override String get profileNotFound => 'Profile not found.';
  @override String get tryAgain => 'Try Again';
  @override String get editProfile => 'Edit Profile';
  @override String get saving => 'Saving...';

  @override String get editProfileTitle => 'Edit Profile';
  @override String get fullName => 'Full name';
  @override String get username => 'Username';
  @override String get location => 'Location';
  @override String get charityName => 'Charity name';
  @override String get camera => 'Camera';
  @override String get gallery => 'Gallery';

  @override String rateName(String name) => 'Rate $name';
  @override String get submitRating => 'Submit Rating';
  @override String get rateOutOfFive => 'Rate out of 5';
  @override String yourRating(String value) => 'Your rating: $value/5';
  @override String get ratingSaved => 'Rating saved.';
  @override String get ratingFailed => 'Rating failed';

  @override String reportName(String name) => 'Report $name';
  @override String get reportUser => 'Report User';
  @override String get reportReasonHint => 'Why are you reporting this user?';
  @override String get pleaseWriteReason => 'Please write a reason.';
  @override String get reportSubmitted => 'Report submitted. Thank you.';
  @override String get couldNotSendReport => 'Could not send report';
  @override String get sending => 'Sending...';
  @override String get submitReport => 'Submit Report';

  @override String get profilePhotoUpdated => 'Profile photo updated.';
  @override String get uploadFailed => 'Upload failed';
  @override String get saveFailed => 'Save failed';
  @override String get profileUpdated => 'Profile updated.';
  @override String get nameAndUsernameRequired =>
      'Full name and username are required.';
  @override String get fullNameNoNumbers => 'Full name cannot contain numbers.';
  @override String get charityNameNoNumbers =>
      'Charity name cannot contain numbers.';
  @override String get locationRequired => 'Location is required.';
  @override String get charityNameAndLocationRequired =>
      'Charity name and location are required.';
  @override String get pleaseLoginFirst => 'Please login first.';
  @override String get followFailed => 'Follow failed';
  @override String get openChatFailed => 'Open chat failed';

  @override String get searchBusinesses => 'Search businesses';
  @override String get clear => 'Clear';
  @override String get filters => 'Filters';
  @override String get reset => 'Reset';
  @override String get sortBy => 'Sort by';
  @override String get maximumDistance => 'Maximum distance';
  @override String get anyDistance => 'Any distance';
  @override String get enableLocationForDistance =>
      'Enable location to filter by distance.';
  @override String get applyFilters => 'Apply filters';
  @override String withinKm(String km) => 'Within $km km';
  @override String get sortTopRated => 'Top rated';
  @override String get sortMostReviewed => 'Most reviewed';
  @override String get sortClosest => 'Closest';
  @override String get sortAlphabetical => 'A–Z';
  @override String get requestABusiness => 'Request a business';
  @override String get requestBusinessBody =>
      'Know a place that should be on Able+? Send us the name and we\'ll '
      'reach out to verify accessibility.';
  @override String get close => 'Close';
  @override String get submit => 'Submit';
  @override String get requestThanks => 'Thanks — we\'ll review it.';
  @override String get couldNotLoadBusinesses => 'Could not load businesses.';
  @override String get noBusinessesMatch => 'No businesses match';
  @override String get noBusinessesMatchBody =>
      'Try clearing some filters, or let us know about a place that should be here.';
  @override String get noRatingsYet => 'No ratings yet';
  @override String kmAway(String km) => '$km km away';

  @override String get featureWheelchairAccess => 'Wheelchair access';
  @override String get featureServiceAnimal => 'Service animals welcome';
  @override String get featureSignLanguage => 'Sign language';
  @override String get featureBraille => 'Braille support';
  @override String get featureSensoryFriendly => 'Sensory friendly';
  @override String get featureAccessibleParking => 'Accessible parking';

  @override String get pleaseLogInFirst => 'Please log in first.';
  @override String get pleaseLogInToUseSupport => 'Please log in to use support.';
  @override String get pleaseLogInToViewTicket =>
      'Please log in to view this ticket.';
  @override String get createSupportTicket => 'Create a support ticket';
  @override String get wellGetBackToYou => "We'll get back to you soon";
  @override String get ticketTitle => 'Ticket title';
  @override String get ticketTitleHint => 'e.g. I cannot update my profile';
  @override String get category => 'Category';
  @override String get priority => 'Priority';
  @override String get messageLabel => 'Message';
  @override String get messageHint => 'Describe your issue or question...';
  @override String get creating => 'Creating...';
  @override String get createTicket => 'Create Ticket';
  @override String get titleAndMessageRequired =>
      'Please enter a title and message.';
  @override String get supportTicketCreated => 'Support ticket created.';
  @override String get failedToCreateTicket => 'Failed to create ticket';
  @override String get myTickets => 'My Tickets';
  @override String get noTicketsYet => 'No tickets yet.';
  @override String get couldNotLoadTickets => 'Could not load tickets';
  @override String get couldNotLoadMessages => 'Could not load messages';
  @override String get supportTicketFallback => 'Support ticket';
  @override String lastMessageAt(String date) => 'Last message: $date';
  @override String get typeYourMessage => 'Type your message...';
  @override String get pleaseTypeMessage => 'Please type a message.';
  @override String get failedToSendMessage => 'Failed to send message';
  @override String get ticketClosedToast => 'Ticket closed.';
  @override String get failedToCloseTicket => 'Failed to close ticket';
  @override String get ticketReopenedToast => 'Ticket reopened.';
  @override String get failedToReopenTicket => 'Failed to reopen ticket';
  @override String get iReopenedThisTicket => 'I reopened this ticket.';
  @override String get thisTicketIsClosed => 'This ticket is closed.';
  @override String get reopen => 'Reopen';
  @override String get closeTicket => 'Close';
  @override String get statusWaitingForSupport => 'Waiting for support';
  @override String get statusSupportReplied => 'Support replied';
  @override String get statusClosed => 'Closed';
  @override String get statusOpen => 'Open';
  @override String get categoryGeneral => 'General';
  @override String get categoryAccount => 'Account';
  @override String get categoryPayments => 'Payments';
  @override String get categoryBug => 'Bug';
  @override String get categorySafety => 'Safety';
  @override String get priorityLow => 'Low';
  @override String get priorityNormal => 'Normal';
  @override String get priorityHigh => 'High';
  @override String get priorityUrgent => 'Urgent';
  @override String senderSystem(String date) => 'System • $date';
  @override String senderYou(String date) => 'You • $date';
  @override String senderSupport(String date) => 'Support • $date';

  @override String get error => 'Error';
  @override String get retry => 'Retry';
  @override String get loading => 'Loading...';
  @override String get success => 'Success';

  @override String get justNow => 'Just now';
  @override String minutesAgo(int count) => '${count}m ago';
  @override String hoursAgo(int count) => '${count}h ago';
  @override String daysAgo(int count) => '${count}d ago';
}

// ──────────────────────────────────────────────
// ARABIC
// ──────────────────────────────────────────────
class _AppLocalizationsAr extends AppLocalizations {
  _AppLocalizationsAr() : super('ar');

  @override String get appName => 'Able+';

  @override String get settings => 'الإعدادات';
  @override String get darkMode => 'الوضع الداكن';
  @override String get language => 'اللغة';
  @override String get textToSpeech => 'تحويل النص إلى كلام';
  @override String get colorBlindMode => 'وضع عمى الألوان';
  @override String get colorBlindModeDesc =>
      'يطبّق فلتر Deuteranopia للمساعدة في التمييز بين الألوان';
  @override String get privacySettings => 'إعدادات الخصوصية';
  @override String get appearance => 'المظهر';
  @override String get accessibility => 'إمكانية الوصول';
  @override String get deuteranopiaFilter => 'فلتر عمى الألوان';
  @override String get howColorsAppear => 'كيف تظهر الألوان مع هذا الفلتر:';
  @override String get normal => 'عادي';
  @override String get withFilter => 'مع الفلتر';

  @override String get home => 'الرئيسية';
  @override String get map => 'الخريطة';
  @override String get messages => 'الرسائل';
  @override String get profile => 'الملف الشخصي';
  @override String get notifications => 'الإشعارات';

  @override String get myActivity => 'نشاطي';
  @override String get support => 'الدعم';
  @override String get aboutUs => 'من نحن';
  @override String get logOut => 'تسجيل الخروج';
  @override String get logOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';
  @override String get cancel => 'إلغاء';
  @override String get confirm => 'تأكيد';

  @override String get recentActivity => 'النشاط الأخير';
  @override String get recentActivityDesc =>
      'ستظهر هنا إعجاباتك وتعليقاتك ومتابعاتك حتى تتمكن من المتابعة من حيث توقفت.';
  @override String get noActivityYet => 'لا يوجد نشاط بعد';
  @override String get noCommentsYet => 'لا يوجد تعليقات بعد';
  @override String get noLikesYet => 'لا يوجد إعجابات بعد';
  @override String get noSavedYet => 'لا يوجد منشورات محفوظة بعد';
  @override String get comments => 'التعليقات';
  @override String get likes => 'الإعجابات';
  @override String get saved => 'المحفوظات';
  @override String get youLikedAPost => 'أعجبك منشور';
  @override String get youCommentedOnAPost => 'علّقت على منشور';
  @override String get youSavedAPost => 'حفظت منشوراً';
  @override String get tapToViewPost => 'اضغط لعرض المنشور';
  @override String get tapToOpenProfile => 'اضغط لفتح الملف الشخصي';
  @override String youFollowed(String name) => 'قمت بمتابعة $name';
  @override String get someone => 'شخص ما';
  @override String get postNoLongerAvailable => 'هذا المنشور لم يعد متاحاً.';
  @override String get profileNotAvailable => 'الملف الشخصي غير متاح.';
  @override String get couldNotLoadActivity => 'تعذّر تحميل نشاطك.';

  @override String get ourTeam => 'فريقنا';
  @override String get founderCeo => 'مؤسس والرئيس التنفيذي';
  @override String get email => 'البريد الإلكتروني';
  @override String get phone => 'الهاتف';
  @override String get couldNotOpenEmail => 'تعذّر فتح تطبيق البريد الإلكتروني';
  @override String get couldNotOpenPhone => 'تعذّر فتح تطبيق الهاتف';
  @override String get ableTeam => 'فريق Able+';
  @override String get aboutUsBody =>
      'نحن فريق مكرّس لتقديم أفضل الخدمات بطريقة احترافية وبسيطة. هدفنا هو خلق تجربة رائعة للعملاء من خلال الجودة والثقة والاهتمام بالتفاصيل.';

  @override String get sendMessage => 'إرسال رسالة';
  @override String get typeMessage => 'اكتب رسالة...';
  @override String get noMessages => 'لا توجد رسائل بعد';
  @override String get startConversation => 'ابدأ محادثة';

  @override String get createPost => 'إنشاء منشور';
  @override String get post => 'نشر';
  @override String get title => 'العنوان';
  @override String get description => 'الوصف';
  @override String get addImage => 'إضافة صورة';
  @override String get addVideo => 'إضافة فيديو';

  @override String get search => 'بحث';
  @override String get filter => 'تصفية';
  @override String get noResults => 'لا توجد نتائج';
  @override String get follow => 'متابعة';
  @override String get unfollow => 'إلغاء المتابعة';
  @override String get followers => 'المتابعون';
  @override String get following => 'يتابع';
  @override String get like => 'إعجاب';
  @override String get comment => 'تعليق';
  @override String get share => 'مشاركة';
  @override String get save => 'حفظ';
  @override String get all => 'الكل';

  @override String get businesses => 'الأعمال';
  @override String get tutors => 'المدرّسون';
  @override String get charities => 'الجمعيات الخيرية';

  @override String get places => 'الأماكن';
  @override String get findandshare => 'المجتمع';
  @override String get findandsharePostNotice => communityPostNotice;
  @override String get postTofindandshare => postToCommunity;
  @override String get postedToFindandshare => postedToCommunity;
  @override String get verifiedAccessibility => 'إمكانية وصول موثّقة';
  @override String get learningSupport => 'دعم تعليمي';
  @override String get supportAndVolunteering => 'الدعم والتطوع';
  @override String get questionsAndUpdates => 'أسئلة وتحديثات';
  @override String get communityFeed => 'تغذية المجتمع';

  @override String get latestPosts => 'أحدث المنشورات التي يشاركها المستخدمون.';
  @override String get postsFromFollowing => 'منشورات من الأشخاص الذين تتابعهم.';
  @override String get noPostsYet => 'لا توجد منشورات بعد';
  @override String get noFollowingPostsYet => 'لا توجد منشورات من المتابَعين بعد';
  @override String get followToSeePosts =>
      'تابع المستخدمين لترى منشوراتهم هنا، أو عُد إلى الكل.';
  @override String get createFirstPost =>
      'أنشئ منشورك الأول لمشاركته مع الجميع.';

  @override String get login => 'تسجيل الدخول';
  @override String get signup => 'إنشاء حساب';
  @override String get forgotPassword => 'نسيت كلمة المرور؟';
  @override String get enterEmail => 'أدخل بريدك الإلكتروني';
  @override String get enterPassword => 'أدخل كلمة المرور';
  @override String get dontHaveAccount => 'ليس لديك حساب؟';
  @override String get alreadyHaveAccount => 'لديك حساب بالفعل؟';
  @override String get resetPassword => 'إعادة تعيين كلمة المرور';
  @override String get sendOtp => 'إرسال رمز التحقق';
  @override String get verifyOtp => 'التحقق من الرمز';
  @override String get newPassword => 'كلمة مرور جديدة';
  @override String get confirmPassword => 'تأكيد كلمة المرور';
  @override String get password => 'كلمة المرور';
  @override String get emailRequired => 'البريد الإلكتروني مطلوب';
  @override String get enterValidEmail => 'أدخل بريداً إلكترونياً صالحاً';
  @override String get passwordRequired => 'كلمة المرور مطلوبة';
  @override String get passwordMin6 => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
  @override String get loginFailedTryAgain =>
      'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى!';
  @override String get emailNotVerified =>
      'لم يتم التحقق من بريدك الإلكتروني بعد. يرجى التحقق من بريدك الوارد وتأكيده أولاً.';
  @override String get incorrectEmailOrPassword =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  @override String get noAccountFound =>
      'لا يوجد حساب لهذا البريد الإلكتروني. يرجى إنشاء حساب أولاً.';
  @override String get somethingWentWrongColon => 'حدث خطأ ما';
  @override String get createAccount => 'إنشاء حساب';
  @override String get backToLogin => 'العودة لتسجيل الدخول';

  @override String get resetYourPassword => 'إعادة تعيين كلمة المرور';
  @override String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل لك رمز التحقق (OTP).';
  @override String get emailHintExample => 'example@email.com';
  @override String get pleaseEnterEmail => 'يرجى إدخال بريدك الإلكتروني';
  @override String get pleaseEnterValidEmail => 'يرجى إدخال بريد إلكتروني صالح';
  @override String get resetCodeSent =>
      'تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني';
  @override String get pleaseWaitBeforeAnotherCode =>
      'يرجى الانتظار قبل طلب رمز آخر.';
  @override String get noAccountFoundForEmail =>
      'لا يوجد حساب لهذا البريد الإلكتروني.';
  @override String get failedToSendResetCode => 'فشل إرسال رمز إعادة التعيين';
  @override String get enterVerificationCode => 'أدخل رمز التحقق';
  @override String otpSentTo(String email) =>
      'أرسلنا رمزاً مكوناً من 6 أرقام إلى\n$email';
  @override String get otpCodeLabel => 'رمز التحقق';
  @override String get pleaseEnterOtp => 'يرجى إدخال رمز التحقق';
  @override String get otpMustBe6Digits => 'يجب أن يتكون رمز التحقق من 6 أرقام';
  @override String get invalidOrExpiredOtp =>
      'رمز تحقق غير صالح أو منتهي الصلاحية';
  @override String get otpVerifiedSuccessfully => 'تم التحقق من الرمز بنجاح';
  @override String get otpExpired => 'انتهت صلاحية الرمز. يرجى طلب رمز جديد.';
  @override String get otpInvalid =>
      'الرمز غير صالح. يرجى التحقق من الرمز والمحاولة مرة أخرى.';
  @override String get failedToVerifyOtp => 'فشل التحقق من الرمز';
  @override String get otpResentSuccessfully => 'تمت إعادة إرسال الرمز بنجاح';
  @override String get failedToResendOtp => 'فشلت إعادة إرسال الرمز';
  @override String get resendOtp => 'إعادة إرسال الرمز';
  @override String get back => 'رجوع';

  @override String get createNewPassword => 'إنشاء كلمة مرور جديدة';
  @override String get setANewPassword => 'تعيين كلمة مرور جديدة';
  @override String createSecurePasswordFor(String email) =>
      'أنشئ كلمة مرور جديدة وآمنة لـ\n$email';
  @override String get newPasswordLabel => 'كلمة المرور الجديدة';
  @override String get confirmPasswordLabel => 'تأكيد كلمة المرور';
  @override String get enterYourNewPassword => 'أدخل كلمة المرور الجديدة';
  @override String get reEnterYourPassword => 'أعد إدخال كلمة المرور';
  @override String get pleaseEnterNewPassword => 'يرجى إدخال كلمة مرور جديدة';
  @override String get passwordMin8 => 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
  @override String get passwordNeedsUppercase =>
      'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل';
  @override String get passwordNeedsLowercase =>
      'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل';
  @override String get passwordNeedsNumber =>
      'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
  @override String get pleaseConfirmPassword => 'يرجى تأكيد كلمة المرور';
  @override String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';
  @override String get passwordRequirementsHint =>
      'يجب أن تتضمن كلمة المرور أحرفاً كبيرة وصغيرة، بالإضافة إلى رقم واحد على الأقل.';
  @override String get sessionExpired =>
      'انتهت الجلسة. يرجى تسجيل الدخول والمحاولة مرة أخرى.';
  @override String get chooseDifferentPassword =>
      'يرجى اختيار كلمة مرور مختلفة عن القديمة.';
  @override String get enterStrongerPassword =>
      'يرجى إدخال كلمة مرور أقوى والمحاولة مرة أخرى.';
  @override String get passwordUpdatedSuccessfully => 'تم تحديث كلمة المرور بنجاح';
  @override String get failedToResetPassword => 'فشل إعادة تعيين كلمة المرور';
  @override String get chooseAccountType => 'اختر نوع الحساب';
  @override String get chooseAccountTypeSubtitle =>
      'اختر نوع حسابك لمتابعة إنشاء الحساب.';
  @override String get accountTypeCharity => 'جمعية خيرية';
  @override String get accountTypeBusinessOwner => 'صاحب عمل';
  @override String get accountTypeTutor => 'مدرّس';
  @override String get accountTypeUser => 'مستخدم';

  @override String get createYourAccount => 'أنشئ حسابك';
  @override String get signupRolesSubtitle =>
      'يمكن للمستخدمين الدخول مباشرةً. أما المدرّسون والأعمال والجمعيات الخيرية فسيرسلون طلب موافقة إلى المشرف.';
  @override String get fullNameRequired => 'الاسم الكامل مطلوب';
  @override String get fullNameMin3 => 'يجب أن يكون الاسم الكامل 3 أحرف على الأقل';
  @override String get fullNameLettersOnly =>
      'يمكن أن يحتوي الاسم الكامل على أحرف فقط';
  @override String get usernameRequired => 'اسم المستخدم مطلوب';
  @override String get usernameMin3 =>
      'يجب أن يكون اسم المستخدم 3 أحرف على الأقل';
  @override String get usernameMax20 => 'يجب ألا يتجاوز اسم المستخدم 20 حرفاً';
  @override String get usernameAllowedChars =>
      'يمكن أن يحتوي اسم المستخدم على أحرف وأرقام وشرطة سفلية فقط';
  @override String get confirmPasswordRequired => 'تأكيد كلمة المرور مطلوب';
  @override String get locationRequiredForAccount =>
      'الموقع مطلوب لإنشاء حساب.';
  @override String get signupFailed => 'فشل إنشاء الحساب';
  @override String get accountCreatedVerifyEmail =>
      'تم إنشاء الحساب. يرجى التحقق من بريدك الإلكتروني.';
  @override String unknownAccountType(String type) => 'نوع حساب غير معروف: $type';
  @override String get errorColon => 'خطأ';
  @override String get locationNoticeUser =>
      'بعد الضغط على الزر، سيُطلب منك مشاركة موقعك حتى نتمكن من عرض الأماكن القريبة منك.';
  @override String get verificationNoticeOther =>
      'يتطلب هذا النوع من الحسابات مراجعة المستندات قبل تفعيله.';
  @override String get continueToVerification => 'المتابعة إلى التحقق';
  @override String get submitForApproval => 'إرسال للموافقة';
  @override String get useCurrentLocation => 'استخدام الموقع الحالي';
  @override String get pleaseShareLocation =>
      'يرجى مشاركة موقعك الحالي للمتابعة.';
  @override String get uploadIdImage => 'رفع صورة الهوية';
  @override String get idImageFormats => 'JPG أو JPEG أو PNG';
  @override String get couldNotReadFile => 'تعذّر قراءة الملف المحدد.';
  @override String get failedToPickFile => 'فشل اختيار الملف';
  @override String get missingSignupInfo =>
      'معلومات التسجيل ناقصة. يرجى العودة والتسجيل مرة أخرى.';

  @override String get businessSignUp => 'تسجيل نشاط تجاري';
  @override String get businessVerificationNotice =>
      'يلزم تحقق إضافي لحسابات الأعمال قبل الموافقة.';
  @override String get uploadBusinessPhotos => 'ارفع 3-5 صور للنشاط التجاري';
  @override String get accessibilityPhotosHint =>
      'صور لإمكانية الوصول في النشاط التجاري';
  @override String photosSelected(int count) => 'تم اختيار $count صور';
  @override String get uploadCommercialRegister => 'رفع السجل التجاري';
  @override String get fileFormatsHint => 'PDF أو صورة أو مستند';
  @override String get businessDocumentsNotice =>
      'هذه المستندات مطلوبة للتحقق من حساب نشاطك التجاري.';
  @override String get selectBetween3And5Photos =>
      'يرجى اختيار ما بين 3 و5 صور للنشاط التجاري.';
  @override String get imageCouldNotBeRead => 'تعذّر قراءة إحدى الصور المحددة.';
  @override String get failedToPickPhotos => 'فشل اختيار صور النشاط التجاري';
  @override String get pleaseUpload3To5Photos =>
      'يرجى رفع 3 إلى 5 صور للنشاط التجاري.';
  @override String get pleaseUploadCommercialRegister =>
      'يرجى رفع السجل التجاري.';
  @override String get pleaseUploadIdImage => 'يرجى رفع صورة الهوية.';
  @override String get couldNotCreateBusinessAccount =>
      'تعذّر إنشاء حساب النشاط التجاري.';
  @override String get businessSubmittedVerifyEmail =>
      'تم إرسال حساب النشاط التجاري بنجاح. يرجى التحقق من بريدك الإلكتروني.';
  @override String get failedToSubmitBusiness =>
      'فشل إرسال تسجيل النشاط التجاري';

  @override String get charitySignUp => 'تسجيل جمعية خيرية';
  @override String get charityVerificationNotice =>
      'يلزم تحقق إضافي لحسابات الجمعيات الخيرية قبل الموافقة.';
  @override String get charityNameLabel => 'اسم الجمعية';
  @override String get charityNameRequired => 'اسم الجمعية مطلوب';
  @override String get enterValidCharityName => 'أدخل اسم جمعية صالحاً';
  @override String get uploadCharityProof => 'رفع إثبات الجمعية';
  @override String get charityDocumentsNotice =>
      'هذه المستندات مطلوبة للتحقق من حساب جمعيتك.';
  @override String get pleaseUploadCharityProof => 'يرجى رفع إثبات الجمعية.';
  @override String get missingSignupDataStartOver =>
      'بيانات التسجيل ناقصة. يرجى البدء من جديد.';
  @override String get charitySubmittedVerifyEmail =>
      'تم إرسال حساب الجمعية الخيرية بنجاح. يرجى التحقق من بريدك الإلكتروني.';
  @override String get failedToSubmitCharity =>
      'فشل إرسال تسجيل الجمعية الخيرية';

  @override String get tutorSignUp => 'تسجيل مدرّس';
  @override String get tutorVerificationNotice =>
      'يلزم تحقق إضافي لحسابات المدرّسين قبل الموافقة.';
  @override String get yourBio => 'نبذتك';
  @override String get bioHint =>
      'أخبر الطلاب عن خبرتك وأسلوب تدريسك وما يجعلك مدرّساً متميزاً.';
  @override String get bioRequired => 'النبذة مطلوبة';
  @override String get bioMinChars => 'يرجى كتابة 20 حرفاً على الأقل';
  @override String get subjectsYouTeach => 'المواد التي تدرّسها';
  @override String get yourLocation => 'موقعك';
  @override String get locationPrivateNote =>
      'موقعك خاص. يُستخدم فقط لعرض الأماكن القريبة منك.';
  @override String get uploadCertificateProof => 'رفع إثبات الشهادة';
  @override String get certificateFormatsHint => 'PDF أو صورة أو مستند';
  @override String get uploadCvSpecialization => 'رفع السيرة الذاتية / التخصص';
  @override String get tutorDocumentsNotice =>
      'هذه المستندات مطلوبة للتحقق من حساب المدرّس الخاص بك.';
  @override String get pleaseAddSubject =>
      'يرجى إضافة مادة واحدة على الأقل تدرّسها.';
  @override String get pleaseUploadCertificate => 'يرجى رفع إثبات الشهادة.';
  @override String get pleaseUploadCv =>
      'يرجى رفع سيرتك الذاتية أو ملف التخصص.';
  @override String get missingAccountInfo =>
      'معلومات الحساب ناقصة. يرجى العودة وإكمال التسجيل مرة أخرى.';
  @override String get passwordMissingGoBack =>
      'كلمة المرور مفقودة. يرجى العودة وإكمال التسجيل مرة أخرى.';
  @override String get tutorSubmittedForVerification =>
      'تم إرسال حساب المدرّس بنجاح للتحقق.';
  @override String get failedToSubmitTutor => 'فشل إرسال تسجيل المدرّس';

  @override String get currentLocation => 'الموقع الحالي';
  @override String get tapToDetectGps => 'اضغط للكشف باستخدام GPS';
  @override String get locationSavedNote =>
      'تم حفظ الموقع. يمكنك إضافة مدينة/منطقة لاحقاً من ملفك الشخصي.';
  @override String get addSubjectHint => 'أضف مادة واضغط Enter';
  @override String get addAnotherHint => 'أضف أخرى';
  @override String get suggestions => 'اقتراحات';

  @override String get noMessagesYet => 'لا توجد رسائل بعد.';
  @override String get unknown => 'غير معروف';
  @override String get deleteChat => 'حذف المحادثة';
  @override String get youBothBlockedShort => 'لقد حظر كل منكما الآخر';
  @override String get youBlockedThisUser => 'لقد حظرت هذا المستخدم';
  @override String get thisUserBlockedYou => 'قام هذا المستخدم بحظرك';
  @override String get messagesHidden => 'الرسائل مخفية';
  @override String get timeNow => 'الآن';
  @override String minutesShort(int count) => 'منذ $count د';
  @override String hoursShort(int count) => 'منذ $count س';
  @override String daysShort(int count) => 'منذ $count ي';

  @override String get ableUser => 'مستخدم Able';
  @override String get cannotBlockMissingInfo =>
      'تعذّر الحظر: معلومات المستخدم ناقصة.';
  @override String get blockUserQuestion => 'حظر المستخدم؟';
  @override String get blockUserBody =>
      'سيظهر باسم مستخدم Able. ستُخفى الرسائل الجديدة حتى إلغاء الحظر.';
  @override String get block => 'حظر';
  @override String get unblock => 'إلغاء الحظر';
  @override String get userBlocked => 'تم حظر المستخدم.';
  @override String blockFailed(String error) => 'فشل الحظر: $error';
  @override String get userUnblocked => 'تم إلغاء حظر المستخدم.';
  @override String unblockFailed(String error) => 'فشل إلغاء الحظر: $error';
  @override String get profileUnavailable => 'الملف الشخصي غير متاح.';
  @override String get profileInfoMissing => 'معلومات الملف الشخصي ناقصة.';
  @override String get edited => 'مُعدّلة';
  @override String get sendingStatus => 'جارٍ الإرسال...';
  @override String get seenStatus => 'تمت المشاهدة';
  @override String get startTheConversation => 'ابدأ المحادثة.';
  @override String get messageWillAppearAfterUnblock =>
      'ستظهر الرسالة بعد إلغاء الحظر...';
  @override String get messageHintDefault => 'رسالة...';
  @override String get messageWillAppearToThem =>
      'ستظهر الرسالة لهم بعد إلغاء الحظر.';
  @override String sendFailed(String error) => 'فشل الإرسال: $error';
  @override String get waitUntilSent => 'انتظر حتى يتم إرسال الرسالة.';
  @override String get editMessage => 'تعديل الرسالة';
  @override String get messageDialogHint => 'رسالة...';
  @override String get messageUpdated => 'تم تحديث الرسالة.';
  @override String editFailed(String error) => 'فشل التعديل: $error';
  @override String get deleteMessageQuestion => 'حذف الرسالة؟';
  @override String get deleteMessageBody =>
      'هل أنت متأكد أنك تريد حذف هذه الرسالة؟';
  @override String get delete => 'حذف';
  @override String get deleteMessageMenu => 'حذف الرسالة';
  @override String get deleteForMe => 'حذف لي فقط';           // ✅ NEW
  @override String get deleteForEveryone => 'حذف للجميع';     // ✅ NEW

  @override String get markAllRead => 'تعليم الكل كمقروء';
  @override String get noNotificationsYet => 'لا توجد إشعارات بعد';
  @override String get postNoLongerAvailableNotif => 'هذا المنشور لم يعد متاحاً.';
  @override String get userProfileNotAvailable =>
      'الملف الشخصي للمستخدم غير متاح.';
  @override String get notifActionLiked => 'أعجب بمنشورك';
  @override String get notifActionCommented => 'علّق على منشورك';
  @override String get notifActionFollowed => 'بدأ بمتابعتك';
  @override String get notifActionMessaged => 'أرسل لك رسالة';
  @override String get notifActionBooking => 'أرسل لك حجزاً';

  @override String get createPostTitle => 'إنشاء منشور';
  @override String get createAPost => 'أنشئ منشوراً';
  @override String get communityPostNotice =>
      'سيتم مشاركة هذا المنشور في المجتمع.';
  @override String get homePostNotice =>
      'سيظهر هذا المنشور في صفحتك الرئيسية.';
  @override String get accountLoading => 'جارٍ التحميل...';
  @override String get addAPhoto => 'أضف صورة';
  @override String get tapToChoose => 'اضغط للاختيار';
  @override String get cameraOrGallery => 'الكاميرا أو المعرض';
  @override String get addAVideo => 'أضف فيديو';
  @override String get upTo2Minutes => 'حتى دقيقتين';
  @override String get recordVideo => 'تسجيل فيديو';
  @override String get galleryVideo => 'فيديو من المعرض';
  @override String get videoSelected => 'تم اختيار الفيديو';
  @override String get describeProduct => 'صف المنتج...';
  @override String get whatsOnYourMind => 'بماذا تفكّر؟';
  @override String get donationLinkHint => 'رابط التبرع (https://...)';
  @override String get donationLinkNote =>
      'اختياري. سيظهر زر "تبرّع الآن" على منشورك ويفتح هذا الرابط.';
  @override String get postToCommunity => 'النشر في المجتمع';
  @override String get postToHome => 'النشر في الرئيسية';
  @override String get addDescriptionImageOrVideo =>
      'أضف وصفاً أو صورة أو فيديو';
  @override String get accountStillLoading => 'لا يزال الحساب قيد التحميل';
  @override String get noUserLoggedIn =>
      'لا يوجد مستخدم مسجّل الدخول. يرجى تسجيل الدخول أولاً.';
  @override String get accountNotFound =>
      'لم يتم العثور على الحساب. يرجى تسجيل الدخول مرة أخرى.';
  @override String get postedToCommunity => 'تم النشر في المجتمع بنجاح';
  @override String get postCreatedSuccess => 'تم إنشاء المنشور بنجاح';
  @override String get tagUser => 'مستخدم';
  @override String get tagEducational => 'تعليمي';
  @override String get tagBusiness => 'نشاط تجاري';
  @override String get tagCharity => 'جمعية خيرية';

  @override String get postTitle => 'منشور';
  @override String couldNotLoadPost(String error) =>
      'تعذّر تحميل هذا المنشور.\n$error';
  @override String get postDeletedByAuthor => 'ربما تم حذفه من قبل صاحبه.';
  @override String get postRoleClient => 'مستخدم';
  @override String get postRoleTutor => 'مدرّس';
  @override String get postRoleBusiness => 'نشاط تجاري';
  @override String get postRoleCharity => 'جمعية خيرية';
  @override String get removedFromSaved => 'تمت الإزالة من المنشورات المحفوظة.';
  @override String get postSavedSuccess => 'تم حفظ المنشور بنجاح.';
  @override String saveFailedError(String error) => 'فشل الحفظ: $error';
  @override String likeFailedError(String error) => 'فشل الإعجاب: $error';
  @override String get editPost => 'تعديل المنشور';
  @override String get deletePost => 'حذف المنشور';
  @override String get reportPost => 'الإبلاغ عن المنشور';
  @override String get reportPostSubtitle =>
      'أرسل هذا المنشور إلى المشرف للمراجعة.';
  @override String get deletePostQuestion => 'حذف المنشور؟';
  @override String get deletePostBody =>
      'هل أنت متأكد أنك تريد حذف هذا المنشور؟';
  @override String get postDeleted => 'تم حذف المنشور.';
  @override String deletePostFailedError(String error) => 'فشل الحذف: $error';
  @override String get reportPostReasonHint =>
      'السبب (مثل: بريد مزعج، تحرّش، محتوى غير لائق…)';
  @override String get reportPostBody =>
      'أخبر المشرف لماذا تعتقد أن هذا المنشور يجب مراجعته. بلاغك خاص.';
  @override String get pleaseWriteShortReason => 'يرجى كتابة سبب مختصر.';
  @override String get reportSentThanks =>
      'تم إرسال البلاغ إلى المشرف. شكراً لك.';
  @override String get couldNotSendReportTryAgain =>
      'تعذّر إرسال البلاغ. حاول مرة أخرى.';
  @override String get editYourPost => 'عدّل منشورك...';
  @override String newImageLabel(String name) => 'صورة جديدة: $name';
  @override String newVideoLabel(String name) => 'فيديو جديد: $name';
  @override String get noImageSelected => 'لم يتم اختيار صورة.';
  @override String get currentVideoAttached => 'الفيديو الحالي مرفق';
  @override String get imageLabel => 'صورة';
  @override String get videoLabel => 'فيديو';
  @override String get postCannotBeEmpty => 'لا يمكن أن يكون المنشور فارغاً.';
  @override String get postUpdated => 'تم تحديث المنشور.';
  @override String editFailedError(String error) => 'فشل التعديل: $error';
  @override String get shareToFollowing => 'المشاركة مع المتابَعين';
  @override String get notFollowingAnyone => 'أنت لا تتابع أحداً بعد.';
  @override String get postShared => 'تمت مشاركة المنشور.';
  @override String shareFailedError(String error) => 'فشلت المشاركة: $error';
  @override String get seeTranslation => 'عرض الترجمة';
  @override String get seeOriginal => 'عرض النص الأصلي';
  @override String get translating => 'جارٍ الترجمة…';
  @override String get couldNotTranslate => 'تعذّرت الترجمة. حاول مرة أخرى.';
  @override String get commentsTitle => 'التعليقات';
  @override String get noCommentsYetPeriod => 'لا توجد تعليقات بعد.';
  @override String get addACommentHint => 'أضف تعليقاً...';
  @override String get editComment => 'تعديل التعليق';
  @override String get commentDialogHint => 'تعليق...';
  @override String get commentUpdated => 'تم تحديث التعليق.';
  @override String editCommentFailedError(String error) =>
      'فشل تعديل التعليق: $error';
  @override String get deleteCommentQuestion => 'حذف التعليق؟';
  @override String get deleteCommentBody =>
      'هل أنت متأكد أنك تريد حذف هذا التعليق؟';
  @override String get commentDeleted => 'تم حذف التعليق.';
  @override String deleteCommentFailedError(String error) =>
      'فشل حذف التعليق: $error';
  @override String commentFailedError(String error) => 'فشل التعليق: $error';
  @override String get editCommentMenu => 'تعديل التعليق';
  @override String get deleteCommentMenu => 'حذف التعليق';
  @override String get donateNow => 'تبرّع الآن';
  @override String get invalidDonationLink => 'رابط تبرّع غير صالح.';
  @override String get couldNotOpenDonationLink => 'تعذّر فتح رابط التبرّع.';

  @override String get mapTitle => 'الخريطة';
  @override String get nearbyPlaces => 'الأماكن القريبة';
  @override String get youMarker => 'أنت';
  @override String get searchPlaces => 'ابحث عن الأماكن...';
  @override String get noPlacesFound => 'لا توجد أماكن.';
  @override String get noPlacesFoundYet => 'لا توجد أماكن بعد.';
  @override String get mapNearbyHeading =>
      'الخريطة وأماكن إمكانية الوصول القريبة';
  @override String get mapNearbySubtitle =>
      'تصفّح المواقع الموثوقة وراجع ميزات إمكانية الوصول الرئيسية قبل الزيارة.';
  @override String get suggestedPlaces => 'أماكن مقترحة';
  @override String get openMap => 'فتح';
  @override String get viewDetails => 'عرض التفاصيل';
  @override String get accessibilityInfoPending =>
      'معلومات إمكانية الوصول قيد الإعداد';

  @override String get placeKindCharity => 'جمعية خيرية';
  @override String get placeKindBusiness => 'نشاط تجاري';
  @override String get ratingNew => 'جديد';
  @override String get viewProfile => 'عرض الملف الشخصي';
  @override String get directionsComingSoon =>
      'ستُفتح الاتجاهات في تطبيق الخرائط قريباً.';
  @override String get shareComingSoon => 'المشاركة قريباً.';
  @override String get reviews => 'المراجعات';
  @override String get writeReview => 'اكتب مراجعة';
  @override String get writeReviewShort => 'كتابة';
  @override String get noReviewsYet => 'لا توجد مراجعات بعد.';
  @override String get noReviewsBeFirst =>
      'لا توجد مراجعات بعد. كن أول من يكتب واحدة.';
  @override String couldNotLoadReviews(String error) =>
      'تعذّر تحميل المراجعات: $error';
  @override String get editYourReview => 'عدّل مراجعتك';
  @override String get reviewCommentHint => 'شارك تفاصيل عن زيارتك (اختياري)';
  @override String get thanksForReview => 'شكراً على مراجعتك.';
  @override String couldNotSaveReview(String error) =>
      'تعذّر حفظ المراجعة: $error';
  @override String weeksAgo(int count) => 'منذ $count أسبوع';
  @override String monthsAgo(int count) => 'منذ $count شهر';
  @override String yearsAgo(int count) => 'منذ $count سنة';
  @override String followsCountSubtitle(int count) =>
      'يتابع هذا الملف $count شخصاً';
  @override String followersCountSubtitle(int count) =>
      'يتابع هذا الملفَ $count شخصاً';
  @override String get notFollowingAnyoneProfile =>
      'هذا الملف لا يتابع أحداً بعد.';
  @override String get noFollowersProfile => 'لا أحد يتابع هذا الملف بعد.';
  @override String get messageDeleted => 'تم حذف الرسالة.';
  @override String deleteFailed(String error) => 'فشل الحذف: $error';
  @override String get onlyEditOwnMessages =>
      'يمكنك تعديل أو حذف رسائلك فقط.';
  @override String get loadingPost => 'جارٍ تحميل المنشور...';
  @override String get postUnavailable => 'المنشور غير متاح';
  @override String get sharedAPost => 'شارك منشوراً';
  @override String get youBothBlocked =>
      'لقد حظر كل منكما الآخر. الرسائل مخفية حتى إلغاء الحظر.';
  @override String get youBlockedAbleUser =>
      'لقد حظرت هذا المستخدم. الرسائل الجديدة مخفية حتى إلغاء الحظر.';
  @override String get ableUserBlockedYou =>
      'قام هذا المستخدم بحظرك. الرسائل الجديدة مخفية حتى إلغاء الحظر.';
  @override String get blockUserMenu => 'حظر المستخدم';
  @override String get unblockUserMenu => 'إلغاء حظر المستخدم';

  @override String get findAndShare => 'ابحث وشارك';
  @override String get findAndShareSubtitle =>
      'اعثر على منتجات مفيدة وشارك ما قد يساعد الآخرين.';
  @override String get findAndSharePostDetails => 'تفاصيل منشور ابحث وشارك';
  @override String get somethingWentWrong => 'حدث خطأ ما';
  @override String get noPostsShareHint =>
      'عند مشاركة المستخدمين للمنتجات، ستظهر هنا.';
  @override String get videoBadge => 'فيديو';
  @override String get couldNotLoadVideo => 'تعذّر تحميل الفيديو';
  @override String get couldNotLoadImage => 'تعذّر تحميل الصورة';
  @override String get descriptionLabel => 'الوصف';
  @override String get contactOwner => 'التواصل مع صاحب المنشور';
  @override String get mustBeSignedInToMessage =>
      'يجب تسجيل الدخول لإرسال الرسائل.';
  @override String get ownerInfoMissing => 'معلومات صاحب المنشور غير متوفرة.';
  @override String get cannotMessageOwnPost => 'لا يمكنك مراسلة منشورك الخاص.';
  @override String couldNotOpenChat(String error) =>
      'تعذّر فتح المحادثة: $error';
  @override String get deletePostQuestionFs => 'حذف المنشور؟';
  @override String get deletePostBodyFs =>
      'سيؤدي هذا إلى إزالة منشورك نهائياً من «ابحث وشارك». لا يمكن التراجع عن هذا الإجراء.';
  @override String get deletingPost => 'جارٍ الحذف...';

  @override String get noLocation => 'لا يوجد موقع';
  @override String get supportACharity => 'ادعم جمعية خيرية';
  @override String get charitiesWillShareHere =>
      'ستشارك الجمعيات الخيرية قضاياها هنا.';
  @override String campaignsSubtitle(int count) =>
      'منشورات من $count حملة يمكنك المساعدة فيها.';
  @override String get noCharityPostsYet => 'لا توجد منشورات خيرية بعد';
  @override String get whenCharitiesPostHint =>
      'عندما تنشر الجمعيات حملاتها، ستظهر هنا.';
  @override String couldNotLoadCharityPosts(String error) =>
      'تعذّر تحميل المنشورات الخيرية.\n$error';
  @override String get editCharityPost => 'تعديل المنشور الخيري';
  @override String get donationLinkOptional => 'رابط التبرع (اختياري)';
  @override String get noImageAttached => 'لا توجد صورة مرفقة.';
  @override String get changeImage => 'تغيير الصورة';
  @override String get saveChanges => 'حفظ التغييرات';
  @override String get updateFailedTryAgain => 'فشل التحديث. حاول مرة أخرى.';
  @override String get noDonationLink => 'لا يوجد رابط تبرع';
  @override String get charityNoDonationLink =>
      'لم تضِف هذه الجمعية رابط تبرع.';
  @override String get charityFallbackName => 'جمعية خيرية';
  @override String get searchCharities => 'ابحث عن جمعية خيرية';
  @override String get noCharitiesMatchSearch => 'لا توجد جمعية خيرية بهاذا الاسم';

  @override String get searchTutors => 'ابحث عن المدرّسين...';
  @override String tutorsAvailable(int count) => '$count مدرّس متاح';
  @override String get noTutorsFound => 'لم يتم العثور على مدرّسين';
  @override String get unknownSubject => 'مادة غير محددة';
  @override String get onlyClientsCanMessageTutors =>
      'يمكن للمستخدمين فقط مراسلة المدرّسين';
  @override String chatError(String error) => 'خطأ في المحادثة: $error';
  @override String get openProfile => 'فتح الملف الشخصي';
  @override String get startChat => 'بدء محادثة';
  @override String get profileButton => 'الملف الشخصي';
  @override String get chatButton => 'محادثة';

  @override String get roleClient => 'مستخدم';
  @override String get roleTutor => 'مدرّس';
  @override String get roleBusiness => 'نشاط تجاري';
  @override String get roleCharity => 'جمعية خيرية';

  @override String get posts => 'المنشورات';
  @override String get rating => 'التقييم';
  @override String get message => 'مراسلة';
  @override String get more => 'المزيد';
  @override String get noDescriptionYet => 'لا يوجد وصف بعد.';
  @override String get noPostsYetPeriod => 'لا توجد منشورات بعد.';
  @override String get profileNotFound => 'لم يتم العثور على الملف الشخصي.';
  @override String get tryAgain => 'حاول مرة أخرى';
  @override String get editProfile => 'تعديل الملف الشخصي';
  @override String get saving => 'جارٍ الحفظ...';

  @override String get editProfileTitle => 'تعديل الملف الشخصي';
  @override String get fullName => 'الاسم الكامل';
  @override String get username => 'اسم المستخدم';
  @override String get location => 'الموقع';
  @override String get charityName => 'اسم الجمعية';
  @override String get camera => 'الكاميرا';
  @override String get gallery => 'المعرض';

  @override String rateName(String name) => 'قيّم $name';
  @override String get submitRating => 'إرسال التقييم';
  @override String get rateOutOfFive => 'قيّم من 5';
  @override String yourRating(String value) => 'تقييمك: $value/5';
  @override String get ratingSaved => 'تم حفظ التقييم.';
  @override String get ratingFailed => 'فشل التقييم';

  @override String reportName(String name) => 'الإبلاغ عن $name';
  @override String get reportUser => 'الإبلاغ عن المستخدم';
  @override String get reportReasonHint => 'لماذا تُبلغ عن هذا المستخدم؟';
  @override String get pleaseWriteReason => 'يرجى كتابة سبب.';
  @override String get reportSubmitted => 'تم إرسال البلاغ. شكراً لك.';
  @override String get couldNotSendReport => 'تعذّر إرسال البلاغ';
  @override String get sending => 'جارٍ الإرسال...';
  @override String get submitReport => 'إرسال البلاغ';

  @override String get profilePhotoUpdated => 'تم تحديث صورة الملف الشخصي.';
  @override String get uploadFailed => 'فشل الرفع';
  @override String get saveFailed => 'فشل الحفظ';
  @override String get profileUpdated => 'تم تحديث الملف الشخصي.';
  @override String get nameAndUsernameRequired =>
      'الاسم الكامل واسم المستخدم مطلوبان.';
  @override String get fullNameNoNumbers =>
      'لا يمكن أن يحتوي الاسم الكامل على أرقام.';
  @override String get charityNameNoNumbers =>
      'لا يمكن أن يحتوي اسم الجمعية على أرقام.';
  @override String get locationRequired => 'الموقع مطلوب.';
  @override String get charityNameAndLocationRequired =>
      'اسم الجمعية والموقع مطلوبان.';
  @override String get pleaseLoginFirst => 'يرجى تسجيل الدخول أولاً.';
  @override String get followFailed => 'فشلت المتابعة';
  @override String get openChatFailed => 'تعذّر فتح المحادثة';

  @override String get searchBusinesses => 'ابحث عن الأعمال';
  @override String get clear => 'مسح';
  @override String get filters => 'عوامل التصفية';
  @override String get reset => 'إعادة تعيين';
  @override String get sortBy => 'ترتيب حسب';
  @override String get maximumDistance => 'أقصى مسافة';
  @override String get anyDistance => 'أي مسافة';
  @override String get enableLocationForDistance =>
      'فعّل الموقع للتصفية حسب المسافة.';
  @override String get applyFilters => 'تطبيق عوامل التصفية';
  @override String withinKm(String km) => 'ضمن $km كم';
  @override String get sortTopRated => 'الأعلى تقييماً';
  @override String get sortMostReviewed => 'الأكثر مراجعةً';
  @override String get sortClosest => 'الأقرب';
  @override String get sortAlphabetical => 'أ–ي';
  @override String get requestABusiness => 'طلب إضافة نشاط';
  @override String get requestBusinessBody =>
      'تعرف مكاناً يستحق أن يكون على Able+؟ أرسل لنا الاسم وسنتواصل '
      'للتحقق من إمكانية الوصول.';
  @override String get close => 'إغلاق';
  @override String get submit => 'إرسال';
  @override String get requestThanks => 'شكراً — سنراجعه.';
  @override String get couldNotLoadBusinesses => 'تعذّر تحميل الأعمال.';
  @override String get noBusinessesMatch => 'لا توجد أعمال مطابقة';
  @override String get noBusinessesMatchBody =>
      'حاول مسح بعض عوامل التصفية، أو أخبرنا عن مكان يجب أن يكون هنا.';
  @override String get noRatingsYet => 'لا توجد تقييمات بعد';
  @override String kmAway(String km) => 'يبعد $km كم';

  @override String get featureWheelchairAccess => 'وصول الكراسي المتحركة';
  @override String get featureServiceAnimal => 'حيوانات الخدمة مرحب بها';
  @override String get featureSignLanguage => 'لغة الإشارة';
  @override String get featureBraille => 'دعم طريقة برايل';
  @override String get featureSensoryFriendly => 'ملائم حسّياً';
  @override String get featureAccessibleParking => 'مواقف لذوي الإعاقة';

  @override String get pleaseLogInFirst => 'يرجى تسجيل الدخول أولاً.';
  @override String get pleaseLogInToUseSupport =>
      'يرجى تسجيل الدخول لاستخدام الدعم.';
  @override String get pleaseLogInToViewTicket =>
      'يرجى تسجيل الدخول لعرض هذه التذكرة.';
  @override String get createSupportTicket => 'إنشاء تذكرة دعم';
  @override String get wellGetBackToYou => 'سنعاود التواصل معك قريباً';
  @override String get ticketTitle => 'عنوان التذكرة';
  @override String get ticketTitleHint =>
      'مثال: لا أستطيع تحديث ملفي الشخصي';
  @override String get category => 'الفئة';
  @override String get priority => 'الأولوية';
  @override String get messageLabel => 'الرسالة';
  @override String get messageHint => 'صف مشكلتك أو سؤالك...';
  @override String get creating => 'جارٍ الإنشاء...';
  @override String get createTicket => 'إنشاء تذكرة';
  @override String get titleAndMessageRequired => 'يرجى إدخال عنوان ورسالة.';
  @override String get supportTicketCreated => 'تم إنشاء تذكرة الدعم.';
  @override String get failedToCreateTicket => 'فشل إنشاء التذكرة';
  @override String get myTickets => 'تذاكري';
  @override String get noTicketsYet => 'لا توجد تذاكر بعد.';
  @override String get couldNotLoadTickets => 'تعذّر تحميل التذاكر';
  @override String get couldNotLoadMessages => 'تعذّر تحميل الرسائل';
  @override String get supportTicketFallback => 'تذكرة دعم';
  @override String lastMessageAt(String date) => 'آخر رسالة: $date';
  @override String get typeYourMessage => 'اكتب رسالتك...';
  @override String get pleaseTypeMessage => 'يرجى كتابة رسالة.';
  @override String get failedToSendMessage => 'فشل إرسال الرسالة';
  @override String get ticketClosedToast => 'تم إغلاق التذكرة.';
  @override String get failedToCloseTicket => 'فشل إغلاق التذكرة';
  @override String get ticketReopenedToast => 'تمت إعادة فتح التذكرة.';
  @override String get failedToReopenTicket => 'فشلت إعادة فتح التذكرة';
  @override String get iReopenedThisTicket => 'أعدت فتح هذه التذكرة.';
  @override String get thisTicketIsClosed => 'هذه التذكرة مغلقة.';
  @override String get reopen => 'إعادة فتح';
  @override String get closeTicket => 'إغلاق';
  @override String get statusWaitingForSupport => 'بانتظار الدعم';
  @override String get statusSupportReplied => 'رد الدعم';
  @override String get statusClosed => 'مغلقة';
  @override String get statusOpen => 'مفتوحة';
  @override String get categoryGeneral => 'عام';
  @override String get categoryAccount => 'الحساب';
  @override String get categoryPayments => 'المدفوعات';
  @override String get categoryBug => 'خلل';
  @override String get categorySafety => 'الأمان';
  @override String get priorityLow => 'منخفضة';
  @override String get priorityNormal => 'عادية';
  @override String get priorityHigh => 'عالية';
  @override String get priorityUrgent => 'عاجلة';
  @override String senderSystem(String date) => 'النظام • $date';
  @override String senderYou(String date) => 'أنت • $date';
  @override String senderSupport(String date) => 'الدعم • $date';

  @override String get error => 'خطأ';
  @override String get retry => 'إعادة المحاولة';
  @override String get loading => 'جارٍ التحميل...';
  @override String get success => 'تم بنجاح';

  @override String get justNow => 'الآن';
  @override String minutesAgo(int count) => 'منذ ${count} د';
  @override String hoursAgo(int count) => 'منذ ${count} س';
  @override String daysAgo(int count) => 'منذ ${count} أيام';
}

// ──────────────────────────────────────────────
// DELEGATE
// ──────────────────────────────────────────────
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      locale.languageCode == 'ar'
          ? _AppLocalizationsAr()
          : _AppLocalizationsEn(),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}