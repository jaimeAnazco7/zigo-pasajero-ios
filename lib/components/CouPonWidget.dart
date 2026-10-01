import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Extensions/dataTypeExtensions.dart';
import '../model/CouponData.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class CouPonWidget extends StatefulWidget {
  @override
  CouPonWidgetState createState() => CouPonWidgetState();
}

class CouPonWidgetState extends State<CouPonWidget> {
  ScrollController scrollController = ScrollController();

  List<CouponData> couponData = [];
  int currentPage = 1;
  int totalPage = 1;

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (currentPage < totalPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});
          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  void init() async {
    await getCouponList(page: currentPage).then((value) {
      appStore.setLoading(false);
      currentPage = value.pagination!.currentPage!;
      totalPage = value.pagination!.totalPages!;
      if (currentPage == 1) {
        couponData.clear();
      }
      couponData.addAll(value.data!);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _discountLabel(CouponData data) {
    final discount = data.discount ?? 0;
    if (data.discountType == CHARGE_TYPE_FIXED) {
      return '${language.get} ${appStore.currencyCode} ${discount.toStringAsFixed(digitAfterDecimal)}';
    }
    final max = data.maximumDiscount ?? 0;
    if (max > 0) {
      return '${language.get} $discount% ${language.off} (máx. ${appStore.currencyCode} ${max.toStringAsFixed(0)})';
    }
    return '${language.get} $discount% ${language.off}';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Stack(
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: neonBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(defaultRadius),
                  topRight: Radius.circular(defaultRadius),
                ),
                border: Border(
                  top: BorderSide(color: neonAccent.withOpacity(0.35), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16, right: 4, top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(language.availableOffers, style: boldTextStyle(color: neonHighlight, size: 16)),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, size: 22, color: neonHighlight),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: neonAccent.withOpacity(0.22), height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      itemCount: couponData.length,
                      itemBuilder: (_, index) {
                        final CouponData data = couponData[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.pop(context, data.code.validate());
                            toast(language.copied);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: neonSurfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: neonAccent.withOpacity(0.35), width: 1),
                            ),
                            padding: EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: neonBackground,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: neonAccent.withOpacity(0.55)),
                                            ),
                                            child: Text(
                                              data.code.validate(),
                                              style: boldTextStyle(color: neonAccent, size: 15, letterSpacing: 0.6),
                                            ),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            data.title.validate(),
                                            style: boldTextStyle(color: Colors.white, size: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    MaterialButton(
                                      minWidth: 44,
                                      height: 44,
                                      elevation: 0,
                                      onPressed: () {
                                        Navigator.pop(context, data.code.validate());
                                        toast(language.copied);
                                      },
                                      color: neonAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      child: Icon(Icons.content_copy, size: 18, color: neonOnAccent),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _discountLabel(data),
                                  style: primaryTextStyle(color: neonAccent, size: 13, weight: FontWeight.w600),
                                ),
                                if (data.description.validate().isNotEmpty) ...[
                                  SizedBox(height: 6),
                                  Text(
                                    data.description.validate(),
                                    style: secondaryTextStyle(color: neonHighlight.withOpacity(0.85), size: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(height: 10),
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            ),
            if (!appStore.isLoading && couponData.isEmpty) emptyWidget(),
          ],
        );
      },
    );
  }
}
