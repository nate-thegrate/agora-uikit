import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:agora_uikit/controllers/rtc_buttons.dart';
import 'package:agora_uikit/models/agora_settings.dart';
import 'package:agora_uikit/src/layout/widgets/disabled_video_widget.dart';
import 'package:agora_uikit/src/layout/widgets/host_controls.dart';
import 'package:agora_uikit/src/layout/widgets/number_of_users.dart';
import 'package:agora_uikit/src/layout/widgets/user_av_state_widget.dart';
import 'package:flutter/material.dart';

class FloatingLayout extends StatefulWidget {
  final AgoraClient client;

  /// Set the height of the container in the floating view. The default height is 0.2 of the total height.
  final double? floatingLayoutContainerHeight;

  /// Set the width of the container in the floating view. The default width is 1/3 of the total width.
  final double? floatingLayoutContainerWidth;

  /// Padding of the main user or the active speaker in the floating layout.
  final EdgeInsets floatingLayoutMainViewPadding;

  /// Padding of the secondary user present in the list.
  final EdgeInsets floatingLayoutSubViewPadding;

  /// Widget that will be displayed when the local or remote user has disabled it's video.
  final Widget disabledVideoWidget;

  /// Display the camera and microphone status of a user. This feature is only available in the [Layout.floating]
  final bool? showAVState;

  /// Display the host controls. This feature is only available in the [Layout.floating]
  final bool? enableHostControl;

  /// Display the total number of users in a channel.
  final bool? showNumberOfUsers;

  // Render mode for local and remote video
  final RenderModeType? renderModeType;

  final bool? useFlutterTexture;
  final bool? useAndroidSurfaceView;

  const FloatingLayout({
    super.key,
    required this.client,
    this.floatingLayoutContainerHeight,
    this.floatingLayoutContainerWidth,
    this.floatingLayoutMainViewPadding = const EdgeInsets.fromLTRB(3, 0, 3, 3),
    this.floatingLayoutSubViewPadding = const EdgeInsets.fromLTRB(3, 3, 0, 3),
    this.disabledVideoWidget = const DisabledVideoWidget(),
    this.showAVState = false,
    this.enableHostControl = false,
    this.showNumberOfUsers,
    this.renderModeType = RenderModeType.renderModeHidden,
    this.useAndroidSurfaceView = false,
    this.useFlutterTexture = false,
  });

  @override
  State<FloatingLayout> createState() => _FloatingLayoutState();
}

class _FloatingLayoutState extends State<FloatingLayout> {
  Widget _getLocalViews() {
    final agoraSettings = widget.client.sessionController.value;
    final VideoViewController controller;
    if (agoraSettings.isScreenShared) {
      controller = VideoViewController(
        rtcEngine: agoraSettings.engine!,
        canvas: const VideoCanvas(
          uid: 0,
          sourceType: VideoSourceType.videoSourceScreen,
        ),
      );
    } else {
      controller = VideoViewController(
        rtcEngine: agoraSettings.engine!,
        canvas: VideoCanvas(uid: 0, renderMode: widget.renderModeType),
        useFlutterTexture: widget.useFlutterTexture!,
        useAndroidSurfaceView: widget.useAndroidSurfaceView!,
      );
    }
    return AgoraVideoView(controller: controller);
  }

  Widget _getRemoteViews(int uid) {
    final agoraSettings = widget.client.sessionController.value;
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: agoraSettings.engine!,
        canvas: VideoCanvas(uid: uid, renderMode: widget.renderModeType),
        connection: RtcConnection(
          channelId: agoraSettings.connectionData!.channelName,
        ),
        useFlutterTexture: widget.useFlutterTexture!,
        useAndroidSurfaceView: widget.useAndroidSurfaceView!,
      ),
    );
  }

  Widget _viewFloat() {
    final agoraSettings = widget.client.sessionController.value;
    if (agoraSettings.users.isNotEmpty) {
      Widget itemBuilder(BuildContext context, int index) {
        final user = agoraSettings.users[index];
        if (user.uid == agoraSettings.mainAgoraUser.uid) {
          return SizedBox.shrink();
        }

        final stack = Stack(
          children: [
            if (user.uid == agoraSettings.localUid) ...[
              Positioned.fill(child: ColoredBox(color: Colors.black)),
              Center(
                child: Text(
                  'Local User',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (agoraSettings.isLocalVideoDisabled ||
                  agoraSettings.isScreenShared)
                widget.disabledVideoWidget
              else
                Expanded(child: _getLocalViews()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () {
                    widget.client.sessionController
                        .setActiveSpeakerDisabled(false);
                    widget.client.sessionController.swapUser(index: index);
                  },
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.push_pin_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.showAVState!)
                UserAVStateWidget(
                  videoDisabled: agoraSettings.isLocalVideoDisabled,
                  muted: agoraSettings.isLocalUserMuted,
                ),
            ] else if (user.videoDisabled) ...[
              Positioned.fill(child: ColoredBox(color: Colors.black)),
              widget.disabledVideoWidget,
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            widget.client.sessionController
                                .setActiveSpeakerDisabled(true);
                            widget.client.sessionController
                                .swapUser(index: index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              Icons.push_pin_rounded,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: (widget.enableHostControl ?? false)
                          ? HostControls(
                              client: widget.client,
                              videoDisabled: user.videoDisabled,
                              muted: user.muted,
                              index: index,
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (widget.showAVState!)
                UserAVStateWidget(
                  videoDisabled: user.videoDisabled,
                  muted: user.muted,
                ),
            ] else ...[
              Expanded(child: _getRemoteViews(user.uid)),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            widget.client.sessionController
                                .setActiveSpeakerDisabled(true);
                            widget.client.sessionController
                                .swapUser(index: index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3.0),
                            child: Icon(
                              Icons.push_pin_rounded,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.enableHostControl ?? false)
                      Align(
                        alignment: Alignment.topRight,
                        child: HostControls(
                          client: widget.client,
                          videoDisabled: user.videoDisabled,
                          muted: user.muted,
                          index: index,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.showAVState!)
                UserAVStateWidget(
                  videoDisabled: user.videoDisabled,
                  muted: user.muted,
                ),
            ],
          ],
        );
        return Padding(
          key: Key('$index'),
          padding: widget.floatingLayoutSubViewPadding,
          child: SizedBox(
            width: widget.floatingLayoutContainerWidth ??
                MediaQuery.of(context).size.width / 3,
            child: Expanded(child: stack),
          ),
        );
      }

      final mainUser = agoraSettings.mainAgoraUser;
      return Column(
        children: [
          Container(
            height: widget.floatingLayoutContainerHeight ??
                MediaQuery.of(context).size.height * 0.2,
            width: double.infinity,
            alignment: Alignment.topLeft,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: agoraSettings.users.length,
              itemBuilder: itemBuilder,
            ),
          ),
          if (mainUser.uid != agoraSettings.localUid && mainUser.uid != 0)
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: widget.floatingLayoutMainViewPadding,
                    child: mainUser.videoDisabled
                        ? widget.disabledVideoWidget
                        : SizedBox.expand(child: _getRemoteViews(mainUser.uid)),
                  ),
                  if (widget.enableHostControl ?? false)
                    Align(
                      alignment: Alignment.topRight,
                      child: HostControls(
                        client: widget.client,
                        videoDisabled: mainUser.videoDisabled,
                        muted: mainUser.muted,
                        index: agoraSettings.users.indexWhere(
                          (element) => element.uid == mainUser.uid,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: widget.floatingLayoutMainViewPadding,
                child: agoraSettings.isLocalVideoDisabled &&
                        !agoraSettings.isScreenShared
                    ? widget.disabledVideoWidget
                    : Stack(
                        children: [
                          SizedBox.expand(
                            child: ColoredBox(
                              color: Colors.black,
                              child: Center(
                                child: Text(
                                  'Local User',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          SizedBox.expand(
                            child: _getLocalViews(),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      );
    }
    if (agoraSettings.clientRoleType == ClientRoleType.clientRoleBroadcaster) {
      return SizedBox.expand(
        child:
            agoraSettings.isLocalVideoDisabled && !agoraSettings.isScreenShared
                ? widget.disabledVideoWidget
                : _getLocalViews(),
      );
    }
    return SizedBox.expand(
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: Text(
            'Waiting for the host to join.',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.client.sessionController,
      builder: (context, AgoraSettings agoraSettings, widgetx) {
        void buttonToggle() {
          if (agoraSettings.showMicMessage &&
              !agoraSettings.showCameraMessage) {
            toggleMute(sessionController: widget.client.sessionController);
          } else {
            toggleCamera(sessionController: widget.client.sessionController);
          }
          agoraSettings = agoraSettings.copyWith(
            displaySnackbar: false,
            showMicMessage: false,
            showCameraMessage: false,
          );
        }

        return Center(
          child: Stack(
            children: [
              _viewFloat(),
              if (widget.showNumberOfUsers ?? false)
                Align(
                  alignment: Alignment.topRight,
                  child: NumberOfUsers(userCount: agoraSettings.users.length),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Visibility(
                  visible: agoraSettings.displaySnackbar,
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (agoraSettings.showMicMessage)
                          agoraSettings.muteRequest == MicState.muted
                              ? Text("Please unmute your mic")
                              : Text("Please mute your mic"),
                        if (agoraSettings.showCameraMessage)
                          agoraSettings.cameraRequest == CameraState.disabled
                              ? Text("Please turn on your camera")
                              : Text("Please turn off your camera"),
                        TextButton(
                          onPressed: buttonToggle,
                          child: agoraSettings.showMicMessage
                              ? Text(
                                  agoraSettings.muteRequest == MicState.muted
                                      ? "Unmute"
                                      : "Mute",
                                  style: TextStyle(color: Colors.blue),
                                )
                              : Text(
                                  agoraSettings.cameraRequest ==
                                          CameraState.disabled
                                      ? "Enable"
                                      : "Disable",
                                  style: TextStyle(color: Colors.blue),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
