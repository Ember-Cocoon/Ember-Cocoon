# 项目介绍

这是一个开发中的叙事游戏项目，基于 UE 5.7 版本进行制作，使用 Git LFS 进行同步与版本管理

# Git 同步结构

主要针对 Content 文件夹进行说明，项目的资源文件一般也都存放于这个文件夹中

在 Content 文件夹中，仅有 ProjectContent 文件夹被 Git 所跟踪管理，Content 中的其余文件夹均不会被 Git 跟踪管理

因为一般导入资源包到 UE 项目中时，会默认导入到 Content 文件夹中，在进行开发制作时，请选择所需的相关资源移入 ProjectContent 文件夹中进行同步即可

> Content 文件夹下，除 ProjectContent 文件夹以外的其余所有内容，均不会被 Git 所同步，已在 `.gitignore` 中设置

# 比例尺说明

`Content/ProjectContent/_Map/SandBox` 下的 `Lvl_ThirdPerson` 地图有简易的房屋墙面比例尺参考
