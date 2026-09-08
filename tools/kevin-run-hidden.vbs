' Kevin hidden PowerShell launcher.
' Scheduled tasks should call:
'   wscript.exe //B //nologo kevin-run-hidden.vbs <script.ps1> [args...]
' WindowStyle 0 + //B means no console flash and no focus steal.
Option Explicit
If WScript.Arguments.Count < 1 Then WScript.Quit 1
Dim sh, cmd, i
Set sh = CreateObject("Wscript.Shell")
cmd = "powershell.exe -NoLogo -NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File " & Chr(34) & WScript.Arguments(0) & Chr(34)
For i = 1 To WScript.Arguments.Count - 1
  cmd = cmd & " " & WScript.Arguments(i)
Next
sh.Run cmd, 0, False
