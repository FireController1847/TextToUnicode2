# Table of Contents
- [winutil.inc](#winutilinc)
  - [Constants](#constants)
  - [Data](#data)
    - [Text](#text)
    - [Standard I/O](#standard-io)
  - [Macros](#macros)
    - [M_WRITECONSOLE](#m_writeconsole)
    - [M_READCONSOLE](#m_readconsole)
    - [M_COPYWSTR](#m_copywstr)
    - [M_UTF16LE_REMOVECRLF](#m_utf16le_removecrlf)
    - [M_UTF8_TO_UTF16LE](#m_utf8_to_utf16le)
  - [Procedures](#procedures)
    - [Crash](#crash)
    - [InitConsole](#initconsole)
    - [HexToUTF16LE](#hextoutf16le)
    - [InternalError](#internalerror)
    - [PauseAndExit](#pauseandexit)

# winutil.inc
## Constants
`STD_INPUT_HANDLE (-10)`  
`STD_OUTPUT_HANDLE (-11)`  
`MAX_PATH (260)`  

## Data
### Text
**TextToExit** `WORD`: Press enter to exit.  
**TextToExit_LEN** `CONST`: 23  

### Standard I/O
Handles are initialized via `InitConsole`.

**StdOutHandle** `QWORD`: ?  
**StdInHandle** `QWORD`: ?  
**StdInBuffer** `WORD`: `MAX_PATH` DUP (?)
**StdInCharsWritten** `DWORD`: ?

## Macros
### M_WRITECONSOLE
**Required Stack Space**: `N/A`  
**Args:** `W_STR`, `W_STRLEN`  
**See:** [WriteConsole](https://learn.microsoft.com/en-us/windows/console/writeconsole)  
  
Loads the effective address of W_STR, then writes W_STRLEN characters of it to the
console output.

### M_READCONSOLE
**Required Stack Space**: `8h` (1 stack argument)  
**Args:** `N/A`  
**See:** [ReadConsole](https://learn.microsoft.com/en-us/windows/console/readconsole)  
  
Waits for console input and then an 'ENTER' press. Writes the result into `StdInBuffer`
and the number of characters written into `StdInCharsWritten`.

### M_COPYWSTR
**Required Stack Space**: `N/A`  
**Args:** `MEM_FROM`, `MEM_TO`  
**See:** `N/A`  

Copies a wide-string from the given 'from' memory location to the given 'to' memory location.

### M_UTF16LE_REMOVECRLF
**Required Stack Space**: `N/A`  
**Args:** `W_STR`, `W_STRLEN`  
**See:** `N/A`

Removes the "CRLF" code from the end of a UTF16LE string.

### M_UTF8_TO_UTF16LE
**Required Stack Space**: `10h` (2 stack arguments)  
**Args:** `UTF8_STR`, `UTF16_BUFFER`, `STRLEN`  
**See:** [MultiByteToWideChar](https://learn.microsoft.com/en-us/windows/win32/api/stringapiset/nf-stringapiset-multibytetowidechar)

Converts a given UTF-8 string via pointer to a UTF-16 string and writes the number
of characters given to the buffer.

## Procedures
### Crash
**Args**: `N/A`  
**C Signature**:
```c
void Crash();
```
**See**: [GetLastError](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror), [ExitProcess](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess)

Gets the last error for debugging, then exits the process with an
exit code of the last error.

### InitConsole
**Args**: `N/A`  
**C Signature**:
```c
void InitConsole();
```
**See**: [Console Handles](https://learn.microsoft.com/en-us/windows/console/console-handles), [GetStdHandle](https://learn.microsoft.com/en-us/windows/console/getstdhandle), [SetLastError](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-setlasterror)  

Initializes a program to be a console program. Think of it as "Initialize Console
Program." Sets the last error to zero, then fetches the `StdInHandle` and `StdOutHandle`.

### HexToUTF16LE
**Args**: `RCX: HexValue`  
**C Signature**:
```c
QWORD HexToUTF16LE (
    [in] WORD   HexValue
);
```
**See**: `N/A`

Converts the given WORD-sized value stored in RCX to the Unicode UTF16LE equivalent value
outputted on RAX, following the Win32 __fastcall calling conventions.

### InternalError
**Args**: `N/A`
**C Signature**:
```c
void InternalError();
```
**See**: [GetLastError](https://learn.microsoft.com/en-us/windows/win32/api/errhandlingapi/nf-errhandlingapi-getlasterror), [ExitProcess](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess)

Gets the last error, converts it to UTF16LE, writes it to an Internal Error string, prints
that string to the console, and then calls [PauseAndExit](#pauseandexit).

### PauseAndExit
**Args**: `RCX: ExitCode`  
**C Signature**:
```c
void PauseAndExit(
    [in] QWORD  ExitCode
);
```
**See**: [ExitProcess](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-exitprocess)  

Writes the `TextToExit` string to the screen, waits for an 'ENTER' press from the user,
and then exits the process with the specified exit code.
