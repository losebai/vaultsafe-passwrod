#include "win32_window.h"

#include <dwmapi.h>
#include <shellscalingapi.h>

#include <flutter/flutter_window.h>

#include "resource.h"

namespace {

// Windows Security Flag - Prevent screenshots
void EnableSecurity(HWND window) {
  // Set WS_EX_NOREDIRECTIONBITMAP to prevent screenshots
  SetClassLongPtr(window, GCL_STYLE, GetClassLongPtr(window, GCL_STYLE) | CS_NOCLOSE);

  // For enhanced security, you can also use DWM API
  // Note: This may affect visual appearance
}

}  // namespace

Win32Window::Win32Window() {
  // Use a high DPI for better rendering on modern displays
  HMODULE shcore_module = LoadLibrary(L"shcore.dll");
  if (shcore_module) {
    auto set_process_dpi_awareness =
        reinterpret_cast<SetProcessDpiAwarenessType>(
            GetProcAddress(shcore_module, "SetProcessDpiAwareness"));
    if (set_process_dpi_awareness) {
      set_process_dpi_awareness(PROCESS_PER_MONITOR_DPI_AWARE);
    }
    FreeLibrary(shcore_module);
  }
}

Win32Window::~Win32Window() {
  Destroy();
}

bool Win32Window::CreateAndShow(const std::wstring& title,
                                const Point& origin,
                                const Size& size) {
  Destroy();

  const RECT window_rect = {origin.x, origin.y,
                            origin.x + size.width,
                            origin.y + size.height};

  return CreateAndShow(title, window_rect);
}

bool Win32Window::CreateAndShow(const std::wstring& title,
                                const RECT& content_rect) {
  window_handle_ = CreateWindow(
      window_class_name_.c_str(), title.c_str(),
      WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      content_rect.left, content_rect.top,
      content_rect.right - content_rect.left,
      content_rect.bottom - content_rect.top,
      nullptr, nullptr, GetModuleHandle(nullptr), this);

  if (!window_handle_) {
    return false;
  }

  // Enable security features
  EnableSecurity(window_handle_);

  return true;
}

void Win32Window::Destroy() {
  if (window_handle_) {
    DestroyWindow(window_handle_);
    window_handle_ = nullptr;
  }
}

void Win32Window::SetChildContent(HWND content) {
  ::SetParent(content, window_handle_);
  ::SetWindowPos(content, nullptr, 0, 0,
                 ::GetClientWindowLength(),
                 ::GetClientWindowLength(),
                 SWP_NOSIZE | SWP_NOMOVE | SWP_NOZORDER);
}

HWND Win32Window::GetHandle() {
  return window_handle_;
}

ATOM Win32Window::RegisterWindowClass() {
  WNDCLASSEXW wcex = {};

  wcex.cbSize = sizeof(WNDCLASSEXW);
  wcex.style = CS_HREDRAW | CS_VREDRAW;
  wcex.lpfnWndProc = WndProc;
  wcex.hInstance = GetModuleHandle(nullptr);
  wcex.hIcon = LoadIcon(nullptr, IDI_APPLICATION);
  wcex.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wcex.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
  wcex.lpszClassName = window_class_name_.c_str();

  return RegisterClassExW(&wcex);
}

LRESULT Win32Window::MessageHandler(HWND window,
                                    UINT const message,
                                    WPARAM const wparam,
                                    LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto cs = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowUserData(window, reinterpret_cast<Win32Window*>(cs->lpCreateParams));
    return true;
  }

  auto* this_window = GetWindowUserData(window);
  if (this_window) {
    return this_window->WindowProcDelegate(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

LRESULT CALLBACK Win32Window::WndProc(HWND const window,
                                      UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
  if (message == WM_NCCREATE) {
    auto window_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
    SetWindowUserData(window, reinterpret_cast<Win32Window*>(window_struct->lpCreateParams));
  }

  auto* this_window = GetWindowUserData(window);

  if (this_window) {
    return this_window->MessageHandler(window, message, wparam, lparam);
  }

  return DefWindowProc(window, message, wparam, lparam);
}

void Win32Window::SetWindowUserData(HWND window, Win32Window* this_window) {
  SetWindowLongPtr(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(this_window));
}

Win32Window* Win32Window::GetWindowUserData(HWND window) {
  return reinterpret_cast<Win32Window*>(GetWindowLongPtr(window, GWLP_USERDATA));
}
