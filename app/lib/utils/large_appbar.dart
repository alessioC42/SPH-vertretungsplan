import 'package:flutter/material.dart';

class LargeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color? backgroundColor;
  final Text title;
  final void Function()? back;
  final bool showBackButton; 

  const LargeAppBar({
    super.key, 
    required this.title, 
    this.backgroundColor, 
    this.back,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 88);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHigh,
      leading: showBackButton ? IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: back ?? () => Navigator.of(context).pop(),
      ) : null,
      automaticallyImplyLeading: showBackButton,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(88),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 28),
              child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  child: title),
            ),
          ],
        ),
      ),
    );
  }
}
