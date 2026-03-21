import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import 'package:nammaexpense/l10n/app_localizations.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  void _showAddEditModal(BuildContext context, {Category? existingCategory}) {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    String selectedIconName = existingCategory?.iconName ?? 'burger';
    Color selectedColor = existingCategory?.color ?? Colors.blue;

    final availableColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        final screenWidth = MediaQuery.of(ctx).size.width;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                top: screenHeight * 0.03,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isEditing ? AppLocalizations.of(context)!.editCategory : AppLocalizations.of(context)!.newCategory,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Name Field
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.categoryName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Color Picker
                    Text(AppLocalizations.of(context)!.selectColor, style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: screenHeight * 0.01),
                    SizedBox(
                      height: screenHeight * 0.06,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableColors.length,
                        itemBuilder: (context, index) {
                          final color = availableColors[index];
                          final isSelected = selectedColor.value == color.value;
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedColor = color),
                            child: Container(
                              margin: EdgeInsets.only(right: screenWidth * 0.02),
                              width: screenHeight * 0.05,
                              height: screenHeight * 0.05,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Icon Picker
                    Text(AppLocalizations.of(context)!.selectIcon, style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: screenHeight * 0.01),
                    Container(
                      height: screenHeight * 0.25,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: GridView.builder(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: availableIcons.keys.length,
                        itemBuilder: (context, index) {
                          final iconName = availableIcons.keys.elementAt(index);
                          final iconData = availableIcons[iconName]!;
                          final isSelected = selectedIconName == iconName;
                          
                          return GestureDetector(
                            onTap: () => setModalState(() => selectedIconName = iconName),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                iconData,
                                color: isSelected ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Action Buttons
                    FilledButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.enterName)));
                          return;
                        }
                        
                        final newCat = Category(
                          id: existingCategory?.id ?? const Uuid().v4(),
                          name: nameController.text.trim(),
                          icon: availableIcons[selectedIconName]!,
                          color: selectedColor,
                          isCustom: true,
                          iconName: selectedIconName,
                        );
                        
                        final provider = Provider.of<UserProvider>(context, listen: false);
                        if (isEditing) {
                          provider.updateCustomCategory(newCat);
                        } else {
                          provider.addCustomCategory(newCat);
                        }
                        
                        Navigator.pop(context);
                      },
                      child: Text(isEditing ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.createCategory),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final categories = userProvider.categories;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageCategories),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          
          return Card(
            margin: EdgeInsets.only(bottom: screenWidth * 0.02),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color.withOpacity(0.2),
                child: Icon(cat.icon, color: cat.color),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: cat.isCustom 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditModal(context, existingCategory: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(AppLocalizations.of(context)!.deleteCategory),
                              content: Text(AppLocalizations.of(context)!.deleteCategoryWarning),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    userProvider.deleteCustomCategory(cat.id);
                                    Navigator.pop(ctx);
                                  },
                                  child: Text(AppLocalizations.of(context)!.delete),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Tooltip(
                    message: AppLocalizations.of(context)!.defaultCategoriesWarning,
                    child: const Icon(Icons.lock_outline, color: Colors.grey),
                  ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditModal(context),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.newCategory),
      ),
    );
  }
}
