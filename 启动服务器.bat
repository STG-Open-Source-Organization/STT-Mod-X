@ECHO OFF
title Minecraft������
SET BINDIR=%~dp0
:_MENU
CLS
set tm1=%time:~0,2%
set tm2=%time:~3,2%
set tm3=%time:~6,2%
@echo. 
echo  ����ʱ�䣺%date% %tm1%��%TM2%��
@echo.
@echo. �밴���������������������������
@echo.
pause
cls
@echo.     
@echo. ����ʱ�䣺%date% %tm1%��%TM2%��
@echo. ----------------------------------------------------------------- 
@echo. 
@echo. 
@echo.                   ����������������,���Եȡ���
@echo. 
@echo.
@echo. -----------------------------------------------------------------
java -Xms10000M -Xmx10000M -XX:+AggressiveOpts -XX:+UseCompressedOops -jar CatServer-27d41d1-universal.jar
@echo.
@echo. ----------------------------------------------------------------- 
@echo.               Minecraft --- ������ݱ������ �ѹط�
@echo.
@echo.                         ��������رոô���
@echo. -----------------------------------------------------------------
pause
EXIT
