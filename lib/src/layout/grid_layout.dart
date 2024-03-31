import 'dart:math';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/models/agora_user.dart';
import 'package:agora_uikit/src/layout/widgets/disabled_video_widget.dart';
import 'package:agora_uikit/src/layout/widgets/number_of_users.dart';
import 'package:flutter/material.dart';
import 'package:agora_uikit/agora_uikit.dart';

class GridLayout extends StatefulWidget {
  final AgoraClient client;

  /// Display the total number of users in a channel.
  final bool? showNumberOfUsers;

  /// Widget that will be displayed when the local or remote user has disabled it's video.
  final Widget? disabledVideoWidget;

  /// Render mode for local and remote video
  final RenderModeType renderModeType;

  const GridLayout({
    super.key,
    required this.client,
    this.showNumberOfUsers,
    this.disabledVideoWidget = const DisabledVideoWidget(),
    this.renderModeType = RenderModeType.renderModeHidden,
  });

  @override
  State<GridLayout> createState() => _GridLayoutState();
}

class _GridLayoutState extends State<GridLayout> {
  List<Widget> _getRenderViews() {
    final disabledVideoWidget = DisabledVideoStfWidget(
      disabledVideoWidget: widget.disabledVideoWidget,
    );
    final agoraSettings = widget.client.sessionController.value;

    return [
      if (widget.client.agoraChannelData?.clientRoleType
          case ClientRoleType.clientRoleBroadcaster || null)
        if (agoraSettings.isLocalVideoDisabled)
          disabledVideoWidget
        else
          AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: agoraSettings.engine!,
              canvas: VideoCanvas(uid: 0, renderMode: widget.renderModeType),
            ),
          ),
      for (AgoraUser user in agoraSettings.users)
        if (user.clientRoleType == ClientRoleType.clientRoleBroadcaster)
          disabledVideoWidget
        else
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: agoraSettings.engine!,
              canvas: VideoCanvas(
                uid: user.uid,
                renderMode: widget.renderModeType,
              ),
              connection: RtcConnection(
                channelId: agoraSettings.connectionData!.channelName,
              ),
            ),
          ),
    ];
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    return Expanded(
      child: Row(
        children: [for (final view in views) Expanded(child: view)],
      ),
    );
  }

  Widget _viewGrid() {
    final views = _getRenderViews();
    switch (views.length) {
      case 0:
        return Container(
          color: Colors.white,
          child: Center(
            child: Text(
              'Waiting for the host to join',
              style: TextStyle(color: Colors.black),
            ),
          ),
        );
      case 1:
        return SizedBox.expand(child: views[0]);
      case 2:
        return Column(
          children: [
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]]),
          ],
        );
      case final int length when length % 2 == 0:
        return Column(
          children: [
            for (int i = 0; i < views.length; i += 2)
              _expandedVideoRow(views.sublist(i, i + 2)),
          ],
        );
      default:
        return Container(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < views.length; i += 2)
                _expandedVideoRow(
                  views.sublist(i, min(i + 2, views.length)),
                ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.client.sessionController,
      builder: (context, counter, widgetx) {
        return Center(
          child: Stack(
            children: [
              _viewGrid(),
              if (widget.showNumberOfUsers ?? false)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: NumberOfUsers(userCount: counter.users.length),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class DisabledVideoStfWidget extends StatefulWidget {
  final Widget? disabledVideoWidget;
  const DisabledVideoStfWidget({super.key, this.disabledVideoWidget});

  @override
  State<DisabledVideoStfWidget> createState() => _DisabledVideoStfWidgetState();
}

class _DisabledVideoStfWidgetState extends State<DisabledVideoStfWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.disabledVideoWidget!;
  }
}
