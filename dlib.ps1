# 1) Make sure the folder exists
New-Item -ItemType Directory -Force -Path .\preprocessing\dlib_tools | Out-Null

# 2) Download the 81-landmark predictor (officially referenced by DeepfakeBench docs)
$dest = ".\preprocessing\dlib_tools\shape_predictor_81_face_landmarks.dat"
Invoke-WebRequest -UseBasicParsing `
  -Uri "https://raw.githubusercontent.com/codeniko/shape_predictor_81_face_landmarks/master/shape_predictor_81_face_landmarks.dat" `
  -OutFile $dest

# 3) (Optional) Verify size/hash
Get-Item $dest | Select-Object Name,Length
Get-FileHash $dest -Algorithm SHA256
