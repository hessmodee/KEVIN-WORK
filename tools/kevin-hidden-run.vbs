' Kevin hidden runner v1.7
' Launch argv fully hidden. powershell -WindowStyle Hidden still allocates a console and steals focus.
If WScript.Arguments.Count < 1 Then WScript.Quit 1
Dim i, a, cmd
cmd = ""
For i = 0 To WScript.Arguments.Count - 1
  a = WScript.Arguments(i)
  If (InStr(a, " ") > 0) And (Left(a, 1) <> Chr(34)) Then a = Chr(34) & a & Chr(34)
  If i > 0 Then cmd = cmd & " "
  cmd = cmd & a
Next
CreateObject("WScript.Shell").Run cmd, 0, False
