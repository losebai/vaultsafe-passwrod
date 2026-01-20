#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with |title| that is positioned and sized using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, hence to ensure a
  // consistent size this function will scale the |size| to the appropriate
  // physical pixels based on the monitor DPI.
  // Returns |true| on success.
  bool CreateAndShow(const std::wstring& title,
                     const Point& origin,
                     const Size& size);

  // Release OS resources associated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to host components that need
  // Windows-specific APIs to interact with the window (e.g. Flutter).
  HWND GetHandle() { return window_handle_; }

 protected:
  // Registers a window class; returns the class atom.
  virtual ATOM RegisterWindowClass();

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responsponds to changes in DPI. All other messages are handled by
  // |WindowProcDelegate|.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Called by MessageHandler to process messages.
  virtual LRESULT WindowProcDelegate(HWND window,
                                     UINT const message,
                                     WPARAM const wparam,
                                     LPARAM const lparam) noexcept {
    return DefWindowProc(window, message, wparam, lparam);
  }

  // Stores window data associated with |window|.
  static void SetWindowUserData(HWND window, Win32Window* this_window);

  // Retrieves the window data associated with |window|.
  static Win32Window* GetWindowUserData(HWND window);

  const std::wstring window_class_name_;
  HWND window_handle_ = nullptr;
  HMODULE instance_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
