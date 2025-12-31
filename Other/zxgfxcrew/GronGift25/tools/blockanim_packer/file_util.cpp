#include <algorithm>
#include "file_util.h"

namespace FileUtils
{
	// Returns full paths to regular files directly inside DirectoryPath (non-recursive),
	// sorted alphabetically according to the platform's native path/string ordering.
	// If the directory does not exist or isn't a directory, returns an empty list.
	inline std::vector<std::filesystem::path> GetFilesSorted(const std::filesystem::path& DirectoryPath)
	{
		namespace fs = std::filesystem;

		std::vector<fs::path> Files;

		std::error_code Error;
		if (!fs::exists(DirectoryPath, Error) || !fs::is_directory(DirectoryPath, Error))
		{
			return Files;
		}

		for (const fs::directory_entry& Entry : fs::directory_iterator(DirectoryPath, Error))
		{
			if (Error)
			{
				break;
			}

			if (!Entry.is_regular_file(Error) || Error)
			{
				Error.clear();
				continue;
			}

			Files.emplace_back(Entry.path());
		}

		std::sort(Files.begin(), Files.end(),
			[](const fs::path& A, const fs::path& B) -> bool
			{
				// Sort by filename only, using the platform's native ordering
				const fs::path& AName = A.filename();
				const fs::path& BName = B.filename();

				if (AName != BName)
				{
					return AName < BName;
				}

				// Tie-breaker to ensure strict weak ordering
				return A < B;
			});

		return Files;
	}

	// Convenience overload for std::string input
	std::vector<std::filesystem::path> GetFilesSorted(const std::string& DirectoryPath)
	{
		return GetFilesSorted(std::filesystem::path(DirectoryPath));
	}
}
