import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/helpers/human_formats.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';


class BalanceTile extends StatelessWidget {

  final Balance balance;

  const BalanceTile({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = balance.amount < 0 ? colors.error : Colors.green.shade400;
    final textStyle = Theme.of(context).textTheme;

    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        balance.fullName,
                        style: textStyle.bodySmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold)
                    ),
                    Text(
                        balance.name,
                        style: textStyle.bodySmall?.copyWith(color: color)
                    )
                  ]
              ),

              Row(
                  children: [
                    Column(
                        children: [
                          Row(
                              children: [
                                const Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 16),
                                Text(
                                    ' Deb: ${HumanFormats.toAmount(balance.debit)}',
                                    style: textStyle.bodySmall?.copyWith(color: color)
                                )
                              ]
                          ),
                          Row(
                              children: [
                                const Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16),
                                Text(
                                    'Cred: ${HumanFormats.toAmount(balance.credit)}',
                                    style: textStyle.bodySmall?.copyWith(color: color)
                                )
                              ]
                          )
                        ]
                    ),

                    const SizedBox(width: 16),

                    Text(
                        HumanFormats.toAmount(balance.amount),
                        style: textStyle.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold)
                    )
                  ]
              )
            ]
        )
    );
  }

}
