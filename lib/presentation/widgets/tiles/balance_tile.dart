import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';


class BalanceTile extends StatelessWidget {

  final Balance balance;
  final String? role;

  const BalanceTile({
    super.key,
    required this.role,
    required this.balance
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = balance.total < 0 ? colors.error : Colors.green.shade700;

    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
            padding: const EdgeInsets.all(4.0),
            child:  ListTile(
              title: Text(
                  balance.currency,
                  style: TextStyle(
                      color: color,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
              subtitle: _getSubtitle(color),
              trailing: _buildBalanceInfo(color)
            )
        )
    );

  }

  Widget _buildBalanceInfo(Color color) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
              balance.balanceToString('D'),
              style: TextStyle(
                  color: color,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold
              )),
          const SizedBox(height: 4),
          Text(
              balance.balanceToString('C'),
              style: TextStyle(
                  color: color,
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold
              ))
        ]
    );
  }

  Widget? _getSubtitle(Color? color) {
    if (role == ApiRole.manager) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                balance.partnerName,
                style: TextStyle(
                    color: color,
                    fontSize: 16.0,
                    fontWeight: FontWeight.normal),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
            Text(
                balance.totalToString(),
                style: TextStyle(
                    color: color,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold))
          ]
      );
    } else if (role == ApiRole.delivery) {
      return Text(
          balance.totalToString(),
          style: TextStyle(
              color: color,
              fontSize: 16.0,
              fontWeight: FontWeight.bold));
    }

    return null;
  }
}
