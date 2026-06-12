import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swarnbook/core/network/api_client.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/features/auth/application/app_permissions.dart';
import 'package:swarnbook/features/tenant/application/tenant_profile_payload.dart';
import 'package:swarnbook/features/tenant/data/models/tenant_profile.dart';
import 'package:swarnbook/features/tenant/data/repositories/tenant_repository.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/application/data_image.dart';
import 'package:swarnbook/shared/widgets/common_widgets.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  final _repository = TenantRepository();
  final _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();

  TenantProfile? _profile;
  String? _logoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _canManageProfile = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadProfile();
  }

  Future<void> _loadRole() async {
    try {
      final role = await fetchCurrentUserRole(ApiClient());
      if (mounted) setState(() => _canManageProfile = isAdminRole(role));
    } catch (_) {
      if (mounted) setState(() => _canManageProfile = false);
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _repository.getProfile();
      if (!mounted) return;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _isLoading = false);
        AppToast.error(context, l10n.errorFailedLoadShopProfile);
      }
    }
  }

  void _applyProfile(TenantProfile profile) {
    _shopNameController.text = profile.shopName;
    _ownerNameController.text = profile.ownerName;
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
    _cityController.text = profile.city ?? '';
    _stateController.text = profile.state ?? '';
    _pincodeController.text = profile.pincode ?? '';
    _gstinController.text = profile.gstin ?? '';
    _panController.text = profile.pan ?? '';
    _logoUrl = profile.logoUrl;
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canManageProfile) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final profile = await _repository.updateProfile(
        TenantProfileUpdateInput(
          shopName: _shopNameController.text,
          ownerName: _ownerNameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          city: _cityController.text,
          state: _stateController.text,
          pincode: _pincodeController.text,
          gstin: _gstinController.text,
          pan: _panController.text,
          logoUrl: _logoUrl,
        ),
      );

      _applyProfile(profile);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isSaving = false;
        });
        AppToast.success(context, l10n.successShopProfileUpdated);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(context, l10n.errorFailedUpdateShopProfile);
      }
    }
  }

  Future<void> _chooseShopLogo() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_canManageProfile) return;

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final dataUri = jpegImageDataUri(bytes: bytes);

      if (!mounted) return;
      setState(() => _logoUrl = dataUri);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, l10n.errorFailedPickShopLogo);
      }
    }
  }

  void _clearShopLogo() {
    if (!_canManageProfile) return;
    setState(() => _logoUrl = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.shopProfileTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                if (_canManageProfile)
                  GoldButton(
                    label: l10n.shopProfileSaveChanges,
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.shopProfileSubtitle,
              style: TextStyle(color: AppColors.text3(context)),
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1000;
                return Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.lg,
                  children: [
                    SizedBox(
                      width: isWide
                          ? (constraints.maxWidth - AppSpacing.lg - 320)
                          : constraints.maxWidth,
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeader(
                                title: l10n.shopProfileBusinessDetails,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _shopNameController,
                                l10n.shopProfileFieldShopName,
                                requiredMessage:
                                    l10n.validationShopNameRequired,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _ownerNameController,
                                l10n.shopProfileFieldOwnerName,
                                requiredMessage:
                                    l10n.validationOwnerNameRequired,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _emailController,
                                l10n.shopProfileFieldEmail,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _phoneController,
                                l10n.shopProfileFieldPhone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _addressController,
                                l10n.shopProfileFieldAddress,
                                maxLines: 3,
                                keyboardType: TextInputType.streetAddress,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _cityController,
                                l10n.shopProfileFieldCity,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _stateController,
                                l10n.shopProfileFieldState,
                                textInputAction: TextInputAction.next,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _pincodeController,
                                l10n.shopProfileFieldPincode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _gstinController,
                                l10n.shopProfileFieldGstin,
                                textInputAction: TextInputAction.next,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildField(
                                _panController,
                                l10n.shopProfileFieldPan,
                                textInputAction: TextInputAction.done,
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isWide ? 320 : constraints.maxWidth,
                      child: Column(
                        children: [
                          _buildLogoCard(l10n),
                          const SizedBox(height: AppSpacing.lg),
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SectionHeader(title: l10n.shopProfileTeam),
                                const SizedBox(height: AppSpacing.md),
                                ...?_profile?.users.map(
                                  (user) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          child: Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: TextStyle(
                                                  color: AppColors.text1(
                                                    context,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                user.email ??
                                                    user.phone ??
                                                    l10n.shopProfileNoContactInfo,
                                                style: TextStyle(
                                                  color: AppColors.text3(
                                                    context,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              StatusBadge(label: user.role),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCard(AppLocalizations l10n) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.shopProfileLogoTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.shopProfileLogoSubtitle,
            style: TextStyle(color: AppColors.text3(context)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(child: _buildLogoPreview()),
          if (_canManageProfile) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseShopLogo,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(l10n.shopProfileChooseLogo),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: l10n.shopProfileRemoveLogo,
                  onPressed: _logoUrl == null ? null : _clearShopLogo,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoPreview() {
    final logoUrl = _logoUrl;
    Widget child = const Icon(
      Icons.storefront_rounded,
      color: AppColors.textOnPrimary,
      size: 38,
    );

    if (logoUrl != null && logoUrl.isNotEmpty) {
      if (isDataImage(logoUrl)) {
        try {
          child = Image.memory(decodeDataImage(logoUrl), fit: BoxFit.cover);
        } catch (_) {
          child = const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textOnPrimary,
            size: 34,
          );
        }
      } else {
        child = Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textOnPrimary,
            size: 34,
          ),
        );
      }
    }

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        gradient: logoUrl == null || logoUrl.isEmpty
            ? AppColors.goldGradient
            : null,
        color: logoUrl == null || logoUrl.isEmpty
            ? null
            : AppColors.surfL(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.brd(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? requiredMessage,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: _canManageProfile,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (requiredMessage != null &&
            (value == null || value.trim().isEmpty)) {
          return requiredMessage;
        }
        return null;
      },
    );
  }
}
