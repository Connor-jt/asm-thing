//
//
//#include <Windows.h>
//#include <winuser.h>
//
//void doody() {
//    PAINTSTRUCT ps;
//    HDC hdc = BeginPaint(hwnd, &ps);
//
//    // All painting occurs here, between BeginPaint and EndPaint.
//
//    FillRect(hdc, &ps.rcPaint, (HBRUSH)(6));
//
//    HBITMAP hBitmap = (HBITMAP)LoadImageW(0, L"res\\sd.png", 0, 0, 0, 0x00000010);
//    if (hBitmap)
//    {
//        // Create a compatible device context 
//        HDC hdcMem = CreateCompatibleDC(hdc);
//        SelectObject(hdcMem, hBitmap);
//        // Get the bitmap dimensions 
//        // Use BitBlt to copy the bitmap to the window's device context 
//        BitBlt(hdc, 0, 0, 32, 32, hdcMem, 0, 0, SRCCOPY);
//        // Clean up 
//        DeleteDC(hdcMem);
//        //DeleteObject(hBitmap);
//
//        const int number = MAKEROP4(SRCCOPY, 0x00AA0029);
//        const int number = (DWORD)(0xAA000000 | ((DWORD)0xAACC0020));
//
//    }
//
//    EndPaint(hwnd, &ps);
//}