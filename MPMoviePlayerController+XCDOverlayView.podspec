Pod::Spec.new do |s|
  s.name             = "MPMoviePlayerController+XCDOverlayView"
  s.version          = "1.0.0"
  s.summary          = "Overlay view synchronized with playback controls for MPMoviePlayerController"
  s.description      = <<-DESC
                       Displaying some information in overlay to a movie is an easy task.
                       Synchronizing the overlay with the playback controls of `MPMoviePlayerController` is a hard task.
                       **MPMoviePlayerController+XCDOverlayView** lets you add your own view to a
                       `MPMoviePlayerController`and automatically synchronizes it with the playback controls.
                       DESC
  s.homepage         = "https://github.com/0xced/MPMoviePlayerController-XCDOverlayView"
  s.screenshot       = "https://raw.github.com/0xced/MPMoviePlayerController-XCDOverlayView/#{s.version}/Screenshots/MPMoviePlayerController-XCDOverlayView.gif"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Cédric Luthi" => "cedric.luthi@gmail.com" }
  s.social_media_url = "https://twitter.com/0xced"
  s.platform         = :ios, "7.0"
  s.source           = { :git => "https://github.com/0xced/MPMoviePlayerController-XCDOverlayView.git", :tag => s.version.to_s }
  s.source_files     = "MPMoviePlayerController+XCDOverlayView"
  s.framework        = "MediaPlayer"
  s.requires_arc     = true
end
