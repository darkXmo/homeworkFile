#pragma warning( disable : 4996)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cstring>
#include <string>
#include <vector>

#define BYTE    unsigned char
#define WORD    unsigned short
#define DWORD   unsigned int

#define BOOT_START_ADDR 0x7c00

typedef struct _FAT12_HEADER FAT12_HEADER;
typedef struct _FAT12_HEADER* PFAT12_HEADER;

#pragma pack (1)

struct _FAT12_HEADER {
	BYTE    JmpCode[3];
	BYTE    BS_OEMName[8];
	WORD    BPB_BytesPerSec;
	BYTE    BPB_SecPerClus;
	WORD    BPB_RsvdSecCnt;
	BYTE    BPB_NumFATs;
	WORD    BPB_RootEntCnt;
	WORD    BPB_TotSec16;
	BYTE    BPB_Media;
	WORD    BPB_FATSz16;
	WORD    BPB_SecPerTrk;
	WORD    BPB_NumHeads;
	DWORD   BPB_HiddSec;
	DWORD   BPB_TotSec32;
	BYTE    BS_DrvNum;
	BYTE    BS_Reserved1;
	BYTE    BS_BootSig;
	DWORD   BS_VolID;
	BYTE    BS_VolLab[11];
	BYTE    BS_FileSysType[8];
};

typedef struct _FILE_HEADER FILE_HEADER;
typedef struct _FILE_HEADER* PFILE_HEADER;

struct _FILE_HEADER {
	BYTE    DIR_Name[11];
	BYTE    DIR_Attr;
	BYTE    Reserved[10];
	WORD    DIR_WrtTime;
	WORD    DIR_WrtDate;
	WORD    DIR_FstClus;
	DWORD   DIR_FileSize;
};

#pragma pack ()

struct FileItem {
	unsigned int FileNo;
	string filename;
	unsigned int type;
	DWORD startLSB;
	vector<string> children;
};

void PrintImage(unsigned char* pImageBuffer);

FILE_HEADER FileHeaders[30];

void SeekRootDir(unsigned char* pImageBuffer);

DWORD ReadFile(unsigned char* pImageBuffer, PFILE_HEADER pFileHeader, unsigned char* outBuffer);

DWORD GetLSB(DWORD ClusOfTable, PFAT12_HEADER pFAT12Header);

WORD GetFATNext(BYTE* FATTable, WORD CurOffset);

DWORD ReadData(unsigned char* pImageBuffer, DWORD LSB, unsigned char* outBuffer);

using namespace std;

vector<FileItem> FileList;

int main() {

	const char* filePath = "../../../ref.img";
	FILE* pImageFile = fopen(filePath, "rb");

	// fseek 指针位置控制，此时指针指向文件的末尾
	fseek(pImageFile, 0, SEEK_END);

	// 调用ftell函数，指针的大小代表整个文件的偏移量，该方法将返回整个文件的大小
	long lFileSize = ftell(pImageFile);

	printf("Image size: %ld\n", lFileSize);

	// alloc buffer
	// 申请一个空间，这个空间由char为单位（即以一个字节为单位），总共申请这个文件的空间，刚好将整个文件置入缓存（内存）中。
	unsigned char* pImageBuffer = (unsigned char*)malloc(lFileSize);

	// 判断申请是否成功
	if (pImageBuffer == NULL)
	{
		puts("Memmory alloc failed!");
		return 1;
	}

	// 将指针回到文件首位
	fseek(pImageFile, 0, SEEK_SET);

	// read the whole image file into memmory，将整个文件读进内存。返回值应当是文件大小。
	long lReadResult = fread(pImageBuffer, 1, lFileSize, pImageFile);

	printf("Read size: %ld\n", lReadResult);

	// 判断读入是否正常
	if (lReadResult != lFileSize)
	{
		puts("Read file error!");
		free(pImageBuffer);
		fclose(pImageFile);
		return 1;
	}

	// finish reading, close file 结束读取，已经进内存了
	fclose(pImageFile);


	// print FAT12 structure 输出内存结构信息
	PrintImage(pImageBuffer);

	
	// seek files of root directory  输出img根目录内容
	SeekRootDir(pImageBuffer);


	// file read buffer
	unsigned char outBuffer[4096];

	// read file 0
	DWORD fileSize = ReadFile(pImageBuffer, &FileHeaders[2], outBuffer);

	printf("File size: %u, file content: \n%s", fileSize, outBuffer);

	getchar();

	return 0;
}

void PrintImage(unsigned char* pImageBuffer)
{
	puts("\nStart to print image:\n");

	// 结构体的指针对其buffer的指针，因为pImageBuffer的首地址开始就是_FAT12_HEADER结构体。
	// 直接将读到内存中的镜像文件首地址传给FAT12_HEADER结构体指针，进行强制转化，就能对各字段进行读取了。
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// calculate start address of boot program
	// BOOT_START_ADDR表示Boot扇区在内存中的加载起始地址位0x7c00。
	// 将BOOT_START_ADDR（Boot扇区读到内存中的首地址）加上跳转Offset再加上2就能得到引导程序的首地址了。
	WORD wBootStart = BOOT_START_ADDR + pFAT12Header->JmpCode[1] + 2;
	printf("Boot start address: 0x%04x\n", wBootStart);

	char buffer[20];

	memcpy(buffer, pFAT12Header->BS_OEMName, 8);
	buffer[8] = 0;

	printf("BS_OEMName:         %s\n", buffer);
	printf("BPB_BytesPerSec:    %u\n", pFAT12Header->BPB_BytesPerSec);
	printf("BPB_SecPerClus:     %u\n", pFAT12Header->BPB_SecPerClus);
	printf("BPB_RsvdSecCnt:     %u\n", pFAT12Header->BPB_RsvdSecCnt);
	printf("BPB_NumFATs:        %u\n", pFAT12Header->BPB_NumFATs);
	printf("BPB_RootEntCnt:     %u\n", pFAT12Header->BPB_RootEntCnt);
	printf("BPB_TotSec16:       %u\n", pFAT12Header->BPB_TotSec16);
	printf("BPB_Media:          0x%02x\n", pFAT12Header->BPB_Media);
	printf("BPB_FATSz16:        %u\n", pFAT12Header->BPB_FATSz16);
	printf("BPB_SecPerTrk:      %u\n", pFAT12Header->BPB_SecPerTrk);
	printf("BPB_NumHeads:       %u\n", pFAT12Header->BPB_NumHeads);
	printf("BPB_HiddSec:        %u\n", pFAT12Header->BPB_HiddSec);
	printf("BPB_TotSec32:       %u\n", pFAT12Header->BPB_TotSec32);
	printf("BS_DrvNum:          %u\n", pFAT12Header->BS_DrvNum);
	printf("BS_Reserved1:       %u\n", pFAT12Header->BS_Reserved1);
	printf("BS_BootSig:         %u\n", pFAT12Header->BS_BootSig);
	printf("BS_VolID:           %u\n", pFAT12Header->BS_VolID);

	memcpy(buffer, pFAT12Header->BS_VolLab, 11);
	buffer[11] = 0;
	printf("BS_VolLab:          %s\n", buffer);

	memcpy(buffer, pFAT12Header->BS_FileSysType, 8);
	buffer[11] = 0;
	printf("BS_FileSysType:     %s\n", buffer);
}

void SeekRootDir(unsigned char* pImageBuffer)
{
	// 跟之前一样，将内存指针指向缓存头部
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	puts("\nStart seek files of root dir:");

	// sectors number of start of root directory
	// 计算出了根目录的起始扇区。计算方法为：隐藏扇区数 + 保留扇区数(Boot Sector) + FAT表数量 × FAT表大小(Sectors)。
	// 也就是将根目录前面所有的扇区数加起来。
	DWORD wRootDirStartSec = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;

	printf("Start sector of root directory:    %u\n", wRootDirStartSec);

	// bytes num of start of root directory
	// 将其乘上每扇区的字节数就能得到根目录的起始字节偏移了
	DWORD dwRootDirStartBytes = wRootDirStartSec * pFAT12Header->BPB_BytesPerSec;
	printf("Start bytes of root directory:      %u\n", dwRootDirStartBytes);

	// 现在引入新的结构体，File_Header，和PFAT12_Header一样，直接进行指针的赋予
	PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwRootDirStartBytes);

	int fileNum = 1;
	// 文件的序号

	// 之后就能够对这个结构体进行操作，然后使用++pFileHeader;来遍历根目录。 
	// 根据pFileHeader的第一个Byte是否为0x00来判断是否到达最后一个文件
	// （这个判断是不对的，中间有文件可能被删除，而且可能隔着0x00后面还有有效文件，所以这里需要后续再改。
	// 但是仅仅针对这一个构造的Image是有效的，就暂时用着了）。最终得到的文件都放入FileHeaders中。
	while (*(BYTE*)pFileHeader)
	{
		// copy file header to the array
		FileHeaders[fileNum - 1] = *pFileHeader;

		char buffer[20];
		memcpy(buffer, pFileHeader->DIR_Name, 11);
		buffer[11] = 0;

		printf("File no.            %d\n", fileNum);
		printf("File name:          %s\n", buffer);
		printf("File attributes:    0x%02x\n", pFileHeader->DIR_Attr);
		// 属性 attribute
		// 00000000：普通文件，可随意读写
		// 00000001：只读文件，不可改写
		// 00000010：隐藏文件，浏览文件时隐藏列表
		// 00000100：系统文件，删除的时候会有提示
		// 00001000：卷标，作为磁盘的卷标识符
		// 00010000：目录文件，此文件是一个子目录，它的内容就是此目录下的所有文件目录项
		// 00100000：归档文件

		printf("First clus num:     %u\n\n", pFileHeader->DIR_FstClus);

		++pFileHeader;
		++fileNum;
	}
}

// 读文件 -- 其子函数包括  GetLSB，GetFATNext，ReadData
// ReadFile函数能够根据传入的_FILE_HEADER结构体从传入的ImageBuffer中读出数据，并写到传入的outBuffer中。
DWORD ReadFile(unsigned char* pImageBuffer, PFILE_HEADER pFileHeader, unsigned char* outBuffer)
{

	// 获取引导扇区
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// 获取文件名
	char nameBuffer[20];
	memcpy(nameBuffer, pFileHeader->DIR_Name, 11);
	nameBuffer[11] = 0;

	printf("The FAT chain of file %s:\n", nameBuffer);

	// calculate the pointer of FAT Table
	// FAT表所在扇区的所在字节
	BYTE* pbStartOfFATTab = pImageBuffer + (pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt) * pFAT12Header->BPB_BytesPerSec;

	// next是第一个簇（因为是第一个，所有暂时还没NEXT）
	WORD next = pFileHeader->DIR_FstClus;

	// 循环按字节读
	DWORD readBytes = 0;
	do
	{
		printf(", 0x%03x", next);

		// get the LSB of clus num
		// 得到这个扇区的扇区号
		DWORD dwCurLSB = GetLSB(next, pFAT12Header);

		// read data
		// 读里面的数据
		readBytes += ReadData(pImageBuffer, dwCurLSB, outBuffer + readBytes);

		// get next clus num according to current clus num
		// 读下一个。
		next = GetFATNext(pbStartOfFATTab, next);

	} while (next <= 0xfef);

	puts(""); // 输出

	return readBytes;
}

// 传入簇和PFAT12头文件，获取簇内容 
// GetLSB用来计算出给出的FAT表项对应在数据区的扇区号。
DWORD GetLSB(DWORD ClusOfTable, PFAT12_HEADER pFAT12Header)
{
	// 就是将数据区前面所有的扇区号都加起来，得到“数据区”的起始扇区，
	// 然后将给出的FAT项减2（前两项是废物），再乘上每簇的扇区数，加上数据区的起始扇区号，最后就得到了当前FAT项的LSB。

	// 用户数据区起始扇区=隐藏扇区+保留扇区+FAT表数*FAT表所占扇区+根目录所占扇区
	DWORD dwDataStartClus = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16 + \
		pFAT12Header->BPB_RootEntCnt * 32 / pFAT12Header->BPB_BytesPerSec;

	// 簇起始线性扇区=用户数据区起始扇区+(簇号-2)*每簇所占扇区-1
	return dwDataStartClus + (ClusOfTable - 2) * pFAT12Header->BPB_SecPerClus;
}

// GetFATNext根据当前给出的FAT表项，得到它在FAT表里的下一项。其实现如下。
WORD GetFATNext(BYTE* FATTable, WORD CurOffset)
{
	// 先用传来的FAT表项×1.5得到实际需要读取的值在FAT表中的Bytes偏移，然后用一个WORD来存储它。 
	
	// 字节偏移
	WORD tabOff = CurOffset * 1.5;

	WORD nextOff = *(WORD*)(FATTable + tabOff);

	// 接着，判断这个偏移是奇数还是偶数。如果是奇数，则将前4位清0(与上0x0fff)，如果是偶数，则将其右移4位，最终得到下一项的FAT表偏移。 
	nextOff = CurOffset % 2 == 0 ? nextOff & 0x0fff : nextOff >> 4;

	// 返回下一项的FAT表偏移
	return nextOff;
}

// 计算出传入的LSB在镜像Buffer中的位置(Bytes)，然后写到传入的outBuffer中。

DWORD ReadData(unsigned char* pImageBuffer, DWORD LSB, unsigned char* outBuffer)
{
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// 使用LSB×每扇区的字节数，得到要读的扇区的字节起始值

	// 扇区字节起始值
	DWORD dwReadPosBytes = LSB * pFAT12Header->BPB_BytesPerSec;

	// 然后用memcpy将ImageBuffer的ReadPosBytes偏移处的数据写到outBuffer中，
	// 写入长度是每簇的扇区数与每扇区的字节数的积，也就是每簇的字节数。
	memcpy(outBuffer, pImageBuffer + dwReadPosBytes, pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec);

	// 返回每个簇所占扇区数 * 每个扇区所占比特数，即簇所占的比特数 
	return pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec;
}
