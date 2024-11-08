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