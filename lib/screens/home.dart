import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:windows_taskbar/windows_taskbar.dart';
import '../components/windows_button.dart';

class MusicFileViewer extends StatefulWidget {
  @override
  _MusicFileViewerState createState() => _MusicFileViewerState();
}

class _MusicFileViewerState extends State<MusicFileViewer> {
  final SupabaseClient supabase = Supabase.instance.client;
  final AudioPlayer player = AudioPlayer(); // Audio player instance
  List<String> musicFiles = []; // To store list of music files
  int currentTrackIndex = -1; // Index of current track
  bool isPlaying = false; // To track if music is playing
  bool isPaused = false; // To track if music is paused
  double currentPosition = 0.0; // Current position of the song
  double duration = 1.0; // Duration of the song (needed for the slider)

  @override
  void initState() {
    super.initState();
    fetchMusicFiles(); // Fetch the music files when the widget is initialized
    player.onPositionChanged.listen((duration) {
      setState(() {
        currentPosition = duration.inSeconds.toDouble();
      });
    });
    player.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration.inSeconds.toDouble();
      });
    });
    player.onPlayerComplete.listen((event) {
      nextTrack(); // Automatically go to the next track when one ends
    });
  }

  void setupTaskbarControls() {
    if (isPlaying) {
      WindowsTaskbar.setThumbnailToolbar([
        ThumbnailToolbarButton(
          ThumbnailToolbarAssetIcon(
              !isPlaying ? 'assets/play.ico' : 'assets/pause.ico'),
          "Play",
          () {
            if (!isPlaying) {
              String fileName =
                  musicFiles.isNotEmpty ? musicFiles[currentTrackIndex] : '';
              playMusic(
                  fileName); // Play the current or first track if not playing
            }
          },
        ),
        // ThumbnailToolbarButton(
        //   ThumbnailToolbarAssetIcon(
        //       isPlaying ? 'assets/pause.ico' : 'assets/play.ico'),
        //   "Pause",
        //   () {
        //     if (isPlaying) {
        //       pauseMusic(); // Pause the current track
        //     }
        //   },
        // ),
        // ThumbnailToolbarButton(
        //   ThumbnailToolbarAssetIcon('assets/next.ico'),
        //   "Next",
        //   () {
        //     nextTrack(); // Play the next track
        //   },
        // ),
        // ThumbnailToolbarButton(
        //   ThumbnailToolbarAssetIcon('assets/previous.ico'),
        //   "Previous",
        //   () {
        //     previousTrack(); // Play the previous track
        //   },
        // ),
      ]);
    }
  }

  // Fetch the music files from 'playlist 1' folder
  Future<void> fetchMusicFiles() async {
    final response = await supabase.storage.from('music').list();

    setState(() {
      musicFiles = response
          .where((file) => !file.name.endsWith('/'))
          .map((file) => file.name)
          .toList();
    });
  }

  // Play the music file using the URL from Supabase
  Future<void> playMusic(String fileName) async {
    String fileUrl = supabase.storage.from('music').getPublicUrl(fileName);

    print("File URL: $fileUrl");

    try {
      await player.play(UrlSource(fileUrl));

      setState(() {
        isPlaying = true;
        isPaused = false;
      });

      print("Audio is now playing.");
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  // Pause the music
  Future<void> pauseMusic() async {
    await player.pause();
    setState(() {
      isPlaying = false;
      isPaused = true;
    });
  }

  // Stop the music
  Future<void> stopMusic() async {
    await player.stop();
    setState(() {
      isPlaying = false;
      isPaused = false;
      currentPosition = 0.0;
    });
  }

  // Play the next track
  void nextTrack() {
    setState(() {
      currentTrackIndex = (currentTrackIndex + 1) % musicFiles.length;
    });
    playMusic(musicFiles[currentTrackIndex]);
  }

  // Play the previous track
  void previousTrack() {
    setState(() {
      currentTrackIndex =
          (currentTrackIndex - 1 + musicFiles.length) % musicFiles.length;
    });
    playMusic(musicFiles[currentTrackIndex]);
  }

  Future<void> deleteMusicFile(String fileName, int index) async {
    try {
      // Delete the file from Supabase storage
      await supabase.storage.from('music').remove([fileName]);

      // Remove the file from the local list
      setState(() {
        musicFiles.removeAt(index);
      });

      print('Deleted $fileName successfully.');
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  Future<void> addSong() async {
    // Let the user pick a song
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.audio, allowMultiple: true);

    if (result != null) {
      // Iterate over all selected files
      for (PlatformFile file in result.files) {
        try {
          // Define the file path for upload
          String filePath = file.name; // Uploads the file to the bucket root

          // Convert the PlatformFile to a Dart File object
          File dartFile = File(file.path!);

          // Upload the file directly to Supabase
          await supabase.storage.from('music').upload(filePath, dartFile);

          print('Uploaded ${file.name} successfully.');
        } catch (e) {
          print('Error uploading song ${file.name}: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading ${file.name}')),
          );
        }
      }

      // Refresh the music files list after all uploads are complete
      fetchMusicFiles();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Songs uploaded successfully')),
      );
    }
  }

  void seekTo(double value) {
    final newPosition = Duration(
      milliseconds: (Duration.millisecondsPerSecond * value).toInt(),
    );
    player.seek(newPosition);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(30),
        child: kIsWeb ||
                !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                ),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  title: Text(
                    'MusiHolic',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  toolbarHeight: 30,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  actions: const [],
                ),
              )
            : MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: fetchMusicFiles,
                      child: AppBar(
                        backgroundColor: Colors.transparent,
                        title: Text(
                          'MusiHolic',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        toolbarHeight: 30,
                        scrolledUnderElevation: 0,
                        elevation: 0,
                        actions: [
                          if (!kIsWeb &&
                              (Platform.isWindows ||
                                  Platform.isLinux ||
                                  Platform.isMacOS))
                            const WindowsButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
      body: musicFiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Text(
                      //   'Playlist 1',
                      //   // style: TextStyle(fontSize: 25),
                      // ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ElevatedButton(
                            onPressed: addSong, child: Text('Add Song')),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedContainer(
                    duration: Duration(seconds: 5),
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(10)),
                    child: ListView.builder(
                      itemCount: musicFiles.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Material(
                              color: currentTrackIndex == index
                                  ? Color.fromARGB(255, 22, 21, 21)
                                  : Colors.transparent,
                              child: ListTile(
                                tileColor: Colors.transparent,
                                leading: AnimatedSwitcher(
                                  duration: Duration(
                                      milliseconds:
                                          200), // Smooth animation duration
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                        scale: animation, child: child);
                                  },
                                  child: currentTrackIndex == index
                                      ? Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                              color: Color(0xFF0F0F0F),
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 0.6),
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Icon(Icons.music_note_rounded),
                                        )
                                      : Container(
                                          height: 40,
                                          width: 40,
                                        ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      deleteMusicFile(musicFiles[index], index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  icon: Icon(Icons.more_vert_rounded),
                                ),
                                title: currentTrackIndex == index
                                    ? Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          musicFiles[index],
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    : Text(
                                        musicFiles[index],
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                onTap: () {
                                  setState(() {
                                    currentTrackIndex = index;
                                  });

                                  playMusic(musicFiles[index]);
                                },
                              ),
                            ),
                            Divider(
                              color: Colors.grey,
                              indent: 10,
                              endIndent: 10,
                              height: 0,
                              thickness: 0.5, // Thickness of the divider
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                // Music Controls Section (Play, Pause, Stop, Slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                        color: Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              onPressed: previousTrack, // Previous track button
                            ),
                            IconButton(
                              icon: Icon(isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              onPressed: () {
                                if (isPlaying) {
                                  pauseMusic(); // Pause the audio if playing
                                } else {
                                  if (currentTrackIndex == -1) {
                                    setState(() {
                                      currentTrackIndex = 0;
                                    });
                                  }
                                  playMusic(musicFiles[
                                      currentTrackIndex]); // Play the selected track
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: nextTrack, // Next track button
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                _formatDuration(
                                    Duration(seconds: currentPosition.toInt())),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Text(
                                _formatDuration(
                                    Duration(seconds: duration.toInt())),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: currentPosition,
                          min: 0.0,
                          max: duration,
                          onChanged: (value) {
                            seekTo(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
    );
  }
}
