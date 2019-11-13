#pragma warning( disable : 4996)

#include <fstream>
#include <iostream>
#include <vector>
#include <string>

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
void printLSLChind(string head, floderItem floder);
void printcat(floderItem floder, string fileName);

char* outputString;

int main() {
	const char* filePath = "../../../nju.img";
	FILE* pImageFile = fopen(filePath, "rb");

	// fseek ָ��λ�ÿ��ƣ���ʱָ��ָ���ļ���ĩβ
	fseek(pImageFile, 0, SEEK_END);

	// ����ftell������ָ��Ĵ�С���������ļ���ƫ�������÷��������������ļ��Ĵ�С
	long lFileSize = ftell(pImageFile);

	// alloc buffer
	// ����һ���ռ䣬����ռ���charΪ��λ������һ���ֽ�Ϊ��λ�����ܹ���������ļ��Ŀռ䣬�պý������ļ����뻺�棨�ڴ棩�С�
	pImageBuffer = (unsigned char*)malloc(lFileSize);

	if (pImageBuffer == NULL)
	{
		printf_s("Memmory alloc failed!");
		return 1;
	}

	fseek(pImageFile, 0, SEEK_SET);

	// read the whole image file into memmory���������ļ������ڴ档����ֵӦ�����ļ���С��
	// ���������ļ��������plmageBuffer��
	long lReadResult = fread(pImageBuffer, 1, lFileSize, pImageFile);

	fclose(pImageFile);

	// ָ�룬����ָ�����ڵ�Ŀ��
	// �����������Ϣ
	pFAT12Header = (PFAT12_HEADER)pImageBuffer;
	
	// ��ø�Ŀ¼��Ϣ
	SeekRootDir();
	iSeekChildDir(&floderList[0]);

	string input;

	// TODO:
	outputString = (char*)"> ";

	while (input != "exit") {
		// TODO
		outputString = (char*)"> ";
		cout << outputString;
		getline(cin, input);
		input.erase(0, input.find_first_not_of(" "));
		input.erase(input.find_last_not_of(" ") + 1);
		if (input.compare("ls") == 0) {
			printLS();
		}
		if (input.compare("ls -l") == 0) {
			printLSL();
		}
	}
	return 0;
}

void SeekRootDir() {
	// ��Ŀ¼����ʼ������
	wRootDirStartSec = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;
	// ��Ŀ¼����ʼ�ֽ�
	unsigned int dwRootDirStartBytes = wRootDirStartSec * pFAT12Header->BPB_BytesPerSec;
	PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwRootDirStartBytes);
	floderItem root;
	root.no = 0;
	root.floderName = "";
	// ��Ŀ¼�ĵ�һ���ļ�
	while (*(BYTE*)pFileHeader) {
		FILE_HEADER fileHeader = *pFileHeader;
		char buffer[20];
		memcpy(buffer, pFileHeader->DIR_Name, 8);
		buffer[8] = 0;
		string str = buffer;
		str.erase(str.find_last_not_of(" ") + 1);		
		if ((fileHeader.DIR_Attr & 0b00010000) == 0) {
			// ��һ���ļ�
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
			// ��һ�����ļ���
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

//  ������Ŀ¼

floderItem SeekChildDir(floderItem *r, unsigned int number) {
	floderItem root = *r;
	// �û����ݵ���ʼ������
	// �û���������ʼ����=��Ŀ¼��ռ����+��������+��������+FAT����*FAT����ռ����
	unsigned int wChildDirStartSec = pFAT12Header->BPB_RootEntCnt*32 / pFAT12Header->BPB_BytesPerSec + pFAT12Header->BPB_HiddSec +
		pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16;
	// ����ʼ��������=�û���������ʼ����+(�غ�-2)*ÿ����ռ����-1
	unsigned int clusStartSec = wChildDirStartSec + (root.startClus-2) * (pFAT12Header->BPB_SecPerClus);

	// ��Ŀ¼�ļ�����ʼ�ֽ�
	unsigned int dwChildDirStartBytes = clusStartSec * pFAT12Header->BPB_BytesPerSec;
	unsigned char* s = pImageBuffer + dwChildDirStartBytes;
	PFILE_HEADER pFileHeader = (PFILE_HEADER)(pImageBuffer + dwChildDirStartBytes);
	pFileHeader += 2;
	// ��Ŀ¼�ĵ�һ���ļ�
	// ��Ŀ¼�ĵ�һ���ļ�
	unsigned int k = 1;
	while (*(BYTE*)pFileHeader) {
		FILE_HEADER fileHeader = *pFileHeader;
		char buffer[20];
		memcpy(buffer, pFileHeader->DIR_Name, 8);
		buffer[8] = 0;
		string str = buffer;
		str.erase(str.find_last_not_of(" ") + 1);
		if ((fileHeader.DIR_Attr & 0b00010000) == 0) {
			// ��һ���ļ�
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
			// ��һ�����ļ���
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

// ��������������Ŀ¼
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

// ���ļ����ղ���������Ŀ¼����ļ���
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
			// TODO:
			outputString = (char *)outBuffer;
			cout << outputString;
			return;
		}
	}
	// TODO:
	printf("no such file\n");

	
}


// ���ļ� -- ���Ӻ�������  GetLSB��GetFATNext��ReadData
// ReadFile�����ܹ����ݴ����_FILE_HEADER�ṹ��Ӵ����ImageBuffer�ж������ݣ���д�������outBuffer�С�
DWORD ReadFile(WORD FstClus, unsigned char* outBuffer)
{

	// ��ȡ��������
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// ��ȡ�ļ���

	// calculate the pointer of FAT Table
	// FAT�����������������ֽ�
	BYTE* pbStartOfFATTab = pImageBuffer + (pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt) * pFAT12Header->BPB_BytesPerSec;

	// next�ǵ�һ���أ���Ϊ�ǵ�һ����������ʱ��ûNEXT��
	WORD next = FstClus;

	// ѭ�����ֽڶ�
	DWORD readBytes = 0;
	do
	{
		// get the LSB of clus num
		// �õ����������������
		DWORD dwCurLSB = GetLSB(next, pFAT12Header);

		// read data
		// �����������
		readBytes += ReadData(dwCurLSB, outBuffer + readBytes);

		// get next clus num according to current clus num
		// ����һ����
		next = GetFATNext(pbStartOfFATTab, next);

	} while (next <= 0xfef);

	return readBytes;
}

// ����غ�PFAT12ͷ�ļ�����ȡ������ 
// GetLSB���������������FAT�����Ӧ���������������š�
DWORD GetLSB(DWORD ClusOfTable, PFAT12_HEADER pFAT12Header)
{
	// ���ǽ�������ǰ�����е������Ŷ����������õ���������������ʼ������
	// Ȼ�󽫸�����FAT���2��ǰ�����Ƿ�����ٳ���ÿ�ص�����������������������ʼ�����ţ����͵õ��˵�ǰFAT���LSB��

	// �û���������ʼ����=��������+��������+FAT����*FAT����ռ����+��Ŀ¼��ռ����
	DWORD dwDataStartClus = pFAT12Header->BPB_HiddSec + pFAT12Header->BPB_RsvdSecCnt + pFAT12Header->BPB_NumFATs * pFAT12Header->BPB_FATSz16 + \
		pFAT12Header->BPB_RootEntCnt * 32 / pFAT12Header->BPB_BytesPerSec;

	// ����ʼ��������=�û���������ʼ����+(�غ�-2)*ÿ����ռ����-1
	return dwDataStartClus + (ClusOfTable - 2) * pFAT12Header->BPB_SecPerClus;
}

// GetFATNext���ݵ�ǰ������FAT����õ�����FAT�������һ���ʵ�����¡�
WORD GetFATNext(BYTE* FATTable, WORD CurOffset)
{
	// ���ô�����FAT�����1.5�õ�ʵ����Ҫ��ȡ��ֵ��FAT���е�Bytesƫ�ƣ�Ȼ����һ��WORD���洢���� 

	// �ֽ�ƫ��
	WORD tabOff = CurOffset * 1.5;

	WORD nextOff = *(WORD*)(FATTable + tabOff);

	// ���ţ��ж����ƫ������������ż�����������������ǰ4λ��0(����0x0fff)�������ż������������4λ�����յõ���һ���FAT��ƫ�ơ� 
	nextOff = CurOffset % 2 == 0 ? nextOff & 0x0fff : nextOff >> 4;

	// ������һ���FAT��ƫ��
	return nextOff;
}

// ����������LSB�ھ���Buffer�е�λ��(Bytes)��Ȼ��д�������outBuffer�С�

DWORD ReadData(DWORD LSB, unsigned char* outBuffer)
{
	PFAT12_HEADER pFAT12Header = (PFAT12_HEADER)pImageBuffer;

	// ʹ��LSB��ÿ�������ֽ������õ�Ҫ�����������ֽ���ʼֵ

	// �����ֽ���ʼֵ
	DWORD dwReadPosBytes = LSB * pFAT12Header->BPB_BytesPerSec;

	// Ȼ����memcpy��ImageBuffer��ReadPosBytesƫ�ƴ�������д��outBuffer�У�
	// д�볤����ÿ�ص���������ÿ�������ֽ����Ļ���Ҳ����ÿ�ص��ֽ�����
	memcpy(outBuffer, pImageBuffer + dwReadPosBytes, pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec);

	// ����ÿ������ռ������ * ÿ��������ռ��������������ռ�ı����� 
	return pFAT12Header->BPB_SecPerClus * pFAT12Header->BPB_BytesPerSec;
}

void printLS() {
	// �����Ŀ¼�������

	// TODO :
	outputString = (char*)"/:\n";
	cout << outputString;

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
	for (unsigned int i = 0; i < fileNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		output += item.Files[i].fileName;
	}
	
	outputString = (char*)output.data();
	// TODO : 
	cout << outputString;

	string head = "/";
	for (unsigned int i = 0; i < floderNum; i++) {
		printLSChild(head, item.Floders[i]);
	}

	// TODO :
	outputString = (char*) ("\n");
	cout << outputString;
}

// ����ѭ�����floder��floder������
void printLSChild(string head, floderItem floder) {

	// TODO :
	outputString = (char*)"\n";
	cout << outputString;

	string output;
	output = head +  floder.floderName + "/:\n";
	outputString = (char*)output.data();
	// TODO
	cout << outputString;

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
	unsigned int fileNum = floder.childFileNum;
	for (unsigned int i = 0; i < fileNum; i++) {
		if (i != 0) {
			output += "  ";
		}
		output += floder.Files[i].fileName;
	}

	outputString = (char*)output.data();
	// TODO : 
	cout << outputString;

	head = head + floder.floderName + "/";
	for (unsigned int i = 2; i < floderNum; i++) {
		printLSChild(head, floder.Floders[i]);
	}
}

void printLSL() {

}
void printLSLChind(string head, floderItem floder) {

}

void printcat(floderItem floder, string fileName) {

}