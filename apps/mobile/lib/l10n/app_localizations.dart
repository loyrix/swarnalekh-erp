import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

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
    Locale('gu'),
    Locale('hi'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'SwarnaLekh'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get navMortgage;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @pageShopProfile.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile'**
  String get pageShopProfile;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @menuShopProfile.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile'**
  String get menuShopProfile;

  /// No description provided for @menuLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get menuLogout;

  /// No description provided for @menuLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get menuLanguage;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get languageGujarati;

  /// No description provided for @placeholderComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get placeholderComingSoon;

  /// No description provided for @placeholderModuleInProgress.
  ///
  /// In en, this message translates to:
  /// **'This module is being built'**
  String get placeholderModuleInProgress;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your jewellery business'**
  String get loginSubtitle;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join SwarnaLekh to manage your jewellery business'**
  String get signupSubtitle;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get authEmailAddress;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authConfirmPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authDontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authDontHaveAccount;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authSecureConnection.
  ///
  /// In en, this message translates to:
  /// **'Secure, encrypted connection'**
  String get authSecureConnection;

  /// No description provided for @validationValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationValidEmail;

  /// No description provided for @validationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordMin;

  /// No description provided for @validationPasswordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsNoMatch;

  /// No description provided for @registrationSetupShop.
  ///
  /// In en, this message translates to:
  /// **'Setup Your Shop'**
  String get registrationSetupShop;

  /// No description provided for @registrationAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there!'**
  String get registrationAlmostThere;

  /// No description provided for @registrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your business to set up your account.'**
  String get registrationSubtitle;

  /// No description provided for @registrationShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name *'**
  String get registrationShopName;

  /// No description provided for @registrationOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name *'**
  String get registrationOwnerName;

  /// No description provided for @registrationCityOptional.
  ///
  /// In en, this message translates to:
  /// **'City (Optional)'**
  String get registrationCityOptional;

  /// No description provided for @registrationCompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get registrationCompleteSetup;

  /// No description provided for @registrationFailedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Registration failed:'**
  String get registrationFailedPrefix;

  /// No description provided for @inventoryOverview.
  ///
  /// In en, this message translates to:
  /// **'Inventory Overview'**
  String get inventoryOverview;

  /// No description provided for @inventoryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get inventoryAddItem;

  /// No description provided for @inventoryInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inventoryInStock;

  /// No description provided for @inventorySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get inventorySold;

  /// No description provided for @inventoryStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock Value'**
  String get inventoryStockValue;

  /// No description provided for @inventoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryAll;

  /// No description provided for @inventoryRatesPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rates:'**
  String get inventoryRatesPrefix;

  /// No description provided for @inventoryItemsSuffix.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get inventoryItemsSuffix;

  /// No description provided for @billingInvoiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Invoice History'**
  String get billingInvoiceHistory;

  /// No description provided for @billingCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get billingCreateInvoice;

  /// No description provided for @billingCreateSalesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create sales bills and review recent invoices from one place.'**
  String get billingCreateSalesSubtitle;

  /// No description provided for @ratesTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Rates'**
  String get ratesTitle;

  /// No description provided for @ratesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set today\'s metal rates to be used across all billing and inventory.'**
  String get ratesSubtitle;

  /// No description provided for @shopProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your shop details, contact information, and billing identity.'**
  String get shopProfileSubtitle;

  /// No description provided for @shopProfileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get shopProfileSaveChanges;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @customerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get customerAdd;

  /// No description provided for @customerWalkIn.
  ///
  /// In en, this message translates to:
  /// **'Walk-in customer'**
  String get customerWalkIn;

  /// No description provided for @billingSelectInventoryItems.
  ///
  /// In en, this message translates to:
  /// **'Select Inventory Items'**
  String get billingSelectInventoryItems;

  /// No description provided for @shopProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Profile'**
  String get shopProfileTitle;

  /// No description provided for @ratesGoldPerGram.
  ///
  /// In en, this message translates to:
  /// **'Gold Rates (per gram)'**
  String get ratesGoldPerGram;

  /// No description provided for @ratesSilverPerGram.
  ///
  /// In en, this message translates to:
  /// **'Silver Rate (per gram)'**
  String get ratesSilverPerGram;

  /// No description provided for @ratesFineSilver.
  ///
  /// In en, this message translates to:
  /// **'Fine Silver'**
  String get ratesFineSilver;

  /// No description provided for @ratesSaveRates.
  ///
  /// In en, this message translates to:
  /// **'Save Rates'**
  String get ratesSaveRates;

  /// No description provided for @ratesSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get ratesSaving;

  /// No description provided for @ratesGold22.
  ///
  /// In en, this message translates to:
  /// **'Gold 22K'**
  String get ratesGold22;

  /// No description provided for @ratesGold18.
  ///
  /// In en, this message translates to:
  /// **'Gold 18K'**
  String get ratesGold18;

  /// No description provided for @ratesSelectedDate.
  ///
  /// In en, this message translates to:
  /// **'Selected Date'**
  String get ratesSelectedDate;

  /// No description provided for @ratesAvailable.
  ///
  /// In en, this message translates to:
  /// **'rates available'**
  String get ratesAvailable;

  /// No description provided for @ratesMissing.
  ///
  /// In en, this message translates to:
  /// **'rates missing'**
  String get ratesMissing;

  /// No description provided for @ratesLatestAvailable.
  ///
  /// In en, this message translates to:
  /// **'Latest Available'**
  String get ratesLatestAvailable;

  /// No description provided for @ratesNoRatesYet.
  ///
  /// In en, this message translates to:
  /// **'No rates yet'**
  String get ratesNoRatesYet;

  /// No description provided for @ratesRecentSnapshots.
  ///
  /// In en, this message translates to:
  /// **'{count} day snapshots in recent history'**
  String ratesRecentSnapshots(int count);

  /// No description provided for @errorFailedLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get errorFailedLoadCustomers;

  /// No description provided for @errorFailedSaveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to save customer'**
  String get errorFailedSaveCustomer;

  /// No description provided for @customersSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone...'**
  String get customersSearchHint;

  /// No description provided for @customerNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get customerNoPhone;

  /// No description provided for @customerVisits.
  ///
  /// In en, this message translates to:
  /// **'visits'**
  String get customerVisits;

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Name *'**
  String get customerNameLabel;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerPhoneLabel;

  /// No description provided for @customerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customerEmailLabel;

  /// No description provided for @customerCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get customerCityLabel;

  /// No description provided for @customerPreferredKaratLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Karat'**
  String get customerPreferredKaratLabel;

  /// No description provided for @validationCustomerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name is required'**
  String get validationCustomerNameRequired;

  /// No description provided for @commonNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get commonNotes;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @errorFailedLoadRates.
  ///
  /// In en, this message translates to:
  /// **'Failed to load rates'**
  String get errorFailedLoadRates;

  /// No description provided for @errorEnterValidRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter at least one valid rate'**
  String get errorEnterValidRate;

  /// No description provided for @successRatesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rates updated successfully!'**
  String get successRatesUpdated;

  /// No description provided for @errorFailedSaveRates.
  ///
  /// In en, this message translates to:
  /// **'Failed to save rates'**
  String get errorFailedSaveRates;

  /// No description provided for @errorFailedLoadInvoices.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoices'**
  String get errorFailedLoadInvoices;

  /// No description provided for @billingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by invoice number or customer...'**
  String get billingSearchHint;

  /// No description provided for @billingInvoiceFallback.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get billingInvoiceFallback;

  /// No description provided for @billingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get billingStatusPending;

  /// No description provided for @billingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get billingStatusCompleted;

  /// No description provided for @billingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get billingTotal;

  /// No description provided for @billingPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billingPaid;

  /// No description provided for @billingBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get billingBalance;

  /// No description provided for @billingItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get billingItems;

  /// No description provided for @errorFailedLoadBillingData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load billing data'**
  String get errorFailedLoadBillingData;

  /// No description provided for @errorSelectInventoryItem.
  ///
  /// In en, this message translates to:
  /// **'Select at least one inventory item'**
  String get errorSelectInventoryItem;

  /// No description provided for @errorFailedCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to create invoice'**
  String get errorFailedCreateInvoice;

  /// No description provided for @billingCustomerOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer (optional)'**
  String get billingCustomerOptional;

  /// No description provided for @billingCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get billingCustomerFallback;

  /// No description provided for @billingItemFallback.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get billingItemFallback;

  /// No description provided for @billingNoTag.
  ///
  /// In en, this message translates to:
  /// **'No tag'**
  String get billingNoTag;

  /// No description provided for @billingBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get billingBulk;

  /// No description provided for @billingUnique.
  ///
  /// In en, this message translates to:
  /// **'Unique'**
  String get billingUnique;

  /// No description provided for @billingQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get billingQty;

  /// No description provided for @billingSelectedUnits.
  ///
  /// In en, this message translates to:
  /// **'Selected Units'**
  String get billingSelectedUnits;

  /// No description provided for @billingEstimatedSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated Subtotal'**
  String get billingEstimatedSubtotal;

  /// No description provided for @billingDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get billingDiscountAmount;

  /// No description provided for @billingAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get billingAmountPaid;

  /// No description provided for @billingPaymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get billingPaymentMode;

  /// No description provided for @billingPaymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get billingPaymentCash;

  /// No description provided for @billingPaymentUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get billingPaymentUpi;

  /// No description provided for @billingPaymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get billingPaymentCard;

  /// No description provided for @billingRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure today\'s rates are set for the selected items before creating the invoice.'**
  String get billingRatesHint;

  /// No description provided for @errorFailedLoadShopProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shop profile'**
  String get errorFailedLoadShopProfile;

  /// No description provided for @successShopProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Shop profile updated'**
  String get successShopProfileUpdated;

  /// No description provided for @errorFailedUpdateShopProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update shop profile'**
  String get errorFailedUpdateShopProfile;

  /// No description provided for @shopProfileBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get shopProfileBusinessDetails;

  /// No description provided for @shopProfileTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get shopProfileTeam;

  /// No description provided for @shopProfileNoContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get shopProfileNoContactInfo;

  /// No description provided for @shopProfileFieldShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name *'**
  String get shopProfileFieldShopName;

  /// No description provided for @shopProfileFieldOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name *'**
  String get shopProfileFieldOwnerName;

  /// No description provided for @shopProfileFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get shopProfileFieldEmail;

  /// No description provided for @shopProfileFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get shopProfileFieldPhone;

  /// No description provided for @shopProfileFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get shopProfileFieldAddress;

  /// No description provided for @shopProfileFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get shopProfileFieldCity;

  /// No description provided for @shopProfileFieldState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get shopProfileFieldState;

  /// No description provided for @shopProfileFieldPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get shopProfileFieldPincode;

  /// No description provided for @shopProfileFieldGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get shopProfileFieldGstin;

  /// No description provided for @shopProfileFieldPan.
  ///
  /// In en, this message translates to:
  /// **'PAN'**
  String get shopProfileFieldPan;

  /// No description provided for @validationShopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop name is required'**
  String get validationShopNameRequired;

  /// No description provided for @validationOwnerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Owner name is required'**
  String get validationOwnerNameRequired;

  /// No description provided for @dashboardGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get dashboardGoodMorning;

  /// No description provided for @dashboardGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get dashboardGoodAfternoon;

  /// No description provided for @dashboardGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get dashboardGoodEvening;

  /// No description provided for @dashboardOwnerFallback.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get dashboardOwnerFallback;

  /// No description provided for @dashboardShopFallback.
  ///
  /// In en, this message translates to:
  /// **'Your Jewellery Shop'**
  String get dashboardShopFallback;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardNewBill.
  ///
  /// In en, this message translates to:
  /// **'New Bill'**
  String get dashboardNewBill;

  /// No description provided for @dashboardCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get dashboardCreateInvoice;

  /// No description provided for @dashboardAddMortgage.
  ///
  /// In en, this message translates to:
  /// **'Add Mortgage'**
  String get dashboardAddMortgage;

  /// No description provided for @dashboardSearchProduct.
  ///
  /// In en, this message translates to:
  /// **'Search Product'**
  String get dashboardSearchProduct;

  /// No description provided for @dashboardSearchCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search Customer'**
  String get dashboardSearchCustomer;

  /// No description provided for @dashboardNewContact.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get dashboardNewContact;

  /// No description provided for @dashboardSetRates.
  ///
  /// In en, this message translates to:
  /// **'Set Rates'**
  String get dashboardSetRates;

  /// No description provided for @dashboardTodaysPrices.
  ///
  /// In en, this message translates to:
  /// **'Today\'s prices'**
  String get dashboardTodaysPrices;

  /// No description provided for @dashboardItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'items available'**
  String get dashboardItemsAvailable;

  /// No description provided for @dashboardTotalRegistered.
  ///
  /// In en, this message translates to:
  /// **'total registered'**
  String get dashboardTotalRegistered;

  /// No description provided for @dashboardItemsSold.
  ///
  /// In en, this message translates to:
  /// **'items sold'**
  String get dashboardItemsSold;

  /// No description provided for @dashboardTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get dashboardTotalItems;

  /// No description provided for @dashboardInCatalog.
  ///
  /// In en, this message translates to:
  /// **'in catalog'**
  String get dashboardInCatalog;

  /// No description provided for @dashboardTodaysRates.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Rates'**
  String get dashboardTodaysRates;

  /// No description provided for @dashboardRatesMissingHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s rates haven\'t been set yet. Tap Update to set them now.'**
  String get dashboardRatesMissingHint;

  /// No description provided for @dashboardRecentCustomers.
  ///
  /// In en, this message translates to:
  /// **'Recent Customers'**
  String get dashboardRecentCustomers;

  /// No description provided for @dashboardNoCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get dashboardNoCustomersYet;

  /// No description provided for @dashboardAddFirstCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add First Customer'**
  String get dashboardAddFirstCustomer;

  /// No description provided for @errorFailedLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard data'**
  String get errorFailedLoadDashboard;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get commonNotSet;

  /// No description provided for @ratesGold24.
  ///
  /// In en, this message translates to:
  /// **'Gold 24K'**
  String get ratesGold24;

  /// No description provided for @errorFailedLoadInventory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inventory'**
  String get errorFailedLoadInventory;

  /// No description provided for @inventoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Inventory Item'**
  String get inventoryDeleteTitle;

  /// No description provided for @inventoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {itemName} from inventory?'**
  String inventoryDeleteConfirm(String itemName);

  /// No description provided for @inventoryThisItem.
  ///
  /// In en, this message translates to:
  /// **'this item'**
  String get inventoryThisItem;

  /// No description provided for @inventoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Inventory item deleted'**
  String get inventoryDeleted;

  /// No description provided for @errorFailedDeleteInventory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete inventory item'**
  String get errorFailedDeleteInventory;

  /// No description provided for @inventoryMetalGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get inventoryMetalGold;

  /// No description provided for @inventoryMetalSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get inventoryMetalSilver;

  /// No description provided for @inventoryMetalPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get inventoryMetalPlatinum;

  /// No description provided for @inventoryMetalOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get inventoryMetalOther;

  /// No description provided for @inventoryOnApproval.
  ///
  /// In en, this message translates to:
  /// **'On Approval'**
  String get inventoryOnApproval;

  /// No description provided for @inventoryReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get inventoryReserved;

  /// No description provided for @inventoryStockTypeBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get inventoryStockTypeBulk;

  /// No description provided for @inventoryStockTypeUnique.
  ///
  /// In en, this message translates to:
  /// **'Unique'**
  String get inventoryStockTypeUnique;

  /// No description provided for @inventoryColumnTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get inventoryColumnTag;

  /// No description provided for @inventoryColumnItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get inventoryColumnItem;

  /// No description provided for @inventoryColumnStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get inventoryColumnStock;

  /// No description provided for @inventoryColumnQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get inventoryColumnQty;

  /// No description provided for @inventoryColumnMetal.
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get inventoryColumnMetal;

  /// No description provided for @inventoryColumnKarat.
  ///
  /// In en, this message translates to:
  /// **'Karat'**
  String get inventoryColumnKarat;

  /// No description provided for @inventoryColumnGrossPerPiece.
  ///
  /// In en, this message translates to:
  /// **'Gross/Pc'**
  String get inventoryColumnGrossPerPiece;

  /// No description provided for @inventoryColumnNetPerPiece.
  ///
  /// In en, this message translates to:
  /// **'Net/Pc'**
  String get inventoryColumnNetPerPiece;

  /// No description provided for @inventoryColumnEstimatedPerPiece.
  ///
  /// In en, this message translates to:
  /// **'Est./Pc'**
  String get inventoryColumnEstimatedPerPiece;

  /// No description provided for @inventoryColumnTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get inventoryColumnTotalValue;

  /// No description provided for @inventoryColumnMaking.
  ///
  /// In en, this message translates to:
  /// **'Making'**
  String get inventoryColumnMaking;

  /// No description provided for @inventoryColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryColumnStatus;

  /// No description provided for @inventoryColumnLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get inventoryColumnLocation;

  /// No description provided for @inventoryColumnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get inventoryColumnActions;

  /// No description provided for @inventoryUnnamedItem.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Item'**
  String get inventoryUnnamedItem;

  /// No description provided for @inventoryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get inventoryEditItem;

  /// No description provided for @inventoryDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get inventoryDeleteItem;

  /// No description provided for @inventoryMakingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Making'**
  String get inventoryMakingPrefix;

  /// No description provided for @validationWeightGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Gross and net weight must be greater than zero'**
  String get validationWeightGreaterThanZero;

  /// No description provided for @validationMilligramsRange.
  ///
  /// In en, this message translates to:
  /// **'Milligrams must be between 0 and 999'**
  String get validationMilligramsRange;

  /// No description provided for @validationNetWeightGreater.
  ///
  /// In en, this message translates to:
  /// **'Net weight cannot be greater than gross weight'**
  String get validationNetWeightGreater;

  /// No description provided for @errorFailedSaveInventory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save inventory item'**
  String get errorFailedSaveInventory;

  /// No description provided for @inventoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Inventory Item'**
  String get inventoryEditTitle;

  /// No description provided for @inventoryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory Item'**
  String get inventoryAddTitle;

  /// No description provided for @inventoryFieldItemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name *'**
  String get inventoryFieldItemName;

  /// No description provided for @inventoryFieldTagNumber.
  ///
  /// In en, this message translates to:
  /// **'Tag Number'**
  String get inventoryFieldTagNumber;

  /// No description provided for @inventoryFieldStockType.
  ///
  /// In en, this message translates to:
  /// **'Stock Type'**
  String get inventoryFieldStockType;

  /// No description provided for @inventoryFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity *'**
  String get inventoryFieldQuantity;

  /// No description provided for @inventoryFieldMetalType.
  ///
  /// In en, this message translates to:
  /// **'Metal Type *'**
  String get inventoryFieldMetalType;

  /// No description provided for @inventoryFieldKarat.
  ///
  /// In en, this message translates to:
  /// **'Karat'**
  String get inventoryFieldKarat;

  /// No description provided for @inventoryFieldGrossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight *'**
  String get inventoryFieldGrossWeight;

  /// No description provided for @inventoryFieldNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight *'**
  String get inventoryFieldNetWeight;

  /// No description provided for @inventoryFieldMakingMode.
  ///
  /// In en, this message translates to:
  /// **'Making Mode'**
  String get inventoryFieldMakingMode;

  /// No description provided for @inventoryFixedMaking.
  ///
  /// In en, this message translates to:
  /// **'Fixed Making'**
  String get inventoryFixedMaking;

  /// No description provided for @inventoryMakingPercentage.
  ///
  /// In en, this message translates to:
  /// **'Making Percentage'**
  String get inventoryMakingPercentage;

  /// No description provided for @inventoryMakingPerGram.
  ///
  /// In en, this message translates to:
  /// **'Making Charges / Gram'**
  String get inventoryMakingPerGram;

  /// No description provided for @inventoryGrams.
  ///
  /// In en, this message translates to:
  /// **'Grams'**
  String get inventoryGrams;

  /// No description provided for @inventoryMilligrams.
  ///
  /// In en, this message translates to:
  /// **'Milligrams'**
  String get inventoryMilligrams;

  /// No description provided for @inventoryMakingModePerGram.
  ///
  /// In en, this message translates to:
  /// **'Per Gram'**
  String get inventoryMakingModePerGram;

  /// No description provided for @inventoryMakingModeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get inventoryMakingModeFixed;

  /// No description provided for @inventoryMakingModePercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get inventoryMakingModePercentage;

  /// No description provided for @validationItemNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Item name is required'**
  String get validationItemNameRequired;

  /// No description provided for @validationQuantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get validationQuantityRequired;

  /// No description provided for @validationValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get validationValidNumber;

  /// No description provided for @validationWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid whole number'**
  String get validationWholeNumber;

  /// No description provided for @validationQuantityMinOne.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be at least 1'**
  String get validationQuantityMinOne;

  /// No description provided for @otpNotActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Not Active'**
  String get otpNotActiveTitle;

  /// No description provided for @otpNotActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Phone OTP is currently disabled for the MVP. Use email/password login and signup for now.'**
  String get otpNotActiveMessage;

  /// No description provided for @otpNoPhoneProvided.
  ///
  /// In en, this message translates to:
  /// **'No phone number was provided.'**
  String get otpNoPhoneProvided;

  /// No description provided for @otpLegacyPhone.
  ///
  /// In en, this message translates to:
  /// **'Legacy phone: {phone}'**
  String otpLegacyPhone(String phone);

  /// No description provided for @otpBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get otpBackToLogin;
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
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
