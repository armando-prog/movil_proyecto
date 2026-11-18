import 'package:flutter/material.dart';

import '../data/database_service.dart';
import '../data/models.dart';
import 'components.dart';
import 'plant_form_page.dart';
import 'theme.dart';

class GardenShell extends StatefulWidget {
  const GardenShell({
    super.key,
    required this.user,
    required this.database,
    required this.onSignedOut,
    required this.onUserChanged,
  });

  final BroteUser user;
  final DatabaseService database;
  final Future<void> Function() onSignedOut;
  final ValueChanged<BroteUser> onUserChanged;

  @override
  State<GardenShell> createState() => _GardenShellState();
}

class _GardenShellState extends State<GardenShell> {
  int _tab = 0;
  List<Plant> _plants = [];
  List<CareLog> _logs = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final plants = await widget.database.getPlants(widget.user.id!);
      final logs = await widget.database.getCareLogs(widget.user.id!);
      if (mounted) {
        setState(() {
          _plants = plants;
          _logs = logs;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'No pudimos leer tus datos: $error';
        });
      }
    }
  }

  Future<void> _editPlant([Plant? plant]) async {
    final result = await Navigator.of(context).push<Plant>(
      MaterialPageRoute(
        builder: (_) => PlantFormPage(userId: widget.user.id!, plant: plant),
      ),
    );
    if (result == null) return;
    await widget.database.savePlant(result);
    await _refresh();
  }

  Future<void> _deletePlant(Plant plant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Retirar esta planta?'),
        content: Text(
          'Se eliminará la ficha de ${plant.name} y sus notas de cuidado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.database.deletePlant(plant);
    await _refresh();
  }

  Future<void> _water(Plant plant) async {
    await widget.database.waterPlant(plant);
    await _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plant.name} · riego guardado en la bitácora'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addJournalNote() async {
    if (_plants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade una planta para iniciar la bitácora.'),
        ),
      );
      return;
    }
    final result = await showModalBottomSheet<_JournalEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _JournalEntrySheet(plants: _plants),
    );
    if (result == null) return;
    await widget.database.addCareLog(
      userId: widget.user.id!,
      plantId: result.plant.id!,
      plantName: result.plant.name,
      action: result.action,
      note: result.note,
    );
    await _refresh();
  }

  Future<void> _deleteLog(CareLog log) async {
    await widget.database.deleteCareLog(log.id!, widget.user.id!);
    await _refresh();
  }

  Future<void> _renameUser() async {
    final controller = TextEditingController(text: widget.user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo te llamamos?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    final updated = await widget.database.updateUserName(widget.user, name);
    widget.onUserChanged(updated);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de Brote?'),
        content: const Text(
          'Tu jardín se quedará guardado en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.onSignedOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 820;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: EmptyGarden(
          title: 'No abre tu jardín',
          message: _loadError!,
          action: FilledButton(
            onPressed: () {
              setState(() => _loading = true);
              _refresh();
            },
            child: const Text('Reintentar'),
          ),
        ),
      );
    }
    final screens = [
      _HomePage(
        user: widget.user,
        plants: _plants,
        onOpenPlants: () => setState(() => _tab = 1),
        onAddPlant: () => _editPlant(),
        onWater: _water,
        onPlantTap: _editPlant,
      ),
      _CollectionPage(
        plants: _plants,
        onAdd: () => _editPlant(),
        onEdit: _editPlant,
        onWater: _water,
        onDelete: _deletePlant,
      ),
      _JournalPage(logs: _logs, onAdd: _addJournalNote, onDelete: _deleteLog),
      _ProfilePage(
        user: widget.user,
        plantCount: _plants.length,
        logCount: _logs.length,
        onRename: _renameUser,
        onSignOut: _signOut,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) ...[
              const SizedBox(width: 20),
              _SideNavigation(
                selected: _tab,
                onSelect: (index) => setState(() => _tab = index),
              ),
              const SizedBox(width: 16),
              const VerticalDivider(width: 1, indent: 24, endIndent: 24),
            ],
            Expanded(
              child: IndexedStack(index: _tab, children: screens),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (index) => setState(() => _tab = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.wb_sunny_outlined),
                  selectedIcon: Icon(Icons.wb_sunny_rounded),
                  label: 'Hoy',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Jardín',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Bitácora',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Cuenta',
                ),
              ],
            ),
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.wb_sunny_outlined, 'Hoy'),
    (Icons.grid_view_outlined, 'Jardín'),
    (Icons.menu_book_outlined, 'Bitácora'),
    (Icons.person_outline_rounded, 'Cuenta'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 14, 12, 34),
          child: BroteMark(),
        ),
        for (var index = 0; index < _items.length; index++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: ListTile(
              selected: selected == index,
              selectedTileColor: const Color(0xFFE5E9DC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              leading: Icon(_items[index].$1),
              title: Text(_items[index].$2),
              onTap: () => onSelect(index),
            ),
          ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'CUIDAR TAMBIÉN\nES MIRAR DESPACIO.',
            style: TextStyle(
              color: mutedInk,
              fontSize: 9,
              height: 1.6,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.user,
    required this.plants,
    required this.onOpenPlants,
    required this.onAddPlant,
    required this.onWater,
    required this.onPlantTap,
  });

  final BroteUser user;
  final List<Plant> plants;
  final VoidCallback onOpenPlants;
  final VoidCallback onAddPlant;
  final ValueChanged<Plant> onWater;
  final ValueChanged<Plant> onPlantTap;

  @override
  Widget build(BuildContext context) {
    final due = plants.where((plant) => plant.needsWatering).toList();
    final greeting = greetingName(user.name);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 740;
        final horizontal = wide ? 38.0 : 20.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    if (wide) const SizedBox.shrink() else const BroteMark(),
                    const Spacer(),
                    const Eyebrow('TU RINCÓN VERDE'),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 17,
                      color: terracotta,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 31, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(_todayLabel()),
                    const SizedBox(height: 8),
                    Text(
                      'Hola, $greeting.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Un ratito para tus plantas cambia el día.',
                      style: TextStyle(color: mutedInk),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 23, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: _DailyCard(
                  dueCount: due.length,
                  plantCount: plants.length,
                  nextPlant: due.isEmpty
                      ? (plants.isEmpty ? null : plants.first)
                      : due.first,
                  onWater: due.isEmpty || plants.isEmpty
                      ? null
                      : () => onWater(due.first),
                  onSeeAll: onOpenPlants,
                  onAdd: onAddPlant,
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 27, horizontal, 11),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('UN VISTAZO'),
                          const SizedBox(height: 5),
                          Text(
                            plants.isEmpty
                                ? 'Tu primer brote'
                                : 'En tu espacio',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onOpenPlants,
                      child: const Text('Ver jardín'),
                    ),
                  ],
                ),
              ),
            ),
            if (plants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyGarden(
                  title: 'Todo empieza con una',
                  message: 'Agrega una planta y guarda aquí sus cuidados.',
                  action: FilledButton.icon(
                    onPressed: onAddPlant,
                    icon: const Icon(Icons.add),
                    label: const Text('Añadir planta'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 28),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final columns = cardConstraints.maxWidth >= 900
                          ? 3
                          : cardConstraints.maxWidth >= 540
                          ? 2
                          : 1;
                      return Wrap(
                        spacing: 13,
                        runSpacing: 13,
                        children: plants.take(3).map((plant) {
                          final cardWidth = columns == 1
                              ? cardConstraints.maxWidth
                              : (cardConstraints.maxWidth -
                                        13 * (columns - 1)) /
                                    columns;
                          return SizedBox(
                            width: cardWidth,
                            child: _HomePlantCard(
                              plant: plant,
                              onTap: () => onPlantTap(plant),
                              onWater: () => onWater(plant),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _todayLabel() {
    const weekdays = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO',
    ];
    const months = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    final date = DateTime.now();
    return '${weekdays[date.weekday - 1]} · ${date.day} DE ${months[date.month - 1]}';
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.dueCount,
    required this.plantCount,
    required this.nextPlant,
    required this.onWater,
    required this.onSeeAll,
    required this.onAdd,
  });

  final int dueCount;
  final int plantCount;
  final Plant? nextPlant;
  final VoidCallback? onWater;
  final VoidCallback onSeeAll;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(25),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 440;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('EL PEQUEÑO RITUAL DE HOY', color: Color(0xFFBDCAAD)),
            const SizedBox(height: 12),
            Text(
              plantCount == 0
                  ? 'Tu jardín empieza aquí.'
                  : dueCount == 0
                  ? 'Hoy todo va a su ritmo.'
                  : dueCount == 1
                  ? 'Una planta pide un poco de agua.'
                  : '$dueCount plantas piden un poco de agua.',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: Colors.white, fontSize: 21),
            ),
            const SizedBox(height: 7),
            Text(
              plantCount == 0
                  ? 'Añade la primera y hagamos espacio para algo vivo.'
                  : dueCount == 0
                  ? 'Tu siguiente revisión ya está en la agenda.'
                  : '${nextPlant!.name} · ${nextPlant!.location}',
              style: const TextStyle(color: Color(0xFFD4D8CF), fontSize: 12),
            ),
            const SizedBox(height: 17),
            Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                if (plantCount == 0)
                  FilledButton.tonal(
                    onPressed: onAdd,
                    child: const Text('Añadir planta'),
                  )
                else if (onWater != null)
                  FilledButton.tonalIcon(
                    onPressed: onWater,
                    icon: const Icon(Icons.water_drop_outlined, size: 17),
                    label: const Text('Ya la regué'),
                    style: FilledButton.styleFrom(
                      foregroundColor: ink,
                      backgroundColor: const Color(0xFFE3E9D1),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: onSeeAll,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text('Ver mi jardín'),
                  ),
                if (plantCount > 0)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text('$plantCount en tu jardín  ↗'),
                  ),
              ],
            ),
          ],
        );
        if (stack) return content;
        return Row(
          children: [
            Expanded(child: content),
            const SizedBox(width: 18),
            Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_rounded,
                size: 55,
                color: Color(0xFFD6DCA9),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _HomePlantCard extends StatelessWidget {
  const _HomePlantCard({
    required this.plant,
    required this.onTap,
    required this.onWater,
  });
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onWater;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.64),
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: PlantArtwork(plant: plant, height: 72, radius: 15),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plant.species,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedInk, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  _WaterStatus(plant: plant),
                ],
              ),
            ),
            IconButton(
              onPressed: onWater,
              tooltip: 'Registrar riego',
              icon: const Icon(Icons.water_drop_outlined, color: forest),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CollectionPage extends StatefulWidget {
  const _CollectionPage({
    required this.plants,
    required this.onAdd,
    required this.onEdit,
    required this.onWater,
    required this.onDelete,
  });
  final List<Plant> plants;
  final VoidCallback onAdd;
  final ValueChanged<Plant> onEdit;
  final ValueChanged<Plant> onWater;
  final Future<void> Function(Plant) onDelete;

  @override
  State<_CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<_CollectionPage> {
  final _search = TextEditingController();
  bool _dueOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = widget.plants.where((plant) {
      final matchesText =
          query.isEmpty ||
          '${plant.name} ${plant.species} ${plant.location}'
              .toLowerCase()
              .contains(query);
      return matchesText && (!_dueOnly || plant.needsWatering);
    }).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 700 ? 38.0 : 20.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 27, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Eyebrow('COLECCIÓN PERSONAL'),
                          const SizedBox(height: 7),
                          Text(
                            'Mi jardín',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${widget.plants.length} ${widget.plants.length == 1 ? 'planta' : 'plantas'} en tu espacio',
                            style: const TextStyle(color: mutedInk),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: widget.onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Busca por nombre, especie o lugar',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 9, horizontal, 7),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    selected: _dueOnly,
                    onSelected: (selected) =>
                        setState(() => _dueOnly = selected),
                    avatar: Icon(
                      Icons.water_drop_outlined,
                      size: 16,
                      color: _dueOnly ? forest : mutedInk,
                    ),
                    label: const Text('Necesitan agua'),
                    showCheckmark: false,
                  ),
                ),
              ),
            ),
            if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyGarden(
                  title: widget.plants.isEmpty
                      ? 'Aún no hay plantas'
                      : 'No encontramos nada',
                  message: widget.plants.isEmpty
                      ? 'Cada ficha es un pequeño ritual que vale la pena guardar.'
                      : 'Prueba otro nombre o cambia el filtro de riego.',
                  action: widget.plants.isEmpty
                      ? FilledButton.icon(
                          onPressed: widget.onAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir mi primera planta'),
                        )
                      : null,
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 28),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final plant = visible[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: Dismissible(
                        key: ValueKey(plant.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await widget.onDelete(plant);
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4D8CE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: terracotta,
                          ),
                        ),
                        child: _CollectionCard(
                          plant: plant,
                          onTap: () => widget.onEdit(plant),
                          onWater: () => widget.onWater(plant),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.plant,
    required this.onTap,
    required this.onWater,
  });
  final Plant plant;
  final VoidCallback onTap;
  final VoidCallback onWater;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.68),
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 94,
              child: PlantArtwork(plant: plant, height: 94, radius: 14),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plant.species,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: mutedInk, fontSize: 11),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: mutedInk,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          plant.location,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: mutedInk, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Flexible(child: _WaterStatus(plant: plant)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onWater,
              tooltip: 'Registrar riego',
              icon: const Icon(Icons.water_drop_outlined, color: forest),
            ),
          ],
        ),
      ),
    ),
  );
}

class _WaterStatus extends StatelessWidget {
  const _WaterStatus({required this.plant});
  final Plant plant;

  @override
  Widget build(BuildContext context) {
    final due = plant.needsWatering;
    final days = plant.nextWatering.difference(DateTime.now()).inDays;
    final label = due
        ? 'Toca regar'
        : days <= 0
        ? 'Mañana'
        : 'En $days ${days == 1 ? 'día' : 'días'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: due ? const Color(0xFFF5E2D9) : const Color(0xFFE6EBDD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: due ? terracotta : forest,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JournalPage extends StatelessWidget {
  const _JournalPage({
    required this.logs,
    required this.onAdd,
    required this.onDelete,
  });
  final List<CareLog> logs;
  final VoidCallback onAdd;
  final ValueChanged<CareLog> onDelete;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth > 700 ? 38.0 : 20.0;
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 27, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow('MEMORIA DE CUIDADOS'),
                        const SizedBox(height: 7),
                        Text(
                          'Bitácora',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Los gestos pequeños también cuentan.',
                          style: TextStyle(color: mutedInk),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onAdd,
                    tooltip: 'Añadir nota',
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9D8),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, color: forest),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        logs.isEmpty
                            ? 'Aquí se irán guardando tus riegos y observaciones.'
                            : '${logs.length} momentos guardados en tu jardín.',
                        style: const TextStyle(
                          color: ink,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyGarden(
                title: 'Una historia por empezar',
                message: 'Registra un riego o añade una nota sobre lo que observaste.',
                action: FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Escribir una nota'),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 28),
              sliver: SliverList.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Dismissible(
                    key: ValueKey(log.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => onDelete(log),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4D8CE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: terracotta,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE7EBDD),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                log.action == 'Riego'
                                    ? Icons.water_drop_outlined
                                    : Icons.spa_outlined,
                                size: 20,
                                color: forest,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.action,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    log.plantName,
                                    style: const TextStyle(
                                      color: forest,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (log.note.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(log.note),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    '${shortDate(log.createdAt)} · ${_timeLabel(log.createdAt)}',
                                    style: const TextStyle(
                                      color: mutedInk,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.swipe_left_alt_rounded,
                              color: Color(0xFFB7BDB4),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    },
  );

  String _timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _JournalEntry {
  const _JournalEntry(this.plant, this.action, this.note);
  final Plant plant;
  final String action;
  final String note;
}

class _JournalEntrySheet extends StatefulWidget {
  const _JournalEntrySheet({required this.plants});
  final List<Plant> plants;

  @override
  State<_JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<_JournalEntrySheet> {
  final _note = TextEditingController();
  late Plant _plant = widget.plants.first;
  String _action = 'Observación';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      22,
      8,
      22,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Un momento para recordar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Plant>(
          initialValue: _plant,
          decoration: const InputDecoration(labelText: 'Planta'),
          items: widget.plants
              .map(
                (plant) =>
                    DropdownMenuItem(value: plant, child: Text(plant.name)),
              )
              .toList(),
          onChanged: (plant) {
            if (plant != null) setState(() => _plant = plant);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _action,
          decoration: const InputDecoration(labelText: 'Tipo de nota'),
          items: const [
            DropdownMenuItem(value: 'Observación', child: Text('Observación')),
            DropdownMenuItem(value: 'Abono', child: Text('Abono')),
            DropdownMenuItem(value: 'Poda', child: Text('Poda')),
            DropdownMenuItem(value: 'Trasplante', child: Text('Trasplante')),
          ],
          onChanged: (action) {
            if (action != null) setState(() => _action = action);
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: '¿Qué notaste?',
            hintText: 'Una hoja nueva, la tierra seca…',
          ),
        ),
        const SizedBox(height: 17),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _JournalEntry(_plant, _action, _note.text.trim()),
            ),
            child: const Text('Guardar en la bitácora'),
          ),
        ),
      ],
    ),
  );
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.user,
    required this.plantCount,
    required this.logCount,
    required this.onRename,
    required this.onSignOut,
  });
  final BroteUser user;
  final int plantCount;
  final int logCount;
  final VoidCallback onRename;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final horizontal = constraints.maxWidth > 700 ? 38.0 : 20.0;
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 27, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('UN ESPACIO PROPIO'),
                  const SizedBox(height: 7),
                  Text(
                    'Tu cuenta',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 23, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E6D0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.trim().isEmpty
                              ? 'B'
                              : user.name.trim()[0].toUpperCase(),
                          style: const TextStyle(
                            color: forest,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: const TextStyle(
                              color: Color(0xFFD4D8CF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRename,
                      tooltip: 'Cambiar nombre',
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(value: '$plantCount', label: 'PLANTAS'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(value: '$logCount', label: 'MOMENTOS'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 27, horizontal, 0),
            sliver: SliverToBoxAdapter(child: const Eyebrow('PREFERENCIAS')),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 0),
            sliver: SliverToBoxAdapter(
              child: Material(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(19),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline_rounded,
                        color: forest,
                      ),
                      title: const Text('Editar nombre'),
                      subtitle: const Text('Tu nombre en los saludos'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: onRename,
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    const ListTile(
                      leading: Icon(Icons.lock_outline_rounded, color: forest),
                      title: Text('Datos en este dispositivo'),
                      subtitle: Text('Tu jardín vive aquí, no en la nube.'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(horizontal, 22, horizontal, 30),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: terracotta,
                  side: const BorderSide(color: Color(0xFFD9B6A8)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 5),
        Eyebrow(label),
      ],
    ),
  );
}
