
# SwiftUI Video Player

A simple SwiftUI video player that:
- Loads a given video URL.
- Auto-starts playing the video.
- Hides video controls.
- Supports videos with non-standard resolutions.
- Adjusts the player view to match the video's resolution.

## Usage

1. **Clone the Project**
   git clone https://github.com/YinkaAdepoju/iris-video
Open in Xcode
Open the project in Xcode.

Replace Video URL
In VideoPlayerContainerView, replace the default video URL with your desired video URL.

swift
@State private var videoURL: URL = URL(string: "https://your-video-url.com/video.mp4")!
Build and Run
Build and run the project.

This setup ensures a smooth video playback experience with the specified functionalities.

Code Structure
VideoPlayerView: Handles the AVPlayer and gestures.
VideoPlayerContainerView: Manages video URL and player state.
VideoSizeReader: Adjusts the player view to match the video size.
ContentView: Main view to render the video player.
VideoPlayerApp: Entry point of the SwiftUI app.

Example
Replace the URL in VideoPlayerContainerView:

swift
@State private var videoURL: URL = URL(string: "https://your-video-url.com/video.mp4")!
Ensure the video auto-starts and adjust the view to fit any video resolution seamlessly.
