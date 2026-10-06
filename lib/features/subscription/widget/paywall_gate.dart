import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/util/haptics.dart';
import '../../../core/widget/loading_view.dart';
import '../cubit/subscription_cubit.dart';

/// Hard paywall in front of the app. A user without access still sees [child],
/// but every tap lands on the paywall instead, so closing it never unlocks
/// anything. Admin and creator accounts pass straight through.
class PaywallGate extends StatefulWidget {
  const PaywallGate({super.key, required this.child});

  final Widget child;

  @override
  State<PaywallGate> createState() => _PaywallGateState();
}

class _PaywallGateState extends State<PaywallGate> {
  @override
  void initState() {
    super.initState();
    // The listener only sees changes, so a state already resolved on mount —
    // the usual case on launch — is handled here, once the frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SubscriptionCubit>();
      if (cubit.state.isResolved) cubit.presentPaywall();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SubscriptionCubit, SubscriptionState>(
      // Present once the gate first resolves, and again whenever access is lost.
      listenWhen: (previous, current) =>
          (!previous.isResolved && current.isResolved) ||
          (current.isResolved && previous.hasAccess && !current.hasAccess),
      listener: (context, state) => context.read<SubscriptionCubit>().presentPaywall(),
      buildWhen: (previous, current) =>
          previous.isResolved != current.isResolved || previous.hasAccess != current.hasAccess,
      builder: (context, state) {
        if (!state.isResolved) return const LoadingView();
        if (state.hasAccess) return widget.child;
        return Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Haptics.tap();
                  context.read<SubscriptionCubit>().presentPaywall();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
