



//#define _CRT_SECURE_NO_WARNINGS 1
//#include <stdio.h>      // for printf
//#include <string.h>     // for strnlen
//#include <stdlib.h>     // for _countof, _itoa fns, _MAX_COUNT macros
//#include <windows.h>
//#include <WinUser.h>
//
//void doody() {
//    char buffer[_MAX_U64TOSTR_BASE2_COUNT];
//    int r;
//    malloc(10);
//    (DWORD)0x00CC0020;
//    DT_BOTTOM;
//    RECT var = {};
//    IMAGE_CURSOR;
//    PM_REMOVE;
//    DT_NOCLIP;
//        DT_LEFT;
//        auto xPos = GET_X_LPARAM(lParam);
//        auto yPos = GET_Y_LPARAM(lParam);
//    DrawText();
//    SetBkMode(wdc, TRANSPARENT);
//    PeekMessageW();
//    for (r = 10; r >= 2; --r)
//    {
//        _i64toa(-1LL, buffer, r);
//        printf("base %d: %s (%d chars)\n", r, buffer,
//            strnlen(buffer, _countof(buffer)));
//    }
//}

//
//#include <windows.h>
//
//double PCFreq = 0.0;
//__int64 CounterStart = 0;
//
//int main()
//{
//    RedrawWindow(0, NULL, NULL, RDW_INVALIDATE);
//
//
//    long cycles_per_second, start_time, end_time;
//
//    QueryPerformanceCounter((LARGE_INTEGER*)&start_time);
//
//    // some lengthy code ...
//
//    QueryPerformanceCounter((LARGE_INTEGER*)&end_time);
//
//    QueryPerformanceFrequency((LARGE_INTEGER*)&cycles_per_second);
//
//    long ticks = end_time - start_time;
//    long diff_microsec = (ticks*1000000) / cycles_per_second;
//
//    //StartCounter();
//    //Sleep(1000);
//    //GetCounter();
//    return 0;
//}
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
//    COLOR_WINDOW
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