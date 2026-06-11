// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SwarnaLekh';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navMortgage => 'Mortgage';

  @override
  String get navBilling => 'Billing';

  @override
  String get navReports => 'Reports';

  @override
  String get pageShopProfile => 'Shop Profile';

  @override
  String get searchHint => 'Search...';

  @override
  String get menuShopProfile => 'Shop Profile';

  @override
  String get menuLogout => 'Logout';

  @override
  String get menuLanguage => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get languageGujarati => 'Gujarati';

  @override
  String get placeholderComingSoon => 'Coming soon';

  @override
  String get placeholderModuleInProgress => 'This module is being built';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to manage your jewellery business';

  @override
  String get signupTitle => 'Create Account';

  @override
  String get signupSubtitle =>
      'Join SwarnaLekh to manage your jewellery business';

  @override
  String get authEmailAddress => 'Email Address';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authCreateAccount => 'Create Account';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authDontHaveAccount => 'Don\'t have an account?';

  @override
  String get authOr => 'or';

  @override
  String get authSecureConnection => 'Secure, encrypted connection';

  @override
  String get validationValidEmail => 'Enter a valid email';

  @override
  String get validationPasswordMin => 'Password must be at least 6 characters';

  @override
  String get validationPasswordsNoMatch => 'Passwords do not match';

  @override
  String get registrationSetupShop => 'Setup Your Shop';

  @override
  String get registrationAlmostThere => 'Almost there!';

  @override
  String get registrationSubtitle =>
      'Tell us about your business to set up your account.';

  @override
  String get registrationShopName => 'Shop Name *';

  @override
  String get registrationOwnerName => 'Owner Name *';

  @override
  String get registrationCityOptional => 'City (Optional)';

  @override
  String get registrationCompleteSetup => 'Complete Setup';

  @override
  String get registrationFailedPrefix => 'Registration failed:';

  @override
  String get inventoryOverview => 'Inventory Overview';

  @override
  String get inventoryAddItem => 'Add Item';

  @override
  String get inventoryInStock => 'In Stock';

  @override
  String get inventorySold => 'Sold';

  @override
  String get inventoryStockValue => 'Stock Value';

  @override
  String get inventoryAll => 'All';

  @override
  String get inventoryRatesPrefix => 'Rates:';

  @override
  String get inventoryItemsSuffix => 'items';

  @override
  String get billingInvoiceHistory => 'Invoice History';

  @override
  String get billingCreateInvoice => 'Create Invoice';

  @override
  String get billingCreateSalesSubtitle =>
      'Create sales bills and review recent invoices from one place.';

  @override
  String get ratesTitle => 'Daily Rates';

  @override
  String get ratesSubtitle =>
      'Set today\'s metal rates to be used across all billing and inventory.';

  @override
  String get shopProfileSubtitle =>
      'Manage your shop details, contact information, and billing identity.';

  @override
  String get shopProfileSaveChanges => 'Save Changes';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonToday => 'Today';

  @override
  String get customerAdd => 'Add Customer';

  @override
  String get customerWalkIn => 'Walk-in customer';

  @override
  String get billingSelectInventoryItems => 'Select Inventory Items';

  @override
  String get shopProfileTitle => 'Shop Profile';

  @override
  String get ratesGoldPerGram => 'Gold Rates (per gram)';

  @override
  String get ratesSilverPerGram => 'Silver Rate (per gram)';

  @override
  String get ratesFineSilver => 'Fine Silver';

  @override
  String get ratesSaveRates => 'Save Rates';

  @override
  String get ratesSaving => 'Saving...';

  @override
  String get ratesGold22 => 'Gold 22K';

  @override
  String get ratesGold18 => 'Gold 18K';

  @override
  String get ratesSelectedDate => 'Selected Date';

  @override
  String get ratesAvailable => 'rates available';

  @override
  String get ratesMissing => 'rates missing';

  @override
  String get ratesLatestAvailable => 'Latest Available';

  @override
  String get ratesNoRatesYet => 'No rates yet';

  @override
  String ratesRecentSnapshots(int count) {
    return '$count day snapshots in recent history';
  }

  @override
  String get errorFailedLoadCustomers => 'Failed to load customers';

  @override
  String get errorFailedSaveCustomer => 'Failed to save customer';

  @override
  String get customersSearchHint => 'Search by name or phone...';

  @override
  String get customerNoPhone => 'No phone';

  @override
  String get customerVisits => 'visits';

  @override
  String get customerNameLabel => 'Customer Name *';

  @override
  String get customerPhoneLabel => 'Phone';

  @override
  String get customerEmailLabel => 'Email';

  @override
  String get customerCityLabel => 'City';

  @override
  String get customerPreferredKaratLabel => 'Preferred Karat';

  @override
  String get validationCustomerNameRequired => 'Customer name is required';

  @override
  String get commonNotes => 'Notes';

  @override
  String get commonUpdate => 'Update';

  @override
  String get errorFailedLoadRates => 'Failed to load rates';

  @override
  String get errorEnterValidRate => 'Please enter at least one valid rate';

  @override
  String get successRatesUpdated => 'Rates updated successfully!';

  @override
  String get errorFailedSaveRates => 'Failed to save rates';

  @override
  String get errorFailedLoadInvoices => 'Failed to load invoices';

  @override
  String get billingSearchHint => 'Search by invoice number or customer...';

  @override
  String get billingInvoiceFallback => 'Invoice';

  @override
  String get billingStatusPending => 'pending';

  @override
  String get billingStatusCompleted => 'completed';

  @override
  String get billingTotal => 'Total';

  @override
  String get billingPaid => 'Paid';

  @override
  String get billingBalance => 'Balance';

  @override
  String get billingItems => 'Items';

  @override
  String get errorFailedLoadBillingData => 'Failed to load billing data';

  @override
  String get errorSelectInventoryItem => 'Select at least one inventory item';

  @override
  String get errorFailedCreateInvoice => 'Failed to create invoice';

  @override
  String get billingCustomerOptional => 'Customer (optional)';

  @override
  String get billingCustomerFallback => 'Customer';

  @override
  String get billingItemFallback => 'Item';

  @override
  String get billingNoTag => 'No tag';

  @override
  String get billingBulk => 'Bulk';

  @override
  String get billingUnique => 'Unique';

  @override
  String get billingQty => 'Qty';

  @override
  String get billingBillTable => 'Bill Table';

  @override
  String get billingProduct => 'Product';

  @override
  String get billingWeight => 'Weight';

  @override
  String get billingPrice => 'Price';

  @override
  String get billingCustomerDetails => 'Customer Details';

  @override
  String get billingSavedCustomer => 'Saved Customer';

  @override
  String get billingCustomerName => 'Customer Name';

  @override
  String get billingMobileNumber => 'Mobile Number';

  @override
  String get billingSearchInventory => 'Search Inventory';

  @override
  String get billingSelectedUnits => 'Selected Units';

  @override
  String get billingEstimatedSubtotal => 'Estimated Subtotal';

  @override
  String get billingDiscountAmount => 'Discount Amount';

  @override
  String get billingAmountPaid => 'Amount Paid';

  @override
  String get billingPaymentMode => 'Payment Mode';

  @override
  String get billingPaymentCash => 'Cash';

  @override
  String get billingPaymentUpi => 'UPI';

  @override
  String get billingPaymentCard => 'Card';

  @override
  String get billingPaymentDebitCard => 'Debit Card';

  @override
  String get billingPaymentCreditCard => 'Credit Card';

  @override
  String get billingPaymentBankTransfer => 'Bank Transfer';

  @override
  String get billingProductValue => 'Product Value';

  @override
  String get billingMakingCharges => 'Making Charges';

  @override
  String get billingGst => 'GST';

  @override
  String get billingFinalTotal => 'Final Total';

  @override
  String get billingRatesHint =>
      'Products with a saved selling price use that price. Items without selling price need current rates before billing.';

  @override
  String get errorFailedLoadShopProfile => 'Failed to load shop profile';

  @override
  String get successShopProfileUpdated => 'Shop profile updated';

  @override
  String get errorFailedUpdateShopProfile => 'Failed to update shop profile';

  @override
  String get shopProfileBusinessDetails => 'Business Details';

  @override
  String get shopProfileTeam => 'Team';

  @override
  String get shopProfileNoContactInfo => 'No contact info';

  @override
  String get shopProfileFieldShopName => 'Shop Name *';

  @override
  String get shopProfileFieldOwnerName => 'Owner Name *';

  @override
  String get shopProfileFieldEmail => 'Email';

  @override
  String get shopProfileFieldPhone => 'Phone';

  @override
  String get shopProfileFieldAddress => 'Address';

  @override
  String get shopProfileFieldCity => 'City';

  @override
  String get shopProfileFieldState => 'State';

  @override
  String get shopProfileFieldPincode => 'Pincode';

  @override
  String get shopProfileFieldGstin => 'GSTIN';

  @override
  String get shopProfileFieldPan => 'PAN';

  @override
  String get validationShopNameRequired => 'Shop name is required';

  @override
  String get validationOwnerNameRequired => 'Owner name is required';

  @override
  String get dashboardGoodMorning => 'Good morning';

  @override
  String get dashboardGoodAfternoon => 'Good afternoon';

  @override
  String get dashboardGoodEvening => 'Good evening';

  @override
  String get dashboardOwnerFallback => 'Owner';

  @override
  String get dashboardShopFallback => 'Your Jewellery Shop';

  @override
  String get dashboardQuickActions => 'Quick Actions';

  @override
  String get dashboardNewBill => 'New Bill';

  @override
  String get dashboardCreateInvoice => 'Create invoice';

  @override
  String get dashboardAddMortgage => 'Add Mortgage';

  @override
  String get dashboardSearchProduct => 'Search Product';

  @override
  String get dashboardSearchCustomer => 'Search Customer';

  @override
  String get dashboardNewContact => 'New contact';

  @override
  String get dashboardSetRates => 'Set Rates';

  @override
  String get dashboardTodaysPrices => 'Today\'s prices';

  @override
  String get dashboardItemsAvailable => 'items available';

  @override
  String get dashboardTotalRegistered => 'total registered';

  @override
  String get dashboardItemsSold => 'items sold';

  @override
  String get dashboardTotalItems => 'Total Items';

  @override
  String get dashboardInCatalog => 'in catalog';

  @override
  String get dashboardTodaysRates => 'Today\'s Rates';

  @override
  String get dashboardRatesMissingHint =>
      'Today\'s rates haven\'t been set yet. Tap Update to set them now.';

  @override
  String get dashboardRecentCustomers => 'Recent Customers';

  @override
  String get dashboardNoCustomersYet => 'No customers yet';

  @override
  String get dashboardAddFirstCustomer => 'Add First Customer';

  @override
  String get errorFailedLoadDashboard => 'Failed to load dashboard data';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonNotSet => 'Not set';

  @override
  String get ratesGold24 => 'Gold 24K';

  @override
  String get errorFailedLoadInventory => 'Failed to load inventory';

  @override
  String get inventoryDeleteTitle => 'Delete Inventory Item';

  @override
  String inventoryDeleteConfirm(String itemName) {
    return 'Delete $itemName from inventory?';
  }

  @override
  String get inventoryThisItem => 'this item';

  @override
  String get inventoryDeleted => 'Inventory item deleted';

  @override
  String get errorFailedDeleteInventory => 'Failed to delete inventory item';

  @override
  String get inventoryMetalGold => 'Gold';

  @override
  String get inventoryMetalSilver => 'Silver';

  @override
  String get inventoryMetalPlatinum => 'Platinum';

  @override
  String get inventoryMetalOther => 'Other';

  @override
  String get inventoryOnApproval => 'On Approval';

  @override
  String get inventoryReserved => 'Reserved';

  @override
  String get inventoryStockTypeBulk => 'Bulk';

  @override
  String get inventoryStockTypeUnique => 'Unique';

  @override
  String get inventoryColumnTag => 'Tag';

  @override
  String get inventoryColumnItem => 'Item';

  @override
  String get inventoryColumnStock => 'Stock';

  @override
  String get inventoryColumnQty => 'Qty';

  @override
  String get inventoryColumnMetal => 'Metal';

  @override
  String get inventoryColumnKarat => 'Karat';

  @override
  String get inventoryColumnGrossPerPiece => 'Gross/Pc';

  @override
  String get inventoryColumnNetPerPiece => 'Net/Pc';

  @override
  String get inventoryColumnEstimatedPerPiece => 'Est./Pc';

  @override
  String get inventoryColumnTotalValue => 'Total Value';

  @override
  String get inventoryColumnMaking => 'Making';

  @override
  String get inventoryColumnStatus => 'Status';

  @override
  String get inventoryColumnLocation => 'Location';

  @override
  String get inventoryColumnActions => 'Actions';

  @override
  String get inventoryUnnamedItem => 'Unnamed Item';

  @override
  String get inventoryEditItem => 'Edit item';

  @override
  String get inventoryDeleteItem => 'Delete item';

  @override
  String get inventoryMakingPrefix => 'Making';

  @override
  String get validationWeightGreaterThanZero =>
      'Gross and net weight must be greater than zero';

  @override
  String get validationMilligramsRange =>
      'Milligrams must be between 0 and 999';

  @override
  String get validationNetWeightGreater =>
      'Net weight cannot be greater than gross weight';

  @override
  String get errorFailedSaveInventory => 'Failed to save inventory item';

  @override
  String get inventoryEditTitle => 'Edit Inventory Item';

  @override
  String get inventoryAddTitle => 'Add Inventory Item';

  @override
  String get inventoryFieldItemName => 'Item Name *';

  @override
  String get inventoryFieldTagNumber => 'Tag Number';

  @override
  String get inventoryFieldStockType => 'Stock Type';

  @override
  String get inventoryFieldQuantity => 'Quantity *';

  @override
  String get inventoryFieldMetalType => 'Metal Type *';

  @override
  String get inventoryFieldKarat => 'Karat';

  @override
  String get inventoryFieldGrossWeight => 'Gross Weight *';

  @override
  String get inventoryFieldNetWeight => 'Net Weight *';

  @override
  String get inventoryFieldMakingMode => 'Making Mode';

  @override
  String get inventoryFixedMaking => 'Fixed Making';

  @override
  String get inventoryMakingPercentage => 'Making Percentage';

  @override
  String get inventoryMakingPerGram => 'Making Charges / Gram';

  @override
  String get inventoryGrams => 'Grams';

  @override
  String get inventoryMilligrams => 'Milligrams';

  @override
  String get inventoryMakingModePerGram => 'Per Gram';

  @override
  String get inventoryMakingModeFixed => 'Fixed';

  @override
  String get inventoryMakingModePercentage => 'Percentage';

  @override
  String get validationItemNameRequired => 'Item name is required';

  @override
  String get validationQuantityRequired => 'Quantity is required';

  @override
  String get validationValidNumber => 'Enter a valid number';

  @override
  String get validationWholeNumber => 'Enter a valid whole number';

  @override
  String get validationQuantityMinOne => 'Quantity must be at least 1';

  @override
  String get otpNotActiveTitle => 'OTP Not Active';

  @override
  String get otpNotActiveMessage =>
      'Phone OTP is currently disabled for the MVP. Use email/password login and signup for now.';

  @override
  String get otpNoPhoneProvided => 'No phone number was provided.';

  @override
  String otpLegacyPhone(String phone) {
    return 'Legacy phone: $phone';
  }

  @override
  String get otpBackToLogin => 'Back to Login';
}
