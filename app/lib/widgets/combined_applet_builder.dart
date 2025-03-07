import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:sph_plan/models/account_types.dart';

import 'package:sph_plan/generated/l10n.dart';
import 'package:sph_plan/models/client_status_exceptions.dart';
import '../core/applet_parser.dart';
import '../core/sph/sph.dart';
import 'error_view.dart';

typedef RefreshFunction = Future<void> Function();
typedef UpdateSetting = Future<void> Function(String key, dynamic value);
typedef BuilderFunction<T> = Widget Function(BuildContext, T, AccountType,
    Map<String, dynamic>, UpdateSetting, RefreshFunction? refresh);

class CombinedAppletBuilder<T> extends StatefulWidget {
  final AppletParser<T> parser;
  final String phpUrl;
  final Map<String, dynamic> settingsDefaults;
  final AccountType accountType;
  final BuilderFunction<T> builder;
  final bool showErrorAppBar;
  final AppBar? loadingAppBar;

  const CombinedAppletBuilder({
    super.key,
    required this.parser,
    required this.phpUrl,
    required this.settingsDefaults,
    required this.accountType,
    required this.builder,
    this.showErrorAppBar = false,
    this.loadingAppBar,
  });

  @override
  State<CombinedAppletBuilder<T>> createState() =>
      _CombinedAppletBuilderState<T>();
}

class _CombinedAppletBuilderState<T> extends State<CombinedAppletBuilder<T>> {
  late Map<String, dynamic> appletSettings;
  bool _loading = true;

  Widget _loadingState() {
    return Scaffold(
      appBar: widget.loadingAppBar,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void initSettings() async {
    appletSettings = await sph!.prefs.kv
        .getAllApplet(widget.phpUrl, widget.settingsDefaults);
    if (mounted) {
      setState(() {
      _loading = false;
    });
    }
  }

  @override
  void initState() {
    widget.parser.fetchData();
    super.initState();
    initSettings();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.parser.stream,
      builder: (context, snapshot) {
        if (snapshot.hasError || snapshot.data?.status == FetcherStatus.error) {
          return Scaffold(
            body: ErrorView(
              showAppBar: widget.showErrorAppBar,
              error: snapshot.data!.contentStatus == ContentStatus.offline
                  ? NoConnectionException()
                  : UnknownException(),
              retry: snapshot.data!.contentStatus == ContentStatus.online
                  ? () => widget.parser.fetchData(forceRefresh: true)
                  : null,
            ),
          );
        } else if (!snapshot.hasData ||
            snapshot.data?.status == FetcherStatus.fetching ||
            _loading) {
          return _loadingState();
        } else {
          return Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (snapshot.data?.contentStatus == ContentStatus.offline)
                Container(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: SafeArea(
                    left: false,
                    right: false,
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.offline_pin,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(
                            width: 4,
                          ),
                          Text(
                              '${AppLocalizations.of(context).offline} (${snapshot.data?.fetchedAt.format('E dd.MM HH:mm')})',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: widget.builder(
                  context,
                  snapshot.data!.content as T,
                  widget.accountType,
                  appletSettings,
                      (String key, dynamic value) async {
                    await sph!.prefs.kv.setAppletValue(widget.phpUrl, key, value);
                    setState(() {
                      appletSettings[key] = value;
                    });
                  },
                      () async {
                    await widget.parser.fetchData(forceRefresh: true);
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
