TOOLPATH = ../z_tools/
INCPATH  = ../z_tools/haribote/

MAKE     = $(TOOLPATH)make.exe -r
#NASK汇编成目标代码
NASK     = $(TOOLPATH)nask.exe
#编译城GAC汇编代码
CC1      = $(TOOLPATH)cc1.exe -I$(INCPATH) -Os -Wall -quiet
#GAC格式转NASK格式
GAS2NASK = $(TOOLPATH)gas2nask.exe -a
#链接程序
OBJ2BIM  = $(TOOLPATH)obj2bim.exe

BIM2HRB  = $(TOOLPATH)bim2hrb.exe
RULEFILE = $(TOOLPATH)haribote/haribote.rul
EDIMG    = $(TOOLPATH)edimg.exe
IMGTOL   = $(TOOLPATH)imgtol.com
COPY     = copy
DEL      = del

default:ipl.bin bootpack.bim

#MBR引导区程序
ipl.bin : ipl_2load18s.nas 
	$(NASK) ipl_2load18s.nas ipl.bin

#naskfunc 编译为待链接二进制
naskfunc.obj : naskfunc.nas
	$(NASK) naskfunc.nas naskfunc.obj

#bootpack.c 1 使用cc1 生成gnu汇编样式
bootpack.gas : bootpack.c 
	$(CC1) -o bootpack.gas bootpack.c

#bootpack.c 2 转换gnu汇编样式为nask汇编
bootpack.nas : bootpack.gas 
	$(GAS2NASK) bootpack.gas bootpack.nas

#bootpack.c 3 编译为待链接的二进制文件
bootpack.obj : bootpack.nas
	$(NASK) bootpack.nas bootpack.obj

#链接
bootpack.bim : bootpack.obj naskfunc.obj 
	$(OBJ2BIM) @$(RULEFILE) out:bootpack.bim stack:3136k map:bootpack.map \
		bootpack.obj naskfunc.obj
# 3MB+64KB=3136KB

#链接后的文件添加操作系统能识别的头
bootpack.hrb : bootpack.bim 
	$(BIM2HRB) bootpack.bim bootpack.hrb