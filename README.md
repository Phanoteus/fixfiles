# fixfiles
A system for running any number of search and replace operations (defined in an external JSON file) against any number of text-based files and logging the results. When a target file matches a search pattern and is therefore a candidate for the associated replace operation, the existing file is backed up (if a backup folder has been specified by the user) before being modified or the existing file is renamed (using a simple datetime suffix, e.g., "default.20161225.asp") as a kind of in-place backup mechanism and a new file with the current name (e.g., "default.asp") is then written to disk.
