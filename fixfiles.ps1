<#
.SYNOPSIS
Executes search and replace operations on text files.

.DESCRIPTION
This script is essentially a utility for running any number of search and replace operations (defined
in an external JSON file) against any number of text-based files and logging the results. When a file
matches a search pattern and is therefore a candidate for the associated replace operation, the
current file is backed up (if a backup folder has been specified by the user) before being modified
or the current file is renamed (using a date suffix, e.g., "default.20151225.asp") as a kind of in-place
backup mechanism and a new file with the current name (e.g., "default.asp") is then written to disk.

Contacts: Phanoteus
Date: 12/06/2016

.NOTES
You can execute the script from a PowerShell prompt or from the PowerShell IDE. You may have to configure your
script execution privileges in order to run PowerShell scripts. (See http://go.microsoft.com/fwlink/?LinkID=135170
for more information).

This script will probably not be included in your PATH environment variable, so to execute the script, change into the
directory containing the script from the prompt and type a dot (.) followed by a backslash (\) followed by the name
of the script. The "targetDirectory", "operationsFile", and "logFile" parameters are mandatory. The "fileList" specification and
the switches ("-dryrun", "-allornone", and "-excludeOnBackupFailure") are optional.

The format of the JSON operation-definition file (specified by the "operationsFile" parameter) should be as follows:

{
  "operations": [
    {
      "description": "A description of the operation",
      "primarySearch": "A regular-expression-based search pattern",
      "primaryReplace": "A regular-expression-based replace pattern",
      "dependentSearch": "A secondary search pattern" or an empty string (""),
      "dependentReplace": "A secondary replace pattern" or an empty string (""),
      "dependencyCondition": The condition under which the dependent operation executes. If false, then the secondary operation
        runs only if the primary search operation fails to find anything. If true, then the secondary operation runs only if the
        primary search is successful. The only permitted values are true or false.
    },
    {
      "description": "A description of another operation",
      "primarySearch": "Another regular-expression-based search pattern",
      "primaryReplace": "Another regular-expression-based replace pattern",
      "dependentSearch": "",
      "dependentReplace": "",
      "dependencyCondition": false
    },
    {
      etc.
    }
  ],
  "inclusions": [
    "myonefile.txt",
    "*.asp",
    "*.html",
    "*.htm",
    "*.xhtml",
    "etc.",
    "etc."
  ],
  "exclusions": {
    "folders": [
        "foldername1",
        "foldername2",
        "parentfolder\\subfolder"
    ],
    "files": [
        "A regular-expression-based search pattern",
        "Another regular-expression-based search pattern",
        "etc.",
        "etc."
    ]
  }
}

For a given operation definition (object), the "description", "primarySearch", and "primaryReplace" values
are required. The "description" and "primaryReplace" values can be empty strings. The "primarySearch" value can
consist entirely of spaces or any valid regular expression, but it can't be an empty string. The "dependentSearch"
member doesn't have to be included at all. But if it is included and intended to be executed, then a "dependentReplace"
value must be specified as well. The "dependencyCondition" member/value doesn't need to be specified. If it's not specified,
it is assumed to be "false".

The "inclusions" and "exclusions" sections of the JSON definition file are optional. If you don't specify any
inclusions, then the process will be executed against every file found in the specified target directory.
The exclusions section allows for a given file type (e.g., "*.txt") to be included (using the inclusions section)
but excluded based on a given file name pattern (e.g., "backup.txt"). You can specify folder names in the "folders"
array (either as literal strings or regular expressions) and you can specify regular expression patterns for files
to exclude.

This is minimal default template for an operation definition file:

{
  "operations": [
    {
      "description": "Description1",
      "primarySearch": "",
      "primaryReplace": "",
      "dependentSearch": "",
      "dependentReplace": "",
      "dependencyCondition": false
    },
    {
      "description": "Description2",
      "primarySearch": "",
      "primaryReplace": "",
      "dependentSearch": "",
      "dependentReplace": "",
      "dependencyCondition": false
    }
  ],
  "inclusions": [
    "*.asp",
    "*.html",
    "*.htm",
    "*.xhtml"
  ],
  "exclusions": [
    {
      "folders": [
        ""
      ],
      "files": [
        ""
      ]
    }
  ]
}

Keep in mind that in order for the strings in this JSON file to be valid, certain characters must be "escaped". For regular expressions, the main
characters you will have to escape are double quotes (") and backslashes (\). That is, if your search regular expression were something like the following:

  <p>"We\swere\ssoldiers\sonce,\sand\syoung,"\she\ssaid.<p>

To include that in your JSON file as a value in a key/value pair, you'd have to escape the backslashes and quotes and then put the whole string in quotes
(because string values in JSON files MUST be double-quoted per the JSON spec):

  "primarySearch": "<p>\"We\\swere\\ssoldiers\\sonce,\\sand\\syoung,\"\\she\\ssaid.</p>"

This is just something to be aware of. You will probably not be creating the JSON operation definition files manually. The easiest way to create a valid
JSON operations file is to use the FixFiles Configuration Generator (fixfiles.html). The FixFiles Configuration Generator can build a valid operation
definition file and you can also use it to create a valid command-line command expression to execute the FixFiles script.

In other words, the FixFiles Configuration Generator (fixfiles.html) is a kind of GUI for the FixFiles PowerShell script (fixfiles.ps1).

.PARAMETER targetDirectory
Required. The directory containing the files on which the search and replace operations will be executed.

.PARAMETER operationsFile
Required. The path to a JSON file containing the operation definitions.

.PARAMETER logFile
Required. The full path to a log file (or simply the name of a file to be created or used in the current directory).
If the file exists, it will be overwritten. If not, it will be created.

.PARAMETER fileList
Optional. A path specification to an output file for storing the list of updated files. If the file exists, it
will be overwritten. If not, it will be created. You can use this list of files as input into another
script to FTP the files to a server or simply to copy to another location. If a file name is specified (without
further path qualification), the file will be created in the current directory.

.PARAMETER backupDirectory
Optional. A path specification of a folder for backup copies of updated files. If you don't specify a backup folder,
files that are to be updated will be renamed (with a date suffix) in place before being modified. Either way, an
attempt will be made to back up the target file. (See the description of the excludeOnBackupFailure switch for
more information on how FixFiles behaves as a consequence of backup failures.)

.PARAMETER dryrun
Optional. This switch sets the utility to process files and log results but no files are actually changed on disk.
You can use this switch to get an idea of how and which files will be affected.

.PARAMETER allornone
Optional. This switch sets the utility to make changes to a given file only if all of the defined operations can be performed.
That is, you may want your Operations to be performed as a group only. Otherwise, the script will make whatever
changes each individual Operation can make (based on matched patterns).

.PARAMETER excludeOnBackupFailure
Optional. This switch specifies whether the updated contents of a given file are written to disk if for any reason the
current file can't be copied to a backup folder or renamed as an "in-place" backup. By default (that is, when this switch
is not specified), updated contents are written to disk even if the current file can't be backed up or renamed. That is, the
current file itself will be updated. As an extra precaution, you can prevent the current file from being updated if it can't
be backed up or renamed first by specifying this switch on execution of the script.

.EXAMPLE
PS C:\> .\fixfiles 'C:\local-server-content\html' 'C:\operations.json' 'fixfiles.log' -fileList 'updatedfiles.txt' -backupDirectory 'C:\backups' -dryrun -allornone
.EXAMPLE
PS C:\Users\billyshakes\> .\fixfiles 'D:\htmldocs\testdocs' 'fixdumbquotes.json' 'C:\Users\billyshakes\documents\mylogfile.txt'
#>

Param(
    [Parameter(Mandatory=$True, Position=0)][string]$targetDirectory,
    [Parameter(Mandatory=$True, Position=1)][string]$operationsFile,
    [Parameter(Mandatory=$True, Position=2)][string]$logFile,
    [Parameter(Mandatory=$False)][string]$fileList = '',
    [Parameter(Mandatory=$False)][string]$backupDirectory = '',
    [Parameter(Mandatory=$False)][switch]$dryrun,
    [Parameter(Mandatory=$False)][switch]$allornone,
    [Parameter(Mandatory=$False)][switch]$excludeOnBackupFailure
)

# Process parameters.
If (!(Test-Path($targetDirectory))) {
    Write-Output "Target directory not found."
    Exit
}
If (!(Test-Path($operationsFile))) {
    Write-Output "Specified operations file not found."
    Exit
}
If ($backupDirectory) {
    If (!(Test-Path($backupDirectory))) {
        Try {
            New-Item -Path $backupDirectory -ItemType directory -ErrorAction Stop | Out-Null
        }
        Catch {
            Write-Output = $_.Exception.Message
            Exit
        }
    }
}
If ($dryrun) {
    $dryrunCode = ' [DRYRUN]'
}
Else {
    $dryrunCode = ''
}
If ($fileList.Length -gt 0) {
    $saveList = $True
}
Else {
    $saveList = $False
}

<#
Set up a constructor function for creating Operation objects.
An Operation comprises regular expressions for defining a primary search/replace action
in a file (page) and, optionally, additional regular expressions to define a
dependent search/replace action that can be executed depending on the outcome
of the primary action. That is, if you want a secondary search/replace action to be executed
if the primary action does NOT make any changes to a given file, you can set the Condition
value for the Operation object to false ($False) and add DependentSearch and DependentReplace
values for the Operation. If you want the dependent action to be executed only if the
primary action DOES make a change, you can set the Condition value to true ($True).
If you don't need a dependent action for your Operation, just don't set a value for the
DependentSearch property.
#>
Function New-Operation {
    Param (
        [Parameter(Mandatory=$False)][string]$Description = '',
        [Parameter(Mandatory=$True)][string]$Search,
        [Parameter(Mandatory=$False)][string]$Replace = '',
        [Parameter(Mandatory=$False)][boolean]$Condition = $False,
        [Parameter(Mandatory=$False)][string]$DependentSearch = '',
        [Parameter(Mandatory=$False)][string]$DependentReplace = ''
    )

    $operation = New-Object –TypeName PSObject
    $operation | Add-Member -MemberType NoteProperty -Name Description -Value $Description
    $operation | Add-Member -MemberType NoteProperty -Name Search -Value $Search
    $operation | Add-Member -MemberType NoteProperty -Name Replace -Value $Replace
    $operation | Add-Member -MemberType NoteProperty -Name Condition -Value $Condition
    $operation | Add-Member -MemberType NoteProperty -Name DependentSearch -Value $DependentSearch
    $operation | Add-Member -MemberType NoteProperty -Name DependentReplace -Value $DependentReplace

    $operation
}

<#
First try to construct operations object from JSON definition file. Some basic validation here.
At least an "operations" member must be defined in the JSON file.
#>

Try {
    [PSCustomObject]$jsonObject = Get-Content -Raw -Path $operationsFile | ConvertFrom-Json -ErrorAction Stop
}
Catch {
    $jsonObject = $null
}

If (!($jsonObject) -or !(Get-Member -InputObject $jsonObject -Name 'operations' -MemberType Properties)) {
    Write-Output "Invalid input file: $operationsFile"
    Exit
}

[PSCustomObject[]]$operationSet = @()

<#
In the JSON definition file, for a given operation definition, a "description" is required (although it may be an empty string),
a "primarySearch" value is required (and it MUST NOT be an empty string, because that would make no sense, but it CAN consist entirely
of spaces, because you may want to find spaces to replace), and a "primaryReplace" value is required (but it CAN be an empty string,
because you may want to replace the found string with nothing---that is, you may want to delete the found string). Also, if a dependent
search operation is defined (and it may be nothing but spaces), then a dependent replace expression must be defined for the dependent
search operation to be performed. But the dependent replace expression, again, can be an empty string. The logic in
this loop (along with the requirements for creating the New-Operation object) should enforce these rules.
#>
ForEach ($op In $jsonObject.operations) {
    Try {
        $newOp = New-Operation -Description $op.description -Search $op.primarySearch -Replace $op.primaryReplace -ErrorAction Stop

        If ($op.dependentSearch) {
            If (Get-Member -InputObject $op -Name 'dependentReplace' -MemberType Properties) {
                $newOp."DependentSearch" = $op.dependentSearch
                $newOp."DependentReplace" = $op.dependentReplace
                If ($op.dependencyCondition -eq $True) {
                    $newOp."Condition" = $True
                }
            }
        }
        $operationSet += $newOp
    }
    Catch {
        <#
        The operation may not be defined properly (with, that is, the appropriate members) in the JSON file.
        Skip to the next operation definition.
        #>
        Continue
    }
}

# Continue only if one or more operations were properly defined in the JSON definition file.
If ($operationSet.Count -eq 0) {
    Write-Output "No valid operations defined in input file: $operationsFile"
    Exit
}

<#
These are the FILE NAMES or FILE TYPES to be INCLUDED in the scope of the operation. It is easier and safer to
confine the scope of operations to a sub-set of explicitly included file types rather than to attempt
to identify all the file types you'd want to exclude from the operation. If no inclusions are specified
in the JSON definition file, the assumption is that EVERY FILE TYPE will be included in processing.
#>
$inclusions = @()
If (Get-Member -InputObject $jsonObject -Name 'inclusions' -MemberType Properties) {
    ForEach ($include In $jsonObject.inclusions) {
        $include = $include.Trim()
        If ($include) {
            # Full path is limited in Windows to 260 characters.
            If ($include.Length -gt 260) {
                $include.SubString(0, 260)
            }
            $inclusions += $include
        }
    }
}

If ($inclusions.Count -eq 0) {
    #All files will be processed!
    $inclusions = '*'
}

<#
Now set up a filter for excluding FOLDERS as specified in the JSON definition file.
#>
$excludedFolders = @()
If (Get-Member -InputObject $jsonObject -Name 'exclusions' -MemberType Properties) {
    $hasExclusions = $True
    ForEach ($pattern In $jsonObject.exclusions.folders) {
        $pattern = $pattern.Trim()
        If ($pattern) {
            $pattern = '\' + $pattern + '\'
            $pattern = $pattern -replace '\\+', '\\'
            $excludedFolders += $pattern
        }
    }
    $exclusionFilter = [String]::Join('|', $excludedFolders)
}
Else {
    $hasExclusions = $False
}

# Get an array of file handles based on the foregoing inclusion/exclusion settings.
If ($exclusionFilter) {
    $exclusionFilter = '(' + $exclusionFilter + ')'
    $files = Get-ChildItem -File -Path $targetDirectory -Include $inclusions -Recurse | Where-Object {($_.Length -gt 0) -and ($_.FullName -notmatch $exclusionFilter)}
}
Else {
    $files = Get-ChildItem -File -Path $targetDirectory -Include $inclusions -Recurse | Where-Object {($_.Length -gt 0)}
}

$touches = 0
$fileCount = 0
$log = 'Start Time: ' + (Get-Date).ToString() + $dryrunCode
<#
Log details of operation.
#>
$log = $log + "`r`n------------------------------------------------------------"
ForEach ($op in $operationSet) {
    $log = $log + "`r`nOperation Description: " + $op."Description" + "`r`nSearch Expression: " + $op."Search" + "`r`nReplace Expression: " + $op."Replace" +
    "`r`nDependent Search: " + $op."DependentSearch" + "`r`nDependent Replace: " + $op."DependentReplace" + "`r`nDependent Condition: " + $op."Condition" + "`r`n"
}
$log = $log + "`r`nFile Inclusions: " + $inclusions
$log = $log + "`r`nExcluded Folder Filter: " + $exclusionFilter
$log = $log + "`r`n------------------------------------------------------------"

If ($saveList) {
    $updatedFiles = [System.Collections.ArrayList]@()
}

ForEach ($file in $files) {
    $changeType = ''
    $logLine = ''
    $actionCodes = ''
    $action = ''
    $backupLocation = ''
    $newFilePath = ''

    Try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
    }
    Catch {
        $changeType = '[FILE ERROR]'
        $logLine = $changeType + "`t[ERROR OPENING FILE FOR PATTERN MATCHING]`t" + $file.FullName
        $log = $log + "`r`n" + $logLine
        Continue
    }

    <#
    Implementing file pattern exclusions here (if they are specified in the JSON definition file).
    This may not be the most efficient mechanism, but it provides for the specification of multiple
    exclusion patterns (in the JSON definition file). Adding an undefined number of -notmatch regular
    expressions to the Where-Object of the Get-ChildItem command that gets the array of files in the
    first place would get unwieldy. So, all of the files that match the value of the -Include parameter
    passed to the Get-ChildItem cmdlet are returned and then the files whose names match any of the specified
    exclusion patterns as defined in the JSON file are skipped (excluded from processing) here.
    #>

    If ($hasExclusions) {
        $continue = $False
        ForEach ($pattern In $jsonObject.exclusions.files) {
            $pattern = $pattern.Trim()
            If ($pattern) {
                If ($file.BaseName -match $pattern) {
                    $continue = $True
                    Break
                }
            }
        }
        If ($continue) { Continue }
    }

    ForEach ($op in $operationSet) {
        # Attempt to apply primary search and replace action.
        $modified = $content -replace $op."Search", $op."Replace"
        If (!([Object]::ReferenceEquals($content, $modified))) {
            <#
            If you reach this point, the $content and the $modified variables don't have
            the same reference. That is, they are not the same object. (Using the .NET
            [Object]::ReferenceEquals comparison method here because if the RegEx search found
            no matches to its pattern, the $content variable will not be changed and both
            the $content variable and the $modified variable will therefore reference the
            same object in memory. If a change had been made, the RegEx replace action
            would have created a NEW string object in memory and the assignment operator (=)
            would have set the $modified variable to point to it.)
            #>
            $touches++
            $content = $modified
            $action = $op."Description"

            <#
            Execute dependent action if primary action succeeded (i.e., found something to replace) and
            Operation condition is set to True.
            #>
            If (($op."Condition" -eq $True) -and ($op."DependentSearch" -ne '')) {
                $modified = $content -replace $op."DependentSearch", $op."DependentReplace"
                If (!([Object]::ReferenceEquals($content, $modified))) {
                    $content = $modified
                    $action = $action + ' (and Dependent Action)'
                }
            }
        }
        Else {
            <# Primary action failed to make any changes to the target file (i.e., it didn't
            find anything to replace in the target. So if Operation condition is set to False,
            attempt to execute dependent action.
            #>
            If (($op."Condition" -eq $False) -and ($op."DependentSearch" -ne '')) {
                $modified = $content -replace $op."DependentSearch", $op."DependentReplace"
                If (!([Object]::ReferenceEquals($content, $modified))) {
                    $touches++
                    $content = $modified
                    $action = $op."Description" + ' (Dependent Action Only)'
                }
            }
        }

        # Create $actionCodes string for logging.
        If ($action.Length -gt 0) {
            If ($actionCodes.Length -gt 0) {
                $actionCodes = $actionCodes + ' | ' + $action
            }
            Else {
                $actionCodes = $actionCodes + $action
            }
        }

        # Reset $action string for next iteration.
        $action = ''
    }

    # Build logging strings and, optionally, apply changes to the file on disk.
    If ($touches -gt 0) {
        $operationForm = ''
        If ($touches -eq 1) {
            $operationForm = 'OPERATION: '
        }
        Else {
            $operationForm = 'OPERATIONS: '
        }

        $logLine = "[" + $touches.ToString() + " $operationForm" + "$actionCodes]"

        If (($allornone) -and ($touches -lt $operationSet.Length)) {
            $changeType = "[EXCLUDED]"
        }
        Else {
            $changeType = "[UPDATED]"
            If (!$dryrun) {
                <#
                At this point, if changes have been made, they have only been
                applied to the file contents held in memory. Here the changes are
                actually committed to disk (if the script is not executing in dry-run mode).
                Of course, writing to disk may fail for one reason or another.

                First, try to make a backup of the target file. If a backup folder has been specified
                by the user, copy the file to that folder. Otherwise, try to make an "in-place" backup by
                renaming the target file with a date suffix.
                #>

                $backupError = @()

                If ($backupDirectory) {
                    Try {
                        $backupLocation = $file.DirectoryName
                        $backupLocation = $backupLocation.Replace($targetDirectory, $backupDirectory)
                        $newFilePath = $backupLocation + "\" + $file.Name
                        New-Item -ItemType File -Path $newFilePath -Force -ErrorAction Stop -ErrorVariable backupError | Out-Null
                        Copy-Item $file.FullName -Destination $backupLocation -Force -ErrorAction Stop -ErrorVariable backupError
                    }
                    Catch {
                        $changeType = "[EXCLUDED]"
                        $logLine = "[UNABLE TO CREATE BACKUP FILE]"
                    }
                }

                If (($backupError) -or (!$backupDirectory)) {
                    # Reset error variable.
                    $backupError = @()

                    $dateSuffix = Get-Date -Format yyyyMMdd

                    $backupFile = $file.BaseName + ".$dateSuffix" + $file.Extension
                    $backupFilePath = $file.DirectoryName + "\$backupFile"
                    If (Test-Path -Path $backupFilePath) {
                        $timeSuffix = Get-Date -Format HHmmss
                        $backupFile = $file.BaseName + ".$dateSuffix.$timeSuffix" + $file.Extension
                    }

                    Try {
                        Rename-Item -Path $file.FullName -NewName $backupFile -ErrorAction Stop -ErrorVariable backupError
                    }
                    Catch {
                        $changeType = "[EXCLUDED]"
                        $logLine = "[UNABLE TO CREATE BACKUP FILE]"
                    }
                }

                <#
                If the file was backed up/renamed successfully OR if the backup/rename failed but
                the 'excludeOnBackupFailure' switch was not specified when the script was
                executed, then try to write the changed content to disk.
                #>
                If ((!$backupError) -or ($backupError -and !$excludeOnBackupFailure)) {
                    Try {
                        Set-Content $file.FullName $content -ErrorAction Stop
                        If ($saveList) {
                            <#
                            Add to list of updated files if requested by user.
                            (Note that the Add method of an ArrayList returns the index of
                            the added item, which would be displayed for each item
                            if not captured in a variable or piped to the Null output.)
                            #>
                            $updatedFiles.Add($file.FullName) | Out-Null
                        }
                    }
                    Catch {
                        $changeType = "[UPDATE ERROR]"
                        $logLine = "[FILE WRITE ERROR]"
                    }
                }
            }
        }

        $logLine = $changeType + "`t$logLine`t" + $file.FullName

        $log = $log + "`r`n" + $logLine
        $fileCount++
        $touches = 0
    }
}

If ($saveList) {
    # Attempt to write list of updated files to disk.
    If ($updatedFiles.Count -gt 0) {
        Try {
            $separator = "`r`n"
            $listContents = [string]::Join($separator, $updatedFiles.ToArray([string]))
            Set-Content -Path $fileList $listContents -ErrorAction Stop
            $log = $log + "`r`n[LIST OF UPDATED FILES]`t$fileList"
        }
        Catch {
            $ErrorMessage = $_.Exception.Message
            $log = $log + "`r`n[FILE LIST ERROR]`tUnable to create updated file list: $ErrorMessage"
        }
    }
}

# Finalize logging contents.
$log = $log + "`r`n[$fileCount FILE(S) PROCESSED]" + "`r`nEnd Time: " + (Get-Date).ToString() + $dryrunCode

# Attempt to write log file to disk.
Try {
    Set-Content -Path $logFile $log -ErrorAction Stop
}
Catch {
    $ErrorMessage = $_.Exception.Message
    Write-Output "Unable to write to log file: $ErrorMessage"
    # Can't write to log file. Try to output to console.
    Write-Output '----------------------------------------'
    Write-Output $log
}