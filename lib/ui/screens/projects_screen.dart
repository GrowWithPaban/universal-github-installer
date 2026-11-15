import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/supported_technologies.dart';
import '../../state/app_state.dart';
import '../../state/projects_provider.dart';
import '../widgets/project_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProgrammingLanguage? _filterLang;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projectsProvider = context.watch<ProjectsProvider>();

    final query = _searchController.text.trim().toLowerCase();
    final filtered = projectsProvider.projects.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.githubUrl.toLowerCase().contains(query) ||
          p.techStack.framework.displayName.toLowerCase().contains(query);
      final matchesLang = _filterLang == null || p.techStack.language == _filterLang;
      return matchesSearch && matchesLang;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Projects',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${projectsProvider.projects.length} installed projects managed by GitHub Installer',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Install New Project'),
                  onPressed: () => appState.setTab(NavigationTab.installNew),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search & Filter Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by project name, repo, or framework...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 14),
                DropdownButton<ProgrammingLanguage?>(
                  value: _filterLang,
                  hint: const Text('All Languages'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Languages')),
                    ...ProgrammingLanguage.values.map(
                      (lang) => DropdownMenuItem(
                        value: lang,
                        child: Text(lang.displayName),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _filterLang = val),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Projects List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open, size: 54, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            projectsProvider.projects.isEmpty
                                ? 'No projects installed yet'
                                : 'No projects match your search criteria',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (projectsProvider.projects.isEmpty)
                            ElevatedButton(
                              onPressed: () => appState.setTab(NavigationTab.installNew),
                              child: const Text('Install your first project'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return ProjectCard(project: filtered[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

