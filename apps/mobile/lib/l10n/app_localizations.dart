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

  /// No description provided for @billingBillTable.
  ///
  /// In en, this message translates to:
  /// **'Bill Table'**
  String get billingBillTable;

  /// No description provided for @billingProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get billingProduct;

  /// No description provided for @billingWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get billingWeight;

  /// No description provided for @billingPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get billingPrice;

  /// No description provided for @billingCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get billingCustomerDetails;

  /// No description provided for @billingSavedCustomer.
  ///
  /// In en, this message translates to:
  /// **'Saved Customer'**
  String get billingSavedCustomer;

  /// No description provided for @billingCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get billingCustomerName;

  /// No description provided for @billingMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get billingMobileNumber;

  /// No description provided for @billingSearchInventory.
  ///
  /// In en, this message translates to:
  /// **'Search Inventory'**
  String get billingSearchInventory;

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

  /// No description provided for @billingPaymentDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Debit Card'**
  String get billingPaymentDebitCard;

  /// No description provided for @billingPaymentCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get billingPaymentCreditCard;

  /// No description provided for @billingPaymentBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get billingPaymentBankTransfer;

  /// No description provided for @billingProductValue.
  ///
  /// In en, this message translates to:
  /// **'Product Value'**
  String get billingProductValue;

  /// No description provided for @billingMakingCharges.
  ///
  /// In en, this message translates to:
  /// **'Making Charges'**
  String get billingMakingCharges;

  /// No description provided for @billingGst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get billingGst;

  /// No description provided for @billingFinalTotal.
  ///
  /// In en, this message translates to:
  /// **'Final Total'**
  String get billingFinalTotal;

  /// No description provided for @billingRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Products with a saved selling price use that price. Items without selling price need current rates before billing.'**
  String get billingRatesHint;

  /// No description provided for @billingSectionDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get billingSectionDashboard;

  /// No description provided for @billingSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'Invoice History'**
  String get billingSectionHistory;

  /// No description provided for @billingTodayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get billingTodayRevenue;

  /// No description provided for @billingMonthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get billingMonthlyRevenue;

  /// No description provided for @billingTotalBills.
  ///
  /// In en, this message translates to:
  /// **'Total Bills'**
  String get billingTotalBills;

  /// No description provided for @billingAverageBill.
  ///
  /// In en, this message translates to:
  /// **'Average Bill'**
  String get billingAverageBill;

  /// No description provided for @billingTopSellingProducts.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Products'**
  String get billingTopSellingProducts;

  /// No description provided for @billingFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get billingFromDate;

  /// No description provided for @billingToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get billingToDate;

  /// No description provided for @billingDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get billingDateHint;

  /// No description provided for @billingClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get billingClearFilters;

  /// No description provided for @billingRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh invoices'**
  String get billingRefresh;

  /// No description provided for @billingViewInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'View invoice details'**
  String get billingViewInvoiceDetails;

  /// No description provided for @billingReprintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Reprint invoice'**
  String get billingReprintInvoice;

  /// No description provided for @billingDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get billingDownloadPdf;

  /// No description provided for @billingShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get billingShareWhatsApp;

  /// No description provided for @billingInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get billingInvoiceDetails;

  /// No description provided for @billingInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice No'**
  String get billingInvoiceNumber;

  /// No description provided for @billingInvoiceDate.
  ///
  /// In en, this message translates to:
  /// **'Invoice Date'**
  String get billingInvoiceDate;

  /// No description provided for @billingPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get billingPaymentMethod;

  /// No description provided for @billingMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get billingMobile;

  /// No description provided for @billingGstin.
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get billingGstin;

  /// No description provided for @billingPurity.
  ///
  /// In en, this message translates to:
  /// **'Purity'**
  String get billingPurity;

  /// No description provided for @billingGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get billingGross;

  /// No description provided for @billingNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get billingNet;

  /// No description provided for @billingRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get billingRate;

  /// No description provided for @billingGstBase.
  ///
  /// In en, this message translates to:
  /// **'GST Base'**
  String get billingGstBase;

  /// No description provided for @billingNoProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get billingNoProductsFound;

  /// No description provided for @billingGstBreakdown.
  ///
  /// In en, this message translates to:
  /// **'GST Breakdown'**
  String get billingGstBreakdown;

  /// No description provided for @billingTaxableAmount.
  ///
  /// In en, this message translates to:
  /// **'Taxable Amount'**
  String get billingTaxableAmount;

  /// No description provided for @billingTotalGst.
  ///
  /// In en, this message translates to:
  /// **'Total GST'**
  String get billingTotalGst;

  /// No description provided for @billingBillCalculation.
  ///
  /// In en, this message translates to:
  /// **'Bill Calculation'**
  String get billingBillCalculation;

  /// No description provided for @billingGoldValue.
  ///
  /// In en, this message translates to:
  /// **'Gold Value'**
  String get billingGoldValue;

  /// No description provided for @billingStoneValue.
  ///
  /// In en, this message translates to:
  /// **'Stone Value'**
  String get billingStoneValue;

  /// No description provided for @billingDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get billingDiscount;

  /// No description provided for @billingOldGold.
  ///
  /// In en, this message translates to:
  /// **'Old Gold'**
  String get billingOldGold;

  /// No description provided for @billingInvoiceProtection.
  ///
  /// In en, this message translates to:
  /// **'Invoice Protection'**
  String get billingInvoiceProtection;

  /// No description provided for @billingVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get billingVerification;

  /// No description provided for @billingQrPayload.
  ///
  /// In en, this message translates to:
  /// **'QR Payload'**
  String get billingQrPayload;

  /// No description provided for @billingGenerated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get billingGenerated;

  /// No description provided for @billingInvoicePdfReady.
  ///
  /// In en, this message translates to:
  /// **'Invoice PDF ready'**
  String get billingInvoicePdfReady;

  /// No description provided for @billingInvoiceCreated.
  ///
  /// In en, this message translates to:
  /// **'Invoice created'**
  String get billingInvoiceCreated;

  /// No description provided for @billingWhatsAppOpened.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp opened'**
  String get billingWhatsAppOpened;

  /// No description provided for @errorInvoiceIdMissing.
  ///
  /// In en, this message translates to:
  /// **'Invoice ID is missing'**
  String get errorInvoiceIdMissing;

  /// No description provided for @errorFailedLoadInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invoice details'**
  String get errorFailedLoadInvoiceDetails;

  /// No description provided for @errorFailedGenerateInvoicePdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate invoice PDF'**
  String get errorFailedGenerateInvoicePdf;

  /// No description provided for @errorCouldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get errorCouldNotOpenWhatsApp;

  /// No description provided for @errorFailedPrepareWhatsAppInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to prepare WhatsApp invoice'**
  String get errorFailedPrepareWhatsAppInvoice;

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

  /// No description provided for @errorFailedPickShopLogo.
  ///
  /// In en, this message translates to:
  /// **'Failed to select shop logo'**
  String get errorFailedPickShopLogo;

  /// No description provided for @shopProfileBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get shopProfileBusinessDetails;

  /// No description provided for @shopProfileLogoTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop Logo'**
  String get shopProfileLogoTitle;

  /// No description provided for @shopProfileLogoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used on invoice preview and PDF.'**
  String get shopProfileLogoSubtitle;

  /// No description provided for @shopProfileChooseLogo.
  ///
  /// In en, this message translates to:
  /// **'Choose Logo'**
  String get shopProfileChooseLogo;

  /// No description provided for @shopProfileRemoveLogo.
  ///
  /// In en, this message translates to:
  /// **'Remove Logo'**
  String get shopProfileRemoveLogo;

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

  /// No description provided for @dashboardSoldProducts.
  ///
  /// In en, this message translates to:
  /// **'Sold Products'**
  String get dashboardSoldProducts;

  /// No description provided for @dashboardSoldThisMonthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sold this month'**
  String get dashboardSoldThisMonthSubtitle;

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

  /// No description provided for @inventoryGramsSuffix.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get inventoryGramsSuffix;

  /// No description provided for @inventoryTagAutoHint.
  ///
  /// In en, this message translates to:
  /// **'Tag number is auto-generated from the category (e.g. RG-01)'**
  String get inventoryTagAutoHint;

  /// No description provided for @inventoryTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get inventoryTakePhoto;

  /// No description provided for @inventoryNetWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculated: gross weight minus stone weight'**
  String get inventoryNetWeightHint;

  /// No description provided for @validationCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get validationCategoryRequired;

  /// No description provided for @validationStoneExceedsGross.
  ///
  /// In en, this message translates to:
  /// **'Stone weight must be less than gross weight'**
  String get validationStoneExceedsGross;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get commonTimeRange;

  /// No description provided for @inventoryMetalBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Products by Metal'**
  String get inventoryMetalBreakdownTitle;

  /// No description provided for @inventoryGoldByKarat.
  ///
  /// In en, this message translates to:
  /// **'Gold by Karat'**
  String get inventoryGoldByKarat;

  /// No description provided for @inventorySilverByPurity.
  ///
  /// In en, this message translates to:
  /// **'Silver by Purity'**
  String get inventorySilverByPurity;

  /// No description provided for @inventoryPiecesSuffix.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get inventoryPiecesSuffix;

  /// No description provided for @dashboardStockAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get dashboardStockAlertsTitle;

  /// No description provided for @dashboardStockAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} categories need restocking'**
  String dashboardStockAlertsSubtitle(int count);

  /// No description provided for @dashboardStockAlertOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get dashboardStockAlertOut;

  /// No description provided for @dashboardStockAlertLow.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get dashboardStockAlertLow;

  /// No description provided for @dashboardStockAlertCounts.
  ///
  /// In en, this message translates to:
  /// **'In stock: {inStock} · Min: {minStock}'**
  String dashboardStockAlertCounts(int inStock, int minStock);

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

  /// No description provided for @validationKaratRequired.
  ///
  /// In en, this message translates to:
  /// **'Karat / purity is required'**
  String get validationKaratRequired;

  /// No description provided for @inventorySellingPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — leave blank to price live from the daily rate'**
  String get inventorySellingPriceHint;

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

  /// No description provided for @commonClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get commonClearSearch;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get commonFilters;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this. Please try again.'**
  String get commonErrorBody;

  /// No description provided for @pageSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get pageSecurity;

  /// No description provided for @pageUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get pageUserManagement;

  /// No description provided for @pageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get pageCategories;

  /// No description provided for @categoryAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get categoryAddTitle;

  /// No description provided for @categoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get categoryEditTitle;

  /// No description provided for @categoryFieldName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryFieldName;

  /// No description provided for @categoryFieldPrefix.
  ///
  /// In en, this message translates to:
  /// **'Tag Prefix'**
  String get categoryFieldPrefix;

  /// No description provided for @categoryPrefixHelp.
  ///
  /// In en, this message translates to:
  /// **'2–6 letters, e.g. RG → tags RG-01, RG-02…'**
  String get categoryPrefixHelp;

  /// No description provided for @categoryFieldMinStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get categoryFieldMinStock;

  /// No description provided for @categoryMinStockHelp.
  ///
  /// In en, this message translates to:
  /// **'Alert when in-stock count falls to this level'**
  String get categoryMinStockHelp;

  /// No description provided for @categorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories…'**
  String get categorySearchHint;

  /// No description provided for @categoryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get categoryNoResults;

  /// No description provided for @categoryNoPrefix.
  ///
  /// In en, this message translates to:
  /// **'No tag prefix yet'**
  String get categoryNoPrefix;

  /// No description provided for @categoryTagPreview.
  ///
  /// In en, this message translates to:
  /// **'Tags like {tag}'**
  String categoryTagPreview(String tag);

  /// No description provided for @categoryInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get categoryInStock;

  /// No description provided for @categoryStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get categoryStatusInactive;

  /// No description provided for @categoryStatusLow.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get categoryStatusLow;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Only empty categories can be deleted.'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Category deleted'**
  String get categoryDeleted;

  /// No description provided for @errorFailedSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save category'**
  String get errorFailedSaveCategory;

  /// No description provided for @errorFailedDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get errorFailedDeleteCategory;

  /// No description provided for @validationCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter a category name'**
  String get validationCategoryName;

  /// No description provided for @validationCategoryPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix needs at least 2 letters'**
  String get validationCategoryPrefix;

  /// No description provided for @errorFailedLoadActivityLogs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load activity logs'**
  String get errorFailedLoadActivityLogs;

  /// No description provided for @errorFailedGenerateBackup.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate backup'**
  String get errorFailedGenerateBackup;

  /// No description provided for @errorFailedLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get errorFailedLoadUsers;

  /// No description provided for @errorFailedDeactivateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate user'**
  String get errorFailedDeactivateUser;

  /// No description provided for @errorFailedSaveUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to save user'**
  String get errorFailedSaveUser;

  /// No description provided for @securityDataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get securityDataBackup;

  /// No description provided for @securityExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export tenant data for customers, inventory, billing, mortgage, reports source data, and activity logs.'**
  String get securityExportSubtitle;

  /// No description provided for @securityNoBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No backup export recorded yet.'**
  String get securityNoBackupYet;

  /// No description provided for @securityLastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export: {date}'**
  String securityLastExport(String date);

  /// No description provided for @securityBackupReady.
  ///
  /// In en, this message translates to:
  /// **'Backup ready: {fileName}'**
  String securityBackupReady(String fileName);

  /// No description provided for @securitySearchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search activity logs'**
  String get securitySearchLogs;

  /// No description provided for @securityFilterArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get securityFilterArea;

  /// No description provided for @securityFilterAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All Areas'**
  String get securityFilterAllAreas;

  /// No description provided for @securityFilterInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get securityFilterInventory;

  /// No description provided for @securityFilterCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get securityFilterCustomers;

  /// No description provided for @securityFilterBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get securityFilterBilling;

  /// No description provided for @securityFilterMortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get securityFilterMortgage;

  /// No description provided for @securityFilterRates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get securityFilterRates;

  /// No description provided for @securityFilterBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get securityFilterBackup;

  /// No description provided for @securityFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get securityFilterAction;

  /// No description provided for @securityFilterAllActions.
  ///
  /// In en, this message translates to:
  /// **'All Actions'**
  String get securityFilterAllActions;

  /// No description provided for @securityActionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get securityActionCreate;

  /// No description provided for @securityActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get securityActionUpdate;

  /// No description provided for @securityActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get securityActionDelete;

  /// No description provided for @securityActionPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get securityActionPayment;

  /// No description provided for @securityActionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get securityActionClose;

  /// No description provided for @securityActionBackupExport.
  ///
  /// In en, this message translates to:
  /// **'Backup Export'**
  String get securityActionBackupExport;

  /// No description provided for @securityRefreshLogs.
  ///
  /// In en, this message translates to:
  /// **'Refresh logs'**
  String get securityRefreshLogs;

  /// No description provided for @securityActivityLogs.
  ///
  /// In en, this message translates to:
  /// **'Activity Logs'**
  String get securityActivityLogs;

  /// No description provided for @securityLogCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shown'**
  String securityLogCount(int count);

  /// No description provided for @securityNoLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No activity logs found.'**
  String get securityNoLogsFound;

  /// No description provided for @securityFeatures.
  ///
  /// In en, this message translates to:
  /// **'Security Features'**
  String get securityFeatures;

  /// No description provided for @securitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Activity logs and data backup for the shop.'**
  String get securitySubtitle;

  /// No description provided for @securityExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get securityExportBackup;

  /// No description provided for @userDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate User'**
  String get userDeactivateTitle;

  /// No description provided for @userDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {userName}?'**
  String userDeactivateConfirm(String userName);

  /// No description provided for @userDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get userDeactivateAction;

  /// No description provided for @userDeactivated.
  ///
  /// In en, this message translates to:
  /// **'User deactivated'**
  String get userDeactivated;

  /// No description provided for @userManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage shop admins and staff users.'**
  String get userManagementSubtitle;

  /// No description provided for @userAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get userAddUser;

  /// No description provided for @userSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users'**
  String get userSearchHint;

  /// No description provided for @userTeamHeader.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get userTeamHeader;

  /// No description provided for @userCount.
  ///
  /// In en, this message translates to:
  /// **'{count} users'**
  String userCount(int count);

  /// No description provided for @userNoResults.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get userNoResults;

  /// No description provided for @userNoContactInfo.
  ///
  /// In en, this message translates to:
  /// **'No contact info'**
  String get userNoContactInfo;

  /// No description provided for @userStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get userStatusActive;

  /// No description provided for @userStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get userStatusInactive;

  /// No description provided for @userStatusLoginLinked.
  ///
  /// In en, this message translates to:
  /// **'Login Linked'**
  String get userStatusLoginLinked;

  /// No description provided for @userStatusPendingLogin.
  ///
  /// In en, this message translates to:
  /// **'Pending Login'**
  String get userStatusPendingLogin;

  /// No description provided for @userEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit user'**
  String get userEditTooltip;

  /// No description provided for @userDeactivateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Deactivate user'**
  String get userDeactivateTooltip;

  /// No description provided for @userEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get userEditTitle;

  /// No description provided for @userAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get userAddTitle;

  /// No description provided for @userFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get userFieldName;

  /// No description provided for @validationUserName.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name'**
  String get validationUserName;

  /// No description provided for @userFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get userFieldEmail;

  /// No description provided for @validationUserEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validationUserEmail;

  /// No description provided for @userFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get userFieldPhone;

  /// No description provided for @userRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get userRoleOwner;

  /// No description provided for @userFieldRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get userFieldRole;

  /// No description provided for @userRoleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get userRoleStaff;

  /// No description provided for @userRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get userRoleAdmin;

  /// No description provided for @userRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management is for Admin users'**
  String get userRestrictedTitle;

  /// No description provided for @userRestrictedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff users can continue with their assigned work areas.'**
  String get userRestrictedSubtitle;

  /// No description provided for @userOnboardingTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Onboarding'**
  String get userOnboardingTipTitle;

  /// No description provided for @userOnboardingTipDesc.
  ///
  /// In en, this message translates to:
  /// **'Newly added staff must download the app and use the Sign Up option with the exact email address provided here to set their password and link their account.'**
  String get userOnboardingTipDesc;

  /// No description provided for @appShellToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Toggle theme'**
  String get appShellToggleTheme;

  /// No description provided for @appShellSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get appShellSecurity;

  /// No description provided for @appShellUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get appShellUserManagement;

  /// No description provided for @dashboardTotalGoldStock.
  ///
  /// In en, this message translates to:
  /// **'Total Gold Stock'**
  String get dashboardTotalGoldStock;

  /// No description provided for @dashboardAvailableNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Available net weight'**
  String get dashboardAvailableNetWeight;

  /// No description provided for @dashboardTotalSilverStock.
  ///
  /// In en, this message translates to:
  /// **'Total Silver Stock'**
  String get dashboardTotalSilverStock;

  /// No description provided for @dashboardInventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Inventory Value'**
  String get dashboardInventoryValue;

  /// No description provided for @dashboardAvailableStockValue.
  ///
  /// In en, this message translates to:
  /// **'Available stock value'**
  String get dashboardAvailableStockValue;

  /// No description provided for @dashboardThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get dashboardThisMonth;

  /// No description provided for @dashboardMortgageDues.
  ///
  /// In en, this message translates to:
  /// **'Mortgage dues'**
  String get dashboardMortgageDues;

  /// No description provided for @dashboardMortgageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Mortgage accounts'**
  String get dashboardMortgageAccounts;

  /// No description provided for @dashboardBilledToday.
  ///
  /// In en, this message translates to:
  /// **'Billed today'**
  String get dashboardBilledToday;

  /// No description provided for @dashboardGeneratedInvoices.
  ///
  /// In en, this message translates to:
  /// **'Generated invoices'**
  String get dashboardGeneratedInvoices;

  /// No description provided for @dashboardGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get dashboardGold;

  /// No description provided for @dashboardSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get dashboardSilver;

  /// No description provided for @dashboardRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get dashboardRevenue;

  /// No description provided for @dashboardLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get dashboardLoans;

  /// No description provided for @dashboardViewAllStats.
  ///
  /// In en, this message translates to:
  /// **'View all stats ({count})'**
  String dashboardViewAllStats(int count);

  /// No description provided for @dashboardRevenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get dashboardRevenueTrend;

  /// No description provided for @dashboardSalesLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Sales · last 7 days'**
  String get dashboardSalesLast7Days;

  /// No description provided for @dashboardNoRecentSales.
  ///
  /// In en, this message translates to:
  /// **'No sales in the last 7 days'**
  String get dashboardNoRecentSales;

  /// No description provided for @dashboardMonthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get dashboardMonthlyRevenue;

  /// No description provided for @dashboardPendingInterest.
  ///
  /// In en, this message translates to:
  /// **'Pending Interest'**
  String get dashboardPendingInterest;

  /// No description provided for @dashboardActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get dashboardActiveLoans;

  /// No description provided for @dashboardTodaysSales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get dashboardTodaysSales;

  /// No description provided for @dashboardTotalBills.
  ///
  /// In en, this message translates to:
  /// **'Total Bills'**
  String get dashboardTotalBills;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @reportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory, billing, GST, and mortgage reports from the Jewellery ERP flow.'**
  String get reportsSubtitle;

  /// No description provided for @reportsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search product, design, customer, invoice, or mobile'**
  String get reportsSearchHint;

  /// No description provided for @reportsFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get reportsFromDate;

  /// No description provided for @reportsToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get reportsToDate;

  /// No description provided for @reportsDateHint.
  ///
  /// In en, this message translates to:
  /// **'YYYY-MM-DD'**
  String get reportsDateHint;

  /// No description provided for @reportsCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get reportsCategory;

  /// No description provided for @reportsBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get reportsBranch;

  /// No description provided for @reportsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get reportsStatus;

  /// No description provided for @reportsAllStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get reportsAllStatus;

  /// No description provided for @reportsInStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get reportsInStock;

  /// No description provided for @reportsReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reportsReserved;

  /// No description provided for @reportsSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get reportsSold;

  /// No description provided for @reportsActiveLoan.
  ///
  /// In en, this message translates to:
  /// **'Active Loan'**
  String get reportsActiveLoan;

  /// No description provided for @reportsClosedLoan.
  ///
  /// In en, this message translates to:
  /// **'Closed Loan'**
  String get reportsClosedLoan;

  /// No description provided for @reportsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh reports'**
  String get reportsRefresh;

  /// No description provided for @reportsFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get reportsFilters;

  /// No description provided for @reportsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reportsReset;

  /// No description provided for @reportsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reportsApply;

  /// No description provided for @reportsInventoryReports.
  ///
  /// In en, this message translates to:
  /// **'Inventory Reports'**
  String get reportsInventoryReports;

  /// No description provided for @reportsBillingReports.
  ///
  /// In en, this message translates to:
  /// **'Billing Reports'**
  String get reportsBillingReports;

  /// No description provided for @reportsMortgageReports.
  ///
  /// In en, this message translates to:
  /// **'Mortgage Reports'**
  String get reportsMortgageReports;

  /// No description provided for @reportsDailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales Report'**
  String get reportsDailySales;

  /// No description provided for @reportsMonthlySales.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales Report'**
  String get reportsMonthlySales;

  /// No description provided for @reportsGst.
  ///
  /// In en, this message translates to:
  /// **'GST Report'**
  String get reportsGst;

  /// No description provided for @reportsActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'Active Loans Report'**
  String get reportsActiveLoans;

  /// No description provided for @reportsInterestCollection.
  ///
  /// In en, this message translates to:
  /// **'Interest Collection Report'**
  String get reportsInterestCollection;

  /// No description provided for @reportsClosedLoans.
  ///
  /// In en, this message translates to:
  /// **'Closed Loans Report'**
  String get reportsClosedLoans;

  /// No description provided for @reportsCurrentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock Report'**
  String get reportsCurrentStock;

  /// No description provided for @reportsSoldProducts.
  ///
  /// In en, this message translates to:
  /// **'Sold Products Report'**
  String get reportsSoldProducts;

  /// No description provided for @reportsLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Report'**
  String get reportsLowStock;

  /// No description provided for @reportsNoSalesDay.
  ///
  /// In en, this message translates to:
  /// **'No sales found for this day.'**
  String get reportsNoSalesDay;

  /// No description provided for @reportsNoSalesMonth.
  ///
  /// In en, this message translates to:
  /// **'No sales found for this month.'**
  String get reportsNoSalesMonth;

  /// No description provided for @reportsNoGstData.
  ///
  /// In en, this message translates to:
  /// **'No GST data found.'**
  String get reportsNoGstData;

  /// No description provided for @reportsNoActiveLoans.
  ///
  /// In en, this message translates to:
  /// **'No active loans found.'**
  String get reportsNoActiveLoans;

  /// No description provided for @reportsNoInterestCollections.
  ///
  /// In en, this message translates to:
  /// **'No interest collections found.'**
  String get reportsNoInterestCollections;

  /// No description provided for @reportsNoClosedLoans.
  ///
  /// In en, this message translates to:
  /// **'No closed loans found.'**
  String get reportsNoClosedLoans;

  /// No description provided for @reportsNoCurrentStock.
  ///
  /// In en, this message translates to:
  /// **'No current stock found.'**
  String get reportsNoCurrentStock;

  /// No description provided for @reportsNoSoldProducts.
  ///
  /// In en, this message translates to:
  /// **'No sold products found.'**
  String get reportsNoSoldProducts;

  /// No description provided for @reportsNoLowStock.
  ///
  /// In en, this message translates to:
  /// **'No low stock products found.'**
  String get reportsNoLowStock;

  /// No description provided for @reportsGstSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tax collected from filtered invoice history.'**
  String get reportsGstSubtitle;

  /// No description provided for @reportsActiveLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open gold loans with pending balances and due dates.'**
  String get reportsActiveLoansSubtitle;

  /// No description provided for @reportsInterestCollectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipts generated for interest and settlement payments.'**
  String get reportsInterestCollectionSubtitle;

  /// No description provided for @reportsClosedLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Settled loans moved out of active mortgage tracking.'**
  String get reportsClosedLoansSubtitle;

  /// No description provided for @reportsCurrentStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{goldWeight} gold, {silverWeight} silver in stock.'**
  String reportsCurrentStockSubtitle(String goldWeight, String silverWeight);

  /// No description provided for @reportsSoldProductsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sold products linked to invoice history.'**
  String get reportsSoldProductsSubtitle;

  /// No description provided for @reportsLowStockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk products with two or fewer units available.'**
  String get reportsLowStockSubtitle;

  /// No description provided for @reportsProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get reportsProduct;

  /// No description provided for @reportsUncategorised.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get reportsUncategorised;

  /// No description provided for @reportsNoDesignNumber.
  ///
  /// In en, this message translates to:
  /// **'No design number'**
  String get reportsNoDesignNumber;

  /// No description provided for @reportsPurity.
  ///
  /// In en, this message translates to:
  /// **'Purity'**
  String get reportsPurity;

  /// No description provided for @reportsGross.
  ///
  /// In en, this message translates to:
  /// **'Gross'**
  String get reportsGross;

  /// No description provided for @reportsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reportsNet;

  /// No description provided for @reportsSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get reportsSellingPrice;

  /// No description provided for @reportsMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get reportsMain;

  /// No description provided for @reportsInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get reportsInvoice;

  /// No description provided for @reportsCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get reportsCustomer;

  /// No description provided for @reportsPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get reportsPayment;

  /// No description provided for @reportsSoldDate.
  ///
  /// In en, this message translates to:
  /// **'Sold Date'**
  String get reportsSoldDate;

  /// No description provided for @reportsMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get reportsMobile;

  /// No description provided for @reportsAvailableQty.
  ///
  /// In en, this message translates to:
  /// **'Available Qty'**
  String get reportsAvailableQty;

  /// No description provided for @reportsDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportsDate;

  /// No description provided for @reportsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get reportsTotal;

  /// No description provided for @reportsItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get reportsItems;

  /// No description provided for @reportsTaxable.
  ///
  /// In en, this message translates to:
  /// **'Taxable'**
  String get reportsTaxable;

  /// No description provided for @reportsCgst.
  ///
  /// In en, this message translates to:
  /// **'CGST'**
  String get reportsCgst;

  /// No description provided for @reportsSgst.
  ///
  /// In en, this message translates to:
  /// **'SGST'**
  String get reportsSgst;

  /// No description provided for @reportsTotalGst.
  ///
  /// In en, this message translates to:
  /// **'Total GST'**
  String get reportsTotalGst;

  /// No description provided for @reportsMortgageLoan.
  ///
  /// In en, this message translates to:
  /// **'Mortgage Loan'**
  String get reportsMortgageLoan;

  /// No description provided for @reportsLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get reportsLoanAmount;

  /// No description provided for @reportsPendingInterest.
  ///
  /// In en, this message translates to:
  /// **'Pending Interest'**
  String get reportsPendingInterest;

  /// No description provided for @reportsPayable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get reportsPayable;

  /// No description provided for @reportsNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get reportsNextDue;

  /// No description provided for @reportsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get reportsReceipt;

  /// No description provided for @reportsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reportsAmount;

  /// No description provided for @reportsMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get reportsMode;

  /// No description provided for @reportsInterestPaid.
  ///
  /// In en, this message translates to:
  /// **'Interest Paid'**
  String get reportsInterestPaid;

  /// No description provided for @reportsClosingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing Date'**
  String get reportsClosingDate;

  /// No description provided for @reportsLoanStatus.
  ///
  /// In en, this message translates to:
  /// **'Loan Status'**
  String get reportsLoanStatus;

  /// No description provided for @reportsExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export report PDF'**
  String get reportsExportPdf;

  /// No description provided for @reportsAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Reports are for Admin users'**
  String get reportsAdminOnly;

  /// No description provided for @reportsStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Staff can continue using Billing, Inventory View, and Mortgage collections.'**
  String get reportsStaffSubtitle;

  /// No description provided for @reportsRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get reportsRestricted;

  /// No description provided for @reportsSalesGeneratedOn.
  ///
  /// In en, this message translates to:
  /// **'Sales generated on {date}.'**
  String reportsSalesGeneratedOn(String date);

  /// No description provided for @reportsSalesGeneratedIn.
  ///
  /// In en, this message translates to:
  /// **'Sales generated in {date}.'**
  String reportsSalesGeneratedIn(String date);

  /// No description provided for @mortgageTitle.
  ///
  /// In en, this message translates to:
  /// **'Mortgage / Gold Loan'**
  String get mortgageTitle;

  /// No description provided for @mortgageAddMortgage.
  ///
  /// In en, this message translates to:
  /// **'Add Mortgage'**
  String get mortgageAddMortgage;

  /// No description provided for @mortgageActive.
  ///
  /// In en, this message translates to:
  /// **'Active Loans'**
  String get mortgageActive;

  /// No description provided for @mortgageClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed Loans'**
  String get mortgageClosed;

  /// No description provided for @mortgagePendingInterest.
  ///
  /// In en, this message translates to:
  /// **'Pending Interest'**
  String get mortgagePendingInterest;

  /// No description provided for @mortgageTotalLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Loan Amount'**
  String get mortgageTotalLoanAmount;

  /// No description provided for @mortgageTodaysCollections.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Collections'**
  String get mortgageTodaysCollections;

  /// No description provided for @mortgageCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get mortgageCollections;

  /// No description provided for @mortgageOverdueLoans.
  ///
  /// In en, this message translates to:
  /// **'Overdue Loans'**
  String get mortgageOverdueLoans;

  /// No description provided for @mortgageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer, mobile, or loan number'**
  String get mortgageSearchHint;

  /// No description provided for @mortgageStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get mortgageStatusActive;

  /// No description provided for @mortgageStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get mortgageStatusClosed;

  /// No description provided for @mortgageStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mortgageStatusAll;

  /// No description provided for @mortgageNoLoansFound.
  ///
  /// In en, this message translates to:
  /// **'No mortgage loans found'**
  String get mortgageNoLoansFound;

  /// No description provided for @mortgageNoLoansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a gold loan or adjust the search and filters.'**
  String get mortgageNoLoansSubtitle;

  /// No description provided for @mortgageLoanFallback.
  ///
  /// In en, this message translates to:
  /// **'Mortgage Loan'**
  String get mortgageLoanFallback;

  /// No description provided for @mortgageCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get mortgageCustomerFallback;

  /// No description provided for @mortgageCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get mortgageCollect;

  /// No description provided for @mortgageClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mortgageClose;

  /// No description provided for @mortgageOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get mortgageOutstanding;

  /// No description provided for @mortgageTotalPayable.
  ///
  /// In en, this message translates to:
  /// **'Total Payable'**
  String get mortgageTotalPayable;

  /// No description provided for @mortgageInterestPaid.
  ///
  /// In en, this message translates to:
  /// **'Interest Paid'**
  String get mortgageInterestPaid;

  /// No description provided for @mortgageClosingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing Date'**
  String get mortgageClosingDate;

  /// No description provided for @mortgageLoanStatus.
  ///
  /// In en, this message translates to:
  /// **'Loan Status'**
  String get mortgageLoanStatus;

  /// No description provided for @mortgageInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get mortgageInterestRate;

  /// No description provided for @mortgageNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next Due'**
  String get mortgageNextDue;

  /// No description provided for @mortgageLoanDate.
  ///
  /// In en, this message translates to:
  /// **'Loan Date *'**
  String get mortgageLoanDate;

  /// No description provided for @mortgageTenure.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get mortgageTenure;

  /// No description provided for @mortgageInterestMonths.
  ///
  /// In en, this message translates to:
  /// **'Interest Months'**
  String get mortgageInterestMonths;

  /// No description provided for @mortgageOrnaments.
  ///
  /// In en, this message translates to:
  /// **'Ornaments'**
  String get mortgageOrnaments;

  /// No description provided for @mortgageReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get mortgageReceipt;

  /// No description provided for @mortgageCreated.
  ///
  /// In en, this message translates to:
  /// **'Mortgage loan created'**
  String get mortgageCreated;

  /// No description provided for @mortgagePaymentSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment saved'**
  String get mortgagePaymentSaved;

  /// No description provided for @mortgageLoanClosed.
  ///
  /// In en, this message translates to:
  /// **'Loan closed'**
  String get mortgageLoanClosed;

  /// No description provided for @mortgagePaymentReceiptMissing.
  ///
  /// In en, this message translates to:
  /// **'Payment receipt is missing'**
  String get mortgagePaymentReceiptMissing;

  /// No description provided for @mortgageFailedGenerateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate payment receipt'**
  String get mortgageFailedGenerateReceipt;

  /// No description provided for @mortgageAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Mortgage'**
  String get mortgageAddTitle;

  /// No description provided for @mortgageCustomerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get mortgageCustomerDetails;

  /// No description provided for @mortgageCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name *'**
  String get mortgageCustomerName;

  /// No description provided for @mortgageMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mortgageMobileNumber;

  /// No description provided for @mortgageAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get mortgageAddress;

  /// No description provided for @mortgageAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get mortgageAadhaarNumber;

  /// No description provided for @mortgagePanNumber.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get mortgagePanNumber;

  /// No description provided for @mortgageCustomerVerification.
  ///
  /// In en, this message translates to:
  /// **'Customer Verification'**
  String get mortgageCustomerVerification;

  /// No description provided for @mortgagePhotoId.
  ///
  /// In en, this message translates to:
  /// **'Photo ID'**
  String get mortgagePhotoId;

  /// No description provided for @mortgageCustomerPhoto.
  ///
  /// In en, this message translates to:
  /// **'Customer Photo'**
  String get mortgageCustomerPhoto;

  /// No description provided for @mortgageGoldDetails.
  ///
  /// In en, this message translates to:
  /// **'Gold Details'**
  String get mortgageGoldDetails;

  /// No description provided for @mortgageOrnamentType.
  ///
  /// In en, this message translates to:
  /// **'Ornament Type *'**
  String get mortgageOrnamentType;

  /// No description provided for @mortgageGrossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight *'**
  String get mortgageGrossWeight;

  /// No description provided for @mortgageNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight *'**
  String get mortgageNetWeight;

  /// No description provided for @mortgageLoanDetails.
  ///
  /// In en, this message translates to:
  /// **'Loan Details'**
  String get mortgageLoanDetails;

  /// No description provided for @mortgageLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount *'**
  String get mortgageLoanAmount;

  /// No description provided for @mortgageMonthlyInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Monthly Interest Rate % *'**
  String get mortgageMonthlyInterestRate;

  /// No description provided for @mortgageSaveLoan.
  ///
  /// In en, this message translates to:
  /// **'Save Loan'**
  String get mortgageSaveLoan;

  /// No description provided for @mortgageCollectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Payment'**
  String get mortgageCollectPayment;

  /// No description provided for @mortgageAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get mortgageAmount;

  /// No description provided for @mortgagePaymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get mortgagePaymentType;

  /// No description provided for @mortgageEditPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment'**
  String get mortgageEditPayment;

  /// No description provided for @mortgageClosure.
  ///
  /// In en, this message translates to:
  /// **'Closure'**
  String get mortgageClosure;

  /// No description provided for @mortgageInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get mortgageInterest;

  /// No description provided for @mortgagePrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get mortgagePrincipal;

  /// No description provided for @mortgagePaymentMode.
  ///
  /// In en, this message translates to:
  /// **'Payment Mode'**
  String get mortgagePaymentMode;

  /// No description provided for @mortgageReferenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference Number'**
  String get mortgageReferenceNumber;

  /// No description provided for @mortgageSavePayment.
  ///
  /// In en, this message translates to:
  /// **'Save Payment'**
  String get mortgageSavePayment;

  /// No description provided for @mortgageCloseLoan.
  ///
  /// In en, this message translates to:
  /// **'Close Loan'**
  String get mortgageCloseLoan;

  /// No description provided for @mortgageSettlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Settlement Amount *'**
  String get mortgageSettlementAmount;

  /// No description provided for @mortgageSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get mortgageSelected;

  /// No description provided for @mortgageChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get mortgageChooseImage;

  /// No description provided for @mortgageEnterValidLoanDate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid loan date'**
  String get mortgageEnterValidLoanDate;

  /// No description provided for @mortgageNetWeightExceedsGross.
  ///
  /// In en, this message translates to:
  /// **'Net weight cannot exceed gross weight'**
  String get mortgageNetWeightExceedsGross;

  /// No description provided for @mortgageFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create mortgage'**
  String get mortgageFailedCreate;

  /// No description provided for @mortgageFailedSavePayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to save payment'**
  String get mortgageFailedSavePayment;

  /// No description provided for @mortgageFailedCloseLoan.
  ///
  /// In en, this message translates to:
  /// **'Failed to close loan'**
  String get mortgageFailedCloseLoan;

  /// No description provided for @mortgageSelectLoanDate.
  ///
  /// In en, this message translates to:
  /// **'Select loan date'**
  String get mortgageSelectLoanDate;

  /// No description provided for @mortgagePurity.
  ///
  /// In en, this message translates to:
  /// **'Purity'**
  String get mortgagePurity;

  /// No description provided for @mortgageRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get mortgageRequired;

  /// No description provided for @mortgageEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get mortgageEnterValidAmount;

  /// No description provided for @inventoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get inventoryManagement;

  /// No description provided for @inventoryViewInventory.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get inventoryViewInventory;

  /// No description provided for @inventoryAddStock.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get inventoryAddStock;

  /// No description provided for @inventorySoldProducts.
  ///
  /// In en, this message translates to:
  /// **'Sold Products'**
  String get inventorySoldProducts;

  /// No description provided for @inventoryTotalGoldWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Gold Weight'**
  String get inventoryTotalGoldWeight;

  /// No description provided for @inventoryTotalSilverWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Silver Weight'**
  String get inventoryTotalSilverWeight;

  /// No description provided for @inventoryTotalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get inventoryTotalProducts;

  /// No description provided for @inventoryAlertLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get inventoryAlertLowStock;

  /// No description provided for @inventoryAlertOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get inventoryAlertOutOfStock;

  /// No description provided for @inventoryAlertHighValue.
  ///
  /// In en, this message translates to:
  /// **'High Value'**
  String get inventoryAlertHighValue;

  /// No description provided for @inventoryAlertUnsold.
  ///
  /// In en, this message translates to:
  /// **'Unsold'**
  String get inventoryAlertUnsold;

  /// No description provided for @inventoryScanHuidReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan HUID Receipt'**
  String get inventoryScanHuidReceipt;

  /// No description provided for @inventoryScanHuidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture a receipt and review AI-filled inventory rows before saving.'**
  String get inventoryScanHuidSubtitle;

  /// No description provided for @inventoryAddManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get inventoryAddManually;

  /// No description provided for @inventoryAddManuallySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a single item using the regular inventory form.'**
  String get inventoryAddManuallySubtitle;

  /// No description provided for @inventoryReadingHuid.
  ///
  /// In en, this message translates to:
  /// **'Reading HUID receipt...'**
  String get inventoryReadingHuid;

  /// No description provided for @inventoryChooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get inventoryChooseFromGallery;

  /// No description provided for @inventoryNoRowsFound.
  ///
  /// In en, this message translates to:
  /// **'No inventory rows were found in this receipt'**
  String get inventoryNoRowsFound;

  /// No description provided for @inventoryImported.
  ///
  /// In en, this message translates to:
  /// **'Inventory imported'**
  String get inventoryImported;

  /// No description provided for @inventoryFailedScanHuid.
  ///
  /// In en, this message translates to:
  /// **'Failed to scan HUID receipt'**
  String get inventoryFailedScanHuid;

  /// No description provided for @inventoryFailedImportRows.
  ///
  /// In en, this message translates to:
  /// **'Failed to import inventory rows'**
  String get inventoryFailedImportRows;

  /// No description provided for @inventoryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get inventoryClearSearch;

  /// No description provided for @inventorySearchHintSold.
  ///
  /// In en, this message translates to:
  /// **'Search invoice, customer, product, mobile, payment method'**
  String get inventorySearchHintSold;

  /// No description provided for @inventorySearchHintStock.
  ///
  /// In en, this message translates to:
  /// **'Search product, design number, tag, HUID'**
  String get inventorySearchHintStock;

  /// No description provided for @inventoryCountSold.
  ///
  /// In en, this message translates to:
  /// **'{count} sold products'**
  String inventoryCountSold(int count);

  /// No description provided for @inventoryNoSoldFound.
  ///
  /// In en, this message translates to:
  /// **'No sold products found'**
  String get inventoryNoSoldFound;

  /// No description provided for @inventoryNoSoldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sold products will appear here after billing is completed.'**
  String get inventoryNoSoldSubtitle;

  /// No description provided for @inventoryView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get inventoryView;

  /// No description provided for @inventoryViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get inventoryViewDetails;

  /// No description provided for @inventoryFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get inventoryFilters;

  /// No description provided for @inventoryFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get inventoryFilterReset;

  /// No description provided for @inventoryFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get inventoryFilterApply;

  /// No description provided for @inventoryFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryFilterStatus;

  /// No description provided for @inventoryFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryFilterCategory;

  /// No description provided for @inventoryFilterBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get inventoryFilterBranch;

  /// No description provided for @inventoryProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get inventoryProductDetails;

  /// No description provided for @inventoryWeightDetails.
  ///
  /// In en, this message translates to:
  /// **'Weight Details'**
  String get inventoryWeightDetails;

  /// No description provided for @inventoryPriceDetails.
  ///
  /// In en, this message translates to:
  /// **'Price Details'**
  String get inventoryPriceDetails;

  /// No description provided for @inventoryUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get inventoryUploadImage;

  /// No description provided for @inventoryFormStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get inventoryFormStatus;

  /// No description provided for @inventoryFieldDesignNumber.
  ///
  /// In en, this message translates to:
  /// **'Design Number'**
  String get inventoryFieldDesignNumber;

  /// No description provided for @inventoryFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryFieldCategory;

  /// No description provided for @inventoryFieldStoneWeight.
  ///
  /// In en, this message translates to:
  /// **'Stone Weight (g)'**
  String get inventoryFieldStoneWeight;

  /// No description provided for @inventoryFieldPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price / g'**
  String get inventoryFieldPurchasePrice;

  /// No description provided for @inventoryFieldBranch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get inventoryFieldBranch;

  /// No description provided for @inventoryFieldSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get inventoryFieldSellingPrice;

  /// No description provided for @inventoryChooseProductImage.
  ///
  /// In en, this message translates to:
  /// **'Choose Product Image'**
  String get inventoryChooseProductImage;

  /// No description provided for @inventoryRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove product image'**
  String get inventoryRemoveImage;

  /// No description provided for @inventoryImageReady.
  ///
  /// In en, this message translates to:
  /// **'Selected product image is ready to save.'**
  String get inventoryImageReady;

  /// No description provided for @inventoryFieldImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Product Image URL'**
  String get inventoryFieldImageUrl;

  /// No description provided for @inventoryAutoCalculations.
  ///
  /// In en, this message translates to:
  /// **'Auto Calculations'**
  String get inventoryAutoCalculations;

  /// No description provided for @inventoryCalcNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight'**
  String get inventoryCalcNetWeight;

  /// No description provided for @inventoryCalcMakingCharges.
  ///
  /// In en, this message translates to:
  /// **'Making Charges'**
  String get inventoryCalcMakingCharges;

  /// No description provided for @inventoryCalcFinalSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Selling Price'**
  String get inventoryCalcFinalSellingPrice;

  /// No description provided for @inventoryProductInfo.
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get inventoryProductInfo;

  /// No description provided for @inventoryProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get inventoryProductName;

  /// No description provided for @inventoryProductCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get inventoryProductCode;

  /// No description provided for @inventoryGrossWeight.
  ///
  /// In en, this message translates to:
  /// **'Gross Weight'**
  String get inventoryGrossWeight;

  /// No description provided for @inventoryStoneWeight.
  ///
  /// In en, this message translates to:
  /// **'Stone Weight'**
  String get inventoryStoneWeight;

  /// No description provided for @inventoryPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get inventoryPurchasePrice;

  /// No description provided for @inventoryMakingCharges.
  ///
  /// In en, this message translates to:
  /// **'Making Charges'**
  String get inventoryMakingCharges;

  /// No description provided for @inventoryGstInfo.
  ///
  /// In en, this message translates to:
  /// **'3% calculated during billing'**
  String get inventoryGstInfo;

  /// No description provided for @inventoryStatusInfo.
  ///
  /// In en, this message translates to:
  /// **'Status Information'**
  String get inventoryStatusInfo;

  /// No description provided for @inventoryQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get inventoryQuantity;

  /// No description provided for @inventoryClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get inventoryClose;

  /// No description provided for @inventoryReviewHuidTitle.
  ///
  /// In en, this message translates to:
  /// **'Review HUID Receipt Items'**
  String get inventoryReviewHuidTitle;

  /// No description provided for @inventoryReviewHuidSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check the AI-filled rows before adding them to inventory.'**
  String get inventoryReviewHuidSubtitle;

  /// No description provided for @inventoryImportItems.
  ///
  /// In en, this message translates to:
  /// **'Import Items'**
  String get inventoryImportItems;

  /// No description provided for @inventoryHuid.
  ///
  /// In en, this message translates to:
  /// **'HUID'**
  String get inventoryHuid;

  /// No description provided for @inventoryHallmark.
  ///
  /// In en, this message translates to:
  /// **'Hallmark'**
  String get inventoryHallmark;

  /// No description provided for @inventoryKarat.
  ///
  /// In en, this message translates to:
  /// **'Karat'**
  String get inventoryKarat;

  /// No description provided for @inventoryMetal.
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get inventoryMetal;

  /// No description provided for @inventoryWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get inventoryWarnings;

  /// No description provided for @inventoryWarningsOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get inventoryWarningsOk;

  /// No description provided for @inventoryAutoGenerated.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated'**
  String get inventoryAutoGenerated;

  /// No description provided for @inventoryReviewItemNumber.
  ///
  /// In en, this message translates to:
  /// **'Item {number}'**
  String inventoryReviewItemNumber(Object number);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get validationEnterNumber;

  /// No description provided for @validationMinQuantity.
  ///
  /// In en, this message translates to:
  /// **'Min 1'**
  String get validationMinQuantity;

  /// No description provided for @validationMinGreaterZero.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get validationMinGreaterZero;

  /// No description provided for @inventoryColumnCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryColumnCategory;

  /// No description provided for @inventoryColumnDesignNumber.
  ///
  /// In en, this message translates to:
  /// **'Design Number'**
  String get inventoryColumnDesignNumber;

  /// No description provided for @inventoryColumnPurity.
  ///
  /// In en, this message translates to:
  /// **'Purity'**
  String get inventoryColumnPurity;

  /// No description provided for @inventoryColumnNetWeight.
  ///
  /// In en, this message translates to:
  /// **'Net Weight'**
  String get inventoryColumnNetWeight;

  /// No description provided for @inventoryColumnSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get inventoryColumnSellingPrice;

  /// No description provided for @inventoryColumnInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get inventoryColumnInvoiceNumber;

  /// No description provided for @inventoryColumnCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get inventoryColumnCustomerName;

  /// No description provided for @inventoryColumnProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get inventoryColumnProductName;

  /// No description provided for @inventoryColumnSoldDate.
  ///
  /// In en, this message translates to:
  /// **'Sold Date'**
  String get inventoryColumnSoldDate;

  /// No description provided for @inventoryColumnPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get inventoryColumnPaymentMethod;

  /// No description provided for @inventoryCompactNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get inventoryCompactNet;

  /// No description provided for @inventoryCompactPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get inventoryCompactPrice;

  /// No description provided for @inventoryCompactPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get inventoryCompactPayment;

  /// No description provided for @billingCollectPayment.
  ///
  /// In en, this message translates to:
  /// **'Collect Payment'**
  String get billingCollectPayment;

  /// No description provided for @billingPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get billingPayments;

  /// No description provided for @billingPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get billingPaymentAmount;

  /// No description provided for @billingReference.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get billingReference;

  /// No description provided for @billingPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get billingPaymentRecorded;

  /// No description provided for @billingNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet'**
  String get billingNoPayments;

  /// No description provided for @billingCollectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record a payment against this invoice'**
  String get billingCollectSubtitle;

  /// No description provided for @errorFailedRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get errorFailedRecordPayment;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export ready: {fileName}'**
  String exportReady(String fileName);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @billingActionCollect.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get billingActionCollect;

  /// No description provided for @billingActionPrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get billingActionPrint;

  /// No description provided for @billingActionDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get billingActionDownload;

  /// No description provided for @billingActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get billingActionShare;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get periodMonth;

  /// No description provided for @period3Months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get period3Months;

  /// No description provided for @period6Months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get period6Months;

  /// No description provided for @period12Months.
  ///
  /// In en, this message translates to:
  /// **'12 Months'**
  String get period12Months;

  /// No description provided for @periodAll.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get periodAll;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get periodCustom;

  /// No description provided for @searchGlobalHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers, items, invoices...'**
  String get searchGlobalHint;

  /// No description provided for @searchStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get searchStartTitle;

  /// No description provided for @searchStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find customers, inventory items and invoices in one place.'**
  String get searchStartSubtitle;
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
