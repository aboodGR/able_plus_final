import 'package:ableplusproject/providers/Post_provider.dart';
import 'package:ableplusproject/providers/businesses_provider.dart';
import 'package:ableplusproject/providers/places_provider.dart';
import 'package:ableplusproject/providers/vip_provider.dart';
import 'package:ableplusproject/theme/app_theme.dart';
import 'package:ableplusproject/widgets/AbleScaffold.dart';
import 'package:ableplusproject/widgets/VipBadge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

String _vipText(BuildContext context, String en, String ar) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class VipMembershipScreen extends ConsumerWidget {
  const VipMembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(viewerProvider).valueOrNull;
    if (viewer != null && viewer.role == 'client') {
      return AbleScaffold(
        title: 'VIP',
        showBackButton: true,
        body: Center(
          child: Text(_vipText(context, 'VIP is available to service providers only.',
              'عضوية VIP متاحة لمزودي الخدمات فقط.')),
        ),
      );
    }
    final status = ref.watch(currentVipStatusProvider).valueOrNull;
    return AbleScaffold(
      title: _vipText(context, 'VIP Membership', 'عضوية VIP'),
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF302104), Color(0xFF7A5100), Color(0xFFD99A16)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VipBadge(),
                const SizedBox(height: 14),
                Text(
                  _vipText(context, 'Stand out with premium visibility',
                      'تميّز بظهور مميز ومحتوى ذهبي'),
                  style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  _vipText(context, '2 JOD for 30 days • Presentation demo payment only',
                      '2 دينار لمدة 30 يومًا • دفع تجريبي للعرض فقط'),
                  style: TextStyle(color: Colors.white.withOpacity(.82), height: 1.4),
                ),
                if (status != null) ...[
                  const SizedBox(height: 15),
                  Text(
                    _vipText(context, 'Active until ${_date(status.expiresAt)}',
                        'فعالة حتى ${_date(status.expiresAt)}'),
                    style: const TextStyle(color: Color(0xFFFFE690), fontWeight: FontWeight.w800),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _Benefit(icon: Icons.auto_awesome_rounded, title: _vipText(context, 'Gold premium styling', 'مظهر ذهبي مميز'), body: _vipText(context, 'Your profile and content receive a clear VIP presentation.', 'يحصل ملفك ومحتواك على مظهر VIP واضح.')),
          _Benefit(icon: Icons.verified_rounded, title: _vipText(context, 'VIP badge', 'شارة VIP'), body: _vipText(context, 'A badge appears where your provider identity is shown.', 'تظهر الشارة عند عرض هوية مزود الخدمة.')),
          _Benefit(icon: Icons.trending_up_rounded, title: _vipText(context, 'Higher visibility', 'ظهور أعلى'), body: _vipText(context, 'Active VIP posts and provider cards appear before normal items.', 'تظهر منشورات وبطاقات VIP الفعالة قبل العناصر العادية.')),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/home/vip/payment'),
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(_vipText(context,
                status == null ? 'Upgrade to VIP — 2 JOD / 30 days' : 'Renew VIP — add 30 days',
                status == null ? 'الترقية إلى VIP — 2 دينار / 30 يومًا' : 'تجديد VIP — إضافة 30 يومًا')),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: const Color(0xFFD99A16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AbleTheme.glassCard(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AbleTheme.glassBorder(context)),
          ),
          child: Row(children: [
            Icon(icon, color: const Color(0xFFD99A16)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(body, style: TextStyle(color: AbleTheme.textMuted(context), fontSize: 13)),
            ])),
          ]),
        ),
      );
}

class VipDemoPaymentScreen extends ConsumerStatefulWidget {
  const VipDemoPaymentScreen({super.key});
  @override
  ConsumerState<VipDemoPaymentScreen> createState() => _VipDemoPaymentScreenState();
}

class _VipDemoPaymentScreenState extends ConsumerState<VipDemoPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holder = TextEditingController();
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _holder.dispose(); _number.dispose(); _expiry.dispose(); _cvv.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? _vipText(context, 'Required for the demo form.', 'مطلوب في النموذج التجريبي.') : null;

  String? _card(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length < 4 ? _vipText(context, 'Enter any 4+ fake digits.', 'أدخل أي 4 أرقام تجريبية أو أكثر.') : null;
  }

  Future<void> _pay() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // Deliberately do NOT send cardholder/card/CVV/expiry to Supabase.
      final result = await activateDemoVip();
      ref.invalidate(currentVipStatusProvider);
      ref.invalidate(activeVipProvidersProvider);
      ref.invalidate(postsProvider);
      ref.invalidate(charityPostsProvider);
      ref.invalidate(businessesProvider);
      ref.invalidate(tutorsProvider);
      ref.invalidate(placesProvider);
      if (!mounted) return;
      context.go('/home/vip/success', extra: result.expiresAt);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _vipText(context,
          'Could not activate VIP. Ask the project owner to run the VIP SQL migration, then retry.\n$e',
          'تعذر تفعيل VIP. اطلب تشغيل ترحيل SQL الخاص بـ VIP ثم أعد المحاولة.\n$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AbleScaffold(
        title: _vipText(context, 'Demo payment', 'الدفع التجريبي'),
        showBackButton: true,
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF4D0), borderRadius: BorderRadius.circular(16)),
                child: Text(_vipText(context,
                    'Graduation-project demo only. No real charge occurs and card fields are never stored or sent to the database.',
                    'هذا دفع تجريبي لمشروع التخرج فقط. لا يوجد خصم حقيقي ولا يتم حفظ أو إرسال بيانات البطاقة لقاعدة البيانات.'),
                    style: const TextStyle(color: Color(0xFF694500), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              _field(_holder, _vipText(context, 'Cardholder name', 'اسم حامل البطاقة'), validator: _required),
              _field(_number, _vipText(context, 'Visa / Mastercard number', 'رقم Visa / Mastercard'),
                  hint: '1324 1234', keyboard: TextInputType.number, validator: _card),
              Row(children: [
                Expanded(child: _field(_expiry, _vipText(context, 'Expiry', 'الانتهاء'), hint: '12/34', validator: _required)),
                const SizedBox(width: 12),
                Expanded(child: _field(_cvv, 'CVV', hint: '1234', keyboard: TextInputType.number, validator: _required)),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(.4))),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _pay,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(55), backgroundColor: const Color(0xFFD99A16)),
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_vipText(context, 'Pay 2 JOD (Demo)', 'ادفع 2 دينار (تجريبي)')),
              ),
            ],
          ),
        ),
      );

  Widget _field(TextEditingController controller, String label, {String? hint, TextInputType? keyboard, String? Function(String?)? validator}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: keyboard == TextInputType.number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9 /-]'))] : null,
          validator: validator,
          decoration: InputDecoration(labelText: label, hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
        ),
      );
}

class VipSuccessScreen extends StatelessWidget {
  const VipSuccessScreen({super.key, required this.expiresAt});
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) => AbleScaffold(
        title: 'VIP',
        showBackButton: true,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.workspace_premium_rounded, size: 84, color: Color(0xFFD99A16)),
              const SizedBox(height: 12),
              Text(_vipText(context, 'Congratulations! VIP is active.', 'تهانينا! عضوية VIP فعّالة.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              if (expiresAt != null)
                Text(_vipText(context, 'Expires on ${_date(expiresAt!)}', 'تنتهي في ${_date(expiresAt!)}'), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD99A16))),
              const SizedBox(height: 12),
              Text(_vipText(context, 'Your badge, gold content styling, and feed priority are now active.', 'أصبحت الشارة والمظهر الذهبي وأولوية الظهور فعالة الآن.'), textAlign: TextAlign.center),
              const SizedBox(height: 25),
              FilledButton(onPressed: () => context.go('/home'), child: Text(_vipText(context, 'Return home', 'العودة للرئيسية'))),
            ]),
          ),
        ),
      );
}

String _date(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
