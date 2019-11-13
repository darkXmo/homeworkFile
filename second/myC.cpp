#pragma warning( disable : 4996)



#include <fstream>
#include <iostream>
#include <vector>
#include <string>
#include <cstring>
#include <stdio.h>
#include <stdlib.h>

#include <regex>
#include <regex.h>
using namespace std;

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
	BYTE    DIR_Name[8];
	BYTE    DIR_TYPE[3];
	BYTE    DIR_Attr;
	BYTE    Reserved[10];
	WORD    DIR_WrtTime;
	WORD    DIR_WrtDate;
	WORD    DIR_FstClus;
	DWORD   DIR_FileSize;
};

#pragma pack ()

using namespace std;

struct fileItem {
	unsigned int folderNum = 0;
	unsigned long size = 0;
	unsigned int startClus = 0;
	string fileName;
};

struct floderItem {
	unsigned int no = 0;
	unsigned int childFileNum = 0;
	unsigned int childFloderNum= 0;
	unsigned int startClus = 0;
	string floderName;
	vector <floderItem> Floders;
	vector <fileItem> Files;
};

struct command {
	unsigned int type = 0;
	string name;
};

vector<FILE_HEADER> FileHeaders;
PFAT12_HEADER pFAT12Header;
vector <fileItem> fileList;
vector <floderItem> floderList;
unsigned int wRootDirStartSec = 0;
unsigned int floderNum = 1;

unsigned char* pImageBuffer;
void SeekRootDir();
floderItem SeekChildDir(floderItem *root, unsigned int number);
void iSeekChildDir(floderItem* floder);
void catFile(unsigned int floderNum, string name);
DWORD ReadFile(WORD FstClus, unsigned char* outBuffer);
DWORD GetLSB(DWORD ClusOfTable, PFAT12_HEADER pFAT12Header);
WORD GetFATNext(BYTE* FATTable, WORD CurOffset);
DWORD ReadData(DWORD LSB, unsigned char* outBuffer);

void printLS();
void printLSChild(string head, floderItem floder);
void printLSL();
void printLSLChild(string head, floderItem floder);
void printcat(string fileName);

void printB(string input);
void printR(string input);

command coExp(string input);

void printLSc(string name);
void printLSLc(string name);
int gfNum(string name);
floderItem getFloder(unsigned int no);
string getHead(unsigned int no);

char* outputString;
extern "C"{
	void sprint();
	void rsprint();
}	

int main() {

	const char* filePath = "./a.img";
	FILE* pImageFile = fopen(filePath, "rb");

	// fseek 指针位置控制，此时指针指向文件的末尾
	fseek(pImageFile, 0, SEEK_END);

	// 调用ftell函数，指针的大小代表整个文件的偏移量，该方法将返回整个文件的大小
	long lFileSize = ftell(pImageFile);

	// alloc buffer
	// 申请一个空间，这个空间由char为单位（即以一个字节为单位），总共申请这个文件的空间，刚好将整个文件置入缓存（内存）中。
	pImageBuffer = (unsigned char*)malloc(lFileSize);

	if (pImageBuffer == NULL)
	{
		cout << ("Memmory alloc failed!");
		return 1;
	}

	fseek(pImageFile, 0, SEEK_SET);

	// read the whole image file into memmory，将整个文件读进内存。返回值应当是文件大小。
	// 现在整个文件都在这个plmageBuffer中
	long lReadResult = fread(pImageBuffer, 1, lFileSize, pImageFile);

	fclose(pImageFile);

	// 指针，用来指向现在的目标
	// 获得引导区信息
	pFAT12Header = (PFAT12_HEADER)pImageBuffer;
	
	// 获得根目录信息
	SeekRootDir();
	iSeekChildDir(&floderList[0]);

	string input;

	while (input != "exit") {
		printB("> ");
		getline(cin, input);
		input.erase(0, input.find_first_not_of(" "));
		input.erase(input.find_last_not_of(" ") + 1);
		command c = coExp(input);
		if (input == "exit") {
			break;
		}
		if (c.type == 0){
			printB("command not defined\n");
		}
		else if (c.type == 1) {
			printLS();
		}
		else if (c.type == 2) {
			printLSL();
		}
		else if (c.type == 3){
			printLSc(c.name);
		}
		else if (c.type == 4){
			printLSLc(c.name);
		}
		else if (c.type == 5){
			printcat(c.name);
		}
	}
	return 0;
}

void SeekRootDir() {
	// 根目录的起始扇区。
	wRootDirStartSec = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;
	// 根目录的起始字节
	unsigned int dwRootDirStartBytes = wRootDirStartSec * pFAT12Header->BPB_BytesPerSec;
	PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwRootDirStartBytes);
	floderItem root;
	root.no = 0;
	root.floderName = "";
	// 根目录的第一个文件
	while (*(BYTE*)pFileHeader) {
		FILE_HEADER fileHeader = *pFileHeader;
		char buffer[20];
		memcpy(buffer, pFileHeader->DIR_Name, 8);
		buffer[8] = 0;
		string str = buffer;
		str.erase(str.find_last_not_of(" ") + 1);		
		if ((fileHeader.DIR_Attr & 0b00010000) == 0) {
			// 是一个文件
			fileItem item;
			item.folderNum = 0;

			char buffer1[20];
			memcpy(buffer1, pFileHeader->DIR_TYPE, 3);
			buffer1[3] = 0;
			string str1 = buffer1;
			str1.erase(str1.find_last_not_of(" ") + 1);

			item.fileName = str+"."+str1;
			item.size = fileHeader.DIR_FileSize;
			item.startClus = fileHeader.DIR_FstClus;
			fileList.push_back(item);
			root.Files.push_back(item);
			root.childFileNum++;
		}
		else {
			// 是一个子文件夹
			floderItem item;
			item.floderName = str;
			item.startClus = fileHeader.DIR_FstClus;
			item.childFileNum = 0;
			item.childFloderNum = 0;
			item.no = floderNum;
			floderNum++;
			floderList.push_back(item);
			root.Floders.push_back(item);
			root.childFloderNum++;
		}
		FileHeaders.push_back(fileHeader);
		++pFileHeader;
	}
	floderList.insert(floderList.begin(), root);
}

//  查找子目录

floderItem SeekChildDir(floderItem *r, unsigned int number) {
	floderItem root = *r;
	// 用户数据的起始扇区。
	// 用户数据区起始扇区=根目录所占扇区+隐藏扇区+保留扇区+FAT表数*FAT表所占扇区
	unsigned int wChildDirStartSec = pFAT12Header->BPB_RootEntCnt*32 / pFAT12Header->BPB_BytesPerSec + pFAT12Header->BPB_HiddSec +
		pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;
	// 簇起始线性扇区=用户数据区起始扇区+(簇号-2)*每簇所占扇区-1
	unsigned int clusStartSec = wChildDirStartSec + (root.startClus-2) * (pFAT12Header->BPB_SecPerClus);

	// 子目录文件的起始字节
	unsigned int dwChildDirStartBytes = clusStartSec * pFAT12Header->BPB_BytesPerSec;
	unsigned char* s = pImageBuffer + dwChildDirStartBytes;
	PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwChildDirStartBytes);
	pFileHeader += 2;
	// 根目录的第一个文件
	// 根目录的第一个文件
	unsigned int k = 1;
	while (*(BYTE*)pFileHeader) {
		FILE_HEADER fileHeader = *pFileHeader;
		char buffer[20];
		memcpy(buffer, pFileHeader->DIR_Name, 8);
		buffer[8] = 0;
		string str = buffer;
		str.erase(str.find_last_not_of(" ") + 1);
		if ((fileHeader.DIR_Attr & 0b00010000) == 0) {
			// 是一个文件
			fileItem item;
			item.folderNum = root.no;

			char buffer1[20];
			memcpy(buffer1, pFileHeader->DIR_TYPE, 3);
			buffer1[3] = 0;
			string str1 = buffer1;
			str1.erase(str1.find_last_not_of(" ") + 1);

			item.fileName = str + "." + str1;
			item.size = fileHeader.DIR_FileSize;
			item.startClus = fileHeader.DIR_FstClus;
			fileList.push_back(item);
			root.Files.push_back(item);
			root.childFileNum++;
		}
		else {
			// 是一个子文件夹
			floderItem item;
			item.floderName = str;
			item.startClus = fileHeader.DIR_FstClus;
			item.childFileNum = 0;
			item.childFloderNum = 0;
			item.no = root.no + k*10;
			k++;
			root.Floders.push_back(item);
			root.childFloderNum++;
			FileHeaders.push_back(fileHeader);
		}
		++pFileHeader;
	}
	return root;
}

// 迭代遍历查找子目录
void iSeekChildDir(floderItem *floder) {
	if (floder->no == 0) {
		for (unsigned int i = 0; i < floder->childFloderNum; i++) {
			floder->Floders[i].Floders.push_back((*floder).Floders[i]);
			floder->Floders[i].Floders.push_back(*floder);
			floder->Floders[i] = SeekChildDir(&floder->Floders[i], floder->no);
			iSeekChildDir(&floder->Floders[i]);
			floderList[i + 1] = floder->Floders[i];
		}
	}
	else {
		for (unsigned int i = 2; i < floder->childFloderNum + 2; i++) {
			floder->Floders[i].Floders.push_back((*floder).Floders[i]);
			floder->Floders[i].Floders.push_back(*floder);
			floder->Floders[i] = SeekChildDir(&floder->Floders[i], floder->no);
			iSeekChildDir(&floder->Floders[i]);
		}
	}

}

// 读文件最终操作，输入目录项和文件名
void catFile(unsigned int floderNum, string name) {
	unsigned char outBuffer[32768];
	floderItem item = floderList[0];
	floderItem ans;
	if (floderNum != 0) {
		unsigned int n = floderNum % 10;
		floderNum /= 10;
		item = floderList[n];
		while (floderNum != 0) {
			unsigned int n = floderNum % 10;
			floderNum /= 10;
			ans = item.Floders[n + 1];
			item = ans;
		}
	}
	for (unsigned int i = 0; i < item.childFileNum; i++) {
		if (name == item.Files[i].fileName) {
			ReadFile(item.Files[i].startClus, outBuffer);
			string output = (char *)outBuffer;
			printB(output);
			return;
		}
	}

	printB("no such file\n");
	
}


// 读文件 -- 其子函数包括  GetLSB，GetFATNext，ReadData
// ReadFile函数能够根据传入的_FILE_HEADER结构体从传入的ImageBuffer中读出数据，并写到传入的outBuffer中。
DWORD ReadFile(WORD FstClus, unsigned char* outBuffer)
{

	// 获取引导扇区
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// 获取文件名

	// calculate the pointer of FAT Table
	// FAT表所在扇区的所在字节
	BYTE* pbStartOfFATTab = pImageBuffer + (pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt) * pFAT12Header->BPB_BytesPerSec;

	// next是第一个簇（因为是第一个，所有暂时还没NEXT）
	WORD next = FstClus;

	// 循环按字节读
	DWORD readBytes = 0;
	do
	{
		// get the LSB of clus num
		// 得到这个扇区的扇区号
		DWORD dwCurLSB = GetLSB(next, pFAT12Header);

		// read data
		// 读里面的数据
		readBytes += ReadData(dwCurLSB, outBuffer + readBytes);

		// get next clus num according to current clus num
		// 读下一个。
		next = GetFATNext(pbStartOfFATTab, next);

	} while (next <= 0xfef);

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

DWORD ReadData(DWORD LSB, unsigned char* outBuffer)
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

void printLS() {
	// 输出根目录里的内容

	printB("/:\n");

	floderItem item = floderList[0];
	unsigned int fileNum = item.childFileNum;
	unsigned int floderNum = item.childFloderNum;
	string output = "";
	for (unsigned int i = 0; i < floderNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		output += item.Floders[i].floderName;
	}
	if (output != "") {
		output += "  ";
	}
	// print all floder
	printR(output);
	output = "";
	for (unsigned int i = 0; i < fileNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		output += item.Files[i].fileName;
	}
	
	printB(output);


	printB("\n");

	string head = "/";
	for (unsigned int i = 0; i < floderNum; i++) {
		printLSChild(head, item.Floders[i]);
	}

	printB("\n");
}

// 迭代循环输出floder里floder的内容
void printLSChild(string head, floderItem floder) {


	string output;
	output = head +  floder.floderName + "/:\n";
	printB(output);

	output = "";
	unsigned int floderNum = floder.childFloderNum+2;
	for (unsigned int i = 0; i < floderNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		if (i == 0) {
			output += ".";
		}
		else if (i == 1) {

			output += "..";
		}
		else {
			output += floder.Floders[i].floderName;
		}
	}
	if (output != "") {
		output += "  ";
	}
	// print all floder
	printR(output);
	output = "";

	unsigned int fileNum = floder.childFileNum;
	for (unsigned int i = 0; i < fileNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		output += floder.Files[i].fileName;
	}

	printB(output);
	printB("\n");
	output = "";

	head = head + floder.floderName + "/";
	for (unsigned int i = 2; i < floderNum; i++) {
		printLSChild(head, floder.Floders[i]);
	}
}

void printLSL() {
	floderItem root = floderList[0];
	unsigned fdN = root.childFloderNum;
	unsigned flN = root.childFileNum;
	string out = "/ " + to_string(fdN) + " " + to_string(flN) + ":\n";
	printB(out);
	out = "";
	for(unsigned int i=0;i<fdN;i++){
		floderItem floder = root.Floders[i];
		out += floder.floderName;
		printR(out);
		out = "  ";
		out += to_string(floder.childFloderNum) + " " + to_string(floder.childFileNum) + "\n";
		printB(out);
		out = "";
	}
	for (unsigned int i=0;i<flN;i++){
		fileItem f = root.Files[i];
		out += f.fileName;
		printB(out);
		out = "  ";
		out += to_string(f.size) + "\n";
		printB(out);
		out = "";
	}
	printB("\n");
	for (unsigned int i=0;i<fdN;i++){
		printLSLChild("/",root.Floders[i]);
	}
}


void printLSLChild(string head, floderItem root) {
	unsigned fdN = root.childFloderNum;
	unsigned flN = root.childFileNum;
	string out = head + root.floderName + "/ " + to_string(fdN) + " " + to_string(flN) + ":\n";
	printB(out);
	out = "";
	printR(".\n..\n");
	for (unsigned int i=2;i<fdN+2;i++){
		floderItem floder = root.Floders[i];
		out += floder.floderName;
		printR(out);
		out = "  ";
		out += to_string(floder.childFloderNum) + " " + to_string(floder.childFileNum) + "\n";
		printB(out);
		out = "";
	}
	for (unsigned int i=0;i<flN;i++){
		fileItem f = root.Files[i];
		out += f.fileName;
		printB(out);
		out = "  ";
		out += to_string(f.size) + "\n";
		printB(out);
		out = "";
	}
	printB("\n");
	for (unsigned int i=2;i<fdN+2;i++){
		printLSLChild(head+root.floderName+"/",root.Floders[i]);
	}
}




void printB(string input){
	outputString = (char*)input.data();
	sprint();
}

void printR(string input){
	outputString = (char*)input.data();
	rsprint();
}

command coExp(string input){
	command ans;
	ans.type = 0;
	ans.name = "";
	if (input == "ls"){
		ans.type = 1;
		ans.name = "";
		return ans;
	}
	// 定义一个正则表达式 , 4~23 位数字和字母的组合
	regex repPattern2("ls +-l+",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult2;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid2 = regex_match(input, rerResult2, repPattern2);
	if (bValid2)
	{
		ans.type = 2;
		ans.name = "";
		return ans;
	}

	regex repPatternF("\\.[A-Z]+",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResultF;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValidF = regex_search(input, rerResultF, repPatternF);


	if (bValidF)
	{
		if (input.substr(0,2)=="ls"){
			printB("File cannot be lsed. ");
			return ans;
		}
	}



	regex repPattern3("(ls +)((/[0-9A-Z]+)+)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult3;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid3 = regex_match(input, rerResult3, repPattern3);
	if (bValid3)
	{
		ans.type = 3;
		ans.name = rerResult3[2];
		return ans;
	}

	regex repPattern41("(ls +-l+ +)((/[0-9A-Z]+)+)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult41;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid41 = regex_match(input, rerResult41, repPattern41);
	if (bValid41)
	{
		ans.type = 4;
		ans.name = rerResult41[2];
		return ans;
	}

	regex repPattern42("(ls +)((/[0-9A-Z]+)+) +(-l+)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult42;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid42 = regex_match(input, rerResult42, repPattern42);
	if (bValid42)
	{
		ans.type = 4;
		ans.name = rerResult42[2];
		return ans;
	}

	regex repPattern43("(ls +-l+) +((/[0-9A-Z]+)+) +(-l+)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult43;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid43 = regex_match(input, rerResult43, repPattern43);
	if (bValid43)
	{
		ans.type = 4;
		ans.name = rerResult43[2];
		return ans;
	}

	regex repPattern5("(cat) +(((/[0-9A-Z]+)*)(/[A-Z0-9]+(.[A-Z]+)?))$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult5;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid5 = regex_match(input, rerResult5, repPattern5);
	if (bValid5)
	{
		ans.type = 5;
		ans.name = rerResult5[2];
		return ans;
	}

	regex repPattern51("(cat) +([A-Z0-9]+(.[A-Z]+)?)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> rerResult51;
	// 定义待匹配的字符串
	// 进行匹配
	bool bValid51 = regex_match(input, rerResult51, repPattern51);
	if (bValid51)
	{
		ans.type = 5;
		string r = "/";
		r += rerResult51[2];
		ans.name = r;
		return ans;
	}
	return ans;
}

int gfNum(string name){
	unsigned int ans = 0;
	smatch result;
	regex pattern("(/[0-9A-Z]+)");

	//迭代器声明
	string::const_iterator iterStart = name.begin();
	string::const_iterator iterEnd = name.end();
	string temp;

	vector <string> fl;
	while (regex_search(name, result, pattern))
	{
		temp = result[0];
		fl.push_back(temp.substr(1));
		name = result.suffix().str();
	}
	unsigned int size = fl.size();

	floderItem root = floderList[0];
	unsigned int flN = root.childFloderNum;
	string floderName = fl[0];
	bool notFound = true;
	for (unsigned int i=0;i<flN;i++){
		floderItem floder = root.Floders[i];
		string n = floder.floderName;
		if (n == floderName) {
			root = floder;
			notFound = false;
			break;
		}
	}
	if (notFound){
		return -1;
	}
	if (size == 1){
		return root.no;
	}
	for(unsigned int i=1;i<size;i++){
		flN = root.childFloderNum;
		floderName = fl[i];
		notFound = true;
		for (unsigned int i=2;i<flN+2;i++){
			floderItem floder = root.Floders[i];
			string n = floder.floderName;
			if (n == floderName) {
				root = floder;
				notFound = false;
				break;
			}
		}
		if (notFound){
			return -1;
		}
	}
	return root.no;
}

void printLSc(string name){
	int fN = gfNum(name);
	if (fN == -1){
		printB("floder not found!\n");
	}
	else {
		floderItem floder = getFloder(fN);
		string head = getHead(fN);
		printLSChild(head, floder);
		printB("\n");
	}
	
}

void printLSLc(string name){
	int fN = gfNum(name);
	if (fN == -1){
		printB("floder not found!\n");
	}
	else {
		floderItem floder = getFloder(fN);
		string head = getHead(fN);
		printLSLChild(head, floder);
		printB("\n");
	}
}

void printcat(string name) {
	string filename;
	regex Pattern("(/[A-Z0-9]+(.[A-Z]+)?)$",regex_constants::extended);
	// 声明匹配结果变量
	match_results<string::const_iterator> Result;
	// 定义待匹配的字符串
	// 进行匹配
	bool isAfile = regex_match(name, Result, Pattern);
	if (isAfile){
		catFile(0, name.substr(1));
	}
	else {
		smatch m;
		regex_search(name, m, Pattern);
		filename = m[0];
		unsigned int floL = name.length() - filename.length(); 
		string floderPath = name.substr(0, floL);
		int fN = gfNum(floderPath);
		if (fN == -1){
			printB("floder not found!\n");
		}
		else {
			catFile(fN, filename.substr(1));
		}
	}

}

floderItem getFloder(unsigned int no){
	if (no == 0){
		return floderList[0];
	}
	if (no < 10){
		return floderList[no];
	}
	unsigned int i = no % 10;
	no /= 10;
	floderItem ans = floderList[i];
	while(no > 0){
		i = no % 10;
		no /= 10;
		ans = ans.Floders[i+1];
	}
	return ans;
}

string getHead(unsigned int no){
	if (no < 10){
		return "/";
	}
	unsigned int i = no % 10;
	no /= 10;
	floderItem ans = floderList[i];
	string res = "";
	while(no > 0){
		i = no % 10;
		no /= 10;
		res = "/" + ans.floderName;
		ans = ans.Floders[i+1];
	}
	res += "/";
	return res;
}