import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pqrsmart/core/theme/app_colors.dart';
import 'package:pqrsmart/presentation/blocs/RequestBloc.dart';
import 'package:pqrsmart/presentation/blocs/UserBloc.dart';
import 'package:pqrsmart/presentation/states/RequestEvent.dart';
import 'package:pqrsmart/presentation/states/RequestState.dart';
import 'package:pqrsmart/presentation/states/UserSatate.dart';
import 'package:pqrsmart/presentation/widgets/geo_dashboard_panels.dart';

// ==========================================
// DASHBOARD ADMINISTRATIVO - MAPAS
// ==========================================
// Coloca el mapa territorial y el mapa de calor en una fila o columna adaptable.
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _heatmapRefresh = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Resumen del sistema',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Indicadores cargados desde los servicios disponibles.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _registerAssistedRequest,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Registrar solicitud presencial'),
              ),
            ),
            const SizedBox(height: 12),
            _Statistics(wide: wide),
            const SizedBox(height: 22),
            const Text(
              'Información geográfica',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TerritoryMapPanel()),
                  SizedBox(width: 14),
                  Expanded(child: HeatmapPanel(key: ValueKey(_heatmapRefresh))),
                ],
              )
            else ...[
              const TerritoryMapPanel(),
              const SizedBox(height: 14),
              HeatmapPanel(key: ValueKey(_heatmapRefresh)),
            ],
          ],
        );
      },
    ),
  );

  Future<void> _registerAssistedRequest() async {
    final saved = await Navigator.pushNamed(context, '/newAssistedRequest');
    if (!mounted || saved != true) return;
    context.read<RequestBloc>().add(LoadAllRequestsEvent());
    setState(() => _heatmapRefresh++);
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final columns = wide ? 5 : 2;
    return BlocBuilder<RequestBloc, RequestState>(
      builder: (context, requestState) {
        final requests = requestState is RequestLoaded
            ? requestState.request
            : null;
        final total = requests?.length.toString() ?? '—';
        final pending = requests
            ?.where(
              (request) => (request.requestState?.nameRequestState ?? '')
                  .toUpperCase()
                  .contains('PEND'),
            )
            .length
            .toString();
        final inProgress = requests
            ?.where(
              (request) => (request.requestState?.nameRequestState ?? '')
                  .toUpperCase()
                  .contains('PROCESO'),
            )
            .length
            .toString();
        final attended = requests
            ?.where((request) {
              final status = (request.requestState?.nameRequestState ?? '')
                  .toUpperCase();
              return status.contains('ATEND') ||
                  status.contains('FINAL') ||
                  status.contains('RESUEL');
            })
            .length
            .toString();

        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            final users = userState is UserLoaded
                ? userState.user.length.toString()
                : '—';
            final stats = [
              _StatData('Solicitudes', total, Icons.description_outlined),
              _StatData('Pendientes', pending ?? '—', Icons.pending_actions),
              _StatData('En proceso', inProgress ?? '—', Icons.autorenew),
              _StatData('Atendidas', attended ?? '—', Icons.task_alt),
              _StatData('Usuarios', users, Icons.people_outline),
            ];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 100,
              ),
              itemBuilder: (context, index) => _StatCard(data: stats[index]),
            );
          },
        );
      },
    );
  }
}

class _StatData {
  const _StatData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: AppColors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(data.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
