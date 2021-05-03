@ECHO OFF
title Minecraft服务器
SET BINDIR=%~dp0
:_MENU
CLS
set tm1=%time:~0,2%
set tm2=%time:~3,2%
set tm3=%time:~6,2%
@echo. 
echo  现在时间：%date% %tm1%点%TM2%分
@echo.
@echo. 请按下任意键来启动服务器…………
@echo.
pause
cls
@echo.     
@echo. 现在时间：%date% %tm1%点%TM2%分
@echo. ----------------------------------------------------------------- 
@echo. 
@echo. 
@echo.                   服务器正在启动中,请稍等……
@echo. 
@echo.
@echo. -----------------------------------------------------------------
java -Xms4096M -Xmx4096M -XX:+AggressiveOpts -XX:+UseCompressedOops -jar mohist-1.16.5-433-server.jar
//forge-1.15.2-31.2.36.jar
@echo.
@echo. ----------------------------------------------------------------- 
@echo.               Minecraft --- 玩家数据保存完毕 已关服
@echo.
@echo.                         按任意键关闭该窗口
@echo. -----------------------------------------------------------------
pause
EXIT
