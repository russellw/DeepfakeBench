\dependencies\dependencies -modules C:\Users\russe\anaconda3\envs\dfba\Lib\site-packages\cv2.pyd >a.txt
conda list | findstr /I "opencv ffmpeg" >>a.txt
where python >>a.txt
echo %CONDA_PREFIX% >>a.txt
Lclip a.txt

