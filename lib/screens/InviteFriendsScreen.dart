import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../model/PassengerReferralModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

class InviteFriendsScreen extends StatefulWidget {
  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  PassengerReferralStatsModel? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final value = await getPassengerReferralStats();
      if (!mounted) return;
      setState(() {
        stats = value;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      toast(e.toString());
    }
  }

  Future<void> _share() async {
    final code = stats?.referralCode.validate() ?? '';
    final link = stats?.shareLink.validate() ?? '';
    final welcome = stats?.welcomeBonusAmount ?? 5;

    // Solo beneficio del invitado. No mencionar recompensa del invitador (obs. Rolando).
    final text = '¡Únete a Zigo con mi código $code!\n'
        'Recibe S/$welcome en tu primer viaje.\n'
        'Link: $link';

    await Share.share(text, subject: 'Invita y gana con Zigo');
  }

  Future<void> _copyCode() async {
    final code = stats?.referralCode.validate() ?? '';
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    toast('Código copiado: $code');
  }

  Future<void> _copyLink() async {
    final link = stats?.shareLink.validate() ?? '';
    if (link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    toast('Link copiado');
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'completed':
        return 'Completó 1er viaje';
      case 'pending':
        return 'Pendiente de 1er viaje';
      case 'rejected':
        return 'Rechazado';
      default:
        return status.validate();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'completed':
        return neonAccent;
      case 'pending':
        return neonHighlight;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final needed = stats?.referralsNeeded ?? 3;
    final progress = stats?.progressInCycle ?? 0;
    final completed = stats?.completedReferrals ?? 0;
    final remaining = stats?.remainingForNextReward ?? needed;
    final welcome = stats?.welcomeBonusAmount ?? 5;
    final maxFree = stats?.freeRideMaxDiscount ?? 15;

    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        iconTheme: IconThemeData(color: neonAccent),
        title: Text('Invita y gana', style: boldTextStyle(color: neonHighlight)),
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            if (!loading && stats != null)
              RefreshIndicator(
                onRefresh: _load,
                color: neonAccent,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: neonSurfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: neonAccent.withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tu código de invitación', style: secondaryTextStyle(color: neonHighlight)),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    stats!.referralCode.validate(),
                                    style: boldTextStyle(size: 28, color: neonAccent),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _copyCode,
                                  icon: Icon(Icons.copy, color: neonHighlight),
                                  tooltip: 'Copiar código',
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              stats!.shareLink.validate(),
                              style: secondaryTextStyle(color: Colors.white70, size: 12),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _copyLink,
                                child: Text('Copiar link', style: boldTextStyle(color: neonAccent, size: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: neonSurfaceCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cómo funciona', style: boldTextStyle(color: neonHighlight)),
                            SizedBox(height: 10),
                            Text('1. Comparte tu código o link con amigos.', style: primaryTextStyle(color: Colors.white70, size: 13)),
                            SizedBox(height: 6),
                            Text('2. Ellos reciben S/$welcome en su primer viaje.', style: primaryTextStyle(color: Colors.white70, size: 13)),
                            SizedBox(height: 6),
                            Text('3. Por cada $needed amigos que completen su 1er viaje, ganas 1 viaje gratis (hasta S/$maxFree).',
                                style: primaryTextStyle(color: Colors.white70, size: 13)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: neonSurfaceCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tu progreso', style: boldTextStyle(color: neonHighlight)),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(needed, (index) {
                                final filled = index < progress;
                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: filled ? neonAccent : neonAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 12),
                            Text(
                              progress == 0 && completed > 0
                                  ? '¡Completaste un ciclo! Empieza el siguiente ($needed amigos más).'
                                  : '$progress / $needed  ·  Te faltan $remaining para tu próximo viaje gratis',
                              style: primaryTextStyle(color: Colors.white, size: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Válidos: $completed  ·  Pendientes: ${stats!.pendingReferrals ?? 0}',
                              style: secondaryTextStyle(color: Colors.white54, size: 12),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      AppButtonWidget(
                        width: MediaQuery.of(context).size.width,
                        text: 'Compartir por WhatsApp',
                        onTap: _share,
                      ),
                      SizedBox(height: 24),
                      Text('Mis referidos', style: boldTextStyle(color: neonHighlight)),
                      SizedBox(height: 8),
                      if ((stats!.referrals ?? []).isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text('Aún no has invitado a nadie', style: secondaryTextStyle(color: Colors.white54)),
                          ),
                        )
                      else
                        ...stats!.referrals!.map((item) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: neonSurfaceCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, color: neonAccent),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name.validate(value: 'Amigo'), style: boldTextStyle(color: Colors.white, size: 14)),
                                      SizedBox(height: 2),
                                      Text(_statusLabel(item.status), style: secondaryTextStyle(color: _statusColor(item.status), size: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      if ((stats!.rewards ?? []).isNotEmpty) ...[
                        SizedBox(height: 16),
                        Text('Premios obtenidos', style: boldTextStyle(color: neonHighlight)),
                        SizedBox(height: 8),
                        ...stats!.rewards!.map((r) {
                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: neonSurfaceCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.card_giftcard, color: neonAccent),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.rewardType == 'welcome_bonus' ? 'Bono bienvenida' : 'Viaje gratis #${r.milestone ?? ''}',
                                        style: boldTextStyle(color: Colors.white, size: 14),
                                      ),
                                      if (r.couponCode.validate().isNotEmpty)
                                        Text('Cupón: ${r.couponCode}', style: secondaryTextStyle(color: neonHighlight, size: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            if (loading || appStore.isLoading) loaderWidget(),
            if (!loading && stats == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No se pudo cargar la info de referidos', style: primaryTextStyle(color: Colors.white70)),
                    SizedBox(height: 12),
                    AppButtonWidget(text: 'Reintentar', onTap: _load),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}
