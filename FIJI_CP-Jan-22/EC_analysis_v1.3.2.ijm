setBatchMode(true); //Start batch mode
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (choices={"Columbus", "Harmony", "CPInput"}, style="radioButtonHorizontal") source


// -----------------------------------------------------------
// GLOBAL VARIABLES
// -----------------------------------------------------------
var VERSION = 1.32;
/*
VERSION 1.1: 31/05/2020
  Fix file naming management bug. Fix CPInput management.
  Improved management of per-channel preprocessing configuration.
  No need to set suffix.
VERSION 1.0: first release to Lorenzo, 30/05/2020.
  Features: assign names to channels, columns and rows;
            select fields per col/row combination;
            per-channel configurable pre-processing.
            File rename functionality disabled.
*/
// Suffix: "tiff" for Harmony, "tif" for Columbus or CPInput
var suffix = ".tif";
// Chosen experiment ID
var experimentId = "";
// Output file name will be different than input (xxxNames arrays are populated)
var nameChangeRequired = false;
// Harmony: r02c02f14p01-ch3sk1fk1fl1.tiff --> 002-r02c02f14ch3-HUVEC-VEGF-VEC.tiff
// Columbus: 002002-1-001001001.tiff --> 002-002002f01001-HUVEC-VEGF-VEC.tiff
// Arrays containing input file information lists
var rowList = newArray; 
var colList = newArray; 
var chanList = newArray;
var fieldList = newArray;
// Array containing names associated to input information lists
var rowNames = newArray; 
var colNames = newArray; 
var chanNames = newArray;
// Files selection
var DEFAULT_SELECTED_FIELDS_NR = 10;
var selectedFileList = newArray;
// Pre-Processing: scale + illumination correction
// Rolling parameter for Subtract Background per channel (0=no pre-proc)
var chanDefaultNames = newArray("VEC", "NCH", "PHA", "NUC");
var DEFAULT_ROLLING = 150;
var NOTCH_ROLLING = 300;
var chanPreProc = newArray;

// -----------------------------------------------------------
// MACRO EXECUTION
// -----------------------------------------------------------
// Update suffix if input is from Harmony
if (source == "Harmony")
{
	suffix = ".tiff";
}
// Collect row, column and channel identifiers from the input filenames
InputFileNamesMapping(input);
// Allow user to associate names to the rows, columns, channels
if (source != "CPInput")
{
	// Read names for rows, columns and channels chosen by user
	FileNameDialog("File Name Formatter");
}
// Log information about the row, columns and channels names
WriteToLog(output, "create");

// Select the number of fields for each combination row/column
FieldSelectionDialog("Fields Selector");

// Pre-processing available for Harmony or Columbus input
if (source != "CPInput")
{
	// Configure and apply pre-processing (scaling + illumination correction)
	// for each channel
	PreProcessorDialog("Channel Pre-Processing Selector");
	ApplyPreProcessing(input, output, 0);  // 0 = process all required images
}
else
{
	// No processing: copy selected images to output folder
	CopySelectedToOuput(input, output);
}

// -----------------------------------------------------------
// -----------------------------------------------------------
// CUSTOM FUNCTIONS TO SUPPORT MACROS EXECUTION
// -----------------------------------------------------------
// -----------------------------------------------------------
// ***********************************************************************
// [FUNCTIONS] SINGLE IMAGE PROCESSING
// ***********************************************************************
function runPreProc(inputFilename, outputFilename, rolling)
{
	//background_params = "rolling="+rolling+" sliding";
	background_params = "blurring="+rolling+" hide";

   	open(inputFilename);
    //run("Scale...", "x=0.5 y=0.5 width=1080 height=1080 interpolation=Bilinear average create");		
	run("Pseudo flat field correction", background_params);
	//run("Subtract Background...", background_params);	
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	
	saveAs("Tiff", outputFilename);
    run("Close All");
    run("Collect Garbage");
}

// ***********************************************************************
// [FUNCTIONS] CONDITIONAL IMAGES PROCESSING
// ***********************************************************************
function ApplyPreProcessing(input, output, maxProcNr)
{
	procNr = 0;
	chanProcNr = newArray(chanNames.length);
	// Create output folder
	outfolder = output + File.separator + "preproc";
	File.makeDirectory(outfolder);
	// Read input filenames list
	flist = getFileList(input);
	flist = Array.sort(flist);
	for (i = 0; i < flist.length; i++)
	{
		if (endsWith(flist[i], suffix) == false)
		{
			continue;
		}
		// Get the index of the channel for the current image
		chIndex = GetChannelIndex(flist[i]);
		if (chIndex == -1)              continue; 	// unknown channel name
		if (chanPreProc[chIndex] == 0)  continue;  	// pre-processing disabled
		// Pre-process the input image if it is in the selected list
		outputName = GetOutputFileName(flist[i]);
		if (IsInSelectedList(outputName, selectedFileList))
		{
			runPreProc(input + File.separator + flist[i], 
			           outfolder + File.separator + outputName,
			           chanPreProc[chIndex]);
			procNr += 1;
			chanProcNr[chIndex] += 1;
			if (procNr == maxProcNr)
			{
				break;
			}
		}			
	}
	WriteToLog(output, "\nPreProcessing results available in "+outfolder);
	LogProcessingPerChannel(output, chanProcNr);
	Dialog.create("Result");
	message = "Processing completed."+procNr+" images processed.";
	Dialog.addMessage(message);
	Dialog.show();	
}

function CopySelectedToOuput(input, output)
{
	copiedNr = 0;
	// Create output folder
	outfolder = output + File.separator + "selected";
	File.makeDirectory(outfolder);
	// Read input filenames list
	flist = getFileList(input);
	flist = Array.sort(flist);
	for (i = 0; i < flist.length; i++)
	{
		if (endsWith(flist[i], suffix) == false)
		{
			continue;
		}
		outputName = GetOutputFileName(flist[i]);
		if (IsInSelectedList(outputName, selectedFileList))
		{
			File.copy(input + File.separator + flist[i],
			          outfolder + File.separator + outputName);
			copiedNr += 1;
		}
	}
	WriteToLog(output, "\nSelected images available in "+outfolder);
	Dialog.create("Result");
	Dialog.addMessage("Processing completed." + copiedNr + " images copied.");
	Dialog.show();
}


// ****************************************************
// [FUNCTIONS] DIALOGS FOR USER INTERACTION
// ****************************************************
function FileNameDialog(currTitle)
{
	Dialog.create(currTitle);
	Dialog.addMessage("Add experiment ID (3 char) and rename rows, columns and channels.\n");

  	html = "<html>"
     +"<h2>Filename formatter help</h2>"
     +"<body>
     +"Format output filename.<br>"
     +"- add ExpID prefix (first 3 char), if not empty.<br>"
     +"- rename rows, columns and channels with the given values.<br>"
     +"Example: ExpID=EXP2, r02=HUVEC, c02=VEGF, ch3=VEC will result in <br>" 
	 +"HARMONY:  r02c02f14p01-ch3sk1fk1fl1.tiff --> EXP2-r02c02f14ch3-HUVEC-VEGF-VEC.tif<br>"
	 +"COLUMBUS: 002002-1-001001003.tif --> EXP2-002002f01002-HUVEC-VEGF-VEC.tif<br>"
     +"</body>";

	Dialog.addHelp(html);

    Dialog.addString("ExpID:", "");
    Dialog.addMessage("Rows: ");
	for (i=0; i<rowList.length; i++)
	{
		if (i > 0) Dialog.addToSameRow();
		Dialog.addString(rowList[i], rowList[i]);
	}
	Dialog.addMessage("Columns: ");
	for (i=0; i<colList.length; i++)
	{
		if (i > 0) Dialog.addToSameRow();
		Dialog.addString(colList[i], colList[i]);
	}
	Dialog.addMessage("Channels: ");
	for (i=0; i<chanList.length; i++)
	{
		if (i > 0) Dialog.addToSameRow();
		if (i > chanDefaultNames.length-1)
		{
			Dialog.addString(chanList[i], chanList[i]);
		}
		else
		{
		    Dialog.addString(chanList[i], chanDefaultNames[i]);
		}
	}  	

	Dialog.show();
	experimentId = Dialog.getString();
	// Read the new names and check that at least one of the names is different, otherwise
    // the output filename will not be changed (only expId added as prefix if not empty)
	nameChangeRequired = false;
	for (i=0; i<rowList.length; i++)
	{
		rowNames = Array.concat(rowNames, Dialog.getString());
		if (rowNames[i] != rowList[i])
		{
			nameChangeRequired = true;
		}
	}
	for (i=0; i<colList.length; i++)
	{
		colNames = Array.concat(colNames, Dialog.getString());
		if (colNames[i] != colList[i])
		{
			nameChangeRequired = true;
		}
	}
	for (i=0; i<chanList.length; i++)
	{
		if (chanNames.length > i)
		{
			chanNames[i] = Dialog.getString();
		}
		else
		{
			chanNames = Array.concat(chanNames, Dialog.getString());
		}
		if (chanNames[i] != chanList[i])
		{
			nameChangeRequired = true;
		}		
	}
}

function PreProcessorDialog(title)
{
	Dialog.create(title);

	// Prepare checkbox for preprocessing and support to read rolling number
    for (i=0; i<chanNames.length; i++)
	{
		Dialog.addMessage(chanNames[i]);
		Dialog.addCheckbox("Pre-Proc", true);
		Dialog.addToSameRow();
		currRolling = DEFAULT_ROLLING;
		if ((chanNames[i] == "NCH") || (chanNames[i] == "NTCH") ||
		    (chanNames[i] == "NOTCH"))
		{
		    currRolling = NOTCH_ROLLING;
		}
		Dialog.addNumber("rolling", currRolling);
	}
	Dialog.show();
	// Read flag to enable pre-proc
	preProcEnable = newArray(chanNames.length);
	for (i=0; i<chanNames.length; i++)
	{
	    preProcEnable[i] = Dialog.getCheckbox();
	}
	// Read rolling values and override with 0 if pre-proc has been disabled
	WriteToLog(output, "\nPre-processing");	
	for (i=0; i<chanNames.length; i++)
	{
	    chanPreProc = Array.concat(chanPreProc, Dialog.getNumber());
	    if (preProcEnable[i] == false)
	    {
	    	chanPreProc[i] = 0;
	    }
		// Log information about the pre-processing required for each channel
	    message = chanNames[i] + ": pre-proc ";
	    if (chanPreProc[i] == 0)
	    {
	    	message += "disabled";
	    }
	    else 
	    {
	    	message += "enabled (rolling=" + chanPreProc[i] + ")";
	    }
		WriteToLog(output, message);
	}	
}

function FieldSelectionDialog(title)
{
	Dialog.create(title);

  	html = "<html>"
     +"<h2>Field selection help</h2>"
     +"<body>
     +"By default all fields are selected for all the available columns/rows.<br>"
     +"Fill in the table to set the number of fields for each combination of row and column.<br>"
     +"Example: 36 fields found, we want to select 10 fields for col2/row2 and 5 for all the other combinations.<br>"
     +"The fields will be selected according to the choice in the dropdown menu:<br>"
     +"- rnd (random): fields are randomly chosen among the ones available (example: 10/36 for col2/row2 and 5/36 for the others); <br>" 
     +"- frst (first set): first set of available fields (example: fields from 1 to 10 or 1 to 5); <br>" 
     +"- last (last set): last set of available fields (example: fields from 26 to 36 or 31 to 36); <br>" 
     +"- all: reverts any selection (example: all 36 fields selected). <br>" 
     +"</body>";

	Dialog.addHelp(html);
	maxFieldsNr = DEFAULT_SELECTED_FIELDS_NR;
    if (fieldList.length < maxFieldsNr)
    {
    	maxFieldsNr = fieldList.length;
    }

    Dialog.addMessage("Select the number of field for each row/col combination\nor select 'all' from the dropdown menu.");
    Dialog.addMessage("Available fields nr:" + fieldList.length); 
    items = newArray("rnd", "frst", "last", "all");
	Dialog.addChoice("", items);
	
    colMsg = "   ";
    for (i=0; i<colNames.length; i++)
    {
    	colMsg += colNames[i] + "             ";
    }
    Dialog.addMessage(colMsg);
	for (i=0; i<rowList.length; i++)
	{
		for (j=0; j<colList.length; j++)
		{
			if (j == 0)
			{
				Dialog.addNumber(rowNames[i], maxFieldsNr);
			}
			else
			{
				Dialog.addToSameRow();
				Dialog.addNumber("", maxFieldsNr);
			}
		}
	}
	Dialog.show();
    fieldSelectionType = Dialog.getChoice();
	WriteToLog(output, "\nField selection: "+fieldSelectionType);
	
    if (fieldSelectionType == "all")
    {
    	return;
    }
	for (i=0; i<rowList.length; i++)
	{
		for (j=0; j<colList.length; j++)
		{
			fieldsNr = Dialog.getNumber();
			if (fieldList.length < fieldsNr)
			{
				fieldsNr = fieldList.length;
			}
			fieldsIndexes = SelectFields(fieldsNr, fieldSelectionType);
			if (fieldSelectionType == "rnd")
			{
				logMsg = rowNames[i] +", "+colNames[j] + printArray("", fieldsIndexes, false);
				WriteToLog(output, logMsg);
			}
			outputNamePrefix = rowList[i] + colList[j] + "f";			
            for (k=0; k<fieldsIndexes.length; k++)
            {
			    selectedFileList = Array.concat(selectedFileList, outputNamePrefix+fieldsIndexes[k]);
            }
            
		}
	}
}

function SelectFields(fieldsNr, fieldsSelectionType)
{
	indexes = newArray(fieldsNr);
	indexSet = newArray;
	newIndex = -1;
	for(i=0; i<fieldsNr; i++)
	{
		if (fieldsSelectionType == "frst")
		{
			indexes[i] = fieldList[i];
		}
		else 
		{
			if(fieldsSelectionType == "last")
			{
				indexes[i] = fieldList[fieldList.length-i-1];
			}
			else
			{
			
			    loopNr = 0;
				while ((indexSet.length < i+1) || (loopNr > 100))
				{
					newIndex = round(random() * (fieldList.length-1));
					indexSet = UpdateSet(newIndex, indexSet);
					loopNr += 1;
				}
				indexes[i] = fieldList[newIndex];
			}
		}
	}
	return indexes;
}

// ****************************************************
// [FUNCTIONS] LOGFILE MANAGEMENT AND DEBUG SUPPORT
// ****************************************************
function WriteToLog(outfolder, logstring)
{
	logfilename = outfolder + File.separator;
	if (source != "CPInput")
	{
		logfilename += "PreProcessingConf.log";
	}
	else
	{
		logfilename += "SelectionConf.log";
	}
	if (logstring != "create")
	{
		File.append(logstring, logfilename);
		return;
	}
	// Processing started: create new log file and start logging
	if (File.exists(logfilename))
	{
		File.delete(logfilename);
	}
	logfile = File.open(logfilename);
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	month = month + 1;
	dayOfMonth = dayOfMonth + 1;
	print(logfile, "-----------------------------------------------");
	print(logfile, dayOfMonth+"/"+month+"/"+year+" "+hour+":"+minute+":"+second+"  EC ANALYSIS LOG");
	print(logfile, "-----------------------------------------------");
	print(logfile, "Source:       " + source);
	print(logfile, " ");
	print(logfile, "ExperimentID: " + experimentId);
	print(logfile, "Rows:");
    LogMappingToFile(logfile, rowList, rowNames); 
    print(logfile, "Columns:");
    LogMappingToFile(logfile, colList, colNames);
    print(logfile, "Channels:"); 
    LogMappingToFile(logfile, chanList, chanNames); 
	File.close(logfile);	
}

function LogProcessingPerChannel(outfolder, procNrPerChannel)
{
	for (i=0; i<chanNames.length; i++)
	{
		message = chanNames[i] + ": "+procNrPerChannel[i]+" images processed.";
		WriteToLog(outfolder, message);
	}
}

function LogMappingToFile(file, valueList, nameList)
{
	for (i=0; i<valueList.length; i++)
	{
		print(file, " " + valueList[i] + " -> " + nameList[i]);
	}
}

function printArray(myarrayname, myarray, output)
{
	message = myarrayname + ": ";
	for(i=0; i<myarray.length;i++)
	{
		message += myarray[i];
		if (output)
		{
			message += "\n";
		}
		else
		{
			message += ", ";
		}
	}
	if (output)
	{
		print(message);
	}
	return message;
}

// ****************************************************
// [FUNCTIONS] ARRAY MANAGEMENT FUNCTIONS
// ****************************************************
function UpdateSet(value, setName)
{
	for(i=0; i<setName.length; i++)
	{
		if (setName[i] == value)
		{
			// value already in the set: return
			return setName;
		}
	}
	// value not in the set: add it
	setName = Array.concat(setName, value);	
	return setName;
}

function MapValueOnName(value, valueList, nameList)
{
	for (i=0; i<valueList.length; i++)
	{
		if (valueList[i] == value)
		{
			return nameList[i];
		}
	}
	return "NOTFOUND";
}

function GetIndex(value, valueList)
{
	for (i=0; i<valueList.length; i++)
	{
		if (valueList[i] == value)
		{
			return i;
		}
	}
	return -1;
}

// ****************************************************
// [FUNCTIONS] INPUT/OUTPUT FILES MANAGEMENT FUNCTIONS
// ****************************************************
function IsInSelectedList(outputName, selectedFileList)
{
	for(i=0; i<selectedFileList.length; i++)
	{
		if (lastIndexOf(outputName, selectedFileList[i]) != -1)
		{
			return true;
		}
	}
	return false;
}

function GetOutputFileName(inputName)
{
	if ((nameChangeRequired == false) || (source == "CPInput"))
	{
		return inputName;
	}
	fileinfo = GetInputFileInfo(inputName);
	outputName = fileinfo[0] + fileinfo[1] + "f" + fileinfo[3] + fileinfo[2];
   	outputName = outputName + "-" + MapValueOnName(fileinfo[0], rowList, rowNames);
   	outputName = outputName + "-" + MapValueOnName(fileinfo[1], colList, colNames);
   	outputName = outputName + "-" + MapValueOnName(fileinfo[2], chanList, chanNames);
   	if (lengthOf(experimentId) > 0)
   	{
   		outputName = experimentId + "-" + outputName;
   	}
   	return outputName;
}

function GetChannelIndex(filename)
{
	fileinfo = GetInputFileInfo(filename);
	return GetIndex(fileinfo[2], chanList);
}


// Return an array of identifiers for the row, column, channel and field
function GetInputFileInfo(filename)
{
	// Array containing the offsets for row, column, channel and field
	HarmonyFilenameIndexes = newArray(0, 3, -12, 7);    // absolute values
	ColumbusFilenameIndexes = newArray(0, 3, -3, 7);    // absolute values
	CPInputFilenameOffsets = newArray(0, 3, 9, 7);      // relative to the first "-"	

	fileinfo = newArray(4);
	indexes = newArray;
	if (source == "Harmony")
	{
		indexes = Array.concat(indexes, HarmonyFilenameIndexes);
		// read field
	    fileinfo[3] = substring(filename, indexes[3], indexes[3]+2);
	}
	else 
	{
		if (source == "Columbus")
		{
			indexes = Array.concat(indexes, ColumbusFilenameIndexes);
			// read field
			second_digit_index = indexes[3]+1;
		    if (substring(filename, second_digit_index, second_digit_index+1) == '-')
		    {
		    	fileinfo[3] = "0" + substring(filename, indexes[3], indexes[3]+1);
		    }
		    else
		    {
		    	fileinfo[3] = substring(filename, indexes[3], indexes[3]+2);
		    }
		}
		else // (source == "CPInput")
		{
			start_index = indexOf(filename, "-") + 1;
			for (i=0; i<CPInputFilenameOffsets.length; i++)
			{
				indexes = Array.concat(indexes, CPInputFilenameOffsets[i]+start_index);
			}
			// read field
			fileinfo[3] = substring(filename, indexes[3], indexes[3]+2);
		}
	}
	// read row, column and channel
	extension_idx = lastIndexOf(filename, ".");
	for (i=0; i<3; i++)
	{
		curr_index = indexes[i];
		if (curr_index < 0)
		{
			curr_index += extension_idx;
		}
		fileinfo[i] = substring(filename, curr_index, curr_index+3);
	}
 
	return fileinfo;
}

function InputFileNamesMapping(input)
{
	flist = getFileList(input);
	flist = Array.sort(flist);
	validFilesNr = 0;
	for (i = 0; i < flist.length; i++)
	{
		if (endsWith(flist[i], suffix) == false)
		{
			continue;
		}
		// Get the row, column, channel and field identifiers and add them to the 
		// corresponding lists if the value is not already present		
		fileinfo = GetInputFileInfo(flist[i]);
		rowList = UpdateSet(fileinfo[0], rowList);
		colList = UpdateSet(fileinfo[1], colList);
		chanList = UpdateSet(fileinfo[2], chanList);
		fieldList = UpdateSet(fileinfo[3], fieldList);
		validFilesNr += 1;
		// If source is CPInput, map the names of rows, columns and channels
		if (source == "CPInput")
		{
			GetCPInputNames(flist[i]);

		}
	}
	if (validFilesNr == 0)
    {
    	exit("No file matching the given suffix " + suffix +" found. Quitting.");
    }
    else
    {
    	Array.sort(fieldList);
    }
	return validFilesNr;
}

function GetCPInputNames(filename)
{
	// Get channel name and update the array with channel names
	startIdx = lastIndexOf(filename, "-") + 1;
	endIdx = lastIndexOf(filename, ".");
	chanNames = UpdateSet(substring(filename, startIdx, endIdx), chanNames);
	// Get column name and update the array with column names
	// NOTE: multiple columns can have the same name
	startIdx -= 1;
	endIdx = startIdx;
	while (startIdx > 0)
	{
	    startIdx -= 1;
		if (fromCharCode(charCodeAt(filename, startIdx)) == "-")
		{
			break;
		}
	}
	startIdx += 1;
	currColName = substring(filename, startIdx, endIdx);
	// Get row name and update the array with row names
	startIdx -= 1;
	endIdx = startIdx;
	while (startIdx > 0)
	{
	    startIdx -= 1;		
		if (fromCharCode(charCodeAt(filename, startIdx)) == "-")
		{
			break;
		}
	}
	startIdx += 1;
	rowNames = UpdateSet(substring(filename, startIdx, endIdx), rowNames);
	// Management of multiple columns with the same name
	currColId = substring(filename, startIdx-10, startIdx-10+3);
	print(filename + "--->" + currColId);
	colIdx = GetIndex(currColId, colList);
	if (colIdx != -1)
	{
		if (colNames.length-1 < colIdx)
		{
			colNames = Array.concat(colNames, currColName);
		}
		else
		{
			colNames[colIdx] = currColName;
		}
	}	
}

// **************************************************************
// **************************************************************
setBatchMode(false); //End batch mode