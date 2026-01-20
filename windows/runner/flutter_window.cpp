#include "flutter_window.h"

#include <optional>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::CreateAndShow(const std::wstring& title,
                                  const Point& origin,
                                  const Size& size) {
  if (!Win32Window::CreateAndShow(title, origin, size)) {
    return false;
  }

  // Set up the Flutter view controller.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      instance_, GetHandle());
  if (!flutter_controller_->engine()) {
    return false;
  }
  if (!flutter_controller_->engine()->Run()) {
    return false;
  }
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Enable keyboard input
  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  return true;
}
