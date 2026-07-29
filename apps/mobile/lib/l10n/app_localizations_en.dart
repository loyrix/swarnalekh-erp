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
  String get billingCustomerAddress => 'Customer Address';

  @override
  String get billingBillPricing => 'Bill Pricing (optional)';

  @override
  String get billingGoldRatePerGram => 'Gold Rate (₹/g)';

  @override
  String get billingMakingPerGram => 'Making (₹/g)';

  @override
  String get billingGstPercent => 'GST %';

  @override
  String get billingBillPricingHint =>
      'Set a gold rate to price every rate-based item on this bill. Making applies per gram; items with a saved selling price keep it. GST defaults to 3%.';

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
  String get billingSectionDashboard => 'Dashboard';

  @override
  String get billingSectionHistory => 'Invoice History';

  @override
  String get billingTodayRevenue => 'Today\'s Revenue';

  @override
  String get billingMonthlyRevenue => 'Monthly Revenue';

  @override
  String get billingTotalBills => 'Total Bills';

  @override
  String get billingAverageBill => 'Average Bill';

  @override
  String get billingTopSellingProducts => 'Top Selling Products';

  @override
  String get billingBillPreview => 'Bill Preview';

  @override
  String get billingFromDate => 'From date';

  @override
  String get billingToDate => 'To date';

  @override
  String get billingDateHint => 'YYYY-MM-DD';

  @override
  String get billingClearFilters => 'Clear filters';

  @override
  String get billingRefresh => 'Refresh invoices';

  @override
  String get billingViewInvoiceDetails => 'View invoice details';

  @override
  String get billingReprintInvoice => 'Reprint invoice';

  @override
  String get billingDownloadPdf => 'Download PDF';

  @override
  String get billingShareWhatsApp => 'Share on WhatsApp';

  @override
  String get billingInvoiceDetails => 'Invoice Details';

  @override
  String get billingInvoiceNumber => 'Invoice No';

  @override
  String get billingInvoiceDate => 'Invoice Date';

  @override
  String get billingPaymentMethod => 'Payment Method';

  @override
  String get billingMobile => 'Mobile';

  @override
  String get billingGstin => 'GSTIN';

  @override
  String get billingPurity => 'Purity';

  @override
  String get billingGross => 'Gross';

  @override
  String get billingNet => 'Net';

  @override
  String get billingRate => 'Rate';

  @override
  String get billingGstBase => 'GST Base';

  @override
  String get billingNoProductsFound => 'No products found';

  @override
  String get billingGstBreakdown => 'GST Breakdown';

  @override
  String get billingTaxableAmount => 'Taxable Amount';

  @override
  String get billingTotalGst => 'Total GST';

  @override
  String get billingBillCalculation => 'Bill Calculation';

  @override
  String get billingGoldValue => 'Gold Value';

  @override
  String get billingStoneValue => 'Stone Value';

  @override
  String get billingDiscount => 'Discount';

  @override
  String get billingOldGold => 'Old Gold';

  @override
  String get billingInvoiceProtection => 'Invoice Protection';

  @override
  String get billingVerification => 'Verification';

  @override
  String get billingQrPayload => 'QR Payload';

  @override
  String get billingGenerated => 'Generated';

  @override
  String get billingInvoicePdfReady => 'Invoice PDF ready';

  @override
  String get billingInvoiceCreated => 'Invoice created';

  @override
  String get billingWhatsAppOpened => 'WhatsApp opened';

  @override
  String get errorInvoiceIdMissing => 'Invoice ID is missing';

  @override
  String get errorFailedLoadInvoiceDetails => 'Failed to load invoice details';

  @override
  String get errorFailedGenerateInvoicePdf => 'Failed to generate invoice PDF';

  @override
  String get errorCouldNotOpenWhatsApp => 'Could not open WhatsApp';

  @override
  String get errorFailedPrepareWhatsAppInvoice =>
      'Failed to prepare WhatsApp invoice';

  @override
  String get errorFailedLoadShopProfile => 'Failed to load shop profile';

  @override
  String get successShopProfileUpdated => 'Shop profile updated';

  @override
  String get errorFailedUpdateShopProfile => 'Failed to update shop profile';

  @override
  String get errorFailedPickShopLogo => 'Failed to select shop logo';

  @override
  String get shopProfileBusinessDetails => 'Business Details';

  @override
  String get shopProfileLogoTitle => 'Shop Logo';

  @override
  String get shopProfileLogoSubtitle => 'Used on invoice preview and PDF.';

  @override
  String get shopProfileChooseLogo => 'Choose Logo';

  @override
  String get shopProfileRemoveLogo => 'Remove Logo';

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
  String get dashboardBusinessOverview => 'Business Overview';

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
  String get dashboardSoldProducts => 'Sold Products';

  @override
  String get dashboardSoldThisMonthSubtitle => 'Sold this month';

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
  String get inventoryFieldDetails => 'Details (optional)';

  @override
  String get inventoryDetailsHint =>
      'e.g. Hollow Rope — item name becomes Category (Details)';

  @override
  String get inventoryFieldTagNumber => 'Tag Number';

  @override
  String get inventoryTagNumberHint =>
      'Optional — blank auto-generates (RG-0001). Type an existing tag, or a number (\"2\" → PD-0002).';

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
  String get inventoryGramsSuffix => 'g';

  @override
  String get inventoryTagAutoHint =>
      'Tag number is auto-generated from the category (e.g. RG-01)';

  @override
  String get inventoryTakePhoto => 'Take photo';

  @override
  String get inventoryNetWeightHint =>
      'Auto-calculated: gross weight minus stone weight';

  @override
  String get validationCategoryRequired => 'Select a category';

  @override
  String get validationStoneExceedsGross =>
      'Stone weight must be less than gross weight';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonTimeRange => 'Time Range';

  @override
  String get inventoryMetalBreakdownTitle => 'Products by Metal';

  @override
  String get inventoryGoldByKarat => 'Gold by Karat';

  @override
  String get inventorySilverByPurity => 'Silver by Purity';

  @override
  String get inventoryPiecesSuffix => 'pcs';

  @override
  String get dashboardStockAlertsTitle => 'Out of Stock';

  @override
  String dashboardStockAlertsSubtitle(int count) {
    return '$count categories need restocking';
  }

  @override
  String get dashboardStockAlertOut => 'Out of stock';

  @override
  String get dashboardStockAlertLow => 'Low stock';

  @override
  String dashboardStockAlertCounts(int inStock, int minStock) {
    return 'In stock: $inStock · Min: $minStock';
  }

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
  String get validationKaratRequired => 'Karat / purity is required';

  @override
  String get inventorySellingPriceHint =>
      'Optional — leave blank to price live from the daily rate';

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

  @override
  String get commonClearSearch => 'Clear search';

  @override
  String get commonSave => 'Save';

  @override
  String get commonActive => 'Active';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonFilters => 'Filters';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String get commonErrorBody => 'We couldn\'t load this. Please try again.';

  @override
  String get pageSecurity => 'Security';

  @override
  String get pageUserManagement => 'User Management';

  @override
  String get pageCategories => 'Categories';

  @override
  String get categoryAddTitle => 'Add Category';

  @override
  String get categoryEditTitle => 'Edit Category';

  @override
  String get categoryFieldName => 'Category Name';

  @override
  String get categoryFieldPrefix => 'Tag Prefix';

  @override
  String get categoryPrefixHelp => '2–6 letters, e.g. RG → tags RG-01, RG-02…';

  @override
  String get categoryFieldMinStock => 'Min Stock';

  @override
  String get categoryMinStockHelp =>
      'Alert when in-stock count falls to this level';

  @override
  String get categorySearchHint => 'Search categories…';

  @override
  String get categoryNoResults => 'No categories found';

  @override
  String get categoryNoPrefix => 'No tag prefix yet';

  @override
  String categoryTagPreview(String tag) {
    return 'Tags like $tag';
  }

  @override
  String get categoryInStock => 'In Stock';

  @override
  String get categoryStatusInactive => 'Inactive';

  @override
  String get categoryStatusLow => 'Low Stock';

  @override
  String get categoryDeleteTitle => 'Delete Category';

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete \"$name\"? Only empty categories can be deleted.';
  }

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get errorFailedSaveCategory => 'Failed to save category';

  @override
  String get errorFailedDeleteCategory => 'Failed to delete category';

  @override
  String get validationCategoryName => 'Enter a category name';

  @override
  String get validationCategoryPrefix => 'Prefix needs at least 2 letters';

  @override
  String get errorFailedLoadActivityLogs => 'Failed to load activity logs';

  @override
  String get errorFailedGenerateBackup => 'Failed to generate backup';

  @override
  String get errorFailedLoadUsers => 'Failed to load users';

  @override
  String get errorFailedDeactivateUser => 'Failed to deactivate user';

  @override
  String get errorFailedSaveUser => 'Failed to save user';

  @override
  String get securityDataBackup => 'Data Backup';

  @override
  String get securityExportSubtitle =>
      'Export tenant data for customers, inventory, billing, mortgage, reports source data, and activity logs.';

  @override
  String get securityNoBackupYet => 'No backup export recorded yet.';

  @override
  String securityLastExport(String date) {
    return 'Last export: $date';
  }

  @override
  String securityBackupReady(String fileName) {
    return 'Backup ready: $fileName';
  }

  @override
  String get securitySearchLogs => 'Search activity logs';

  @override
  String get securityFilterArea => 'Area';

  @override
  String get securityFilterAllAreas => 'All Areas';

  @override
  String get securityFilterInventory => 'Inventory';

  @override
  String get securityFilterCustomers => 'Customers';

  @override
  String get securityFilterBilling => 'Billing';

  @override
  String get securityFilterMortgage => 'Mortgage';

  @override
  String get securityFilterRates => 'Rates';

  @override
  String get securityFilterBackup => 'Backup';

  @override
  String get securityFilterAction => 'Action';

  @override
  String get securityFilterAllActions => 'All Actions';

  @override
  String get securityActionCreate => 'Create';

  @override
  String get securityActionUpdate => 'Update';

  @override
  String get securityActionDelete => 'Delete';

  @override
  String get securityActionPayment => 'Payment';

  @override
  String get securityActionClose => 'Close';

  @override
  String get securityActionBackupExport => 'Backup Export';

  @override
  String get securityRefreshLogs => 'Refresh logs';

  @override
  String get securityActivityLogs => 'Activity Logs';

  @override
  String securityLogCount(int count) {
    return '$count shown';
  }

  @override
  String get securityNoLogsFound => 'No activity logs found.';

  @override
  String get securityFeatures => 'Security Features';

  @override
  String get securitySubtitle => 'Activity logs and data backup for the shop.';

  @override
  String get securityExportBackup => 'Export Backup';

  @override
  String get userDeactivateTitle => 'Deactivate User';

  @override
  String userDeactivateConfirm(String userName) {
    return 'Deactivate $userName?';
  }

  @override
  String get userDeactivateAction => 'Deactivate';

  @override
  String get userDeactivated => 'User deactivated';

  @override
  String get userManagementSubtitle => 'Manage shop admins and staff users.';

  @override
  String get userAddUser => 'Add User';

  @override
  String get userSearchHint => 'Search users';

  @override
  String get userTeamHeader => 'Team';

  @override
  String userCount(int count) {
    return '$count users';
  }

  @override
  String get userNoResults => 'No users found.';

  @override
  String get userNoContactInfo => 'No contact info';

  @override
  String get userStatusActive => 'Active';

  @override
  String get userStatusInactive => 'Inactive';

  @override
  String get userStatusLoginLinked => 'Login Linked';

  @override
  String get userStatusPendingLogin => 'Pending Login';

  @override
  String get userEditTooltip => 'Edit user';

  @override
  String get userDeactivateTooltip => 'Deactivate user';

  @override
  String get userEditTitle => 'Edit User';

  @override
  String get userAddTitle => 'Add User';

  @override
  String get userFieldName => 'Name';

  @override
  String get validationUserName => 'Enter a valid name';

  @override
  String get userFieldEmail => 'Email';

  @override
  String get validationUserEmail => 'Enter a valid email';

  @override
  String get userFieldPhone => 'Phone';

  @override
  String get userRoleOwner => 'Owner';

  @override
  String get userFieldRole => 'Role';

  @override
  String get userRoleStaff => 'Staff';

  @override
  String get userRoleAdmin => 'Admin';

  @override
  String get userRestrictedTitle => 'User Management is for Admin users';

  @override
  String get userRestrictedSubtitle =>
      'Staff users can continue with their assigned work areas.';

  @override
  String get userOnboardingTipTitle => 'Staff Onboarding';

  @override
  String get userOnboardingTipDesc =>
      'Newly added staff must download the app and use the Sign Up option with the exact email address provided here to set their password and link their account.';

  @override
  String get appShellToggleTheme => 'Toggle theme';

  @override
  String get appShellSecurity => 'Security';

  @override
  String get appShellUserManagement => 'User Management';

  @override
  String get dashboardTotalGoldStock => 'Total Gold Stock';

  @override
  String get dashboardAvailableNetWeight => 'Available net weight';

  @override
  String get dashboardTotalSilverStock => 'Total Silver Stock';

  @override
  String get dashboardInventoryValue => 'Inventory Value';

  @override
  String get dashboardAvailableStockValue => 'Available stock value';

  @override
  String get dashboardThisMonth => 'This month';

  @override
  String get dashboardMortgageDues => 'Mortgage dues';

  @override
  String get dashboardMortgageAccounts => 'Mortgage accounts';

  @override
  String get dashboardBilledToday => 'Billed today';

  @override
  String get dashboardGeneratedInvoices => 'Generated invoices';

  @override
  String get dashboardGold => 'Gold';

  @override
  String get dashboardSilver => 'Silver';

  @override
  String get dashboardRevenue => 'Revenue';

  @override
  String get dashboardLoans => 'Loans';

  @override
  String dashboardViewAllStats(int count) {
    return 'View all stats ($count)';
  }

  @override
  String get dashboardRevenueTrend => 'Revenue Trend';

  @override
  String get dashboardSalesLast7Days => 'Sales · last 7 days';

  @override
  String get dashboardNoRecentSales => 'No sales in the last 7 days';

  @override
  String get dashboardMonthlyRevenue => 'Monthly Revenue';

  @override
  String get dashboardPendingInterest => 'Pending Interest';

  @override
  String get dashboardActiveLoans => 'Active Loans';

  @override
  String get dashboardTodaysSales => 'Today\'s Sales';

  @override
  String get dashboardTotalBills => 'Total Bills';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsSubtitle =>
      'Inventory, billing, GST, and mortgage reports from the Jewellery ERP flow.';

  @override
  String get reportsSearchHint =>
      'Search product, design, customer, invoice, or mobile';

  @override
  String get reportsFromDate => 'From date';

  @override
  String get reportsToDate => 'To date';

  @override
  String get reportsDateHint => 'YYYY-MM-DD';

  @override
  String get reportsCategory => 'Category';

  @override
  String get reportsBranch => 'Branch';

  @override
  String get reportsStatus => 'Status';

  @override
  String get reportsAllStatus => 'All Status';

  @override
  String get reportsInStock => 'In Stock';

  @override
  String get reportsReserved => 'Reserved';

  @override
  String get reportsSold => 'Sold';

  @override
  String get reportsActiveLoan => 'Active Loan';

  @override
  String get reportsClosedLoan => 'Closed Loan';

  @override
  String get reportsRefresh => 'Refresh reports';

  @override
  String get reportsFilters => 'Filters';

  @override
  String get reportsReset => 'Reset';

  @override
  String get reportsApply => 'Apply';

  @override
  String get reportsInventoryReports => 'Inventory Reports';

  @override
  String get reportsBillingReports => 'Billing Reports';

  @override
  String get reportsMortgageReports => 'Mortgage Reports';

  @override
  String get reportsDailySales => 'Daily Sales Report';

  @override
  String get reportsMonthlySales => 'Monthly Sales Report';

  @override
  String get reportsGst => 'GST Report';

  @override
  String get reportsActiveLoans => 'Active Loans Report';

  @override
  String get reportsInterestCollection => 'Interest Collection Report';

  @override
  String get reportsClosedLoans => 'Closed Loans Report';

  @override
  String get reportsCurrentStock => 'Current Stock Report';

  @override
  String get reportsSoldProducts => 'Sold Products Report';

  @override
  String get reportsLowStock => 'Low Stock Report';

  @override
  String get reportsNoSalesDay => 'No sales found for this day.';

  @override
  String get reportsNoSalesMonth => 'No sales found for this month.';

  @override
  String get reportsNoGstData => 'No GST data found.';

  @override
  String get reportsNoActiveLoans => 'No active loans found.';

  @override
  String get reportsNoInterestCollections => 'No interest collections found.';

  @override
  String get reportsNoClosedLoans => 'No closed loans found.';

  @override
  String get reportsNoCurrentStock => 'No current stock found.';

  @override
  String get reportsNoSoldProducts => 'No sold products found.';

  @override
  String get reportsNoLowStock => 'No low stock products found.';

  @override
  String get reportsGstSubtitle =>
      'Tax collected from filtered invoice history.';

  @override
  String get reportsActiveLoansSubtitle =>
      'Open gold loans with pending balances and due dates.';

  @override
  String get reportsInterestCollectionSubtitle =>
      'Receipts generated for interest and settlement payments.';

  @override
  String get reportsClosedLoansSubtitle =>
      'Settled loans moved out of active mortgage tracking.';

  @override
  String reportsCurrentStockSubtitle(String goldWeight, String silverWeight) {
    return '$goldWeight gold, $silverWeight silver in stock.';
  }

  @override
  String get reportsSoldProductsSubtitle =>
      'Sold products linked to invoice history.';

  @override
  String get reportsLowStockSubtitle =>
      'Bulk products with two or fewer units available.';

  @override
  String get reportsProduct => 'Product';

  @override
  String get reportsUncategorised => 'Uncategorised';

  @override
  String get reportsNoDesignNumber => 'No design number';

  @override
  String get reportsPurity => 'Purity';

  @override
  String get reportsGross => 'Gross';

  @override
  String get reportsNet => 'Net';

  @override
  String get reportsSellingPrice => 'Selling Price';

  @override
  String get reportsMain => 'Main';

  @override
  String get reportsInvoice => 'Invoice';

  @override
  String get reportsCustomer => 'Customer';

  @override
  String get reportsPayment => 'Payment';

  @override
  String get reportsSoldDate => 'Sold Date';

  @override
  String get reportsMobile => 'Mobile';

  @override
  String get reportsAvailableQty => 'Available Qty';

  @override
  String get reportsDate => 'Date';

  @override
  String get reportsTotal => 'Total';

  @override
  String get reportsItems => 'Items';

  @override
  String get reportsTaxable => 'Taxable';

  @override
  String get reportsCgst => 'CGST';

  @override
  String get reportsSgst => 'SGST';

  @override
  String get reportsTotalGst => 'Total GST';

  @override
  String get reportsMortgageLoan => 'Mortgage Loan';

  @override
  String get reportsLoanAmount => 'Loan Amount';

  @override
  String get reportsPendingInterest => 'Pending Interest';

  @override
  String get reportsPayable => 'Payable';

  @override
  String get reportsNextDue => 'Next Due';

  @override
  String get reportsReceipt => 'Receipt';

  @override
  String get reportsAmount => 'Amount';

  @override
  String get reportsMode => 'Mode';

  @override
  String get reportsInterestPaid => 'Interest Paid';

  @override
  String get reportsClosingDate => 'Closing Date';

  @override
  String get reportsLoanStatus => 'Loan Status';

  @override
  String get reportsExportPdf => 'Export report PDF';

  @override
  String get reportsAdminOnly => 'Reports are for Admin users';

  @override
  String get reportsStaffSubtitle =>
      'Staff can continue using Billing, Inventory View, and Mortgage collections.';

  @override
  String get reportsRestricted => 'Restricted';

  @override
  String reportsSalesGeneratedOn(String date) {
    return 'Sales generated on $date.';
  }

  @override
  String reportsSalesGeneratedIn(String date) {
    return 'Sales generated in $date.';
  }

  @override
  String get mortgageTitle => 'Mortgage / Gold Loan';

  @override
  String get mortgageAddMortgage => 'Add Mortgage';

  @override
  String get mortgageActive => 'Active Loans';

  @override
  String get mortgageClosed => 'Closed Loans';

  @override
  String get mortgagePendingInterest => 'Pending Interest';

  @override
  String get mortgageTotalLoanAmount => 'Total Loan Amount';

  @override
  String get mortgageTodaysCollections => 'Today\'s Collections';

  @override
  String get mortgageCollections => 'Collections';

  @override
  String get mortgageOverdueLoans => 'Overdue Loans';

  @override
  String get mortgageSearchHint => 'Search customer, mobile, or loan number';

  @override
  String get mortgageStatusActive => 'Active';

  @override
  String get mortgageStatusClosed => 'Closed';

  @override
  String get mortgageStatusAll => 'All';

  @override
  String get mortgageNoLoansFound => 'No mortgage loans found';

  @override
  String get mortgageNoLoansSubtitle =>
      'Create a gold loan or adjust the search and filters.';

  @override
  String get mortgageLoanFallback => 'Mortgage Loan';

  @override
  String get mortgageCustomerFallback => 'Customer';

  @override
  String get mortgageCollect => 'Collect';

  @override
  String get mortgageClose => 'Close';

  @override
  String get mortgageOutstanding => 'Outstanding';

  @override
  String get mortgageTotalPayable => 'Total Payable';

  @override
  String get mortgageInterestPaid => 'Interest Paid';

  @override
  String get mortgageClosingDate => 'Closing Date';

  @override
  String get mortgageLoanStatus => 'Loan Status';

  @override
  String get mortgageInterestRate => 'Interest Rate';

  @override
  String get mortgageNextDue => 'Next Due';

  @override
  String get mortgageLoanDate => 'Loan Date *';

  @override
  String get mortgageTenure => 'Tenure';

  @override
  String get mortgageInterestMonths => 'Interest Months';

  @override
  String get mortgageOrnaments => 'Ornaments';

  @override
  String get mortgageReceipt => 'Receipt';

  @override
  String get mortgageCreated => 'Mortgage loan created';

  @override
  String get mortgagePaymentSaved => 'Payment saved';

  @override
  String get mortgageLoanClosed => 'Loan closed';

  @override
  String get mortgageReopen => 'Reopen';

  @override
  String get mortgageReopenConfirm =>
      'Reopen this loan to correct a wrong collection or closing? The settlement entry is removed and the loan becomes active again.';

  @override
  String get mortgageLoanReopened => 'Loan reopened';

  @override
  String get mortgageFailedReopen => 'Could not reopen the loan';

  @override
  String get mortgageAddTopup => 'Add Top-up';

  @override
  String get mortgageTopupTitle => 'Add Loan Top-up';

  @override
  String get mortgageTopupHelp =>
      'Add extra principal to this loan. How the top-up accrues interest follows your global mortgage setting.';

  @override
  String get mortgageTopupAmount => 'Top-up Amount';

  @override
  String get mortgageTopupDate => 'Top-up Date';

  @override
  String get mortgageTotalTopups => 'Total Top-ups';

  @override
  String get mortgageTopupAdded => 'Top-up added';

  @override
  String get mortgageFailedTopup => 'Could not add the top-up';

  @override
  String get mortgageSettings => 'Mortgage settings';

  @override
  String get mortgageTopupPolicy => 'Top-up interest policy';

  @override
  String get mortgageTopupSeparate => 'From the top-up date';

  @override
  String get mortgageTopupSeparateHint =>
      'Interest on a top-up starts from its own date.';

  @override
  String get mortgageTopupMerge => 'Merge with original loan';

  @override
  String get mortgageTopupMergeHint =>
      'Interest on a top-up is charged from the original loan date.';

  @override
  String get mortgageSettingsSaved => 'Setting saved';

  @override
  String get mortgageSettingsFailed => 'Could not save the setting';

  @override
  String get mortgagePaymentReceiptMissing => 'Payment receipt is missing';

  @override
  String get mortgageFailedGenerateReceipt =>
      'Failed to generate payment receipt';

  @override
  String get mortgageAddTitle => 'Add Mortgage';

  @override
  String get mortgageCustomerDetails => 'Customer Details';

  @override
  String get mortgageCustomerName => 'Customer Name *';

  @override
  String get mortgageMobileNumber => 'Mobile Number';

  @override
  String get mortgageAddress => 'Address';

  @override
  String get mortgageAadhaarNumber => 'Aadhaar Number';

  @override
  String get mortgagePanNumber => 'PAN Number';

  @override
  String get mortgageCustomerVerification => 'Customer Verification';

  @override
  String get mortgagePhotoId => 'Photo ID';

  @override
  String get mortgageCustomerPhoto => 'Customer Photo';

  @override
  String get mortgageGoldDetails => 'Gold Details';

  @override
  String get mortgageOrnamentType => 'Ornament Type *';

  @override
  String get mortgageGrossWeight => 'Gross Weight *';

  @override
  String get mortgageNetWeight => 'Net Weight *';

  @override
  String get mortgageLoanDetails => 'Loan Details';

  @override
  String get mortgageLoanAmount => 'Loan Amount *';

  @override
  String get mortgageMonthlyInterestRate => 'Monthly Interest Rate % *';

  @override
  String get mortgageSaveLoan => 'Save Loan';

  @override
  String get mortgageCollectPayment => 'Collect Payment';

  @override
  String get mortgageAmount => 'Amount *';

  @override
  String get mortgagePaymentType => 'Payment Type';

  @override
  String get mortgageEditPayment => 'Edit Payment';

  @override
  String get mortgageClosure => 'Closure';

  @override
  String get mortgageInterest => 'Interest';

  @override
  String get mortgagePrincipal => 'Principal';

  @override
  String get mortgagePaymentMode => 'Payment Mode';

  @override
  String get mortgageReferenceNumber => 'Reference Number';

  @override
  String get mortgageSavePayment => 'Save Payment';

  @override
  String get mortgageViewDetails => 'View Details';

  @override
  String get mortgageLoanOverview => 'Loan Overview';

  @override
  String get mortgageTopupHistory => 'Top-up History';

  @override
  String get mortgagePaymentHistory => 'Payment History';

  @override
  String get mortgageContactFailed => 'Could not open the contact app';

  @override
  String mortgageDueInDays(int days) {
    return 'DUE IN $days DAYS';
  }

  @override
  String mortgageOverdueByDays(int days) {
    return 'OVERDUE BY $days DAYS';
  }

  @override
  String get mortgageEditLoan => 'Edit Loan';

  @override
  String get mortgageLoanUpdated => 'Loan updated';

  @override
  String get mortgageFailedUpdateLoan => 'Could not update the loan';

  @override
  String get mortgageInterestRatePercent => 'Interest Rate (% per month)';

  @override
  String get mortgageLoanLedger => 'Loan Ledger';

  @override
  String get mortgageViewFullLedger => 'View Full Ledger';

  @override
  String get mortgageNoLedger => 'No ledger entries yet';

  @override
  String get mortgagePrintStatement => 'Print Statement';

  @override
  String get mortgageShareStatement => 'Share Statement';

  @override
  String get mortgageStatementFailed => 'Could not generate the statement';

  @override
  String get mortgageLedgerLoanCreated => 'Loan Created';

  @override
  String get mortgageLedgerTopupAdded => 'Top-up Added';

  @override
  String get mortgageLedgerInterestCollected => 'Interest Collected';

  @override
  String get mortgageLedgerPrincipalCollected => 'Principal Collected';

  @override
  String get mortgageLedgerClosed => 'Loan Closed';

  @override
  String get mortgageCloseLoan => 'Close Loan';

  @override
  String get mortgageProceedToClose => 'Proceed to Close';

  @override
  String get mortgageCloseInterestBanner =>
      'This loan has a top-up amount. Choose how to calculate interest while closing — this affects the final amount the customer pays.';

  @override
  String get mortgageSelectInterestOption =>
      'Select Interest Calculation Option';

  @override
  String get mortgageFromOriginalLoanDate => 'From Original Loan Date';

  @override
  String get mortgageFromTopupDate => 'From Top-up Date';

  @override
  String get mortgageOriginalLoanDate => 'Original Loan Date';

  @override
  String get mortgageRecommended => 'RECOMMENDED';

  @override
  String get mortgagePreviewCalculation => 'Preview Calculation';

  @override
  String get mortgagePrincipalOutstanding => 'Principal (Outstanding)';

  @override
  String get mortgageInterestCalculated => 'Interest (Calculated)';

  @override
  String mortgageInterestFromOriginalDesc(String date) {
    return 'Interest is calculated from the original loan date ($date), including the top-up amount.';
  }

  @override
  String mortgageInterestFromTopupDesc(String date) {
    return 'Interest on the top-up is calculated from the top-up date ($date).';
  }

  @override
  String mortgageInterestFromLabel(String date) {
    return 'Interest will be calculated from $date';
  }

  @override
  String get mortgageSettlementAmount => 'Settlement Amount *';

  @override
  String get mortgageSelected => 'Selected';

  @override
  String get mortgageChooseImage => 'Choose image';

  @override
  String get mortgageEnterValidLoanDate => 'Enter a valid loan date';

  @override
  String get mortgageNetWeightExceedsGross =>
      'Net weight cannot exceed gross weight';

  @override
  String get mortgageFailedCreate => 'Failed to create mortgage';

  @override
  String get mortgageFailedSavePayment => 'Failed to save payment';

  @override
  String get mortgageFailedCloseLoan => 'Failed to close loan';

  @override
  String get mortgageSelectLoanDate => 'Select loan date';

  @override
  String get mortgagePurity => 'Purity';

  @override
  String get mortgageRequired => 'Required';

  @override
  String get mortgageEnterValidAmount => 'Enter a valid amount';

  @override
  String get inventoryManagement => 'Inventory Management';

  @override
  String get inventoryViewInventory => 'View Inventory';

  @override
  String get inventoryAddStock => 'Add Stock';

  @override
  String get inventorySoldProducts => 'Sold Products';

  @override
  String get inventoryTotalGoldWeight => 'Total Gold Weight';

  @override
  String get inventoryTotalSilverWeight => 'Total Silver Weight';

  @override
  String get inventoryTotalProducts => 'Total Products';

  @override
  String get inventoryAlertLowStock => 'Low Stock';

  @override
  String get inventoryAlertOutOfStock => 'Out of Stock';

  @override
  String get inventoryAlertHighValue => 'High Value';

  @override
  String get inventoryAlertUnsold => 'Unsold';

  @override
  String get inventoryScanHuidReceipt => 'Scan HUID Receipt';

  @override
  String get inventoryScanHuidSubtitle =>
      'Capture a receipt and review AI-filled inventory rows before saving.';

  @override
  String get inventoryAddManually => 'Add Manually';

  @override
  String get inventoryAddManuallySubtitle =>
      'Enter a single item using the regular inventory form.';

  @override
  String get inventoryReadingHuid => 'Reading HUID receipt...';

  @override
  String get inventoryChooseFromGallery => 'Choose from gallery';

  @override
  String get inventoryNoRowsFound =>
      'No inventory rows were found in this receipt';

  @override
  String get inventoryImported => 'Inventory imported';

  @override
  String get inventoryFailedScanHuid => 'Failed to scan HUID receipt';

  @override
  String get inventoryFailedImportRows => 'Failed to import inventory rows';

  @override
  String get inventoryClearSearch => 'Clear search';

  @override
  String get inventorySearchHintSold =>
      'Search invoice, customer, product, mobile, payment method';

  @override
  String get inventorySearchHintStock =>
      'Search product, design number, tag, HUID';

  @override
  String inventoryCountSold(int count) {
    return '$count sold products';
  }

  @override
  String get inventoryNoSoldFound => 'No sold products found';

  @override
  String get inventoryNoSoldSubtitle =>
      'Sold products will appear here after billing is completed.';

  @override
  String get inventoryView => 'View';

  @override
  String get inventoryViewDetails => 'View details';

  @override
  String get inventoryFilters => 'Filters';

  @override
  String get inventoryFilterReset => 'Reset';

  @override
  String get inventoryFilterApply => 'Apply';

  @override
  String get inventoryFilterStatus => 'Status';

  @override
  String get inventoryFilterCategory => 'Category';

  @override
  String get inventoryFilterBranch => 'Branch';

  @override
  String get inventoryProductDetails => 'Product Details';

  @override
  String get inventoryWeightDetails => 'Weight Details';

  @override
  String get inventoryPriceDetails => 'Price Details';

  @override
  String get inventoryUploadImage => 'Upload Image';

  @override
  String get inventoryFormStatus => 'Status';

  @override
  String get inventoryFieldDesignNumber => 'Design Number';

  @override
  String get inventoryFieldCategory => 'Category';

  @override
  String get inventoryFieldStoneWeight => 'Stone Weight (g)';

  @override
  String get inventoryFieldPurchasePrice => 'Purchase Price / g';

  @override
  String get inventoryFieldBranch => 'Branch';

  @override
  String get inventoryFieldSellingPrice => 'Selling Price';

  @override
  String get inventoryChooseProductImage => 'Choose Product Image';

  @override
  String get inventoryRemoveImage => 'Remove product image';

  @override
  String get inventoryImageReady => 'Selected product image is ready to save.';

  @override
  String get inventoryFieldImageUrl => 'Product Image URL';

  @override
  String get inventoryAutoCalculations => 'Auto Calculations';

  @override
  String get inventoryCalcNetWeight => 'Net Weight';

  @override
  String get inventoryCalcMakingCharges => 'Making Charges';

  @override
  String get inventoryCalcFinalSellingPrice => 'Final Selling Price';

  @override
  String get inventoryProductInfo => 'Product Information';

  @override
  String get inventoryProductName => 'Product Name';

  @override
  String get inventoryProductCode => 'Product Code';

  @override
  String get inventoryGrossWeight => 'Gross Weight';

  @override
  String get inventoryStoneWeight => 'Stone Weight';

  @override
  String get inventoryPurchasePrice => 'Purchase Price';

  @override
  String get inventoryMakingCharges => 'Making Charges';

  @override
  String get inventoryGstInfo => '3% calculated during billing';

  @override
  String get inventoryStatusInfo => 'Status Information';

  @override
  String get inventoryQuantity => 'Quantity';

  @override
  String get inventoryClose => 'Close';

  @override
  String get inventoryReviewHuidTitle => 'Review HUID Receipt Items';

  @override
  String get inventoryReviewHuidSubtitle =>
      'Check the AI-filled rows before adding them to inventory.';

  @override
  String get inventoryImportItems => 'Import Items';

  @override
  String get inventoryImportFile => 'Import from File';

  @override
  String get inventoryImportFileSubtitle =>
      'Bring stock in from another jewellery ERP (CSV or Excel).';

  @override
  String get inventoryImportFileHelp =>
      'Choose a CSV or Excel (.xlsx) file exported from your old software. Existing tag numbers are kept as-is; only rows without a tag get a new one.';

  @override
  String get inventoryImportChooseFile => 'Choose CSV / Excel file';

  @override
  String get inventoryImportMapColumns => 'Map Columns';

  @override
  String get inventoryImportSkipColumn => '— Skip —';

  @override
  String get inventoryImportEmptyFile => 'That file has no rows to import.';

  @override
  String get inventoryImportParseFailed =>
      'Could not read that file. Check it is a valid CSV or Excel export.';

  @override
  String get inventoryImportNoValidRows =>
      'No valid rows to import — fix the highlighted errors first.';

  @override
  String inventoryImportSummary(int valid, int errors) {
    return '$valid ready to import, $errors with errors';
  }

  @override
  String inventoryImportDuplicateTags(int count) {
    return '$count duplicate tag number(s) in the file — make each tag unique before importing.';
  }

  @override
  String inventoryImportRowError(int row, String reasons) {
    return 'Row $row: $reasons';
  }

  @override
  String get inventoryHuid => 'HUID';

  @override
  String get inventoryHallmark => 'Hallmark';

  @override
  String get inventoryKarat => 'Karat';

  @override
  String get inventoryMetal => 'Metal';

  @override
  String get inventoryWarnings => 'Warnings';

  @override
  String get inventoryWarningsOk => 'OK';

  @override
  String get inventoryAutoGenerated => 'Auto-generated';

  @override
  String inventoryReviewItemNumber(Object number) {
    return 'Item $number';
  }

  @override
  String get validationRequired => 'Required';

  @override
  String get validationEnterNumber => 'Enter a number';

  @override
  String get validationMinQuantity => 'Min 1';

  @override
  String get validationMinGreaterZero => 'Must be greater than 0';

  @override
  String get inventoryColumnCategory => 'Category';

  @override
  String get inventoryColumnDesignNumber => 'Design Number';

  @override
  String get inventoryColumnPurity => 'Purity';

  @override
  String get inventoryColumnNetWeight => 'Net Weight';

  @override
  String get inventoryColumnSellingPrice => 'Selling Price';

  @override
  String get inventoryColumnInvoiceNumber => 'Invoice Number';

  @override
  String get inventoryColumnCustomerName => 'Customer Name';

  @override
  String get inventoryColumnProductName => 'Product Name';

  @override
  String get inventoryColumnSoldDate => 'Sold Date';

  @override
  String get inventoryColumnPaymentMethod => 'Payment Method';

  @override
  String get inventoryCompactNet => 'Net';

  @override
  String get inventoryCompactPrice => 'Price';

  @override
  String get inventoryCompactPayment => 'Payment';

  @override
  String get billingCollectPayment => 'Collect Payment';

  @override
  String get billingPayments => 'Payments';

  @override
  String get billingPaymentAmount => 'Amount';

  @override
  String get billingReference => 'Reference (optional)';

  @override
  String get billingPaymentRecorded => 'Payment recorded';

  @override
  String get billingNoPayments => 'No payments recorded yet';

  @override
  String get billingCollectSubtitle => 'Record a payment against this invoice';

  @override
  String get errorFailedRecordPayment => 'Failed to record payment';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String exportReady(String fileName) {
    return 'Export ready: $fileName';
  }

  @override
  String get exportFailed => 'Export failed';

  @override
  String get billingActionCollect => 'Collect';

  @override
  String get billingActionPrint => 'Print';

  @override
  String get billingActionDownload => 'Download';

  @override
  String get billingActionShare => 'Share';

  @override
  String get periodToday => 'Today';

  @override
  String get periodYesterday => 'Yesterday';

  @override
  String get periodLast7 => 'Last 7 Days';

  @override
  String get periodLast30 => 'Last 30 Days';

  @override
  String get periodMonth => 'This Month';

  @override
  String get periodLastMonth => 'Last Month';

  @override
  String get period3Months => 'Last 3 Months';

  @override
  String get period6Months => 'Last 6 Months';

  @override
  String get period12Months => '12 Months';

  @override
  String get periodFinancialYear => 'Financial Year';

  @override
  String get periodAll => 'All Time';

  @override
  String get periodCustom => 'Custom Range';

  @override
  String get searchGlobalHint => 'Search customers, items, invoices...';

  @override
  String get searchStartTitle => 'Search everything';

  @override
  String get searchStartSubtitle =>
      'Find customers, inventory items and invoices in one place.';
}
