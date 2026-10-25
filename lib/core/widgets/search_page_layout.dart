import 'package:flutter/material.dart';

import 'app_header.dart';
import 'soft_background.dart';

class SearchPageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<Widget> listChildren;
  final List<Widget> headerChildren;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final ScrollController? scrollController;

  const SearchPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    required this.hintText,
    required this.listChildren,
    this.headerChildren = const [],
    this.onChanged,
    this.onSubmitted,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = 24.0 + mediaQuery.viewPadding.bottom;

    final content = SoftBackground(
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: hintText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (headerChildren.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: headerChildren,
                ),
              ),
            if (headerChildren.isNotEmpty) const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                itemCount: listChildren.length,
                itemBuilder: (context, index) => listChildren[index],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppHeader(
        title: title,
        subtitle: subtitle,
        actions: actions,
        leading: leading,
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );
  }
}
