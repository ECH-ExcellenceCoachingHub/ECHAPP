import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_rw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('rw')
  ];

  /// The app name
  ///
  /// In en, this message translates to:
  /// **'Excellence Coaching Hub'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @unselect.
  ///
  /// In en, this message translates to:
  /// **'Unselect'**
  String get unselect;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get languageSelectionTitle;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to continue'**
  String get languageSelectionSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @kinyarwanda.
  ///
  /// In en, this message translates to:
  /// **'Kinyarwanda'**
  String get kinyarwanda;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// No description provided for @myLearning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get myLearning;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @exams.
  ///
  /// In en, this message translates to:
  /// **'Exams'**
  String get exams;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @certificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificates;

  /// No description provided for @awards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get awards;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @browseBooks.
  ///
  /// In en, this message translates to:
  /// **'Browse books'**
  String get browseBooks;

  /// No description provided for @browseResources.
  ///
  /// In en, this message translates to:
  /// **'Browse Resources'**
  String get browseResources;

  /// No description provided for @offlineContent.
  ///
  /// In en, this message translates to:
  /// **'Offline Content'**
  String get offlineContent;

  /// No description provided for @viewAwards.
  ///
  /// In en, this message translates to:
  /// **'View Awards'**
  String get viewAwards;

  /// No description provided for @examHistory.
  ///
  /// In en, this message translates to:
  /// **'Exam History'**
  String get examHistory;

  /// No description provided for @pastResults.
  ///
  /// In en, this message translates to:
  /// **'Past Results'**
  String get pastResults;

  /// No description provided for @continueCourses.
  ///
  /// In en, this message translates to:
  /// **'Continue Courses'**
  String get continueCourses;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolled;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @excellenceHub.
  ///
  /// In en, this message translates to:
  /// **'Excellence Hub'**
  String get excellenceHub;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing app...'**
  String get splashInitializing;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your learning experience...'**
  String get splashPreparing;

  /// No description provided for @splashReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to go!'**
  String get splashReady;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Transforming Education Through Technology'**
  String get authTagline;

  /// No description provided for @authExpertLed.
  ///
  /// In en, this message translates to:
  /// **'Expert-Led Learning'**
  String get authExpertLed;

  /// No description provided for @authLearnGrowSucceed.
  ///
  /// In en, this message translates to:
  /// **'Learn • Grow • Succeed'**
  String get authLearnGrowSucceed;

  /// No description provided for @authSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Excellence Coaching Hub'**
  String get authSelectionTitle;

  /// No description provided for @authSelectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to continue'**
  String get authSelectionSubtitle;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @phoneAuthTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Authentication'**
  String get phoneAuthTitle;

  /// No description provided for @phoneAuthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to receive a verification code'**
  String get phoneAuthSubtitle;

  /// No description provided for @phoneSignIn.
  ///
  /// In en, this message translates to:
  /// **'Phone Sign In'**
  String get phoneSignIn;

  /// No description provided for @quickAndSecure.
  ///
  /// In en, this message translates to:
  /// **'Quick & Secure Access'**
  String get quickAndSecure;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your phone number for a fast and secure experience. No password required.'**
  String get signInWithPhone;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get enterVerificationCode;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhoneNumber;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @changePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Change phone number'**
  String get changePhoneNumber;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @enterVerificationCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get enterVerificationCodeError;

  /// No description provided for @enter6DigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 6-digit code'**
  String get enter6DigitCode;

  /// No description provided for @phoneAuthBrowserWarning.
  ///
  /// In en, this message translates to:
  /// **'Phone authentication may open a browser for verification. Please allow the process to complete.'**
  String get phoneAuthBrowserWarning;

  /// No description provided for @emailAuthOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Path'**
  String get emailAuthOptionTitle;

  /// No description provided for @emailAuthOptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select how you\'d like to proceed with your account'**
  String get emailAuthOptionSubtitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your existing account'**
  String get signInSubtitle;

  /// No description provided for @signInPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access your account'**
  String get signInPhoneSubtitle;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our community of learners'**
  String get createAccountSubtitle;

  /// No description provided for @createAccountPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our community'**
  String get createAccountPhoneSubtitle;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover your access'**
  String get resetPasswordPhoneSubtitle;

  /// No description provided for @accessYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Access your existing account'**
  String get accessYourAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our community of learners'**
  String get joinCommunity;

  /// No description provided for @recoverAccess.
  ///
  /// In en, this message translates to:
  /// **'Recover your account access'**
  String get recoverAccess;

  /// No description provided for @enterpriseSecurity.
  ///
  /// In en, this message translates to:
  /// **'Your account is protected with enterprise-grade security'**
  String get enterpriseSecurity;

  /// No description provided for @secureProtected.
  ///
  /// In en, this message translates to:
  /// **'Your information is secure and protected'**
  String get secureProtected;

  /// No description provided for @chooseYourPath.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Path'**
  String get chooseYourPath;

  /// No description provided for @selectHowToProceed.
  ///
  /// In en, this message translates to:
  /// **'Select how you\'d like to proceed with your account'**
  String get selectHowToProceed;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please enter your details'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @registerNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get registerNow;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Login now'**
  String get loginNow;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details to get started'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @agreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get agreeToTerms;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you instructions to reset your password'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent! Check your email.'**
  String get resetLinkSent;

  /// No description provided for @enterResetCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Reset Code'**
  String get enterResetCodeTitle;

  /// No description provided for @enterResetCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to your email'**
  String get enterResetCodeSubtitle;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordUpdated;

  /// No description provided for @nameCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s Your Name?'**
  String get nameCollectionTitle;

  /// No description provided for @nameCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us personalize your experience'**
  String get nameCollectionSubtitle;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jean Bosco Uwimana'**
  String get nameHint;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get nameRequiredError;

  /// No description provided for @nameTooShortError.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShortError;

  /// No description provided for @continueToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Continue to Dashboard'**
  String get continueToDashboard;

  /// No description provided for @phoneCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Phone Number'**
  String get phoneCollectionTitle;

  /// No description provided for @phoneCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps secure your account'**
  String get phoneCollectionSubtitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @onboardingInterestTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you interested in?'**
  String get onboardingInterestTitle;

  /// No description provided for @onboardingInterestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select topics you\'d like to learn about'**
  String get onboardingInterestSubtitle;

  /// No description provided for @onboardingPersonalizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Your Learning Goals'**
  String get onboardingPersonalizationTitle;

  /// No description provided for @onboardingPersonalizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us your ambitions and get a personalised path'**
  String get onboardingPersonalizationSubtitle;

  /// No description provided for @shortTermGoal.
  ///
  /// In en, this message translates to:
  /// **'Short Term Goal'**
  String get shortTermGoal;

  /// No description provided for @midTermGoal.
  ///
  /// In en, this message translates to:
  /// **'Mid Term Goal'**
  String get midTermGoal;

  /// No description provided for @longTermGoal.
  ///
  /// In en, this message translates to:
  /// **'Long Term Goal'**
  String get longTermGoal;

  /// No description provided for @shortTermHint.
  ///
  /// In en, this message translates to:
  /// **'What do you want to achieve soon?'**
  String get shortTermHint;

  /// No description provided for @midTermHint.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to be in 1–2 years?'**
  String get midTermHint;

  /// No description provided for @longTermHint.
  ///
  /// In en, this message translates to:
  /// **'What is your ultimate ambition?'**
  String get longTermHint;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveAndContinue;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @ofText.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofText;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @byContinuing.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get byContinuing;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @deviceWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Security'**
  String get deviceWarningTitle;

  /// No description provided for @deviceWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is permanently bound to your first login device. To use a different device, please contact our support team.'**
  String get deviceWarningMessage;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @videoCourses.
  ///
  /// In en, this message translates to:
  /// **'Video Courses'**
  String get videoCourses;

  /// No description provided for @interactiveQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Interactive Quizzes'**
  String get interactiveQuizzes;

  /// No description provided for @certifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certifications;

  /// No description provided for @expertInstructors.
  ///
  /// In en, this message translates to:
  /// **'Expert Instructors'**
  String get expertInstructors;

  /// No description provided for @learnAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Learn Anywhere'**
  String get learnAnywhere;

  /// No description provided for @progressTracking.
  ///
  /// In en, this message translates to:
  /// **'Progress Tracking'**
  String get progressTracking;

  /// No description provided for @studentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get studentDashboard;

  /// No description provided for @startYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Start Your Journey'**
  String get startYourJourney;

  /// No description provided for @findCourseForGoals.
  ///
  /// In en, this message translates to:
  /// **'Find a course for your goals'**
  String get findCourseForGoals;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @motivationalQuote1.
  ///
  /// In en, this message translates to:
  /// **'Build skills for your next opportunity.'**
  String get motivationalQuote1;

  /// No description provided for @motivationalQuote2.
  ///
  /// In en, this message translates to:
  /// **'Every lesson brings you closer to your goal.'**
  String get motivationalQuote2;

  /// No description provided for @motivationalQuote3.
  ///
  /// In en, this message translates to:
  /// **'Keep going — consistency beats talent.'**
  String get motivationalQuote3;

  /// No description provided for @motivationalQuote4.
  ///
  /// In en, this message translates to:
  /// **'Champions learn daily. You are one.'**
  String get motivationalQuote4;

  /// No description provided for @motivationalQuote5.
  ///
  /// In en, this message translates to:
  /// **'Small steps, massive results.'**
  String get motivationalQuote5;

  /// No description provided for @motivationalQuote6.
  ///
  /// In en, this message translates to:
  /// **'Your future self is watching. Make it count.'**
  String get motivationalQuote6;

  /// No description provided for @motivationalQuote7.
  ///
  /// In en, this message translates to:
  /// **'Top performers never stop learning.'**
  String get motivationalQuote7;

  /// No description provided for @welcomeToExcellenceHub.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Excellence Hub!'**
  String get welcomeToExcellenceHub;

  /// No description provided for @startFirstLesson.
  ///
  /// In en, this message translates to:
  /// **'Start your first lesson today and earn XP.'**
  String get startFirstLesson;

  /// No description provided for @keepStreakAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep the streak alive.'**
  String get keepStreakAlive;

  /// No description provided for @consistencyIsSuperpower.
  ///
  /// In en, this message translates to:
  /// **'Your consistency is your superpower.'**
  String get consistencyIsSuperpower;

  /// No description provided for @deviceSecurity.
  ///
  /// In en, this message translates to:
  /// **'Device Security'**
  String get deviceSecurity;

  /// No description provided for @accountBoundToDevice.
  ///
  /// In en, this message translates to:
  /// **'Account secured to this device. Contact support to change.'**
  String get accountBoundToDevice;

  /// No description provided for @refreshApp.
  ///
  /// In en, this message translates to:
  /// **'Refresh App'**
  String get refreshApp;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @searchCourses.
  ///
  /// In en, this message translates to:
  /// **'Search courses, instructors...'**
  String get searchCourses;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for courses, topics...'**
  String get searchHint;

  /// No description provided for @continueLearningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get continueLearningSubtitle;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startLearning;

  /// No description provided for @reviewCourse.
  ///
  /// In en, this message translates to:
  /// **'Review Course'**
  String get reviewCourse;

  /// No description provided for @courseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Course completed!'**
  String get courseCompleted;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get notStarted;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your progress'**
  String get yourProgress;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// No description provided for @popularCourses.
  ///
  /// In en, this message translates to:
  /// **'Popular Courses'**
  String get popularCourses;

  /// No description provided for @noEnrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'No enrolled courses yet'**
  String get noEnrolledCourses;

  /// No description provided for @startLearningToday.
  ///
  /// In en, this message translates to:
  /// **'Start learning today by enrolling in a course!'**
  String get startLearningToday;

  /// No description provided for @browseCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse Courses'**
  String get browseCourses;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @myCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// No description provided for @allCourses.
  ///
  /// In en, this message translates to:
  /// **'All Courses'**
  String get allCourses;

  /// No description provided for @courseDetails.
  ///
  /// In en, this message translates to:
  /// **'Course Details'**
  String get courseDetails;

  /// No description provided for @coursePrice.
  ///
  /// In en, this message translates to:
  /// **'COURSE PRICE'**
  String get coursePrice;

  /// No description provided for @courseCategory.
  ///
  /// In en, this message translates to:
  /// **'COURSE CATEGORY'**
  String get courseCategory;

  /// No description provided for @instructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructor;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @lesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lesson;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get enroll;

  /// No description provided for @enrollNow.
  ///
  /// In en, this message translates to:
  /// **'Enroll Now'**
  String get enrollNow;

  /// No description provided for @enrolling.
  ///
  /// In en, this message translates to:
  /// **'Enrolling...'**
  String get enrolling;

  /// No description provided for @alreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You are already enrolled!'**
  String get alreadyEnrolled;

  /// No description provided for @enrolledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Enrolled successfully!'**
  String get enrolledSuccessfully;

  /// No description provided for @enrollmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Enrollment failed'**
  String get enrollmentFailed;

  /// No description provided for @enrolledInCourse.
  ///
  /// In en, this message translates to:
  /// **'Enrolled in course'**
  String get enrolledInCourse;

  /// No description provided for @youAreEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You are enrolled'**
  String get youAreEnrolled;

  /// No description provided for @redirectingToLearning.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to learning...'**
  String get redirectingToLearning;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @courseDescription.
  ///
  /// In en, this message translates to:
  /// **'Course Description'**
  String get courseDescription;

  /// No description provided for @whatYouWillLearn.
  ///
  /// In en, this message translates to:
  /// **'What You Will Learn'**
  String get whatYouWillLearn;

  /// No description provided for @learningObjectives.
  ///
  /// In en, this message translates to:
  /// **'Learning Objectives'**
  String get learningObjectives;

  /// No description provided for @requirements.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// No description provided for @courseRequirements.
  ///
  /// In en, this message translates to:
  /// **'Course Requirements'**
  String get courseRequirements;

  /// No description provided for @aboutInstructor.
  ///
  /// In en, this message translates to:
  /// **'About Instructor'**
  String get aboutInstructor;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescription;

  /// No description provided for @noThumbnail.
  ///
  /// In en, this message translates to:
  /// **'No thumbnail available'**
  String get noThumbnail;

  /// No description provided for @limitedTimeOffer.
  ///
  /// In en, this message translates to:
  /// **'Limited time offer • 30-day money back guarantee'**
  String get limitedTimeOffer;

  /// No description provided for @lifetimeAccess.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Access'**
  String get lifetimeAccess;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get months;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get years;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learning;

  /// No description provided for @learningTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningTitle;

  /// No description provided for @startLesson.
  ///
  /// In en, this message translates to:
  /// **'Start Lesson'**
  String get startLesson;

  /// No description provided for @nextLesson.
  ///
  /// In en, this message translates to:
  /// **'Next lesson'**
  String get nextLesson;

  /// No description provided for @previousLesson.
  ///
  /// In en, this message translates to:
  /// **'Previous Lesson'**
  String get previousLesson;

  /// No description provided for @completeLesson.
  ///
  /// In en, this message translates to:
  /// **'Complete Lesson'**
  String get completeLesson;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @lessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lesson Completed'**
  String get lessonCompleted;

  /// No description provided for @lessonInProgress.
  ///
  /// In en, this message translates to:
  /// **'Lesson In Progress'**
  String get lessonInProgress;

  /// No description provided for @courseContent.
  ///
  /// In en, this message translates to:
  /// **'Course Content'**
  String get courseContent;

  /// No description provided for @courseOverview.
  ///
  /// In en, this message translates to:
  /// **'Course Overview'**
  String get courseOverview;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @transcript.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcript;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @quizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzesTitle;

  /// No description provided for @takeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take Quiz'**
  String get takeQuiz;

  /// No description provided for @quizResults.
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResults;

  /// No description provided for @yourScore.
  ///
  /// In en, this message translates to:
  /// **'Your Score'**
  String get yourScore;

  /// No description provided for @passingScore.
  ///
  /// In en, this message translates to:
  /// **'Passing Score'**
  String get passingScore;

  /// No description provided for @passed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get passed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @retakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Retake quiz'**
  String get retakeQuiz;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @answers.
  ///
  /// In en, this message translates to:
  /// **'Answers'**
  String get answers;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @submitQuiz.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get submitQuiz;

  /// No description provided for @quizSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Quiz Submitted'**
  String get quizSubmitted;

  /// No description provided for @quizInProgress.
  ///
  /// In en, this message translates to:
  /// **'Quiz in progress'**
  String get quizInProgress;

  /// No description provided for @wishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlist;

  /// No description provided for @savedCourses.
  ///
  /// In en, this message translates to:
  /// **'Saved Courses'**
  String get savedCourses;

  /// No description provided for @addToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Add to Wishlist'**
  String get addToWishlist;

  /// No description provided for @removeFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from Wishlist'**
  String get removeFromWishlist;

  /// No description provided for @addedToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// No description provided for @removedFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// No description provided for @wishlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistEmpty;

  /// No description provided for @wishlistEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save courses you\'re interested in for later'**
  String get wishlistEmptySubtitle;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @completedPayment.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedPayment;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'20% OFF'**
  String get discount;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @transactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get transactionDate;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get paymentSuccessful;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailed;

  /// No description provided for @paymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending'**
  String get paymentPending;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Payment processing'**
  String get paymentProcessing;

  /// No description provided for @initiatePayment.
  ///
  /// In en, this message translates to:
  /// **'Initiate Payment'**
  String get initiatePayment;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @verifyPayment.
  ///
  /// In en, this message translates to:
  /// **'Verify Payment'**
  String get verifyPayment;

  /// No description provided for @mtnMomo.
  ///
  /// In en, this message translates to:
  /// **'MTN Mobile Money'**
  String get mtnMomo;

  /// No description provided for @airtelMoney.
  ///
  /// In en, this message translates to:
  /// **'Airtel Money'**
  String get airtelMoney;

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get creditCard;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @myCertificates.
  ///
  /// In en, this message translates to:
  /// **'My Certificates'**
  String get myCertificates;

  /// No description provided for @downloadCertificate.
  ///
  /// In en, this message translates to:
  /// **'Download Certificate'**
  String get downloadCertificate;

  /// No description provided for @certificateOfCompletion.
  ///
  /// In en, this message translates to:
  /// **'Certificate of Completion'**
  String get certificateOfCompletion;

  /// No description provided for @thisCertifiesThat.
  ///
  /// In en, this message translates to:
  /// **'This certifies that'**
  String get thisCertifiesThat;

  /// No description provided for @hasCompleted.
  ///
  /// In en, this message translates to:
  /// **'has successfully completed'**
  String get hasCompleted;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @certificateId.
  ///
  /// In en, this message translates to:
  /// **'Certificate ID'**
  String get certificateId;

  /// No description provided for @verifyCertificate.
  ///
  /// In en, this message translates to:
  /// **'Verify Certificate'**
  String get verifyCertificate;

  /// No description provided for @noCertificates.
  ///
  /// In en, this message translates to:
  /// **'No certificates yet'**
  String get noCertificates;

  /// No description provided for @noCertificatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete courses to earn certificates'**
  String get noCertificatesSubtitle;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with using the app'**
  String get helpCenterSubtitle;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @accountManagement.
  ///
  /// In en, this message translates to:
  /// **'Account Management'**
  String get accountManagement;

  /// No description provided for @technicalSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get technicalSupport;

  /// No description provided for @howToCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'How do I create an account?'**
  String get howToCreateAccount;

  /// No description provided for @howToEnroll.
  ///
  /// In en, this message translates to:
  /// **'How do I enroll in a course?'**
  String get howToEnroll;

  /// No description provided for @howToAccessOffline.
  ///
  /// In en, this message translates to:
  /// **'Can I access courses offline?'**
  String get howToAccessOffline;

  /// No description provided for @howToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'How do I change my password?'**
  String get howToChangePassword;

  /// No description provided for @howToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get howToUpdateProfile;

  /// No description provided for @howToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get howToDeleteAccount;

  /// No description provided for @appCrashing.
  ///
  /// In en, this message translates to:
  /// **'The app is crashing, what should I do?'**
  String get appCrashing;

  /// No description provided for @videosNotLoading.
  ///
  /// In en, this message translates to:
  /// **'Videos are not loading properly'**
  String get videosNotLoading;

  /// No description provided for @paymentIssues.
  ///
  /// In en, this message translates to:
  /// **'I\'m having payment issues'**
  String get paymentIssues;

  /// No description provided for @createAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Continue with Google\" or \"Continue with Email\" on the welcome screen to create your account.'**
  String get createAccountAnswer;

  /// No description provided for @enrollAnswer.
  ///
  /// In en, this message translates to:
  /// **'Browse courses from the dashboard or courses page, then tap \"Enroll\" on any course you\'re interested in.'**
  String get enrollAnswer;

  /// No description provided for @offlineAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, downloaded videos can be accessed offline. Look for the download icon on course content.'**
  String get offlineAnswer;

  /// No description provided for @changePasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Password & Security to change your password.'**
  String get changePasswordAnswer;

  /// No description provided for @updateProfileAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap your profile picture on the dashboard and select \"Edit Profile\" to update your information.'**
  String get updateProfileAnswer;

  /// No description provided for @deleteAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team at info@excellencecoachinghub.com to request account deletion.'**
  String get deleteAccountAnswer;

  /// No description provided for @crashingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Try closing and reopening the app. If the problem persists, restart your device and reinstall the app.'**
  String get crashingAnswer;

  /// No description provided for @videosAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection. Try switching to a different network or clearing the app cache.'**
  String get videosAnswer;

  /// No description provided for @paymentAnswer.
  ///
  /// In en, this message translates to:
  /// **'Ensure your payment method is valid. If problems continue, contact our support team with details.'**
  String get paymentAnswer;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need More Help?'**
  String get needMoreHelp;

  /// No description provided for @support24_7.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help you 24/7:'**
  String get support24_7;

  /// No description provided for @chatWithUs.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support team now'**
  String get chatWithUs;

  /// No description provided for @alternativeContact.
  ///
  /// In en, this message translates to:
  /// **'Alternative Contact'**
  String get alternativeContact;

  /// No description provided for @secondaryLine.
  ///
  /// In en, this message translates to:
  /// **'Secondary Line:'**
  String get secondaryLine;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformation;

  /// No description provided for @updatePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your personal details'**
  String get updatePersonalDetails;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive important updates and reminders'**
  String get receiveUpdates;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme enabled'**
  String get darkTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme enabled'**
  String get lightTheme;

  /// No description provided for @darkModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Dark mode enabled'**
  String get darkModeEnabled;

  /// No description provided for @lightModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Light mode enabled'**
  String get lightModeEnabled;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @shareThoughts.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts with us'**
  String get shareThoughts;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version and information'**
  String get appVersion;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @readPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicy;

  /// No description provided for @readTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTerms;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @permanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get permanentlyDelete;

  /// No description provided for @signOutAllDevices.
  ///
  /// In en, this message translates to:
  /// **'Sign out from all devices'**
  String get signOutAllDevices;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogout;

  /// No description provided for @areYouSureSignOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get areYouSureSignOut;

  /// No description provided for @areYouSureDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.'**
  String get areYouSureDelete;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @enterPasswordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to confirm:'**
  String get enterPasswordConfirm;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmation;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Reset Onboarding'**
  String get resetOnboarding;

  /// No description provided for @resetOnboardingConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will reset your onboarding status and you will need to complete it again. Do you want to continue?'**
  String get resetOnboardingConfirm;

  /// No description provided for @resetOnboardingFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset onboarding'**
  String get resetOnboardingFailed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @tapToChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap photo to change'**
  String get tapToChangePhoto;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @profileUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get profileUpdateError;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @myDownloads.
  ///
  /// In en, this message translates to:
  /// **'My Downloads'**
  String get myDownloads;

  /// No description provided for @downloadedContent.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Content'**
  String get downloadedContent;

  /// No description provided for @downloadedCourses.
  ///
  /// In en, this message translates to:
  /// **'Downloaded Courses'**
  String get downloadedCourses;

  /// No description provided for @availableOffline.
  ///
  /// In en, this message translates to:
  /// **'Available Offline'**
  String get availableOffline;

  /// No description provided for @downloadCourse.
  ///
  /// In en, this message translates to:
  /// **'Download Course'**
  String get downloadCourse;

  /// No description provided for @downloadLesson.
  ///
  /// In en, this message translates to:
  /// **'Download Lesson'**
  String get downloadLesson;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete'**
  String get downloadComplete;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloads;

  /// No description provided for @noDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download courses to access them offline'**
  String get noDownloadsSubtitle;

  /// No description provided for @deleteDownload.
  ///
  /// In en, this message translates to:
  /// **'Delete Download'**
  String get deleteDownload;

  /// No description provided for @deleteDownloadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this download?'**
  String get deleteDownloadConfirm;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @usedStorage.
  ///
  /// In en, this message translates to:
  /// **'Used Storage'**
  String get usedStorage;

  /// No description provided for @freeStorage.
  ///
  /// In en, this message translates to:
  /// **'Free Storage'**
  String get freeStorage;

  /// No description provided for @manageStorage.
  ///
  /// In en, this message translates to:
  /// **'Manage Storage'**
  String get manageStorage;

  /// No description provided for @clearAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Clear All Downloads'**
  String get clearAllDownloads;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// No description provided for @termsContent.
  ///
  /// In en, this message translates to:
  /// **'By using this application, you agree to our terms of service...\n\n• You must be at least 13 years old\n• Content is for educational purposes only\n• Payments are non-refundable after 7 days\n• We reserve the right to terminate accounts\n\nLast updated: February 1, 2026'**
  String get termsContent;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @readPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacy;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get noNotificationsSubtitle;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @adminAccess.
  ///
  /// In en, this message translates to:
  /// **'Admin Access'**
  String get adminAccess;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get students;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @activeStudents.
  ///
  /// In en, this message translates to:
  /// **'Active Students'**
  String get activeStudents;

  /// No description provided for @newStudents.
  ///
  /// In en, this message translates to:
  /// **'New Students'**
  String get newStudents;

  /// No description provided for @coursesManagement.
  ///
  /// In en, this message translates to:
  /// **'Courses Management'**
  String get coursesManagement;

  /// No description provided for @createCourse.
  ///
  /// In en, this message translates to:
  /// **'Create Course'**
  String get createCourse;

  /// No description provided for @editCourse.
  ///
  /// In en, this message translates to:
  /// **'Edit Course'**
  String get editCourse;

  /// No description provided for @deleteCourse.
  ///
  /// In en, this message translates to:
  /// **'Delete Course'**
  String get deleteCourse;

  /// No description provided for @courseCreated.
  ///
  /// In en, this message translates to:
  /// **'Course created successfully'**
  String get courseCreated;

  /// No description provided for @courseUpdated.
  ///
  /// In en, this message translates to:
  /// **'Course updated successfully'**
  String get courseUpdated;

  /// No description provided for @courseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Course deleted successfully'**
  String get courseDeleted;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @addLesson.
  ///
  /// In en, this message translates to:
  /// **'Add Lesson'**
  String get addLesson;

  /// No description provided for @editLesson.
  ///
  /// In en, this message translates to:
  /// **'Edit Lesson'**
  String get editLesson;

  /// No description provided for @deleteLesson.
  ///
  /// In en, this message translates to:
  /// **'Delete Lesson'**
  String get deleteLesson;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @courseAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Course Analytics'**
  String get courseAnalytics;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @enrollments.
  ///
  /// In en, this message translates to:
  /// **'Enrollments'**
  String get enrollments;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average Rating'**
  String get averageRating;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @studentRole.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentRole;

  /// No description provided for @instructorRole.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get instructorRole;

  /// No description provided for @moderatorRole.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get moderatorRole;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @userFeedback.
  ///
  /// In en, this message translates to:
  /// **'User Feedback'**
  String get userFeedback;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @paymentSettings.
  ///
  /// In en, this message translates to:
  /// **'Payment Settings'**
  String get paymentSettings;

  /// No description provided for @notificationSettingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettingsAdmin;

  /// No description provided for @contentModeration.
  ///
  /// In en, this message translates to:
  /// **'Content Moderation'**
  String get contentModeration;

  /// No description provided for @syncUsers.
  ///
  /// In en, this message translates to:
  /// **'Sync Users'**
  String get syncUsers;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @applicationRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Application refreshed'**
  String get applicationRefreshed;

  /// No description provided for @landingTitle.
  ///
  /// In en, this message translates to:
  /// **'Master New Skills'**
  String get landingTitle;

  /// No description provided for @landingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access world-class courses from industry experts'**
  String get landingSubtitle;

  /// No description provided for @getStartedFree.
  ///
  /// In en, this message translates to:
  /// **'Get Started for Free'**
  String get getStartedFree;

  /// No description provided for @exploreCourses.
  ///
  /// In en, this message translates to:
  /// **'Explore Courses'**
  String get exploreCourses;

  /// No description provided for @trustedBy.
  ///
  /// In en, this message translates to:
  /// **'Trusted by learners worldwide'**
  String get trustedBy;

  /// No description provided for @whyChooseUs.
  ///
  /// In en, this message translates to:
  /// **'Why Choose Us?'**
  String get whyChooseUs;

  /// No description provided for @enrolledCourses.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Courses'**
  String get enrolledCourses;

  /// No description provided for @updateInterests.
  ///
  /// In en, this message translates to:
  /// **'Update Interests'**
  String get updateInterests;

  /// No description provided for @updateYourInterests.
  ///
  /// In en, this message translates to:
  /// **'Update your interests'**
  String get updateYourInterests;

  /// No description provided for @selectInterests.
  ///
  /// In en, this message translates to:
  /// **'Select topics you\'re interested in'**
  String get selectInterests;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completion;

  /// No description provided for @courseCompletion.
  ///
  /// In en, this message translates to:
  /// **'Course Completion'**
  String get courseCompletion;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @quarterWay.
  ///
  /// In en, this message translates to:
  /// **'Quarter way there!'**
  String get quarterWay;

  /// No description provided for @momentumBuilding.
  ///
  /// In en, this message translates to:
  /// **'You have hit 25% — momentum is building!'**
  String get momentumBuilding;

  /// No description provided for @halfwayChampion.
  ///
  /// In en, this message translates to:
  /// **'Halfway champion!'**
  String get halfwayChampion;

  /// No description provided for @finishLineReal.
  ///
  /// In en, this message translates to:
  /// **'You are at 50% — the finish line is real.'**
  String get finishLineReal;

  /// No description provided for @almostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get almostThere;

  /// No description provided for @nearlyUnstoppable.
  ///
  /// In en, this message translates to:
  /// **'75% done — you are nearly unstoppable.'**
  String get nearlyUnstoppable;

  /// No description provided for @incredibleEffort.
  ///
  /// In en, this message translates to:
  /// **'You finished a course. Incredible effort!'**
  String get incredibleEffort;

  /// No description provided for @myLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibrary;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @exam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get exam;

  /// No description provided for @takeExam.
  ///
  /// In en, this message translates to:
  /// **'Take Exam'**
  String get takeExam;

  /// No description provided for @examResults.
  ///
  /// In en, this message translates to:
  /// **'Exam Results'**
  String get examResults;

  /// No description provided for @examTime.
  ///
  /// In en, this message translates to:
  /// **'Exam Time'**
  String get examTime;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time Left'**
  String get timeLeft;

  /// No description provided for @examInstructions.
  ///
  /// In en, this message translates to:
  /// **'Exam Instructions'**
  String get examInstructions;

  /// No description provided for @examSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Exam Submitted'**
  String get examSubmitted;

  /// No description provided for @examScore.
  ///
  /// In en, this message translates to:
  /// **'Exam Score'**
  String get examScore;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @examPassed.
  ///
  /// In en, this message translates to:
  /// **'Exam Passed'**
  String get examPassed;

  /// No description provided for @examFailed.
  ///
  /// In en, this message translates to:
  /// **'Exam Failed'**
  String get examFailed;

  /// No description provided for @onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboarding;

  /// No description provided for @completeOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Complete Onboarding'**
  String get completeOnboarding;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackSent;

  /// No description provided for @feedbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send feedback. Please try again.'**
  String get feedbackFailed;

  /// No description provided for @howCanWeImprove.
  ///
  /// In en, this message translates to:
  /// **'Tell us how we can improve...'**
  String get howCanWeImprove;

  /// No description provided for @enterFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please enter some feedback'**
  String get enterFeedback;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'A premium learning platform for continuous education and skill development.'**
  String get aboutApp;

  /// No description provided for @appVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionInfo;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Excellence Coaching Hub'**
  String get copyright;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @actionCannotUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotUndone;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Action'**
  String get confirmAction;

  /// No description provided for @generalError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get generalError;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized access'**
  String get unauthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'Forbidden'**
  String get forbidden;

  /// No description provided for @invalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalidInput;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @shareCourse.
  ///
  /// In en, this message translates to:
  /// **'Check out this amazing course'**
  String get shareCourse;

  /// No description provided for @shareCourseSubject.
  ///
  /// In en, this message translates to:
  /// **'Course Recommendation'**
  String get shareCourseSubject;

  /// No description provided for @learnMoreAt.
  ///
  /// In en, this message translates to:
  /// **'Learn more at Excellence Coaching Hub!'**
  String get learnMoreAt;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back! Keep the streak alive.'**
  String get welcomeBackTitle;

  /// No description provided for @yourConsistency.
  ///
  /// In en, this message translates to:
  /// **'Your consistency is your superpower.'**
  String get yourConsistency;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @learningStatistics.
  ///
  /// In en, this message translates to:
  /// **'Learning Statistics'**
  String get learningStatistics;

  /// No description provided for @coursesEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Courses Enrolled'**
  String get coursesEnrolled;

  /// No description provided for @lessonsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lessons Completed'**
  String get lessonsCompleted;

  /// No description provided for @examsTaken.
  ///
  /// In en, this message translates to:
  /// **'Exams Taken'**
  String get examsTaken;

  /// No description provided for @hoursLearned.
  ///
  /// In en, this message translates to:
  /// **'Hours Learned'**
  String get hoursLearned;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available'**
  String get noCategoriesAvailable;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @searchAcrossAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Search across all available courses'**
  String get searchAcrossAllCourses;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @liveClassesAvailable.
  ///
  /// In en, this message translates to:
  /// **'Live Classes Available'**
  String get liveClassesAvailable;

  /// No description provided for @contactUsForLiveClasses.
  ///
  /// In en, this message translates to:
  /// **'Contact Us for Live Classes'**
  String get contactUsForLiveClasses;

  /// No description provided for @liveClassesBenefit.
  ///
  /// In en, this message translates to:
  /// **'Get real-time interaction, instant feedback & personalized guidance from instructors.'**
  String get liveClassesBenefit;

  /// No description provided for @myProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgress;

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get averageScore;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @exploreCategories.
  ///
  /// In en, this message translates to:
  /// **'Explore Categories'**
  String get exploreCategories;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @whatsappNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Not Available'**
  String get whatsappNotAvailable;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed or not accessible on this device.'**
  String get whatsappNotInstalled;

  /// No description provided for @callNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Call Not Available'**
  String get callNotAvailable;

  /// No description provided for @phoneCallsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Phone calls are not supported on this device.'**
  String get phoneCallsNotSupported;

  /// No description provided for @emailNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Email Not Available'**
  String get emailNotAvailable;

  /// No description provided for @emailClientNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Email client is not available on this device.'**
  String get emailClientNotAvailable;

  /// No description provided for @refreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed'**
  String get refreshed;

  /// No description provided for @dashboardRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Dashboard refreshed'**
  String get dashboardRefreshed;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @callDirectly.
  ///
  /// In en, this message translates to:
  /// **'Call Directly'**
  String get callDirectly;

  /// No description provided for @copyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy Number'**
  String get copyNumber;

  /// No description provided for @copyToClipboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboardLabel;

  /// No description provided for @whatsappMessage.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Message'**
  String get whatsappMessage;

  /// No description provided for @sendWhatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Send WhatsApp message'**
  String get sendWhatsAppMessage;

  /// No description provided for @selectedCategory.
  ///
  /// In en, this message translates to:
  /// **'Selected category'**
  String get selectedCategory;

  /// No description provided for @failedToLoadCourses.
  ///
  /// In en, this message translates to:
  /// **'Failed to load courses'**
  String get failedToLoadCourses;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseTryAgainLater;

  /// No description provided for @untitledCourse.
  ///
  /// In en, this message translates to:
  /// **'Untitled Course'**
  String get untitledCourse;

  /// No description provided for @noCoursesFound.
  ///
  /// In en, this message translates to:
  /// **'No courses found'**
  String get noCoursesFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter criteria'**
  String get tryAdjustingSearch;

  /// No description provided for @browseAllAvailableCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse all available courses'**
  String get browseAllAvailableCourses;

  /// No description provided for @quizInstructions.
  ///
  /// In en, this message translates to:
  /// **'Quiz Instructions'**
  String get quizInstructions;

  /// No description provided for @quizOnlyLesson.
  ///
  /// In en, this message translates to:
  /// **'Quiz-Only Lesson'**
  String get quizOnlyLesson;

  /// No description provided for @openAIChat.
  ///
  /// In en, this message translates to:
  /// **'Open AI chat'**
  String get openAIChat;

  /// No description provided for @certificateProcessing.
  ///
  /// In en, this message translates to:
  /// **'Certificate Processing'**
  String get certificateProcessing;

  /// No description provided for @viewCertificates.
  ///
  /// In en, this message translates to:
  /// **'View Certificates'**
  String get viewCertificates;

  /// No description provided for @generateNow.
  ///
  /// In en, this message translates to:
  /// **'Generate Now'**
  String get generateNow;

  /// No description provided for @finalExamFailed.
  ///
  /// In en, this message translates to:
  /// **'Final Exam Failed'**
  String get finalExamFailed;

  /// No description provided for @certificateAlreadyEarned.
  ///
  /// In en, this message translates to:
  /// **'Certificate Already Earned'**
  String get certificateAlreadyEarned;

  /// No description provided for @unenrollFromCourse.
  ///
  /// In en, this message translates to:
  /// **'Unenroll from Course'**
  String get unenrollFromCourse;

  /// No description provided for @unenroll.
  ///
  /// In en, this message translates to:
  /// **'Unenroll'**
  String get unenroll;

  /// No description provided for @viewCertificate.
  ///
  /// In en, this message translates to:
  /// **'View Certificate'**
  String get viewCertificate;

  /// No description provided for @lessonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get lessonNotFound;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @aiHelp.
  ///
  /// In en, this message translates to:
  /// **'AI Help'**
  String get aiHelp;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// No description provided for @currentLesson.
  ///
  /// In en, this message translates to:
  /// **'Current lesson'**
  String get currentLesson;

  /// No description provided for @advancedTopics.
  ///
  /// In en, this message translates to:
  /// **'Advanced topics'**
  String get advancedTopics;

  /// No description provided for @learningPlatform.
  ///
  /// In en, this message translates to:
  /// **'Learning Platform'**
  String get learningPlatform;

  /// No description provided for @askAI.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAI;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @videoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video not available'**
  String get videoNotAvailable;

  /// No description provided for @viewInDownloads.
  ///
  /// In en, this message translates to:
  /// **'View in Downloads'**
  String get viewInDownloads;

  /// No description provided for @noVideoAvailableForDownload.
  ///
  /// In en, this message translates to:
  /// **'No video available for download'**
  String get noVideoAvailableForDownload;

  /// No description provided for @aboutThisLesson.
  ///
  /// In en, this message translates to:
  /// **'About this lesson'**
  String get aboutThisLesson;

  /// No description provided for @comprehensiveStudyGuide.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive study guide'**
  String get comprehensiveStudyGuide;

  /// No description provided for @additionalLearningResource.
  ///
  /// In en, this message translates to:
  /// **'Additional learning resource'**
  String get additionalLearningResource;

  /// No description provided for @learningMaterials.
  ///
  /// In en, this message translates to:
  /// **'Learning materials'**
  String get learningMaterials;

  /// No description provided for @watchLessonVideo.
  ///
  /// In en, this message translates to:
  /// **'Watch the lesson video'**
  String get watchLessonVideo;

  /// No description provided for @reviewLessonNotes.
  ///
  /// In en, this message translates to:
  /// **'Review lesson notes'**
  String get reviewLessonNotes;

  /// No description provided for @completeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Complete the quiz'**
  String get completeQuiz;

  /// No description provided for @markLessonComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark lesson complete'**
  String get markLessonComplete;

  /// No description provided for @lessonOverview.
  ///
  /// In en, this message translates to:
  /// **'Lesson overview'**
  String get lessonOverview;

  /// No description provided for @aiTutor.
  ///
  /// In en, this message translates to:
  /// **'AI Tutor'**
  String get aiTutor;

  /// No description provided for @askAnythingAboutLesson.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about this lesson'**
  String get askAnythingAboutLesson;

  /// No description provided for @simplifyMainConcept.
  ///
  /// In en, this message translates to:
  /// **'Try: \"Simplify the main concept for me\"'**
  String get simplifyMainConcept;

  /// No description provided for @lessonsDone.
  ///
  /// In en, this message translates to:
  /// **'Lessons done'**
  String get lessonsDone;

  /// No description provided for @lessonNotes.
  ///
  /// In en, this message translates to:
  /// **'Lesson Notes'**
  String get lessonNotes;

  /// No description provided for @downloadPDF.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPDF;

  /// No description provided for @viewDownloads.
  ///
  /// In en, this message translates to:
  /// **'View Downloads'**
  String get viewDownloads;

  /// No description provided for @pdfView.
  ///
  /// In en, this message translates to:
  /// **'PDF View'**
  String get pdfView;

  /// No description provided for @textView.
  ///
  /// In en, this message translates to:
  /// **'Text View'**
  String get textView;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get noNotesAvailable;

  /// No description provided for @lessonNoNotesYet.
  ///
  /// In en, this message translates to:
  /// **'This lesson doesn\'t have notes yet'**
  String get lessonNoNotesYet;

  /// No description provided for @quizQuestions.
  ///
  /// In en, this message translates to:
  /// **'Quiz Questions'**
  String get quizQuestions;

  /// No description provided for @failedToLoadQuizQuestions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load quiz questions'**
  String get failedToLoadQuizQuestions;

  /// No description provided for @noQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get noQuestionsAvailable;

  /// No description provided for @quizNoQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'This quiz doesn\'t have any questions yet'**
  String get quizNoQuestionsYet;

  /// No description provided for @testUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Test your understanding of this lesson'**
  String get testUnderstanding;

  /// No description provided for @viewAttemptHistory.
  ///
  /// In en, this message translates to:
  /// **'View attempt history'**
  String get viewAttemptHistory;

  /// No description provided for @attemptHistory.
  ///
  /// In en, this message translates to:
  /// **'Attempt history'**
  String get attemptHistory;

  /// No description provided for @noAttemptsYet.
  ///
  /// In en, this message translates to:
  /// **'No attempts yet'**
  String get noAttemptsYet;

  /// No description provided for @completeQuizSeeResults.
  ///
  /// In en, this message translates to:
  /// **'Complete the quiz to see your results here'**
  String get completeQuizSeeResults;

  /// No description provided for @studyTips.
  ///
  /// In en, this message translates to:
  /// **'Study tips'**
  String get studyTips;

  /// No description provided for @courseFeedback.
  ///
  /// In en, this message translates to:
  /// **'Course Feedback'**
  String get courseFeedback;

  /// No description provided for @shareExperienceImprove.
  ///
  /// In en, this message translates to:
  /// **'Share your experience and help us improve'**
  String get shareExperienceImprove;

  /// No description provided for @rateThisCourse.
  ///
  /// In en, this message translates to:
  /// **'Rate this course'**
  String get rateThisCourse;

  /// No description provided for @tapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get tapToRate;

  /// No description provided for @yourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get yourFeedback;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @updateYourFeedback.
  ///
  /// In en, this message translates to:
  /// **'Update Your Feedback'**
  String get updateYourFeedback;

  /// No description provided for @studentReviews.
  ///
  /// In en, this message translates to:
  /// **'Student Reviews'**
  String get studentReviews;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @anonymousStudent.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Student'**
  String get anonymousStudent;

  /// No description provided for @lessonMaterial.
  ///
  /// In en, this message translates to:
  /// **'Lesson Material'**
  String get lessonMaterial;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @successfullyUnenrolled.
  ///
  /// In en, this message translates to:
  /// **'Successfully unenrolled from course'**
  String get successfullyUnenrolled;

  /// No description provided for @noVideoAvailableLesson.
  ///
  /// In en, this message translates to:
  /// **'No video available for this lesson'**
  String get noVideoAvailableLesson;

  /// No description provided for @lessonBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Lesson bookmarked!'**
  String get lessonBookmarked;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// No description provided for @checkOutLesson.
  ///
  /// In en, this message translates to:
  /// **'Check out this lesson from Excellence Coaching Hub'**
  String get checkOutLesson;

  /// No description provided for @askAIButton.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAIButton;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @resumeLessons.
  ///
  /// In en, this message translates to:
  /// **'Resume lessons'**
  String get resumeLessons;

  /// No description provided for @studyOffline.
  ///
  /// In en, this message translates to:
  /// **'Study offline'**
  String get studyOffline;

  /// No description provided for @showProgress.
  ///
  /// In en, this message translates to:
  /// **'Show progress'**
  String get showProgress;

  /// No description provided for @reviewResults.
  ///
  /// In en, this message translates to:
  /// **'Review results'**
  String get reviewResults;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @professionalLearningFailedToLoadCourse.
  ///
  /// In en, this message translates to:
  /// **'Failed to load course'**
  String get professionalLearningFailedToLoadCourse;

  /// No description provided for @professionalLearningCheckConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get professionalLearningCheckConnectionTryAgain;

  /// No description provided for @professionalLearningCourseInformation.
  ///
  /// In en, this message translates to:
  /// **'Course Information'**
  String get professionalLearningCourseInformation;

  /// No description provided for @professionalLearningYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get professionalLearningYourProgress;

  /// No description provided for @professionalLearningComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get professionalLearningComplete;

  /// No description provided for @professionalLearningContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get professionalLearningContinueLearning;

  /// No description provided for @professionalLearningViewContent.
  ///
  /// In en, this message translates to:
  /// **'View Content'**
  String get professionalLearningViewContent;

  /// No description provided for @professionalLearningNoContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get professionalLearningNoContentAvailable;

  /// No description provided for @professionalLearningOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get professionalLearningOverview;

  /// No description provided for @professionalLearningContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get professionalLearningContent;

  /// No description provided for @professionalLearningResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get professionalLearningResources;

  /// No description provided for @professionalLearningRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get professionalLearningRefresh;

  /// No description provided for @professionalLearningCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get professionalLearningCertificates;

  /// No description provided for @professionalLearningYourCertificates.
  ///
  /// In en, this message translates to:
  /// **'Your Certificates'**
  String get professionalLearningYourCertificates;

  /// No description provided for @professionalLearningCertificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get professionalLearningCertificate;

  /// No description provided for @professionalLearningIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get professionalLearningIssued;

  /// No description provided for @professionalLearningAdditionalResources.
  ///
  /// In en, this message translates to:
  /// **'Additional Resources'**
  String get professionalLearningAdditionalResources;

  /// No description provided for @professionalLearningStudentGuide.
  ///
  /// In en, this message translates to:
  /// **'Student Guide'**
  String get professionalLearningStudentGuide;

  /// No description provided for @professionalLearningStudentGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with navigation and features'**
  String get professionalLearningStudentGuideSubtitle;

  /// No description provided for @professionalLearningAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get professionalLearningAiAssistant;

  /// No description provided for @professionalLearningAiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help with course content'**
  String get professionalLearningAiAssistantSubtitle;

  /// No description provided for @professionalLearningContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get professionalLearningContinue;

  /// No description provided for @professionalLearningNoLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available'**
  String get professionalLearningNoLessonsAvailable;

  /// No description provided for @professionalLearningLessonsCount.
  ///
  /// In en, this message translates to:
  /// **'lessons'**
  String get professionalLearningLessonsCount;

  /// No description provided for @lessonScreenLessonNotFound.
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get lessonScreenLessonNotFound;

  /// No description provided for @lessonScreenLessonNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The lesson you\'re looking for doesn\'t exist or has been removed.'**
  String get lessonScreenLessonNotFoundMessage;

  /// No description provided for @lessonScreenGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get lessonScreenGoBack;

  /// No description provided for @lessonScreenCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get lessonScreenCompleted;

  /// No description provided for @lessonScreenAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get lessonScreenAiAssistant;

  /// No description provided for @lessonScreenReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get lessonScreenReportIssue;

  /// No description provided for @lessonScreenNoVideoAvailable.
  ///
  /// In en, this message translates to:
  /// **'No video available'**
  String get lessonScreenNoVideoAvailable;

  /// No description provided for @lessonScreenLessonOverview.
  ///
  /// In en, this message translates to:
  /// **'Lesson Overview'**
  String get lessonScreenLessonOverview;

  /// No description provided for @lessonScreenNoDuration.
  ///
  /// In en, this message translates to:
  /// **'No duration'**
  String get lessonScreenNoDuration;

  /// No description provided for @lessonScreenPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get lessonScreenPrevious;

  /// No description provided for @lessonScreenNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lessonScreenNext;

  /// No description provided for @lessonScreenMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get lessonScreenMarkComplete;

  /// No description provided for @lessonScreenMarkLessonComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark lesson complete'**
  String get lessonScreenMarkLessonComplete;

  /// No description provided for @searchInCategory.
  ///
  /// In en, this message translates to:
  /// **'Search in {category}...'**
  String searchInCategory(Object category);

  /// No description provided for @filterCourses.
  ///
  /// In en, this message translates to:
  /// **'Filter Courses'**
  String get filterCourses;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'Short (<1h)'**
  String get short;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium (1-3h)'**
  String get medium;

  /// No description provided for @long.
  ///
  /// In en, this message translates to:
  /// **'Long (>3h)'**
  String get long;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @stars4Plus.
  ///
  /// In en, this message translates to:
  /// **'4+ Stars'**
  String get stars4Plus;

  /// No description provided for @stars4_5Plus.
  ///
  /// In en, this message translates to:
  /// **'4.5+ Stars'**
  String get stars4_5Plus;

  /// No description provided for @adjustSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter criteria'**
  String get adjustSearchCriteria;

  /// No description provided for @basedOnYourInterests.
  ///
  /// In en, this message translates to:
  /// **'Based on your interests: {interests}'**
  String basedOnYourInterests(Object interests);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @coursesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} courses'**
  String coursesCount(Object count);

  /// No description provided for @browseAllCourses.
  ///
  /// In en, this message translates to:
  /// **'Browse all available courses'**
  String get browseAllCourses;

  /// No description provided for @byInstructor.
  ///
  /// In en, this message translates to:
  /// **'by {instructor}'**
  String byInstructor(Object instructor);

  /// No description provided for @noThumbnailAvailable.
  ///
  /// In en, this message translates to:
  /// **'No thumbnail available'**
  String get noThumbnailAvailable;

  /// No description provided for @aboutThisCourse.
  ///
  /// In en, this message translates to:
  /// **'About This Course'**
  String get aboutThisCourse;

  /// No description provided for @meetYourInstructor.
  ///
  /// In en, this message translates to:
  /// **'Meet Your Instructor'**
  String get meetYourInstructor;

  /// No description provided for @leadInstructor.
  ///
  /// In en, this message translates to:
  /// **'Lead Instructor & Course Creator'**
  String get leadInstructor;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start Learning?'**
  String get readyToStart;

  /// No description provided for @joinThousands.
  ///
  /// In en, this message translates to:
  /// **'Join thousands of students who have already transformed their skills'**
  String get joinThousands;

  /// No description provided for @checkingEnrollment.
  ///
  /// In en, this message translates to:
  /// **'Checking enrollment status...'**
  String get checkingEnrollment;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get access;

  /// No description provided for @lifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime'**
  String get lifetime;

  /// No description provided for @redirecting.
  ///
  /// In en, this message translates to:
  /// **'Redirecting...'**
  String get redirecting;

  /// No description provided for @withYearsExperience.
  ///
  /// In en, this message translates to:
  /// **'With extensive teaching experience and expertise in modern practices, our instructor brings real-world knowledge to help you succeed.'**
  String get withYearsExperience;

  /// No description provided for @sidebarSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get sidebarSignIn;

  /// No description provided for @sidebarRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get sidebarRegister;

  /// No description provided for @sidebarUnlockPotential.
  ///
  /// In en, this message translates to:
  /// **'Unlock your potential with expert-led courses.'**
  String get sidebarUnlockPotential;

  /// No description provided for @sidebarLearningPlatform.
  ///
  /// In en, this message translates to:
  /// **'LEARNING PLATFORM'**
  String get sidebarLearningPlatform;

  /// No description provided for @sidebarSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get sidebarSectionOverview;

  /// No description provided for @sidebarSectionLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get sidebarSectionLearning;

  /// No description provided for @sidebarSectionConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get sidebarSectionConnect;

  /// No description provided for @sidebarSectionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get sidebarSectionManage;

  /// No description provided for @sidebarSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sidebarSectionAccount;

  /// No description provided for @sidebarSectionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get sidebarSectionGetStarted;

  /// No description provided for @sidebarViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get sidebarViewProfile;

  /// No description provided for @sidebarAdminNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sidebarAdminNotifications;

  /// No description provided for @sidebarAdminStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get sidebarAdminStudents;

  /// No description provided for @sidebarAdminPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get sidebarAdminPayments;

  /// No description provided for @sidebarAdminAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get sidebarAdminAnalytics;

  /// No description provided for @sidebarAreYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get sidebarAreYouSureLogout;

  /// No description provided for @sidebarExpandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand Sidebar'**
  String get sidebarExpandSidebar;

  /// No description provided for @sidebarCollapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse Sidebar'**
  String get sidebarCollapseSidebar;

  /// No description provided for @sidebarGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get sidebarGoBack;

  /// No description provided for @sidebarRefreshApp.
  ///
  /// In en, this message translates to:
  /// **'Refresh App'**
  String get sidebarRefreshApp;

  /// No description provided for @examPreparation.
  ///
  /// In en, this message translates to:
  /// **'Exam Preparation'**
  String get examPreparation;

  /// No description provided for @examPreparationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prepare for your exams with past papers and practice tests'**
  String get examPreparationSubtitle;

  /// No description provided for @examPreparationBenefit.
  ///
  /// In en, this message translates to:
  /// **'Access past papers, practice tests, and expert guidance to ace your exams'**
  String get examPreparationBenefit;

  /// No description provided for @visitExamMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Visit Exam Marketplace'**
  String get visitExamMarketplace;

  /// No description provided for @examMarketplaceUrl.
  ///
  /// In en, this message translates to:
  /// **'https://www.eexams.net/marketplace'**
  String get examMarketplaceUrl;

  /// No description provided for @notificationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Delete All Notifications'**
  String get deleteAllNotifications;

  /// No description provided for @deleteAllNotificationsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all notifications? This action cannot be undone.'**
  String get deleteAllNotificationsConfirm;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @allNotificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get allNotificationsDeleted;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noNotificationsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see important updates here'**
  String get noNotificationsYetSubtitle;

  /// No description provided for @failedToLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get failedToLoadNotifications;

  /// No description provided for @notificationTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get notificationTypePayment;

  /// No description provided for @notificationTypeCourse.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get notificationTypeCourse;

  /// No description provided for @notificationTypeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get notificationTypeExam;

  /// No description provided for @notificationTypeAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get notificationTypeAchievement;

  /// No description provided for @notificationTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get notificationTypeReminder;

  /// No description provided for @notificationTypePromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get notificationTypePromotion;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// No description provided for @reminderDontBreakStreak.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your streak!'**
  String get reminderDontBreakStreak;

  /// No description provided for @reminderDontBreakStreakBody.
  ///
  /// In en, this message translates to:
  /// **'Your brain misses learning. Just 5 minutes today?'**
  String get reminderDontBreakStreakBody;

  /// No description provided for @reminderMissYou.
  ///
  /// In en, this message translates to:
  /// **'Excellence Hub misses you'**
  String get reminderMissYou;

  /// No description provided for @reminderMissYouBody.
  ///
  /// In en, this message translates to:
  /// **'Ready to master that next lesson? Come on back!'**
  String get reminderMissYouBody;

  /// No description provided for @reminderGoalWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your goal is waiting!'**
  String get reminderGoalWaiting;

  /// No description provided for @reminderGoalWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Success doesn\'t happen by itself. Let\'s learn something new.'**
  String get reminderGoalWaitingBody;

  /// No description provided for @reminderQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick reminder...'**
  String get reminderQuick;

  /// No description provided for @reminderQuickBody.
  ///
  /// In en, this message translates to:
  /// **'Consistency is the key to mastery. See you in the app!'**
  String get reminderQuickBody;

  /// No description provided for @reminderPsst.
  ///
  /// In en, this message translates to:
  /// **'Psst...'**
  String get reminderPsst;

  /// No description provided for @reminderPsstBody.
  ///
  /// In en, this message translates to:
  /// **'A little bird told me you haven\'t learned anything today.'**
  String get reminderPsstBody;

  /// No description provided for @reminderMomentum.
  ///
  /// In en, this message translates to:
  /// **'Keep the momentum!'**
  String get reminderMomentum;

  /// No description provided for @reminderMomentumBody.
  ///
  /// In en, this message translates to:
  /// **'You were doing so well! Don\'t stop now.'**
  String get reminderMomentumBody;

  /// No description provided for @paymentPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Payment Pending Approval'**
  String get paymentPendingApproval;

  /// No description provided for @waitingForAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for admin approval...'**
  String get waitingForAdminApproval;

  /// No description provided for @stillWaitingForAdminApproval.
  ///
  /// In en, this message translates to:
  /// **'Still waiting for admin approval...'**
  String get stillWaitingForAdminApproval;

  /// No description provided for @noPaymentFoundForCourse.
  ///
  /// In en, this message translates to:
  /// **'No payment found for this course'**
  String get noPaymentFoundForCourse;

  /// No description provided for @paymentApprovedRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Payment Approved! Redirecting to course...'**
  String get paymentApprovedRedirecting;

  /// No description provided for @paymentPendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Your payment for \"{course}\" is currently pending admin approval.'**
  String paymentPendingDescription(Object course);

  /// No description provided for @directPaymentAvailable.
  ///
  /// In en, this message translates to:
  /// **'Direct Payment Available'**
  String get directPaymentAvailable;

  /// No description provided for @momoCode.
  ///
  /// In en, this message translates to:
  /// **'MoMo Code'**
  String get momoCode;

  /// No description provided for @momoCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'MoMo code copied to clipboard!'**
  String get momoCodeCopied;

  /// No description provided for @directPaymentDescription.
  ///
  /// In en, this message translates to:
  /// **'You can pay directly using the MoMo code above or contact us for other payment options.'**
  String get directPaymentDescription;

  /// No description provided for @courseAccessDuration.
  ///
  /// In en, this message translates to:
  /// **'Course Access Duration'**
  String get courseAccessDuration;

  /// No description provided for @courseAccessDurationDescription.
  ///
  /// In en, this message translates to:
  /// **'You will have access to this course for {duration} {unit}'**
  String courseAccessDurationDescription(Object duration, Object unit);

  /// No description provided for @courseAccessDurationWarning.
  ///
  /// In en, this message translates to:
  /// **'Important: You must complete the course within this time period. Access will expire automatically after {duration} {unit} and you will need to repurchase to regain access.'**
  String courseAccessDurationWarning(Object duration, Object unit);

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @toCompletePayment.
  ///
  /// In en, this message translates to:
  /// **'To complete your payment:'**
  String get toCompletePayment;

  /// No description provided for @paymentViaMtnMomo.
  ///
  /// In en, this message translates to:
  /// **'Payment via MTN MoMo:'**
  String get paymentViaMtnMomo;

  /// No description provided for @paymentViaAirtelMoney.
  ///
  /// In en, this message translates to:
  /// **'Payment via Airtel Money:'**
  String get paymentViaAirtelMoney;

  /// No description provided for @paymentViaBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Payment via Bank Transfer ({bank}):'**
  String paymentViaBankTransfer(Object bank);

  /// No description provided for @contactSupportPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact Support Phone:'**
  String get contactSupportPhone;

  /// No description provided for @contactSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact Support Email:'**
  String get contactSupportEmail;

  /// No description provided for @contactOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Contact on WhatsApp:'**
  String get contactOnWhatsapp;

  /// No description provided for @contactForPayment.
  ///
  /// In en, this message translates to:
  /// **'1. Contact for payment via:'**
  String get contactForPayment;

  /// No description provided for @alsoAvailableVia.
  ///
  /// In en, this message translates to:
  /// **'2. Also available via:'**
  String get alsoAvailableVia;

  /// No description provided for @additionalContact.
  ///
  /// In en, this message translates to:
  /// **'3. Additional contact:'**
  String get additionalContact;

  /// No description provided for @contactViaEmail.
  ///
  /// In en, this message translates to:
  /// **'4. Contact via email:'**
  String get contactViaEmail;

  /// No description provided for @contactOnWhatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'5. Or contact us on WhatsApp:'**
  String get contactOnWhatsappNumber;

  /// No description provided for @keepTransactionId.
  ///
  /// In en, this message translates to:
  /// **'Important: Keep your transaction ID for reference and send proof of payment to admin.'**
  String get keepTransactionId;

  /// No description provided for @autoCheckingPayment.
  ///
  /// In en, this message translates to:
  /// **'Automatically checking payment status every 5 seconds...'**
  String get autoCheckingPayment;

  /// No description provided for @backToCourse.
  ///
  /// In en, this message translates to:
  /// **'Back to Course'**
  String get backToCourse;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get checkStatus;

  /// No description provided for @myPayments.
  ///
  /// In en, this message translates to:
  /// **'My Payments'**
  String get myPayments;

  /// No description provided for @errorLoadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Error loading payments'**
  String get errorLoadingPayments;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments found'**
  String get noPaymentsFound;

  /// No description provided for @tryAdjustingSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search criteria'**
  String get tryAdjustingSearchCriteria;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t made any payments yet'**
  String get noPaymentsYet;

  /// No description provided for @searchByTransactionOrCourse.
  ///
  /// In en, this message translates to:
  /// **'Search by transaction ID or course...'**
  String get searchByTransactionOrCourse;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @contactInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfoLabel;

  /// No description provided for @cancelPayment.
  ///
  /// In en, this message translates to:
  /// **'Cancel Payment'**
  String get cancelPayment;

  /// No description provided for @areYouSureCancelPayment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel payment {transactionId}? This action cannot be undone.'**
  String areYouSureCancelPayment(Object transactionId);

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @transactionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionIdLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @paymentMethodLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabelDetail;

  /// No description provided for @contactInfoLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactInfoLabelDetail;

  /// No description provided for @courseLabel.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get courseLabel;

  /// No description provided for @paymentDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDateLabel;

  /// No description provided for @adminApproval.
  ///
  /// In en, this message translates to:
  /// **'Admin Approval'**
  String get adminApproval;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved By'**
  String get approvedBy;

  /// No description provided for @approvedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved At'**
  String get approvedAt;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @initiatePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Initiate Payment'**
  String get initiatePaymentTitle;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount:'**
  String get totalAmount;

  /// No description provided for @discountApplied.
  ///
  /// In en, this message translates to:
  /// **'(20% Discount Applied)'**
  String get discountApplied;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @payUsingMtnMomo.
  ///
  /// In en, this message translates to:
  /// **'Pay using your MTN Mobile Money account'**
  String get payUsingMtnMomo;

  /// No description provided for @payUsingAirtelMoney.
  ///
  /// In en, this message translates to:
  /// **'Pay using your Airtel Money account'**
  String get payUsingAirtelMoney;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @phoneNumberOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Phone Number or Email'**
  String get phoneNumberOrEmail;

  /// No description provided for @enterContactInformation.
  ///
  /// In en, this message translates to:
  /// **'Enter your contact information'**
  String get enterContactInformation;

  /// No description provided for @pleaseEnterContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Please enter your contact information'**
  String get pleaseEnterContactInfo;

  /// No description provided for @pleaseEnterValidContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid contact information'**
  String get pleaseEnterValidContactInfo;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @needOtherPaymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Need Other Payment Options?'**
  String get needOtherPaymentOptions;

  /// No description provided for @contactForAlternativePayment.
  ///
  /// In en, this message translates to:
  /// **'Contact us for alternative payment methods including:'**
  String get contactForAlternativePayment;

  /// No description provided for @bankTransferOption.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransferOption;

  /// No description provided for @creditDebitCards.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Cards'**
  String get creditDebitCards;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash Payment'**
  String get cashPayment;

  /// No description provided for @otherMobileMoneyProviders.
  ///
  /// In en, this message translates to:
  /// **'Other Mobile Money Providers'**
  String get otherMobileMoneyProviders;

  /// No description provided for @contactNumbers.
  ///
  /// In en, this message translates to:
  /// **'Contact Numbers:'**
  String get contactNumbers;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get emailLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp:'**
  String get whatsappLabel;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'By initiating this payment, you agree to our terms and conditions. Your payment will be processed and you will receive confirmation once the payment is completed. Course access is time-bound as mentioned above.'**
  String get termsAndConditions;

  /// No description provided for @paymentInitiated.
  ///
  /// In en, this message translates to:
  /// **'Payment Initiated'**
  String get paymentInitiated;

  /// No description provided for @paymentInitiatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been initiated successfully.'**
  String get paymentInitiatedSuccess;

  /// No description provided for @accessPermissions.
  ///
  /// In en, this message translates to:
  /// **'Access Permissions'**
  String get accessPermissions;

  /// No description provided for @canAccessLiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Can Access Live Sessions'**
  String get canAccessLiveSessions;

  /// No description provided for @canAccessLiveSessionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow student to join live sessions'**
  String get canAccessLiveSessionsDescription;

  /// No description provided for @canAccessChapters.
  ///
  /// In en, this message translates to:
  /// **'Can Access Chapters & Materials'**
  String get canAccessChapters;

  /// No description provided for @canAccessChaptersDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow student to view course content'**
  String get canAccessChaptersDescription;

  /// No description provided for @noPermissionToAccessLiveSessions.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access live sessions. Please contact your administrator.'**
  String get noPermissionToAccessLiveSessions;

  /// No description provided for @noPermissionToAccessChapters.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access course materials. Please contact your administrator.'**
  String get noPermissionToAccessChapters;

  /// No description provided for @nextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next Steps:'**
  String get nextSteps;

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact:'**
  String get contactLabel;

  /// No description provided for @unknownCourse.
  ///
  /// In en, this message translates to:
  /// **'Unknown Course'**
  String get unknownCourse;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn together. Collaborate. Succeed.'**
  String get communityTagline;

  /// No description provided for @courseCommunity.
  ///
  /// In en, this message translates to:
  /// **'COURSE COMMUNITY'**
  String get courseCommunity;

  /// No description provided for @echCourseCommunity.
  ///
  /// In en, this message translates to:
  /// **'ECH Course Community'**
  String get echCourseCommunity;

  /// No description provided for @communitySectionHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get communitySectionHome;

  /// No description provided for @communitySectionStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get communitySectionStudents;

  /// No description provided for @communitySectionDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get communitySectionDiscussions;

  /// No description provided for @communitySectionChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get communitySectionChat;

  /// No description provided for @communitySectionGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get communitySectionGroups;

  /// No description provided for @communitySectionWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get communitySectionWork;

  /// No description provided for @communitySectionResources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get communitySectionResources;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @echStudent.
  ///
  /// In en, this message translates to:
  /// **'ECH Student'**
  String get echStudent;

  /// No description provided for @echSupport.
  ///
  /// In en, this message translates to:
  /// **'ECH Support'**
  String get echSupport;

  /// No description provided for @communityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the community'**
  String get communityLoadFailed;

  /// No description provided for @communityNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'You need to be enrolled in this course to join its community.'**
  String get communityNotEnrolled;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @noDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadline;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @studentsCount.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get studentsCount;

  /// No description provided for @studentSingular.
  ///
  /// In en, this message translates to:
  /// **'student'**
  String get studentSingular;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'active now'**
  String get activeNow;

  /// No description provided for @groupsCount.
  ///
  /// In en, this message translates to:
  /// **'groups'**
  String get groupsCount;

  /// No description provided for @groupSingular.
  ///
  /// In en, this message translates to:
  /// **'group'**
  String get groupSingular;

  /// No description provided for @findStudents.
  ///
  /// In en, this message translates to:
  /// **'Find\nstudents'**
  String get findStudents;

  /// No description provided for @createGroupAction.
  ///
  /// In en, this message translates to:
  /// **'Create\ngroup'**
  String get createGroupAction;

  /// No description provided for @askQuestionAction.
  ///
  /// In en, this message translates to:
  /// **'Ask a\nquestion'**
  String get askQuestionAction;

  /// No description provided for @courseChatAction.
  ///
  /// In en, this message translates to:
  /// **'Course\nchat'**
  String get courseChatAction;

  /// No description provided for @postNoticeAction.
  ///
  /// In en, this message translates to:
  /// **'Post\nnotice'**
  String get postNoticeAction;

  /// No description provided for @startPostAction.
  ///
  /// In en, this message translates to:
  /// **'Start\npost'**
  String get startPostAction;

  /// No description provided for @yourTeacher.
  ///
  /// In en, this message translates to:
  /// **'Your teacher'**
  String get yourTeacher;

  /// No description provided for @yourTeachers.
  ///
  /// In en, this message translates to:
  /// **'Your teachers'**
  String get yourTeachers;

  /// No description provided for @pinnedByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Pinned by your teacher'**
  String get pinnedByTeacher;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @studentsLearningNow.
  ///
  /// In en, this message translates to:
  /// **'Students learning now'**
  String get studentsLearningNow;

  /// No description provided for @enrolledActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{enrolled} enrolled · {active} active right now'**
  String enrolledActiveSummary(Object active, Object enrolled);

  /// No description provided for @nobodyStudyingNow.
  ///
  /// In en, this message translates to:
  /// **'Nobody else is studying right now — you are ahead of the class. Leave a question and classmates will find it later.'**
  String get nobodyStudyingNow;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get myGroups;

  /// No description provided for @workThroughCourseWithClassmates.
  ///
  /// In en, this message translates to:
  /// **'Work through the course with classmates'**
  String get workThroughCourseWithClassmates;

  /// No description provided for @activeGroupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active {label}'**
  String activeGroupsCount(Object count, Object label);

  /// No description provided for @notInGroupYet.
  ///
  /// In en, this message translates to:
  /// **'You are not in a study group yet'**
  String get notInGroupYet;

  /// No description provided for @groupsBenefit.
  ///
  /// In en, this message translates to:
  /// **'Groups give you a shared task list, a private chat and one place to submit group assignments.'**
  String get groupsBenefit;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @findOne.
  ///
  /// In en, this message translates to:
  /// **'Find one'**
  String get findOne;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @membersOf.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max} members'**
  String membersOf(Object count, Object max);

  /// No description provided for @openTasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open {label}'**
  String openTasksCount(Object count, Object label);

  /// No description provided for @taskSingular.
  ///
  /// In en, this message translates to:
  /// **'task'**
  String get taskSingular;

  /// No description provided for @tasksPlural.
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get tasksPlural;

  /// No description provided for @coursework.
  ///
  /// In en, this message translates to:
  /// **'Coursework'**
  String get coursework;

  /// No description provided for @myAssignments.
  ///
  /// In en, this message translates to:
  /// **'My assignments'**
  String get myAssignments;

  /// No description provided for @nothingWaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for review'**
  String get nothingWaitingReview;

  /// No description provided for @submissionsAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} submission(s) awaiting review'**
  String submissionsAwaitingReview(Object count);

  /// No description provided for @youAreUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You are up to date'**
  String get youAreUpToDate;

  /// No description provided for @openAssignmentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} open {label}'**
  String openAssignmentsCount(Object count, Object label);

  /// No description provided for @assignmentSingular.
  ///
  /// In en, this message translates to:
  /// **'assignment'**
  String get assignmentSingular;

  /// No description provided for @assignmentsPlural.
  ///
  /// In en, this message translates to:
  /// **'assignments'**
  String get assignmentsPlural;

  /// No description provided for @noCourseworkPublished.
  ///
  /// In en, this message translates to:
  /// **'No coursework published yet. Publish one from the Work tab.'**
  String get noCourseworkPublished;

  /// No description provided for @noAssignmentsDue.
  ///
  /// In en, this message translates to:
  /// **'No assignments are due right now.'**
  String get noAssignmentsDue;

  /// No description provided for @groupWork.
  ///
  /// In en, this message translates to:
  /// **'Group work'**
  String get groupWork;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @marksLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} marks'**
  String marksLabel(Object count);

  /// No description provided for @courseDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Course discussions'**
  String get courseDiscussions;

  /// No description provided for @threadsInCourse.
  ///
  /// In en, this message translates to:
  /// **'{count} threads in this course'**
  String threadsInCourse(Object count);

  /// No description provided for @noDiscussionsYet.
  ///
  /// In en, this message translates to:
  /// **'No discussions yet'**
  String get noDiscussionsYet;

  /// No description provided for @beFirstToAsk.
  ///
  /// In en, this message translates to:
  /// **'Be the first to ask something — a classmate or your teacher will pick it up.'**
  String get beFirstToAsk;

  /// No description provided for @startDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Start discussion'**
  String get startDiscussion;

  /// No description provided for @teacherAnswered.
  ///
  /// In en, this message translates to:
  /// **'Teacher answered'**
  String get teacherAnswered;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @nextStudySession.
  ///
  /// In en, this message translates to:
  /// **'Next study session'**
  String get nextStudySession;

  /// No description provided for @studySessionLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Study session live now'**
  String get studySessionLiveNow;

  /// No description provided for @joiningCount.
  ///
  /// In en, this message translates to:
  /// **'{count} joining'**
  String joiningCount(Object count);

  /// No description provided for @goingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} going'**
  String goingCount(Object count);

  /// No description provided for @inTheRoomTapToJoin.
  ///
  /// In en, this message translates to:
  /// **'{count} in the room · tap to join'**
  String inTheRoomTapToJoin(Object count);

  /// No description provided for @openFullCommunity.
  ///
  /// In en, this message translates to:
  /// **'Open the full community'**
  String get openFullCommunity;

  /// No description provided for @openFullCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Students · Discussions · Chat · Groups · Work · Resources'**
  String get openFullCommunitySubtitle;

  /// No description provided for @noCourseCommunitiesYet.
  ///
  /// In en, this message translates to:
  /// **'No course communities yet'**
  String get noCourseCommunitiesYet;

  /// No description provided for @communityHubStudentIntro.
  ///
  /// In en, this message translates to:
  /// **'Pick a course to meet the students learning it with you, join a study group, and get help.'**
  String get communityHubStudentIntro;

  /// No description provided for @communityHubTeacherIntro.
  ///
  /// In en, this message translates to:
  /// **'Post announcements, publish assignments, answer questions and grade group work — all inside the course your students already study in.'**
  String get communityHubTeacherIntro;

  /// No description provided for @everyCourseHasCommunity.
  ///
  /// In en, this message translates to:
  /// **'Every course you enrol in comes with its own community — classmates, study groups and discussions.'**
  String get everyCourseHasCommunity;

  /// No description provided for @noCoursesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No courses assigned to you'**
  String get noCoursesAssigned;

  /// No description provided for @noCoursesAssignedHint.
  ///
  /// In en, this message translates to:
  /// **'Once you are assigned to a course, its community appears here with your teacher tools.'**
  String get noCoursesAssignedHint;

  /// No description provided for @openCourseCommunity.
  ///
  /// In en, this message translates to:
  /// **'Open the course community'**
  String get openCourseCommunity;

  /// No description provided for @studentsActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'{students} students · {active} active'**
  String studentsActiveSummary(Object active, Object students);

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @timeMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesShort(Object minutes);

  /// No description provided for @timeHoursShort.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursShort(Object hours);

  /// No description provided for @timeDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysShort(Object days);

  /// No description provided for @timeWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'{weeks}w ago'**
  String timeWeeksShort(Object weeks);

  /// No description provided for @timeMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String timeMonthsShort(Object months);

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @dueTodayPassed.
  ///
  /// In en, this message translates to:
  /// **'Due today (passed)'**
  String get dueTodayPassed;

  /// No description provided for @overdueByDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days}d'**
  String overdueByDays(Object days);

  /// No description provided for @dueInHours.
  ///
  /// In en, this message translates to:
  /// **'Due in {hours}h'**
  String dueInHours(Object hours);

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String dueInDays(Object days);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(Object date);

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get openLink;

  /// No description provided for @linkBlockedByBrowser.
  ///
  /// In en, this message translates to:
  /// **'Your browser blocked the automatic redirect. Tap below to open it.'**
  String get linkBlockedByBrowser;

  /// No description provided for @linkLooksBroken.
  ///
  /// In en, this message translates to:
  /// **'That link looks broken'**
  String get linkLooksBroken;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @studyPartners.
  ///
  /// In en, this message translates to:
  /// **'Study partners'**
  String get studyPartners;

  /// No description provided for @searchClassmatesByName.
  ///
  /// In en, this message translates to:
  /// **'Search classmates by name'**
  String get searchClassmatesByName;

  /// No description provided for @searchClassmates.
  ///
  /// In en, this message translates to:
  /// **'Search classmates'**
  String get searchClassmates;

  /// No description provided for @activeNowFilter.
  ///
  /// In en, this message translates to:
  /// **'Active now'**
  String get activeNowFilter;

  /// No description provided for @teachersFilter.
  ///
  /// In en, this message translates to:
  /// **'Teachers'**
  String get teachersFilter;

  /// No description provided for @nobodyActiveRightNow.
  ///
  /// In en, this message translates to:
  /// **'Nobody is active right now'**
  String get nobodyActiveRightNow;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get noStudentsFound;

  /// No description provided for @checkBackLaterOrAsk.
  ///
  /// In en, this message translates to:
  /// **'Check back later, or leave a question so classmates find it when they come online.'**
  String get checkBackLaterOrAsk;

  /// No description provided for @tryDifferentName.
  ///
  /// In en, this message translates to:
  /// **'Try a different name or clear the filters.'**
  String get tryDifferentName;

  /// No description provided for @enrolledLabel.
  ///
  /// In en, this message translates to:
  /// **'enrolled'**
  String get enrolledLabel;

  /// No description provided for @teachersLabel.
  ///
  /// In en, this message translates to:
  /// **'teachers'**
  String get teachersLabel;

  /// No description provided for @youSuffix.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(Object name);

  /// No description provided for @messagePerson.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String messagePerson(Object name);

  /// No description provided for @lookingForStudyPartner.
  ///
  /// In en, this message translates to:
  /// **'Looking for a study partner'**
  String get lookingForStudyPartner;

  /// No description provided for @studentsLookingForPartners.
  ///
  /// In en, this message translates to:
  /// **'Students looking for partners'**
  String get studentsLookingForPartners;

  /// No description provided for @nobodyPublishedCard.
  ///
  /// In en, this message translates to:
  /// **'Nobody has published a card yet'**
  String get nobodyPublishedCard;

  /// No description provided for @classmatesWantToStudy.
  ///
  /// In en, this message translates to:
  /// **'{count} classmate(s) want to study together'**
  String classmatesWantToStudy(Object count);

  /// No description provided for @noStudyPartnersListed.
  ///
  /// In en, this message translates to:
  /// **'No study partners listed yet'**
  String get noStudyPartnersListed;

  /// No description provided for @publishYourCardHint.
  ///
  /// In en, this message translates to:
  /// **'Publish your own card above — classmates who join later will see it and can reach out.'**
  String get publishYourCardHint;

  /// No description provided for @youAreListedAsPartner.
  ///
  /// In en, this message translates to:
  /// **'You are listed as looking for a partner'**
  String get youAreListedAsPartner;

  /// No description provided for @letClassmatesKnow.
  ///
  /// In en, this message translates to:
  /// **'Let classmates know you want a study partner'**
  String get letClassmatesKnow;

  /// No description provided for @noGoalSet.
  ///
  /// In en, this message translates to:
  /// **'No goal set'**
  String get noGoalSet;

  /// No description provided for @partnerCardPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you want to work on and when you are free. Only people in this course can see it, and you can remove it at any time.'**
  String get partnerCardPrivacyHint;

  /// No description provided for @editMyCard.
  ///
  /// In en, this message translates to:
  /// **'Edit my card'**
  String get editMyCard;

  /// No description provided for @publishMyCard.
  ///
  /// In en, this message translates to:
  /// **'Publish my card'**
  String get publishMyCard;

  /// No description provided for @removedFromPartnerList.
  ///
  /// In en, this message translates to:
  /// **'Removed from the partner list'**
  String get removedFromPartnerList;

  /// No description provided for @findStudyPartner.
  ///
  /// In en, this message translates to:
  /// **'Find a study partner'**
  String get findStudyPartner;

  /// No description provided for @whatWorkingTowards.
  ///
  /// In en, this message translates to:
  /// **'What are you working towards?'**
  String get whatWorkingTowards;

  /// No description provided for @goalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Prepare for the August exam'**
  String get goalHint;

  /// No description provided for @topicsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Topics (comma separated)'**
  String get topicsCommaSeparated;

  /// No description provided for @whenAreYouFree.
  ///
  /// In en, this message translates to:
  /// **'When are you usually free?'**
  String get whenAreYouFree;

  /// No description provided for @anythingElseOptional.
  ///
  /// In en, this message translates to:
  /// **'Anything else (optional)'**
  String get anythingElseOptional;

  /// No description provided for @yourCardIsLive.
  ///
  /// In en, this message translates to:
  /// **'Your study partner card is live'**
  String get yourCardIsLive;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @availableColon.
  ///
  /// In en, this message translates to:
  /// **'Available: {slots}'**
  String availableColon(Object slots);

  /// No description provided for @slotMornings.
  ///
  /// In en, this message translates to:
  /// **'Mornings'**
  String get slotMornings;

  /// No description provided for @slotAfternoons.
  ///
  /// In en, this message translates to:
  /// **'Afternoons'**
  String get slotAfternoons;

  /// No description provided for @slotEvenings.
  ///
  /// In en, this message translates to:
  /// **'Evenings'**
  String get slotEvenings;

  /// No description provided for @slotWeekends.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get slotWeekends;

  /// No description provided for @slotFlexible.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get slotFlexible;

  /// No description provided for @couldNotLoadClassmates.
  ///
  /// In en, this message translates to:
  /// **'Could not load classmates.'**
  String get couldNotLoadClassmates;

  /// No description provided for @nobodyToMessageYet.
  ///
  /// In en, this message translates to:
  /// **'Nobody to message yet'**
  String get nobodyToMessageYet;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// No description provided for @studentProfile.
  ///
  /// In en, this message translates to:
  /// **'Student profile'**
  String get studentProfile;

  /// No description provided for @currentlyStudying.
  ///
  /// In en, this message translates to:
  /// **'Currently studying'**
  String get currentlyStudying;

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @percentThroughCourse.
  ///
  /// In en, this message translates to:
  /// **'{percent}% through the course'**
  String percentThroughCourse(Object percent);

  /// No description provided for @groupsStat.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsStat;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replies;

  /// No description provided for @studyGroupsInCourse.
  ///
  /// In en, this message translates to:
  /// **'Study groups in this course'**
  String get studyGroupsInCourse;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(Object count);

  /// No description provided for @messageYourTeacher.
  ///
  /// In en, this message translates to:
  /// **'Message your teacher'**
  String get messageYourTeacher;

  /// No description provided for @teacherDiscussionHint.
  ///
  /// In en, this message translates to:
  /// **'For anything the whole class would benefit from, the Discussions tab is a better place than a private message.'**
  String get teacherDiscussionHint;

  /// No description provided for @inviteToGroupHint.
  ///
  /// In en, this message translates to:
  /// **'You can also invite {name} to a study group from the Groups tab.'**
  String inviteToGroupHint(Object name);

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadCount(Object count);

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get newMessage;

  /// No description provided for @publicFilter.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicFilter;

  /// No description provided for @directFilter.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get directFilter;

  /// No description provided for @privateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateLabel;

  /// No description provided for @groupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// No description provided for @everyoneInThisCourse.
  ///
  /// In en, this message translates to:
  /// **'Everyone in this course'**
  String get everyoneInThisCourse;

  /// No description provided for @noDirectChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No direct chats yet'**
  String get noDirectChatsYet;

  /// No description provided for @notInGroupYetShort.
  ///
  /// In en, this message translates to:
  /// **'You are not in a group yet'**
  String get notInGroupYetShort;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @directChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Message a classmate or your teacher privately — those chats appear here.'**
  String get directChatsHint;

  /// No description provided for @groupChatsHint.
  ///
  /// In en, this message translates to:
  /// **'Join or create a study group and its chat shows up here.'**
  String get groupChatsHint;

  /// No description provided for @startWithCourseChat.
  ///
  /// In en, this message translates to:
  /// **'Start with the course chat — everyone studying this course can see it.'**
  String get startWithCourseChat;

  /// No description provided for @sayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello'**
  String get sayHello;

  /// No description provided for @sayHelloToClass.
  ///
  /// In en, this message translates to:
  /// **'Say something to the whole class'**
  String get sayHelloToClass;

  /// No description provided for @noMessagesInGroup.
  ///
  /// In en, this message translates to:
  /// **'No messages in this group yet'**
  String get noMessagesInGroup;

  /// No description provided for @attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get attachment;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @youPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String youPrefix(Object text);

  /// No description provided for @startTheConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get startTheConversation;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get writeAMessage;

  /// No description provided for @writeAReply.
  ///
  /// In en, this message translates to:
  /// **'Write a reply…'**
  String get writeAReply;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @messageRemoved.
  ///
  /// In en, this message translates to:
  /// **'This message was removed'**
  String get messageRemoved;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(Object name);

  /// No description provided for @replying.
  ///
  /// In en, this message translates to:
  /// **'Replying'**
  String get replying;

  /// No description provided for @messageCouldNotBeSent.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent'**
  String get messageCouldNotBeSent;

  /// No description provided for @groupChatEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'This is your group’s private chat. Plan who does what, and share what you find.'**
  String get groupChatEmptyHint;

  /// No description provided for @courseChatEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Ask about a lesson, share what clicked for you, or offer to help someone.'**
  String get courseChatEmptyHint;

  /// No description provided for @searchDiscussions.
  ///
  /// In en, this message translates to:
  /// **'Search discussions'**
  String get searchDiscussions;

  /// No description provided for @discussionsFilter.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get discussionsFilter;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @unanswered.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get unanswered;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get getHelp;

  /// No description provided for @nothingMatchesSearch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that search'**
  String get nothingMatchesSearch;

  /// No description provided for @noPostsHereYet.
  ///
  /// In en, this message translates to:
  /// **'No posts here yet'**
  String get noPostsHereYet;

  /// No description provided for @tryDifferentWords.
  ///
  /// In en, this message translates to:
  /// **'Try different words, or start the discussion yourself.'**
  String get tryDifferentWords;

  /// No description provided for @askFirstQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask the first question — your classmates and teacher will see it in their community feed.'**
  String get askFirstQuestion;

  /// No description provided for @startAPost.
  ///
  /// In en, this message translates to:
  /// **'Start a post'**
  String get startAPost;

  /// No description provided for @dashLiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Live Sessions'**
  String get dashLiveSessions;

  /// No description provided for @dashContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get dashContinueLearning;

  /// No description provided for @dashJoinParticipate.
  ///
  /// In en, this message translates to:
  /// **'Join & participate'**
  String get dashJoinParticipate;

  /// No description provided for @dashLearnTogether.
  ///
  /// In en, this message translates to:
  /// **'Learn together'**
  String get dashLearnTogether;

  /// No description provided for @dashYourAchievements.
  ///
  /// In en, this message translates to:
  /// **'Your achievements'**
  String get dashYourAchievements;

  /// No description provided for @dashQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashQuickActions;

  /// No description provided for @dashQuickActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Jump straight to what you need'**
  String get dashQuickActionsSubtitle;

  /// No description provided for @dashPickUpWhereLeft.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get dashPickUpWhereLeft;

  /// No description provided for @dashReadyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get dashReadyToStart;

  /// No description provided for @drawerTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn • Grow • Build Your Future'**
  String get drawerTagline;

  /// No description provided for @drawerCareerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Career Guidance'**
  String get drawerCareerGuidance;

  /// No description provided for @drawerGetSupport.
  ///
  /// In en, this message translates to:
  /// **'Get support'**
  String get drawerGetSupport;

  /// No description provided for @drawerJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get drawerJobs;

  /// No description provided for @drawerFindOpportunities.
  ///
  /// In en, this message translates to:
  /// **'Find opportunities'**
  String get drawerFindOpportunities;

  /// No description provided for @drawerSectionProfileProgress.
  ///
  /// In en, this message translates to:
  /// **'Profile & Progress'**
  String get drawerSectionProfileProgress;

  /// No description provided for @drawerMyProgress.
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get drawerMyProgress;

  /// No description provided for @drawerTrackGrowth.
  ///
  /// In en, this message translates to:
  /// **'Track your growth'**
  String get drawerTrackGrowth;

  /// No description provided for @drawerSectionCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get drawerSectionCommunication;

  /// No description provided for @drawerStayConnected.
  ///
  /// In en, this message translates to:
  /// **'Stay connected'**
  String get drawerStayConnected;

  /// No description provided for @drawerNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get drawerNeedHelp;

  /// No description provided for @drawerContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support or get assistance'**
  String get drawerContactSupport;

  /// No description provided for @drawerAppPreferences.
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get drawerAppPreferences;

  /// No description provided for @drawerBetterSkills.
  ///
  /// In en, this message translates to:
  /// **'Better Skills'**
  String get drawerBetterSkills;

  /// No description provided for @drawerBrighterFuture.
  ///
  /// In en, this message translates to:
  /// **'Brighter Future'**
  String get drawerBrighterFuture;

  /// No description provided for @drawerSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get drawerSoon;

  /// No description provided for @drawerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon — we\'re building this for you.'**
  String get drawerComingSoon;

  /// No description provided for @drawerAccessAccount.
  ///
  /// In en, this message translates to:
  /// **'Access your account'**
  String get drawerAccessAccount;

  /// No description provided for @drawerCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create a free account'**
  String get drawerCreateAccount;

  /// No description provided for @drawerSectionInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get drawerSectionInsights;

  /// No description provided for @drawerPlatformInsights.
  ///
  /// In en, this message translates to:
  /// **'Platform insights'**
  String get drawerPlatformInsights;

  /// No description provided for @drawerPushReport.
  ///
  /// In en, this message translates to:
  /// **'Push Report'**
  String get drawerPushReport;

  /// No description provided for @drawerDeliveryStats.
  ///
  /// In en, this message translates to:
  /// **'Delivery statistics'**
  String get drawerDeliveryStats;

  /// No description provided for @drawerCreateEditCourses.
  ///
  /// In en, this message translates to:
  /// **'Create & edit courses'**
  String get drawerCreateEditCourses;

  /// No description provided for @drawerLearnersAccess.
  ///
  /// In en, this message translates to:
  /// **'Learners & access'**
  String get drawerLearnersAccess;

  /// No description provided for @drawerRecordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get drawerRecordings;

  /// No description provided for @drawerSessionVideos.
  ///
  /// In en, this message translates to:
  /// **'Session videos'**
  String get drawerSessionVideos;

  /// No description provided for @drawerApproveTrack.
  ///
  /// In en, this message translates to:
  /// **'Approve & track'**
  String get drawerApproveTrack;

  /// No description provided for @drawerSendAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Send announcements'**
  String get drawerSendAnnouncements;

  /// No description provided for @drawerExploreCatalog.
  ///
  /// In en, this message translates to:
  /// **'Explore the catalog'**
  String get drawerExploreCatalog;

  /// No description provided for @drawerBooksResources.
  ///
  /// In en, this message translates to:
  /// **'Books & resources'**
  String get drawerBooksResources;

  /// No description provided for @drawerYourResults.
  ///
  /// In en, this message translates to:
  /// **'Your results'**
  String get drawerYourResults;

  /// No description provided for @drawerOfflineLearning.
  ///
  /// In en, this message translates to:
  /// **'Learn offline'**
  String get drawerOfflineLearning;

  /// No description provided for @drawerBillingHistory.
  ///
  /// In en, this message translates to:
  /// **'Billing history'**
  String get drawerBillingHistory;

  /// No description provided for @drawerAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get drawerAdministrator;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'rw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'rw':
      return AppLocalizationsRw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
