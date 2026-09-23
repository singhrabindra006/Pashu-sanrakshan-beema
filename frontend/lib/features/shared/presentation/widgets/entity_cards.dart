import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/media/cached_image.dart';
import '../../../../core/widgets/status/status_chip.dart';
import '../../data/models/animal_model.dart';
import '../../data/models/application_model.dart';
import '../../data/models/claim_model.dart';
import '../../data/models/farmer_model.dart';
import '../../data/models/scheme_model.dart';

/// Row on AnimalListPage and inside AdminFarmerDetailPage.
class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal, this.onTap, this.onEdit, this.onDeactivate, this.onPhotoTap});

  final AnimalModel animal;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback? onPhotoTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GestureDetector(
                onTap: onPhotoTap,
                child: CachedImage(
                  url: animal.photoUrl,
                  width: 68,
                  height: 68,
                  fallbackIcon: Icons.pets_outlined,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            animal.earTag,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        StatusChip(status: animal.isActive ? 'ACTIVE' : 'INACTIVE', compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${animal.animalType.label}${animal.breed == null ? '' : ' - ${animal.breed}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Age ${DateFormatter.monthsToAge(animal.ageMonths)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (animal.hasActiveApplication)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Insurance in progress',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onEdit != null || onDeactivate != null)
                PopupMenuButton<String>(
                  tooltip: 'Actions',
                  onSelected: (value) => value == 'edit' ? onEdit?.call() : onDeactivate?.call(),
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                    if (onDeactivate != null && animal.isActive)
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.block_outlined),
                          title: Text('Deactivate'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row on SchemeListPage and AdminSchemeListPage.
class SchemeCard extends StatelessWidget {
  const SchemeCard({super.key, required this.scheme, this.onTap, this.onEdit, this.onToggle, this.showStatus = false});

  final SchemeModel scheme;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final scheme_ = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (showStatus) StatusChip(status: scheme.statusLabel, compact: true),
                  if (onEdit != null || onToggle != null)
                    PopupMenuButton<String>(
                      onSelected: (value) => value == 'edit' ? onEdit?.call() : onToggle?.call(),
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                        if (onToggle != null)
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(scheme.isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined),
                              title: Text(scheme.isActive ? 'Deactivate' : 'Activate'),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              if (!scheme.description.isNullOrBlank) ...[
                const SizedBox(height: 6),
                Text(
                  scheme.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme_.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _IconLabel(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'Up to ${DateFormatter.currency(scheme.maxCoverage)}',
                  ),
                  _IconLabel(
                    icon: Icons.event_outlined,
                    text: DateFormatter.range(scheme.startDate, scheme.endDate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row on ApplicationListPage and AdminApplicationListPage.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.application, this.onTap, this.showFarmer = false});

  final ApplicationModel application;
  final VoidCallback? onTap;
  final bool showFarmer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.applicationNumber,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: application.status.value, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              if (showFarmer) _IconLabel(icon: Icons.person_outline, text: application.farmerName),
              _IconLabel(
                icon: Icons.pets_outlined,
                text: '${application.animalEarTag} - ${application.animalType.label}',
              ),
              _IconLabel(icon: Icons.policy_outlined, text: application.schemeName),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormatter.currency(application.coverageAmount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    DateFormatter.relative(application.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (application.isApproved && application.policyNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _IconLabel(icon: Icons.verified_outlined, text: 'Policy ${application.policyNumber}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row on ClaimListPage and AdminClaimListPage.
class ClaimCard extends StatelessWidget {
  const ClaimCard({super.key, required this.claim, this.onTap, this.showFarmer = false});

  final ClaimModel claim;
  final VoidCallback? onTap;
  final bool showFarmer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.claimNumber,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusChip(status: claim.status.value, compact: true),
                ],
              ),
              const SizedBox(height: 8),
              if (showFarmer) _IconLabel(icon: Icons.person_outline, text: claim.farmerName),
              _IconLabel(icon: Icons.report_problem_outlined, text: claim.incidentType.label),
              _IconLabel(icon: Icons.event_outlined, text: DateFormatter.displayRaw(claim.incidentDate)),
              _IconLabel(icon: Icons.pets_outlined, text: claim.animalEarTag),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Claimed ${DateFormatter.currency(claim.claimedAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (claim.approvedAmount != null)
                    Text(
                      'Paid ${DateFormatter.currency(claim.approvedAmount)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row on AdminFarmerListPage.
class FarmerCard extends StatelessWidget {
  const FarmerCard({super.key, required this.farmer, this.onTap, this.onToggle});

  final FarmerModel farmer;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              UserAvatar(imageUrl: farmer.imageUrl, name: farmer.fullName, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      farmer.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (!farmer.phone.isNullOrBlank)
                      Text(
                        farmer.phone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '${farmer.animalCount} animals · ${farmer.applicationCount} apps · ${farmer.claimCount} claims',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StatusChip(status: farmer.isActive ? 'ACTIVE' : 'INACTIVE', compact: true),
                  if (onToggle != null)
                    IconButton(
                      tooltip: farmer.isActive ? 'Deactivate' : 'Activate',
                      icon: Icon(farmer.isActive ? Icons.toggle_on : Icons.toggle_off_outlined),
                      onPressed: onToggle,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
