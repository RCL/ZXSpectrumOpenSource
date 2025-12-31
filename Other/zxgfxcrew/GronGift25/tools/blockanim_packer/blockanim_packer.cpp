#define _CRT_SECURE_NO_WARNINGS
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <memory>
#include <thread>
#include <atomic>
#include <assert.h>
#include <filesystem>
#include <fstream>

#include "file_util.h"

struct SpeccyScreen
{
	unsigned char Bitmap[6144];
	unsigned char Attrs[768];
};

static_assert(sizeof(SpeccyScreen) == 6912);

bool SaveMemWithExt(const char* OrgName, const char* ExtraExt, const unsigned char* Memory, size_t MemSize, size_t FrameNumber = size_t(-1))
{
	// save the file with a new extension, overwriting existing
	char Name[128];
	if (FrameNumber == size_t(-1))
	{
		snprintf(Name, sizeof(Name), "%s.%s", OrgName, ExtraExt);
	}
	else
	{
		snprintf(Name, sizeof(Name), "%s.%llu.%s", OrgName, FrameNumber, ExtraExt);
	}

	FILE* Fp = fopen(Name, "wb");
	if (!Fp)
	{
		return false;
	}

	fwrite(Memory, 1, MemSize, Fp);
	fclose(Fp);

	return true;
}

bool ReadScrSequence(const char* Filename, std::vector<SpeccyScreen>& OutScreens)
{
	std::vector<std::filesystem::path> SortedPaths = FileUtils::GetFilesSorted(Filename);

	if (SortedPaths.empty())
	{
		return false;
	}

	size_t NumFrames = SortedPaths.size();

	OutScreens.resize(NumFrames);
	for (unsigned long Idx = 0; Idx < NumFrames; ++Idx)
	{
		std::filesystem::path& FilePath = SortedPaths[Idx];

		std::error_code Error;
		if (!std::filesystem::exists(FilePath, Error) ||
			!std::filesystem::is_regular_file(FilePath, Error))
		{
			return false;
		}

		std::ifstream File(FilePath, std::ios::binary | std::ios::ate);
		if (!File.is_open())
		{
			return false;
		}

		const uint64_t FileSize = static_cast<uint64_t>(std::filesystem::file_size(FilePath, Error));

		// refuse to load files bigger than SCR
		if (Error || FileSize == 0 || FileSize != 6912)
		{
			return false;
		}

		File.seekg(0, std::ios::beg);
		SpeccyScreen& Scr = OutScreens[Idx];

		File.read(reinterpret_cast<char*>(Scr.Bitmap), 6144);
		File.read(reinterpret_cast<char*>(Scr.Attrs), 768);

		if (!File.good())
		{
			return false;
		}
	}

	return true;
}

struct Difference
{
	// which value we need to set
	unsigned char Value;
	// which value we expect to see there
	unsigned char PrevValue;
};

// takes: address in SCR file (0-6911)
// returns: block address in 32x24 grid, treating the grid as laid out by rows,
//  so e.g. X=20 Y=10 will have an index 10*32 + 20 = 340
size_t GetBlockFromAddress(size_t AddrInSCRFile)
{
	if (AddrInSCRFile < 6144)
	{
		// in Z80 code, if DE is a screen addr, it's attr address is calculated like this:
		//	ld a, d
		//	rra
		//	rra
		//	rra
		//	and 3
		//	or #58
		//	ld d, a
		size_t UpperByte = ((AddrInSCRFile & 0xFF00) >> 3) & 0x300;
		size_t BlockAddr = (UpperByte | (AddrInSCRFile & 0xFF));
		return BlockAddr;	
	}
	else
	{
		return AddrInSCRFile - 6144;
	}
}

void DiffScreens(const char* OrgName, size_t IdxAreaOrdinal, const unsigned char* PrevArea, const unsigned char* CurArea)
{
	// find all different areas
	// classify each difference as belonging to a certain block
	// keep them organized spatially
	std::vector<Difference> Blocks[32 * 24];
	const size_t ScreenSize = 6912;

	size_t NumDifferences = 0;
	size_t NumDifferentBlocks = 0;

	// find and classify the differences
	{
		for (size_t Idx = 0; Idx < ScreenSize; ++Idx)
		{
			// we're establishing how large the difference is
			if (PrevArea[Idx] != CurArea[Idx])
			{
				Difference New;
				New.Value = CurArea[Idx];
				New.PrevValue = CurArea[Idx];

				// find its block coordinates
				size_t BlockAddr = GetBlockFromAddress(Idx);
				Blocks[BlockAddr].push_back(New);

				++NumDifferences;
			}
		}

		for (size_t IdxBlock = 0; IdxBlock < 32 * 24; ++IdxBlock)
		{
			if (Blocks[IdxBlock].empty())
			{
				continue;
			}

			++NumDifferentBlocks;
		}
	}

	// print stats
	printf("Screen %llu: %llu different blocks (%.2f%%), %llu different bytes (%.2f%%)\n",
		IdxAreaOrdinal,
		NumDifferentBlocks, 100.0 * NumDifferentBlocks / (32.0 * 24.0),
		NumDifferences, 100.0 * NumDifferences / (double)ScreenSize);

	std::vector<unsigned char> BlockData;
	BlockData.reserve(NumDifferentBlocks * (8 + 1 + 2) + 2);

	for (size_t IdxBlock = 0; IdxBlock < 32 * 24; ++IdxBlock)
	{
		if (Blocks[IdxBlock].empty())
		{
			continue;
		}

		// save attribute address
		unsigned short AttribAddress = static_cast<unsigned short>(IdxBlock) + 0x5800;

		BlockData.push_back(static_cast<unsigned char>(AttribAddress & 0xFF));
		BlockData.push_back(static_cast<unsigned char>((AttribAddress >> 8) & 0xFF));

		// save attribute value first
		BlockData.push_back(CurArea[6144 + IdxBlock]);

		// find its screen address and save attr
		size_t BitmapAddr = (((IdxBlock & 0x300) << 3)) | (IdxBlock & 0xFF);
		for (size_t IdxByte = 0; IdxByte < 8; ++IdxByte)
		{
			BlockData.push_back(CurArea[BitmapAddr]);
			BitmapAddr += 256;
		}
	}
	BlockData.push_back(0);
	BlockData.push_back(0);

	SaveMemWithExt(OrgName, "blocks", BlockData.data(), BlockData.size(), IdxAreaOrdinal);
}



bool SaveBlockAnim(const char* OrgName, const std::vector<SpeccyScreen>& Screens)
{
	std::vector<std::thread> Threads;

	auto ProcessingLambda = [&Screens, OrgName](size_t IdxPreviousFrame, size_t IdxFrame)
		{
			const SpeccyScreen& ScrPrev = Screens[IdxPreviousFrame];
			const SpeccyScreen& ScrCur = Screens[IdxFrame];

			DiffScreens(OrgName, IdxFrame, ScrPrev.Bitmap, ScrCur.Bitmap);
		};

	// spawn a thread for each frame, and just oversubscribe if need be
	for (size_t Idx = 0, NumFrames = (size_t)Screens.size(); Idx < NumFrames; ++Idx)
	{
		Threads.emplace_back(ProcessingLambda, (Idx - 1) % NumFrames, Idx);
	}

	for (std::thread& Thread : Threads)
	{
		Thread.join();
	}

	printf("Compressed.\n");

	// save the file
	std::string Out;
	Out += "\tdevice ZXSPECTRUM48\n\n";
	Out += "\tmodule BlockAnim\n\n";

	Out += "\torg $4000\n\n";
	for (size_t Idx = 0, NumFrames = (size_t)Screens.size(); Idx < NumFrames; ++Idx)
	{
		char Temp[128];
		snprintf(Temp, sizeof(Temp), "frame_%llu:\n", Idx);
		Out += Temp;
		snprintf(Temp, sizeof(Temp), "\tincbin \"%s.%llu.blocks\"\n", OrgName, Idx);
		Out += Temp;
	}
	Out += "\n\n";
	Out += "\tSAVEBIN \"anim.blockanim\", $4000, $-$4000\n";
	Out += "\tendmodule\n";

	SaveMemWithExt(OrgName, "asm", reinterpret_cast<const unsigned char*>(Out.c_str()), Out.length());
	return true;
}


int main(int argc, const char *argv[])
{
	if (argc < 2)
	{
		printf("Usage: blockanim_packer <path_to_directory_with_SCR_files>\n\n");
		printf(	"Utility will read all files in that directory (they all are expected to be 6912 byte SCRs, if\n"
				"not, it will error out), sort them alphabetically (so if they are numbered, they will be in\n"
				"the proper order), and produce files with differences between them, plus an assembly file to\n"
				"collate them together. Run it in sjasmplus to produce the final binary.\n"
				"\n"
			);
		return 1;
	}

	std::vector<SpeccyScreen> Screens;
	if (!ReadScrSequence(argv[1], Screens))
	{
		fprintf(stderr, "Cannot read SCR sequence - check that all files in the directory are 6912 byte .SCR\n");
		return 1;
	};

	if (!SaveBlockAnim(argv[1], Screens))
	{
		fprintf(stderr, "Cannot compress and save BlockAnim - internal error.\n");
		return 1;
	}

    return 0;
}
