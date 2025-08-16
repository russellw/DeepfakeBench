for %%F in ("%CONDA_PREFIX%\Library\bin\libffi-*.dll") do echo %%F
for %%F in ("%CONDA_PREFIX%\Library\bin\libffi-*.dll") do copy "%%F" "%CONDA_PREFIX%\Library\bin\ffi.dll"
