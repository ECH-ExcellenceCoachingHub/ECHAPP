import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/router/post_auth_navigation.dart';
import 'package:excellencecoachinghub/utils/phone_validator.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/widgets/desktop_brand_panel.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

class _Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  const _Country(this.name, this.code, this.dialCode, this.flag);
}

const List<_Country> _countries = [
  // Africa
  _Country('Algeria', 'DZ', '+213', '🇩🇿'),
  _Country('Angola', 'AO', '+244', '🇦🇴'),
  _Country('Benin', 'BJ', '+229', '🇧🇯'),
  _Country('Botswana', 'BW', '+267', '🇧🇼'),
  _Country('Burkina Faso', 'BF', '+226', '🇧🇫'),
  _Country('Burundi', 'BI', '+257', '��'),
  _Country('Cameroon', 'CM', '+237', '🇨🇲'),
  _Country('Cape Verde', 'CV', '+238', '🇨🇻'),
  _Country('Chad', 'TD', '+235', '🇹🇩'),
  _Country('Comoros', 'KM', '+269', '🇰🇲'),
  _Country('Congo', 'CG', '+242', '🇨🇬'),
  _Country('DR Congo', 'CD', '+243', '🇨🇩'),
  _Country('Djibouti', 'DJ', '+253', '��'),
  _Country('Egypt', 'EG', '+20', '🇪�'),
  _Country('Equatorial Guinea', 'GQ', '+240', '🇬🇶'),
  _Country('Eritrea', 'ER', '+291', '🇷'),
  _Country('Eswatini', 'SZ', '+268', '🇸🇿'),
  _Country('Ethiopia', 'ET', '+251', '🇪🇹'),
  _Country('Gabon', 'GA', '+241', '🇬�'),
  _Country('Gambia', 'GM', '+220', '🇬🇲'),
  _Country('Ghana', 'GH', '+233', '🇬🇭'),
  _Country('Guinea', 'GN', '+224', '🇬🇳'),
  _Country('Guinea-Bissau', 'GW', '+245', '🇬🇼'),
  _Country('Ivory Coast', 'CI', '+225', '�🇮'),
  _Country('Kenya', 'KE', '+254', '🇰🇪'),
  _Country('Lesotho', 'LS', '+266', '🇱🇸'),
  _Country('Liberia', 'LR', '+231', '🇱🇷'),
  _Country('Libya', 'LY', '+218', '🇱🇾'),
  _Country('Madagascar', 'MG', '+261', '🇲🇬'),
  _Country('Malawi', 'MW', '+265', '🇲🇼'),
  _Country('Mali', 'ML', '+223', '🇲🇱'),
  _Country('Mauritania', 'MR', '+222', '🇲🇷'),
  _Country('Mauritius', 'MU', '+230', '🇲🇺'),
  _Country('Morocco', 'MA', '+212', '🇲🇦'),
  _Country('Mozambique', 'MZ', '+258', '🇲🇿'),
  _Country('Namibia', 'NA', '+264', '🇳🇦'),
  _Country('Niger', 'NE', '+227', '��'),
  _Country('Nigeria', 'NG', '+234', '🇳🇬'),
  _Country('Rwanda', 'RW', '+250', '🇷🇼'),
  _Country('Sao Tome', 'ST', '+239', '🇸🇹'),
  _Country('Senegal', 'SN', '+221', '🇸🇳'),
  _Country('Seychelles', 'SC', '+248', '🇸🇨'),
  _Country('Sierra Leone', 'SL', '+232', '🇸🇱'),
  _Country('Somalia', 'SO', '+252', '🇸🇴'),
  _Country('South Africa', 'ZA', '+27', '🇿🇦'),
  _Country('South Sudan', 'SS', '+211', '🇸🇸'),
  _Country('Sudan', 'SD', '+249', '🇸🇩'),
  _Country('Tanzania', 'TZ', '+255', '🇹🇿'),
  _Country('Togo', 'TG', '+228', '🇹🇬'),
  _Country('Tunisia', 'TN', '+216', '🇹🇳'),
  _Country('Uganda', 'UG', '+256', '🇺🇬'),
  _Country('Zambia', 'ZM', '+260', '🇿🇲'),
  _Country('Zimbabwe', 'ZW', '+263', '🇿🇼'),
  // Americas
  _Country('Argentina', 'AR', '+54', '🇦🇷'),
  _Country('Bahamas', 'BS', '+1', '🇧🇸'),
  _Country('Barbados', 'BB', '+1', '🇧🇧'),
  _Country('Belize', 'BZ', '+501', '🇧🇿'),
  _Country('Bolivia', 'BO', '+591', '🇧🇴'),
  _Country('Brazil', 'BR', '+55', '🇧🇷'),
  _Country('Canada', 'CA', '+1', '🇨🇦'),
  _Country('Chile', 'CL', '+56', '🇨🇱'),
  _Country('Colombia', 'CO', '+57', '🇨🇴'),
  _Country('Costa Rica', 'CR', '+506', '🇨🇷'),
  _Country('Cuba', 'CU', '+53', '�🇺'),
  _Country('Dominican Republic', 'DO', '+1', '🇩🇴'),
  _Country('Ecuador', 'EC', '+593', '�🇨'),
  _Country('El Salvador', 'SV', '+503', '🇸🇻'),
  _Country('Guatemala', 'GT', '+502', '��'),
  _Country('Guyana', 'GY', '+592', '🇬🇾'),
  _Country('Haiti', 'HT', '+509', '🇭🇹'),
  _Country('Honduras', 'HN', '+504', '🇭🇳'),
  _Country('Jamaica', 'JM', '+1', '🇯🇲'),
  _Country('Mexico', 'MX', '+52', '🇲🇽'),
  _Country('Nicaragua', 'NI', '+505', '🇳🇮'),
  _Country('Panama', 'PA', '+507', '🇵🇦'),
  _Country('Paraguay', 'PY', '+595', '🇵🇾'),
  _Country('Peru', 'PE', '+51', '🇵🇪'),
  _Country('Suriname', 'SR', '+597', '🇸🇷'),
  _Country('Trinidad', 'TT', '+1', '🇹🇹'),
  _Country('United States', 'US', '+1', '🇺🇸'),
  _Country('Uruguay', 'UY', '+598', '🇺🇾'),
  _Country('Venezuela', 'VE', '+58', '🇻🇪'),
  // Asia
  _Country('Afghanistan', 'AF', '+93', '🇦🇫'),
  _Country('Bangladesh', 'BD', '+880', '🇧🇩'),
  _Country('Cambodia', 'KH', '+855', '🇰🇭'),
  _Country('China', 'CN', '+86', '🇨🇳'),
  _Country('Hong Kong', 'HK', '+852', '🇭🇰'),
  _Country('India', 'IN', '+91', '🇮🇳'),
  _Country('Indonesia', 'ID', '+62', '🇮🇩'),
  _Country('Iran', 'IR', '+98', '🇮🇷'),
  _Country('Iraq', 'IQ', '+964', '🇮🇶'),
  _Country('Israel', 'IL', '+972', '🇮🇱'),
  _Country('Japan', 'JP', '+81', '🇯🇵'),
  _Country('Jordan', 'JO', '+962', '🇯🇴'),
  _Country('Kazakhstan', 'KZ', '+7', '🇰🇿'),
  _Country('Kuwait', 'KW', '+965', '🇰🇼'),
  _Country('Laos', 'LA', '+856', '🇱🇦'),
  _Country('Lebanon', 'LB', '+961', '🇱🇧'),
  _Country('Malaysia', 'MY', '+60', '🇲🇾'),
  _Country('Maldives', 'MV', '+960', '🇲🇻'),
  _Country('Mongolia', 'MN', '+976', '🇲🇳'),
  _Country('Myanmar', 'MM', '+95', '🇲🇲'),
  _Country('Nepal', 'NP', '+977', '🇳🇵'),
  _Country('North Korea', 'KP', '+850', '🇰🇵'),
  _Country('Oman', 'OM', '+968', '🇴🇲'),
  _Country('Pakistan', 'PK', '+92', '🇵🇰'),
  _Country('Palestine', 'PS', '+970', '🇵🇸'),
  _Country('Philippines', 'PH', '+63', '🇵🇭'),
  _Country('Qatar', 'QA', '+974', '🇶🇦'),
  _Country('Russia', 'RU', '+7', '🇷🇺'),
  _Country('Saudi Arabia', 'SA', '+966', '🇸🇦'),
  _Country('Singapore', 'SG', '+65', '🇸🇬'),
  _Country('South Korea', 'KR', '+82', '🇰🇷'),
  _Country('Sri Lanka', 'LK', '+94', '🇱🇰'),
  _Country('Syria', 'SY', '+963', '🇸🇾'),
  _Country('Taiwan', 'TW', '+886', '🇹🇼'),
  _Country('Tajikistan', 'TJ', '+992', '🇹🇯'),
  _Country('Thailand', 'TH', '+66', '🇹🇭'),
  _Country('Timor-Leste', 'TL', '+670', '🇹🇱'),
  _Country('Turkey', 'TR', '+90', '🇹🇷'),
  _Country('Turkmenistan', 'TM', '+993', '🇹🇲'),
  _Country('UAE', 'AE', '+971', '🇦🇪'),
  _Country('Uzbekistan', 'UZ', '+998', '🇺🇿'),
  _Country('Vietnam', 'VN', '+84', '🇻🇳'),
  _Country('Yemen', 'YE', '+967', '🇾🇪'),
  // Europe
  _Country('Albania', 'AL', '+355', '🇦🇱'),
  _Country('Austria', 'AT', '+43', '🇦🇹'),
  _Country('Belarus', 'BY', '+375', '🇧🇾'),
  _Country('Belgium', 'BE', '+32', '🇧🇪'),
  _Country('Bosnia', 'BA', '+387', '🇧🇦'),
  _Country('Bulgaria', 'BG', '+359', '🇧🇬'),
  _Country('Croatia', 'HR', '+385', '🇭🇷'),
  _Country('Cyprus', 'CY', '+357', '🇨🇾'),
  _Country('Czech Republic', 'CZ', '+420', '🇨🇿'),
  _Country('Denmark', 'DK', '+45', '��'),
  _Country('Estonia', 'EE', '+372', '🇪🇪'),
  _Country('Finland', 'FI', '+358', '🇫🇮'),
  _Country('France', 'FR', '+33', '🇫🇷'),
  _Country('Germany', 'DE', '+49', '🇩🇪'),
  _Country('Greece', 'GR', '+30', '🇬🇷'),
  _Country('Hungary', 'HU', '+36', '🇭🇺'),
  _Country('Iceland', 'IS', '+354', '🇮🇸'),
  _Country('Ireland', 'IE', '+353', '🇮🇪'),
  _Country('Italy', 'IT', '+39', '🇮🇹'),
  _Country('Latvia', 'LV', '+371', '🇱🇻'),
  _Country('Lithuania', 'LT', '+370', '🇱🇹'),
  _Country('Luxembourg', 'LU', '+352', '🇱🇺'),
  _Country('Malta', 'MT', '+356', '🇲🇹'),
  _Country('Moldova', 'MD', '+373', '🇲🇩'),
  _Country('Montenegro', 'ME', '+382', '🇲�'),
  _Country('Netherlands', 'NL', '+31', '🇳🇱'),
  _Country('North Macedonia', 'MK', '+389', '🇲�'),
  _Country('Norway', 'NO', '+47', '🇳🇴'),
  _Country('Poland', 'PL', '+48', '🇵🇱'),
  _Country('Portugal', 'PT', '+351', '🇵🇹'),
  _Country('Romania', 'RO', '+40', '🇷🇴'),
  _Country('Serbia', 'RS', '+381', '🇷🇸'),
  _Country('Slovakia', 'SK', '+421', '🇸🇰'),
  _Country('Slovenia', 'SI', '+386', '🇸�'),
  _Country('Spain', 'ES', '+34', '🇪🇸'),
  _Country('Sweden', 'SE', '+46', '🇸🇪'),
  _Country('Switzerland', 'CH', '+41', '🇨🇭'),
  _Country('Ukraine', 'UA', '+380', '🇺🇦'),
  _Country('United Kingdom', 'GB', '+44', '🇬🇧'),
  // Oceania
  _Country('Australia', 'AU', '+61', '🇦🇺'),
  _Country('Fiji', 'FJ', '+679', '🇫🇯'),
  _Country('New Zealand', 'NZ', '+64', '🇳🇿'),
  _Country('Papua New Guinea', 'PG', '+675', '��'),
];

class PhoneCollectionScreen extends ConsumerStatefulWidget {
  const PhoneCollectionScreen({super.key});

  @override
  _PhoneCollectionScreenState createState() => _PhoneCollectionScreenState();
}

class _PhoneCollectionScreenState extends ConsumerState<PhoneCollectionScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _skipping = false;
  _Country _selectedCountry = _countries.firstWhere((c) => c.code == 'RW');

  // Theme-aware getters
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _backgroundColor => _isDark ? const Color(0xFF0F172A) : const Color(0xFF00C896);
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF1A2433);
  Color get _secondaryTextColor => _isDark ? Colors.white70 : const Color(0xFF8899AA);
  Color get _borderColor => _isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get _inputBgColor => _isDark ? const Color(0xFF0F172A) : Colors.white;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    return PhoneValidator.validatePhone(value);
  }

  void _showCountryPicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: _borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.selectCountry ?? 'Select Country',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _textColor),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: _textColor),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _countries.length,
                    itemBuilder: (context, index) {
                      final country = _countries[index];
                      final isSelected = country.code == _selectedCountry.code;
                      return ListTile(
                        leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(country.name, style: TextStyle(color: _textColor)),
                        subtitle: Text(country.dialCode, style: TextStyle(color: _secondaryTextColor)),
                        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00C896)) : null,
                        onTap: () {
                          debugPrint('DEBUG: Country selected: ${country.name} (${country.dialCode})');
                          setState(() => _selectedCountry = country);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePhoneNumber() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String phoneNumber = _phoneController.text.trim();
      
      debugPrint('DEBUG: Selected country: ${_selectedCountry.name} (${_selectedCountry.dialCode})');
      debugPrint('DEBUG: Original phone input: "$phoneNumber"');
      
      // If user didn't include country code, prepend the selected one
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '${_selectedCountry.dialCode}$phoneNumber';
        debugPrint('DEBUG: Phone after adding country code: "$phoneNumber"');
      }
      
      final formattedPhone = PhoneValidator.formatPhoneNumber(phoneNumber);
      debugPrint('DEBUG: Final formatted phone: "$formattedPhone"');
      await ref.read(authProvider.notifier).updateProfile(
        phone: formattedPhone,
        hasCompletedOnboarding: true,
      );
      _skipping = true; // this method handles navigation from here

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number saved successfully!'),
            backgroundColor: Color(0xFF00C896),
          ),
        );
        
        // Check if user has enrolled courses before navigating
        try {
          final enrolledCourses = await ref.read(enrolledCoursesProvider.future);
          if (enrolledCourses.isEmpty) {
            context.go('/courses');
          } else {
            context.go('/dashboard');
          }
        } catch (e) {
          debugPrint('Error checking enrolled courses: $e');
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving phone number: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);

    // Skip if user already has a phone number (given at registration or via
    // phone sign-in). Not while saving — _savePhoneNumber navigates itself.
    final user = authState.user;
    if (user != null && userHasPhone(user) && !_isLoading) {
      if (!_skipping) {
        _skipping = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (!user.hasCompletedOnboarding) await markOnboardingComplete(ref);
          if (mounted) await goHome(context, ref);
        });
      }
      return const SizedBox.shrink();
    }

    if (isDesktop) {
      return Scaffold(
        backgroundColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        body: _buildDesktopLayout(l10n),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (context.canPop())
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back_ios_rounded, color: _isDark ? Colors.white : Colors.white),
                    ),
                  const Spacer(),
                ],
              ),
            ),

            // Logo/Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              l10n?.phoneCollectionTitle ?? 'Add Your Phone Number',
              style: TextStyle(
                color: _isDark ? Colors.white : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              l10n?.phoneCollectionSubtitle ?? 'Stay connected for important updates',
              style: TextStyle(color: _isDark ? Colors.white70 : Colors.white70, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Card
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhoneForm(l10n),
                      const SizedBox(height: 24),
                      _buildSaveButton(l10n),
                      const SizedBox(height: 16),
                      _buildSkipButton(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm(AppLocalizations? l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country selector
          Text(
            l10n?.selectCountry ?? 'Country',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: _inputBgColor,
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            child: InkWell(
              onTap: _isLoading ? null : () {
                debugPrint('Country picker tapped');
                _showCountryPicker();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor, width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(_selectedCountry.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Text(_selectedCountry.dialCode, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: _textColor)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedCountry.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: _textColor),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: _secondaryTextColor, size: 28),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n?.phoneNumber ?? 'Phone Number',
            style: TextStyle(
              color: _textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: _inputBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1.5),
              boxShadow: _isDark ? [] : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: _phoneController,
              enabled: !_isLoading,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: _textColor, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g., ${_selectedCountry.dialCode == '+7' ? '938288834' : '938288834'} (without ${_selectedCountry.dialCode})',
                hintStyle: TextStyle(color: _secondaryTextColor),
                prefixIcon: Icon(Icons.phone_rounded, color: _secondaryTextColor),
                prefixText: '${_selectedCountry.dialCode} ',
                prefixStyle: TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.w500),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: _validatePhone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _savePhoneNumber(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your number without the country code${_selectedCountry.dialCode == '+7' ? ' (10 digits required)' : ''}',
            style: TextStyle(color: _secondaryTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppLocalizations? l10n) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C896), Color(0xFF009E76)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: const Color(0xFF00C896).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
        ),
        child: InkWell(
          onTap: _isLoading ? null : _savePhoneNumber,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _isLoading
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(l10n?.continueToDashboard ?? 'Save Phone Number', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(AppLocalizations? l10n) {
    return TextButton(
      onPressed: _isLoading ? null : () async {
        // Skip phone collection and complete onboarding
        try {
          await ref.read(authProvider.notifier).updateProfile(
            hasCompletedOnboarding: true,
          );
          if (mounted) {
            // Check if user has enrolled courses
            try {
              final enrolledCourses = await ref.read(enrolledCoursesProvider.future);
              if (enrolledCourses.isEmpty) {
                context.go('/courses');
              } else {
                context.go('/dashboard');
              }
            } catch (e) {
              debugPrint('Error checking enrolled courses: $e');
              context.go('/dashboard');
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Text(
        l10n?.skipForNow ?? 'Skip for now',
        style: TextStyle(color: _secondaryTextColor, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // ─── Desktop layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(AppLocalizations? l10n) {
    return Row(
      children: [
        // Left branding panel (42%)
        const Expanded(
          flex: 42,
          child: DesktopBrandPanel(
            headline: 'Secure Your',
            title: 'Account',
            tagline: 'Add your phone number for enhanced security and important updates.',
          ),
        ),
        // Right content panel (58%)
        Expanded(
          flex: 58,
          child: _buildDesktopRightPanel(l10n),
        ),
      ],
    );
  }

  Widget _buildDesktopRightPanel(AppLocalizations? l10n) {
    return Scaffold(
      backgroundColor: _isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.phoneCollectionTitle ?? 'Add Phone Number',
                              style: TextStyle(
                                color: _textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n?.phoneCollectionSubtitle ?? 'This helps secure your account',
                              style: TextStyle(
                                color: _secondaryTextColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Form card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor, width: 1),
                    boxShadow: _isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPhoneForm(l10n),
                      const SizedBox(height: 24),
                      _buildSaveButton(l10n),
                      const SizedBox(height: 16),
                      _buildSkipButton(l10n),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
