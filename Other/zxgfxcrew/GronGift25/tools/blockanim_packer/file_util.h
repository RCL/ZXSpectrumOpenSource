#pragma once

#include <filesystem>
#include <string>

namespace FileUtils
{
	// Returns full paths to regular files directly inside DirectoryPath (non-recursive),
	// sorted alphabetically according to the platform's native path/string ordering.
	// If the directory does not exist or isn't a directory, returns an empty list.
	std::vector<std::filesystem::path> GetFilesSorted(const std::string& DirectoryPath);
}
