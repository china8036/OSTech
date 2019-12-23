; haribote-ipl
; TAB=4
;使用nask编译器编译操作系统无关二进制文件 然后使用dd写入磁盘

CYLS	EQU		10				; 声明CYLS=10

; 指明程序被装载地址bios会自动装载启动盘第一扇区512字节到0x7c00并跳到此处执行 此处告诉汇编器内存地址自动加0x7c00
		ORG		0x7c00			
; 标准FAT12格式软盘专用的代码 Stand FAT12 format floppy code 第一扇区一般用来描述磁盘的文件系统格式 如fat32 ntfs此处格式化成fat12系统样式
		JMP		entry           ; 因为下面为fat文件系统描述 非操作指令 所以第一条指令跳到指令区
		DB		0x90 			; 开始格式化成fat12文件系统结构
		DB		"HARIBOTE"		; 启动扇区名称（8字节）
		DW		512				; 每个扇区（sector）大小（必须512字节）
		DB		1				; 簇（cluster）大小（必须为1个扇区）
		DW		1				; FAT起始位置（一般为第一个扇区）
		DB		2				; FAT个数（必须为2）
		DW		224				; 根目录大小（一般为224项）
		DW		2880			; 该磁盘大小（必须为2880扇区1440*1024/512）
		DB		0xf0			; 磁盘类型（必须为0xf0）
		DW		9				; FAT的长度（必??9扇区）
		DW		18				; 一个磁道（track）有几个扇区（必须为18）
		DW		2				; 磁头数（必??2）
		DD		0				; 不使用分区，必须是0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明（固定）
		DD		0xffffffff		; （可能是）卷标号码
		DB		"HARIBOTEOS "	; 磁盘的名称（必须为11字?，不足填空格）
		DB		"FAT12   "		; 磁盘格式名称（必??8字?，不足填空格）
		RESB	18				; 先空出18字节

; 程序主体

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820
		MOV		ES,AX           ;es：bx指向接收从扇区读入数据的内存区
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0
		MOV		CL,2			; 扇区2

readloop:
		MOV		SI,0			; 记录失败次数寄存器

retry:
		MOV		AH,0x02			; AH=0x02 : 读入磁盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0            ; es：bx指向接收从扇区读入数据的内存区
		MOV		DL,0x80			; 软驱从0开始，0：软驱A，1：软驱B；硬盘从80h开始，
		INT		0x13			; 调用磁盘BIOS
		JNC		next			; 没出错则跳转到fin
		ADD		SI,1			; 往SI加1
		CMP		SI,5			; 比较SI与5 
		JAE		error			; SI >= 5 跳转到error 重试五次仍然失败后报错 AH里有错误号
		MOV		AX,0x0000       ; 每次出错都重置驱动器
		MOV		DX,0x0080		; 
		INT		0x13			; 重置驱动器
		JMP		retry
next:
		MOV		AX,ES			; 把内存地址后移0x200（512/16十六进制转换）
		ADD		AX,0x0020
		MOV		ES,AX			; ADD ES,0x020因为没有ADD ES，只能通过AX进行
		ADD		CL,1			; 往CL里面加1
		CMP		CL,18			; 比较CL与18
		JBE		readloop		; CL <= 18 跳转到readloop
		MOV		CL,1                  
		ADD		DH,1            ; 下一个磁头
		CMP		DH,2            ; 磁头2结束
		JB		readloop		; DH < 2 跳转到readloop
		MOV		DH,0
		ADD		CH,1            ; 下一个柱面
		CMP		CH,CYLS         ; 到CYLS柱面结束
		JB		readloop		; CH < CYLS 跳转到readloop

; 读取完毕，跳转到haribote.sys执行！
		MOV		[0x0ff0],CH		;
		JMP		0xc200

error:
		MOV		SI,msg ;msg内存地址赋予SI AH里有错误号
		MOV     AL,AH  ; error 下面的为自己添加方便输出AH错误码
		SHR     AL,7
		ADD 	AL,48
		MOV     [SI+20],AL  ;ascii 48为0
		MOV 	AL,AH
		SHL  	AL,1
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+21],AL
		MOV 	AL,AH
		SHL  	AL,2
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+22],AL
		MOV 	AL,AH
		SHL  	AL,3
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+23],AL
		MOV 	AL,AH
		SHL  	AL,4
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+24],AL
		MOV 	AL,AH
		SHL  	AL,5
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+25],AL
		MOV 	AL,AH
		SHL  	AL,6
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+26],AL
		MOV 	AL,AH
		SHL  	AL,7
		SHR  	AL,7
		ADD 	AL,48
		MOV     [SI+27],AL


putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 给SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡BIOS
		JMP		putloop

fin:
		HLT						; 让CPU停止，等待指令
		JMP		fin				; 无限循环

msg:
		DB		0x0a, 0x0a		; 换行两次
		DB		"load error CODE:8xxxxxxxx" ;xxx预留为AH错误码填充
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x001fe

		DB		0x55, 0xaa