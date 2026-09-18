import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/circle_icon_button.dart';
import '../../../core/widget/primary_button.dart';
import '../../../core/widget/progress_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../preferences/cubit/profile_cubit.dart';
import '../cubit/onboarding_cubit.dart';
import '../model/onboarding_step.dart';
import '../widget/rating_modal.dart';
import '../widget/steps/language_step.dart';
import '../widget/steps/options_step.dart';
import '../widget/steps/simple_steps.dart';
import '../widget/steps/welcome_step.dart';
import 'generating_screen.dart';

/// Hosts the whole pre-app experience: questions, the rating prompt and the
/// plan-generation screen.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      // Persisting the profile is what ends onboarding, so listen for `done`.
      listenWhen: (previous, current) =>
          previous.phase != current.phase && current.phase == OnboardingPhase.done,
      listener: (context, state) =>
          context.read<ProfileCubit>().completeOnboarding(state.draft),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: SafeArea(
            child: Stack(
              children: [
                switch (state.phase) {
                  OnboardingPhase.generating || OnboardingPhase.done => GeneratingScreen(
                      displayName: state.draft.displayName(AppL10n.of(context).defaultChefName),
                      generationStep: state.generationStep,
                      onSkip: context.read<OnboardingCubit>().finishGeneration,
                      onBack: context.read<OnboardingCubit>().back,
                    ),
                  _ => _StepsView(state: state),
                },
                if (state.phase == OnboardingPhase.rating)
                  Positioned.fill(
                    child: RatingModal(onDismiss: context.read<OnboardingCubit>().dismissRating),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The scrolling question flow, with the shared top bar and continue button.
class _StepsView extends StatelessWidget {
  const _StepsView({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final l10n = AppL10n.of(context);
    final step = state.currentStep;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 14.h, 24.w, 22.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (step.showTopBar) _TopBar(step: step, onBack: cubit.back),
                    Expanded(child: _stepBody(context, cubit, step)),
                    if (step.showContinueButton) ...[
                      SizedBox(height: 16.h),
                      PrimaryButton(
                        label: step.continueLabelOverride == 'generate'
                            ? l10n.actionGeneratePlan
                            : l10n.actionContinue,
                        onPressed: cubit.next,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stepBody(BuildContext context, OnboardingCubit cubit, OnboardingStep step) {
    final l10n = AppL10n.of(context);
    return switch (step.kind) {
      StepKind.language => LanguageStep(
          onSelected: (code) {
            cubit.setLanguage(code);
            cubit.next();
          },
        ),
      StepKind.welcome => WelcomeStep(
          onBack: cubit.back,
          onNext: cubit.next,
          storeName: state.draft.store,
        ),
      StepKind.text => NameStep(initialValue: state.draft.name, onChanged: cubit.setName),
      StepKind.options => OptionsStep(
          step: step,
          isSelected: (optionId) => cubit.isSelected(step.id, optionId),
          // The store grid advances on tap; every other options step waits for
          // the continue button so multi-select stays possible.
          onSelect: step.id == StepIds.store ? cubit.selectAndAdvance : cubit.select,
        ),
      StepKind.counter => CounterStep(
          count: state.draft.household,
          onIncrement: cubit.incrementHousehold,
          onDecrement: cubit.decrementHousehold,
        ),
      StepKind.days => DaysStep(selected: state.draft.days, onToggle: cubit.toggleDay),
      StepKind.slider => BudgetStep(
          budget: state.draft.budget,
          minBudget: OnboardingCubit.minBudget,
          maxBudget: OnboardingCubit.maxBudget,
          country: state.draft.country,
          onChanged: cubit.setBudget,
        ),
      StepKind.info => InfoStep(
          emoji: '👨‍🍳',
          title: l10n.onbInfoPlanningTitle,
          subtitle: l10n.onbInfoPlanningSubtitle,
        ),
      StepKind.infoBars => const InfoBarsStep(),
      StepKind.infoMoney => InfoMoneyStep(country: state.draft.country),
      StepKind.testimonial => const TestimonialStep(),
    };
  }
}

/// Back arrow plus the progress track.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});

  final OnboardingStep step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 26.h),
      child: Row(
        children: [
          CircleIconButton(glyph: '←', onPressed: onBack),
          if (step.showProgress) ...[
            SizedBox(width: 16.w),
            Expanded(child: ProgressBar(value: step.progress! / 100)),
          ],
        ],
      ),
    );
  }
}
