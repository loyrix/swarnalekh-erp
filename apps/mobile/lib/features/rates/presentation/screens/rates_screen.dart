import 'package:flutter/material.dart';
import 'package:swarnbook/core/theme/app_theme.dart';
import 'package:swarnbook/l10n/app_localizations.dart';
import 'package:swarnbook/shared/widgets/app_kit.dart';
import 'package:swarnbook/shared/widgets/error_toast.dart';
import '../../data/repositories/rates_repository.dart';

class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  final _repository = RatesRepository();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;
  List<Map<String, dynamic>> _history = [];
  DateTime? _latestAvailableDate;

  // Form controllers
  final _gold22Controller = TextEditingController();
  final _gold18Controller = TextEditingController();
  final _silverController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _gold22Controller.dispose();
    _gold18Controller.dispose();
    _silverController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        _repository.getRatesByDate(_selectedDate),
        _repository.getHistory(days: 7),
      ]);
      final rates = results[0] as List;
      final history = results[1] as List<Map<String, dynamic>>;

      // Reset
      _gold22Controller.text = '';
      _gold18Controller.text = '';
      _silverController.text = '';

      for (var r in rates) {
        if (r.metalType == 'gold' && r.karat == '22K') {
          _gold22Controller.text = r.ratePerGram.toString();
        } else if (r.metalType == 'gold' && r.karat == '18K') {
          _gold18Controller.text = r.ratePerGram.toString();
        } else if (r.metalType == 'silver') {
          _silverController.text = r.ratePerGram.toString();
        }
      }

      if (mounted) {
        setState(() {
          _history = history;
          final latestDateString = history.isNotEmpty
              ? history.first['date']?.toString()
              : null;
          _latestAvailableDate = latestDateString != null
              ? DateTime.tryParse(latestDateString)
              : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
        final l10n = AppLocalizations.of(context)!;
        AppToast.error(context, l10n.errorFailedLoadRates);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRates() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> ratesToSave = [];
      final dateStr = _selectedDate.toIso8601String();

      final g22 = double.tryParse(_gold22Controller.text);
      if (g22 != null && g22 > 0) {
        ratesToSave.add({
          'rateDate': dateStr,
          'metalType': 'gold',
          'karat': '22K',
          'ratePerGram': g22,
        });
      }

      final g18 = double.tryParse(_gold18Controller.text);
      if (g18 != null && g18 > 0) {
        ratesToSave.add({
          'rateDate': dateStr,
          'metalType': 'gold',
          'karat': '18K',
          'ratePerGram': g18,
        });
      }

      final silver = double.tryParse(_silverController.text);
      if (silver != null && silver > 0) {
        ratesToSave.add({
          'rateDate': dateStr,
          'metalType': 'silver',
          'karat': '',
          'ratePerGram': silver,
        });
      }

      if (ratesToSave.isEmpty) {
        throw Exception(l10n.errorEnterValidRate);
      }

      await _repository.bulkUpdateRates(ratesToSave);

      if (mounted) {
        AppToast.success(context, l10n.successRatesUpdated);
        _loadRates();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, l10n.errorFailedSaveRates);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: _loadRates,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap so the title + date controls never overflow on a phone:
            // they sit on one line when wide and stack when narrow.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              runSpacing: AppSpacing.sm,
              children: [
                Text(
                  l10n.ratesTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                        _loadRates();
                      },
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: Text(l10n.commonToday),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _buildDateSelector(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.ratesSubtitle,
              style: TextStyle(color: AppColors.text3(context)),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildInsightRow(),
            const SizedBox(height: AppSpacing.xxl),

            if (_isLoading)
              const SizedBox(
                height: 320,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_hasError)
              SizedBox(height: 320, child: AppErrorView(onRetry: _loadRates))
            else ...[
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SectionHeader(title: l10n.ratesGoldPerGram),
                        _buildRateInput(
                          l10n.ratesGold22,
                          _gold22Controller,
                          AppColors.gold,
                          '₹',
                          '6650',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildRateInput(
                          l10n.ratesGold18,
                          _gold18Controller,
                          AppColors.gold,
                          '₹',
                          '5440',
                        ),

                        const SizedBox(height: AppSpacing.xl),
                        Divider(color: AppColors.div(context)),
                        const SizedBox(height: AppSpacing.xl),

                        SectionHeader(title: l10n.ratesSilverPerGram),
                        _buildRateInput(
                          l10n.ratesFineSilver,
                          _silverController,
                          AppColors.silver,
                          '₹',
                          '95',
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        GoldButton(
                          label: _isSaving
                              ? l10n.ratesSaving
                              : l10n.ratesSaveRates,
                          icon: Icons.check_circle_outline,
                          isLoading: _isSaving,
                          onPressed: _isSaving ? null : _saveRates,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow() {
    final l10n = AppLocalizations.of(context)!;
    final hasSelectedDateRates =
        _gold22Controller.text.isNotEmpty ||
        _gold18Controller.text.isNotEmpty ||
        _silverController.text.isNotEmpty;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 280,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ratesSelectedDate,
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                StatusBadge(
                  label: hasSelectedDateRates
                      ? l10n.ratesAvailable
                      : l10n.ratesMissing,
                  color: hasSelectedDateRates
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 280,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.ratesLatestAvailable,
                  style: TextStyle(
                    color: AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _latestAvailableDate == null
                      ? l10n.ratesNoRatesYet
                      : '${_latestAvailableDate!.day}/${_latestAvailableDate!.month}/${_latestAvailableDate!.year}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.ratesRecentSnapshots(_history.length),
                  style: TextStyle(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: AppColors.textOnPrimary,
                  surface: AppColors.surf(context),
                  onSurface: AppColors.text1(context),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null && mounted) {
          setState(() => _selectedDate = date);
          _loadRates();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfL(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.brd(context)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.text2(context),
            ),
            const SizedBox(width: 8),
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: TextStyle(
                color: AppColors.text1(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.text2(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateInput(
    String label,
    TextEditingController controller,
    Color color,
    String prefix,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.text2(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text1(context),
          ),
          decoration: InputDecoration(
            prefixText: '$prefix  ',
            prefixStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text3(context),
            ),
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: AppColors.text3(context).withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
