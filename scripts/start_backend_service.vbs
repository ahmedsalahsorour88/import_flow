' =====================================================================
' Sorour Logistics ERP — Invisible Background Backend Service Launcher
' Starts FastAPI backend silently without popping any terminal console window.
' =====================================================================
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

strScriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
strRootDir = fso.GetParentFolderName(strScriptDir)
WshShell.CurrentDirectory = strRootDir

' Check if port 28080 is already active
Set objExec = WshShell.Exec("cmd /c netstat -ano | findstr "":28080""")
strOutput = objExec.StdOut.ReadAll()

If InStr(strOutput, "LISTENING") > 0 Then
    ' Backend is already running, no action needed
    WScript.Quit 0
End If

' Launch python uvicorn silently in background (0 = hidden, False = async)
strCmd = "py -3.14 -m uvicorn main:app --host 127.0.0.1 --port 28080 --no-access-log"
WshShell.Run strCmd, 0, False

WScript.Quit 0
