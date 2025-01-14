import 'package:cyber_security_app/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerPage extends StatefulWidget {
  final int courseId;

  const VideoPlayerPage({Key? key, required this.courseId}) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  String _currentVideoTitle = "Loading...";
  bool _isLoading = true;

  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _fetchCourseData();
  }

  /// Fetch course sections and videos from the backend
  Future<void> _fetchCourseData() async {
    try {
      // Fetch sections for the course
      final sectionsResponse = await ApiService.getRequest(
          '/api/Sections/course/${widget.courseId}');
      final sections = List<Map<String, dynamic>>.from(sectionsResponse);

      setState(() {
        _sections = sections;
      });

      // Fetch videos for the first section as a sample
      if (sections.isNotEmpty) {
        final firstSectionId = sections.first['sectionID'];
        final videosResponse =
            await ApiService.getRequest('/api/Videos/section/$firstSectionId');
        final videos = List<Map<String, dynamic>>.from(videosResponse);

        setState(() {
          _sections = sections;
          _videos = videos;
          if (videos.isNotEmpty) {
            _currentVideoTitle = videos.first['title'];
            _initializePlayer(videos.first['url']);
          } else {
            _currentVideoTitle = 'No videos available';
            _isLoading = false;
          }
        });
      } else {
        setState(() {
          _currentVideoTitle = 'No sections available';
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching course data: $error');
      setState(() {
        _currentVideoTitle = 'Failed to load data';
        _isLoading = false;
      });
    }
  }

  /// Initialize the video player with the given URL
  Future<void> _initializePlayer(String videoUrl) async {
    _videoPlayerController = VideoPlayerController.network(videoUrl);

    try {
      await _videoPlayerController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('Error initializing video player: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> loadNewVideo(String videoUrl, String videoTitle) async {
    setState(() {
      _isLoading = true;
      _currentVideoTitle = videoTitle;
    });

    // Dispose existing controllers
    _chewieController?.dispose();
    await _videoPlayerController.dispose();

    // Initialize new video
    _initializePlayer(videoUrl);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1D1F),
      appBar: AppBar(
        title: const Text('Course Player'),
        backgroundColor: const Color(0xFF2D2F31),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player Area
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.black54,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const Center(
                          child: Text(
                            'Failed to load video',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
            ),

            // Video Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _currentVideoTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Sections and Videos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: _sections.map((section) {
                  final sectionId = section['sectionID'];
                  final sectionTitle = section['title'];

                  return _buildSection(
                    sectionTitle,
                    () async {
                      final videosResponse = await ApiService.getRequest(
                          '/api/Videos/section/$sectionId');
                      setState(() {
                        _videos =
                            List<Map<String, dynamic>>.from(videosResponse);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String sectionTitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2F31),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              sectionTitle + "SECTION TITLE BURADA",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Video List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              final video = _videos[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white38),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  video['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  loadNewVideo(video['url'], video['title']);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
