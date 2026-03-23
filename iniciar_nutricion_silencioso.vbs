Option Explicit

Dim shell, fso
Dim rootPath, backendPath, frontendPath, logsPath
Dim setupLog, backendLog, frontendLog
Dim setupCmd, backendCmd, frontendCmd
Dim exitCode

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

rootPath = fso.GetParentFolderName(WScript.ScriptFullName)
backendPath = rootPath & "\backend"
frontendPath = rootPath & "\Nutricion-flutter"
logsPath = rootPath & "\logs"

If Not fso.FolderExists(backendPath) Then
  MsgBox "No existe la carpeta backend en: " & backendPath, vbCritical, "Lanzador Nutricion"
  WScript.Quit 1
End If

If Not fso.FolderExists(frontendPath) Then
  MsgBox "No existe la carpeta Nutricion-flutter en: " & frontendPath, vbCritical, "Lanzador Nutricion"
  WScript.Quit 1
End If

If Not fso.FolderExists(logsPath) Then
  fso.CreateFolder logsPath
End If

setupLog = logsPath & "\setup.log"
backendLog = logsPath & "\backend.log"
frontendLog = logsPath & "\frontend.log"

setupCmd = "cmd /c cd /d """ & rootPath & """ && " & _
           "(py -m pip install -r """ & backendPath & "\requirements.txt"" || python -m pip install -r """ & backendPath & "\requirements.txt"") > """ & setupLog & """ 2>&1 && " & _
           "cd /d """ & frontendPath & """ && flutter pub get >> """ & setupLog & """ 2>&1"

exitCode = shell.Run(setupCmd, 0, True)
If exitCode <> 0 Then
  MsgBox "Error instalando dependencias. Revisa: " & setupLog, vbCritical, "Lanzador Nutricion"
  WScript.Quit exitCode
End If

backendCmd = "cmd /c cd /d """ & backendPath & """ && " & _
             "(py -m uvicorn main:app --host 127.0.0.1 --port 8000 || python -m uvicorn main:app --host 127.0.0.1 --port 8000) > """ & backendLog & """ 2>&1"

frontendCmd = "cmd /c cd /d """ & frontendPath & """ && " & _
              "flutter run -d windows > """ & frontendLog & """ 2>&1"

shell.Run backendCmd, 0, False
WScript.Sleep 1200
shell.Run frontendCmd, 0, False

' Sin alerta en ejecucion correcta: solo se muestran mensajes si hay error.
